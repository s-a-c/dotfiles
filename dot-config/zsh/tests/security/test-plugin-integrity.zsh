#!/usr/bin/env zsh
#=============================================================================
# File: test-plugin-integrity.zsh
# Purpose: Comprehensive test suite for plugin integrity verification system
# Dependencies: openssl, jq (optional), zgenom test environment
# Author: Configuration management system
# Last Modified: 2025-08-21
#
# Test Coverage:
# - Trusted plugin registry verification
# - Plugin tampering detection
# - Security level enforcement (STRICT, WARN, DISABLED)
# - Hash-based integrity checking
# - Malicious plugin blocking
# - Logging and audit trail validation
#=============================================================================

# Test Configuration
TEST_NAME="Plugin Integrity Verification"
TEST_DIR="/tmp/zsh-plugin-integrity-test-$$"
ORIGINAL_PWD="$(pwd)"

# Test Results Tracking
declare -A test_results
test_count=0
passed_count=0
failed_count=0

# Logging setup per user rules - UTC timestamps in date-named subdirs
TEST_LOG_DIR="$HOME/.config/zsh/logs/$(date -u +%Y-%m-%d)"
TEST_LOG_FILE="$TEST_LOG_DIR/test-plugin-integrity-$(date -u +%H%M%S).log"
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
    log_test "INFO" "Setting up test environment in $TEST_DIR"
    
    # Create test directory structure
    mkdir -p "$TEST_DIR"/{mock-plugins,mock-zgenom,security,logs}
    cd "$TEST_DIR" || return 1
    
    # Create mock plugin directories for testing
    mkdir -p "mock-plugins/trusted-plugin"
    echo '# Trusted test plugin' > "mock-plugins/trusted-plugin/plugin.zsh"
    echo 'echo "Loading trusted plugin"' >> "mock-plugins/trusted-plugin/plugin.zsh"
    
    mkdir -p "mock-plugins/untrusted-plugin"
    echo '# Untrusted test plugin' > "mock-plugins/untrusted-plugin/plugin.zsh"
    echo 'echo "Loading untrusted plugin"' >> "mock-plugins/untrusted-plugin/plugin.zsh"
    
    mkdir -p "mock-plugins/tampered-plugin"
    echo '# Original tampered plugin' > "mock-plugins/tampered-plugin/plugin.zsh"
    echo 'echo "Loading original plugin"' >> "mock-plugins/tampered-plugin/plugin.zsh"
    
    # Set up test environment variables
    export ZSH_PLUGIN_REGISTRY_DIR="$TEST_DIR/security/plugin-registry"
    export ZSH_PLUGIN_CACHE_DIR="$TEST_DIR/mock-zgenom/integrity-cache"
    export ZSH_PLUGIN_SECURITY_LOG="$TEST_DIR/logs/plugin-security.log"
    export ZGEN_DIR="$TEST_DIR/mock-zgenom"
    
    # Create directories
    mkdir -p "$ZSH_PLUGIN_REGISTRY_DIR" "$ZSH_PLUGIN_CACHE_DIR" "$(dirname "$ZSH_PLUGIN_SECURITY_LOG")"
    
    # Source the integrity verification system
    source "$HOME/.config/zsh/.zshrc.pre-plugins.d/04-plugin-integrity-verification.zsh"
    
    log_test "INFO" "Test environment setup complete"
    return 0
}

