#!/usr/bin/env zsh
# 95-prompt-ready.zsh - FIXED VERSION
# Prompt readiness tracking without background jobs that can cause hangs

# Guard: prevent double load
[[ -n ${_LOADED_PROMPT_READY_MODULE:-} ]] && return
_LOADED_PROMPT_READY_MODULE=1

# Early opt-out
if [[ "${ZSH_PERF_PROMPT_MARKERS:-1}" == "0" ]]; then
    return 0
fi

# Provide a quiet debug echo if global helper is absent
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Simplified prompt ready capture without background jobs
__pr__capture_prompt_ready() {
    # Prevent re-entry
    [[ -n ${PROMPT_READY_MS:-} ]] && return 0

    # Capture timing if available
    if command -v date >/dev/null 2>&1; then
        PROMPT_READY_MS=$(date +%s%3N 2>/dev/null || date +%s000)
        export PROMPT_READY_MS
    fi

    # Emit SEGMENT + legacy marker (idempotent) if log available
    if [[ -n ${PERF_SEGMENT_LOG:-} && -w ${PERF_SEGMENT_LOG:-/dev/null} && -n ${PROMPT_READY_MS:-} && -z ${_PROMPT_READY_SEGMENT_EMITTED:-} ]]; then
        # Attempt delta computation if start anchor available
        if [[ -n ${ZSH_START_MS:-} ]]; then
            (( PROMPT_READY_DELTA_MS = PROMPT_READY_MS - ZSH_START_MS ))
        else
            PROMPT_READY_DELTA_MS=0
        fi
        {
            print "PROMPT_READY_COMPLETE ${PROMPT_READY_DELTA_MS}"
            print "SEGMENT name=prompt_ready ms=${PROMPT_READY_DELTA_MS} phase=prompt sample=${PERF_SAMPLE_CONTEXT:-unknown}"
        } >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
        _PROMPT_READY_SEGMENT_EMITTED=1
    fi

    # Structured telemetry JSON (opt-in; zero overhead when ZSH_LOG_STRUCTURED!=1)
    if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" && -n ${PROMPT_READY_MS:-} && -z ${_PROMPT_READY_JSON_EMITTED:-} ]]; then
        # Ensure delta computed (reuse if already set)
        if [[ -z ${PROMPT_READY_DELTA_MS:-} ]]; then
            if [[ -n ${ZSH_START_MS:-} ]]; then
                (( PROMPT_READY_DELTA_MS = PROMPT_READY_MS - ZSH_START_MS ))
            else
                PROMPT_READY_DELTA_MS=0
            fi
        fi
        # Timestamp (epoch ms) from EPOCHREALTIME if available
        local __pr_ts
        if [[ -n ${EPOCHREALTIME:-} ]]; then
            __pr_ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
        else
            __pr_ts="$(date +%s 2>/dev/null || printf 0)000"
        fi
        local __target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}}"
        if [[ -w ${__target} ]]; then
            print -- "{\"type\":\"segment\",\"name\":\"prompt_ready\",\"ms\":${PROMPT_READY_DELTA_MS},\"phase\":\"prompt\",\"sample\":\"${PERF_SAMPLE_CONTEXT:-unknown}\",\"ts\":${__pr_ts}}" >> "${__target}" 2>/dev/null || true
        fi
        _PROMPT_READY_JSON_EMITTED=1
    fi

    zsh_debug_echo "# [prompt-ready] captured PROMPT_READY_MS=${PROMPT_READY_MS:-n/a}"
}

# Install hook if possible
if autoload -Uz add-zsh-hook 2>/dev/null; then
    add-zsh-hook precmd __pr__capture_prompt_ready 2>/dev/null || true
elif typeset -f precmd >/dev/null 2>&1; then
    # Wrap existing precmd
    eval "precmd() { __pr__capture_prompt_ready; $(typeset -f precmd | sed '1d;$d'); }"
else
    # Simple precmd
    precmd() { __pr__capture_prompt_ready; }
fi

# NO BACKGROUND JOBS - they can cause hangs in non-interactive shells
# All sleep-based deferred checks have been removed

zsh_debug_echo "# [prompt-ready] simplified instrumentation installed (no background jobs)"
