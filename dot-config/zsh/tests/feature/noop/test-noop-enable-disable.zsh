#!/usr/bin/env zsh
# ==============================================================================
# Enable/Disable Semantics Tests – noop Feature
# File: tests/feature/noop/test-noop-enable-disable.zsh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Validate precedence and behavior of feature enable/disable logic for the
#   Stage 4 exemplar feature `noop`.
#
# Precedence (as implemented in feature_noop_is_enabled):
#   1. Global disable sentinel: ZSH_FEATURES_DISABLE contains 'all'
#   2. Per-feature override var: ZSH_FEATURE_NOOP_ENABLED (yes/no)
#   3. Explicit disable list: ZSH_FEATURES_DISABLE
#   4. Explicit enable list:  ZSH_FEATURES_ENABLE
#   5. FEATURE_DEFAULT_ENABLED fallback
#
# Required Outcomes:
#   - Default state: enabled
#   - Global disable-all overrides everything (even per-feature override=yes)
#   - Disable list blocks feature unless per-feature override explicitly enables
#     (design allows override-before-disable precedence)
#   - Enable list enables feature when not otherwise disabled
#   - Per-feature override=no forces disable, even if enable list contains name
#   - Per-feature override=yes forces enable even if disable list contains name
#
# Policy Notes:
#   - No external processes executed (pure shell logic).
#   - Runs under `zsh -f` environment via unified runner.
#
# Exit Codes:
#   - 0 on success
#   - 1 on any assertion failure
# ==============================================================================

emulate -L zsh
setopt nounset
setopt pipe_fail

# ------------------------------------------------------------------------------
# Minimal assertion helpers (local, no external sourcing)
# ------------------------------------------------------------------------------
typeset -g __fail_count=0
typeset -g __section="(unset)"

_section() {
  __section="$1"
  print -- "[SECTION] $1"
}

_fail() {
  print -u2 -- "[FAIL] ${__section} $*"
  (( __fail_count++ ))
}

_pass() {
  print -- "[PASS] $*"
}

assert_success() {
  local label="$1"; shift
  if "$@"; then
    _pass "$label"
  else
    _fail "$label (expected success, got failure)"
  fi
}

assert_failure() {
  local label="$1"; shift
  if "$@"; then
    _fail "$label (expected failure, got success)"
  else
    _pass "$label"
  fi
}

# Convenience wrapper to invoke feature_noop_is_enabled respecting exit code
noop_enabled() {
  feature_noop_is_enabled
}

# Reset environment-affecting vars between tests
_reset_env() {
  unset ZSH_FEATURES_DISABLE ZSH_FEATURES_ENABLE ZSH_FEATURE_NOOP_ENABLED
}

# ------------------------------------------------------------------------------
# Locate & source noop feature module (relative to this test file)
# ------------------------------------------------------------------------------
__test_dir="${0:A:h}"
__zsh_root="${__test_dir%/tests/feature/noop}"
if [[ ! -f "${__zsh_root}/feature/noop.zsh" ]]; then
  print -u2 "[FATAL] Could not locate noop feature module at: ${__zsh_root}/feature/noop.zsh"
  exit 1
fi
source "${__zsh_root}/feature/noop.zsh"

# Sanity: required function existence
typeset -f feature_noop_is_enabled >/dev/null 2>&1 || {
  print -u2 "[FATAL] feature_noop_is_enabled is missing"
  exit 1
}

# ------------------------------------------------------------------------------
# 1. Default state (no env overrides)
# ------------------------------------------------------------------------------
_section "default"
_reset_env
assert_success "default: enabled by default" noop_enabled

# ------------------------------------------------------------------------------
# 2. Disable via global 'all'
# ------------------------------------------------------------------------------
_section "global-disable-all"
_reset_env
ZSH_FEATURES_DISABLE="all"
assert_failure "global disable-all: noop disabled" noop_enabled

