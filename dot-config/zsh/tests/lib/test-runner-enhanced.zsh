#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/tests/lib/test-runner-enhanced.zsh
#
# Enhanced Test Runner for ZSH Configuration Tests
# Provides parallel execution, coverage tracking, structured output,
# and comprehensive test management capabilities.
#
# Features:
# - Parallel test execution with configurable worker count
# - Code coverage integration with kcov
# - Structured JSON and human-readable output
# - Test discovery and filtering
# - Performance timing and metrics
# - Integration with test isolation framework
# - Failure analysis and reporting
#
# Usage:
#   source tests/lib/test-runner-enhanced.zsh
#   runner_execute_tests [options]
#
# Options:
#   --parallel N        Number of parallel workers (default: auto-detect)
#   --coverage          Enable code coverage tracking
#   --format FORMAT     Output format: json, human, both (default: both)
#   --timeout N         Per-test timeout in seconds (default: 60)
#   --filter PATTERN    Run only tests matching pattern
#   --exclude PATTERN   Exclude tests matching pattern
#   --stop-on-fail      Stop execution on first failure
#   --verbose           Enable verbose output
#   --dry-run           Show what would be executed without running
#

set -u

# Enhanced runner global state
typeset -g RUNNER_INITIALIZED=0
typeset -g RUNNER_PARALLEL_WORKERS=0
typeset -g RUNNER_COVERAGE_ENABLED=0
typeset -g RUNNER_OUTPUT_FORMAT="both"
typeset -g RUNNER_TIMEOUT=60
typeset -g RUNNER_STOP_ON_FAIL=0
typeset -g RUNNER_VERBOSE=0
typeset -g RUNNER_DRY_RUN=0
typeset -g RUNNER_FILTER_PATTERN=""
typeset -g RUNNER_EXCLUDE_PATTERN=""

# Test execution state
typeset -g RUNNER_TESTS_DISCOVERED=()
typeset -g RUNNER_TESTS_FILTERED=()
typeset -g RUNNER_TESTS_RESULTS=()
typeset -g RUNNER_WORKER_PIDS=()
typeset -g RUNNER_START_TIME=0
typeset -g RUNNER_END_TIME=0

# Directories and files
typeset -g RUNNER_RESULTS_DIR="${ZSH_LOG_DIR:-${ZDOTDIR}/logs}/test-results"
typeset -g RUNNER_COVERAGE_DIR="${RUNNER_RESULTS_DIR}/coverage"
typeset -g RUNNER_WORK_DIR="${RUNNER_RESULTS_DIR}/work"
typeset -g RUNNER_TIMESTAMP=""

# Debug and logging
_runner_debug() {
    if (( RUNNER_VERBOSE )); then
        printf "[RUNNER] %s\n" "$*" >&2
    fi
}

_runner_error() {
    printf "[RUNNER ERROR] %s\n" "$*" >&2
}

_runner_info() {
    printf "[RUNNER] %s\n" "$*"
}

# Initialize enhanced test runner
runner_init() {
    if (( RUNNER_INITIALIZED )); then
        return 0
    fi

    _runner_debug "Initializing enhanced test runner"

    # Set timestamp
    RUNNER_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

    # Create required directories
    mkdir -p "$RUNNER_RESULTS_DIR" "$RUNNER_COVERAGE_DIR" "$RUNNER_WORK_DIR" || {
        _runner_error "Failed to create runner directories"
        return 1
    }

    # Auto-detect parallel workers if not set
    if (( RUNNER_PARALLEL_WORKERS == 0 )); then
        if command -v nproc >/dev/null 2>&1; then
            RUNNER_PARALLEL_WORKERS=$(nproc)
        elif command -v sysctl >/dev/null 2>&1; then
            RUNNER_PARALLEL_WORKERS=$(sysctl -n hw.ncpu 2>/dev/null || echo 2)
        else
            RUNNER_PARALLEL_WORKERS=2
        fi

        # Cap at reasonable maximum for test stability
        if (( RUNNER_PARALLEL_WORKERS > 8 )); then
            RUNNER_PARALLEL_WORKERS=8
        fi
    fi

    # Check coverage tool availability
    if (( RUNNER_COVERAGE_ENABLED )); then
        if ! command -v kcov >/dev/null 2>&1; then
            _runner_error "Coverage enabled but kcov not found"
            return 1
        fi
    fi

    # Load test isolation framework
    local isolation_lib="${ZDOTDIR}/tests/lib/test-isolation.zsh"
    if [[ -f "$isolation_lib" ]]; then
        source "$isolation_lib" || {
            _runner_error "Failed to load test isolation framework"
            return 1
        }
    fi

    # Setup signal handling
    trap 'runner_cleanup_on_exit' EXIT INT TERM

    RUNNER_INITIALIZED=1
    _runner_debug "Enhanced test runner initialized (workers: $RUNNER_PARALLEL_WORKERS)"
    return 0
}

