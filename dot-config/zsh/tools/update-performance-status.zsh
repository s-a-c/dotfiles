#!/usr/bin/env zsh
# update-performance-status.zsh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Parse multi-metric performance classifier output (CLASSIFIER lines) to:
#     1. Aggregate per-metric statistics (mean, baseline, delta %, RSD, status).
#     2. Determine overall status (prefer explicit OVERALL line; else worst metric).
#     3. Maintain an OK streak counter (resets on WARN/FAIL).
#     4. Persist JSON status summary (for README block sync, badges, governance triggers).
#     5. Preserve max historical OK streak and optional enforce_active flag from prior state.
#
# DESIGN GOALS:
#   - Zero external dependencies (no jq, perl).
#   - Idempotent: re-running with identical input produces identical JSON.
#   - Defensive parsing: ignore malformed lines; warn instead of hard fail.
#   - Extensible (additional metrics auto-added).
#
# INPUT SOURCES (PRIORITY ORDER):
#   1. --log <file> (explicit)
#   2. STDIN (if piped and --log not provided)
#
# STATE FILE:
#   A previous JSON can be supplied via --state <file> to carry forward:
#     ok_streak_current, ok_streak_max, enforce_active (if present)
#
# OUTPUT:
#   JSON written to --json-out (default: docs/redesignv2/artifacts/metrics/perf_classifier_status.json)
#
# CLASSIFIER LINE EXAMPLES:
#   Per-metric:
#     CLASSIFIER status=OK delta=+0.0% mean_ms=334 baseline_mean_ms=334 median_ms=334 rsd=1.9% runs=5 metric=prompt_ready_ms warn_threshold=10% fail_threshold=25% mode=observe
#   Overall:
#     CLASSIFIER status=OVERALL overall_status=OK metrics=4 worst_metric=post_plugin_total_ms worst_delta=+0.0%
#
# EXIT CODES:
#   0 success (always; classification gating handled elsewhere)
#   1 usage error
#
# USAGE:
#   tools/update-performance-status.zsh --log classifier.out
#   tools/update-performance-status.zsh --log classifier.out --state prev.json --json-out status.json
#   cat classifier.out | tools/update-performance-status.zsh
#
# OPTIONS:
#   --log <file>          Input file containing CLASSIFIER lines
#   --state <file>        Previous JSON state (optional)
#   --json-out <file>     Output JSON path (default: docs/redesignv2/artifacts/metrics/perf_classifier_status.json)
#   --max-recent <N>      Keep up to N recent metric status snapshots (default: 0 = disabled)
#   --require-overall     If provided, warn if no OVERALL line found (no hard fail)
#   --dry-run             Parse & print JSON to stdout only (no write)
#   --quiet               Suppress non-essential stderr info
#   -h | --help           Show help
#
# JSON SCHEMA (example excerpt):
# {
#   "generated_at": "2025-09-13T10:22:11Z",
#   "overall_status": "OK",
#   "ok_streak_current": 5,
#   "ok_streak_max": 5,
#   "enforce_active": false,
#   "metrics": {
#     "prompt_ready": {
#       "raw_metric_key": "prompt_ready_ms",
#       "status": "OK",
#       "mean_ms": 334,
#       "baseline_mean_ms": 334,
#       "delta_pct": 0.0,
#       "rsd_pct": 1.9,
#       "runs": 5
#     }
#   },
#   "recent_overall": [
#     {"ts":"2025-09-13T10:22:11Z","status":"OK","worst_metric":"post_plugin_total_ms","worst_delta_pct":0.0}
#   ],
#   "source": {
#     "mode": "observe",
#     "warn_threshold_pct": 10,
#     "fail_threshold_pct": 25
#   }
# }
#
# NOTES:
#   - Activation logic (governance row insertion) happens outside this script.
#   - This script makes no CI pass/fail decisions—pure data producer.
#

set -euo pipefail

# ---------------- Defaults ----------------
LOG_FILE=""
STATE_FILE=""
JSON_OUT="docs/redesignv2/artifacts/metrics/perf_classifier_status.json"
MAX_RECENT=0
REQUIRE_OVERALL=0
DRY_RUN=0
QUIET=0