# ------------------------------------------------------------------------------
# 3. Specific disable list (space-separated / comma-separated)
# ------------------------------------------------------------------------------
_section "disable-list"
_reset_env
ZSH_FEATURES_DISABLE="noop other"
assert_failure "disable list (space): noop disabled" noop_enabled

_reset_env
ZSH_FEATURES_DISABLE="other,noop,another"
assert_failure "disable list (comma): noop disabled" noop_enabled

_reset_env
ZSH_FEATURES_DISABLE="other"
assert_success "disable list (not containing noop) leaves enabled" noop_enabled

# ------------------------------------------------------------------------------
# 4. Enable list enables if not disabled elsewhere
# ------------------------------------------------------------------------------
_section "enable-list"
_reset_env
ZSH_FEATURES_ENABLE="noop"
assert_success "enable list: noop enabled" noop_enabled

# Combined enable + unrelated disable
_reset_env
ZSH_FEATURES_ENABLE="noop"
ZSH_FEATURES_DISABLE="unrelated"
assert_success "enable list + unrelated disable: noop enabled" noop_enabled

# ------------------------------------------------------------------------------
# 5. Disable list vs enable list (disable takes precedence after override check)
# ------------------------------------------------------------------------------
_section "disable-vs-enable"
_reset_env
ZSH_FEATURES_DISABLE="noop"
ZSH_FEATURES_ENABLE="noop"
assert_failure "disable vs enable: disable wins" noop_enabled

# ------------------------------------------------------------------------------
# 6. Per-feature override = no (forces disable even if enabled elsewhere)
# ------------------------------------------------------------------------------
_section "override-no"
_reset_env
ZSH_FEATURE_NOOP_ENABLED="no"
assert_failure "override=no: disables feature" noop_enabled

_reset_env
ZSH_FEATURE_NOOP_ENABLED="no"
ZSH_FEATURES_ENABLE="noop"
assert_failure "override=no over enable list" noop_enabled

# ------------------------------------------------------------------------------
# 7. Per-feature override = yes (forces enable even if in disable list)
# ------------------------------------------------------------------------------
_section "override-yes"
_reset_env
ZSH_FEATURE_NOOP_ENABLED="yes"
assert_success "override=yes: enables feature" noop_enabled

_reset_env
ZSH_FEATURE_NOOP_ENABLED="yes"
ZSH_FEATURES_DISABLE="noop"
assert_success "override=yes over disable list (precedence rule)" noop_enabled

# ------------------------------------------------------------------------------
# 8. Global disable-all still dominates even with override=yes
# ------------------------------------------------------------------------------
_section "global-all-beats-override"
_reset_env
ZSH_FEATURES_DISABLE="all"
ZSH_FEATURE_NOOP_ENABLED="yes"
assert_failure "global disable-all beats override=yes" noop_enabled

# ------------------------------------------------------------------------------
# 9. Mixed lists (ensure parsing of commas/spaces robust)
# ------------------------------------------------------------------------------
_section "mixed-lists"
_reset_env
ZSH_FEATURES_DISABLE="alpha,noop beta"
assert_failure "mixed list containing noop disables it" noop_enabled

_reset_env
ZSH_FEATURES_ENABLE="alpha,noop beta"
assert_success "mixed enable list containing noop enables it" noop_enabled

# ------------------------------------------------------------------------------
# 10. Cached enablement does not persist across environment changes
#     (Because function feature_noop_is_enabled reads env each call; registry
#      caching applies only after registry integration, but we ensure semantics)
# ------------------------------------------------------------------------------
_section "no-stale-cache"
_reset_env
assert_success "initial check" noop_enabled
ZSH_FEATURES_DISABLE="noop"
assert_failure "post-change disable takes effect" noop_enabled

# ------------------------------------------------------------------------------
# Summary & Exit
# ------------------------------------------------------------------------------
if (( __fail_count > 0 )); then
  print -u2 -- "[RESULT] FAIL (${__fail_count} failures)"
  exit 1
fi

print -- "[RESULT] OK"
exit 0
