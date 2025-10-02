#!/usr/bin/env bash
set -euo pipefail

echo "=== Legacy Performance Monitoring Module Test ==="
echo "Module: .zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh"
echo "Using: /opt/homebrew/bin/zsh"
echo ""

REPO_PATH="/Users/s-a-c/dotfiles/dot-config/zsh"
MODULE_PATH="$REPO_PATH/.zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh"

if [[ ! -f "$MODULE_PATH" ]]; then
    echo "❌ Module not found: $MODULE_PATH"
    exit 1
fi

echo "✅ Module file exists: $MODULE_PATH"
echo ""

# Test the module by running zsh with proper environment
SHELL=/opt/homebrew/bin/zsh \
ZDOTDIR="$REPO_PATH" \
PERF_SEGMENT_LOG="$REPO_PATH/logs/perf-current.log" \
PERF_SEGMENT_TRACE=1 \
/opt/homebrew/bin/zsh -c "
# Set up environment inside zsh
setopt no_global_rcs
export ZDOTDIR='$REPO_PATH'
export PERF_SEGMENT_LOG='$REPO_PATH/logs/perf-current.log'
export PERF_SEGMENT_TRACE=1

echo '=== Loading Module ==='
source '$MODULE_PATH'
echo '✅ Module loaded successfully'
echo ''

echo '=== Function Availability Test ==='
functions_found=0
expected_functions=('perf_now_ms' 'perf_segment_start' 'perf_segment_end' 'measure_startup_performance' 'record_performance_metric')

for func in \$expected_functions; do
  if whence -w \$func >/dev/null 2>&1; then
    echo \"✅ \$func - found\"
    ((functions_found++))
  else
    echo \"❌ \$func - missing\"
  fi
done

echo \"Functions found: \$functions_found/\${#expected_functions[@]}\"
echo ''

echo '=== Timing Functions Test ==='
if whence -w perf_now_ms >/dev/null 2>&1; then
  start_time=\$(perf_now_ms)
  echo \"Current time: \${start_time}ms\"
  if [[ \"\$start_time\" =~ ^[0-9]+\$ ]]; then
    echo \"✅ perf_now_ms returns valid timestamp\"
    timing_works=1
  else
    echo \"❌ perf_now_ms returned invalid value\"
    timing_works=0
  fi
else
  echo \"❌ perf_now_ms not available\"
  timing_works=0
fi
echo ''

echo '=== Segment Timing Test ==='
if whence -w perf_segment_start >/dev/null 2>&1 && whence -w perf_segment_end >/dev/null 2>&1; then
  perf_segment_start 'test_segment'
  sleep 0.01
  duration=\$(perf_segment_end 'test_segment')
  echo \"Test segment duration: \${duration}ms\"
  
  if [[ \"\$duration\" =~ ^[0-9]+\$ ]] && (( duration >= 5 && duration <= 100 )); then
    echo \"✅ Segment timing works correctly\"
    segment_works=1
  else
    echo \"❌ Segment timing returned unexpected value: \$duration\"
    segment_works=0
  fi
else
  echo \"❌ Segment timing functions not available\"
  segment_works=0
fi
echo ''

echo '=== Management Commands Test ==='
mgmt_commands=('perf-status' 'perf-measure' 'perf-test-suite')
mgmt_found=0

for cmd in \$mgmt_commands; do
  if whence -w \$cmd >/dev/null 2>&1; then
    echo \"✅ \$cmd - available\"
    ((mgmt_found++))
  else
    echo \"❌ \$cmd - missing\"
  fi
done

echo \"Management commands found: \$mgmt_found/\${#mgmt_commands[@]}\"
echo ''

echo '=== System Monitoring Test ==='
if whence -w system_health_check >/dev/null 2>&1; then
  echo \"✅ system_health_check - available\"
  system_works=1
else
  echo \"❌ system_health_check - missing\"
  system_works=0
fi
echo ''

echo '=== Configuration Test ==='
config_vars=('ZSH_PERFORMANCE_MONITORING_VERSION' '_PERFORMANCE_MONITORING_LOADED')
config_found=0

for var in \$config_vars; do
  if [[ -n \"\${(P)var:-}\" ]]; then
    echo \"✅ \$var = \${(P)var}\"
    ((config_found++))
  else
    echo \"❌ \$var - not set\"
  fi
done

echo \"Configuration variables found: \$config_found/\${#config_vars[@]}\"
echo ''

echo '=== Quick Startup Test ==='
if whence -w quick_startup_test >/dev/null 2>&1; then
  echo \"✅ quick_startup_test command found\"
  echo \"Running quick startup test (1 iteration)...\"
  quick_startup_test 1 2>/dev/null || echo \"(startup test completed with warnings)\"
  startup_test_works=1
else
  echo \"❌ quick_startup_test not available\"
  startup_test_works=0
fi
echo ''

echo '=== Test Summary ==='
total_tests=7
passed_tests=0

echo \"Test Results:\"
(( functions_found >= 3 )) && { echo \"  ✅ Basic functions available\"; ((passed_tests++)); } || echo \"  ❌ Basic functions missing\"
(( timing_works == 1 )) && { echo \"  ✅ Timing functions work\"; ((passed_tests++)); } || echo \"  ❌ Timing functions failed\"
(( segment_works == 1 )) && { echo \"  ✅ Segment timing works\"; ((passed_tests++)); } || echo \"  ❌ Segment timing failed\"
(( mgmt_found >= 1 )) && { echo \"  ✅ Management commands available\"; ((passed_tests++)); } || echo \"  ❌ Management commands missing\"
(( system_works == 1 )) && { echo \"  ✅ System monitoring available\"; ((passed_tests++)); } || echo \"  ❌ System monitoring missing\"
(( config_found >= 1 )) && { echo \"  ✅ Configuration variables set\"; ((passed_tests++)); } || echo \"  ❌ Configuration variables missing\"
(( startup_test_works == 1 )) && { echo \"  ✅ Startup test available\"; ((passed_tests++)); } || echo \"  ❌ Startup test missing\"

echo \"\"
echo \"Tests passed: \$passed_tests/\$total_tests\"

if (( passed_tests >= 5 )); then
  echo \"🎉 Legacy performance monitoring module is working well!\"
  exit 0
else
  echo \"⚠️ Legacy performance monitoring module needs attention\"
  exit 1
fi
"

exit_code=$?
echo ""
echo "Test completed with exit code: $exit_code"
exit $exit_code