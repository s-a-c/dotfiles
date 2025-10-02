#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$REPO"

ZDOTDIR="${ZDOTDIR:-$REPO}"
export ZDOTDIR

LOG_DIR="$ZDOTDIR/logs"
TEST_OUT="$LOG_DIR/test-results"
mkdir -p "$LOG_DIR" "$TEST_OUT"

# Legacy module environment (no redesign flags)
export PERF_SEGMENT_TRACE="${PERF_SEGMENT_TRACE:-1}"
export PERF_PROMPT_HARNESS="${PERF_PROMPT_HARNESS:-1}"
export PERF_CAPTURE_FAST="${PERF_CAPTURE_FAST:-1}"
export SELFTEST_HARD_FAIL="${SELFTEST_HARD_FAIL:-1}"
export PERF_SEGMENT_LOG="${PERF_SEGMENT_LOG:-$LOG_DIR/perf-current.log}"

# Legacy consolidated module path
LEGACY_MODULE="$REPO/.zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh"

if [[ ! -f "$LEGACY_MODULE" ]]; then
  echo "ERROR: Legacy consolidated performance monitoring module not found: $LEGACY_MODULE" >&2
  exit 2
fi

echo "Testing Legacy Consolidated Performance Monitoring Module"
echo "========================================================="
echo "Module: $LEGACY_MODULE"
echo "ZDOTDIR: $ZDOTDIR"
echo "Test logs: $TEST_OUT"
echo ""

RUN_LOG="$TEST_OUT/legacy-perf-module-test-$(date +%Y%m%dT%H%M%S).log"
JSON_OUT="$TEST_OUT/legacy-perf-module-selftest-$(date +%Y%m%dT%H%M%S).json"

# Run a zsh harness in no-rc mode to avoid user/global initialization
LEGACY_MODULE="$LEGACY_MODULE" JSON_OUT="$JSON_OUT" REPO_ZDOTDIR="$ZDOTDIR" PERF_SEGMENT_LOG="$PERF_SEGMENT_LOG" \
/opt/homebrew/bin/zsh -df <<'ZSH_EOF' 2>&1 | tee -a "$RUN_LOG"
emulate -L zsh -o no_unset
rpt() { print -r -- "TEST:$1:$2:$3"; }
exists() { whence -w "$1" >/dev/null 2>&1; }

# Force ZDOTDIR to the repo-local path inside the sub-shell
typeset -gx ZDOTDIR="$REPO_ZDOTDIR"

print "Starting legacy performance monitoring module test..."
print "Module: $LEGACY_MODULE"
print "ZDOTDIR: $ZDOTDIR"

# Source the performance module
if [[ -r "$LEGACY_MODULE" ]]; then
  source "$LEGACY_MODULE"
  rpt INFO "module_loaded" "$LEGACY_MODULE"
else
  rpt FAIL "module_not_readable" "$LEGACY_MODULE"
  exit 1
fi

# Enumerate exported functions likely related to perf/segment/timer
mkdir -p "$ZDOTDIR/logs/test-results"
{
  for n in ${(ok)functions}; do
    if [[ "$n" == (perf_*|*_perf|*segment*|*timer*|measure_*|quick_*|*-status|*-measure|*-test*|system_*) ]]; then
      print -r -- "$n"
    fi
  done
} > "$ZDOTDIR/logs/test-results/legacy-perf-functions.txt"
rpt INFO "functions_listed" "$ZDOTDIR/logs/test-results/legacy-perf-functions.txt"

# Ensure logs directory and primary perf log exists
mkdir -p -- "$ZDOTDIR/logs"
[[ -e "$PERF_SEGMENT_LOG" ]] || : >| "$PERF_SEGMENT_LOG"
[[ -d "$ZDOTDIR/logs" ]] && rpt PASS "dir_logs" "$ZDOTDIR/logs" || rpt FAIL "dir_logs" "$ZDOTDIR/logs"
[[ -f "$PERF_SEGMENT_LOG" ]] && rpt PASS "file_perf_log" "$PERF_SEGMENT_LOG" || rpt FAIL "file_perf_log" "$PERF_SEGMENT_LOG"

# Test for module self-test function
typeset -i rc=1 ran=0
local -a selftests
selftests=( test_performance_monitoring perf_selftest performance_selftest legacy_perf_selftest )
local fn
for fn in $selftests; do
  if exists "$fn"; then
     rpt INFO "selftest_running" "$fn"
     if "$fn" >/dev/null 2>&1; then
       rpt PASS "selftest_ok" "$fn"
       ran=1 rc=0
       break
     else
       rc=$?
       rpt FAIL "selftest_rc" "$fn:$rc"
       ran=1
       break
     fi
  fi
done

# If no built-in self-test, check basic function availability
if (( ran == 0 )); then
  rpt INFO "selftest_fallback" "checking_basic_functions"
  local basic_functions=0
  
  # Check key performance functions exist
  for func in perf_now_ms record_performance_metric measure_startup_performance perf_segment_start perf_segment_end; do
    if exists "$func"; then
      ((basic_functions++))
      rpt PASS "basic_function" "$func"
    else
      rpt FAIL "basic_function" "$func"
    fi
  done
  
  if (( basic_functions >= 3 )); then
    rpt PASS "basic_functions_available" "$basic_functions/5"
    rc=0
  else
    rpt FAIL "basic_functions_available" "$basic_functions/5"
    rc=1
  fi