# Internal accumulators
typeset -A METRIC_STATUS          # status by metric key
typeset -A METRIC_MEAN            # mean_ms
typeset -A METRIC_BASELINE        # baseline_mean_ms
typeset -A METRIC_DELTA           # numeric delta (%)
typeset -A METRIC_RSD             # relative stdev (%)
typeset -A METRIC_RUNS            # sample count
typeset -A METRIC_RAW_KEY         # raw metric= key from classifier

OVERALL_STATUS=""
OVERALL_WORST_METRIC=""
OVERALL_WORST_DELTA=""
SOURCE_MODE=""
WARN_THRESHOLD=""
FAIL_THRESHOLD=""

OK_STREAK_CURRENT=0
OK_STREAK_MAX=0
ENFORCE_ACTIVE="false"

RECENT_JSON=""   # from state (array)
NEW_RECENT_JSON="" # updated recent entries array

print_info() { (( QUIET )) || print -r -- "[update-status][info] $*" >&2; }
print_warn() { print -r -- "[update-status][warn] $*" >&2; }
print_err()  { print -r -- "[update-status][err]  $*" >&2; }

usage() {
  sed -n '1,/^usage_end$/p' "$0" | sed '$d'
  cat <<'EOF'
EOF
  exit 0
}

# (Above header already documents usage; marker for extraction)
usage_end

# ---------------- Argument Parsing ----------------
while (( $# > 0 )); do
  case "$1" in
    --log) shift; LOG_FILE="${1:-}";;
    --log=*) LOG_FILE="${1#*=}";;
    --state) shift; STATE_FILE="${1:-}";;
    --state=*) STATE_FILE="${1#*=}";;
    --json-out) shift; JSON_OUT="${1:-}";;
    --json-out=*) JSON_OUT="${1#*=}";;
    --max-recent) shift; MAX_RECENT="${1:-0}";;
    --max-recent=*) MAX_RECENT="${1#*=}";;
    --require-overall) REQUIRE_OVERALL=1;;
    --dry-run) DRY_RUN=1;;
    --quiet) QUIET=1;;
    -h|--help) usage;;
    *)
      print_err "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

# Validate MAX_RECENT
if ! [[ "$MAX_RECENT" =~ ^[0-9]+$ ]]; then
  print_err "--max-recent must be an integer"
  exit 1
fi

# ---------------- Input Acquisition ----------------
CLASSIFIER_DATA=""
if [[ -n "$LOG_FILE" ]]; then
  if [[ ! -r "$LOG_FILE" ]]; then
    print_err "Cannot read --log file: $LOG_FILE"
    exit 1
  fi
  CLASSIFIER_DATA="$(<"$LOG_FILE")"
else
  # If stdin is not a tty, read
  if [[ ! -t 0 ]]; then
    CLASSIFIER_DATA="$(cat)"
  else
    print_err "No --log file provided and no stdin data."
    exit 1
  fi
fi

[[ -n "$CLASSIFIER_DATA" ]] || { print_err "Empty classifier input."; exit 1; }

# ---------------- Prior State Parsing (Shallow) ----------------
if [[ -n "$STATE_FILE" && -r "$STATE_FILE" ]]; then
  STATE_CONTENT="$(<"$STATE_FILE")"
  # Extract numeric values by naive regex; robust enough given controlled format
  if grep -q '"ok_streak_current"' <<<"$STATE_CONTENT"; then
    OK_STREAK_CURRENT="$(grep -E '"ok_streak_current"' <<<"$STATE_CONTENT" | sed -E 's/.*: *([0-9]+).*/\1/' | head -n1)"
  fi
  if grep -q '"ok_streak_max"' <<<"$STATE_CONTENT"; then
    OK_STREAK_MAX="$(grep -E '"ok_streak_max"' <<<"$STATE_CONTENT" | sed -E 's/.*: *([0-9]+).*/\1/' | head -n1)"
  fi
  if grep -q '"enforce_active"' <<<"$STATE_CONTENT"; then
    ENFORCE_ACTIVE="$(grep -E '"enforce_active"' <<<"$STATE_CONTENT" | sed -E 's/.*: *(true|false).*/\1/' | head -n1)"
  fi
  # Extract recent_overall array (store raw)
  if grep -q '"recent_overall"' <<<"$STATE_CONTENT"; then
    RECENT_JSON="$(awk '/"recent_overall"/,/]/' <<<"$STATE_CONTENT" | sed -n '2,$p' | sed '$d')"
    # RECENT_JSON holds lines inside array OR empty if no entries
  fi
