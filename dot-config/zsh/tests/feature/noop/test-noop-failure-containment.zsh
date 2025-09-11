#!/usr/bin/env zsh
# ==============================================================================
# Failure Containment Test – noop Feature
# File: tests/feature/noop/test-noop-failure-containment.zsh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Validate that a feature-scoped failure (via the noop feature's test
#   injection helper) is safely contained by a standard invocation boundary
#   and does not corrupt the shell session or falsely mark initialization
#   state. This anticipates Stage 4 invocation wrapper behavior.
#
# Scope:
#   - Confirms failure injection returns expected code (42)
#   - Ensures boundary wrapper surfaces non-zero while shell remains usable
#   - Verifies noop init success path unaffected by prior injected failure
#   - Ensures no accidental initialization state mutation on failure path
#
# Assumptions:
#   - noop feature module present at feature/noop.zsh
#   - feature provides:
#       * feature_noop_init
#       * feature_noop__test_inject_failure
#       * variable __feature_noop_initialized
#
# Policy Notes:
#   - Pure shell; no external processes spawned.
#   - Runnable under `zsh -f` through unified test runner.
#
# Exit Codes:
#   0 = success
#   1 = assertion failures
# ==============================================================================
emulate -L zsh
setopt nounset
setopt pipe_fail

# ------------------------------------------------------------------------------
# Local assertion helpers (kept minimal / isolated)
# ------------------------------------------------------------------------------
typeset -g __fc_failures=0
typeset -g __fc_section="(unset)"

_section() {
  __fc_section="$1"
  print -- "[SECTION] $1"
}

_fail() {
  print -u2 -- "[FAIL] ${__fc_section} $*"
  (( __fc_failures++ ))
}

_pass() {
  print -- "[PASS] $*"
}

assert_eq() {
  local exp="$1" act="$2" msg="${3:-}"
  if [[ "$exp" != "$act" ]]; then
    _fail "assert_eq expected='$exp' actual='$act' ${msg}"
  else
    _pass "eq: $exp (${msg})"
  fi
}

assert_success() {
  local label="$1"; shift
  if "$@"; then
    _pass "$label"
  else
    _fail "$label (expected success)"
  fi
}

assert_failure() {
  local label="$1"; shift
  if "$@"; then
    _fail "$label (expected failure)"
  else
    _pass "$label"
  fi
}

# ------------------------------------------------------------------------------
# Resolve project root & source noop feature
# ------------------------------------------------------------------------------
__test_dir="${0:A:h}"
__zsh_root="${__test_dir%/tests/feature/noop}"

if [[ ! -f "${__zsh_root}/feature/noop.zsh" ]]; then
  print -u2 "[FATAL] Missing noop feature module at: ${__zsh_root}/feature/noop.zsh"
  exit 1
fi
source "${__zsh_root}/feature/noop.zsh"

# Sanity presence checks
typeset -f feature_noop_init >/dev/null 2>&1 || { print -u2 "[FATAL] feature_noop_init missing"; exit 1; }
typeset -f feature_noop__test_inject_failure >/dev/null 2>&1 || { print -u2 "[FATAL] failure injection helper missing"; exit 1; }

# ------------------------------------------------------------------------------
# Boundary wrapper (simulates future registry invocation model)
# Captures exit status, prevents shell abort, logs outcome.
# ------------------------------------------------------------------------------
invoke_feature_safely() {
  # $1 = init|failure
  local mode="$1" rc=0
  case "$mode" in
    init)
      feature_noop_init
      rc=$?
      ;;
    failure)
      feature_noop__test_inject_failure
      rc=$?
      ;;
    *)
      print -u2 "[boundary] unknown mode '$mode'"
      return 97
      ;;
  esac
  if (( rc != 0 )); then
    print -u2 "[boundary] feature noop mode=$mode exited rc=$rc (contained)"
  fi
  return $rc
}

# ------------------------------------------------------------------------------
# 1. Failure injection returns expected code
# ------------------------------------------------------------------------------
_section "failure-injection-return-code"
rc=0
feature_noop__test_inject_failure || rc=$?
assert_eq "42" "$rc" "injected failure code"

# Ensure no initialization flag set by failure
if (( ${__feature_noop_initialized:-0} != 0 )); then
  _fail "failure path should not set __feature_noop_initialized"
else
  _pass "failure did not set init flag"
fi

# ------------------------------------------------------------------------------
# 2. Boundary containment: non-zero preserved, shell continues
# ------------------------------------------------------------------------------
_section "boundary-containment"
rc=0
invoke_feature_safely failure || rc=$?
assert_eq "42" "$rc" "boundary preserved exit code"

# Shell still functional (simple arithmetic & builtin)
if ! out=$(echo test_ok 2>/dev/null); then
  _fail "shell unusable after contained failure (echo failed)"
else
  assert_eq "test_ok" "$out" "post-failure echo output"
fi

# ------------------------------------------------------------------------------
# 3. Normal init after prior failure still succeeds
# ------------------------------------------------------------------------------
_section "init-after-failure"
invoke_feature_safely init
init_rc=$?
assert_eq "0" "$init_rc" "init returned success"
if (( __feature_noop_initialized != 1 )); then
  _fail "__feature_noop_initialized expected=1 got=${__feature_noop_initialized:-unset}"
else
  _pass "init flag set"
fi

# ------------------------------------------------------------------------------
# 4. Idempotent init (second invocation no error)
# ------------------------------------------------------------------------------
_section "idempotent-init"
invoke_feature_safely init
second_rc=$?
assert_eq "0" "$second_rc" "second init remains success"
assert_eq "1" "${__feature_noop_initialized}" "init flag stable"

# ------------------------------------------------------------------------------
# 5. Failure after successful init does NOT unset initialized state
# ------------------------------------------------------------------------------
_section "post-init-failure-does-not-reset"
invoke_feature_safely failure || true
assert_eq "1" "${__feature_noop_initialized}" "init flag persists after failure"

# ------------------------------------------------------------------------------
# 6. Self-check passes (should succeed when initialized)
# ------------------------------------------------------------------------------
_section "self-check"
if typeset -f feature_noop_self_check >/dev/null 2>&1; then
  feature_noop_self_check
  sc_rc=$?
  assert_eq "0" "$sc_rc" "self-check success"
else
  _pass "self-check function absent (optional)"
fi

# ------------------------------------------------------------------------------
# 7. Teardown works and removes function
# ------------------------------------------------------------------------------
_section "teardown"
if typeset -f feature_noop_teardown >/dev/null 2>&1; then
  feature_noop_teardown
  td_rc=$?
  assert_eq "0" "$td_rc" "teardown success"
  if typeset -f noop::ping >/dev/null 2>&1; then
    _fail "noop::ping should be removed by teardown"
  else
    _pass "noop::ping removed"
  fi
else
  _pass "teardown function absent (optional)"
fi

# ------------------------------------------------------------------------------
# Report
# ------------------------------------------------------------------------------
if (( __fc_failures > 0 )); then
  print -u2 -- "[RESULT] FAIL (${__fc_failures} failures)"
  exit 1
fi
print -- "[RESULT] OK"
exit 0
