#!/usr/bin/env zsh
#=============================================================================
# File: test-plugin-integrity-simple.zsh
# Purpose: Simplified plugin integrity verification test to avoid hanging issues
# Dependencies: openssl, jq (optional)
# Author: Configuration management system
# Last Modified: 2025-08-21
#=============================================================================

# Test Configuration
TEST_NAME="Plugin Integrity Verification (Simplified)"
TEST_DIR="/tmp/zsh-plugin-integrity-simple-$$"
ORIGINAL_PWD="$(pwd)"

# Test Results Tracking
test_count=0
passed_count=0
failed_count=0

# Logging setup per user rules
TEST_LOG_DIR="$HOME/.config/zsh/logs/$(date -u +%Y-%m-%d)"
TEST_LOG_FILE="$TEST_LOG_DIR/test-plugin-integrity-simple-$(date -u +%H%M%S).log"
mkdir -p "$TEST_LOG_DIR" 2>/dev/null || true

# Ensure working directory restoration per user rules
trap 'cd "$ORIGINAL_PWD" 2>/dev/null || true; cleanup_test_environment' EXIT

log_test() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "[$timestamp] [$level] $message" >> "$TEST_LOG_FILE" 2>/dev/null || true
    echo "[$timestamp] [$level] $message"
}

setup_test_environment() {
    log_test "INFO" "Setting up simplified test environment in $TEST_DIR"
    
    # Create test directory structure
    mkdir -p "$TEST_DIR"/{mock-plugins,mock-zgenom,security,logs}
    cd "$TEST_DIR" || return 1
    
    # Create mock plugin directories for testing
    mkdir -p "mock-plugins/trusted-plugin"
    echo '# Trusted test plugin' > "mock-plugins/trusted-plugin/plugin.zsh"
    
    mkdir -p "mock-plugins/untrusted-plugin"
    echo '# Untrusted test plugin' > "mock-plugins/untrusted-plugin/plugin.zsh"
    
    # Set up test environment variables
    export ZSH_PLUGIN_REGISTRY_DIR="$TEST_DIR/security/plugin-registry"
    export ZSH_PLUGIN_CACHE_DIR="$TEST_DIR/mock-zgenom/integrity-cache"
    export ZSH_PLUGIN_SECURITY_LOG="$TEST_DIR/logs/plugin-security.log"
    export ZGEN_DIR="$TEST_DIR/mock-zgenom"
    
    # Create directories
    mkdir -p "$ZSH_PLUGIN_REGISTRY_DIR" "$ZSH_PLUGIN_CACHE_DIR" "$(dirname "$ZSH_PLUGIN_SECURITY_LOG")"
    
    # Source the integrity verification system
    if ! source "$HOME/.config/zsh/.zshrc.pre-plugins.d/04-plugin-integrity-verification.zsh" 2>/dev/null; then
        log_test "ERROR" "Failed to source plugin integrity verification system"
        return 1
    fi
    
    log_test "INFO" "Test environment setup complete"
    return 0
}

cleanup_test_environment() {
    log_test "INFO" "Cleaning up test environment"
    
    # Restore original directory per user rules
    cd "$ORIGINAL_PWD" 2>/dev/null || true
    
    # Clean up test directory
    if [[ -d "$TEST_DIR" && "$TEST_DIR" =~ ^/tmp/zsh-plugin-integrity-simple- ]]; then
        rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    
    # Unset test environment variables
    unset ZSH_PLUGIN_REGISTRY_DIR ZSH_PLUGIN_CACHE_DIR ZSH_PLUGIN_SECURITY_LOG ZGEN_DIR
    
    log_test "INFO" "Test environment cleanup complete"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((test_count++))
    log_test "INFO" "Running test $test_count: $test_name"
    echo "🔍 Test $test_count: $test_name"
    
    if timeout 30 $test_function; then
        ((passed_count++))
        log_test "PASS" "Test $test_count: $test_name - PASSED"
        echo "✅ Test $test_count: $test_name - PASSED"
    else
        ((failed_count++))
        log_test "FAIL" "Test $test_count: $test_name - FAILED"
        echo "❌ Test $test_count: $test_name - FAILED"
    fi
}

# Test 1: Registry Creation
test_registry_creation() {
    log_test "INFO" "Testing registry creation"
    
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"
    
    if [[ ! -f "$registry_file" ]]; then
        log_test "ERROR" "Registry file not created: $registry_file"
        return 1
    fi
    
    if [[ ! -s "$registry_file" ]]; then
        log_test "ERROR" "Registry file is empty"
        return 1
    fi
    
    # Basic content check
    if ! grep -q "zdharma-continuum/fast-syntax-highlighting" "$registry_file"; then
        log_test "ERROR" "Registry missing expected plugin entries"
        return 1
    fi
    
    log_test "INFO" "Registry creation test successful"
    return 0
}

