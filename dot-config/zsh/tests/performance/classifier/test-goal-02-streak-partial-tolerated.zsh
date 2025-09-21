#!/usr/bin/env zsh
# test-goal-02-streak-partial-tolerated.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   T-GOAL-02 — Streak mode tolerates missing metrics. JSON should include
#   partial=true, and the classifier must exit 0 in observe mode.
#
# SCOPE:
#   - Multi-metric run: include a valid metric and a missing metric to trigger partial.
#   - Validate JSON fields: goal="streak", partial=true, and no ephemeral=true.
#   - Confirm missing metric is referenced in debug overlay (_debug.missing_metrics).
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped gracefully.
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 classifier invocation failure (unexpected in observe mode)
#   3 JSON output missing or empty
#   4 goal field mismatch (not streak)
#   5 partial flag not present/true
#   6 ephemeral should not be true in streak (unexpected)
#   7 missing metric not referenced in debug overlay
#
# USAGE:
#   zsh dotfiles/dot-config/zsh/tests/performance/classifier/test-goal-02-streak-partial-tolerated.zsh
#
# NOTES:
#   - This test asserts Phase 4/6 wiring for Streak:
#       JSON_PARTIAL_OK=1, REQUIRE_ALL_METRICS=0 → emit "partial": true when
#       missing metrics occur, and continue with rc=0 in observe mode.
#   - We explicitly set GOAL=streak to avoid environment interference.

set -euo pipefail

print_err()  { print -r -- "[goal-02-streak][err]  $*" >&2; }
print_info() { print -r -- "[goal-02-streak][info] $*" >&2; }
print_skip() { print -r -- "[goal-02-streak][skip] $*" >&2; }

# Skip if gawk is unavailable (multi-metric stats rely on gawk asort in this environment)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-02 (Streak partial tolerance)."
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

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goal02streak)"
json_out="${tmpdir}/streak-partial.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

missing_metric="nonexistent_metric_zzz"
metrics="prompt_ready,${missing_metric}"

print_info "Running classifier (GOAL=streak) with metrics='${metrics}' to trigger partial; expecting exit 0 (observe)."

set +e
GOAL=streak PERF_CLASSIFIER_DEBUG=1 \
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

# Assert goal == "streak"
goal_val="$(sed -nE 's/.*"goal"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$json_out" | head -n1)"
if [[ "${goal_val:-}" != "streak" ]]; then
  print_err "Goal mismatch in JSON: expected 'streak', got '${goal_val:-<unset>}'"
  sed -n '1,160p' "$json_out" >&2 || true
  exit 4
fi

# Assert partial=true (Streak allows partial emission)
if ! grep -q '"partial"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Expected 'partial: true' not found in JSON."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 5
fi

# Assert ephemeral should not be true in streak
if grep -q '"ephemeral"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'ephemeral: true' found in JSON for streak."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 6
fi

# Confirm missing metric is mentioned (debug overlay contains missing_metrics)
if ! grep -q "$missing_metric" "$json_out" 2>/dev/null; then
  print_err "Missing metric '${missing_metric}' not found in debug overlay."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 7
fi

print_info "PASS: Streak mode tolerated missing metric (partial=true), no ephemeral flag, exit=0 as expected."
exit 0
