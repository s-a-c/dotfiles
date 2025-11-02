#!/usr/bin/env zsh
# perf-minimal-markers.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Emit synthetic PRE / POST plugin and PROMPT readiness markers (legacy + SEGMENT schema)
#   when running in a constrained "minimal" performance harness where the full plugin/theme
#   stack is skipped and natural markers will not appear. Ensures downstream perf-capture
#   tooling receives monotonically increasing lifecycle timestamps usable for variance
#   tracking & gating decisions.
#
# USAGE (perf-capture.zsh integration example):
#   PERF_SEGMENT_LOG="$temp_log" PERF_SYNTH_TOTAL_MS="$total_ms" \
#     zsh "$ZDOTDIR/tools/helpers/perf-minimal-markers.zsh"
#
# INPUT ENVIRONMENT:
#   PERF_SEGMENT_LOG          Destination log file (appended). If absent, script exits quietly.
#   PERF_SYNTH_TOTAL_MS       (Optional) Total wall-clock ms for the startup measurement.
#                             If absent or zero, script does nothing (avoids guesswork).
#   PERF_SAMPLE_CONTEXT       (Optional) Label for sample= field (default: mean).
#   PERF_SYNTH_PRE_PCT        (Optional) Fraction (0.0-1.0) of total_ms representing pre_plugin_total
#                             default 0.30 (30%).
#   PERF_SYNTH_POST_PCT       (Optional) Fraction (0.0-1.0) of total_ms representing post_plugin_total
#                             default 0.85 (85%). Must be >= PRE_PCT; if not, it is clamped.
#   PERF_SYNTH_MIN_GRAN_MS    (Optional) Minimum granularity in ms (default 1).
#   PERF_SYNTH_VERBOSE        (Optional) If "1", emit stderr diagnostics.
#
# OUTPUT:
#   Appends (if not already present in the log):
#     PRE_PLUGIN_COMPLETE <ms>
#     SEGMENT name=pre_plugin_total ms=<ms> phase=pre_plugin sample=<ctx>
#     POST_PLUGIN_COMPLETE <ms>
#     SEGMENT name=post_plugin_total ms=<ms> phase=post_plugin sample=<ctx>
#     PROMPT_READY_COMPLETE <ms_from_pre_end>
#     SEGMENT name=prompt_ready ms=<ms_from_pre_end> phase=prompt sample=<ctx>
#
#   Where:
#     <ms> values are monotonically non-decreasing and bounded by total_ms.
#     prompt_ready delta = total_ms (or (total_ms - pre_ms) depending on interpretation).
#     We select (prompt_ready delta = total_ms) so that "prompt_ready_ms" aligns with
#     the same semantic already consumed by perf-capture (representing readiness window).
#
# SAFETY:
#   - Idempotent: If any of the primary legacy markers already exist, it will not duplicate them.
#   - Will not overwrite existing lines; only appends.
#   - Exits 0 on all paths (non-fatal).
#
# POLICY:
#   - No network, localized log writes only.
#
# LIMITATIONS:
#   - Synthetic percentages are heuristics; not a substitute for full instrumentation.
#
# FUTURE IMPROVEMENTS:
#   - Adaptive modeling based on historical distribution.
#   - Accept an explicit pre/post breakdown from caller for higher fidelity.
#
# ------------------------------------------------------------------------------

set -euo pipefail

verbose() {
  [[ "${PERF_SYNTH_VERBOSE:-0}" == "1" ]] && print -u2 -- "[perf-minimal-markers] $*"
}

# Fast bail-outs
[[ -n "${PERF_SEGMENT_LOG:-}" ]] || { verbose "No PERF_SEGMENT_LOG set; exiting"; exit 0; }
TOTAL_MS="${PERF_SYNTH_TOTAL_MS:-0}"
[[ "$TOTAL_MS" =~ ^[0-9]+$ ]] || TOTAL_MS=0
(( TOTAL_MS > 0 )) || { verbose "TOTAL_MS empty or zero; exiting"; exit 0; }

