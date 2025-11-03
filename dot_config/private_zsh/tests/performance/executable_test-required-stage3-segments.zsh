#!/usr/bin/env zsh
# =============================================================================
# test-required-stage3-segments.zsh
#
# Category: performance
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Stage 3 requires consistent emission of core lifecycle performance markers
#   so that variance gating, drift detection, and regression enforcement can
#   advance from observe → warn → gate. This test verifies presence and basic
#   integrity of required segment markers in the canonical segments file.
#
#   Required segment labels:
#     - pre_plugin_total
#     - post_plugin_total
#     - prompt_ready
#
#   These correspond to JSON fields: pre_plugin_cost_ms, post_plugin_cost_ms,
#   prompt_ready_ms (multi-sample aggregation & gating rely on them).
#
# INVARIANTS (Ix):
#   I1: Segment file exists and is readable.
#   I2: Each required label appears at least once as a SEGMENT line.
#   I3: Extracted ms values are numeric (integer).
#   I4: At least $STAGE3_SEGMENTS_MIN_NONZERO (default 2) of the required
#       segments have ms > 0 (signals instrumentation actually ran).
#   I5: If PERF_STAGE3_SEGMENTS_STRICT=1 then any required segment with ms=0
#       is a FAIL (strict gate); otherwise zero values downgrade to WARN
#       (still pass overall unless other failures).
#
# OUTPUT:
#   PASS:, WARN:, FAIL: lines followed by TEST RESULT: PASS|FAIL
#
# EXIT CODES:
#   0 - All enforced invariants satisfied (or SKIP)
#   1 - One or more enforced invariants failed
#
# SKIP CONDITIONS:
#   - TDD_SKIP_STAGE3_REQUIRED_SEGMENTS=1
#
# ENVIRONMENT OVERRIDES:
#   STAGE3_SEGMENTS_FILE=path/to/perf-current-segments.txt
#       (Default: docs/redesignv2/artifacts/metrics/perf-current-segments.txt)
#   STAGE3_SEGMENTS_MIN_NONZERO=<N>   (default 2)
#   PERF_STAGE3_SEGMENTS_STRICT=1     (treat zero ms as FAIL instead of WARN)
#   TDD_SKIP_STAGE3_REQUIRED_SEGMENTS=1   (skip test)
#
# RATIONALE:
#   A zero or missing post_plugin_total or prompt_ready value in multi-sample
#   aggregation leads to false stability signals and prevents safe gating.
#   Enforcing early ensures subsequent variance log entries are meaningful.
#
# FUTURE ENHANCEMENTS:
#   - Parse and validate correlation with perf-current.json values.
#   - Enforce monotonic ordering constraints (pre <= post <= prompt).
#   - Integrate with a drift JSON schema once unified ledger diff exposes
#     derived regression data directly.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_STAGE3_REQUIRED_SEGMENTS:-0}" == "1" ]]; then
  print "SKIP: stage3 required segment marker test (TDD_SKIP_STAGE3_REQUIRED_SEGMENTS=1)"
  exit 0
fi

# ---------------- Configuration ----------------
: "${STAGE3_SEGMENTS_FILE:=docs/redesignv2/artifacts/metrics/perf-current-segments.txt}"
: "${STAGE3_SEGMENTS_MIN_NONZERO:=2}"
: "${PERF_STAGE3_SEGMENTS_STRICT:=0}"

# Required labels (ordered for reporting)
typeset -a REQUIRED_LABELS
REQUIRED_LABELS=(pre_plugin_total post_plugin_total prompt_ready)

PASS=()
FAIL=()
WARN=()

pass(){ PASS+=("$1"); }
fail(){ FAIL+=("$1"); }
warn(){ WARN+=("$1"); }

# ---------------- I1: File existence ----------------
if [[ ! -f "$STAGE3_SEGMENTS_FILE" ]]; then
  fail "I1 segments-file-missing ($STAGE3_SEGMENTS_FILE)"
  # Fatal to proceed meaningfully
  goto_report=1
