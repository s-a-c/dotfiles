#!/usr/bin/env zsh
# Emergency timeout protection for shell initialization
# This should be sourced early to wrap potentially hanging operations

# Define timeout wrapper if not available
if ! command -v timeout >/dev/null 2>&1; then
    # Simple timeout implementation using background job
    timeout() {
        local duration="$1"
        shift
        ( "$@" ) & local pid=$!
        ( sleep "$duration" && kill -TERM $pid 2>/dev/null ) & local timer=$!
        if wait $pid 2>/dev/null; then
            kill -TERM $timer 2>/dev/null
            wait $timer 2>/dev/null
            return 0
        else
            return 124
        fi
    }
fi

# Export for use in other scripts
export -f timeout 2>/dev/null || true

# Set emergency flags if initialization is taking too long
if [[ -n "${ZSH_INIT_TIMEOUT:-}" ]]; then
    export NO_ZGENOM=1
    export SKIP_PLUGINS=1
    export SKIP_EXTERNAL_TOOLS=1
    zsh_debug_echo "# [timeout-protection] Emergency mode activated"
fi
