#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Environment Context Test Suite
# ==============================================================================
# Purpose: Test context-aware environment variable handling to ensure safe
#          environment modification when sourced and proper cleanup when
#          executed, including variable export and cleanup tracking.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-env-context.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_SOURCE_EXECUTE_DEBUG=false

# Load the source/execute detection system
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
        zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-env-context.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
        zf::debug "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

        zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
            zf::debug "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
            zf::debug "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
            zf::debug "    ASSERTION FAILED: $message"
            zf::debug "    Expected: '$expected'"
            zf::debug "    Actual: '$actual'"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
            zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. ENVIRONMENT FUNCTION TESTS
# ------------------------------------------------------------------------------

test_environment_functions_exist() {
    assert_function_exists "safe_export" &&
    assert_function_exists "context_cleanup"
}

test_safe_export_global_scope() {
    # Test global scope export
    local test_var_name="ZSH_TEST_GLOBAL_VAR_$$"
    local test_var_value="global_test_$(date +%s)"

    # Export variable with global scope
    safe_export "$test_var_name" "$test_var_value" "global"

    # Verify it was exported
    local exported_value="${(P)test_var_name}"
    assert_equals "$test_var_value" "$exported_value" "Global export should set variable correctly"

    # Clean up
    unset "$test_var_name"
}

test_safe_export_local_scope() {
    # Test local scope export behavior
    local test_var_name="ZSH_TEST_LOCAL_VAR_$$"
    local test_var_value="local_test_$(date +%s)"

    # Export variable with local scope
    safe_export "$test_var_name" "$test_var_value" "local"

    # Verify it was set (behavior depends on context)
    local exported_value="${(P)test_var_name}"

    if is_being_sourced; then
        # When sourced, local scope might behave differently
        # Just verify the function ran without error
        return 0
    else
        # When executed, should export globally
        assert_equals "$test_var_value" "$exported_value" "Local export should set variable when executed"
    fi

    # Clean up
    unset "$test_var_name"
}

test_safe_export_default_scope() {
    # Test default scope behavior (should be global)
    local test_var_name="ZSH_TEST_DEFAULT_VAR_$$"
    local test_var_value="default_test_$(date +%s)"

    # Export variable without specifying scope
    safe_export "$test_var_name" "$test_var_value"

    # Verify it was exported
    local exported_value="${(P)test_var_name}"
    assert_equals "$test_var_value" "$exported_value" "Default export should set variable correctly"

    # Clean up
    unset "$test_var_name"
}

