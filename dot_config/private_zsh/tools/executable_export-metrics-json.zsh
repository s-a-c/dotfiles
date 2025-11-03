#!/usr/bin/env zsh
# export-metrics-json.zsh
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Purpose:
#   Produce a consolidated machine‑readable metrics JSON aggregating:
#     - Infrastructure health badge (infra-health.json)
#     - Infrastructure trend (infra-trend.json)
#     - Security severity & counts (security.json)
#     - Hooks integrity (hooks.json)
#     - Structure layout status (structure.json)
#     - Performance (perf.json)
#     - Optional summary (summary.json) to harvest hashes / mtimes
#
# Output:
#   A single JSON file (default: docs/badges/metrics.json) with:
#     {
#       "schemaVersion": 1,
#       "generatedUTC": "...",
#       "sources": {...},
#       "infra": {...},
#       "security": {...},
#       "performance": {...},
#       "structure": {...},
#       "hooks": {...},
#       "hashes": {...},        # if discoverable
#       "mtimes": {...},        # if discoverable
#       "scores": {...},        # normalized numeric scores
#       "status": {...}         # high-level classification & overall gate
#     }
#
# Rationale / Policy:
#   - Single canonical metrics artifact simplifies downstream dashboards & diff-based monitoring.
#   - Encourages transparent scoring (no hidden weighting).
#   - Aligns with performance & security documentation standards (structured, reproducible output).
#
# Scoring Heuristics:
#   Color → ordinal mapping (for comparative trending):
#     brightgreen=5, green=4, yellow=3, orange=2, red=1, lightgrey=0, (unknown / empty = 0)
#   Security severity weight (highest present):
#     critical=5, high=4, moderate=3, informational=2, none=4 (treated equal to green baseline), unknown=1
#   Infra trend classification (trend field):
#     improved-major=+2, improved=+1, stable/new=0, regressed=-1, regressed-major=-2, missing/unknown=0
#
# Exit Codes:
#   0 success
#   1 usage / argument error
#   2 security critical (if --fail-on-critical)
#   3 major infra regression (if --fail-on-major-regression and trend=regressed-major)
#   4 generic gating failure (aggregate gate fail)
#
# Options:
#   --output <path>                  Set output file (default docs/badges/metrics.json)
#   --summary <path>                 Path to summary.json (default docs/badges/summary.json)
#   --dir <path>                     Badge directory root (default docs/badges)
#   --fail-on-critical               Non-zero exit if security severity = critical
#   --fail-on-major-regression       Non-zero exit if infra trend regressed-major
#   --overall-gate                   Enable aggregate gating rule (see rules below)
#   --pretty                         Pretty-print JSON (if jq available)
#   --verbose                        Verbose logging
#   --quiet                          Suppress non-error logs
#   --dry-run                        Print JSON to stdout only (do not write file)
#   --help                           Show usage
#
# Aggregate Gate (when --overall-gate):
#   Fails if:
#     - security severity critical or
#     - infra trend regressed-major or
#     - infra color red or
#     - hooks status enforced-fail / fail-missing or
#     - structure color red
#
# Dependencies:
#   - jq optional (enhances parsing & pretty output). Pure POSIX-ish fallbacks provided via grep/sed/awk.
#
# Safe Operation:
#   - Read-only with respect to existing badge files.
#   - Creates parent directories for the output if missing.
#
# Future Enhancements:
#   - Historical ring buffer / append-only log.
#   - Weighted composite index scoring for SLA dashboards.
#   - Emission of delta vs last metrics.json (similar to infra-trend for all components).
#
set -euo pipefail

########################
# Default Configuration
########################
BADGE_DIR="docs/badges"
OUTPUT="docs/badges/metrics.json"
SUMMARY="docs/badges/summary.json"
FAIL_ON_CRITICAL=0
FAIL_ON_MAJOR_REGRESSION=0
OVERALL_GATE=0
PRETTY=0
VERBOSE=0
QUIET=0
DRY_RUN=0

SCRIPT=${0:t}

log() { ((QUIET)) || printf "[%s] %s\n" "$SCRIPT" "$*"; }
vlog() { ((VERBOSE)) && log "$@"; }
err() { printf "[%s][ERROR] %s\n" "$SCRIPT" "$*" >&2; }

usage() {
    grep -E '^# ' "$0" | sed 's/^# //'
    exit 0
}

have_jq() { command -v jq >/dev/null 2>&1; }

color_score() {
    local c="${1:l}"
    case "$c" in
    brightgreen) echo 5 ;;
    green) echo 4 ;;
    yellow) echo 3 ;;
    orange) echo 2 ;;
    red) echo 1 ;;
    lightgrey | lightgray | grey | gray | "") echo 0 ;;
    *) echo 0 ;;
    esac
}

severity_score() {
    # Map aggregated severity classification
    local s="${1:l}"
    case "$s" in
    critical) echo 5 ;;
    high) echo 4 ;;
    moderate) echo 3 ;;
    informational) echo 2 ;;
    none) echo 4 ;; # treat 'none' as healthy baseline
    unknown | "") echo 1 ;;
    *) echo 1 ;;
    esac
}

