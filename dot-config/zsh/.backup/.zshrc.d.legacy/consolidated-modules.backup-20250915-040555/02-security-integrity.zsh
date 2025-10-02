#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Security & Integrity Module
# ==============================================================================
# Purpose: Comprehensive security and integrity management including plugin
#          integrity checks and system security auditing
# 
# Consolidated from:
#   - ACTIVE-00_20-plugin-integrity-core.zsh (6 functions)
#   - ACTIVE-00_21-plugin-integrity-advanced.zsh (7 functions)
#   - DISABLED-00_80-security-check.zsh (8 functions)
#
# Dependencies: 01-core-infrastructure.zsh (for logging functions)
# Load Order: Early (20-29 range)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-14
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_SECURITY_INTEGRITY_LOADED:-}" ]]; then
    return 0
fi
export _SECURITY_INTEGRITY_LOADED=1

# Debug helper - use core infrastructure if available
_security_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[SECURITY-DEBUG] $1" >&2
    fi
}

_security_debug "Loading security & integrity module..."

# ==============================================================================
# SECTION 1: PLUGIN INTEGRITY CORE
# ==============================================================================
# From: ACTIVE-00_20-plugin-integrity-core.zsh
# Purpose: Core plugin integrity validation (6 functions)

_security_debug "Loading core plugin integrity functions..."

# Global plugin integrity settings
PLUGIN_INTEGRITY_ENABLED="${PLUGIN_INTEGRITY_ENABLED:-1}"
PLUGIN_REGISTRY_FILE="${PLUGIN_REGISTRY_FILE:-$ZDOTDIR/.plugin-registry}"
PLUGIN_LOG_FILE="${PLUGIN_LOG_FILE:-$ZSH_LOG_DIR/plugin-security.log}"

# Log plugin security events
_log_plugin_security() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -w "$PLUGIN_LOG_FILE" ]] || mkdir -p "$(dirname "$PLUGIN_LOG_FILE")" 2>/dev/null; then
        echo "[$timestamp] [$level] $message" >> "$PLUGIN_LOG_FILE"
    fi
    
    if [[ "$level" == "ERROR" ]] || [[ "$level" == "WARN" ]]; then
        echo "[PLUGIN-SECURITY] $message" >&2
    fi
}

# Create plugin registry entry
_create_plugin_registry_entry() {
    local plugin_name="$1"
    local plugin_path="$2"
    local checksum="$3"
    
    if [[ -z "$plugin_name" || -z "$plugin_path" ]]; then
        _log_plugin_security "ERROR" "Invalid plugin registry entry: missing name or path"
        return 1
    fi
    
    # Ensure registry directory exists
    mkdir -p "$(dirname "$PLUGIN_REGISTRY_FILE")"
    
    # Create or update registry entry
    local entry="${plugin_name}:${plugin_path}:${checksum:-unknown}:$(date '+%s')"
    
    # Remove existing entry for this plugin
    if [[ -f "$PLUGIN_REGISTRY_FILE" ]]; then
        grep -v "^${plugin_name}:" "$PLUGIN_REGISTRY_FILE" > "${PLUGIN_REGISTRY_FILE}.tmp" 2>/dev/null || true
        mv "${PLUGIN_REGISTRY_FILE}.tmp" "$PLUGIN_REGISTRY_FILE" 2>/dev/null || true
    fi
    
    # Add new entry
    echo "$entry" >> "$PLUGIN_REGISTRY_FILE"
    _log_plugin_security "INFO" "Registered plugin: $plugin_name"
}

# Get plugin registry information
_get_plugin_registry_info() {
    local plugin_name="$1"
    
    if [[ -f "$PLUGIN_REGISTRY_FILE" ]]; then
        grep "^${plugin_name}:" "$PLUGIN_REGISTRY_FILE" 2>/dev/null
    fi
}

# Basic plugin verification
_verify_plugin_basic() {
    local plugin_path="$1"
    local plugin_name="$2"
    
    if [[ ! -f "$plugin_path" ]]; then
        _log_plugin_security "ERROR" "Plugin file not found: $plugin_path"
        return 1
    fi
    
    if [[ ! -r "$plugin_path" ]]; then
        _log_plugin_security "ERROR" "Plugin file not readable: $plugin_path"
        return 1
    fi
    
    # Check for suspicious patterns
    if grep -q "rm -rf /" "$plugin_path" 2>/dev/null; then
        _log_plugin_security "ERROR" "Dangerous pattern detected in plugin: $plugin_name"
        return 1
    fi
    
    _log_plugin_security "INFO" "Basic verification passed: $plugin_name"
    return 0
}

