#!/usr/bin/env zsh
# generate-variance-state-badge.zsh
#
# Schema (extended): variance-state.v1
#
# PURPOSE:
#   Produce an explicit variance enforcement mode artifact (variance-state.json)
#   plus (optionally) a Shields‑compatible badge JSON summarizing the current
#   performance variance gating state: observe | warn | gate.
#
#   This formalizes what was previously “derived” by governance aggregation so
#   downstream tooling (governance badge, promotion guard, infra-health) can
#   consume a stable contract instead of guessing from thresholds.
#
# DECISION MODEL (default):
#   - Parse multi-sample performance aggregate (perf-multi-current.json) for
#     pre & post plugin metrics (mean + stddev) and compute RSD = stddev/mean.
#   - Maintain a persistent streak counter (state file) of consecutive
#     “stable” runs (both RSDs <= VARIANCE_RSD_THRESHOLD_WARN).
#   - Mode transitions:
#       observe → warn  when stable_run_count >= VARIANCE_STREAK_REQUIRED
#       warn    → gate  when stable_run_count >= VARIANCE_STREAK_REQUIRED + 1
#   - Any instability (one metric missing or RSD above threshold) resets
#     stable_run_count to 0 and mode returns to observe (unless --mode override).
#
# OVERRIDES:
#   - --mode <observe|warn|gate> forces the mode (still records parsed RSD, but
#     does NOT advance/reset the streak unless --respect-streak is passed).
#   - --respect-streak with --mode will still mutate stable_run_count following
#     stability evaluation; without it the streak is preserved as-is.
#
# OUTPUT FILES:
#   (a) variance-state.json (extended schema)
#   (b) variance badge JSON (label “variance”) if requested
#
# EXTENDED JSON SCHEMA (variance-state.v1):
# {
#   "schema":"variance-state.v1",
#   "generated_at":"UTC_ISO8601",
#   "mode":"observe|warn|gate",
#   "rsd":{
#     "pre":{"mean":<num|null>,"stddev":<num|null>,"rsd":<num|null>},
#     "post":{"mean":<num|null>,"stddev":<num|null>,"rsd":<num|null>}
#   },
#   "thresholds":{
#     "rsd_warn_max":0.05,
#     "streak_required":2
#   },
#   "stable_run_count":<int>,
#   "previous_mode":"observe|warn|gate|none",
#   "promotion_notes":"<string>",
#   "sources":{
#     "samples_file":"path|missing",
#     "state_file":"path|missing"
#   }
# }
#
# BADGE JSON (Shields):
#   {"label":"variance","message":"observe|warn|gate","color":"<color>"}
#
# COLORS (defaults):
#   observe: lightgrey
#   warn:    yellow
#   gate:    brightgreen
#
# EXIT CODES:
#   0 success
#   1 usage / parse error
#
# FLAGS:
#   --samples <file>      Path to perf-multi-current.json (multi-sample aggregate)
#   --output <file>       Extended variance-state JSON output (default $VARIANCE_STATE_OUT or derived)
#   --badge <file>        Badge JSON output path
#   --mode <m>            Force mode (observe|warn|gate)
#   --respect-streak      Allow streak counter to update when forcing mode
#   --state-file <file>   Persistent streak state file (default derived)
#   --no-badge            Do not emit badge even if --badge/VARIANCE_BADGE_OUT present
#   --quiet               Suppress non-fatal logs
#   --help
#
# ENVIRONMENT OVERRIDES:
#   VARIANCE_SAMPLES_FILE
#   VARIANCE_STATE_OUT
#   VARIANCE_BADGE_OUT
#   VARIANCE_STATE_FILE          (persistent streak file)
#   VARIANCE_RSD_THRESHOLD_WARN  (default 0.05)
#   VARIANCE_STREAK_REQUIRED     (default 2)
#   VARIANCE_COLOR_OBSERVE       (default lightgrey)
#   VARIANCE_COLOR_WARN          (default yellow)
#   VARIANCE_COLOR_GATE          (default brightgreen)
#
# FALLBACK PARSING:
#   If jq is unavailable, a lightweight regex extraction is attempted. If
#   either mean or stddev cannot be parsed, rsd becomes null and stability
#   evaluation for that metric fails (keeps mode=observe).
#
# SECURITY:
#   - Read-only processing of local artifacts.
#   - No network access.
#
# FUTURE ENHANCEMENTS:
#   - Median Absolute Deviation (MAD) alternative gating.
#   - Separate thresholds for pre vs post segments.
#   - JSON schema validation test.
#
set -euo pipefail