# Parse command line arguments
runner_parse_args() {
    while (( $# > 0 )); do
        case "$1" in
            --parallel)
                shift
                RUNNER_PARALLEL_WORKERS="$1"
                ;;
            --coverage)
                RUNNER_COVERAGE_ENABLED=1
                ;;
            --format)
                shift
                RUNNER_OUTPUT_FORMAT="$1"
                ;;
            --timeout)
                shift
                RUNNER_TIMEOUT="$1"
                ;;
            --filter)
                shift
                RUNNER_FILTER_PATTERN="$1"
                ;;
            --exclude)
                shift
                RUNNER_EXCLUDE_PATTERN="$1"
                ;;
            --stop-on-fail)
                RUNNER_STOP_ON_FAIL=1
                ;;
            --verbose)
                RUNNER_VERBOSE=1
                ;;
            --dry-run)
                RUNNER_DRY_RUN=1
                ;;
            --help)
                runner_show_help
                return 2
                ;;
            *)
                _runner_error "Unknown option: $1"
                return 1
                ;;
        esac
        shift
    done
}

# Show help information
runner_show_help() {
    cat <<EOF
Enhanced ZSH Test Runner

Usage: runner_execute_tests [options]

Options:
  --parallel N        Number of parallel workers (default: auto-detect)
  --coverage          Enable code coverage tracking
  --format FORMAT     Output format: json, human, both (default: both)
  --timeout N         Per-test timeout in seconds (default: 60)
  --filter PATTERN    Run only tests matching pattern
  --exclude PATTERN   Exclude tests matching pattern
  --stop-on-fail      Stop execution on first failure
  --verbose           Enable verbose output
  --dry-run           Show what would be executed without running
  --help              Show this help

Examples:
  runner_execute_tests --parallel 4 --coverage
  runner_execute_tests --filter "integration*" --verbose
  runner_execute_tests --exclude "perf*" --stop-on-fail
EOF
}

# Discover all test files
runner_discover_tests() {
    local test_base_dir="${ZDOTDIR}/tests"
    RUNNER_TESTS_DISCOVERED=()

    _runner_debug "Discovering tests in: $test_base_dir"

    # Find all test files
    while IFS= read -r -d '' test_file; do
        RUNNER_TESTS_DISCOVERED+=("$test_file")
    done < <(find "$test_base_dir" -name "test-*.zsh" -type f -print0 2>/dev/null)

    _runner_debug "Discovered ${#RUNNER_TESTS_DISCOVERED} test files"
    return 0
}

# Filter tests based on patterns
runner_filter_tests() {
    RUNNER_TESTS_FILTERED=()

    local test_file
    for test_file in "${RUNNER_TESTS_DISCOVERED[@]}"; do
        local test_name="${test_file##*/}"
        local include=1

        # Apply include filter
        if [[ -n "$RUNNER_FILTER_PATTERN" ]]; then
            if [[ ! "$test_name" == *"$RUNNER_FILTER_PATTERN"* ]]; then
                include=0
            fi
        fi

        # Apply exclude filter
        if (( include )) && [[ -n "$RUNNER_EXCLUDE_PATTERN" ]]; then
            if [[ "$test_name" == *"$RUNNER_EXCLUDE_PATTERN"* ]]; then
                include=0
            fi
        fi

        if (( include )); then
            RUNNER_TESTS_FILTERED+=("$test_file")
        fi
    done

    _runner_debug "Filtered to ${#RUNNER_TESTS_FILTERED} test files"
    return 0
}

