#!/usr/bin/env zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 05-environment-sanitization.zsh
# Purpose: Implement comprehensive environment sanitization for security hardening
# Dependencies: None (pure zsh)
# Author: Configuration management system
# Last Modified: 2025-08-21
#
# Key Security Features:
# - Secure PATH validation and sanitization
# - Sensitive environment variable filtering
# - Secure umask enforcement
# - Privilege escalation detection
# - Environment variable injection prevention
# - Comprehensive logging of security events
#=============================================================================

# 1. Configuration Variables
#=============================================================================

# Environment security settings
export ZSH_ENV_SECURITY_LEVEL="${ZSH_ENV_SECURITY_LEVEL:-WARN}"  # STRICT, WARN, DISABLED
export ZSH_ENV_SECURITY_LOG="${HOME}/.config/zsh/logs/$(date +%Y-%m-%d)/environment-security.log"
export ZSH_ENV_SECURE_UMASK="${ZSH_ENV_SECURE_UMASK:-022}"  # Secure default umask

# Create log directory
[[ ! -d "$(dirname "$ZSH_ENV_SECURITY_LOG")" ]] && mkdir -p "$(dirname "$ZSH_ENV_SECURITY_LOG")"

# Sensitive variable patterns (case-insensitive)
declare -A ZSH_SENSITIVE_VAR_PATTERNS
ZSH_SENSITIVE_VAR_PATTERNS=(
    'password' '.*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd].*'
    'token' '.*[Tt][Oo][Kk][Ee][Nn].*'
    'key' '.*[Kk][Ee][Yy].*'
    'secret' '.*[Ss][Ee][Cc][Rr][Ee][Tt].*'
    'auth' '.*[Aa][Uu][Tt][Hh].*'
    'credential' '.*[Cc][Rr][Ee][Dd][Ee][Nn][Tt][Ii][Aa][Ll].*'
    'private' '.*[Pp][Rr][Ii][Vv][Aa][Tt][Ee].*'
)

# Insecure PATH patterns
declare -a ZSH_INSECURE_PATH_PATTERNS
ZSH_INSECURE_PATH_PATTERNS=(
    '.'                    # Current directory
    '..'                   # Parent directory  
    ''                     # Empty path component
    '/tmp'                 # World-writable temp
    '/var/tmp'             # World-writable temp
)

# 2. Logging Functions
#=============================================================================

_log_env_security() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    
    echo "[$timestamp] [$level] $message" >> "$ZSH_ENV_SECURITY_LOG" 2>/dev/null || true
    
    # Also log to stderr for STRICT violations
    if [[ "$level" == "VIOLATION" && "$ZSH_ENV_SECURITY_LEVEL" == "STRICT" ]]; then
        echo "[ENV SECURITY] $message" >&2
    fi
}

# 3. PATH Security Functions
#=============================================================================

