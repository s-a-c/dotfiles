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
    ZSH_ENABLE_PREPLUGIN_REDESIGN=1 zsh -ic 'exit' >/dev/null 2>&1 || true
    local end=$EPOCHREALTIME
    # Convert (floating seconds) to ms (integer)
    local delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    awk -v d=$delta_sec 'BEGIN{printf "%d", d*1000}'
}

measure_startup_with_segments() {
    local temp_log
    temp_log=$(mktemp)
    local start=$EPOCHREALTIME

    # Run zsh with segment + prompt timing enabled
    if [[ "${PERF_ENABLE_PROMPT_HARNESS:-1}" == "1" ]]; then
        # Use interactive harness that auto-exits after first prompt (PROMPT_READY_COMPLETE)
        # 95-prompt-ready.zsh will trigger exit when PERF_PROMPT_HARNESS=1
        ZSH_ENABLE_PREPLUGIN_REDESIGN=1 PERF_PROMPT_HARNESS=1 PERF_SEGMENT_LOG="$temp_log" zsh -i </dev/null >/dev/null 2>&1 || true
    else
        # Fallback: traditional interactive + immediate exit (may only capture fallback timing)
        ZSH_ENABLE_PREPLUGIN_REDESIGN=1 PERF_SEGMENT_LOG="$temp_log" zsh -i -c 'exit' >/dev/null 2>&1 || true
    fi

    local end=$EPOCHREALTIME
    local total_delta_sec
    total_delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    local total_ms
    total_ms=$(awk -v d=$total_delta_sec 'BEGIN{printf "%d", d*1000}')

    # Parse segment timings from log
    local pre_plugin_ms=0
    local post_plugin_ms=0
    local prompt_ready_ms=0
    local post_segments_raw=""
    local post_segments_encoded=""

    if [[ -f "$temp_log" ]]; then
        pre_plugin_ms=$(grep "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        post_plugin_ms=$(grep "POST_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        prompt_ready_ms=$(grep "PROMPT_READY_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        # Collect granular post-plugin segments
        post_segments_raw=$(grep "^POST_PLUGIN_SEGMENT " "$temp_log" 2>/dev/null || true)
        if [[ -n $post_segments_raw ]]; then
            # Encode as name=ms;name=ms (strip leading marker tokens)
            # Format in log: POST_PLUGIN_SEGMENT <label> <ms>
            post_segments_encoded=$(printf '%s\n' "$post_segments_raw" | awk '{print $2"="$3}' | paste -sd';' -)
        fi
    fi

    rm -f "$temp_log" 2>/dev/null || true

    # Emit 5th field with encoded segment list
    echo "$total_ms:$pre_plugin_ms:$post_plugin_ms:$prompt_ready_ms:$post_segments_encoded"
}

echo "[perf-capture] cold run with segments..." >&2
COLD_SEGMENTS=$(measure_startup_with_segments)
COLD_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f1)
COLD_PRE_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f2)
COLD_POST_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f3)
COLD_PROMPT_MS=$(echo "$COLD_SEGMENTS" | cut -d: -f4)
COLD_POST_SEGMENTS_ENC=$(echo "$COLD_SEGMENTS" | cut -d: -f5-)

echo "[perf-capture] warm run with segments..." >&2
WARM_SEGMENTS=$(measure_startup_with_segments)
WARM_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f1)
WARM_PRE_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f2)
WARM_POST_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f3)
WARM_PROMPT_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f4)
WARM_POST_SEGMENTS_ENC=$(echo "$WARM_SEGMENTS" | cut -d: -f5-)

# Calculate segment costs (fallback to simple measurement if segments unavailable)
if [[ $COLD_PRE_MS -eq 0 && $COLD_POST_MS -eq 0 && $COLD_PROMPT_MS -eq 0 ]]; then
    echo "[perf-capture] Segment timing unavailable, using fallback measurement" >&2
    COLD_MS=$(measure_startup)
    WARM_MS=$(measure_startup)
    COLD_PRE_MS="null"
    COLD_POST_MS="null"
    COLD_PROMPT_MS="null"
    WARM_PRE_MS="null"
    WARM_POST_MS="null"
    WARM_PROMPT_MS="null"
fi

# Normalize numeric copies for arithmetic (treat "null" as 0)
NUM_COLD_PRE=$([[ "$COLD_PRE_MS" == "null" ]] && echo 0 || echo "$COLD_PRE_MS")
NUM_WARM_PRE=$([[ "$WARM_PRE_MS" == "null" ]] && echo 0 || echo "$WARM_PRE_MS")
NUM_COLD_POST=$([[ "$COLD_POST_MS" == "null" ]] && echo 0 || echo "$COLD_POST_MS")
NUM_WARM_POST=$([[ "$WARM_POST_MS" == "null" ]] && echo 0 || echo "$WARM_POST_MS")
NUM_COLD_PROMPT=$([[ "$COLD_PROMPT_MS" == "null" ]] && echo 0 || echo "$COLD_PROMPT_MS")
NUM_WARM_PROMPT=$([[ "$WARM_PROMPT_MS" == "null" ]] && echo 0 || echo "$WARM_PROMPT_MS")

