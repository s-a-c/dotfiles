#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Comprehensive Validation System
# ==============================================================================
# Purpose: Validate ZSH configuration environment, directories, commands, and
#          system state to ensure proper functionality and identify issues
#          before they impact user experience.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Load Order: 99th in 00-core (final validation after all core components)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_VALIDATION_LOADED:-}" && -z "${ZSH_VALIDATION_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zsh_debug_echo "WARNING: Source/execute detection system not found: $detection_script"
        zsh_debug_echo "Validation will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zsh_debug_echo >/dev/null 2>&1; then
    _validation_log() {
        context_zsh_debug_echo "$1" "${2:-INFO}"
    }
    _validation_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Configuration Validation: $message" "$exit_code" "validation"
        else
            zsh_debug_echo "ERROR [validation]: $message"
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _validation_log() {
        zsh_debug_echo "# [validation] $1"
    }
    _validation_error() {
        zsh_debug_echo "ERROR [validation]: $1"
        return "${2:-1}"
    }
fi

## 1. Global Configuration and Validation Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _validation_log "Loading configuration validation system v1.0"
}

# 1.1. Set global validation version for tracking
export ZSH_VALIDATION_VERSION="1.0.0"
export ZSH_VALIDATION_LOADED="$(date -u '+    %FT%T %Z')"

# 1.2. Validation configuration
export ZSH_VALIDATION_STRICT_MODE="${ZSH_VALIDATION_STRICT_MODE:-false}"
export ZSH_VALIDATION_LOG_ISSUES="${ZSH_VALIDATION_LOG_ISSUES:-true}"

## 2. Environment Validation Functions
#=============================================================================

