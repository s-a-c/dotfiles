#!/bin/bash
# ==============================================================================
# run-tests-direct.sh
#
# Direct test runner that bypasses zsh startup overhead by running tests
# directly with minimal environment setup.
#
# This script:
# - Uses bash instead of zsh to avoid .zshenv loading
# - Sets up minimal required environment variables
# - Runs test files directly with zsh -f (no startup files)
# - Provides fast test execution for CI and development
# ==============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZDOTDIR="${ZDOTDIR:-$(dirname "$SCRIPT_DIR")}"
TEST_BASE_DIR="${ZDOTDIR}/tests"
RESULTS_DIR="${ZDOTDIR}/logs/test-results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS_FILE="${RESULTS_DIR}/test-results-${TIMESTAMP}.log"

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Test counters
total_tests=0
passed_tests=0
failed_tests=0
skipped_tests=0

# Colors for output (if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging function
log_result() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" | tee -a "$RESULTS_FILE"
}

# Run a single test with minimal zsh environment
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .zsh)"

    ((total_tests++))

    echo -n -e "${BLUE}Running${NC} ($total_tests) $test_name... "

    if [[ ! -f "$test_file" ]]; then
        echo -e "${YELLOW}SKIP${NC} (not found)"
        log_result "SKIP" "$test_name - not found"
        ((skipped_tests++))
        return 0
    fi

    if [[ ! -r "$test_file" ]]; then
        echo -e "${YELLOW}SKIP${NC} (not readable)"
        log_result "SKIP" "$test_name - not readable"
        ((skipped_tests++))
        return 0
    fi

    # Run test with minimal zsh environment
    # -f: no startup files (.zshenv, .zshrc, etc.)
    # We export minimal required variables
    local output
    local exit_code

    output=$(
        export ZDOTDIR="$ZDOTDIR"
        export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
        export ZSH_LOG_DIR="${ZSH_LOG_DIR:-$ZDOTDIR/logs}"
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

        # Run with timeout
        timeout 10 /bin/zsh -f "$test_file" 2>&1
    ) && exit_code=0 || exit_code=$?

    # Handle timeout
    if [[ $exit_code -eq 124 ]]; then
        echo -e "${RED}TIMEOUT${NC}"
        log_result "FAIL" "$test_name - timeout after 10s"
        ((failed_tests++))
        echo "  Partial output:"
        echo "$output" | head -10 | sed 's/^/    /'
        return 0
    fi

    # Process results
    if [[ $exit_code -eq 0 ]]; then
        # Check if test output indicates pass
        if echo "$output" | grep -q "TEST RESULT: PASS"; then
            echo -e "${GREEN}PASS${NC}"
            log_result "PASS" "$test_name"
            ((passed_tests++))
        elif echo "$output" | grep -q "TEST RESULT: FAIL"; then
            echo -e "${RED}FAIL${NC}"
            log_result "FAIL" "$test_name - test reported failure"
            ((failed_tests++))
            echo "  Test output:"
            echo "$output" | grep -E "(FAIL|ERROR|SUMMARY)" | head -5 | sed 's/^/    /'
        elif echo "$output" | grep -q "SKIP"; then
            echo -e "${YELLOW}SKIP${NC}"
            log_result "SKIP" "$test_name - test skipped itself"
            ((skipped_tests++))
        else
            # No clear result, check exit code
            if [[ $exit_code -eq 0 ]]; then
                echo -e "${GREEN}PASS${NC} (exit 0)"
                log_result "PASS" "$test_name (by exit code)"
                ((passed_tests++))
            else
                echo -e "${RED}FAIL${NC} (exit $exit_code)"
                log_result "FAIL" "$test_name - exit code: $exit_code"
                ((failed_tests++))
                echo "  Output tail:"
                echo "$output" | tail -5 | sed 's/^/    /'
            fi
        fi
    else
        echo -e "${RED}FAIL${NC} (exit $exit_code)"
        log_result "FAIL" "$test_name - exit code: $exit_code"
        ((failed_tests++))
        echo "  Error output:"
        echo "$output" | grep -E "(Error|FAIL|ERROR)" | head -5 | sed 's/^/    /'
    fi

    # Show verbose output if requested
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "  Full output:"
        echo "$output" | sed 's/^/    /'
    fi
}

# Find and run tests in a directory
run_tests_in_dir() {
    local dir="$1"
    local pattern="${2:-test-*.zsh}"

    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}Warning:${NC} Directory not found: $dir"
        return 0
    fi

    local count=$(find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l)
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}Warning:${NC} No tests found in $dir"
        return 0
    fi

    echo -e "${BLUE}Running tests from:${NC} $dir ($count files)"
    echo ""

    while IFS= read -r test_file; do
        run_test "$test_file"

        # Check for fail-fast
        if [[ "${FAIL_FAST:-0}" == "1" && $failed_tests -gt 0 ]]; then
            echo -e "${RED}Fail-fast triggered, stopping test execution${NC}"
            return 1
        fi
    done < <(find "$dir" -name "$pattern" -type f | sort)

    echo ""
}

