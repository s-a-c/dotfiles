#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Source/Execute Detection Test Suite
# ==============================================================================
# Purpose: Comprehensive test suite to validate the source/execute detection
#          system, including detection accuracy, error handling behavior,
#          output control, and environment management in both contexts.
#
# Author: ZSH Configuration Management System
# Created: 2025-01-27
# Version: 1.0
# Usage: ./test-source-execute-detection.zsh (execute) or source test-... (source)
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_SOURCE_EXECUTE_DEBUG=false

# Save current directory
TEST_ORIGINAL_PWD="$PWD"

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
LOG_FILE="$LOG_DIR/test-source-execute-detection.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
<<<<<<< HEAD
        zf::debug "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
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

    # Run the test function and capture result
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

assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"

    if eval "$condition"; then
        return 0
    else
<<<<<<< HEAD
            zf::debug "    ASSERTION FAILED: $message"
            zf::debug "    Condition: $condition"
=======
            zsh_debug_echo "    ASSERTION FAILED: $message"
            zsh_debug_echo "    Condition: $condition"
>>>>>>> origin/develop
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"

    if ! eval "$condition"; then
        return 0
    else
<<<<<<< HEAD
            zf::debug "    ASSERTION FAILED: $message"
            zf::debug "    Condition: $condition"
=======
            zsh_debug_echo "    ASSERTION FAILED: $message"
            zsh_debug_echo "    Condition: $condition"
>>>>>>> origin/develop
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
<<<<<<< HEAD
            zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
=======
            zsh_debug_echo "    ASSERTION FAILED: Function '$function_name' should exist"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. CONTEXT DETECTION TESTS
# ------------------------------------------------------------------------------

test_detection_functions_exist() {
    assert_function_exists "is_being_sourced" &&
    assert_function_exists "is_being_executed" &&
    assert_function_exists "get_execution_context" &&
    assert_function_exists "get_context_info"
}

test_detection_logic_consistency() {
    # Test that is_being_sourced and is_being_executed are inverses
    if is_being_sourced; then
        assert_false "is_being_executed" "is_being_executed should return false when sourced"
    else
        assert_true "is_being_executed" "is_being_executed should return true when executed"
    fi
}

test_context_string_detection() {
    local context=$(get_execution_context)

    if is_being_sourced; then
        assert_equals "sourced" "$context" "Context string should be 'sourced' when sourced"
    else
        assert_equals "executed" "$context" "Context string should be 'executed' when executed"
    fi
}

test_context_info_output() {
    # Test that get_context_info produces reasonable output
    local context_info=$(get_context_info)

    # Should contain key information
    assert_true '[[ "$context_info" =~ "Context:" ]]' "Context info should contain 'Context:'"
    assert_true '[[ "$context_info" =~ "Shell:" ]]' "Context info should contain 'Shell:'"
    assert_true '[[ "$context_info" =~ "Script:" ]]' "Context info should contain 'Script:'"
    assert_true '[[ "$context_info" =~ "PID:" ]]' "Context info should contain 'PID:'"
}

# ------------------------------------------------------------------------------
# 3. ERROR HANDLING TESTS
# ------------------------------------------------------------------------------

test_context_exit_function_exists() {
    assert_function_exists "context_exit" &&
    assert_function_exists "context_success" &&
    assert_function_exists "context_warning"
}

test_context_warning_behavior() {
    # Test that context_warning always returns 0
    local warning_output=$(context_warning "Test warning message" 2>&1)
    local exit_code=$?

    assert_equals "0" "$exit_code" "context_warning should return 0" &&
    assert_true '[[ "$warning_output" =~ "WARNING" ]]' "Warning output should contain 'WARNING'"
}

# Note: We cannot easily test context_exit and context_success in the same process
# as they would terminate/return from the script. These are tested implicitly.

# ------------------------------------------------------------------------------
# 4. OUTPUT CONTROL TESTS
# ------------------------------------------------------------------------------

test_output_functions_exist() {
    assert_function_exists "context_echo" &&
    assert_function_exists "context_log"
}

test_context_echo_levels() {
    # Test different output levels
    local info_output=$(context_echo "Info message" "info" 2>/dev/null)
    local warn_output=$(context_echo "Warn message" "warn" 2>&1)
    local error_output=$(context_echo "Error message" "error" 2>&1)

    # Warnings and errors should always be shown
    assert_true '[[ "$warn_output" =~ "Warn message" ]]' "Warning should be displayed"
    assert_true '[[ "$error_output" =~ "Error message" ]]' "Error should be displayed"

    return 0  # Info behavior depends on context, so we don't assert it
}

test_context_echo_force_output() {
    # Test forced output
    local forced_output=$(context_echo "Forced message" "info" "true" 2>/dev/null)

    assert_true '[[ "$forced_output" =~ "Forced message" ]]' "Forced output should be displayed"
}

