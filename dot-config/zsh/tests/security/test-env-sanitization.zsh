#!/usr/bin/env zsh
#=============================================================================
# File: test-env-sanitization.zsh
# Purpose: Comprehensive test suite for environment sanitization system
# Dependencies: None (pure zsh)
# Author: Configuration management system
# Last Modified: 2025-08-21
#
# Test Coverage:
# - PATH security validation and sanitization
# - Sensitive environment variable detection and filtering
# - Secure umask enforcement
# - Privilege escalation detection
# - Security level configuration (STRICT, WARN, DISABLED)
# - Logging and audit trail validation
#=============================================================================

# Test Configuration
TEST_NAME="Environment Sanitization"
TEST_DIR="/tmp/zsh-env-sanitization-test-$$"
ORIGINAL_PWD="$(pwd)"

# Test Results Tracking
declare -A test_results
test_count=0
passed_count=0
failed_count=0

# Logging setup per user rules - UTC timestamps in date-named subdirs
TEST_LOG_DIR="$HOME/.config/zsh/logs/$(date -u +%Y-%m-%d)"
TEST_LOG_FILE="$TEST_LOG_DIR/test-env-sanitization-$(date -u +%H%M%S).log"
mkdir -p "$TEST_LOG_DIR" 2>/dev/null || true

# Ensure working directory restoration per user rules
trap 'cd "$ORIGINAL_PWD" 2>/dev/null || true; cleanup_test_environment' EXIT

log_test() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "[$timestamp] [$level] $message" | tee -a "$TEST_LOG_FILE" 2>/dev/null || echo "[$timestamp] [$level] $message"
}

setup_test_environment() {
    log_test "INFO" "Setting up environment sanitization test environment in $TEST_DIR"
    
    # Create test directory structure
    mkdir -p "$TEST_DIR"/{secure,insecure,logs}
    cd "$TEST_DIR" || return 1
    
    # Create insecure test directories
    mkdir -p "insecure/world-writable"
    chmod 777 "insecure/world-writable"  # World-writable directory
    
    # Create secure test directory
    mkdir -p "secure/safe"
    chmod 755 "secure/safe"
    
    # Set up test environment variables
    export ZSH_ENV_TESTING="true"  # Disable auto-initialization
    export ZSH_ENV_SECURITY_LEVEL="WARN"  # Start with warn mode
    export ZSH_ENV_SECURITY_LOG="$TEST_DIR/logs/env-security.log"
    export ZSH_ENV_SECURE_UMASK="022"
    export ZSH_ENV_SECURITY_VERBOSE="true"
    
    # Create log directory
    mkdir -p "$(dirname "$ZSH_ENV_SECURITY_LOG")"
    
    # Store original environment state
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_UMASK="$(umask)"
    
    # Check if sanitization script exists
    local sanitization_script="$HOME/.config/zsh/.zshrc.pre-plugins.d/05-environment-sanitization.zsh"
    if [[ ! -f "$sanitization_script" ]]; then
        log_test "ERROR" "Environment sanitization script not found at $sanitization_script"
        return 1
    fi
    
    # Source the environment sanitization system with verbose debugging
    echo "Attempting to source: $sanitization_script"
    if ! source "$sanitization_script"; then
        log_test "ERROR" "Failed to source environment sanitization system"
        return 1
    fi
    
    log_test "INFO" "Test environment setup complete"
    return 0
}

