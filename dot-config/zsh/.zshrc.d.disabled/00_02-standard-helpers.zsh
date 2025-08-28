#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Standard Helpers Library
# ==============================================================================
# Purpose: Standardized helper library for ZSH configuration consistency
#          with integrated source/execute detection and context-aware behavior
# Dependencies: 01-source-execute-detection.zsh (loaded automatically)
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.1.0
# Load Order: SECOND in 00-core (after source/execute detection)
#
# This file provides standardized helper functions to ensure consistency
# across all ZSH configuration files. These functions should be used
# throughout the configuration to maintain quality and reduce duplication.
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_HELPERS_LOADED:-}" && -z "${ZSH_HELPERS_TESTING:-}" ]]; then
    return 0
fi

# Standard logging function (fallback to zsh_debug_echo from .zshenv)
_helpers_log() {
    zsh_debug_echo "# [helpers] $1"
}

# 1. Global Configuration and Validation
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    _helpers_log "++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _helpers_log "Loading standard helpers library v1.1.0"
}

# 1.1. Set global helper version for validation
export ZSH_HELPERS_VERSION="1.1.0"
export ZSH_HELPERS_LOADED="$(date -u '+    %FT%T %Z')"

# 1.2. Context-aware error handling
_helpers_error() {
    local message="$1"
    local exit_code="${2:-1}"

    if declare -f handle_error >/dev/null 2>&1; then
        handle_error "Standard Helpers: $message" "$exit_code" "helpers"
    else
        zsh_debug_echo "ERROR [helpers]: $message"
        if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
            exit "$exit_code"
        else
            return "$exit_code"
        fi
    fi
}

# 1.2. Function existence cache (performance optimization)
declare -gA _zsh_helper_cache

# 2. Core Utility Functions
#=============================================================================

# 2.1. Standard UTC timestamp for logging
utc_timestamp() {
    if command -v date >/dev/null 2>&1; then
        date -u '+    %FT%T %Z'
    else
        zsh_debug_echo "$(date '+%Y-%m-%d %H:%M:%S') UTC"
    fi
}

# 2.2. Safe logging with directory creation
safe_log() {
    local log_file="$1"
    local message="$2"
    local timestamp="${3:-$(utc_timestamp)}"

    # Create log directory if it doesn't exist
    [[ ! -d "$(dirname "$log_file")" ]] && mkdir -p "$(dirname "$log_file")"

    # Log with error suppression
    zsh_debug_echo "[$timestamp] $message" >> "$log_file" 2>/dev/null || true
}

# 2.3. Enhanced debug logging
debug_log() {
    local context="$1"
    local message="$2"
    local level="${3:-INFO}"

    if [[ "$ZSH_DEBUG" == "1" ]]; then
        local timestamp="$(utc_timestamp)"
        zsh_debug_echo "# [$timestamp] [$level] [$context] $message"
    fi
}

# 3. Command and File Existence Functions
#=============================================================================

# 3.1. Standard command existence check with caching
# NOTE: has_command() has been moved to .zshenv for broader availability
# All command checking now uses the enhanced has_command() from .zshenv
# which provides caching via _zsh_command_cache

# 3.2. File existence and readability check
has_readable_file() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]]
}

# 3.3. Directory existence and accessibility check
has_accessible_dir() {
    local dir="$1"
    [[ -d "$dir" && -x "$dir" ]]
}

# 3.4. Path component validation
is_secure_path_component() {
    local component="$1"

    # Check for insecure patterns
    case "$component" in
        ""|"."|".."|"/tmp"|"/var/tmp") return 1 ;;
        *)
            # Check if exists and is world-writable
            if [[ -d "$component" ]]; then
                local perms="$(stat -f "%p" "$component" 2>/dev/null | tail -c 3)"
                [[ "$perms" =~ [2367] ]] && return 1
            fi
            return 0 ;;
    esac
}

# 4. Environment Variable Management
#=============================================================================

# 4.1. Export variable only if not already set (idempotent export)
export_if_unset() {
    local var_name="$1"
    local var_value="$2"

    [[ -z "${(P)var_name}" ]] && export "$var_name"="$var_value"
}

# 4.2. Export variable with validation
export_with_validation() {
    local var_name="$1"
    local var_value="$2"
    local validator_func="$3"

    if [[ -n "$validator_func" ]]; then
        if "$validator_func" "$var_value"; then
            export "$var_name"="$var_value"
            return 0
        else
            debug_log "export" "Validation failed for $var_name=$var_value" "WARN"
            return 1
        fi
    else
        export "$var_name"="$var_value"
    fi
}

