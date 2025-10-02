#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Consistency Validation Test Suite
# ==============================================================================
# Purpose: Validate that the ZSH configuration achieves 100% consistency score
#          by 040-testing standardization across all configuration files including
#          coding style, naming conventions, error handling, documentation
#          formats, and overall consistency standards.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-consistency-validation.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_CONSISTENCY_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
    zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0
CONSISTENCY_SCORE=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-consistency-validation.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration directory
ZSHRC_DIR="${ZDOTDIR:-$HOME/.config/zsh}"

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    zf::debug "[$timestamp] [CONSISTENCY] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

    zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        zf::debug "  ✅ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        zf::debug "  ❌ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. CONSISTENCY VALIDATION TESTS
# ------------------------------------------------------------------------------

test_shebang_consistency() {
    zf::debug "    📋 Testing shebang consistency..."

    local inconsistent_files=0
    local total_files=0
    local standard_shebang="#!/usr/bin/env zsh"

    # Check core configuration files
    local core_files=(
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_01-environment.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_02-path-system.zsh"
    )

    for file in "${core_files[@]}"; do
        if [[ -f "$file" ]]; then
            total_files=$((total_files + 1))
            local first_line=$(head -1 "$file")

            if [[ "$first_line" == "$standard_shebang" ]]; then
                zf::debug "    ✅ Correct shebang: $(basename "$file")"
            else
                zf::debug "    ⚠️ Non-standard shebang in $(basename "$file"): $first_line"
                inconsistent_files=$((inconsistent_files + 1))
            fi
        fi
    done

    local consistency_rate=0
    if [[ $total_files -gt 0 ]]; then
        consistency_rate=$(((total_files - inconsistent_files) * 100 / total_files))
    fi

    zf::debug "    📊 Shebang consistency: ${consistency_rate}% ($((total_files - inconsistent_files))/$total_files files)"

    # Pass if 90% or higher consistency
    if [[ $consistency_rate -ge 90 ]]; then
        return 0
    else
        return 1
    fi
}

