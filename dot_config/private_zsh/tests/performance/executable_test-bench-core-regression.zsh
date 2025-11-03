#!/usr/bin/env zsh
# =============================================================================
# test-bench-core-regression.zsh
#
# Category: performance (micro benchmark – warn-only Stage 3 harness)
#
# PURPOSE:
#   Compare a freshly captured (or provided) micro benchmark JSON for core
#   helper functions (zf:: namespace) against a stored baseline
#   (bench-core-baseline.json) and surface potential per‑call latency
#   regressions. Stage 3 intent is OBSERVATIONAL / WARN-ONLY: the test
#   should not fail CI yet unless explicitly placed in strict mode.
#
# STAGE 3 MODE:
#   - WARN on regressions > BENCH_CORE_REGRESS_WARN_FACTOR (default 2.0x).
#   - (Optional) FAIL only if BENCH_CORE_STRICT=1 and regression exceeds
#     BENCH_CORE_REGRESS_FAIL_FACTOR (default 3.0x).
#   - If any shimmed functions appear in baseline or current capture,
#     skip ratio enforcement (warn) because dispatch overhead only.
#
# BASELINE / CURRENT:
#   baseline file (expected): docs/redesignv2/artifacts/metrics/bench-core-baseline.json
#   current file (optional):  BENCH_CORE_CURRENT_FILE variable or generated ad‑hoc.
#
# GENERATING CURRENT (when none supplied):
#   Harness: tests/performance/core-functions/bench-core-functions.zsh
#   Iterations/Repeat tuned lower than canonical baseline for speed while
#   still producing stable medians (iterations=3000 repeat=2 by default).
#
# OUTPUT:
#   PASS:, WARN:, FAIL: lines
#   Final summary: TEST RESULT: PASS|FAIL
#
# EXIT CODES:
#   0 success (including warn-only mode)
#   1 failure (only in strict mode OR fundamental invariant break)
#
# INVARIANTS (I*):
#   I1 baseline file exists & non-empty
#   I2 current file captured / available
#   I3 schema == bench-core.v1 in both
#   I4 If shimmed_count > 0 in either → WARN & skip ratio checks
#   I5 Function name sets identical (WARN if drift)
#   I6 median_per_call_us numeric for all functions (WARN otherwise)
#   I7 regression ratio > warn-factor ⇒ WARN (unless skip)
#   I8 regression ratio > fail-factor ⇒ FAIL only if strict
#
# ENVIRONMENT:
#   BENCH_CORE_BASELINE_FILE      (default docs/redesignv2/artifacts/metrics/bench-core-baseline.json)
#   BENCH_CORE_CURRENT_FILE       (if provided, skip ad-hoc capture)
#   BENCH_CORE_CAPTURE_ITER       (default 3000)
#   BENCH_CORE_CAPTURE_REPEAT     (default 2)
#   BENCH_CORE_REGRESS_WARN_FACTOR (default 2.0)
#   BENCH_CORE_REGRESS_FAIL_FACTOR (default 3.0)
#   BENCH_CORE_STRICT=1           (enable fail on severe regressions)
#   BENCH_CORE_HARNESS            (override path to bench-core-functions.zsh)
#   TDD_SKIP_BENCH_CORE=1         (skip test)
#
# FUTURE (post Stage 3):
#   - Integrate percentile statistics when repeat>2
#   - JSON schema version gating
#   - Drifts aggregated into governance badge
#   - Adaptive threshold from historical rolling baseline
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_BENCH_CORE:-0}" == "1" ]]; then
  print "SKIP: micro benchmark regression test (TDD_SKIP_BENCH_CORE=1)"
  exit 0
fi

# ---------------- Configuration ----------------
: "${BENCH_CORE_BASELINE_FILE:=docs/redesignv2/artifacts/metrics/bench-core-baseline.json}"
: "${BENCH_CORE_CURRENT_FILE:=}"
: "${BENCH_CORE_CAPTURE_ITER:=3000}"
: "${BENCH_CORE_CAPTURE_REPEAT:=2}"
: "${BENCH_CORE_REGRESS_WARN_FACTOR:=2.0}"
: "${BENCH_CORE_REGRESS_FAIL_FACTOR:=3.0}"
: "${BENCH_CORE_STRICT:=0}"
: "${BENCH_CORE_HARNESS:=tests/performance/core-functions/bench-core-functions.zsh}"

PASS=()
WARN=()
FAIL=()

pass(){ PASS+=("$1"); }
warn(){ WARN+=("$1"); }
fail(){ FAIL+=("$1"); }

strict_maybe_fail() {
  # Promote to FAIL only if strict; else WARN
  local msg="$1"
  if (( BENCH_CORE_STRICT )); then
    fail "$msg"
  else
    warn "$msg"
  fi
}

float_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

