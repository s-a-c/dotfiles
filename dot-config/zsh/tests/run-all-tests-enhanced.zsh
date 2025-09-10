#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/tests/run-all-tests-enhanced.zsh
#
# Enhanced Test Runner for ZSH Configuration
# Integrates parallel execution, coverage tracking, and comprehensive reporting
#
# This is the enhanced version of the original run-all-tests.zsh with:
# - Parallel test execution
# - Code coverage integration
# - Test isolation framework
# - Structured JSON and human-readable output
# - Advanced filtering and reporting
#
# Usage:
#   ./run-all-tests-enhanced.zsh [options]
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
#   --help              Show help information
#

set -euo pipefail

# Script metadata - use ZSH-specific reliable methods
SCRIPT_NAME="${${(%):-%x}:t}"
SCRIPT_DIR="${${(%):-%x}:A:h}"
ORIGINAL_CWD="$PWD"

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Change to ZDOTDIR for all test execution
cd "$ZDOTDIR" || {
    echo "ERROR: Failed to cd to ZDOTDIR ($ZDOTDIR)" >&2
    exit 2
}

# Enhanced runner configuration
ENHANCED_RUNNER_VERSION="1.0.0"
ENHANCED_RUNNER_INITIALIZED=0

# Default settings
DEFAULT_PARALLEL_WORKERS=0  # Auto-detect
DEFAULT_TIMEOUT=60
DEFAULT_FORMAT="both"
DEFAULT_COVERAGE=0
DEFAULT_VERBOSE=0
DEFAULT_DRY_RUN=0
DEFAULT_STOP_ON_FAIL=0

# Runtime settings (will be set by argument parsing)
PARALLEL_WORKERS="$DEFAULT_PARALLEL_WORKERS"
TIMEOUT="$DEFAULT_TIMEOUT"
OUTPUT_FORMAT="$DEFAULT_FORMAT"
COVERAGE_ENABLED="$DEFAULT_COVERAGE"
VERBOSE="$DEFAULT_VERBOSE"
DRY_RUN="$DEFAULT_DRY_RUN"
STOP_ON_FAIL="$DEFAULT_STOP_ON_FAIL"
FILTER_PATTERN=""
EXCLUDE_PATTERN=""

# Directories
TEST_BASE_DIR="${ZDOTDIR}/tests"
RESULTS_DIR="${ZSH_LOG_DIR:-${ZDOTDIR}/logs}/test-results"
ENHANCED_RESULTS_DIR="${RESULTS_DIR}/enhanced"
LIB_DIR="${TEST_BASE_DIR}/lib"
TOOLS_DIR="${TEST_BASE_DIR}/tools"

# Libraries
TEST_FRAMEWORK_LIB="${LIB_DIR}/test-framework.zsh"
TEST_ISOLATION_LIB="${LIB_DIR}/test-isolation.zsh"
TEST_RUNNER_LIB="${LIB_DIR}/test-runner-enhanced.zsh"
COVERAGE_SETUP="${TOOLS_DIR}/setup-coverage.zsh"

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Logging functions
enhanced_log() {
    printf "[${BOLD}ENHANCED${NC}] %s\n" "$*"
}

enhanced_debug() {
    if (( VERBOSE )); then
        printf "[${BLUE}ENHANCED DEBUG${NC}] %s\n" "$*" >&2
    fi
}

enhanced_error() {
    printf "[${RED}ENHANCED ERROR${NC}] %s\n" "$*" >&2
}

enhanced_success() {
    printf "[${GREEN}ENHANCED${NC}] %s\n" "$*"
}

enhanced_warn() {
    printf "[${YELLOW}ENHANCED WARN${NC}] %s\n" "$*"
}

