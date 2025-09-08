#!/usr/bin/env zsh
# =============================================================================
# test-core-functions-manifest.zsh
#
# Purpose:
#   Enforces (or observes, depending on env toggles) alignment between the
#   exported Stage 3 core function namespace (zf::*) and the golden manifest:
#     docs/redesignv2/artifacts/golden/core-functions-manifest-stage3.txt
#
# Golden Manifest Format:
#   - Comment lines start with '#'
#   - A delimiter line containing exactly '---'
#   - One fully-qualified function name per subsequent non-comment, non-empty line
#
# Invariants (default strict mode):
#   M1: Golden manifest file exists (else SKIP)
#   M2: At least one golden function entry parsed
#   M3: Current exported zf::* function set equals golden set (no additions / removals)
#   M4: (Optional) Order check if CORE_FN_MANIFEST_STRICT_ORDER=1
#
# Environment Controls:
#   TDD_SKIP_CORE_FN_MANIFEST=1          -> Skip test
#   CORE_FN_MANIFEST_PATH=<path>         -> Override manifest path
#   CORE_FN_MANIFEST_ALLOW_SUPERSET=1    -> Allow new functions (superset) (WARN / PASS)
#   CORE_FN_MANIFEST_ALLOW_SUBSET=1      -> Allow missing functions (subset) (WARN / PASS)
#   CORE_FN_MANIFEST_STRICT_ORDER=1      -> Enforce manifest order (exact sequence)
#   CORE_FN_MANIFEST_WARN_ONLY=1         -> Never fail; emit FAIL lines but exit 0
#
# Exit Codes:
#   0 = PASS (or SKIP, or WARN-only mode)
#   1 = FAIL (differences + strict mode)
#
# Interaction with Other Tests:
#   - test-core-function-count.zsh covers minimum / golden numeric thresholds
#   - test-core-functions-namespace.zsh covers namespace hygiene & shadows
#   - This test focuses on NAME-LEVEL drift relative to curated manifest
#
# Update Workflow (when intentionally changing core functions):
#   1. Modify 10-core-functions.zsh (add/remove/rename functions).
#   2. Regenerate current list: ( zf::list_functions || functions | grep '^zf::' ).
#   3. Update the golden manifest list (alphabetical strongly recommended).
#   4. Add a rationale entry to IMPLEMENTATION.md change log.
#   5. Commit updated manifest & related test adjustments.
#
# =============================================================================

set -euo pipefail

# ---------------------------
# Skip Handling
# ---------------------------
if [[ "${TDD_SKIP_CORE_FN_MANIFEST:-0}" == "1" ]]; then
  print "SKIP: core functions manifest test skipped (TDD_SKIP_CORE_FN_MANIFEST=1)"
  exit 0
fi

# ---------------------------
# Config / Paths
# ---------------------------
SCRIPT_SRC="${(%):-%N}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$ZDOTDIR"
fi

: "${CORE_FN_MANIFEST_PATH:="${REPO_ROOT}/dot-config/zsh/docs/redesignv2/artifacts/golden/core-functions-manifest-stage3.txt"}"

# --- DEBUG PATCH: Show all relevant paths ---
zsh_debug_echo "DEBUG: PWD=$PWD"
zsh_debug_echo "DEBUG: ZDOTDIR=$ZDOTDIR"
zsh_debug_echo "DEBUG: SCRIPT_SRC=$SCRIPT_SRC"
THIS_DIR="${SCRIPT_SRC:h}"
zsh_debug_echo "DEBUG: THIS_DIR=$THIS_DIR"
zsh_debug_echo "DEBUG: REPO_ROOT=$REPO_ROOT"
zsh_debug_echo "DEBUG: CORE_FN_MANIFEST_PATH=$CORE_FN_MANIFEST_PATH"
# --- END DEBUG PATCH ---

ALLOW_SUPER=${CORE_FN_MANIFEST_ALLOW_SUPERSET:-0}
ALLOW_SUB=${CORE_FN_MANIFEST_ALLOW_SUBSET:-0}
STRICT_ORDER=${CORE_FN_MANIFEST_STRICT_ORDER:-0}
WARN_ONLY=${CORE_FN_MANIFEST_WARN_ONLY:-0}

PASS=()
FAIL=()
WARN=()

pass(){ PASS+=("$1"); }
fail(){ FAIL+=("$1"); }
warn(){ WARN+=("$1"); }

# ---------------------------
# Manifest Parsing
# ---------------------------
if [[ ! -f "$CORE_FN_MANIFEST_PATH" ]]; then
  print "SKIP: manifest file missing ($CORE_FN_MANIFEST_PATH)"
  exit 0
fi
pass "M1 manifest-present"

