#!/usr/bin/env zsh
# perf-capture-multi.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Execute multiple consecutive startup performance capture runs (cold/warm harness
#   per run via existing perf-capture tooling) and emit an aggregated statistics
#   artifact including mean / min / max / stddev for core lifecycle metrics and
#   hotspot segment labels (post-plugin segments) to support:
#     - Stabilization & variance analysis prior to enabling perf gating
#     - Confidence in baselines (observe → warn → gate transitions)
#     - Data-informed tuning of interim and final budget thresholds
#
# DESIGN:
#   - Wraps existing tools/perf-capture.zsh (single-run capture) for N samples.
#   - After each run, copies perf-current.json to a preserved per-run sample file.
#   - Parses required numeric fields without external heavy JSON tooling (jq not required).
#   - Aggregates per-run metrics + segment mean_ms values.
#   - Emits consolidated JSON: perf-multi-current.json (schema perf-multi.v1).
#
# OUTPUT ARTIFACTS (metrics directory):
#   perf-sample-<i>.json          (raw per-run copy of perf-current.json after run i)
#   perf-multi-current.json       (aggregate across all samples)
#
# SCHEMA (perf-multi-current.json - abridged):
# {
#   "schema":"perf-multi.v1",
#   "timestamp":"20250902T031251",
#   "samples":3,
#   "guidelines_checksum":"<sha256>|null",
#   "per_run":[{ "... per-run metrics ..." }],
#   "aggregate":{
#       "cold_ms":{"mean":..,"min":..,"max":..,"stddev":..,"values":[...]},
#       "post_plugin_cost_ms":{...},
#       ...
#   },
#   "segments":[
#       {"label":"compinit","mean_ms":..,"min_ms":..,"max_ms":..,"stddev_ms":..,"values":[...]},
#       ...
#   ]
# }
#
# OPTIONS:
#   -n / --samples <N>         Number of capture iterations (default 3)
#   -s / --sleep   <SECONDS>   Sleep between runs (fractional ok, default 0)
#   --quiet                    Suppress per-run perf-capture console noise
#   --no-segments              Skip segment aggregation (lifecycle only)
#   --help                     Usage output
#
# ENVIRONMENT (respected / forwarded):
#   ZDOTDIR                    Base config directory (auto-detected if unset)
#   GUIDELINES_CHECKSUM        If pre-exported, used directly
#   PERF_CAPTURE_BIN           Override path to perf-capture.zsh
#
# EXIT CODES:
#   0 Success
#   1 Invalid arguments / missing single-run tool
#   2 Runtime failure during one of the captures
#
# DEPENDENCIES:
#   - Relies on tools/perf-capture.zsh existing & functioning
#   - Shell utilities: awk, grep, sed, date, printf
#
# SECURITY / POLICY:
#   - Read/write inside repository metrics/log directories only
#   - No network usage
#
# FUTURE ENHANCEMENTS:
#   - Percentile calculations (p50 / p90)
#   - Rolling baseline auto-update command
#   - JSON schema versioning & validation test
#   - Optional jq pathway if available (for robust JSON parsing)
#
# -----------------------------------------------------------------------------

set -euo pipefail
: ${PERF_CAPTURE_MULTI_DEBUG:=0}
: ${PERF_CAPTURE_RUN_TIMEOUT_SEC:=20}

SCRIPT_NAME="${0##*/}"

usage() {
  cat <<EOF
$SCRIPT_NAME - Multi-sample ZSH startup performance aggregator

Usage: $SCRIPT_NAME [options]

Options:
  -n, --samples <N>        Number of capture runs (default: 3)
  -s, --sleep <SECONDS>    Sleep between runs (default: 0)
      --quiet              Suppress single-run perf-capture output
      --no-segments        Skip per-segment aggregation (faster)
      --help               Show this help

Artifacts:
  Writes per-run perf-sample-<i>.json and aggregate perf-multi-current.json
  into redesignv2 metrics directory (or legacy redesign fallback).

Example:
  $SCRIPT_NAME -n 5 -s 0.5
EOF
}

# ---------------- Argument Parsing ----------------
SAMPLES=3
SLEEP_INTERVAL=0
QUIET=0
DO_SEGMENTS=1

