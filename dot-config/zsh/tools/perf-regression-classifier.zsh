#!/usr/bin/env zsh
# perf-regression-classifier.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Enhanced performance regression classifier with multi-metric support.
#   Captures multiple redesign shell startups, extracts key timing segments
#   (prompt_ready, pre_plugin_total, post_plugin_total, deferred_total),
#   compares aggregated statistics against stored baselines, and emits
#   classification lines according to configurable percentage thresholds.
#
# FEATURES (v2 Enhanced):
#   - Multi-metric extraction and classification
#   - Per-metric and overall status reporting
#   - Unified JSON output with metric breakdown
#   - Backward compatible single-metric mode
#   - Multiple baseline files support
#   - Enhanced structured telemetry correlation
#   - GOAL scaffold (Streak/Governance/Explore/CI) — current phase: goal parsing + JSON field only
#
# MODES:
#   observe (default): never non‑zero exit on WARN/FAIL (report only)
#   enforce          : exit code signals worst metric status
#
# OUTPUT:
#   Human: Per-metric CLASSIFIER lines + overall summary
#   JSON: Comprehensive multi-metric summary (now includes "goal")
#
# EXIT CODES:
#   0 OK (or WARN/FAIL in observe mode)
#   2 WARN (enforce mode only)
#   3 FAIL (enforce mode only)
#   1 Generic error / invalid usage
#
# USAGE:
#   ./perf-regression-classifier.zsh
#   ./perf-regression-classifier.zsh --metrics prompt_ready,pre_plugin_total
#   ./perf-regression-classifier.zsh --enforce --warn-threshold 8 --fail-threshold 20
#   ./perf-regression-classifier.zsh --goal governance --runs 5
#
# NOTE (GOAL Scaffold Phase 3):
#   goal parsed/emitted + apply_goal_profile exports inert internal flags (ALLOW_SYNTHETIC_SEGMENTS, REQUIRE_ALL_METRICS, HARD_STRICT, STRICT_PHASED, SOFT_MISSING_OK, JSON_PARTIAL_OK, EPHEMERAL_FLAG). No gating/behavioral changes yet.
#
# ------------------------------------------------------------------------------
set -uo pipefail

# Defaults
RUNS=5
WARN_THRESHOLD=10        # percent
FAIL_THRESHOLD=25        # percent
MODE="observe"           # observe|enforce
BASELINE_DIR="artifacts/metrics"
METRICS="prompt_ready"   # Start with single metric for backward compatibility
JSON_OUT=""
QUIET=0
ZSH_BIN="${ZSH_BIN:-zsh}"
GOAL="${GOAL:-Streak}"   # Streak|Governance|Explore|CI (normalized to lowercase later)

# Ensure baseline directory exists (lazy)
mkdir -p -- "${BASELINE_DIR}" 2>/dev/null || true

print_err() { print -r -- "[perf-classifier][err] $*" >&2; }
print_dbg() { [[ -n "${PERF_CLASSIFIER_DEBUG:-}" ]] && print -r -- "[perf-classifier][dbg] $*" >&2 || true; }

usage() {
  cat <<'EOF'
perf-regression-classifier.zsh
  Enhanced multi-metric performance regression classifier.

Options:
  --runs N                (default: 5)
  --warn-threshold PCT    (default: 10)
  --fail-threshold PCT    (default: 25)
  --baseline-dir PATH     (default: artifacts/metrics)
  --baseline PATH         (default: artifacts/metrics/perf-baseline.json) [DEPRECATED - use --baseline-dir]
  --metrics LIST          (default: prompt_ready)
  --metric NAME           (default: prompt_ready_ms) [DEPRECATED - use --metrics]
  --mode observe|enforce  (default: observe)
  --json-out FILE         (optional) write JSON summary
  --goal PROFILE          (optional) streak|governance|explore|ci (default: streak if unset)
  --quiet                 suppress non-essential output
  -h, --help              show this help

Metrics:
  prompt_ready      - Total startup to first prompt
  pre_plugin_total  - Pre-plugin phase duration
  post_plugin_total - Post-plugin phase duration
  deferred_total    - Postprompt async work

Exit Codes:
  0 OK (or classification in observe mode)
  2 WARN (enforce mode) - based on worst metric
  3 FAIL (enforce mode) - based on worst metric
  1 error / usage

EOF
}

