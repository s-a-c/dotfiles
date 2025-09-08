#!/bin/zsh
# 70-shim-removal.zsh - Runtime-only shim disabling for ZSH redesign evaluation
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

# Guard: Only run if redesign is enabled
[[ "${ZSH_USE_REDESIGN:-0}" != "1" ]] && return 0

# Sentinel guard for redesign module
_LOADED_70_SHIM_REMOVAL=1
# Performance timing start
local _shim_removal_start_time=$EPOCHREALTIME

# Runtime shim disabling (non-destructive evaluation only)
# NOTE: This module provides RUNTIME-ONLY shim disabling for evaluation purposes.
# No files are removed from disk. On-disk shim removal requires separate explicit approval.

# Shim detection and runtime disabling
local shimmed_commands=()
local disabled_count=0

# Check for common shimmed commands and disable them at runtime
_disable_shim_runtime() {
    local cmd="$1"
    local original_path="$2"

    if command -v "$cmd" >/dev/null 2>&1; then
        local current_path=$(command -v "$cmd")

        # Check if this appears to be a shim (common shim patterns)
        if [[ "$current_path" =~ "/.local/share/" ]] || \
           [[ "$current_path" =~ "/shims/" ]] || \
           [[ "$current_path" =~ "/.asdf/" ]] || \
           [[ "$current_path" =~ "/.mise/" ]] || \
           [[ "$current_path" =~ "/.rtx/" ]]; then

            shimmed_commands+=("$cmd:$current_path")

            # Runtime disable by aliasing to original path (if known)
            if [[ -n "$original_path" ]] && [[ -x "$original_path" ]]; then
                alias "$cmd"="$original_path"
                ((disabled_count++))
            fi
        fi
    fi
}

# Common commands that are often shimmed
_disable_shim_runtime "node" "/usr/local/bin/node"
_disable_shim_runtime "npm" "/usr/local/bin/npm"
_disable_shim_runtime "python" "/usr/bin/python3"
_disable_shim_runtime "pip" "/usr/local/bin/pip3"
_disable_shim_runtime "ruby" "/usr/bin/ruby"
_disable_shim_runtime "gem" "/usr/bin/gem"
_disable_shim_runtime "java" "/usr/bin/java"

# Report findings (only in debug mode)
if [[ "${ZSH_DEBUG_SHIM_REMOVAL:-0}" == "1" ]]; then
    echo "[SHIM-REMOVAL] Detected ${#shimmed_commands[@]} shimmed commands"
    echo "[SHIM-REMOVAL] Runtime disabled: ${disabled_count} commands"
    if [[ ${#shimmed_commands[@]} -gt 0 ]]; then
        echo "[SHIM-REMOVAL] Shimmed commands found:"
        printf '  %s\n' "${shimmed_commands[@]}"
    fi
fi

# Set sentinel for shim removal completion
export _ZSH_SHIM_REMOVAL_DONE=1

# Performance timing end
local _shim_removal_end_time=$EPOCHREALTIME
export ZSH_PERF_SHIM_REMOVAL_TIME=$(( (_shim_removal_end_time - _shim_removal_start_time) * 1000 ))

# Cleanup function
unfunction _disable_shim_runtime 2>/dev/null || true
