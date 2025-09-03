#!/usr/bin/env zsh
# test-preplugin-baseline-threshold.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
#
# PURPOSE:
#   Guard against regressions in the pre-plugin phase cost after the Stage 2 baseline
#   (`preplugin-baseline.json`) is captured. Ensures `pre_plugin_total` does not exceed
#   the recorded baseline mean by more than an allowed regression percentage (default 10%).
#
# SCOPE:
#   - Reads baseline metrics JSON (multi-sample recommended) for mean_ms
#   - Performs a fresh perf capture (segments) and extracts current `pre_plugin_total`
#   - Compares current vs baseline (with configurable allowed regression)
#
# BEHAVIOR:
#   - If baseline file is missing: SKIP (Stage 2 baseline not yet committed)
#   - If perf capture tooling missing: FAIL (infrastructure issue)
#   - If segment missing in capture: FAIL (instrumentation regression)
#   - If current_ms > baseline_mean * (1 + allowed_pct/100): FAIL
#
# CONFIG (env overrides):
#   PREPLUGIN_BASELINE_PATH   Path to baseline JSON
#   PREPLUGIN_ALLOWED_REGRESSION_PCT  Allowed regression percentage (default 10)
#   PREPLUGIN_SEGMENTS_FILE   Override path to generated segments file (optional)
#
# EXIT CODES:
#   0 PASS / SKIP
#   1 FAIL (regression or infra issue)
#
# OUTPUT (human-readable):
#   PASS/FAIL/SKIP lines plus diagnostic values.
#
# DEPENDENCIES:
#   - tools/perf-capture.zsh (segments mode)
#   - jq (optional; falls back to awk/grep parsing)
#
# NOTE:
#   This test is introduced immediately after Stage 2 code completion; it only becomes
#   authoritative (non-skip) once the baseline artifact is committed.

set -u

: ${ZDOTDIR:=${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
: ${PREPLUGIN_BASELINE_PATH:="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/preplugin-baseline.json"}
: ${PREPLUGIN_ALLOWED_REGRESSION_PCT:=10}

TOOLS_DIR="${ZDOTDIR}/tools"
CAPTURE="${TOOLS_DIR}/perf-capture.zsh"

segments_target_default="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
SEGMENTS_FILE="${PREPLUGIN_SEGMENTS_FILE:-$segments_target_default}"

pass() { printf "PASS: %s\n" "$*"; exit 0; }
skip() { printf "SKIP: %s\n" "$*"; exit 0; }
fail() { printf "FAIL: %s\n" "$*" >&2; exit 1; }

if [[ ! -f "$PREPLUGIN_BASELINE_PATH" ]]; then
  skip "Baseline file not present yet: $PREPLUGIN_BASELINE_PATH"
fi

if [[ ! -x "$CAPTURE" ]]; then
  fail "perf capture tool missing or not executable: $CAPTURE"
fi

# ---------------- Parse baseline mean_ms ----------------
baseline_mean=""
if command -v jq >/dev/null 2>&1; then
  baseline_mean="$(jq -r '.mean_ms // empty' "$PREPLUGIN_BASELINE_PATH" 2>/dev/null || true)"
fi

if [[ -z "$baseline_mean" ]]; then
  # Fallback grep/awk (looks for "mean_ms" : <number>)
  baseline_mean="$(grep -E '"mean_ms"' "$PREPLUGIN_BASELINE_PATH" 2>/dev/null | head -1 | sed -E 's/.*"mean_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' || true)"
fi

[[ -n "$baseline_mean" && "$baseline_mean" == <-> ]] || fail "Could not parse baseline mean_ms in $PREPLUGIN_BASELINE_PATH"

# ---------------- Capture current segments ----------------
# We only need one run; multi-sample variance handled elsewhere.
# Allow capture script to silently succeed; it should produce the segments file.
if ! "$CAPTURE" --segments >/dev/null 2>&1; then
  fail "perf capture script failed"
fi

[[ -f "$SEGMENTS_FILE" ]] || fail "segments file missing after capture: $SEGMENTS_FILE"

current_line="$(grep -E '^SEGMENT name=pre_plugin_total ' "$SEGMENTS_FILE" | head -1 || true)"
[[ -n "$current_line" ]] || fail "pre_plugin_total segment not found in $SEGMENTS_FILE"

current_ms="$(printf '%s' "$current_line" | sed -E 's/.* ms=([0-9]+).*/\1/')"
[[ -n "$current_ms" && "$current_ms" == <-> ]] || fail "Could not parse ms value from segment line: $current_line"

# ---------------- Threshold comparison ----------------
allowed_pct="$PREPLUGIN_ALLOWED_REGRESSION_PCT"
# Compute threshold = baseline_mean * (1 + allowed_pct/100)
threshold_ms=$(( baseline_mean + (baseline_mean * allowed_pct / 100) ))

if (( current_ms <= threshold_ms )); then
  pass "pre_plugin_total=${current_ms}ms baseline_mean=${baseline_mean}ms allowed_regression=${allowed_pct}% threshold=${threshold_ms}ms"
else
  fail "pre_plugin_total regression: current=${current_ms}ms baseline_mean=${baseline_mean}ms allowed=${allowed_pct}% threshold=${threshold_ms}ms"
fi
