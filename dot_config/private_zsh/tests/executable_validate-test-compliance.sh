#!/bin/bash
# ==============================================================================
# validate-test-compliance.sh
#
# Test Compliance Validator for ZSH Test Suite
#
# Purpose:
#   Validates that all test scripts comply with the zsh -f requirement and
#   testing standards. Provides detailed reports on compliance status and
#   migration needs.
#
# Usage:
#   ./validate-test-compliance.sh                    # Check all tests
#   ./validate-test-compliance.sh tests/unit         # Check specific directory
#   ./validate-test-compliance.sh --fix              # Add compliance headers
#   ./validate-test-compliance.sh --report           # Generate detailed report
#   ./validate-test-compliance.sh --ci               # CI mode (exit 1 on failures)
#
# Exit Codes:
#   0 - All tests compliant
#   1 - Compliance failures found
#   2 - Script error
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_BASE_DIR="${TEST_BASE_DIR:-$SCRIPT_DIR}"
REPORT_FILE="${REPORT_FILE:-$SCRIPT_DIR/compliance-report.txt}"

# Counters
total_tests=0
compliant_tests=0
non_compliant_tests=0
skipped_tests=0
fixed_tests=0

# Arrays for tracking
declare -a COMPLIANT=()
declare -a NON_COMPLIANT=()
declare -a SKIPPED=()
declare -a NEEDS_HEADER=()
declare -a TIMEOUT_FAILURES=()
declare -a EXECUTION_FAILURES=()

# Options
FIX_MODE=0
REPORT_MODE=0
CI_MODE=0
VERBOSE=0
TEST_TIMEOUT=5

# Colors (if terminal supports)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_verbose() {
    [[ $VERBOSE -eq 1 ]] && echo -e "${CYAN}[DEBUG]${NC} $*" >&2
}

