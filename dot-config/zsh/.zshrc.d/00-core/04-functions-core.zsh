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
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
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
        echo "# [path] Invalid PATH entries removed: ${invalid_paths[*]}" >&2
    fi

    # Rebuild PATH with only valid directories
    PATH=$(IFS=':'; echo "${valid_paths[*]}")
    export PATH
}

# Quick directory existence check
dir_exists() {
    [[ -d "$1" ]]
}

# Command existence check with caching
typeset -gA _command_cache
command_exists() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return 1

    # Check cache first
    if [[ -n "${_command_cache[$cmd]}" ]]; then
        [[ "${_command_cache[$cmd]}" == "1" ]] && return 0 || return 1
    fi

    # Check if command exists
    if command -v "$cmd" >/dev/null 2>&1; then
        _command_cache[$cmd]="1"
        return 0
    else
        _command_cache[$cmd]="0"
        return 1
    fi
}

# Fast file sourcing with error handling
safe_source() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]] && source "$file"
}

# Environment variable default setting
env_default() {
    local var="$1" default="$2"
    [[ -z "${(P)var}" ]] && export "$var"="$default"
}

# Clean up function cache (useful for debugging)
clear_command_cache() {
    _command_cache=()
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [functions] Command cache cleared" >&2
}

# Performance timing utility
time_function() {
    local func="$1"
    shift
    local start_time=$SECONDS
    "$func" "$@"
    local end_time=$SECONDS
    local duration=$((end_time - start_time))
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [timing] $func took ${duration}s" >&2
    return $?
}

# Export core functions for global use
# NOTE: _path_* functions are defined and exported in .zshenv
{
    typeset -gf path_validate dir_exists command_exists safe_source env_default
    typeset -gf clear_command_cache time_function
} >/dev/null 2>&1

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [00-core] Core functions loaded" >&2