cleanup_test_environment() {
    log_test "INFO" "Cleaning up test environment"
    
    # Restore original directory per user rules
    cd "$ORIGINAL_PWD" 2>/dev/null || true
    
    # Restore original environment
    if [[ -n "$ORIGINAL_PATH" ]]; then
        export PATH="$ORIGINAL_PATH"
    fi
    
    if [[ -n "$ORIGINAL_UMASK" ]]; then
        umask "$ORIGINAL_UMASK"
    fi
    
    # Clean up test directory
    if [[ -d "$TEST_DIR" && "$TEST_DIR" =~ ^/tmp/zsh-env-sanitization-test- ]]; then
        rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    
    # Unset test environment variables
    unset ZSH_ENV_SECURITY_LEVEL ZSH_ENV_SECURITY_LOG ZSH_ENV_SECURE_UMASK
    unset ORIGINAL_PATH ORIGINAL_UMASK
    
    log_test "INFO" "Test environment cleanup complete"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((test_count++))
    log_test "INFO" "Running test $test_count: $test_name"
    
    # Run the test function directly in zsh
    if $test_function; then
        test_results[$test_count]="PASS"
        ((passed_count++))
        log_test "PASS" "Test $test_count: $test_name - PASSED"
        echo "✅ Test $test_count: $test_name - PASSED"
    else
        test_results[$test_count]="FAIL"
        ((failed_count++))
        log_test "FAIL" "Test $test_count: $test_name - FAILED"
        echo "❌ Test $test_count: $test_name - FAILED"
    fi
}

# Test 1: PATH Security Validation
test_path_security_validation() {
    log_test "INFO" "Testing PATH security validation"
    
    # Test secure PATH
    local secure_path="/usr/bin:/bin:/usr/sbin:/sbin"
    if ! _validate_path_security "$secure_path" >/dev/null 2>&1; then
        log_test "ERROR" "Secure PATH failed validation"
        return 1
    fi
    
    # Test insecure PATH with current directory
    local insecure_path=".:$secure_path"
    if _validate_path_security "$insecure_path" >/dev/null 2>&1; then
        log_test "ERROR" "Insecure PATH (with .) passed validation"
        return 1
    fi
    
    # Test PATH with empty components
    local empty_path="/usr/bin::/bin"
    if _validate_path_security "$empty_path" >/dev/null 2>&1; then
        log_test "ERROR" "PATH with empty components passed validation"
        return 1
    fi
    
    # Test PATH with /tmp
    local tmp_path="/usr/bin:/tmp:/bin"
    if _validate_path_security "$tmp_path" >/dev/null 2>&1; then
        log_test "ERROR" "PATH with /tmp passed validation"
        return 1
    fi
    
    log_test "INFO" "PATH security validation test successful"
    return 0
}

# Test 2: PATH Sanitization
test_path_sanitization() {
    log_test "INFO" "Testing PATH sanitization"
    
    # Create test PATH with insecure components
    local original_path=".:$TEST_DIR/insecure/world-writable:/usr/bin:/tmp:/bin:..:$TEST_DIR/secure/safe"
    
    # Sanitize the PATH
    local sanitized_path="$(_sanitize_path "$original_path")"
    
    # Verify insecure components were removed
    if [[ "$sanitized_path" == *"."* ]]; then
        log_test "ERROR" "Current directory (.) not removed from PATH"
        return 1
    fi
    
    if [[ "$sanitized_path" == *"/tmp"* ]]; then
        log_test "ERROR" "/tmp not removed from PATH"
        return 1
    fi
    
    if [[ "$sanitized_path" == *"world-writable"* ]]; then
        log_test "ERROR" "World-writable directory not removed from PATH"
        return 1
    fi
    
    # Verify secure components were kept
    if [[ "$sanitized_path" != *"/usr/bin"* ]]; then
        log_test "ERROR" "Secure component /usr/bin was removed"
        return 1
    fi
    
    if [[ "$sanitized_path" != *"$TEST_DIR/secure/safe"* ]]; then
        log_test "ERROR" "Secure test directory was removed"
        return 1
    fi
    
    log_test "INFO" "PATH sanitization test successful"
    return 0
}