# 4.3. Safe variable unset with existence check
safe_unset() {
    local var_name="$1"
    [[ -n "${(P)var_name}" ]] && unset "$var_name"
}

# 4.4. Check if variable matches sensitive patterns
is_sensitive_variable() {
    local var_name="$1"
    local sensitive_patterns=(
        '.*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*'
        '.*[Tt][Oo][Kk][Ee][Nn].*'
        '.*[Kk][Ee][Yy].*'
        '.*[Ss][Ee][Cc][Rr][Ee][Tt].*'
        '.*[Aa][Uu][Tt][Hh].*'
        '.*[Cc][Rr][Ee][Dd][Ee][Nn][Tt][Ii][Aa][Ll].*'
    )

    for pattern in "${sensitive_patterns[@]}"; do
        [[ "$var_name" =~ $pattern ]] && return 0
    done
    return 1
}

# 5. PATH Management Functions
#=============================================================================

# NOTE: PATH management functions have been moved to .zshenv for broader availability
# The following functions are available from .zshenv with superior implementations:
# - _path_prepend(), _path_append(), _path_remove() - field-based implementations
# - path_dedupe() - with --verbose and --dry-run options
# - _field_* functions for advanced field manipulation
#
# Use the .zshenv implementations instead of duplicating functionality here.
# This ensures consistent behavior and eliminates cache conflicts.

# 6. Safe Operations and Error Handling
#=============================================================================

# 6.1. Safe file sourcing with error handling and validation
safe_source() {
    local file="$1"
    local required="${2:-false}"

    if has_readable_file "$file"; then
        if source "$file" 2>/dev/null; then
            debug_log "source" "Successfully sourced: $file" "INFO"
            return 0
        else
            debug_log "source" "Error sourcing file: $file" "ERROR"
            [[ "$required" == "true" ]] && return 1 || return 0
        fi
    else
        debug_log "source" "File not readable: $file" "WARN"
        [[ "$required" == "true" ]] && return 1 || return 0
    fi
}

# 6.2. Execute command with timeout and error handling
safe_execute() {
    local timeout_duration="$1"
    local description="$2"
    shift 2

    debug_log "execute" "Starting: $description" "INFO"

    if has_command "timeout"; then
        if timeout "$timeout_duration" "$@"; then
            debug_log "execute" "Completed successfully: $description" "INFO"
            return 0
        else
            local exit_code=$?
            debug_log "execute" "Failed (exit $exit_code): $description" "ERROR"
            return $exit_code
        fi
    else
        # Fallback without timeout
        if "$@"; then
            debug_log "execute" "Completed successfully: $description" "INFO"
            return 0
        else
            local exit_code=$?
            debug_log "execute" "Failed (exit $exit_code): $description" "ERROR"
            return $exit_code
        fi
    fi
}

# 6.3. Retry mechanism for unreliable operations
retry_operation() {
    local max_attempts="$1"
    local delay="$2"
    local description="$3"
    shift 3

    local attempt=1
    while (( attempt <= max_attempts )); do
        debug_log "retry" "Attempt $attempt/$max_attempts: $description" "INFO"

        if "$@"; then
            debug_log "retry" "Succeeded on attempt $attempt: $description" "INFO"
            return 0
        fi

        if (( attempt < max_attempts )); then
            debug_log "retry" "Failed attempt $attempt, retrying in ${delay}s: $description" "WARN"
            sleep "$delay"
        fi

        ((attempt++))
    done

    debug_log "retry" "Failed after $max_attempts attempts: $description" "ERROR"
    return 1
}

# 7. Performance and Caching Functions
#=============================================================================

# 7.1. Clear helper caches
clear_helper_cache() {
    _zsh_helper_cache=()
    debug_log "cache" "Helper caches cleared" "INFO"
}

# 7.2. Time function execution
time_helper_function() {
    local func_name="$1"
    shift
    local start_time="$SECONDS"

    "$func_name" "$@"
    local result=$?

    local end_time="$SECONDS"
    local duration=$(( end_time - start_time ))
    debug_log "timing" "$func_name completed in ${duration}s" "PERF"

    return $result
}

# 7.3. Create performance marker
perf_marker() {
    local marker_name="$1"
    local marker_file="${ZSH_PERF_LOG:-$HOME/.config/zsh/logs/performance.log}"

    safe_log "$marker_file" "MARKER: $marker_name - $(utc_timestamp)"
}