cleanup_test_environment() {
    log_test "INFO" "Cleaning up test environment"
    
    # Restore original directory per user rules
    cd "$ORIGINAL_PWD" 2>/dev/null || true
    
    # Clean up test directory
    if [[ -d "$TEST_DIR" && "$TEST_DIR" =~ ^/tmp/zsh-plugin-integrity-test- ]]; then
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

# Test 1: Registry Creation and Basic Structure
test_registry_creation() {
    log_test "INFO" "Testing trusted plugin registry creation"
    
    # Registry should be created automatically
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"
    
    if [[ ! -f "$registry_file" ]]; then
        log_test "ERROR" "Registry file not created: $registry_file"
        return 1
    fi
    
    # Check if jq is available for JSON parsing
    if command -v jq >/dev/null 2>&1; then
        # Verify registry structure
        if ! jq -e '.registry_version' "$registry_file" >/dev/null 2>&1; then
            log_test "ERROR" "Registry missing version field"
            return 1
        fi
        
        if ! jq -e '.plugins' "$registry_file" >/dev/null 2>&1; then
            log_test "ERROR" "Registry missing plugins field"
            return 1
        fi
        
        local plugin_count
        plugin_count="$(jq -r '.plugins | keys | length' "$registry_file" 2>/dev/null || echo "0")"
        
        if [[ "$plugin_count" -lt 1 ]]; then
            log_test "ERROR" "Registry contains no plugins: $plugin_count"
            return 1
        fi
        
        log_test "INFO" "Registry created successfully with $plugin_count plugins"
    else
        log_test "WARN" "jq not available, skipping JSON structure validation"
        # Just check if file exists and has content
        if [[ ! -s "$registry_file" ]]; then
            log_test "ERROR" "Registry file is empty"
            return 1
        fi
    fi
    
    return 0
}

# Test 2: Trusted Plugin Verification
test_trusted_plugin_verification() {
    log_test "INFO" "Testing trusted plugin verification"
    
    # Set security level to WARN to allow testing
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    # Test verification of a known trusted plugin
    local plugin_name="zdharma-continuum/fast-syntax-highlighting"
    local plugin_path="$TEST_DIR/mock-plugins/trusted-plugin"
    
    if ! _verify_plugin_integrity "$plugin_name" "$plugin_path"; then
        log_test "ERROR" "Trusted plugin verification failed"
        return 1
    fi
    
    # Check if verification was logged
    if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
        if ! grep -q "VERIFIED: $plugin_name" "$ZSH_PLUGIN_SECURITY_LOG"; then
            log_test "ERROR" "Plugin verification not logged"
            return 1
        fi
    fi
    
    log_test "INFO" "Trusted plugin verification successful"
    return 0
}

# Test 3: Untrusted Plugin Detection
test_untrusted_plugin_detection() {
    log_test "INFO" "Testing untrusted plugin detection"
    
    # Test with WARN level first
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    local plugin_name="malicious/untrusted-plugin"
    local plugin_path="$TEST_DIR/mock-plugins/untrusted-plugin"
    
    # Should succeed with warning in WARN mode
    if ! _verify_plugin_integrity "$plugin_name" "$plugin_path"; then
        log_test "ERROR" "Untrusted plugin should be allowed in WARN mode"
        return 1
    fi
    
    # Test with STRICT level
    export ZSH_PLUGIN_SECURITY_LEVEL="STRICT"
    
    # Should fail in STRICT mode
    if _verify_plugin_integrity "$plugin_name" "$plugin_path"; then
        log_test "ERROR" "Untrusted plugin should be blocked in STRICT mode"
        return 1
    fi
    
    # Check if blocking was logged
    if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
        if ! grep -q "BLOCKED: $plugin_name" "$ZSH_PLUGIN_SECURITY_LOG"; then
            log_test "ERROR" "Plugin blocking not logged"
            return 1
        fi
    fi
    
    log_test "INFO" "Untrusted plugin detection successful"
    return 0
}

# Test 4: Plugin Tampering Detection
test_plugin_tampering_detection() {
    log_test "INFO" "Testing plugin tampering detection"
    
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    local plugin_name="zdharma-continuum/fast-syntax-highlighting"
    local plugin_path="$TEST_DIR/mock-plugins/tampered-plugin"
    
    # First verification should cache the hash
    if ! _verify_plugin_integrity "$plugin_name" "$plugin_path"; then
        log_test "ERROR" "Initial plugin verification failed"
        return 1
    fi
    
    # Tamper with the plugin
    echo '# MALICIOUS CODE ADDED' >> "$plugin_path/plugin.zsh"
    echo 'rm -rf $HOME 2>/dev/null || true' >> "$plugin_path/plugin.zsh"
    
    # Second verification should detect tampering
    if _verify_plugin_integrity "$plugin_name" "$plugin_path" 2>/dev/null; then
        # In WARN mode, it should still pass but log a warning
        if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
            if ! grep -q "hash changed" "$ZSH_PLUGIN_SECURITY_LOG"; then
                log_test "ERROR" "Plugin tampering not detected"
                return 1
            fi
        fi
    fi
    
    # Test with STRICT mode
    export ZSH_PLUGIN_SECURITY_LEVEL="STRICT"
    
    if _verify_plugin_integrity "$plugin_name" "$plugin_path" 2>/dev/null; then
        log_test "ERROR" "Tampered plugin should be blocked in STRICT mode"
        return 1
    fi
    
    log_test "INFO" "Plugin tampering detection successful"
    return 0
}

# Test 5: Security Level Configuration
test_security_level_configuration() {
    log_test "INFO" "Testing security level configuration"
    
    local plugin_name="malicious/test-plugin"
    local plugin_path="$TEST_DIR/mock-plugins/untrusted-plugin"
    
    # Test DISABLED mode
    export ZSH_PLUGIN_SECURITY_LEVEL="DISABLED"
    if ! _secure_zgenom_load "$plugin_name"; then
        log_test "ERROR" "Plugin should be allowed in DISABLED mode"
        return 1
    fi
    
    # Test WARN mode
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    if ! _secure_zgenom_load "$plugin_name"; then
        log_test "ERROR" "Plugin should be allowed with warning in WARN mode"
        return 1
    fi
    
    # Test STRICT mode
    export ZSH_PLUGIN_SECURITY_LEVEL="STRICT"
    if _secure_zgenom_load "$plugin_name" 2>/dev/null; then
        log_test "ERROR" "Untrusted plugin should be blocked in STRICT mode"
        return 1
    fi
    
    log_test "INFO" "Security level configuration test successful"
    return 0
}

# Test 6: Hash Generation and Caching
test_hash_generation_caching() {
    log_test "INFO" "Testing plugin hash generation and caching"
    
    local plugin_path="$TEST_DIR/mock-plugins/trusted-plugin"
    
    # Generate hash
    local hash1="$(_get_plugin_hash "$plugin_path")"
    
    if [[ "$hash1" == "directory_not_found" || "$hash1" == "hash_failed" ]]; then
        log_test "ERROR" "Hash generation failed: $hash1"
        return 1
    fi
    
    # Generate hash again - should be identical
    local hash2="$(_get_plugin_hash "$plugin_path")"
    
    if [[ "$hash1" != "$hash2" ]]; then
        log_test "ERROR" "Hash generation not consistent: $hash1 != $hash2"
        return 1
    fi
    
    # Modify plugin and verify hash changes
    echo '# Additional content' >> "$plugin_path/plugin.zsh"
    local hash3="$(_get_plugin_hash "$plugin_path")"
    
    if [[ "$hash1" == "$hash3" ]]; then
        log_test "ERROR" "Hash should change after file modification"
        return 1
    fi
    
    log_test "INFO" "Hash generation and caching test successful"
    return 0
}

# Test 7: Logging and Audit Trail
test_logging_audit_trail() {
    log_test "INFO" "Testing logging and audit trail"
    
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    # Clear existing log
    > "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || true
    
    # Perform some actions that should be logged
    _verify_plugin_integrity "zdharma-continuum/fast-syntax-highlighting" "$TEST_DIR/mock-plugins/trusted-plugin"
    _verify_plugin_integrity "malicious/untrusted-plugin" "$TEST_DIR/mock-plugins/untrusted-plugin"
    
    # Check log file exists and has content
    if [[ ! -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
        log_test "ERROR" "Security log file not created"
        return 1
    fi
    
    # Check for expected log entries
    local log_content
    log_content="$(cat "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || echo "")"
    
    if ! echo "$log_content" | grep -q "VERIFIED:"; then
        log_test "ERROR" "Verification not logged"
        return 1
    fi
    
    if ! echo "$log_content" | grep -q "ALLOWED:"; then
        log_test "ERROR" "Warning not logged"
        return 1
    fi
    
    # Check UTC timestamp format
    if ! echo "$log_content" | grep -q "\[.*UTC\]"; then
        log_test "ERROR" "Log entries missing UTC timestamps"
        return 1
    fi
    
    log_test "INFO" "Logging and audit trail test successful"
    return 0
}

# Test 8: Plugin Name Extraction
test_plugin_name_extraction() {
    log_test "INFO" "Testing plugin name extraction from various formats"
    
    export ZSH_PLUGIN_SECURITY_LEVEL="DISABLED"  # Skip actual verification
    
    # Test various plugin specification formats
    local test_specs=(
        "https://github.com/user/plugin.git"
        "https://github.com/user/plugin"
        "user/plugin"
        "simple-plugin"
    )
    
    for spec in "${test_specs[@]}"; do
        if ! _secure_zgenom_load "$spec"; then
            log_test "ERROR" "Failed to handle plugin spec: $spec"
            return 1
        fi
    done
    
    log_test "INFO" "Plugin name extraction test successful"
    return 0
}

# Test 9: Security Status and Management Functions
test_security_status_functions() {
    log_test "INFO" "Testing security status and management functions"
    
    # Test status function
    local status_output
    status_output="$(_plugin_security_status 2>/dev/null || echo "status_failed")"
    
    if [[ "$status_output" == "status_failed" ]]; then
        log_test "ERROR" "Security status function failed"
        return 1
    fi
    
    if ! echo "$status_output" | grep -q "Plugin Security Status"; then
        log_test "ERROR" "Status output missing expected content"
        return 1
    fi
    
    # Test registry update function
    local update_output
    update_output="$(_plugin_security_update_registry 2>/dev/null || echo "update_failed")"
    
    if [[ "$update_output" == "update_failed" ]]; then
        log_test "ERROR" "Registry update function failed"
        return 1
    fi
    
    log_test "INFO" "Security status and management functions test successful"
    return 0
}

# Test 10: Error Handling and Resilience
test_error_handling() {
    log_test "INFO" "Testing error handling and resilience"
    
    export ZSH_PLUGIN_SECURITY_LEVEL="WARN"
    
    # Test with non-existent plugin path
    if ! _verify_plugin_integrity "test/plugin" "/nonexistent/path"; then
        log_test "ERROR" "Should handle non-existent paths gracefully in WARN mode"
        return 1
    fi
    
    # Test with corrupted registry (if jq available)
    if command -v jq >/dev/null 2>&1; then
        local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"
        local backup_content
        backup_content="$(cat "$registry_file" 2>/dev/null)"
        
        # Corrupt the registry
        echo "invalid json content" > "$registry_file"
        
        # Should handle corruption gracefully
        if ! _verify_plugin_integrity "test/plugin" "$TEST_DIR/mock-plugins/trusted-plugin" 2>/dev/null; then
            log_test "ERROR" "Should handle corrupted registry gracefully"
            # Restore registry
            echo "$backup_content" > "$registry_file"
            return 1
        fi
        
        # Restore registry
        echo "$backup_content" > "$registry_file"
    fi
    
    log_test "INFO" "Error handling and resilience test successful"
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
    
    # Run all tests
    run_test "Registry Creation and Structure" test_registry_creation
    run_test "Trusted Plugin Verification" test_trusted_plugin_verification
    run_test "Untrusted Plugin Detection" test_untrusted_plugin_detection
    run_test "Plugin Tampering Detection" test_plugin_tampering_detection
    run_test "Security Level Configuration" test_security_level_configuration
    run_test "Hash Generation and Caching" test_hash_generation_caching
    run_test "Logging and Audit Trail" test_logging_audit_trail
    run_test "Plugin Name Extraction" test_plugin_name_extraction
    run_test "Security Status Functions" test_security_status_functions
    run_test "Error Handling and Resilience" test_error_handling
    
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
        echo "🎉 All tests passed! Plugin integrity verification system is working correctly."
        log_test "INFO" "All tests passed - system ready for production use"
        return 0
    else
        echo "⚠️  Some tests failed. Please review the logs and fix issues before deployment."
        log_test "WARN" "$failed_count tests failed - system needs attention before production use"
        return 1
    fi
}

# Execute main function only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
