#!/usr/bin/env zsh
# CRITICAL PATH FIX - Prevents PATH duplication
# This must be the very first file to load

# Prevent multiple loading
if [[ -n "${_CRITICAL_PATH_FIXED:-}" ]]; then
    return 0
fi

# Deduplicate PATH immediately if it's corrupted
if [[ ${#PATH} -gt 5000 ]]; then
    zf::debug "⚠️  Detected corrupted PATH (${#PATH} chars), fixing..."
    # Split PATH and remove duplicates
    local -a path_array
    IFS=':' read -rA path_array <<< "$PATH"
    typeset -U path_array
    export PATH="${(j.:.)path_array}"
    zf::debug "✅ PATH fixed (now ${#PATH} chars)"
fi

# Set clean, minimal PATH base
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add essential user paths if they exist
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"

# Remove duplicates one final time
typeset -U path

export _CRITICAL_PATH_FIXED=1
