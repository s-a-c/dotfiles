#!/usr/bin/env zsh
# =============================================================================
# test-trust-anchors.zsh
# Category: unit / core
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate the read-only trust anchor helper APIs introduced in
#   00-security-integrity.zsh:
#     - zf::trust_anchor_has <key>
#     - zf::trust_anchor_get <key>
#     - zf::trust_anchor_keys
#     - zf::trust_anchor_dump
#
#   Ensures helpers:
#     * Exist and are functions.
#     * Expose expected default anchors (policy_version, mode).
#     * Provide deterministic, sorted key ordering.
#     * Do not mutate anchor map (pure read side-effects).
#     * Behave correctly on missing keys (non-zero return, no output).
#     * Remain idempotent across re-sourcing the security module.
#
# SCOPE:
#   Pure unit validation — does not (yet) enforce a golden list (future stages
#   may add a golden trust anchor manifest once hashing / policy anchors expand).
#
# SKIP:
#   Set TDD_SKIP_TRUST_ANCHORS=1 to skip (e.g., during rapid iteration).
#
# EXIT CODES:
#   0 = PASS (all invariants satisfied or intentionally SKIP)
#   1 = FAIL (one or more invariants violated)
#
# INVARIANTS (Ix):
#   I1: Security module file present & source succeeds.
#   I2: Helper functions are defined (typeset -f).
#   I3: Default anchors include required keys (policy_version, mode).
#   I4: zf::trust_anchor_keys output is sorted ascending (lexicographic).
#   I5: zf::trust_anchor_dump lines == key count and each line key=value maps exactly to ZF_TRUST_ANCHORS.
#   I6: has/get return success (0) and correct value for each existing key.
#   I7: has/get return failure (non-zero) and no output for missing key.
#   I8: Calling helper functions does not change anchor count / keys.
#   I9: Re-sourcing module does not change anchor count / values.
#
# FUTURE (Not enforced here):
#   - Golden manifest + hash of concatenated sorted key list.
#   - Policy checksum alignment once hashing stage implemented.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_TRUST_ANCHORS:-0}" == "1" ]]; then
  print "SKIP: trust anchor unit test skipped (TDD_SKIP_TRUST_ANCHORS=1)"
  exit 0
fi

PASS=()
FAIL=()
WARN=()

pass(){ PASS+=("$1"); }
fail(){ FAIL+=("$1"); }
warn(){ WARN+=("$1"); }

# -----------------------------------------------------------------------------
# Repo root & module resolution
# -----------------------------------------------------------------------------
SCRIPT_SRC="${(%):-%N}"
THIS_DIR="${SCRIPT_SRC:h}"
# Assume redesign module path is stable (Stage 3); adjust if structure changes.
SEC_MODULE_REL=".zshrc.d.REDESIGN/00-security-integrity.zsh"
REPO_ROOT="$(cd "$THIS_DIR/../../../.." && pwd -P 2>/dev/null)"
SEC_MODULE_PATH="${REPO_ROOT}/dot-config/zsh/${SEC_MODULE_REL}"

if [[ ! -f "$SEC_MODULE_PATH" ]]; then
  fail "I1 security-module-missing (${SEC_MODULE_PATH})"
  # Cannot proceed meaningfully; treat as soft skip with failure so CI surfaces infra issue.
  print "SUMMARY: Missing security module – aborting remaining checks."
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  exit 1
fi

# Source module (capture pre-state for idempotency comparisons)
# shellcheck disable=SC1090
if ! . "$SEC_MODULE_PATH" 2>/dev/null; then
  fail "I1 security-module-source-failed"
else
  pass "I1 security-module-source-ok"
fi

# -----------------------------------------------------------------------------
# Helper existence (I2)
# -----------------------------------------------------------------------------
HELPERS=(zf::trust_anchor_has zf::trust_anchor_get zf::trust_anchor_keys zf::trust_anchor_dump)
for fn in "${HELPERS[@]}"; do
  if typeset -f "$fn" >/dev/null 2>&1; then
    pass "I2 helper-exists:${fn}"
  else
    fail "I2 helper-missing:${fn}"
  fi