if ((NUM_COLD_PRE > 0 || NUM_WARM_PRE > 0)); then
    PRE_COST_MS=$(((NUM_COLD_PRE + NUM_WARM_PRE) / 2))
else
    PRE_COST_MS=0
fi
if ((NUM_COLD_POST > 0 || NUM_WARM_POST > 0)); then
    POST_COST_MS=$(((NUM_COLD_POST + NUM_WARM_POST) / 2))
else
    POST_COST_MS=0
fi
if ((NUM_COLD_PRE > 0 || NUM_COLD_POST > 0 || NUM_WARM_PRE > 0 || NUM_WARM_POST > 0 || NUM_COLD_PROMPT > 0 || NUM_WARM_PROMPT > 0)); then
    SEGMENTS_AVAILABLE=true
else
    SEGMENTS_AVAILABLE=false
fi
if ((NUM_COLD_PROMPT > 0 || NUM_WARM_PROMPT > 0)); then
    PROMPT_READY_MS=$(((NUM_COLD_PROMPT + NUM_WARM_PROMPT) / 2))
else
    PROMPT_READY_MS=0
fi

# Build breakdown JSON array (average cold/warm per label)
post_breakdown_json="[]"
# Merge encoded lists: label=ms;...
if [[ -n ${COLD_POST_SEGMENTS_ENC:-} || -n ${WARM_POST_SEGMENTS_ENC:-} ]]; then
  typeset -A _cold_seg _warm_seg _labels
  IFS=';' read -rA _carr <<<"${COLD_POST_SEGMENTS_ENC:-}"
  for e in "${_carr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _cold_seg[$lb]=$ms
    _labels[$lb]=1
  done
  IFS=';' read -rA _warr <<<"${WARM_POST_SEGMENTS_ENC:-}"
  for e in "${_warr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _warm_seg[$lb]=$ms
    _labels[$lb]=1
  done
  # Construct JSON
  post_breakdown_json="["
  first=1
  for lb in ${(k)_labels}; do
    c=${_cold_seg[$lb]:-0}
    w=${_warm_seg[$lb]:-0}
    if (( c > 0 && w > 0 )); then
      m=$(( (c + w) / 2 ))
    else
      m=$(( c > 0 ? c : w ))
    fi
    (( first )) || post_breakdown_json+=","
    first=0
    post_breakdown_json+="{\"label\":\"$lb\",\"cold_ms\":$c,\"warm_ms\":$w,\"mean_ms\":$m}"
  done
  post_breakdown_json+="]"
  unset _cold_seg _warm_seg _labels _carr _warr lb ms c w m first
fi

cat >"$OUT_DIR/$STAMP.json" <<EOF
{
  "timestamp":"$STAMP",
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "cold_pre_plugin_ms":$COLD_PRE_MS,
  "cold_post_plugin_ms":$COLD_POST_MS,
  "cold_prompt_ready_ms":$COLD_PROMPT_MS,
  "warm_pre_plugin_ms":$WARM_PRE_MS,
  "warm_post_plugin_ms":$WARM_POST_MS,
  "warm_prompt_ready_ms":$WARM_PROMPT_MS,
  "post_plugin_segments": $post_breakdown_json
}
EOF

# Also update the current metrics file used by promotion guard
cat >"$METRICS_DIR/perf-current.json" <<EOF
{
  "timestamp":"$STAMP",
  "mean_ms":$(((COLD_MS + WARM_MS) / 2)),
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "pre_plugin_cost_ms":$PRE_COST_MS,
  "post_plugin_cost_ms":$POST_COST_MS,
  "prompt_ready_ms":$PROMPT_READY_MS,
  "segments_available":$SEGMENTS_AVAILABLE,
  "post_plugin_segments": $post_breakdown_json
}
EOF

echo "[perf-capture] wrote $OUT_DIR/$STAMP.json"
echo "[perf-capture] updated $METRICS_DIR/perf-current.json"
echo "[perf-capture] cold: ${COLD_MS}ms (pre: ${COLD_PRE_MS:-N/A}ms, post: ${COLD_POST_MS:-N/A}ms, prompt: ${COLD_PROMPT_MS:-N/A}ms)"
echo "[perf-capture] warm: ${WARM_MS}ms (pre: ${WARM_PRE_MS:-N/A}ms, post: ${WARM_POST_MS:-N/A}ms, prompt: ${WARM_PROMPT_MS:-N/A}ms)"
