#!/usr/bin/env zsh
# .config/zsh/tests/lib/test-framework.zsh
#
# Lightweight but robust test framework for integration tests used by the redesign
# pipeline. Provides:
#  - test counters and summary reporting
#  - test_start / test_pass / test_fail helpers
#  - assertion helpers (eq, ne, file exists, executable, match)
#  - run_with_timeout helper (uses `timeout` if present, falls back to a safe bg monitor)
#  - automatic summary on exit and optional immediate abort on critical failures
#
# Design notes:
#  - This file intentionally avoids `set -e` globally so tests can handle failures
#    via the framework helpers.
#  - Uses zsh features but keeps things portable across common shells where possible.
#
# Usage (example):
#   source tests/lib/test-framework.zsh
#   test_suite_start "my-suite"
#   test_start "should do X"
#   run_with_timeout 10 -- some-command arg1 arg2 || test_fail "cmd failed"
#   assert_eq "expected" "$actual"
#   test_pass
#   test_suite_end
#

# Do not abort script on non-zero by default — framework manages failure accounting.
set -u

# Counters and state (global)
typeset -g TF_TOTAL=0
typeset -g TF_PASSED=0
typeset -g TF_FAILED=0
typeset -g TF_SKIPPED=0
typeset -g TF_CURRENT_NAME=""
typeset -g TF_TEST_START_TS=0
typeset -g TF_SUITE_NAME=""
typeset -g TF_FAILURES=()    # list of failure messages
typeset -g TF_VERBOSE=${TF_VERBOSE:-0}
typeset -g TF_ABORT_ON_FAIL=${TF_ABORT_ON_FAIL:-0} # if 1, abort on first failure

# Timestamp helpers
_now_ts() {
  date -u +%s 2>/dev/null || perl -e 'print time'
}
_now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || perl -e 'print scalar gmtime()'
}

# Internal: print if verbose
_tf_log() {
  if (( TF_VERBOSE )); then
    printf "%s [framework] %s\n" "$(_now_iso)" "$*" >&2
  fi
}

# Start a test suite
test_suite_start() {
  TF_SUITE_NAME="${1:-unnamed-suite}"
  TF_TOTAL=0; TF_PASSED=0; TF_FAILED=0; TF_SKIPPED=0
  TF_FAILURES=()
  TF_SUITE_START_TS=$(_now_ts)
  printf "\n===== TEST SUITE START: %s (%s) =====\n" "${TF_SUITE_NAME}" "$(_now_iso)"
  # Ensure we print a summary on exit if the caller forgets
  # trap 'test_framework_summary; exit $(( TF_FAILED > 0 ? 1 : 0 ))' EXIT INT TERM
}

# Start a single test
test_start() {
  TF_CURRENT_NAME="${*}"
  TF_TEST_START_TS=$(_now_ts)
  (( TF_TOTAL++ ))
  printf "\n[TEST] START: %s\n" "${TF_CURRENT_NAME}"
}

# Mark current test as passed
test_pass() {
  local msg="${*:-OK}"
  (( TF_PASSED++ ))
  printf "[TEST] PASS: %s -- %s\n" "${TF_CURRENT_NAME}" "${msg}"
  TF_CURRENT_NAME=""
  TF_TEST_START_TS=0
}

# Mark current test as failed
test_fail() {
  local msg="${*:-FAILED}"
  (( TF_FAILED++ ))
  TF_FAILURES+=("${TF_CURRENT_NAME}: ${msg}")
  printf "[TEST] FAIL: %s -- %s\n" "${TF_CURRENT_NAME}" "${msg}" >&2
  TF_CURRENT_NAME=""
  TF_TEST_START_TS=0
  if (( TF_ABORT_ON_FAIL )); then
    test_framework_summary
    exit 1
  fi
  return 1
}

# Mark current test as skipped
test_skip() {
  local reason="${*:-skipped}"
  (( TF_SKIPPED++ ))
  printf "[TEST] SKIP: %s -- %s\n" "${TF_CURRENT_NAME}" "${reason}"
  TF_CURRENT_NAME=""
  TF_TEST_START_TS=0
}

# Assertions --------------------------------------------------------------

# assert_eq <expected> <actual> [message]
assert_eq() {
  local expected="$1"; local actual="$2"; shift 2
  local msg="${*:-expected == actual}"
  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    test_fail "assert_eq failed: ${msg} (expected='${expected}' actual='${actual}')"
    return 1
  fi
}

