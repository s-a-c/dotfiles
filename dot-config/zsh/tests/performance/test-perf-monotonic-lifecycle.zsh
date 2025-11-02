#!/usr/bin/env zsh
# =============================================================================
# test-perf-monotonic-lifecycle.zsh
#
# Category: performance (lifecycle ordering)
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md)
#
# PURPOSE:
#   Validate (Stage 3 → Stage 4 transition readiness) that core lifecycle
#   timing metrics obey monotonic ordering:
#
#       pre_plugin_total <= post_plugin_total <= prompt_ready
#
#   This relationship is critical for:
#     - Reasoning about incremental costs added after pre-plugin phase
#     - Avoiding inverted or partial captures that can hide regressions
#     - Trusting variance stability and drift analyses that assume ordering
#
#   The test works in two modes:
#     * Non-strict (default): Zero or missing post/prompt values produce WARN,
#       and monotonic violations also WARN (still PASS overall). Suitable while
#       instrumentation for post_plugin_total / prompt_ready is stabilizing.
#     * Strict: (PERF_MONOTONIC_STRICT=1) Any invariant violation becomes FAIL.
#
# DATA SOURCES (attempted in order):
#   1. perf-current-segments.txt  (SEGMENT lines: SEGMENT name=<label> ms=<int> ...)
#   2. perf-current.json          (fields: pre_plugin_cost_ms, post_plugin_cost_ms,
#                                  prompt_ready_ms)
#
# INVARIANTS:
#   I1: At least one data source found (segments or JSON)            (WARN->FAIL strict if absent)
#   I2: pre_plugin_total parsed & numeric > 0 (else WARN)            (FAIL strict)
#   I3: post_plugin_total parsed & numeric (zero allowed non-strict) (FAIL strict if <=0)
#   I4: prompt_ready parsed & numeric (zero allowed non-strict)      (FAIL strict if <=0)
#   I5: If all three > 0, enforce pre <= post <= prompt              (WARN non-strict / FAIL strict)
#
# OUTPUT:
#   PASS:, WARN:, FAIL: lines then final line:
#     TEST RESULT: PASS | FAIL | SKIP
#
# EXIT CODES:
#   0  Test passed (or only warnings / skip)
#   1  One or more FAIL (strict or fundamental invariant)
#
# ENVIRONMENT:
#   PERF_MONOTONIC_SEGMENTS_FILE   (default docs/redesignv2/artifacts/metrics/perf-current-segments.txt)
#   PERF_MONOTONIC_JSON_FILE       (default docs/redesignv2/artifacts/metrics/perf-current.json)
#   PERF_MONOTONIC_STRICT=1        (fail on WARN-class issues)
#   TDD_SKIP_PERF_MONOTONIC=1      (skip test)
#
# FUTURE ENHANCEMENTS:
#   - Correlate values against multi-sample aggregate means.
#   - Add threshold drift classification (e.g., post - pre delta growth watch).
#   - Export machine-readable JSON summarizing monotonic evaluation for gating.
#   - Cross-check with variance stability log entries for coherence.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_PERF_MONOTONIC:-0}" == "1" ]]; then
  print "SKIP: lifecycle monotonic test (TDD_SKIP_PERF_MONOTONIC=1)"
  exit 0
fi

: "${PERF_MONOTONIC_SEGMENTS_FILE:=docs/redesignv2/artifacts/metrics/perf-current-segments.txt}"
: "${PERF_MONOTONIC_JSON_FILE:=docs/redesignv2/artifacts/metrics/perf-current.json}"
: "${PERF_MONOTONIC_STRICT:=0}"

PASS=()
WARN=()
FAIL=()

pass(){ PASS+=("$1"); }
warn(){ WARN+=("$1"); }
fail(){ FAIL+=("$1"); }

strict_fail_or_warn() {
  local msg="$1"
  if (( PERF_MONOTONIC_STRICT )); then
    fail "$msg"
  else
    warn "$msg"
  fi
}

