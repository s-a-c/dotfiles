#!/usr/bin/env zsh
# Core Functions - Essential utility functions
# This file provides core utility functions needed throughout the shell
# Load time target: <30ms

# Prevent function nesting errors and conditionally disable verbose output
export FUNCNEST=500  # Increased for starship prompt
if [[ -z "$ZSH_DEBUG_VERBOSE" ]]; then
    setopt NO_VERBOSE
    setopt NO_XTRACE
    setopt NO_FUNCTION_ARGZERO
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
    zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
}

# PATH management functions are defined in .zshenv and should not be redefined
# The _path_prepend, _path_append, and _path_remove functions are available globally
# from .zshenv and must not be duplicated to avoid conflicts.

# PATH validation and cleanup
path_validate() {
    local invalid_paths=()
    local valid_paths=()
    local dir

    # Split PATH and validate each directory
    IFS=':' read -rA path_array <<< "$PATH"
    for dir in "${path_array[@]}"; do
        if [[ -d "$dir" ]]; then
            valid_paths+=("$dir")
        else
            invalid_paths+=("$dir")
        fi
    done

    # Report invalid paths only when PATH_DEBUG is set
    if [[ -n "$PATH_DEBUG" && ${#invalid_paths[@]} -gt 0 ]]; then
        zsh_debug_echo "# [path] Invalid PATH entries removed: ${invalid_paths[*]}"
    fi

    # Rebuild PATH with only valid directories
    PATH=$(IFS=':'; zsh_debug_echo "${valid_paths[*]}")
    export PATH
}

# Quick directory existence check
dir_exists() {
    [[ -d "$1" ]]
}

# Command existence check with caching
# NOTE: Using has_command() from .zshenv instead of duplicate implementation
# This provides the same functionality with a standardized cache system
# The has_command() function is available globally and should be used instead

# Legacy alias for compatibility (maps to standardized has_command)
command_exists() {
    has_command "$@"
}

# Fast file sourcing with error handling - REMOVED
# Using comprehensive version from 00_02-standard-helpers.zsh instead

# Environment variable default setting
env_default() {
    local var="$1" default="$2"
    [[ -z "${(P)var}" ]] && export "$var"="$default"
}

# Clean up function cache (useful for debugging)
clear_command_cache() {
    # Clear the standardized cache from .zshenv
    if declare -A _zsh_command_cache >/dev/null 2>&1; then
        # Clear command cache entries
        _zsh_command_cache=()
        zsh_debug_echo "# [functions] Command cache cleared"
    fi
}

# Performance timing utility
time_function() {
    local func="$1"
    shift
    local start_time=$SECONDS
    "$func" "$@"
    local end_time=$SECONDS
    local duration=$((end_time - start_time))
    zsh_debug_echo "# [timing] $func took ${duration}s"
    return $?
}

# Export core functions for global use
# NOTE: _path_* functions are defined and exported in .zshenv
{
    typeset -gf path_validate dir_exists command_exists safe_source env_default
    typeset -gf clear_command_cache time_function
} >/dev/null 2>&1

zsh_debug_echo "# [00-core] Core functions loaded"
