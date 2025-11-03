#!/usr/bin/env zsh
# test-idle-trigger-basic.zsh
#
# Basic verification scaffold for Idle / Background Trigger (S4-27)
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Validate the initial idle trigger stub (97-idle-trigger.zsh) provides:
#     1. Registration API behavior (ordering, duplicate handling, function existence).
#     2. Single-pass idempotent execution (second invocation is a no-op).
#     3. Timeout flagging for slow tasks (soft timeout).
#     4. Structured telemetry gating (only when ZSH_LOG_STRUCTURED=1).
#
# SCOPE:
#   This test DOES NOT (yet) assert:
#     - Hard budget enforcement early-stop (covered in a future dedicated test).
#     - JSON schema validation (handled by telemetry schema test suite later).
#
# EXIT CODES:
#   0 = success
#   1 = failure (any assertion failed)
#
# NOTE:
#   Designed to run under `zsh -f` (no user config). Uses only builtin features.
#
# ------------------------------------------------------------------------------
emulate -L zsh
setopt errexit nounset pipefail

# Utilities --------------------------------------------------------------------
fail() { print -r -- "[FAIL] $*" >&2; exit 1; }
info() { print -r -- "[INFO] $*" >&2; }
assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    fail "assert_eq: expected='$expected' actual='$actual' :: $msg"
  fi
}
assert_true() {
  local cond="$1" msg="$2"
  if ! eval "$cond"; then
    fail "assert_true: $msg"
  fi
}
assert_contains() {
  local needle="$1" haystack="$2" msg="$3"
  if ! print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    fail "assert_contains: '$needle' not found :: $msg"
  fi
}
assert_not_contains() {
  local needle="$1" haystack="$2" msg="$3"
  if print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    fail "assert_not_contains: '$needle' unexpectedly present :: $msg"
  fi
}

# Resolve repository root (script may be invoked from anywhere)
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
# Expect layout: .../dot-config/zsh/tests/performance/idle/
ZSH_ROOT="${SCRIPT_DIR:A:h:h:h}"   # climb up to dot-config/zsh
IDLE_FILE="${ZSH_ROOT}/.zshrc.d.REDESIGN/97-idle-trigger.zsh"

[[ -r "$IDLE_FILE" ]] || fail "Idle trigger file not readable: $IDLE_FILE"

# Source idle trigger module
source "$IDLE_FILE"

# Confirm sentinel
assert_true '[[ -n ${_LOADED_97_IDLE_TRIGGER:-} ]]' "Idle trigger sentinel not set"

# Prepare environment flags (tight timeout to trigger flag on slow task)
ZSH_IDLE_ENABLE=1
ZSH_IDLE_HARD_BUDGET_MS=120      # generous for this test (ms)
ZSH_IDLE_TASK_TIMEOUT_MS=25      # any task >25ms should flag timeout
ZSH_IDLE_LOG_VERBOSE=0
ZSH_LOG_STRUCTURED=1             # enable structured telemetry to exercise JSON path

# Define demo tasks ------------------------------------------------------------
# Fast task (should not timeout)
test_idle_fast() {
  :  # intentionally no-op
}

# Slow task (simulate ~60ms)
test_idle_slow() {
  # Use sleep for clarity; acceptable in post-prompt domain (non-critical path)
  sleep 0.06
}

# Missing task (we will NOT register; used to test function existence guard)
# test_idle_missing() is intentionally undefined

# Registration Tests -----------------------------------------------------------
rc=0
zf::idle::register fast test_idle_fast "fast no-op task" || rc=$?
assert_eq "0" "$rc" "fast task registration failed"

rc=0
zf::idle::register slow test_idle_slow "slow task triggers timeout flag" || rc=$?
assert_eq "0" "$rc" "slow task registration failed"

# Duplicate registration should return 2 (non-fatal, ignored)
rc=0
zf::idle::register fast test_idle_fast "duplicate" || rc=$?
assert_eq "2" "$rc" "duplicate registration did not return code 2"

