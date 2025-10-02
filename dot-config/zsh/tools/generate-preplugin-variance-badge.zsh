#!/usr/bin/env zsh
# ============================================================================
# generate-preplugin-variance-badge.zsh
#
# Purpose:
#   Generate a Shields.io JSON badge summarizing pre-plugin startup variance
#   stability (RSD) and the currently recommended regression guard tightening
#   based on multiple Stage 3 baseline artifacts.
#
# Data Sources:
#   Relies on tools/preplugin-variance-eval.zsh which aggregates
#   preplugin-baseline-stage3*.json files (schema: preplugin-baseline.v2).
#
# Outputs (prefers redesignv2 layout; falls back to legacy):
#   Preferred:
#     docs/redesignv2/artifacts/metrics/preplugin-variance-eval.json
#     docs/redesignv2/artifacts/badges/preplugin-variance.json
#   Legacy fallback:
#     docs/redesign/metrics/preplugin-variance-eval.json
#     docs/redesign/badges/preplugin-variance.json
#
# Badge JSON Example:
#   {
#     "schemaVersion":1,
#     "label":"preplugin variance",
#     "message":"rsd=0.041 guard=+5% (stable)",
#     "color":"green"
#   }
#
# Color Heuristic:
#   guard 5%  -> green
#   guard 7%  -> yellow
#   guard 10% -> red if rsd > 0.08, else orange (moderate) if rsd <=0.08
#   no data   -> lightgrey
#
# Exit Codes:
#   0 success (even if no data)
#   2 evaluator failure (only if --fail-on-error)
#
# Options:
#   --metrics-dir <dir>     Override metrics directory root
#   --badges-dir  <dir>     Override badges directory root
#   --eval-script <path>    Path to preplugin-variance-eval.zsh (auto-detect)
#   --pattern <glob>        Glob for stage3 files (default: preplugin-baseline-stage3*.json)
#   --label <text>          Badge label (default: "preplugin variance")
#   --badge <file>          Explicit badge output path
#   --eval-json <file>      Explicit evaluation JSON output path
#   --fail-on-error         Non-zero exit when evaluation fails
#   --quiet                 Suppress stderr status lines
#   -h|--help               Show help
#
# Dependencies:
#   - zsh, awk, grep, sed, date
#   - jq (optional; fallback grep parsing used if absent)
#
# Style:
#   - 4 space indentation
#   - Defensive parsing (NULL-safe)
#
# ============================================================================

set -euo pipefail

# Resilient script directory resolution (avoids direct ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
    SCRIPT_DIR="$(zf::script_dir "${(%):-%N}")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
    SCRIPT_DIR="$(resolve_script_dir "${(%):-%N}")"
else
    _gpvb_src="${(%):-%N}"
    [[ -z "$_gpvb_src" ]] && _gpvb_src="$0"
    # Minimal symlink resolve (one hop)
    if [[ -h "$_gpvb_src" ]]; then
        _gpvb_link="$(readlink "$_gpvb_src" 2>/dev/null || true)"
        [[ -n "$_gpvb_link" ]] && _gpvb_src="$_gpvb_link"
        unset _gpvb_link
    fi
    SCRIPT_DIR="${_gpvb_src:h}"
    unset _gpvb_src
fi
ROOT_DIR="${SCRIPT_DIR:h}"             # tools -> zsh root
PREFERRED_ROOT="${ROOT_DIR}/docs/redesignv2/artifacts"
LEGACY_ROOT="${ROOT_DIR}/docs/redesign"

# ----------------------------- Defaults ---------------------------------------
PATTERN="preplugin-baseline-stage3*.json"
LABEL="preplugin variance"
FAIL_ON_ERROR=0
QUIET=0
EVAL_SCRIPT_DEFAULT="${SCRIPT_DIR}/preplugin-variance-eval.zsh"
EVAL_SCRIPT="$EVAL_SCRIPT_DEFAULT"