# ---------------- Data Extraction Helpers ----------------
integer_or_zero() {
  [[ "$1" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  echo "$1"
}

parse_segments() {
  local file="$1"
  local label="$2"
  # Use last occurrence
  local line
  line=$(grep -E "SEGMENT name=${label} " "$file" 2>/dev/null | tail -1 || true)
  [[ -z "$line" ]] && return 1
  local ms
  ms=$(sed -n 's/.* name='"$label"' .* ms=\([0-9][0-9]*\).*/\1/p' <<<"$line")
  [[ -z "$ms" ]] && return 2
  integer_or_zero "$ms"
  return 0
}

parse_json_field() {
  local file="$1" field="$2"
  # Grep/sed lightweight (no jq dependency required)
  local raw
  raw=$(grep -E "\"${field}\"" "$file" 2>/dev/null | head -1 | sed -E 's/.*"'"${field}"'":[[:space:]]*([0-9]+).*/\1/' || true)
  integer_or_zero "${raw:-0}"
}

# ---------------- Primary Extraction ----------------
src_used=""

pre= post= prompt=

if [[ -f "$PERF_MONOTONIC_SEGMENTS_FILE" ]]; then
  pre=$(parse_segments "$PERF_MONOTONIC_SEGMENTS_FILE" pre_plugin_total || true)
  post=$(parse_segments "$PERF_MONOTONIC_SEGMENTS_FILE" post_plugin_total || true)
  prompt=$(parse_segments "$PERF_MONOTONIC_SEGMENTS_FILE" prompt_ready || true)

  if [[ -n "$pre$post$prompt" ]]; then
    src_used="segments"
    pass "I1 source-detected (segments)"
  fi
fi

if [[ -z "$src_used" && -f "$PERF_MONOTONIC_JSON_FILE" ]]; then
  pre=$(parse_json_field "$PERF_MONOTONIC_JSON_FILE" pre_plugin_cost_ms)
  post=$(parse_json_field "$PERF_MONOTONIC_JSON_FILE" post_plugin_cost_ms)
  prompt=$(parse_json_field "$PERF_MONOTONIC_JSON_FILE" prompt_ready_ms)
  src_used="json"
  pass "I1 source-detected (json)"
fi

if [[ -z "$src_used" ]]; then
  strict_fail_or_warn "I1 no-data-source (segments/json missing)"
  # Fundamental: cannot continue meaningful checks
  # If strict => FAIL; else WARN but still exit success since gating not possible.
  if (( PERF_MONOTONIC_STRICT )); then
    for f in "${FAIL[@]}"; do print "FAIL: $f"; done
    for w in "${WARN[@]}"; do print "WARN: $w"; done
    print "TEST RESULT: FAIL"
    exit 1
  else
    for p in "${PASS[@]}"; do print "PASS: $p"; done
    for w in "${WARN[@]}"; do print "WARN: $w"; done
    print "TEST RESULT: PASS"
    exit 0
  fi
fi

# Normalize empties
pre=${pre:-0}
post=${post:-0}
prompt=${prompt:-0}

# ---------------- Invariant Evaluation ----------------
if (( pre > 0 )); then
  pass "I2 pre_plugin_total>0 (${pre}ms)"
else
  strict_fail_or_warn "I2 pre_plugin_total-nonpositive (${pre})"
fi

if (( post >= 0 )); then
  if (( post > 0 )); then
    pass "I3 post_plugin_total>=0 (${post}ms)"
  else
    strict_fail_or_warn "I3 post_plugin_total-zero (${post})"
  fi
else
  strict_fail_or_warn "I3 post_plugin_total-invalid (${post})"
fi

if (( prompt >= 0 )); then
  if (( prompt > 0 )); then
    pass "I4 prompt_ready>=0 (${prompt}ms)"
  else
    strict_fail_or_warn "I4 prompt_ready-zero (${prompt})"
  fi
else
  strict_fail_or_warn "I4 prompt_ready-invalid (${prompt})"
fi

# Only enforce ordering when all strictly >0
if (( pre > 0 && post > 0 && prompt > 0 )); then
  ordering_ok=1
  if (( pre > post )); then
    ordering_ok=0
    strict_fail_or_warn "I5 ordering-violation pre>post (${pre}>${post})"
  fi
  if (( post > prompt )); then
    ordering_ok=0
    strict_fail_or_warn "I5 ordering-violation post>prompt (${post}>${prompt})"
  fi
  if (( ordering_ok )); then
    pass "I5 monotonic-ok pre=${pre} <= post=${post} <= prompt=${prompt}"
  fi
else
  warn "I5 monotonic-deferred (one or more zero values) pre=${pre} post=${post} prompt=${prompt}"
fi

# ---------------- Report & Exit ----------------
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