else
  if [[ ! -r "$STAGE3_SEGMENTS_FILE" ]]; then
    fail "I1 segments-file-not-readable ($STAGE3_SEGMENTS_FILE)"
    goto_report=1
  else
    pass "I1 segments-file-present"
  fi
fi

if [[ "${goto_report:-0}" == "1" ]]; then
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL"
  exit 1
fi

# ---------------- I2/I3: Presence + numeric parse ----------------
typeset -A SEG_VALUES SEG_LINE
missing=0
for label in "${REQUIRED_LABELS[@]}"; do
  # Extract last occurrence to minimize partial/incomplete earlier lines
  line=$(grep -E "SEGMENT name=${label} " "$STAGE3_SEGMENTS_FILE" 2>/dev/null | tail -1 || true)
  if [[ -z "$line" ]]; then
    fail "I2 missing-label:${label}"
    (( missing++ ))
    continue
  fi
  SEG_LINE[$label]="$line"
  # Extract ms=<int>
  ms=$(sed -n 's/.* name='"$label"' .* ms=\([0-9][0-9]*\).*/\1/p' <<<"$line")
  if [[ -z "$ms" ]]; then
    fail "I3 non-numeric-ms:${label}"
    continue
  fi
  SEG_VALUES[$label]="$ms"
done

if (( missing == 0 )); then
  pass "I2 all-required-labels-present"
fi

# If any missing labels, keep evaluating others (surfacing all issues).

# Numeric verification for present labels
numeric_fail=0
for label in "${REQUIRED_LABELS[@]}"; do
  [[ -z "${SEG_VALUES[$label]:-}" ]] && continue
  if [[ ! "${SEG_VALUES[$label]}" =~ ^[0-9]+$ ]]; then
    fail "I3 invalid-numeric:${label} value='${SEG_VALUES[$label]}'"
    (( numeric_fail++ ))
  fi
done
if (( numeric_fail == 0 )); then
  pass "I3 numeric-parse-ok"
fi

# ---------------- I4/I5: Non-zero coverage & strict handling ----------------
nonzero_count=0
zero_labels=()

for label in "${REQUIRED_LABELS[@]}"; do
  val="${SEG_VALUES[$label]:-}"
  [[ -z "$val" ]] && continue
  if (( val > 0 )); then
    (( nonzero_count++ ))
  else
    zero_labels+=("$label")
  fi
done

if (( nonzero_count >= STAGE3_SEGMENTS_MIN_NONZERO )); then
  pass "I4 nonzero-threshold-met count=${nonzero_count}/${#REQUIRED_LABELS[@]}"
else
  # If labels missing already flagged, keep failure classification separate.
  fail "I4 insufficient-nonzero count=${nonzero_count} required>=${STAGE3_SEGMENTS_MIN_NONZERO}"
fi

if (( ${#zero_labels[@]} > 0 )); then
  if (( PERF_STAGE3_SEGMENTS_STRICT )); then
    fail "I5 zero-values-strict labels=${(j:,:)zero_labels}"
  else
    warn "I5 zero-values-non-strict labels=${(j:,:)zero_labels}"
  fi
else
  pass "I5 no-zero-values"
fi

# ---------------- Optional Consistency (Monotonic heuristic) ----------------
# Heuristic: prompt_ready should be >= pre_plugin_total and >= post_plugin_total (when non-zero)
# Note: If prompt == post (common), that's acceptable.
if [[ -n "${SEG_VALUES[prompt_ready]:-}" && -n "${SEG_VALUES[post_plugin_total]:-}" ]]; then
  pr=${SEG_VALUES[prompt_ready]}
  po=${SEG_VALUES[post_plugin_total]}
  pre=${SEG_VALUES[pre_plugin_total]:-0}
  # Only evaluate if both > 0
  if (( pr > 0 && po > 0 )); then
    if (( pr < po || pr < pre )); then
      # Soft warning (instrumentation ordering can adjust)
      warn "M1 prompt-ready-monotonic-suspect prompt=${pr} post=${po} pre=${pre}"
    else
      pass "M1 prompt-ready-monotonic-ok"
    fi
  fi
fi

# ---------------- Report ----------------
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
