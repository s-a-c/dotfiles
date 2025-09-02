#!/usr/bin/env zsh
# async-dispatcher.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Phase A shadow-mode asynchronous task dispatcher skeleton for the ZSH redesign.
#   Provides registration, launch, collection, and basic instrumentation for async
#   tasks without yet removing their synchronous counterparts. This enables early
#   variance / stability observation before deferring actual work.
#
# SCOPE (Phase A):
#   - Shadow mode only (ASYNC_MODE=shadow) executes tasks AFTER prompt_ready scheduling.
#   - 'on' mode is stubbed; real deferral activation will occur in Phase C.
#   - Integrates with segment-lib.zsh if loaded; otherwise uses lightweight fallbacks.
#
# FEATURES:
#   - Declarative task registration API (async_register_task)
#   - Environment flag gating: ASYNC_MODE=off|shadow|on
#   - Basic timeout bookkeeping (logical; actual enforcement pending later phase)
#   - Segment emission: async_task_<id>_start / _done / _fail
#   - Prototype optional zpty worker pool (feature flag ASYNC_USE_ZPTY=1)
#   - Safe no-op when requirements absent (zsh <5.2, POSIX sh fallback, etc.)
#
# NON-FEATURES (Yet):
#   - Real timeout kill / watchdog
#   - Adaptive concurrency heuristics
#   - Overhead attribution vs removed sync cost
#
# SECURITY / SAFETY:
#   - Background subshell (&!) or zpty child shells (isolated) execute task body.
#   - No user input interpolation; caller responsibility to sanitize task commands.
#   - Tasks default disabled unless explicitly registered and enabled via manifest.
#
# MANIFEST INTEGRATION:
#   - Attempts to read async manifest JSON (if jq present) at:
#       docs/redesignv2/async/manifest.json
#   - Fallback: manual registration calls may be inserted in redesign modules.
#
# USAGE (Phase A):
#   1. Source late in post-plugin initialization (after segment-lib).
#   2. Set ASYNC_MODE=shadow (for observation) or ASYNC_MODE=off (default).
#   3. (Optional) Enable worker pool: ASYNC_USE_ZPTY=1; set ASYNC_ZPTY_WORKERS (default 2).
#   4. Register tasks / load manifest; call async_dispatch_init.
#   5. Launch tasks (async_launch_shadow_tasks) then periodically async_flush_cycle.
#
# ENV VARS (initial subset):
#   ASYNC_MODE=off|shadow|on          (default off)
#   ASYNC_DEBUG_VERBOSE=1             (debug logging)
#   ASYNC_FORCE_TIMEOUT=<task_id>     (simulate timeout path)
#   ASYNC_TEST_FAKE_LATENCY_MS=<int>  (sleep injected into each task pre body)
#   ASYNC_USE_ZPTY=1                  (enable prototype worker pool)
#   ASYNC_ZPTY_WORKERS=<N>            (pool size, default 2)
#
# EXIT CONDITIONS:
#   - Script never aborts shell; all failures degrade gracefully with logs.
#
# -----------------------------------------------------------------------------
# CONFIG & GLOBALS
# -----------------------------------------------------------------------------

: ${ASYNC_MODE:=off}

# Associative registries
typeset -gA __ASYNC_TASK_CMD          # id -> command string
typeset -gA __ASYNC_TASK_PRIORITY     # id -> priority
typeset -gA __ASYNC_TASK_TIMEOUT_MS   # id -> numeric timeout
typeset -gA __ASYNC_TASK_STATUS       # id -> pending|running|done|fail|timeout|queued
typeset -gA __ASYNC_TASK_LABEL        # id -> label / segment base
typeset -gA __ASYNC_TASK_START_MS     # id -> epoch ms
typeset -gA __ASYNC_TASK_END_MS       # id -> epoch ms
typeset -gA __ASYNC_TASK_PID          # id -> background PID (bg engine)
typeset -gA __ASYNC_TASK_ERROR        # id -> error string
typeset -gA __ASYNC_TASK_FEATURE_FLAG # id -> feature flag name
typeset -gA __ASYNC_TASK_ENGINE       # id -> bg|zpty
typeset -gA __ASYNC_TASK_PTY          # id -> zpty name (if engine=zpty)
typeset -ga __ASYNC_TASK_QUEUE        # queued task ids (for zpty pool)

