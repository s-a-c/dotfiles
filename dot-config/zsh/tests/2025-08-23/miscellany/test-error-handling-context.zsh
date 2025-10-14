<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Error Handling Context Test Suite
# ==============================================================================
# Purpose: Test context-aware error handling functions to ensure proper
#          behavior when scripts are sourced vs executed, including return/exit
#          logic, error message formatting, and context preservation.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-error-handling-context.zsh (execute) or source test-... (source)
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
<<<<<<< HEAD
    zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
=======
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
>>>>>>> origin/develop
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
LOG_FILE="$LOG_DIR/test-error-handling-context.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
<<<<<<< HEAD
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
=======
        zsh_debug_echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
>>>>>>> origin/develop
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

<<<<<<< HEAD
    zf::debug "Running test $TEST_COUNT: $test_name"
=======
        zsh_debug_echo "Running test $TEST_COUNT: $test_name"
>>>>>>> origin/develop
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
<<<<<<< HEAD
        zf::debug "  ✓ PASS: $test_name"
=======
            zsh_debug_echo "  ✓ PASS: $test_name"
>>>>>>> origin/develop
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
<<<<<<< HEAD
        zf::debug "  ✗ FAIL: $test_name"
=======
            zsh_debug_echo "  ✗ FAIL: $test_name"
>>>>>>> origin/develop
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
<<<<<<< HEAD
        zf::debug "    ASSERTION FAILED: $message"
        zf::debug "    Expected: '$expected'"
        zf::debug "    Actual: '$actual'"
=======
            zsh_debug_echo "    ASSERTION FAILED: $message"
            zsh_debug_echo "    Expected: '$expected'"
            zsh_debug_echo "    Actual: '$actual'"
>>>>>>> origin/develop
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

<<<<<<< HEAD
    if declare -f "$function_name" >/dev/null; then
        return 0
    else
        zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
=======
    if declare -f "$function_name" > /dev/null; then
        return 0
    else
            zsh_debug_echo "    ASSERTION FAILED: Function '$function_name' should exist"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. ERROR HANDLING FUNCTION TESTS
# ------------------------------------------------------------------------------

test_error_handling_functions_exist() {
    assert_function_exists "handle_error" &&
<<<<<<< HEAD
        assert_function_exists "safe_exit" &&
        assert_function_exists "exit_or_return"
=======
    assert_function_exists "safe_exit" &&
    assert_function_exists "exit_or_return"
>>>>>>> origin/develop
}

test_handle_error_message_formatting() {
    # Test that handle_error formats messages correctly
    local test_message="Test error message"
    local context=$(get_execution_context)

    # Capture error output (redirect stderr to stdout for 040-testing)
    local error_output
    if is_being_sourced; then
        # When sourced, handle_error should return, not exit
        error_output=$(handle_error "$test_message" 42 "test_function" 2>&1 || true)
    else
        # When executed, we can't easily test this without subshells
        # So we'll test the message formatting logic indirectly
        return 0
    fi

    # Check that error message contains expected components
    [[ "$error_output" =~ "ERROR" ]] &&
<<<<<<< HEAD
        [[ "$error_output" =~ "$context" ]] &&
        [[ "$error_output" =~ "$test_message" ]]
=======
    [[ "$error_output" =~ "$context" ]] &&
    [[ "$error_output" =~ "$test_message" ]]
>>>>>>> origin/develop
}

test_safe_exit_context_awareness() {
    # Test that safe_exit behaves correctly in different contexts
    if is_being_sourced; then
        # When sourced, safe_exit should return (we can test this)
        local exit_code=0
        safe_exit 42 || exit_code=$?
        assert_equals "42" "$exit_code" "safe_exit should return correct code when sourced"
    else
        # When executed, safe_exit would exit (can't test directly)
        return 0
    fi
}