while (( $# > 0 )); do
  case "$1" in
    -n|--samples)
      shift || { echo "Missing value after --samples" >&2; exit 1; }
      SAMPLES="$1"
      ;;
    -s|--sleep)
      shift || { echo "Missing value after --sleep" >&2; exit 1; }
      SLEEP_INTERVAL="$1"
      ;;
    --quiet)
      QUIET=1
      ;;
    --no-segments)
      DO_SEGMENTS=0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if ! [[ "$SAMPLES" =~ ^[0-9]+$ ]] || (( SAMPLES < 1 )); then
  echo "Invalid --samples value: $SAMPLES" >&2
  exit 1
fi

# ---------------- Environment Resolution ----------------
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Metrics directory (prefer redesignv2)
if [[ -d "$ZDOTDIR/docs/redesignv2/artifacts/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
elif [[ -d "$ZDOTDIR/docs/redesign/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesign/metrics"
else
  echo "Unable to locate metrics directory under $ZDOTDIR/docs" >&2
  exit 1
fi

mkdir -p "$METRICS_DIR"

PERF_CAPTURE_BIN="${PERF_CAPTURE_BIN:-$ZDOTDIR/tools/perf-capture.zsh}"
if [[ ! -x "$PERF_CAPTURE_BIN" ]]; then
  # It may not be executable; try running via zsh
  if [[ ! -f "$PERF_CAPTURE_BIN" ]]; then
    echo "Single-run perf-capture tool not found at $PERF_CAPTURE_BIN" >&2
    exit 1
  fi
fi

timestamp() {
  date +%Y%m%dT%H%M%S
}

STAMP=$(timestamp)

# ---------------- Guidelines Checksum ----------------
# Reuse existing if exported; else attempt helper script; else null
if [[ -z "${GUIDELINES_CHECKSUM:-}" ]]; then
  CHECKSUM_SCRIPT="$ZDOTDIR/tools/guidelines-checksum.sh"
  if [[ -x "$CHECKSUM_SCRIPT" ]]; then
    GUIDELINES_CHECKSUM="$("$CHECKSUM_SCRIPT" 2>/dev/null | head -1 | tr -d '[:space:]' || true)"
    export GUIDELINES_CHECKSUM
  fi
fi

# ---------------- Data Structures ----------------
# Arrays of numeric values (as strings) for computation
# Track only valid (non-zero) samples; skipped zero-runs are not counted toward aggregate.
cold_values=()
warm_values=()
pre_values=()
post_values=()
prompt_values=()

# Associative arrays for segment aggregation (label -> list string "v1 v2 ...")
typeset -A seg_values
typeset -A seg_min
typeset -A seg_max
typeset -A seg_sum
typeset -A seg_sum_sq
typeset -A seg_count

# ---------------- Helpers ----------------
extract_json_number() {
  # Hardened JSON integer field extractor.
  # Returns 0 if key not found or value not a signed integer.
  # Usage: extract_json_number <file> <key>
  local file="$1" key="$2" raw val
  raw=$(grep -E "\"${key}\"[[:space:]]*:" "$file" 2>/dev/null | head -1 || true)
  [[ -z $raw ]] && { echo 0; return 0; }
  # Isolate the numeric token after the first matching "key":
  val=$(printf '%s\n' "$raw" | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([-]?[0-9]+).*/\1/")
  [[ $val =~ ^-?[0-9]+$ ]] || val=0
  echo "$val"
}

segment_iterate_file() {
  # Parse post_plugin_segments array objects from a perf sample JSON file
  # We only need label + mean_ms
  local file="$1"
  [[ $DO_SEGMENTS -eq 1 ]] || return 0
  awk '
    /"post_plugin_segments"[[:space:]]*:/ {in_arr=1; next}
    in_arr==1 && /\]/ {in_arr=0; next}
    in_arr==1 {
      # Expect lines like {"label":"compinit","cold_ms":15,"warm_ms":10,"mean_ms":12}
      if ($0 ~ /"label"/) {
        lab=$0
        # extract label
        gsub(/.*"label":"/, "", lab)
        gsub(/".*/, "", lab)
        # extract mean_ms
        mm=$0
        gsub(/.*"mean_ms":/, "", mm)
        gsub(/[^0-9].*/, "", mm)
        if (lab != "" && mm ~ /^[0-9]+$/) {
          printf("%s %s\n", lab, mm)
        }
      }
    }
  ' "$file" 2>/dev/null
}

stats_mean() {
  # args: list of numbers (returns floating mean with 2 decimals)
  awk 'BEGIN{n=0; s=0} {s+=$1; n++} END{ if(n>0) printf("%.2f", s/n); else print "0.00"}' <<<"$*"
}

stats_min() {
  awk 'BEGIN{min=""} { if(min==""||$1<min) min=$1 } END{ if(min=="") min=0; printf("%d", min) }' <<<"$*"
}

stats_max() {
  awk 'BEGIN{max=""} { if(max==""||$1>max) max=$1 } END{ if(max=="") max=0; printf("%d", max) }' <<<"$*"
}

stats_stddev() {
  # population stddev (float with 2 decimals)
  awk '
    BEGIN{n=0; sum=0; sumsq=0}
    {n++; sum+=$1; sumsq+=$1*$1}
    END{
      if(n<2){printf("0.00"); exit}
      mean=sum/n
      var=(sumsq/n) - (mean*mean)
      if (var<0) var=0
      printf("%.2f", sqrt(var))
    }
  ' <<<"$*"
}

add_segment_value() {
  local label="$1" value="$2"
  # Initialize
  if [[ -z ${seg_count[$label]:-} ]]; then
    seg_count[$label]=0
    seg_min[$label]=$value
    seg_max[$label]=$value
    seg_sum[$label]=0
    seg_sum_sq[$label]=0
    seg_values[$label]=""
  fi
  (( seg_count[$label]++ ))
  (( value < seg_min[$label] )) && seg_min[$label]=$value
  (( value > seg_max[$label] )) && seg_max[$label]=$value
  (( seg_sum[$label] += value ))
  (( seg_sum_sq[$label] += value * value ))
  seg_values[$label]="${seg_values[$label]} $value"
}

# ---------------- Capture Loop ----------------
echo "[perf-capture-multi] Starting multi-sample capture: samples=$SAMPLES sleep=$SLEEP_INTERVAL segments=$((DO_SEGMENTS)) timeout=${PERF_CAPTURE_RUN_TIMEOUT_SEC}s debug=${PERF_CAPTURE_MULTI_DEBUG}"

valid_sample_count=0
skipped_sample_count=0
out_index=0
for (( i=1; i<=SAMPLES; i++ )); do
  echo "[perf-capture-multi] Run $i/$SAMPLES"
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] invoking perf-capture (iteration=$i)"
  fi
  run_rc=0
  if [[ $QUIET -eq 1 ]]; then
    if ! timeout "$PERF_CAPTURE_RUN_TIMEOUT_SEC"s zsh "$PERF_CAPTURE_BIN" >/dev/null 2>&1; then
      run_rc=$?
    fi
  else
    if ! timeout "$PERF_CAPTURE_RUN_TIMEOUT_SEC"s zsh "$PERF_CAPTURE_BIN"; then
      run_rc=$?
    fi
  fi
  if (( run_rc != 0 )); then
    echo "[perf-capture-multi] WARN: perf-capture exited rc=$run_rc on run $i (skipping sample)" >&2
    (( skipped_sample_count++ ))
    # progress marker (error)
    print "run=$i rc=$run_rc skipped=1" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
    continue
  fi

  # After each run perf-current.json is the latest
  CURRENT_FILE="$METRICS_DIR/perf-current.json"
  if [[ ! -f "$CURRENT_FILE" ]]; then
    echo "[perf-capture-multi] ERROR: perf-current.json not found after run $i" >&2
    exit 2
  fi

  SAMPLE_FILE="$METRICS_DIR/perf-sample-${i}.json"
  cp "$CURRENT_FILE" "$SAMPLE_FILE"

  cold=$(extract_json_number "$SAMPLE_FILE" cold_ms)
  warm=$(extract_json_number "$SAMPLE_FILE" warm_ms)
  pre=$(extract_json_number "$SAMPLE_FILE" pre_plugin_cost_ms)
  post=$(extract_json_number "$SAMPLE_FILE" post_plugin_cost_ms)
  prompt=$(extract_json_number "$SAMPLE_FILE" prompt_ready_ms)

  # Normalize to non-negative integers (treat invalid / negative as 0)
  [[ $cold =~ ^-?[0-9]+$ ]] || cold=0
  [[ $warm =~ ^-?[0-9]+$ ]] || warm=0
  [[ $pre =~ ^-?[0-9]+$ ]] || pre=0
  [[ $post =~ ^-?[0-9]+$ ]] || post=0
  [[ $prompt =~ ^-?[0-9]+$ ]] || prompt=0
  (( cold < 0 )) && cold=0
  (( warm < 0 )) && warm=0
  (( pre  < 0 )) && pre=0
  (( post < 0 )) && post=0
  (( prompt < 0 )) && prompt=0

  # Skip invalid sample (both cold & warm zero implies capture failed / early abort)
  if (( cold == 0 && warm == 0 )); then
    (( skipped_sample_count++ ))
    echo "[perf-capture-multi] NOTICE: Skipping sample $i (cold_ms=0 warm_ms=0)"
    mv "$SAMPLE_FILE" "${SAMPLE_FILE}.skipped" 2>/dev/null || true
    # Do not record metrics for this iteration
    continue
  fi

  (( valid_sample_count++ ))
  # Per-sample debug summary
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] sample $i parsed cold=$cold warm=$warm pre=$pre post=$post prompt=$prompt" >&2
  fi
  # Append progress marker
  print "run=$i rc=0 cold=$cold warm=$warm pre=$pre post=$post prompt=$prompt" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true

  cold_values+=("$cold")
  warm_values+=("$warm")
  pre_values+=("$pre")
  post_values+=("$post")
  prompt_values+=("$prompt")

  if [[ $DO_SEGMENTS -eq 1 ]]; then
    while read -r lab mm; do
      add_segment_value "$lab" "$mm"
    done < <(segment_iterate_file "$SAMPLE_FILE")
  fi

  if (( i < SAMPLES )) && [[ "$SLEEP_INTERVAL" != "0" ]]; then
    sleep "$SLEEP_INTERVAL"
  fi
done

# ---------------- Aggregate Computation ----------------
join_csv() {
  local arr; arr=("$@")
  local first=1 out=""
  for v in "${arr[@]}"; do
    if (( first )); then
      out="$v"; first=0
    else
      out="$out,$v"
    fi
  done
  printf '%s' "$out"
}

cold_csv=$(join_csv "${cold_values[@]}")
warm_csv=$(join_csv "${warm_values[@]}")
pre_csv=$(join_csv "${pre_values[@]}")
post_csv=$(join_csv "${post_values[@]}")
prompt_csv=$(join_csv "${prompt_values[@]}")

metric_block() {
  local name="$1"; shift
  local -a vals=("$@")
  local csv=$(join_csv "${vals[@]}")
  local mean=$(stats_mean "${vals[*]}")
  local min=$(stats_min "${vals[*]}")
  local max=$(stats_max "${vals[*]}")
  local sd=$(stats_stddev "${vals[*]}")
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] metric=${name} values=${vals[*]:-} mean=${mean} min=${min} max=${max} sd=${sd}" >&2
  fi
  cat <<EOF
    "${name}": {
      "mean": $mean,
      "min": $min,
      "max": $max,
      "stddev": $sd,
      "values": [${csv}]
    }
EOF
}

# ---------------- Emit Aggregate JSON ----------------
AGG_FILE="$METRICS_DIR/perf-multi-current.json"
{
  echo "{"
  echo "  \"schema\": \"perf-multi.v1\","
  echo "  \"timestamp\": \"$(timestamp)\","
  ACTUAL_SAMPLES=$valid_sample_count
  echo "  \"samples\": $ACTUAL_SAMPLES,"
  if [[ -n "${GUIDELINES_CHECKSUM:-}" ]]; then
    echo "  \"guidelines_checksum\": \"${GUIDELINES_CHECKSUM}\","
  else
    echo "  \"guidelines_checksum\": null,"
  fi
  # Per-run summary array
  echo "  \"per_run\": ["
  for (( i=1; i<=SAMPLES; i++ )); do
    file="$METRICS_DIR/perf-sample-${i}.json"
    # Use default 0 to avoid unbound element errors under `set -u` if array slot missing
    cold="${cold_values[$out_index]:-0}"
    warm="${warm_values[$out_index]:-0}"
    pre="${pre_values[$out_index]:-0}"
    post="${post_values[$out_index]:-0}"
    prompt="${prompt_values[$out_index]:-0}"
    # Skip placeholder zero-only entries (were never appended) by detecting 0-cold & 0-warm while we still have more recorded samples ahead
    if (( cold == 0 && warm == 0 )); then
      continue
    fi
    comma=","
    (( out_index + 1 == ACTUAL_SAMPLES )) && comma=""
    echo "    {\"index\": $((out_index+1)), \"cold_ms\": $cold, \"warm_ms\": $warm, \"pre_plugin_cost_ms\": $pre, \"post_plugin_cost_ms\": $post, \"prompt_ready_ms\": $prompt}${comma}"
    (( out_index++ ))
  done
  echo "  ],"
  echo "  \"aggregate\": {"
  # Aggregate metrics
  metric_block cold_ms "${cold_values[@]:-0}"
  echo "    ,"
  metric_block warm_ms "${warm_values[@]:-0}"
  echo "    ,"
  metric_block pre_plugin_cost_ms "${pre_values[@]:-0}"
  echo "    ,"
  metric_block post_plugin_cost_ms "${post_values[@]:-0}"
  echo "    ,"
  metric_block prompt_ready_ms "${prompt_values[@]:-0}"
  echo "  },"
  if [[ $DO_SEGMENTS -eq 1 ]]; then
    if (( ${#seg_count[@]} == 0 )); then
      echo "  \"segments\": []"
      echo "[perf-capture-multi] NOTICE: No post_plugin_segments detected across valid samples (seg_count=0)" >&2
    else
      echo "  \"segments\": ["
      seg_labels=("${(@k)seg_count}")
      seg_labels=("${(on)seg_labels}")
      for (( si=1; si<=${#seg_labels[@]}; si++ )); do
        lab="${seg_labels[$si]}"
        count=${seg_count[$lab]}
        sum=${seg_sum[$lab]}
        sum_sq=${seg_sum_sq[$lab]}
        min=${seg_min[$lab]}
        max=${seg_max[$lab]}
        mean=$(( sum / count ))
        var_num=$(( (sum_sq / count) - (mean * mean) ))
        (( var_num < 0 )) && var_num=0
        stddev=$(awk -v v="$var_num" 'BEGIN{printf("%d", sqrt(v)+0.5)}')
        csv_values=$(echo "${seg_values[$lab]}" | sed -e 's/^ *//' -e 's/  */ /g' | tr ' ' ',' )
        [[ -z "$csv_values" ]] && csv_values="0"
        comma=","
        (( si == ${#seg_labels[@]} )) && comma=""
        cat <<EOF
    { "label": "$lab", "samples": $count, "mean_ms": $mean, "min_ms": $min, "max_ms": $max, "stddev_ms": $stddev, "values":[${csv_values}] }${comma}
EOF
      done
      echo "  ]"
    fi
  else
    echo "  \"segments\": []"
  fi
  echo "}"
} >"$AGG_FILE"

echo "[perf-capture-multi] Wrote aggregate: $AGG_FILE"
echo "[perf-capture-multi] Samples requested=$SAMPLES valid=$valid_sample_count skipped=$skipped_sample_count (cold_ms mean=$(stats_mean \"${cold_values[*]:-0}\"), post_plugin_cost_ms mean=$(stats_mean \"${post_values[*]:-0}\")) timeout=${PERF_CAPTURE_RUN_TIMEOUT_SEC}s"

# Guidance for next steps (informational)
cat <<'NOTE'
[perf-capture-multi] Guidance:
  - Use stddev/mean ratio to decide when to advance from observe -> warn.
  - High variance on post_plugin_cost_ms suggests deferring more work asynchronously.
  - Commit perf-sample-* only if needed for debugging; typically ignore via .gitignore.
  - Update documentation (Instrumentation Snapshot / Interim Performance Roadmap) if mean shifts materially.
NOTE

exit 0