# zpty pool bookkeeping
typeset -gA __ASYNC_ZPTY_SLOT_TASK    # pty_name -> task id
typeset -gA __ASYNC_ZPTY_SLOT_START   # pty_name -> start ms
typeset -gA __ASYNC_ZPTY_SLOT_SCRIPT  # pty_name -> temp script path (for cleanup)
typeset -g  __ASYNC_ZPTY_ENABLED=0
: ${ASYNC_ZPTY_WORKERS:=2}

# Simple priority ordering (cosmetic < normal < critical)
typeset -gA __ASYNC_PRIORITY_WEIGHT
__ASYNC_PRIORITY_WEIGHT[cosmetic]=10
__ASYNC_PRIORITY_WEIGHT[normal]=50
__ASYNC_PRIORITY_WEIGHT[critical]=90

# Default timeouts
: ${ASYNC_DEFAULT_TIMEOUT_MS:=1500}
: ${ASYNC_HARD_TIMEOUT_CAP_MS:=5000}

# Segment log file (same variable used by segment-lib if present)
: ${PERF_SEGMENT_LOG:=}

# -----------------------------------------------------------------------------
# UTILS
# -----------------------------------------------------------------------------

_asyncd_ts_ms() {
  printf '%s' "$(($(date +%s%N 2>/dev/null)/1000000))" 2>/dev/null || date +%s000
}

_asyncd_debug() {
  [[ -n ${ASYNC_DEBUG_VERBOSE:-} ]] || return 0
  print -- "[asyncd][debug] $*" >&2
}

_asyncd_log() {
  print -- "[asyncd] $*" >&2
}

_asyncd_warn() {
  print -- "[asyncd][warn] $*" >&2
}

_asyncd_error() {
  print -- "[asyncd][error] $*" >&2
}

# Segment emission (fallback if segment-lib absent)
_asyncd_segment_emit() {
  local name="$1" ms="$2" phase="post_plugin"
  if [[ -n ${PERF_SEGMENT_LOG} && -w ${PERF_SEGMENT_LOG} ]]; then
    print "SEGMENT name=${name} ms=${ms} phase=${phase} sample=${PERF_SAMPLE_MODE:-unknown}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
  fi
}

# Wrapper to start / end using segment-lib if available
_asyncd_segment_start() {
  local label="$1"
  if typeset -f _zsh_perf_segment_start >/dev/null 2>&1; then
    _zsh_perf_segment_start "${label}" post_plugin
  else
    __ASYNC_SEGMENT_FALLBACK_START[$label]=$(_asyncd_ts_ms)
  fi
}

_asyncd_segment_end() {
  local label="$1"
  if typeset -f _zsh_perf_segment_end >/dev/null 2>&1; then
    _zsh_perf_segment_end "${label}" post_plugin
  else
    local start=${__ASYNC_SEGMENT_FALLBACK_START[$label]:-0}
    local end=$(_asyncd_ts_ms)
    local delta=$(( end - start ))
    _asyncd_segment_emit "${label}" "${delta}"
  fi
}

typeset -gA __ASYNC_SEGMENT_FALLBACK_START

# -----------------------------------------------------------------------------
# CAPABILITY PROBE
# -----------------------------------------------------------------------------

