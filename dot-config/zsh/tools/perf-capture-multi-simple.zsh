#!/usr/bin/env zsh
# -----------------------------------------------------------------------------
# perf-capture-multi-simple.zsh
#
# Purpose:
#   Minimal / robust fallback multi-run performance capture aggregator used
#   while the advanced perf-capture-multi.zsh harness is being repaired.
#   Executes N independent invocations of tools/perf-capture.zsh (fast path),
#   collects per-run lifecycle metrics (pre/post/prompt), and emits an
#   aggregate JSON with basic statistics & relative stddev (RSD).
#
# Key Design Goals:
#   - Zero synthetic replication (only authentic samples recorded)
#   - Graceful degradation if jq is absent (pure awk/grep parsing fallback)
#   - Simplicity: no async watchdog, no retries; each run is self-contained
#   - Provides authenticity + RSD fields for gating / variance-state input
#
# Outputs (default metrics dir: docs/redesignv2/artifacts/metrics):
#   perf-simple-sample-<i>.json         (raw copy of perf-current.json after each run)
#   perf-multi-simple.json              (aggregate, schema: perf-multi-simple.v1)
#
# Aggregate JSON (abridged):
# {
#   "schema":"perf-multi-simple.v1",
#   "timestamp":"2025-09-04T22:20:15Z",
#   "samples":5,
#   "metrics":{
#     "pre_plugin_cost_ms":{"values":[...],"mean":..,"stddev":..,"rsd":..},
#     "post_plugin_total_ms":{...},
#     "prompt_ready_ms":{...},
#     "cold_ms":{...},
#     "warm_ms":{...}
#   },
#   "authentic_samples":5,
#   "requested_samples":5,
#   "partial":false
# }
#
# Exit Codes:
#   0 success (≥1 sample)
#   1 argument / environment error
#   2 no successful samples collected
#
# Environment / Flags:
#   ZDOTDIR                         Base config (auto-detected if unset)
#   PERF_CAPTURE_BIN                Override path to tools/perf-capture.zsh
#   PERF_SIMPLE_SAMPLES             Default sample count if -n not provided
#   PERF_SIMPLE_SLEEP               Default inter-run sleep (seconds, default 0)
#   PERF_SIMPLE_FORCE=1             Ignore existing aggregate & always recapture
#
# CLI:
#   -n / --samples <N>
#   -s / --sleep <SEC>
#   -o / --output <FILE>            Aggregate JSON path (default perf-multi-simple.json)
#   --metrics-dir <DIR>             Override metrics directory
#   --quiet                         Suppress per-run perf-capture output
#   -h / --help
#
# Notes:
#   - post_plugin_total_ms preferred; falls back to post_plugin_cost_ms.
#   - If a run yields zero cold & warm → sample skipped.
#   - No retries: caller can loop externally if needed.
#
# -----------------------------------------------------------------------------

# Disable -e so we can capture non‑zero statuses without aborting the loop; keep -u and pipefail for safety.
set -uo pipefail
DEBUG_SIMPLE_MULTI=${DEBUG_SIMPLE_MULTI:-1}

print_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  -n, --samples <N>        Number of capture runs (default: \${PERF_SIMPLE_SAMPLES:-5})
  -s, --sleep <SEC>        Sleep between runs (default: \${PERF_SIMPLE_SLEEP:-0})
  -o, --output <FILE>      Aggregate JSON output (default: perf-multi-simple.json)
      --metrics-dir <DIR>  Metrics directory override
      --quiet              Suppress per-run perf-capture output
      --force              Force new capture (ignore existing aggregate)
  -h, --help               Show this help

Environment:
  PERF_SIMPLE_SAMPLES, PERF_SIMPLE_SLEEP, PERF_SIMPLE_FORCE, ZDOTDIR, PERF_CAPTURE_BIN

EOF
}

# ---------------- Argument Parsing ----------------
SAMPLES="${PERF_SIMPLE_SAMPLES:-5}"
SLEEP_INTERVAL="${PERF_SIMPLE_SLEEP:-0}"
OUTPUT_FILE=""
QUIET=0
FORCE="${PERF_SIMPLE_FORCE:-0}"
METRICS_DIR_OVERRIDE=""