# Legacy single-metric compatibility
SINGLE_METRIC_MODE=0
LEGACY_BASELINE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs) shift; RUNS="${1:-}";;
    --runs=*) RUNS="${1#*=}";;
    --warn-threshold) shift; WARN_THRESHOLD="${1:-}";;
    --warn-threshold=*) WARN_THRESHOLD="${1#*=}";;
    --fail-threshold) shift; FAIL_THRESHOLD="${1:-}";;
    --fail-threshold=*) FAIL_THRESHOLD="${1#*=}";;
    --baseline-dir) shift; BASELINE_DIR="${1:-}";;
    --baseline-dir=*) BASELINE_DIR="${1#*=}";;
    --baseline)
      shift
      LEGACY_BASELINE_FILE="${1:-}"
      SINGLE_METRIC_MODE=1
      ;;
    --baseline=*)
      LEGACY_BASELINE_FILE="${1#*=}"
      SINGLE_METRIC_MODE=1
      ;;
    --metrics) shift; METRICS="${1:-}";;
    --metrics=*) METRICS="${1#*=}";;
    --metric)
      shift
      # Convert legacy metric name to new format
      case "${1:-}" in
        prompt_ready_ms) METRICS="prompt_ready";;
        *) METRICS="${1:-}";;
      esac
      SINGLE_METRIC_MODE=1
      ;;
    --metric=*)
      local m="${1#*=}"
      case "$m" in
        prompt_ready_ms) METRICS="prompt_ready";;
        *) METRICS="$m";;
      esac
      SINGLE_METRIC_MODE=1
      ;;
    --mode) shift; MODE="${1:-}";;
    --mode=*) MODE="${1#*=}";;
    --json-out) shift; JSON_OUT="${1:-}";;
    --json-out=*) JSON_OUT="${1#*=}";;
    --quiet) QUIET=1;;
    --goal) shift; GOAL="${1:-}";;
    --goal=*) GOAL="${1#*=}";;
    -h|--help) usage; exit 0;;
    *)
      print_err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

# Validate inputs
is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }
for v in "$RUNS" "$WARN_THRESHOLD" "$FAIL_THRESHOLD"; do
  is_int "$v" || { print_err "Invalid integer value: $v"; exit 1; }
done
(( RUNS > 0 )) || { print_err "--runs must be > 0"; exit 1; }
(( WARN_THRESHOLD < FAIL_THRESHOLD )) || { print_err "WARN threshold must be < FAIL threshold"; exit 1; }
[[ "$MODE" == "observe" || "$MODE" == "enforce" ]] || { print_err "--mode must be observe|enforce"; exit 1; }
# Normalize GOAL (scaffold phase: only JSON surfacing)
GOAL="${GOAL:l}"
case "$GOAL" in
  streak|governance|explore|ci) ;;
  *) print_dbg "Unrecognized GOAL='${GOAL}', defaulting to 'streak'"; GOAL="streak";;
esac

# Apply GOAL profile internal flags (Phase 3 scaffold - inert; no behavioral gating yet)
apply_goal_profile() {
  local g="${GOAL:-streak}"
  g="${g:l}"
  ALLOW_SYNTHETIC_SEGMENTS=0
  REQUIRE_ALL_METRICS=1
  HARD_STRICT=1
  STRICT_PHASED=0
  SOFT_MISSING_OK=0
  JSON_PARTIAL_OK=0
  EPHEMERAL_FLAG=0
  case "$g" in
    streak)
      ALLOW_SYNTHETIC_SEGMENTS=1
      REQUIRE_ALL_METRICS=0
      HARD_STRICT=0
      STRICT_PHASED=1
      SOFT_MISSING_OK=1
      JSON_PARTIAL_OK=1
      ;;
    governance)
      # Defaults already represent strict governance posture
      ;;
    explore)
      ALLOW_SYNTHETIC_SEGMENTS=1
      REQUIRE_ALL_METRICS=0
      HARD_STRICT=0
      SOFT_MISSING_OK=1
      JSON_PARTIAL_OK=1
      EPHEMERAL_FLAG=1
      ;;
    ci)
      # Mirrors governance strictness (future: may diverge slightly)
      ;;
    *)
      g="streak"
      ALLOW_SYNTHETIC_SEGMENTS=1
      REQUIRE_ALL_METRICS=0
      HARD_STRICT=0
      STRICT_PHASED=1
      SOFT_MISSING_OK=1
      JSON_PARTIAL_OK=1
      ;;
  esac
  GOAL="$g"
  export GOAL ALLOW_SYNTHETIC_SEGMENTS REQUIRE_ALL_METRICS HARD_STRICT STRICT_PHASED \
         SOFT_MISSING_OK JSON_PARTIAL_OK EPHEMERAL_FLAG
  [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print -r -- "[perf-classifier][dbg] goal=$GOAL flags: syn=$ALLOW_SYNTHETIC_SEGMENTS req_all=$REQUIRE_ALL_METRICS hard=$HARD_STRICT phased=$STRICT_PHASED soft=$SOFT_MISSING_OK partial_ok=$JSON_PARTIAL_OK eph=$EPHEMERAL_FLAG" >&2
}

if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  zmodload zsh/datetime 2>/dev/null || true
  __agp_t0="${EPOCHREALTIME:-}"
fi
apply_goal_profile
if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  __agp_t1="${EPOCHREALTIME:-}"
  if [[ -n "${__agp_t0:-}" && -n "${__agp_t1:-}" ]]; then
    __agp_us=$(awk -v t0="$__agp_t0" -v t1="$__agp_t1" 'BEGIN{ printf "%d", (t1 - t0) * 1000000 }')
    print_dbg "apply_goal_profile timing_us=${__agp_us}"
  fi
fi

# Parse metrics list
IFS=',' read -rA METRIC_ARRAY <<< "$METRICS"

# ------------------------------------------------------------------------------
# Segment Extraction Functions
# ------------------------------------------------------------------------------

