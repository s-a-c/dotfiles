#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Automated Consistency Checker and Fixer
# ==============================================================================
# Purpose: Automated tool to identify and fix consistency issues in ZSH
#          configuration files to achieve 100% consistency score with
#          comprehensive analysis and automated fixes for environment variables,
#          error handling, function naming, arrays, and documentation headers.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 2.0 - Updated for .zshenv consistency
# Usage: ./consistency-checker.zsh [--fix] [--report]
# ==============================================================================

# Source .zshenv to ensure consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Configuration - use variables from .zshenv
ZSHRC_DIR="${ZDOTDIR}"
<<<<<<< HEAD
REPORT_FILE="$ZSH_LOG_DIR/consistency-report-$(date "+%Y%m%d-%H%M%S" 2>/dev/null || zf::debug "unknown").log"
BACKUP_DIR="$ZDOTDIR/.backups/consistency-$(date "+%Y%m%d-%H%M%S" 2>/dev/null || zf::debug "unknown")"
=======
REPORT_FILE="$ZSH_LOG_DIR/consistency-report-$(date "+%Y%m%d-%H%M%S" 2>/dev/null || zsh_debug_echo "unknown").log"
BACKUP_DIR="$ZDOTDIR/.backups/consistency-$(date "+%Y%m%d-%H%M%S" 2>/dev/null || zsh_debug_echo "unknown")"
>>>>>>> origin/develop

# Counters
TOTAL_FILES=0
ISSUES_FOUND=0
ISSUES_FIXED=0

# Create necessary directories
mkdir -p "$(dirname "$REPORT_FILE")" "$BACKUP_DIR" 2>/dev/null

<<<<<<< HEAD

# Logging functions - consistent with .zshenv debug system
log_info() {
    zf::debug "ℹ️  $1" | tee -a "$REPORT_FILE"
    zf::debug "# [consistency-checker] INFO: $1"
}

log_warn() {
    zf::debug "⚠️  $1" | tee -a "$REPORT_FILE"
    zf::debug "# [consistency-checker] WARN: $1"
}

log_error() {
    zf::debug "❌ $1" | tee -a "$REPORT_FILE"
    zf::debug "# [consistency-checker] ERROR: $1"
}

log_success() {
    zf::debug "✅ $1" | tee -a "$REPORT_FILE"
    zf::debug "# [consistency-checker] SUCCESS: $1"
}

log_fix() {
    zf::debug "🔧 $1" | tee -a "$REPORT_FILE"
    zf::debug "# [consistency-checker] FIX: $1"
=======
# Use zsh_debug_echo from .zshenv if available, otherwise create fallback
zsh_debug_echo() {
    echo "$@"
    if [[ "${ZSH_DEBUG:-0}" == "1" ]]; then
        print -r -- "$@" >> "$ZSH_DEBUG_LOG"
    fi
}

# Logging functions - consistent with .zshenv debug system
log_info() {
        zsh_debug_echo "ℹ️  $1" | tee -a "$REPORT_FILE"
    zsh_debug_echo "# [consistency-checker] INFO: $1"
}

log_warn() {
        zsh_debug_echo "⚠️  $1" | tee -a "$REPORT_FILE"
    zsh_debug_echo "# [consistency-checker] WARN: $1"
}

log_error() {
        zsh_debug_echo "❌ $1" | tee -a "$REPORT_FILE"
    zsh_debug_echo "# [consistency-checker] ERROR: $1"
}

log_success() {
        zsh_debug_echo "✅ $1" | tee -a "$REPORT_FILE"
    zsh_debug_echo "# [consistency-checker] SUCCESS: $1"
}

log_fix() {
        zsh_debug_echo "🔧 $1" | tee -a "$REPORT_FILE"
    zsh_debug_echo "# [consistency-checker] FIX: $1"
>>>>>>> origin/develop
    ISSUES_FIXED=$((ISSUES_FIXED + 1))
}

# Backup function using .zshenv paths
backup_file() {
    local file="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file")"
    cp "$file" "$backup_path" 2>/dev/null
}

