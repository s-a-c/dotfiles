#!/usr/bin/env zsh
# test-goal-03-governance-missing-metric-fail.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   T-GOAL-03 — Governance strictness for missing metrics must be classification-fatal in enforce mode.
#   When one or more requested metrics are missing, the classifier should exit non-zero in enforce mode,
#   and JSON should not include "partial": true (governance is not tolerant), but debug overlay should
#   indicate missing metrics.
#
# SCOPE:
#   - Multi-metric invocation with one valid metric and one intentionally missing metric.
#   - GOAL=governance, enforce mode → expect non-zero exit (preferably 3).
#   - JSON verification:
#       * goal == "governance"
#       * no "partial": true (JSON_PARTIAL_OK=0 for governance)
#       * _debug.missing_metrics contains the missing metric name
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped (multi-metric stats rely on asort).
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 expected non-zero exit not observed (governance strictness not enforced)
#   3 JSON output missing or empty
#   4 goal field mismatch (not governance)
#   5 unexpected 'partial: true' present (should not be emitted under governance)
#   6 missing metric not referenced in debug overlay
#
# USAGE:
#   zsh dotfiles/dot-config/zsh/tests/performance/classifier/test-goal-03-governance-missing-metric-fail.zsh
#
# NOTES:
#   - This test depends on Phase 4 gating via GOAL flags and Phase 6 JSON emission rules.
#   - Synthetic fallback is not part of this test; only missing-metric governance strictness is verified.

set -euo pipefail

print_err()  { print -r -- "[goal-03-gov-missing][err]  $*" >&2; }
print_info() { print -r -- "[goal-03-gov-missing][info] $*" >&2; }
print_skip() { print -r -- "[goal-03-gov-missing][skip] $*" >&2; }

# Skip if gawk is unavailable (multi-metric stats rely on gawk asort in this environment)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-03 (Governance missing-metric fail)."
  exit 0
fi

script_dir="${0:A:h}"
root_dir="${script_dir:A}/../../.."
root_dir="$(cd "$root_dir" && pwd)"

classifier="${root_dir}/tools/perf-regression-classifier.zsh"
[[ -f "$classifier" ]] || { print_err "Classifier not found at: $classifier"; exit 1; }
[[ -x "$classifier" ]] || chmod +x "$classifier" 2>/dev/null || true
[[ -x "$classifier" ]] || { print_err "Classifier not executable: $classifier"; exit 1; }

mkdir -p -- "${root_dir}/artifacts/metrics" 2>/dev/null || true

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goal03gov)"
json_out="${tmpdir}/governance-missing-metric.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

# Compose metrics to trigger partial: include one known-good and one intentionally missing key
missing_metric="nonexistent_metric_zzz"
metrics="prompt_ready,${missing_metric}"

print_info "Running classifier (GOAL=governance, enforce) with metrics='${metrics}' to trigger missing metrics → expect non-zero exit."

set +e
GOAL=governance PERF_CLASSIFIER_DEBUG=1 \
  "$classifier" \
    --runs 1 \
    --metrics "$metrics" \
    --mode enforce \
    --warn-threshold 10 \
    --fail-threshold 25 \
    --baseline-dir "${root_dir}/artifacts/metrics" \
    --json-out "$json_out" \
    --quiet
rc=$?
set -e

# Governance strictness should return non-zero (prefer 3) due to missing metrics disallowed
if [[ "$rc" -eq 0 ]]; then
  print_err "Expected non-zero exit in governance enforce mode when metrics are missing, got 0."
  exit 2
fi
print_info "Classifier returned non-zero as expected (rc=${rc})."

# Verify JSON written
if [[ ! -s "$json_out" ]]; then
  print_err "JSON output missing or empty: $json_out"
  exit 3
fi

# Verify goal field equals "governance"
goal_val="$(sed -nE 's/.*"goal"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$json_out" | head -n1)"
if [[ "${goal_val:-}" != "governance" ]]; then
  print_err "Goal mismatch in JSON: expected 'governance', got '${goal_val:-<unset>}'"
  sed -n '1,200p' "$json_out" >&2 || true
  exit 4
fi

# Governance should NOT emit partial=true
if grep -q '"partial"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'partial: true' present in JSON under governance."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 5
fi

# Confirm missing metric is mentioned (debug overlay contains missing_metrics)
if ! grep -q "$missing_metric" "$json_out" 2>/dev/null; then
  print_err "Missing metric '${missing_metric}' not found in debug overlay; expected in _debug.missing_metrics."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 6
fi

print_info "PASS: Governance enforces fail on missing metrics; JSON verified (no partial flag; missing metric recorded in debug overlay)."
exit 0