# Execute a single test with isolation
runner_execute_single_test() {
    local test_file="$1"
    local worker_id="$2"
    local test_name="${test_file##*/}"
    local result_file="$RUNNER_WORK_DIR/result-${worker_id}-$$-$(date +%s).json"

    local start_time end_time duration exit_code
    local output_file="$RUNNER_WORK_DIR/output-${worker_id}-$$-$(date +%s).log"
    local coverage_file=""

    _runner_debug "[Worker $worker_id] Starting test: $test_name"

    start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Setup coverage if enabled
    if (( RUNNER_COVERAGE_ENABLED )); then
        coverage_file="$RUNNER_COVERAGE_DIR/${test_name%.zsh}"
        mkdir -p "$coverage_file"
    fi

    # Execute test with isolation
    {
        if command -v isolation_start_test >/dev/null 2>&1; then
            isolation_start_test "$test_name"
        fi

        if (( RUNNER_COVERAGE_ENABLED )) && [[ -n "$coverage_file" ]]; then
            # Run with coverage
            timeout "${RUNNER_TIMEOUT}s" kcov \
                --exclude-pattern=/usr,/opt,/nix \
                --include-pattern="$ZDOTDIR" \
                "$coverage_file" \
                zsh "$test_file"
        else
            # Run without coverage
            timeout "${RUNNER_TIMEOUT}s" zsh "$test_file"
        fi

        exit_code=$?

        if command -v isolation_end_test >/dev/null 2>&1; then
            isolation_end_test
        fi

        return $exit_code

    } >"$output_file" 2>&1
    exit_code=$?

    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")

    # Generate result JSON
    {
        printf '{\n'
        printf '  "test_name": "%s",\n' "$test_name"
        printf '  "test_file": "%s",\n' "$test_file"
        printf '  "worker_id": "%s",\n' "$worker_id"
        printf '  "start_time": "%s",\n' "$start_time"
        printf '  "end_time": "%s",\n' "$end_time"
        printf '  "duration": "%s",\n' "$duration"
        printf '  "exit_code": %d,\n' "$exit_code"
        printf '  "status": "%s",\n' "$(( exit_code == 0 )) && echo "PASS" || echo "FAIL""
        printf '  "output_file": "%s"' "$output_file"
        if [[ -n "$coverage_file" ]]; then
            printf ',\n  "coverage_file": "%s"' "$coverage_file"
        fi
        printf '\n}\n'
    } > "$result_file"

    _runner_debug "[Worker $worker_id] Completed test: $test_name (exit: $exit_code, duration: ${duration}s)"
    return $exit_code
}

# Worker process for parallel execution
runner_worker_process() {
    local worker_id="$1"
    local work_queue="$2"

    _runner_debug "[Worker $worker_id] Started"

    while IFS= read -r test_file <&3; do
        if [[ -z "$test_file" ]]; then
            break
        fi

        runner_execute_single_test "$test_file" "$worker_id"
        local test_exit=$?

        # Signal main process if stop-on-fail is enabled
        if (( RUNNER_STOP_ON_FAIL && test_exit != 0 )); then
            touch "$RUNNER_WORK_DIR/stop-on-fail-signal"
            break
        fi
    done 3< "$work_queue"

    _runner_debug "[Worker $worker_id] Finished"
}

