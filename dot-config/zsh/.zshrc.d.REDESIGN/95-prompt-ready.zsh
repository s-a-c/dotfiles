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
