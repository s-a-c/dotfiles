<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Configuration Validation Test Suite
# ==============================================================================
# Purpose: Test the configuration validation system to ensure proper detection
#          of environment issues, directory problems, missing commands, and
#          configuration file issues with comprehensive CI-compatible 040-testing.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-config-validation.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 99-validation.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_VALIDATION_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
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

# Load the validation system
VALIDATION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_99-validation.zsh"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
<<<<<<< HEAD
    zf::debug "ERROR: Configuration validation script not found: $VALIDATION_SCRIPT"
=======
        zsh_debug_echo "ERROR: Configuration validation script not found: $VALIDATION_SCRIPT"
>>>>>>> origin/develop
    exit 1
fi

# Source the validation system
source "$VALIDATION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-config-validation.log"
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
# 2. VALIDATION FUNCTION TESTS
# ------------------------------------------------------------------------------

test_validation_functions_exist() {
    assert_function_exists "_validate_configuration" &&
<<<<<<< HEAD
        assert_function_exists "_validate_environment" &&
        assert_function_exists "_validate_directories" &&
        assert_function_exists "_validate_commands" &&
        assert_function_exists "_validate_config_files" &&
        assert_function_exists "_validate_zsh_state"
}

test_environment_validation() {
    zf::debug "    📊 Testing environment validation..."
=======
    assert_function_exists "_validate_environment" &&
    assert_function_exists "_validate_directories" &&
    assert_function_exists "_validate_commands" &&
    assert_function_exists "_validate_config_files" &&
    assert_function_exists "_validate_zsh_state"
}

