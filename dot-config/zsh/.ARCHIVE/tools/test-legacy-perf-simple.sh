#!/usr/bin/env bash
set -euo pipefail

echo "=== Legacy Performance Monitoring Module Test ==="
echo "Module: .zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh"
echo ""

# Test script for the zsh subprocess
cat > /tmp/perf_test.zsh << 'ZSH_TEST'
# Set ZDOTDIR to repo path
typeset -gx ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"

# Source the legacy performance module
source "$ZDOTDIR/.zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh"

echo "✅ Module loaded successfully"

# Test 1: Check for basic functions
echo ""
echo "=== Function Availability Test ==="
functions_found=0
expected_functions=("perf_now_ms" "perf_segment_start" "perf_segment_end" "measure_startup_performance" "record_performance_metric")

for func in "${expected_functions[@]}"; do
  if whence -w "$func" >/dev/null 2>&1; then
    echo "✅ $func - found"
    ((functions_found++))
  else
    echo "❌ $func - missing"
  fi
done

echo "Functions found: $functions_found/${#expected_functions[@]}"

# Test 2: Performance timing
echo ""
echo "=== Timing Functions Test ==="
if whence -w perf_now_ms >/dev/null 2>&1; then
  start_time=$(perf_now_ms)
  echo "Current time: ${start_time}ms"
  if [[ "$start_time" =~ ^[0-9]+$ ]]; then
    echo "✅ perf_now_ms returns valid timestamp"
  else
    echo "❌ perf_now_ms returned invalid value"
  fi
else
  echo "❌ perf_now_ms not available"
fi

# Test 3: Segment timing
echo ""
echo "=== Segment Timing Test ==="
if whence -w perf_segment_start >/dev/null 2>&1 && whence -w perf_segment_end >/dev/null 2>&1; then
  perf_segment_start "test_segment"
  sleep 0.01
  duration=$(perf_segment_end "test_segment")
  echo "Test segment duration: ${duration}ms"
  
  if [[ "$duration" =~ ^[0-9]+$ ]] && (( duration >= 5 && duration <= 100 )); then
    echo "✅ Segment timing works correctly"
  else
    echo "❌ Segment timing returned unexpected value: $duration"
  fi
else
  echo "❌ Segment timing functions not available"
fi

# Test 4: Management commands
echo ""
echo "=== Management Commands Test ==="
mgmt_commands=("perf-status" "perf-measure" "perf-test-suite")
mgmt_found=0

for cmd in "${mgmt_commands[@]}"; do
  if whence -w "$cmd" >/dev/null 2>&1; then
    echo "✅ $cmd - available"
    ((mgmt_found++))
  else
    echo "❌ $cmd - missing"
  fi
done

echo "Management commands found: $mgmt_found/${#mgmt_commands[@]}"

# Test 5: System monitoring
echo ""
echo "=== System Monitoring Test ==="
if whence -w system_health_check >/dev/null 2>&1; then
  echo "✅ system_health_check - available"
else
  echo "❌ system_health_check - missing"
fi

# Test 6: Variables and configuration
echo ""
echo "=== Configuration Test ==="
config_vars=("ZSH_PERFORMANCE_MONITORING_VERSION" "_PERFORMANCE_MONITORING_LOADED")
config_found=0

for var in "${config_vars[@]}"; do
  if [[ -n "${(P)var:-}" ]]; then
    echo "✅ $var = ${(P)var}"
    ((config_found++))
  else
    echo "❌ $var - not set"
  fi
done

echo "Configuration variables found: $config_found/${#config_vars[@]}"

# Summary
echo ""
echo "=== Test Summary ==="
total_tests=6
passed_tests=0

(( functions_found >= 3 )) && ((passed_tests++))
[[ "$start_time" =~ ^[0-9]+$ ]] && ((passed_tests++))
(( duration >= 5 && duration <= 100 )) && ((passed_tests++))
(( mgmt_found >= 1 )) && ((passed_tests++))
whence -w system_health_check >/dev/null 2>&1 && ((passed_tests++))
(( config_found >= 1 )) && ((passed_tests++))

echo "Tests passed: $passed_tests/$total_tests"

if (( passed_tests >= 4 )); then
  echo "🎉 Legacy performance monitoring module is working well!"
  exit 0
else
  echo "⚠️ Legacy performance monitoring module needs attention"
  exit 1
fi
ZSH_TEST

# Run the test using Homebrew zsh
/opt/homebrew/bin/zsh -df /tmp/perf_test.zsh
exit_code=$?

# Cleanup
rm -f /tmp/perf_test.zsh

echo ""
echo "Test completed with exit code: $exit_code"
exit $exit_code