else
  OK_STREAK_CURRENT=0
  OK_STREAK_MAX=0
  ENFORCE_ACTIVE="false"
fi

# ---------------- Parsing Helpers ----------------
trim_pct() {
  # Remove leading + and trailing %
  local v="${1//+/}"
  v="${v%%%}"
  print -r -- "$v"
}

normalize_metric_key() {
  # convert prompt_ready_ms -> prompt_ready, else drop _ms suffix if present
  local raw="$1"
  if [[ "$raw" == *_ms ]]; then
    print -r -- "${raw%_ms}"
  else
    print -r -- "$raw"
  fi
}

# ---------------- Parse Classifier Lines ----------------
# Accept both per-metric and OVERALL lines.
while IFS= read -r line; do
  [[ "$line" == CLASSIFIER* ]] || continue

  if [[ "$line" == *" status=OVERALL "* || "$line" == *" status=OVERALL"* ]]; then
    # OVERALL / aggregator line
    # Extract overall_status (some classifier variants may use overall_status=; fallback to status=OVERALL then overall_status=...)
    OVERALL_STATUS="$(sed -n 's/.*overall_status=\([A-Z]\+\).*/\1/p' <<<"$line")"
    [[ -z "$OVERALL_STATUS" ]] && OVERALL_STATUS="UNKNOWN"
    OVERALL_WORST_METRIC="$(sed -n 's/.*worst_metric=\([a-zA-Z0-9_]\+\).*/\1/p' <<<"$line")"
    OVERALL_WORST_DELTA="$(sed -n 's/.*worst_delta=\([+-.0-9%]\+\).*/\1/p' <<<"$line")"
    # thresholds not always present in overall line; capture if available
    WARN_THRESHOLD="${WARN_THRESHOLD:-$(sed -n 's/.*warn_threshold=\([0-9]\+\)%.*/\1/p' <<<"$line")}"
    FAIL_THRESHOLD="${FAIL_THRESHOLD:-$(sed -n 's/.*fail_threshold=\([0-9]\+\)%.*/\1/p' <<<"$line")}"
  else
    # Per-metric line
    local m_status delta mean baseline rsd runs metric raw_mode warn fail
    m_status="$(sed -n 's/.*status=\([A-Z]\+\).*/\1/p' <<<"$line" | awk '{print $1}')" # earliest status token
    delta="$(sed -n 's/.* delta=\([+-.0-9%]\+\).*/\1/p' <<<"$line")"
    mean="$(sed -n 's/.* mean_ms=\([0-9]\+\).*/\1/p' <<<"$line")"
    baseline="$(sed -n 's/.* baseline_mean_ms=\([0-9]\+\).*/\1/p' <<<"$line")"
    rsd="$(sed -n 's/.* rsd=\([0-9.]\+\)%.*/\1/p' <<<"$line")"
    runs="$(sed -n 's/.* runs=\([0-9]\+\).*/\1/p' <<<"$line")"
    raw_mode="$(sed -n 's/.* mode=\([a-zA-Z]\+\).*/\1/p' <<<"$line")"
    metric="$(sed -n 's/.* metric=\([a-zA-Z0-9_]\+\).*/\1/p' <<<"$line")"
    warn="$(sed -n 's/.* warn_threshold=\([0-9]\+\)%.*/\1/p' <<<"$line")"
    fail="$(sed -n 's/.* fail_threshold=\([0-9]\+\)%.*/\1/p' <<<"$line")"

    [[ -n "$warn" ]] && WARN_THRESHOLD="${WARN_THRESHOLD:-$warn}"
    [[ -n "$fail" ]] && FAIL_THRESHOLD="${FAIL_THRESHOLD:-$fail}"
    [[ -n "$raw_mode" ]] && SOURCE_MODE="${SOURCE_MODE:-$raw_mode}"

    if [[ -z "$metric" || -z "$m_status" ]]; then
      print_warn "Skipping malformed classifier line: $line"
      continue
    fi

    local norm_key
    norm_key="$(normalize_metric_key "$metric")"

    # Populate arrays
    METRIC_RAW_KEY["$norm_key"]="$metric"
    METRIC_STATUS["$norm_key"]="$m_status"
    [[ -n "$mean" ]] && METRIC_MEAN["$norm_key"]="$mean"
    [[ -n "$baseline" ]] && METRIC_BASELINE["$norm_key"]="$baseline"
    if [[ -n "$delta" ]]; then
      METRIC_DELTA["$norm_key"]="$(trim_pct "$delta")"
    fi
    [[ -n "$rsd" ]] && METRIC_RSD["$norm_key"]="$rsd"
    [[ -n "$runs" ]] && METRIC_RUNS["$norm_key"]="$runs"
  fi
