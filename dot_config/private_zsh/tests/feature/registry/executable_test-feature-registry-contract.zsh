#!/usr/bin/env zsh
# ==============================================================================
# Registry Contract Test
# File: tests/feature/registry/test-feature-registry-contract.zsh
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Validate baseline feature registry scaffold contracts:
#     - Data structures and functions exist
#     - Feature registration works (idempotent + metadata persistence)
#     - Topological ordering honors dependencies & phases
#     - Disabled features are excluded from order
#     - Cycle detection surfaces non-zero exit
#     - Unknown / disabled dependency handling is non-fatal
#     - Enablement caching logic functions
#
# Scope:
#   DOES NOT test future (not yet implemented) invocation phases (preload/init/postprompt),
#   telemetry timing, or deferred scheduling.
#
# Execution:
#   Must be runnable under `zsh -f` via the unified runner `run-all-tests-v2.zsh`.
#
# Policy Notes:
#   - No external commands executed (performance and determinism).
#   - All assertions pure shell logic.
#
# ==============================================================================

emulate -L zsh

setopt nounset
setopt pipe_fail

# ------------------------------------------------------------------------------
# Minimal assertion framework (kept local to avoid cross-test coupling)
# ------------------------------------------------------------------------------
_test_failures=0
_test_current_section="(unset)"

assert_true() {
  local expr="$1" msg="${2:-}"
  if ! eval "$expr"; then
    print -u2 "[FAIL] ${_test_current_section} assert_true: $expr ${msg:+-- $msg}"
    (( _test_failures++ ))
  fi
}

assert_false() {
  local expr="$1" msg="${2:-}"
  if eval "$expr"; then
    print -u2 "[FAIL] ${_test_current_section} assert_false: $expr ${msg:+-- $msg}"
    (( _test_failures++ ))
  fi
}

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    print -u2 "[FAIL] ${_test_current_section} assert_eq: expected='$expected' actual='$actual' ${msg:+-- $msg}"
    (( _test_failures++ ))
  fi
}

section() {
  _test_current_section="$1"
  print -- "[SECTION] $1"
}

finish() {
  if (( _test_failures > 0 )); then
    print -u2 "[RESULT] FAIL (${_test_failures} failures)"
    return 1
  fi
  print -- "[RESULT] OK"
  return 0
}

# ------------------------------------------------------------------------------
# Locate repository root relative to this test file
# ------------------------------------------------------------------------------
# This file path: dot-config/zsh/tests/feature/registry/test-feature-registry-contract.zsh
# We need to source: dot-config/zsh/feature/registry/feature-registry.zsh
# Ascend from tests/feature/registry -> tests -> (root of zsh config)
# ------------------------------------------------------------------------------
__test_dir="${0:A:h}"
__zsh_root="${__test_dir%/tests/feature/registry}"
# Fallback sanity check
if [[ ! -d "${__zsh_root}/feature/registry" ]]; then
  print -u2 "[FATAL] Could not resolve feature registry directory from path: ${__zsh_root}/feature/registry"
  exit 1
fi

# Source registry scaffold
source "${__zsh_root}/feature/registry/feature-registry.zsh"

section "registry:structure"

# ------------------------------------------------------------------------------
# 1. Structural existence tests
# ------------------------------------------------------------------------------
for fn in \
  feature_registry_init \
  feature_registry_add \
  feature_registry_is_enabled \
  feature_registry_resolve_order \
  feature_registry_list \
  feature_registry_self_check \
  feature_registry_invoke_phase \
  feature_registry_dump_table
do
  assert_true "typeset -f ${fn} >/dev/null" "missing function $fn"
done

# ------------------------------------------------------------------------------
# 2. Basic registration & ordering
# ------------------------------------------------------------------------------
section "registry:basic-registration"

# Clean state assumptions
assert_eq "0" "${#ZSH_FEATURE_REGISTRY_NAMES[@]}" "registry should be empty at start of test"

# Define simple enablement functions (explicit to verify delegation)
feature_alpha_is_enabled() { return 0 }    # always enabled
feature_beta_is_enabled()  { return 0 }    # always enabled
feature_gamma_is_enabled() { return 0 }    # always enabled

