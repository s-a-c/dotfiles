#!/usr/bin/env zsh
# ==============================================================================
# ZSH Pre-Plugin Module: Path Safety
# ==============================================================================
# Purpose: Initialize PATH safety and ensure baseline protection
# Dependencies: .zshenv (for ZQS_BASELINE_PATH_SNAPSHOT)
# Load Order: 00/XX (first - before any PATH manipulation)
# Author: ZSH Configuration System
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_PATH_SAFETY_LOADED:-}" ]]; then
    return 0
fi
export _PATH_SAFETY_LOADED=1

# Debug helper - early stage, minimal logging
_path_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && echo "[PATH-SAFETY] $1" >&2
}

_path_debug "Loading path safety module..."

# ==============================================================================
# SECTION 0: PROMPT VARIABLE SAFETY
# ==============================================================================
# Purpose: Ensure all RPS* and prompt variables are defined before any plugins load
# This prevents "parameter not set" errors from Oh My Zsh and other plugins
# that may reference these variables unconditionally during async operations

# Ensure all RPS variables exist (even if .zshenv already initialized them)
# Use conditional assignment to avoid overriding existing values
: ${RPS1:=""}
: ${RPS2:=""}
: ${RPS3:=""}
: ${RPS4:=""}
: ${RPS5:=""}
: ${RPROMPT:=""}
: ${PROMPT:=""}

# Additional prompt-related variables that might be referenced
: ${PS1:="%m%# "}
: ${PS2:="> "}
: ${PS3:="?# "}
: ${PS4:="+%N:%i> "}

_path_debug "Prompt variables initialized for plugin safety"

# ==============================================================================
# SECTION 1: PATH BASELINE PROTECTION
# ==============================================================================
# Purpose: Ensure PATH never regresses below .zshenv baseline

_path_debug "Protecting PATH baseline..."

# Ensure path array exists
typeset -a path

# Merge baseline entries back if any are missing
if [[ -n ${ZQS_BASELINE_PATH_SNAPSHOT-} ]]; then
    local -a want have
    want=("${(s.:.)ZQS_BASELINE_PATH_SNAPSHOT}")
    have=("${path[@]}")
    for d in "${want[@]}"; do
        if [[ -n $d ]] && [[ ${have[(Ie)$d]} -eq 0 ]]; then
            path+=("$d")
        fi
    done
    # Unique-ify without removing any unique baseline entry
    typeset -Ua path
    export PATH="${(j.:.)path}"
    hash -r
    _path_debug "Merged baseline PATH protection (${#path[@]} total directories)"
fi

# ==============================================================================
# SECTION 2: PATH SAFETY CORE
# ==============================================================================
# Purpose: Normalize PATH structure and ensure path array is available

_path_debug "Initializing PATH safety..."

# Ensure path array is properly initialized and synchronized with PATH
if [[ -z "${path:-}" ]]; then
    # Initialize path array from PATH if not already set
    typeset -a path
    path=("${(s.:.)PATH}")
    _path_debug "Initialized path array from PATH"
fi

# Ensure PATH and path are synchronized
if [[ "${(j.:.)path}" != "$PATH" ]]; then
    # Sync PATH from path array
    export PATH="${(j.:.)path}"
    _path_debug "Synchronized PATH from path array"
fi

# ==============================================================================
# SECTION 3: PATH NORMALIZATION
# ==============================================================================
# Purpose: Remove empty entries and normalize path structure

_path_debug "Normalizing PATH structure..."

# Remove empty path entries that can cause issues
local -a cleaned_path
cleaned_path=()
for dir in "${path[@]}"; do
    if [[ -n "$dir" ]]; then
        cleaned_path+=("$dir")
    fi
done

# Update arrays if we removed empty entries
if [[ ${#cleaned_path[@]} -ne ${#path[@]} ]]; then
    local removed_count=$((${#path[@]} - ${#cleaned_path[@]}))
    path=("${cleaned_path[@]}")
    export PATH="${(j.:.)path}"
    _path_debug "Removed ${removed_count} empty path entries"
fi

# ==============================================================================
# SECTION 4: EARLY PATH VALIDATION
# ==============================================================================
# Purpose: Validate critical commands are available

_path_debug "Validating critical commands..."

# Check for essential commands that should be available
local -a missing_commands
missing_commands=()
for cmd in date rg direnv; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing_commands+=("$cmd")
    fi
done

if [[ ${#missing_commands[@]} -gt 0 ]]; then
    _path_debug "INFO: Commands not in PATH: ${missing_commands[*]}"
fi

_path_debug "Path safety initialization complete (${#path[@]} directories)"

# Force command hash table rebuild after all PATH operations
# This ensures commands are properly resolved during subsequent module loading
rehash
_path_debug "Command hash table rebuilt"

# ==============================================================================
# MODULE COMPLETION MARKER
# ==============================================================================
export PATH_SAFETY_VERSION="1.0.0"
export PATH_SAFETY_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

_path_debug "Path safety module ready"

# ==============================================================================
# END OF PATH SAFETY MODULE
# ==============================================================================