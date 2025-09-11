#!/usr/bin/env zsh
# test-classifier-baselines.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Validate presence (and minimal integrity) of per-metric performance baseline files
#   used by the multi-metric regression classifier:
#     - pre_plugin_total
#     - post_plugin_total
#     - prompt_ready
#     - deferred_total
#
#   This guards against silent drift where a metric stops emitting or its baseline
#   is accidentally deleted, which would cause spurious BASELINE_CREATED states or
#   hide regressions.
#
# MODES:
#   - Default (observe): FAIL if any baseline missing.
#   - Bootstrap (when ALLOW_BASELINE_CREATE=1): If any baseline missing, invoke the
#       classifier in observe mode to create them, then re-validate.
#   - Hard enforce (when ENFORCE_BASELINES=1): ALWAYS fail if any baseline is created
#       during the test (i.e., the test itself should not be doing baseline creation).
#
# ENVIRONMENT VARIABLES:
#   PERF_BASELINE_DIR         Override baseline directory (default: ./artifacts/metrics)
#   CLASSIFIER_PATH           Override path to perf-regression-classifier.zsh
#   RUNS                      Number of runs for (optional) baseline bootstrap (default: 3)
#   ALLOW_BASELINE_CREATE=1   Permit automatic baseline creation if missing (observe use)
#   ENFORCE_BASELINES=1       Treat any missing baseline as immediate failure (no creation)
#   QUIET=1                   Suppress PASS detail lines
#
# EXIT CODES:
#   0 Success (all required baselines present & valid)
#   1 Usage / internal invocation error
#   2 Baseline(s) missing and not created (or enforce mode)
#   3 Baseline file exists but failed integrity sanity checks
#   4 Classifier bootstrap attempt failed
#
# SANITY CHECKS (minimal):
#   - File exists and readable
#   - Contains `"metric": "<metric>_ms"` (legacy naming) OR `"mean_ms":`
#   - JSON appears non-empty and not truncated (size > 10 bytes)
#
# NOTES:
#   We intentionally do not parse with jq here to keep this test runnable in
#   minimal environments (classifier already depends on jq in CI; this remains lenient).
#
# FUTURE ENHANCEMENTS:
#   - Add RSD / runs field presence validation
#   - Cross-check timestamp freshness vs allowable staleness window
#   - Integrate into a combined “telemetry integrity” meta test
#
# USAGE:
#   zsh tests/performance/telemetry/test-classifier-baselines.zsh
#
# -----------------------------------------------------------------------------

set -euo pipefail

QUIET=${QUIET:-0}
ALLOW_BASELINE_CREATE=${ALLOW_BASELINE_CREATE:-0}
ENFORCE_BASELINES=${ENFORCE_BASELINES:-0}
RUNS=${RUNS:-3}

script_dir="${(%):-%N:h}"
# Assuming path: dot-config/zsh/tests/performance/telemetry
# Root (dot-config/zsh) = script_dir/../../..
root_dir="${script_dir:A}/../../.."
root_dir="$(cd "$root_dir" && pwd)"

# Default baseline directory (aligns with CI workflow)
PERF_BASELINE_DIR="${PERF_BASELINE_DIR:-${root_dir}/artifacts/metrics}"

CLASSIFIER_PATH="${CLASSIFIER_PATH:-${root_dir}/tools/perf-regression-classifier.zsh}"

metrics=(
  pre_plugin_total
  post_plugin_total
  prompt_ready
  deferred_total
)

pass() { (( QUIET )) || print -r -- "PASS: $*"; }
fail() { print -r -- "FAIL: $*" >&2; exit "${2:-2}"; }
info() { (( QUIET )) || print -r -- "INFO: $*"; }
warn() { print -r -- "WARN: $*" >&2; }

[[ -d "$PERF_BASELINE_DIR" ]] || {
  if (( ALLOW_BASELINE_CREATE )) && ((! ENFORCE_BASELINES)); then
    info "Creating missing baseline directory: $PERF_BASELINE_DIR"
    mkdir -p -- "$PERF_BASELINE_DIR" || fail "Unable to create baseline directory $PERF_BASELINE_DIR" 1
  else
    fail "Baseline directory missing: $PERF_BASELINE_DIR"
  fi
}

missing=()
invalid=()

validate_file() {
  local metric="$1"
  local f="${PERF_BASELINE_DIR}/${metric}-baseline.json"
  if [[ ! -r "$f" ]]; then
    missing+=("$metric")
    return 0
  fi
  local size
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' ' || echo 0)
  (( size > 10 )) || { invalid+=("$metric:too_small"); return 0; }
  # Basic content sniffing
  if ! grep -q '"mean_ms"' "$f" 2>/dev/null; then
    invalid+=("$metric:missing_mean_ms")
  fi
  # Legacy metric field form (optional) – do not fail if absent; just note
  if ! grep -q "\"metric\"" "$f" 2>/dev/null; then
    info "Baseline $metric missing 'metric' field (acceptable if new format)"
  fi
  return 0
}

info "Baseline directory: $PERF_BASELINE_DIR"
info "Metrics under test: ${(j:, :)metrics}"

for m in "${metrics[@]}"; do
  validate_file "$m"
done

if (( ${#invalid[@]} > 0 )); then
  fail "Invalid baseline file(s): ${(j:, :)invalid}" 3
fi

if (( ${#missing[@]} > 0 )); then
  if (( ENFORCE_BASELINES )); then
    fail "Missing baseline(s) in enforce mode: ${(j:, :)missing}" 2
  fi
  if (( ! ALLOW_BASELINE_CREATE )); then
    fail "Missing baseline(s) and ALLOW_BASELINE_CREATE not set: ${(j:, :)missing}" 2
  fi

  # Bootstrap creation
  info "Attempting baseline bootstrap for missing metrics: ${(j:, :)missing}"

  if [[ ! -x "$CLASSIFIER_PATH" ]]; then
    fail "Classifier script not found or not executable: $CLASSIFIER_PATH" 1
  fi

  # Build metrics arg list (use full set; missing ones will be created, existing unaffected)
  local metrics_arg
  metrics_arg=$(printf "%s," "${metrics[@]}")
  metrics_arg="${metrics_arg%,}"

  # Run classifier in observe mode (never enforce here)
  if ! "$CLASSIFIER_PATH" \
      --runs "$RUNS" \
      --metrics "$metrics_arg" \
      --mode observe \
      --warn-threshold 10 \
      --fail-threshold 25 \
      --baseline-dir "$PERF_BASELINE_DIR" \
      --quiet; then
    fail "Classifier baseline bootstrap failed" 4
  fi

  # Re-validate after creation
  missing=()
  for m in "${metrics[@]}"; do
    validate_file "$m"
  done

  if (( ${#missing[@]} > 0 )); then
    fail "Baseline bootstrap incomplete; still missing: ${(j:, :)missing}" 4
  fi
  info "Baseline bootstrap successful."
fi

# Final success summary
for m in "${metrics[@]}"; do
  pass "Baseline present: ${m}-baseline.json"
done

print -r -- "RESULT: All classifier baselines present and valid."
exit 0
