#!/usr/bin/env zsh
# auto-enable-perf-warn-gate.zsh
#
# PURPOSE:
#   Automates a recommendation (and optional environment toggle file emission)
#   for moving the performance diff guard from observe → warn/gate based on
#   multi-sample variance stability. Once variance is consistently low across
#   key segments, the script suggests (or directly emits) enabling:
#       PERF_DIFF_FAIL_ON_REGRESSION=1
#
# STRATEGY:
#   1. Parse the multi-sample performance JSON (default:
#        docs/redesignv2/artifacts/metrics/perf-multi-current.json)
#   2. Extract mean_ms and stdev_ms (or infer from alternative keys) for a
#      target segment set (default: post_plugin_total pre_plugin_total prompt_ready)
#   3. Compute variance% = (stdev_ms / mean_ms)*100 (mean_ms > 0 guard)
#   4. A segment is STABLE if variance% ≤ threshold (default 5.0)
#   5. All required segments must be STABLE in a run to count the run as STABLE
#   6. Maintain rolling state in a JSON state file (default:
#        docs/redesignv2/artifacts/metrics/perf-gate-state.json)
#   7. After N consecutive stable runs (default 2), recommend enabling gating
#      (decision = "enable_fail"). Otherwise decision = "observe".
#
# OUTPUTS:
#   - Recommendation JSON (default: docs/redesignv2/artifacts/metrics/perf-gating-recommendation.json)
#       {
#         "schemaVersion":1,
#         "decision":"enable_fail"|"observe"|"force_enable"|"force_disable",
#         "stable_consecutive":2,
#         "required_consecutive":2,
#         "threshold_pct":5,
#         "segments":[
#           {"name":"post_plugin_total","mean_ms":1234,"stdev_ms":12,"variance_pct":0.97,"status":"stable"}
#         ],
#         "generatedAt":"ISO8601",
#         "notes": "...",
#         "stateFile":"path"
#       }
#   - Optional environment export file (e.g. --env-out .ci/perf-mode.env):
#       PERF_DIFF_FAIL_ON_REGRESSION=1   (only when decision is enable_fail / force_enable)
#
# EXIT CODES:
#   0 = success (recommendation produced)
#   10 = success but still observing (not yet enough stable runs)
#   11 = degraded: missing metrics / insufficient data (still produced JSON)
#   1  = usage / fatal parsing error
#
# FLAGS:
#   --multi <file>              Path to multi-sample JSON (default shown above)
#   --segments "a b c"          Space-separated segment names (default core trio)
#   --threshold-pct <float>     Variance% stability threshold (default 5)
#   --required-stable <int>     Consecutive stable runs required (default 2)
#   --state-file <file>         Persistence of consecutive counter
#   --output <file>             Recommendation JSON output
#   --env-out <file>            Emit shell export lines for CI consumption
#   --force-enable              Force decision=force_enable (bypass variance logic)
#   --force-disable             Force decision=force_disable (bypass variance logic)
#   --dry-run                   Do not mutate state file (read-only evaluation)
#   --quiet                     Suppress non-error logs
#   --help                      Show help
#
# ASSUMPTIONS / FORMAT FLEXIBILITY:
#   Supports these possible shapes for each segment object (first match wins):
#       .segments.<name>.mean_ms / .segments.<name>.stdev_ms
#       .segments.<name>.mean / .segments.<name>.stdev
#       .segments.<name>.ms_mean / .segments.<name>.ms_stdev
#   If jq absent, a very naive grep/sed fallback attempts extraction (best‑effort).
#
# INTEGRATION SUGGESTION (GitHub Actions):
#   - Run after multi-sample capture & variance test.
#   - Source env-out file (if created) to conditionally set
#       PERF_DIFF_FAIL_ON_REGRESSION=1
#     for a later perf-diff step or guard script.
#
# SAFETY:
#   - Never auto-enables fail mode on first stable run (needs required streak).
#   - State file JSON includes last decision & streak for auditability.
#
# FUTURE ENHANCEMENTS (not implemented here):
#   - Rolling window (instead of strict consecutive)
#   - Median absolute deviation support
#   - Segment weighting
#   - Combined regression & variance composite scoring
#
set -euo pipefail

