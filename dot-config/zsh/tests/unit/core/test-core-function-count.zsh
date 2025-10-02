#!/usr/bin/env zsh
# =============================================================================
# test-core-function-count.zsh
#
# Purpose:
#   Enforces and tracks the evolving count of exported core helper functions
#   in the Stage 3 module: 10-core-functions.zsh (zf::* namespace).
#
# Validation Focus:
#   FC1: Module present (else SKIP – infrastructure / ordering issue).
#   FC2: Sourcing succeeds (idempotent safe).
#   FC3: Namespaced function count >= CORE_FN_MIN_EXPECT (baseline growth gate).
#   FC4: (Optional) If CORE_FN_GOLDEN_COUNT is set:
#          - count == GOLDEN → PASS (stable)
#          - count >  GOLDEN → PASS (growth) if CORE_FN_ALLOW_GROWTH=1 else FAIL (unexpected drift)
#          - count <  GOLDEN → FAIL (regression)
#
# Environment Controls:
#   TDD_SKIP_CORE_FN_COUNT=1   -> Skip this test
#   CORE_FN_MIN_EXPECT=<int>   -> Minimum acceptable count (default: 5)

# ---------------------------------------
# Debug Output: Environment, Variables, and Setopts
# ---------------------------------------
print "=== DEBUG ENVIRONMENT ==="
print "PWD: $PWD"
print "ZDOTDIR: ${ZDOTDIR:-<unset>}"
print "REPO_ROOT: ${REPO_ROOT:-<unset>}"
print "MODULE_PATH: ${MODULE_PATH:-<unset>}"
print "ZSH_VERSION: $ZSH_VERSION"
print "ZSH_PATCHLEVEL: ${ZSH_PATCHLEVEL:-<unset>}"
print "ZSH_MODULE_PATH: ${ZSH_MODULE_PATH:-<unset>}"
print "module_path: ${module_path:-<unset>}"
print "parameter: ${parameter:-<unset>}"
print "functions[parameter]: ${functions[parameter]:-<unset>}"
print "setopts: $(setopt)"
print "=== END DEBUG ENVIRONMENT ==="
#   CORE_FN_GOLDEN_COUNT=<int> -> Exact expected count (drift tracked)
#   CORE_FN_ALLOW_GROWTH=1     -> Allow new functions beyond golden (warn/pass)
#
# Exit Codes:
#   0 = PASS or SKIP
#   1 = FAIL (one or more invariants)
#
# Notes:
#   - Complements test-core-functions-namespace.zsh (namespace hygiene).
#   - This test cares only about quantity, not specific names. For name-level
#     drift protection introduce a golden manifest later when stabilised.
#   - Intentionally fast: no subshells, pure reflective enumeration.
#
# Future Enhancements:
#   - Optional per-function size / cyclomatic complexity export.
#   - Golden manifest (hash of concatenated definitions) gating.
# =============================================================================

set -euo pipefail

trap 'zf::debug "DEBUG: Error at line $LINENO in function $funcstack"; typeset -f ${funcstack[1]} 2>/dev/null' ERR

# ---------------------------------------
# Skip Handling
# ---------------------------------------
if [[ "${TDD_SKIP_CORE_FN_COUNT:-0}" == "1" ]]; then
  print "SKIP: core function count test skipped (TDD_SKIP_CORE_FN_COUNT=1)"
  exit 0
fi

PASS=()
FAIL=()
pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }

# ---------------------------------------
# Repo Root / Module Path
# ---------------------------------------
SCRIPT_SRC="${(%):-%N}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$ZDOTDIR"
fi

MODULE_REL=".zshrc.d.REDESIGN/10-core-functions.zsh"
MODULE_PATH="${REPO_ROOT}/dot-config/zsh/${MODULE_REL}"

if [[ ! -f "$MODULE_PATH" ]]; then
  print "SKIP: core functions module not present (${MODULE_REL})"
  exit 0
fi
pass "FC1 module-present"

# ---------------------------------------
# Source Module (Idempotent Safe)
# ---------------------------------------
# shellcheck disable=SC1090
if ! . "$MODULE_PATH" 2>/dev/null; then
  fail "FC2 module-source-failed"
else
  pass "FC2 module-sourced"
fi

# ---------------------------------------
# Collect Namespaced Functions
# ---------------------------------------
local -a CORE_FUNCS
CORE_FUNCS=(${(k)functions:#zf::*})
COUNT=${#CORE_FUNCS[@]}

MIN_EXPECT=${CORE_FN_MIN_EXPECT:-5}
if (( COUNT < MIN_EXPECT )); then
  fail "FC3 below-minimum count=${COUNT} min=${MIN_EXPECT}"
else
  pass "FC3 meets-minimum count=${COUNT} min=${MIN_EXPECT}"
fi

# ---------------------------------------
# Golden Count Drift Logic (Optional)
# ---------------------------------------
if [[ -n "${CORE_FN_GOLDEN_COUNT:-}" ]]; then
  if ! [[ "${CORE_FN_GOLDEN_COUNT}" =~ '^[0-9]+$' ]]; then
    fail "FC4 invalid-golden-non-numeric=${CORE_FN_GOLDEN_COUNT}"
  else
    GOLDEN=${CORE_FN_GOLDEN_COUNT}
    if (( COUNT == GOLDEN )); then
      pass "FC4 golden-match count=${COUNT}"
    elif (( COUNT < GOLDEN )); then
      fail "FC4 golden-regression count=${COUNT} golden=${GOLDEN}"
    else
      # COUNT > GOLDEN
      if [[ "${CORE_FN_ALLOW_GROWTH:-0}" == "1" ]]; then
        pass "FC4 golden-growth-allowed count=${COUNT} golden=${GOLDEN}"
      else
        fail "FC4 golden-growth-disallowed count=${COUNT} golden=${GOLDEN}"
      fi
    fi
  fi
else
  pass "FC4 golden-unset (skipped)"
fi

# ---------------------------------------
# Optional Fingerprint (Informational)
# ---------------------------------------
# Hash concatenated definitions (whitespace stripped) for drift observation
if (( COUNT > 0 )); then
  defs=""
  for f in "${CORE_FUNCS[@]}"; do
    defs+="${functions[$f]}"
  done
  fp=$(print -- "$defs" | sed -e 's/[[:space:]]//g' | LC_ALL=C tr -d '\n' | sha1sum 2>/dev/null | awk '{print $1}')
  [[ -n "$fp" ]] || fp="na"
  pass "FC5 fingerprint=${fp}"
else
  pass "FC5 fingerprint-skipped (no functions)"
fi

# ---------------------------------------
# Reporting
# ---------------------------------------
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} count=${COUNT} min=${MIN_EXPECT} golden=${CORE_FN_GOLDEN_COUNT:-<unset>} growth_allowed=${CORE_FN_ALLOW_GROWTH:-0}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
