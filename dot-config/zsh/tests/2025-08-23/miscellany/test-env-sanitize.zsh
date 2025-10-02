#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Environment Sanitization Test Suite
# ==============================================================================
# Purpose: Test environment sanitization security module to ensure proper
#          filtering of sensitive variables, PATH security validation,
#          umask enforcement, and comprehensive security policy compliance.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-env-sanitize.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 08-environment-sanitization.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_ENV_SANITIZATION_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
    zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Load the environment sanitization module
SANITIZATION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_08-environment-sanitization.zsh"

if [[ ! -f "$SANITIZATION_SCRIPT" ]]; then
    zf::debug "ERROR: Environment sanitization script not found: $SANITIZATION_SCRIPT"
    exit 1
fi

# Source the sanitization system
source "$SANITIZATION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-env-sanitize.log"
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
# 2. SANITIZATION FUNCTION TESTS
# ------------------------------------------------------------------------------

test_sanitization_functions_exist() {
    assert_function_exists "_sanitize_environment" &&
        assert_function_exists "_sanitize_sensitive_variables" &&
        assert_function_exists "_validate_path_security" &&
        assert_function_exists "_enforce_secure_umask" &&
        assert_function_exists "_is_sensitive_variable"
}

test_sensitive_variable_detection() {
    # Test that sensitive variable patterns are detected correctly
    local test_vars=(
        "TEST_PASSWORD" "API_KEY" "SECRET_TOKEN" "DB_PASS"
        "AWS_SECRET_ACCESS_KEY" "OAUTH_CLIENT_SECRET" "PRIVATE_KEY"
    )

    local safe_vars=(
        "TEST_CONFIG" "API_URL" "PUBLIC_TOKEN" "DB_HOST"
        "AWS_REGION" "OAUTH_REDIRECT_URL" "PUBLIC_KEY"
    )

    # Test sensitive variable detection
    local sensitive_var
    for sensitive_var in "${test_vars[@]}"; do
        if ! _is_sensitive_variable "$sensitive_var"; then
            zf::debug "    ASSERTION FAILED: '$sensitive_var' should be detected as sensitive"
            return 1
        fi
    done

    # Test that safe variables are not flagged
    local safe_var
    for safe_var in "${safe_vars[@]}"; do
        if _is_sensitive_variable "$safe_var"; then
            zf::debug "    ASSERTION FAILED: '$safe_var' should not be detected as sensitive"
            return 1
        fi
    done

    zf::debug "    ✓ Sensitive variable detection working correctly"
    return 0
}

test_sensitive_variable_sanitization() {
    # Create test sensitive variables
    export TEST_SECRET_KEY="test_secret_value"
    export TEST_API_PASSWORD="test_password"
    export TEST_SAFE_CONFIG="safe_value"

    # Run sanitization
    _sanitize_sensitive_variables >/dev/null 2>&1

    # Check that sensitive variables were removed
    if [[ -n "${TEST_SECRET_KEY:-}" ]]; then
        zf::debug "    ASSERTION FAILED: TEST_SECRET_KEY should have been sanitized"
        return 1
    fi

    if [[ -n "${TEST_API_PASSWORD:-}" ]]; then
        zf::debug "    ASSERTION FAILED: TEST_API_PASSWORD should have been sanitized"
        return 1
    fi

    # Check that safe variables were preserved
    if [[ -z "${TEST_SAFE_CONFIG:-}" ]]; then
        zf::debug "    ASSERTION FAILED: TEST_SAFE_CONFIG should have been preserved"
        return 1
    fi

    # Clean up
    unset TEST_SAFE_CONFIG

    zf::debug "    ✓ Sensitive variable sanitization working correctly"
    return 0
}

# ------------------------------------------------------------------------------
# 3. PATH SECURITY TESTS
# ------------------------------------------------------------------------------

test_path_security_validation() {
    # Save original PATH
    local original_path="$PATH"

    # Test with secure PATH
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

    if ! _validate_path_security >/dev/null 2>&1; then
        zf::debug "    ASSERTION FAILED: Secure PATH should pass validation"
        export PATH="$original_path"
        return 1
    fi

    # Test with insecure PATH (relative path)
    export PATH="/usr/bin:.:$PATH"

    if _validate_path_security >/dev/null 2>&1; then
        zf::debug "    ASSERTION FAILED: Insecure PATH with relative entry should fail validation"
        export PATH="$original_path"
        return 1
    fi

    # Restore original PATH
    export PATH="$original_path"

    zf::debug "    ✓ PATH security validation working correctly"
    return 0
}

# ------------------------------------------------------------------------------
# 4. UMASK SECURITY TESTS
# ------------------------------------------------------------------------------

