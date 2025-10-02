#!/usr/bin/env zsh
# ==============================================================================
# 10-SECURITY-INTEGRITY.ZSH - Security and Integrity Validation (REDESIGN v2)
# ==============================================================================
# Purpose: Security integrity validation, path verification, and safety checks
# Consolidates: 03-security-integrity.zsh and 00-security-integrity.zsh
# Load Order: Early (10-) after shell options
# Author: ZSH Configuration Redesign System
# Created: 2025-09-22
# Version: 2.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_SECURITY_INTEGRITY_REDESIGN:-}" ]]; then
    return 0
fi
export _SECURITY_INTEGRITY_REDESIGN=1

# Debug helper
_security_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[SECURITY] $1" || true
}

_security_debug "Loading security and integrity validation (v2.0.0)"

# ==============================================================================
# SECTION 1: PATH SECURITY VALIDATION
# ==============================================================================

# Validate PATH for security issues
_validate_path_security() {
    local -a security_issues=()
    local -a path_entries=(${(s/:/)PATH})

    _security_debug "Validating PATH security (${#path_entries[@]} entries)"

    for entry in "${path_entries[@]}"; do
        # Skip empty entries
        [[ -n "$entry" ]] || continue

        # Check for world-writable directories (with fallback)
        if [[ -d "$entry" ]] && [[ -w "$entry" ]]; then
            local perms
            if command -v stat >/dev/null 2>&1; then
                # Completely suppress all output during stat operation
                {
                    # Comprehensive debug suppression for WezTerm
                    setopt localoptions
                    unsetopt xtrace 2>/dev/null || true
                    unsetopt verbose 2>/dev/null || true
                    set +x 2>/dev/null || true
                    set +v 2>/dev/null || true
                    exec 3>&2 2>/dev/null
                    perms="$(stat -f "%A" "$entry" 2>/dev/null || stat -c "%a" "$entry" 2>/dev/null || echo "unknown")"
                    exec 2>&3 3>&-
                } >/dev/null 2>&1
                # Only report actual security issues, don't spam debug output
                if [[ "$perms" =~ ".*7$|.*6$|.*3$|.*2$" ]]; then
                    security_issues+=("World-writable directory in PATH: $entry")
                fi
            fi
        fi

        # Check for relative paths (security risk)
        if [[ "$entry" != /* ]]; then
            security_issues+=("Relative path in PATH: $entry")
        fi

        # Check for non-existent directories
        if [[ ! -d "$entry" ]]; then
            security_issues+=("Non-existent directory in PATH: $entry")
        fi
    done

    # Report security issues
    if [[ ${#security_issues[@]} -gt 0 ]]; then
        _security_debug "⚠️  PATH security issues found:"
        for issue in "${security_issues[@]}"; do
            _security_debug "  - $issue"
        done
        return 1
    else
        _security_debug "✅ PATH security validation passed"
        return 0
    fi
}

# Run PATH security validation with comprehensive debug suppression
{
    # Save current state
    local was_xtrace_on=0
    [[ -o xtrace ]] && was_xtrace_on=1

    # Completely disable all debug output
    setopt localoptions
    unsetopt xtrace verbose monitor 2>/dev/null || true
    set +x +v +m 2>/dev/null || true

    # Redirect stderr to suppress any remaining output
    exec 3>&2 2>/dev/null

    # Run validation
    _validate_path_security

    # Restore stderr
    exec 2>&3 3>&-

    # Restore xtrace if it was originally on
    (( was_xtrace_on )) && set -x 2>/dev/null || true
} >/dev/null 2>&1

# ==============================================================================
# SECTION 2: SHELL ENVIRONMENT SECURITY
# ==============================================================================

# Validate shell environment for security issues
_validate_shell_security() {
    local -a warnings=()

    # Check for dangerous shell options
    if [[ -o GLOB_ASSIGN ]]; then
        warnings+=("GLOB_ASSIGN enabled - may cause security issues")
    fi

    # Check for unsafe umask
    local current_umask=$(umask)
    if [[ "$current_umask" =~ ^0*[0-3][0-6][0-6]$ ]]; then
        warnings+=("Permissive umask detected: $current_umask")
    fi

    # Check for elevated privileges
    if [[ "$EUID" -eq 0 ]]; then
        warnings+=("Running as root - security risk")
    fi

    # Check for suspicious environment variables
    local -a suspicious_vars=(
        "LD_PRELOAD" "LD_LIBRARY_PATH" "DYLD_INSERT_LIBRARIES"
        "DYLD_LIBRARY_PATH" "PYTHONPATH"
    )

    for var in "${suspicious_vars[@]}"; do
        # Safe parameter expansion with default
        local var_value="${(P)var:-}"
        if [[ -n "$var_value" ]]; then
            warnings+=("Suspicious environment variable set: $var")
        fi
    done

    # Report warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        _security_debug "⚠️  Shell security warnings:"
        for warning in "${warnings[@]}"; do
            _security_debug "  - $warning"
        done
    else
        _security_debug "✅ Shell security validation passed"
    fi
}

# Run shell security validation with comprehensive debug suppression
{
    # Save current state
    local was_xtrace_on=0
    [[ -o xtrace ]] && was_xtrace_on=1

    # Completely disable all debug output
    setopt localoptions
    unsetopt xtrace verbose monitor 2>/dev/null || true
    set +x +v +m 2>/dev/null || true

    # Redirect stderr to suppress any remaining output
    exec 3>&2 2>/dev/null

    # Run validation
    _validate_shell_security

    # Restore stderr
    exec 2>&3 3>&-

    # Restore xtrace if it was originally on
    (( was_xtrace_on )) && set -x 2>/dev/null || true
} >/dev/null 2>&1

# ==============================================================================
# SECTION 3: FILE INTEGRITY VERIFICATION
# ==============================================================================

# Verify critical file integrity
_verify_file_integrity() {
    local -a critical_files=(
        "$ZDOTDIR/.zshrc"
        "$ZDOTDIR/.zshenv"
        "/etc/zshrc"
        "/etc/zshenv"
    )

    _security_debug "Verifying file integrity for critical files"

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            # Check file permissions (with fallback)
            if command -v stat >/dev/null 2>&1; then
                local file_perms file_owner
                # Completely suppress all output during stat operations
                {
                    # Comprehensive debug suppression for WezTerm
                    setopt localoptions
                    unsetopt xtrace 2>/dev/null || true
                    unsetopt verbose 2>/dev/null || true
                    set +x 2>/dev/null || true
                    set +v 2>/dev/null || true
                    exec 3>&2 2>/dev/null
                    file_perms=$(stat -f "%A" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null || echo "unknown")
                    file_owner=$(stat -f "%Su" "$file" 2>/dev/null || stat -c "%U" "$file" 2>/dev/null || echo "unknown")
                    exec 2>&3 3>&-
                } >/dev/null 2>&1

                if [[ "$file_perms" =~ ".*[2367]$" ]]; then
                    _security_debug "⚠️  Potentially unsafe permissions on $file: $file_perms"
                fi

                # Check file ownership
                if [[ "$file_owner" != "$USER" ]] && [[ "$file_owner" != "root" ]] && [[ "$file_owner" != "unknown" ]]; then
                    _security_debug "⚠️  Suspicious ownership on $file: $file_owner"
                fi
            fi
        fi
    done
}

# Run file integrity verification with comprehensive debug suppression
{
    # Save current state
    local was_xtrace_on=0
    [[ -o xtrace ]] && was_xtrace_on=1

    # Completely disable all debug output
    setopt localoptions
    unsetopt xtrace verbose monitor 2>/dev/null || true
    set +x +v +m 2>/dev/null || true

    # Redirect stderr to suppress any remaining output
    exec 3>&2 2>/dev/null

    # Run verification
    _verify_file_integrity

    # Restore stderr
    exec 2>&3 3>&-

    # Restore xtrace if it was originally on
    (( was_xtrace_on )) && set -x 2>/dev/null || true
} >/dev/null 2>&1

# ==============================================================================
# SECTION 4: CONFIGURATION INTEGRITY
# ==============================================================================

# Validate configuration integrity
_validate_config_integrity() {
    local validation_errors=0

    # Check for required environment variables
    local -a required_vars=("ZDOTDIR" "USER" "HOME")
    for var in "${required_vars[@]}"; do
        if [[ -z "${(P)var}" ]]; then
            _security_debug "❌ Required environment variable missing: $var"
            ((validation_errors++))
        fi
    done

    # Validate ZDOTDIR
    if [[ -n "$ZDOTDIR" ]]; then
        if [[ ! -d "$ZDOTDIR" ]]; then
            _security_debug "❌ ZDOTDIR points to non-existent directory: $ZDOTDIR"
            ((validation_errors++))
        elif [[ ! -r "$ZDOTDIR" ]]; then
            _security_debug "❌ ZDOTDIR is not readable: $ZDOTDIR"
            ((validation_errors++))
        fi
    fi

    # Validate shell version
    if [[ -z "$ZSH_VERSION" ]]; then
        _security_debug "❌ ZSH_VERSION not set - may not be running in ZSH"
        ((validation_errors++))
    fi

    if [[ $validation_errors -eq 0 ]]; then
        _security_debug "✅ Configuration integrity validated"
        return 0
    else
        _security_debug "❌ Configuration integrity validation failed ($validation_errors errors)"
        return 1
    fi
}

# Run configuration integrity validation
_validate_config_integrity

# ==============================================================================
# SECTION 5: PLUGIN SECURITY FRAMEWORK
# ==============================================================================

# Plugin security validation framework
declare -A TRUSTED_PLUGINS=(
    ["zsh-users/zsh-syntax-highlighting"]="trusted"
    ["zsh-users/zsh-autosuggestions"]="trusted"
    ["zsh-users/zsh-completions"]="trusted"
    ["ohmyzsh/ohmyzsh"]="trusted"
    ["romkatv/powerlevel10k"]="trusted"
)

_validate_plugin_security() {
    local plugin_name="$1"
    local plugin_path="$2"

    # Check if plugin is in trusted list
    if [[ -n "${TRUSTED_PLUGINS[$plugin_name]:-}" ]]; then
        _security_debug "✅ Trusted plugin: $plugin_name"
        return 0
    fi

    # Perform basic security checks
    if [[ -n "$plugin_path" ]] && [[ -d "$plugin_path" ]]; then
        # Check for suspicious files
        local -a suspicious_files=(
            "$plugin_path"/**/*.so(N)
            "$plugin_path"/**/*.dylib(N)
            "$plugin_path"/**/Makefile(N)
            "$plugin_path"/**/makefile(N)
        )

        if [[ ${#suspicious_files[@]} -gt 0 ]]; then
            _security_debug "⚠️  Plugin contains potentially dangerous files: $plugin_name"
            return 1
        fi

        _security_debug "✅ Plugin security check passed: $plugin_name"
        return 0
    fi

    _security_debug "❓ Unknown plugin security status: $plugin_name"
    return 2
}

# Export plugin validation function for use by plugin managers
export -f _validate_plugin_security 2>/dev/null || true

# ==============================================================================
# SECTION 6: RUNTIME SECURITY MONITORING
# ==============================================================================

# Security monitoring for runtime changes
_monitor_security_state() {
    # Store initial security state
    export INITIAL_PATH="$PATH"
    export INITIAL_UMASK="$(umask)"
    export INITIAL_SHELL_OPTIONS="$(set -o)"

    # Set up monitoring function
    _check_security_changes() {
        local changes_detected=0

        # Check for PATH changes
        if [[ "$PATH" != "$INITIAL_PATH" ]]; then
            _security_debug "PATH changed during runtime"
            ((changes_detected++))
        fi

        # Check for umask changes
        if [[ "$(umask)" != "$INITIAL_UMASK" ]]; then
            _security_debug "umask changed during runtime"
            ((changes_detected++))
        fi

        if [[ $changes_detected -gt 0 ]]; then
            _security_debug "⚠️  Security state changes detected ($changes_detected)"
        fi
    }

    # Register for periodic checks (if supported)
    if command -v periodic >/dev/null 2>&1; then
        periodic 300 _check_security_changes  # Check every 5 minutes
    fi

    _security_debug "Runtime security monitoring initialized"
}

# Initialize security monitoring
_monitor_security_state

# ==============================================================================
# SECTION 7: SECURITY UTILITIES
# ==============================================================================

# Secure temporary file creation
secure_mktemp() {
    local template="${1:-secure.XXXXXX}"
    local tmpfile

    if command -v mktemp >/dev/null 2>&1; then
        tmpfile=$(mktemp "$template")
    else
        # Fallback implementation
        tmpfile="/tmp/$template.$$"
        touch "$tmpfile"
        chmod 600 "$tmpfile"
    fi

    # Ensure secure permissions
    chmod 600 "$tmpfile" 2>/dev/null
    echo "$tmpfile"
}

# Secure command execution
secure_exec() {
    local command="$1"
    shift

    # Validate command exists and is executable
    if ! command -v "$command" >/dev/null 2>&1; then
        _security_debug "❌ Command not found: $command"
        return 1
    fi

    # Get command path
    local cmd_path=$(command -v "$command")

    # Check if command is in a secure location
    local -a secure_paths=(
        "/bin" "/usr/bin" "/usr/local/bin"
        "/sbin" "/usr/sbin" "/usr/local/sbin"
        "/opt/homebrew/bin" "/opt/homebrew/sbin"
    )

    local is_secure=0
    for secure_path in "${secure_paths[@]}"; do
        if [[ "$cmd_path" == "$secure_path"/* ]]; then
            is_secure=1
            break
        fi
    done

    if [[ $is_secure -eq 0 ]]; then
        _security_debug "⚠️  Executing command from non-standard location: $cmd_path"
    fi

    # Execute command
    "$cmd_path" "$@"
}

_security_debug "Security utilities loaded"

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export SECURITY_INTEGRITY_VERSION="2.0.0"
export SECURITY_INTEGRITY_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

_security_debug "Security and integrity validation complete"

# Clean up helper function
unset -f _security_debug

# ==============================================================================
# END OF SECURITY INTEGRITY MODULE
# ==============================================================================
