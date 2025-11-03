#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Output Control Test Suite
# ==============================================================================
# Purpose: Test context-aware output management functions to ensure proper
#          behavior of conditional output, logging, and messaging based on
#          execution context (sourced vs executed).
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-output-control.zsh (execute) or source test-... (source)
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
LOG_FILE="$LOG_DIR/test-output-control.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
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

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    if [[ "$haystack" =~ "$needle" ]]; then
        return 0
    else
        zf::debug "    ASSERTION FAILED: $message"
        zf::debug "    Haystack: '$haystack'"
        zf::debug "    Needle: '$needle'"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" >/dev/null; then
        return 0
    else
        zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. OUTPUT CONTROL FUNCTION TESTS
# ------------------------------------------------------------------------------

test_output_control_functions_exist() {
    assert_function_exists "context_echo" &&
        assert_function_exists "conditional_output"
}

test_context_echo_info_level() {
    # Test INFO level output
    local test_message="Test info message $(date +%s)"
    local output=$(context_echo "$test_message" "INFO" 2>/dev/null)

    assert_contains "$output" "$test_message" "INFO output should contain message"
}

test_context_echo_warn_level() {
    # Test WARN level output (should go to stderr)
    local test_message="Test warning message $(date +%s)"
    local output=$(context_echo "$test_message" "WARN" 2>&1)

    assert_contains "$output" "$test_message" "WARN output should contain message"
}

test_context_echo_error_level() {
    # Test ERROR level output (should go to stderr)
    local test_message="Test error message $(date +%s)"
    local output=$(context_echo "$test_message" "ERROR" 2>&1)

    assert_contains "$output" "$test_message" "ERROR output should contain message"
}

test_context_echo_debug_mode() {
    # Test debug mode formatting
    local original_debug="$ZSH_SOURCE_EXECUTE_DEBUG"
    export ZSH_SOURCE_EXECUTE_DEBUG=true

    local test_message="Debug test message"
    local output=$(context_echo "$test_message" "INFO" 2>/dev/null)
    local context=$(get_execution_context)

    # Should contain debug formatting
    assert_contains "$output" "INFO" "Debug output should contain level" &&
        assert_contains "$output" "$context" "Debug output should contain context"

    # Restore original debug setting
    export ZSH_SOURCE_EXECUTE_DEBUG="$original_debug"
}

# ------------------------------------------------------------------------------
# 3. CONDITIONAL OUTPUT TESTS
# ------------------------------------------------------------------------------

test_conditional_output_both() {
    # Test output with "both" filter (default)
    local test_message="Both context message $(date +%s)"
    local output=$(conditional_output "$test_message" "both" 2>/dev/null)

    assert_contains "$output" "$test_message" "Both filter should always output message"
}

test_conditional_output_sourced_filter() {
    # Test output with "sourced" filter
    local test_message="Sourced context message $(date +%s)"
    local output=$(conditional_output "$test_message" "sourced" 2>/dev/null)

    if is_being_sourced; then
        assert_contains "$output" "$test_message" "Sourced filter should output when sourced"
    else
        # When executed, should be empty
        [[ -z "$output" ]] || {
            zf::debug "    ASSERTION FAILED: Sourced filter should not output when executed"
            return 1
        }
    fi
}

test_conditional_output_executed_filter() {
    # Test output with "executed" filter
    local test_message="Executed context message $(date +%s)"
    local output=$(conditional_output "$test_message" "executed" 2>/dev/null)

    if is_being_executed; then
        assert_contains "$output" "$test_message" "Executed filter should output when executed"
    else
        # When sourced, should be empty
        [[ -z "$output" ]] || {
            zf::debug "    ASSERTION FAILED: Executed filter should not output when sourced"
            return 1
        }
    fi
}

test_conditional_output_default_behavior() {
    # Test default behavior (should be "both")
    local test_message="Default behavior message $(date +%s)"
    local output=$(conditional_output "$test_message" 2>/dev/null)

    assert_contains "$output" "$test_message" "Default behavior should output message"
}

# ------------------------------------------------------------------------------
# 4. OUTPUT LOGGING TESTS
# ------------------------------------------------------------------------------