# Check if file has compliance header
has_compliance_header() {
    local file="$1"

    if grep -q "TEST_MODE:" "$file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Extract test mode from header
get_test_mode() {
    local file="$1"

    grep "TEST_MODE:" "$file" 2>/dev/null | sed 's/.*TEST_MODE: *//' | awk '{print $1}'
}

# Check if test runs with zsh -f
test_zsh_f_execution() {
    local file="$1"
    local timeout_cmd="timeout"

    # Check for GNU timeout or gtimeout
    if ! command -v timeout >/dev/null 2>&1; then
        if command -v gtimeout >/dev/null 2>&1; then
            timeout_cmd="gtimeout"
        else
            log_verbose "No timeout command available, using subshell with sleep"
            # Fallback: run in background and kill after timeout
            (
                zsh -f "$file" >/dev/null 2>&1 &
                local pid=$!
                sleep $TEST_TIMEOUT
                kill $pid 2>/dev/null && return 124
                wait $pid
                return $?
            )
            return $?
        fi
    fi

    # Run test with timeout
    log_verbose "Testing: $timeout_cmd $TEST_TIMEOUT zsh -f $file"
    $timeout_cmd $TEST_TIMEOUT zsh -f "$file" >/dev/null 2>&1
    return $?
}

# Add compliance header to file
add_compliance_header() {
    local file="$1"
    local temp_file="/tmp/compliance_fix_$$"

    # Determine test class based on path
    local test_class="unit"
    if [[ "$file" == *"/integration/"* ]]; then
        test_class="integration"
    elif [[ "$file" == *"/performance/"* ]] || [[ "$file" == *"/perf/"* ]]; then
        test_class="performance"
    elif [[ "$file" == *"/e2e/"* ]]; then
        test_class="e2e"
    fi

    # Create header
    cat > "$temp_file" << 'EOF'
#!/usr/bin/env zsh
# ==============================================================================
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# DEPENDENCIES: self-contained
#
# [Original content follows]
# ==============================================================================

EOF

    # Update test class
    sed -i.bak "s/TEST_CLASS: unit/TEST_CLASS: $test_class/" "$temp_file"

    # Append original content (skip shebang if present)
    if head -1 "$file" | grep -q "^#!/"; then
        tail -n +2 "$file" >> "$temp_file"
    else
        cat "$file" >> "$temp_file"
    fi

    # Replace original
    mv "$temp_file" "$file"
    chmod +x "$file"

    log_success "Added compliance header to $(basename "$file")"
}

# Validate a single test file
validate_test() {
    local file="$1"
    local basename="$(basename "$file")"

    ((total_tests++))

    log_verbose "Validating: $file"

    # Check 1: Has compliance header
    if ! has_compliance_header "$file"; then
        log_verbose "  Missing compliance header"
        NEEDS_HEADER+=("$file")

        if [[ $FIX_MODE -eq 1 ]]; then
            add_compliance_header "$file"
            ((fixed_tests++))
        fi
    fi

    # Check 2: Test mode declaration
    local test_mode=$(get_test_mode "$file")
    if [[ -z "$test_mode" ]]; then
        test_mode="unknown"
    fi

    log_verbose "  Test mode: $test_mode"

    # Check 3: Actual zsh -f execution
    if [[ "$test_mode" == "full-environment" ]] || [[ "$test_mode" == "full-environment-allowed" ]]; then
        log_verbose "  Skipping zsh -f test (full environment allowed)"
        SKIPPED+=("$file")
        ((skipped_tests++))
        return 0
    fi

    # Try to run with zsh -f
    test_zsh_f_execution "$file"
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_verbose "  ✓ Passes zsh -f execution"
        COMPLIANT+=("$file")
        ((compliant_tests++))
    elif [[ $exit_code -eq 124 ]]; then
        log_verbose "  ✗ Timeout during zsh -f execution"
        TIMEOUT_FAILURES+=("$file")
        NON_COMPLIANT+=("$file")
        ((non_compliant_tests++))
    elif [[ $exit_code -eq 3 ]]; then
        log_verbose "  ⚠ Test skipped itself"
        SKIPPED+=("$file")
        ((skipped_tests++))
    else
        log_verbose "  ✗ Failed zsh -f execution (exit: $exit_code)"
        EXECUTION_FAILURES+=("$file")
        NON_COMPLIANT+=("$file")
        ((non_compliant_tests++))
    fi
}

# Generate detailed report
generate_report() {
    local report_file="$1"

    {
        echo "ZSH Test Compliance Report"
        echo "=========================="
        echo "Generated: $(date)"
        echo "Test Directory: $TEST_BASE_DIR"
        echo ""
        echo "Summary"
        echo "-------"
        echo "Total Tests:        $total_tests"
        echo "Compliant:          $compliant_tests ($(( compliant_tests * 100 / (total_tests > 0 ? total_tests : 1) ))%)"
        echo "Non-Compliant:      $non_compliant_tests"
        echo "Skipped (E2E):      $skipped_tests"
        if [[ $FIX_MODE -eq 1 ]]; then
            echo "Fixed:              $fixed_tests"
        fi
        echo ""

        if [[ ${#COMPLIANT[@]} -gt 0 ]]; then
            echo "Compliant Tests (${#COMPLIANT[@]})"
            echo "----------------"
            for test in "${COMPLIANT[@]}"; do
                echo "  ✓ $(basename "$test")"
            done
            echo ""
        fi

        if [[ ${#NON_COMPLIANT[@]} -gt 0 ]]; then
            echo "Non-Compliant Tests (${#NON_COMPLIANT[@]})"
            echo "-------------------"
            for test in "${NON_COMPLIANT[@]}"; do
                echo "  ✗ $(basename "$test")"
                if [[ " ${TIMEOUT_FAILURES[*]} " == *" $test "* ]]; then
                    echo "    Reason: Timeout during zsh -f execution"
                elif [[ " ${EXECUTION_FAILURES[*]} " == *" $test "* ]]; then
                    echo "    Reason: Failed zsh -f execution"
                fi
                if [[ " ${NEEDS_HEADER[*]} " == *" $test "* ]]; then
                    echo "    Missing: Compliance header"
                fi
            done
            echo ""
        fi

        if [[ ${#SKIPPED[@]} -gt 0 ]]; then
            echo "Skipped Tests (E2E) (${#SKIPPED[@]})"
            echo "-------------------"
            for test in "${SKIPPED[@]}"; do
                echo "  ⚠ $(basename "$test") - Requires full environment"
            done
            echo ""
        fi

        echo "Recommendations"
        echo "--------------"
        if [[ ${#NEEDS_HEADER[@]} -gt 0 ]]; then
            echo "• Add compliance headers to ${#NEEDS_HEADER[@]} tests"
            echo "  Run: $0 --fix"
        fi
        if [[ ${#TIMEOUT_FAILURES[@]} -gt 0 ]]; then
            echo "• Fix timeout issues in ${#TIMEOUT_FAILURES[@]} tests"
            echo "  These tests likely have infinite loops or are loading .zshenv"
        fi
        if [[ ${#EXECUTION_FAILURES[@]} -gt 0 ]]; then
            echo "• Fix execution failures in ${#EXECUTION_FAILURES[@]} tests"
            echo "  These tests have missing dependencies or syntax errors"
        fi

        echo ""
        echo "Migration Commands"
        echo "-----------------"
        if [[ ${#NON_COMPLIANT[@]} -gt 0 ]]; then
            echo "# Test individual failures:"
            for test in "${NON_COMPLIANT[@]:0:3}"; do
                echo "zsh -f $test"
            done
            if [[ ${#NON_COMPLIANT[@]} -gt 3 ]]; then
                echo "# ... and $((${#NON_COMPLIANT[@]} - 3)) more"
            fi
        fi
    } | tee "$report_file"
}

# ------------------------------------------------------------------------------
# Main Script
# ------------------------------------------------------------------------------

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            FIX_MODE=1
            shift
            ;;
        --report)
            REPORT_MODE=1
            shift
            ;;
        --ci)
            CI_MODE=1
            shift
            ;;
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --timeout)
            TEST_TIMEOUT="$2"
            shift 2
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS] [TEST_DIRECTORY]

Options:
    --fix       Add compliance headers to tests missing them
    --report    Generate detailed compliance report
    --ci        CI mode (exit 1 if any non-compliant tests)
    --verbose   Show detailed progress
    --timeout N Set test timeout in seconds (default: 5)
    --help      Show this help message

Examples:
    $0                           # Check all tests
    $0 tests/unit                # Check specific directory
    $0 --fix                    # Add missing headers
    $0 --report --ci            # Generate report and fail if non-compliant
EOF
            exit 0
            ;;
        *)
            # Assume it's a test directory
            if [[ -d "$1" ]]; then
                TEST_BASE_DIR="$1"
            else
                log_error "Unknown option or invalid directory: $1"
                exit 2
            fi
            shift
            ;;
    esac
done

# Main execution
log_info "ZSH Test Compliance Validator"
log_info "Checking tests in: $TEST_BASE_DIR"
echo ""

# Find all test files
test_files=()
while IFS= read -r -d '' file; do
    test_files+=("$file")
done < <(find "$TEST_BASE_DIR" -name "test-*.zsh" -type f -print0 2>/dev/null)

if [[ ${#test_files[@]} -eq 0 ]]; then
    log_warning "No test files found in $TEST_BASE_DIR"
    exit 0
fi

log_info "Found ${#test_files[@]} test files to validate"
echo ""

# Validate each test
for test_file in "${test_files[@]}"; do
    validate_test "$test_file"
done

echo ""

# Generate report if requested
if [[ $REPORT_MODE -eq 1 ]]; then
    generate_report "$REPORT_FILE"
else
    # Simple summary
    echo "================================"
    echo "Validation Summary"
    echo "================================"
    echo -e "Total Tests:    $total_tests"
    echo -e "Compliant:      ${GREEN}$compliant_tests${NC} ($(( compliant_tests * 100 / (total_tests > 0 ? total_tests : 1) ))%)"
    echo -e "Non-Compliant:  ${RED}$non_compliant_tests${NC}"
    echo -e "Skipped (E2E):  ${YELLOW}$skipped_tests${NC}"

    if [[ $FIX_MODE -eq 1 ]]; then
        echo -e "Fixed:          ${GREEN}$fixed_tests${NC}"
    fi
fi

# Exit code
if [[ $CI_MODE -eq 1 && $non_compliant_tests -gt 0 ]]; then
    echo ""
    log_error "CI Mode: Failing due to $non_compliant_tests non-compliant tests"
    exit 1
elif [[ $non_compliant_tests -gt 0 ]]; then
    echo ""
    log_warning "Found $non_compliant_tests non-compliant tests. Run with --fix to add headers."
    exit 0
else
    echo ""
    log_success "All tests are compliant!"
    exit 0
fi