# Check 1: Environment Variable Consistency
check_environment_variables() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for lowercase environment variables
    if grep -n '^export [a-z]' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found lowercase environment variables"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i 's/^export \([a-z][a-zA-Z0-9_]*\)=/export \U\1=/g' "$file"
            log_fix "Fixed lowercase environment variables in $file"
        fi
    fi

    # Check for unquoted environment variable values
    if grep -n '^export [A-Z_]*=[^"$].*[[:space:]]' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found unquoted environment variables with spaces"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            # This is complex, so we'll flag it for manual 020-review
            log_warn "Manual review needed for unquoted variables in $file"
        fi
    fi

    # Check for inconsistent export patterns
    if grep -n '^export [A-Z_]*=[^"$]' "$file" | grep -v '${.*}' >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found exports without proper quoting"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            # Add quotes around simple values
            sed -i 's/^export \([A-Z_]*\)=\([^"$][^[:space:]]*\)$/export \1="\2"/g' "$file"
            log_fix "Added quotes to simple export values in $file"
        fi
    fi

    return $issues
}

# Check 2: Function Naming Consistency
check_function_naming() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for functions without parentheses
    if grep -n '^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*{' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found functions without parentheses"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i 's/^\([a-zA-Z_][a-zA-Z0-9_]*\)[[:space:]]*{/\1() {/g' "$file"
            log_fix "Added parentheses to function declarations in $file"
        fi
    fi

    # Check for camelCase functions
    if grep -n '^[a-z][a-zA-Z]*[A-Z].*()' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found camelCase function names"
        # This requires manual 020-review as automatic conversion is complex
        if [[ "$fix_mode" == "true" ]]; then
            log_warn "Manual review needed for camelCase functions in $file"
        fi
    fi

    # Check for function keyword usage
    if grep -n '^function [a-zA-Z_]' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found 'function' keyword usage"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i 's/^function \([a-zA-Z_][a-zA-Z0-9_]*\)/\1()/g' "$file"
            log_fix "Removed 'function' keyword in $file"
        fi
    fi

    return $issues
}

# Check 3: Array Declaration Consistency
check_array_declarations() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for unquoted array elements (simple cases)
    if grep -n '=([^"]*[[:space:]][^"]*[^)])' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found potentially unquoted array elements"
        # This is complex to fix automatically, flag for manual 020-review
        if [[ "$fix_mode" == "true" ]]; then
            log_warn "Manual review needed for array quoting in $file"
        fi
    fi

    # Check for verbose array expansion
    if grep -n '\${.*\[@\]}.*\${.*\[@\]}' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found verbose array expansion patterns"
        # Flag for manual 020-review
        if [[ "$fix_mode" == "true" ]]; then
            log_warn "Manual review needed for array expansion in $file"
        fi
    fi

    return $issues
}

# Check 4: Error Handling Consistency
check_error_handling() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for commands without error handling
    local command_lines=$(grep -n '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]' "$file" | grep -v '||' | grep -v '&&' | wc -l)
    local total_commands=$(grep -n '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]' "$file" | wc -l)

    if [[ $total_commands -gt 0 ]]; then
        local error_handling_ratio=$((command_lines * 100 / total_commands))
        if [[ $error_handling_ratio -gt 30 ]]; then
            issues=$((issues + 1))
            log_warn "File $file: $error_handling_ratio% of commands lack error handling"
            # This requires manual 020-review
            if [[ "$fix_mode" == "true" ]]; then
                log_warn "Manual review needed for error handling in $file"
            fi
        fi
    fi

    return $issues
}