async_capability_probe() {
  if [[ -z ${ZSH_VERSION:-} ]]; then
    _asyncd_warn "Not running under zsh; async disabled"
    return 1
  fi

  # Prototype zpty worker pool
  if [[ "${ASYNC_USE_ZPTY:-0}" == "1" ]]; then
    if zmodload zsh/zpty 2>/dev/null; then
      __ASYNC_ZPTY_ENABLED=1
      _asyncd_debug "zpty module loaded (prototype pool enabled) workers=${ASYNC_ZPTY_WORKERS}"
    else
      _asyncd_warn "zpty unavailable; falling back to background engine"
      __ASYNC_ZPTY_ENABLED=0
    fi
  fi
  return 0
}

# -----------------------------------------------------------------------------
# REGISTRATION
# -----------------------------------------------------------------------------

# Usage: async_register_task <id> <priority> <timeout_ms> <label> <feature_flag> <command>
async_register_task() {
  local id="$1" priority="$2" timeout_ms="$3" label="$4" feature_flag="$5"
  shift 5 || true
  local cmd="$*"

  if [[ -z $id || -z $cmd ]]; then
    _asyncd_warn "Skipping registration (id or cmd missing)"
    return 1
  fi

  if [[ -n ${__ASYNC_TASK_CMD[$id]:-} ]]; then
    _asyncd_warn "Task '$id' already registered – replacing"
  fi

  # Validate priority
  if [[ -z ${__ASYNC_PRIORITY_WEIGHT[$priority]:-} ]]; then
    _asyncd_warn "Unknown priority '$priority' for task '$id' – defaulting to 'normal'"
    priority=normal
  fi

  # Timeout normalization
  if [[ -z $timeout_ms || ! $timeout_ms =~ '^[0-9]+$' ]]; then
    timeout_ms=$ASYNC_DEFAULT_TIMEOUT_MS
  fi
  if (( timeout_ms > ASYNC_HARD_TIMEOUT_CAP_MS )); then
    timeout_ms=$ASYNC_HARD_TIMEOUT_CAP_MS
  fi

  __ASYNC_TASK_CMD[$id]="$cmd"
  __ASYNC_TASK_PRIORITY[$id]="$priority"
  __ASYNC_TASK_TIMEOUT_MS[$id]="$timeout_ms"
  __ASYNC_TASK_LABEL[$id]="${label:-async_task_${id}}"
  __ASYNC_TASK_STATUS[$id]="pending"
  __ASYNC_TASK_FEATURE_FLAG[$id]="${feature_flag:-}"
  __ASYNC_TASK_ENGINE[$id]=""

  _asyncd_debug "Registered task id=$id priority=$priority timeout_ms=$timeout_ms label=${__ASYNC_TASK_LABEL[$id]}"
}

# -----------------------------------------------------------------------------
# MANIFEST LOADING (Optional)
# -----------------------------------------------------------------------------

async_manifest_load() {
  local manifest="${ASYNC_MANIFEST_PATH:-${ZDOTDIR:-$HOME/.zsh}/docs/redesignv2/async/manifest.json}"
  if [[ ! -r $manifest && -r "./docs/redesignv2/async/manifest.json" ]]; then
    manifest="./docs/redesignv2/async/manifest.json"
  fi
  [[ -r $manifest ]] || return 0

  command -v jq >/dev/null 2>&1 || {
    _asyncd_debug "jq not found; skipping manifest parse"
    return 0
  }

  _asyncd_debug "Parsing async manifest: $manifest"
  local ids
  ids=($(jq -r '.tasks[] | select(.enabled==true) | .id' "$manifest" 2>/dev/null))
  local id label priority timeout feature_flag
  for id in "${ids[@]}"; do
    label=$(jq -r --arg id "$id" '.tasks[] | select(.id==$id) | .label' "$manifest" 2>/dev/null)
    priority=$(jq -r --arg id "$id" '.tasks[] | select(.id==$id) | .priority' "$manifest" 2>/dev/null)
    timeout=$(jq -r --arg id "$id" '.tasks[] | select(.id==$id) | .timeout_ms' "$manifest" 2>/dev/null)
    feature_flag=$(jq -r --arg id "$id" '.tasks[] | select(.id==$id) | .feature_flag' "$manifest" 2>/dev/null)
    local cmd
    case "$id" in
      theme_extras)
        cmd=': ${ASYNC_TEST_FAKE_LATENCY_MS:=0}; [[ $ASYNC_TEST_FAKE_LATENCY_MS -gt 0 ]] && sleep $((${ASYNC_TEST_FAKE_LATENCY_MS}/1000.0)) || true'
        ;;
      completion_cache_scan)
        cmd=': ${ASYNC_TEST_FAKE_LATENCY_MS:=0}; [[ $ASYNC_TEST_FAKE_LATENCY_MS -gt 0 ]] && sleep $((${ASYNC_TEST_FAKE_LATENCY_MS}/1000.0)) || true'
        ;;
      *)
        cmd=': # no-op placeholder (future real task)'
        ;;
    esac
    async_register_task "$id" "$priority" "$timeout" "$label" "$feature_flag" "$cmd"
  done
}