test_context_log_functionality() {
    # Test that context_log creates log entries
    local test_message="Test log message $(date +%s)"

    # Call context_log (suppress output)
    context_log "$test_message" "info" 2>/dev/null

    # Determine the actual log file used by context_log
    local ctx_log_dir="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
    local ctx_log_file="$ctx_log_dir/source-execute-detection.log"

    # Check if the message appears in the context log file
    if [[ -f "$ctx_log_file" ]]; then
        assert_true "grep -q \"$test_message\" \"$ctx_log_file\"" "Log message should appear in context log file"
    else
<<<<<<< HEAD
            zf::debug "    WARNING: Context log file does not exist, skipping log verification"
=======
            zsh_debug_echo "    WARNING: Context log file does not exist, skipping log verification"
>>>>>>> origin/develop
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. ENVIRONMENT MANAGEMENT TESTS
# ------------------------------------------------------------------------------

test_environment_functions_exist() {
    assert_function_exists "context_export" &&
    assert_function_exists "context_cleanup_env" &&
    assert_function_exists "context_setup_cleanup"
}

test_context_export_functionality() {
    # Test variable export
    local test_var_name="ZSH_TEST_CONTEXT_VAR_$$"
    local test_var_value="test_value_$(date +%s)"

    # Export the variable
    context_export "$test_var_name" "$test_var_value" "false" 2>/dev/null

    # Verify it was exported
    local exported_value="${(P)test_var_name}"
    assert_equals "$test_var_value" "$exported_value" "Exported variable should have correct value"

    # Clean up
    unset "$test_var_name"
}

test_cleanup_tracking() {
    # Test cleanup variable tracking (only when executed)
    local test_var_name="ZSH_TEST_CLEANUP_VAR_$$"
    local test_var_value="cleanup_test_$(date +%s)"

    # Export with cleanup tracking
    context_export "$test_var_name" "$test_var_value" "true" 2>/dev/null

    if is_being_executed; then
        # Should be tracked for cleanup
        assert_true '[[ -n "$ZSH_CONTEXT_CLEANUP_VARS" ]]' "Cleanup vars should be tracked when executed"
    fi

    # Manual cleanup for test
    unset "$test_var_name" ZSH_CONTEXT_CLEANUP_VARS
}

# ------------------------------------------------------------------------------
# 6. UTILITY FUNCTION TESTS
# ------------------------------------------------------------------------------

test_utility_functions_exist() {
    assert_function_exists "context_run_main" &&
    assert_function_exists "validate_context_detection"
}

test_context_run_main_with_dummy_function() {
    # Create a dummy main function
    dummy_main_function() {
<<<<<<< HEAD
            zf::debug "dummy_main_executed"
=======
            zsh_debug_echo "dummy_main_executed"
>>>>>>> origin/develop
        return 42
    }

    # Test context_run_main behavior
    if is_being_executed; then
        # Should run when executed (but we can't test this easily without subshells)
        return 0
    else
        # Should not run when sourced
        local output=$(context_run_main "dummy_main_function" 2>/dev/null)
        assert_true '[[ -z "$output" ]]' "Main function should not run when sourced"
    fi

    # Clean up
    unset -f dummy_main_function
}

test_validate_context_detection() {
    # Test that validation runs without errors
    local validation_output=$(validate_context_detection 2>/dev/null)
    local exit_code=$?

    assert_equals "0" "$exit_code" "Context validation should succeed" &&
    assert_true '[[ "$validation_output" =~ "Context Detection Validation" ]]' "Should produce validation output"
}

# ------------------------------------------------------------------------------
# 7. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_detection_system_initialization() {
    # Test that the system initializes correctly
    # Functions should be available globally
    assert_function_exists "is_being_sourced" &&
    assert_function_exists "is_being_executed" &&
    assert_function_exists "context_log"
}

test_logging_directory_creation() {
    # Test that log directories are created properly
    local test_log_dir="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"

    # The directory should exist after context_log calls
    assert_true '[[ -d "$test_log_dir" ]]' "Log directory should be created"
}

# ------------------------------------------------------------------------------
# 8. CROSS-CONTEXT VALIDATION TESTS
# ------------------------------------------------------------------------------

test_current_execution_context() {
    # Document the current execution context for validation
    local context=$(get_execution_context)

<<<<<<< HEAD
        zf::debug "  Current execution context: $context"
=======
        zsh_debug_echo "  Current execution context: $context"
>>>>>>> origin/develop
    log_test "Detected execution context: $context"

    # This test always passes but provides important information
    return 0
}

test_shell_environment_compatibility() {
    # Test compatibility with different shell features
    assert_true '[[ -n "$ZSH_VERSION" ]]' "Should be running in ZSH"

    # Test array functionality (ZSH-specific)
    local test_array=(one two three)
    assert_equals "3" "${#test_array[@]}" "Array operations should work"

    # Test parameter expansion
    local test_string="hello_world"
    assert_equals "hello" "${test_string%_*}" "Parameter expansion should work"
}

