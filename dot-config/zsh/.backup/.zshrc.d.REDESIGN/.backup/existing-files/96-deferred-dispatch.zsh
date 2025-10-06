#!/usr/bin/env zsh
# 96-deferred-dispatch.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Stage 4 deferred execution skeleton. Provides a minimal, testable dispatcher
#   that runs AFTER the first prompt (post first precmd cycle) without adding
#   measurable pre-prompt latency. Enables future non-critical tasks to execute
#   outside the startup critical path (e.g. warming caches, extended telemetry).
#
# FEATURES (Initial Skeleton):
#   - Lightweight registry (ordered) for deferred jobs
#   - Supported trigger (phase 1): postprompt (execute exactly once after the
#     very first user-visible prompt)
#   - Telemetry: per-job timing (ms) appended to $PERF_SEGMENT_LOG (if set)
#     using line format: DEFERRED id=<id> ms=<elapsed> rc=<rc>
#   - Local log aggregation: $ZDOTDIR/.logs/deferred.log
#   - Dummy job to validate dispatch path
#
# GUARANTEES:
#   - Adds ≤ ~1–2ms of parsing/definition cost; zero execution cost before prompt
#   - No stdout/stderr noise during interactive use (all logging redirected)
#   - Safe in non-interactive shells (auto-disabled)
#
# FUTURE EXTENSIONS (Not yet implemented):
#   - Additional triggers: idle, background-safe, network-available
#   - Concurrency model / work queue
#   - Dependency edges between deferred jobs
#   - Structured JSON emission channel
#
# SAFETY / FAILURE MODE:
#   - Dispatcher never aborts shell; individual job failures are recorded with rc
#   - Missing / unwritable log locations silently degrade
#
# INTEGRATION NOTES:
#   - Must load AFTER 95-prompt-ready.zsh so PROMPT_READY_MS is already captured
#   - Tests can assert presence of log lines and PERF_SEGMENT_LOG markers
#
# ------------------------------------------------------------------------------

# Guard against multiple sourcing
[[ -n ${_LOADED_96_DEFERRED_DISPATCH:-} ]] && return 0
_LOADED_96_DEFERRED_DISPATCH=1

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }
typeset -f zf::warn  >/dev/null 2>&1 || zf::warn()  { print -- "[zf][WARN] $*" >&2; }

# Non-interactive shells: DO NOT install anything
if [[ $- != *i* ]]; then
  zf::debug "deferred: non-interactive shell; dispatcher disabled"
  return 0
fi

# ------------------------------------------------------------------------------
# Registry Structures
# ------------------------------------------------------------------------------
# Ordered list of job ids (preserves registration order)
typeset -ga _ZSH_DEFERRED_ORDER
# Metadata associative arrays (indexed by id)
typeset -gA _ZSH_DEFERRED_FUNC        # id => function name
typeset -gA _ZSH_DEFERRED_TRIGGER     # id => trigger keyword
typeset -gA _ZSH_DEFERRED_DESC        # id => human description
typeset -gA _ZSH_DEFERRED_FLAGS       # id => future flags / JSON-ish string

# Supported triggers (phase 1)
_ZSH_DEFERRED_SUPPORTED_TRIGGERS=("postprompt")

zf::defer::register() {
  # Usage: zf::defer::register <id> <function> <trigger> <description...>
  local id func trig
  id="$1"; func="$2"; trig="$3"; shift 3 || true
  local desc="$*"

  [[ -n "$id" && -n "$func" && -n "$trig" ]] || {
    zf::warn "defer::register invalid args (id='$id' func='$func' trig='$trig')"
    return 1
  }

  # Validate trigger
  local ok=0 t
  for t in "${_ZSH_DEFERRED_SUPPORTED_TRIGGERS[@]}"; do
    [[ "$trig" == "$t" ]] && ok=1
  done
  (( ok )) || {
    zf::warn "defer::register unsupported trigger '$trig' for id='$id'"
    return 1
  }

  # If already exists, skip (idempotent)
  if [[ -n ${_ZSH_DEFERRED_FUNC[$id]:-} ]]; then
    zf::debug "defer::register skipping duplicate id=$id"
    return 0
  fi

  _ZSH_DEFERRED_ORDER+=("$id")
  _ZSH_DEFERRED_FUNC[$id]="$func"
  _ZSH_DEFERRED_TRIGGER[$id]="$trig"
  _ZSH_DEFERRED_DESC[$id]="${desc:-unset}"
  _ZSH_DEFERRED_FLAGS[$id]="{}"

  zf::debug "defer::register id=$id func=$func trig=$trig"
  return 0
}

# ------------------------------------------------------------------------------
# Telemetry Helpers
# ------------------------------------------------------------------------------
__zsh_defer__now_epoch_ms() {
  # Prefer zsh's EPOCHREALTIME for precision
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    # EPOCHREALTIME = seconds.fraction
    awk -v t="${EPOCHREALTIME}" 'BEGIN{ split(t,a,"."); ms = (a[1]*1000) + substr(a[2]"000",1,3); printf "%d", ms }'
  else
    # Fallback coarse
    printf "%(%s)T000" -1 2>/dev/null || date +%s000
  fi
}

