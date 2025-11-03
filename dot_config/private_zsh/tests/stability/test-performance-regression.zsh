#!/usr/bin/env zsh
# ==============================================================================
# Performance Regression Test Script
# ==============================================================================
# Purpose: Measure startup time and compare against baseline
# Part of: Phase 1, Task 1.2.4 - Configuration Stability Testing
# Created: 2025-10-07
# ==============================================================================

emulate -L zsh
setopt ERR_RETURN NO_UNSET PIPE_FAIL

# Color output helpers
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Test configuration
SCRIPT_DIR="${0:A:h}"
ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
TEST_REPORT_DIR="${ZDOTDIR}/tests/stability/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${TEST_REPORT_DIR}/performance-regression-${TIMESTAMP}.md"

# Performance configuration
BASELINE_TIME=1.8  # seconds (from user's current optimized startup time)
REGRESSION_THRESHOLD=0.2  # 10% regression threshold (0.18s)
NUM_RUNS=5

# Ensure report directory exists
mkdir -p "${TEST_REPORT_DIR}"

# Test results
typeset -a TIMING_RESULTS=()
typeset -F MEAN_TIME=0.0
typeset -F MEDIAN_TIME=0.0
typeset -F MIN_TIME=999.0
typeset -F MAX_TIME=0.0
typeset -F STD_DEV=0.0

# ==============================================================================
# Functions
# ==============================================================================