fi

# Timing utilities checks
typeset -i ok_any=0
if exists perf_now_ms; then
  local t="$(perf_now_ms)"
  if [[ -n "$t" && "$t" =~ ^[0-9]+$ ]]; then
    rpt PASS "perf_now_ms" "$t"
    ok_any=1
  else
    rpt FAIL "perf_now_ms" "invalid:$t"
  fi
fi

# Test segment timing
if exists perf_segment_start && exists perf_segment_end; then
  perf_segment_start "test_segment"
  sleep 0.01
  local duration="$(perf_segment_end "test_segment")"
  if [[ -n "$duration" && "$duration" =~ ^[0-9]+$ ]]; then
    rpt PASS "segment_cycle" "test_segment:${duration}ms"
    ok_any=1
  else
    rpt FAIL "segment_cycle" "invalid_duration:$duration"
  fi
fi

# Test startup measurement functions
typeset -i started=0
if exists measure_startup_performance; then
  local startup_time="$(measure_startup_performance 1 "test")"
  if [[ -n "$startup_time" && "$startup_time" =~ ^[0-9]+$ ]]; then
    rpt PASS "startup_measure" "measure_startup_performance:${startup_time}ms"
    started=1
  else
    rpt FAIL "startup_measure" "measure_startup_performance:invalid:$startup_time"
  fi
elif exists quick_startup_test; then
  # Try the quick test command
  if quick_startup_test 1 >/dev/null 2>&1; then
    rpt PASS "startup_measure" "quick_startup_test"
    started=1
  else
    rpt FAIL "startup_measure" "quick_startup_test"
  fi
fi

# Fallback startup measurement
if (( started == 0 )); then
  export TIMEFMT=$'%U user %S sys %P cpu %*E total'
  if ZDOTDIR="$ZDOTDIR" timeout 10 time /opt/homebrew/bin/zsh -i -c exit >/dev/null 2>&1; then
     rpt PASS "startup_measure_fallback" "time /opt/homebrew/bin/zsh -i -c exit"
  else
     rpt FAIL "startup_measure_fallback" "time failed"
  fi
fi

# Test performance management commands
local -a mgmt_commands=( perf-status perf-measure perf-test-suite )
local mgmt_available=0
for cmd in "${mgmt_commands[@]}"; do
  if exists "$cmd"; then
    rpt PASS "mgmt_command" "$cmd"
    ((mgmt_available++))
  else
    rpt FAIL "mgmt_command" "$cmd"
  fi
done
rpt INFO "mgmt_commands_available" "$mgmt_available/${#mgmt_commands[@]}"

# Test system monitoring
if exists system_health_check; then
  if system_health_check >/dev/null 2>&1; then
    rpt PASS "system_monitoring" "system_health_check"
  else
    rpt FAIL "system_monitoring" "system_health_check"
  fi
fi

# Test metrics recording
if exists record_performance_metric; then
  record_performance_metric "test_metric" "100" "test_context"
  rpt PASS "metrics_recording" "record_performance_metric"
fi

# Log write check
print -r -- "legacy segment test $(date +%s)" >> "$PERF_SEGMENT_LOG" || true
[[ -s "$PERF_SEGMENT_LOG" ]] && rpt PASS "perf_log_nonempty" "$PERF_SEGMENT_LOG" || rpt FAIL "perf_log_nonempty" "$PERF_SEGMENT_LOG"

# Check for essential variables/arrays
local -a essential_vars=( ZSH_PERFORMANCE_MONITORING_VERSION _PERFORMANCE_MONITORING_LOADED )
for var in "${essential_vars[@]}"; do
  if [[ -n "${(P)var:-}" ]]; then
    rpt PASS "essential_var" "$var=${(P)var}"
  else
    rpt FAIL "essential_var" "$var"
  fi
done

# Check timing precision
(( ok_any == 1 )) || rpt FAIL "timing_api" "no-working-functions"

echo ""
echo "Legacy Performance Monitoring Module Test Complete"
exit $rc
ZSH_EOF

status=${PIPESTATUS[0]}
echo ""
echo "Harness exit status: $status"

# Show test summary
echo ""
echo "Test Summary:"
echo "============="
if [[ -f "$RUN_LOG" ]]; then
  pass_count=$(grep -c '^TEST:PASS:' "$RUN_LOG" || true)
  fail_count=$(grep -c '^TEST:FAIL:' "$RUN_LOG" || true)
  echo "Pass count: ${pass_count:-0}"
  echo "Fail count: ${fail_count:-0}"
  echo ""
  echo "Failed tests:"
  grep '^TEST:FAIL:' "$RUN_LOG" | sed 's/^TEST:FAIL:/  ❌ /' || echo "  None"
  echo ""
  echo "Key successes:"
  grep '^TEST:PASS:' "$RUN_LOG" | grep -E "(module_loaded|perf_now_ms|segment_cycle|startup_measure|mgmt_command)" | sed 's/^TEST:PASS:/  ✅ /' | head -5 || echo "  None"
fi

echo ""
echo "Full log: $RUN_LOG"
echo "Functions exported: $ZDOTDIR/logs/test-results/legacy-perf-functions.txt"

exit "$status"
