#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Documentation Headers Test Suite
# ==============================================================================
# Purpose: Test configuration files for standardized documentation headers
#          including proper format, numbering, purpose statements, and
#          consistent structure across all configuration files.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-doc-headers.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
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
LOG_FILE="$LOG_DIR/test-doc-headers.log"
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
        zsh_debug_echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

        zsh_debug_echo "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
            zsh_debug_echo "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
            zsh_debug_echo "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

get_config_files() {
    find "$ZSHRC_DIR" -name "*.zsh" -type f 2>/dev/null | sort
}

# ------------------------------------------------------------------------------
# 2. HEADER PRESENCE TESTS
# ------------------------------------------------------------------------------

test_header_presence() {
    local files_with_headers=0
    local files_without_headers=0
    local total_files=0

        zsh_debug_echo "    📊 Analyzing header presence..."

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        local filename=$(basename "$config_file")
        local first_10_lines=$(head -n 10 "$config_file")

        # Check if file has any comment header in first 10 lines
        if     zsh_debug_echo "$first_10_lines" | grep -q "^#" 2>/dev/null; then
            files_with_headers=$((files_with_headers + 1))
                zsh_debug_echo "    ✓ $filename: Has header comments"
        else
            files_without_headers=$((files_without_headers + 1))
                zsh_debug_echo "    ⚠ $filename: No header comments"
        fi
    done < <(get_config_files)

        zsh_debug_echo "    📊 Header presence: $files_with_headers/$total_files files have headers"

    # Pass if at least 80% of files have headers
    local header_percentage=$((files_with_headers * 100 / total_files))
    [[ $header_percentage -ge 80 ]]
}

# ------------------------------------------------------------------------------
# 3. HEADER FORMAT TESTS
# ------------------------------------------------------------------------------

