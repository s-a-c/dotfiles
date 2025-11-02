#!/usr/bin/env zsh
# test-goal-05-unset-equals-streak.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   T-GOAL-05 — Unset GOAL must equal Streak semantics:
#     - goal defaults to "streak"
#     - missing metrics tolerated (partial=true) in observe mode (rc=0)
#     - no ephemeral=true
#
# SCOPE:
#   - Multi-metric run: one valid + one missing metric to trigger partial
#   - Validate JSON fields: goal="streak", partial=true, no ephemeral=true
#   - Confirm missing metric listed (debug overlay presence check)
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, skip gracefully (multi-metric stats rely on asort).
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 classifier invocation failure (unexpected in observe mode)
#   3 JSON output missing or empty
#   4 goal field mismatch (not streak)
#   5 partial flag not present/true
#   6 ephemeral should not be true in streak (unexpected)
#   7 missing metric not referenced (debug overlay)
#
# USAGE:
#   zsh dotfiles/dot-config/zsh/tests/performance/classifier/test-goal-05-unset-equals-streak.zsh
#
# NOTES:
#   - Explicitly ensure GOAL is unset/null for invocation (default → Streak semantics).

set -euo pipefail

print_err()  { print -r -- "[goal-05-unset][err]  $*" >&2; }
print_info() { print -r -- "[goal-05-unset][info] $*" >&2; }
print_skip() { print -r -- "[goal-05-unset][skip] $*" >&2; }

# Skip if gawk is unavailable (multi-metric stats need asort)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-05 (Unset GOAL equals streak semantics)."
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

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goal05unset)"
json_out="${tmpdir}/unset-equals-streak.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

missing_metric="nonexistent_metric_zzz"
metrics="prompt_ready,${missing_metric}"

print_info "Running classifier with GOAL unset (null) to validate default streak semantics."
print_info "Metrics='${metrics}' to trigger partial in observe mode (expect rc=0)."

# Ensure GOAL is null for this invocation; classifier defaults to Streak
set +e
GOAL= PERF_CLASSIFIER_DEBUG=1 \
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
  print_err "Classifier returned non-zero in observe mode (rc=${rc}); expected rc=0 under streak semantics."
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
  print_err "Expected 'partial: true' not found in JSON for default (streak) semantics."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 5
fi

# Assert ephemeral should not be true in streak
if grep -q '"ephemeral"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'ephemeral: true' found in JSON for default (streak) semantics."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 6
fi

# Confirm missing metric is mentioned (debug overlay contains missing_metrics)
if ! grep -q "$missing_metric" "$json_out" 2>/dev/null; then
  print_err "Missing metric '${missing_metric}' not found in output (debug overlay expected)."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 7
fi

print_info "PASS: Unset GOAL defaulted to streak semantics (goal=streak, partial=true, no ephemeral), rc=0 observed."
exit 0