extract_metric_ms() {
  local file="$1" metric="$2"
  local ms

  case "$metric" in
    prompt_ready)
      ms=$(grep -E '^SEGMENT name=prompt_ready ms=[0-9]+' "$file" 2>/dev/null \
          | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
      if [[ -z "$ms" ]]; then
        # Fallback to native marker only if numeric is present
        ms=$(grep -E '^PROMPT_READY_COMPLETE[[:space:]]+[0-9]+' "$file" 2>/dev/null | awk '{print $2}' | head -n1)
      fi
      if [[ -z "$ms" ]]; then
        # Guard: if prompt_ready is present but ms is empty, coerce to 0 to keep pipeline alive
        if grep -qE '^SEGMENT name=prompt_ready ' "$file" 2>/dev/null || grep -qE '^PROMPT_READY_COMPLETE' "$file" 2>/dev/null; then
          ms="0"
        fi
      fi
      ;;
    pre_plugin_total)
      ms=$(grep -E '^SEGMENT name=pre_plugin_total ms=[0-9]+' "$file" 2>/dev/null \
          | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
      if [[ -z "$ms" ]]; then
        ms=$(grep -E '^PRE_PLUGIN_COMPLETE ' "$file" 2>/dev/null | awk '{print $2}' | head -n1)
      fi
      ;;
    post_plugin_total)
      ms=$(grep -E '^SEGMENT name=post_plugin_total ms=[0-9]+' "$file" 2>/dev/null \
          | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
      if [[ -z "$ms" ]]; then
        ms=$(grep -E '^POST_PLUGIN_COMPLETE ' "$file" 2>/dev/null | awk '{print $2}' | head -n1)
      fi
      ;;
    deferred_total)
      ms=$(grep -E '^SEGMENT name=deferred_total ms=[0-9]+' "$file" 2>/dev/null \
          | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
      ;;
    *)
      # Generic pattern for custom metrics
      ms=$(grep -E "^SEGMENT name=${metric} ms=[0-9]+" "$file" 2>/dev/null \
          | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
      ;;
  esac

  [[ -n "$ms" ]] && is_int "$ms" || ms=""
  print -r -- "$ms"
}

# ------------------------------------------------------------------------------
# Capture Runner
# ------------------------------------------------------------------------------

launch_single_capture() {
  local tmpd="$1"
  local logf="$2"
  cat > "${tmpd}/capture-runner.zsh" <<'EOF'
#!/usr/bin/env zsh
setopt no_prompt_subst
ZDOTDIR_ROOT="${PWD}/dot-config/zsh"
PRE_DIR="${ZDOTDIR_ROOT}/.zshrc.pre-plugins.d.REDESIGN"
POST_DIR="${ZDOTDIR_ROOT}/.zshrc.d.REDESIGN"
FEATURE_REGISTRY="${ZDOTDIR_ROOT}/feature/registry/feature-registry.zsh"

# Define missing functions
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  echo "[capture][dbg] starting capture-runner (PID=$$) log=$PERF_SEGMENT_LOG" >&2
fi

# Pre-plugin modules (critical for timing anchors)
source "${PRE_DIR}/00-path-safety.zsh" 2>/dev/null || true
source "${PRE_DIR}/40-pre-plugin-reserved.zsh" 2>/dev/null || true

# Post-plugin modules (add splash + idle + full boundary chain for segment completeness)
source "${POST_DIR}/10-core-functions.zsh" 2>/dev/null || true
source "${POST_DIR}/85-post-plugin-boundary.zsh" 2>/dev/null || true
source "${POST_DIR}/90-splash.zsh" 2>/dev/null || true
source "${POST_DIR}/95-prompt-ready.zsh" 2>/dev/null || true
source "${POST_DIR}/96-deferred-dispatch.zsh" 2>/dev/null || true
source "${POST_DIR}/97-idle-trigger.zsh" 2>/dev/null || true

if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  echo "[capture][dbg] modules sourced; attempting feature registry" >&2
fi

# Feature registry (optional; guards if absent)
if [[ -r "${FEATURE_REGISTRY}" ]]; then
  source "${FEATURE_REGISTRY}" 2>/dev/null || true
  if [[ "${PERF_CLASSIFIER_ENABLE_FEATURES:-1}" == "1" ]]; then
    # Enable telemetry collection (structured JSON only if already requested externally)
    : ${ZSH_FEATURE_TELEMETRY:=1}
    # Reuse PERF_SEGMENT_LOG for JSON sidecar when not explicitly set
    : ${PERF_SEGMENT_JSON_LOG:=${PERF_SEGMENT_LOG}}
    if typeset -f feature_registry_invoke_phase >/dev/null 2>&1; then
      feature_registry_invoke_phase preload 2>/dev/null || true
      feature_registry_invoke_phase init 2>/dev/null || true
    fi
    if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
      echo "[capture][dbg] feature registry invoked (preload+init) features=${#ZSH_FEATURE_REGISTRY_NAMES[@]}" >&2
    fi
  fi
fi

# Capture all phases
typeset -f __pr__capture_prompt_ready >/dev/null 2>&1 && __pr__capture_prompt_ready 2>/dev/null
typeset -f __zsh_deferred_run_once     >/dev/null 2>&1 && __zsh_deferred_run_once
typeset -f zf::idle::run_if_ready       >/dev/null 2>&1 && zf::idle::run_if_ready

if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  echo "[capture][dbg] capture complete; emitting RUN_COMPLETE marker" >&2
fi

# Synthetic fallback segment emission (if expected lines missing)
# Ensures classifier can proceed even if minimal sourcing omitted some segment producers.
if [[ -n ${PERF_SEGMENT_LOG:-} ]]; then
  __synth_used=0
  {
    grep -q '^SEGMENT name=pre_plugin_total ' "$PERF_SEGMENT_LOG" 2>/dev/null || { print "SEGMENT name=pre_plugin_total ms=0 phase=pre_plugin sample=${PERF_SAMPLE_CONTEXT:-mean}"; __synth_used=1; }
    grep -q '^SEGMENT name=post_plugin_total ' "$PERF_SEGMENT_LOG" 2>/dev/null || { print "SEGMENT name=post_plugin_total ms=0 phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-mean}"; __synth_used=1; }
    grep -q '^SEGMENT name=prompt_ready ms=[0-9]\+' "$PERF_SEGMENT_LOG" 2>/dev/null || print "SEGMENT name=prompt_ready ms=${PROMPT_READY_DELTA_MS:-0} phase=prompt sample=${PERF_SAMPLE_CONTEXT:-mean}"
    grep -q '^SEGMENT name=deferred_total ' "$PERF_SEGMENT_LOG" 2>/dev/null || { print "SEGMENT name=deferred_total ms=0 phase=postprompt sample=${PERF_SAMPLE_CONTEXT:-mean}"; __synth_used=1; }
  } >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
  # Guarded synthetic marker emission (Phase 3 preview only – inert by default)
  if [[ "$__synth_used" -eq 1 && -n ${PERF_SYNTHETIC_MARKER_PREVIEW:-} ]]; then
    print "#SYNTHETIC_FALLBACK_INSERTED=1" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
  fi
fi
if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  if [[ -n ${PERF_SEGMENT_LOG:-} ]]; then
    echo "[capture][dbg] synthetic fallback segment check complete (marker_preview=${PERF_SYNTHETIC_MARKER_PREVIEW:-0})" >&2
  else
    echo "[capture][dbg] synthetic fallback segment check complete" >&2
  fi
fi
print "#RUN_COMPLETE"
EOF
  chmod +x "${tmpd}/capture-runner.zsh"
  if [[ -n "${PERF_CLASSIFIER_DEBUG:-}" ]]; then
    PERF_SEGMENT_LOG="$logf" "${ZSH_BIN}" -f "${tmpd}/capture-runner.zsh" 2>&1 || true
  else
    PERF_SEGMENT_LOG="$logf" "${ZSH_BIN}" -f "${tmpd}/capture-runner.zsh" >/dev/null 2>&1 || true
  fi
}