done <<< "$CLASSIFIER_DATA"

# Derive thresholds/mode if still empty
[[ -z "$SOURCE_MODE" ]] && SOURCE_MODE="observe"
[[ -z "$WARN_THRESHOLD" ]] && WARN_THRESHOLD="10"
[[ -z "$FAIL_THRESHOLD" ]] && FAIL_THRESHOLD="25"

# ---------------- Compute Overall (if missing) ----------------
if [[ -z "$OVERALL_STATUS" || "$OVERALL_STATUS" == "UNKNOWN" ]]; then
  # Determine worst status among metrics: FAIL > WARN > OK > (fallback)
  local worst="OK"
  local worst_metric=""
  local worst_delta="0"
  for k in "${(@k)METRIC_STATUS}"; do
    local st="${METRIC_STATUS[$k]}"
    local d="${METRIC_DELTA[$k]:-0}"
    # convert to numeric
    local dn="${d//%/}"
    [[ -z "$dn" ]] && dn=0
    if [[ "$st" == "FAIL" ]]; then
      worst="FAIL"; worst_metric="${METRIC_RAW_KEY[$k]:-$k}"; worst_delta="$dn"
      break
    elif [[ "$st" == "WARN" && "$worst" != "FAIL" ]]; then
      worst="WARN"; worst_metric="${METRIC_RAW_KEY[$k]:-$k}"; worst_delta="$dn"
    elif [[ "$st" == "OK" && "$worst" == "OK" ]]; then
      # keep largest delta among OK
      if (( ${dn%%.*} > ${worst_delta%%.*} )); then
        worst_metric="${METRIC_RAW_KEY[$k]:-$k}"; worst_delta="$dn"
      fi
    fi
  done
  OVERALL_STATUS="$worst"
  OVERALL_WORST_METRIC="$worst_metric"
  OVERALL_WORST_DELTA="$worst_delta"
else
  # Clean worst delta if present with %
  OVERALL_WORST_DELTA="$(trim_pct "$OVERALL_WORST_DELTA")"
fi

if (( REQUIRE_OVERALL )) && [[ -z "$OVERALL_WORST_METRIC" ]]; then
  print_warn "No explicit OVERALL line found; computed overall=$OVERALL_STATUS"
fi

# ---------------- Update Streak ----------------
if [[ "$OVERALL_STATUS" == "OK" ]]; then
  (( OK_STREAK_CURRENT++ ))
else
  OK_STREAK_CURRENT=0
fi
(( OK_STREAK_CURRENT > OK_STREAK_MAX )) && OK_STREAK_MAX=$OK_STREAK_CURRENT

# ---------------- Recent Overall History ----------------
# Build new recent entry
CURRENT_TS="$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")"
NEW_ENTRY="{\"ts\":\"$CURRENT_TS\",\"status\":\"$OVERALL_STATUS\",\"worst_metric\":\"$OVERALL_WORST_METRIC\",\"worst_delta_pct\":${OVERALL_WORST_DELTA:-0}}"