# Test 3: Sensitive Variable Detection
test_sensitive_variable_detection() {
    log_test "INFO" "Testing sensitive variable detection"
    
    # Set up test sensitive variables
    export TEST_PASSWORD="secret123"
    export API_TOKEN="abc123def456"
    export SECRET_KEY="mysecretkey"
    export SAFE_VAR="not_sensitive"
    
    # Get list of sensitive variables
    local sensitive_vars
    sensitive_vars="$(_find_sensitive_variables)"
    
    # Check that sensitive variables were detected
    if ! echo "$sensitive_vars" | grep -q "TEST_PASSWORD"; then
        log_test "ERROR" "TEST_PASSWORD not detected as sensitive"
        return 1
    fi
    
    if ! echo "$sensitive_vars" | grep -q "API_TOKEN"; then
        log_test "ERROR" "API_TOKEN not detected as sensitive"
        return 1
    fi
    
    if ! echo "$sensitive_vars" | grep -q "SECRET_KEY"; then
        log_test "ERROR" "SECRET_KEY not detected as sensitive"
        return 1
    fi
    
    # Check that safe variable was not detected
    if echo "$sensitive_vars" | grep -q "SAFE_VAR"; then
        log_test "ERROR" "SAFE_VAR incorrectly detected as sensitive"
        return 1
    fi
    
    # Clean up test variables
    unset TEST_PASSWORD API_TOKEN SECRET_KEY SAFE_VAR
    
    log_test "INFO" "Sensitive variable detection test successful"
    return 0
}

# Test 4: Sensitive Variable Removal
test_sensitive_variable_removal() {
    log_test "INFO" "Testing sensitive variable removal"
    
    # Set up test variables
    export TEST_PASSWORD="secret123"
    export API_TOKEN="abc123def456"
    export SAFE_VAR="not_sensitive"
    
    # Remove sensitive variables
    _sanitize_sensitive_variables "remove" >/dev/null 2>&1
    
    # Check that sensitive variables were removed
    if [[ -n "${TEST_PASSWORD:-}" ]]; then
        log_test "ERROR" "TEST_PASSWORD was not removed"
        return 1
    fi
    
    if [[ -n "${API_TOKEN:-}" ]]; then
        log_test "ERROR" "API_TOKEN was not removed"
        return 1
    fi
    
    # Check that safe variable was not removed
    if [[ -z "${SAFE_VAR:-}" ]]; then
        log_test "ERROR" "SAFE_VAR was incorrectly removed"
        return 1
    fi
    
    # Clean up
    unset SAFE_VAR
    
    log_test "INFO" "Sensitive variable removal test successful"
    return 0
}

# Test 5: Umask Security Enforcement
test_umask_enforcement() {
    log_test "INFO" "Testing umask security enforcement"
    
    # Set an insecure umask
    umask 000
    
    # Enforce secure umask
    if _enforce_secure_umask; then
        log_test "ERROR" "Umask enforcement should have detected insecure umask"
        return 1
    fi
    
    # Check that umask was changed
    local current_umask="$(umask)"
    if [[ "$current_umask" != "022" ]]; then
        log_test "ERROR" "Umask was not set to secure value (got: $current_umask, expected: 022)"
        return 1
    fi
    
    # Test with already secure umask
    if ! _enforce_secure_umask; then
        log_test "ERROR" "Umask enforcement failed with already secure umask"
        return 1
    fi
    
    log_test "INFO" "Umask enforcement test successful"
    return 0
}

# Test 6: Privilege Escalation Detection
test_privilege_escalation_detection() {
    log_test "INFO" "Testing privilege escalation detection"
    
    # Test root detection (should not be root in normal testing)
    local priv_violations
    priv_violations="$(_check_privilege_escalation)"
    
    # In normal testing, we shouldn't be root
    if [[ "$EUID" -eq 0 ]]; then
        if ! echo "$priv_violations" | grep -q "Running as root"; then
            log_test "ERROR" "Root user detection failed"
            return 1
        fi
    fi
    
    # Test suspicious environment variable detection
    export LD_PRELOAD="/tmp/malicious.so"
    
    priv_violations="$(_check_privilege_escalation)"
    if ! echo "$priv_violations" | grep -q "LD_PRELOAD"; then
        log_test "ERROR" "Suspicious LD_PRELOAD not detected"
        unset LD_PRELOAD
        return 1
    fi
    
    unset LD_PRELOAD
    
    log_test "INFO" "Privilege escalation detection test successful"
    return 0
}

