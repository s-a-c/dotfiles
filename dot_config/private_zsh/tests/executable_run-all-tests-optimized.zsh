#!/usr/bin/env zsh
# ==============================================================================
# run-all-tests-optimized.zsh
#
# Optimized test runner that loads .zshenv once and runs tests in-process
# to avoid the overhead of spawning 137+ separate zsh processes.
#
# Key improvements:
# - Single .zshenv load for entire test suite
# - Tests are sourced in subshells rather than executed as separate processes
# - Maintains test isolation through subshell environments
# - Dramatic performance improvement for test suite execution
# ==============================================================================

set -uo pipefail

# Save original working directory
ORIGINAL_CWD="$PWD"

# Source .zshenv ONCE to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Change to ZDOTDIR for all test execution
cd "$ZDOTDIR" || {
    echo "ERROR: Failed to cd to ZDOTDIR ($ZDOTDIR)"
    exit 2
}



zf::debug "# [run-all-tests-optimized] Starting optimized test suite"
zf::debug "# [run-all-tests-optimized] Single .zshenv load complete"

# Test configuration
TEST_BASE_DIR="${ZDOTDIR}/tests"
RESULTS_DIR="${ZSH_LOG_DIR:-${ZDOTDIR}/logs}/test-results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S 2>/dev/null || echo "$(date +%Y%m%d_%H%M%S)")"
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
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date)")"

    echo "[$timestamp] [$level] $message" | tee -a "$RESULTS_FILE"
}

# Run a single test in a subshell to maintain isolation
run_test_in_subshell() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .zsh)"

    # Increment counter
    ((total_tests++))
    local test_index=$total_tests

    # Capture start time
    local start_time=$(date +%s 2>/dev/null || echo 0)

    echo -n "${BLUE}Running${NC} (${test_index}) $test_name... "

    if [[ ! -f "$test_file" ]]; then
        echo "${YELLOW}SKIP${NC} (not found)"
        log_result "SKIP" "$test_name - not found (index=${test_index})"
        ((skipped_tests++))
        return 0
    fi

    if [[ ! -r "$test_file" ]]; then
        echo "${YELLOW}SKIP${NC} (not readable)"
        log_result "SKIP" "$test_name - not readable (index=${test_index})"
        ((skipped_tests++))
        return 0
    fi

    # Run test in subshell with timeout protection
    local output
    local exit_code

    # Use a subshell to isolate test execution
    output=$(
        (
            # Set a timeout using TMOUT (zsh built-in)
            TMOUT=60

            # Source the test file instead of executing it
            # This avoids spawning a new zsh process and reloading .zshenv
            source "$test_file" 2>&1

            # Return the exit code
            return $?
        ) 2>&1
    )
    exit_code=$?

    # Calculate duration
    local end_time=$(date +%s 2>/dev/null || echo 0)
    local duration=$((end_time - start_time))

    # Process results
    if [[ $exit_code -eq 0 ]]; then
        echo "${GREEN}PASS${NC} (${duration}s)"
        log_result "PASS" "$test_name (${duration}s, index=${test_index})"
        ((passed_tests++))

        # Show output if verbose
        if [[ "${verbose:-0}" -eq 1 ]]; then
            echo "$output" | sed 's/^/    /'
        fi
    else
        echo "${RED}FAIL${NC} (exit: $exit_code, ${duration}s)"
        log_result "FAIL" "$test_name - exit code: $exit_code (${duration}s, index=${test_index})"
        ((failed_tests++))

        # Always show failure output
        echo "  ${RED}Error details:${NC}"
        echo "$output" | sed 's/^/    /'

        if [[ "${fail_fast:-0}" -eq 1 ]]; then
            return 1
        fi
    fi
}

# Find and run all tests
find_and_run_tests() {
    local search_dir="$1"
    local pattern="${2:-test-*.zsh}"

    if [[ ! -d "$search_dir" ]]; then
        echo "${YELLOW}Warning:${NC} Test directory not found: $search_dir"
        return 0
    fi

    local -a test_files
    test_files=("${(@f)$(find "$search_dir" -name "$pattern" -type f | LC_ALL=C sort)}")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "${YELLOW}Warning:${NC} No test files found in $search_dir"
        return 0
    fi

    echo "${BLUE}Running tests from:${NC} $search_dir (${#test_files[@]} files)"
    echo ""

    for test_file in "${test_files[@]}"; do
        run_test_in_subshell "$test_file"

        # Check for fail-fast
        if [[ "${fail_fast:-0}" -eq 1 && $failed_tests -gt 0 ]]; then
            echo "${RED}Fail-fast triggered, stopping test execution${NC}"
            return 1
        fi
    done

    echo ""
}

