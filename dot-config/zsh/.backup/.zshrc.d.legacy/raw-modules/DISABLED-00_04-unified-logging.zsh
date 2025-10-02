#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Unified Logging System
# ==============================================================================
# Purpose: Centralized logging system to replace multiple logging frameworks
#          across the ZSH configuration with consistent interface and behavior
# Author: ZSH Configuration Management System
# Created: 2025-08-26
# Version: 1.0.0
# Load Order: FIRST in 00-core (before all other modules)
# ==============================================================================

# Guard against multiple sourcing
if [[ -n "${ZSH_UNIFIED_LOGGING_LOADED:-}" ]]; then
    return 0
fi

# Set global logging version and load status
export ZSH_UNIFIED_LOGGING_VERSION="1.0.0"
export ZSH_UNIFIED_LOGGING_LOADED="$(date -u '+%FT%T %Z')"

# Logging levels (numeric for easy comparison)
typeset -gA ZSH_LOG_LEVELS
ZSH_LOG_LEVELS=(
    [DEBUG]=10
    [INFO]=20
    [WARN]=30
    [ERROR]=40
    [FATAL]=50
)

# Default log level (can be overridden by environment)
export ZSH_LOG_LEVEL="${ZSH_LOG_LEVEL:-INFO}"

# Unified logging function
zsh_log() {
    local level="$1"
    local component="$2"
    local message="$3"

    # Validate inputs
    [[ -z "$level" || -z "$component" || -z "$message" ]] && return 1

    # Check if this level should be logged
    local current_level_num="${ZSH_LOG_LEVELS[${ZSH_LOG_LEVEL:u}]:-20}"
    local msg_level_num="${ZSH_LOG_LEVELS[${level:u}]:-20}"

    # Only log if message level >= current log level
    if (( msg_level_num >= current_level_num )); then
        local timestamp=""
        if [[ "$ZSH_LOG_TIMESTAMPS" == "true" ]]; then
            timestamp="$(date -u '+%H:%M:%S') "
        fi

        local prefix="${timestamp}[${level:u}] [${component}]"

        # Use zf::debug if available (from .zshenv), otherwise echo to stderr
        if declare -f zf::debug >/dev/null 2>&1; then
            zf::debug "${prefix} ${message}"
        else
            echo "${prefix} ${message}" >&2
        fi
    fi
}

# Unified error handling function
zsh_error() {
    local component="$1"
    local message="$2"
    local exit_code="${3:-1}"

    # Log the error
    zsh_log "ERROR" "$component" "$message"

    # Use handle_error if available from helpers, otherwise basic handling
    if declare -f handle_error >/dev/null 2>&1; then
        handle_error "$component: $message" "$exit_code" "$component"
    else
        # Check if we're in a script being executed vs sourced
        if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
            exit "$exit_code"
        else
            return "$exit_code"
        fi
    fi
}

# Convenience functions for common log levels
zsh_debug() { zsh_log "DEBUG" "$1" "$2"; }
zsh_info() { zsh_log "INFO" "$1" "$2"; }
zsh_warn() { zsh_log "WARN" "$1" "$2"; }
zsh_fatal() { zsh_log "FATAL" "$1" "$2"; }

# Legacy compatibility aliases for existing logging functions
# These allow existing code to work without modification
_helpers_log() { zsh_log "INFO" "helpers" "$1"; }
_helpers_error() { zsh_error "helpers" "$1" "$2"; }
_comp_log() { zsh_log "${2:-INFO}" "completion" "$1"; }
_comp_error() { zsh_error "completion" "$1" "$2"; }
_async_log() { zsh_log "${2:-INFO}" "async" "$1"; }
_async_error() { zsh_error "async" "$1" "$2"; }
_perf_log() { zsh_log "${2:-INFO}" "performance" "$1"; }
_perf_error() { zsh_error "performance" "$1" "$2"; }

# Export functions for global use
autoload -Uz zsh_log zsh_error zsh_debug zsh_info zsh_warn zsh_fatal
autoload -Uz _helpers_log _helpers_error _comp_log _comp_error
autoload -Uz _async_log _async_error _perf_log _perf_error

[[ "$ZSH_DEBUG" == "1" ]] && {
    zsh_info "unified-logging" "Unified logging system v${ZSH_UNIFIED_LOGGING_VERSION} loaded"
}