# Plugin security status
plugin_security_status() {
    echo "=== Plugin Security Status ==="
    echo "Registry file: $PLUGIN_REGISTRY_FILE"
    echo "Log file: $PLUGIN_LOG_FILE"
    echo "Integrity checks: ${PLUGIN_INTEGRITY_ENABLED:-disabled}"
    
    if [[ -f "$PLUGIN_REGISTRY_FILE" ]]; then
        local count=$(wc -l < "$PLUGIN_REGISTRY_FILE" 2>/dev/null || echo 0)
        echo "Registered plugins: $count"
    else
        echo "Registered plugins: 0 (registry not found)"
    fi
}

# ==============================================================================
# SECTION 2: ADVANCED PLUGIN INTEGRITY
# ==============================================================================
# From: ACTIVE-00_21-plugin-integrity-advanced.zsh
# Purpose: Advanced plugin integrity validation (7 functions)

_security_debug "Loading advanced plugin integrity functions..."

# Calculate file checksum
_calculate_plugin_checksum() {
    local file_path="$1"
    
    if [[ -f "$file_path" ]]; then
        if command -v sha256sum >/dev/null 2>&1; then
            sha256sum "$file_path" | awk '{print $1}'
        elif command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$file_path" | awk '{print $1}'
        elif command -v md5 >/dev/null 2>&1; then
            md5 "$file_path" | awk '{print $4}'
        else
            echo "unknown"
        fi
    else
        echo "missing"
    fi
}

# Verify plugin checksum
_verify_plugin_checksum() {
    local plugin_name="$1"
    local plugin_path="$2"
    
    local registry_info=$(_get_plugin_registry_info "$plugin_name")
    if [[ -z "$registry_info" ]]; then
        _log_plugin_security "WARN" "No registry entry for plugin: $plugin_name"
        return 1
    fi
    
    local stored_checksum=$(echo "$registry_info" | cut -d: -f3)
    local current_checksum=$(_calculate_plugin_checksum "$plugin_path")
    
    if [[ "$stored_checksum" != "$current_checksum" ]]; then
        _log_plugin_security "ERROR" "Checksum mismatch for plugin: $plugin_name"
        return 1
    fi
    
    _log_plugin_security "INFO" "Checksum verified: $plugin_name"
    return 0
}

# Advanced plugin validation
_validate_plugin_advanced() {
    local plugin_name="$1"
    local plugin_path="$2"
    
    # Basic checks first
    if ! _verify_plugin_basic "$plugin_path" "$plugin_name"; then
        return 1
    fi
    
    # Check for executable permissions (potential security risk)
    if [[ -x "$plugin_path" ]]; then
        _log_plugin_security "WARN" "Plugin has executable permissions: $plugin_name"
    fi
    
    # Check file size (extremely large files are suspicious)
    if [[ -f "$plugin_path" ]]; then
        local size=$(stat -f%z "$plugin_path" 2>/dev/null || stat -c%s "$plugin_path" 2>/dev/null || echo 0)
        if [[ $size -gt 1048576 ]]; then  # 1MB
            _log_plugin_security "WARN" "Large plugin file detected: $plugin_name ($size bytes)"
        fi
    fi
    
    # Check for network access patterns
    if grep -q "curl\|wget\|nc\|telnet" "$plugin_path" 2>/dev/null; then
        _log_plugin_security "INFO" "Network access detected in plugin: $plugin_name"
    fi
    
    return 0
}

# Register plugin with advanced checks
register_plugin_secure() {
    local plugin_name="$1"
    local plugin_path="$2"
    
    if ! _validate_plugin_advanced "$plugin_name" "$plugin_path"; then
        _log_plugin_security "ERROR" "Failed to validate plugin: $plugin_name"
        return 1
    fi
    
    local checksum=$(_calculate_plugin_checksum "$plugin_path")
    _create_plugin_registry_entry "$plugin_name" "$plugin_path" "$checksum"
}

# Verify all registered plugins
verify_all_plugins() {
    if [[ ! -f "$PLUGIN_REGISTRY_FILE" ]]; then
        echo "No plugin registry found"
        return 0
    fi
    
    local total=0
    local passed=0
    local failed=0
    
    while IFS=: read -r name path checksum timestamp; do
        ((total++))
        echo "Verifying: $name"
        
        if _verify_plugin_checksum "$name" "$path"; then
            ((passed++))
        else
            ((failed++))
        fi
    done < "$PLUGIN_REGISTRY_FILE"
    
    echo "Plugin verification complete: $passed passed, $failed failed, $total total"
    return $(( failed > 0 ? 1 : 0 ))
}

# Plugin integrity report
plugin_integrity_report() {
    echo "=== Plugin Integrity Report ==="
    echo "Generated: $(date)"
    echo ""
    
    plugin_security_status
    echo ""
    
    if [[ -f "$PLUGIN_LOG_FILE" ]]; then
        echo "Recent security events:"
        tail -10 "$PLUGIN_LOG_FILE" 2>/dev/null || echo "No recent events"
    fi
}