_validate_path_security() {
    local path_to_check="$1"
    local violations=()
    
    # Check for insecure PATH components
    local IFS=':'
    local -a path_components
    path_components=(${=path_to_check})
    
    for component in "${path_components[@]}"; do
        # Skip empty components (handled separately)
        [[ -z "$component" ]] && continue
        
        for pattern in "${ZSH_INSECURE_PATH_PATTERNS[@]}"; do
            # Handle empty pattern specially
            if [[ -z "$pattern" ]]; then
                continue  # Empty pattern is handled separately
            fi
            if [[ "$component" == "$pattern" ]]; then
                violations+=("Insecure PATH component: $component")
                continue 2  # Skip to next component
            fi
        done
        
        # Check if path exists and permissions
        if [[ -d "$component" ]]; then
            # Check if directory is world-writable
            if [[ -w "$component" ]] && [[ "$(stat -f "%p" "$component" 2>/dev/null | tail -c 3)" =~ [2367] ]]; then
                violations+=("World-writable PATH component: $component")
            fi
        fi
    done
    
    # Check for empty components (::)
    if [[ "$path_to_check" =~ :: ]]; then
        violations+=("Empty PATH component detected (::)")
    fi
    
    # Check for leading/trailing colons
    if [[ "$path_to_check" =~ ^: ]]; then
        violations+=("PATH starts with colon (current directory risk)")
    fi
    
    if [[ "$path_to_check" =~ :$ ]]; then
        violations+=("PATH ends with colon (current directory risk)")
    fi
    
    # Return violations
    for violation in "${violations[@]}"; do
        echo "$violation"
    done
    
    return $(( ${#violations[@]} > 0 ? 1 : 0 ))
}

_sanitize_path() {
    local original_path="$1"
    local sanitized_path=""
    local removed_components=()
    
    # Split PATH into components
    local IFS=':'
    local -a path_components
    path_components=(${=original_path})
    
    for component in "${path_components[@]}"; do
        local keep_component=true
        
        # Skip empty components
        if [[ -z "$component" ]]; then
            removed_components+=("empty component")
            continue
        fi
        
        # Check against insecure patterns
        for pattern in "${ZSH_INSECURE_PATH_PATTERNS[@]}"; do
            # Handle empty pattern specially
            if [[ -z "$pattern" ]]; then
                continue  # Empty pattern is handled separately
            fi
            if [[ "$component" == "$pattern" ]]; then
                removed_components+=("$component")
                keep_component=false
                break
            fi
        done
        
        # Check directory security
        if [[ "$keep_component" == true && -d "$component" ]]; then
            # Check if world-writable
            if [[ -w "$component" ]] && [[ "$(stat -f "%p" "$component" 2>/dev/null | tail -c 3)" =~ [2367] ]]; then
                removed_components+=("$component (world-writable)")
                keep_component=false
            fi
        fi
        
        # Add to sanitized path if safe
        if [[ "$keep_component" == true ]]; then
            if [[ -z "$sanitized_path" ]]; then
                sanitized_path="$component"
            else
                sanitized_path="$sanitized_path:$component"
            fi
        fi
    done
    
    # Log removed components
    for removed in "${removed_components[@]}"; do
        _log_env_security "WARN" "Removed insecure PATH component: $removed"
    done
    
    echo "$sanitized_path"
    return $(( ${#removed_components[@]} > 0 ? 1 : 0 ))
}

# 4. Environment Variable Sanitization
#=============================================================================

_find_sensitive_variables() {
    local -a sensitive_vars=()
    
    # Check all environment variables against sensitive patterns
    for var_name in $(env | cut -d= -f1); do
        for pattern_name in "${(@k)ZSH_SENSITIVE_VAR_PATTERNS}"; do
            local pattern="${ZSH_SENSITIVE_VAR_PATTERNS[$pattern_name]}"
            if [[ "$var_name" =~ $pattern ]]; then
                sensitive_vars+=("$var_name")
                break
            fi
        done
    done
    
    # Return unique sensitive variables
    printf '%s\n' "${sensitive_vars[@]}" | sort -u
}

_sanitize_sensitive_variables() {
    local action="$1"  # 'warn' or 'remove'
    local -a sensitive_vars
    
    # Get list of sensitive variables
    while IFS= read -r var_name; do
        [[ -n "$var_name" ]] && sensitive_vars+=("$var_name")
    done < <(_find_sensitive_variables)
    
    if [[ ${#sensitive_vars[@]} -eq 0 ]]; then
        _log_env_security "INFO" "No sensitive environment variables detected"
        return 0
    fi
    
    # Process each sensitive variable
    for var_name in "${sensitive_vars[@]}"; do
        local var_value="${(P)var_name}"
        local value_length=${#var_value}
        
        if [[ "$action" == "remove" ]]; then
            unset "$var_name"
            _log_env_security "VIOLATION" "REMOVED sensitive variable: $var_name (length: $value_length)"
        else
            _log_env_security "WARN" "DETECTED sensitive variable: $var_name (length: $value_length)"
        fi
    done
    
    return $(( ${#sensitive_vars[@]} > 0 ? 1 : 0 ))
}

# 5. Privilege and Permission Functions
#=============================================================================

_check_privilege_escalation() {
    local violations=()
    
    # Check if running as root
    if [[ "$EUID" -eq 0 ]]; then
        violations+=("Running as root user (UID 0)")
    fi
    
    # Check for suspicious SUID/SGID in PATH
    local IFS=':'
    local -a path_components
    path_components=(${=PATH})
    
    for dir in "${path_components[@]}"; do
        [[ ! -d "$dir" ]] && continue
        
        # Look for SUID/SGID files
        while IFS= read -r file; do
            [[ -n "$file" ]] && violations+=("SUID/SGID file in PATH: $file")
        done < <(find "$dir" -maxdepth 1 -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -5)
    done
    
    # Check for suspicious environment variables
    local suspicious_env_vars=('LD_PRELOAD' 'LD_LIBRARY_PATH' 'DYLD_INSERT_LIBRARIES' 'DYLD_LIBRARY_PATH')
    for var in "${suspicious_env_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            violations+=("Suspicious environment variable set: $var=${(P)var}")
        fi
    done
    
    # Return violations
    for violation in "${violations[@]}"; do
        echo "$violation"
    done
    
    return $(( ${#violations[@]} > 0 ? 1 : 0 ))
}

_enforce_secure_umask() {
    local current_umask="$(umask)"
    local target_umask="$ZSH_ENV_SECURE_UMASK"
    
    if [[ "$current_umask" != "$target_umask" ]]; then
        local old_umask="$current_umask"
        umask "$target_umask"
        _log_env_security "INFO" "Updated umask from $old_umask to $target_umask"
        return 1
    fi
    
    return 0
}

# 6. Main Environment Sanitization Function
#=============================================================================

_sanitize_environment() {
    local violations=()
    local fixes_applied=()
    
# Save current working directory per user rules
    local original_pwd="$(pwd)"
    # Note: zsh uses EXIT instead of RETURN for function cleanup
    
    _log_env_security "INFO" "Starting environment sanitization (level: $ZSH_ENV_SECURITY_LEVEL)"
    
    # Skip if disabled
    if [[ "$ZSH_ENV_SECURITY_LEVEL" == "DISABLED" ]]; then
        _log_env_security "INFO" "Environment sanitization disabled"
        return 0
    fi
    
    # 1. Check PATH security
    local path_violations
    path_violations="$(_validate_path_security "$PATH")"
    if [[ -n "$path_violations" ]]; then
        while IFS= read -r violation; do
            [[ -n "$violation" ]] && violations+=("PATH: $violation")
        done <<< "$path_violations"
        
        # Sanitize PATH if in STRICT mode
        if [[ "$ZSH_ENV_SECURITY_LEVEL" == "STRICT" ]]; then
            local sanitized_path
            sanitized_path="$(_sanitize_path "$PATH")"
            if [[ "$sanitized_path" != "$PATH" ]]; then
                export PATH="$sanitized_path"
                fixes_applied+=("PATH sanitized")
                _log_env_security "VIOLATION" "PATH sanitized due to security violations"
            fi
        fi
    fi
    
    # 2. Check sensitive environment variables
    local sensitive_action="warn"
    [[ "$ZSH_ENV_SECURITY_LEVEL" == "STRICT" ]] && sensitive_action="remove"
    
    if ! _sanitize_sensitive_variables "$sensitive_action"; then
        violations+=("Sensitive environment variables detected")
        if [[ "$sensitive_action" == "remove" ]]; then
            fixes_applied+=("Sensitive variables removed")
        fi
    fi
    
    # 3. Check privilege escalation risks
    local priv_violations
    priv_violations="$(_check_privilege_escalation)"
    if [[ -n "$priv_violations" ]]; then
        while IFS= read -r violation; do
            [[ -n "$violation" ]] && violations+=("PRIVILEGE: $violation")
        done <<< "$priv_violations"
    fi
    
    # 4. Enforce secure umask
    if ! _enforce_secure_umask; then
        fixes_applied+=("Secure umask enforced")
    fi
    
    # 5. Report results
    local violation_count=${#violations[@]}
    local fix_count=${#fixes_applied[@]}
    
    if [[ $violation_count -eq 0 ]]; then
        _log_env_security "INFO" "Environment sanitization completed: No security violations found"
        return 0
    else
        local level="WARN"
        [[ "$ZSH_ENV_SECURITY_LEVEL" == "STRICT" ]] && level="VIOLATION"
        
        _log_env_security "$level" "Environment sanitization completed: $violation_count violations found, $fix_count fixes applied"
        
        # Log individual violations
        for violation in "${violations[@]}"; do
            _log_env_security "$level" "VIOLATION: $violation"
        done
        
        # Log fixes applied
        for fix in "${fixes_applied[@]}"; do
            _log_env_security "INFO" "FIXED: $fix"
        done
        
        # In STRICT mode, return error if unfixed violations remain
        if [[ "$ZSH_ENV_SECURITY_LEVEL" == "STRICT" && $fix_count -lt $violation_count ]]; then
            return 1
        fi
    fi
    
    return 0
}

# 7. Security Status and Management Functions
#=============================================================================

_environment_security_status() {
    echo "=== Environment Security Status ==="
    echo "Security Level: $ZSH_ENV_SECURITY_LEVEL"
    echo "Security Log: $ZSH_ENV_SECURITY_LOG"
    echo "Secure umask: $ZSH_ENV_SECURE_UMASK"
    echo "Current umask: $(umask)"
    echo ""
    
    echo "PATH Security Analysis:"
    local path_issues
    path_issues="$(_validate_path_security "$PATH")"
    if [[ -n "$path_issues" ]]; then
        echo "⚠️  PATH Issues Found:"
        while IFS= read -r issue; do
            [[ -n "$issue" ]] && echo "  - $issue"
        done <<< "$path_issues"
    else
        echo "✅ PATH appears secure"
    fi
    echo ""
    
    echo "Sensitive Variables:"
    local sensitive_count
    sensitive_count="$(_find_sensitive_variables | wc -l)"
    echo "Found $sensitive_count potentially sensitive environment variables"
    
    echo ""
    echo "Recent Security Events:"
    if [[ -f "$ZSH_ENV_SECURITY_LOG" ]]; then
        tail -5 "$ZSH_ENV_SECURITY_LOG" 2>/dev/null || echo "No recent events"
    else
        echo "No security log found"
    fi
}

_environment_security_scan() {
    echo "🔍 Running comprehensive environment security scan..."
    echo ""
    
    # Run sanitization in scan mode (don't apply fixes)
    local original_level="$ZSH_ENV_SECURITY_LEVEL"
    ZSH_ENV_SECURITY_LEVEL="WARN"
    
    _sanitize_environment
    local result=$?
    
    # Restore original level
    ZSH_ENV_SECURITY_LEVEL="$original_level"
    
    echo ""
    if [[ $result -eq 0 ]]; then
        echo "✅ Environment security scan completed: No violations found"
    else
        echo "⚠️  Environment security scan completed: Violations detected (see log for details)"
    fi
    
    return $result
}

# 8. Functions and Initialize
#=============================================================================

# Functions are automatically available in zsh without explicit export

# Initialize sanitization on load
_log_env_security "INFO" "Environment sanitization system initialized (level: $ZSH_ENV_SECURITY_LEVEL)"

# Run initial sanitization only if not in test mode
if [[ "$ZSH_ENV_SECURITY_LEVEL" != "DISABLED" && -z "$ZSH_ENV_TESTING" ]]; then
    _sanitize_environment
fi

# Display security status if requested
if [[ "${ZSH_ENV_SECURITY_VERBOSE:-false}" == "true" ]]; then
    echo "Environment sanitization system loaded (level: $ZSH_ENV_SECURITY_LEVEL)"
fi
