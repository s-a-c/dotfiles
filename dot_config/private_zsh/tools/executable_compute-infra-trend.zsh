#!/usr/bin/env zsh
# compute-infra-trend.zsh
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
# Policy references:
#   - Development workflow guidelines (structure & reporting)
#   - Testing & performance standards (trend comparability)
#   - Security standards (no external network / deterministic parsing)
#
# Purpose:
#   Compare the current infra-health badge JSON against a previous version
#   to produce an explicit trend/drift artifact (infra-trend.json), enabling:
#     - CI gating on regression magnitude
#     - Historical dashboards
#     - Consistent semantic trend labels beyond raw color changes
#
# Inputs (default locations):
#   Current badge:  docs/badges/infra-health.json
#   Previous badge: (auto) git show HEAD~1:docs/badges/infra-health.json
#                    or provided via --previous <path>
#
# Output:
#   docs/badges/infra-trend.json (unless overridden) with fields:
#     {
#       "schemaVersion": 1,
#       "label": "infra-trend",
#       "previous": { "color": "...", "message": "..." },
#       "current":  { "color": "...", "message": "..." },
#       "delta": <int>,
#       "trend": "improved|improved-major|stable|regressed|regressed-major|new|missing",
#       "computedUTC": "2025-01-01T00:00:00Z",
#       "commit": "<HEAD SHA>",
#       "previousCommit": "<prev SHA or empty>",
#       "notes": "... (optional explanatory string)"
#     }
#
# Color Scoring (ordinal):
#   brightgreen=5, green=4, yellow=3, orange=2, red=1, lightgrey=0, (unknown -> 0)
#
# Trend Rules:
#   previous missing & current present -> trend = new
#   previous present & current missing -> trend = missing
#   delta >= +2  -> improved-major
#   delta == +1  -> improved
#   delta == 0   -> stable
#   delta == -1  -> regressed
#   delta <= -2  -> regressed-major
#
# Exit Codes:
#   0 success (no enforced failure)
#   1 usage / argument error
#   2 regression threshold exceeded (when --fail-on-regression applies)
#   3 major regression threshold exceeded (when --fail-on-major applies)
#
# Options:
#   --current <file>        Path to current infra-health.json
#   --previous <file>       Path to previous infra-health.json (skip git lookup)
#   --git-prev <rev>        Git rev (default HEAD~1) to read previous file from repository
#   --output <file>         Output trend JSON (default docs/badges/infra-trend.json)
#   --fail-on-regression    Non-zero exit if delta < 0
#   --fail-on-major         Non-zero exit if delta <= -2
#   --quiet                 Suppress non-error logs
#   --verbose               Extra debug logs
#   --help                  Show usage
#
# Safe Operation:
#   - Does not modify git history or working tree.
#   - Reads prior version via 'git show' if not explicitly provided.
#   - Works without jq (falls back to grep/sed parsing).
#
# Examples:
#   tools/compute-infra-trend.zsh
#   tools/compute-infra-trend.zsh --git-prev HEAD~2 --fail-on-major
#   tools/compute-infra-trend.zsh --previous /tmp/old.json --current docs/badges/infra-health.json
#
set -euo pipefail

############################
# Configuration / Defaults #
############################
CURRENT="docs/badges/infra-health.json"
PREVIOUS=""
GIT_PREV="HEAD~1"
OUTPUT="docs/badges/infra-trend.json"
FAIL_ON_REGRESSION=0
FAIL_ON_MAJOR=0
QUIET=0
VERBOSE=0

SCRIPT=${0:t}

############################
# Helpers                 #
############################
log() { ((QUIET)) || printf "[%s] %s\n" "$SCRIPT" "$*"; }
debug() { ((VERBOSE)) && printf "[%s][DBG] %s\n" "$SCRIPT" "$*"; }
err() { printf "[%s][ERR] %s\n" "$SCRIPT" "$*" >&2; }

usage() {
    sed -n '1,120p' "$0" | grep -E '^# ' | sed 's/^# //'
    cat <<EOF

Quick usage:
  $SCRIPT [--current file] [--previous file|--git-prev REV] [--output file]
          [--fail-on-regression] [--fail-on-major] [--quiet] [--verbose]

EOF
}

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

score_color() {
    local c="${1:l}"
    case "$c" in
    brightgreen) echo 5 ;;
    green) echo 4 ;;
    yellow) echo 3 ;;
    orange) echo 2 ;;
    red) echo 1 ;;
    lightgrey | lightgray | grey | gray) echo 0 ;;
    *) echo 0 ;;
    esac
}

extract_field() {
    # Args: file field
    local file="$1" field="$2" line
    [[ -f "$file" ]] || {
        echo ""
        return 0
    }
    if ((have_jq)); then
        jq -r --arg f "$field" '.[$f] // empty' "$file" 2>/dev/null || true
    else
        # naive fallback
        line=$(grep -o "\"$field\":\"[^\"]*\"" "$file" | head -1 || true)
        echo "${line#*\":\"}" | sed 's/"$//'
    fi
}

extract_color() {
    local file="$1"
    if ((have_jq)); then
        jq -r '.color // empty' "$file" 2>/dev/null || true
    else
        grep -o '"color":"[^"]*"' "$file" | head -1 | sed 's/.*"color":"\([^"]*\)".*/\1/' || true
    fi
}

extract_message() {
    local file="$1"
    if ((have_jq)); then
        jq -r '.message // empty' "$file" 2>/dev/null || true
    else
        grep -o '"message":"[^"]*"' "$file" | head -1 | sed 's/.*"message":"\([^"]*\)".*/\1/' || true
    fi
}