trend_delta() {
    local t="${1:l}"
    case "$t" in
    improved-major) echo 2 ;;
    improved) echo 1 ;;
    stable | new) echo 0 ;;
    regressed) echo -1 ;;
    regressed-major) echo -2 ;;
    missing | unknown | "") echo 0 ;;
    *) echo 0 ;;
    esac
}

json_field() {
    # Args: file field
    local file="$1" field="$2"
    [[ -f "$file" ]] || {
        echo ""
        return 0
    }
    if have_jq; then
        jq -r --arg f "$field" '.[$f] // empty' "$file" 2>/dev/null || echo ""
    else
        grep -o "\"$field\":\"[^\"]*\"" "$file" 2>/dev/null | head -1 | sed 's/.*"'"$field"'":"\([^"]*\)".*/\1/' || true
    fi
}

json_color() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo ""
        return 0
    }
    if have_jq; then
        jq -r '.color // empty' "$file" 2>/dev/null || echo ""
    else
        grep -o '"color":"[^"]*"' "$file" | head -1 | sed 's/.*"color":"\([^"]*\)".*/\1/'
    fi
}

json_message() {
    local file="$1"
    [[ -f "$file" ]] || {
        echo ""
        return 0
    }
    if have_jq; then
        jq -r '.message // empty' "$file" 2>/dev/null || echo ""
    else
        grep -o '"message":"[^"]*"' "$file" | head -1 | sed 's/.*"message":"\([^"]*\)".*/\1/'
    fi
}

json_numeric() {
    local file="$1" field="$2"
    [[ -f "$file" ]] || {
        echo 0
        return 0
    }
    if have_jq; then
        jq -r --arg f "$field" '.[$f] // 0' "$file" 2>/dev/null || echo 0
    else
        local line
        line=$(grep -o "\"$field\":[0-9]\+" "$file" 2>/dev/null | head -1 || true)
        echo "${line##*:}" | tr -dc '0-9' || echo 0
    fi
}

hash_meta_from_summary() {
    # Emit a JSON fragment for hashes or mtimes if present in summary
    local type="$1" # hashes | mtimes
    local file="$SUMMARY"
    [[ -f "$file" ]] || {
        echo "{}"
        return 0
    }
    if have_jq; then
        jq -r --arg t "$type" '.[$t] // {}' "$file" 2>/dev/null || echo "{}"
    else
        # naive extraction: build object manually
        local frag keys
        frag="{"
        keys=$(grep -o "\"$type\":{\"[^\}]*\"" "$file" | head -1 || true)
        if [[ -n "$keys" ]]; then
            # Extract inner content
            frag=$(echo "$keys" | sed "s/\"$type\"://")
        else
            frag="{}"
        fi
        echo "$frag"
    fi
}

################
# Arg Parsing
################
while [[ $# -gt 0 ]]; do
    case "$1" in
    --output)
        OUTPUT="$2"
        shift 2
        ;;
    --summary)
        SUMMARY="$2"
        shift 2
        ;;
    --dir)
        BADGE_DIR="$2"
        shift 2
        ;;
    --fail-on-critical)
        FAIL_ON_CRITICAL=1
        shift
        ;;
    --fail-on-major-regression)
        FAIL_ON_MAJOR_REGRESSION=1
        shift
        ;;
    --overall-gate)
        OVERALL_GATE=1
        shift
        ;;
    --pretty)
        PRETTY=1
        shift
        ;;
    --verbose)
        VERBOSE=1
        shift
        ;;
    --quiet)
        QUIET=1
        shift
        ;;
    --dry-run)
        DRY_RUN=1
        shift
        ;;
    --help | -h) usage ;;
    *)
        err "Unknown argument: $1"
        exit 1
        ;;
    esac
done

mkdir -p "${OUTPUT:h}" || true

################
# Source Files
################
PERF="${BADGE_DIR}/perf.json"
STRUCT="${BADGE_DIR}/structure.json"
HOOKS="${BADGE_DIR}/hooks.json"
SEC="${BADGE_DIR}/security.json"
INFRA="${BADGE_DIR}/infra-health.json"
INFRA_TREND="${BADGE_DIR}/infra-trend.json"

################
# Extract Data
################
perf_color=$(json_color "$PERF")
perf_msg=$(json_message "$PERF")

struct_color=$(json_color "$STRUCT")
struct_msg=$(json_message "$STRUCT")

hooks_color=$(json_color "$HOOKS")
hooks_msg=$(json_message "$HOOKS") # message doubles as status

sec_color=$(json_color "$SEC")
sec_msg_raw=$(json_message "$SEC")
sec_severity=$(json_field "$SEC" "severity")
sec_high=$(json_numeric "$SEC" "high")
sec_medium=$(json_numeric "$SEC" "medium")
sec_low=$(json_numeric "$SEC" "low")

infra_color=$(json_color "$INFRA")
infra_msg=$(json_message "$INFRA")

