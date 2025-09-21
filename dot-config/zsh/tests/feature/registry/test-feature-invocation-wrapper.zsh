#!/usr/bin/env zsh
# ==============================================================================
# Invocation Wrapper Test – Registry Phase Dispatch & Timing
# File: tests/feature/registry/test-feature-invocation-wrapper.zsh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Validates new feature invocation wrapper behaviour implemented in:
#     feature/registry/feature-registry.zsh
#   Focus areas:
#     - Phase dispatch: preload, init, postprompt
#     - Enablement filtering (noop feature is enabled by default)
#     - Status tracking (ZSH_FEATURE_STATUS[name])
#     - Per‑feature synchronous timing capture (init phase) when telemetry enabled
#     - Non-execution of postprompt phase for non-deferred features
#
# Assumptions:
#   - noop feature module present at feature/noop.zsh (auto-registers itself)
#   - Registry updated with feature_registry_invoke_phase implementation
#   - Timing array: ZSH_FEATURE_TIMINGS_SYNC
#   - Status map:  ZSH_FEATURE_STATUS
#
# Test Strategy:
#   1. Source registry + noop feature in clean (zsh -f) environment.
#   2. Force telemetry on (ZSH_FEATURE_TELEMETRY=1) for timing coverage.
#   3. Invoke preload phase -> expect no errors, status=ok or unset→ok after init.
#   4. Invoke init phase -> expect noop::ping defined, status=ok, timing captured (>=0).
#   5. Capture timing value; assert integer and reasonably small (<50ms safety cap).
#   6. Invoke postprompt phase -> noop is not deferred; timing unchanged, no errors.
#   7. Ensure status remains ok and no duplicate mutation side-effects (idempotence).
#
# Exit Codes:
#   0 = success
#   1 = failure
#
# Policy Notes:
#   - No external processes spawned.
#   - Pure shell; deterministic under `zsh -f`.
# ==============================================================================

emulate -L zsh
setopt nounset
setopt pipe_fail

# ------------------------------------------------------------------------------
# Minimal assertion framework (isolated to this test)
# ------------------------------------------------------------------------------
typeset -g __tw_failures=0
typeset -g __tw_section="(unset)"

_section() {
  __tw_section="$1"
  print -- "[SECTION] $1"
}

_fail() {
  print -u2 -- "[FAIL] ${__tw_section} $*"
  (( __tw_failures++ ))
}

_pass() {
  print -- "[PASS] $*"
}

assert_true() {
  local label="$1"; shift
  if "$@"; then
    _pass "$label"
  else
    _fail "$label (expected success)"
  fi
}

assert_false() {
  local label="$1"; shift
  if "$@"; then
    _fail "$label (expected failure)"
  else
    _pass "$label"
  fi
}

assert_eq() {
  local exp="$1" act="$2" label="$3"
  if [[ "$exp" != "$act" ]]; then
    _fail "${label:-eq} expected='$exp' actual='$act'"
  else
    _pass "${label:-eq} ($exp)"
  fi
}

assert_int_ge() {
  local min="$1" val="$2" label="$3"
  if [[ ! "$val" == <-> ]]; then
    _fail "${label:-ge} value '$val' not integer"
    return
  fi
  if (( val < min )); then
    _fail "${label:-ge} expected >= $min got $val"
  else
    _pass "${label:-ge} $val >= $min"
  fi
}

assert_int_le() {
  local max="$1" val="$2" label="$3"
  if [[ ! "$val" == <-> ]]; then
    _fail "${label:-le} value '$val' not integer"
    return
  fi
  if (( val > max )); then
    _fail "${label:-le} expected <= $max got $val"
  else
    _pass "${label:-le} $val <= $max"
  fi
}

# ------------------------------------------------------------------------------
# Resolve paths & source required components
# ------------------------------------------------------------------------------
_section "environment-setup"

# This test file path: dot-config/zsh/tests/feature/registry/test-feature-invocation-wrapper.zsh
__test_dir="${0:A:h}"
__zsh_root="${__test_dir%/tests/feature/registry}"

if [[ ! -f "${__zsh_root}/feature/registry/feature-registry.zsh" ]]; then
  _fail "Registry file not found: ${__zsh_root}/feature/registry/feature-registry.zsh"
  print -u2 -- "[RESULT] FAIL (early abort)"
  exit 1
fi

if [[ ! -f "${__zsh_root}/feature/noop.zsh" ]]; then
  _fail "Noop feature not found: ${__zsh_root}/feature/noop.zsh"
  print -u2 -- "[RESULT] FAIL (early abort)"
  exit 1
fi

