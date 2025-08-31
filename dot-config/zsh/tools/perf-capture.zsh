#!/usr/bin/env zsh
# perf-capture.zsh
# Phase 06 Tool: Capture cold & warm startup metrics (wall-clock ms) and store JSON entries.
# Enhanced: Track pre-plugin and post-plugin duration segments for detailed analysis.
# NOTE: Preliminary placeholder; refine after completion 020-consolidation.
set -euo pipefail

zmodload zsh/datetime || true
STAMP=$(date +%Y%m%dT%H%M%S)
OUT_DIR=${ZDOTDIR:-$HOME/.config/zsh}/logs/perf
# Prefer new redesignv2 metrics path; fall back to legacy if not present
if [[ -d ${ZDOTDIR:-$HOME/.config/zsh}/docs/redesignv2/artifacts/metrics ]]; then
    METRICS_DIR=${ZDOTDIR:-$HOME/.config/zsh}/docs/redesignv2/artifacts/metrics
else
    METRICS_DIR=${ZDOTDIR:-$HOME/.config/zsh}/docs/redesign/metrics
fi
mkdir -p "$OUT_DIR" "$METRICS_DIR"

measure_startup() {
    local start=$EPOCHREALTIME
    zsh -ic 'exit' >/dev/null 2>&1 || true
    local end=$EPOCHREALTIME
    # Convert (floating seconds) to ms (integer)
    local delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    awk -v d=$delta_sec 'BEGIN{printf "%d", d*1000}'
}

measure_startup_with_segments() {
    local temp_log=$(mktemp)
    local start=$EPOCHREALTIME

    # Run zsh with segment timing enabled
    PERF_SEGMENT_LOG="$temp_log" zsh -ic 'exit' >/dev/null 2>&1 || true

    local end=$EPOCHREALTIME
    local total_delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    local total_ms=$(awk -v d=$total_delta_sec 'BEGIN{printf "%d", d*1000}')

    # Parse segment timings from log
    local pre_plugin_ms=0
    local post_plugin_ms=0

    if [[ -f "$temp_log" ]]; then
        pre_plugin_ms=$(grep "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        post_plugin_ms=$(grep "POST_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
    fi

    rm -f "$temp_log" 2>/dev/null || true

    echo "$total_ms:$pre_plugin_ms:$post_plugin_ms"
}

echo "[perf-capture] cold run with segments..." >&2
COLD_SEGMENTS=$(measure_startup_with_segments)
COLD_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f1)
COLD_PRE_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f2)
COLD_POST_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f3)

echo "[perf-capture] warm run with segments..." >&2
WARM_SEGMENTS=$(measure_startup_with_segments)
WARM_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f1)
WARM_PRE_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f2)
WARM_POST_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f3)

# Calculate segment costs (fallback to simple measurement if segments unavailable)
if [[ $COLD_PRE_MS -eq 0 && $COLD_POST_MS -eq 0 ]]; then
    echo "[perf-capture] Segment timing unavailable, using fallback measurement" >&2
    COLD_MS=$(measure_startup)
    WARM_MS=$(measure_startup)
    COLD_PRE_MS="null"
    COLD_POST_MS="null"
    WARM_PRE_MS="null"
    WARM_POST_MS="null"
fi

cat >"$OUT_DIR/$STAMP.json" <<EOF
{
  "timestamp":"$STAMP",
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "cold_pre_plugin_ms":$COLD_PRE_MS,
  "cold_post_plugin_ms":$COLD_POST_MS,
  "warm_pre_plugin_ms":$WARM_PRE_MS,
  "warm_post_plugin_ms":$WARM_POST_MS
}
EOF

# Also update the current metrics file used by promotion guard
cat >"$METRICS_DIR/perf-current.json" <<EOF
{
  "timestamp":"$STAMP",
  "mean_ms":$(((COLD_MS + WARM_MS) / 2)),
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "pre_plugin_cost_ms":$((COLD_PRE_MS > 0 ? (COLD_PRE_MS + WARM_PRE_MS) / 2 : 0)),
  "post_plugin_cost_ms":$((COLD_POST_MS > 0 ? (COLD_POST_MS + WARM_POST_MS) / 2 : 0)),
  "segments_available":$((COLD_PRE_MS > 0 || COLD_POST_MS > 0 ? "true" : "false"))
}
EOF

echo "[perf-capture] wrote $OUT_DIR/$STAMP.json"
echo "[perf-capture] updated $METRICS_DIR/perf-current.json"
echo "[perf-capture] cold: ${COLD_MS}ms (pre: ${COLD_PRE_MS:-N/A}ms, post: ${COLD_POST_MS:-N/A}ms)"
echo "[perf-capture] warm: ${WARM_MS}ms (pre: ${WARM_PRE_MS:-N/A}ms, post: ${WARM_POST_MS:-N/A}ms)"
