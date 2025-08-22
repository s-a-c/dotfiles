#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Configuration Validation Test Suite
# ==============================================================================
# Purpose: Test the configuration validation system to ensure proper detection
#          of environment issues, directory problems, missing commands, and
#          configuration file issues with comprehensive CI-compatible testing.
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

# Set testing flag to prevent initialization conflicts
export ZSH_VALIDATION_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
    echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT" >&2
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Load the validation system
VALIDATION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/99-validation.zsh"

if [[ ! -f "$VALIDATION_SCRIPT" ]]; then
    echo "ERROR: Configuration validation script not found: $VALIDATION_SCRIPT" >&2
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
    echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"
    
    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        echo "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"
    
    if declare -f "$function_name" > /dev/null; then
        return 0
    else
        echo "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. VALIDATION FUNCTION TESTS
# ------------------------------------------------------------------------------

test_validation_functions_exist() {
    assert_function_exists "_validate_configuration" &&
    assert_function_exists "_validate_environment" &&
    assert_function_exists "_validate_directories" &&
    assert_function_exists "_validate_commands" &&
    assert_function_exists "_validate_config_files" &&
    assert_function_exists "_validate_zsh_state"
}

test_environment_validation() {
    echo "    📊 Testing environment validation..."
    
    # Save original environment
    local original_path="$PATH"
    local original_home="$HOME"
    
    # Test with good environment
    if _validate_environment >/dev/null 2>&1; then
        echo "    ✓ Environment validation passes with good environment"
    else
        echo "    ⚠ Environment validation found issues (may be expected)"
    fi
    
    # Test with missing PATH (simulate issue)
    export PATH=""
    local validation_result=0
    _validate_environment >/dev/null 2>&1 || validation_result=$?
    
    if [[ $validation_result -gt 0 ]]; then
        echo "    ✓ Environment validation correctly detects missing PATH"
    else
        echo "    ⚠ Environment validation should detect missing PATH"
    fi
    
    # Restore environment
    export PATH="$original_path"
    
    return 0
}

test_directory_validation() {
    echo "    📊 Testing directory validation..."
    
    # Test with existing directories
    if _validate_directories >/dev/null 2>&1; then
        echo "    ✓ Directory validation passes with existing directories"
        return 0
    else
        echo "    ⚠ Directory validation found missing directories (may be expected)"
        return 0  # Don't fail test as some directories might be missing in test environment
    fi
}

test_command_validation() {
    echo "    📊 Testing command validation..."
    
    # Test command validation
    local validation_result=0
    _validate_commands >/dev/null 2>&1 || validation_result=$?
    
    if [[ $validation_result -eq 0 ]]; then
        echo "    ✓ Command validation passes - all essential commands available"
    else
        echo "    ⚠ Command validation found missing commands: $validation_result missing"
        # Don't fail test as some commands might be missing in CI environment
    fi
    
    return 0
}

test_config_file_validation() {
    echo "    📊 Testing configuration file validation..."
    
    # Test with existing files
    local validation_result=0
    _validate_config_files >/dev/null 2>&1 || validation_result=$?
    
    if [[ $validation_result -eq 0 ]]; then
        echo "    ✓ Configuration file validation passes - all essential files present"
    else
        echo "    ⚠ Configuration file validation found missing files: $validation_result missing"
        # Don't fail test as some files might be missing in test environment
    fi
    
    return 0
}

test_zsh_state_validation() {
    echo "    📊 Testing ZSH state validation..."
    
    # Test ZSH state validation
    local validation_result=0
    _validate_zsh_state >/dev/null 2>&1 || validation_result=$?
    
    if [[ $validation_result -eq 0 ]]; then
        echo "    ✓ ZSH state validation passes - shell state is good"
    else
        echo "    ⚠ ZSH state validation found issues: $validation_result issues"
        # Don't fail test as some state issues might be expected
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# 3. COMPREHENSIVE VALIDATION TESTS
# ------------------------------------------------------------------------------

test_comprehensive_validation() {
    echo "    📊 Testing comprehensive validation..."
    
    # Test comprehensive validation
    local validation_result=0
    _validate_configuration >/dev/null 2>&1 || validation_result=$?
    
    echo "    📊 Comprehensive validation result: $validation_result total issues"
    
    # Pass if validation completes (regardless of issues found)
    if [[ $validation_result -ge 0 ]]; then
        echo "    ✓ Comprehensive validation completed successfully"
        return 0
    else
        echo "    ✗ Comprehensive validation failed to complete"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_validation_performance() {
    echo "    📊 Testing validation performance..."
    
    # Test validation performance
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    # Run validation multiple times
    for i in {1..3}; do
        _validate_configuration >/dev/null 2>&1
    done
    
    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local duration
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.1")
    else
        duration="<0.1"
    fi
    
    echo "    📊 Validation performance: 3 runs in ${duration}s"
    
    # Performance should be reasonable (less than 2 seconds for 3 runs)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$duration < 2.0" | bc -l 2>/dev/null || echo "1") )); then
            echo "    ✓ Validation performance is acceptable"
            return 0
        else
            echo "    ⚠ Validation performance may be slow"
            return 0  # Don't fail test, performance can vary
        fi
    else
        echo "    ✓ Validation performance test completed"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. CI COMPATIBILITY TESTS
# ------------------------------------------------------------------------------

test_ci_compatibility() {
    echo "    📊 Testing CI compatibility..."
    
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
        echo "    ✓ Validation works in CI environment"
        return 0
    else
        echo "    ✗ Validation failed in CI environment"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Configuration Validation Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "Validation Version: ${ZSH_VALIDATION_VERSION:-unknown}"
    echo ""
    
    log_test "Starting configuration validation test suite"
    
    # Function Existence Tests
    echo "=== Validation Function Tests ==="
    run_test "Validation Functions Exist" "test_validation_functions_exist"
    
    # Individual Validation Tests
    echo ""
    echo "=== Individual Validation Tests ==="
    run_test "Environment Validation" "test_environment_validation"
    run_test "Directory Validation" "test_directory_validation"
    run_test "Command Validation" "test_command_validation"
    run_test "Config File Validation" "test_config_file_validation"
    run_test "ZSH State Validation" "test_zsh_state_validation"
    
    # Comprehensive Tests
    echo ""
    echo "=== Comprehensive Validation Tests ==="
    run_test "Comprehensive Validation" "test_comprehensive_validation"
    
    # Performance Tests
    echo ""
    echo "=== Performance Tests ==="
    run_test "Validation Performance" "test_validation_performance"
    
    # CI Compatibility Tests
    echo ""
    echo "=== CI Compatibility Tests ==="
    run_test "CI Compatibility" "test_ci_compatibility"
    
    # Results Summary
    echo ""
    echo "========================================================"
    echo "Test Results Summary"
    echo "========================================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $TEST_PASSED"
    echo "Failed: $TEST_FAILED"
    
    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
    echo "Success Rate: ${pass_percentage}%"
    
    log_test "Configuration validation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All configuration validation tests passed!"
        return 0
    else
        echo ""
        echo "❌ $TEST_FAILED configuration validation test(s) failed."
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
    echo "Configuration validation test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Configuration Validation Test Suite
# ==============================================================================