# -----------------------------------------------------------------------------
# DISPATCHER INIT
# -----------------------------------------------------------------------------

async_dispatch_init() {
  async_capability_probe || {
    _asyncd_warn "Capability probe failed – async disabled"
    ASYNC_MODE=off
    return 0
  }
  _asyncd_debug "Initializing async dispatcher (mode=$ASYNC_MODE zpty=${__ASYNC_ZPTY_ENABLED})"
  async_manifest_load
  return 0
}

# -----------------------------------------------------------------------------
# INTERNAL: zpty POOL HELPERS (Prototype)
# -----------------------------------------------------------------------------

_asyncd_zpty_active_count() {
  local c=0 name
  for name in ${(k)__ASYNC_ZPTY_SLOT_TASK}; do
    (( c++ ))
  done
  echo $c
}

_asyncd_zpty_launch_task() {
  # Args: id
  local id="$1"
  local label="${__ASYNC_TASK_LABEL[$id]}"
  local cmd="${__ASYNC_TASK_CMD[$id]}"
  local pty="asyncpty_${id}"
  if [[ -n ${__ASYNC_ZPTY_SLOT_TASK[$pty]:-} ]]; then
    _asyncd_warn "PTY name collision for $pty"
    return 1
  fi

  __ASYNC_TASK_START_MS[$id]=$(_asyncd_ts_ms)
  __ASYNC_TASK_STATUS[$id]="running"
  __ASYNC_TASK_ENGINE[$id]="zpty"
  __ASYNC_TASK_PTY[$id]="$pty"
  _asyncd_segment_start "async_task_${id}_start"

  # Build a temp script to avoid complex in-line quoting / brace parse errors.
  local tmp_script
  tmp_script=$(mktemp 2>/dev/null || mktemp -t asyncpty) || {
    _asyncd_warn "mktemp failed; falling back to background engine for $id"
    unset __ASYNC_TASK_ENGINE[$id] __ASYNC_TASK_PTY[$id]
    __ASYNC_TASK_STATUS[$id]="pending"
    return 1
  }

  # Safely escaped command (shell-quoted) so we can eval it in the child.
  local escaped_cmd
  printf -v escaped_cmd '%q' "$cmd"

  cat >"$tmp_script" <<EOF
# zpty task wrapper for id=$id
set -eu
rc=0
if [ -n "\${ASYNC_TEST_FAKE_LATENCY_MS:-}" ]; then
  ms=\${ASYNC_TEST_FAKE_LATENCY_MS}
  if [ "\$ms" -gt 0 ] 2>/dev/null; then
    sleep "\$(printf '%.3f' "\$((ms))/1000")"
  fi
fi
if [ "\${ASYNC_FORCE_TIMEOUT:-}" = "$id" ]; then
  # Simulated timeout: exceed logical limit
  sleep "\$(printf '%.3f' "\$(( ${__ASYNC_TASK_TIMEOUT_MS[$id]:-${ASYNC_DEFAULT_TIMEOUT_MS}} + 200 ))/1000")"
  rc=124
else
  eval $escaped_cmd
  rc=\$?
fi
print "__ASYNC_DONE id=$id rc=\$rc"
exit \$rc
EOF

  # Launch zpty (non-blocking). Use direct file execution to avoid nested quoting.
  if ! zpty -b "$pty" zsh "$tmp_script"; then
    _asyncd_warn "Failed to launch zpty for task $id – falling back to background"
    rm -f "$tmp_script" 2>/dev/null || true
    unset __ASYNC_TASK_ENGINE[$id] __ASYNC_TASK_PTY[$id]
    __ASYNC_TASK_STATUS[$id]="pending"
    return 1
  fi
  # We keep tmp_script in place until completion; child references its content already.
  __ASYNC_ZPTY_SLOT_TASK[$pty]="$id"
  __ASYNC_ZPTY_SLOT_START[$pty]=${__ASYNC_TASK_START_MS[$id]}
  _asyncd_debug "zpty launch id=$id pty=$pty script=$tmp_script"
  __ASYNC_ZPTY_SLOT_SCRIPT[$pty]="$tmp_script"
  return 0
}

