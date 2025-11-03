#!/usr/bin/env zsh
# preplugin-baseline-capture.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
#
# PURPOSE:
#   Capture a multi-sample performance baseline for the pre-plugin phase (`pre_plugin_total`)
#   and emit a JSON artifact (default: docs/redesignv2/artifacts/metrics/preplugin-baseline.json)
#   suitable for regression guards and historical auditing.
#
# FEATURES:
#   - Runs perf capture N times (default 5) using tools/perf-capture.zsh
#   - Extracts SEGMENT line: SEGMENT name=pre_plugin_total ms=<value>
#   - Computes summary statistics (mean, stdev, min, max, p50, p90, p95, p99)
#   - Emits structured JSON with provenance fields (timestamp, sample_count, tool_version placeholder)
#   - Graceful handling of missing tooling or segment lines (clear ERROR status & non-zero exit)
#   - Optional outlier trimming (IQR filtering) with reporting (disabled by default)
#
# USAGE:
#   ./preplugin-baseline-capture.zsh
#
# IMPORTANT:
#   Run from a clean environment representative of typical user startup.
#   Avoid heavy background load during capture to reduce noise.
#
# ENVIRONMENT OVERRIDES:
#   PREPLUGIN_RUNS                 Number of capture iterations (default 5)
#   PREPLUGIN_MIN_RUNS             Minimum required runs (default 3)
#   PREPLUGIN_OUT                  Output JSON path (default autodetect redesignv2 metrics dir)
#   PREPLUGIN_SEGMENTS_FILE        Override final segments file path to parse (per run it honors perf tools default)
#   PREPLUGIN_VERBOSE=1            Emit detailed progress to stderr
#   PREPLUGIN_IQR_FILTER=1         Enable simple IQR outlier filtering
#   PREPLUGIN_KEEP_INTERMEDIATE=1  Preserve raw per-run segment snapshots (stored next to output)
#   PREPLUGIN_TAG                  Custom tag string to embed (e.g. "stage2-initial")
#
# EXIT CODES:
#   0 Success
#   1 Usage / configuration error
#   2 Tooling missing / capture failure
#   3 No valid samples collected
#   4 Segment missing in all runs
#
# OUTPUT JSON SCHEMA (example):
# {
#   "segment": "pre_plugin_total",
#   "samples_ms": [95,97,96,95,98],
#   "filtered_samples_ms": [... or null],
#   "sample_count": 5,
#   "filtered_sample_count": 5,
#   "mean_ms": 96,
#   "stdev_ms": 1.1,
#   "min_ms": 95,
#   "max_ms": 98,
#   "p50_ms": 96,
#   "p90_ms": 98,
#   "p95_ms": 98,
#   "p99_ms": 98,
#   "iqr_low_cutoff_ms": null,
#   "iqr_high_cutoff_ms": null,
#   "guidelines_checksum": "<sha256|unset>",
#   "captured_at": "2025-09-02T12:34:56Z",
#   "runs_requested": 5,
#   "tool_version": "1.0",
#   "host_uname": "Darwin",
#   "tag": "stage2-baseline",
#   "notes": "Stage 2 baseline (multi-sample N=5)"
# }
#
# DEPENDENCIES:
#   - tools/perf-capture.zsh (must emit perf-current-segments.txt with SEGMENT lines)
#
# SAFETY:
#   - Does not modify user configuration; read-only operations + file write of JSON artifact.
#
# FUTURE EXTENSIONS:
#   - Warm vs cold run classification
#   - Confidence interval computation
#   - Rolling baseline merge
#
set -euo pipefail

