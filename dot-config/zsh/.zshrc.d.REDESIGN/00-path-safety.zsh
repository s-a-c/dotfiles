#!/usr/bin/env zsh
# ==============================================================================
# 00-PATH-SAFETY.ZSH - Comprehensive Path Management (REDESIGN v2)
# ==============================================================================
# Purpose: Consolidates all PATH-related safety, resolution, and enhancement
# Consolidates: critical-path-fix + path-resolution-fix + path-guarantee + path-enhancements
# Load Order: CRITICAL - Must be first (00-) to establish safe PATH immediately
# Author: ZSH Configuration Redesign System
# Created: 2025-09-21
# Version: 2.2.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_PATH_SAFETY_LOADED:-}" ]]; then
    return 0
fi
export _PATH_SAFETY_LOADED=1

# Auto-load core infrastructure if not available
if [[ -z "${_CORE_INFRASTRUCTURE_REDESIGN:-}" ]] && [[ -f "${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh"
fi

# Use direct zf:: debug calls
zf::debug "[PATH-SAFETY] Loading comprehensive PATH safety system (v2.2.0)"

# ==============================================================================
# SECTION 1: CORRUPTION DETECTION AND EMERGENCY REPAIR
# ==============================================================================
# Based on: 00_00-critical-path-fix.zsh

# Emergency PATH corruption detection and repair
if [[ ${#PATH} -gt 5000 ]]; then
    zf::debug "[PATH-SAFETY] ⚠️  PATH corruption detected (${#PATH} chars) - initiating emergency repair"

    # Emergency deduplication using zsh array uniqueness
    local -a emergency_path
    IFS=':' read -rA emergency_path <<< "$PATH"
    typeset -U emergency_path
    export PATH="${(j.:.)emergency_path}"

    [[ -n "${ZSH_DEBUG:-}" ]] && echo "[PATH-SAFETY] ✅ Emergency PATH repair completed (reduced to ${#PATH} chars)" || true
fi

# ==============================================================================
# SECTION 2: SMART PATH FOUNDATION WITH BASELINE PRESERVATION
# ==============================================================================
# Enhanced from: path-guarantee + path-resolution + current path-safety

# Strategy: Preserve .zshenv baseline if available, otherwise establish clean foundation
if [[ -n "${ZQS_BASELINE_PATH_SNAPSHOT:-}" ]]; then
    zf::debug "[PATH-SAFETY] Preserving .zshenv PATH baseline, applying intelligent merge"

    # Essential paths that must be available for safe operation
    local -a essential_paths=(
        "/opt/homebrew/bin"        # Homebrew primary (macOS)
        "/opt/homebrew/sbin"       # Homebrew system binaries
        "/usr/local/bin"           # Local installations
        "/usr/local/sbin"          # Local system binaries
        "/usr/bin"                 # System binaries
        "/bin"                     # Core system binaries
        "/usr/sbin"                # System administration
        "/sbin"                    # Core system administration
    )

    # Current PATH components for deduplication check
    local -a current_path
    IFS=':' read -rA current_path <<< "$PATH"

    # Merge missing essential paths (preserves order, adds only what's missing)
    for essential_dir in "${essential_paths[@]}"; do
        if [[ -n "$essential_dir" ]] && [[ -d "$essential_dir" ]] && [[ ${current_path[(Ie)$essential_dir]} -eq 0 ]]; then
            path+=("$essential_dir")
            zf::debug "[PATH-SAFETY] Merged missing essential path: $essential_dir"
        fi
    done
else
    zf::debug "[PATH-SAFETY] No .zshenv baseline found - establishing clean PATH foundation"

    # Clean PATH establishment with priority ordering
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

    # Add user-specific directories if they exist
    [[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH" && zf::debug "[PATH-SAFETY] Added ~/.local/bin"
    [[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH" && zf::debug "[PATH-SAFETY] Added ~/bin"
fi

# ==============================================================================
# SECTION 3: HOMEBREW PATH ENHANCEMENT
# ==============================================================================
# Based on: 05-path-enhancements.zsh

# Homebrew-specific path management (only add what's missing)
if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix 2>/dev/null)

    if [[ -n "$BREW_PREFIX" ]]; then
        # Only add Homebrew sbin if not already present and directory exists
        if [[ -d "${BREW_PREFIX}/sbin" ]] && [[ ":$PATH:" != *":${BREW_PREFIX}/sbin:"* ]]; then
            # Prepend to maintain Homebrew priority
            export PATH="${BREW_PREFIX}/sbin:$PATH"
            zf::debug "[PATH-SAFETY] Enhanced PATH with Homebrew sbin: ${BREW_PREFIX}/sbin"
        fi

        # Homebrew bin is typically already prioritized in .zshenv, so we skip it
        # unless it's somehow missing
        if [[ -d "${BREW_PREFIX}/bin" ]] && [[ ":$PATH:" != *":${BREW_PREFIX}/bin:"* ]]; then
            export PATH="${BREW_PREFIX}/bin:$PATH"
            zf::debug "[PATH-SAFETY] Enhanced PATH with missing Homebrew bin: ${BREW_PREFIX}/bin"
        fi
    fi
fi

# ==============================================================================
# SECTION 4: COMMAND RESOLUTION CACHE
# ==============================================================================
# Based on: 00_01-path-resolution-fix.zsh

# Cache critical command locations to avoid repeated lookups during loading
if command -v fzf >/dev/null 2>&1; then
    export FZF_COMMAND="$(command -v fzf)"
    zf::debug "[PATH-SAFETY] Cached FZF location: $FZF_COMMAND"
fi

if command -v bat >/dev/null 2>&1; then
    export BAT_COMMAND="$(command -v bat)"
    zf::debug "[PATH-SAFETY] Cached BAT location: $BAT_COMMAND"
fi

if command -v eza >/dev/null 2>&1; then
    export EZA_COMMAND="$(command -v eza)"
    zf::debug "[PATH-SAFETY] Cached EZA location: $EZA_COMMAND"
fi

# ==============================================================================
# SECTION 5: SAFE COMMAND WRAPPERS
# ==============================================================================
# Based on: 00_05-path-guarantee.zsh

# ==============================================================================
# CONSOLIDATED FUNCTION INTEGRATION
# ==============================================================================
# Path safety functionality now consolidated into zf:: namespace
# This provides backward compatibility wrappers

# Backward compatibility wrapper - use consolidated zf:: function
safe_command() {
    zf::path_safe_command "$@"
}

# Backward compatibility wrappers for safe command variants
safe_date() { zf::safe_date "$@"; }
safe_mkdir() { zf::safe_mkdir "$@"; }
safe_dirname() { zf::safe_dirname "$@"; }
safe_basename() { zf::safe_basename "$@"; }
safe_readlink() { zf::safe_readlink "$@"; }

# ==============================================================================
# SECTION 6: PATH VALIDATION AND FINALIZATION
# ==============================================================================

# Final PATH validation and cleanup (SAFE VERSION)
zf::debug "[PATH-SAFETY] Performing final PATH validation and cleanup"

# Work directly with PATH string to avoid array synchronization issues
local original_path="$PATH"
local -a path_components=()
IFS=':' read -rA path_components <<< "$PATH"

# Remove empty entries and invalid directories
local -a valid_path_components=()
local removed_count=0

for dir in "${path_components[@]}"; do
    if [[ -n "$dir" ]]; then
        valid_path_components+=("$dir")
    else
        ((removed_count++))
    fi
done

if [[ $removed_count -gt 0 ]]; then
    export PATH="$(IFS=':'; echo "${valid_path_components[*]}")"
    zf::debug "[PATH-SAFETY] Removed $removed_count empty path entries"
fi

# Simple deduplication using ZSH built-in method
local -a unique_path_components=()
IFS=':' read -rA unique_path_components <<< "$PATH"
typeset -U unique_path_components
export PATH="$(IFS=':'; echo "${unique_path_components[*]}")"

# Ensure path array stays synchronized (this is safe)
path=("${unique_path_components[@]}")

# Rebuild command hash table
rehash
zf::debug "[PATH-SAFETY] Command hash table rebuilt"

# ==============================================================================
# SECTION 7: PROMPT SAFETY INITIALIZATION
# ==============================================================================
# Prevent plugin errors from undefined prompt variables

# Ensure all prompt-related variables exist (prevents parameter not set errors)
: ${RPS1:=""}
: ${RPS2:=""}
: ${RPS3:=""}
: ${RPS4:=""}
: ${RPS5:=""}
: ${RPROMPT:=""}
: ${PROMPT:=""}
: ${PS1:="%m%# "}
: ${PS2:="> "}
: ${PS3:="?# "}
: ${PS4:="+%N:%i> "}

zf::debug "[PATH-SAFETY] Prompt variables initialized for plugin safety"

# ==============================================================================
# NAMESPACE MIGRATION COMPLETE
# ==============================================================================
# All functions have been migrated to the zf:: namespace.
# Use zf::ensure_cmd instead of can_haz
# Use zf::debug instead of zf::debug
# Use zf::ssh_ensure_agent instead of ensure_ssh_agent
# Use zf::perf_checkpoint instead of perf_checkpoint
# etc.

# Essential compatibility wrappers for critical functions only
can_haz() { zf::ensure_cmd "$@"; }  # Keep for backward compatibility
# Legacy debug wrapper - use direct echo for now
zf::debug() { [[ -n "${ZSH_DEBUG:-}" ]] && echo "[DEBUG] $*" || true; }

# Mark namespace migration complete
export _ZF_NAMESPACE_MIGRATION_COMPLETE=1
zf::debug "[PATH-SAFETY] Namespace migration complete - use zf:: functions directly"

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export PATH_SAFETY_REDESIGN_VERSION="2.2.0"
export PATH_SAFETY_REDESIGN_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

zf::debug "[PATH-SAFETY] Comprehensive PATH safety system ready (${#path[@]} directories in PATH)"

# Legacy functions removed - using zf:: namespace directly

# ==============================================================================
# END OF PATH SAFETY MODULE
# ==============================================================================
