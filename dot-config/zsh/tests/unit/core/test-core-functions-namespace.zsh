#!/usr/bin/env zsh
# =============================================================================
# test-core-functions-namespace.zsh
#
# Purpose:
#   Ensures Stage 3 core function module (`10-core-functions.zsh`) defines a
#   non-empty, collision‑free set of namespaced helpers using the `zf::` prefix
#   and does not leak un-namespaced shadow equivalents (e.g. defining both
#   `zf::ensure_cmd` and `ensure_cmd`).
#
# Validations:
#   CF1: Module file present (else SKIP).
#   CF2: After sourcing, at least MIN_EXPECT functions with prefix `zf::` exist.
#   CF3: No duplicate names (should never happen in a standard functions table).
#   CF4: No un-namespaced shadow of a namespaced function (base name).
#   CF5: Optional stability fingerprint (emitted, not enforced) for future drift tracking.
#
# Environment Skips:
#   TDD_SKIP_CORE_FN_NS=1   -> Skip this test.
#
# Exit Codes:
#   0 = PASS (or SKIP)
#   1 = FAIL
#
# Notes:
#   - This test does *not* enforce a hard fixed list yet; it focuses on structural
#     namespace hygiene. A future enhancement can add a golden manifest.
#   - Works even if the module has already been sourced earlier in the test run.
#
# Future Enhancements (Non-blocking):
#   - Add golden count / allowlist checksum gating once Stage 3 stabilizes.
#   - Emit per-function length metrics for performance audit.
# =============================================================================

set -euo pipefail

# -----------------------
# Skip Handling
# -----------------------
if [[ "${TDD_SKIP_CORE_FN_NS:-0}" == "1" ]]; then
  print "SKIP: core functions namespace test skipped (TDD_SKIP_CORE_FN_NS=1)"
  exit 0
fi

# Quiet debug shim if not defined
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

PASS=()
FAIL=()
MIN_EXPECT=${CORE_FN_MIN_EXPECT:-3}   # Adjustable threshold (tune as module grows)

pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }

# -----------------------
# Path / Module Resolution
# -----------------------
SCRIPT_SRC="${(%):-%N}"
if typeset -f zf::script_dir >/dev/null 2>&1; then
  THIS_DIR="$(zf::script_dir "$SCRIPT_SRC")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
  THIS_DIR="$(resolve_script_dir "$SCRIPT_SRC")"
else
  THIS_DIR="${SCRIPT_SRC:h}"
fi

REPO_ROOT="$(cd "$THIS_DIR/../../../.." && pwd -P 2>/dev/null)"
MODULE_REL=".zshrc.d.REDESIGN/10-core-functions.zsh"
MODULE_PATH="${REPO_ROOT}/dot-config/zsh/${MODULE_REL}"

if [[ ! -f "$MODULE_PATH" ]]; then
  print "SKIP: core functions module not present (${MODULE_REL})"
  exit 0
fi
pass "CF1 module-present"

# -----------------------
# Source (Idempotent)
# -----------------------
# shellcheck disable=SC1090
if ! . "$MODULE_PATH" 2>/dev/null; then
  fail "CF2 module-source-failed"
  goto_report=1
else
  pass "CF2 module-sourced"
fi

# -----------------------
# Collect Namespaced Functions
# -----------------------
# functions - autoloaded list; ${(k)functions} enumerates names.
local -a NS_FUNCS
NS_FUNCS=(${(k)functions:#zf::*})

if (( ${#NS_FUNCS[@]} == 0 )); then
  fail "CF3 no-namespaced-functions-found"
elif (( ${#NS_FUNCS[@]} < MIN_EXPECT )); then
  fail "CF3 below-minimum-namespaced-count found=${#NS_FUNCS[@]} min=${MIN_EXPECT}"
else
  pass "CF3 namespaced-count-ok (${#NS_FUNCS[@]})"
fi

# -----------------------
# Duplicate Detection (Defensive)
# -----------------------
typeset -A FN_SEEN
local dup_count=0
for f in "${NS_FUNCS[@]}"; do
  if [[ -n "${FN_SEEN[$f]:-}" ]]; then
    (( dup_count++ ))
  else
    FN_SEEN["$f"]=1
  fi
done

if (( dup_count == 0 )); then
  pass "CF4 no-duplicate-names"
else
  fail "CF4 duplicates-detected=${dup_count}"
fi

# -----------------------
# Shadow Collision Detection
#   e.g. zf::ensure_cmd AND ensure_cmd (un-namespaced) => fail
# -----------------------
local -a SHADOWS
for f in "${NS_FUNCS[@]}"; do
  base="${f##*::}"
  if [[ -n "$base" && -n "${functions[$base]:-}" ]]; then
    SHADOWS+=("$f|$base")
  fi
done

if (( ${#SHADOWS[@]} == 0 )); then
  pass "CF5 no-unprefixed-shadows"
else
  fail "CF5 shadow-collisions (${(j:, :)SHADOWS})"
fi

# -----------------------
# Optional Stability Fingerprint
#   (Not enforced; informational drift marker)
# -----------------------
# Concatenate definitions stripped of whitespace & produce a hash
local defs canon
defs=""
for f in "${NS_FUNCS[@]}"; do
  # functions -M is not used; take raw definition
  defs+="${functions[$f]}"
done
canon="$(print -- "$defs" | sed -e 's/[[:space:]]//g' | LC_ALL=C tr -d '\n' | sha1sum 2>/dev/null || print -- "na")"
pass "CF6 fingerprint=${canon%% *}"

# -----------------------
# Reporting
# -----------------------
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} namespace_funcs=${#NS_FUNCS[@]} min_expected=${MIN_EXPECT}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
