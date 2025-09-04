#!/usr/bin/env zsh
# =============================================================================
# test-perf-drift-badge-presence.zsh
#
# Category: performance (badge / observability)
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate (WARN mode during Stage 3) presence & basic structural correctness of the
#   performance drift badge JSON produced by tools/perf-drift-badge.sh.
#   This ensures downstream documentation and infra-health aggregation can rely
#   on a stable artifact before enforcing any gating logic.
#
# SCOPE (Stage 3 – Warn Mode):
#   - Missing or malformed badge file => WARN (unless STRICT enabled).
#   - Invalid / unexpected fields => WARN.
#   - Only escalate to FAIL when PERF_DRIFT_BADGE_STRICT=1 (opt-in later).
#
# INVARIANTS:
#   I1: Badge file exists (WARN if missing; FAIL only in strict mode).
#   I2: JSON contains required top-level keys: label, message, color.
#   I3: label == "perf drift" (exact match).
#   I4: color in {green,yellow,red,lightgrey}.
#   I5: If message matches /fail/ then WARN (not FAIL in warn mode) unless STRICT.
#   I6: If message includes a "+X" regression suffix then X parses as number (WARN if not).
#
# OUTPUT:
#   PASS:, WARN:, FAIL: lines followed by TEST RESULT: PASS|FAIL
#
# EXIT CODES:
#   0 = All enforced invariants satisfied (or only warnings in non-strict mode)
#   1 = Failure (only when STRICT and an invariant is violated)
#
# ENVIRONMENT:
#   PERF_DRIFT_BADGE_FILE=path     (default docs/redesignv2/artifacts/badges/perf-drift.json)
#   PERF_DRIFT_BADGE_STRICT=1      (treat WARN-class violations as FAIL)
#   TDD_SKIP_PERF_DRIFT_BADGE=1    (skip test)
#
# FUTURE (post Stage 3):
#   - Enforce presence as FAIL.
#   - Correlate max regression pct with ledger embedding.
#   - Add JSON schema version & validate.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_PERF_DRIFT_BADGE:-0}" == "1" ]]; then
  print "SKIP: perf drift badge presence test (TDD_SKIP_PERF_DRIFT_BADGE=1)"
  exit 0
fi

: "${PERF_DRIFT_BADGE_FILE:=docs/redesignv2/artifacts/badges/perf-drift.json}"
: "${PERF_DRIFT_BADGE_STRICT:=0}"

PASS=()
WARN=()
FAIL=()

pass(){ PASS+=("$1"); }
warn(){ WARN+=("$1"); }
fail(){ FAIL+=("$1"); }

strict_fail() {
  if (( PERF_DRIFT_BADGE_STRICT )); then
    fail "$1"
  else
    warn "$1"
  fi
}

if [[ ! -f "$PERF_DRIFT_BADGE_FILE" ]]; then
  strict_fail "I1 badge-missing ($PERF_DRIFT_BADGE_FILE)"
  # No further parsing possible
else
  pass "I1 badge-file-present"

  raw="$(<"$PERF_DRIFT_BADGE_FILE" 2>/dev/null || true)"

  if [[ -z "$raw" ]]; then
    strict_fail "I2 empty-file"
  else
    # Detect JSON presence quickly
    if ! grep -q '"label"' <<<"$raw" || ! grep -q '"message"' <<<"$raw" || ! grep -q '"color"' <<<"$raw"; then
      strict_fail "I2 missing-required-keys"
    else
      pass "I2 keys-present-basic"
    fi

    # Prefer jq if available
    have_jq=0
    command -v jq >/dev/null 2>&1 && have_jq=1

    label=""
    message=""
    color=""

    if (( have_jq )); then
      label=$(jq -r '.label // empty' "$PERF_DRIFT_BADGE_FILE" 2>/dev/null || true)
      message=$(jq -r '.message // empty' "$PERF_DRIFT_BADGE_FILE" 2>/dev/null || true)
      color=$(jq -r '.color // empty' "$PERF_DRIFT_BADGE_FILE" 2>/dev/null || true)
    else
      # Fallback heuristic extraction
      label=$(sed -n 's/.*"label"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$raw" | head -1)
      message=$(sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$raw" | head -1)
      color=$(sed -n 's/.*"color"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$raw" | head -1)
    fi

    if [[ "$label" == "perf drift" ]]; then
      pass "I3 correct-label"
    elif [[ -n "$label" ]]; then
      strict_fail "I3 unexpected-label:'$label'"
    else
      strict_fail "I3 label-missing"
    fi

    case "$color" in
      green|yellow|red|lightgrey)
        pass "I4 color-valid($color)"
        ;;
      "")
        strict_fail "I4 color-missing"
        ;;
      *)
        strict_fail "I4 color-invalid($color)"
        ;;
    esac

    # Regression severity inspection
    if [[ "$message" == *"fail"* ]]; then
      # In warn mode this is a warning only; release gating would escalate.
      strict_fail "I5 fail-severity-observed message='$message'"
    elif [[ -n "$message" ]]; then
      pass "I5 message-present"
    else
      strict_fail "I5 message-empty"
    fi

    # Detect +X% max suffix (e.g., "+7.1% max")
    if grep -Eq '\+\d+(\.\d+)?% max' <<<"$message"; then
      pass "I6 max-regression-suffix-detected"
      # Extract numeric
      suffix_num=$(sed -n 's/.*+\([0-9]\+\(\.[0-9]\+\)\?\)% max.*/\1/p' <<<"$message")
      if [[ ! "$suffix_num" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        strict_fail "I6 suffix-numeric-parse-failed raw='$message'"
      fi
    else
      warn "I6 no-max-regression-suffix (expected once drift badge enhancement active)"
    fi
  fi
fi

# Summary / Exit
if (( ${#FAIL[@]} == 0 )); then
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  print "TEST RESULT: PASS"
  exit 0
else
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL (${#FAIL[@]} invariant(s) failed)"
  exit 1
fi