# --------------------------
# Defaults
# --------------------------
MULTI_FILE="docs/redesignv2/artifacts/metrics/perf-multi-current.json"
SEGMENTS=("post_plugin_total" "pre_plugin_total" "prompt_ready")
THRESHOLD_PCT="5.0"
REQUIRED_STABLE=2
STATE_FILE="docs/redesignv2/artifacts/metrics/perf-gate-state.json"
OUTPUT_FILE="docs/redesignv2/artifacts/metrics/perf-gating-recommendation.json"
ENV_OUT=""
FORCE_ENABLE=0
FORCE_DISABLE=0
DRY_RUN=0
QUIET=0

# --------------------------
# Helpers
# --------------------------
log(){ (( QUIET )) || printf "[perf-gate] %s\n" "$*" >&2; }
warn(){ printf "[perf-gate][WARN] %s\n" "$*" >&2; }
err(){ printf "[perf-gate][ERROR] %s\n" "$*" >&2; }

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

show_help() {
  sed -n '1,120p' "$0"
}

float_re='^[0-9]+([.][0-9]+)?$'

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --multi) MULTI_FILE="$2"; shift 2 ;;
      --segments) SEGMENTS=(${=2}); shift 2 ;;
      --threshold-pct) THRESHOLD_PCT="$2"; shift 2 ;;
      --required-stable) REQUIRED_STABLE="$2"; shift 2 ;;
      --state-file) STATE_FILE="$2"; shift 2 ;;
      --output) OUTPUT_FILE="$2"; shift 2 ;;
      --env-out) ENV_OUT="$2"; shift 2 ;;
      --force-enable) FORCE_ENABLE=1; shift ;;
      --force-disable) FORCE_DISABLE=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --quiet) QUIET=1; shift ;;
      --help|-h) show_help; exit 0 ;;
      *) err "Unknown argument: $1"; exit 1 ;;
    esac
  done
}

parse_args "$@"

if (( FORCE_ENABLE && FORCE_DISABLE )); then
  err "Cannot specify both --force-enable and --force-disable"
  exit 1
fi

if ! [[ "$THRESHOLD_PCT" =~ $float_re ]]; then
  err "Invalid --threshold-pct value: $THRESHOLD_PCT"
  exit 1
fi
if ! [[ "$REQUIRED_STABLE" =~ '^[0-9]+$' ]]; then
  err "Invalid --required-stable value: $REQUIRED_STABLE"
  exit 1
fi
(( REQUIRED_STABLE > 0 )) || { err "--required-stable must be > 0"; exit 1; }

# --------------------------
# State Management
# --------------------------
STABLE_CONSEC=0
LAST_DECISION="observe"

load_state() {
  [[ -f "$STATE_FILE" ]] || return 0
  local raw
  raw=$(<"$STATE_FILE") || return 0
  if [[ $have_jq -eq 1 ]]; then
    STABLE_CONSEC=$(jq -r '.stable_consecutive // 0' <<<"$raw" 2>/dev/null || echo 0)
    LAST_DECISION=$(jq -r '.last_decision // "observe"' <<<"$raw" 2>/dev/null || echo "observe")
  else
    STABLE_CONSEC=$(print -- "$raw" | sed -n 's/.*"stable_consecutive":[[:space:]]*\([0-9]\+\).*/\1/p' | head -1)
    [[ -z "$STABLE_CONSEC" ]] && STABLE_CONSEC=0
    LAST_DECISION=$(print -- "$raw" | sed -n 's/.*"last_decision":"\([^"]*\)".*/\1/p' | head -1)
    [[ -z "$LAST_DECISION" ]] && LAST_DECISION="observe"
  fi
}