# Check 5: Documentation Header Consistency
check_documentation_headers() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for inconsistent shebang
    local first_line=$(head -1 "$file")
    if [[ "$first_line" =~ ^#!/ ]]; then
<<<<<<< HEAD
        if [[ "$first_line" != "#!/usr/bin/env zsh" ]]; then
=======
        if [[ "$first_line" != "#!/opt/homebrew/bin/zsh" ]]; then
>>>>>>> origin/develop
            issues=$((issues + 1))
            log_warn "File $file: Inconsistent shebang: $first_line"

            if [[ "$fix_mode" == "true" ]]; then
                backup_file "$file"
<<<<<<< HEAD
                sed -i '1s|^#!/.*|#!/usr/bin/env zsh|' "$file"
=======
                sed -i '1s|^#!/.*|#!/opt/homebrew/bin/zsh|' "$file"
>>>>>>> origin/develop
                log_fix "Standardized shebang in $file"
            fi
        fi
    fi

    # Check for double hash comments in headers
    if head -20 "$file" | grep -n '^##[^#]' >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found double hash comments in header"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i '1,20s/^##\([^#]\)/# \1/g' "$file"
            log_fix "Fixed double hash comments in $file"
        fi
    fi

    # Check for missing file description
    if ! head -10 "$file" | grep -q "Purpose:\|Description:" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Missing file description in header"
        # This requires manual addition
        if [[ "$fix_mode" == "true" ]]; then
            log_warn "Manual review needed to add description to $file"
        fi
    fi

    return $issues
}

# Check 6: Code Style Consistency
check_code_style() {
    local file="$1"
    local fix_mode="$2"
    local issues=0

    # Check for inconsistent indentation (tabs vs spaces)
    if grep -n $'\t' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found tab characters (should use spaces)"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i 's/\t/    /g' "$file"
            log_fix "Converted tabs to spaces in $file"
        fi
    fi

    # Check for trailing whitespace
    if grep -n '[[:space:]]$' "$file" >/dev/null 2>&1; then
        issues=$((issues + 1))
        log_warn "File $file: Found trailing whitespace"

        if [[ "$fix_mode" == "true" ]]; then
            backup_file "$file"
            sed -i 's/[[:space:]]*$//' "$file"
            log_fix "Removed trailing whitespace in $file"
        fi
    fi

    return $issues
}

# Main consistency check function
check_file_consistency() {
    local file="$1"
    local fix_mode="$2"
    local file_issues=0

    log_info "Checking file: $file"

    # Run all consistency checks
    check_environment_variables "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    check_function_naming "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    check_array_declarations "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    check_error_handling "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    check_documentation_headers "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    check_code_style "$file" "$fix_mode"
    file_issues=$((file_issues + $?))

    if [[ $file_issues -eq 0 ]]; then
        log_success "File $file: No consistency issues found"
    else
        log_warn "File $file: Found $file_issues consistency issues"
        ISSUES_FOUND=$((ISSUES_FOUND + file_issues))
    fi

    return $file_issues
}

# Generate consistency report
generate_report() {
    local consistency_score
    if [[ $TOTAL_FILES -gt 0 && $ISSUES_FOUND -gt 0 ]]; then
        # Calculate consistency score (higher is better)
<<<<<<< HEAD
        local max_possible_issues=$((TOTAL_FILES * 6)) # 6 check categories per file
        consistency_score=$(((max_possible_issues - ISSUES_FOUND) * 100 / max_possible_issues))
=======
        local max_possible_issues=$((TOTAL_FILES * 6))  # 6 check categories per file
        consistency_score=$(( (max_possible_issues - ISSUES_FOUND) * 100 / max_possible_issues ))
>>>>>>> origin/develop
    else
        consistency_score=100
    fi

<<<<<<< HEAD
    zf::debug "========================================================"
    zf::debug "ZSH Configuration Consistency Report"
    zf::debug "========================================================"
    zf::debug "Generated: $(date)"
    zf::debug "Files analyzed: $TOTAL_FILES"
    zf::debug "Issues found: $ISSUES_FOUND"
    zf::debug "Issues fixed: $ISSUES_FIXED"
    zf::debug "Consistency Score: ${consistency_score}%"
    zf::debug ""

    if [[ $consistency_score -ge 95 ]]; then
        zf::debug "🏆 EXCELLENT: Configuration meets high consistency standards"
    elif [[ $consistency_score -ge 85 ]]; then
        zf::debug "✅ GOOD: Configuration has good consistency with minor issues"
    elif [[ $consistency_score -ge 70 ]]; then
        zf::debug "⚠️  ACCEPTABLE: Configuration needs consistency improvements"
    else
        zf::debug "❌ NEEDS WORK: Configuration requires significant consistency fixes"
    fi

    zf::debug ""
    zf::debug "Report saved to: $REPORT_FILE"
    if [[ $ISSUES_FIXED -gt 0 ]]; then
        zf::debug "Backups saved to: $BACKUP_DIR"
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "ZSH Configuration Consistency Report"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Generated: $(date)"
        zsh_debug_echo "Files analyzed: $TOTAL_FILES"
        zsh_debug_echo "Issues found: $ISSUES_FOUND"
        zsh_debug_echo "Issues fixed: $ISSUES_FIXED"
        zsh_debug_echo "Consistency Score: ${consistency_score}%"
        zsh_debug_echo ""

    if [[ $consistency_score -ge 95 ]]; then
            zsh_debug_echo "🏆 EXCELLENT: Configuration meets high consistency standards"
    elif [[ $consistency_score -ge 85 ]]; then
            zsh_debug_echo "✅ GOOD: Configuration has good consistency with minor issues"
    elif [[ $consistency_score -ge 70 ]]; then
            zsh_debug_echo "⚠️  ACCEPTABLE: Configuration needs consistency improvements"
    else
            zsh_debug_echo "❌ NEEDS WORK: Configuration requires significant consistency fixes"
    fi

        zsh_debug_echo ""
        zsh_debug_echo "Report saved to: $REPORT_FILE"
    if [[ $ISSUES_FIXED -gt 0 ]]; then
            zsh_debug_echo "Backups saved to: $BACKUP_DIR"
>>>>>>> origin/develop
    fi
}

# Main execution
main() {
    local fix_mode=false
    local report_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
<<<<<<< HEAD
        --fix)
            fix_mode=true
            shift
            ;;
        --report)
            report_only=true
            shift
            ;;
        *)
            zf::debug "Usage: $0 [--fix] [--report]"
            zf::debug "  --fix    Apply automatic fixes"
            zf::debug "  --report Generate report only"
            exit 1
            ;;
        esac
    done

    zf::debug "========================================================"
    zf::debug "ZSH Configuration Consistency Checker"
    zf::debug "========================================================"
    zf::debug "Mode: $(if $fix_mode; then echo CHECK AND FIX; else echo CHECK ONLY; fi)"
    zf::debug "Directory: $ZSHRC_DIR"
    zf::debug ""

    # Initialize report
    cat >"$REPORT_FILE" <<EOF