test_header_format_quality() {
    local files_with_good_headers=0
    local files_with_poor_headers=0
    local total_files=0

        zsh_debug_echo "    📊 Analyzing header format quality..."

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        local filename=$(basename "$config_file")
        local first_20_lines=$(head -n 20 "$config_file")

        # Skip files without headers
        if !     zsh_debug_echo "$first_20_lines" | grep -q "^#" 2>/dev/null; then
            continue
        fi

        local header_quality_score=0
        local max_score=5

        # Check 1: Has purpose/description
        if     zsh_debug_echo "$first_20_lines" | grep -qi "purpose\|description\|configuration" 2>/dev/null; then
            header_quality_score=$((header_quality_score + 1))
        fi

        # Check 2: Has structured format (multiple comment lines)
        local comment_lines=$(echo "$first_20_lines" | grep -c "^#" 2>/dev/null)
        if [[ $comment_lines -ge 3 ]]; then
            header_quality_score=$((header_quality_score + 1))
        fi

        # Check 3: Has section separators or organization
        if     zsh_debug_echo "$first_20_lines" | grep -q "^#.*=\|^#.*-\|^##" 2>/dev/null; then
            header_quality_score=$((header_quality_score + 1))
        fi

        # Check 4: Has file identification (filename or title)
        if     zsh_debug_echo "$first_20_lines" | grep -qi "file:\|title:\|name:" 2>/dev/null; then
            header_quality_score=$((header_quality_score + 1))
        fi

        # Check 5: Has load order or dependency info
        if     zsh_debug_echo "$first_20_lines" | grep -qi "load\|order\|depend\|phase" 2>/dev/null; then
            header_quality_score=$((header_quality_score + 1))
        fi

        local quality_percentage=$((header_quality_score * 100 / max_score))

        if [[ $quality_percentage -ge 60 ]]; then
            files_with_good_headers=$((files_with_good_headers + 1))
                zsh_debug_echo "    ✓ $filename: Good header quality ($quality_percentage%)"
        else
            files_with_poor_headers=$((files_with_poor_headers + 1))
                zsh_debug_echo "    ⚠ $filename: Poor header quality ($quality_percentage%)"
        fi
    done < <(get_config_files)

        zsh_debug_echo "    📊 Header quality: $files_with_good_headers good, $files_with_poor_headers poor"

    # Pass if at least 70% of files with headers have good quality
    local total_with_headers=$((files_with_good_headers + files_with_poor_headers))
    if [[ $total_with_headers -gt 0 ]]; then
        local good_percentage=$((files_with_good_headers * 100 / total_with_headers))
        [[ $good_percentage -ge 70 ]]
    else
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 4. STANDARDIZED FORMAT TESTS
# ------------------------------------------------------------------------------

test_standardized_format_compliance() {
    local files_with_standard_format=0
    local files_without_standard_format=0
    local total_files=0

        zsh_debug_echo "    📊 Analyzing standardized format compliance..."

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue
        total_files=$((total_files + 1))

        local filename=$(basename "$config_file")
        local first_30_lines=$(head -n 30 "$config_file")

        local standard_compliance_score=0
        local max_score=4

        # Check 1: Uses proper shebang
        if head -n 1 "$config_file" | grep -q "#!/opt/homebrew/bin/zsh" 2>/dev/null; then
            standard_compliance_score=$((standard_compliance_score + 1))
        fi

        # Check 2: Has structured header block (==== or ---- separators)
        if     zsh_debug_echo "$first_30_lines" | grep -q "^#.*====\|^#.*----" 2>/dev/null; then
            standard_compliance_score=$((standard_compliance_score + 1))
        fi

        # Check 3: Has numbered sections (## 1. or similar)
        if     zsh_debug_echo "$first_30_lines" | grep -q "^##.*[0-9]\." 2>/dev/null; then
            standard_compliance_score=$((standard_compliance_score + 1))
        fi

        # Check 4: Has consistent comment formatting
        local hash_lines=$(echo "$first_30_lines" | grep -c "^#" 2>/dev/null)
        local structured_lines=$(echo "$first_30_lines" | grep -c "^# \|^##" 2>/dev/null)
        if [[ $hash_lines -gt 0 && $structured_lines -ge $((hash_lines * 2 / 3)) ]]; then
            standard_compliance_score=$((standard_compliance_score + 1))
        fi

        local compliance_percentage=$((standard_compliance_score * 100 / max_score))

        if [[ $compliance_percentage -ge 50 ]]; then
            files_with_standard_format=$((files_with_standard_format + 1))
                zsh_debug_echo "    ✓ $filename: Standard format compliance ($compliance_percentage%)"
        else
            files_without_standard_format=$((files_without_standard_format + 1))
                zsh_debug_echo "    ⚠ $filename: Non-standard format ($compliance_percentage%)"
        fi
    done < <(get_config_files)

        zsh_debug_echo "    📊 Standard format: $files_with_standard_format compliant, $files_without_standard_format non-compliant"

    # Pass if at least 60% of files follow standard format
    local compliance_percentage=$((files_with_standard_format * 100 / total_files))
    [[ $compliance_percentage -ge 60 ]]
}

# ------------------------------------------------------------------------------
# 5. CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_header_consistency() {
    local consistent_patterns=0
    local total_patterns=3

        zsh_debug_echo "    📊 Analyzing header consistency patterns..."

    # Pattern 1: Consistent debug pattern usage
    local debug_pattern_files=$(find "$ZSHRC_DIR" -name "*.zsh" -exec grep -l 'ZSH_DEBUG.*==.*1' {} \; 2>/dev/null | wc -l)
    local total_files=$(find "$ZSHRC_DIR" -name "*.zsh" | wc -l)

    if [[ $debug_pattern_files -ge $((total_files * 2 / 3)) ]]; then
        consistent_patterns=$((consistent_patterns + 1))
            zsh_debug_echo "    ✓ Debug pattern: Consistently used across files"
    else
            zsh_debug_echo "    ⚠ Debug pattern: Inconsistent usage"
    fi

    # Pattern 2: Consistent section numbering
    local numbered_section_files=$(find "$ZSHRC_DIR" -name "*.zsh" -exec grep -l '^##.*[0-9]\.' {} \; 2>/dev/null | wc -l)

    if [[ $numbered_section_files -ge $((total_files / 3)) ]]; then
        consistent_patterns=$((consistent_patterns + 1))
            zsh_debug_echo "    ✓ Section numbering: Used in multiple files"
    else
            zsh_debug_echo "    ⚠ Section numbering: Limited usage"
    fi

    # Pattern 3: Consistent header separators
    local separator_files=$(find "$ZSHRC_DIR" -name "*.zsh" -exec grep -l '^#.*====\|^#.*----' {} \; 2>/dev/null | wc -l)

    if [[ $separator_files -ge $((total_files / 4)) ]]; then
        consistent_patterns=$((consistent_patterns + 1))
            zsh_debug_echo "    ✓ Header separators: Used in multiple files"
    else
            zsh_debug_echo "    ⚠ Header separators: Limited usage"
    fi

        zsh_debug_echo "    📊 Consistency patterns: $consistent_patterns/$total_patterns patterns are consistent"

    # Pass if at least 2/3 patterns are consistent
    [[ $consistent_patterns -ge $((total_patterns * 2 / 3)) ]]
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Documentation Headers Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Configuration Directory: $ZSHRC_DIR"
        zsh_debug_echo ""

    log_test "Starting documentation headers test suite"

    # Header Presence Tests
        zsh_debug_echo "=== Header Presence Tests ==="
    run_test "Header Presence" "test_header_presence"

    # Header Format Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Header Format Quality Tests ==="
    run_test "Header Format Quality" "test_header_format_quality"

    # Standardized Format Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Standardized Format Tests ==="
    run_test "Standardized Format Compliance" "test_standardized_format_compliance"

    # Consistency Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Header Consistency Tests ==="
    run_test "Header Consistency" "test_header_consistency"

    # Results Summary
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zsh_debug_echo "Success Rate: ${pass_percentage}%"

    log_test "Documentation headers test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All documentation header tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED documentation header test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
        zsh_debug_echo "Documentation headers test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Documentation Headers Test Suite
# ==============================================================================
