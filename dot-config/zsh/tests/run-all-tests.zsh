#!/usr/bin/env zsh
# NOTE: JSON summary timing fix applied – JSON now emitted AFTER recursive fallback
# test execution and BEFORE human-readable summary print so counts include TDD nested tests.
# Comprehensive Test Runner
# UPDATED: Consistent with .zshenv configuration
set -uo pipefail

# Save original working directory
ORIGINAL_CWD="$PWD"

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Change to ZDOTDIR for all test execution
cd "$ZDOTDIR" || {
    echo "ERROR: Failed to cd to ZDOTDIR ($ZDOTDIR)"
    exit 2
}

# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [run-all-tests] Starting comprehensive test suite"
fi

# Test configuration
TEST_BASE_DIR="${ZDOTDIR}/tests"
RESULTS_DIR="${ZSH_LOG_DIR:-${ZDOTDIR}/logs}/test-results"
TIMESTAMP="$(date +%Y%m%d_%H%M%S 2>/dev/null || zsh_debug_echo "$(date +%Y%m%d_%H%M%S)")"
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
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || zsh_debug_echo "$(date)")"

    zsh_debug_echo "[$timestamp] [$level] $message" | tee -a "$RESULTS_FILE"
}

# Portable timeout runner (prefers GNU timeout; falls back to gtimeout, perl, python3, or a naive zsh loop)
run_with_timeout() {
    emulate -L zsh
    set -o nounset
    local seconds="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
        return $?
    fi
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
        return $?
    fi
    if command -v perl >/dev/null 2>&1; then
        perl -e 'alarm shift @ARGV; exec @ARGV' "$seconds" "$@"
        return $?
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$seconds" "$@" <<'PY'
import os, signal, subprocess, sys, time
t = int(sys.argv[1]); cmd = sys.argv[2:]
p = subprocess.Popen(cmd)
try:
    p.wait(timeout=t)
    sys.exit(p.returncode)
except subprocess.TimeoutExpired:
    try:
        p.terminate(); time.sleep(0.5)
    except Exception:
        pass
    try:
        p.kill()
    except Exception:
        pass
    sys.exit(124)
PY
        return $?
    fi
    # Naive fallback using zsh loop
    "$@" & local pid=$!
    local waited=0
    while kill -0 $pid 2>/dev/null; do
        sleep 1
        waited=$(( waited + 1 ))
        if (( waited >= seconds )); then
            kill $pid 2>/dev/null || true
            sleep 0.2
            kill -9 $pid 2>/dev/null || true
            return 124
        fi
    done
    wait $pid
    return $?
}

# Run a single test
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .zsh)"

    # Increment counter first to derive 1-based index
    ((total_tests++))
    local test_index=$total_tests

    # Capture start time (ms)
    zmodload zsh/datetime 2>/dev/null || true
    local start_rt=$EPOCHREALTIME
    local start_ms=$(printf '%s' "$start_rt" | awk -F. '{ms=$1*1000; if(NF>1){ ms+=substr($2"000",1,3)+0 } printf "%d", ms}')

    zsh_debug_echo "${BLUE}Running${NC} (${test_index}) $test_name..."

    if [[ ! -x "$test_file" ]]; then
        zsh_debug_echo "${YELLOW}SKIP${NC} (not executable)"
        log_result "SKIP" "$test_name - not executable (index=${test_index})"
        ((skipped_tests++))
        return 0
    fi

    # Run test with timeout
    local output
    local exit_code

    if output=$(run_with_timeout 60 "$test_file" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    # Capture end time & compute duration
    local end_rt=$EPOCHREALTIME
    local end_ms=$(printf '%s' "$end_rt" | awk -F. '{ms=$1*1000; if(NF>1){ ms+=substr($2"000",1,3)+0 } printf "%d", ms}')
    local duration_ms=0
    if [[ -n ${start_ms:-} && -n ${end_ms:-} ]]; then
        ((duration_ms = end_ms - start_ms))
    fi

    if [[ $exit_code -eq 0 ]]; then
        if [[ "$output" == *"SKIP"* ]]; then
            zsh_debug_echo "${YELLOW}SKIP${NC} (${duration_ms}ms)"
            log_result "SKIP" "$test_name - $output (index=${test_index} duration=${duration_ms}ms)"
            ((skipped_tests++))
        else
            zsh_debug_echo "${GREEN}PASS${NC} (${duration_ms}ms)"
            log_result "PASS" "$test_name - $output (index=${test_index} duration=${duration_ms}ms)"
            ((passed_tests++))
        fi
    else
        if [[ "$output" == *"SKIP:"* ]]; then
            zsh_debug_echo "${YELLOW}SKIP${NC} (${duration_ms}ms)"
            log_result "SKIP" "$test_name - $output (index=${test_index} duration=${duration_ms}ms)"
            ((skipped_tests++))
        else
            zsh_debug_echo "${RED}FAIL${NC} (${duration_ms}ms)"
            log_result "FAIL" "$test_name - Exit code: $exit_code (index=${test_index} duration=${duration_ms}ms)"
            log_result "FAIL" "$test_name - Output: $output"
            ((failed_tests++))

            # Show failure details immediately
            zsh_debug_echo "  ${RED}Error details:${NC}"
            zsh_debug_echo "$output" | sed 's/^/    /'
            if [[ $fail_fast -eq 1 ]]; then
                return 1
            fi
        fi
    fi
}