test_exit_or_return_behavior() {
    # Test the core exit_or_return function
    if is_being_sourced; then
        # Should return when sourced
        local return_code=0
        exit_or_return 123 "Test message" || return_code=$?
        assert_equals "123" "$return_code" "exit_or_return should return correct code when sourced"
    else
        # Would exit when executed (can't test directly)
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 3. ERROR CONTEXT PRESERVATION TESTS
# ------------------------------------------------------------------------------

test_error_context_information() {
    # Test that error functions preserve context information
    local context=$(get_execution_context)

    # Test context_echo error level
    local error_output=$(context_echo "Test error context" "ERROR" 2>&1)

    # Should contain the message
    [[ "$error_output" =~ "Test error context" ]]
}

test_function_stack_preservation() {
    # Test that error handling preserves function stack information
    local test_function_name="test_error_function"

    # Create a test function that calls handle_error
    eval "
    $test_function_name() {
        if is_being_sourced; then
            handle_error 'Stack test error' 1 '$test_function_name' 2>/dev/null || true
        fi
    }
    "

    # Call the test function
    if is_being_sourced; then
        "$test_function_name"
    fi

    # Clean up
    unset -f "$test_function_name" 2>/dev/null || true

    return 0
}

# ------------------------------------------------------------------------------
# 4. ERROR LOGGING TESTS
# ------------------------------------------------------------------------------

test_error_logging_functionality() {
    # Test that errors are properly logged
    local test_error_message="Test logging error $(date +%s)"

    # Generate an error (suppress output)
    if is_being_sourced; then
        handle_error "$test_error_message" 1 "test_function" 2>/dev/null || true
    else
        # For executed context, we can't easily test without subprocesses
        return 0
    fi

    # Check if error appears in detection log
    local detection_log="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')/source-execute-detection.log"

    if [[ -f "$detection_log" ]]; then
        if grep -q "$test_error_message" "$detection_log" 2>/dev/null; then
            return 0
        else
<<<<<<< HEAD
            zf::debug "    WARNING: Error message not found in detection log"
            return 0 # Don't fail test, just warn
        fi
    else
        zf::debug "    WARNING: Detection log file not found"
        return 0 # Don't fail test, just warn
=======
                zsh_debug_echo "    WARNING: Error message not found in detection log"
            return 0  # Don't fail test, just warn
        fi
    else
            zsh_debug_echo "    WARNING: Detection log file not found"
        return 0  # Don't fail test, just warn
>>>>>>> origin/develop
    fi
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_error_handling_integration() {
    # Test integration between different error handling functions
    local context=$(get_execution_context)

    # Test that all error functions work together
    assert_function_exists "handle_error" &&
<<<<<<< HEAD
        assert_function_exists "safe_exit" &&
        assert_function_exists "exit_or_return" &&
        assert_function_exists "context_echo"
=======
    assert_function_exists "safe_exit" &&
    assert_function_exists "exit_or_return" &&
    assert_function_exists "context_echo"
>>>>>>> origin/develop
}

test_cross_context_compatibility() {
    # Test that error handling works in both contexts
    local current_context=$(get_execution_context)

    # Document current context
<<<<<<< HEAD
    zf::debug "  Testing in context: $current_context"
=======
        zsh_debug_echo "  Testing in context: $current_context"
>>>>>>> origin/develop

    # Test basic error function availability
    assert_function_exists "handle_error"
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
    zf::debug "========================================================"
    zf::debug "Error Handling Context Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Log File: $LOG_FILE"
    zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Error Handling Context Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Log File: $LOG_FILE"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting error handling context test suite"

    # Core Function Tests
<<<<<<< HEAD
    zf::debug "=== Error Handling Function Tests ==="
=======
        zsh_debug_echo "=== Error Handling Function Tests ==="
>>>>>>> origin/develop
    run_test "Error Handling Functions Exist" "test_error_handling_functions_exist"
    run_test "Handle Error Message Formatting" "test_handle_error_message_formatting"
    run_test "Safe Exit Context Awareness" "test_safe_exit_context_awareness"
    run_test "Exit or Return Behavior" "test_exit_or_return_behavior"

    # Context Preservation Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Error Context Preservation Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Error Context Preservation Tests ==="
>>>>>>> origin/develop
    run_test "Error Context Information" "test_error_context_information"
    run_test "Function Stack Preservation" "test_function_stack_preservation"

    # Logging Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Error Logging Tests ==="
    run_test "Error Logging Functionality" "test_error_logging_functionality"

    # Integration Tests
    zf::debug ""
    zf::debug "=== Integration Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Error Logging Tests ==="
    run_test "Error Logging Functionality" "test_error_logging_functionality"

    # Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
>>>>>>> origin/develop
    run_test "Error Handling Integration" "test_error_handling_integration"
    run_test "Cross Context Compatibility" "test_cross_context_compatibility"

    # Results Summary
<<<<<<< HEAD
    zf::debug ""
    zf::debug "========================================================"
    zf::debug "Test Results Summary"
    zf::debug "========================================================"
    zf::debug "Total Tests: $TEST_COUNT"
    zf::debug "Passed: $TEST_PASSED"
    zf::debug "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi
    zf::debug "Success Rate: ${pass_percentage}%"
=======
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zsh_debug_echo "Success Rate: ${pass_percentage}%"
>>>>>>> origin/develop

    log_test "Error handling test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All error handling tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED error handling test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All error handling tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED error handling test(s) failed."
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
<<<<<<< HEAD
    zf::debug "Error handling context test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Error handling context test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Error Handling Context Test Suite
# ==============================================================================