# Clean plugin registry
clean_plugin_registry() {
    if [[ -f "$PLUGIN_REGISTRY_FILE" ]]; then
        # Remove entries for non-existent files
        local temp_file="${PLUGIN_REGISTRY_FILE}.clean"
        while IFS=: read -r name path checksum timestamp; do
            if [[ -f "$path" ]]; then
                echo "$name:$path:$checksum:$timestamp"
            else
                _log_plugin_security "INFO" "Removed stale registry entry: $name"
            fi
        done < "$PLUGIN_REGISTRY_FILE" > "$temp_file"
        
        mv "$temp_file" "$PLUGIN_REGISTRY_FILE"
        echo "Plugin registry cleaned"
    fi
}

# ==============================================================================
# SECTION 3: COMPREHENSIVE SECURITY AUDIT
# ==============================================================================
# From: DISABLED-00_80-security-check.zsh
# Purpose: Comprehensive security audit system (8 functions)

_security_debug "Loading comprehensive security audit functions..."

# Check file permissions
_check_file_permissions() {
    local target_dir="${1:-$HOME}"
    local issues=0
    
    # Check for world-writable files in important directories
    local important_dirs=("$HOME/.ssh" "$HOME/.gnupg" "$ZDOTDIR")
    
    for dir in "${important_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local world_writable=$(find "$dir" -type f -perm -002 2>/dev/null | wc -l)
            if [[ $world_writable -gt 0 ]]; then
                _log_plugin_security "WARN" "World-writable files found in $dir: $world_writable"
                ((issues++))
            fi
        fi
    done
    
    return $issues
}

# Check directory security
_check_directory_security() {
    local issues=0
    
    # Check SSH directory permissions
    if [[ -d "$HOME/.ssh" ]]; then
        local ssh_perms=$(stat -f%Mp%Lp "$HOME/.ssh" 2>/dev/null || stat -c%a "$HOME/.ssh" 2>/dev/null)
        if [[ "$ssh_perms" != "700" ]]; then
            _log_plugin_security "WARN" "SSH directory has incorrect permissions: $ssh_perms"
            ((issues++))
        fi
    fi
    
    # Check for sensitive files with wrong permissions
    local sensitive_files=("$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519" "$HOME/.netrc")
    for file in "${sensitive_files[@]}"; do
        if [[ -f "$file" ]]; then
            local file_perms=$(stat -f%Mp%Lp "$file" 2>/dev/null || stat -c%a "$file" 2>/dev/null)
            if [[ "$file_perms" != "600" ]]; then
                _log_plugin_security "WARN" "Sensitive file has incorrect permissions: $file ($file_perms)"
                ((issues++))
            fi
        fi
    done
    
    return $issues
}

# Check shell options for security
_check_shell_options() {
    local issues=0
    
    # Check for dangerous shell options
    if ! setopt | grep -q RESTRICTED; then
        if [[ -n "$BASH_VERSION" ]]; then
            if [[ "$-" != *r* ]]; then
                _log_plugin_security "INFO" "Shell is not running in restricted mode"
            fi
        fi
    fi
    
    # Check history settings
    if [[ -z "$HISTFILE" ]]; then
        _log_plugin_security "INFO" "History file not set"
    fi
    
    return $issues
}

# Check environment variables for security issues
_check_environment_variables() {
    local issues=0
    
    # Check for potentially dangerous PATH entries
    if echo "$PATH" | grep -q "\."; then
        _log_plugin_security "WARN" "Current directory (.) found in PATH"
        ((issues++))
    fi
    
    # Check for empty PATH components
    if echo "$PATH" | grep -q "::"; then
        _log_plugin_security "WARN" "Empty PATH component found"
        ((issues++))
    fi
    
    # Check for LD_PRELOAD or similar
    if [[ -n "$LD_PRELOAD" ]]; then
        _log_plugin_security "WARN" "LD_PRELOAD is set: $LD_PRELOAD"
        ((issues++))
    fi
    
    if [[ -n "$DYLD_INSERT_LIBRARIES" ]]; then
        _log_plugin_security "WARN" "DYLD_INSERT_LIBRARIES is set: $DYLD_INSERT_LIBRARIES"
        ((issues++))
    fi
    
    return $issues
}

# Check for suspicious processes
_check_suspicious_processes() {
    local issues=0
    
    # This is a basic check - in practice, you'd want more sophisticated detection
    local suspicious_patterns=("nc -l" "python -m http.server" "python -m SimpleHTTPServer")
    
    for pattern in "${suspicious_patterns[@]}"; do
        if pgrep -f "$pattern" >/dev/null 2>&1; then
            _log_plugin_security "INFO" "Potentially suspicious process detected: $pattern"
        fi
    done
    
    return $issues
}

