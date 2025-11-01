#!/usr/bin/env zsh
# =============================================================================
# test-core-micro-bench-smoke.zsh
#
# Category: performance (smoke)
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Smoke‑test the Stage 3 core functions micro‑benchmark harness
#   (bench-core-functions.zsh) to ensure:
#     1. Harness is present & runnable.
#     2. At least one BENCH line is emitted with required fields.
#     3. Numeric fields parse as non‑negative numbers.
#     4. Basic sanity constraints: per_call_us > 0 and < an upper guard (soft).
#     5. At least one expected canonical core helper (zf::log / zf::warn /
#        zf::ensure_cmd / zf::with_timing) is represented (warn if missing).
#
# DESIGN:
#   Lightweight (small iteration count) – NOT a performance gate; purely a
#   correctness & integration guard for the harness. Does not fail CI on
#   absence of specific helpers (only missing harness or malformed output).
#
# INVARIANTS:
#   I1: Harness file exists & is executable (else SKIP).
#   I2: Harness run (iterations=50, repeat=1) exits with rc=0.
#   I3: >=1 BENCH line detected.
#   I4: Each BENCH line includes tokens:
#         name= iterations= total_ms= per_call_us= rc=
#   I5: Field values numeric / well‑formed:
#         iterations > 0, total_ms >= 0, per_call_us >= 0, rc >= 0
#   I6: At least one BENCH line corresponds to an expected core helper
#       (soft requirement → WARN if absent, not FAIL).
#   I7: per_call_us upper sanity (default threshold 5000µs) not exceeded for
#       more than MAX_OUTLIERS (default 2); else FAIL (likely harness or env issue).
#
# ENVIRONMENT OVERRIDES:
#   TDD_SKIP_CORE_MICRO_BENCH_SMOKE=1   -> Skip test.
#   CORE_MICRO_BENCH_ITER=50            -> Iteration override.
#   CORE_MICRO_BENCH_REPEAT=1           -> Repeat override.
#   CORE_MICRO_BENCH_MAX_PER_US=5000    -> Upper per-call µs sanity threshold.
#   CORE_MICRO_BENCH_MAX_OUTLIERS=2     -> Allowed count above threshold.
#
# EXIT CODES:
#   0 PASS / SKIP
#   1 FAIL
#
# FUTURE EXTENSIONS:
#   - Parse JSON output (--json) for stable schema validation.
#   - Compare against stored baseline median per_call_us (warn mode).
#   - Integrate micro totals into perf ledger pseudo segment.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_CORE_MICRO_BENCH_SMOKE:-0}" == "1" ]]; then
  print "SKIP: core micro-benchmark smoke (TDD_SKIP_CORE_MICRO_BENCH_SMOKE=1)"
  exit 0
fi

PASS=()
FAIL=()
WARN=()

pass(){ PASS+=("$1"); }
fail(){ FAIL+=("$1"); }
warn(){ WARN+=("$1"); }

# Configuration
ITER="${CORE_MICRO_BENCH_ITER:-50}"
REPEAT="${CORE_MICRO_BENCH_REPEAT:-1}"
MAX_PER_US="${CORE_MICRO_BENCH_MAX_PER_US:-5000}"
MAX_OUTLIERS="${CORE_MICRO_BENCH_MAX_OUTLIERS:-2}"

SCRIPT_SRC="${(%):-%N}"
THIS_DIR="${SCRIPT_SRC:h}"
REPO_ROOT="$(cd "$THIS_DIR/../../../.." && pwd -P 2>/dev/null)"

HARNESS="${REPO_ROOT}/dot-config/zsh/tests/performance/core-functions/bench-core-functions.zsh"

if [[ ! -f "$HARNESS" ]]; then
  print "SKIP: harness missing ($HARNESS)"
  exit 0
fi

if [[ ! -x "$HARNESS" ]]; then
  # Try to make executable silently; if fails we still proceed (may source)
  chmod +x "$HARNESS" 2>/dev/null || true
fi

if [[ ! -x "$HARNESS" ]]; then
  fail "I1 harness-not-executable"
  print "TEST RESULT: FAIL"
  exit 1
else
  pass "I1 harness-present-executable"
fi

# Execute harness (machine lines appear on stdout)
# Use --machine-only to suppress human table noise
OUTPUT="$(
  BENCH_ITER="$ITER" BENCH_REPEAT="$REPEAT" \
  "$HARNESS" --iterations "$ITER" --repeat "$REPEAT" --machine-only 2>/dev/null || echo "__HARNESS_FAILED__$?"
)"