if (( MAX_RECENT > 0 )); then
  typeset -a existing
  if [[ -n "$RECENT_JSON" ]]; then
    # Reconstruct existing entries lines (simple JSON objects each line or partial)
    # We'll just grab object starts: { ... }
    # Simpler: collapse to single line, split on '}{' with re-wrapping
    local collapsed
    collapsed="$(echo "$RECENT_JSON" | tr -d '\n' | sed 's/ //g')"
    # Insert delimiter
    collapsed="${collapsed#\[}"
    collapsed="${collapsed%\]}"
    # Split by '},{'
    IFS=$',' existing=()
    # Instead of complicated parsing, accept risk: if objects contain internal commas unaffected.
    # We'll re-parse using a safer approach: rely on original lines if multi-line; keep simple.
    # For robustness, we only push prior entries if they look like {"ts":
    while IFS= read -r l; do
      [[ "$l" == *'"ts"'* ]] && existing+="$l"
    done <<< "$RECENT_JSON"
  fi

  # Prepend new
  typeset -a updated
  updated=("$NEW_ENTRY" "${existing[@]}")

  # Trim to MAX_RECENT
  if (( ${#updated[@]} > MAX_RECENT )); then
    updated=("${updated[1,MAX_RECENT]}")
  fi

  # Join
  NEW_RECENT_JSON="$(printf '%s,\n' "${updated[@]}")"
  NEW_RECENT_JSON="${NEW_RECENT_JSON%,?}" # drop trailing comma/newline if present
fi

# ---------------- JSON Assembly ----------------
mkdir -p -- "${JSON_OUT:h}" 2>/dev/null || true

json_escape() {
  # Minimal escape for quotes/backslashes
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  print -r -- "$s"
}

# Metrics JSON
METRICS_JSON=""
for k in "${(@k)METRIC_STATUS}"; do
  local raw="${METRIC_RAW_KEY[$k]}"
  local st="${METRIC_STATUS[$k]}"
  local mean="${METRIC_MEAN[$k]:-0}"
  local base="${METRIC_BASELINE[$k]:-0}"
  local delta="${METRIC_DELTA[$k]:-0}"
  local rsd="${METRIC_RSD[$k]:-0}"
  local runs="${METRIC_RUNS[$k]:-0}"
  METRICS_JSON+=$'"'"$k"'":{'
  METRICS_JSON+=$'"raw_metric_key":"'"$raw"'"'
  METRICS_JSON+=$',"status":"'"$st"'"'
  METRICS_JSON+=$',"mean_ms":'"$mean"
  METRICS_JSON+=$',"baseline_mean_ms":'"$base"
  METRICS_JSON+=$',"delta_pct":'"${delta//%/}"
  METRICS_JSON+=$',"rsd_pct":'"${rsd//%/}"
  METRICS_JSON+=$',"runs":'"$runs"
  METRICS_JSON+='},'
done
METRICS_JSON="${METRICS_JSON%,}" # strip trailing comma

# Recent overall JSON
if (( MAX_RECENT > 0 )); then
  if [[ -n "$NEW_RECENT_JSON" ]]; then
    RECENT_OVERALL_JSON="$NEW_RECENT_JSON"
  elif [[ -n "$RECENT_JSON" ]]; then
    RECENT_OVERALL_JSON="$RECENT_JSON"
  else
    RECENT_OVERALL_JSON=""
  fi
else
  RECENT_OVERALL_JSON=""
fi

OUTPUT_JSON=$(cat <<EOF
{
  "generated_at": "$CURRENT_TS",
  "overall_status": "$OVERALL_STATUS",
  "ok_streak_current": $OK_STREAK_CURRENT,
  "ok_streak_max": $OK_STREAK_MAX,
  "enforce_active": $ENFORCE_ACTIVE,
  "overall_worst_metric": "$(json_escape "$OVERALL_WORST_METRIC")",
  "overall_worst_delta_pct": ${OVERALL_WORST_DELTA:-0},
  "metrics": { ${METRICS_JSON:-} },
  "source": {
    "mode": "$(json_escape "$SOURCE_MODE")",
    "warn_threshold_pct": $WARN_THRESHOLD,
    "fail_threshold_pct": $FAIL_THRESHOLD
  }$( (( MAX_RECENT > 0 )) && print -r -- "," || true )
EOF
)

if (( MAX_RECENT > 0 )); then
  OUTPUT_JSON+=$'\n  "recent_overall": [\n'
  if [[ -n "$RECENT_OVERALL_JSON" ]]; then
    # Ensure each object on single line
    OUTPUT_JSON+=$(echo "$RECENT_OVERALL_JSON" | sed 's/^[[:space:]]*//')
    OUTPUT_JSON+=$'\n'
  fi
  OUTPUT_JSON+=$'  ]\n'
else
  OUTPUT_JSON+=$'\n'
fi
OUTPUT_JSON+=$'}'

# ---------------- Emit ----------------
if (( DRY_RUN )); then
  print_info "DRY_RUN=1 → JSON not written (showing output)"
  print -r -- "$OUTPUT_JSON"
else
  print_info "Writing JSON status to: $JSON_OUT"
  printf "%s\n" "$OUTPUT_JSON" >"$JSON_OUT"
fi

print_info "Overall=$OVERALL_STATUS streak=${OK_STREAK_CURRENT} (max=${OK_STREAK_MAX}) metrics=${#METRIC_STATUS[@]} mode=$SOURCE_MODE"
exit 0
