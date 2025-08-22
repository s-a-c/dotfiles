#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Comprehensive Security Audit System
# ==============================================================================
# Purpose: Comprehensive security audit and monitoring system for ZSH
#          configuration to detect insecure conditions, permissions issues,
#          configuration vulnerabilities, and potential security risks.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Load Order: 99th in 00-core (final security check after all core components)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-testing environments
if [[ -n "${ZSH_SECURITY_CHECK_LOADED:-}" && -z "${ZSH_SECURITY_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        echo "WARNING: Source/execute detection system not found: $detection_script" >&2
        echo "Security check will work but without context-aware features" >&2
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_echo >/dev/null 2>&1; then
    _security_log() {
        context_echo "$1" "${2:-INFO}"
    }
    _security_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Security Check: $message" "$exit_code" "security"
        else
            echo "ERROR [security]: $message" >&2
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _security_log() {
        echo "# [security] $1" >&2
    }
    _security_error() {
        echo "ERROR [security]: $1" >&2
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Security Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    _security_log "Loading comprehensive security audit system v1.0"
}

# 1.1. Set global security version for tracking
export ZSH_SECURITY_CHECK_VERSION="1.0.0"
export ZSH_SECURITY_CHECK_LOADED="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# 1.2. Security configuration
export ZSH_SECURITY_STRICT_MODE="${ZSH_SECURITY_STRICT_MODE:-false}"
export ZSH_SECURITY_LOG_ISSUES="${ZSH_SECURITY_LOG_ISSUES:-true}"
export ZSH_SECURITY_AUTO_FIX="${ZSH_SECURITY_AUTO_FIX:-false}"

## 2. File and Directory Security Functions
#=============================================================================

# 2.1. Check file and directory permissions
_check_file_permissions() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking file and directory permissions..."

    # Critical files that should not be world-writable
    local critical_files=(
        "$ZDOTDIR/.zshrc"
        "$ZDOTDIR/.zshrc.d"
        "$HOME/.ssh"
        "$HOME/.ssh/config"
        "$HOME/.ssh/id_*"
        "/etc/passwd"
        "/etc/shadow"
    )

    for file_pattern in "${critical_files[@]}"; do
        # Check if pattern contains wildcards
        if [[ "$file_pattern" == *"*"* ]]; then
            # Use glob expansion for patterns
            for file in $file_pattern; do
                [[ -e "$file" ]] || continue

                total_checks=$((total_checks + 1))

            # Check if world-writable
            if [[ -w "$file" ]] && [[ "$(stat -f "%Mp%Lp" "$file" 2>/dev/null)" =~ ".*[2367]$" ]]; then
                issues_found=$((issues_found + 1))
                if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                    _security_log "SECURITY ISSUE: World-writable file: $file" "WARN"
                fi

                # Auto-fix if enabled
                if [[ "$ZSH_SECURITY_AUTO_FIX" == "true" ]]; then
                    chmod go-w "$file" 2>/dev/null && {
                        _security_log "AUTO-FIX: Removed world-write permission from $file" "INFO"
                    }
                fi
            else
                _security_log "✓ File permissions secure: $file" "DEBUG"
            fi
            done
        else
            # Handle non-wildcard patterns (direct file paths)
            file="$file_pattern"
            [[ -e "$file" ]] || continue

            total_checks=$((total_checks + 1))

            # Check if world-writable
            if [[ -w "$file" ]] && [[ "$(stat -f "%Mp%Lp" "$file" 2>/dev/null)" =~ ".*[2367]$" ]]; then
                issues_found=$((issues_found + 1))
                if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                    _security_log "SECURITY ISSUE: World-writable file: $file" "WARN"
                fi

                # Auto-fix if enabled
                if [[ "$ZSH_SECURITY_AUTO_FIX" == "true" ]]; then
                    chmod go-w "$file" 2>/dev/null && {
                        _security_log "AUTO-FIX: Removed world-write permission from $file" "INFO"
                    }
                fi
            else
                _security_log "✓ File permissions secure: $file" "DEBUG"
            fi
        fi
    done

    _security_log "File permission check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

# 2.2. Check directory ownership and permissions
_check_directory_security() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking directory security..."

    # Critical directories
    local critical_dirs=(
        "$ZDOTDIR"
        "$ZDOTDIR/.zshrc.d"
        "$HOME/.ssh"
        "$HOME"
    )

    for dir in "${critical_dirs[@]}"; do
        [[ -d "$dir" ]] || continue

        total_checks=$((total_checks + 1))

        # Check ownership
        local owner=$(stat -f "%Su" "$dir" 2>/dev/null)
        if [[ "$owner" != "$USER" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: Directory not owned by user: $dir (owner: $owner)" "WARN"
            fi
        fi

        # Check permissions
        local perms=$(stat -f "%Mp%Lp" "$dir" 2>/dev/null)
        if [[ "$perms" =~ ".*[2367]$" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: World-writable directory: $dir" "WARN"
            fi
        fi
    done

    _security_log "Directory security check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 3. Configuration Security Functions
#=============================================================================

# 3.1. Check for insecure shell options
_check_shell_options() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking shell options for security issues..."

    # Dangerous shell options that should not be set
    local dangerous_options=(
        "GLOB_SUBST"
        "SH_WORD_SPLIT"
        "KSH_ARRAYS"
        "BASH_REMATCH"
    )

    for option in "${dangerous_options[@]}"; do
        total_checks=$((total_checks + 1))

        if [[ -o "$option" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: Dangerous shell option enabled: $option" "WARN"
            fi

            # Auto-fix if enabled
            if [[ "$ZSH_SECURITY_AUTO_FIX" == "true" ]]; then
                unsetopt "$option" 2>/dev/null && {
                    _security_log "AUTO-FIX: Disabled dangerous option: $option" "INFO"
                }
            fi
        else
            _security_log "✓ Shell option secure: $option (disabled)" "DEBUG"
        fi
    done

    _security_log "Shell options check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

# 3.2. Check environment variables for sensitive data
_check_environment_variables() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking environment variables for sensitive data..."

    # Patterns that might indicate sensitive data in environment
    local sensitive_patterns=(
        "*PASSWORD*" "*PASSWD*" "*SECRET*" "*PRIVATE_KEY*"
        "*API_KEY*" "*ACCESS_KEY*" "*AUTH_TOKEN*"
        "*CREDENTIAL*" "*CERT*"
    )

    for pattern in "${sensitive_patterns[@]}"; do
        # Check if any environment variables match the pattern
        for var in ${(M)${(k)parameters}:#${~pattern}}; do
            total_checks=$((total_checks + 1))

            # Skip known safe variables
            case "$var" in
                "SSH_AUTH_SOCK"|"GPG_AGENT_INFO"|"KEYCHAIN_*") continue ;;
            esac

            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: Potentially sensitive variable in environment: $var" "WARN"
            fi
        done
    done

    _security_log "Environment variables check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 4. Network and Process Security Functions
#=============================================================================

# 4.1. Check for suspicious processes
_check_suspicious_processes() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking for suspicious processes..."

    # Suspicious process patterns
    local suspicious_patterns=(
        "keylogger" "backdoor" "rootkit" "trojan"
        "nc -l" "netcat -l" "socat"
    )

    for pattern in "${suspicious_patterns[@]}"; do
        total_checks=$((total_checks + 1))

        if pgrep -f "$pattern" >/dev/null 2>&1; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: Suspicious process detected: $pattern" "WARN"
            fi
        else
            _security_log "✓ No suspicious processes found for pattern: $pattern" "DEBUG"
        fi
    done

    _security_log "Process security check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

# 4.2. Check network connections
_check_network_security() {
    local issues_found=0
    local total_checks=0

    _security_log "Checking network security..."

    # Check for suspicious listening ports
    if command -v netstat >/dev/null 2>&1; then
        total_checks=$((total_checks + 1))

        # Look for unusual listening ports
        local suspicious_ports=$(netstat -an 2>/dev/null | grep LISTEN | grep -E ":(1234|4444|5555|6666|7777|8888|9999|31337)" || true)

        if [[ -n "$suspicious_ports" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_SECURITY_LOG_ISSUES" == "true" ]]; then
                _security_log "SECURITY ISSUE: Suspicious listening ports detected" "WARN"
                _security_log "Details: $suspicious_ports" "DEBUG"
            fi
        else
            _security_log "✓ No suspicious listening ports detected" "DEBUG"
        fi
    fi

    _security_log "Network security check: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 5. Main Security Audit Function
#=============================================================================

# 5.1. Comprehensive security audit
_run_security_audit() {
    local audit_start_time=$(date +%s.%N 2>/dev/null || date +%s)
    local total_issues=0

    _security_log "Starting comprehensive security audit..."

    # Run all security checks
    _check_file_permissions || total_issues=$((total_issues + $?))
    _check_directory_security || total_issues=$((total_issues + $?))
    _check_shell_options || total_issues=$((total_issues + $?))
    _check_environment_variables || total_issues=$((total_issues + $?))
    _check_suspicious_processes || total_issues=$((total_issues + $?))
    _check_network_security || total_issues=$((total_issues + $?))

    # Calculate audit time
    local audit_end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local audit_duration
    if command -v bc >/dev/null 2>&1; then
        audit_duration=$(echo "$audit_end_time - $audit_start_time" | bc 2>/dev/null || echo "0.001")
    else
        audit_duration="<0.001"
    fi

    # Report results
    if [[ $total_issues -eq 0 ]]; then
        _security_log "Security audit completed successfully - no issues found (${audit_duration}s)"
        return 0
    else
        _security_log "Security audit completed with $total_issues issues found (${audit_duration}s)" "WARN"

        if [[ "$ZSH_SECURITY_STRICT_MODE" == "true" ]]; then
            _security_error "Security audit failed in strict mode" $total_issues
        fi

        return $total_issues
    fi
}

## 6. Initialization and Execution
#=============================================================================

# 6.1. Auto-audit (unless in testing mode)
if [[ -z "$ZSH_SECURITY_TESTING" && "$ZSH_ENABLE_SECURITY_CHECK" != "false" ]]; then
    # Run security audit automatically during shell initialization
    if ! _run_security_audit; then
        if [[ "$ZSH_SECURITY_STRICT_MODE" == "true" ]]; then
            _security_error "Security audit failed during initialization" 1
        else
            _security_log "Security audit completed with warnings (non-strict mode)" "WARN"
        fi
    fi
fi

[[ "$ZSH_DEBUG" == "1" ]] && _security_log "✅ Security audit system loaded successfully"

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
main() {
    echo "========================================================"
    echo "ZSH Configuration Security Audit System"
    echo "========================================================"
    echo "Version: $ZSH_SECURITY_CHECK_VERSION"
    echo "Loaded: $ZSH_SECURITY_CHECK_LOADED"
    echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        echo "Execution Context: $(get_execution_context)"
        echo ""
    fi

    echo "Running comprehensive security audit..."
    if _run_security_audit; then
        echo ""
        echo "🎉 Security audit completed successfully!"
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 0
        else
            exit 0
        fi
    else
        echo ""
        echo "❌ Security audit completed with issues."
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 1
        else
            exit 1
        fi
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        main "$@"
    fi
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"security-check"* ]]; then
    # Fallback detection for direct execution
    main "$@"
fi

# ==============================================================================
# END: Security Audit System
# ==============================================================================