# ---------------- Defaults ----------------
: "${VARIANCE_RSD_THRESHOLD_WARN:=0.05}"
: "${VARIANCE_STREAK_REQUIRED:=2}"
: "${VARIANCE_SAMPLES_FILE:=docs/redesignv2/artifacts/metrics/perf-multi-current.json}"
: "${VARIANCE_STATE_OUT:=docs/redesignv2/artifacts/badges/variance-state.json}"
: "${VARIANCE_BADGE_OUT:=docs/badges/variance-state.json}"
: "${VARIANCE_STATE_FILE:=docs/redesignv2/artifacts/metrics/variance-gating-state.json}"

: "${VARIANCE_COLOR_OBSERVE:=lightgrey}"
: "${VARIANCE_COLOR_WARN:=yellow}"
: "${VARIANCE_COLOR_GATE:=brightgreen}"

FORCE_MODE=""
RESPECT_STREAK=0
NO_BADGE=0
QUIET=0
SAMPLES_FILE="$VARIANCE_SAMPLES_FILE"
OUT_JSON="$VARIANCE_STATE_OUT"
BADGE_JSON="$VARIANCE_BADGE_OUT"
STATE_FILE="$VARIANCE_STATE_FILE"

print_help() {
  sed -n '1,180p' "$0" | grep -E '^#' | sed 's/^# \{0,1\}//'
  cat <<EOF

Usage:
  $0 [--samples file] [--output file] [--badge file] [--mode observe|warn|gate] [--respect-streak] [--state-file file] [--no-badge]

Examples:
  $0
  $0 --samples docs/redesignv2/artifacts/metrics/perf-multi-current.json --output docs/redesignv2/artifacts/badges/variance-state.json --badge docs/badges/variance-state.json
  VARIANCE_RSD_THRESHOLD_WARN=0.04 VARIANCE_STREAK_REQUIRED=3 $0

EOF
}

while (( $# )); do
  case "$1" in
    --samples) shift; SAMPLES_FILE="${1:-}";;
    --output) shift; OUT_JSON="${1:-}";;
    --badge) shift; BADGE_JSON="${1:-}";;
    --mode) shift; FORCE_MODE="${1:-}";;
    --respect-streak) RESPECT_STREAK=1;;
    --state-file) shift; STATE_FILE="${1:-}";;
    --no-badge) NO_BADGE=1;;
    --quiet) QUIET=1;;
    --help|-h) print_help; exit 0;;
    --) shift; break;;
    *) echo "ERROR: unknown argument: $1" >&2; print_help; exit 1;;
  esac
  shift || true
done

if [[ -n "$FORCE_MODE" && ! "$FORCE_MODE" =~ ^(observe|warn|gate)$ ]]; then
  echo "ERROR: --mode must be observe|warn|gate" >&2
  exit 1
fi

_have_jq=0
command -v jq >/dev/null 2>&1 && _have_jq=1

# ---------------- Parsing Helpers ----------------
_num_or_null() {
  local v=$1
  [[ "$v" =~ ^[0-9]+([.][0-9]+)?$ ]] && echo "$v" || echo "null"
}