# Determine preferred dirs
if [[ -d "${PREFERRED_ROOT}/metrics" ]]; then
    METRICS_DIR="${PREFERRED_ROOT}/metrics"
    BADGES_DIR="${PREFERRED_ROOT}/badges"
else
    METRICS_DIR="${LEGACY_ROOT}/metrics"
    BADGES_DIR="${LEGACY_ROOT}/badges"
fi

BADGE_PATH=""
EVAL_JSON_OUT=""
# ----------------------------- Helpers ----------------------------------------
log() { (( QUIET )) || printf '%s\n' "[variance-badge] $*" >&2; }
warn() { printf '%s\n' "[variance-badge][WARN] $*" >&2; }
err()  { printf '%s\n' "[variance-badge][ERROR] $*" >&2; }

usage() {
    sed -n '1,120p' "$0"
    exit 0
}

json_escape() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# ----------------------------- Args -------------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --metrics-dir) shift || { err "Missing value after --metrics-dir"; exit 2; }; METRICS_DIR="$2"; shift ;;
        --badges-dir)  shift || { err "Missing value after --badges-dir"; exit 2; }; BADGES_DIR="$2"; shift ;;
        --pattern)     shift || { err "Missing value after --pattern"; exit 2; }; PATTERN="$2"; shift ;;
        --label)       shift || { err "Missing value after --label"; exit 2; }; LABEL="$2"; shift ;;
        --eval-script) shift || { err "Missing value after --eval-script"; exit 2; }; EVAL_SCRIPT="$2"; shift ;;
        --badge)       shift || { err "Missing value after --badge"; exit 2; }; BADGE_PATH="$2"; shift ;;
        --eval-json)   shift || { err "Missing value after --eval-json"; exit 2; }; EVAL_JSON_OUT="$2"; shift ;;
        --fail-on-error) FAIL_ON_ERROR=1; shift ;;
        --quiet)       QUIET=1; shift ;;
        -h|--help)     usage ;;
        *) err "Unknown argument: $1"; usage ;;
    esac
done

mkdir -p "$METRICS_DIR" "$BADGES_DIR" 2>/dev/null || true

if [[ -z "$BADGE_PATH" ]]; then
    BADGE_PATH="${BADGES_DIR}/preplugin-variance.json"
fi
if [[ -z "$EVAL_JSON_OUT" ]]; then
    EVAL_JSON_OUT="${METRICS_DIR}/preplugin-variance-eval.json"
fi

# Resolve evaluator script if missing
if [[ ! -x "$EVAL_SCRIPT" ]]; then
    # Attempt sibling resolution (in case of alternate layout)
    if [[ -x "${SCRIPT_DIR}/../tools/preplugin-variance-eval.zsh" ]]; then
        EVAL_SCRIPT="${SCRIPT_DIR}/../tools/preplugin-variance-eval.zsh"
    fi
fi

if [[ ! -x "$EVAL_SCRIPT" ]]; then
    warn "Evaluator script not found/executable: $EVAL_SCRIPT"
    printf '{"schemaVersion":1,"label":"%s","message":"no-eval-script","color":"lightgrey"}\n' "$(printf '%s' "$LABEL" | json_escape)" > "$BADGE_PATH"
    exit 0
fi