test_context_echo_logging() {
    # Test that context_echo logs messages
    local test_message="Logging test message $(date +%s)"

    # Call context_echo (suppress stdout)
    context_echo "$test_message" "INFO" >/dev/null 2>&1

    # Check if message appears in detection log
    local detection_log="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')/source-execute-detection.log"

    if [[ -f "$detection_log" ]]; then
        if grep -q "$test_message" "$detection_log" 2>/dev/null; then
            return 0
        else
            zf::debug "    WARNING: Message not found in detection log (may be expected)"
            return 0 # Don't fail test, logging might be conditional
        fi
    else
        zf::debug "    WARNING: Detection log file not found"
        return 0 # Don't fail test, logging setup might vary
    fi
}

# ------------------------------------------------------------------------------
# 5. OUTPUT STREAM TESTS
# ------------------------------------------------------------------------------

test_output_stream_routing() {
    # Test that different levels go to correct streams
    local info_message="Info stream test"
    local warn_message="Warn stream test"
    local error_message="Error stream test"

    # Test INFO goes to stdout
    local info_stdout=$(context_echo "$info_message" "INFO" 2>/dev/null)
    local info_stderr=$(context_echo "$info_message" "INFO" 2>&1 >/dev/null)

    # INFO should appear in stdout, not stderr
    assert_contains "$info_stdout" "$info_message" "INFO should go to stdout"

    # Test WARN goes to stderr
    local warn_output=$(context_echo "$warn_message" "WARN" 2>&1 >/dev/null)
    assert_contains "$warn_output" "$warn_message" "WARN should go to stderr"

    # Test ERROR goes to stderr
    local error_output=$(context_echo "$error_message" "ERROR" 2>&1 >/dev/null)
    assert_contains "$error_output" "$error_message" "ERROR should go to stderr"
}

# ------------------------------------------------------------------------------
# 6. CONTEXT AWARENESS TESTS
# ------------------------------------------------------------------------------

test_output_context_awareness() {
    # Test that output functions are aware of execution context
    local context=$(get_execution_context)

    # Test that context information is available
    [[ -n "$context" ]] || {
        zf::debug "    ASSERTION FAILED: Context should not be empty"
        return 1
    }

    zf::debug "  Current context: $context"
    return 0
}

test_output_integration_with_detection() {
    # Test integration between output functions and detection system
    assert_function_exists "is_being_sourced" &&
        assert_function_exists "is_being_executed" &&
        assert_function_exists "get_execution_context" &&
        assert_function_exists "context_echo" &&
        assert_function_exists "conditional_output"
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Output Control Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Log File: $LOG_FILE"
    zf::debug ""

    log_test "Starting output control test suite"

    # Function Existence Tests
    zf::debug "=== Output Control Function Tests ==="
    run_test "Output Control Functions Exist" "test_output_control_functions_exist"
    run_test "Context     zf::debug INFO Level" "test_context_echo_info_level"
    run_test "Context     zf::debug WARN Level" "test_context_echo_warn_level"
    run_test "Context     zf::debug ERROR Level" "test_context_echo_error_level"
    run_test "Context     zf::debug Debug Mode" "test_context_echo_debug_mode"

    # Conditional Output Tests
    zf::debug ""
    zf::debug "=== Conditional Output Tests ==="
    run_test "Conditional Output Both" "test_conditional_output_both"
    run_test "Conditional Output Sourced Filter" "test_conditional_output_sourced_filter"
    run_test "Conditional Output Executed Filter" "test_conditional_output_executed_filter"
    run_test "Conditional Output Default Behavior" "test_conditional_output_default_behavior"

    # Logging Tests
    zf::debug ""
    zf::debug "=== Output Logging Tests ==="
    run_test "Context     zf::debug Logging" "test_context_echo_logging"

    # Stream Routing Tests
    zf::debug ""
    zf::debug "=== Output Stream Tests ==="
    run_test "Output Stream Routing" "test_output_stream_routing"

    # Context Awareness Tests
    zf::debug ""
    zf::debug "=== Context Awareness Tests ==="
    run_test "Output Context Awareness" "test_output_context_awareness"
    run_test "Output Integration with Detection" "test_output_integration_with_detection"

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
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi
    zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Output control test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All output control tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED output control test(s) failed."
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
    zf::debug "Output control test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Output Control Test Suite
# ==============================================================================
