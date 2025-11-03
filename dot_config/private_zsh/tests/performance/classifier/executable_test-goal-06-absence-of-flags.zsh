#!/usr/bin/env zsh
# test-goal-06-absence-of-flags.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   T-GOAL-06 — Verify absence of conditional JSON flags when conditions are not met.
#   In a normal run (no missing metrics, no synthetic marker preview, non-explore goal),
#   the JSON output must NOT include:
#     - "partial": true
#     - "ephemeral": true
#     - "synthetic_used": true
#
# SCOPE:
#   - Multi-metric mode with a single valid metric to avoid partial conditions.
#   - GOAL=streak (non-explore) so ephemeral should not be present.
#   - Do not enable synthetic marker preview; synthetic_used should remain unset/absent.
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped gracefully
#     (multi-metric stats rely on asort in this environment).
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 classifier invocation failure (unexpected in observe mode)
#   3 JSON output missing or empty
#   4 goal field mismatch (not streak)
#   5 unexpected 'ephemeral: true' present
#   6 unexpected 'partial: true' present
#   7 unexpected 'synthetic_used: true' present
#
# USAGE:
#   zsh .config/zsh/tests/performance/classifier/test-goal-06-absence-of-flags.zsh
#
# NOTES:
#   - This test targets Phase 6 JSON semantics where conditional fields are only emitted
#     when the corresponding condition is satisfied. In a clean, non-synthetic, non-explore,
#     non-partial run, those flags must be absent.

set -euo pipefail

print_err()  { print -r -- "[goal-06-absence][err]  $*" >&2; }
print_info() { print -r -- "[goal-06-absence][info] $*" >&2; }
print_skip() { print -r -- "[goal-06-absence][skip] $*" >&2; }

# Skip if gawk is unavailable (multi-metric stats rely on gawk asort in this environment)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-06 (absence of flags)."
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

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goal06absence)"
json_out="${tmpdir}/absence-of-flags.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

metrics="prompt_ready"

print_info "Running classifier (GOAL=streak) with metrics='${metrics}' expecting no partial/ephemeral/synthetic_used flags."

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

# The following flags must NOT be present with value 'true'
if grep -q '"ephemeral"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'ephemeral: true' present in JSON."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 5
fi

if grep -q '"partial"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'partial: true' present in JSON."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 6
fi

if grep -q '"synthetic_used"[[:space:]]*:[[:space:]]*true' "$json_out" 2>/dev/null; then
  print_err "Unexpected 'synthetic_used: true' present in JSON."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 7
fi

print_info "PASS: No conditional flags present (partial/ephemeral/synthetic_used) under clean streak run."
exit 0