# 2.1. Validate essential environment variables
_validate_environment() {
    local issues_found=0
    local total_checks=0

    _validation_log "Validating essential environment variables..."

    # Essential variables that should be set
    local essential_vars=(
        "HOME" "USER" "SHELL" "PATH" "ZDOTDIR"
        "EDITOR" "PAGER" "LANG"
    )

    for var in "${essential_vars[@]}"; do
        total_checks=$((total_checks + 1))

        if [[ -z "${(P)var}" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential variable $var is not set" "WARN"
            fi
        else
            _validation_log "✓ $var is set: ${(P)var}" "DEBUG"
        fi
    done

    # Check PATH validity
    total_checks=$((total_checks + 1))
    if [[ -z "$PATH" ]]; then
        issues_found=$((issues_found + 1))
        _validation_log "CRITICAL: PATH is empty" "ERROR"
    elif [[ "$PATH" != *"/bin"* ]]; then
        issues_found=$((issues_found + 1))
        _validation_log "ISSUE: PATH doesn't contain /bin directory" "WARN"
    fi

    _validation_log "Environment validation: $issues_found issues found in $total_checks checks"
    return $issues_found
}

# 2.2. Validate directory structure
_validate_directories() {
    local issues_found=0
    local total_checks=0

    _validation_log "Validating ZSH configuration directory structure..."

    # Essential directories that should exist
    local essential_dirs=(
        "$ZDOTDIR"
        "$ZDOTDIR/.zshrc.d"
        "$ZDOTDIR/tests"
        "$ZDOTDIR/logs"
    )

    # Key files that actually exist in .zshrc.d (updated to match current structure)
    local essential_files=(
        "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZDOTDIR/.zshrc.d/00_01-environment.zsh"
        "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
    )

    for dir in "${essential_dirs[@]}"; do
        total_checks=$((total_checks + 1))

        if [[ ! -d "$dir" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential directory missing: $dir" "WARN"
            fi
        else
            _validation_log "✓ Directory exists: $dir" "DEBUG"
        fi
    done

    for file in "${essential_files[@]}"; do
        total_checks=$((total_checks + 1))

        if [[ ! -f "$file" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential file missing: $file" "WARN"
            fi
        else
            _validation_log "✓ File exists: $file" "DEBUG"
        fi
    done

    _validation_log "Directory validation: $issues_found issues found in $total_checks checks"
    return $issues_found
}

# 2.3. Validate essential commands
_validate_commands() {
    local issues_found=0
    local total_checks=0

    _validation_log "Validating essential command availability..."

    # Essential commands that should be available
    local essential_commands=(
        "zsh" "bash" "sh"
        "ls" "cat" "grep" "sed" "awk"
        "git" "curl" "wget"
        "date" "stat" "find"
    )

    for cmd in "${essential_commands[@]}"; do
        total_checks=$((total_checks + 1))

        if ! command -v "$cmd" >/dev/null 2>&1; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential command not found: $cmd" "WARN"
            fi
        else
            _validation_log "✓ Command available: $cmd" "DEBUG"
        fi
    done

    _validation_log "Command validation: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 3. Configuration File Validation
#=============================================================================

# 3.1. Validate core configuration files
_validate_config_files() {
    local issues_found=0
    local total_checks=0

    _validation_log "Validating core configuration files..."

    # Essential configuration files - updated to match actual directory structure
    local essential_files=(
        "$ZDOTDIR/.zshrc"
        "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZDOTDIR/.zshrc.d/00_01-environment.zsh"
    )

    for file in "${essential_files[@]}"; do
        total_checks=$((total_checks + 1))

        if [[ ! -f "$file" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential file missing: $file" "WARN"
            fi
        elif [[ ! -r "$file" ]]; then
            issues_found=$((issues_found + 1))
            if [[ "$ZSH_VALIDATION_LOG_ISSUES" == "true" ]]; then
                _validation_log "ISSUE: Essential file not readable: $file" "WARN"
            fi
        else
            _validation_log "✓ File exists and readable: $(basename "$file")" "DEBUG"
        fi
    done

    _validation_log "Configuration file validation: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 4. System State Validation
#=============================================================================

# 4.1. Validate ZSH-specific settings
_validate_zsh_state() {
    local issues_found=0
    local total_checks=0

    _validation_log "Validating ZSH system state..."

    # Check ZSH version
    total_checks=$((total_checks + 1))
    local zsh_version=$(zsh --version 2>/dev/null | head -n1)
    if [[ -z "$zsh_version" ]]; then
        issues_found=$((issues_found + 1))
        _validation_log "ISSUE: Cannot determine ZSH version" "WARN"
    else
        _validation_log "✓ ZSH version: $zsh_version" "DEBUG"
    fi

    # Check if we're running in ZSH
    total_checks=$((total_checks + 1))
    if [[ -z "$ZSH_VERSION" ]]; then
        issues_found=$((issues_found + 1))
        _validation_log "ISSUE: Not running in ZSH shell" "WARN"
    else
        _validation_log "✓ Running in ZSH: $ZSH_VERSION" "DEBUG"
    fi

    # Check essential ZSH options
    total_checks=$((total_checks + 1))
    if [[ -o EXTENDED_GLOB ]]; then
        _validation_log "✓ EXTENDED_GLOB option is set" "DEBUG"
    else
        issues_found=$((issues_found + 1))
        _validation_log "ISSUE: EXTENDED_GLOB option not set" "WARN"
    fi

    _validation_log "ZSH state validation: $issues_found issues found in $total_checks checks"
    return $issues_found
}

## 5. Main Validation Function
#=============================================================================

# 5.1. Comprehensive configuration validation
_validate_configuration() {
    local validation_start_time=$(date +%s.%N 2>/dev/null || date +%s)
    local total_issues=0

    _validation_log "Starting comprehensive configuration validation..."

    # Run all validation checks
    _validate_environment || total_issues=$((total_issues + $?))
    _validate_directories || total_issues=$((total_issues + $?))
    _validate_commands || total_issues=$((total_issues + $?))
    _validate_config_files || total_issues=$((total_issues + $?))
    _validate_zsh_state || total_issues=$((total_issues + $?))

    # Calculate validation time
    local validation_end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local validation_duration
    if command -v bc >/dev/null 2>&1; then
        validation_duration=$(zsh_debug_echo "$validation_end_time - $validation_start_time" | bc 2>/dev/null || zsh_debug_echo "0.001")
    else
        validation_duration="<0.001"
    fi

    # Report results
    if [[ $total_issues -eq 0 ]]; then
        _validation_log "Configuration validation completed successfully (${validation_duration}s)"
        return 0
    else
        _validation_log "Configuration validation completed with $total_issues issues (${validation_duration}s)" "WARN"

        if [[ "$ZSH_VALIDATION_STRICT_MODE" == "true" ]]; then
            _validation_error "Configuration validation failed in strict mode" $total_issues
        fi

        return $total_issues
    fi
}

## 6. Initialization and Execution
#=============================================================================

# 6.1. Auto-validation (unless in 040-testing mode)
if [[ -z "$ZSH_VALIDATION_TESTING" && "$ZSH_ENABLE_VALIDATION" != "false" ]]; then
    # Run validation automatically during shell initialization
    if ! _validate_configuration; then
        if [[ "$ZSH_VALIDATION_STRICT_MODE" == "true" ]]; then
            _validation_error "Configuration validation failed during initialization" 1
        else
            _validation_log "Configuration validation completed with warnings (non-strict mode)" "WARN"
        fi
    fi
fi

[[ "$ZSH_DEBUG" == "1" ]] && _validation_log "✅ Configuration validation system loaded successfully"

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
_validation_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Configuration Validation System"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_VALIDATION_VERSION"
    zsh_debug_echo "Loaded: $ZSH_VALIDATION_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    zsh_debug_echo "Running comprehensive configuration validation..."
    if _validate_configuration; then
        zsh_debug_echo ""
        zsh_debug_echo "🎉 Configuration validation completed successfully!"
        if declare -f safe_exit >/dev/null 2>&1; then
            safe_exit 0
        else
            exit 0
        fi
    else
        zsh_debug_echo ""
        zsh_debug_echo "❌ Configuration validation completed with issues."
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
elif [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"validation"* ]]; then
    # Fallback detection for direct execution
    main "$@"
fi

# ==============================================================================
# END: Configuration Validation System
# ==============================================================================