read_previous_from_git() {
    local rev="$1" path="$2"
    git show "${rev}:${path}" 2>/dev/null || return 1
}

write_json() {
    local prevColor="$1" prevMsg="$2" curColor="$3" curMsg="$4" delta="$5" trend="$6" notes="$7" prevSha="$8" curSha="$9"
    local now
    now=$(date -u +%FT%TZ 2>/dev/null || date)
    mkdir -p "${OUTPUT:h}" || true
    cat >"$OUTPUT".tmp <<EOF
{
  "schemaVersion": 1,
  "label": "infra-trend",
  "previous": { "color": "${prevColor}", "message": "${prevMsg}" },
  "current":  { "color": "${curColor}", "message": "${curMsg}" },
  "delta": ${delta},
  "trend": "${trend}",
  "computedUTC": "${now}",
  "previousCommit": "${prevSha}",
  "commit": "${curSha}",
  "notes": "${notes}"
}
EOF
    mv "$OUTPUT".tmp "$OUTPUT"
    log "Wrote trend: $OUTPUT (trend=${trend} delta=${delta})"
}

############################
# Argument Parsing         #
############################
while [[ $# -gt 0 ]]; do
    case "$1" in
    --current)
        CURRENT="$2"
        shift 2
        ;;
    --previous)
        PREVIOUS="$2"
        shift 2
        ;;
    --git-prev)
        GIT_PREV="$2"
        shift 2
        ;;
    --output)
        OUTPUT="$2"
        shift 2
        ;;
    --fail-on-regression)
        FAIL_ON_REGRESSION=1
        shift
        ;;
    --fail-on-major)
        FAIL_ON_MAJOR=1
        shift
        ;;
    --quiet)
        QUIET=1
        shift
        ;;
    --verbose)
        VERBOSE=1
        shift
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        err "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
done

############################
# Input Validation         #
############################
if [[ ! -f "$CURRENT" ]]; then
    err "Current infra badge not found: $CURRENT"
    # If current missing and previous also missing, produce a 'missing' artifact if feasible
    if [[ -z "$PREVIOUS" ]]; then
        log "No current file; producing placeholder trend (missing)."
        write_json "" "" "" "" 0 "missing" "current badge absent" "" ""
        exit 0
    else
        exit 1
    fi
fi

# Resolve previous content
prev_tmp=""
if [[ -n "$PREVIOUS" ]]; then
    if [[ -f "$PREVIOUS" ]]; then
        prev_tmp="$PREVIOUS"
    else
        err "Specified previous file not found: $PREVIOUS"
        exit 1
    fi
else
    # Try git show
    if read_previous_from_git "$GIT_PREV" "$CURRENT" >/dev/null; then
        prev_tmp=$(mktemp)
        if ! read_previous_from_git "$GIT_PREV" "$CURRENT" >"$prev_tmp" 2>/dev/null; then
            rm -f "$prev_tmp"
            prev_tmp=""
        fi
    else
        debug "git show ${GIT_PREV}:${CURRENT} failed (treat as no previous)."
        prev_tmp=""
    fi
fi

############################
# Extract current fields   #
############################
curColor=$(extract_color "$CURRENT")
curMsg=$(extract_message "$CURRENT")

[[ -z "$curColor" ]] && curColor="lightgrey"
[[ -z "$curMsg" ]] && curMsg="(no-message)"

curScore=$(score_color "$curColor")

############################
# Extract previous fields  #
############################
prevColor=""
prevMsg=""
prevScore=0
trend=""
delta=0
notes=""
prevSha=""
curSha=""

# Commit SHAs (best effort)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    curSha=$(git rev-parse HEAD 2>/dev/null || echo "")
    if git rev-parse "$GIT_PREV" >/dev/null 2>&1; then
        prevSha=$(git rev-parse "$GIT_PREV" 2>/dev/null || echo "")
    fi
fi

if [[ -n "$prev_tmp" && -f "$prev_tmp" ]]; then
    prevColor=$(extract_color "$prev_tmp")
    prevMsg=$(extract_message "$prev_tmp")
    [[ -z "$prevColor" ]] && prevColor="lightgrey"
    [[ -z "$prevMsg" ]] && prevMsg="(no-message)"
    prevScore=$(score_color "$prevColor")
    delta=$((curScore - prevScore))
    # Determine trend based on rules
    if [[ "$prevColor" == "" && "$curColor" != "" ]]; then
        trend="new"
    elif [[ "$prevColor" != "" && "$curColor" == "" ]]; then
        trend="missing"
    else
        if ((delta >= 2)); then
            trend="improved-major"
        elif ((delta == 1)); then
            trend="improved"
        elif ((delta == 0)); then
            trend="stable"
        elif ((delta == -1)); then
            trend="regressed"
        elif ((delta <= -2)); then
            trend="regressed-major"
        fi
    fi
    notes="prevScore=${prevScore} curScore=${curScore}"
else
    # No previous data
    prevColor=""
    prevMsg=""
    prevScore=0
    trend="new"
    delta=$curScore
    notes="no-previous-reference"
fi

############################
# Emit JSON Artifact       #
############################
write_json "$prevColor" "$prevMsg" "$curColor" "$curMsg" "$delta" "$trend" "$notes" "$prevSha" "$curSha"

############################
# Optional Failure Modes   #
############################
if ((FAIL_ON_MAJOR)) && [[ "$trend" == "regressed-major" ]]; then
    err "Major regression detected (delta=$delta)."
    exit 3
fi

if ((FAIL_ON_REGRESSION)) && [[ "$trend" == "regressed" || "$trend" == "regressed-major" ]]; then
    err "Regression detected (trend=$trend delta=$delta)."
    exit 2
fi

exit 0