# Find and run all tests
find_and_run_tests() {
    local search_dir="$1"
    local pattern="$2"

    if [[ ! -d "$search_dir" ]]; then
        zsh_debug_echo "${YELLOW}Warning:${NC} Test directory not found: $search_dir"
        return 0
    fi

    local -a test_files
    test_files=("${(@f)$(find "$search_dir" -name "$pattern" -type f | LC_ALL=C sort)}")

    if [[ ${#test_files[@]} -eq 0 ]]; then
        zsh_debug_echo "${YELLOW}Warning:${NC} No test files found in $search_dir"
        return 0
    fi

    zsh_debug_echo "${BLUE}Running tests from:${NC} $search_dir"
    zsh_debug_echo ""
    if [[ "${verbose:-0}" -eq 1 || "${ZSH_DEBUG:-0}" -eq 1 ]]; then
        zsh_debug_echo "Discovered ${#test_files[@]} test file(s) in $search_dir:"
        for tf in "${test_files[@]}"; do
            zsh_debug_echo "  - $tf"
        done
        zsh_debug_echo ""
    fi

    for test_file in "${test_files[@]}"; do
        run_test "$test_file"
    done

    zsh_debug_echo ""
}

# Main execution
main() {
    zsh_debug_echo "🧪 ZSH Configuration Test Suite"
    zsh_debug_echo "================================"
    zsh_debug_echo "ZDOTDIR: $ZDOTDIR"
    zsh_debug_echo "Results: $RESULTS_FILE"
    zsh_debug_echo ""

    log_result "INFO" "Starting test suite execution"
    log_result "INFO" "ZDOTDIR: $ZDOTDIR"
    log_result "INFO" "ZSH_COMPDUMP: ${ZSH_COMPDUMP:-<not set>}"
    log_result "INFO" "ZSH_CACHE_DIR: ${ZSH_CACHE_DIR:-<not set>}"

    # Make test files executable
    zsh_debug_echo "Setting test file permissions..."
    find "$TEST_BASE_DIR" -name "test-*.zsh" -type f -exec chmod +x {} \; 2>/dev/null || true

    # Run Phase 05 tests (PATH and environment)
    find_and_run_tests "$TEST_BASE_DIR/path/phase05" "test-*.zsh"

    # Run Phase 06 tests (Performance and completion)
    find_and_run_tests "$TEST_BASE_DIR/perf/phase06" "test-*.zsh"

    # Run Design tests (structure and sentinel validation)
    find_and_run_tests "$TEST_BASE_DIR/design" "test-*.zsh"

    # Run Unit tests (individual component testing)
    find_and_run_tests "$TEST_BASE_DIR/unit" "test-*.zsh"

    # Run Integration tests (component interaction testing)
    find_and_run_tests "$TEST_BASE_DIR/integration" "test-*.zsh"

    # Run Feature tests (functional testing)
    find_and_run_tests "$TEST_BASE_DIR/feature" "test-*.zsh"

    # Run Security tests (async state and integrity)
    find_and_run_tests "$TEST_BASE_DIR/security" "test-*.zsh"

    # Run Performance tests (regression and segment analysis)
    find_and_run_tests "$TEST_BASE_DIR/performance" "test-*.zsh"

    # Run Style tests (code quality and formatting)
    find_and_run_tests "$TEST_BASE_DIR/style" "test-*.zsh"

    # Run any other test directories not explicitly covered
    for test_dir in "$TEST_BASE_DIR"/*; do
        if [[ -d "$test_dir" ]]; then
            local dir_name="$(basename "$test_dir")"
            case "$dir_name" in
            path | perf | design | unit | integration | feature | security | performance | style)
                # Already handled above
                ;;
            *)
                find_and_run_tests "$test_dir" "test-*.zsh"
                ;;
            esac
        fi
    done

    # Summary
    # Emit JSON summary (final counts) BEFORE human-readable summary so machine consumers
    # can act even if later formatting fails. This occurs AFTER recursive fallback tests.
    if ((json_output)); then
        json_file="${RESULTS_DIR}/test-results-${TIMESTAMP}.json"
        {
            printf '{\n'
            printf '  "timestamp": "%s",\n' "$TIMESTAMP"
            printf '  "total": %d,\n' "$total_tests"
            printf '  "passed": %d,\n' "$passed_tests"
            printf '  "failed": %d,\n' "$failed_tests"
            printf '  "skipped": %d,\n' "$skipped_tests"
            printf '  "status": "%s"\n' "$([[ $failed_tests -eq 0 ]] && echo "pass" || echo "fail")"
            printf '}\n'
        } >"$json_file"
        # Force a best-effort flush so downstream steps (CI, promotion guard) can read immediately
        { command -v sync >/dev/null 2>&1 && sync "$json_file" 2>/dev/null || true; } || true
        zsh_debug_echo "# [run-all-tests] JSON summary written: $json_file"
    fi

    zsh_debug_echo "================================"
    zsh_debug_echo "📊 Test Results Summary"
    zsh_debug_echo "================================"
    zsh_debug_echo "Total tests:  $total_tests"
    zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
    zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
    zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
    zsh_debug_echo ""

    log_result "SUMMARY" "Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests, Skipped: $skipped_tests"
    # Recursive fallback discovery for nested TDD directories (e.g., tests/**/tdd/test-*.zsh)
    # Ensures newly added deep tests are executed even if not in primary category paths.
    if [[ -d "$TEST_BASE_DIR" ]]; then
        while IFS= read -r extra_test; do
            [[ -z $extra_test ]] && continue
            # Derive test name and check if it already appeared in results (avoid duplicate execution)
            test_base="$(basename "$extra_test")"
            test_name="${test_base%.zsh}"
            if ! grep -q " $test_name " "$RESULTS_FILE" 2>/dev/null; then
                run_test "$extra_test"
            fi
        done < <(find "$TEST_BASE_DIR" -type f -path "*/tdd/test-*.zsh" 2>/dev/null | sort)
    fi
    if ((json_output)); then
        json_file="${RESULTS_DIR}/test-results-${TIMESTAMP}.json"
        {
            printf '{\n'
            printf '  "timestamp": "%s",\n' "$TIMESTAMP"
            printf '  "total": %d,\n' "$total_tests"
            printf '  "passed": %d,\n' "$passed_tests"
            printf '  "failed": %d,\n' "$failed_tests"
            printf '  "skipped": %d,\n' "$skipped_tests"
            printf '  "duration_seconds": %s\n' "null"
            printf '}\n'
        } >"$json_file"
        zsh_debug_echo "# [run-all-tests] JSON summary written: $json_file"
    fi

    if [[ $failed_tests -eq 0 ]]; then
        zsh_debug_echo "${GREEN}✅ All tests passed!${NC}"
        log_result "SUCCESS" "All tests passed"

        # Use zsh_debug_echo for success message
        if declare -f zsh_debug_echo >/dev/null 2>&1; then
            zsh_debug_echo "# [run-all-tests] All tests completed successfully"
        fi

# Restore original working directory before exit
cd "$ORIGINAL_CWD" || {
    echo "ERROR: Failed to restore original working directory ($ORIGINAL_CWD)"
    exit 2
}

        return 0
    else
        zsh_debug_echo "${RED}❌ $failed_tests test(s) failed${NC}"
        zsh_debug_echo "Check the results file for details: $RESULTS_FILE"
        log_result "FAILURE" "$failed_tests test(s) failed"
        return 1
    fi
}

# Parse command line arguments
show_help() {
    cat <<EOF
ZSH Configuration Test Suite

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -q, --quiet     Quiet mode (minimal output)
    --path-only     Run only PATH-related tests
    --perf-only     Run only performance tests
    --design-only   Run only design and structure tests
    --security-only Run only security and async tests
    --unit-only     Run only unit tests
    --integration-only Run only integration tests
    --category <list>   Run only specified categories (comma-separated)
    --fail-fast     Exit immediately on first test failure

EXAMPLES:
    $0                  # Run all tests
    $0 --path-only      # Run only PATH tests
    $0 --perf-only      # Run only performance tests
    $0 --design-only    # Run only design and structure tests
    $0 --security-only  # Run only security tests
    $0 -v               # Run with verbose output

OUTPUT:
    Results are logged to: $RESULTS_FILE

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
category_list=""
fail_fast=0

while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        show_help
        exit 0
        ;;
    -v | --verbose)
        verbose=1
        export ZSH_DEBUG=1
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
    --category=*)
        category_list="${1#*=}"
        shift
        ;;
    --category)
        category_list="$2"
        shift 2
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
        zsh_debug_echo "Unknown option: $1"
        zsh_debug_echo "Use -h or --help for usage information"
        exit 1
        ;;
    esac
