#!/usr/bin/env zsh
# PATH Resolution Fix - Early Loading
# Ensures PATH is properly set before any plugin loading

# Prevent multiple loading
if [[ -n "${_PATH_RESOLUTION_FIXED:-}" ]]; then
    return 0
fi

# Ensure critical paths are available early
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:$PATH"

# Cache command locations to avoid repeated lookups during loading
if command -v fzf >/dev/null 2>&1; then
    export FZF_COMMAND="$(command -v fzf)"
fi

if command -v bat >/dev/null 2>&1; then
    export BAT_COMMAND="$(command -v bat)"
fi

# Mark as completed
export _PATH_RESOLUTION_FIXED=1