while (( $# )); do
  case "$1" in
    -n|--samples) shift || { echo "Missing value after --samples" >&2; exit 1; }; SAMPLES="$1" ;;
    -s|--sleep) shift || { echo "Missing value after --sleep" >&2; exit 1; }; SLEEP_INTERVAL="$1" ;;
    -o|--output) shift || { echo "Missing value after --output" >&2; exit 1; }; OUTPUT_FILE="$1" ;;
    --metrics-dir) shift || { echo "Missing value after --metrics-dir" >&2; exit 1; }; METRICS_DIR_OVERRIDE="$1" ;;
    --quiet) QUIET=1 ;;
    --force) FORCE=1 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift || true
done

if ! [[ "$SAMPLES" =~ ^[0-9]+$ ]] || (( SAMPLES < 1 )); then
  echo "Invalid sample count: $SAMPLES" >&2
  exit 1
fi

# ---------------- Environment & Paths ----------------
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Metrics directory preference
if [[ -n "$METRICS_DIR_OVERRIDE" ]]; then
  METRICS_DIR="$METRICS_DIR_OVERRIDE"
elif [[ -d "$ZDOTDIR/docs/redesignv2/artifacts/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
elif [[ -d "$ZDOTDIR/docs/redesign/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesign/metrics"
else
  echo "Unable to locate metrics directory (override with --metrics-dir)" >&2
  exit 1
fi

mkdir -p "$METRICS_DIR" 2>/dev/null || true

PERF_CAPTURE_BIN="${PERF_CAPTURE_BIN:-$ZDOTDIR/tools/perf-capture.zsh}"
if [[ ! -f "$PERF_CAPTURE_BIN" ]]; then
  echo "perf-capture tool not found: $PERF_CAPTURE_BIN" >&2
  exit 1
fi

# Output file
if [[ -z "$OUTPUT_FILE" ]]; then
  OUTPUT_FILE="$METRICS_DIR/perf-multi-simple.json"
fi

if (( FORCE != 1 )) && [[ -s "$OUTPUT_FILE" ]]; then
  echo "[perf-capture-multi-simple] Existing aggregate present ($OUTPUT_FILE) – use --force to overwrite"
  exit 0
fi

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

timestamp_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date
}

# ---------------- Data Accumulators ----------------
cold_vals=()
warm_vals=()
pre_vals=()
post_vals=()
prompt_vals=()
valid=0
skipped=0

# ---------------- Helpers ----------------
append_val() {
  # Ensures numeric, else 0
  local v="$1"
  [[ "$v" =~ ^-?[0-9]+$ ]] || v=0
  echo "$v"
}

stats_mean() {
  awk '{for(i=1;i<=NF;i++){s+=$i;n++}}END{if(n>0)printf("%.2f",s/n);else print "0.00"}' <<<"$*"
}
stats_stddev() {
  awk '{
    for(i=1;i<=NF;i++){n++;s+=$i;ss+=$i*$i}
  }END{
    if(n<2){printf("0.00");exit}
    m=s/n
    v=(ss/n)-(m*m); if(v<0)v=0
    printf("%.2f", sqrt(v))
  }' <<<"$*"
}
stats_rsd() {
  local mean sd
  mean=$(stats_mean "$@")
  sd=$(stats_stddev "$@")
  awk -v m="$mean" -v s="$sd" 'BEGIN{ if (m+0==0) printf "0.0000"; else printf "%.4f", (s/m) }'
}

extract_field_portable() {
  # Prefer jq, otherwise grep+sed
  local file="$1" key="$2" val
  if (( have_jq )); then
    val=$(jq -r --arg k "$key" '.[$k] // .lifecycle[$k] // empty' "$file" 2>/dev/null || true)
  else
    val=$(grep -E "\"$key\"[[:space:]]*:" "$file" 2>/dev/null | head -1 | sed -E "s/.*\"$key\"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/")
  fi
  [[ "$val" =~ ^[0-9]+$ ]] || val=0
  echo "$val"
}

# ---------------- Capture Loop ----------------
echo "[perf-capture-multi-simple] Starting: samples=$SAMPLES sleep=$SLEEP_INTERVAL quiet=$QUIET metrics_dir=$METRICS_DIR"
for (( i=1; i<=SAMPLES; i++ )); do  # (duplicate loop marker not expected; if present, keep instrumentation consistent)
  if (( DEBUG_SIMPLE_MULTI )); then
    echo "[perf-capture-multi-simple][debug] begin-iteration i=$i"
  fi
  if (( DEBUG_SIMPLE_MULTI )); then
    echo "[perf-capture-multi-simple][debug] begin-iteration i=$i"
  fi
  echo "[perf-capture-multi-simple] Run $i/$SAMPLES"
  # Remove perf-current.json before run to avoid stale reuse
  rm -f "$METRICS_DIR/perf-current.json" 2>/dev/null || true

  if (( QUIET )); then
    ( zsh "$PERF_CAPTURE_BIN" >/dev/null 2>&1 )
    run_rc=$?
  else
    ( zsh "$PERF_CAPTURE_BIN" )
    run_rc=$?
  fi
  if (( DEBUG_SIMPLE_MULTI )); then
    echo "[perf-capture-multi-simple][debug] run_rc=$run_rc i=$i"
  fi
  # Never abort loop on non-zero (just record skip if no sample produced)

  SAMPLE_SRC="$METRICS_DIR/perf-current.json"
  if [[ ! -f "$SAMPLE_SRC" ]]; then
    echo "[perf-capture-multi-simple] WARN: missing perf-current.json (skipping)"
    (( skipped++ ))
    continue
  fi

  # Copy sample
  SAMPLE_OUT="$METRICS_DIR/perf-simple-sample-${i}.json"
  cp "$SAMPLE_SRC" "$SAMPLE_OUT" 2>/dev/null || true

  cold=$(extract_field_portable "$SAMPLE_OUT" cold_ms)
  warm=$(extract_field_portable "$SAMPLE_OUT" warm_ms)
  pre=$(extract_field_portable "$SAMPLE_OUT" pre_plugin_cost_ms)

  # Prefer total first
  post=$(extract_field_portable "$SAMPLE_OUT" post_plugin_total_ms)
  if (( post == 0 )); then
    post=$(extract_field_portable "$SAMPLE_OUT" post_plugin_cost_ms)
  fi
  prompt=$(extract_field_portable "$SAMPLE_OUT" prompt_ready_ms)
  if (( prompt == 0 && post > 0 )); then
    if [[ "${PERF_SIMPLE_STRICT_PROMPT:-0}" == "1" ]]; then
      # Strict mode: leave prompt_ready_ms at 0 so downstream tooling
      # can distinguish absence of explicit PROMPT_READY marker and
      # avoid mirroring post_plugin_total_ms.
      :
    else
      prompt=$post   # approximate fallback (documented)
    fi
  fi

  # Validate sample
  if (( cold == 0 && warm == 0 )); then
    echo "[perf-capture-multi-simple] NOTICE: zero cold & warm – skip sample $i"
    (( skipped++ ))
    continue
  fi

  cold_vals+=("$(append_val "$cold")")
  warm_vals+=("$(append_val "$warm")")
  pre_vals+=("$(append_val "$pre")")
  post_vals+=("$(append_val "$post")")
  prompt_vals+=("$(append_val "$prompt")")
  (( valid++ ))

  if (( SLEEP_INTERVAL > 0 )) && (( i < SAMPLES )); then
    sleep "$SLEEP_INTERVAL"
  fi
done

if (( valid == 0 )); then
  echo "[perf-capture-multi-simple] ERROR: no valid samples collected" >&2
  exit 2
fi

partial=false
if (( valid < SAMPLES )); then
  partial=true
  echo "[perf-capture-multi-simple] WARN: partial capture valid=$valid requested=$SAMPLES"
fi

join_csv() {
  local first=1 out="" v
  for v in "$@"; do
    if (( first )); then out="$v"; first=0; else out+=",${v}"; fi
  done
  printf '%s' "$out"
}

cold_csv=$(join_csv "${cold_vals[@]}")
warm_csv=$(join_csv "${warm_vals[@]}")
pre_csv=$(join_csv "${pre_vals[@]}")
post_csv=$(join_csv "${post_vals[@]}")
prompt_csv=$(join_csv "${prompt_vals[@]}")

mean_cold=$(stats_mean "${cold_vals[*]}")
sd_cold=$(stats_stddev "${cold_vals[*]}")
rsd_cold=$(stats_rsd "${cold_vals[*]}")

mean_warm=$(stats_mean "${warm_vals[*]}")
sd_warm=$(stats_stddev "${warm_vals[*]}")
rsd_warm=$(stats_rsd "${warm_vals[*]}")

mean_pre=$(stats_mean "${pre_vals[*]}")
sd_pre=$(stats_stddev "${pre_vals[*]}")
rsd_pre=$(stats_rsd "${pre_vals[*]}")

mean_post=$(stats_mean "${post_vals[*]}")
sd_post=$(stats_stddev "${post_vals[*]}")
rsd_post=$(stats_rsd "${post_vals[*]}")

mean_prompt=$(stats_mean "${prompt_vals[*]}")
sd_prompt=$(stats_stddev "${prompt_vals[*]}")
rsd_prompt=$(stats_rsd "${prompt_vals[*]}")

# ---------------- Outlier Detection (F54 precursor) ----------------
# Detect a single large post_plugin_total_ms outlier (>2x median) to surface
# variance anomalies early. Added fields emitted under "outlier" in JSON.
compute_median() {
  local -a arr=("$@")
  local n=${#arr[@]}
  (( n == 0 )) && { echo 0; return 0; }
  local -a sorted
  IFS=$'\n' sorted=($(printf "%s\n" "${arr[@]}" | sort -n))
  if (( n % 2 == 1 )); then
    echo "${sorted[$(( (n+1)/2 ))]}"
  else
    local a=${sorted[$(( n/2 ))]}
    local b=${sorted[$(( n/2 + 1 ))]}
    echo $(( (a + b) / 2 ))
  fi
}

median_post=$(compute_median "${post_vals[@]}")
outlier_detected=false
outlier_metric=""
outlier_index=-1
outlier_value=0
outlier_factor=0
if [[ -n "${median_post:-}" && "$median_post" -gt 0 ]]; then
  idx=0
  for v in "${post_vals[@]}"; do
    if (( v > median_post * 2 )); then
      outlier_detected=true
      outlier_metric="post_plugin_total_ms"
      outlier_index=$idx
      outlier_value=$v
      outlier_factor=$(awk -v vv=$v -v mm=$median_post 'BEGIN{printf "%.4f", vv/mm}')
      break
    fi
    (( idx++ ))
  done
fi

ts=$(timestamp_iso)

# ---------------- Emit Aggregate JSON ----------------
tmp_out="${OUTPUT_FILE}.tmp"
{
  echo "{"
  echo "  \"schema\": \"perf-multi-simple.v1\","
  echo "  \"timestamp\": \"$ts\","
  echo "  \"requested_samples\": $SAMPLES,"
  echo "  \"samples\": $valid,"
  echo "  \"authentic_samples\": $valid,"
  echo "  \"partial\": $partial,"
  echo "  \"strict_prompt\": ${PERF_SIMPLE_STRICT_PROMPT:-0},"
  echo "  \"outlier\": {\"detected\": $outlier_detected, \"metric\": \"${outlier_metric}\", \"index\": $outlier_index, \"value\": $outlier_value, \"median\": ${median_post:-0}, \"factor\": \"${outlier_factor:-0}\"},"
  echo "  \"metrics\": {"
  echo "    \"cold_ms\": {\"values\":[$cold_csv],\"mean\":$mean_cold,\"stddev\":$sd_cold,\"rsd\":$rsd_cold},"
  echo "    \"warm_ms\": {\"values\":[$warm_csv],\"mean\":$mean_warm,\"stddev\":$sd_warm,\"rsd\":$rsd_warm},"
  echo "    \"pre_plugin_cost_ms\": {\"values\":[$pre_csv],\"mean\":$mean_pre,\"stddev\":$sd_pre,\"rsd\":$rsd_pre},"
  echo "    \"post_plugin_total_ms\": {\"values\":[$post_csv],\"mean\":$mean_post,\"stddev\":$sd_post,\"rsd\":$rsd_post},"
  echo "    \"prompt_ready_ms\": {\"values\":[$prompt_csv],\"mean\":$mean_prompt,\"stddev\":$sd_prompt,\"rsd\":$rsd_prompt}"
  echo "  }"
  echo "}"
} >| "$tmp_out"

mv "$tmp_out" "$OUTPUT_FILE" 2>/dev/null || { echo "Failed to write $OUTPUT_FILE" >&2; exit 1; }

echo "[perf-capture-multi-simple] Wrote aggregate: $OUTPUT_FILE (valid=$valid partial=$partial)"

exit 0