# 8. Validation and Testing Functions
#=============================================================================

# 8.1. Validate helper library integrity
validate_helpers() {
    local required_functions=(
        "utc_timestamp" "safe_log" "debug_log"
        "has_command" "has_readable_file" "has_accessible_dir" "is_secure_path_component"
        "export_if_unset" "export_with_validation" "safe_unset" "is_sensitive_variable"
        "safe_source" "safe_execute" "retry_operation"
        "clear_helper_cache" "time_helper_function" "perf_marker"
    )

    local missing_functions=()
    for func in "${required_functions[@]}"; do
        if ! type "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        fi
    done

    if (( ${#missing_functions[@]} > 0 )); then
        zsh_debug_echo "ERROR: Missing helper functions: ${missing_functions[*]}"
        return 1
    fi

    debug_log "validation" "All ${#required_functions[@]} helper functions validated successfully" "INFO"
    return 0
}

# 8.2. Self-test for critical functions
test_helpers() {
    local test_results=()

    # Test command detection
    if has_command "zsh_debug_echo"; then
        test_results+=("✅ has_command")
    else
        test_results+=("❌ has_command")
    fi

    # Test variable functions
    export_if_unset "ZSH_TEST_HELPER_VAR" "test_value"
    if [[ "$ZSH_TEST_HELPER_VAR" == "test_value" ]]; then
        test_results+=("✅ export_if_unset")
        safe_unset "ZSH_TEST_HELPER_VAR"
        if [[ -z "$ZSH_TEST_HELPER_VAR" ]]; then
            test_results+=("✅ safe_unset")
        else
            test_results+=("❌ safe_unset")
        fi
    else
        test_results+=("❌ export_if_unset")
    fi

    # Test timestamp
    local timestamp="$(utc_timestamp)"
    if [[ "$timestamp" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC ]]; then
        test_results+=("✅ utc_timestamp")
    else
        test_results+=("❌ utc_timestamp")
    fi

    zsh_debug_echo "=== Helper Library Self-Test Results ==="
    for result in "${test_results[@]}"; do
        zsh_debug_echo "$result"
    done

    local failed_count=$(zsh_debug_echo "${test_results[*]}" | grep -c "❌")
    return $failed_count
}

# 9. Export Functions and Initialization
#=============================================================================

# 9.1. Export all helper functions globally
{
    # Core utilities
    typeset -gf utc_timestamp safe_log debug_log

    # Existence checks
    typeset -gf has_readable_file has_accessible_dir is_secure_path_component

    # Environment management
    typeset -gf export_if_unset export_with_validation safe_unset is_sensitive_variable


    # Safe operations
    typeset -gf safe_source safe_execute retry_operation

    # Performance and caching
    typeset -gf clear_helper_cache time_helper_function perf_marker

    # Validation
    typeset -gf validate_helpers test_helpers
} >/dev/null 2>&1

# 9.2. Initialize helper library with context-aware behavior
if [[ -z "$ZSH_HELPERS_TESTING" ]]; then
    # Perform self-validation in non-040-testing mode
    if ! validate_helpers; then
        _helpers_error "Helper library validation failed" 1
        return 1
    fi

    debug_log "helpers" "Standard helper library initialized successfully (v$ZSH_HELPERS_VERSION)" "INFO"
    perf_marker "helpers_loaded"

    # Context-aware completion message
    if declare -f get_execution_context >/dev/null 2>&1; then
        local context=$(get_execution_context)
        _helpers_log "Standard helpers library loaded in $context context"
    else
        _helpers_log "Standard helpers library loaded"
    fi
fi

[[ "$ZSH_DEBUG" == "1" ]] && _helpers_log "✅ Standard helpers library loaded with $(typeset -f | grep -c '^[a-zA-Z_]') functions"

# ------------------------------------------------------------------------------
# 10. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
_standard_helpers_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Standard Helpers Library"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_HELPERS_VERSION"
    zsh_debug_echo "Loaded: $ZSH_HELPERS_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    zsh_debug_echo "Running self-test..."
    if test_helpers; then
        zsh_debug_echo ""
        zsh_debug_echo "🎉 All helper functions are working correctly!"
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 0
        else
            exit 0
        fi
    else
        zsh_debug_echo ""
        zsh_debug_echo "❌ Some helper functions failed self-test."
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 1
        else
            exit 1
        fi
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        _standard_helpers_main "$@"
    fi
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"standard-helpers"* ]]; then
    # Fallback detection for direct execution
    _standard_helpers_main "$@"
fi