# assert_ne <not_expected> <actual> [message]
assert_ne() {
  local not_expected="$1"; local actual="$2"; shift 2
  local msg="${*:-expected != actual}"
  if [[ "$not_expected" != "$actual" ]]; then
    return 0
  else
    test_fail "assert_ne failed: ${msg} (not_expected='${not_expected}' actual='${actual}')"
    return 1
  fi
}

# assert_file_exists <path>
assert_file_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    return 0
  else
    test_fail "file not found: $f"
    return 1
  fi
}

# assert_executable <path>
assert_executable() {
  local f="$1"
  if [[ -x "$f" ]]; then
    return 0
  else
    test_fail "not executable: $f"
    return 1
  fi
}

# assert_match <regex> <string>
assert_match() {
  local re="$1"; local s="$2"
  if [[ "$s" =~ $re ]]; then
    return 0
  else
    test_fail "assert_match failed: pattern '$re' not found in '$s'"
    return 1
  fi
}

# Utility: run command with timeout
# Usage: run_with_timeout <seconds> -- <cmd> [args...]
# Returns the underlying command exit code, or 124 on timeout, 125 on killing failure.
run_with_timeout() {
  if [[ $# -lt 2 ]]; then
    printf "run_with_timeout usage: run_with_timeout <secs> -- <cmd...>\n" >&2
    return 2
  fi
  local secs="$1"; shift
  if [[ "$1" = "--" ]]; then shift; fi
  local cmd=( "$@" )
  # If `timeout` exists, prefer it
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs"s "${cmd[@]}"
    return $?
  fi
  # Fallback implementation: run in background, monitor and kill after timeout
  local outpid
  "${cmd[@]}" &
  outpid=$!
  local start ts now elapsed
  start=$(_now_ts)
  while kill -0 "$outpid" 2>/dev/null; do
    now=$(_now_ts)
    elapsed=$(( now - start ))
    if (( elapsed >= secs )); then
      kill -TERM "$outpid" 2>/dev/null || kill -KILL "$outpid" 2>/dev/null || true
      # wait a bit for process to exit
      sleep 0.1
      if kill -0 "$outpid" 2>/dev/null; then
        kill -KILL "$outpid" 2>/dev/null || true
        return 125
      fi
      return 124
    fi
    sleep 0.05
  done
  wait "$outpid" 2>/dev/null || return $?
  return $?
}

# Helper: run command and capture stdout/stderr into variables or files
# Usage: run_capture <output-file> -- <cmd...>
run_capture() {
  if [[ $# -lt 2 ]]; then
    printf "run_capture usage: run_capture <out-file> -- <cmd...>\n" >&2
    return 2
  fi
  local outfile="$1"; shift
  if [[ "$1" = "--" ]]; then shift; fi
  "${@}" >"$outfile" 2>&1
  return $?
}

# Summary reporting -------------------------------------------------------

test_framework_summary() {
  local end_ts=$(_now_ts)
  local elapsed=$(( end_ts - TF_SUITE_START_TS ))
  printf "\n===== TEST SUITE SUMMARY: %s =====\n" "${TF_SUITE_NAME:-unnamed}"
  printf "Total: %d, Passed: %d, Failed: %d, Skipped: %d\n" "$TF_TOTAL" "$TF_PASSED" "$TF_FAILED" "$TF_SKIPPED"
  printf "Elapsed: %ds\n" "${elapsed}"
  if (( TF_FAILED > 0 )); then
    printf "\nFailures:\n" >&2
    for f in "${TF_FAILURES[@]}"; do
      printf " - %s\n" "$f" >&2
    done
  else
    printf "All tests passed ✓\n"
  fi
  printf "========================================\n\n"
}

# Convenience: end the suite explicitly
test_suite_end() {
  local passed="$TF_PASSED"
  local total="$TF_TOTAL"
  test_framework_summary
  # reset the EXIT trap so the summary isn't printed twice
  trap - EXIT INT TERM
  return $(( TF_FAILED > 0 ? 1 : 0 ))
}

# Small helper to conditionally skip tests for platform-specific reasons
test_skip_if() {
  local cond="$1"; shift
  if eval "$cond"; then
    test_skip "$*"
    return 0
  fi
  return 1
}

# Export functions for subshells (if zsh supports it)
if typeset -f >/dev/null 2>&1; then
  export -f test_start test_pass test_fail test_skip test_skip_if test_suite_start test_suite_end \
           assert_eq assert_ne assert_file_exists assert_executable assert_match \
           run_with_timeout run_capture test_framework_summary >/dev/null 2>&1 || true
fi

# End of test framework shim