ZSH Configuration Consistency Report
Generated: $(date)
Mode: $(if $fix_mode; then echo CHECK AND FIX; else echo CHECK ONLY; fi)
=======
            --fix)
                fix_mode=true
                shift
                ;;
            --report)
                report_only=true
                shift
                ;;
            *)
                    zsh_debug_echo "Usage: $0 [--fix] [--report]"
                    zsh_debug_echo "  --fix    Apply automatic fixes"
                    zsh_debug_echo "  --report Generate report only"
                exit 1
                ;;
        esac
    done

        zsh_debug_echo "========================================================"
        zsh_debug_echo "ZSH Configuration Consistency Checker"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Mode: $(if $fix_mode; then     zsh_debug_echo "CHECK AND FIX"; else     zsh_debug_echo "CHECK ONLY"; fi)"
        zsh_debug_echo "Directory: $ZSHRC_DIR"
        zsh_debug_echo ""

    # Initialize report
    cat > "$REPORT_FILE" << EOF
ZSH Configuration Consistency Report
Generated: $(date)
Mode: $(if $fix_mode; then     zsh_debug_echo "CHECK AND FIX"; else     zsh_debug_echo "CHECK ONLY"; fi)
>>>>>>> origin/develop

EOF

    # Find main ZSH configuration files (exclude cache, logs, backups)
    local zsh_files=()
    while IFS= read -r -d '' file; do
        # Skip cache, logs, backups, and test directories
        if [[ "$file" != *"/.cache/"* && "$file" != *"/logs/"* && "$file" != *"/.backups/"* && "$file" != *"/tests/"* ]]; then
            zsh_files+=("$file")
        fi
    done < <(find "$ZSHRC_DIR" -name "*.zsh" -type f -print0 2>/dev/null)

    TOTAL_FILES=${#zsh_files[@]}

    if [[ $TOTAL_FILES -eq 0 ]]; then
        log_error "No ZSH configuration files found in $ZSHRC_DIR"
        exit 1
    fi

    log_info "Found $TOTAL_FILES ZSH configuration files"
<<<<<<< HEAD
    zf::debug ""
=======
        zsh_debug_echo ""
>>>>>>> origin/develop

    # Check each file
    for file in "${zsh_files[@]}"; do
        check_file_consistency "$file" "$fix_mode"
    done

<<<<<<< HEAD
    zf::debug ""
=======
        zsh_debug_echo ""
>>>>>>> origin/develop
    generate_report

    # Exit with appropriate code
    if [[ $ISSUES_FOUND -gt 0 && $fix_mode == false ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "💡 Run with --fix to automatically fix issues"
=======
            zsh_debug_echo ""
            zsh_debug_echo "💡 Run with --fix to automatically fix issues"
>>>>>>> origin/develop
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
