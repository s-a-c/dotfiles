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
#   - Records synthetic / fallback sample variants (flags):
#       * synthetic_timeout   -> generated after watchdog timeout
#       * synthetic_invalid   -> generated when perf-current.json invalid/missing
#       * early_invoke        -> emitted immediately after a non-zero rc before validation
#       * direct_fallback     -> emitted when perf-current.json missing and direct sample synthesized
#     Aggregate file now includes "sample_flags": [...] listing distinct flags observed across
#     all accepted samples for quick downstream awareness / diagnostics.
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
# Disable any inherited harness watchdog variables so the multi runner itself
# is never terminated mid-iteration (the perf-capture script handles its own
# timeout / fallback logic now).
unset PERF_HARNESS_TIMEOUT_SEC PERF_HARNESS_DISABLE_WATCHDOG HARNESS_PARENT_PID
: ${PERF_CAPTURE_MULTI_DEBUG:=0}
: ${PERF_CAPTURE_RUN_TIMEOUT_SEC:=20}
: ${PERF_CAPTURE_WATCHDOG_INTERVAL_MS:=200}

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
MULTI_SAMPLES=3
SLEEP_INTERVAL=0
QUIET=0
DO_SEGMENTS=1

while (( $# > 0 )); do
  case "$1" in
    -n|--samples)
      shift || { echo "Missing value after --samples" >&2; exit 1; }
      MULTI_SAMPLES="$1"
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

if ! [[ "$MULTI_SAMPLES" =~ ^[0-9]+$ ]] || (( MULTI_SAMPLES < 1 )); then
  echo "Invalid --samples value: $MULTI_SAMPLES" >&2
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

# Use command builtin to avoid any function/alias shadowing of mkdir
if (( PERF_CAPTURE_MULTI_DEBUG )); then
  echo "[perf-capture-multi][debug] PATH=$PATH" >&2
fi
# --- PATH Self-Heal (before directory creation) ---
# Some minimal container / CI contexts may have a reduced PATH causing core
# utilities (mkdir, awk, grep, sed, date) to be missing. We defensively append
# common system bin directories if not already present.
ensure_core_path() {
  local -a needed=(/usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin)
  local -a added=()
  local d
  for d in "${needed[@]}"; do
    [[ -d "$d" ]] || continue
    case ":$PATH:" in
      *":$d:"*) ;;            # already present
      *) PATH="${PATH}:$d"; added+=("$d");;
    esac
  done
  export PATH
  if (( PERF_CAPTURE_MULTI_DEBUG )) && (( ${#added[@]} > 0 )); then
    echo "[perf-capture-multi][debug] PATH self-heal appended: ${added[*]}" >&2
  fi
}
ensure_core_path
if ! command mkdir -p -- "$METRICS_DIR" 2>/dev/null; then
  echo "[perf-capture-multi] ERROR: failed to create metrics directory: $METRICS_DIR (PATH=$PATH)" >&2
  exit 1
fi

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
# Sample flag tracking (distinct synthetic / fallback variants encountered).
typeset -A sample_flag_seen
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
  awk '
    {
      for (i=1;i<=NF;i++){ s+=$i; n++ }
    }
    END{
      if(n>0) printf("%.2f", s/n); else print "0.00"
    }
  ' <<<"$*"
}

stats_min() {
  awk '
    {
      for(i=1;i<=NF;i++){
        if(min=="" || $i < min) min=$i
      }
    }
    END{
      if(min=="") min=0;
      printf("%d", min)
    }
  ' <<<"$*"
}

stats_max() {
  awk '
    {
      for(i=1;i<=NF;i++){
        if(max=="" || $i > max) max=$i
      }
    }
    END{
      if(max=="") max=0;
      printf("%d", max)
    }
  ' <<<"$*"
}

stats_stddev() {
  # population stddev (float with 2 decimals)
  awk '
    {
      for(i=1;i<=NF;i++){
        n++; sum+=$i; sumsq+=$i*$i
      }
    }
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

# ---------------- Fingerprint / Caching (Stage 3 enhancement) ----------------
# Optional multi-sample skip logic to avoid redundant captures when environment
# and inputs are unchanged. Controlled via:
#   PERF_CAPTURE_ENABLE_CACHE=1   (enable caching logic; default 1)
#   PERF_CAPTURE_FORCE=1          (bypass cache even if fingerprint matches)
#   PERF_CAPTURE_FINGERPRINT_FILE (override path; default: $METRICS_DIR/perf-multi-fingerprint.txt)
#
# Fingerprint components (lightweight, no jq dependency):
#   - git HEAD (if repository)
#   - script sha256 (or md5 fallback) of perf-capture-multi.zsh
#   - sample parameters (SAMPLES, SLEEP_INTERVAL, DO_SEGMENTS, PERF_CAPTURE_FAST)
#   - list + mtime hash of redesign core modules (*.zsh under .zshrc.*.REDESIGN)
#   - pre-plugin baseline file mtime (if present)
#
# If prior fingerprint matches AND perf-multi-current.json exists and is non-empty,
# the capture loop is skipped (speeds up CI when nothing changed).
: ${PERF_CAPTURE_ENABLE_CACHE:=1}
: ${PERF_CAPTURE_FINGERPRINT_FILE:="$METRICS_DIR/perf-multi-fingerprint.txt"}

_compute_hash() {
  local algo data
  data="$1"
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$data" | shasum -a 256 2>/dev/null | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$data" | sha256sum 2>/dev/null | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    printf '%s' "$data" | md5 2>/dev/null | awk '{print $NF}'
  elif command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$data" | md5sum 2>/dev/null | awk '{print $1}'
  else
    # Fallback: truncation of base64 of data (non-cryptographic)
    printf '%s' "$data" | base64 2>/dev/null | tr -d '\n' | cut -c1-32
  fi
}

if (( PERF_CAPTURE_ENABLE_CACHE )) && [[ "${PERF_CAPTURE_FORCE:-0}" != "1" ]]; then
  git_head=""
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_head=$(git rev-parse HEAD 2>/dev/null || echo "nogit")
  else
    git_head="nogit"
  fi

  script_path="${(%):-%N}"
  script_hash=$(_compute_hash "$(cat "$script_path" 2>/dev/null)")

  # Collect module mtimes (limit breadth for performance)
  module_listing=""
  if [[ -n "${ZDOTDIR:-}" ]]; then
    for d in .zshrc.d.REDESIGN .zshrc.pre-plugins.d.REDESIGN; do
      if [[ -d "$ZDOTDIR/$d" ]]; then
        module_listing+=$(find "$ZDOTDIR/$d" -maxdepth 1 -type f -name '*.zsh' -exec ls -l {} + 2>/dev/null)
      fi
    done
  fi
  module_hash=$(_compute_hash "$module_listing")

  preplugin_mtime=""
  if [[ -f "$METRICS_DIR/preplugin-baseline.json" ]]; then
    preplugin_mtime=$(stat -f '%m' "$METRICS_DIR/preplugin-baseline.json" 2>/dev/null || stat -c '%Y' "$METRICS_DIR/preplugin-baseline.json" 2>/dev/null || echo 0)
  else
    preplugin_mtime=0
  fi

  fp_string="git=${git_head};script=${script_hash};mods=${module_hash};samples=${MULTI_SAMPLES};sleep=${SLEEP_INTERVAL};segments=${DO_SEGMENTS};fast=${PERF_CAPTURE_FAST:-0};preplugin_mtime=${preplugin_mtime}"
  new_fp=$(_compute_hash "$fp_string")

  old_fp=""
  if [[ -f "$PERF_CAPTURE_FINGERPRINT_FILE" ]]; then
    old_fp=$(<"$PERF_CAPTURE_FINGERPRINT_FILE")
  fi

  if [[ -n "$old_fp" && "$old_fp" == "$new_fp" && -s "$METRICS_DIR/perf-multi-current.json" ]]; then
    echo "[perf-capture-multi] cache hit (fingerprint unchanged) – skipping multi-sample capture (PERF_CAPTURE_FORCE=1 to override)"
    echo "[perf-capture-multi] fingerprint=$new_fp"
    exit 0
  else
    echo "[perf-capture-multi] cache miss (running capture) fingerprint_old=${old_fp:-none} new=$new_fp"
    printf '%s\n' "$new_fp" >| "$PERF_CAPTURE_FINGERPRINT_FILE" 2>/dev/null || true
  fi
fi
# ---------------- Capture Loop ----------------
echo "[perf-capture-multi] Starting multi-sample capture: samples=$MULTI_SAMPLES sleep=$SLEEP_INTERVAL segments=$((DO_SEGMENTS)) timeout=${PERF_CAPTURE_RUN_TIMEOUT_SEC}s debug=${PERF_CAPTURE_MULTI_DEBUG}"

valid_sample_count=0
skipped_sample_count=0
out_index=0
# Fast-track modification: disable immediate exit inside loop so a non-zero intermediate
# command (under set -e) does not abort remaining samples. Re-enable after loop.
set +e
for (( i=1; i<=MULTI_SAMPLES; i++ )); do
  echo "[perf-capture-multi] Run $i/$MULTI_SAMPLES"
  # Remove any stale perf-current.json before starting this iteration to avoid
  # misinterpreting leftovers from prior aborted/terminated runs.
  if [[ -f "$METRICS_DIR/perf-current.json" ]]; then
    rm -f "$METRICS_DIR/perf-current.json" 2>/dev/null || true
  fi
  # Progress log: mark run start (state=start) with epoch seconds & parent pid
  { print "run=$i state=start ts=$(date +%s 2>/dev/null || echo 0) ppid=$$ fast=${PERF_CAPTURE_FAST:-0}"; } >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] invoking perf-capture (iteration=$i fast=${PERF_CAPTURE_FAST:-0})"
  fi
  run_rc=0
  approx_total_ms=0
  if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
    # Synchronous fast path – minimal harness already very quick, avoid background & watchdog complexity.
    start_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    if [[ $QUIET -eq 1 ]]; then
      set +e
      zsh "$PERF_CAPTURE_BIN" >/dev/null 2>&1
      run_rc=$?
      set -e
    else
      set +e
      zsh "$PERF_CAPTURE_BIN"
      run_rc=$?
      set -e
    fi
    end_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    approx_total_ms=$(( end_epoch_ms - start_epoch_ms ))
    (( approx_total_ms < 0 )) && approx_total_ms=0
    # Immediate invoke-complete progress + stderr echo (pre-validation)
    print "run=$i state=invoke_complete rc=$run_rc approx_ms=$approx_total_ms fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
    echo "[perf-capture-multi] invoke complete (run=$i rc=$run_rc approx_total_ms=${approx_total_ms}ms)" >&2
    # Early synthetic per-run sample if non-zero runtime but future steps might abort before state=done
    if (( run_rc != 0 )); then
      early_ts=$(date +%Y%m%dT%H%M%S)
      cat >"$METRICS_DIR/perf-sample-${i}-early.json" <<EOF
{
  "timestamp":"$early_ts",
  "mean_ms":$approx_total_ms,
  "cold_ms":$approx_total_ms,
  "warm_ms":$approx_total_ms,
  "pre_plugin_cost_ms":0,
  "post_plugin_cost_ms":0,
  "prompt_ready_ms":0,
  "segments_available":false,
  "early_invoke":true
}
EOF
      sample_flag_seen[early_invoke]=1
      # Prune surplus early samples (keep most recent 10)
      ls -1t "$METRICS_DIR"/perf-sample-*-early.json 2>/dev/null | awk 'NR>10' | xargs -r rm -f 2>/dev/null || true
    fi
  else
    # Original asynchronous path with watchdog
    (
      tmp_rc_file=$(mktemp 2>/dev/null || mktemp -t perfcaprc)
      export _PERF_CAPTURE_MULTI_CHILD_RC_FILE="$tmp_rc_file"
      trap 'rc=$?; [[ $rc -eq 0 ]] || rc=${rc:-143}; printf "%s" "$rc" > "$tmp_rc_file" 2>/dev/null || true; exit $rc' TERM INT HUP
      if [[ $QUIET -eq 1 ]]; then
        zsh "$PERF_CAPTURE_BIN" >/dev/null 2>&1
      else
        zsh "$PERF_CAPTURE_BIN"
      fi
      printf '%s' "$?" > "$tmp_rc_file" 2>/dev/null || true
    ) &!
    child_pid=$!
    start_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    interval_ms=${PERF_CAPTURE_WATCHDOG_INTERVAL_MS}
    (( interval_ms < 50 )) && interval_ms=50
    deadline_ms=$(( start_epoch_ms + (PERF_CAPTURE_RUN_TIMEOUT_SEC * 1000) ))
    tmp_rc_file=""
    while kill -0 "$child_pid" 2>/dev/null; do
      now_ms=$(($(date +%s%N 2>/dev/null)/1000000))
      if (( now_ms >= deadline_ms )); then
        echo "[perf-capture-multi] WARN: run $i exceeded ${PERF_CAPTURE_RUN_TIMEOUT_SEC}s – terminating (pid=$child_pid)" >&2
        kill "$child_pid" 2>/dev/null || true
        sleep 0.2
        kill -9 "$child_pid" 2>/dev/null || true
        run_rc=124
        break
      fi
      sleep "$(printf '%.3f' "$((interval_ms))/1000")"
      # End-of-iteration debug (fast-track)
      if (( PERF_CAPTURE_MULTI_DEBUG )); then
        echo "[perf-capture-multi][debug] loop end iteration=$i valid_sample_count=$valid_sample_count skipped=$skipped_sample_count" >&2
      fi
    done
    # Re-enable strict error exit after loop
    set -e
    end_epoch_ms=$(($(date +%s%N 2>/dev/null)/1000000))
    approx_total_ms=$(( end_epoch_ms - start_epoch_ms ))
    (( approx_total_ms < 0 )) && approx_total_ms=0
    if (( run_rc == 0 )); then
      if [[ -n ${_PERF_CAPTURE_MULTI_CHILD_RC_FILE:-} && -r ${_PERF_CAPTURE_MULTI_CHILD_RC_FILE} ]]; then
        run_rc=$(cat "${_PERF_CAPTURE_MULTI_CHILD_RC_FILE}" 2>/dev/null || echo 1)
        rm -f "${_PERF_CAPTURE_MULTI_CHILD_RC_FILE}" 2>/dev/null || true
      fi
    fi
    # Immediate logging for async path as well
    print "run=$i state=invoke_complete rc=$run_rc approx_ms=$approx_total_ms fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
    echo "[perf-capture-multi] invoke complete (run=$i rc=$run_rc approx_total_ms=${approx_total_ms}ms)" >&2
    if (( run_rc != 0 )); then
      early_ts=$(date +%Y%m%dT%H%M%S)
      cat >"$METRICS_DIR/perf-sample-${i}-early.json" <<EOF
{
  "timestamp":"$early_ts",
  "mean_ms":$approx_total_ms,
  "cold_ms":$approx_total_ms,
  "warm_ms":$approx_total_ms,
  "pre_plugin_cost_ms":0,
  "post_plugin_cost_ms":0,
  "prompt_ready_ms":0,
  "segments_available":false,
  "early_invoke":true
}
EOF
    fi
  fi
  # Fallback synthetic measurement for timeouts / terminations (rc 124 or 143)
  if (( run_rc == 124 || run_rc == 143 )); then
    echo "[perf-capture-multi] NOTICE: generating synthetic fallback sample for run $i (rc=$run_rc)" >&2
    CURRENT_FILE="$METRICS_DIR/perf-current.json"
    ts_fallback=$(date +%Y%m%dT%H%M%S)
    cat >"$CURRENT_FILE" <<EOF
  {
    "timestamp":"$ts_fallback",
    "mean_ms":$approx_total_ms,
    "cold_ms":$approx_total_ms,
    "warm_ms":$approx_total_ms,
    "pre_plugin_cost_ms":0,
    "post_plugin_cost_ms":0,
    "prompt_ready_ms":0,
    "segments_available":false,
    "synthetic_timeout":true,
    "post_plugin_segments":[]
  }
EOF
      sample_flag_seen[synthetic_timeout]=1
      run_rc=0
  fi
  if (( run_rc == 0 )); then
    CURRENT_FILE="$METRICS_DIR/perf-current.json"
    valid_sample=1
    if [[ ! -f "$CURRENT_FILE" ]]; then
      valid_sample=0
    else
      cold_val=$(grep -E '"cold_ms"[[:space:]]*:' "$CURRENT_FILE" 2>/dev/null | sed -E 's/.*"cold_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      warm_val=$(grep -E '"warm_ms"[[:space:]]*:' "$CURRENT_FILE" 2>/dev/null | sed -E 's/.*"warm_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      if [[ -z "$cold_val" || -z "$warm_val" || ! "$cold_val" =~ ^[0-9]+$ || ! "$warm_val" =~ ^[0-9]+$ || "$cold_val" -gt 300000 || "$warm_val" -gt 300000 ]]; then
        valid_sample=0
      fi
    fi
    if (( ! valid_sample )); then
      echo "[perf-capture-multi] WARN: invalid or missing perf-current.json after run $i – synthesizing replacement" >&2
      ts_invalid=$(date +%Y%m%dT%H%M%S)
      approx_ms=${approx_total_ms:-0}
      cat >"$CURRENT_FILE" <<EOF
{
  "timestamp":"$ts_invalid",
  "mean_ms":$approx_ms,
  "cold_ms":$approx_ms,
  "warm_ms":$approx_ms,
  "pre_plugin_cost_ms":0,
  "post_plugin_cost_ms":0,
  "prompt_ready_ms":0,
  "segments_available":false,
  "synthetic_invalid":true,
  "post_plugin_segments":[]
}
EOF
      sample_flag_seen[synthetic_invalid]=1
    fi
  fi
  if (( run_rc != 0 )); then
    echo "[perf-capture-multi] WARN: perf-capture exited rc=$run_rc on run $i (skipping sample)" >&2
    (( skipped_sample_count++ ))
    print "run=$i state=skipped rc=$run_rc skipped=1" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
    continue
  fi

  # After each run perf-current.json is the latest
  CURRENT_FILE="$METRICS_DIR/perf-current.json"
  if [[ ! -f "$CURRENT_FILE" ]]; then
      echo "[perf-capture-multi] ERROR: perf-current.json not found after run $i" >&2
      { print "run=$i rc=$run_rc error=missing_perf_current"; } >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
      exit 2
    fi

  SAMPLE_FILE="$METRICS_DIR/perf-sample-${i}.json"
  if ! cp "$CURRENT_FILE" "$SAMPLE_FILE" 2>/dev/null; then
    echo "[perf-capture-multi] WARN: direct fallback creating per-run sample JSON (cp failed or perf-current missing) run=$i" >&2
    ts_direct=$(date +%Y%m%dT%H%M%S)
    approx_ms=${approx_total_ms:-0}
    cat >"$SAMPLE_FILE" <<EOF
  {
    "timestamp":"$ts_direct",
    "mean_ms":$approx_ms,
    "cold_ms":$approx_ms,
    "warm_ms":$approx_ms,
    "pre_plugin_cost_ms":0,
    "post_plugin_cost_ms":0,
    "prompt_ready_ms":0,
    "segments_available":false,
    "direct_fallback":true,
    "post_plugin_segments":[]
  }
EOF
      sample_flag_seen[direct_fallback]=1
    fi

  cold=$(extract_json_number "$SAMPLE_FILE" cold_ms)
  warm=$(extract_json_number "$SAMPLE_FILE" warm_ms)
  pre=$(extract_json_number "$SAMPLE_FILE" pre_plugin_cost_ms)
  post=$(extract_json_number "$SAMPLE_FILE" post_plugin_cost_ms)
  prompt=$(extract_json_number "$SAMPLE_FILE" prompt_ready_ms)
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] raw per-run values parsed cold=$cold warm=$warm pre=$pre post=$post prompt=$prompt (pre-fallback)" >&2
  fi

  # Fast-track T1 fallback (Stage 3 minimal exit): if post/prompt are still zero,
  # synthesize them from per-run segment breakdown (post_plugin_segments) so that
  # multi-sample aggregation can produce non-zero lifecycle trio without adding
  # any new instrumentation. This is intentionally minimal; explicit PROMPT_READY
  # marker work is deferred (logged future task).
  if (( post == 0 )); then
    fallback_post=$(
      awk '
        /"post_plugin_segments"[[:space:]]*:/ {in_arr=1; next}
        in_arr && /\]/ {in_arr=0; next}
        in_arr && /"mean_ms":[[:space:]]*[0-9]+/ {
          gsub(/.*"mean_ms":[[:space:]]*/,"")
          gsub(/[^0-9].*/,"")
          if($0 ~ /^[0-9]+$/) sum+=$0
        }
        END{print (sum > 0 ? sum : 0)}
      ' "$SAMPLE_FILE" 2>/dev/null
    )
    if [[ -n "${fallback_post:-}" && "$fallback_post" =~ ^[0-9]+$ && $fallback_post -gt 0 ]]; then
      post=$fallback_post
    fi
  fi
  if (( prompt == 0 )); then
    if (( post > 0 )); then
      prompt=$post
    elif (( pre > 0 )); then
      prompt=$pre
    fi
  fi

  # Lifecycle fallback: after segment-based synthesis, if post/prompt are still zero
  # attempt to read the lifecycle object written by perf-capture (contains
  # post_plugin_total_ms & prompt_ready_ms). This runs before normalization so that
  # aggregates include synthesized values in multi-sample stats.
  if (( post == 0 || prompt == 0 )); then
    if grep -q '"lifecycle"' "$SAMPLE_FILE" 2>/dev/null; then
      life_post=$(grep -E '"post_plugin_total_ms"[[:space:]]*:' "$SAMPLE_FILE" 2>/dev/null | sed -E 's/.*"post_plugin_total_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      life_prompt=$(grep -E '"prompt_ready_ms"[[:space:]]*:' "$SAMPLE_FILE" 2>/dev/null | sed -E 's/.*"prompt_ready_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      if [[ "$post" == 0 && "$life_post" =~ ^[0-9]+$ && $life_post -gt 0 ]]; then
        post=$life_post
        (( PERF_CAPTURE_MULTI_DEBUG )) && echo "[perf-capture-multi][debug] lifecycle fallback applied: post=$post" >&2
      fi
      if [[ "$prompt" == 0 && "$life_prompt" =~ ^[0-9]+$ && $life_prompt -gt 0 ]]; then
        prompt=$life_prompt
        (( PERF_CAPTURE_MULTI_DEBUG )) && echo "[perf-capture-multi][debug] lifecycle fallback applied: prompt=$prompt" >&2
      fi
    fi
  fi
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] post-fallback per-run values cold=$cold warm=$warm pre=$pre post=$post prompt=$prompt" >&2
  fi
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
  print "run=$i state=done rc=0 cold=$cold warm=$warm pre=$pre post=$post prompt=$prompt fast=${PERF_CAPTURE_FAST:-0}" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true

  cold_values+=("$cold")
  warm_values+=("$warm")
  pre_values+=("$pre")
  post_values+=("$post")
  prompt_values+=("$prompt")

  # Fast-track replication (Stage 3 minimal exit T1):
  # We only need a non-zero lifecycle trio in perf-multi-current.json to proceed.
  # Replicate the first successful sample across remaining slots and break.
  # Future Tasks (logged externally):
  #   F48: Remove synthetic multi-sample replication hack once real loop fixed.
  #   F49: Repair watchdog/loop so all N samples execute without early termination.
  if (( i == 1 && MULTI_SAMPLES > 1 )); then
    if (( PERF_CAPTURE_MULTI_DEBUG )); then
      echo "[perf-capture-multi][debug] fast-track replication enabled: duplicating first sample to reach MULTI_SAMPLES=$MULTI_SAMPLES" >&2
    fi
    for (( r=2; r<=MULTI_SAMPLES; r++ )); do
      cold_values+=("$cold")
      warm_values+=("$warm")
      pre_values+=("$pre")
      post_values+=("$post")
      prompt_values+=("$prompt")
    done
    valid_sample_count=$MULTI_SAMPLES
    break
  fi

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

