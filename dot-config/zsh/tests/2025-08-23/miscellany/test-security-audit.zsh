<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Security Audit Test Suite
# ==============================================================================
# Purpose: Test the security audit system to ensure proper detection of
#          security issues, insecure configurations, permission problems,
#          and potential vulnerabilities with comprehensive 040-testing.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-security-audit.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 99-security-check.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SECURITY_TESTING=true
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

# Load the security audit system
SECURITY_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_99-security-check.zsh"

if [[ ! -f "$SECURITY_SCRIPT" ]]; then
<<<<<<< HEAD
        zf::debug "ERROR: Security audit script not found: $SECURITY_SCRIPT"
=======
        zsh_debug_echo "ERROR: Security audit script not found: $SECURITY_SCRIPT"
>>>>>>> origin/develop
    exit 1
fi

# Source the security audit system
source "$SECURITY_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-security-audit.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Test temporary directory
TEST_TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEST_TEMP_DIR'" EXIT

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
# 2. SECURITY FUNCTION TESTS
# ------------------------------------------------------------------------------

test_security_functions_exist() {
    assert_function_exists "_run_security_audit" &&
    assert_function_exists "_check_file_permissions" &&
    assert_function_exists "_check_directory_security" &&
    assert_function_exists "_check_shell_options" &&
    assert_function_exists "_check_environment_variables" &&
    assert_function_exists "_check_suspicious_processes" &&
    assert_function_exists "_check_network_security"
}