# Read existing markers (avoid duplicates)
if [[ -f "$PERF_SEGMENT_LOG" ]]; then
  if grep -q 'PRE_PLUGIN_COMPLETE' "$PERF_SEGMENT_LOG" 2>/dev/null; then
    verbose "Existing PRE_PLUGIN_COMPLETE found; skipping synthetic emission"
    exit 0
  fi
fi

# Configuration
PRE_PCT="${PERF_SYNTH_PRE_PCT:-0.30}"
POST_PCT="${PERF_SYNTH_POST_PCT:-0.85}"
MIN_GRAN="${PERF_SYNTH_MIN_GRAN_MS:-1}"
SAMPLE_CTX="${PERF_SAMPLE_CONTEXT:-mean}"

# Sanitize numeric percentages (fallback defaults if invalid)
float_re='^([0-9]*\\.[0-9]+|[0-9]+\\.?)[0-9]*$'
[[ "$PRE_PCT" =~ $float_re ]] || PRE_PCT="0.30"
[[ "$POST_PCT" =~ $float_re ]] || POST_PCT="0.85"
# Clamp
awk_clamp() {
  # args: value low high
  awk -v v="$1" -v lo="$2" -v hi="$3" 'BEGIN{
    if (v<lo) v=lo;
    if (v>hi) v=hi;
    printf "%.6f", v;
  }'
}
PRE_PCT=$(awk_clamp "$PRE_PCT" 0.05 0.90)
POST_PCT=$(awk_clamp "$POST_PCT" "$PRE_PCT" 0.98)

# Compute coarse breakdown
# Convert fractional percentages to integer ms, enforcing monotonic ascending sequence.
pre_ms=$(awk -v t="$TOTAL_MS" -v p="$PRE_PCT" 'BEGIN{printf "%d", (t*p)}')
post_ms=$(awk -v t="$TOTAL_MS" -v p="$POST_PCT" 'BEGIN{printf "%d", (t*p)}')

# Enforce minimum granularity & ordering
(( pre_ms < MIN_GRAN )) && pre_ms=$MIN_GRAN
(( post_ms <= pre_ms )) && post_ms=$(( pre_ms + MIN_GRAN ))
(( post_ms > TOTAL_MS )) && post_ms=$TOTAL_MS

# We represent prompt-ready delta as TOTAL_MS (consumed later as prompt_ready_ms)
prompt_delta="$TOTAL_MS"

# Final monotonic guard
(( pre_ms > TOTAL_MS )) && pre_ms=$TOTAL_MS
(( post_ms > TOTAL_MS )) && post_ms=$TOTAL_MS
(( prompt_delta < post_ms )) && prompt_delta=$post_ms

verbose "TOTAL_MS=$TOTAL_MS pre_ms=$pre_ms post_ms=$post_ms prompt_delta=$prompt_delta"

# Append markers atomically (best effort)
{
  print "PRE_PLUGIN_COMPLETE ${pre_ms}"
  print "SEGMENT name=pre_plugin_total ms=${pre_ms} phase=pre_plugin sample=${SAMPLE_CTX}"
  print "POST_PLUGIN_COMPLETE ${post_ms}"
  print "SEGMENT name=post_plugin_total ms=${post_ms} phase=post_plugin sample=${SAMPLE_CTX}"
  print "PROMPT_READY_COMPLETE ${prompt_delta}"
  print "SEGMENT name=prompt_ready ms=${prompt_delta} phase=prompt sample=${SAMPLE_CTX}"
} >>"$PERF_SEGMENT_LOG" 2>/dev/null || {
  verbose "Failed appending synthetic markers to $PERF_SEGMENT_LOG"
  exit 0
}

verbose "Synthetic markers appended to $PERF_SEGMENT_LOG"
exit 0