# ------------------------------------------------------------------------------
# Statistics
# ------------------------------------------------------------------------------

calc_stats() {
  local awk_bin="${AWK_BIN:-}"
  if [[ -z "$awk_bin" ]]; then
    if command -v gawk >/dev/null 2>&1; then
      awk_bin="gawk"
    else
      awk_bin="awk"
    fi
  fi
  "$awk_bin" '
    NF {
      v[NR]=$1; sum+=$1; sq+=$1*$1;
    }
    END {
      if(NR==0){ print "0 0 0 0"; exit }
      mean=sum/NR
      asort(v)
      if (NR%2==1) { median=v[(NR+1)/2] } else { median=(v[NR/2]+v[NR/2+1])/2 }
      if (NR>1) {
        var=(sq - (sum*sum/NR))/(NR-1)
        if (var<0) var=0
        std=sqrt(var)
      } else {
        std=0
      }
      rsd = (mean>0)? (std/mean*100) : 0
      printf "%.2f %.2f %.2f %.2f\n", mean, median, std, rsd
    }'
}

percent_delta() {
  local new="$1" base="$2"
  if (( base == 0 )); then
    print "0"
    return 0
  fi
  local awk_bin="${AWK_BIN:-}"
  if [[ -z "$awk_bin" ]]; then
    if command -v gawk >/dev/null 2>&1; then
      awk_bin="gawk"
    else
      awk_bin="awk"
    fi
  fi
  "$awk_bin" -v n="$new" -v b="$base" 'BEGIN{ printf "%.2f", ((n-b)/b)*100 }'
}

# ------------------------------------------------------------------------------
# Main Capture Loop
# ------------------------------------------------------------------------------

TMP_BASE="$(mktemp -d 2>/dev/null || mktemp -d -t perf_classifier)"
LOG_DIR="${TMP_BASE}/runs"
mkdir -p "$LOG_DIR"