# Show help
show_help() {
    cat <<EOF
${BOLD}Enhanced ZSH Configuration Test Runner${NC}
Version: $ENHANCED_RUNNER_VERSION

${BOLD}USAGE:${NC}
  $SCRIPT_NAME [options]

${BOLD}OPTIONS:${NC}
  --parallel N        Number of parallel workers (default: auto-detect)
  --coverage          Enable code coverage tracking with kcov
  --format FORMAT     Output format: json, human, both (default: both)
  --timeout N         Per-test timeout in seconds (default: 60)
  --filter PATTERN    Run only tests matching pattern (substring match)
  --exclude PATTERN   Exclude tests matching pattern (substring match)
  --stop-on-fail      Stop execution on first test failure
  --verbose           Enable verbose debug output
  --dry-run           Show what would be executed without running tests
  --help              Show this help information

${BOLD}EXAMPLES:${NC}
  # Run all tests with default settings
  $SCRIPT_NAME

  # Run with 4 parallel workers and coverage
  $SCRIPT_NAME --parallel 4 --coverage

  # Run only integration tests with verbose output
  $SCRIPT_NAME --filter integration --verbose

  # Exclude performance tests and stop on first failure
  $SCRIPT_NAME --exclude perf --stop-on-fail

  # Generate only JSON output with 30s timeout
  $SCRIPT_NAME --format json --timeout 30

  # Show what would be executed (dry run)
  $SCRIPT_NAME --dry-run --verbose

${BOLD}ENVIRONMENT VARIABLES:${NC}
  ZDOTDIR             ZSH configuration directory
  ZSH_LOG_DIR         Test results output directory
  COVERAGE_DEBUG      Enable coverage debug output (0/1)
  ENHANCED_DEBUG      Enable enhanced runner debug (0/1)

${BOLD}COVERAGE:${NC}
  Coverage tracking uses kcov to analyze ZSH script execution.
  Reports are generated in HTML, JSON, and XML formats.
  Coverage data is stored in: ${ZDOTDIR}/tests/coverage/

${BOLD}OUTPUT FORMATS:${NC}
  json    - Structured JSON for CI/automation
  human   - Human-readable terminal output
  both    - Both JSON and human-readable (default)

${BOLD}PARALLEL EXECUTION:${NC}
  Auto-detects CPU cores (capped at 8 for stability).
  Each test runs in isolated environment with cleanup.
  Failed tests don't affect other parallel executions.

EOF
}

# Parse command line arguments
parse_arguments() {
    while (( $# > 0 )); do
        case "$1" in
            --parallel)
                shift
                if [[ -z "${1:-}" ]] || [[ ! "$1" =~ ^[0-9]+$ ]]; then
                    enhanced_error "Invalid parallel worker count: ${1:-}"
                    return 1
                fi
                PARALLEL_WORKERS="$1"
                ;;
            --coverage)
                COVERAGE_ENABLED=1
                ;;
            --format)
                shift
                if [[ ! "${1:-}" =~ ^(json|human|both)$ ]]; then
                    enhanced_error "Invalid format: ${1:-}. Must be: json, human, or both"
                    return 1
                fi
                OUTPUT_FORMAT="$1"
                ;;
            --timeout)
                shift
                if [[ -z "${1:-}" ]] || [[ ! "$1" =~ ^[0-9]+$ ]]; then
                    enhanced_error "Invalid timeout: ${1:-}"
                    return 1
                fi
                TIMEOUT="$1"
                ;;
            --filter)
                shift
                FILTER_PATTERN="${1:-}"
                ;;
            --exclude)
                shift
                EXCLUDE_PATTERN="${1:-}"
                ;;
            --stop-on-fail)
                STOP_ON_FAIL=1
                ;;
            --verbose)
                VERBOSE=1
                export ENHANCED_DEBUG=1
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --help|-h)
                show_help
                return 2
                ;;
            *)
                enhanced_error "Unknown option: $1"
                enhanced_log "Use --help for usage information"
                return 1
                ;;
        esac
        shift
    done
}