# ----------------------------- Discovery --------------------------------------
setopt nullglob 2>/dev/null || true
stage3_files=("$METRICS_DIR"/$PATTERN(N))
unsetopt nullglob 2>/dev/null || true
file_count=${#stage3_files[@]}

if (( file_count == 0 )); then
    log "No Stage 3 baseline files (pattern=$PATTERN dir=$METRICS_DIR)"
    printf '{"schemaVersion":1,"label":"%s","message":"no-data","color":"lightgrey"}\n' "$(printf '%s' "$LABEL" | json_escape)" > "$BADGE_PATH"
    exit 0
fi

log "Found $file_count stage3 artifact(s). Running variance evaluation."

# ----------------------------- Run Evaluator ----------------------------------
# We allow evaluation failure to degrade gracefully.
EVAL_JSON="$("$EVAL_SCRIPT" --dir "$METRICS_DIR" --glob "$PATTERN" --json 2>/dev/null || true)"

if [[ -z "$EVAL_JSON" ]] || ! printf '%s' "$EVAL_JSON" | grep -q '"schema"[[:space:]]*:[[:space:]]*"preplugin-variance-eval.v1"'; then
    err "Evaluator did not produce expected JSON schema."
    if (( FAIL_ON_ERROR )); then
        printf '{"schemaVersion":1,"label":"%s","message":"eval-error","color":"red"}\n' "$(printf '%s' "$LABEL" | json_escape)" > "$BADGE_PATH"
        exit 2
    else
        printf '{"schemaVersion":1,"label":"%s","message":"eval-error","color":"lightgrey"}\n' "$(printf '%s' "$LABEL" | json_escape)" > "$BADGE_PATH"
        exit 0
    fi
fi

printf '%s\n' "$EVAL_JSON" > "$EVAL_JSON_OUT"

# ----------------------------- JSON Field Extraction --------------------------
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

extract_field() {
    local key="$1"
    if (( have_jq )); then
        jq -r --arg k "$key" '.[$k]' 2>/dev/null <<< "$EVAL_JSON" | sed 's/null//'
    else
        printf '%s\n' "$EVAL_JSON" | grep -E "\"$key\"" | head -1 | \
        sed -E 's/.*"'$key'"[[:space:]]*:[[:space:]]*//; s/[",]$//' | tr -d '"'
    fi
}

RSD="$(extract_field aggregate_rsd | sed -E 's/[^0-9.].*//')"
GUARD_PCT="$(extract_field recommended_guard_pct | tr -cd '0-9')"
TOTAL_SAMPLES="$(extract_field total_samples | tr -cd '0-9')"
FILES_ANALYZED="$(extract_field analyzed_files | tr -cd '0-9')"
BAND="$(extract_field rsd_band | sed -E 's/[^a-zA-Z0-9_-]//g')"

# Sanity defaults if parsing failed
[[ -z "$RSD" ]] && RSD="0"
[[ -z "$GUARD_PCT" ]] && GUARD_PCT="10"
[[ -z "$BAND" ]] && BAND="unknown"

# Normalize RSD display to 3 decimals
RSD_FMT=$(awk -v r="$RSD" 'BEGIN{ if (r=="") r=0; printf "%.3f", r }')

# ----------------------------- Color Logic ------------------------------------
color="lightgrey"
case "$GUARD_PCT" in
    5) color="green" ;;
    7) color="yellow" ;;
    10)
        # Distinguish moderate vs noisy
        if awk -v r="$RSD" 'BEGIN{exit !(r>0.08)}'; then
        color="red"
        else
        color="orange"
        fi
        ;;
    *) color="lightgrey" ;;
esac

message="rsd=${RSD_FMT} guard=+${GUARD_PCT}%"
if [[ -n "$BAND" ]]; then
    message="${message} (${BAND})"
fi

# Escape JSON
label_esc="$(printf '%s' "$LABEL" | json_escape)"
msg_esc="$(printf '%s' "$message" | json_escape)"

# ----------------------------- Write Badge ------------------------------------
mkdir -p "$(dirname "$BADGE_PATH")" 2>/dev/null || true
{
    printf '{'
    printf '"schemaVersion":1,'
    printf '"label":"%s",' "$label_esc"
    printf '"message":"%s",' "$msg_esc"
    printf '"color":"%s"' "$color"
    printf '}\n'
} > "$BADGE_PATH"

log "Badge written: $BADGE_PATH (files=$FILES_ANALYZED samples=$TOTAL_SAMPLES rsd=$RSD_FMT guard=+${GUARD_PCT}%% color=$color)"

exit 0