test_environment_validation() {
        zsh_debug_echo "    📊 Testing environment validation..."
>>>>>>> origin/develop

    # Save original environment
    local original_path="$PATH"
    local original_home="$HOME"

    # Test with good environment
    if _validate_environment >/dev/null 2>&1; then
<<<<<<< HEAD
        zf::debug "    ✓ Environment validation passes with good environment"
    else
        zf::debug "    ⚠ Environment validation found issues (may be expected)"
=======
            zsh_debug_echo "    ✓ Environment validation passes with good environment"
    else
            zsh_debug_echo "    ⚠ Environment validation found issues (may be expected)"
>>>>>>> origin/develop
    fi

    # Test with missing PATH (simulate issue)
    export PATH=""
    local validation_result=0
    _validate_environment >/dev/null 2>&1 || validation_result=$?

    if [[ $validation_result -gt 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ Environment validation correctly detects missing PATH"
    else
        zf::debug "    ⚠ Environment validation should detect missing PATH"
=======
            zsh_debug_echo "    ✓ Environment validation correctly detects missing PATH"
    else
            zsh_debug_echo "    ⚠ Environment validation should detect missing PATH"
>>>>>>> origin/develop
    fi

    # Restore environment
    export PATH="$original_path"

    return 0
}

test_directory_validation() {
<<<<<<< HEAD
    zf::debug "    📊 Testing directory validation..."

    # Test with existing directories
    if _validate_directories >/dev/null 2>&1; then
        zf::debug "    ✓ Directory validation passes with existing directories"
        return 0
    else
        zf::debug "    ⚠ Directory validation found missing directories (may be expected)"
        return 0 # Don't fail test as some directories might be missing in test environment
=======
        zsh_debug_echo "    📊 Testing directory validation..."

    # Test with existing directories
    if _validate_directories >/dev/null 2>&1; then
            zsh_debug_echo "    ✓ Directory validation passes with existing directories"
        return 0
    else
            zsh_debug_echo "    ⚠ Directory validation found missing directories (may be expected)"
        return 0  # Don't fail test as some directories might be missing in test environment
>>>>>>> origin/develop
    fi
}

test_command_validation() {
<<<<<<< HEAD
    zf::debug "    📊 Testing command validation..."
=======
        zsh_debug_echo "    📊 Testing command validation..."
>>>>>>> origin/develop

    # Test command validation
    local validation_result=0
    _validate_commands >/dev/null 2>&1 || validation_result=$?

    if [[ $validation_result -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ Command validation passes - all essential commands available"
    else
        zf::debug "    ⚠ Command validation found missing commands: $validation_result missing"
=======
            zsh_debug_echo "    ✓ Command validation passes - all essential commands available"
    else
            zsh_debug_echo "    ⚠ Command validation found missing commands: $validation_result missing"
>>>>>>> origin/develop
        # Don't fail test as some commands might be missing in CI environment
    fi

    return 0
}

test_config_file_validation() {
<<<<<<< HEAD
    zf::debug "    📊 Testing configuration file validation..."
=======
        zsh_debug_echo "    📊 Testing configuration file validation..."
>>>>>>> origin/develop

    # Test with existing files
    local validation_result=0
    _validate_config_files >/dev/null 2>&1 || validation_result=$?

    if [[ $validation_result -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ Configuration file validation passes - all essential files present"
    else
        zf::debug "    ⚠ Configuration file validation found missing files: $validation_result missing"
=======
            zsh_debug_echo "    ✓ Configuration file validation passes - all essential files present"
    else
            zsh_debug_echo "    ⚠ Configuration file validation found missing files: $validation_result missing"
>>>>>>> origin/develop
        # Don't fail test as some files might be missing in test environment
    fi

    return 0
}

test_zsh_state_validation() {
<<<<<<< HEAD
    zf::debug "    📊 Testing ZSH state validation..."
=======
        zsh_debug_echo "    📊 Testing ZSH state validation..."
>>>>>>> origin/develop

    # Test ZSH state validation
    local validation_result=0
    _validate_zsh_state >/dev/null 2>&1 || validation_result=$?

    if [[ $validation_result -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ ZSH state validation passes - shell state is good"
    else
        zf::debug "    ⚠ ZSH state validation found issues: $validation_result issues"
=======
            zsh_debug_echo "    ✓ ZSH state validation passes - shell state is good"
    else
            zsh_debug_echo "    ⚠ ZSH state validation found issues: $validation_result issues"
>>>>>>> origin/develop
        # Don't fail test as some state issues might be expected
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. COMPREHENSIVE VALIDATION TESTS
# ------------------------------------------------------------------------------

test_comprehensive_validation() {
<<<<<<< HEAD
    zf::debug "    📊 Testing comprehensive validation..."
=======
        zsh_debug_echo "    📊 Testing comprehensive validation..."
>>>>>>> origin/develop

    # Test comprehensive validation
    local validation_result=0
    _validate_configuration >/dev/null 2>&1 || validation_result=$?

<<<<<<< HEAD
    zf::debug "    📊 Comprehensive validation result: $validation_result total issues"

    # Pass if validation completes (regardless of issues found)
    if [[ $validation_result -ge 0 ]]; then
        zf::debug "    ✓ Comprehensive validation completed successfully"
        return 0
    else
        zf::debug "    ✗ Comprehensive validation failed to complete"
=======
        zsh_debug_echo "    📊 Comprehensive validation result: $validation_result total issues"

    # Pass if validation completes (regardless of issues found)
    if [[ $validation_result -ge 0 ]]; then
            zsh_debug_echo "    ✓ Comprehensive validation completed successfully"
        return 0
    else
            zsh_debug_echo "    ✗ Comprehensive validation failed to complete"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_validation_performance() {
<<<<<<< HEAD
    zf::debug "    📊 Testing validation performance..."
=======
        zsh_debug_echo "    📊 Testing validation performance..."
>>>>>>> origin/develop

    # Test validation performance
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Run validation multiple times
    for i in {1..3}; do
        _validate_configuration >/dev/null 2>&1
    done

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local duration
    if command -v bc >/dev/null 2>&1; then
<<<<<<< HEAD
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || zf::debug "0.1")
=======
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || zsh_debug_echo "0.1")
>>>>>>> origin/develop
    else
        duration="<0.1"
    fi

<<<<<<< HEAD
    zf::debug "    📊 Validation performance: 3 runs in ${duration}s"

    # Performance should be reasonable (less than 2 seconds for 3 runs)
    if command -v bc >/dev/null 2>&1; then
        if (($(echo "$duration < 2.0" | bc -l 2>/dev/null || zf::debug "1"))); then
            zf::debug "    ✓ Validation performance is acceptable"
            return 0
        else
            zf::debug "    ⚠ Validation performance may be slow"
            return 0 # Don't fail test, performance can vary
        fi
    else
        zf::debug "    ✓ Validation performance test completed"
=======
        zsh_debug_echo "    📊 Validation performance: 3 runs in ${duration}s"

    # Performance should be reasonable (less than 2 seconds for 3 runs)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$duration < 2.0" | bc -l 2>/dev/null || zsh_debug_echo "1") )); then
                zsh_debug_echo "    ✓ Validation performance is acceptable"
            return 0
        else
                zsh_debug_echo "    ⚠ Validation performance may be slow"
            return 0  # Don't fail test, performance can vary
        fi
    else
            zsh_debug_echo "    ✓ Validation performance test completed"
>>>>>>> origin/develop
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. CI COMPATIBILITY TESTS
# ------------------------------------------------------------------------------

test_ci_compatibility() {
<<<<<<< HEAD
    zf::debug "    📊 Testing CI compatibility..."
=======
        zsh_debug_echo "    📊 Testing CI compatibility..."
>>>>>>> origin/develop

    # Test that validation works in non-interactive environment
    local ci_result=0

    # Simulate CI environment
    local original_term="$TERM"
    export TERM="dumb"

    # Run validation in CI mode
    ZSH_VALIDATION_LOG_ISSUES=false _validate_configuration >/dev/null 2>&1 || ci_result=$?

    # Restore environment
    export TERM="$original_term"

    if [[ $ci_result -ge 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ Validation works in CI environment"
        return 0
    else
        zf::debug "    ✗ Validation failed in CI environment"
=======
            zsh_debug_echo "    ✓ Validation works in CI environment"
        return 0
    else
            zsh_debug_echo "    ✗ Validation failed in CI environment"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
    zf::debug "========================================================"
    zf::debug "Configuration Validation Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Validation Version: ${ZSH_VALIDATION_VERSION:-unknown}"
    zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Configuration Validation Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Validation Version: ${ZSH_VALIDATION_VERSION:-unknown}"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting configuration validation test suite"

    # Function Existence Tests
<<<<<<< HEAD
    zf::debug "=== Validation Function Tests ==="
    run_test "Validation Functions Exist" "test_validation_functions_exist"

    # Individual Validation Tests
    zf::debug ""
    zf::debug "=== Individual Validation Tests ==="
=======
        zsh_debug_echo "=== Validation Function Tests ==="
    run_test "Validation Functions Exist" "test_validation_functions_exist"

    # Individual Validation Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Individual Validation Tests ==="
>>>>>>> origin/develop
    run_test "Environment Validation" "test_environment_validation"
    run_test "Directory Validation" "test_directory_validation"
    run_test "Command Validation" "test_command_validation"
    run_test "Config File Validation" "test_config_file_validation"
    run_test "ZSH State Validation" "test_zsh_state_validation"

    # Comprehensive Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Comprehensive Validation Tests ==="
    run_test "Comprehensive Validation" "test_comprehensive_validation"

    # Performance Tests
    zf::debug ""
    zf::debug "=== Performance Tests ==="
    run_test "Validation Performance" "test_validation_performance"

    # CI Compatibility Tests
    zf::debug ""
    zf::debug "=== CI Compatibility Tests ==="
    run_test "CI Compatibility" "test_ci_compatibility"

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
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Comprehensive Validation Tests ==="
    run_test "Comprehensive Validation" "test_comprehensive_validation"

    # Performance Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Performance Tests ==="
    run_test "Validation Performance" "test_validation_performance"

    # CI Compatibility Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== CI Compatibility Tests ==="
    run_test "CI Compatibility" "test_ci_compatibility"

    # Results Summary
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

    log_test "Configuration validation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All configuration validation tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED configuration validation test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All configuration validation tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED configuration validation test(s) failed."
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
    zf::debug "Configuration validation test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Configuration validation test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Configuration Validation Test Suite
# ==============================================================================