# Check prerequisites
check_prerequisites() {
    enhanced_debug "Checking prerequisites..."

    local missing_deps=()

    # Check for required ZSH version
    if [[ -z "${ZSH_VERSION:-}" ]]; then
        missing_deps+=("zsh")
    fi

    # Check for basic utilities
    local required_utils=(find xargs timeout bc)
    for util in "${required_utils[@]}"; do
        if ! command -v "$util" >/dev/null 2>&1; then
            missing_deps+=("$util")
        fi
    done

    # Check coverage prerequisites if enabled
    if (( COVERAGE_ENABLED )); then
        if ! command -v kcov >/dev/null 2>&1; then
            missing_deps+=("kcov")
        fi
    fi

    if (( ${#missing_deps[@]} > 0 )); then
        enhanced_error "Missing required dependencies: ${missing_deps[*]}"
        enhanced_log "Install missing tools and try again"
        return 1
    fi

    enhanced_debug "All prerequisites satisfied"
    return 0
}

# Initialize enhanced runner
initialize_runner() {
    if (( ENHANCED_RUNNER_INITIALIZED )); then
        return 0
    fi

    enhanced_debug "Initializing enhanced test runner..."

    # Create directories
    mkdir -p "$RESULTS_DIR" "$ENHANCED_RESULTS_DIR"

    # Load required libraries
    local libs_to_load=()

    # Always load test framework
    if [[ -f "$TEST_FRAMEWORK_LIB" ]]; then
        enhanced_debug "Loading test framework library..."
        source "$TEST_FRAMEWORK_LIB" || {
            enhanced_error "Failed to load test framework library"
            return 1
        }
    fi

    # Load test isolation if available
    if [[ -f "$TEST_ISOLATION_LIB" ]]; then
        enhanced_debug "Loading test isolation library..."
        source "$TEST_ISOLATION_LIB" || {
            enhanced_warn "Failed to load test isolation library - continuing without isolation"
        }
    fi

    # Load enhanced runner library if available
    if [[ -f "$TEST_RUNNER_LIB" ]]; then
        enhanced_debug "Loading enhanced runner library..."
        source "$TEST_RUNNER_LIB" || {
            enhanced_warn "Failed to load enhanced runner library - using fallback mode"
        }
    fi

    # Initialize coverage if enabled
    if (( COVERAGE_ENABLED )) && [[ -f "$COVERAGE_SETUP" ]]; then
        enhanced_debug "Initializing coverage tracking..."
        source "$COVERAGE_SETUP" || {
            enhanced_warn "Failed to initialize coverage - continuing without coverage"
            COVERAGE_ENABLED=0
        }

        if (( COVERAGE_ENABLED )); then
            coverage_init || {
                enhanced_warn "Coverage initialization failed - disabling coverage"
                COVERAGE_ENABLED=0
            }
        fi
    fi

    ENHANCED_RUNNER_INITIALIZED=1
    enhanced_debug "Enhanced runner initialized successfully"
    return 0
}

# Fallback test execution (if enhanced runner lib not available)
fallback_execute_tests() {
    enhanced_log "Using fallback test execution mode..."

    # Use the original run-all-tests.zsh logic
    local original_runner="${TEST_BASE_DIR}/run-all-tests.zsh"

    if [[ -f "$original_runner" && "$original_runner" != "$0" ]]; then
        enhanced_log "Delegating to original runner: $original_runner"
        exec "$original_runner"
    fi

    # Manual fallback implementation
    enhanced_log "Executing manual fallback..."

    local total_tests=0 passed_tests=0 failed_tests=0
    local start_time end_time
    start_time=$(date +%s)

    # Find and execute tests
    while IFS= read -r -d '' test_file; do
        local test_name="${test_file##*/}"

        # Apply filters
        if [[ -n "$FILTER_PATTERN" && ! "$test_name" == *"$FILTER_PATTERN"* ]]; then
            continue
        fi

        if [[ -n "$EXCLUDE_PATTERN" && "$test_name" == *"$EXCLUDE_PATTERN"* ]]; then
            continue
        fi

        (( total_tests++ ))

        if (( DRY_RUN )); then
            enhanced_log "Would execute: $test_file"
            continue
        fi

        enhanced_log "Executing: $test_name"

        if timeout "${TIMEOUT}s" zsh "$test_file" >/dev/null 2>&1; then
            (( passed_tests++ ))
            enhanced_success "PASS: $test_name"
        else
            (( failed_tests++ ))
            enhanced_error "FAIL: $test_name"

            if (( STOP_ON_FAIL )); then
                enhanced_error "Stopping on failure (--stop-on-fail enabled)"
                break
            fi
        fi
    done < <(find "$TEST_BASE_DIR" -name "test-*.zsh" -type f -print0 2>/dev/null)

    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    # Summary
    enhanced_log "===== FALLBACK TEST SUMMARY ====="
    enhanced_log "Total: $total_tests, Passed: $passed_tests, Failed: $failed_tests"
    enhanced_log "Duration: ${duration}s"

    if (( failed_tests > 0 )); then
        enhanced_error "Some tests failed"
        return 1
    else
        enhanced_success "All tests passed"
        return 0
    fi
}

# Main execution function
main() {
    # Print banner
    if [[ "$OUTPUT_FORMAT" == "human" || "$OUTPUT_FORMAT" == "both" ]]; then
        enhanced_log "${BOLD}Enhanced ZSH Configuration Test Runner${NC}"
        enhanced_log "Version: $ENHANCED_RUNNER_VERSION"
        enhanced_log "Working directory: $ZDOTDIR"
        enhanced_log ""
    fi

    # Parse arguments
    parse_arguments "$@" || {
        local exit_code=$?
        if (( exit_code == 2 )); then
            return 0  # Help was shown
        fi
        return $exit_code
    }

    # Show configuration in dry-run or verbose mode
    if (( DRY_RUN || VERBOSE )); then
        enhanced_log "Configuration:"
        enhanced_log "  Parallel workers: $PARALLEL_WORKERS"
        enhanced_log "  Coverage enabled: $(( COVERAGE_ENABLED )) && echo "Yes" || echo "No""
        enhanced_log "  Output format: $OUTPUT_FORMAT"
        enhanced_log "  Timeout: ${TIMEOUT}s"
        enhanced_log "  Filter pattern: ${FILTER_PATTERN:-"(none)"}"
        enhanced_log "  Exclude pattern: ${EXCLUDE_PATTERN:-"(none)"}"
        enhanced_log "  Stop on fail: $(( STOP_ON_FAIL )) && echo "Yes" || echo "No""
        enhanced_log ""
    fi

    # Check prerequisites
    check_prerequisites || return 1

    # Initialize runner
    initialize_runner || return 1

    # Use enhanced runner if available, otherwise fallback
    if command -v runner_execute_tests >/dev/null 2>&1; then
        enhanced_debug "Using enhanced runner implementation"

        # Build arguments for enhanced runner
        local runner_args=()

        if (( PARALLEL_WORKERS > 0 )); then
            runner_args+=(--parallel "$PARALLEL_WORKERS")
        fi

        if (( COVERAGE_ENABLED )); then
            runner_args+=(--coverage)
        fi

        runner_args+=(--format "$OUTPUT_FORMAT")
        runner_args+=(--timeout "$TIMEOUT")

        if [[ -n "$FILTER_PATTERN" ]]; then
            runner_args+=(--filter "$FILTER_PATTERN")
        fi

        if [[ -n "$EXCLUDE_PATTERN" ]]; then
            runner_args+=(--exclude "$EXCLUDE_PATTERN")
        fi

        if (( STOP_ON_FAIL )); then
            runner_args+=(--stop-on-fail)
        fi

        if (( VERBOSE )); then
            runner_args+=(--verbose)
        fi

        if (( DRY_RUN )); then
            runner_args+=(--dry-run)
        fi

        # Execute enhanced runner
        runner_execute_tests "${runner_args[@]}"
    else
        enhanced_warn "Enhanced runner not available, using fallback mode"
        fallback_execute_tests
    fi
}

# Cleanup on exit
cleanup_on_exit() {
    # Restore original working directory
    cd "$ORIGINAL_CWD" 2>/dev/null || true

    # Additional cleanup if needed
    if command -v runner_cleanup_on_exit >/dev/null 2>&1; then
        runner_cleanup_on_exit
    fi
}

# Setup signal handlers
trap cleanup_on_exit EXIT INT TERM

# Execute main function if script is run directly (not sourced)
# Use ZSH-specific method to detect if script is being executed vs sourced
if [[ "${ZSH_EVAL_CONTEXT:-}" == toplevel || "${ZSH_EVAL_CONTEXT:-}" == cmdarg* ]]; then
    main "$@"
fi