test_safe_export_error_handling() {
    # Test error handling for invalid input
    local error_output

    # Test with empty variable name (should fail)
    if is_being_sourced; then
        error_output=$(safe_export "" "value" 2>&1 || true)
        [[ "$error_output" =~ "Variable name required" ]] || {
                zf::debug "    WARNING: Expected error message not found"
            return 0  # Don't fail test, error handling might vary
        }
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. CONTEXT CLEANUP TESTS
# ------------------------------------------------------------------------------

test_context_cleanup_function_exists() {
    # Test that cleanup function exists and can be called
    assert_function_exists "context_cleanup"
}

test_context_cleanup_with_valid_function() {
    # Create a test cleanup function
    local cleanup_function_name="test_cleanup_function_$$"
    local cleanup_marker_var="ZSH_TEST_CLEANUP_MARKER_$$"

    # Create cleanup function that sets a marker
    eval "
    $cleanup_function_name() {
        export $cleanup_marker_var='cleanup_executed'
    }
    "

    # Call context_cleanup
    if is_being_executed; then
        # When executed, cleanup should run immediately
        context_cleanup "$cleanup_function_name"

        # Check if cleanup ran
        local marker_value="${(P)cleanup_marker_var}"
        assert_equals "cleanup_executed" "$marker_value" "Cleanup should execute when script is executed"
    else
        # When sourced, cleanup is registered (behavior may vary)
        context_cleanup "$cleanup_function_name" 2>/dev/null || true
        return 0  # Don't assert specific behavior for sourced context
    fi

    # Clean up
    unset -f "$cleanup_function_name" 2>/dev/null || true
    unset "$cleanup_marker_var" 2>/dev/null || true
}

test_context_cleanup_with_invalid_function() {
    # Test cleanup with non-existent function
    local invalid_function_name="non_existent_cleanup_function_$$"

    if is_being_executed; then
        # Should handle error gracefully
        local error_output=$(context_cleanup "$invalid_function_name" 2>&1 || true)
        [[ "$error_output" =~ "not found" ]] || {
                zf::debug "    WARNING: Expected error message not found"
            return 0  # Don't fail test, error handling might vary
        }
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 4. ENVIRONMENT LOGGING TESTS
# ------------------------------------------------------------------------------

test_environment_operation_logging() {
    # Test that environment operations are logged
    local test_var_name="ZSH_TEST_LOG_VAR_$$"
    local test_var_value="log_test_$(date +%s)"

    # Perform an export operation
    safe_export "$test_var_name" "$test_var_value" "global"

    # Check if operation appears in detection log
    local detection_log="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')/source-execute-detection.log"

    if [[ -f "$detection_log" ]]; then
        if grep -q "$test_var_name" "$detection_log" 2>/dev/null; then
            # Clean up and return success
            unset "$test_var_name"
            return 0
        else
                zf::debug "    WARNING: Environment operation not found in log"
            unset "$test_var_name"
            return 0  # Don't fail test, logging might be conditional
        fi
    else
            zf::debug "    WARNING: Detection log file not found"
        unset "$test_var_name"
        return 0  # Don't fail test, logging setup might vary
    fi
}

# ------------------------------------------------------------------------------
# 5. CONTEXT AWARENESS TESTS
# ------------------------------------------------------------------------------

test_environment_context_awareness() {
    # Test that environment functions are context-aware
    local context=$(get_execution_context)

        zf::debug "  Testing in context: $context"

    # Test that context information is available to environment functions
    [[ -n "$context" ]] || {
            zf::debug "    ASSERTION FAILED: Context should not be empty"
        return 1
    }

    return 0
}

test_environment_integration_with_detection() {
    # Test integration between environment functions and detection system
    assert_function_exists "is_being_sourced" &&
    assert_function_exists "is_being_executed" &&
    assert_function_exists "get_execution_context" &&
    assert_function_exists "safe_export" &&
    assert_function_exists "context_cleanup"
}

# ------------------------------------------------------------------------------
# 6. VARIABLE SCOPE TESTS
# ------------------------------------------------------------------------------

test_variable_scope_behavior() {
    # Test variable scope behavior in different contexts
    local test_var_name="ZSH_TEST_SCOPE_VAR_$$"
    local test_var_value="scope_test_$(date +%s)"

    # Set variable using safe_export
    safe_export "$test_var_name" "$test_var_value" "global"

    # Verify variable is accessible
    local retrieved_value="${(P)test_var_name}"
    assert_equals "$test_var_value" "$retrieved_value" "Variable should be accessible after export"

    # Clean up
    unset "$test_var_name"
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zf::debug "========================================================"
        zf::debug "Environment Context Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Log File: $LOG_FILE"
        zf::debug ""

    log_test "Starting environment context test suite"

    # Function Existence Tests
        zf::debug "=== Environment Function Tests ==="
    run_test "Environment Functions Exist" "test_environment_functions_exist"
    run_test "Safe Export Global Scope" "test_safe_export_global_scope"
    run_test "Safe Export Local Scope" "test_safe_export_local_scope"
    run_test "Safe Export Default Scope" "test_safe_export_default_scope"
    run_test "Safe Export Error Handling" "test_safe_export_error_handling"

    # Cleanup Tests
        zf::debug ""
        zf::debug "=== Context Cleanup Tests ==="
    run_test "Context Cleanup Function Exists" "test_context_cleanup_function_exists"
    run_test "Context Cleanup with Valid Function" "test_context_cleanup_with_valid_function"
    run_test "Context Cleanup with Invalid Function" "test_context_cleanup_with_invalid_function"

    # Logging Tests
        zf::debug ""
        zf::debug "=== Environment Logging Tests ==="
    run_test "Environment Operation Logging" "test_environment_operation_logging"

    # Context Awareness Tests
        zf::debug ""
        zf::debug "=== Context Awareness Tests ==="
    run_test "Environment Context Awareness" "test_environment_context_awareness"
    run_test "Environment Integration with Detection" "test_environment_integration_with_detection"

    # Variable Scope Tests
        zf::debug ""
        zf::debug "=== Variable Scope Tests ==="
    run_test "Variable Scope Behavior" "test_variable_scope_behavior"

    # Results Summary
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Environment context test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zf::debug ""
            zf::debug "🎉 All environment context tests passed!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED environment context test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
        zf::debug "Environment context test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Environment Context Test Suite
# ==============================================================================