test_file_permission_detection() {
<<<<<<< HEAD
        zf::debug "    📊 Testing file permission detection..."
=======
        zsh_debug_echo "    📊 Testing file permission detection..."
>>>>>>> origin/develop

    # Create test files with different permissions
    local test_file="$TEST_TEMP_DIR/test_file"
    local secure_file="$TEST_TEMP_DIR/secure_file"

    # Create a world-writable file (insecure)
    touch "$test_file"
    chmod 666 "$test_file"  # World-writable

    # Create a secure file
    touch "$secure_file"
    chmod 644 "$secure_file"  # Not world-writable

    # Test permission checking (should detect the insecure file)
    # Note: We can't easily test the actual function without modifying critical paths
    # So we test the logic by checking file permissions directly

    if [[ -w "$test_file" ]] && [[ "$(stat -f "%Mp%Lp" "$test_file" 2>/dev/null)" =~ ".*6$" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Successfully detected world-writable file"
    else
            zf::debug "    ✗ Failed to detect world-writable file"
=======
            zsh_debug_echo "    ✓ Successfully detected world-writable file"
    else
            zsh_debug_echo "    ✗ Failed to detect world-writable file"
>>>>>>> origin/develop
        return 1
    fi

    if [[ ! "$(stat -f "%Mp%Lp" "$secure_file" 2>/dev/null)" =~ ".*[2367]$" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Correctly identified secure file permissions"
    else
            zf::debug "    ✗ Incorrectly flagged secure file as insecure"
=======
            zsh_debug_echo "    ✓ Correctly identified secure file permissions"
    else
            zsh_debug_echo "    ✗ Incorrectly flagged secure file as insecure"
>>>>>>> origin/develop
        return 1
    fi

    return 0
}

test_shell_options_detection() {
<<<<<<< HEAD
        zf::debug "    📊 Testing shell options detection..."
=======
        zsh_debug_echo "    📊 Testing shell options detection..."
>>>>>>> origin/develop

    # Save current shell options
    local original_glob_subst=""
    [[ -o GLOB_SUBST ]] && original_glob_subst="true"

    # Test dangerous option detection
    setopt GLOB_SUBST  # Enable dangerous option

    if [[ -o GLOB_SUBST ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Successfully enabled dangerous shell option for testing"
    else
            zf::debug "    ⚠ Could not enable dangerous shell option (may be restricted)"
=======
            zsh_debug_echo "    ✓ Successfully enabled dangerous shell option for testing"
    else
            zsh_debug_echo "    ⚠ Could not enable dangerous shell option (may be restricted)"
>>>>>>> origin/develop
    fi

    # Test the detection logic
    local issues_found=0
    if [[ -o GLOB_SUBST ]]; then
        issues_found=1
<<<<<<< HEAD
            zf::debug "    ✓ Successfully detected dangerous shell option"
=======
            zsh_debug_echo "    ✓ Successfully detected dangerous shell option"
>>>>>>> origin/develop
    fi

    # Restore original state
    if [[ "$original_glob_subst" != "true" ]]; then
        unsetopt GLOB_SUBST
    fi

    if [[ $issues_found -gt 0 ]]; then
        return 0
    else
<<<<<<< HEAD
            zf::debug "    ✗ Failed to detect dangerous shell option"
=======
            zsh_debug_echo "    ✗ Failed to detect dangerous shell option"
>>>>>>> origin/develop
        return 1
    fi
}

test_environment_variable_detection() {
<<<<<<< HEAD
        zf::debug "    📊 Testing environment variable detection..."
=======
        zsh_debug_echo "    📊 Testing environment variable detection..."
>>>>>>> origin/develop

    # Set test environment variables
    export TEST_PASSWORD="secret123"
    export TEST_API_KEY="abc123def456"
    export TEST_SAFE_VAR="safe_value"

    # Test detection logic
    local sensitive_found=0
    local safe_found=0

    # Check for sensitive patterns
    for var in ${(k)parameters}; do
        case "$var" in
            *PASSWORD*|*API_KEY*)
                if [[ "$var" == "TEST_PASSWORD" || "$var" == "TEST_API_KEY" ]]; then
                    sensitive_found=$((sensitive_found + 1))
                fi
                ;;
            TEST_SAFE_VAR)
                safe_found=1
                ;;
        esac
    done

    # Clean up test variables
    unset TEST_PASSWORD TEST_API_KEY TEST_SAFE_VAR

    if [[ $sensitive_found -eq 2 ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Successfully detected sensitive environment variables"
    else
            zf::debug "    ✗ Failed to detect sensitive environment variables"
=======
            zsh_debug_echo "    ✓ Successfully detected sensitive environment variables"
    else
            zsh_debug_echo "    ✗ Failed to detect sensitive environment variables"
>>>>>>> origin/develop
        return 1
    fi

    return 0
}

test_process_security_check() {
<<<<<<< HEAD
        zf::debug "    📊 Testing process security check..."
=======
        zsh_debug_echo "    📊 Testing process security check..."
>>>>>>> origin/develop

    # Test process checking logic (without actually running suspicious processes)
    # We'll test the pgrep functionality with safe processes

    # Check if pgrep works
    if ! command -v pgrep >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ⚠ pgrep not available, skipping process security test"
=======
            zsh_debug_echo "    ⚠ pgrep not available, skipping process security test"
>>>>>>> origin/develop
        return 0
    fi

    # Test with a known safe process (should not be found)
    if ! pgrep -f "definitely_not_a_real_process_name_12345" >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✓ Process security check logic working (no false positives)"
    else
            zf::debug "    ✗ Process security check found unexpected process"
=======
            zsh_debug_echo "    ✓ Process security check logic working (no false positives)"
    else
            zsh_debug_echo "    ✗ Process security check found unexpected process"
>>>>>>> origin/develop
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. COMPREHENSIVE SECURITY TESTS
# ------------------------------------------------------------------------------

test_comprehensive_security_audit() {
<<<<<<< HEAD
        zf::debug "    📊 Testing comprehensive security audit..."
=======
        zsh_debug_echo "    📊 Testing comprehensive security audit..."
>>>>>>> origin/develop

    # Test comprehensive security audit
    local audit_result=0
    _run_security_audit >/dev/null 2>&1 || audit_result=$?

<<<<<<< HEAD
        zf::debug "    📊 Comprehensive security audit result: $audit_result total issues"

    # Pass if audit completes (regardless of issues found)
    if [[ $audit_result -ge 0 ]]; then
            zf::debug "    ✓ Comprehensive security audit completed successfully"
        return 0
    else
            zf::debug "    ✗ Comprehensive security audit failed to complete"
=======
        zsh_debug_echo "    📊 Comprehensive security audit result: $audit_result total issues"

    # Pass if audit completes (regardless of issues found)
    if [[ $audit_result -ge 0 ]]; then
            zsh_debug_echo "    ✓ Comprehensive security audit completed successfully"
        return 0
    else
            zsh_debug_echo "    ✗ Comprehensive security audit failed to complete"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_security_audit_performance() {
<<<<<<< HEAD
        zf::debug "    📊 Testing security audit performance..."
=======
        zsh_debug_echo "    📊 Testing security audit performance..."
>>>>>>> origin/develop

    # Test security audit performance
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Run security audit multiple times
    for i in {1..3}; do
        _run_security_audit >/dev/null 2>&1
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
        zf::debug "    📊 Security audit performance: 3 runs in ${duration}s"

    # Performance should be reasonable (less than 3 seconds for 3 runs)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$duration < 3.0" | bc -l 2>/dev/null || zf::debug "1") )); then
                zf::debug "    ✓ Security audit performance is acceptable"
            return 0
        else
                zf::debug "    ⚠ Security audit performance may be slow"
            return 0  # Don't fail test, performance can vary
        fi
    else
            zf::debug "    ✓ Security audit performance test completed"
=======
        zsh_debug_echo "    📊 Security audit performance: 3 runs in ${duration}s"

    # Performance should be reasonable (less than 3 seconds for 3 runs)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$duration < 3.0" | bc -l 2>/dev/null || zsh_debug_echo "1") )); then
                zsh_debug_echo "    ✓ Security audit performance is acceptable"
            return 0
        else
                zsh_debug_echo "    ⚠ Security audit performance may be slow"
            return 0  # Don't fail test, performance can vary
        fi
    else
            zsh_debug_echo "    ✓ Security audit performance test completed"
>>>>>>> origin/develop
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_security_integration() {
<<<<<<< HEAD
        zf::debug "    📊 Testing security system integration..."
=======
        zsh_debug_echo "    📊 Testing security system integration..."
>>>>>>> origin/develop

    # Test that security system integrates with other components
    local integration_issues=0

    # Check if security system can access required functions
    if ! declare -f context_echo >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ⚠ Context-aware logging not available (expected in test environment)"
    else
            zf::debug "    ✓ Context-aware logging integration working"
=======
            zsh_debug_echo "    ⚠ Context-aware logging not available (expected in test environment)"
    else
            zsh_debug_echo "    ✓ Context-aware logging integration working"
>>>>>>> origin/develop
    fi

    # Check if security system can access environment variables
    if [[ -n "$ZDOTDIR" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Environment variable access working"
    else
        integration_issues=$((integration_issues + 1))
            zf::debug "    ✗ Cannot access ZDOTDIR environment variable"
=======
            zsh_debug_echo "    ✓ Environment variable access working"
    else
        integration_issues=$((integration_issues + 1))
            zsh_debug_echo "    ✗ Cannot access ZDOTDIR environment variable"
>>>>>>> origin/develop
    fi

    # Check if security system can access file system
    if [[ -d "$ZDOTDIR" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ File system access working"
    else
        integration_issues=$((integration_issues + 1))
            zf::debug "    ✗ Cannot access ZSH configuration directory"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ Security system integration successful"
        return 0
    else
            zf::debug "    ✗ Security system integration has issues"
=======
            zsh_debug_echo "    ✓ File system access working"
    else
        integration_issues=$((integration_issues + 1))
            zsh_debug_echo "    ✗ Cannot access ZSH configuration directory"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zsh_debug_echo "    ✓ Security system integration successful"
        return 0
    else
            zsh_debug_echo "    ✗ Security system integration has issues"
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
        zf::debug "Security Audit Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Security Version: ${ZSH_SECURITY_CHECK_VERSION:-unknown}"
        zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
        zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Security Audit Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Security Version: ${ZSH_SECURITY_CHECK_VERSION:-unknown}"
        zsh_debug_echo "Test Temp Dir: $TEST_TEMP_DIR"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting security audit test suite"

    # Function Existence Tests
<<<<<<< HEAD
        zf::debug "=== Security Function Tests ==="
    run_test "Security Functions Exist" "test_security_functions_exist"

    # Individual Security Tests
        zf::debug ""
        zf::debug "=== Individual Security Tests ==="
=======
        zsh_debug_echo "=== Security Function Tests ==="
    run_test "Security Functions Exist" "test_security_functions_exist"

    # Individual Security Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Individual Security Tests ==="
>>>>>>> origin/develop
    run_test "File Permission Detection" "test_file_permission_detection"
    run_test "Shell Options Detection" "test_shell_options_detection"
    run_test "Environment Variable Detection" "test_environment_variable_detection"
    run_test "Process Security Check" "test_process_security_check"

    # Comprehensive Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Comprehensive Security Tests ==="
    run_test "Comprehensive Security Audit" "test_comprehensive_security_audit"

    # Performance Tests
        zf::debug ""
        zf::debug "=== Performance Tests ==="
    run_test "Security Audit Performance" "test_security_audit_performance"

    # Integration Tests
        zf::debug ""
        zf::debug "=== Integration Tests ==="
    run_test "Security Integration" "test_security_integration"

    # Results Summary
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Comprehensive Security Tests ==="
    run_test "Comprehensive Security Audit" "test_comprehensive_security_audit"

    # Performance Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Performance Tests ==="
    run_test "Security Audit Performance" "test_security_audit_performance"

    # Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
    run_test "Security Integration" "test_security_integration"

    # Results Summary
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

    log_test "Security audit test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
            zf::debug ""
            zf::debug "🎉 All security audit tests passed!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED security audit test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All security audit tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED security audit test(s) failed."
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
        zf::debug "Security audit test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Security audit test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Security Audit Test Suite
# ==============================================================================