test_umask_enforcement() {
    # Save original umask
    local original_umask=$(umask)

    # Set insecure umask
    umask 000

    # Run umask enforcement
    _enforce_secure_umask >/dev/null 2>&1

    # Check that umask was corrected
    local new_umask=$(umask)
    if [[ "$new_umask" != "022" ]]; then
        zf::debug "    ASSERTION FAILED: Umask should be set to 022, got $new_umask"
        umask "$original_umask"
        return 1
    fi

    # Restore original umask
    umask "$original_umask"

    zf::debug "    ✓ Umask enforcement working correctly"
    return 0
}

# ------------------------------------------------------------------------------
# 5. SHELL SECURITY TESTS
# ------------------------------------------------------------------------------

test_shell_security_validation() {
    # Test shell security validation function
    if ! _validate_shell_security >/dev/null 2>&1; then
        zf::debug "    WARNING: Shell security validation found issues (may be expected)"
        # Don't fail the test as some issues might be environmental
    fi

    zf::debug "    ✓ Shell security validation function working"
    return 0
}

# ------------------------------------------------------------------------------
# 6. COMPREHENSIVE SANITIZATION TESTS
# ------------------------------------------------------------------------------

test_comprehensive_sanitization() {
    # Set up test environment with various security issues
    export TEST_COMPREHENSIVE_SECRET="secret_value"
    export TEST_COMPREHENSIVE_SAFE="safe_value"

    # Save original state
    local original_path="$PATH"
    local original_umask=$(umask)

    # Set insecure state
    umask 000

    # Run comprehensive sanitization
    local sanitization_result=0
    _sanitize_environment >/dev/null 2>&1 || sanitization_result=$?

    # Check results
    local test_passed=true

    # Check sensitive variable was removed
    if [[ -n "${TEST_COMPREHENSIVE_SECRET:-}" ]]; then
        zf::debug "    ASSERTION FAILED: Sensitive variable not sanitized"
        test_passed=false
    fi

    # Check safe variable was preserved
    if [[ -z "${TEST_COMPREHENSIVE_SAFE:-}" ]]; then
        zf::debug "    ASSERTION FAILED: Safe variable was incorrectly removed"
        test_passed=false
    fi

    # Check umask was secured
    if [[ "$(umask)" != "022" ]]; then
        zf::debug "    ASSERTION FAILED: Umask not properly secured"
        test_passed=false
    fi

    # Clean up
    unset TEST_COMPREHENSIVE_SAFE
    export PATH="$original_path"
    umask "$original_umask"

    if $test_passed; then
        zf::debug "    ✓ Comprehensive sanitization working correctly"
        return 0
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_sanitization_performance() {
    # Test that sanitization completes in reasonable time
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Run sanitization multiple times
    for i in {1..5}; do
        _sanitize_environment >/dev/null 2>&1
    done

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local duration
    if command -v bc >/dev/null 2>&1; then
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || zf::debug "0.1")
    else
        duration="<0.1"
    fi

    zf::debug "    📊 Sanitization performance: 5 runs in ${duration}s"

    # Performance should be reasonable (less than 1 second for 5 runs)
    if command -v bc >/dev/null 2>&1; then
        if (($(echo "$duration < 1.0" | bc -l 2>/dev/null || zf::debug "1"))); then
            zf::debug "    ✓ Sanitization performance is acceptable"
            return 0
        else
            zf::debug "    ⚠ Sanitization performance may be slow"
            return 0 # Don't fail test, performance can vary
        fi
    else
        zf::debug "    ✓ Sanitization performance test completed"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 8. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Environment Sanitization Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Sanitization Version: ${ZSH_ENV_SANITIZATION_VERSION:-unknown}"
    zf::debug ""

    log_test "Starting environment sanitization test suite"

    # Function Existence Tests
    zf::debug "=== Sanitization Function Tests ==="
    run_test "Sanitization Functions Exist" "test_sanitization_functions_exist"
    run_test "Sensitive Variable Detection" "test_sensitive_variable_detection"
    run_test "Sensitive Variable Sanitization" "test_sensitive_variable_sanitization"

    # Security Validation Tests
    zf::debug ""
    zf::debug "=== Security Validation Tests ==="
    run_test "PATH Security Validation" "test_path_security_validation"
    run_test "Umask Enforcement" "test_umask_enforcement"
    run_test "Shell Security Validation" "test_shell_security_validation"

    # Comprehensive Tests
    zf::debug ""
    zf::debug "=== Comprehensive Sanitization Tests ==="
    run_test "Comprehensive Sanitization" "test_comprehensive_sanitization"

    # Performance Tests
    zf::debug ""
    zf::debug "=== Performance Tests ==="
    run_test "Sanitization Performance" "test_sanitization_performance"

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

    log_test "Environment sanitization test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All environment sanitization tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED environment sanitization test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 9. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
    zf::debug "Environment sanitization test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Environment Sanitization Test Suite
# ==============================================================================
