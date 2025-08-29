#!/usr/bin/env zsh
# PATH Guarantee for Deferred Loading Scripts
# Ensures system commands are available during early initialization
# Author: Configuration Management System
# Created: 2025-08-26

# 1. Establish minimal safe PATH immediately
#=============================================================================

# Define minimal PATH if not already set or insufficient
if [[ -z "$PATH" ]] || ! command -v date >/dev/null 2>&1; then
    export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
fi

# 2. Create safe command wrappers for deferred scripts
#=============================================================================

# Wrapper function that tries common locations for commands
safe_command() {
    local cmd="$1"
    shift

    # Try command as-is first (uses PATH)
    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" "$@"
        return $?
    fi

    # Try common system locations
    local locations=(
        "/usr/bin/$cmd"
        "/bin/$cmd"
        "/opt/homebrew/bin/$cmd"
        "/usr/local/bin/$cmd"
    )

    for location in "${locations[@]}"; do
        if [[ -x "$location" ]]; then
            "$location" "$@"
            return $?
        fi
    done

        zsh_debug_echo "Error: Command '$cmd' not found in PATH or standard locations"
    return 1
}

# 3. Export safe wrappers for common commands used in deferred scripts
#=============================================================================

safe_date() { safe_command date "$@"; }
safe_mkdir() { safe_command mkdir "$@"; }
safe_dirname() { safe_command dirname "$@"; }
safe_basename() { safe_command basename "$@"; }
safe_readlink() { safe_command readlink "$@"; }

# 4. PATH construction helper for deferred contexts
#=============================================================================

# Function to ensure PATH is properly constructed in deferred contexts
ensure_full_path() {
    # Skip if PATH is already comprehensive (contains homebrew)
    [[ "$PATH" == *"/opt/homebrew/bin"* ]] && return 0

    # Reconstruct PATH by calling path_dedupe if available
    if typeset -f path_dedupe >/dev/null 2>&1; then
        path_dedupe
    else
        # Fallback: basic PATH construction
        local new_path="/opt/homebrew/bin:/opt/homebrew/sbin"
        new_path="$new_path:/usr/local/bin:/usr/local/sbin"
        new_path="$new_path:/usr/bin:/bin:/usr/sbin:/sbin"

        # Add XDG_BIN_HOME if available
        [[ -n "$XDG_BIN_HOME" && -d "$XDG_BIN_HOME" ]] && new_path="$XDG_BIN_HOME:$new_path"

        export PATH="$new_path"
    fi
}

# 5. Debug helper for PATH issues
#=============================================================================

debug_path_state() {
    [[ "$ZSH_DEBUG" != "1" ]] && return 0

        zsh_debug_echo "[PATH DEBUG] Current PATH: $PATH"
        zsh_debug_echo "[PATH DEBUG] date location: $(command -v date 2>/dev/null || zsh_debug_echo 'NOT FOUND')"
        zsh_debug_echo "[PATH DEBUG] mkdir location: $(command -v mkdir 2>/dev/null || zsh_debug_echo 'NOT FOUND')"
}

# Log initialization
zsh_debug_echo "[PATH-GUARANTEE] Safe command wrappers initialized"
