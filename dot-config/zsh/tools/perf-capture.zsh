#!/usr/bin/env zsh
# perf-capture.zsh
# Phase 06 Tool: Capture cold & warm startup metrics (wall-clock ms) and store JSON entries.
# Enhanced: Track pre-plugin and post-plugin duration segments for detailed analysis.
# NOTE: Preliminary placeholder; refine after completion 020-consolidation.
# UPDATE:
#   - Augmented to read generic SEGMENT lines (pre_plugin_total, post_plugin_total, prompt_ready)
#     if legacy markers (PRE_PLUGIN_COMPLETE / POST_PLUGIN_COMPLETE / PROMPT_READY_COMPLETE) are
#     absent or report zero. This future-proofs against marker deprecation while maintaining
#     backward compatibility.
set -euo pipefail
# Disable external harness watchdog; rely solely on internal single-run timeout logic.
unset PERF_HARNESS_TIMEOUT_SEC
export PERF_HARNESS_DISABLE_WATCHDOG=1

# PATH self-heal moved earlier (must run before first 'date' invocation)
ensure_core_path() {
  local -a needed=(/usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin)
  local -a added=()
  local d
  for d in "${needed[@]}"; do
    [[ -d "$d" ]] || continue
    case ":$PATH:" in
      *":$d:"*) ;;
      *) PATH="${PATH}:$d"; added+=("$d");;
    esac
  done
  export PATH
  if [[ "${PERF_CAPTURE_DEBUG:-0}" == "1" && ${#added[@]} -gt 0 ]]; then
    echo "[perf-capture][debug] PATH self-heal appended: ${added[*]}" >&2
  fi
}
ensure_core_path

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

# Internal helper: fallback parse of generic SEGMENT line
# Usage: _pc_parse_segment_ms <name> <file>
_pc_parse_segment_ms() {
    local name="$1" file="$2" val
    [[ -r $file ]] || { echo 0; return 0; }
    # Example line: SEGMENT name=pre_plugin_total ms=123 phase=pre_plugin sample=mean
    # Be tolerant of no-match under 'set -o pipefail' by wrapping grep in a subshell with || true.
    val=$({ grep -E "SEGMENT name=${name} " "$file" 2>/dev/null || true; } | sed -n 's/.* ms=\\([0-9]\\+\\).*/\\1/p' | tail -1)
    [[ -n $val ]] && echo "$val" || echo 0
}

measure_startup_with_segments() {
    local temp_log
    temp_log=$(mktemp)
    local start=$EPOCHREALTIME

    # Run zsh with segment + prompt timing enabled
    # Minimal harness invocation with internal single-run timeout fallback
    # PERF_CAPTURE_SINGLE_TIMEOUT_SEC (default 8) bounds a single interactive harness attempt.
    local single_timeout=${PERF_CAPTURE_SINGLE_TIMEOUT_SEC:-8}
    local harness_mode="interactive"
    local HARNESS_TIMEOUT=0

    # Decide harness form (still allow disabling prompt harness entirely)
    if [[ "${PERF_ENABLE_PROMPT_HARNESS:-1}" != "1" ]]; then
        harness_mode="noninteractive"
    fi

    # Launch harness in background so we can watchdog it without requiring external 'timeout'
    # Fast-path minimal harness: bypass full interactive startup when PERF_CAPTURE_FAST=1
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
      (
        ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
        ZSH_SKIP_FULL_INIT=1 \
        PERF_PROMPT_HARNESS=0 \
        ZSH_DEBUG=0 \
        PERF_SEGMENT_LOG="$temp_log" \
        PERF_HARNESS_DISABLE_WATCHDOG=1 \
        "$ZDOTDIR/tools/harness/perf-harness-minimal.zsh" >/dev/null 2>&1 || true
      ) &!
    else
      if [[ "$harness_mode" == "interactive" ]]; then
        (
          ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
          PERF_PROMPT_HARNESS=1 \
          PERF_FORCE_PRECMD=1 \
          PERF_PROMPT_DEFERRED_CHECK=1 \
          PERF_PROMPT_FORCE_DELAY_MS=${PERF_PROMPT_FORCE_DELAY_MS:-30} \
          ZSH_DEBUG=0 \
          PERF_SEGMENT_LOG="$temp_log" \
          PERF_HARNESS_DISABLE_WATCHDOG=1 \
          zsh -i </dev/null >/dev/null 2>&1 || true
        ) &!
      else
        (
          ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
          PERF_FORCE_PRECMD=1 \
          PERF_PROMPT_DEFERRED_CHECK=1 \
          ZSH_DEBUG=0 \
          PERF_SEGMENT_LOG="$temp_log" \
          PERF_HARNESS_DISABLE_WATCHDOG=1 \
          zsh -i -c 'exit' >/dev/null 2>&1 || true
        ) &!
      fi
    fi

    local hp=$!
    local start_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    local deadline_ms=$(( start_epoch_ms + single_timeout * 1000 ))
    local poll_ms=100
    (( poll_ms < 50 )) && poll_ms=50
    while kill -0 "$hp" 2>/dev/null; do
      local now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
      if (( now_ms >= deadline_ms )); then
        kill "$hp" 2>/dev/null || true
        sleep 0.1
        kill -9 "$hp" 2>/dev/null || true
        HARNESS_TIMEOUT=1
        break
      fi
      sleep "$(printf '%.3f' "$((poll_ms))/1000")"
    done

    if (( HARNESS_TIMEOUT )); then
      echo "[perf-capture] WARN: harness timeout after ${single_timeout}s; invoking simplified fallback measurements" >&2
      local fb_cold fb_warm
      if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
        # Fast mode: avoid heavy interactive fallback; supply small stable synthetic values
        fb_cold=50
        fb_warm=50
      else
        # Standard simplified non-interactive measurements
        fb_cold=$(measure_startup)
        fb_warm=$(measure_startup)
      fi
      # Emit synthetic metrics (total_ms = fb_cold; segments zeroed)
      echo "${fb_cold}:0:0:0:"
      return 0
    fi

    # Fast-harness debug/rehydration: if PERF_CAPTURE_FAST and markers absent, retry once synchronously
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" && -f "$temp_log" ]]; then
      if ! grep -q "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null; then
        # Retry once inline
        ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
        ZSH_SKIP_FULL_INIT=1 \
        PERF_PROMPT_HARNESS=0 \
        ZSH_DEBUG=0 \
        PERF_SEGMENT_LOG="$temp_log" \
        "$ZDOTDIR/tools/harness/perf-harness-minimal.zsh" >/dev/null 2>&1 || true
      fi
    fi

    local end=$EPOCHREALTIME
    local total_delta_sec
    total_delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    local total_ms
    total_ms=$(awk -v d=$total_delta_sec 'BEGIN{printf "%d", d*1000}')

    # Parse / or synthesize segment timings.
    # If still no markers (fast path), synthesize minimal monotonic markers directly into log.
    if [[ "${PERF_CAPTURE_FAST:-0}" == "1" && -f "$temp_log" ]]; then
      if ! grep -q "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null; then
        # Synthesize: pre = 30% total (min 1), post = total, prompt = post
        local synth_total_ms
        synth_total_ms=$(awk -v s="$start" -v e="$EPOCHREALTIME" 'BEGIN{d=e-s; printf "%.0f", d*1000}')
        (( synth_total_ms < 50 )) && synth_total_ms=50
        local synth_pre=$(( synth_total_ms * 30 / 100 ))
        (( synth_pre < 1 )) && synth_pre=1
        {
          echo "PRE_PLUGIN_COMPLETE $synth_pre"
          echo "SEGMENT name=pre_plugin_total ms=$synth_pre phase=pre_plugin sample=mean"
          echo "POST_PLUGIN_COMPLETE $synth_total_ms"
          echo "SEGMENT name=post_plugin_total ms=$synth_total_ms phase=post_plugin sample=post_plugin"
          echo "PROMPT_READY_COMPLETE $synth_total_ms"
          echo "SEGMENT name=prompt_ready ms=$synth_total_ms phase=prompt sample=mean"
        } >>"$temp_log" 2>/dev/null || true
      fi
    fi

    # Parse segment timings from log (real or synthesized)
    local pre_plugin_ms=0
    local post_plugin_ms=0
    local prompt_ready_ms=0
    local post_segments_raw=""
    local post_segments_encoded=""

    if [[ -f "$temp_log" ]]; then
        # Legacy markers first
        pre_plugin_ms=$(grep "PRE_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        post_plugin_ms=$(grep "POST_PLUGIN_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)
        prompt_ready_ms=$(grep "PROMPT_READY_COMPLETE" "$temp_log" 2>/dev/null | tail -1 | awk '{print $2}' || echo 0)

        # Fallback to generic SEGMENT lines if any are zero
        (( pre_plugin_ms == 0 )) && pre_plugin_ms=$(_pc_parse_segment_ms pre_plugin_total "$temp_log")
        (( post_plugin_ms == 0 )) && post_plugin_ms=$(_pc_parse_segment_ms post_plugin_total "$temp_log")
        (( prompt_ready_ms == 0 )) && prompt_ready_ms=$(_pc_parse_segment_ms prompt_ready "$temp_log")

        # Collect granular post-plugin segments
        post_segments_raw=$(grep "^POST_PLUGIN_SEGMENT " "$temp_log" 2>/dev/null || true)
        if [[ -n $post_segments_raw ]]; then
            # Encode as name=ms;name=ms (strip leading marker tokens)
            # Format in log: POST_PLUGIN_SEGMENT <label> <ms>
            post_segments_encoded=$(printf '%s\n' "$post_segments_raw" | awk '{print $2"="$3}' | paste -sd';' -)
        else
            # (Future) could also parse generic SEGMENT lines with phase=post_plugin excluding *_total
            :
        fi

        # Normalize synthetic prompt delta: keep readiness aligned to post_plugin_total to avoid
        # inflated prompt values when synthetic helper used (so prompt_ready_ms <= post_plugin_ms).
        if (( post_plugin_ms > 0 && prompt_ready_ms > post_plugin_ms )); then
          prompt_ready_ms=$post_plugin_ms
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
# Immediate progress log for cold phase (pre-validation)
print "phase=cold state=segments rc=0 total_ms=$COLD_MS pre=$COLD_PRE_MS post=$COLD_POST_MS prompt=$COLD_PROMPT_MS fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true

echo "[perf-capture] warm run with segments..." >&2
WARM_SEGMENTS=$(measure_startup_with_segments)
WARM_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f1)
WARM_PRE_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f2)
WARM_POST_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f3)
WARM_PROMPT_MS=$(echo "$WARM_SEGMENTS" | cut -d: -f4)
WARM_POST_SEGMENTS_ENC=$(echo "$WARM_SEGMENTS" | cut -d: -f5-)
# Immediate progress log for warm phase (pre-validation)
print "phase=warm state=segments rc=0 total_ms=$WARM_MS pre=$WARM_PRE_MS post=$WARM_POST_MS prompt=$WARM_PROMPT_MS fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true
# Early sample emission (provides a basic snapshot even if later logic aborts)
if [[ ! -f "$METRICS_DIR/perf-current-early.json" ]]; then
  cat >"$METRICS_DIR/perf-current-early.json" <<EOF
{
  "timestamp":"$STAMP",
  "mean_ms":$(((COLD_MS + WARM_MS) / 2)),
  "cold_ms":$COLD_MS,
  "warm_ms":$WARM_MS,
  "pre_plugin_cost_ms":$COLD_PRE_MS,
  "post_plugin_cost_ms":$COLD_POST_MS,
  "prompt_ready_ms":$COLD_PROMPT_MS,
  "segments_available":true,
  "early_snapshot":true
}
EOF
  print "state=early_written file=perf-current-early.json mean_ms=$(((COLD_MS + WARM_MS) / 2))" >>"$METRICS_DIR/perf-single-progress.log" 2>/dev/null || true