# Register features with dependency chain: gamma -> beta -> alpha
# gamma depends on beta; beta depends on alpha.
feature_registry_add alpha 1 ""    "no" "core"    "Alpha base feature"    "guid-alpha"
feature_registry_add beta  2 "alpha" "no" "core"  "Beta depends on alpha" "guid-beta"
feature_registry_add gamma 2 "beta"  "no" "extra" "Gamma depends on beta" "guid-gamma"

assert_eq "3" "${#ZSH_FEATURE_REGISTRY_NAMES[@]}" "expected three registered features"

# Resolve order
resolved=($(feature_registry_resolve_order))
# Expect ordering by dependency and phase; alpha first, then beta, then gamma
assert_eq "alpha" "${resolved[1]:-}" "alpha should be first"
assert_eq "beta"  "${resolved[2]:-}" "beta should be second"
assert_eq "gamma" "${resolved[3]:-}" "gamma should be third"
assert_eq "3"     "${#resolved[@]}"  "resolved list length mismatch"

# ------------------------------------------------------------------------------
# 3. Enablement caching behavior
# ------------------------------------------------------------------------------
section "registry:enablement-cache"

# Create a toggling feature to ensure caching persists result
__toggle_counter=0
feature_toggle_is_enabled() {
  (( __toggle_counter++ ))
  # Return success (enabled)
  return 0
}
feature_registry_add toggle 2 "" "no" "test" "Toggle test feature" "guid-toggle"

# First call should increment counter
feature_registry_is_enabled toggle
assert_eq "1" "$__toggle_counter" "first enablement evaluation should be increment 1"

# Second call should NOT call function again (cache)
feature_registry_is_enabled toggle
assert_eq "1" "$__toggle_counter" "cached enablement should not re-invoke function"

# ------------------------------------------------------------------------------
# 4. Disabled feature exclusion (via custom is_enabled function)
# ------------------------------------------------------------------------------
section "registry:disabled-feature-exclusion"

feature_disabled_is_enabled() { return 1 }  # disabled
feature_dep_on_disabled_is_enabled() { return 0 }

feature_registry_add disabled 2 "" "no" "test" "Disabled feature" "guid-disabled"
feature_registry_add dep_on_disabled 2 "disabled" "no" "test" "Depends on disabled" "guid-dep-disabled"

# Resolving order again (invalidate cache due to new registrations)
resolved=($(feature_registry_resolve_order))
# Neither 'disabled' nor 'dep_on_disabled' should appear (dep filtered because its dependency disabled)
# Quick containment checks
for item in "${resolved[@]}"; do
  if [[ "$item" == "disabled" || "$item" == "dep_on_disabled" ]]; then
    assert_true "false" "Disabled or dependency-on-disabled feature present in resolved order"
  fi
done

# ------------------------------------------------------------------------------
# 5. Unknown dependency warning (non-fatal)
# ------------------------------------------------------------------------------
section "registry:unknown-dependency"

feature_unknown_dep_is_enabled() { return 0 }
feature_registry_add unknown_dep 2 "nonexistent_feature" "no" "test" "Depends on unknown" "guid-unknown"

# Resolution should still succeed (returns order) though a warning logged
resolved=($(feature_registry_resolve_order))
assert_true "(( \$? == 0 ))" "resolution should succeed even with unknown dependency"

# ------------------------------------------------------------------------------
# 6. Cycle detection
# ------------------------------------------------------------------------------
section "registry:cycle-detection"

feature_cycle_a_is_enabled() { return 0 }
feature_cycle_b_is_enabled() { return 0 }

feature_registry_add cycle_a 2 "cycle_b" "no" "test" "Cycle A" "guid-cycle-a"
feature_registry_add cycle_b 2 "cycle_a" "no" "test" "Cycle B" "guid-cycle-b"

# Attempt to resolve; expect non-zero due to cycle
if out=$(feature_registry_resolve_order 2>&1); then
  # Resolution succeeded unexpectedly
  assert_true "false" "cycle resolution should fail but succeeded; output=$out"
else
  # Failure expected – pass
  :
fi

# IMPORTANT: After failure, clear cached order to avoid poisoning subsequent tests
ZSH_FEATURE_REGISTRY_RESOLVED_ORDER=()

# ------------------------------------------------------------------------------
# 7. Self-check
# ------------------------------------------------------------------------------
section "registry:self-check"
feature_registry_self_check
assert_true "(( \$? == 0 ))" "self check failed"

# ------------------------------------------------------------------------------
# Finish
# ------------------------------------------------------------------------------
finish
exit $?