# Test 7: Security Level Configuration
test_security_level_configuration() {
    log_test "INFO" "Testing security level configuration"
    
    # Save original security level
    local original_security_level="$ZSH_ENV_SECURITY_LEVEL"
    local original_path="$PATH"
    
    # Test DISABLED mode
    export ZSH_ENV_SECURITY_LEVEL="DISABLED"
    if ! _sanitize_environment >/dev/null 2>&1; then
        log_test "ERROR" "Sanitization should succeed in DISABLED mode"
        export ZSH_ENV_SECURITY_LEVEL="$original_security_level"
        return 1
    fi
    
    # Test WARN mode with insecure PATH
    export ZSH_ENV_SECURITY_LEVEL="WARN"
    export PATH=".:$original_path"  # Add insecure component
    
    if ! _sanitize_environment >/dev/null 2>&1; then
        log_test "ERROR" "Sanitization should succeed in WARN mode even with violations"
        export PATH="$original_path"
        export ZSH_ENV_SECURITY_LEVEL="$original_security_level"
        return 1
    fi
    
    # PATH should not be modified in WARN mode
    if [[ "$PATH" != ".:$original_path" ]]; then
        log_test "ERROR" "PATH was modified in WARN mode (expected: .:$original_path, got: $PATH)"
        export PATH="$original_path"
        export ZSH_ENV_SECURITY_LEVEL="$original_security_level"
        return 1
    fi
    
    # Test STRICT mode
    export ZSH_ENV_SECURITY_LEVEL="STRICT"
    export PATH=".:$original_path"  # Reset with insecure component
    
    # This should modify PATH in STRICT mode
    _sanitize_environment >/dev/null 2>&1
    
    # PATH should be sanitized in STRICT mode (current directory removed)
    if [[ "$PATH" == *":.$original_path"* || "$PATH" == ".:$original_path" ]]; then
        log_test "ERROR" "PATH was not sanitized in STRICT mode (still contains current directory)"
        export PATH="$original_path"
        export ZSH_ENV_SECURITY_LEVEL="$original_security_level"
        return 1
    fi
    
    # Restore original state
    export PATH="$original_path"
    export ZSH_ENV_SECURITY_LEVEL="$original_security_level"
    
    log_test "INFO" "Security level configuration test successful"
    return 0
}

# Test 8: Logging and Audit Trail
test_logging_audit_trail() {
    log_test "INFO" "Testing logging and audit trail"
    
    # Clear existing log
    > "$ZSH_ENV_SECURITY_LOG" 2>/dev/null || true
    
    # Set up test scenario with violations
    export ZSH_ENV_SECURITY_LEVEL="WARN"
    export PATH=".:$PATH"  # Add insecure component
    export TEST_PASSWORD="secret"  # Add sensitive variable
    
    # Run sanitization
    _sanitize_environment >/dev/null 2>&1
    
    # Check log file exists and has content
    if [[ ! -f "$ZSH_ENV_SECURITY_LOG" ]]; then
        log_test "ERROR" "Security log file not created"
        return 1
    fi
    
    # Check for expected log entries
    local log_content
    log_content="$(cat "$ZSH_ENV_SECURITY_LOG" 2>/dev/null || echo "")"
    
    if ! echo "$log_content" | grep -q "VIOLATION.*PATH"; then
        log_test "ERROR" "PATH violation not logged"
        return 1
    fi
    
    if ! echo "$log_content" | grep -q "DETECTED.*TEST_PASSWORD"; then
        log_test "ERROR" "Sensitive variable detection not logged"
        return 1
    fi
    
    # Check UTC timestamp format
    if ! echo "$log_content" | grep -q "\[.*UTC\]"; then
        log_test "ERROR" "Log entries missing UTC timestamps"
        return 1
    fi
    
    # Clean up
    unset TEST_PASSWORD
    export PATH="${PATH#.:}"  # Remove current directory
    
    log_test "INFO" "Logging and audit trail test successful"
    return 0
}

