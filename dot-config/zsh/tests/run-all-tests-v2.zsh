#!/usr/bin/env zsh
# Comprehensive Test Runner v2 - Following ZSH Testing Standards
# Compliant with TEST_DESIGN_GUIDE.md principles
# - Tests run with zsh -f for isolation
# - No assumptions about environment
# - Explicit dependency declaration
# - Proper timeout handling

set -uo pipefail

# === Self-Contained Setup (no environment assumptions) ===
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration (explicit paths)
TEST_BASE_DIR="$SCRIPT_DIR"
ZDOTDIR="${ZDOTDIR:-$REPO_ROOT}"
RESULTS_DIR="${TEST_RESULTS_DIR:-/tmp/zsh-test-results}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RESULTS_FILE="${RESULTS_DIR}/test-results-${TIMESTAMP}.log"
JSON_FILE="${RESULTS_DIR}/test-results-${TIMESTAMP}.json"

# Test execution configuration
TIMEOUT_SECONDS="${TEST_TIMEOUT:-60}"
FAIL_FAST="${TEST_FAIL_FAST:-0}"
VERBOSE="${TEST_VERBOSE:-0}"
JSON_OUTPUT="${TEST_JSON_OUTPUT:-1}"
PARALLEL="${TEST_PARALLEL:-0}"
MAX_PARALLEL="${TEST_MAX_PARALLEL:-4}"

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# === Test Counters ===
typeset -i total_tests=0
typeset -i passed_tests=0
typeset -i failed_tests=0
typeset -i skipped_tests=0
typeset -i timeout_tests=0
typeset -A test_times  # Track test execution times
typeset -A test_results  # Track test results by name

# === Color Support (only if terminal) ===
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' NC=''
fi

# === Utility Functions ===

# Logging function with levels
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local color=""

    case "$level" in
        ERROR)   color="$RED" ;;
        WARNING) color="$YELLOW" ;;
        INFO)    color="$BLUE" ;;
        SUCCESS) color="$GREEN" ;;
        DEBUG)   color="$CYAN" ;;
        *)       color="" ;;
    esac

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$RESULTS_FILE"

    # Log to console if verbose or important
    if [[ "$VERBOSE" -eq 1 ]] || [[ "$level" =~ ^(ERROR|WARNING|SUCCESS)$ ]]; then
        echo -e "${color}[$level]${NC} $message"
    fi
}

# Get millisecond timestamp
get_timestamp_ms() {
    if command -v gdate >/dev/null 2>&1; then
        gdate +%s%3N
    elif command -v date >/dev/null 2>&1 && date +%s%N >/dev/null 2>&1; then
        echo $(($(date +%s%N) / 1000000))
    else
        # Fallback to seconds precision
        echo $(($(date +%s) * 1000))
    fi
}

# Portable timeout implementation
run_with_timeout() {
    local timeout="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout" "$@"
    else
        # Fallback: Run in background with sleep guard
        "$@" &
        local pid=$!
        local count=0

        while kill -0 "$pid" 2>/dev/null; do
            if [[ $count -ge $timeout ]]; then
                kill -TERM "$pid" 2>/dev/null
                sleep 0.5
                kill -KILL "$pid" 2>/dev/null
                return 124
            fi
            sleep 1
            ((count++))
        done

        wait "$pid"
    fi
}

# === Test Discovery Functions ===

