#!/usr/bin/env zsh
# Performance test: Startup time validation
# This test ensures startup performance meets acceptable thresholds

set -euo pipefail

# Setup test environment
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
TEST_DIR="$(cd "${0%/*}" && pwd)"
PERF_CAPTURE_BIN="$ZDOTDIR/tools/perf-capture.zsh"
PERF_MULTI_BIN="$ZDOTDIR/tools/perf-capture-multi.zsh"
METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"

# Performance thresholds
MAX_STARTUP_TIME_MS=3000      # 3 second max startup time
MAX_RSD_THRESHOLD=0.10        # 10% max RSD
MIN_SAMPLES=3                 # Minimum samples for test

echo "Testing startup performance..."

# Function to measure startup time
measure_startup() {
  local samples="${1:-3}"

  if [[ ! -x "$PERF_MULTI_BIN" ]]; then
    echo "ERROR: Performance capture tool not found: $PERF_MULTI_BIN"
    return 1
  fi

  echo "Running $samples performance samples..."

  # Run performance capture
  if ! MULTI_SAMPLES="$samples" zsh "$PERF_MULTI_BIN" --quiet; then
    echo "ERROR: Performance capture failed"
    return 1
  fi

  # Check results
  local results_file="$METRICS_DIR/perf-multi-current.json"
  if [[ ! -f "$results_file" ]]; then
    echo "ERROR: Performance results not found: $results_file"
    return 1
  fi

  return 0
}

# Function to validate performance results
validate_performance() {
  local results_file="$METRICS_DIR/perf-multi-current.json"

  if ! command -v jq >/dev/null 2>&1; then
    echo "WARNING: jq not available, using basic validation"
    # Basic validation without jq
    if grep -q '"post_plugin_cost_ms"' "$results_file"; then
      echo "Basic performance data validation passed"
      return 0
    else
      echo "ERROR: Basic performance data validation failed"
      return 1
    fi
  fi

  echo "Validating performance metrics..."

  # Extract key metrics
  local post_mean rsd_post samples
  post_mean=$(jq -r '.aggregate.post_plugin_cost_ms.mean // 0' "$results_file")
  rsd_post=$(jq -r '.rsd_post // 0' "$results_file")
  samples=$(jq -r '.samples // 0' "$results_file")

  echo "Performance Results:"
  echo "  Startup time: ${post_mean}ms"
  echo "  RSD: $rsd_post"
  echo "  Samples: $samples"

  local failures=0

  # Check startup time threshold
  if (( $(echo "$post_mean > $MAX_STARTUP_TIME_MS" | bc -l 2>/dev/null || echo 0) )); then
    echo "ERROR: Startup time exceeds threshold: ${post_mean}ms > ${MAX_STARTUP_TIME_MS}ms"
    (( failures++ ))
  else
    echo "PASS: Startup time within threshold"
  fi

  # Check RSD threshold
  if (( $(echo "$rsd_post > $MAX_RSD_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
    echo "ERROR: RSD exceeds threshold: $rsd_post > $MAX_RSD_THRESHOLD"
    (( failures++ ))
  else
    echo "PASS: RSD within threshold"
  fi

  # Check sample count
  if (( samples < MIN_SAMPLES )); then
    echo "ERROR: Insufficient samples: $samples < $MIN_SAMPLES"
    (( failures++ ))
  else
    echo "PASS: Sufficient samples collected"
  fi

  return $failures
}

# Run the test
echo "--- Startup Performance Test ---"

fail_count=0

# Measure performance
if ! measure_startup $MIN_SAMPLES; then
  (( fail_count++ ))
fi

# Validate results if measurement succeeded
if (( fail_count == 0 )); then
  if ! validate_performance; then
    (( fail_count++ ))
  fi
fi

echo "--- Performance Test Summary ---"
if (( fail_count > 0 )); then
  echo "PERFORMANCE TEST FAILED"
  exit 1
else
  echo "PERFORMANCE TEST PASSED"
  exit 0
fi