typeset -a GOLDEN_ORDER GOLDEN_SET
delimiter_seen=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  [[ "$line" == \#* ]] && continue
  if [[ "$line" == '---' ]]; then
    delimiter_seen=1
    continue
  fi
  (( delimiter_seen == 0 )) && continue
  # Accept only zf:: prefixed (ignore any trailing comments)
  fn="${line%% *}"
  if [[ "$fn" == zf::* ]]; then
    GOLDEN_ORDER+=("$fn")
  fi
done < "$CORE_FN_MANIFEST_PATH"

if (( ${#GOLDEN_ORDER[@]} == 0 )); then
  fail "M2 no-functions-parsed-from-manifest"
else
  pass "M2 manifest-function-count=${#GOLDEN_ORDER[@]}"
fi

# Build associative for membership
typeset -A GOLDEN_HASH
for f in "${GOLDEN_ORDER[@]}"; do
  GOLDEN_HASH["$f"]=1
done

# ---------------------------
# Current Function Enumeration
# ---------------------------
typeset -a CURRENT_FUNCS
if typeset -f zf::list_functions >/dev/null 2>&1; then
  # Reliable ordered list (implementation currently sorted)
  while IFS= read -r f; do
    [[ -n "$f" ]] && CURRENT_FUNCS+=("$f")
  done < <(zf::list_functions 2>/dev/null || true)
else
  # Fallback to raw function table enumeration
  CURRENT_FUNCS=(${(k)functions:#zf::*})
  CURRENT_FUNCS=("${(@on)CURRENT_FUNCS}")  # sort
fi

if (( ${#CURRENT_FUNCS[@]} == 0 )); then
  fail "M3 no-current-core-functions-detected"
fi

typeset -A CURRENT_HASH
for f in "${CURRENT_FUNCS[@]}"; do
  CURRENT_HASH["$f"]=1
done

# ---------------------------
# Set Comparisons
# ---------------------------
typeset -a ADDED REMOVED
# Added: in current not in golden
for f in "${CURRENT_FUNCS[@]}"; do
  [[ -z "${GOLDEN_HASH[$f]:-}" ]] && ADDED+=("$f")
done
# Removed: in golden not in current
for f in "${GOLDEN_ORDER[@]}"; do
  [[ -z "${CURRENT_HASH[$f]:-}" ]] && REMOVED+=("$f")
done

if (( ${#ADDED[@]} == 0 && ${#REMOVED[@]} == 0 )); then
  pass "M3 sets-match (no additions/removals)"
else
  if (( ${#ADDED[@]} > 0 )); then
    if (( ALLOW_SUPER == 1 )); then
      warn "M3 additions-allowed (${#ADDED[@]}): ${ADDED[*]}"
    else
      fail "M3 unexpected-additions (${#ADDED[@]}): ${ADDED[*]}"
    fi
  fi
  if (( ${#REMOVED[@]} > 0 )); then
    if (( ALLOW_SUB == 1 )); then
      warn "M3 removals-allowed (${#REMOVED[@]}): ${REMOVED[*]}"
    else
      fail "M3 unexpected-removals (${#REMOVED[@]}): ${REMOVED[*]}"
    fi
  fi
fi

# ---------------------------
# Order Check (Optional)
# ---------------------------
if (( STRICT_ORDER == 1 )); then
  # Reconstruct filtered current in golden order comparison form
  # Only compare sequence for intersection (or enforce full sequence equality?)
  # Here: enforce exact sequence equality (length + per-index)
  mismatch=0
  if (( ${#CURRENT_FUNCS[@]} != ${#GOLDEN_ORDER[@]} )); then
    mismatch=1
  else
    for i in {1..${#GOLDEN_ORDER[@]}}; do
      if [[ "${CURRENT_FUNCS[i]}" != "${GOLDEN_ORDER[i]}" ]]; then
        mismatch=1
        break
      fi
    done
  fi
  if (( mismatch )); then
    fail "M4 order-mismatch strict_order=1"
  else
    pass "M4 order-match"
  fi
else
  pass "M4 order-check-skipped"
fi

# ---------------------------
# Fingerprint (Informational)
# ---------------------------
# Fingerprint golden + current (ordered) for future drift gating
golden_fp=$(printf '%s\n' "${GOLDEN_ORDER[@]}" | sha1sum 2>/dev/null | awk '{print $1}')
current_fp=$(printf '%s\n' "${CURRENT_FUNCS[@]}" | sha1sum 2>/dev/null | awk '{print $1}')
pass "M5 golden-fingerprint=${golden_fp:-na}"
pass "M5 current-fingerprint=${current_fp:-na}"

# ---------------------------
# Reporting
# ---------------------------
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for w in "${WARN[@]}"; do
  print "WARN: $w"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} warns=${#WARN[@]} fails=${#FAIL[@]} golden_count=${#GOLDEN_ORDER[@]} current_count=${#CURRENT_FUNCS[@]} added=${#ADDED[@]} removed=${#REMOVED[@]} strict_order=${STRICT_ORDER}"

if (( ${#FAIL[@]} > 0 )) && (( WARN_ONLY == 0 )); then
  print "TEST RESULT: FAIL"
  exit 1
fi

if (( ${#FAIL[@]} > 0 )) && (( WARN_ONLY == 1 )); then
  print "TEST RESULT: WARN-ONLY (failures not enforced)"
  exit 0
fi

print "TEST RESULT: PASS"
exit 0
