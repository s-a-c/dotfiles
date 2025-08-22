#!/opt/homebrew/bin/zsh
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

# Guard against multiple sourcing in non-testing environments
if [[ -n "${ZSH_HELPERS_LOADED:-}" && -z "${ZSH_HELPERS_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        echo "WARNING: Source/execute detection system not found: $detection_script" >&2
        echo "Standard helpers will work but without context-aware features" >&2
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_echo >/dev/null 2>&1; then
    _helpers_log() {
        context_echo "$1" "${2:-INFO}"
    }
else
    # Fallback logging function
    _helpers_log() {
        echo "# [helpers] $1" >&2
    }
fi

# 1. Global Configuration and Validation
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    _helpers_log "Loading standard helpers library v1.1.0"
}

# 1.1. Set global helper version for validation
export ZSH_HELPERS_VERSION="1.1.0"
export ZSH_HELPERS_LOADED="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# 1.2. Context-aware error handling
_helpers_error() {
    local message="$1"
    local exit_code="${2:-1}"

    if declare -f handle_error >/dev/null 2>&1; then
        handle_error "Standard Helpers: $message" "$exit_code" "helpers"
    else
        echo "ERROR [helpers]: $message" >&2
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
        date -u '+%Y-%m-%d %H:%M:%S UTC'
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') UTC"
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
    echo "[$timestamp] $message" >> "$log_file" 2>/dev/null || true
}

# 2.3. Enhanced debug logging
debug_log() {
    local context="$1"
    local message="$2"
    local level="${3:-INFO}"

    if [[ "$ZSH_DEBUG" == "1" ]]; then
        local timestamp="$(utc_timestamp)"
        echo "# [$timestamp] [$level] [$context] $message" >&2
    fi
}

# 3. Command and File Existence Functions
#=============================================================================

# 3.1. Standard command existence check with caching
has_command() {
    local cmd="$1"
    local cache_key="cmd_$cmd"

    [[ -z "$cmd" ]] && return 1

    # Check cache first
    if [[ -n "${_zsh_helper_cache[$cache_key]}" ]]; then
        [[ "${_zsh_helper_cache[$cache_key]}" == "1" ]] && return 0 || return 1
    fi

    # Check command existence
    if command -v "$cmd" >/dev/null 2>&1; then
        _zsh_helper_cache[$cache_key]="1"
        return 0
    else
        _zsh_helper_cache[$cache_key]="0"
        return 1
    fi
}

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

# 5.1. Add to PATH if not already present (idempotent)
path_prepend() {
    local new_path="$1"
    local validate="${2:-true}"

    [[ -z "$new_path" ]] && return 1

    # Validate path security if requested
    if [[ "$validate" == "true" ]] && ! is_secure_path_component "$new_path"; then
        debug_log "path" "Refusing to prepend insecure path: $new_path" "WARN"
        return 1
    fi

    # Check if already in PATH
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        export PATH="$new_path:$PATH"
        debug_log "path" "Prepended to PATH: $new_path" "INFO"
    fi
}

# 5.2. Append to PATH if not already present (idempotent)
path_append() {
    local new_path="$1"
    local validate="${2:-true}"

    [[ -z "$new_path" ]] && return 1

    # Validate path security if requested
    if [[ "$validate" == "true" ]] && ! is_secure_path_component "$new_path"; then
        debug_log "path" "Refusing to append insecure path: $new_path" "WARN"
        return 1
    fi

    # Check if already in PATH
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        export PATH="$PATH:$new_path"
        debug_log "path" "Appended to PATH: $new_path" "INFO"
    fi
}

# 5.3. Remove from PATH
path_remove() {
    local remove_path="$1"
    [[ -z "$remove_path" ]] && return 1

    # Remove all instances of the path
    export PATH="${PATH//$remove_path:/}"
    export PATH="${PATH//:$remove_path/}"
    export PATH="${PATH/#$remove_path/}"

    debug_log "path" "Removed from PATH: $remove_path" "INFO"
}

# 5.4. Clean and validate PATH
path_clean() {
    local cleaned_path=""
    local IFS=":"
    local path_array
    path_array=(${=PATH})

    for dir in "${path_array[@]}"; do
        # Skip empty components
        [[ -z "$dir" ]] && continue

        # Check if already in cleaned path
        [[ ":$cleaned_path:" == *":$dir:"* ]] && continue

        # Validate directory exists
        if [[ -d "$dir" ]]; then
            if [[ -z "$cleaned_path" ]]; then
                cleaned_path="$dir"
            else
                cleaned_path="$cleaned_path:$dir"
            fi
        else
            debug_log "path" "Removed non-existent PATH entry: $dir" "INFO"
        fi
    done

    export PATH="$cleaned_path"
    debug_log "path" "PATH cleaned and validated" "INFO"
}

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
        "path_prepend" "path_append" "path_remove" "path_clean"
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
        echo "ERROR: Missing helper functions: ${missing_functions[*]}" >&2
        return 1
    fi

    debug_log "validation" "All ${#required_functions[@]} helper functions validated successfully" "INFO"
    return 0
}

# 8.2. Self-test for critical functions
test_helpers() {
    local test_results=()

    # Test command detection
    if has_command "echo"; then
        test_results+=("✅ has_command")
    else
        test_results+=("❌ has_command")
    fi

    # Test PATH functions
    local original_path="$PATH"
    path_append "/test/nonexistent" false  # Skip validation for test
    if [[ ":$PATH:" == *":/test/nonexistent:"* ]]; then
        test_results+=("✅ path_append")
        path_remove "/test/nonexistent"
        if [[ ":$PATH:" != *":/test/nonexistent:"* ]]; then
            test_results+=("✅ path_remove")
        else
            test_results+=("❌ path_remove")
        fi
    else
        test_results+=("❌ path_append")
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

    echo "=== Helper Library Self-Test Results ==="
    for result in "${test_results[@]}"; do
        echo "$result"
    done

    local failed_count=$(echo "${test_results[*]}" | grep -c "❌")
    return $failed_count
}

# 9. Export Functions and Initialization
#=============================================================================

# 9.1. Export all helper functions globally
{
    # Core utilities
    typeset -gf utc_timestamp safe_log debug_log

    # Existence checks
    typeset -gf has_command has_readable_file has_accessible_dir is_secure_path_component

    # Environment management
    typeset -gf export_if_unset export_with_validation safe_unset is_sensitive_variable

    # PATH management
    typeset -gf path_prepend path_append path_remove path_clean

    # Safe operations
    typeset -gf safe_source safe_execute retry_operation

    # Performance and caching
    typeset -gf clear_helper_cache time_helper_function perf_marker

    # Validation
    typeset -gf validate_helpers test_helpers
} >/dev/null 2>&1

# 9.2. Initialize helper library with context-aware behavior
if [[ -z "$ZSH_HELPERS_TESTING" ]]; then
    # Perform self-validation in non-testing mode
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
main() {
    echo "========================================================"
    echo "ZSH Standard Helpers Library"
    echo "========================================================"
    echo "Version: $ZSH_HELPERS_VERSION"
    echo "Loaded: $ZSH_HELPERS_LOADED"
    echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        echo "Execution Context: $(get_execution_context)"
        echo ""
    fi

    echo "Running self-test..."
    if test_helpers; then
        echo ""
        echo "🎉 All helper functions are working correctly!"
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 0
        else
            exit 0
        fi
    else
        echo ""
        echo "❌ Some helper functions failed self-test."
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
        main "$@"
    fi
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"standard-helpers"* ]]; then
    # Fallback detection for direct execution
    main "$@"
fi