# Execute tests in parallel
runner_execute_parallel() {
    local test_count=${#RUNNER_TESTS_FILTERED}

    if (( test_count == 0 )); then
        _runner_info "No tests to execute"
        return 0
    fi

    _runner_info "Executing $test_count tests with $RUNNER_PARALLEL_WORKERS workers"

    # Create work queue
    local work_queue="$RUNNER_WORK_DIR/work-queue"
    printf "%s\n" "${RUNNER_TESTS_FILTERED[@]}" > "$work_queue"

    # Start worker processes
    RUNNER_WORKER_PIDS=()
    local worker_id
    for worker_id in $(seq 1 $RUNNER_PARALLEL_WORKERS); do
        runner_worker_process "$worker_id" "$work_queue" &
        RUNNER_WORKER_PIDS+=($!)
    done

    # Monitor workers
    local worker_pid
    for worker_pid in "${RUNNER_WORKER_PIDS[@]}"; do
        wait "$worker_pid"
    done

    _runner_debug "All workers completed"
}

# Collect and aggregate results
runner_collect_results() {
    RUNNER_TESTS_RESULTS=()

    _runner_debug "Collecting test results"

    # Collect all result files
    local result_file
    while IFS= read -r -d '' result_file; do
        if [[ -s "$result_file" ]]; then
            RUNNER_TESTS_RESULTS+=("$result_file")
        fi
    done < <(find "$RUNNER_WORK_DIR" -name "result-*.json" -type f -print0 2>/dev/null)

    _runner_debug "Collected ${#RUNNER_TESTS_RESULTS} test results"
}

# Generate final reports
runner_generate_reports() {
    local total_tests=0 passed_tests=0 failed_tests=0
    local total_duration=0
    local failures=()

    # Aggregate statistics
    local result_file
    for result_file in "${RUNNER_TESTS_RESULTS[@]}"; do
        if [[ -f "$result_file" ]]; then
            local exit_code duration test_name
            exit_code=$(jq -r '.exit_code // 1' "$result_file" 2>/dev/null || echo 1)
            duration=$(jq -r '.duration // "0"' "$result_file" 2>/dev/null || echo 0)
            test_name=$(jq -r '.test_name // "unknown"' "$result_file" 2>/dev/null || echo unknown)

            (( total_tests++ ))
            if (( exit_code == 0 )); then
                (( passed_tests++ ))
            else
                (( failed_tests++ ))
                failures+=("$test_name")
            fi

            total_duration=$(echo "$total_duration + $duration" | bc -l 2>/dev/null || echo "$total_duration")
        fi
    done

    # Generate JSON report
    if [[ "$RUNNER_OUTPUT_FORMAT" == "json" || "$RUNNER_OUTPUT_FORMAT" == "both" ]]; then
        local json_report="$RUNNER_RESULTS_DIR/test-report-${RUNNER_TIMESTAMP}.json"
        {
            printf '{\n'
            printf '  "timestamp": "%s",\n' "$RUNNER_TIMESTAMP"
            printf '  "start_time": "%s",\n' "$RUNNER_START_TIME"
            printf '  "end_time": "%s",\n' "$RUNNER_END_TIME"
            printf '  "total_duration": "%s",\n' "$total_duration"
            printf '  "parallel_workers": %d,\n' "$RUNNER_PARALLEL_WORKERS"
            printf '  "coverage_enabled": %s,\n' "$(( RUNNER_COVERAGE_ENABLED )) && echo true || echo false"
            printf '  "statistics": {\n'
            printf '    "total": %d,\n' "$total_tests"
            printf '    "passed": %d,\n' "$passed_tests"
            printf '    "failed": %d\n' "$failed_tests"
            printf '  },\n'
            printf '  "failures": ['
            local first=1
            for failure in "${failures[@]}"; do
                if (( first )); then
                    printf '"%s"' "$failure"
                    first=0
                else
                    printf ', "%s"' "$failure"
                fi
            done
            printf '],\n'
            printf '  "results": ['
            local first=1
            for result_file in "${RUNNER_TESTS_RESULTS[@]}"; do
                if (( first )); then
                    first=0
                else
                    printf ','
                fi
                printf '\n'
                cat "$result_file" | sed 's/^/    /'
            done
            printf '\n  ]\n'
            printf '}\n'
        } > "$json_report"
        _runner_info "JSON report: $json_report"
    fi

    # Generate human-readable report
    if [[ "$RUNNER_OUTPUT_FORMAT" == "human" || "$RUNNER_OUTPUT_FORMAT" == "both" ]]; then
        _runner_info "===== TEST EXECUTION SUMMARY ====="
        _runner_info "Timestamp: $RUNNER_TIMESTAMP"
        _runner_info "Workers: $RUNNER_PARALLEL_WORKERS"
        _runner_info "Duration: ${total_duration}s"
        _runner_info "Tests: $total_tests, Passed: $passed_tests, Failed: $failed_tests"

        if (( failed_tests > 0 )); then
            _runner_info ""
            _runner_info "FAILURES:"
            for failure in "${failures[@]}"; do
                _runner_info "  - $failure"
            done
        fi

        if (( RUNNER_COVERAGE_ENABLED )); then
            _runner_info ""
            _runner_info "Coverage reports available in: $RUNNER_COVERAGE_DIR"
        fi

        _runner_info "================================="
    fi

    return $(( failed_tests > 0 ? 1 : 0 ))
}

# Cleanup on exit
runner_cleanup_on_exit() {
    _runner_debug "Cleaning up test runner"

    # Kill any remaining worker processes
    local worker_pid
    for worker_pid in "${RUNNER_WORKER_PIDS[@]}"; do
        if kill -0 "$worker_pid" 2>/dev/null; then
            kill -TERM "$worker_pid" 2>/dev/null || kill -KILL "$worker_pid" 2>/dev/null || true
        fi
    done

    # Clean up work files older than 1 hour
    if [[ -d "$RUNNER_WORK_DIR" ]]; then
        find "$RUNNER_WORK_DIR" -name "*.json" -o -name "*.log" -mtime +1h -delete 2>/dev/null || true
    fi
}

# Main execution function
runner_execute_tests() {
    # Parse arguments
    runner_parse_args "$@" || return $?

    # Initialize runner
    runner_init || return 1

    # Record start time
    RUNNER_START_TIME=$(date +%s.%N 2>/dev/null || date +%s)

    if (( RUNNER_DRY_RUN )); then
        _runner_info "DRY RUN MODE - showing what would be executed"
    fi

    # Discover and filter tests
    runner_discover_tests || return 1
    runner_filter_tests || return 1

    if (( RUNNER_DRY_RUN )); then
        _runner_info "Would execute ${#RUNNER_TESTS_FILTERED} tests:"
        printf "  %s\n" "${RUNNER_TESTS_FILTERED[@]}"
        return 0
    fi

    # Execute tests
    runner_execute_parallel

    # Record end time
    RUNNER_END_TIME=$(date +%s.%N 2>/dev/null || date +%s)

    # Collect results and generate reports
    runner_collect_results
    runner_generate_reports

    return $?
}

# Export main functions
if typeset -f >/dev/null 2>&1; then
    export -f runner_execute_tests runner_init runner_parse_args >/dev/null 2>&1 || true
fi