# Test 2: Plugin Verification Function
test_plugin_verification_function() {
    log_test "INFO" "Testing plugin verification function availability"
    
    # Check if function exists
    if ! declare -f _verify_plugin_integrity >/dev/null 2>&1; then
        log_test "ERROR" "Plugin verification function not available"
        return 1
    fi
    
    # Check if helper functions exist
    if ! declare -f _get_plugin_hash >/dev/null 2>&1; then
        log_test "ERROR" "Hash generation function not available"
        return 1
    fi
    
    log_test "INFO" "Plugin verification function test successful"
    return 0
}

# Test 3: Security Level Configuration
test_security_levels() {
    log_test "INFO" "Testing security level configuration"
    
    # Test DISABLED mode
    export ZSH_PLUGIN_SECURITY_LEVEL="DISABLED"
    if ! _secure_zgenom_load "test/plugin" 2>/dev/null; then
        log_test "ERROR" "Plugin should be allowed in DISABLED mode"
        return 1
    fi
    
    # Test WARN mode
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    if ! _secure_zgenom_load "malicious/plugin" 2>/dev/null; then
        log_test "ERROR" "Plugin should be allowed with warning in WARN mode"
        return 1
    fi
    
    log_test "INFO" "Security level configuration test successful"
    return 0
}

# Test 4: Hash Generation
test_hash_generation() {
    log_test "INFO" "Testing hash generation"
    
    local plugin_path="$TEST_DIR/mock-plugins/trusted-plugin"
    
    # Generate hash
    local hash1="$(_get_plugin_hash "$plugin_path" 2>/dev/null || echo "failed")"
    
    if [[ "$hash1" == "directory_not_found" || "$hash1" == "hash_failed" || "$hash1" == "failed" ]]; then
        log_test "ERROR" "Hash generation failed: $hash1"
        return 1
    fi
    
    # Generate hash again - should be identical
    local hash2="$(_get_plugin_hash "$plugin_path" 2>/dev/null || echo "failed")"
    
    if [[ "$hash1" != "$hash2" ]]; then
        log_test "ERROR" "Hash generation not consistent"
        return 1
    fi
    
    log_test "INFO" "Hash generation test successful"
    return 0
}

# Test 5: Basic Integrity Verification
test_basic_integrity() {
    log_test "INFO" "Testing basic integrity verification"
    
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    # Test trusted plugin verification
    local plugin_name="zdharma-continuum/fast-syntax-highlighting"
    local plugin_path="$TEST_DIR/mock-plugins/trusted-plugin"
    
    if ! _verify_plugin_integrity "$plugin_name" "$plugin_path" 2>/dev/null; then
        log_test "ERROR" "Trusted plugin verification failed"
        return 1
    fi
    
    log_test "INFO" "Basic integrity verification test successful"
    return 0
}

# Test 6: Security Functions
test_security_functions() {
    log_test "INFO" "Testing security management functions"
    
    # Test status function (with timeout to avoid hanging)
    if ! timeout 10 _plugin_security_status >/dev/null 2>&1; then
        log_test "ERROR" "Security status function failed or timed out"
        return 1
    fi
    
    log_test "INFO" "Security functions test successful"
    return 0
}

# Main Test Execution
main() {
    log_test "INFO" "Starting $TEST_NAME test suite"
    echo "🔒 Starting $TEST_NAME Test Suite"
    echo "📁 Test Directory: $TEST_DIR"
    echo "📋 Test Log: $TEST_LOG_FILE"
    echo ""
    
    # Setup test environment
    if ! setup_test_environment; then
        log_test "ERROR" "Failed to setup test environment"
        echo "❌ Failed to setup test environment"
        return 1
    fi
    
    # Run essential tests
    run_test "Registry Creation" test_registry_creation
    run_test "Plugin Verification Function" test_plugin_verification_function
    run_test "Security Level Configuration" test_security_levels
    run_test "Hash Generation" test_hash_generation
    run_test "Basic Integrity Verification" test_basic_integrity
    run_test "Security Functions" test_security_functions
    
    # Test Summary
    echo ""
    echo "🔒 $TEST_NAME Test Results:"
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
        echo "🎉 All simplified tests passed! Core plugin integrity verification is working."
        log_test "INFO" "All tests passed - core functionality validated"
        return 0
    else
        echo "⚠️  Some tests failed. Please review the logs."
        log_test "WARN" "$failed_count tests failed - core functionality needs attention"
        return 1
    fi
}

# Execute main function only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