print_header() {
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  ZSH Performance Regression Test${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
  print "  Baseline: ${BASELINE_TIME}s"
  print "  Runs: ${NUM_RUNS}"
  print "  Regression Threshold: ${REGRESSION_THRESHOLD}s (10%)"
  print ""
}

print_section() {
  print ""
  print "${YELLOW}▶ $1${NC}"
  print "${YELLOW}$(printf '─%.0s' {1..70})${NC}"
}

measure_startup_time() {
  local run_number=$1
  
  # Use time command to measure shell startup
  local time_output=$( (time zsh -i -c exit) 2>&1 )
  
  # Extract real time (format: "0.12s user 0.08s system 12% cpu 1.234 total")
  local total_time=$(echo "$time_output" | grep "total" | awk '{print $(NF-1)}')
  
  # Convert to seconds if needed (remove 's' suffix)
  total_time=${total_time%s}
  
  echo "$total_time"
}

run_performance_tests() {
  print_section "Running Performance Tests"
  
  print "  Measuring startup time (${NUM_RUNS} runs)..."
  print ""
  
  for i in {1..$NUM_RUNS}; do
    print -n "  Run ${i}/${NUM_RUNS}: "
    
    local start_time=$(date +%s.%N)
    zsh -i -c exit >/dev/null 2>&1
    local end_time=$(date +%s.%N)
    
    # Calculate elapsed time
    local elapsed=$(echo "$end_time - $start_time" | bc)
    TIMING_RESULTS+=($elapsed)
    
    print "${elapsed}s"
    
    # Update min/max
    if (( $(echo "$elapsed < $MIN_TIME" | bc -l) )); then
      MIN_TIME=$elapsed
    fi
    if (( $(echo "$elapsed > $MAX_TIME" | bc -l) )); then
      MAX_TIME=$elapsed
    fi
  done
}

calculate_statistics() {
  print_section "Calculating Statistics"
  
  # Calculate mean
  local sum=0.0
  for time in "${TIMING_RESULTS[@]}"; do
    sum=$(echo "$sum + $time" | bc -l)
  done
  MEAN_TIME=$(echo "scale=3; $sum / ${#TIMING_RESULTS[@]}" | bc -l)
  
  # Calculate median (sort and take middle value)
  local sorted=(${(on)TIMING_RESULTS})
  local mid=$(( ${#sorted[@]} / 2 ))
  MEDIAN_TIME=${sorted[$mid]}
  
  # Calculate standard deviation
  local variance=0.0
  for time in "${TIMING_RESULTS[@]}"; do
    local diff=$(echo "$time - $MEAN_TIME" | bc -l)
    local squared=$(echo "$diff * $diff" | bc -l)
    variance=$(echo "$variance + $squared" | bc -l)
  done
  variance=$(echo "scale=6; $variance / ${#TIMING_RESULTS[@]}" | bc -l)
  STD_DEV=$(echo "scale=3; sqrt($variance)" | bc -l)
  
  print "  Mean:   ${MEAN_TIME}s"
  print "  Median: ${MEDIAN_TIME}s"
  print "  Min:    ${MIN_TIME}s"
  print "  Max:    ${MAX_TIME}s"
  print "  StdDev: ${STD_DEV}s"
}

check_regression() {
  print_section "Regression Analysis"
  
  local diff=$(echo "$MEAN_TIME - $BASELINE_TIME" | bc -l)
  local percent=$(echo "scale=1; ($diff / $BASELINE_TIME) * 100" | bc -l)
  
  print "  Baseline:     ${BASELINE_TIME}s"
  print "  Current Mean: ${MEAN_TIME}s"
  print "  Difference:   ${diff}s (${percent}%)"
  print ""
  
  # Check if regression exceeds threshold
  if (( $(echo "$diff > $REGRESSION_THRESHOLD" | bc -l) )); then
    print "  ${RED}✗ REGRESSION DETECTED${NC}"
    print "  Performance degraded by ${diff}s (${percent}%)"
    print "  Threshold: ${REGRESSION_THRESHOLD}s"
    return 1
  elif (( $(echo "$diff > 0" | bc -l) )); then
    print "  ${YELLOW}⚠ Minor slowdown detected${NC}"
    print "  Performance degraded by ${diff}s (${percent}%)"
    print "  Still within acceptable threshold"
    return 0
  else
    print "  ${GREEN}✓ No regression detected${NC}"
    print "  Performance improved by ${diff#-}s (${percent#-}%)"
    return 0
  fi
}

generate_report() {
  print_section "Generating Report"
  
  local diff=$(echo "$MEAN_TIME - $BASELINE_TIME" | bc -l)
  local percent=$(echo "scale=1; ($diff / $BASELINE_TIME) * 100" | bc -l)
  local regression_status="✅ PASS"
  
  if (( $(echo "$diff > $REGRESSION_THRESHOLD" | bc -l) )); then
    regression_status="❌ FAIL - Regression Detected"
  elif (( $(echo "$diff > 0" | bc -l) )); then
    regression_status="⚠️ WARN - Minor Slowdown"
  fi
  
  cat > "$REPORT_FILE" <<EOF
# ZSH Performance Regression Test Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Test Script**: tests/stability/test-performance-regression.zsh
**ZDOTDIR**: ${ZDOTDIR}

## Summary

**Status**: ${regression_status}

- **Baseline Time**: ${BASELINE_TIME}s
- **Current Mean Time**: ${MEAN_TIME}s
- **Difference**: ${diff}s (${percent}%)
- **Regression Threshold**: ${REGRESSION_THRESHOLD}s (10%)

## Detailed Statistics

| Metric | Value |
|--------|-------|
| Mean | ${MEAN_TIME}s |
| Median | ${MEDIAN_TIME}s |
| Min | ${MIN_TIME}s |
| Max | ${MAX_TIME}s |
| Std Dev | ${STD_DEV}s |
| Variance | $(echo "scale=3; $STD_DEV * $STD_DEV" | bc -l)s² |

## Individual Run Times

EOF

  for i in {1..${#TIMING_RESULTS[@]}}; do
    echo "- Run ${i}: ${TIMING_RESULTS[$i]}s" >> "$REPORT_FILE"
  done

  cat >> "$REPORT_FILE" <<EOF

## Performance Analysis

### Comparison to Baseline

- **Baseline**: ${BASELINE_TIME}s (optimized configuration)
- **Current**: ${MEAN_TIME}s
- **Change**: ${diff}s (${percent}%)

EOF

  if (( $(echo "$diff > $REGRESSION_THRESHOLD" | bc -l) )); then
    cat >> "$REPORT_FILE" <<EOF
### ❌ Regression Detected

The current configuration shows a performance regression of ${diff}s (${percent}%), which exceeds the acceptable threshold of ${REGRESSION_THRESHOLD}s (10%).

**Recommended Actions**:
1. Review recent configuration changes
2. Profile plugin loading times
3. Check for new heavy plugins
4. Review startup scripts for inefficiencies
5. Consider deferring non-critical plugin loading

EOF
  elif (( $(echo "$diff > 0" | bc -l) )); then
    cat >> "$REPORT_FILE" <<EOF
### ⚠️ Minor Performance Impact

The current configuration shows a minor slowdown of ${diff}s (${percent}%), which is within the acceptable threshold.

**Note**: This is acceptable but should be monitored. Consider investigating if the trend continues.

EOF
  else
    cat >> "$REPORT_FILE" <<EOF
### ✅ Performance Maintained or Improved

The current configuration performs as well as or better than the baseline, with an improvement of ${diff#-}s (${percent#-}%).

EOF
  fi

  cat >> "$REPORT_FILE" <<EOF

## Conclusion

EOF

  if (( $(echo "$diff > $REGRESSION_THRESHOLD" | bc -l) )); then
    cat >> "$REPORT_FILE" <<EOF
❌ **Performance regression detected.** Please investigate and optimize before proceeding.
EOF
  else
    cat >> "$REPORT_FILE" <<EOF
✅ **Performance is acceptable.** The configuration meets performance requirements.
EOF
  fi

  cat >> "$REPORT_FILE" <<EOF

---

*Generated by: tests/stability/test-performance-regression.zsh*
*Part of: Phase 1, Task 1.2.4 - Configuration Stability Testing*
EOF

  print "  ${GREEN}✓${NC} Report saved to: ${REPORT_FILE}"
}

print_summary() {
  local diff=$(echo "$MEAN_TIME - $BASELINE_TIME" | bc -l)
  
  print ""
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print "${BLUE}  Test Summary${NC}"
  print "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  print ""
  print "  Baseline:     ${BASELINE_TIME}s"
  print "  Current Mean: ${MEAN_TIME}s"
  print "  Difference:   ${diff}s"
  print ""
  
  if (( $(echo "$diff > $REGRESSION_THRESHOLD" | bc -l) )); then
    print "  ${RED}✗ Performance regression detected${NC}"
  elif (( $(echo "$diff > 0" | bc -l) )); then
    print "  ${YELLOW}⚠ Minor slowdown (within threshold)${NC}"
  else
    print "  ${GREEN}✓ Performance maintained or improved${NC}"
  fi
  print ""
  print "  Report: ${REPORT_FILE}"
  print ""
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  print_header
  
  run_performance_tests
  calculate_statistics
  local regression_result=0
  check_regression || regression_result=$?
  
  generate_report
  print_summary
  
  return $regression_result
}

main "$@"