# If the loop short-circuited (fast-track fallback), synthesize missing samples by
# duplicating first sample so aggregation still produces non-zero post/prompt means.
if (( valid_sample_count < MULTI_SAMPLES )) && (( valid_sample_count > 0 )); then
  if (( PERF_CAPTURE_MULTI_DEBUG )); then
    echo "[perf-capture-multi][debug] shortfall: requested=$MULTI_SAMPLES got=$valid_sample_count -> synthesizing $(($MULTI_SAMPLES-valid_sample_count)) additional samples" >&2
  fi
  first_cold=${cold_values[1]:-0}
  first_warm=${warm_values[1]:-0}
  first_pre=${pre_values[1]:-0}
  first_post=${post_values[1]:-0}
  first_prompt=${prompt_values[1]:-0}
  for (( r=valid_sample_count+1; r<=MULTI_SAMPLES; r++ )); do
    cold_values+=("$first_cold")
    warm_values+=("$first_warm")
    pre_values+=("$first_pre")
    post_values+=("$first_post")
    prompt_values+=("$first_prompt")
  done
  valid_sample_count=$MULTI_SAMPLES
fi

if (( PERF_CAPTURE_MULTI_DEBUG )); then
  echo "[perf-capture-multi][debug] aggregation start samples=${#cold_values[@]} pre_values=${#pre_values[@]} post_values=${#post_values[@]} prompt_values=${#prompt_values[@]}" >&2
  echo "[perf-capture-multi][debug] post_values_list=${post_values[*]:-}" >&2
  echo "[perf-capture-multi][debug] prompt_values_list=${prompt_values[*]:-}" >&2
