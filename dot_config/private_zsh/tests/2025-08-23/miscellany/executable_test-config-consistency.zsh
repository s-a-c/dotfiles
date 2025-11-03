#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Configuration Consistency Test Suite
# ==============================================================================
# Purpose: Test configuration files for adherence to standardization patterns
#          including exports, paths, conditionals, and helper function usage
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-config-consistency.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_HELPERS_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system
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

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-config-consistency.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration paths
ZSH_CONFIG_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"
ZSHRC_DIR="$ZSH_CONFIG_ROOT/.zshrc.d"

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

    zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        zf::debug "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        zf::debug "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. CONFIGURATION FILE DISCOVERY
# ------------------------------------------------------------------------------

get_config_files() {
    find "$ZSHRC_DIR" -name "*.zsh" -type f 2>/dev/null | sort
}

# ------------------------------------------------------------------------------
# 3. SHEBANG CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_shebang_consistency() {
    local files_with_shebang=0
    local files_with_correct_shebang=0
    local total_files=0

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        local first_line=$(head -n 1 "$config_file")
        if [[ "$first_line" =~ ^#!/ ]]; then
            files_with_shebang=$((files_with_shebang + 1))

            if [[ "$first_line" == "#!/usr/bin/env zsh" ]]; then
                files_with_correct_shebang=$((files_with_correct_shebang + 1))
                zf::debug "    ✓ $(basename "$config_file"): Correct shebang"
            else
                zf::debug "    ⚠ $(basename "$config_file"): Incorrect shebang: $first_line"
            fi
        fi
    done < <(get_config_files)

    zf::debug "    📊 Shebang analysis: $files_with_correct_shebang correct, $files_with_shebang total with shebang, $total_files total files"

    # Pass if files that have shebangs use the correct one
    [[ $files_with_shebang -eq 0 ]] || [[ $files_with_correct_shebang -eq $files_with_shebang ]]
}

# ------------------------------------------------------------------------------
# 4. DEBUG PATTERN CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_debug_pattern_consistency() {
    local files_with_debug=0
    local files_with_consistent_debug=0
    local total_files=0

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        if grep -q "ZSH_DEBUG" "$config_file" 2>/dev/null; then
            files_with_debug=$((files_with_debug + 1))

            # Check for consistent debug pattern
            if grep -q '\[\[ "$ZSH_DEBUG" == "1" \]\]' "$config_file" 2>/dev/null; then
                files_with_consistent_debug=$((files_with_consistent_debug + 1))
                zf::debug "    ✓ $(basename "$config_file"): Consistent debug pattern"
            else
                zf::debug "    ⚠ $(basename "$config_file"): Inconsistent debug pattern"
            fi
        fi
    done < <(get_config_files)

    zf::debug "    📊 Debug pattern analysis: $files_with_consistent_debug/$files_with_debug files use consistent debug patterns"

    # Pass if most files with debug use consistent patterns
    [[ $files_with_debug -eq 0 ]] || [[ $files_with_consistent_debug -ge $((files_with_debug * 3 / 4)) ]]
}

# ------------------------------------------------------------------------------
# 5. EXPORT PATTERN CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_export_pattern_consistency() {
    local files_with_exports=0
    local files_with_good_exports=0
    local total_files=0

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        if grep -q "export " "$config_file" 2>/dev/null; then
            files_with_exports=$((files_with_exports + 1))

            # Check for problematic export patterns
            local problematic_exports=0

            # Check for exports without quotes around values with spaces
            if grep -q 'export [A-Z_]*=[^"]*[[:space:]]' "$config_file" 2>/dev/null; then
                problematic_exports=$((problematic_exports + 1))
            fi

            # Check for exports with inconsistent naming
            if grep -q 'export [a-z]' "$config_file" 2>/dev/null; then
                problematic_exports=$((problematic_exports + 1))
            fi

            if [[ $problematic_exports -eq 0 ]]; then
                files_with_good_exports=$((files_with_good_exports + 1))
                zf::debug "    ✓ $(basename "$config_file"): Good export patterns"
            else
                zf::debug "    ⚠ $(basename "$config_file"): $problematic_exports problematic export patterns"
            fi
        fi
    done < <(get_config_files)

    zf::debug "    📊 Export pattern analysis: $files_with_good_exports/$files_with_exports files have good export patterns"

    # Pass if most files with exports use good patterns
    [[ $files_with_exports -eq 0 ]] || [[ $files_with_good_exports -ge $((files_with_exports * 2 / 3)) ]]
}

# ------------------------------------------------------------------------------
# 6. HELPER FUNCTION USAGE TESTS
# ------------------------------------------------------------------------------