# Find test files matching pattern
discover_tests() {
    local search_dir="$1"
    local pattern="${2:-test-*.zsh}"
    local -a found_tests=()

    if [[ ! -d "$search_dir" ]]; then
        log_message "WARNING" "Test directory not found: $search_dir"
        return 1
    fi

    # Use find for reliable discovery
    while IFS= read -r test_file; do
        if [[ -f "$test_file" ]]; then
            found_tests+=("$test_file")
        fi
    done < <(find "$search_dir" -name "$pattern" -type f 2>/dev/null | sort)

    if [[ ${#found_tests[@]} -gt 0 ]]; then
        printf '%s\n' "${found_tests[@]}"
    fi
}

# Categorize test by its path
categorize_test() {
    local test_path="$1"
    local category="general"

    case "$test_path" in
        */unit/*)        category="unit" ;;
        */integration/*) category="integration" ;;
        */e2e/*)         category="e2e" ;;
        */perf/*)        category="performance" ;;
        */security/*)    category="security" ;;
        */feature/*)     category="feature" ;;
        */design/*)      category="design" ;;
        */critical/*)    category="critical" ;;
        *)               category="general" ;;
    esac

    echo "$category"
}

# === Test Execution Functions ===

# Run a single test with proper isolation
run_single_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .zsh)"
    local test_category="$(categorize_test "$test_file")"
    local test_output=""
    local exit_code=0
    local start_time=$(get_timestamp_ms)

    ((total_tests++))

    # Check if test is executable
    if [[ ! -x "$test_file" ]]; then
        chmod +x "$test_file" 2>/dev/null || {
            log_message "WARNING" "Test not executable and cannot chmod: $test_name"
            ((skipped_tests++))
            test_results[$test_name]="SKIP:not-executable"
            return 0
        }
    fi

    # Determine execution mode based on test category
    local exec_mode="isolated"  # default
    case "$test_category" in
        unit|integration)
            exec_mode="isolated"
            ;;
        e2e)
            exec_mode="full"
            ;;
        *)
            # Check test header for execution hints
            if head -20 "$test_file" | grep -q "REQUIRES_FULL_ENV"; then
                exec_mode="full"
            fi
            ;;
    esac

    # Execute test with appropriate isolation
    log_message "DEBUG" "Running $test_name ($test_category, $exec_mode mode)..."

    if [[ "$exec_mode" == "isolated" ]]; then
        # Run with zsh -f for isolation
        test_output=$(run_with_timeout "$TIMEOUT_SECONDS" zsh -f "$test_file" 2>&1)
        exit_code=$?
    else
        # Run with current environment for e2e tests
        test_output=$(run_with_timeout "$TIMEOUT_SECONDS" "$test_file" 2>&1)
        exit_code=$?
    fi

    local end_time=$(get_timestamp_ms)
    local duration=$((end_time - start_time))
    test_times[$test_name]=$duration

    # Process results
    if [[ $exit_code -eq 124 ]]; then
        # Timeout
        log_message "ERROR" "$test_name TIMEOUT after ${TIMEOUT_SECONDS}s"
        test_results[$test_name]="TIMEOUT"
        ((timeout_tests++))
        ((failed_tests++))

        if [[ "$FAIL_FAST" -eq 1 ]]; then
            return 1
        fi
    elif [[ $exit_code -eq 0 ]]; then
        # Check for skip markers in output
        if echo "$test_output" | grep -q "^SKIP:"; then
            log_message "INFO" "$test_name SKIPPED (${duration}ms)"
            test_results[$test_name]="SKIP"
            ((skipped_tests++))
        else
            log_message "SUCCESS" "$test_name PASSED (${duration}ms)"
            test_results[$test_name]="PASS"
            ((passed_tests++))
        fi
    else
        # Failure
        log_message "ERROR" "$test_name FAILED with exit code $exit_code (${duration}ms)"
        test_results[$test_name]="FAIL:$exit_code"
        ((failed_tests++))

        # Show failure details if verbose
        if [[ "$VERBOSE" -eq 1 ]]; then
            echo -e "${RED}--- Output from $test_name ---${NC}"
            echo "$test_output" | head -50
            echo -e "${RED}--- End of output ---${NC}"
        fi

        if [[ "$FAIL_FAST" -eq 1 ]]; then
            return 1
        fi
    fi

    return 0
}

# Run tests in a directory
run_directory_tests() {
    local test_dir="$1"
    local pattern="${2:-test-*.zsh}"
    local dir_name="$(basename "$test_dir")"
    local -a test_files=()

    # Discover tests
    while IFS= read -r test_file; do
        test_files+=("$test_file")
    done < <(discover_tests "$test_dir" "$pattern")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_message "INFO" "No tests found in $dir_name"
        return 0
    fi

    log_message "INFO" "Running ${#test_files[@]} tests from $dir_name"

    # Run tests (parallel or sequential)
    if [[ "$PARALLEL" -eq 1 ]] && command -v parallel >/dev/null 2>&1; then
        # Parallel execution using GNU parallel
        printf '%s\n' "${test_files[@]}" | \
            parallel -j "$MAX_PARALLEL" --halt-on-error "$FAIL_FAST" \
            "$(declare -f run_single_test); run_single_test {}"
    else
        # Sequential execution
        for test_file in "${test_files[@]}"; do
            run_single_test "$test_file" || {
                [[ "$FAIL_FAST" -eq 1 ]] && return 1
            }
        done
    fi

    return 0
}

# === Report Generation ===

generate_json_report() {
    local status="success"
    [[ $failed_tests -gt 0 ]] && status="failure"
    [[ $timeout_tests -gt 0 ]] && status="timeout"

    cat > "$JSON_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "summary": {
    "total": $total_tests,
    "passed": $passed_tests,
    "failed": $failed_tests,
    "skipped": $skipped_tests,
    "timeout": $timeout_tests,
    "status": "$status"
  },
  "environment": {
    "zdotdir": "$ZDOTDIR",
    "test_dir": "$TEST_BASE_DIR",
    "timeout_seconds": $TIMEOUT_SECONDS,
    "parallel": $PARALLEL,
    "fail_fast": $FAIL_FAST
  },
  "tests": [
EOF

    local first=1
    for test_name in "${(@k)test_results}"; do
        [[ $first -eq 0 ]] && echo "," >> "$JSON_FILE"
        first=0

        local result="${test_results[$test_name]}"
        local time="${test_times[$test_name]:-0}"

        cat >> "$JSON_FILE" <<EOF
    {
      "name": "$test_name",
      "result": "$result",
      "duration_ms": $time
    }
EOF
    done

    cat >> "$JSON_FILE" <<EOF

  ]
}
EOF

    log_message "INFO" "JSON report saved to: $JSON_FILE"
}

generate_summary() {
    echo
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}          Test Suite Summary${NC}"
    echo -e "${BOLD}========================================${NC}"
    echo

    # Status line with color coding
    local status_color="$GREEN"
    local status_text="SUCCESS"
    if [[ $failed_tests -gt 0 ]]; then
        status_color="$RED"
        status_text="FAILURE"
    elif [[ $timeout_tests -gt 0 ]]; then
        status_color="$YELLOW"
        status_text="TIMEOUT"
    fi

    echo -e "Status: ${status_color}${BOLD}${status_text}${NC}"
    echo

    # Results breakdown
    echo "Results:"
    echo -e "  ${GREEN}Passed:${NC}  $passed_tests"
    echo -e "  ${RED}Failed:${NC}  $failed_tests"
    echo -e "  ${YELLOW}Skipped:${NC} $skipped_tests"
    echo -e "  ${MAGENTA}Timeout:${NC} $timeout_tests"
    echo -e "  ${BOLD}Total:${NC}   $total_tests"
    echo

    # Timing statistics
    if [[ ${#test_times[@]} -gt 0 ]]; then
        local total_time=0
        local min_time=999999
        local max_time=0

        for time in "${test_times[@]}"; do
            ((total_time += time))
            [[ $time -lt $min_time ]] && min_time=$time
            [[ $time -gt $max_time ]] && max_time=$time
        done

        local avg_time=$((total_time / ${#test_times[@]}))

        echo "Performance:"
        echo "  Total time:   ${total_time}ms"
        echo "  Average time: ${avg_time}ms"
        echo "  Min time:     ${min_time}ms"
        echo "  Max time:     ${max_time}ms"
        echo
    fi

    # Failed tests details
    if [[ $failed_tests -gt 0 ]]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test_name in "${(@k)test_results}"; do
            if [[ "${test_results[$test_name]}" =~ ^(FAIL|TIMEOUT) ]]; then
                echo "  - $test_name (${test_results[$test_name]})"
            fi
        done
        echo
    fi

    # Output locations
    echo "Reports:"
    echo "  Log file:  $RESULTS_FILE"
    [[ "$JSON_OUTPUT" -eq 1 ]] && echo "  JSON file: $JSON_FILE"
    echo

    # Exit code
    local exit_code=0
    [[ $failed_tests -gt 0 ]] && exit_code=1
    [[ $timeout_tests -gt 0 ]] && exit_code=2

    return $exit_code
}

# === Main Execution ===

main() {
    log_message "INFO" "Starting ZSH Test Suite v2"
    log_message "INFO" "ZDOTDIR: $ZDOTDIR"
    log_message "INFO" "Test directory: $TEST_BASE_DIR"

    # Test directory structure (in priority order)
    local -a test_dirs=(
        "critical"      # Critical functionality tests (run first)
        "unit"          # Unit tests (isolated components)
        "integration"   # Integration tests (component interaction)
        "feature"       # Feature tests (user-facing functionality)
        "security"      # Security tests
        "performance"   # Performance tests
        "design"        # Design validation tests
        "e2e"           # End-to-end tests (run last)
    )

    # Run tests in priority order
    for dir in "${test_dirs[@]}"; do
        if [[ -d "$TEST_BASE_DIR/$dir" ]]; then
            run_directory_tests "$TEST_BASE_DIR/$dir" || {
                [[ "$FAIL_FAST" -eq 1 ]] && break
            }
        fi
    done

    # Run any additional test directories
    for test_dir in "$TEST_BASE_DIR"/*; do
        if [[ -d "$test_dir" ]]; then
            local dir_name="$(basename "$test_dir")"
            # Skip already processed directories and special directories
            if [[ ! " ${test_dirs[@]} " =~ " ${dir_name} " ]] && \
               [[ ! "$dir_name" =~ ^(lib|fixtures|tools|coverage)$ ]]; then
                run_directory_tests "$test_dir" || {
                    [[ "$FAIL_FAST" -eq 1 ]] && break
                }
            fi
        fi
    done

    # Generate reports
    [[ "$JSON_OUTPUT" -eq 1 ]] && generate_json_report
    generate_summary

    # Return appropriate exit code
    [[ $failed_tests -gt 0 ]] && exit 1
    [[ $timeout_tests -gt 0 ]] && exit 2
    exit 0
}

# === Script Entry Point ===

# Handle command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --fail-fast|-f)
            FAIL_FAST=1
            shift
            ;;
        --parallel|-p)
            PARALLEL=1
            shift
            ;;
        --timeout|-t)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --no-json)
            JSON_OUTPUT=0
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Run the ZSH test suite with proper isolation and reporting.

Options:
  -v, --verbose       Show detailed output
  -f, --fail-fast     Stop on first failure
  -p, --parallel      Run tests in parallel (requires GNU parallel)
  -t, --timeout SEC   Test timeout in seconds (default: 60)
  --no-json          Don't generate JSON report
  -h, --help         Show this help message

Environment variables:
  TEST_RESULTS_DIR   Directory for test results (default: /tmp/zsh-test-results)
  TEST_TIMEOUT       Default timeout in seconds (default: 60)
  TEST_FAIL_FAST     Stop on first failure (0 or 1)
  TEST_VERBOSE       Verbose output (0 or 1)
  TEST_PARALLEL      Run tests in parallel (0 or 1)
  TEST_MAX_PARALLEL  Maximum parallel jobs (default: 4)

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run the test suite
main