# ---------------- I1 Baseline Presence ----------------
if [[ ! -s "$BENCH_CORE_BASELINE_FILE" ]]; then
  fail "I1 baseline-missing ($BENCH_CORE_BASELINE_FILE)"
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL"
  exit 1
else
  pass "I1 baseline-present"
fi

# ---------------- Acquire Current Capture (if needed) ----------------
current_tmp=""
if [[ -z "$BENCH_CORE_CURRENT_FILE" ]]; then
  if [[ -x "$BENCH_CORE_HARNESS" || -f "$BENCH_CORE_HARNESS" ]]; then
    current_tmp="$(mktemp -t bench-core-current.XXXXXX.json)"
    BENCH_CORE_CURRENT_FILE="$current_tmp"
    # Use harness (non-fatal if harness fails -> we'll detect)
    set +e
    zsh "$BENCH_CORE_HARNESS" --json --iterations "$BENCH_CORE_CAPTURE_ITER" --repeat "$BENCH_CORE_CAPTURE_REPEAT" --output-json "$BENCH_CORE_CURRENT_FILE" >/dev/null 2>&1
    rc=$?
    set -e
    if (( rc != 0 )) || [[ ! -s "$BENCH_CORE_CURRENT_FILE" ]]; then
      warn "I2 harness-capture-failed rc=$rc (proceeding without current data -> test aborts)"
      fail "I2 current-capture-missing"
      for p in "${PASS[@]}"; do print "PASS: $p"; done
      for w in "${WARN[@]}"; do print "WARN: $w"; done
      for f in "${FAIL[@]}"; do print "FAIL: $f"; done
      print "TEST RESULT: FAIL"
      [[ -n "$current_tmp" ]] && rm -f "$current_tmp" 2>/dev/null || true
      exit 1
    fi
    pass "I2 current-captured harness=${BENCH_CORE_HARNESS}"
  else
    warn "I2 harness-not-found ($BENCH_CORE_HARNESS) and BENCH_CORE_CURRENT_FILE unset"
    fail "I2 current-missing"
    for f in "${FAIL[@]}"; do print "FAIL: $f"; done
    print "TEST RESULT: FAIL"
    exit 1
  fi
else
  if [[ ! -s "$BENCH_CORE_CURRENT_FILE" ]]; then
    fail "I2 current-file-empty ($BENCH_CORE_CURRENT_FILE)"
    for f in "${FAIL[@]}"; do print "FAIL: $f"; done
    print "TEST RESULT: FAIL"
    exit 1
  fi
  pass "I2 current-present ($BENCH_CORE_CURRENT_FILE)"
fi

# ---------------- Helpers to Extract JSON (fallback if no jq) ----------------
extract_json_value() {
  local file="$1" key="$2"
  if (( have_jq )); then
    jq -r --arg k "$key" '.[$k] // empty' "$file" 2>/dev/null || true
  else
    grep -E "\"$key\"" "$file" 2>/dev/null | head -1 | sed -E 's/.*"'$key'":[[:space:]]*"([^"]*)".*/\1/' || true
  fi
}

extract_schema() {
  local file="$1"
  if (( have_jq )); then
    jq -r '.schema // empty' "$file" 2>/dev/null || true
  else
    grep -E '"schema"' "$file" | head -1 | sed -E 's/.*"schema"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || true
  fi
}

extract_shimmed_count() {
  local file="$1"
  if (( have_jq )); then
    jq -r '.shimmed_count // 0' "$file" 2>/dev/null || echo 0
  else
    grep -E '"shimmed_count"' "$file" | head -1 | sed -E 's/.*"shimmed_count"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || echo 0
  fi
}

# Return list of function names (sorted)
extract_function_names() {
  local file="$1"
  if (( have_jq )); then
    jq -r '.functions[]?.name' "$file" 2>/dev/null | sort
  else
    grep -E '"name"' "$file" 2>/dev/null | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' | sort
  fi
}

# Extract median per-call (µs) for function
extract_fn_median_us() {
  local file="$1" fn="$2"
  if (( have_jq )); then
    jq -r --arg n "$fn" '.functions[]?|select(.name==$n)|.median_per_call_us' "$file" 2>/dev/null | head -1
  else
    # Greedy: assume function block on single line (since harness emits compact objects)
    grep -E "\"name\":\"$fn\"" "$file" 2>/dev/null | sed -E 's/.*"median_per_call_us":([0-9.]+).*/\1/' | head -1
  fi
}

# ---------------- I3 Schema Validation ----------------
baseline_schema=$(extract_schema "$BENCH_CORE_BASELINE_FILE")
current_schema=$(extract_schema "$BENCH_CORE_CURRENT_FILE")

if [[ "$baseline_schema" != "bench-core.v1" ]]; then
  strict_maybe_fail "I3 baseline-schema-mismatch ('$baseline_schema')"
else
  pass "I3 baseline-schema-ok"
