#!/usr/bin/env zsh
# test-goal-04-ci-strictness.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   T-GOAL-04 — CI strictness mirrors Governance. When synthetic fallback segments
#   are inserted, the classifier must enforce non‑zero exit in CI mode.
#
# SCOPE:
#   - Single-metric path (prompt_ready_ms) to minimize variability.
#   - Uses marker-based synthetic detection; requires marker preview enabled.
#   - Confirms non-zero exit (preferably 3) in enforce mode when synthetic is disallowed.
#   - Verifies JSON output exists and contains goal=ci.
#   - Confirms _debug.synthetic_used=1 (top-level 'synthetic_used' should not be present in CI).
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped. The classifier’s
#     stats calc relies on asort in this environment.
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 expected non-zero exit not observed (CI strictness not enforced)
#   3 JSON output missing or empty
#   4 goal field mismatch (not ci)
#   5 _debug.synthetic_used not detected as 1
#
# USAGE:
#   zsh dotfiles/dot-config/zsh/tests/performance/classifier/test-goal-04-ci-strictness.zsh
#
# NOTES:
#   - This test toggles PERF_SYNTHETIC_MARKER_PREVIEW=1 to ensure the capture runner
#     writes a synthetic marker when fallback emission occurs.
#   - Gating is driven by GOAL profile flags (Phase 4 wiring), not preview envs.

set -euo pipefail

print_err()  { print -r -- "[goal-ci-test][err]  $*" >&2; }
print_info() { print -r -- "[goal-ci-test][info] $*" >&2; }
print_skip() { print -r -- "[goal-ci-test][skip] $*" >&2; }

# Skip if gawk is unavailable (classifier stats need asort)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping T-GOAL-04 (CI strictness)."
  exit 0
fi

script_dir="${0:A:h}"
root_dir="${script_dir:A}/../../.."
root_dir="$(cd "$root_dir" && pwd)"

classifier="${root_dir}/tools/perf-regression-classifier.zsh"
if [[ ! -f "$classifier" ]]; then
  print_err "Classifier not found at: $classifier"
  exit 1
fi
# Ensure executable bit
if [[ ! -x "$classifier" ]]; then
  chmod +x "$classifier" 2>/dev/null || true
fi
[[ -x "$classifier" ]] || { print_err "Classifier not executable: $classifier"; exit 1; }

# Ensure baseline dir exists
mkdir -p -- "${root_dir}/artifacts/metrics" 2>/dev/null || true

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goalci)"
json_out="${tmpdir}/ci-enforce.json"
cleanup() { rm -rf "$tmpdir" 2>/dev/null || true; }
trap cleanup EXIT

print_info "Running classifier in CI mode with enforce + synthetic marker preview"

# Run classifier with:
# - GOAL=ci (strict: disallow synthetic fallback)
# - PERF_SYNTHETIC_MARKER_PREVIEW=1 (emit marker when fallback occurs)
# - enforce mode (non-zero expected if synthetic is used)
set +e
GOAL=ci PERF_SYNTHETIC_MARKER_PREVIEW=1 PERF_CLASSIFIER_DEBUG=1 \
  "$classifier" \
    --runs 1 \
    --metric prompt_ready_ms \
    --mode enforce \
    --warn-threshold 10 \
    --fail-threshold 25 \
    --baseline-dir "${root_dir}/artifacts/metrics" \
    --json-out "$json_out" \
    --quiet
rc=$?
set -e

# CI strictness should return non-zero (prefer 3) due to synthetic disallowed
if [[ "$rc" -eq 0 ]]; then
  print_err "Expected non-zero exit in CI enforce mode when synthetic is used, got 0."
  exit 2
fi
print_info "Classifier returned non-zero as expected (rc=${rc})."

# Verify JSON written
if [[ ! -s "$json_out" ]]; then
  print_err "JSON output missing or empty: $json_out"
  exit 3
fi

# Verify goal field equals "ci"
goal_val="$(sed -nE 's/.*"goal"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$json_out" | head -n1)"
if [[ "${goal_val:-}" != "ci" ]]; then
  print_err "Goal mismatch in JSON: expected 'ci', got '${goal_val:-<unset>}'"
  sed -n '1,160p' "$json_out" >&2 || true
  exit 4
fi

# Verify _debug.synthetic_used == 1 (marker-driven detection)
dbg_syn="$(sed -nE 's/.*"_debug"[^{]*\{[^}]*"synthetic_used"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$json_out" | head -n1)"
if [[ "${dbg_syn:-0}" -ne 1 ]]; then
  print_err "Debug overlay did not report synthetic_used=1 (got '${dbg_syn:-<unset>}')."
  sed -n '1,200p' "$json_out" >&2 || true
  exit 5
fi

print_info "PASS: CI strictness enforced (non-zero exit) with synthetic marker present; JSON verified."
exit 0