# Source order: registry first, then feature (feature auto-registers)
source "${__zsh_root}/feature/registry/feature-registry.zsh"
source "${__zsh_root}/feature/noop.zsh"

# Clear possible pre-existing timing/status (safety if tests run in batch shell)
unset ZSH_FEATURE_TIMINGS_SYNC 2>/dev/null || true
typeset -gA ZSH_FEATURE_TIMINGS_SYNC
unset ZSH_FEATURE_STATUS 2>/dev/null || true
typeset -gA ZSH_FEATURE_STATUS

ZSH_FEATURE_TELEMETRY=1  # enable timing collection

# Force consistent locale/float formatting
LC_ALL=C

assert_true "registry self check" feature_registry_self_check

# Ensure noop registered
if [[ -z "${ZSH_FEATURE_REGISTRY_PHASE[noop]:-}" ]]; then
  _fail "noop not registered in registry arrays"
fi

# ------------------------------------------------------------------------------
# Preload phase
# ------------------------------------------------------------------------------
_section "preload-phase"
feature_registry_invoke_phase preload
rc=$?
assert_eq "0" "$rc" "preload return code"

# Preload should not necessarily set status (depends if function existed and returned 0)
# We treat absence in status map as acceptable pre-init condition.
if [[ -n "${ZSH_FEATURE_STATUS[noop]:-}" ]]; then
  # If present must not be error
  [[ "${ZSH_FEATURE_STATUS[noop]}" == "error" ]] && _fail "status=error after preload"
fi

# No timing should be recorded yet (timing only on init)
if [[ -n "${ZSH_FEATURE_TIMINGS_SYNC[noop]:-}" ]]; then
  _fail "Timing present prematurely after preload"
else
  _pass "No timing collected on preload (expected)"
fi

# ------------------------------------------------------------------------------
# Init phase
# ------------------------------------------------------------------------------
_section "init-phase"
feature_registry_invoke_phase init
rc=$?
assert_eq "0" "$rc" "init return code"

# Status should now be ok (unless error)
if [[ "${ZSH_FEATURE_STATUS[noop]:-}" != "ok" ]]; then
  _fail "Expected status ok after init; got '${ZSH_FEATURE_STATUS[noop]:-<unset>}'"
else
  _pass "Status ok after init"
fi

# Function introduced by init should exist
assert_true "noop::ping function present" "typeset -f noop::ping >/dev/null 2>&1"

# Timing must be recorded (integer >=0)
if [[ -z "${ZSH_FEATURE_TIMINGS_SYNC[noop]:-}" ]]; then
  _fail "No timing recorded for noop init phase"
else
  local_timing="${ZSH_FEATURE_TIMINGS_SYNC[noop]}"
  assert_int_ge 0 "$local_timing" "timing ge 0"
  # Safety ceiling: a noop feature should be extremely fast; allow generous 50ms cap
  assert_int_le 50 "$local_timing" "timing le 50ms"
fi

# Re-run init to check idempotence & stable timing entry (second invocation allowed)
feature_registry_invoke_phase init
rc=$?
assert_eq "0" "$rc" "second init invocation rc"

# Status should remain ok
if [[ "${ZSH_FEATURE_STATUS[noop]:-}" != "ok" ]]; then
  _fail "Status not ok after second init invocation"
else
  _pass "Status ok after second init"
fi

# ------------------------------------------------------------------------------
# Postprompt phase (noop is NOT deferred: should not run postprompt hook)
# ------------------------------------------------------------------------------
_section "postprompt-phase"
# Capture timing before
pre_post_timing="${ZSH_FEATURE_TIMINGS_SYNC[noop]:-}"
feature_registry_invoke_phase postprompt
rc=$?
assert_eq "0" "$rc" "postprompt return code"

# Ensure timing unchanged (non-deferred feature not modified)
post_post_timing="${ZSH_FEATURE_TIMINGS_SYNC[noop]:-}"
if [[ "$pre_post_timing" != "$post_post_timing" ]]; then
  _fail "Timing changed unexpectedly after postprompt (pre=$pre_post_timing post=$post_post_timing)"
else
  _pass "Timing unchanged after postprompt for non-deferred feature"
fi

# Status still ok
if [[ "${ZSH_FEATURE_STATUS[noop]:-}" != "ok" ]]; then
  _fail "Status degraded after postprompt"
else
  _pass "Status ok after postprompt"
fi

# ------------------------------------------------------------------------------
# Summary & Exit
# ------------------------------------------------------------------------------
if (( __tw_failures > 0 )); then
  print -u2 -- "[RESULT] FAIL (${__tw_failures} failures)"
  exit 1
fi
print -- "[RESULT] OK"
exit 0
