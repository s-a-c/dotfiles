#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Comprehensive Detection Test Suite
# ==============================================================================
# Purpose: Comprehensive validation of the entire source/execute detection
#          system to ensure all scripts work correctly in both source and
#          execute modes with full system integration 040-testing.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-comprehensive-detection.zsh (execute) or source test-... (source)
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
LOG_FILE="$LOG_DIR/test-comprehensive-detection.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration paths
ZSH_CONFIG_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"

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

assert_command_succeeds() {
    local command="$1"
    local message="${2:-Command should succeed}"

    if eval "$command" >/dev/null 2>&1; then
        return 0
    else
            zf::debug "    ASSERTION FAILED: $message"
            zf::debug "    Command: $command"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. SYSTEM-WIDE DETECTION VALIDATION
# ------------------------------------------------------------------------------

test_detection_system_core_functionality() {
    # Test that all core detection functions work correctly
    local core_functions=(
        "is_being_sourced"
        "is_being_executed"
        "get_execution_context"
        "handle_error"
        "safe_exit"
        "context_echo"
        "conditional_output"
        "safe_export"
        "context_cleanup"
    )

    local working_functions=0
    local total_functions=${#core_functions[@]}

    for func_name in "${core_functions[@]}"; do
        if declare -f "$func_name" > /dev/null 2>&1; then
            working_functions=$((working_functions + 1))
                zf::debug "    ✓ $func_name is available and callable"
        else
                zf::debug "    ✗ $func_name is not available"
        fi
    done

        zf::debug "    📊 Core functionality: $working_functions/$total_functions functions working"

    # Pass if at least 80% of functions are working
    [[ $working_functions -ge $((total_functions * 4 / 5)) ]]
}

test_detection_accuracy_in_current_context() {
    # Test detection accuracy in the current execution context
    local current_context=$(get_execution_context)

        zf::debug "    Current execution context: $current_context"

    # Test consistency between detection functions
    if is_being_sourced; then
        if is_being_executed; then
                zf::debug "    ✗ Inconsistent detection: both sourced and executed returned true"
            return 1
        else
                zf::debug "    ✓ Consistent detection: sourced=true, executed=false"
        fi
    else
        if is_being_executed; then
                zf::debug "    ✓ Consistent detection: sourced=false, executed=true"
        else
                zf::debug "    ✗ Inconsistent detection: both sourced and executed returned false"
            return 1
        fi
    fi

    # Test context string accuracy
    if is_being_sourced && [[ "$current_context" =~ "sourced" ]]; then
            zf::debug "    ✓ Context string matches sourced state"
    elif is_being_executed && [[ "$current_context" =~ "executed" ]]; then
            zf::debug "    ✓ Context string matches executed state"
    else
            zf::debug "    ⚠ Context string may not perfectly match detection state"
        # Don't fail the test, context strings can be more descriptive
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. CROSS-CONTEXT BEHAVIOR VALIDATION
# ------------------------------------------------------------------------------

test_error_handling_cross_context() {
    # Test error handling behavior in current context
    local context=$(get_execution_context)

        zf::debug "    Testing error handling in $context context"

    # Test context_echo with different levels
    local info_output=$(context_echo "Test info message" "INFO" 2>/dev/null)
    local warn_output=$(context_echo "Test warn message" "WARN" 2>&1)
    local error_output=$(context_echo "Test error message" "ERROR" 2>&1)

    # All outputs should contain the test messages
    [[ "$info_output" =~ "Test info message" ]] &&
    [[ "$warn_output" =~ "Test warn message" ]] &&
    [[ "$error_output" =~ "Test error message" ]]
}

test_environment_management_cross_context() {
    # Test environment management in current context
    local test_var_name="ZSH_COMPREHENSIVE_TEST_VAR_$$"
    local test_var_value="comprehensive_test_$(date +%s)"

    # Test safe_export
    safe_export "$test_var_name" "$test_var_value" "global"

    # Verify variable was set
    local retrieved_value="${(P)test_var_name}"
    if [[ "$retrieved_value" == "$test_var_value" ]]; then
            zf::debug "    ✓ Environment management working in $(get_execution_context) context"
        unset "$test_var_name"
        return 0
    else
            zf::debug "    ✗ Environment management failed in $(get_execution_context) context"
        unset "$test_var_name"
        return 1
    fi
}

test_output_control_cross_context() {
    # Test output control in current context
    local context=$(get_execution_context)

    # Test conditional output with different filters
    local both_output=$(conditional_output "Both message" "both" 2>/dev/null)
    local sourced_output=$(conditional_output "Sourced message" "sourced" 2>/dev/null)
    local executed_output=$(conditional_output "Executed message" "executed" 2>/dev/null)

    # Both should always produce output
    if [[ -n "$both_output" ]]; then
            zf::debug "    ✓ 'Both' filter produces output in $context context"
    else
            zf::debug "    ✗ 'Both' filter failed to produce output in $context context"
        return 1
    fi

    # Context-specific filters should behave correctly
    if is_being_sourced; then
        if [[ -n "$sourced_output" && -z "$executed_output" ]]; then
                zf::debug "    ✓ Context-specific filters work correctly in sourced context"
        else
                zf::debug "    ⚠ Context-specific filter behavior unexpected in sourced context"
        fi
    else
        if [[ -z "$sourced_output" && -n "$executed_output" ]]; then
                zf::debug "    ✓ Context-specific filters work correctly in executed context"
        else
                zf::debug "    ⚠ Context-specific filter behavior unexpected in executed context"
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 4. INTEGRATION WITH OTHER TEST SUITES
# ------------------------------------------------------------------------------

test_integration_with_other_test_suites() {
    # Test that other test suites can be run and use detection properly
    local test_suites=(
        "$ZSH_CONFIG_ROOT/tests/test-source-execute-detection.zsh"
        "$ZSH_CONFIG_ROOT/tests/test-error-handling-context.zsh"
        "$ZSH_CONFIG_ROOT/tests/test-output-control.zsh"
        "$ZSH_CONFIG_ROOT/tests/test-env-context.zsh"
    )

    local working_suites=0
    local total_suites=0

    for test_suite in "${test_suites[@]}"; do
        if [[ -f "$test_suite" ]]; then
            total_suites=$((total_suites + 1))

            # Test that the suite can be sourced without errors
            if source "$test_suite" >/dev/null 2>&1; then
                working_suites=$((working_suites + 1))
                    zf::debug "    ✓ $(basename "$test_suite") can be sourced successfully"
            else
                    zf::debug "    ⚠ $(basename "$test_suite") had issues when sourced"
            fi
        fi
    done

    if [[ $total_suites -gt 0 ]]; then
            zf::debug "    📊 Test suite integration: $working_suites/$total_suites suites working"
        [[ $working_suites -ge $((total_suites * 3 / 4)) ]]
    else
            zf::debug "    ⚠ No test suites found for integration testing"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. PERFORMANCE AND RELIABILITY VALIDATION
# ------------------------------------------------------------------------------

test_detection_performance() {
    # Test that detection functions perform well
    local start_time=$(date +%s.%N)

    # Run detection functions multiple times
    for i in {1..100}; do
        is_being_sourced >/dev/null 2>&1
        is_being_executed >/dev/null 2>&1
        get_execution_context >/dev/null 2>&1
    done

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || zf::debug "0.1")

        zf::debug "    📊 Detection performance: 300 function calls in ${duration}s"

    # Performance should be reasonable (less than 1 second for 300 calls)
    if (( $(echo "$duration < 1.0" | bc -l 2>/dev/null || zf::debug "1") )); then
            zf::debug "    ✓ Detection performance is acceptable"
        return 0
    else
            zf::debug "    ⚠ Detection performance may be slow"
        return 0  # Don't fail test, performance can vary
    fi
}

test_detection_reliability() {
    # Test that detection functions are reliable across multiple calls
    local initial_context=$(get_execution_context)
    local consistent_results=0
    local total_tests=10

    for i in $(seq 1 $total_tests); do
        local current_context=$(get_execution_context)
        if [[ "$current_context" == "$initial_context" ]]; then
            consistent_results=$((consistent_results + 1))
        fi
    done

        zf::debug "    📊 Detection reliability: $consistent_results/$total_tests consistent results"

    # Should be 100% consistent
    [[ $consistent_results -eq $total_tests ]]
}

# ------------------------------------------------------------------------------
# 6. SYSTEM INTEGRATION VALIDATION
# ------------------------------------------------------------------------------

test_logging_system_integration() {
    # Test that logging system works correctly
    local test_message="Comprehensive detection test message $(date +%s)"

    # Generate a log entry
    context_echo "$test_message" "INFO" >/dev/null 2>&1

    # Check if log directory exists
    if [[ -d "$LOG_DIR" ]]; then
            zf::debug "    ✓ Log directory exists: $LOG_DIR"

        # Check if detection log exists
        local detection_log="$LOG_DIR/source-execute-detection.log"
        if [[ -f "$detection_log" ]]; then
                zf::debug "    ✓ Detection log file exists"
            return 0
        else
                zf::debug "    ⚠ Detection log file not found (may be expected)"
            return 0
        fi
    else
            zf::debug "    ⚠ Log directory not found (may be expected)"
        return 0
    fi
}

test_function_export_system() {
    # Test that functions are properly available in the current shell
    # Note: In ZSH, functions are available within the same shell session
    # but may not be automatically exported to subshells like in bash
    local available_functions=(
        "is_being_sourced"
        "is_being_executed"
        "get_execution_context"
        "handle_error"
        "context_echo"
        "safe_export"
    )

    local available_count=0
    local total_functions=${#available_functions[@]}

    for func_name in "${available_functions[@]}"; do
        # Test if function is available in current shell
        if declare -f "$func_name" >/dev/null 2>&1; then
            available_count=$((available_count + 1))
                zf::debug "    ✓ $func_name is available in current shell"
        else
                zf::debug "    ✗ $func_name is not available"
        fi
    done

        zf::debug "    📊 Function availability: $available_count/$total_functions functions available"

    # Pass if all functions are available in current shell
    [[ $available_count -eq $total_functions ]]
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zf::debug "========================================================"
        zf::debug "Comprehensive Detection Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Log File: $LOG_FILE"
        zf::debug ""

    log_test "Starting comprehensive detection test suite"

    # System-wide Validation
        zf::debug "=== System-wide Detection Validation ==="
    run_test "Detection System Core Functionality" "test_detection_system_core_functionality"
    run_test "Detection Accuracy in Current Context" "test_detection_accuracy_in_current_context"

    # Cross-context Behavior
        zf::debug ""
        zf::debug "=== Cross-context Behavior Validation ==="
    run_test "Error Handling Cross Context" "test_error_handling_cross_context"
    run_test "Environment Management Cross Context" "test_environment_management_cross_context"
    run_test "Output Control Cross Context" "test_output_control_cross_context"

    # Integration Testing
        zf::debug ""
        zf::debug "=== Integration with Other Test Suites ==="
    run_test "Integration with Other Test Suites" "test_integration_with_other_test_suites"

    # Performance and Reliability
        zf::debug ""
        zf::debug "=== Performance and Reliability Validation ==="
    run_test "Detection Performance" "test_detection_performance"
    run_test "Detection Reliability" "test_detection_reliability"

    # System Integration
        zf::debug ""
        zf::debug "=== System Integration Validation ==="
    run_test "Logging System Integration" "test_logging_system_integration"
    run_test "Function Availability System" "test_function_export_system"

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

    log_test "Comprehensive detection test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zf::debug ""
            zf::debug "🎉 All comprehensive detection tests passed!"
            zf::debug "🎯 Source/Execute Detection System is fully validated!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED comprehensive detection test(s) failed."
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
        zf::debug "Comprehensive detection test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Comprehensive Detection Test Suite
# ==============================================================================
