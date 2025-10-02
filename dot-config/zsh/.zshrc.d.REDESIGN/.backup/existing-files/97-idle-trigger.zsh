#!/usr/bin/env zsh
# 97-idle-trigger.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Stage 4 – Sprint 2
#
# Idle / Background Trigger (S4-27 – Initial Stub)
# ------------------------------------------------
# PURPOSE:
#   Provide a *single-pass*, *postprompt*, *non-blocking* execution channel for
#   latency‑tolerant background tasks that MUST NOT affect Time To First Prompt.
#
# MVP GUARANTEES:
#   - Zero measurable cost when disabled OR when no tasks registered (≤0.05ms).
#   - Single execution (idempotent) per shell session.
#   - Deterministic FIFO ordering.
#   - Bounded by HARD BUDGET (soft stop once cumulative elapsed exceeds it).
#   - Safe failure: task RC != 0 increments error counter but does not abort.
#   - Optional structured telemetry (only when ZSH_LOG_STRUCTURED=1).
#
# OUT OF SCOPE (MVP):
#   - Multi-priority queues
#   - Concurrency / background subshell pools
#   - Re-scheduling / retries
#   - Persistent state across sessions
#
# INTEGRATION:
#   This stub does NOT automatically install a hook. An external orchestrator
#   (deferred dispatcher or a future precmd hook) should invoke:
#       zf::idle::run_if_ready
#   exactly once *after* the initial deferred batch completes.
#
# ENV FLAGS (defaults documented below):
#   ZSH_IDLE_ENABLE=1            Master switch
#   ZSH_IDLE_HARD_BUDGET_MS=75   Cumulative soft budget (ms)
#   ZSH_IDLE_TASK_TIMEOUT_MS=50  Soft per-task timeout threshold (ms)
#   ZSH_IDLE_LOG_VERBOSE=0       Verbose per-task stderr logging
#
# PLAIN TEXT MARKERS:
#   IDLE:START budget=<ms> tasks=<N>
#   IDLE:TASK id=<id> ms=<int> rc=<rc> [timeout=1]
#   IDLE:SUMMARY tasks=<N> ok=<Nok> err=<Nerr> elapsed=<ms> budget_exceeded=<0|1>
#
# JSON (when ZSH_LOG_STRUCTURED=1):
#   {"type":"idle_start","ts":<epoch_ms>,"budget_ms":<int>,"tasks":<int>}
#   {"type":"idle_task","id":"<id>","ms":<int>,"rc":<int>,"timeout":false}
#   {"type":"idle_summary","tasks":<int>,"errors":<int>,"elapsed_ms":<int>,"budget_exceeded":false}
#
# TEST HOOKS (planned):
#   - Presence / ordering of IDLE:TASK lines
#   - Budget enforcement (stop after threshold)
#   - Timeout flagging (task dt > ZSH_IDLE_TASK_TIMEOUT_MS)
#
# ------------------------------------------------------------------------------

# Sentinel (module guard)
[[ -n ${_LOADED_97_IDLE_TRIGGER:-} ]] && return 0
_LOADED_97_IDLE_TRIGGER=1

# Only relevant for interactive shells; bail early for non-interactive
if [[ $- != *i* ]]; then
  return 0
fi

# ------------------------------------------------------------------
# Configuration (lazy evaluate / defaults – do not export globally)
# ------------------------------------------------------------------
: "${ZSH_IDLE_ENABLE:=1}"
: "${ZSH_IDLE_HARD_BUDGET_MS:=75}"
: "${ZSH_IDLE_TASK_TIMEOUT_MS:=50}"
: "${ZSH_IDLE_LOG_VERBOSE:=0}"

# ------------------------------------------------------------------
# Data Structures
# ------------------------------------------------------------------
# Ordered task id list
typeset -ga _IDLE_TASK_IDS
# id -> "func:description"
typeset -gA _IDLE_TASK_META
# id -> "rc=<int>:ms=<int>[:timeout=1]"
typeset -gA _IDLE_TASK_RESULTS

# Internal sentinel to ensure run happens once
typeset -g _IDLE_DEFERRED_DONE=""
typeset -g _IDLE_TRIGGER_STARTED=""

# Minimal logging helpers (namespace safe)
typeset -f zf::log  >/dev/null 2>&1 || zf::log()  { print -r -- "[zf][LOG] $*" >&2; }
typeset -f zf::warn >/dev/null 2>&1 || zf::warn() { print -r -- "[zf][WARN] $*" >&2; }
typeset -f zf::err  >/dev/null 2>&1 || zf::err()  { print -r -- "[zf][ERR] $*" >&2; }

# ------------------------------------------------------------------
# Time Helpers
# ------------------------------------------------------------------
__idle__epoch_ms() {
  # Prefer high-resolution EPOCHREALTIME if available
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    # EPOCHREALTIME seconds.fraction → ms integer
    # Use awk only when necessary; cost negligible in idle phase.
    awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); ms=(a[1]*1000)+substr(a[2]"000",1,3); printf "%d", ms }'
  else
    printf "%(%s)T000" -1 2>/dev/null || date +%s000
  fi
}

__idle__since_ms() {
  # Arg: start_ms
  local start="$1" now
  now=$(__idle__epoch_ms)
  (( now - start ))
}

# ------------------------------------------------------------------
# Registration API
# ------------------------------------------------------------------
# Usage: zf::idle::register <id> <function> <description...>
# Returns:
#   0 success
#   1 invalid args / missing function
#   2 duplicate id (non-fatal; existing preserved)
zf::idle::register() {
  local id func
  id="$1"; func="$2"; shift 2 || true
  local desc="$*"

  if [[ -z "$id" || -z "$func" ]]; then
    zf::warn "idle::register invalid args (id='$id' func='$func')"
    return 1
  fi
  if [[ -n ${_IDLE_TASK_META[$id]:-} ]]; then
    return 2
  fi
  if ! typeset -f -- "$func" >/dev/null 2>&1; then
    zf::warn "idle::register function '$func' not found (id=$id)"
    return 1
  fi

  _IDLE_TASK_IDS+=("$id")
  _IDLE_TASK_META[$id]="${func}:${desc:-unset}"

  return 0
}

