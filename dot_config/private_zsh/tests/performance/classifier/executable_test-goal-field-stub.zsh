#!/usr/bin/env zsh
# test-goal-field-stub.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Phase 2 scaffold test for GOAL profile integration in the performance classifier.
#   Verifies that the classifier emits a "goal" field in its JSON output when invoked,
#   defaulting to "streak" (case-insensitive) if GOAL is unset, or matching the explicitly
#   provided value when --goal / GOAL environment variable is used.
#
# SCOPE (Phase 2):
#   - Only asserts presence & value of "goal".
#   - Does NOT yet validate gating (synthetic, partial, ephemeral) — those appear in later phases.
#
# PASS CRITERIA:
#   1. Classifier run produces JSON output file.
#   2. JSON contains a "goal" key.
#   3. Value matches expected profile normalization rules:
#        - Unset → "streak"
#        - Explicit (case-insensitive) → normalized lowercase form
#
# FAILURE MODES:
#   - Missing JSON file
#   - No "goal" key
#   - Value mismatch vs expectation
#   - Classifier invocation non-zero exit (unexpected in observe mode)
#
# ENV VARS (for future extension):
#   TEST_GOAL_OVERRIDE   If set, test will invoke classifier with that goal (e.g. Governance)
#
# EXIT CODES:
#   0 success
#   1 internal usage / environment issue
#   2 classifier invocation failure
#   3 goal field missing
#   4 goal value mismatch
#
# FUTURE EXTENSIONS (Next Phases):
#   - T-GOAL-01..06: partial flag, synthetic gating, ephemeral flag (Explore), strictness behaviors.
#   - Add schema presence assertions for absence of flags when not applicable.
#
# USAGE:
#   zsh tests/performance/classifier/test-goal-field-stub.zsh
#
# ------------------------------------------------------------------------------

set -euo pipefail

print_err() { print -r -- "[goal-test][err] $*" >&2; }
print_info() { print -r -- "[goal-test][info] $*" >&2; }
# Skip if gawk not available to avoid awk asort dependency in environments lacking GNU awk
if ! command -v gawk >/dev/null 2>&1; then
  print -r -- "[goal-test][skip] gawk not found in PATH; skipping GOAL field stub." >&2
  exit 0
fi

script_dir="${0:A:h}"
root_dir="${script_dir:A}/../../.."
root_dir="$(cd "$root_dir" && pwd)"

classifier="${root_dir}/tools/perf-regression-classifier.zsh"
[[ -x "$classifier" ]] || { print_err "Classifier not executable: $classifier"; exit 1; }

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goaltest)"
json_out="${tmpdir}/goal-output.json"

requested_goal="${TEST_GOAL_OVERRIDE:-}"
goal_arg=()
expected_goal="streak"

if [[ -n "$requested_goal" ]]; then
  # Normalize expectation to lowercase
  lower="${requested_goal:l}"
  expected_goal="$lower"
  goal_arg=(--goal "$requested_goal")
  print_info "Testing explicit GOAL override: $requested_goal (expected normalized=${expected_goal})"
else
  print_info "Testing default GOAL behavior (expected=streak)"
fi

# Minimal legacy single-metric run (prompt_ready_ms) with 1 iteration to reduce time.
# Using observe mode to avoid non-zero exits in current phase.
if ! "$classifier" \
      --runs 1 \
      --metric prompt_ready_ms \
      --mode observe \
      --warn-threshold 10 \
      --fail-threshold 25 \
      --baseline-dir "${root_dir}/artifacts/metrics" \
      --json-out "$json_out" \
      --quiet \
      "${goal_arg[@]}" ; then
  print_err "Classifier invocation failed (unexpected in observe mode)."
  rm -rf "$tmpdir"
  exit 2
fi

[[ -s "$json_out" ]] || { print_err "JSON output missing or empty: $json_out"; rm -rf "$tmpdir"; exit 3; }

# Goal presence check
if ! grep -q '"goal"' "$json_out" 2>/dev/null; then
  print_err "No 'goal' field found in JSON output."
  sed -n '1,120p' "$json_out" >&2 || true
  rm -rf "$tmpdir"
  exit 3
fi

# Extract value (simple grep/sed; jq not required for this stub)
actual_goal=$(sed -n 's/.*"goal":[[:space:]]*"\([^"]\+\)".*/\1/p' "$json_out" | head -n1)

if [[ -z "${actual_goal:-}" ]]; then
  print_err "Unable to parse goal value from JSON."
  sed -n '1,120p' "$json_out" >&2 || true
  rm -rf "$tmpdir"
  exit 3
fi

if [[ "$actual_goal" != "$expected_goal" ]]; then
  print_err "Goal value mismatch: expected='${expected_goal}' got='${actual_goal}'"
  sed -n '1,120p' "$json_out" >&2 || true
  rm -rf "$tmpdir"
  exit 4
fi

print_info "PASS: goal='${actual_goal}' (expected='${expected_goal}') JSON field present."
print_info "File: $json_out"

rm -rf "$tmpdir"
exit 0