# Show help
show_help() {
    cat <<EOF
Direct Test Runner for ZSH Configuration

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    --design-only       Run only design tests
    --unit-only         Run only unit tests
    --integration-only  Run only integration tests
    --fail-fast         Stop on first failure

ENVIRONMENT:
    VERBOSE=1           Enable verbose output
    FAIL_FAST=1         Stop on first failure

ADVANTAGES:
    - Bypasses .zshenv loading overhead
    - Uses bash for orchestration
    - Runs tests with zsh -f (no startup files)
    - Much faster than full zsh initialization

EXAMPLES:
    $0                      # Run all tests
    $0 --unit-only          # Run only unit tests
    $0 --fail-fast          # Stop on first failure
    VERBOSE=1 $0            # Run with verbose output

OUTPUT:
    Results are logged to: $RESULTS_FILE

EOF
}

# Parse command line arguments
DESIGN_ONLY=0
UNIT_ONLY=0
INTEGRATION_ONLY=0
VERBOSE="${VERBOSE:-0}"
FAIL_FAST="${FAIL_FAST:-0}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --design-only)
            DESIGN_ONLY=1
            shift
            ;;
        --unit-only)
            UNIT_ONLY=1
            shift
            ;;
        --integration-only)
            INTEGRATION_ONLY=1
            shift
            ;;
        --fail-fast)
            FAIL_FAST=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
echo "🧪 ZSH Configuration Test Suite (Direct Runner)"
echo "=============================================="
echo "ZDOTDIR: $ZDOTDIR"
echo "Results: $RESULTS_FILE"
echo "Mode: Direct execution (bypassing .zshenv)"
echo ""

log_result "INFO" "Starting direct test execution"
log_result "INFO" "ZDOTDIR: $ZDOTDIR"

# Run tests based on options
if [[ $DESIGN_ONLY -eq 1 ]]; then
    run_tests_in_dir "$TEST_BASE_DIR/design"
elif [[ $UNIT_ONLY -eq 1 ]]; then
    run_tests_in_dir "$TEST_BASE_DIR/unit"
    # Also run unit tests in subdirectories
    for subdir in "$TEST_BASE_DIR"/unit/*/; do
        [[ -d "$subdir" ]] && run_tests_in_dir "$subdir"
    done
elif [[ $INTEGRATION_ONLY -eq 1 ]]; then
    run_tests_in_dir "$TEST_BASE_DIR/integration"
else
    # Run all test categories
    run_tests_in_dir "$TEST_BASE_DIR/design"
    run_tests_in_dir "$TEST_BASE_DIR/unit"
    for subdir in "$TEST_BASE_DIR"/unit/*/; do
        [[ -d "$subdir" ]] && run_tests_in_dir "$subdir"
    done
    run_tests_in_dir "$TEST_BASE_DIR/integration"
    run_tests_in_dir "$TEST_BASE_DIR/feature"
    run_tests_in_dir "$TEST_BASE_DIR/security"
    run_tests_in_dir "$TEST_BASE_DIR/performance"
    run_tests_in_dir "$TEST_BASE_DIR/style"
    run_tests_in_dir "$TEST_BASE_DIR/path/phase05"
    run_tests_in_dir "$TEST_BASE_DIR/perf/phase06"
fi

# Generate summary
echo "================================"
echo "📊 Test Results Summary"
echo "================================"
echo "Total tests:  $total_tests"
echo -e "${GREEN}Passed:${NC}       $passed_tests"
echo -e "${RED}Failed:${NC}       $failed_tests"
echo -e "${YELLOW}Skipped:${NC}      $skipped_tests"
echo ""

log_result "SUMMARY" "Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests, Skipped: $skipped_tests"

# Generate JSON summary if needed
if [[ "${JSON_OUTPUT:-0}" == "1" ]]; then
    json_file="${RESULTS_DIR}/test-results-${TIMESTAMP}.json"
    cat > "$json_file" <<EOF
{
    "timestamp": "$TIMESTAMP",
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests,
    "skipped": $skipped_tests,
    "execution_mode": "direct",
    "status": "$([[ $failed_tests -eq 0 ]] && echo "pass" || echo "fail")"
}
EOF
    echo "JSON summary written to: $json_file"
fi

# Exit with appropriate code
if [[ $failed_tests -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $failed_tests test(s) failed${NC}"
    echo "Check the results file for details: $RESULTS_FILE"
    exit 1
fi