_extract_stats_with_jq() {
  local file=$1
  # Expect aggregate.pre_plugin_cost_ms.mean / stddev (perf-multi schema)
  jq -r '
    {
      pre_mean:   (.aggregate.pre_plugin_cost_ms.mean   // null),
      pre_std:    (.aggregate.pre_plugin_cost_ms.stddev // null),
      post_mean:  (.aggregate.post_plugin_cost_ms.mean  // null),
      post_std:   (.aggregate.post_plugin_cost_ms.stddev // null)
    } | @tsv
  ' "$file" 2>/dev/null || return 1
}

_extract_stats_light() {
  # Very lightweight regex pass.
  local file=$1
  local pre_mean pre_std post_mean post_std
  pre_mean=$(grep -E '"pre_plugin_cost_ms"' -A4 "$file" 2>/dev/null | grep '"mean"' | head -1 | sed -E 's/.*"mean"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/' || true)
  pre_std=$(grep -E '"pre_plugin_cost_ms"' -A6 "$file" 2>/dev/null | grep '"stddev"' | head -1 | sed -E 's/.*"stddev"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/' || true)
  post_mean=$(grep -E '"post_plugin_cost_ms"' -A4 "$file" 2>/dev/null | grep '"mean"' | head -1 | sed -E 's/.*"mean"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/' || true)
  post_std=$(grep -E '"post_plugin_cost_ms"' -A6 "$file" 2>/dev/null | grep '"stddev"' | head -1 | sed -E 's/.*"stddev"[[:space:]]*:[[:space:]]*([0-9.]+).*/\1/' || true)
  printf '%s\t%s\t%s\t%s\n' "${pre_mean:-}" "${pre_std:-}" "${post_mean:-}" "${post_std:-}"
}

_compute_rsd() {
  local mean=$1 std=$2
  if [[ "$mean" == "null" || "$std" == "null" || -z "$mean" || -z "$std" ]]; then
    echo "null"; return 0
  fi
  if [[ "$mean" =~ ^[0-9]+([.][0-9]+)?$ && "$std" =~ ^[0-9]+([.][0-9]+)?$ && "$mean" != "0" ]]; then
    awk -v m="$mean" -v s="$std" 'BEGIN{printf "%.6f", s/m}'
  else
    echo "null"
  fi
}

_now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date
}

_json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# ---------------- Load Existing State ----------------
stable_run_count=0
previous_mode="none"
if [[ -f "$STATE_FILE" ]]; then
  if (( _have_jq )); then
    stable_run_count=$(jq -r '.stable_run_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)
    previous_mode=$(jq -r '.mode // "none"' "$STATE_FILE" 2>/dev/null || echo "none")
  else
    stable_run_count=$(grep -E '"stable_run_count"' "$STATE_FILE" 2>/dev/null | sed -E 's/.*: *([0-9]+).*/\1/' || echo 0)
    previous_mode=$(grep -E '"mode"' "$STATE_FILE" 2>/dev/null | sed -E 's/.*"mode"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || echo "none")
  fi
fi

# ---------------- Extract Stats ----------------
pre_mean="null"; pre_std="null"; post_mean="null"; post_std="null"
if [[ -f "$SAMPLES_FILE" ]]; then
  if (( _have_jq )); then
    if stats=$(_extract_stats_with_jq "$SAMPLES_FILE"); then
      pre_mean=$(echo "$stats" | awk '{print $1}')
      pre_std=$(echo "$stats"  | awk '{print $2}')
      post_mean=$(echo "$stats" | awk '{print $3}')
      post_std=$(echo "$stats"  | awk '{print $4}')
    fi
  else
    stats=$(_extract_stats_light "$SAMPLES_FILE" || true)
    pre_mean=$(echo "$stats" | awk '{print $1}')
    pre_std=$(echo "$stats"  | awk '{print $2}')
    post_mean=$(echo "$stats" | awk '{print $3}')
    post_std=$(echo "$stats"  | awk '{print $4}')
  fi
  pre_mean=$(_num_or_null "$pre_mean")
  pre_std=$(_num_or_null "$pre_std")
  post_mean=$(_num_or_null "$post_mean")
  post_std=$(_num_or_null "$post_std")
else
  (( QUIET == 0 )) && echo "[variance-state] WARN: samples file missing: $SAMPLES_FILE" >&2
fi

rsd_pre=$(_compute_rsd "$pre_mean" "$pre_std")
rsd_post=$(_compute_rsd "$post_mean" "$post_std")

# ---------------- Stability & Mode Selection ----------------
stable_this_run=0
if [[ "$rsd_pre" != "null" && "$rsd_post" != "null" ]]; then
  awk -v rp="$rsd_pre" -v rpo="$rsd_post" -v thr="$VARIANCE_RSD_THRESHOLD_WARN" '
    BEGIN{ exit ! (rp <= thr && rpo <= thr) }'
  if (( $? == 0 )); then
    stable_this_run=1
  fi
fi

promotion_notes=""
auto_mode="observe"

if [[ -n "$FORCE_MODE" ]]; then
  auto_mode="$FORCE_MODE"
  promotion_notes="forced_mode=$FORCE_MODE"
  if (( RESPECT_STREAK )); then
    if (( stable_this_run )); then
      (( stable_run_count++ ))
    else
      stable_run_count=0
    fi
    promotion_notes+=",streak_updated"
  else
    promotion_notes+=",streak_preserved"
  fi
else
  if (( stable_this_run )); then
    (( stable_run_count++ ))
    if (( stable_run_count >= VARIANCE_STREAK_REQUIRED + 1 )); then
      auto_mode="gate"
      promotion_notes="streak=${stable_run_count} (>= required+1) promoting to gate"
    elif (( stable_run_count >= VARIANCE_STREAK_REQUIRED )); then
      auto_mode="warn"
      promotion_notes="streak=${stable_run_count} (>= required) promoting to warn"
    else
      auto_mode="observe"
      promotion_notes="streak=${stable_run_count} (below threshold)"
    fi
  else
    if (( stable_run_count > 0 )); then
      promotion_notes="instability_detected (reset streak from ${stable_run_count} to 0)"
    else
      promotion_notes="instability_or_insufficient_data"
    fi
    stable_run_count=0
    auto_mode="observe"
  fi
fi

mode="$auto_mode"

# ---------------- Emit Extended JSON ----------------
iso=$(_now_iso)

mkdir -p "$(dirname "$OUT_JSON")" 2>/dev/null || true
mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true
cat >"$OUT_JSON" <<JSON
{
  "schema":"variance-state.v1",
  "generated_at":"$iso",
  "mode":"$mode",
  "rsd":{
    "pre":{"mean":$pre_mean,"stddev":$pre_std,"rsd":$([[ "$rsd_pre" == "null" ]] && echo null || echo "$rsd_pre")},
    "post":{"mean":$post_mean,"stddev":$post_std,"rsd":$([[ "$rsd_post" == "null" ]] && echo null || echo "$rsd_post")}
  },
  "thresholds":{
    "rsd_warn_max":$VARIANCE_RSD_THRESHOLD_WARN,
    "streak_required":$VARIANCE_STREAK_REQUIRED
  },
  "stable_run_count":$stable_run_count,
  "previous_mode":"$previous_mode",
  "promotion_notes":"$(printf '%s' "$promotion_notes" | _json_escape)",
  "sources":{
    "samples_file":"$( [[ -f "$SAMPLES_FILE" ]] && printf '%s' "$SAMPLES_FILE" || echo missing)",
    "state_file":"$STATE_FILE"
  }
}
JSON

# ---------------- Persist State (lightweight JSON) ----------------
cat >"$STATE_FILE" <<STATE
{"mode":"$mode","stable_run_count":$stable_run_count,"updated_at":"$iso"}
STATE

(( QUIET == 0 )) && echo "[variance-state] mode=$mode rsd_pre=$rsd_pre rsd_post=$rsd_post streak=$stable_run_count"

# ---------------- Badge JSON ----------------
if (( NO_BADGE == 0 )); then
  [[ -n "$BADGE_JSON" ]] || BADGE_JSON="$VARIANCE_BADGE_OUT"
  mkdir -p "$(dirname "$BADGE_JSON")" 2>/dev/null || true
  color="$VARIANCE_COLOR_OBSERVE"
  case "$mode" in
    warn) color="$VARIANCE_COLOR_WARN" ;;
    gate) color="$VARIANCE_COLOR_GATE" ;;
  esac
  cat >"$BADGE_JSON" <<BADGE
{"label":"variance","message":"$mode","color":"$color"}
BADGE
fi

exit 0