done

# Override main for filtered execution
if [[ -n "$category_list" ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Selected Categories: $category_list)"
        zsh_debug_echo "================================================================"
        log_result "INFO" "Running selected categories: $category_list"
        local IFS=","
        local -a categories
        categories=(${=category_list})
        for cat in "${categories[@]}"; do
            case "$cat" in
            design)
                find_and_run_tests "$TEST_BASE_DIR/design" "test-*.zsh"
                ;;
            unit)
                find_and_run_tests "$TEST_BASE_DIR/unit" "test-*.zsh"
                ;;
            feature)
                find_and_run_tests "$TEST_BASE_DIR/feature" "test-*.zsh"
                ;;
            integration)
                find_and_run_tests "$TEST_BASE_DIR/integration" "test-*.zsh"
                ;;
            security)
                find_and_run_tests "$TEST_BASE_DIR/security" "test-*.zsh"
                ;;
            performance|perf)
                find_and_run_tests "$TEST_BASE_DIR/perf/phase06" "test-*.zsh"
                find_and_run_tests "$TEST_BASE_DIR/performance" "test-*.zsh"
                ;;
            path)
                find_and_run_tests "$TEST_BASE_DIR/path/phase05" "test-*.zsh"
                ;;
            style)
                find_and_run_tests "$TEST_BASE_DIR/style" "test-*.zsh"
                ;;
            *)
                zsh_debug_echo "${YELLOW}Warning:${NC} Unknown category: $cat"
                ;;
            esac
        done
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Selected Categories - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $path_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (PATH Tests Only)"
        zsh_debug_echo "================================================"
        log_result "INFO" "Running PATH tests only"
        find_and_run_tests "$TEST_BASE_DIR/path/phase05" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "PATH Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $perf_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Performance Tests Only)"
        zsh_debug_echo "======================================================="
        log_result "INFO" "Running performance tests only"
        find_and_run_tests "$TEST_BASE_DIR/perf/phase06" "test-*.zsh"
        find_and_run_tests "$TEST_BASE_DIR/performance" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Performance Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $design_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Design Tests Only)"
        zsh_debug_echo "=================================================="
        log_result "INFO" "Running design tests only"
        find_and_run_tests "$TEST_BASE_DIR/design" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Design Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $security_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Security Tests Only)"
        zsh_debug_echo "====================================================="
        log_result "INFO" "Running security tests only"
        find_and_run_tests "$TEST_BASE_DIR/security" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Security Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $unit_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Unit Tests Only)"
        zsh_debug_echo "================================================"
        log_result "INFO" "Running unit tests only"
        find_and_run_tests "$TEST_BASE_DIR/unit" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Unit Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
elif [[ $integration_only -eq 1 ]]; then
    main() {
        zsh_debug_echo "🧪 ZSH Configuration Test Suite (Integration Tests Only)"
        zsh_debug_echo "========================================================"
        log_result "INFO" "Running integration tests only"
        find_and_run_tests "$TEST_BASE_DIR/integration" "test-*.zsh"
        # Summary
        zsh_debug_echo "================================"
        zsh_debug_echo "📊 Test Results Summary"
        zsh_debug_echo "================================"
        zsh_debug_echo "Total tests:  $total_tests"
        zsh_debug_echo "${GREEN}Passed:${NC}       $passed_tests"
        zsh_debug_echo "${RED}Failed:${NC}       $failed_tests"
        zsh_debug_echo "${YELLOW}Skipped:${NC}      $skipped_tests"
        log_result "SUMMARY" "Integration Tests - Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
        return $([[ $failed_tests -eq 0 ]] && echo 0 || echo 1)
    }
fi

# Execute main function only when not sourced
if ! (return 0 2>/dev/null); then
  main "$@"
fi