save_state() {
  local dir="${STATE_FILE:h}"
  [[ -d "$dir" ]] || mkdir -p "$dir"
  cat > "${STATE_FILE}.tmp" <<EOF
{
  "stable_consecutive": $STABLE_CONSEC,
  "last_decision": "$LAST_DECISION",
  "updatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "threshold_pct": $THRESHOLD_PCT,
  "required_stable": $REQUIRED_STABLE
}
EOF
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# --------------------------
# Multi-Sample Parsing
# --------------------------
# Returns: mean, stdev for a segment (blank if missing)
extract_segment_stats() {
  local seg="$1" file="$2"
  local mean="" stdev=""
  if [[ ! -f "$file" ]]; then
    echo "::" ; return 0
  fi
  if (( have_jq )); then
    # Try multiple candidate key sets (ordered)
    mean=$(jq -r --arg s "$seg" '
      (.segments[$s].mean_ms // .segments[$s].mean // .segments[$s].ms_mean // empty)
    ' "$file" 2>/dev/null | head -1)
    stdev=$(jq -r --arg s "$seg" '
      (.segments[$s].stdev_ms // .segments[$s].stdev // .segments[$s].ms_stdev // empty)
    ' "$file" 2>/dev/null | head -1)
  else
    # Naive fallback: look for "<seg>" followed by "mean_ms" and "stdev_ms"
    local block
    block=$(grep -A5 -E "\"$seg\"" "$file" 2>/dev/null || true)
    mean=$(print -- "$block" | sed -n 's/.*"mean_ms":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)
    [[ -z "$mean" ]] && mean=$(print -- "$block" | sed -n 's/.*"mean":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)
    stdev=$(print -- "$block" | sed -n 's/.*"stdev_ms":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)
    [[ -z "$stdev" ]] && stdev=$(print -- "$block" | sed -n 's/.*"stdev":[[:space:]]*\([0-9.]\+\).*/\1/p' | head -1)
  fi
  echo "${mean:-}:${stdev:-}"
}

# --------------------------
# Main Evaluation
# --------------------------
load_state

DECISION="observe"
NOTES=()
SEG_REPORT_JSON=()
ALL_STABLE_RUN=1
DATA_PRESENT=1

if (( FORCE_ENABLE )); then
  DECISION="force_enable"
  STABLE_CONSEC=$REQUIRED_STABLE
  LAST_DECISION="$DECISION"
elif (( FORCE_DISABLE )); then
  DECISION="force_disable"
  STABLE_CONSEC=0
  LAST_DECISION="$DECISION"
else
  if [[ ! -f "$MULTI_FILE" ]]; then
    warn "Multi-sample file missing: $MULTI_FILE"
    DATA_PRESENT=0
    ALL_STABLE_RUN=0
  fi

  if (( DATA_PRESENT )); then
    for seg in "${SEGMENTS[@]}"; do
      stats=$(extract_segment_stats "$seg" "$MULTI_FILE")
      mean=${stats%%:*}
      stdev=${stats#*:}
      variance_pct=""
      status="missing"

      if [[ -z "$mean" || -z "$stdev" ]]; then
        status="missing"
        ALL_STABLE_RUN=0
        SEG_REPORT_JSON+=("{\"name\":\"$seg\",\"mean_ms\":null,\"stdev_ms\":null,\"variance_pct\":null,\"status\":\"missing\"}")
        continue
      fi
      if ! [[ "$mean" =~ $float_re ]] || ! [[ "$stdev" =~ $float_re ]]; then
        status="invalid"
        ALL_STABLE_RUN=0
        SEG_REPORT_JSON+=("{\"name\":\"$seg\",\"mean_ms\":\"$mean\",\"stdev_ms\":\"$stdev\",\"variance_pct\":null,\"status\":\"invalid\"}")
        continue
      fi
      if awk -v m="$mean" 'BEGIN{exit (m>0?0:1)}'; then
        variance_pct=$(awk -v s="$stdev" -v m="$mean" 'BEGIN{printf "%.4f", (s/m)*100}')
      else
        variance_pct="0.0000"
      fi
      if awk -v v="$variance_pct" -v th="$THRESHOLD_PCT" 'BEGIN{exit (v<=th?0:1)}'; then
        status="stable"
      else
        status="unstable"
        ALL_STABLE_RUN=0
      fi
      SEG_REPORT_JSON+=("{\"name\":\"$seg\",\"mean_ms\":$mean,\"stdev_ms\":$stdev,\"variance_pct\":$variance_pct,\"status\":\"$status\"}")
    done
  fi

  if (( DATA_PRESENT )); then
    if (( ALL_STABLE_RUN )); then
      (( STABLE_CONSEC++ ))
      NOTES+=("All segments stable this run (streak=$STABLE_CONSEC)")
    else
      if (( STABLE_CONSEC > 0 )); then
        NOTES+=("Stability streak reset (was $STABLE_CONSEC)")
      fi
      STABLE_CONSEC=0
    fi
  fi

  if (( STABLE_CONSEC >= REQUIRED_STABLE )); then
    DECISION="enable_fail"
  else
    DECISION="observe"
  fi

  LAST_DECISION="$DECISION"
fi

# --------------------------
# Persist State (unless dry-run)
# --------------------------
if (( DRY_RUN )); then
  log "Dry run: state not persisted."
else
  save_state
fi

# --------------------------
# Emit Recommendation JSON
# --------------------------
out_dir="${OUTPUT_FILE:h}"
[[ -d "$out_dir" ]] || mkdir -p "$out_dir"

joined_segments=$(printf '%s\n' "${SEG_REPORT_JSON[@]}" | paste -sd, -)

notes_text=$(printf '%s; ' "${NOTES[@]}" | sed 's/; $//')
[[ -z "$notes_text" ]] && notes_text=""

cat > "${OUTPUT_FILE}.tmp" <<EOF
{
  "schemaVersion": 1,
  "decision": "${DECISION}",
  "stable_consecutive": ${STABLE_CONSEC},
  "required_consecutive": ${REQUIRED_STABLE},
  "threshold_pct": ${THRESHOLD_PCT},
  "segments": [ ${joined_segments} ],
  "generatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "stateFile": "$(printf %s "$STATE_FILE")",
  "notes": "$(printf '%s' "$notes_text" | sed 's/"/\\"/g')",
  "force_enable": ${FORCE_ENABLE},
  "force_disable": ${FORCE_DISABLE},
  "dry_run": ${DRY_RUN}
}
EOF

mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
log "Wrote recommendation: $OUTPUT_FILE (decision=$DECISION streak=$STABLE_CONSEC)"

# --------------------------
# ENV Output (optional)
# --------------------------
if [[ -n "$ENV_OUT" ]]; then
  env_dir="${ENV_OUT:h}"
  [[ -d "$env_dir" ]] || mkdir -p "$env_dir"
  {
    if [[ "$DECISION" == "enable_fail" || "$DECISION" == "force_enable" ]]; then
      echo "PERF_DIFF_FAIL_ON_REGRESSION=1"
    else
      echo "PERF_DIFF_FAIL_ON_REGRESSION=0"
    fi
    echo "PERF_DIFF_VARIANCE_STREAK=$STABLE_CONSEC"
    echo "PERF_DIFF_VARIANCE_THRESHOLD=$THRESHOLD_PCT"
  } > "${ENV_OUT}.tmp"
  mv "${ENV_OUT}.tmp" "$ENV_OUT"
  log "Wrote env file: $ENV_OUT"
fi

# --------------------------
# Exit Code Logic
# --------------------------
if (( FORCE_ENABLE || FORCE_DISABLE )); then
  exit 0
fi

if (( DATA_PRESENT == 0 )); then
  warn "No data present; observation only."
  exit 11
fi

if [[ "$DECISION" == "enable_fail" ]]; then
  log "Variance stability criteria met (>=${REQUIRED_STABLE} consecutive); gating may be enabled."
  exit 0
fi

if (( STABLE_CONSEC == 0 )); then
  exit 10  # Not yet stable
fi

exit 10