done

# If helpers missing, further checks will likely cascade; continue to gather context.

# -----------------------------------------------------------------------------
# Snapshot anchors (baseline)
# -----------------------------------------------------------------------------
typeset -A _BASE_ANCHORS
if [[ -v ZF_TRUST_ANCHORS ]]; then
  for k v in ${(kv)ZF_TRUST_ANCHORS}; do
    _BASE_ANCHORS[$k]="$v"
  done
else
  fail "I3 anchors-array-missing (ZF_TRUST_ANCHORS not defined)"
fi

BASE_KEYS=("${(k)_BASE_ANCHORS}")
BASE_KEY_COUNT=${#BASE_KEYS[@]}

# Required default keys (Stage 3 expectation)
REQUIRED_KEYS=(policy_version mode)
for rk in "${REQUIRED_KEYS[@]}"; do
  if [[ -n "${_BASE_ANCHORS[$rk]:-}" ]]; then
    pass "I3 required-key-present:${rk}"
  else
    fail "I3 required-key-missing:${rk}"
  fi
done

# -----------------------------------------------------------------------------
# I4: trust_anchor_keys sorted
# -----------------------------------------------------------------------------
if typeset -f zf::trust_anchor_keys >/dev/null 2>&1; then
  KEYS_OUTPUT="$(zf::trust_anchor_keys 2>/dev/null || true)"
  if [[ -z "$KEYS_OUTPUT" ]]; then
    fail "I4 keys-output-empty"
  else
    # Build expected sorted list from associative array keys
    EXPECT_SORTED="$(printf '%s\n' ${(on)BASE_KEYS})"
    if [[ "$KEYS_OUTPUT" == "$EXPECT_SORTED" ]]; then
      pass "I4 keys-sorted"
    else
      fail "I4 keys-not-sorted (expected sorted lexicographically)"
      print "DEBUG(keys): expected:\n$EXPECT_SORTED\nactual:\n$KEYS_OUTPUT" >&2
    fi
  fi
else
  fail "I4 keys-function-missing"
fi

# -----------------------------------------------------------------------------
# I5: trust_anchor_dump alignment
# -----------------------------------------------------------------------------
if typeset -f zf::trust_anchor_dump >/dev/null 2>&1; then
  DUMP_OUTPUT="$(zf::trust_anchor_dump 2>/dev/null || true)"
  if [[ -z "$DUMP_OUTPUT" ]]; then
    fail "I5 dump-output-empty"
  else
    # Count lines
    DUMP_COUNT=$(printf '%s\n' "$DUMP_OUTPUT" | grep -c . || true)
    if (( DUMP_COUNT != BASE_KEY_COUNT )); then
      fail "I5 dump-count-mismatch expected=${BASE_KEY_COUNT} got=${DUMP_COUNT}"
    else
      pass "I5 dump-count-match"
    fi
    # Validate each key=value line
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" != *=* ]]; then
        fail "I5 dump-line-malformed:${line}"
        continue
      fi
      local_key="${line%%=*}"
      local_val="${line#*=}"
      if [[ -z "${_BASE_ANCHORS[$local_key]:-}" ]]; then
        fail "I5 dump-key-unknown:${local_key}"
      else
        # Compare value
        if [[ "${_BASE_ANCHORS[$local_key]}" == "$local_val" ]]; then
          : # ok
        else
          fail "I5 dump-value-mismatch:${local_key} expected='${_BASE_ANCHORS[$local_key]}' got='${local_val}'"
        fi
      fi
    done <<< "$DUMP_OUTPUT"
    # If no new I5 failures added beyond structural, pass summary
    # (Individual failures already appended)
    pass "I5 dump-validated" 2>/dev/null || true
  fi
else
  fail "I5 dump-function-missing"
fi

# -----------------------------------------------------------------------------
# I6 / I7: has/get semantics (existing + missing key)
# -----------------------------------------------------------------------------
MISSING_KEY="__no_such_anchor__$$"

if typeset -f zf::trust_anchor_has >/dev/null 2>&1 && \
   typeset -f zf::trust_anchor_get >/dev/null 2>&1; then
  # Existing keys
  for k in "${REQUIRED_KEYS[@]}"; do
    if zf::trust_anchor_has "$k"; then
      pass "I6 has-existing:${k}"
    else
      fail "I6 has-missed-existing:${k}"
    fi
    GOT_VAL="$(zf::trust_anchor_get "$k" 2>/dev/null || true)"
    if [[ "$GOT_VAL" == "${_BASE_ANCHORS[$k]}" ]]; then
      pass "I6 get-existing:${k}"
    else
      fail "I6 get-value-mismatch:${k} expected='${_BASE_ANCHORS[$k]}' got='${GOT_VAL}'"
    fi
  done

  # Missing key behavior
  if zf::trust_anchor_has "$MISSING_KEY"; then
    fail "I7 has-true-for-missing:${MISSING_KEY}"
  else
    pass "I7 has-missing-ok"
  fi
  MISSING_VAL="$(zf::trust_anchor_get "$MISSING_KEY" 2>/dev/null || true)"
  if [[ -z "$MISSING_VAL" ]]; then
    pass "I7 get-missing-empty-output"
  else
    fail "I7 get-missing-nonempty-output:'$MISSING_VAL'"
  fi
else
  fail "I6 helpers-missing-for-has-get"
fi

# -----------------------------------------------------------------------------
# I8: Purity (helpers do not mutate anchor map)
# -----------------------------------------------------------------------------
# Capture state, invoke helpers repeatedly, recapture
typeset -A _AFTER_HELPERS
for _ in {1..3}; do
  zf::trust_anchor_keys >/dev/null 2>&1 || true
  zf::trust_anchor_dump >/dev/null 2>&1 || true
  zf::trust_anchor_get policy_version >/dev/null 2>&1 || true
  zf::trust_anchor_has mode >/dev/null 2>&1 || true
done
for k v in ${(kv)ZF_TRUST_ANCHORS}; do
  _AFTER_HELPERS[$k]="$v"
done

if (( ${#_AFTER_HELPERS[@]} != BASE_KEY_COUNT )); then
  fail "I8 anchor-count-changed helpers_before=${BASE_KEY_COUNT} after=${#_AFTER_HELPERS[@]}"
else
  # Compare each key
  for k in "${BASE_KEYS[@]}"; do
    if [[ "${_BASE_ANCHORS[$k]}" != "${_AFTER_HELPERS[$k]}" ]]; then
      fail "I8 anchor-value-changed:${k} before='${_BASE_ANCHORS[$k]}' after='${_AFTER_HELPERS[$k]}'"
    fi
  done
  pass "I8 helpers-pure-no-mutation"
fi

# -----------------------------------------------------------------------------
# I9: Re-source module idempotency for anchors
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
if ! . "$SEC_MODULE_PATH" 2>/dev/null; then
  fail "I9 resource-failed"
else
  # Compare anchor map again
  typeset -A _AFTER_RESOURCE
  for k v in ${(kv)ZF_TRUST_ANCHORS}; do
    _AFTER_RESOURCE[$k]="$v"
  done
  if (( ${#_AFTER_RESOURCE[@]} != BASE_KEY_COUNT )); then
    fail "I9 anchor-count-changed-on-resource before=${BASE_KEY_COUNT} after=${#_AFTER_RESOURCE[@]}"
  else
    local_changed=0
    for k in "${BASE_KEYS[@]}"; do
      if [[ "${_BASE_ANCHORS[$k]}" != "${_AFTER_RESOURCE[$k]}" ]]; then
        fail "I9 anchor-value-changed-on-resource:${k}"
        local_changed=1
      fi
    done
    if (( ! local_changed )); then
      pass "I9 resource-idempotent"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Report
# -----------------------------------------------------------------------------
if (( ${#FAIL[@]} == 0 )); then
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  print "TEST RESULT: PASS (trust anchors)"
  exit 0
else
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL (${#FAIL[@]} invariant(s) violated)"
  exit 1
fi