if grep -q "__HARNESS_FAILED__" <<<"$OUTPUT"; then
  fail "I2 harness-execution-failed"
  print "DEBUG: Raw harness output:"
  print -- "$OUTPUT"
  print "TEST RESULT: FAIL"
  exit 1
fi
pass "I2 harness-executed"

# Collect BENCH lines
BENCH_LINES="$(grep '^BENCH ' <<<"$OUTPUT" || true)"
LINE_COUNT=$(print -r -- "$BENCH_LINES" | grep -c '^BENCH ' || true)

if (( LINE_COUNT == 0 )); then
  fail "I3 zero-bench-lines"
else
  pass "I3 bench-lines-count=${LINE_COUNT}"
fi

# If no bench lines, abort further parsing
if (( LINE_COUNT == 0 )); then
  print "TEST RESULT: FAIL"
  exit 1
fi

# Expected tokens
EXPECTED=(name= iterations= total_ms= per_call_us= rc=)
MALFORMED=0
NUMERIC_FAIL=0
OUTLIERS=0
HAVE_EXPECTED_CORE=0
CORE_CANDIDATES=(zf::log zf::warn zf::ensure_cmd zf::with_timing zf::timed)

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # Token presence
  for tok in "${EXPECTED[@]}"; do
    if ! grep -q " ${tok}" <<<"$line"; then
      (( MALFORMED++ ))
      break
    fi
  done

  # Extract fields (simple sed/awk parsing)
  name=$(sed -n 's/.* name=\([^ ]*\).*/\1/p' <<<"$line")
  iterations=$(sed -n 's/.* iterations=\([0-9]*\).*/\1/p' <<<"$line")
  total_ms=$(sed -n 's/.* total_ms=\([0-9.]*\).*/\1/p' <<<"$line")
  per_call_us=$(sed -n 's/.* per_call_us=\([0-9.]*\).*/\1/p' <<<"$line")
  rc=$(sed -n 's/.* rc=\([0-9]*\).*/\1/p' <<<"$line")

  # Numeric validations
  num_re='^[0-9]+([.][0-9]+)?$'
  int_re='^[0-9]+$'
  if [[ ! "$iterations" =~ $int_re || "$iterations" -lt 1 ]]; then
    (( NUMERIC_FAIL++ ))
  fi
  if [[ ! "$total_ms" =~ $num_re || ! "$per_call_us" =~ $num_re || ! "$rc" =~ $int_re ]]; then
    (( NUMERIC_FAIL++ ))
  fi
  # Non-negative
  if [[ "$total_ms" == -* || "$per_call_us" == -* ]]; then
    (( NUMERIC_FAIL++ ))
  fi
  # Outlier check
  # Convert per_call_us float to integer ceiling for comparison via awk
  is_outlier=$(awk -v v="$per_call_us" -v max="$MAX_PER_US" 'BEGIN{if (v>max)print 1; else print 0}')
  if [[ "$is_outlier" == "1" ]]; then
    (( OUTLIERS++ ))
  fi

  # Expected core helper presence detection
  for c in "${CORE_CANDIDATES[@]}"; do
    if [[ "$name" == "$c" ]]; then
      HAVE_EXPECTED_CORE=1
      break
    fi
  done

done <<<"$BENCH_LINES"

if (( MALFORMED == 0 )); then
  pass "I4 tokens-present-all-lines"
else
  fail "I4 malformed-lines=${MALFORMED}"
fi

if (( NUMERIC_FAIL == 0 )); then
  pass "I5 numeric-fields-valid"
else
  fail "I5 numeric-parse-failures=${NUMERIC_FAIL}"
fi

if (( HAVE_EXPECTED_CORE == 1 )); then
  pass "I6 expected-core-helper-seen"
else
  warn "I6 expected-core-helper-missing (non-fatal)"
fi

if (( OUTLIERS <= MAX_OUTLIERS )); then
  pass "I7 per-call-us-within-threshold outliers=${OUTLIERS}/${MAX_OUTLIERS} threshold=${MAX_PER_US}us"
else
  fail "I7 per-call-outliers-exceeded outliers=${OUTLIERS} threshold=${MAX_PER_US}us"
fi

# ---------------- Summary ----------------
if (( ${#FAIL[@]} == 0 )); then
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  print "TEST RESULT: PASS (core micro-benchmark smoke)"
  exit 0
else
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL (${#FAIL[@]} invariant(s) violated)"
  exit 1
fi