trend_value=$(json_field "$INFRA_TREND" "trend")
trend_prev_color=$(json_field "$INFRA_TREND" "previousColor") # may not exist (legacy)
trend_prev_msg=$(json_field "$INFRA_TREND" "previousMessage") # may not exist
if [[ -z "$trend_prev_color" ]] && [[ -f "$INFRA_TREND" ]] && have_jq; then
    trend_prev_color=$(jq -r '.previous.color // empty' "$INFRA_TREND" 2>/dev/null || echo "")
    trend_prev_msg=$(jq -r '.previous.message // empty' "$INFRA_TREND" 2>/dev/null || echo "")
fi

trend_current_color=$(json_field "$INFRA_TREND" "currentColor")
if [[ -z "$trend_current_color" ]] && [[ -f "$INFRA_TREND" ]] && have_jq; then
    trend_current_color=$(jq -r '.current.color // empty' "$INFRA_TREND" 2>/dev/null || echo "")
fi

trend_delta_val=$(trend_delta "$trend_value")

# Fallback: if trend file missing, treat as unknown stable baseline
[[ -z "$trend_value" ]] && trend_value="unknown"

################
# Scoring
################
score_perf=$(color_score "$perf_color")
score_struct=$(color_score "$struct_color")
score_hooks=$(color_score "$hooks_color")
score_security=$(severity_score "$sec_severity")
score_security_color=$(color_score "$sec_color")
score_infra=$(color_score "$infra_color")
score_trend=$trend_delta_val # already mapped

################
# Hash & Mtime (from summary if present)
################
hashes=$(hash_meta_from_summary "hashes")
mtimes=$(hash_meta_from_summary "mtimes")

################
# Aggregate Classification
################
overall_state="ok"

# Security gating
if [[ "${sec_severity:l}" == "critical" ]]; then
    [[ $FAIL_ON_CRITICAL -eq 1 ]] && overall_state="security-critical"
fi

# Trend gating
if [[ "${trend_value:l}" == "regressed-major" ]]; then
    [[ $FAIL_ON_MAJOR_REGRESSION -eq 1 ]] && overall_state="infra-major-regression"
fi

# Overall composite gating (if enabled)
if [[ $OVERALL_GATE -eq 1 && "$overall_state" == "ok" ]]; then
    if [[ "${sec_severity:l}" == "critical" ]] ||
        [[ "${trend_value:l}" == "regressed-major" ]] ||
        [[ "${infra_color:l}" == "red" ]] ||
        [[ "${hooks_msg:l}" == "enforced-fail" || "${hooks_msg:l}" == "fail-missing" ]] ||
        [[ "${struct_color:l}" == "red" ]]; then
        overall_state="gate-fail"
    fi
fi

################
# Build JSON
################
timestamp=$(date -u +%FT%TZ 2>/dev/null || date)

build_raw_json() {
    cat <<EOF
{
  "schemaVersion": 1,
  "generatedUTC": "$timestamp",
  "sources": {
    "perf": "$PERF",
    "structure": "$STRUCT",
    "hooks": "$HOOKS",
    "security": "$SEC",
    "infraHealth": "$INFRA",
    "infraTrend": "$INFRA_TREND",
    "summary": "$SUMMARY"
  },
  "infra": {
    "color": "${infra_color}",
    "message": "${infra_msg}",
    "trend": "${trend_value}",
    "trendDelta": ${trend_delta_val},
    "previousColor": "${trend_prev_color}",
    "previousMessage": "${trend_prev_msg}",
    "currentTrendColor": "${trend_current_color}"
  },
  "security": {
    "color": "${sec_color}",
    "message": "${sec_msg_raw}",
    "severity": "${sec_severity}",
    "high": ${sec_high},
    "medium": ${sec_medium},
    "low": ${sec_low}
  },
  "performance": {
    "color": "${perf_color}",
    "message": "${perf_msg}"
  },
  "structure": {
    "color": "${struct_color}",
    "message": "${struct_msg}"
  },
  "hooks": {
    "color": "${hooks_color}",
    "status": "${hooks_msg}"
  },
  "hashes": ${hashes},
  "mtimes": ${mtimes},
  "scores": {
    "performance": ${score_perf},
    "structure": ${score_struct},
    "hooks": ${score_hooks},
    "securitySeverity": ${score_security},
    "securityColor": ${score_security_color},
    "infra": ${score_infra},
    "infraTrendDelta": ${score_trend}
  },
  "status": {
    "overall": "${overall_state}",
    "failOnCritical": ${FAIL_ON_CRITICAL},
    "failOnMajorRegression": ${FAIL_ON_MAJOR_REGRESSION},
    "overallGate": ${OVERALL_GATE}
  }
}
EOF
}

raw_json=$(build_raw_json)

if ((PRETTY)) && have_jq; then
    raw_json=$(printf "%s" "$raw_json" | jq '.')
fi

if ((DRY_RUN)); then
    printf "%s\n" "$raw_json"
else
    printf "%s\n" "$raw_json" >"$OUTPUT"
    log "Wrote metrics: $OUTPUT"
fi

################
# Exit Logic
################
if [[ "$overall_state" == "security-critical" ]]; then
    exit 2
elif [[ "$overall_state" == "infra-major-regression" ]]; then
    exit 3
elif [[ "$overall_state" == "gate-fail" ]]; then
    exit 4
fi

exit 0