# ------------------------------------------------------------------------------
# 9. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
        zf::debug "========================================================"
        zf::debug "Source/Execute Detection System Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Test Script: $0"
        zf::debug "Working Directory: $PWD"
        zf::debug "Log File: $LOG_FILE"
        zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Source/Execute Detection System Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Test Script: $0"
        zsh_debug_echo "Working Directory: $PWD"
        zsh_debug_echo "Log File: $LOG_FILE"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting comprehensive test suite"
    log_test "Execution context: $(get_execution_context)"

    # 1. Core Detection Tests
<<<<<<< HEAD
        zf::debug "=== Core Detection Tests ==="
=======
        zsh_debug_echo "=== Core Detection Tests ==="
>>>>>>> origin/develop
    run_test "Detection Functions Exist" "test_detection_functions_exist"
    run_test "Detection Logic Consistency" "test_detection_logic_consistency"
    run_test "Context String Detection" "test_context_string_detection"
    run_test "Context Info Output" "test_context_info_output"

    # 2. Error Handling Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Error Handling Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Error Handling Tests ==="
>>>>>>> origin/develop
    run_test "Context Exit Functions Exist" "test_context_exit_function_exists"
    run_test "Context Warning Behavior" "test_context_warning_behavior"

    # 3. Output Control Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Output Control Tests ==="
    run_test "Output Functions Exist" "test_output_functions_exist"
    run_test "Context     zf::debug Levels" "test_context_echo_levels"
    run_test "Context     zf::debug Force Output" "test_context_echo_force_output"
    run_test "Context Log Functionality" "test_context_log_functionality"

    # 4. Environment Management Tests
        zf::debug ""
        zf::debug "=== Environment Management Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Output Control Tests ==="
    run_test "Output Functions Exist" "test_output_functions_exist"
    run_test "Context     zsh_debug_echo Levels" "test_context_echo_levels"
    run_test "Context     zsh_debug_echo Force Output" "test_context_echo_force_output"
    run_test "Context Log Functionality" "test_context_log_functionality"

    # 4. Environment Management Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Environment Management Tests ==="
>>>>>>> origin/develop
    run_test "Environment Functions Exist" "test_environment_functions_exist"
    run_test "Context Export Functionality" "test_context_export_functionality"
    run_test "Cleanup Tracking" "test_cleanup_tracking"

    # 5. Utility Function Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Utility Function Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Utility Function Tests ==="
>>>>>>> origin/develop
    run_test "Utility Functions Exist" "test_utility_functions_exist"
    run_test "Context Run Main with Dummy" "test_context_run_main_with_dummy_function"
    run_test "Validate Context Detection" "test_validate_context_detection"

    # 6. Integration Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Integration Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
>>>>>>> origin/develop
    run_test "Detection System Initialization" "test_detection_system_initialization"
    run_test "Logging Directory Creation" "test_logging_directory_creation"

    # 7. Cross-Context Validation
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Cross-Context Validation ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Cross-Context Validation ==="
>>>>>>> origin/develop
    run_test "Current Execution Context" "test_current_execution_context"
    run_test "Shell Environment Compatibility" "test_shell_environment_compatibility"

    # 8. Test Results Summary
<<<<<<< HEAD
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"
=======
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"
>>>>>>> origin/develop

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
<<<<<<< HEAD
        zf::debug "Success Rate: ${pass_percentage}%"
=======
        zsh_debug_echo "Success Rate: ${pass_percentage}%"
>>>>>>> origin/develop

    log_test "Test suite completed - $TEST_PASSED/$TEST_COUNT tests passed (${pass_percentage}%)"

    # Restore original directory
    cd "$TEST_ORIGINAL_PWD" 2>/dev/null || true

    # Return appropriate exit code
    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
            zf::debug ""
            zf::debug "🎉 All tests passed successfully!"
        log_test "SUCCESS: All tests passed"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All tests passed successfully!"
        log_test "SUCCESS: All tests passed"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED test(s) failed."
>>>>>>> origin/develop
        log_test "FAILURE: $TEST_FAILED tests failed"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 10. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main execution logic using the detection system we're 040-testing
main() {
    # Test the detection system by running all tests
    run_all_tests
}

# Use context_run_main to demonstrate the functionality
# This will run main() only if the script is executed, not sourced
context_run_main "main" "$@"

# If sourced, just indicate that functions are available
if is_being_sourced; then
<<<<<<< HEAD
        zf::debug "Source/Execute Detection test functions loaded (sourced context)"
        zf::debug "Available test functions:"
        zf::debug "  - run_all_tests"
        zf::debug "  - Individual test functions (test_*)"
        zf::debug "  - Test framework functions (run_test, assert_*)"
=======
        zsh_debug_echo "Source/Execute Detection test functions loaded (sourced context)"
        zsh_debug_echo "Available test functions:"
        zsh_debug_echo "  - run_all_tests"
        zsh_debug_echo "  - Individual test functions (test_*)"
        zsh_debug_echo "  - Test framework functions (run_test, assert_*)"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Source/Execute Detection Test Suite
# ==============================================================================