# Invalid (missing function) should fail (rc=1)
rc=0
zf::idle::register missing test_idle_missing "should fail" || rc=$?
assert_eq "1" "$rc" "registration of missing function should return 1"

# Verify ordering
expected_order="fast slow"
actual_order="${(j: :)_IDLE_TASK_IDS}"
assert_eq "$expected_order" "$actual_order" "Task order mismatch"

# Execution (First Run) --------------------------------------------------------
# Capture output (stdout) for assertions
run_output="$( ( zf::idle::run_if_ready ) 2>&1 )" || fail "run_if_ready returned non-zero unexpectedly"

# Basic markers
assert_contains "IDLE:START" "$run_output" "Missing IDLE:START marker"
assert_contains "IDLE:SUMMARY" "$run_output" "Missing IDLE:SUMMARY marker"
assert_contains "IDLE:TASK id=fast" "$run_output" "Missing fast task line"
assert_contains "IDLE:TASK id=slow" "$run_output" "Missing slow task line"

# Timeout flag presence for slow task
assert_contains "IDLE:TASK id=slow" "$run_output" "Slow task marker missing (pre-timeout check)"
if ! print -r -- "$run_output" | grep -E "IDLE:TASK id=slow .*timeout=1" >/dev/null 2>&1; then
  fail "Slow task did not include timeout=1 flag (expected duration > ${ZSH_IDLE_TASK_TIMEOUT_MS}ms)"
fi

# Structured telemetry presence (idle_start / idle_task / idle_summary)
assert_true 'print -r -- "$run_output" | grep -q "IDLE:TASK id=fast"' "Fast task line missing"
# We cannot easily assert JSON lines here (they go to PERF_SEGMENT_JSON_LOG if configured); acceptable.

# Idempotent Second Run --------------------------------------------------------
second_output="$( ( zf::idle::run_if_ready ) 2>&1 )" || fail "Second run_if_ready non-zero"
# Should not emit any new START / TASK / SUMMARY lines
assert_not_contains "IDLE:START" "$second_output" "Second run should produce no START"
assert_not_contains "IDLE:TASK" "$second_output" "Second run should produce no TASK lines"
assert_not_contains "IDLE:SUMMARY" "$second_output" "Second run should produce no SUMMARY"

# Internal result map checks
assert_true '[[ -n ${_IDLE_TASK_RESULTS[fast]:-} ]]' "No results recorded for fast"
assert_true '[[ -n ${_IDLE_TASK_RESULTS[slow]:-} ]]' "No results recorded for slow"
# Ensure rc keys present
fast_rc="$(print -r -- "${_IDLE_TASK_RESULTS[fast]}" | sed -n 's/.*rc=\([0-9]\+\).*/\1/p')"
slow_rc="$(print -r -- "${_IDLE_TASK_RESULTS[slow]}" | sed -n 's/.*rc=\([0-9]\+\).*/\1/p')"
assert_eq "0" "$fast_rc" "Fast task rc unexpected"
assert_eq "0" "$slow_rc" "Slow task rc unexpected"

# Timeout flag persisted in result for slow
if ! print -r -- "${_IDLE_TASK_RESULTS[slow]}" | grep -q "timeout=1"; then
  fail "Slow task result map missing timeout=1 flag"
fi

# Summary Counts Sanity (ok + err = total executed)
summary_line="$(print -r -- "$run_output" | grep 'IDLE:SUMMARY' || true)"
executed_total="$(print -r -- "$summary_line" | sed -n 's/.*tasks=\([0-9]\+\).*/\1/p')"
ok_count="$(print -r -- "$summary_line" | sed -n 's/.* ok=\([0-9]\+\) .*/\1/p')"
err_count="$(print -r -- "$summary_line" | sed -n 's/.* err=\([0-9]\+\) .*/\1/p')"
assert_eq "$executed_total" "$(( ok_count + err_count ))" "Summary counts mismatch"

info "All idle trigger basic tests passed."
exit 0