__zsh_defer__emit_perf_line() {
  local id="$1" ms="$2" rc="$3"
  [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]] || return 0
  {
    print -- "DEFERRED id=${id} ms=${ms} rc=${rc}"
  } >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
  # Structured telemetry (opt-in; zero overhead when disabled)
  if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" ]]; then
    local __ts
    if [[ -n ${EPOCHREALTIME:-} ]]; then
      __ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
    else
      __ts="$(date +%s 2>/dev/null || printf 0)000"
    fi
    # Fallback: if neither PERF_SEGMENT_JSON_LOG nor PERF_SEGMENT_LOG is set, use /dev/null
    local __target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}}"
    if [[ -w ${__target:-/dev/null} ]]; then
      print -- "{\"type\":\"deferred\",\"id\":\"${id}\",\"ms\":${ms},\"rc\":${rc},\"phase\":\"postprompt\",\"ts\":${__ts}}" >> "${__target}" 2>/dev/null || true
    fi
  fi
}

# ------------------------------------------------------------------------------
# Dispatcher (runs once after first prompt)
# ------------------------------------------------------------------------------
__zsh_deferred_run_once() {
  # Prevent re-entry
  [[ -n ${_ZSH_DEFERRED_DISPATCH_RAN:-} ]] && return 0
  _ZSH_DEFERRED_DISPATCH_RAN=1

  local logdir="${ZDOTDIR:-$HOME/.config/zsh}/.logs"
  local logfile="${logdir}/deferred.log"
  if [[ ! -d "${logdir}" ]]; then
    mkdir -p "${logdir}" 2>/dev/null || true
  fi

  {
    print -- "# deferred-dispatch start ts=$(date +%s 2>/dev/null || printf 0)"
    print -- "# jobs=${#_ZSH_DEFERRED_ORDER[@]}"
  } >> "${logfile}" 2>/dev/null || true

  local id func trig start_ms end_ms delta rc
  local total_ms=0

  for id in "${_ZSH_DEFERRED_ORDER[@]}"; do
    func="${_ZSH_DEFERRED_FUNC[$id]:-}"
    trig="${_ZSH_DEFERRED_TRIGGER[$id]:-}"

    [[ "$trig" == "postprompt" ]] || continue
    [[ -n "$func" ]] || continue
    typeset -f -- "$func" >/dev/null 2>&1 || {
      print -- "# skip id=${id} missing_func=${func}" >> "${logfile}" 2>/dev/null
      continue
    }

    start_ms=$(__zsh_defer__now_epoch_ms)
    {
      "$func"
    } >> "${logfile}" 2>&1
    rc=$?
    end_ms=$(__zsh_defer__now_epoch_ms)
    (( delta = end_ms - start_ms ))
    (( total_ms += delta ))

    __zsh_defer__emit_perf_line "$id" "$delta" "$rc"
    print -- "job id=${id} rc=${rc} ms=${delta}" >> "${logfile}" 2>/dev/null || true
  done

  # Emit cumulative deferred_total SEGMENT (phase=postprompt) for attribution
  if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} ]]; then
    print -- "SEGMENT name=deferred_total ms=${total_ms} phase=postprompt sample=${PERF_SAMPLE_CONTEXT:-unknown}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
  fi
  if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" && -w ${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}} ]]; then
    local __ts
    if [[ -n ${EPOCHREALTIME:-} ]]; then
      __ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
    else
      __ts="$(date +%s 2>/dev/null || printf 0)000"
    fi
    print -- "{\"type\":\"segment\",\"name\":\"deferred_total\",\"ms\":${total_ms},\"phase\":\"postprompt\",\"sample\":\"${PERF_SAMPLE_CONTEXT:-unknown}\",\"ts\":${__ts}}" >> "${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG}}" 2>/dev/null || true
  fi

  print -- "# deferred-dispatch end total_ms=${total_ms}" >> "${logfile}" 2>/dev/null || true

  # S4-27 Idle trigger integration:
  # Invoke idle runner (single-pass) only if the idle module is loaded AND
  # at least one idle task has been registered. This suppresses IDLE:*
  # output when there are zero tasks (maintains zero-noise / zero-overhead).
  if typeset -f zf::idle::run_if_ready >/dev/null 2>&1; then
    if [[ ${#_IDLE_TASK_IDS[@]:-0} -gt 0 ]]; then
      zf::idle::run_if_ready
    fi
  fi
}

# Install hook (after 95 module already set PROMPT_READY_MS)
if autoload -Uz add-zsh-hook 2>/dev/null; then
  add-zsh-hook precmd __zsh_deferred_run_once 2>/dev/null || true
else
  # Fallback wrapping pattern
  if typeset -f precmd >/dev/null 2>&1; then
    # Append our call at end of existing precmd
    eval "$(typeset -f precmd | sed '$d') __zsh_deferred_run_once; }"
  else
    precmd() { __zsh_deferred_run_once; }
  fi
fi

# ------------------------------------------------------------------------------
# Dummy Validation Job
# ------------------------------------------------------------------------------
__zsh_deferred_dummy_job() {
  # Minimal work simulation (avoid large sleeps – keep <20ms)
  # Use builtin sleep if available for slight delay (optional)
  command -v sleep >/dev/null 2>&1 && sleep 0.01 2>/dev/null || true
  print -- "dummy: executed ts=$(date +%s 2>/dev/null || echo 0)"
}

zf::defer::register "dummy-warm" "__zsh_deferred_dummy_job" "postprompt" "Dummy validation job to confirm deferred path"

# Export sentinel for tests
: ${_ZSH_DEFERRED_SKELETON:=1}