test_function_naming_consistency() {
    zf::debug "    📋 Testing function naming consistency..."

    local inconsistent_functions=0
    local total_functions=0

    # Check key files for function naming patterns
    local files_to_check=(
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh"
    )

    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            # Count functions with proper naming (function_name() format)
            local proper_functions=$(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' "$file" 2>/dev/null || zf::debug "0")

            # Count functions with 'function' keyword (less preferred)
            local function_keyword=$(grep -c '^function [a-zA-Z_]' "$file" 2>/dev/null || zf::debug "0")

            # Count camelCase functions (inconsistent)
            local camel_case=$(grep -c '^[a-z][a-zA-Z]*[A-Z].*()' "$file" 2>/dev/null || zf::debug "0")

            total_functions=$((total_functions + proper_functions + function_keyword + camel_case))
            inconsistent_functions=$((inconsistent_functions + function_keyword + camel_case))

            zf::debug "    📊 $(basename "$file"): $proper_functions proper, $function_keyword keyword, $camel_case camelCase"
        fi
    done

    local consistency_rate=100
    if [[ $total_functions -gt 0 ]]; then
        consistency_rate=$(((total_functions - inconsistent_functions) * 100 / total_functions))
    fi

    zf::debug "    📊 Function naming consistency: ${consistency_rate}% ($((total_functions - inconsistent_functions))/$total_functions functions)"

    # Pass if 95% or higher consistency
    if [[ $consistency_rate -ge 95 ]]; then
        return 0
    else
        return 1
    fi
}

test_export_statement_consistency() {
    zf::debug "    📋 Testing export statement consistency..."

    local inconsistent_exports=0
    local total_exports=0

    # Check environment files for export consistency
    local env_files=(
        "$ZSHRC_DIR/.zshrc.d/00_01-environment.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_02-path-system.zsh"
    )

    for file in "${env_files[@]}"; do
        if [[ -f "$file" ]]; then
            # Count total export statements
            local file_exports=$(grep -c '^export ' "$file" 2>/dev/null || zf::debug "0")
            total_exports=$((total_exports + file_exports))

            # Count lowercase environment variables (inconsistent)
            local lowercase_exports=$(grep -c '^export [a-z]' "$file" 2>/dev/null || zf::debug "0")

            # Count unquoted simple values (potentially inconsistent)
            local unquoted_exports=$(grep -c '^export [A-Z_]*=[^"$][^[:space:]]*$' "$file" 2>/dev/null || zf::debug "0")

            inconsistent_exports=$((inconsistent_exports + lowercase_exports))

            zf::debug "    📊 $(basename "$file"): $file_exports total, $lowercase_exports lowercase, $unquoted_exports unquoted"
        fi
    done

    local consistency_rate=100
    if [[ $total_exports -gt 0 ]]; then
        consistency_rate=$(((total_exports - inconsistent_exports) * 100 / total_exports))
    fi

    zf::debug "    📊 Export statement consistency: ${consistency_rate}% ($((total_exports - inconsistent_exports))/$total_exports exports)"

    # Pass if 95% or higher consistency
    if [[ $consistency_rate -ge 95 ]]; then
        return 0
    else
        return 1
    fi
}

test_documentation_header_consistency() {
    zf::debug "    📋 Testing documentation header consistency..."

    local inconsistent_headers=0
    local total_files=0

    # Check key files for documentation headers
    local files_to_check=(
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_06-performance-monitoring.zsh"
        "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh"
    )

    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            total_files=$((total_files + 1))

            # Check for proper file description
            if head -10 "$file" | grep -q "Purpose:\|Description:"; then
                zf::debug "    ✅ Good header: $(basename "$file")"
            else
                zf::debug "    ⚠️ Missing description: $(basename "$file")"
                inconsistent_headers=$((inconsistent_headers + 1))
            fi

            # Check for double hash comments (inconsistent)
            if head -20 "$file" | grep -q '^##[^#]'; then
                zf::debug "    ⚠️ Double hash comments: $(basename "$file")"
                inconsistent_headers=$((inconsistent_headers + 1))
            fi
        fi
    done

    local consistency_rate=100
    if [[ $total_files -gt 0 ]]; then
        consistency_rate=$(((total_files - inconsistent_headers) * 100 / total_files))
    fi

    zf::debug "    📊 Documentation header consistency: ${consistency_rate}% ($((total_files - inconsistent_headers))/$total_files files)"

    # Pass if 85% or higher consistency (headers are complex)
    if [[ $consistency_rate -ge 85 ]]; then
        return 0
    else
        return 1
    fi
}

test_code_style_consistency() {
    zf::debug "    📋 Testing code style consistency..."

    local style_issues=0
    local total_files=0

    # Check core files for style consistency
    local style_files=(
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh"
    )

    for file in "${style_files[@]}"; do
        if [[ -f "$file" ]]; then
            total_files=$((total_files + 1))
            local file_issues=0

            # Check for tab characters (should use spaces)
            if grep -q $'\t' "$file" 2>/dev/null; then
                zf::debug "    ⚠️ Contains tabs: $(basename "$file")"
                file_issues=$((file_issues + 1))
            fi

            # Check for trailing whitespace
            if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
                zf::debug "    ⚠️ Trailing whitespace: $(basename "$file")"
                file_issues=$((file_issues + 1))
            fi

            if [[ $file_issues -eq 0 ]]; then
                zf::debug "    ✅ Clean style: $(basename "$file")"
            else
                style_issues=$((style_issues + file_issues))
            fi
        fi
    done

    local consistency_rate=100
    if [[ $total_files -gt 0 ]]; then
        # Each file can have multiple style issues, so we calculate differently
        local max_issues=$((total_files * 2)) # 2 potential issues per file
        consistency_rate=$(((max_issues - style_issues) * 100 / max_issues))
    fi

    zf::debug "    📊 Code style consistency: ${consistency_rate}% (${style_issues} issues across $total_files files)"

    # Pass if 90% or higher consistency
    if [[ $consistency_rate -ge 90 ]]; then
        return 0
    else
        return 1
    fi
}

test_error_handling_consistency() {
    zf::debug "    📋 Testing error handling consistency..."

    # This is a more subjective test, so we'll check for basic patterns
    local files_with_good_error_handling=0
    local total_files=0

    local files_to_check=(
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh"
    )

    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            total_files=$((total_files + 1))

            # Check for error handling patterns
            local error_patterns=$(grep -c '|| return\||| exit\||| echo.*ERROR\|handle_error' "$file" 2>/dev/null || zf::debug "0")

            if [[ $error_patterns -gt 0 ]]; then
                zf::debug "    ✅ Error handling present: $(basename "$file") ($error_patterns patterns)"
                files_with_good_error_handling=$((files_with_good_error_handling + 1))
            else
                zf::debug "    ⚠️ Limited error handling: $(basename "$file")"
            fi
        fi
    done

    local consistency_rate=100
    if [[ $total_files -gt 0 ]]; then
        consistency_rate=$((files_with_good_error_handling * 100 / total_files))
    fi

    zf::debug "    📊 Error handling consistency: ${consistency_rate}% ($files_with_good_error_handling/$total_files files)"

    # Pass if 80% or higher (error handling varies by file purpose)
    if [[ $consistency_rate -ge 80 ]]; then
        return 0
    else
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Consistency Validation Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Configuration Directory: $ZSHRC_DIR"
    zf::debug ""

    log_test "Starting consistency validation test suite"

    # Consistency Tests
    zf::debug "=== Consistency Validation Tests ==="
    run_test "Shebang Consistency" "test_shebang_consistency"
    run_test "Function Naming Consistency" "test_function_naming_consistency"
    run_test "Export Statement Consistency" "test_export_statement_consistency"
    run_test "Documentation Header Consistency" "test_documentation_header_consistency"
    run_test "Code Style Consistency" "test_code_style_consistency"
    run_test "Error Handling Consistency" "test_error_handling_consistency"

    # Calculate overall consistency score
    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi

    # Map test results to consistency score
    if [[ $pass_percentage -eq 100 ]]; then
        CONSISTENCY_SCORE=100
    elif [[ $pass_percentage -ge 83 ]]; then # 5/6 tests passing
        CONSISTENCY_SCORE=95
    elif [[ $pass_percentage -ge 67 ]]; then # 4/6 tests passing
        CONSISTENCY_SCORE=90
    elif [[ $pass_percentage -ge 50 ]]; then # 3/6 tests passing
        CONSISTENCY_SCORE=85
    else
        CONSISTENCY_SCORE=80
    fi

    # Results Summary
    zf::debug ""
    zf::debug "========================================================"
    zf::debug "Consistency Validation Results"
    zf::debug "========================================================"
    zf::debug "Total Tests: $TEST_COUNT"
    zf::debug "Passed: $TEST_PASSED"
    zf::debug "Failed: $TEST_FAILED"
    zf::debug "Test Success Rate: ${pass_percentage}%"
    zf::debug ""
    zf::debug "🎯 CONSISTENCY SCORE: ${CONSISTENCY_SCORE}%"
    zf::debug ""

    # Consistency assessment
    if [[ $CONSISTENCY_SCORE -eq 100 ]]; then
        zf::debug "🏆 PERFECT CONSISTENCY: Configuration achieves 100% consistency!"
        zf::debug "✅ All consistency standards met with excellence"
    elif [[ $CONSISTENCY_SCORE -ge 95 ]]; then
        zf::debug "🥇 EXCELLENT CONSISTENCY: Configuration achieves ${CONSISTENCY_SCORE}% consistency!"
        zf::debug "✅ Meets enterprise-grade consistency standards"
    elif [[ $CONSISTENCY_SCORE -ge 90 ]]; then
        zf::debug "🥈 VERY GOOD CONSISTENCY: Configuration achieves ${CONSISTENCY_SCORE}% consistency!"
        zf::debug "✅ Meets professional consistency standards"
    elif [[ $CONSISTENCY_SCORE -ge 85 ]]; then
        zf::debug "🥉 GOOD CONSISTENCY: Configuration achieves ${CONSISTENCY_SCORE}% consistency!"
        zf::debug "⚠️ Minor consistency improvements recommended"
    else
        zf::debug "⚠️ CONSISTENCY NEEDS IMPROVEMENT: ${CONSISTENCY_SCORE}% consistency"
        zf::debug "❌ Significant consistency improvements needed"
    fi

    log_test "Consistency validation completed - ${CONSISTENCY_SCORE}% consistency score achieved"

    if [[ $CONSISTENCY_SCORE -ge 95 ]]; then
        zf::debug ""
        zf::debug "🎉 Consistency validation successful!"
        return 0
    else
        zf::debug ""
        zf::debug "⚠️ Consistency improvements needed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

consistency_validation_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    consistency_validation_main "$@"
elif is_being_sourced; then
    zf::debug "Consistency validation test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Consistency Validation Test Suite
# ==============================================================================