# Single metric mode (backward compatibility)
if (( SINGLE_METRIC_MODE )) && [[ ${#METRIC_ARRAY[@]} -eq 1 ]]; then
  metric="${METRIC_ARRAY[1]}"
  VALUES=()
  SYNTHETIC_USED=0

  for ((i=1;i<=RUNS;i++)); do
    run_dir="${LOG_DIR}/run_${i}"
    mkdir -p "$run_dir"
    seg_log="${run_dir}/segments.log"
    launch_single_capture "$run_dir" "$seg_log"
    # Debug-only synthetic marker scan per run (Phase 3 preview)
    if grep -q '^#SYNTHETIC_FALLBACK_INSERTED=1' "$seg_log" 2>/dev/null; then
      SYN_SINGLE_RUN=1
      SYNTHETIC_USED=1
      [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print_dbg "Run $i synthetic marker detected"
    else
      SYN_SINGLE_RUN=0
    fi
    ms_val="$(extract_metric_ms "$seg_log" "$metric")"
    if [[ -z "$ms_val" ]]; then
      print_err "Run $i: Unable to extract ${metric} ms (log: $seg_log)"
      continue
    fi
    VALUES+=("$ms_val")
    (( QUIET )) || print_dbg "Run $i ${metric}_ms=$ms_val"
  done

  if (( ${#VALUES[@]} == 0 )); then
    print_err "No successful captures; aborting."
    # Ensure a minimal JSON artifact is still written for diagnostics
    if [[ -n "$JSON_OUT" ]]; then
      mkdir -p -- "$(dirname "$JSON_OUT")" 2>/dev/null || true
      {
        print '{'
        print "  \"goal\": \"${GOAL}\","
        print "  \"status\": \"ERROR\","
        print "  \"error\": \"no_successful_captures\","
        print "  \"mode\": \"${MODE}\","
        print "  \"generated_at\": \"$(date -Iseconds 2>/dev/null || date)\""
        print '}'
      } > "${JSON_OUT}.tmp" 2>/dev/null || true
      mv "${JSON_OUT}.tmp" "${JSON_OUT}" 2>/dev/null || true
    fi
    if [[ "${MODE:-}" == "observe" ]]; then
      exit 0
    else
      exit 1
    fi
  fi

  # Compute statistics
  stats_line="$(printf "%s\n" "${VALUES[@]}" | calc_stats)"
  mean_ms="${stats_line%% *}"
  rest="${stats_line#* }"
  median_ms="${rest%% *}"
  rest="${rest#* }"
  stddev_ms="${rest%% *}"
  rsd_pct="${rest#* }"

  # Baseline handling
  if [[ -n "$LEGACY_BASELINE_FILE" ]]; then
    BASELINE_FILE="$LEGACY_BASELINE_FILE"
  else
    BASELINE_FILE="${BASELINE_DIR}/perf-baseline.json"
  fi

  baseline_mean=""
  if [[ -f "$BASELINE_FILE" ]]; then
    baseline_mean="$(grep -E '"mean_ms":' "$BASELINE_FILE" 2>/dev/null | sed -n 's/.*"mean_ms":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -n1)"
  fi

  classification="INIT"
  delta_pct="0.00"
  exit_code=0

  if [[ -z "$baseline_mean" ]]; then
    classification="BASELINE_CREATED"
    delta_pct="0.00"
    # Save new baseline
    {
      print '{'
      print "  \"metric\": \"${metric}_ms\","
      print "  \"mean_ms\": ${mean_ms},"
      print "  \"median_ms\": ${median_ms},"
      print "  \"stddev_ms\": ${stddev_ms},"
      print "  \"rsd_pct\": ${rsd_pct},"
      print "  \"runs\": ${#VALUES[@]},"
      print "  \"created_at\": \"$(date -Iseconds 2>/dev/null || date)\","
      print "  \"values\": [${(j:,:)VALUES}]"
      print '}'
    } > "${BASELINE_FILE}.tmp" 2>/dev/null || true
    mv "${BASELINE_FILE}.tmp" "${BASELINE_FILE}" 2>/dev/null || true
    (( QUIET )) || print_dbg "Baseline created at ${BASELINE_FILE}"
  else
    delta_pct="$(percent_delta "$mean_ms" "$baseline_mean")"
    # Determine status
    awk -v d="$delta_pct" -v warn="$WARN_THRESHOLD" -v fail="$FAIL_THRESHOLD" '
      BEGIN{
        status="OK";
        if (d > fail) status="FAIL";
        else if (d > warn) status="WARN";
        print status;
      }' | read -r classification
  fi

  # Human / line output
  sign="+"
  [[ "${delta_pct}" == -* ]] && sign=""

  CLASS_LINE="CLASSIFIER status=${classification} delta=${sign}${delta_pct}% mean_ms=${mean_ms} baseline_mean_ms=${baseline_mean:-${mean_ms}} median_ms=${median_ms} rsd=${rsd_pct}% runs=${#VALUES[@]} metric=${metric}_ms warn_threshold=${WARN_THRESHOLD}% fail_threshold=${FAIL_THRESHOLD}% mode=${MODE}"
  (( QUIET )) || print -r -- "$CLASS_LINE"

  # Optional JSON summary (moved earlier to ensure write-before-exit parity)
  if [[ -n "$JSON_OUT" ]]; then
    mkdir -p -- "$(dirname "$JSON_OUT")" 2>/dev/null || true
    {
      print '{'
      print "  \"metric\": \"${metric}_ms\","
      print "  \"goal\": \"${GOAL}\","
      print "  \"status\": \"${classification}\","
      print "  \"mean_ms\": ${mean_ms},"
      print "  \"median_ms\": ${median_ms},"
      print "  \"stddev_ms\": ${stddev_ms},"
      print "  \"rsd_pct\": ${rsd_pct},"
      print "  \"delta_pct\": ${delta_pct},"
      print "  \"baseline_mean_ms\": ${baseline_mean:-$mean_ms},"
      print "  \"warn_threshold_pct\": ${WARN_THRESHOLD},"
      print "  \"fail_threshold_pct\": ${FAIL_THRESHOLD},"
      print "  \"runs\": ${#VALUES[@]},"
      print "  \"values\": [${(j:,:)VALUES}],"
      print "  \"mode\": \"${MODE}\","
      print "  \"generated_at\": \"$(date -Iseconds 2>/dev/null || date)\","
      print "  \"baseline_file\": \"${BASELINE_FILE}\","
      if [[ "${SYNTHETIC_USED:-0}" -eq 1 && "${ALLOW_SYNTHETIC_SEGMENTS:-0}" -eq 1 ]]; then
        print "  \"synthetic_used\": true,"
      fi
      if [[ "${EPHEMERAL_FLAG:-0}" -eq 1 ]]; then
        print "  \"ephemeral\": true,"
      fi
      print "  \"_debug\": { \"synthetic_used\": ${SYNTHETIC_USED:-0}, \"partial\": 0, \"missing_metrics\": [] }"
      print '}'
    } > "${JSON_OUT}.tmp" 2>/dev/null || {
      print_err "Failed to write JSON summary"
    }
    mv "${JSON_OUT}.tmp" "${JSON_OUT}" 2>/dev/null || true
    (( QUIET )) || print_dbg "Wrote JSON summary to ${JSON_OUT}"
  fi

  # Classification logic (enforce mode exit codes)
  if [[ "$classification" == "WARN" ]]; then
    if [[ "$MODE" == "enforce" ]]; then
      exit_code=2
    fi
  elif [[ "$classification" == "FAIL" ]]; then
    if [[ "$MODE" == "enforce" ]]; then
      exit_code=3
    fi
  else
    exit_code=0
  fi

  # Phase 4 gating (flags-based; no preview env)
  if [[ "$MODE" == "enforce" ]]; then
    if [[ "${ALLOW_SYNTHETIC_SEGMENTS:-0}" -eq 0 && "${SYNTHETIC_USED:-0}" -eq 1 ]]; then
      [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print_dbg "GATING(single): synthetic_used disallowed → enforce-fail"
      exit_code=3
    fi
  fi

  rm -rf "$TMP_BASE"
  if [[ "${MODE:-}" == "observe" ]]; then
    exit 0
  else
    exit ${exit_code:-0}
  fi
fi

# ------------------------------------------------------------------------------
# Multi-metric mode
# ------------------------------------------------------------------------------

# Associative arrays to store metric values
typeset -A METRIC_VALUES
typeset -A METRIC_STATS
typeset -A METRIC_BASELINES
typeset -A METRIC_DELTAS
typeset -A METRIC_STATUS
# Phase 3: PARTIAL latch (debug-only; inert)
PARTIAL_FLAG=0
typeset -a MISSING_METRICS
MISSING_METRICS=()
# Synthetic latch (aggregated across runs; debug + preview gating only)
SYNTHETIC_USED=0

# Initialize metric arrays
for metric in "${METRIC_ARRAY[@]}"; do
  METRIC_VALUES[$metric]=""
done

# Run captures (A: Deep debug – show metric array & paths)
(( QUIET )) || print_dbg "Metrics list: ${METRIC_ARRAY[*]}"
(( QUIET )) || print_dbg "RUNS=${RUNS} BASELINE_DIR=${BASELINE_DIR}"

for ((i=1;i<=RUNS;i++)); do
  run_dir="${LOG_DIR}/run_${i}"
  mkdir -p "$run_dir"
  seg_log="${run_dir}/segments.log"
  (( QUIET )) || print_dbg "Run $i starting capture (seg_log=${seg_log})"
  launch_single_capture "$run_dir" "$seg_log"

  # Debug-only synthetic marker scan per run (Phase 3 preview)
  if grep -q '^#SYNTHETIC_FALLBACK_INSERTED=1' "$seg_log" 2>/dev/null; then
    RUN_SYNTHETIC_USED=1
    SYNTHETIC_USED=1
    [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print_dbg "Run $i synthetic marker detected"
  else
    RUN_SYNTHETIC_USED=0
  fi

  if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
    if [[ -s "$seg_log" ]]; then
      head -n 10 "$seg_log" >&2 || true
    else
      print_err "Run $i: segments.log empty"
    fi
  fi

  # Extract each metric (B: per-metric debug path)
  for metric in "${METRIC_ARRAY[@]}"; do
    ms_val="$(extract_metric_ms "$seg_log" "$metric")"
    if [[ -n "$ms_val" ]]; then
      METRIC_VALUES[$metric]+="$ms_val "
      (( QUIET )) || print_dbg "Run $i ${metric}_ms=$ms_val (accum='${METRIC_VALUES[$metric]}')"
    else
      print_err "Run $i: Unable to extract ${metric} ms (seg_log=${seg_log})"
      # PARTIAL latch: mark missing metric (debug visibility only; no gating in Phase 3)
      PARTIAL_FLAG=1
      MISSING_METRICS+=("$metric")
      if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
        grep -n "SEGMENT name=${metric} " "$seg_log" 2>/dev/null || echo "[dbg] metric=${metric} no matching SEGMENT line" >&2
        print_dbg "PARTIAL latch set; missing+=${metric}"
      fi
    fi
  done
done

# Calculate stats for each metric
overall_status="OK"
worst_metric=""
worst_delta=0

for metric in "${METRIC_ARRAY[@]}"; do
  values="${METRIC_VALUES[$metric]}"
  if [[ -z "$values" || "$values" == " " ]]; then
    print_err "No successful captures for metric: $metric (raw='${METRIC_VALUES[$metric]}')"
    if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
      ls -l "${LOG_DIR}/run_"*/segments.log 2>/dev/null >&2 || true
    fi
    continue
  fi
  (( QUIET )) || print_dbg "Aggregate values for ${metric}: $values"

  # Calculate statistics
  stats_line="$(print -r -- "$values" | tr ' ' '\n' | grep -v '^$' | calc_stats)"
  METRIC_STATS[$metric]="$stats_line"

  mean_ms="${stats_line%% *}"
  rest="${stats_line#* }"
  median_ms="${rest%% *}"
  rest="${rest#* }"
  stddev_ms="${rest%% *}"
  rsd_pct="${rest#* }"

  # Load baseline if exists
  baseline_file="${BASELINE_DIR}/${metric}-baseline.json"
  baseline_mean=""
  if [[ -f "$baseline_file" ]]; then
    baseline_mean="$(grep -E '"mean_ms":' "$baseline_file" 2>/dev/null \
                    | sed -n 's/.*"mean_ms":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -n1)"
  fi

  # Calculate delta and status
  if [[ -z "$baseline_mean" ]]; then
    classification="BASELINE_CREATED"
    delta_pct="0.00"
    baseline_mean="$mean_ms"

    # Save new baseline
    {
      print '{'
      print "  \"metric\": \"${metric}_ms\","
      print "  \"mean_ms\": ${mean_ms},"
      print "  \"median_ms\": ${median_ms},"
      print "  \"stddev_ms\": ${stddev_ms},"
      print "  \"rsd_pct\": ${rsd_pct},"
      print "  \"runs\": $(print -r -- "$values" | wc -w | tr -d ' '),"
      print "  \"created_at\": \"$(date -Iseconds 2>/dev/null || date)\","
      print "  \"values\": [$(print -r -- "$values" | tr ' ' ',' | sed 's/,$//' | sed 's/,,/,/g')]"
      print '}'
    } > "${baseline_file}.tmp" 2>/dev/null || true
    mv "${baseline_file}.tmp" "${baseline_file}" 2>/dev/null || true
  else
    delta_pct="$(percent_delta "$mean_ms" "$baseline_mean")"

    # Determine status
    awk -v d="$delta_pct" -v warn="$WARN_THRESHOLD" -v fail="$FAIL_THRESHOLD" '
      BEGIN{
        status="OK";
        d_abs = (d < 0) ? -d : d;
        if (d_abs > fail) status="FAIL";
        else if (d_abs > warn) status="WARN";
        print status;
      }' | read -r classification
  fi

  METRIC_BASELINES[$metric]="$baseline_mean"
  METRIC_DELTAS[$metric]="$delta_pct"
  METRIC_STATUS[$metric]="$classification"

  # Update overall status (worst-case)
  if [[ "$classification" == "FAIL" ]]; then
    overall_status="FAIL"
    worst_metric="$metric"
    worst_delta="$delta_pct"
  elif [[ "$classification" == "WARN" && "$overall_status" != "FAIL" ]]; then
    overall_status="WARN"
    if [[ -z "$worst_metric" ]] || (( ${delta_pct#-} > ${worst_delta#-} )); then
      worst_metric="$metric"
      worst_delta="$delta_pct"
    fi
  elif [[ "$classification" == "BASELINE_CREATED" && "$overall_status" == "OK" ]]; then
    overall_status="BASELINE_CREATED"
  fi

  # Output per-metric classifier line
  sign="+"
  [[ "${delta_pct}" == -* ]] && sign=""

  CLASS_LINE="CLASSIFIER status=${classification} delta=${sign}${delta_pct}% mean_ms=${mean_ms} baseline_mean_ms=${baseline_mean} median_ms=${median_ms} rsd=${rsd_pct}% runs=$(print -r -- "$values" | wc -w | tr -d ' ') metric=${metric}_ms warn_threshold=${WARN_THRESHOLD}% fail_threshold=${FAIL_THRESHOLD}% mode=${MODE}"
  if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
    print_dbg "Emit line → $CLASS_LINE"
  fi
  (( QUIET )) || print -r -- "$CLASS_LINE"
done

# Output overall summary line
if [[ -n "$worst_metric" ]]; then
  OVERALL_LINE="CLASSIFIER status=OVERALL overall_status=${overall_status} metrics=${#METRIC_ARRAY[@]} worst_metric=${worst_metric}_ms worst_delta=${worst_delta}%"
else
  OVERALL_LINE="CLASSIFIER status=OVERALL overall_status=${overall_status} metrics=${#METRIC_ARRAY[@]}"
fi
if [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]]; then
  print_dbg "OVERALL worst_metric='${worst_metric}' overall_status='${overall_status}'"
  if (( PARTIAL_FLAG )); then
    print_dbg "PARTIAL latch active; missing_metrics=(${(j:,:)MISSING_METRICS})"
  else
    print_dbg "PARTIAL latch inactive"
  fi
  print_dbg "SYNTHETIC_USED=${SYNTHETIC_USED:-0}"
fi
(( QUIET )) || print -r -- "$OVERALL_LINE"

# Determine exit code based on overall status
exit_code=0
if [[ "$overall_status" == "WARN" && "$MODE" == "enforce" ]]; then
  exit_code=2
elif [[ "$overall_status" == "FAIL" && "$MODE" == "enforce" ]]; then
  exit_code=3
fi



# Optional JSON output
if [[ -n "$JSON_OUT" ]]; then
  mkdir -p -- "$(dirname "$JSON_OUT")" 2>/dev/null || true
  {
    print '{'
    print "  \"overall_status\": \"${overall_status}\","
    print "  \"goal\": \"${GOAL}\","
    print "  \"worst_metric\": \"${worst_metric}_ms\","
    print "  \"worst_delta_pct\": ${worst_delta:-0},"
    print "  \"warn_threshold_pct\": ${WARN_THRESHOLD},"
    print "  \"fail_threshold_pct\": ${FAIL_THRESHOLD},"
    print "  \"runs\": ${RUNS},"
    print "  \"mode\": \"${MODE}\","
    print "  \"metrics\": {"

    first=1
    for metric in "${METRIC_ARRAY[@]}"; do
      [[ -n "${METRIC_STATS[$metric]:-}" ]] || continue

      (( first )) || print ","
      first=0

      stats_line="${METRIC_STATS[$metric]}"
      mean_ms="${stats_line%% *}"
      rest="${stats_line#* }"
      median_ms="${rest%% *}"
      rest="${rest#* }"
      stddev_ms="${rest%% *}"
      rsd_pct="${rest#* }"

      print -n "    \"${metric}_ms\": {"
      print -n " \"status\": \"${METRIC_STATUS[$metric]:-UNKNOWN}\","
      print -n " \"delta_pct\": ${METRIC_DELTAS[$metric]:-0},"
      print -n " \"mean_ms\": ${mean_ms},"
      print -n " \"median_ms\": ${median_ms},"
      print -n " \"stddev_ms\": ${stddev_ms},"
      print -n " \"rsd_pct\": ${rsd_pct},"
      print -n " \"baseline_mean_ms\": ${METRIC_BASELINES[$metric]:-$mean_ms},"
      print -n " \"values\": [$(print -r -- "${METRIC_VALUES[$metric]}" | tr ' ' ',' | sed 's/,$//' | sed 's/,,/,/g')]"
      print -n " }"
    done
    print ""
    print "  },"
    print "  \"generated_at\": \"$(date -Iseconds 2>/dev/null || date)\","
    print "  \"baseline_dir\": \"${BASELINE_DIR}\","
    if (( PARTIAL_FLAG )) && [[ "${JSON_PARTIAL_OK:-0}" -eq 1 ]]; then
      print "  \"partial\": true,"
    fi
    if [[ "${SYNTHETIC_USED:-0}" -eq 1 && "${ALLOW_SYNTHETIC_SEGMENTS:-0}" -eq 1 ]]; then
      print "  \"synthetic_used\": true,"
    fi
    if [[ "${EPHEMERAL_FLAG:-0}" -eq 1 ]]; then
      print "  \"ephemeral\": true,"
    fi
    print "  \"_debug\": { \"synthetic_used\": ${SYNTHETIC_USED:-0}, \"partial\": ${PARTIAL_FLAG:-0}, \"missing_metrics\": [\"${(j:\",\":)MISSING_METRICS}\"] }"
    print '}'
  } > "${JSON_OUT}.tmp" 2>/dev/null || {
    print_err "Failed to write JSON summary"
  }
  mv "${JSON_OUT}.tmp" "${JSON_OUT}" 2>/dev/null || true
  (( QUIET )) || print_dbg "Wrote JSON summary to ${JSON_OUT}"
fi

# Phase 4 gating (flags-based; no preview env)
if [[ "$MODE" == "enforce" ]]; then
  if [[ "${REQUIRE_ALL_METRICS:-0}" -ne 0 ]] && (( PARTIAL_FLAG )); then
    [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print_dbg "GATING(multi): missing metrics not allowed → enforce-fail"
    exit_code=3
  elif [[ "${ALLOW_SYNTHETIC_SEGMENTS:-0}" -eq 0 && "${SYNTHETIC_USED:-0}" -eq 1 ]]; then
    [[ -n ${PERF_CLASSIFIER_DEBUG:-} ]] && print_dbg "GATING(multi): synthetic_used disallowed → enforce-fail"
    exit_code=3
  fi
fi

# Cleanup
rm -rf "$TMP_BASE"
if [[ "${MODE:-}" == "observe" ]]; then
  exit 0
else
  exit ${exit_code:-0}
fi
