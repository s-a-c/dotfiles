#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Source/Execute Detection System
# ==============================================================================
# Purpose: Universal source/execute detection system providing context-aware
#          error handling, output control, and environment management.
#
# Author: ZSH Configuration Management System
# Created: 2025-01-27
# Version: 1.0
# Dependencies: None (core system)
# ==============================================================================

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_SOURCE_EXECUTE_LOADED:-}" && -z "${ZSH_SOURCE_EXECUTE_TESTING:-}" ]]; then
    return 0
fi

# Mark this module as loaded
export ZSH_SOURCE_EXECUTE_LOADED=true

# Debug mode flag
export ZSH_SOURCE_EXECUTE_DEBUG="${ZSH_SOURCE_EXECUTE_DEBUG:-false}"

# ------------------------------------------------------------------------------
# 1. CORE DETECTION FUNCTIONS
# ------------------------------------------------------------------------------

# Function: is_being_sourced
# Purpose: Detect if the current script is being sourced using multiple robust techniques
# Returns: 0 if sourced, 1 if executed
# Usage: if is_being_sourced; then ...; fi
is_being_sourced() {
    # Method 1: ZSH_EVAL_CONTEXT (most reliable in modern ZSH)
    if [[ -n "${ZSH_EVAL_CONTEXT:-}" ]]; then
        case "$ZSH_EVAL_CONTEXT" in
            *file*) return 0 ;;      # Contains 'file' = sourced
            *cmdarg*) return 1 ;;    # Contains 'cmdarg' = executed
            *toplevel*) return 1 ;;  # Top-level execution
        esac
    fi

    # Method 2: Compare $0 with script path
    local script_name="$0"
    case "$script_name" in
        # Interactive shell indicators (definitely sourced)
        -*|zsh|bash) return 0 ;;

        # If $0 contains a path and the file exists, likely executed
        */*)
            if [[ -f "$script_name" && -r "$script_name" ]]; then
                return 1  # Executed as script
            else
                return 0  # Sourced (path exists but not directly executable)
            fi
            ;;

        # Script extensions - check if file exists
        *.zsh|*.sh)
            if [[ -f "$script_name" && -r "$script_name" ]]; then
                return 1  # Executed as script
            else
                return 0  # Sourced
            fi
            ;;
    esac

    # Method 3: Script path comparison using ${(%):-%N} (zsh preferred)
    local current_script="${(%):-%N}"
    if [[ -n "$current_script" ]]; then
        if [[ "$current_script" != "$0" ]]; then
            return 0  # Different values = sourced
        fi
    fi

    # Method 4: funcstack analysis (ZSH specific, but careful)
    if [[ -n "${funcstack:-}" ]]; then
        local stack_depth="${#funcstack[@]}"
        if [[ "$stack_depth" -gt 1 ]]; then
            return 0  # In function context = likely sourced
        fi
    fi

    # Method 5: Simple process check (non-blocking)
    if command -v ps >/dev/null 2>&1; then
        local parent_cmd
        # Use timeout to prevent hanging
        parent_cmd=$(timeout 1 ps -o comm= -p "$PPID" 2>/dev/null || zsh_debug_echo "unknown")
        case "$parent_cmd" in
            *zsh*|*bash*|*sh*)
                return 0  # Parent is shell = likely sourced
                ;;
        esac
    fi

    # Default: assume executed if methods are inconclusive
    return 1
}

# Function: is_being_executed
# Purpose: Detect if the current script is being executed directly (inverse of sourced)
# Returns: 0 if executed, 1 if sourced
# Usage: if is_being_executed; then ...; fi
is_being_executed() {
    ! is_being_sourced
}

# Function: get_execution_context
# Purpose: Get detailed execution context information
# Returns: String describing the execution context
# Usage: context=$(get_execution_context)
get_execution_context() {
    local context=""

    if is_being_sourced; then
        context="sourced"

        # Add more specific context if available
        if [[ -n "${funcstack:-}" && "${#funcstack[@]}" -gt 2 ]]; then
            context="sourced (nested)"
        fi

        if [[ "$0" == "-zsh" || "$0" == "-"* ]]; then
            context="sourced (interactive)"
        fi
    else
        context="executed"

        # Check if executed as script vs command
        if [[ -f "$0" ]]; then
            context="executed (script)"
        else
            context="executed (command)"
        fi
    fi

    zsh_debug_echo "$context"
}

# ------------------------------------------------------------------------------
# 2. CONTEXT-AWARE ERROR HANDLING
# ------------------------------------------------------------------------------

# Function: exit_or_return
# Purpose: Context-aware exit/return based on execution mode
# Args: $1 = exit code (default: 1)
#       $2 = optional error message
# Usage: exit_or_return 1 "Error message"
exit_or_return() {
    local exit_code="${1:-1}"
    local error_message="${2:-}"

    # Log the error if message provided
    if [[ -n "$error_message" ]]; then
        _log_detection_event "ERROR" "$error_message (exit_code=$exit_code)"
    fi

    if is_being_sourced; then
        # When sourced, use return to avoid terminating the shell
        return "$exit_code"
    else
        # When executed, use exit
        exit "$exit_code"
    fi
}

# Function: handle_error
# Purpose: Comprehensive error handling with context awareness
# Args: $1 = error message
#       $2 = exit code (default: 1)
#       $3 = optional function name
# Usage: handle_error "Something went wrong" 2 "${funcstack[1]}"
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    local function_name="${3:-${funcstack[2]:-unknown}}"

    # Format error message with context
    local context=$(get_execution_context)
    local formatted_error="ERROR [$context]: $error_message"

    if [[ -n "$function_name" && "$function_name" != "unknown" ]]; then
        formatted_error="$formatted_error (in $function_name)"
    fi

    # Output error based on context
    if is_being_sourced; then
        # When sourced, output to stderr but don't exit shell
        zsh_debug_echo "$formatted_error"
        _log_detection_event "ERROR" "$formatted_error"
        return "$exit_code"
    else
        # When executed, output and exit
        zsh_debug_echo "$formatted_error"
        _log_detection_event "ERROR" "$formatted_error"
        exit "$exit_code"
    fi
}

# Function: safe_exit
# Purpose: Safe exit that respects execution context
# Args: $1 = exit code (default: 0)
# Usage: safe_exit 0
safe_exit() {
    local exit_code="${1:-0}"

    _log_detection_event "EXIT" "Safe exit with code $exit_code ($(get_execution_context))"

    exit_or_return "$exit_code"
}

# ------------------------------------------------------------------------------
# 3. CONTEXT-AWARE OUTPUT CONTROL
# ------------------------------------------------------------------------------

# Function: context_zsh_debug_echo
# Purpose: Context-aware output that can be controlled based on execution mode
# Args: $1 = message
#       $2 = output level (INFO|WARN|ERROR, default: INFO)
# Usage: context_zsh_debug_echo "Starting process" "INFO"
context_zsh_debug_echo() {
    local message="$1"
    local level="${2:-INFO}"
    local context=$(get_execution_context)

    # Format message with context if debug enabled
    if [[ "$ZSH_SOURCE_EXECUTE_DEBUG" == "true" ]]; then
        message="[$level] [$context] $message"
    fi

    case "$level" in
        ERROR)
            zsh_debug_echo "$message"
            ;;
        WARN)
            zsh_debug_echo "$message"
            ;;
        INFO|*)
            zsh_debug_echo "$message"
            ;;
    esac

    # Log the message
    _log_detection_event "$level" "$message"
}

# Function: conditional_output
# Purpose: Output only in certain execution contexts
# Args: $1 = message
#       $2 = context filter (sourced|executed|both, default: both)
# Usage: conditional_output "Debug info" "executed"
conditional_output() {
    local message="$1"
    local context_filter="${2:-both}"

    case "$context_filter" in
        sourced)
            if is_being_sourced; then
                zsh_debug_echo "$message"
            fi
            ;;
        executed)
            if is_being_executed; then
                zsh_debug_echo "$message"
            fi
            ;;
        both|*)
            zsh_debug_echo "$message"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 4. CONTEXT-AWARE ENVIRONMENT MANAGEMENT
# ------------------------------------------------------------------------------

# Function: safe_export
# Purpose: Safely export variables with context awareness
# Args: $1 = variable name
#       $2 = value
#       $3 = export scope (global|local, default: global)
# Usage: safe_export "MY_VAR" "value" "global"
safe_export() {
    local var_name="$1"
    local var_value="$2"
    local export_scope="${3:-global}"

    if [[ -z "$var_name" ]]; then
        handle_error "Variable name required for safe_export"
        return 1
    fi

    case "$export_scope" in
        local)
            # For local scope, only set in current context
            if is_being_sourced; then
                # When sourced, create local variable
                local "$var_name"="$var_value"
            else
                # When executed, export globally
                export "$var_name"="$var_value"
            fi
            ;;
        global|*)
            # Always export globally
            export "$var_name"="$var_value"
            ;;
    esac

    _log_detection_event "EXPORT" "Set $var_name=$var_value (scope: $export_scope, context: $(get_execution_context))"
}

# Function: context_cleanup
# Purpose: Perform cleanup based on execution context
# Args: $1 = cleanup function name
# Usage: context_cleanup "_my_cleanup_function"
context_cleanup() {
    local cleanup_function="$1"

    if [[ -z "$cleanup_function" ]]; then
        handle_error "Cleanup function name required"
        return 1
    fi

    if is_being_executed; then
        # When executed, always run cleanup
        if typeset -f "$cleanup_function" >/dev/null 2>&1; then
            _log_detection_event "CLEANUP" "Running cleanup function: $cleanup_function"
            "$cleanup_function"
        else
            handle_error "Cleanup function '$cleanup_function' not found"
        fi
    else
        # When sourced, register cleanup for later (if supported)
        _log_detection_event "CLEANUP" "Cleanup function '$cleanup_function' registered for sourced context"
        # Note: In sourced context, cleanup might be deferred or handled by the parent
    fi
}

# ------------------------------------------------------------------------------
# 5. UTILITY FUNCTIONS
# ------------------------------------------------------------------------------

# Function: _log_detection_event
# Purpose: Internal logging function for detection events
# Args: $1 = event type
#       $2 = message
_log_detection_event() {
    local event_type="$1"
    local message="$2"

    # Only log if debug enabled or it's an error
    if [[ "$ZSH_SOURCE_EXECUTE_DEBUG" == "true" || "$event_type" == "ERROR" ]]; then
        local timestamp=$(date -u '+    %FT%T %Z')
        local log_dir="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
        local log_file="$log_dir/source-execute-detection.log"

        # Create log directory if it doesn't exist
        mkdir -p "$log_dir" 2>/dev/null || true

        # Log the event
        zsh_debug_echo "[$timestamp] [$event_type] [$$] $message" >> "$log_file" 2>/dev/null || true
    fi
}

# Function: detection_info
# Purpose: Display detailed detection information
# Usage: detection_info
detection_info() {
    zsh_debug_echo "=== Source/Execute Detection Information ==="
    zsh_debug_echo "Execution Context: $(get_execution_context)"
    zsh_debug_echo "Script Name (\$0): $0"
    zsh_debug_echo "Function Stack Depth: ${#funcstack[@]}"
    zsh_debug_echo "Script Path (%N): ${(%):-%N}"
    zsh_debug_echo "Current PID: $$"
    zsh_debug_echo "Parent PID: $PPID"
    zsh_debug_echo "Debug Mode: $ZSH_SOURCE_EXECUTE_DEBUG"
    zsh_debug_echo "=========================================="
}

# Function: test_detection
# Purpose: Quick test of detection functionality
# Usage: test_detection
test_detection() {
    zsh_debug_echo "Testing source/execute detection..."

    if is_being_sourced; then
        zsh_debug_echo "✓ Detected as SOURCED"
    else
        zsh_debug_echo "✓ Detected as EXECUTED"
    fi

    zsh_debug_echo "Context: $(get_execution_context)"

    # Test error handling
    zsh_debug_echo "Testing error handling..."
    context_zsh_debug_echo "This is an info message" "INFO"
    context_zsh_debug_echo "This is a warning message" "WARN"

    zsh_debug_echo "Detection test completed."
}

# ------------------------------------------------------------------------------
# 6. INITIALIZATION AND SELF-TEST
# ------------------------------------------------------------------------------

# Log module loading
_log_detection_event "INIT" "Source/execute detection system loaded (context: $(get_execution_context))"

# Note: In ZSH, functions are automatically available to subshells when defined
# The functions above are now available globally within the ZSH environment

# Run self-test only when executed directly (not when sourced)
if is_being_executed && [[ -z "${ZSH_SOURCE_EXECUTE_TESTING:-}" ]]; then
    zsh_debug_echo "Source/Execute Detection System - Self Test Mode"
    zsh_debug_echo "=============================================="
    test_detection
    detection_info
    zsh_debug_echo ""
    zsh_debug_echo "To use this system, source this file instead of executing it:"
    zsh_debug_echo "  source $0"
    zsh_debug_echo ""
    safe_exit 0
fi

# End of source/execute detection system