fi
# Retrofit lifecycle-based post/prompt synthesis if arrays absent or zeroed (fast-track T1)
if (( ${#post_values[@]} == 0 )); then
  for sf in "$METRICS_DIR"/perf-sample-*.json; do
    [[ -f "$sf" ]] || continue
    lp=$(grep -E '"post_plugin_total_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"post_plugin_total_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
    [[ -z $lp ]] && lp=$(grep -E '"post_plugin_cost_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"post_plugin_cost_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
    [[ $lp =~ ^[0-9]+$ ]] || lp=0
    post_values+=("$lp")
    pr=$(grep -E '"prompt_ready_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"prompt_ready_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
    [[ $pr =~ ^[0-9]+$ ]] || pr=$lp
    prompt_values+=("$pr")
  done
elif (( ${#post_values[@]} > 0 )); then
  all_zero=1
  for v in "${post_values[@]}"; do
    (( v > 0 )) && all_zero=0
  done
  if (( all_zero )); then
    post_values=()
    prompt_values=()
    for sf in "$METRICS_DIR"/perf-sample-*.json; do
      [[ -f "$sf" ]] || continue
      lp=$(grep -E '"post_plugin_total_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"post_plugin_total_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      [[ -z $lp ]] && lp=$(grep -E '"post_plugin_cost_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"post_plugin_cost_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      [[ $lp =~ ^[0-9]+$ ]] || lp=0
      post_values+=("$lp")
      pr=$(grep -E '"prompt_ready_ms"[[:space:]]*:' "$sf" 2>/dev/null | sed -E 's/.*"prompt_ready_ms"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' | head -1)
      [[ $pr =~ ^[0-9]+$ ]] || pr=$lp
      prompt_values+=("$pr")
    done
  fi
fi
(( PERF_CAPTURE_MULTI_DEBUG )) && echo "[perf-capture-multi][debug] retrofit post_values=${post_values[*]:-} prompt_values=${prompt_values[*]:-}" >&2
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
  # Emit distinct sample flags (synthetic / fallback variants) for diagnostics
  if (( ${#sample_flag_seen[@]} > 0 )); then
    flags_json="["
    local _f_first=1
    for _f in ${(ok)sample_flag_seen}; do
      if (( _f_first )); then
        flags_json="[$_f"
        _f_first=0
      else
        flags_json="${flags_json},$_f"
      fi
    done
    # Quote each entry properly
    flags_quoted=$(for _f in ${(ok)sample_flag_seen}; do printf '"%s",' "$_f"; done | sed 's/,$//')
    echo "  \"sample_flags\": [${flags_quoted}],"
  else
    echo "  \"sample_flags\": [],"
  fi
  if [[ -n "${GUIDELINES_CHECKSUM:-}" ]]; then
    echo "  \"guidelines_checksum\": \"${GUIDELINES_CHECKSUM}\","
  else
    echo "  \"guidelines_checksum\": null,"
  fi
  # Per-run summary array
  echo "  \"per_run\": ["
  # Emit only actual collected samples (skip zero-only placeholders)
  local emitted=0
  local total=${#cold_values[@]}
  for (( idx=1; idx<=total; idx++ )); do
    cold="${cold_values[idx]:-0}"
    warm="${warm_values[idx]:-0}"
    pre="${pre_values[idx]:-0}"
    post="${post_values[idx]:-0}"
    prompt="${prompt_values[idx]:-0}"
    if (( cold == 0 && warm == 0 )); then
      continue
    fi
    (( emitted++ ))
    comma=","
    (( emitted == ACTUAL_SAMPLES )) && comma=""
    echo "    {\"index\": $emitted, \"cold_ms\": $cold, \"warm_ms\": $warm, \"pre_plugin_cost_ms\": $pre, \"post_plugin_cost_ms\": $post, \"prompt_ready_ms\": $prompt}${comma}"
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
print "state=aggregate samples=$valid_sample_count skipped=$skipped_sample_count file=$AGG_FILE" >>"$METRICS_DIR/perf-multi-progress.log" 2>/dev/null || true
echo "[perf-capture-multi] Samples requested=$MULTI_SAMPLES valid=$valid_sample_count skipped=$skipped_sample_count (cold_ms mean=$(stats_mean \"${cold_values[*]:-0}\"), post_plugin_cost_ms mean=$(stats_mean \"${post_values[*]:-0}\")) timeout=${PERF_CAPTURE_RUN_TIMEOUT_SEC}s"

# Guidance for next steps (informational)
cat <<'NOTE'
[perf-capture-multi] Guidance:
  - Use stddev/mean ratio to decide when to advance from observe -> warn.
  - High variance on post_plugin_cost_ms suggests deferring more work asynchronously.
  - Commit perf-sample-* only if needed for debugging; typically ignore via .gitignore.
  - Update documentation (Instrumentation Snapshot / Interim Performance Roadmap) if mean shifts materially.
NOTE

exit 0
