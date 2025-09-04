# 95-prompt-ready.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Capture the moment the shell becomes visually "ready" (first prompt render) and
#   emit a structured marker consumable by performance tooling (perf-capture.zsh).
#   This augments existing PRE / POST segment timing to include interactive readiness.
#
# MARKERS EMITTED (when enabled):
#   PROMPT_READY_COMPLETE <delta_ms>
#     <delta_ms> = milliseconds elapsed between PRE_PLUGIN_END_MS (if available)
#                  and the first prompt display. If PRE_PLUGIN_END_MS not present,
#                  falls back to PRE_PLUGIN_START_MS or absolute monotonic ms stamp.
#
# EXPORTED VARIABLES:
#   PROMPT_READY_REALTIME      Floating seconds (EPOCHREALTIME) when prompt first rendered.
#   PROMPT_READY_MS            Absolute ms timestamp (epoch-based) of first prompt render.
#   PROMPT_READY_DELTA_MS      Delta ms to PRE_PLUGIN_END_MS (preferred) or PRE_PLUGIN_START_MS.
#   PROMPT_READY_FROM_START_MS Delta ms from PRE_PLUGIN_START_MS (if both available).
#
# CONFIG / FLAGS:
#   ZSH_PERF_PROMPT_MARKERS=1   (default) Enable prompt readiness capture.
#   Set ZSH_PERF_PROMPT_MARKERS=0 to disable instrumentation (no markers emitted).
#
# SAFETY / IDP:
#   - Idempotent: instrumentation hook self-cleans after first invocation.
#   - Minimal overhead: single arithmetic + optional file append.
#
# DEPENDENCIES:
#   - Relies on zsh/datetime for EPOCHREALTIME (best-effort fallback if unavailable).
#
# FAILURE MODES:
#   - If zmodload fails or EPOCHREALTIME unavailable, variables may be blank and marker omitted.
#   - All failures are silent (no hard abort) to avoid impacting interactive shell.
#
# FUTURE EXTENSIONS:
#   - Additional marker: INTERACTIVE_READY_COMPLETE (post first command latency).
#   - Aggregation of prompt latency variance across sessions.
#
# -----------------------------------------------------------------------------

# Guard: prevent double load
[[ -n ${_LOADED_PROMPT_READY_MODULE:-} ]] && return
_LOADED_PROMPT_READY_MODULE=1

# Early opt-out
if [[ "${ZSH_PERF_PROMPT_MARKERS:-1}" == "0" ]]; then
    return 0
fi

# Provide a quiet debug echo if global helper is absent
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Utility: convert EPOCHREALTIME => integer milliseconds
__pr__epoch_to_ms() {
    # Input: $1 (float seconds) or reads from $EPOCHREALTIME
    local val="${1:-$EPOCHREALTIME}"
    # Fallback: if empty return blank
    [[ -z $val ]] && return 0
    print -r -- "$val" | awk -F. '{ms = ($1 * 1000); if (NF>1) { ms += substr($2 "000",1,3)+0 } printf "%d", ms }' 2>/dev/null
}

# We apply an add-zsh-hook precmd if available; fallback to wrapper
__pr__install_method="adhoc"

if autoload -Uz add-zsh-hook 2>/dev/null; then
    __pr__install_method="add-zsh-hook"
fi

# Core capture function (executed exactly once)
__pr__capture_prompt_ready() {
    # Prevent re-entry
    [[ -n ${PROMPT_READY_MS:-} ]] && return 0

    zmodload zsh/datetime 2>/dev/null || true
    local now_rt=$EPOCHREALTIME
    local now_ms
    now_ms=$(__pr__epoch_to_ms "$now_rt")

    PROMPT_READY_REALTIME="$now_rt"
    PROMPT_READY_MS="$now_ms"
    export PROMPT_READY_REALTIME PROMPT_READY_MS

    local base_ms=""
    local delta_ref="PRE_PLUGIN_END_MS"
    if [[ -n ${PRE_PLUGIN_END_MS:-} ]]; then
        base_ms=$PRE_PLUGIN_END_MS
    elif [[ -n ${PRE_PLUGIN_START_MS:-} ]]; then
        base_ms=$PRE_PLUGIN_START_MS
        delta_ref="PRE_PLUGIN_START_MS"
    fi

    if [[ -n $base_ms && -n $now_ms ]]; then
        ((PROMPT_READY_DELTA_MS = now_ms - base_ms))
        export PROMPT_READY_DELTA_MS
    fi

    if [[ -n ${PRE_PLUGIN_START_MS:-} && -n $now_ms ]]; then
        ((PROMPT_READY_FROM_START_MS = now_ms - PRE_PLUGIN_START_MS))
        export PROMPT_READY_FROM_START_MS
    fi

    # Emit marker if we have a computed delta
    if [[ -n ${PROMPT_READY_DELTA_MS:-} && -n ${PERF_SEGMENT_LOG:-} ]]; then
        {
            print "PROMPT_READY_COMPLETE ${PROMPT_READY_DELTA_MS}"
            print "SEGMENT name=prompt_ready ms=${PROMPT_READY_DELTA_MS} phase=prompt sample=${PERF_SAMPLE_CONTEXT:-unknown}"
        } >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi

    zsh_debug_echo "# [prompt-ready][perf] PROMPT_READY_MS=$PROMPT_READY_MS delta_ref=$delta_ref delta=${PROMPT_READY_DELTA_MS:-n/a} from_start=${PROMPT_READY_FROM_START_MS:-n/a}"

    # Harness: auto-exit after first prompt timing (used by interactive perf harness)
    # Set PERF_PROMPT_HARNESS=1 to enable. Exits after marker emission to allow
    # external runner to measure real prompt latency without manual intervention.
    if [[ "${PERF_PROMPT_HARNESS:-0}" == "1" ]]; then
        zsh_debug_echo "# [prompt-ready][harness] exiting shell after prompt readiness capture"
        # Use builtin exit to avoid triggering additional traps/hooks
        builtin exit
    fi

    # If we injected a temporary precmd wrapper (adhoc mode), remove it
    if [[ ${__pr__install_method} == "adhoc" ]]; then
        unset -f precmd 2>/dev/null || true
    fi

    # Cleanup installer symbols (leave exported timing vars)
    unset -f __pr__capture_prompt_ready __pr__epoch_to_ms
}

