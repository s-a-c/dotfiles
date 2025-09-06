#!/usr/bin/env zsh
# manifest-test-escalation.zsh
# P1.2 Manifest Test Escalation System
#
# PURPOSE:
#   Implements comprehensive test coverage and escalation procedures
#   for critical zsh configuration paths. Provides automated validation,
#   regression detection, and test orchestration.
#
# FEATURES:
#   - Hierarchical test suite organization
#   - Automatic test discovery and execution
#   - Performance regression detection
#   - Test result aggregation and reporting
#   - Integration with CI/CD pipelines
#   - Escalation triggers and notifications

set -euo pipefail

# ------------------------
# Test Framework Constants
# ------------------------

SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd "${0%/*}" && pwd)"
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Test configuration
: ${TEST_SUITE_DIR:="$ZDOTDIR/tests"}
: ${TEST_RESULTS_DIR:="$ZDOTDIR/docs/redesignv2/artifacts/test-results"}
: ${TEST_TIMEOUT:=30}
: ${TEST_PARALLEL:=4}
: ${TEST_VERBOSE:=0}
: ${TEST_ESCALATION_ENABLED:=1}

# Performance thresholds
: ${PERF_REGRESSION_THRESHOLD:=20}  # 20% performance degradation
: ${PERF_VARIANCE_THRESHOLD:=0.15}  # 15% RSD threshold
: ${LOAD_TIME_THRESHOLD:=2000}      # 2 second load time threshold

# Test categories and priorities
typeset -gA TEST_CATEGORIES=(
  ["critical"]=1
  ["essential"]=2
  ["performance"]=3
  ["integration"]=4
  ["compatibility"]=5
)

typeset -gA TEST_ESCALATION_RULES=(
  ["critical"]=1
  ["essential"]=2
  ["performance"]=5
  ["integration"]=10
  ["compatibility"]=20
)

# ------------------------
# Test Discovery System
# ------------------------

# Discover all test files
discover_tests() {
  local category="${1:-all}"
  local pattern="${2:-*.test.zsh}"
  
  if [[ ! -d "$TEST_SUITE_DIR" ]]; then
    echo "[test-discovery] Test suite directory not found: $TEST_SUITE_DIR" >&2
    return 1
  fi
  
  local -a test_files
  
  if [[ "$category" == "all" ]]; then
    test_files=("$TEST_SUITE_DIR"/**/$pattern(.N))
  else
    test_files=("$TEST_SUITE_DIR"/$category/**/$pattern(.N))
    # Also check for category-named test files
    test_files+=("$TEST_SUITE_DIR"/**/*${category}*$pattern(.N))
  fi
  
  if (( ${#test_files[@]} == 0 )); then
    echo "[test-discovery] No tests found for category: $category" >&2
    return 1
  fi
  
  printf '%s\n' "${test_files[@]}"
  return 0
}

# Categorize tests based on path and naming
categorize_test() {
  local test_file="$1"
  local basename="${test_file##*/}"
  
  # Check path-based categorization
  case "$test_file" in
    */critical/*) echo "critical" ;;
    */essential/*) echo "essential" ;;
    */performance/*) echo "performance" ;;
    */integration/*) echo "integration" ;;
    */compatibility/*) echo "compatibility" ;;
    *) 
      # Check filename-based categorization
      case "$basename" in
        *critical*) echo "critical" ;;
        *essential*) echo "essential" ;;
        *perf*|*performance*) echo "performance" ;;
        *integration*) echo "integration" ;;
        *compat*) echo "compatibility" ;;
        *) echo "general" ;;
      esac
      ;;
  esac
}

# ------------------------
# Test Execution Engine
# ------------------------

# Execute a single test with timeout and monitoring
execute_test() {
  local test_file="$1"
  local test_name="${test_file##*/}"
  local category="$(categorize_test "$test_file")"
  local result_file="$TEST_RESULTS_DIR/${test_name%.test.zsh}.result.json"
  
  # Ensure results directory exists
  mkdir -p "$TEST_RESULTS_DIR"
  
  echo "[test-exec] Running test: $test_name (category: $category)"
  
  local start_time end_time duration_ms exit_code
  local stdout_file="$TEST_RESULTS_DIR/${test_name%.test.zsh}.stdout"
  local stderr_file="$TEST_RESULTS_DIR/${test_name%.test.zsh}.stderr"
  
  start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  
  # Execute test with timeout
  if command -v timeout >/dev/null 2>&1; then
    timeout "${TEST_TIMEOUT}s" zsh "$test_file" >"$stdout_file" 2>"$stderr_file"
    exit_code=$?
  else
    # Fallback without timeout
    zsh "$test_file" >"$stdout_file" 2>"$stderr_file"
    exit_code=$?
  fi
  
  end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  duration_ms=$(( (end_time - start_time) / 1000000 ))
  
  # Determine test status
  local status
  case $exit_code in
    0) status="passed" ;;
    124) status="timeout" ;;
    *) status="failed" ;;
  esac
  
  # Collect test output
  local stdout_content stderr_content
  stdout_content=$(<"$stdout_file" 2>/dev/null || echo "")
  stderr_content=$(<"$stderr_file" 2>/dev/null || echo "")
  
  # Generate result JSON
  {
    echo "{"
    echo "  \"test_name\": \"$test_name\","
    echo "  \"test_file\": \"$test_file\","
    echo "  \"category\": \"$category\","
    echo "  \"status\": \"$status\","
    echo "  \"exit_code\": $exit_code,"
    echo "  \"duration_ms\": $duration_ms,"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"timeout_seconds\": $TEST_TIMEOUT,"
    echo "  \"stdout\": $(printf '%s' "$stdout_content" | jq -Rs .),"
    echo "  \"stderr\": $(printf '%s' "$stderr_content" | jq -Rs .)"
    echo "}"
  } >"$result_file"
  
  # Clean up temporary files
  rm -f "$stdout_file" "$stderr_file"
  
  # Check for escalation
  if should_escalate "$category" "$status" "$duration_ms"; then
    escalate_test_result "$test_name" "$category" "$status" "$exit_code" "$duration_ms"
  fi
  
  return $exit_code
}