test_helper_function_usage() {
    local files_that_could_use_helpers=0
    local files_using_helpers=0
    local total_files=0

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        # Skip the helpers file itself
        [[ "$config_file" =~ "standard-helpers" ]] && continue

        # Check if file could benefit from helper functions
        local could_use_helpers=false

        # Files with command existence checks
        if grep -q "command -v\|which\|type " "$config_file" 2>/dev/null; then
            could_use_helpers=true
        fi

        # Files with PATH manipulation
        if grep -q "PATH=" "$config_file" 2>/dev/null; then
            could_use_helpers=true
        fi

        # Files with file existence checks
        if grep -q "\[\[ -f\|\[\[ -d\|\[\[ -x" "$config_file" 2>/dev/null; then
            could_use_helpers=true
        fi

        if $could_use_helpers; then
            files_that_could_use_helpers=$((files_that_could_use_helpers + 1))

            # Check if actually using helper functions
            if grep -q "has_command\|path_prepend\|path_append\|has_readable_file\|safe_source" "$config_file" 2>/dev/null; then
                files_using_helpers=$((files_using_helpers + 1))
                zf::debug "    ✓ $(basename "$config_file"): Uses helper functions"
            else
                zf::debug "    ⚠ $(basename "$config_file"): Could use helper functions"
            fi
        fi
    done < <(get_config_files)

    zf::debug "    📊 Helper usage analysis: $files_using_helpers/$files_that_could_use_helpers files use helper functions where beneficial"

    # Pass if at least some files use helpers (gradual adoption expected)
    [[ $files_that_could_use_helpers -eq 0 ]] || [[ $files_using_helpers -gt 0 ]]
}

# ------------------------------------------------------------------------------
# 7. DOCUMENTATION CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_documentation_consistency() {
    local files_with_headers=0
    local files_with_good_headers=0
    local total_files=0

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        # Check for header comments in first 10 lines
        local header_content=$(head -n 10 "$config_file")

        if [[ "$header_content" =~ "#" ]]; then
            files_with_headers=$((files_with_headers + 1))

            # Check for good header patterns
            local good_header=true

            # Should have purpose/description
            if ! zf::debug "$header_content" | grep -qi "purpose\|description\|configuration" 2>/dev/null; then
                good_header=false
            fi

            if $good_header; then
                files_with_good_headers=$((files_with_good_headers + 1))
                zf::debug "    ✓ $(basename "$config_file"): Good documentation header"
            else
                zf::debug "    ⚠ $(basename "$config_file"): Could improve documentation header"
            fi
        else
            zf::debug "    ⚠ $(basename "$config_file"): No header documentation"
        fi
    done < <(get_config_files)

    zf::debug "    📊 Documentation analysis: $files_with_good_headers/$files_with_headers files have good headers, $files_with_headers/$total_files have headers"

    # Pass if most files have some form of header
    [[ $files_with_headers -ge $((total_files * 2 / 3)) ]]
}

# ------------------------------------------------------------------------------
# 8. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Configuration Consistency Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Configuration Directory: $ZSHRC_DIR"
    zf::debug ""

    log_test "Starting configuration consistency test suite"

    # Shebang Consistency
    zf::debug "=== Shebang Consistency Tests ==="
    run_test "Shebang Consistency" "test_shebang_consistency"

    # Debug Pattern Consistency
    zf::debug ""
    zf::debug "=== Debug Pattern Consistency Tests ==="
    run_test "Debug Pattern Consistency" "test_debug_pattern_consistency"

    # Export Pattern Consistency
    zf::debug ""
    zf::debug "=== Export Pattern Consistency Tests ==="
    run_test "Export Pattern Consistency" "test_export_pattern_consistency"

    # Helper Function Usage
    zf::debug ""
    zf::debug "=== Helper Function Usage Tests ==="
    run_test "Helper Function Usage" "test_helper_function_usage"

    # Documentation Consistency
    zf::debug ""
    zf::debug "=== Documentation Consistency Tests ==="
    run_test "Documentation Consistency" "test_documentation_consistency"

    # Results Summary
    zf::debug ""
    zf::debug "========================================================"
    zf::debug "Test Results Summary"
    zf::debug "========================================================"
    zf::debug "Total Tests: $TEST_COUNT"
    zf::debug "Passed: $TEST_PASSED"
    zf::debug "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi
    zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Configuration consistency test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All configuration consistency tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED configuration consistency test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 9. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
    zf::debug "Configuration consistency test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Configuration Consistency Test Suite
# ==============================================================================