_asyncd_zpty_try_dequeue() {
  # Fill available slots
  local capacity=$ASYNC_ZPTY_WORKERS
  local active=$(_asyncd_zpty_active_count)
  local id
  while (( active < capacity )) && (( ${#__ASYNC_TASK_QUEUE[@]} > 0 )); do
    id="${__ASYNC_TASK_QUEUE[1]}"
    __ASYNC_TASK_QUEUE=("${__ASYNC_TASK_QUEUE[@]:1}")
    _asyncd_zpty_launch_task "$id" || {
      __ASYNC_TASK_STATUS[$id]="fail"
      __ASYNC_TASK_ERROR[$id]="launch_error"
    }
    active=$(_asyncd_zpty_active_count)
  done
}

_asyncd_zpty_poll() {
  (( __ASYNC_ZPTY_ENABLED == 1 )) || return 0
  local pty id line rc delta start elapsed limit now
  now=$(_asyncd_ts_ms)
  for pty id in ${(kv)__ASYNC_ZPTY_SLOT_TASK}; do
    # Attempt non-blocking read (0-length timeout)
    if zpty -r "$pty" line 0 2>/dev/null; then
      if [[ "$line" == __ASYNC_DONE* ]]; then
        rc=${line##*rc=}
        __ASYNC_TASK_END_MS[$id]=$(_asyncd_ts_ms)
        delta=$(( __ASYNC_TASK_END_MS[$id] - __ASYNC_TASK_START_MS[$id] ))
        if (( rc == 0 )); then
          __ASYNC_TASK_STATUS[$id]="done"
          _asyncd_segment_end "async_task_${id}_done"
        elif (( rc == 124 )); then
          __ASYNC_TASK_STATUS[$id]="timeout"
          __ASYNC_TASK_ERROR[$id]="timeout"
          _asyncd_segment_end "async_task_${id}_fail"
        else
          __ASYNC_TASK_STATUS[$id]="fail"
          __ASYNC_TASK_ERROR[$id]="rc=$rc"
          _asyncd_segment_end "async_task_${id}_fail"
        fi
        zpty -d "$pty" 2>/dev/null || true
        unset __ASYNC_ZPTY_SLOT_TASK[$pty] __ASYNC_ZPTY_SLOT_START[$pty]
      fi
    else
      # Timeout check (logical)
      start=${__ASYNC_TASK_START_MS[$id]:-0}
      limit=${__ASYNC_TASK_TIMEOUT_MS[$id]:-$ASYNC_DEFAULT_TIMEOUT_MS}
      elapsed=$(( now - start ))
      if (( elapsed > limit )) && [[ ${__ASYNC_TASK_STATUS[$id]} == running ]]; then
        __ASYNC_TASK_STATUS[$id]="timeout"
        __ASYNC_TASK_END_MS[$id]=$now
        __ASYNC_TASK_ERROR[$id]="timeout"
        _asyncd_warn "zpty task '$id' logical timeout (elapsed=${elapsed}ms > limit=${limit}ms)"
        _asyncd_segment_end "async_task_${id}_fail"
        zpty -d "$pty" 2>/dev/null || true
        [[ -n ${__ASYNC_ZPTY_SLOT_SCRIPT[$pty]:-} ]] && rm -f "${__ASYNC_ZPTY_SLOT_SCRIPT[$pty]}" 2>/dev/null || true
        unset __ASYNC_ZPTY_SLOT_TASK[$pty] __ASYNC_ZPTY_SLOT_START[$pty] __ASYNC_ZPTY_SLOT_SCRIPT[$pty]
      fi
    else
      # If the pty was removed externally, ensure we cleanup
      if ! zpty -t "$pty" 2>/dev/null; then
        [[ -n ${__ASYNC_ZPTY_SLOT_SCRIPT[$pty]:-} ]] && rm -f "${__ASYNC_ZPTY_SLOT_SCRIPT[$pty]}" 2>/dev/null || true
        unset __ASYNC_ZPTY_SLOT_TASK[$pty] __ASYNC_ZPTY_SLOT_START[$pty] __ASYNC_ZPTY_SLOT_SCRIPT[$pty]
      fi
    fi
  done
  _asyncd_zpty_try_dequeue
}

# -----------------------------------------------------------------------------
# TASK LAUNCH (Shadow)
# -----------------------------------------------------------------------------

_asyncd_task_should_run() {
  local id="$1"
  local ff="${__ASYNC_TASK_FEATURE_FLAG[$id]:-}"
  if [[ -n $ff ]]; then
    local __ff_val="${(P)ff:-}"
    if [[ -n $__ff_val ]]; then
      local __norm="${__ff_val:l}"
      if [[ $__norm == "0" || $__norm == "false" || $__norm == "off" ]]; then
        return 1
      fi
    fi
  fi
  return 0
}

async_launch_shadow_tasks() {
  [[ $ASYNC_MODE == shadow ]] || return 0
  local id cmd pid

  for id cmd in ${(kv)__ASYNC_TASK_CMD}; do
    [[ ${__ASYNC_TASK_STATUS[$id]} == pending ]] || continue
    _asyncd_task_should_run "$id" || {
      _asyncd_debug "Feature flag prevented task '$id'"
      continue
    }

    if (( __ASYNC_ZPTY_ENABLED == 1 )); then
      local active=$(_asyncd_zpty_active_count)
      if (( active < ASYNC_ZPTY_WORKERS )); then
        _asyncd_zpty_launch_task "$id" || continue
      else
        __ASYNC_TASK_STATUS[$id]="queued"
        __ASYNC_TASK_ENGINE[$id]="zpty"
        __ASYNC_TASK_QUEUE+=("$id")
        _asyncd_debug "Queued task '$id' (zpty pool saturated)"
      fi
      continue
    fi

    # Fallback background engine
    local label="${__ASYNC_TASK_LABEL[$id]}"
    __ASYNC_TASK_START_MS[$id]=$(_asyncd_ts_ms)
    __ASYNC_TASK_STATUS[$id]="running"
    __ASYNC_TASK_ENGINE[$id]="bg"
    _asyncd_segment_start "async_task_${id}_start"

    {
      if [[ ${ASYNC_FORCE_TIMEOUT:-} == "$id" ]]; then
        sleep "$(( (__ASYNC_TASK_TIMEOUT_MS[$id] + 200)/1000 ))"
        exit 124
      fi
      if [[ -n ${ASYNC_TEST_FAKE_LATENCY_MS:-} ]]; then
        ms=${ASYNC_TEST_FAKE_LATENCY_MS:-0}
        (( ms > 0 )) && sleep "$(printf '%.3f' "$((ms))/1000")"
      fi
      eval "${cmd}"
    } &!

    pid=$!
    __ASYNC_TASK_PID[$id]=$pid
    _asyncd_debug "Launched task id=$id pid=$pid label=$label engine=bg"
  done
}

# -----------------------------------------------------------------------------
# COLLECTION
# -----------------------------------------------------------------------------

async_collect() {
  local id pid rc now delta start elapsed limit
  now=$(_asyncd_ts_ms)

  # zpty engine collection
  _asyncd_zpty_poll

  # background engine collection
  for id pid in ${(kv)__ASYNC_TASK_PID}; do
    [[ ${__ASYNC_TASK_STATUS[$id]} == running ]] || continue
    [[ ${__ASYNC_TASK_ENGINE[$id]} == bg ]] || continue

    if kill -0 "$pid" 2>/dev/null; then
      start=${__ASYNC_TASK_START_MS[$id]:-0}
      elapsed=$(( now - start ))
      limit=${__ASYNC_TASK_TIMEOUT_MS[$id]:-$ASYNC_DEFAULT_TIMEOUT_MS}
      if (( elapsed > limit )); then
        __ASYNC_TASK_STATUS[$id]="timeout"
        __ASYNC_TASK_END_MS[$id]=$now
        __ASYNC_TASK_ERROR[$id]="timeout"
        _asyncd_warn "Task '$id' timed out (elapsed=${elapsed}ms > limit=${limit}ms)"
        _asyncd_segment_end "async_task_${id}_fail"
      fi
      continue
    fi

    wait "$pid" 2>/dev/null
    rc=$?
    __ASYNC_TASK_END_MS[$id]=$(_asyncd_ts_ms)
    delta=$(( __ASYNC_TASK_END_MS[$id] - __ASYNC_TASK_START_MS[$id] ))

    if (( rc == 0 )); then
      __ASYNC_TASK_STATUS[$id]="done"
      _asyncd_segment_end "async_task_${id}_done"
      _asyncd_debug "Task '$id' done rc=0 ms=$delta engine=bg"
    elif (( rc == 124 )) && [[ ${__ASYNC_TASK_ERROR[$id]:-} == timeout ]]; then
      :
    else
      __ASYNC_TASK_STATUS[$id]="fail"
      __ASYNC_TASK_ERROR[$id]="rc=$rc"
      _asyncd_segment_end "async_task_${id}_fail"
      _asyncd_warn "Task '$id' failed rc=$rc ms=$delta engine=bg"
    fi
  done
}

# -----------------------------------------------------------------------------
# FLUSH CYCLE (Single Pass)
# -----------------------------------------------------------------------------

async_flush_cycle() {
  async_collect
  _asyncd_segment_emit async_flush_cycle 0
}

# -----------------------------------------------------------------------------
# SUMMARY (Informational)
# -----------------------------------------------------------------------------

async_summary() {
  local id status ok=0 fail=0 timeout=0 running=0 pending=0 queued=0
  for id status in ${(kv)__ASYNC_TASK_STATUS}; do
    case $status in
      done) ((ok++)) ;;
      fail) ((fail++)) ;;
      timeout) ((timeout++)) ;;
      running) ((running++)) ;;
      pending) ((pending++)) ;;
      queued) ((queued++)) ;;
    esac
  done
  print -- "async_summary ok=$ok fail=$fail timeout=$timeout running=$running pending=$pending queued=$queued zpty_enabled=${__ASYNC_ZPTY_ENABLED}" >&2
}

# -----------------------------------------------------------------------------
# PUBLIC API SHORTCUT (Phase A typical sequence)
# -----------------------------------------------------------------------------
# 1) async_dispatch_init
# 2) async_launch_shadow_tasks
# 3) (Later / multiple) async_flush_cycle
# 4) async_summary

typeset -f async_dispatch_init >/dev/null 2>&1 || true

# End of file (prototype zpty worker pool included)