# Execute test suite
execute_test_suite() {
  local category="${1:-all}"
  local parallel_jobs="${2:-$TEST_PARALLEL}"
  
  echo "[test-suite] Executing test suite (category: $category, parallel: $parallel_jobs)"
  
  local -a test_files
  if ! test_files=($(discover_tests "$category")); then
    echo "[test-suite] No tests to execute" >&2
    return 1
  fi
  
  echo "[test-suite] Found ${#test_files[@]} tests"
  
  local -a pids
  local -a results
  local active_jobs=0
  local total_tests=${#test_files[@]}
  local completed_tests=0
  
  # Execute tests with parallel control
  for test_file in "${test_files[@]}"; do
    # Wait for available slot
    while (( active_jobs >= parallel_jobs )); do
      wait_for_job
      (( active_jobs-- ))
      (( completed_tests++ ))
      echo "[test-suite] Progress: $completed_tests/$total_tests tests completed"
    done
    
    # Start test in background
    execute_test "$test_file" &
    pids+=($!)
    (( active_jobs++ ))
    
    if (( TEST_VERBOSE )); then
      echo "[test-suite] Started test: ${test_file##*/} (PID: $!)" 
    fi
  done
  
  # Wait for remaining jobs
  while (( active_jobs > 0 )); do
    wait_for_job
    (( active_jobs-- ))
    (( completed_tests++ ))
    echo "[test-suite] Progress: $completed_tests/$total_tests tests completed"
  done
  
  echo "[test-suite] Test suite execution completed"
  generate_test_report "$category"
}

# Wait for any background job to complete
wait_for_job() {
  # Wait for any job to complete
  wait -n 2>/dev/null || {
    # Fallback for shells without wait -n
    local pid
    for pid in "${pids[@]}"; do
      if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid" 2>/dev/null || true
        break
      fi
    done
  }
}

# ------------------------
# Test Escalation System
# ------------------------

# Check if test result should be escalated
should_escalate() {
  local category="$1"
  local status="$2"
  local duration_ms="$3"
  
  if [[ "${TEST_ESCALATION_ENABLED:-1}" != "1" ]]; then
    return 1
  fi
  
  local escalation_threshold="${TEST_ESCALATION_RULES[$category]:-999}"
  
  # Always escalate critical failures
  if [[ "$category" == "critical" && "$status" != "passed" ]]; then
    return 0
  fi
  
  # Escalate based on failure count threshold
  local recent_failures
  recent_failures=$(count_recent_failures "$category")
  
  if (( recent_failures >= escalation_threshold )); then
    return 0
  fi
  
  # Escalate performance regressions
  if [[ "$category" == "performance" ]] && (( duration_ms > LOAD_TIME_THRESHOLD )); then
    return 0
  fi
  
  return 1
}

# Count recent test failures for category
count_recent_failures() {
  local category="$1"
  local hours_back="${2:-24}"
  
  local cutoff_time
  cutoff_time=$(date -d "$hours_back hours ago" +%s 2>/dev/null || date -v-"${hours_back}H" +%s 2>/dev/null || echo 0)
  
  local failure_count=0
  local result_file
  
  for result_file in "$TEST_RESULTS_DIR"/*.result.json(.N); do
    if [[ ! -f "$result_file" ]]; then
      continue
    fi
    
    # Parse JSON result
    local test_category test_status test_timestamp
    test_category=$(jq -r '.category // "unknown"' "$result_file" 2>/dev/null || echo "unknown")
    test_status=$(jq -r '.status // "unknown"' "$result_file" 2>/dev/null || echo "unknown")
    test_timestamp=$(jq -r '.timestamp // ""' "$result_file" 2>/dev/null || echo "")
    
    # Skip if not matching category
    if [[ "$test_category" != "$category" ]]; then
      continue
    fi
    
    # Skip if status is not a failure
    if [[ "$test_status" == "passed" ]]; then
      continue
    fi
    
    # Check if within time window
    if [[ -n "$test_timestamp" ]]; then
      local result_time
      result_time=$(date -d "$test_timestamp" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$test_timestamp" +%s 2>/dev/null || echo 0)
      
      if (( result_time >= cutoff_time )); then
        (( failure_count++ ))
      fi
    fi
  done
  
  echo $failure_count
}

# Execute escalation procedure
escalate_test_result() {
  local test_name="$1"
  local category="$2"
  local status="$3"
  local exit_code="$4"
  local duration_ms="$5"
  
  echo "[escalation] Escalating test result: $test_name (category: $category, status: $status)"
  
  # Log escalation event
  local escalation_file="$TEST_RESULTS_DIR/escalations.log"
  {
    echo "$(date -Iseconds) ESCALATION test=$test_name category=$category status=$status exit_code=$exit_code duration_ms=$duration_ms"
  } >>"$escalation_file"
  
  # Send notifications (if configured)
  send_escalation_notification "$test_name" "$category" "$status" "$exit_code" "$duration_ms"
  
  # Trigger additional actions based on category
  case "$category" in
    "critical")
      trigger_critical_escalation "$test_name" "$status" "$exit_code"
      ;;
    "performance")
      trigger_performance_escalation "$test_name" "$duration_ms"
      ;;
  esac
}

# Send escalation notification
send_escalation_notification() {
  local test_name="$1"
  local category="$2"
  local status="$3"
  local exit_code="$4"
  local duration_ms="$5"
  
  # This would integrate with external notification systems
  # For now, just log the event
  echo "[notification] Test escalation: $test_name ($category) failed with status $status (code: $exit_code, duration: ${duration_ms}ms)"
}

# Critical test escalation
trigger_critical_escalation() {
  local test_name="$1"
  local status="$2"
  local exit_code="$3"
  
  echo "[critical-escalation] CRITICAL TEST FAILURE: $test_name (status: $status, exit: $exit_code)"
  
  # This could trigger emergency procedures, rollbacks, etc.
  # For now, create a critical alert file
  local alert_file="$TEST_RESULTS_DIR/CRITICAL_ALERT"
  {
    echo "CRITICAL TEST FAILURE DETECTED"
    echo "Test: $test_name"
    echo "Status: $status"
    echo "Exit Code: $exit_code"
    echo "Timestamp: $(date -Iseconds)"
    echo ""
    echo "Immediate action may be required."
  } >"$alert_file"
}

# Performance regression escalation
trigger_performance_escalation() {
  local test_name="$1"
  local duration_ms="$2"
  
  echo "[perf-escalation] Performance regression detected: $test_name (${duration_ms}ms)"
  
  # Could trigger performance analysis, profiling, etc.
  local perf_alert_file="$TEST_RESULTS_DIR/PERFORMANCE_ALERT"
  {
    echo "PERFORMANCE REGRESSION DETECTED"
    echo "Test: $test_name"
    echo "Duration: ${duration_ms}ms"
    echo "Threshold: ${LOAD_TIME_THRESHOLD}ms"
    echo "Regression: $(( (duration_ms - LOAD_TIME_THRESHOLD) * 100 / LOAD_TIME_THRESHOLD ))%"
    echo "Timestamp: $(date -Iseconds)"
  } >"$perf_alert_file"
}

# ------------------------
# Test Reporting System
# ------------------------

# Generate comprehensive test report
generate_test_report() {
  local category="${1:-all}"
  local report_file="$TEST_RESULTS_DIR/test-report-${category}-$(date +%Y%m%d-%H%M%S).json"
  
  echo "[test-report] Generating test report: $report_file"
  
  local -A category_stats
  local total_tests=0 passed_tests=0 failed_tests=0 timeout_tests=0
  local total_duration=0
  
  # Aggregate results
  local result_file
  for result_file in "$TEST_RESULTS_DIR"/*.result.json(.N); do
    if [[ ! -f "$result_file" ]]; then
      continue
    fi
    
    # Parse result
    local test_category test_status test_duration
    test_category=$(jq -r '.category // "unknown"' "$result_file" 2>/dev/null || echo "unknown")
    test_status=$(jq -r '.status // "unknown"' "$result_file" 2>/dev/null || echo "unknown")
    test_duration=$(jq -r '.duration_ms // 0' "$result_file" 2>/dev/null || echo 0)
    
    # Skip if category doesn't match (unless "all")
    if [[ "$category" != "all" && "$test_category" != "$category" ]]; then
      continue
    fi
    
    # Update counters
    (( total_tests++ ))
    (( total_duration += test_duration ))
    
    case "$test_status" in
      "passed") (( passed_tests++ )) ;;
      "failed") (( failed_tests++ )) ;;
      "timeout") (( timeout_tests++ )) ;;
    esac
    
    # Update category stats
    local cat_key="${test_category}_total"
    (( category_stats[$cat_key] = ${category_stats[$cat_key]:-0} + 1 ))
    
    cat_key="${test_category}_${test_status}"
    (( category_stats[$cat_key] = ${category_stats[$cat_key]:-0} + 1 ))
  done
  
  # Calculate metrics
  local pass_rate=0 avg_duration=0
  if (( total_tests > 0 )); then
    pass_rate=$(( passed_tests * 100 / total_tests ))
    avg_duration=$(( total_duration / total_tests ))
  fi
  
  # Generate JSON report
  {
    echo "{"
    echo "  \"report_type\": \"test_suite_summary\","
    echo "  \"category\": \"$category\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"summary\": {"
    echo "    \"total_tests\": $total_tests,"
    echo "    \"passed_tests\": $passed_tests,"
    echo "    \"failed_tests\": $failed_tests,"
    echo "    \"timeout_tests\": $timeout_tests,"
    echo "    \"pass_rate_percent\": $pass_rate,"
    echo "    \"total_duration_ms\": $total_duration,"
    echo "    \"average_duration_ms\": $avg_duration"
    echo "  },"
    
    # Category breakdown
    echo "  \"category_stats\": {"
    local first=true
    local key
    for key in ${(ok)category_stats}; do
      if [[ "$first" == "true" ]]; then
        first=false
      else
        echo ","
      fi
      echo -n "    \"$key\": ${category_stats[$key]}"
    done
    echo ""
    echo "  },"
    
    echo "  \"thresholds\": {"
    echo "    \"performance_regression_threshold\": $PERF_REGRESSION_THRESHOLD,"
    echo "    \"performance_variance_threshold\": $PERF_VARIANCE_THRESHOLD,"
    echo "    \"load_time_threshold_ms\": $LOAD_TIME_THRESHOLD"
    echo "  }"
    echo "}"
  } >"$report_file"
  
  echo "[test-report] Test report generated: $report_file"
  echo "[test-report] Summary: $total_tests total, $passed_tests passed, $failed_tests failed, $timeout_tests timeout (${pass_rate}% pass rate)"
  
  return $(( failed_tests + timeout_tests > 0 ? 1 : 0 ))
}

# ------------------------
# CLI Interface
# ------------------------

usage() {
  cat <<EOF
$SCRIPT_NAME - Manifest Test Escalation System

Usage: $SCRIPT_NAME [command] [options]

Commands:
  run [category]           Run test suite (default: all)
  discover [category]      Discover available tests
  report [category]        Generate test report
  escalate                 Check for escalation triggers
  health                   Check system health

Options:
  --timeout SECONDS        Test timeout (default: $TEST_TIMEOUT)
  --parallel JOBS          Parallel test execution (default: $TEST_PARALLEL)
  --verbose                Enable verbose output
  --no-escalation          Disable escalation
  --help                   Show this help

Categories: critical, essential, performance, integration, compatibility, all

Examples:
  $SCRIPT_NAME run critical
  $SCRIPT_NAME run --parallel 8 --timeout 60
  $SCRIPT_NAME report performance
  $SCRIPT_NAME discover --verbose
EOF
}

# Parse command line arguments
main() {
  local command="${1:-run}"
  shift 2>/dev/null || true
  
  # Parse options
  while (( $# > 0 )); do
    case "$1" in
      --timeout)
        TEST_TIMEOUT="$2"
        shift 2
        ;;
      --parallel)
        TEST_PARALLEL="$2"
        shift 2
        ;;
      --verbose)
        TEST_VERBOSE=1
        shift
        ;;
      --no-escalation)
        TEST_ESCALATION_ENABLED=0
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done
  
  local category="${1:-all}"
  
  # Execute command
  case "$command" in
    run)
      execute_test_suite "$category" "$TEST_PARALLEL"
      ;;
    discover)
      discover_tests "$category"
      ;;
    report)
      generate_test_report "$category"
      ;;
    escalate)
      check_escalation_triggers "$category"
      ;;
    health)
      check_system_health
      ;;
    *)
      echo "Unknown command: $command" >&2
      usage
      exit 1
      ;;
  esac
}

# Check for escalation triggers
check_escalation_triggers() {
  local category="${1:-all}"
  echo "[escalation-check] Checking escalation triggers for category: $category"
  
  local escalations=0
  local cat
  if [[ "$category" == "all" ]]; then
    for cat in ${(k)TEST_CATEGORIES}; do
      local failures
      failures=$(count_recent_failures "$cat")
      local threshold="${TEST_ESCALATION_RULES[$cat]:-999}"
      
      if (( failures >= threshold )); then
        echo "[escalation-check] Escalation triggered for $cat: $failures failures (threshold: $threshold)"
        (( escalations++ ))
      fi
    done
  else
    local failures
    failures=$(count_recent_failures "$category")
    local threshold="${TEST_ESCALATION_RULES[$category]:-999}"
    
    if (( failures >= threshold )); then
      echo "[escalation-check] Escalation triggered for $category: $failures failures (threshold: $threshold)"
      (( escalations++ ))
    fi
  fi
  
  if (( escalations == 0 )); then
    echo "[escalation-check] No escalations triggered"
    return 0
  else
    echo "[escalation-check] $escalations escalation(s) triggered"
    return 1
  fi
}

# Check system health
check_system_health() {
  echo "[health-check] Checking system health"
  
  local issues=0
  
  # Check directories
  for dir in "$TEST_SUITE_DIR" "$TEST_RESULTS_DIR"; do
    if [[ ! -d "$dir" ]]; then
      echo "[health-check] ERROR: Directory missing: $dir"
      (( issues++ ))
    fi
  done
  
  # Check required commands
  for cmd in zsh jq date; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[health-check] ERROR: Required command missing: $cmd"
      (( issues++ ))
    fi
  done
  
  # Check test files
  local test_count
  test_count=$(discover_tests 2>/dev/null | wc -l)
  if (( test_count == 0 )); then
    echo "[health-check] WARNING: No test files found"
    (( issues++ ))
  else
    echo "[health-check] Found $test_count test files"
  fi
  
  if (( issues == 0 )); then
    echo "[health-check] System health: OK"
    return 0
  else
    echo "[health-check] System health: $issues issue(s) found"
    return 1
  fi
}

# Run main function if script is executed directly
if [[ "${(%):-%N}" == "${0}" ]]; then
  main "$@"
fi
