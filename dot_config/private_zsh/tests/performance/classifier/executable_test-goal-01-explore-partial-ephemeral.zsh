#!/usr/bin/env zsh
# test-goal-01-explore-partial-ephemeral.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   T-GOAL-01 — Explore mode should tolerate missing metrics (partial=true) and
#   emit ephemeral=true. Classifier must exit 0 in observe mode.
#
# SCOPE:
#   - Multi-metric run: include a known-good metric and a missing metric key to trigger partial.
#   - Validate JSON fields: goal="explore", ephemeral=true, partial=true.
#   - Confirm missing metric listed in debug overlay (string presence check).
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped gracefully.
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 classifier invocation failure (unexpected in observe mode)
#   3 JSON output missing or empty
#   4 goal field mismatch (not explore)
#   5 ephemeral flag not present/true
#   6 partial flag not present/true
#   7 missing metric not referenced in debug overlay
#
# USAGE:
#   zsh .config/zsh/tests/performance/classifier/test-goal-01-explore-partial-ephemeral.zsh
#
# NOTES:
#   - This test asserts behavior from Phase 4/6 wiring:
#       Explore: EPHEMERAL_FLAG=1, JSON_PARTIAL_OK=1 → emit "ephemeral": true and "partial": true
#         when missing metric(s) occur.
#   - We do not assert synthetic_used in this test.

set -euo pipefail

print_err()  { print -r -- "[goal-01-explore][err]  $*" >&2; }
print_info() { print -r -- "[goal-01-explore][info] $*" >&2; }
print_skip() { print -r -- "[goal-01-explore][skip] $*" >&2; }

# Skip if gawk is unavailable (multi-metric stats rely on gawk asort in this environment)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-01 (Explore partial + ephemeral)."
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

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goal01explore)"
json_out="${tmpdir}/explore-partial-ephemeral.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

missing_metric="nonexistent_metric_zzz"
metrics="prompt_ready,${missing_metric}"

print_info "Running classifier (GOAL=explore) with metrics='${metrics}' to trigger partial; expecting exit 0 (observe)."

set +e
GOAL=explore PERF_CLASSIFIER_DEBUG=1 \
  "$classifier" \
    --runs 1 \
    --metrics "$metrics" \
    --mode observe \
    --warn-threshold 10 \
    --fail-threshold 25 \
    --baseline-dir "${root_dir}/artifacts/metrics" \
    --json-out "$json_out" \
    --quiet
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  print_err "Classifier returned non-zero in observe mode (rc=${rc}); expected rc=0."
  exit 2
fi

[[ -s "$json_out" ]] || { print_err "JSON output missing or empty: $json_out"; exit 3; }

# Assert goal == "explore"
goal_val="$(sed -nE 's/.*\"goal\"[[:space:]]*:[[:space:]]*\"([^"]+)\".*/\1/p' "$json_out" | head -n1)"
if [[ "${goal_val:-}" != "explore" ]]; then
  print_err "Goal mismatch in JSON: expected 'explore', got '${goal_val:-<unset>}'"
  sed -n '1,160p' "$json_out" >&2 || true
  exit 4
fi

# Assert ephemeral=true
if ! grep -q '"ephemeral"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Expected 'ephemeral: true' not found in JSON."
  sed -n '1,160p' "$json_out" >&2 || true
  exit 5
fi

# Assert partial=true (Explore allows partial emission)
if ! grep -q '"partial"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Expected 'partial: true' not found in JSON."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 6
fi

# Confirm missing metric is mentioned (debug overlay contains missing_metrics; structure may be a single string)
if ! grep -q "$missing_metric" "$json_out" 2>/dev/null; then
  print_err "Missing metric '${missing_metric}' not found in debug overlay."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 7
fi

print_info "PASS: Explore mode emitted ephemeral=true, partial=true; missing metric detected; exit=0 as expected."
exit 0