# Main execution
main() {
    echo "🧪 ZSH Configuration Test Suite (Optimized)"
    echo "==========================================="
    echo "ZDOTDIR: $ZDOTDIR"
    echo "Results: $RESULTS_FILE"
    echo "Mode: In-process execution (single .zshenv load)"
    echo ""

    log_result "INFO" "Starting optimized test suite execution"
    log_result "INFO" "ZDOTDIR: $ZDOTDIR"
    log_result "INFO" "Execution mode: In-process (single .zshenv load)"

    # Count total test files for progress indication
    local total_test_files=$(find "$TEST_BASE_DIR" -name "test-*.zsh" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "Found $total_test_files test files to execute"
    echo ""

    # Run tests by category
    if [[ "${design_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/design"
    elif [[ "${unit_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/unit"
    elif [[ "${integration_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/integration"
    elif [[ "${path_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/path/phase05"
    elif [[ "${perf_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/perf/phase06"
        find_and_run_tests "$TEST_BASE_DIR/performance"
    elif [[ "${security_only:-0}" -eq 1 ]]; then
        find_and_run_tests "$TEST_BASE_DIR/security"
    else
        # Run all test categories
        find_and_run_tests "$TEST_BASE_DIR/path/phase05"
        find_and_run_tests "$TEST_BASE_DIR/perf/phase06"
        find_and_run_tests "$TEST_BASE_DIR/design"
        find_and_run_tests "$TEST_BASE_DIR/unit"
        find_and_run_tests "$TEST_BASE_DIR/integration"
        find_and_run_tests "$TEST_BASE_DIR/feature"
        find_and_run_tests "$TEST_BASE_DIR/security"
        find_and_run_tests "$TEST_BASE_DIR/performance"
        find_and_run_tests "$TEST_BASE_DIR/style"

        # Run any TDD tests
        if [[ -d "$TEST_BASE_DIR" ]]; then
            while IFS= read -r extra_test; do
                [[ -z $extra_test ]] && continue
                test_base="$(basename "$extra_test")"
                test_name="${test_base%.zsh}"
                # Check if not already run
                if ! grep -q " $test_name " "$RESULTS_FILE" 2>/dev/null; then
                    run_test_in_subshell "$extra_test"
                fi
            done < <(find "$TEST_BASE_DIR" -type f -path "*/tdd/test-*.zsh" 2>/dev/null | sort)
        fi
    fi

    # Generate JSON summary if requested
    if [[ "${json_output:-0}" -eq 1 ]]; then
        local json_file="${RESULTS_DIR}/test-results-${TIMESTAMP}.json"
        {
            printf '{\n'
            printf '  "timestamp": "%s",\n' "$TIMESTAMP"
            printf '  "total": %d,\n' "$total_tests"
            printf '  "passed": %d,\n' "$passed_tests"
            printf '  "failed": %d,\n' "$failed_tests"
            printf '  "skipped": %d,\n' "$skipped_tests"
            printf '  "execution_mode": "optimized",\n'
            printf '  "status": "%s"\n' "$([[ $failed_tests -eq 0 ]] && echo "pass" || echo "fail")"
            printf '}\n'
        } >"$json_file"
        echo "# [run-all-tests-optimized] JSON summary written: $json_file"
    fi

    # Summary
    echo "================================"
    echo "📊 Test Results Summary"
    echo "================================"
    echo "Total tests:  $total_tests"
    echo "${GREEN}Passed:${NC}       $passed_tests"
    echo "${RED}Failed:${NC}       $failed_tests"
    echo "${YELLOW}Skipped:${NC}      $skipped_tests"
    echo ""

    log_result "SUMMARY" "Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests, Skipped: $skipped_tests"

    if [[ $failed_tests -eq 0 ]]; then
        echo "${GREEN}✅ All tests passed!${NC}"
        log_result "SUCCESS" "All tests passed"

        # Restore original working directory before exit
        cd "$ORIGINAL_CWD" || true
        return 0
    else
        echo "${RED}❌ $failed_tests test(s) failed${NC}"
        echo "Check the results file for details: $RESULTS_FILE"
        log_result "FAILURE" "$failed_tests test(s) failed"

        # Restore original working directory before exit
        cd "$ORIGINAL_CWD" || true
        return 1
    fi
}

# Parse command line arguments
show_help() {
    cat <<EOF
ZSH Configuration Test Suite (Optimized)

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quiet         Quiet mode (minimal output)
    --path-only         Run only PATH-related tests
    --perf-only         Run only performance tests
    --design-only       Run only design and structure tests
    --security-only     Run only security and async tests
    --unit-only         Run only unit tests
    --integration-only  Run only integration tests
    --fail-fast         Exit immediately on first test failure
    --json              Output JSON summary

OPTIMIZATION:
    This optimized version loads .zshenv once and sources tests in subshells,
    dramatically reducing overhead compared to spawning separate processes.

EXAMPLES:
    $0                  # Run all tests
    $0 --unit-only      # Run only unit tests
    $0 --fail-fast      # Stop on first failure
    $0 -v --json        # Verbose output with JSON summary

OUTPUT:
    Results are logged to: ${RESULTS_DIR}/test-results-*.log

EOF
}

# Parse arguments
verbose=0
quiet=0
path_only=0
perf_only=0
design_only=0
security_only=0
unit_only=0
integration_only=0
json_output=0
fail_fast=0

while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        show_help
        exit 0
        ;;
    -v | --verbose)
        verbose=1
        shift
        ;;
    -q | --quiet)
        quiet=1
        shift
        ;;
    --path-only)
        path_only=1
        shift
        ;;
    --perf-only)
        perf_only=1
        shift
        ;;
    --design-only)
        design_only=1
        shift
        ;;
    --security-only)
        security_only=1
        shift
        ;;
    --unit-only)
        unit_only=1
        shift
        ;;
    --integration-only)
        integration_only=1
        shift
        ;;
    --fail-fast)
        fail_fast=1
        shift
        ;;
    --json)
        json_output=1
        shift
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use -h or --help for usage information"
        exit 1
        ;;
    esac
done

# Execute main function only when not sourced
if ! (return 0 2>/dev/null); then
    main "$@"
fi