# ------------------------------------------------------------------
# Structured Telemetry Emitters (guarded)
# ------------------------------------------------------------------
__idle__emit_json() {
  [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" ]] || return 0
  local line="$1"
  # Choose target: PERF_SEGMENT_JSON_LOG if set else PERF_SEGMENT_LOG else /dev/null
  local target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}}"
  [[ -w "$target" ]] || return 0
  print -r -- "$line" >> "$target" 2>/dev/null || true
}

__idle__emit_start() {
  local ts="$(__idle__epoch_ms)"
  print -r -- "IDLE:START budget=${ZSH_IDLE_HARD_BUDGET_MS}ms tasks=${#_IDLE_TASK_IDS[@]}"
  __idle__emit_json "{\"type\":\"idle_start\",\"ts\":${ts},\"budget_ms\":${ZSH_IDLE_HARD_BUDGET_MS},\"tasks\":${#_IDLE_TASK_IDS[@]}}"
}

__idle__emit_task() {
  local id="$1" ms="$2" rc="$3" timeout_flag="$4"
  local timeout_json="false"
  [[ "$timeout_flag" == "1" ]] && timeout_json="true"
  print -r -- "IDLE:TASK id=${id} ms=${ms} rc=${rc}${timeout_flag:+ timeout=1}"
  __idle__emit_json "{\"type\":\"idle_task\",\"id\":\"${id}\",\"ms\":${ms},\"rc\":${rc},\"timeout\":${timeout_json}}"
}

__idle__emit_summary() {
  local tasks="$1" ok="$2" err="$3" elapsed="$4" exceeded="$5"
  local exceeded_json="false"
  [[ "$exceeded" == "1" ]] && exceeded_json="true"
  print -r -- "IDLE:SUMMARY tasks=${tasks} ok=${ok} err=${err} elapsed=${elapsed} budget_exceeded=${exceeded}"
  __idle__emit_json "{\"type\":\"idle_summary\",\"tasks\":${tasks},\"errors\":${err},\"elapsed_ms\":${elapsed},\"budget_exceeded\":${exceeded_json}}"
}

# ------------------------------------------------------------------
# Core Runner (Single Pass)
# ------------------------------------------------------------------
zf::idle::run_if_ready() {
  # Quick exits (lowest overhead first)
  [[ "${ZSH_IDLE_ENABLE}" == "1" ]] || return 0
  (( ${#_IDLE_TASK_IDS[@]} == 0 )) || true  # continue even if zero; still mark done
  [[ -z ${_IDLE_DEFERRED_DONE:-} ]] || return 0

  _IDLE_TRIGGER_STARTED=1
  local global_start elapsed budget_exceeded=0 errors=0 ok=0
  global_start=$(__idle__epoch_ms)

  __idle__emit_start

  local id meta func desc start_ms dur rc timeout_flag=0
  local cumulative=0

  for id in "${_IDLE_TASK_IDS[@]}"; do
    meta="${_IDLE_TASK_META[$id]}"
    func="${meta%%:*}"
    desc="${meta#*:}"

    start_ms=$(__idle__epoch_ms)
    # Execute task (no arguments in MVP)
    "$func"
    rc=$?
    dur=$(__idle__since_ms "$start_ms")

    timeout_flag=0
    if (( ZSH_IDLE_TASK_TIMEOUT_MS > 0 && dur > ZSH_IDLE_TASK_TIMEOUT_MS )); then
      timeout_flag=1
    fi

    _IDLE_TASK_RESULTS[$id]="rc=${rc}:ms=${dur}${timeout_flag:+:timeout=1}"
    (( rc == 0 )) && (( ok++ )) || (( errors++ ))
    __idle__emit_task "$id" "$dur" "$rc" "$timeout_flag"

    (( cumulative += dur ))
    if (( cumulative > ZSH_IDLE_HARD_BUDGET_MS )); then
      budget_exceeded=1
      zf::warn "idle budget exceeded (${cumulative}ms > ${ZSH_IDLE_HARD_BUDGET_MS}ms) – stopping early"
      break
    fi
  done

  elapsed=$(__idle__since_ms "$global_start")
  __idle__emit_summary "${#_IDLE_TASK_IDS[@]}" "$ok" "$errors" "$elapsed" "$budget_exceeded"

  _IDLE_DEFERRED_DONE=1
  return 0
}

# ------------------------------------------------------------------
# Developer Notes / Future Extensions
# ------------------------------------------------------------------
# - Potential hook installation (not enabled by default to avoid hidden cost):
#     add-zsh-hook precmd zf::idle::run_if_ready
#   This will be decided once the real deferred dispatcher sequencing is finalized.
#
# - Adding a task example (DO NOT COMMIT real heavy work):
#     demo_idle_task() { sleep 0.01 }   # placeholder
#     zf::idle::register demo "demo_idle_task" "Short demo idle task"
#
# - If structured telemetry grows, factor emission into shared util to keep
#   schema alignment with deferred dispatcher JSON.
#
# - When adding idle_total segment to classifier:
#     * Update REFERENCE §5.3 + sync script
#     * Add baseline artifact + tests
#     * Consider distinct budget threshold (likely Warn 25% / Fail 50% vs baseline)
#
# SECURITY / PRIVACY:
# - No user paths or secret values emitted; only ids + timing integers.
#
# END OF FILE
