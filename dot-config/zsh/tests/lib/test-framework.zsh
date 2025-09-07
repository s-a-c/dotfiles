#!/usr/bin/env zsh
# Minimal test framework for integration tests
#
# Provides lightweight functions used by integration scripts:
#   - test_suite_start <name>
#   - test_suite_end <passed> <total>
#   - test_start <name>
#   - test_pass [message]
#   - test_fail [message]
#   - test_warn [message]
#   - test_info [message]
#   - run_with_timeout <seconds> -- <cmd...>
#
# This file intentionally avoids `set -e` so test helpers may return non-zero
# without aborting the caller; callers can decide how to handle failures.

# Print with timestamp
_tf_ts() {
  printf '%s' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

test_suite_start() {
  local name="${1:-unnamed}"
  printf "%s [TEST-SUITE] START: %s\n" "$(_tf_ts)" "$name"
}

test_suite_end() {
  local passed="${1:-0}"
  local total="${2:-0}"
  printf "%s [TEST-SUITE] END: passed=%s/%s\n" "$(_tf_ts)" "$passed" "$total"
}

test_start() {
  local name="${*:-test}"
  printf "%s [TEST] START: %s\n" "$(_tf_ts)" "$name"
}

test_pass() {
  local msg="${*:-ok}"
  printf "%s [TEST] PASS: %s\n" "$(_tf_ts)" "$msg"
  return 0
}

test_fail() {
  local msg="${*:-failed}"
  printf "%s [TEST] FAIL: %s\n" "$(_tf_ts)" "$msg" >&2
  return 1
}

test_warn() {
  local msg="${*:-warning}"
  printf "%s [TEST] WARN: %s\n" "$(_tf_ts)" "$msg" >&2
}

test_info() {
  local msg="${*:-info}"
  printf "%s [TEST] INFO: %s\n" "$(_tf_ts)" "$msg"
}

# Simple assertion helpers ---------------------------------------------------

# assert_file_exists <path>
assert_file_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    return 0
  else
    test_fail "expected file exists: $f"
    return 1
  fi
}

# assert_executable <path>
assert_executable() {
  local f="$1"
  if [[ -x "$f" ]]; then
    return 0
  else
    test_fail "expected executable: $f"
    return 1
  fi
}

# assert_eq <expected> <actual>
assert_eq() {
  local expect="$1"
  local actual="$2"
  if [[ "$expect" == "$actual" ]]; then
    return 0
  else
    test_fail "assert_eq failed: expected='$expect' actual='$actual'"
    return 1
  fi
}

# run_with_timeout <seconds> -- <cmd...>
# Uses `timeout` if available; otherwise runs the command directly.
run_with_timeout() {
  if [[ $# -lt 2 ]]; then
    test_fail "usage: run_with_timeout <seconds> -- <cmd...>"
    return 1
  fi
  local secs="$1"
  shift
  if [[ "$1" == "--" ]]; then
    shift
  fi
  if command -v timeout >/dev/null 2>&1; then
    timeout "${secs}" "$@"
    return $?
  else
    # No timeout binary; run the command directly (best-effort).
    "$@"
    return $?
  fi
}

# Export helpers for subshells if necessary (safe no-op if not supported)
if typeset -f >/dev/null 2>&1; then
  export -f test_suite_start test_suite_end test_start test_pass test_fail test_warn test_info \
           assert_file_exists assert_executable assert_eq run_with_timeout >/dev/null 2>&1 || true
fi

# End of minimal framework shim