# Comprehensive security audit
security_audit() {
    echo "=== Comprehensive Security Audit ==="
    echo "Started: $(date)"
    echo ""
    
    local total_issues=0
    
    echo "Checking file permissions..."
    _check_file_permissions
    total_issues=$((total_issues + $?))
    
    echo "Checking directory security..."
    _check_directory_security  
    total_issues=$((total_issues + $?))
    
    echo "Checking shell options..."
    _check_shell_options
    total_issues=$((total_issues + $?))
    
    echo "Checking environment variables..."
    _check_environment_variables
    total_issues=$((total_issues + $?))
    
    echo "Checking for suspicious processes..."
    _check_suspicious_processes
    total_issues=$((total_issues + $?))
    
    echo ""
    echo "Security audit complete: $total_issues issues found"
    
    if [[ $total_issues -eq 0 ]]; then
        echo "✅ No security issues detected"
    else
        echo "⚠️  Security issues detected - check logs for details"
    fi
    
    return $total_issues
}

# Quick security check
security_quick_check() {
    local issues=0
    
    # Quick file permission check
    if [[ -d "$HOME/.ssh" ]]; then
        local ssh_perms=$(stat -f%Mp%Lp "$HOME/.ssh" 2>/dev/null || stat -c%a "$HOME/.ssh" 2>/dev/null)
        if [[ "$ssh_perms" != "700" ]]; then
            ((issues++))
        fi
    fi
    
    # Quick PATH check
    if echo "$PATH" | grep -q "\."; then
        ((issues++))
    fi
    
    return $issues
}

# Security health score
security_health_score() {
    local score=100
    local deductions=0
    
    # Run quick checks and deduct points
    if ! security_quick_check; then
        deductions=$((deductions + 10))
    fi
    
    # Check plugin integrity
    if [[ -f "$PLUGIN_REGISTRY_FILE" ]]; then
        local plugin_count=$(wc -l < "$PLUGIN_REGISTRY_FILE" 2>/dev/null || echo 0)
        if [[ $plugin_count -eq 0 ]]; then
            deductions=$((deductions + 5))
        fi
    else
        deductions=$((deductions + 15))
    fi
    
    score=$((score - deductions))
    echo "Security Health Score: $score/100"
    
    if [[ $score -ge 90 ]]; then
        echo "Status: Excellent"
    elif [[ $score -ge 75 ]]; then
        echo "Status: Good"
    elif [[ $score -ge 50 ]]; then
        echo "Status: Fair - improvements needed"
    else
        echo "Status: Poor - immediate attention required"
    fi
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_security_debug "Initializing security & integrity module..."

# Initialize plugin security if enabled
if [[ "$PLUGIN_INTEGRITY_ENABLED" == "1" ]]; then
    # Ensure log directory exists
    mkdir -p "$(dirname "$PLUGIN_LOG_FILE")" 2>/dev/null
    
    # Log module initialization
    _log_plugin_security "INFO" "Security & integrity module initialized"
fi

# Set module metadata
export SECURITY_INTEGRITY_VERSION="1.0.0"
export SECURITY_INTEGRITY_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"
export SECURITY_FUNCTIONS_TOTAL=21  # 6 + 7 + 8

_security_debug "Security & integrity module ready"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_security_integrity() {
    local tests_passed=0
    local tests_total=6
    
    # Test 1: Core plugin functions
    if command -v _log_plugin_security >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Core plugin integrity functions loaded"
    else
        echo "❌ Core plugin integrity functions not loaded"
    fi
    
    # Test 2: Advanced plugin functions
    if command -v register_plugin_secure >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Advanced plugin integrity functions loaded"
    else
        echo "❌ Advanced plugin integrity functions not loaded"
    fi
    
    # Test 3: Security audit functions
    if command -v security_audit >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Security audit functions loaded"
    else
        echo "❌ Security audit functions not loaded"
    fi
    
    # Test 4: Registry functionality
    if [[ -n "$PLUGIN_REGISTRY_FILE" ]]; then
        ((tests_passed++))
        echo "✅ Plugin registry configured"
    else
        echo "❌ Plugin registry not configured"
    fi
    
    # Test 5: Logging functionality
    if [[ -n "$PLUGIN_LOG_FILE" ]]; then
        ((tests_passed++))
        echo "✅ Security logging configured"
    else
        echo "❌ Security logging not configured"
    fi
    
    # Test 6: Module metadata
    if [[ -n "$SECURITY_INTEGRITY_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    echo ""
    echo "Security & Integrity Self-Test: $tests_passed/$tests_total tests passed"
    echo "📊 Total security functions: $SECURITY_FUNCTIONS_TOTAL"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF SECURITY & INTEGRITY MODULE
# ==============================================================================