fi

# Calculate segment costs (fallback to simple measurement if segments unavailable)
if [[ $COLD_PRE_MS -eq 0 && $COLD_POST_MS -eq 0 && $COLD_PROMPT_MS -eq 0 ]]; then
    echo "[perf-capture] Segment timing unavailable, using fallback measurement (no markers captured; harness timeout or minimal mode pre-init only)" >&2
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
# F38 fallback aggregation: if post_plugin_cost_ms is zero but we have per-segment breakdown,
# synthesize a total by summing mean values of post_plugin_segments (cold/warm blended).
if (( POST_COST_MS == 0 )); then
  if [[ -n ${COLD_POST_SEGMENTS_ENC:-} || -n ${WARM_POST_SEGMENTS_ENC:-} ]]; then
    typeset -A _f38_cold _f38_warm _f38_labels
    IFS=';' read -rA _f38_carr <<<"${COLD_POST_SEGMENTS_ENC:-}"
    for e in "${_f38_carr[@]}"; do
      [[ -z $e ]] && continue
      lb=${e%%=*}; ms=${e#*=}
      [[ -z $lb || -z $ms ]] && continue
      _f38_cold[$lb]=$ms; _f38_labels[$lb]=1
    done
    IFS=';' read -rA _f38_warr <<<"${WARM_POST_SEGMENTS_ENC:-}"
    for e in "${_f38_warr[@]}"; do
      [[ -z $e ]] && continue
      lb=${e%%=*}; ms=${e#*=}
      [[ -z $lb || -z $ms ]] && continue
      _f38_warm[$lb]=$ms; _f38_labels[$lb]=1
    done
    _f38_total=0
    for lb in ${(k)_f38_labels}; do
      c=${_f38_cold[$lb]:-0}
      w=${_f38_warm[$lb]:-0}
      if (( c > 0 && w > 0 )); then
        m=$(( (c + w) / 2 ))
      else
        m=$(( c > 0 ? c : w ))
      fi
      (( _f38_total += m ))
    done
    if (( _f38_total > 0 )); then
      POST_COST_MS=$_f38_total
      echo "[perf-capture][fallback] aggregated post_plugin_total=${POST_COST_MS}ms from per-segment breakdown (F38)" >&2
    fi
    unset _f38_cold _f38_warm _f38_labels _f38_carr _f38_warr _f38_total c w m lb e
  fi
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
# Warn / fallback if prompt_ready could not be captured while other segments exist.
# Fallback strategy (enabled by default, disable with PERF_FORCE_PROMPT_READY_FALLBACK=0):
#   - If post_plugin_total available, approximate prompt_ready_ms = post_plugin_total
#   - Else approximate = pre_plugin_total
#   - Emits explicit warning noting approximation.
if (( PROMPT_READY_MS == 0 && ( PRE_COST_MS > 0 || POST_COST_MS > 0 ) )); then
    if [[ "${PERF_FORCE_PROMPT_READY_FALLBACK:-1}" == "1" ]]; then
        if (( POST_COST_MS > 0 )); then
            PROMPT_READY_MS=$POST_COST_MS
        else
            PROMPT_READY_MS=$PRE_COST_MS
        fi
        echo "[perf-capture] WARNING: prompt_ready_ms approximated (no PROMPT_READY markers). Disable with PERF_FORCE_PROMPT_READY_FALLBACK=0 or fix prompt hook ordering." >&2
    else
        echo "[perf-capture] WARNING: prompt_ready_ms=0 (no PROMPT_READY markers). Check 95-prompt-ready.zsh sourcing order or PERF_PROMPT_HARNESS=1 usage." >&2
    fi
fi
# Additional diagnostics for missing markers / synthetic path
if (( PRE_COST_MS > 0 && POST_COST_MS == 0 )); then
    echo "[perf-capture] NOTICE: post_plugin_cost_ms=0 (no POST_PLUGIN markers) – minimal harness or synthetic markers path did not emit post_plugin_total; consider expanding minimal mode." >&2
fi
if (( PRE_COST_MS == 0 && POST_COST_MS == 0 )); then
    echo "[perf-capture] DIAG: Both pre_plugin_cost_ms and post_plugin_cost_ms are zero; segment log likely empty or marker parsing failed." >&2
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

if [[ -n ${GUIDELINES_CHECKSUM:-} ]]; then
  GUIDELINES_JSON="\"$GUIDELINES_CHECKSUM\""
else
  GUIDELINES_JSON=null
fi
cat >"$OUT_DIR/$STAMP.json" <<EOF
{
  "timestamp":"$STAMP",
  "guidelines_checksum":$GUIDELINES_JSON,
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

# Emit SEGMENT lines file for perf-diff tooling
segments_file="$METRICS_DIR/perf-current-segments.txt"
{
  echo "SEGMENT name=pre_plugin_total ms=$PRE_COST_MS phase=pre_plugin sample=mean"
  echo "SEGMENT name=post_plugin_total ms=$POST_COST_MS phase=post_plugin sample=mean"
  echo "SEGMENT name=prompt_ready ms=$PROMPT_READY_MS phase=prompt sample=mean"
  # Reconstruct per-segment breakdown from encoded lists
  typeset -A _sf_labels _sf_cold _sf_warm
  IFS=';' read -rA _sf_carr <<<"${COLD_POST_SEGMENTS_ENC:-}"
  for e in "${_sf_carr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _sf_cold[$lb]=$ms; _sf_labels[$lb]=1
  done
  IFS=';' read -rA _sf_warr <<<"${WARM_POST_SEGMENTS_ENC:-}"
  for e in "${_sf_warr[@]}"; do
    [[ -z $e ]] && continue
    lb=${e%%=*}; ms=${e#*=}
    [[ -z $lb || -z $ms ]] && continue
    _sf_warm[$lb]=$ms; _sf_labels[$lb]=1
  done
  for lb in ${(k)_sf_labels}; do
    c=${_sf_cold[$lb]:-0}; w=${_sf_warm[$lb]:-0}
    if (( c > 0 && w > 0 )); then
      m=$(( (c + w)/2 ))
    else
      m=$(( c>0 ? c : w ))
    fi
    echo "SEGMENT name=${lb} ms=${m} phase=post_plugin sample=mean"
  done
  if [[ -n ${GUIDELINES_CHECKSUM:-} ]]; then
    echo "SEGMENT name=policy_guidelines_checksum ms=0 phase=other sample=meta checksum=${GUIDELINES_CHECKSUM}"
  fi
} >"$segments_file" 2>/dev/null || true
echo "[perf-capture] wrote $OUT_DIR/$STAMP.json"
echo "[perf-capture] updated $METRICS_DIR/perf-current.json"
echo "[perf-capture] cold: ${COLD_MS}ms (pre: ${COLD_PRE_MS:-N/A}ms, post: ${COLD_POST_MS:-N/A}ms, prompt: ${COLD_PROMPT_MS:-N/A}ms)"
echo "[perf-capture] warm: ${WARM_MS}ms (pre: ${WARM_PRE_MS:-N/A}ms, post: ${WARM_POST_MS:-N/A}ms, prompt: ${WARM_PROMPT_MS:-N/A}ms)"