# Test 9: Security Status Functions
test_security_status_functions() {
    log_test "INFO" "Testing security status functions"
    
    # Test status function
    local status_output
    status_output="$(_environment_security_status 2>/dev/null || echo "status_failed")"
    
    if [[ "$status_output" == "status_failed" ]]; then
        log_test "ERROR" "Security status function failed"
        return 1
    fi
    
    if ! echo "$status_output" | grep -q "Environment Security Status"; then
        log_test "ERROR" "Status output missing expected header"
        return 1
    fi
    
    # Test scan function
    local scan_output
    scan_output="$(_environment_security_scan 2>/dev/null || echo "scan_failed")"
    
    if [[ "$scan_output" == "scan_failed" ]]; then
        log_test "ERROR" "Security scan function failed"
        return 1
    fi
    
    if ! echo "$scan_output" | grep -q "security scan"; then
        log_test "ERROR" "Scan output missing expected content"
        return 1
    fi
    
    log_test "INFO" "Security status functions test successful"
    return 0
}

# Test 10: Main Sanitization Function
test_main_sanitization_function() {
    log_test "INFO" "Testing main sanitization function"
    
    export ZSH_ENV_SECURITY_LEVEL="WARN"
    
    # Test with no violations
    local original_path="$PATH"
    
    if ! _sanitize_environment >/dev/null 2>&1; then
        log_test "ERROR" "Main sanitization function failed with no violations"
        return 1
    fi
    
    # Test with violations
    export PATH=".:$PATH"
    export TEST_TOKEN="secret123"
    
    # Should succeed in WARN mode
    if ! _sanitize_environment >/dev/null 2>&1; then
        log_test "ERROR" "Main sanitization function failed in WARN mode with violations"
        export PATH="$original_path"
        unset TEST_TOKEN
        return 1
    fi
    
    # Clean up
    export PATH="$original_path"
    unset TEST_TOKEN
    
    log_test "INFO" "Main sanitization function test successful"
    return 0
}

# Main Test Execution
main() {
    log_test "INFO" "Starting $TEST_NAME test suite"
    echo "🛡️  Starting $TEST_NAME Test Suite"
    echo "📁 Test Directory: $TEST_DIR"
    echo "📋 Test Log: $TEST_LOG_FILE"
    echo ""
    
    # Setup test environment
    if ! setup_test_environment; then
        log_test "ERROR" "Failed to setup test environment"
        echo "❌ Failed to setup test environment"
        return 1
    fi
    
    # Run all tests
    run_test "PATH Security Validation" test_path_security_validation
    run_test "PATH Sanitization" test_path_sanitization
    run_test "Sensitive Variable Detection" test_sensitive_variable_detection
    run_test "Sensitive Variable Removal" test_sensitive_variable_removal
    run_test "Umask Security Enforcement" test_umask_enforcement
    run_test "Privilege Escalation Detection" test_privilege_escalation_detection
    run_test "Security Level Configuration" test_security_level_configuration
    run_test "Logging and Audit Trail" test_logging_audit_trail
    run_test "Security Status Functions" test_security_status_functions
    run_test "Main Sanitization Function" test_main_sanitization_function
    
    # Test Summary
    echo ""
    echo "🛡️  $TEST_NAME Test Results:"
    echo "✅ Passed: $passed_count"
    echo "❌ Failed: $failed_count"
    echo "📊 Total:  $test_count"
    echo ""
    
    local success_rate=0
    if [[ $test_count -gt 0 ]]; then
        success_rate=$(( (passed_count * 100) / test_count ))
    fi
    
    echo "📈 Success Rate: $success_rate%"
    
    log_test "INFO" "$TEST_NAME test suite completed: $passed_count/$test_count tests passed ($success_rate%)"
    
    if [[ $failed_count -eq 0 ]]; then
        echo "🎉 All tests passed! Environment sanitization system is working correctly."
        log_test "INFO" "All tests passed - system ready for production use"
        return 0
    else
        echo "⚠️  Some tests failed. Please review the logs and fix issues before deployment."
        log_test "WARN" "$failed_count tests failed - system needs attention before production use"
        return 1
    fi
}

# Execute main function - call directly for zsh compatibility
main "$@"