########################################
# Configuration & Helpers
########################################
: ${ZDOTDIR:=${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
: ${PREPLUGIN_RUNS:=5}
: ${PREPLUGIN_MIN_RUNS:=3}
: ${PREPLUGIN_VERBOSE:=0}
: ${PREPLUGIN_IQR_FILTER:=0}
: ${PREPLUGIN_KEEP_INTERMEDIATE:=0}
: ${PREPLUGIN_TAG:=stage2-baseline}

SEGMENT_NAME="pre_plugin_total"
TOOLS_DIR="${ZDOTDIR}/tools"
PERF_CAPTURE="${TOOLS_DIR}/perf-capture.zsh"
DEFAULT_OUT="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/preplugin-baseline.json"
OUT_PATH="${PREPLUGIN_OUT:-$DEFAULT_OUT}"

log()  { (( PREPLUGIN_VERBOSE )) && printf '[preplugin-baseline] %s\n' "$*" >&2; }
err()  { printf '[preplugin-baseline][error] %s\n' "$*" >&2; }

iso8601() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

require_positive_int() {
  local name="$1" val="$2"
  [[ "$val" == <-> && "$val" -gt 0 ]] || { err "$name must be positive integer (got: $val)"; exit 1; }
}

require_positive_int "PREPLUGIN_RUNS" "$PREPLUGIN_RUNS"
require_positive_int "PREPLUGIN_MIN_RUNS" "$PREPLUGIN_MIN_RUNS"
(( PREPLUGIN_RUNS >= PREPLUGIN_MIN_RUNS )) || { err "PREPLUGIN_RUNS ($PREPLUGIN_RUNS) < PREPLUGIN_MIN_RUNS ($PREPLUGIN_MIN_RUNS)"; exit 1; }

[[ -x "$PERF_CAPTURE" ]] || { err "perf capture tool missing: $PERF_CAPTURE"; exit 2; }

metrics_dir="${OUT_PATH%/*}"
# Use explicit command invocation for portability and environments with restricted builtins
if command -v mkdir >/dev/null 2>&1; then
  command mkdir -p "$metrics_dir" 2>/dev/null || true
else
  # Fallback: attempt to autoload a shell mkdir (rarely needed)
  autoload -U mkdir 2>/dev/null || true
  mkdir -p "$metrics_dir" 2>/dev/null || true
fi

intermediate_dir="${metrics_dir}/preplugin-runs"
if (( PREPLUGIN_KEEP_INTERMEDIATE )); then
  if command -v mkdir >/dev/null 2>&1; then
    command mkdir -p "$intermediate_dir" 2>/dev/null || true
  else
    autoload -U mkdir 2>/dev/null || true
    mkdir -p "$intermediate_dir" 2>/dev/null || true
  fi
fi

########################################
# Data Structures
########################################
typeset -a samples
typeset -a raw_samples
typeset -A run_meta

########################################
# Capture Loop
########################################
# Portable run loop (avoid reliance on external seq)
run=1
while (( run <= PREPLUGIN_RUNS )); do
  log "Run $run/$PREPLUGIN_RUNS: capturing segments"
  # Each invocation should refresh perf-current-segments.txt (default path autodetected by perf-capture)
  if ! "$PERF_CAPTURE" --segments >/dev/null 2>&1; then
    err "perf capture failed (run $run)"
    (( run++ ))
    continue
  fi

  # Determine segments file; mimic perf-segment-budget autolocation
  segments_file="${PREPLUGIN_SEGMENTS_FILE:-${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt}"
  [[ -f "$segments_file" ]] || segments_file="${ZDOTDIR}/docs/redesign/metrics/perf-current-segments.txt"
  if [[ ! -f "$segments_file" ]]; then
    err "segments file not found after capture (run $run)"
    continue
  fi

  segment_line=$(grep -E "^SEGMENT name=${SEGMENT_NAME} " "$segments_file" 2>/dev/null | head -1 || true)
  if [[ -z "$segment_line" ]]; then
    err "segment '${SEGMENT_NAME}' missing (run $run)"
    continue
  fi

  ms_val=$(printf '%s' "$segment_line" | sed -E 's/.* ms=([0-9]+).*/\1/' )
  if [[ -z "$ms_val" || "$ms_val" != <-> ]]; then
    err "failed to parse ms value (run $run): $segment_line"
    continue
  fi

  raw_samples+=("$ms_val")
  samples+=("$ms_val")
  run_meta["run_$run"]="$ms_val"
  log "Run $run: ${SEGMENT_NAME}=${ms_val}ms"

  if (( PREPLUGIN_KEEP_INTERMEDIATE )); then
    cp "$segments_file" "${intermediate_dir}/segments-run-${run}.txt" 2>/dev/null || true
  fi
  (( run++ ))
done

if (( ${#samples[@]} == 0 )); then
  err "no valid samples collected"
  exit 4
fi

if (( ${#samples[@]} < PREPLUGIN_MIN_RUNS )); then
  err "collected ${#samples[@]} samples (< PREPLUGIN_MIN_RUNS=${PREPLUGIN_MIN_RUNS})"
  exit 3
fi

########################################
# Optional IQR Filter
########################################
typeset -a filtered_samples
filtered_samples=("${samples[@]}")

iqr_low="null"
iqr_high="null"

if (( PREPLUGIN_IQR_FILTER )); then
  # Sort
  typeset -a sorted
  sorted=("${samples[@]}")
  IFS=$'\n' sorted=($(printf '%s\n' "${sorted[@]}" | sort -n)) || true
  local_count=${#sorted[@]}
  q1_index=$(( (local_count + 1) / 4 ))
  q3_index=$(( (3 * (local_count + 1)) / 4 ))
  (( q1_index < 1 )) && q1_index=1
  (( q3_index < 1 )) && q3_index=local_count

  q1=${sorted[$q1_index]}
  q3=${sorted[$q3_index]}
  iqr=$(( q3 - q1 ))
  # Tukey fences (mild)
  low_cut=$(( q1 - 1 * iqr ))
  high_cut=$(( q3 + 1 * iqr ))
  iqr_low="$low_cut"
  iqr_high="$high_cut"

  typeset -a kept
  for v in "${filtered_samples[@]}"; do
    if (( v < low_cut || v > high_cut )); then
      log "IQR filter removing outlier: $v (cutoffs ${low_cut}-${high_cut})"
      continue
    fi
    kept+=("$v")
  done
  if (( ${#kept[@]} >= PREPLUGIN_MIN_RUNS )); then
    filtered_samples=("${kept[@]}")
  else
    log "IQR filtering would reduce samples below minimum; retaining original set"
  fi
fi

########################################
# Statistics Helpers
########################################
calc_mean() {
  local -a arr=("$@")
  local sum=0
  for n in "${arr[@]}"; do ((sum+=n)); done
  printf '%s' $(( sum / ${#arr[@]} ))
}

calc_stdev() {
  local -a arr=("$@")
  local count=${#arr[@]}
  (( count > 1 )) || { printf '0'; return 0; }
  local mean sum_sq=0 diff
  mean=$(calc_mean "$@")
  for n in "${arr[@]}"; do
    diff=$(( n - mean ))
    (( sum_sq += diff * diff ))
  done
  # population stdev approximation (integer)
  printf '%s' $(( sqrt(sum_sq / count) ))
}

percentile() {
  local pct="$1"; shift
  local -a arr=("$@")
  IFS=$'\n' arr=($(printf '%s\n' "${arr[@]}" | sort -n)) || true
  local N=${#arr[@]}
  (( N )) || { printf '0'; return 0; }
  # nearest-rank method
  local rank=$(( (pct * N + 99) / 100 ))  # ceil(pct/100 * N)
  (( rank < 1 )) && rank=1
  (( rank > N )) && rank=$N
  printf '%s' "${arr[$rank]}"
}

sqrt() {
  # Integer square root via awk (fallback)
  awk -v n="$1" 'BEGIN{ if (n<0){print 0; exit}; printf("%d", sqrt(n)+0) }'
}

########################################
# Compute Stats
########################################
mean=$(calc_mean "${filtered_samples[@]}")
stdev=$(calc_stdev "${filtered_samples[@]}")
min=$(printf '%s\n' "${filtered_samples[@]}" | sort -n | head -1)
max=$(printf '%s\n' "${filtered_samples[@]}" | sort -n | tail -1)
p50=$(percentile 50 "${filtered_samples[@]}")
p90=$(percentile 90 "${filtered_samples[@]}")
p95=$(percentile 95 "${filtered_samples[@]}")
p99=$(percentile 99 "${filtered_samples[@]}")

guidelines="${GUIDELINES_CHECKSUM:-unset}"
timestamp=$(iso8601)

########################################
# Emit JSON
########################################
{
  printf '{\n'
  printf '  "segment": "%s",\n' "$SEGMENT_NAME"

  printf '  "samples_ms": ['
  for i in {1..${#raw_samples[@]}}; do :; done
  for i in "${!raw_samples[@]}"; do
    printf '%s' "${raw_samples[$i]}"
    (( i < ${#raw_samples[@]}-1 )) && printf ', '
  done
  printf '],\n'

  printf '  "filtered_samples_ms": '
  if (( PREPLUGIN_IQR_FILTER )); then
    printf '['
    for i in "${!filtered_samples[@]}"; do
      printf '%s' "${filtered_samples[$i]}"
      (( i < ${#filtered_samples[@]}-1 )) && printf ', '
    done
    printf '],\n'
  else
    printf 'null,\n'
  fi

  printf '  "sample_count": %d,\n' "${#raw_samples[@]}"
  printf '  "filtered_sample_count": %d,\n' "${#filtered_samples[@]}"
  printf '  "mean_ms": %d,\n' "$mean"
  printf '  "stdev_ms": %d,\n' "$stdev"
  printf '  "min_ms": %d,\n' "$min"
  printf '  "max_ms": %d,\n' "$max"
  printf '  "p50_ms": %d,\n' "$p50"
  printf '  "p90_ms": %d,\n' "$p90"
  printf '  "p95_ms": %d,\n' "$p95"
  printf '  "p99_ms": %d,\n' "$p99"
  printf '  "iqr_low_cutoff_ms": %s,\n' "$iqr_low"
  printf '  "iqr_high_cutoff_ms": %s,\n' "$iqr_high"
  printf '  "guidelines_checksum": "%s",\n' "$guidelines"
  printf '  "captured_at": "%s",\n' "$timestamp"
  printf '  "runs_requested": %d,\n' "$PREPLUGIN_RUNS"
  printf '  "tool_version": "1.0",\n'
  printf '  "host_uname": "%s",\n' "$(uname -s 2>/dev/null || echo unknown)"
  printf '  "tag": "%s",\n' "$PREPLUGIN_TAG"
  printf '  "notes": "Stage 2 baseline (multi-sample N=%d%s)"\n' "${#filtered_samples[@]}" "$(( PREPLUGIN_IQR_FILTER )) && echo ', IQR filtered' || echo ''"
  printf '}\n'
} >"$OUT_PATH".tmp

mv "$OUT_PATH".tmp "$OUT_PATH"
log "Baseline written: $OUT_PATH"
printf '%s\n' "$OUT_PATH"
exit 0