if [[ ${__pr__install_method} == "add-zsh-hook" ]]; then
    add-zsh-hook precmd __pr__capture_prompt_ready 2>/dev/null || {
        # Fallback to adhoc if hook registration fails
        __pr__install_method="adhoc"
    }
fi

# Fallback adhoc precmd definition if hook system unavailable
if [[ ${__pr__install_method} == "adhoc" ]]; then
    if typeset -f precmd >/dev/null 2>&1; then
        # Wrap existing precmd
        eval "precmd() { __pr__capture_prompt_ready; $(typeset -f precmd | sed '1d;$d'); }"
    else
        # Simple precmd
        precmd() { __pr__capture_prompt_ready; }
    fi
fi

zsh_debug_echo "# [prompt-ready] instrumentation installed method=${__pr__install_method}"

# ---------------------------------------------------------------------------
# Forced / Deferred precmd trigger logic (addresses non-render environments)
# CONFIG:
#   PERF_FORCE_PRECMD=1              Force an early synthetic precmd trigger (after short delay) if no readiness yet.
#   PERF_PROMPT_DEFERRED_CHECK=1     Enable a secondary deferred check (default 1).
#   PERF_PROMPT_FORCE_DELAY_MS=50    Delay before forced precmd (default 50ms).
#   PERF_PROMPT_DEFERRED_DELAY_MS=250 Delay before deferred fallback capture (default 250ms).
# RATIONALE:
#   In headless harnesses (stdin redirected, no real prompt render) precmd may never
#   fire. We schedule lightweight background checks that invoke the capture function
#   if readiness markers are still absent, producing a deterministic non‑zero value.
# ---------------------------------------------------------------------------

: ${PERF_PROMPT_FORCE_DELAY_MS:=50}
: ${PERF_PROMPT_DEFERRED_DELAY_MS:=250}

# Early synthetic precmd trigger (short delay)
if [[ "${PERF_FORCE_PRECMD:-0}" == "1" && -z ${PROMPT_READY_MS:-} ]]; then
  {
    sleep "$(printf '%.3f' "$((PERF_PROMPT_FORCE_DELAY_MS))/1000")"
    if [[ -z ${PROMPT_READY_MS:-} ]]; then
      zsh_debug_echo "# [prompt-ready][force] forcing early capture (no prompt yet)"
      __pr__capture_prompt_ready
    fi
  } &!
fi

# Deferred fallback capture (longer delay) if still missing
if [[ "${PERF_PROMPT_DEFERRED_CHECK:-1}" == "1" && -z ${PROMPT_READY_MS:-} ]]; then
  {
    sleep "$(printf '%.3f' "$((PERF_PROMPT_DEFERRED_DELAY_MS))/1000")"
    if [[ -z ${PROMPT_READY_MS:-} ]]; then
      zsh_debug_echo "# [prompt-ready][deferred] readiness still missing; capturing approximate"
      __pr__capture_prompt_ready
    fi
  } &!
fi

# Fallback: In scenarios like 'zsh -i -c "exit"' the precmd hook never fires, so
# prompt readiness is never captured. If a command execution string is present
# and we have not yet recorded PROMPT_READY_MS, approximate readiness now so
# perf-capture can still record a non-zero prompt segment.
if [[ -n ${ZSH_EXECUTION_STRING:-} && -z ${PROMPT_READY_MS:-} ]]; then
    zmodload zsh/datetime 2>/dev/null || true
    now_rt=$EPOCHREALTIME
    now_ms=$(__pr__epoch_to_ms "$now_rt")
    PROMPT_READY_REALTIME=$now_rt
    PROMPT_READY_MS=$now_ms
    export PROMPT_READY_REALTIME PROMPT_READY_MS
    if [[ -n ${PRE_PLUGIN_END_MS:-} ]]; then
        ((PROMPT_READY_DELTA_MS = PROMPT_READY_MS - PRE_PLUGIN_END_MS))
        export PROMPT_READY_DELTA_MS
    elif [[ -n ${PRE_PLUGIN_START_MS:-} ]]; then
        ((PROMPT_READY_DELTA_MS = PROMPT_READY_MS - PRE_PLUGIN_START_MS))
        export PROMPT_READY_DELTA_MS
    fi
    if [[ -n ${PROMPT_READY_DELTA_MS:-} && -n ${PERF_SEGMENT_LOG:-} ]]; then
        {
            print "PROMPT_READY_COMPLETE ${PROMPT_READY_DELTA_MS}"
            print "SEGMENT name=prompt_ready ms=${PROMPT_READY_DELTA_MS} phase=prompt sample=${PERF_SAMPLE_CONTEXT:-unknown}"
        } >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [prompt-ready][perf][fallback] PROMPT_READY_MS=${PROMPT_READY_MS} delta=${PROMPT_READY_DELTA_MS:-n/a}"
fi

# -----------------------------------------------------------------------------
# End of 95-prompt-ready.zsh
