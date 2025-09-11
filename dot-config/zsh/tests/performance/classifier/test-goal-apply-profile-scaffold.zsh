#!/usr/bin/env zsh
# test-goal-apply-profile-scaffold.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Phase 3 scaffold test to verify that the classifier emits the internal GOAL
#   profile flags debug line when PERF_CLASSIFIER_DEBUG=1 is set.
#   This is a placeholder test that only asserts presence of the debug line and
#   expected key tokens; it does NOT validate behavioral gating (still inert).
#
# SCOPE (Phase 3):
#   - Ensures debug output includes normalized goal and the flags map.
#   - Validates the presence of all expected flag tokens in the debug line.
#   - Iterates across: streak, governance, explore, ci.
#
# SKIP CONDITION:
#   - If GNU awk (gawk) is not available in PATH, the test is skipped gracefully.
#
# PASS CRITERIA:
#   - For each goal, the classifier prints a line to stderr:
#       "[perf-classifier][dbg] goal=<normalized_goal> flags: syn=... req_all=... hard=... phased=... soft=... partial_ok=... eph=..."
#   - All key tokens appear at least once in the debug line.
#
# FAILURE MODES:
#   - Classifier missing or not executable.
#   - Debug line not found for any goal.
#   - Missing required tokens in the flags map.
#
# USAGE:
#   zsh tests/performance/classifier/test-goal-apply-profile-scaffold.zsh
#
# NOTES:
#   - This test intentionally does not request JSON output to minimize code paths and
#     reduce sources of flakiness. It uses legacy single-metric mode for resilience.
#   - Behavior remains inert in Phase 3; this only checks that flags are exported and logged.

set -euo pipefail

print_err()  { print -r -- "[goal-profile-test][err]  $*" >&2; }
print_info() { print -r -- "[goal-profile-test][info] $*" >&2; }
print_skip() { print -r -- "[goal-profile-test][skip] $*" >&2; }

# Skip if gawk is unavailable (placeholder policy)
if ! command -v gawk >/dev/null 2>&1; then
  print_skip "gawk not found in PATH; skipping GOAL flags debug assertion."
  exit 0
fi

script_dir="${0:A:h}"
root_dir="${script_dir:A}/../../.."
root_dir="$(cd "$root_dir" && pwd)"

classifier="${root_dir}/tools/perf-regression-classifier.zsh"
# Ensure executable if present
if [[ ! -x "$classifier" && -f "$classifier" ]]; then
  chmod +x "$classifier" 2>/dev/null || true
fi
[[ -x "$classifier" ]] || { print_err "Classifier not executable: $classifier"; exit 1; }

tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t goalflags)"
log_file="${tmpdir}/stderr.log"
mkdir -p -- "${root_dir}/artifacts/metrics" 2>/dev/null || true

# Goals to verify
goals=( streak governance explore ci )

# Required flag tokens to be present in the debug line
required_tokens=( "syn=" "req_all=" "hard=" "phased=" "soft=" "partial_ok=" "eph=" )

# Run per-goal and assert debug line presence + tokens
for g in "${goals[@]}"; do
  print_info "Testing debug flags emission for goal=${g}"

  # Invoke classifier; tolerate non-zero exit (we only assert debug line presence)
  if ! PERF_CLASSIFIER_DEBUG=1 "$classifier" \
        --runs 1 \
        --metric prompt_ready_ms \
        --mode observe \
        --warn-threshold 10 \
        --fail-threshold 25 \
        --baseline-dir "${root_dir}/artifacts/metrics" \
        --quiet \
        --goal "$g" \
        1>/dev/null 2>>"$log_file"
  then
    print_info "Classifier exited non-zero for goal=${g}; continuing since we only assert debug output."
  fi

  # Normalized expected goal (classifier lowercases)
  expected_goal="${g:l}"

  # Find the latest debug line for this goal
  dbg_line="$(grep -F "[perf-classifier][dbg] goal=${expected_goal} flags:" "$log_file" | tail -n1 || true)"
  if [[ -z "${dbg_line:-}" ]]; then
    print_err "Missing debug flags line for goal=${expected_goal}"
    print_err "---- stderr (tail) ----"
    tail -n 40 "$log_file" 2>/dev/null || true
    rm -rf "$tmpdir"
    exit 2
  fi

  # Check all required tokens appear
  for tok in "${required_tokens[@]}"; do
    if [[ "$dbg_line" != *"$tok"* ]]; then
      print_err "Debug line missing token '${tok}' for goal=${expected_goal}"
      print_err "Line: $dbg_line"
      rm -rf "$tmpdir"
      exit 3
    fi
  done

  print_info "PASS: goal=${expected_goal} debug flags line present with all tokens."
done

print_info "All profile debug checks passed."
rm -rf "$tmpdir"
exit 0
