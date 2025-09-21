#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Environment Sanitization Security Module
# ==============================================================================
# Purpose: Sanitize environment variables, secure PATH, and enforce security
#          policies to protect against environment-based attacks and ensure
#          secure shell operation with comprehensive security validation.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Load Order: 8th in 00-core (after basic environment, before tools)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# Security Level: HIGH - Critical security component
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_ENV_SANITIZATION_LOADED:-}" && -z "${ZSH_ENV_SANITIZATION_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zsh_debug_echo "WARNING: Source/execute detection system not found: $detection_script"
        zsh_debug_echo "Environment sanitization will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zsh_debug_echo >/dev/null 2>&1; then
    _sanitize_log() {
        context_zsh_debug_echo "$1" "${2:-INFO}"
    }
    _sanitize_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Environment Sanitization: $message" "$exit_code" "env_sanitize"
        else
            zsh_debug_echo "ERROR [env_sanitize]: $message"
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _sanitize_log() {
        zsh_debug_echo "# [env_sanitize] $1"
    }
    _sanitize_error() {
        zsh_debug_echo "ERROR [env_sanitize]: $1"
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Validation
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _sanitize_log "Loading environment sanitization security module v1.0"
}

# 1.1. Set global sanitization version for validation
export ZSH_ENV_SANITIZATION_VERSION="1.0.0"
ZSH_ENV_SANITIZATION_LOADED="$(date -u '+    %FT%T %Z')"
export ZSH_ENV_SANITIZATION_LOADED

# 1.2. Security configuration
export ZSH_SANITIZATION_STRICT_MODE="${ZSH_SANITIZATION_STRICT_MODE:-false}"
export ZSH_SANITIZATION_LOG_VIOLATIONS="${ZSH_SANITIZATION_LOG_VIOLATIONS:-true}"

## 2. Sensitive Variable Detection and Filtering
#=============================================================================

# 2.1. Define sensitive variable patterns
_get_sensitive_patterns() {
    local -a patterns=(
        # Authentication and credentials
        "*PASSWORD*" "*PASSWD*" "*SECRET*" "*PRIVATE_KEY*" "*SECRET_TOKEN*"
        "*CREDENTIAL*" "*AUTH_TOKEN*" "*CERT*" "*PRIVATE*"

        # API and service keys
        "*API_KEY*" "*ACCESS_KEY*" "*SECRET_KEY*" "*SERVICE_KEY*"
        "*CLIENT_SECRET*" "*CLIENT_ID*" "*OAUTH_SECRET*" "*OAUTH_TOKEN*"

        # Database and connection strings
        "*DB_PASS*" "*DATABASE_URL*" "*CONNECTION_STRING*"
        "*MYSQL_PWD*" "*POSTGRES_PASSWORD*"

        # Cloud and infrastructure
        "*AWS_SECRET*" "*AZURE_*" "*GCP_*" "*GOOGLE_*"
        "*DOCKER_*" "*KUBE*" "*HELM_*"

        # Development and debugging
        "*DEBUG_TOKEN*" "*DEV_KEY*" "*TEST_SECRET*"
    )

    printf '%s\n' "${patterns[@]}"
}

# 2.2. Check if variable name matches sensitive patterns
_is_sensitive_variable() {
    local var_name="$1"
    local pattern

    while IFS= read -r pattern; do
        if [[ "$var_name" == $~pattern ]]; then
            return 0
        fi
    done < <(_get_sensitive_patterns)

    return 1
}

# 2.3. Sanitize sensitive environment variables
_sanitize_sensitive_variables() {
    local sanitized_count=0
    local total_checked=0

    _sanitize_log "Scanning environment for sensitive variables..."

    # Get all environment variables
    local var_name var_value
    while IFS='=' read -r var_name var_value; do
        [[ -n "$var_name" ]] || continue
        total_checked=$((total_checked + 1))

        if _is_sensitive_variable "$var_name"; then
            sanitized_count=$((sanitized_count + 1))

            if [[ "$ZSH_SANITIZATION_LOG_VIOLATIONS" == "true" ]]; then
                _sanitize_log "SECURITY: Sanitizing sensitive variable: $var_name" "WARN"
            fi

            # Unset the sensitive variable
            unset "$var_name"
        fi
    done < <(env)

    _sanitize_log "Sensitive variable scan complete: $sanitized_count/$total_checked variables sanitized"
    return 0
}

## 3. PATH Security Validation and Sanitization
#=============================================================================

# 3.1. Check for insecure PATH entries
_validate_path_security() {
    local -a insecure_paths=()
    local -a secure_paths=()
    local path_entry

    _sanitize_log "Validating PATH security..."

    # Split PATH and analyze each entry
    local path_entry
    local -a path_entries
    # Use ZSH parameter expansion to split on colons
    path_entries=()
    IFS=':' read -rA path_entries <<< "$PATH"

    for path_entry in "${path_entries[@]}"; do
        [[ -n "$path_entry" ]] || continue

        # Check for security issues
        local is_insecure=false

        # Check 1: World-writable directories (skip if directory doesn't exist)
        if [[ -d "$path_entry" ]]; then
            # Only warn for mode 0777 (octal), i.e., drwxrwxrwx
            local perms="$(stat -f '%A' "$path_entry" 2>/dev/null)"
            if [[ "$perms" == "0777" ]]; then
                is_insecure=true
                insecure_paths+=("$path_entry (world-writable)")
            fi
        fi

        # Check 2: Relative paths (security risk)
        if [[ "$path_entry" != /* ]]; then
            is_insecure=true
            insecure_paths+=("$path_entry (relative path)")
        fi

        # Check 3: Non-existent directories
        if [[ ! -d "$path_entry" ]]; then
            is_insecure=true
            insecure_paths+=("$path_entry (non-existent)")
        fi

        if ! $is_insecure; then
            secure_paths+=("$path_entry")
        fi
    done

    # Report 010-findings.md
    if [[ ${#insecure_paths[@]} -gt 0 ]]; then
        _sanitize_log "SECURITY: Found ${#insecure_paths[@]} insecure PATH entries" "WARN"

        if [[ "$ZSH_SANITIZATION_LOG_VIOLATIONS" == "true" ]]; then
            local insecure_path
            for insecure_path in "${insecure_paths[@]}"; do
                _sanitize_log "  - $insecure_path" "WARN"
            done
        fi

        if [[ "$ZSH_SANITIZATION_STRICT_MODE" == "true" ]]; then
            _sanitize_log "SECURITY: Rebuilding PATH with secure entries only" "WARN"
            export PATH=$(IFS=':'; zsh_debug_echo "${secure_paths[*]}")
        fi

        return 1
    else
        _sanitize_log "PATH security validation passed: ${#secure_paths[@]} secure entries"
        return 0
    fi
}

## 4. Security Policy Enforcement
#=============================================================================

# 4.1. Set secure umask
_enforce_secure_umask() {
    local current_umask=$(umask)
    local secure_umask="022"  # rw-r--r-- for files, rwxr-xr-x for directories

    _sanitize_log "Checking umask security (current: $current_umask)..."

    if [[ "$current_umask" != "$secure_umask" ]]; then
        _sanitize_log "SECURITY: Setting secure umask from $current_umask to $secure_umask" "WARN"
        umask "$secure_umask"
    else
        _sanitize_log "Umask security validation passed: $current_umask"
    fi
}

# 4.2. Validate shell security settings
_validate_shell_security() {
    local security_issues=0

    _sanitize_log "Validating shell security settings..."

    # Check for dangerous shell options
    if [[ -o GLOB_SUBST ]]; then
        _sanitize_log "SECURITY: GLOB_SUBST option enabled (potential security risk)" "WARN"
        security_issues=$((security_issues + 1))
    fi

    if [[ -o SH_WORD_SPLIT ]]; then
        _sanitize_log "SECURITY: SH_WORD_SPLIT option enabled (potential security risk)" "WARN"
        security_issues=$((security_issues + 1))
    fi

    # Ensure secure history settings
    if [[ "$HISTFILE" == *"/tmp/"* ]] || [[ "$HISTFILE" == *"/var/tmp/"* ]]; then
        _sanitize_log "SECURITY: History file in temporary directory (security risk)" "WARN"
        security_issues=$((security_issues + 1))
    fi

    if [[ $security_issues -eq 0 ]]; then
        _sanitize_log "Shell security validation passed"
        return 0
    else
        _sanitize_log "SECURITY: Found $security_issues shell security issues" "WARN"
        return 1
    fi
}

## 5. Main Sanitization Function
#=============================================================================

# 5.1. Comprehensive environment sanitization
_sanitize_environment() {
    local sanitization_start_time=$(date +%s.%N 2>/dev/null || date +%s)
    local issues_found=0

    _sanitize_log "Starting comprehensive environment sanitization..."

    # Step 1: Sanitize sensitive variables
    if ! _sanitize_sensitive_variables; then
        issues_found=$((issues_found + 1))
    fi

    # Step 2: Validate PATH security
    if ! _validate_path_security; then
        issues_found=$((issues_found + 1))
    fi

    # Step 3: Enforce secure umask
    _enforce_secure_umask

    # Step 4: Validate shell security settings
    if ! _validate_shell_security; then
        issues_found=$((issues_found + 1))
    fi

    # Calculate sanitization time
    local sanitization_end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local sanitization_duration
    if command -v bc >/dev/null 2>&1; then
        sanitization_duration=$(zsh_debug_echo "$sanitization_end_time - $sanitization_start_time" | bc 2>/dev/null || zsh_debug_echo "0.001")
    else
        sanitization_duration="<0.001"
    fi

    # Report results
    if [[ $issues_found -eq 0 ]]; then
        _sanitize_log "Environment sanitization completed successfully (${sanitization_duration}s)"
        return 0
    else
        _sanitize_log "Environment sanitization completed with $issues_found security issues (${sanitization_duration}s)" "WARN"
        return $issues_found
    fi
}

## 6. Initialization and Execution
#=============================================================================

# 6.1. Auto-sanitization (only if explicitly enabled)
if [[ "$ZSH_ENABLE_SANITIZATION" == "true" && -z "$ZSH_ENV_SANITIZATION_TESTING" ]]; then
    # Run sanitization automatically
    if ! _sanitize_environment; then
        if [[ "$ZSH_SANITIZATION_STRICT_MODE" == "true" ]]; then
            _sanitize_error "Environment sanitization failed in strict mode" 1
        else
            _sanitize_log "Environment sanitization completed with warnings (non-strict mode)" "WARN"
        fi
    fi
elif [[ -z "$ZSH_ENV_SANITIZATION_TESTING" ]]; then
    _sanitize_log "Environment sanitization disabled (set ZSH_ENABLE_SANITIZATION=true to enable)"
fi

[[ "$ZSH_DEBUG" == "1" ]] && _sanitize_log "✅ Environment sanitization security module loaded successfully"

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
_env_sanitization_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Environment Sanitization Security Module"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_ENV_SANITIZATION_VERSION"
    zsh_debug_echo "Loaded: $ZSH_ENV_SANITIZATION_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    zsh_debug_echo "Running comprehensive environment sanitization..."
    if _sanitize_environment; then
        zsh_debug_echo ""
        zsh_debug_echo "🎉 Environment sanitization completed successfully!"
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 0
        else
            exit 0
        fi
    else
        zsh_debug_echo ""
        zsh_debug_echo "❌ Environment sanitization completed with security issues."
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
elif [[ "${(%):-%N}" == "$0" ]] || [[ "${(%):-%N}" == *"environment-sanitization"* ]]; then
    # Fallback detection for direct execution
    main "$@"
fi

# ==============================================================================
# END: Environment Sanitization Security Module
# ==============================================================================