fi
if [[ "$current_schema" != "bench-core.v1" ]]; then
  strict_maybe_fail "I3 current-schema-mismatch ('$current_schema')"
else
  pass "I3 current-schema-ok"
fi

# ---------------- I4 Shim Check ----------------
baseline_shim=$(extract_shimmed_count "$BENCH_CORE_BASELINE_FILE")
current_shim=$(extract_shimmed_count "$BENCH_CORE_CURRENT_FILE")

if [[ -z "$baseline_shim" ]]; then baseline_shim=0; fi
if [[ -z "$current_shim" ]]; then current_shim=0; fi

if (( baseline_shim > 0 || current_shim > 0 )); then
  warn "I4 shimmed-present baseline=${baseline_shim} current=${current_shim} (skipping regression ratios)"
  shim_skip=1
else
  pass "I4 no-shims baseline=0 current=0"
  shim_skip=0
fi

# ---------------- I5 Function Set Drift ----------------
baseline_fns=($(extract_function_names "$BENCH_CORE_BASELINE_FILE"))
current_fns=($(extract_function_names "$BENCH_CORE_CURRENT_FILE"))

typeset -A base_set curr_set
for f in "${baseline_fns[@]}"; do base_set["$f"]=1; done
for f in "${current_fns[@]}"; do curr_set["$f"]=1; done

missing=()
added=()
for f in "${baseline_fns[@]}"; do [[ -z "${curr_set[$f]:-}" ]] && missing+=("$f"); done
for f in "${current_fns[@]}"; do [[ -z "${base_set[$f]:-}" ]] && added+=("$f"); done

if (( ${#missing[@]} == 0 && ${#added[@]} == 0 )); then
  pass "I5 function-set-stable count=${#baseline_fns[@]}"
else
  drift_msg="I5 function-set-drift"
  [[ ${#missing[@]} -gt 0 ]] && drift_msg+=" missing=${(j:,:)missing}"
  [[ ${#added[@]} -gt 0 ]] && drift_msg+=" added=${(j:,:)added}"
  strict_maybe_fail "$drift_msg"
fi

# ---------------- I6 / I7 / I8 Regression Ratios ----------------
if (( shim_skip == 0 )); then
  # Build comparison only for intersection
  common=()
  for f in "${baseline_fns[@]}"; do
    [[ -n "${curr_set[$f]:-}" ]] && common+=("$f")
  done

  warn_factor="$BENCH_CORE_REGRESS_WARN_FACTOR"
  fail_factor="$BENCH_CORE_REGRESS_FAIL_FACTOR"

  float_valid='^[0-9]+([.][0-9]+)?$'

  for f in "${common[@]}"; do
    b_us=$(extract_fn_median_us "$BENCH_CORE_BASELINE_FILE" "$f")
    c_us=$(extract_fn_median_us "$BENCH_CORE_CURRENT_FILE" "$f")
    # Fallback if empty
    [[ -z "$b_us" ]] && b_us="0"
    [[ -z "$c_us" ]] && c_us="0"

    if ! [[ "$b_us" =~ $float_valid && "$c_us" =~ $float_valid ]]; then
      warn "I6 non-numeric-median fn=$f baseline='$b_us' current='$c_us'"
      continue
    fi

    # If baseline is 0 but current >0, can't compute ratio (treat as WARN)
    if awk -v b="$b_us" 'BEGIN{exit !(b==0)}'; then
      if awk -v c="$c_us" 'BEGIN{exit !(c>0)}'; then
        warn "I6 baseline-zero fn=$f current_us=$c_us (cannot ratio)"
      fi
      continue
    fi

    ratio=$(awk -v c="$c_us" -v b="$b_us" 'BEGIN{if(b==0){print 0}else{printf "%.4f", c/b}}')

    # Evaluate thresholds
    if float_ge "$ratio" "$fail_factor"; then
      strict_maybe_fail "I7 severe-regression fn=$f baseline=${b_us}us current=${c_us}us ratio=${ratio} (>=${fail_factor}x)"
    elif float_ge "$ratio" "$warn_factor"; then
      warn "I7 regression fn=$f baseline=${b_us}us current=${c_us}us ratio=${ratio} (>=${warn_factor}x)"
    else
      pass "I7 ok fn=$f ratio=${ratio}"
    fi
  done
else
  warn "I7 skipped-regression-checks (shimmed baseline or current)"
fi

# ---------------- Report ----------------
if (( ${#FAIL[@]} == 0 )); then
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  print "TEST RESULT: PASS"
  rc=0
else
  for p in "${PASS[@]}"; do print "PASS: $p"; done
  for w in "${WARN[@]}"; do print "WARN: $w"; done
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  print "TEST RESULT: FAIL (${#FAIL[@]} invariant(s))"
  rc=1
fi

# Cleanup temp current file if we created one
[[ -n "${current_tmp:-}" ]] && rm -f "$current_tmp" 2>/dev/null || true

exit $rc
