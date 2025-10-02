#!/usr/bin/env zsh
# generate-badges-summary.zsh
# Combine perf + structure badge JSONs (and optionally others) into a single summary JSON.
# Fields:
#     generated_utc, badges: { perf:{message,color}, structure:{message,color}, hooks:{message,color}, security:{message,color}, infra:{message,color}, infra_trend:{message,color} }
# Non-fatal if individual badge files missing.
# Usage: tools/generate-badges-summary.zsh [--output docs/badges/summary.json]
set -euo pipefail
OUT=docs/badges/summary.json
while [[ $# -gt 0 ]]; do
    case $1 in
        --output) OUT=$2; shift 2 ;;
        -h|--help)
            sed -n '1,40p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done
mkdir -p "${OUT:h}" || true
read_badge(){
    local file=$1
    local key=$2
    if [[ -f $file ]]; then
        if command -v jq >/dev/null 2>&1; then
            local msg color
            msg=$(jq -r '.message // empty' "$file" 2>/dev/null)
            color=$(jq -r '.color // empty' "$file" 2>/dev/null)
            [[ -n $msg || -n $color ]] && echo "\"$key\":{\"message\":\"$msg\",\"color\":\"$color\"}" && return 0
        else
            local line; line=$(cat "$file")
            local msg color
            msg=$(echo "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
            color=$(echo "$line" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p')
            [[ -n $msg || -n $color ]] && echo "\"$key\":{\"message\":\"$msg\",\"color\":\"$color\"}" && return 0
        fi
    fi
    return 1
}
entries=()
perf_entry=$(read_badge docs/badges/perf.json perf || true)
[[ -n ${perf_entry:-} ]] && entries+=$perf_entry
perf_ledger_entry=$(read_badge docs/badges/perf-ledger.json perf_ledger || true)
[[ -n ${perf_ledger_entry:-} ]] && entries+=$perf_ledger_entry
perf_drift_entry=$(read_badge docs/badges/perf-drift.json perf_drift || true)
[[ -n ${perf_drift_entry:-} ]] && entries+=$perf_drift_entry
struct_entry=$(read_badge docs/badges/structure.json structure || true)
[[ -n ${struct_entry:-} ]] && entries+=$struct_entry
hooks_entry=$(read_badge docs/badges/hooks.json hooks || true)
[[ -n ${hooks_entry:-} ]] && entries+=$hooks_entry
infra_entry=$(read_badge docs/badges/infra-health.json infra || true)
[[ -n ${infra_entry:-} ]] && entries+=$infra_entry
security_entry=$(read_badge docs/badges/security.json security || true)
[[ -n ${security_entry:-} ]] && entries+=$security_entry
# Derive infra_trend:
#   Preference order:
#     1. docs/badges/infra-trend.json (computed drift artifact)
#     2. Fallback heuristic from infra-health color (legacy behavior)
if [[ -f docs/badges/infra-trend.json ]]; then
    # Parse structured trend artifact
    if command -v jq >/dev/null 2>&1; then
        infra_trend_raw=$(jq -r '.trend // empty' docs/badges/infra-trend.json 2>/dev/null)
    else
        line=$(cat docs/badges/infra-trend.json 2>/dev/null)
        infra_trend_raw=$(echo "$line" | sed -n 's/.*"trend":"\([^"]*\)".*/\1/p')
    fi
    [[ -z "$infra_trend_raw" ]] && infra_trend_raw="unknown"
    # Map trend -> color
    case "$infra_trend_raw" in
        improved-major) trend_color="brightgreen" ;;
        improved)       trend_color="green" ;;
        stable|new)     trend_color="green" ;;
        regressed)      trend_color="orange" ;;
        regressed-major)trend_color="red" ;;
        missing)        trend_color="lightgrey" ;;
        *)              trend_color="lightgrey" ;;
    esac
    infra_trend_entry="\"infra_trend\":{\"message\":\"$infra_trend_raw\",\"color\":\"$trend_color\"}"
    entries+=$infra_trend_entry
elif [[ -f docs/badges/infra-health.json ]]; then
    # Heuristic fallback based on infra-health color
    if command -v jq >/dev/null 2>&1; then
        infra_color=$(jq -r '.color // empty' docs/badges/infra-health.json 2>/dev/null)
    else
        line=$(cat docs/badges/infra-health.json 2>/dev/null)
        infra_color=$(echo "$line" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p')
    fi
    trend="unknown"
    case "$infra_color" in
        brightgreen|green) trend="stable" ;;
        yellow) trend="watch" ;;
        orange) trend="degraded" ;;
        red) trend="critical" ;;
        lightgrey|"") trend="unknown" ;;
        *) trend="unknown" ;;
    esac
    infra_trend_entry="\"infra_trend\":{\"message\":\"$trend\",\"color\":\"${infra_color:-lightgrey}\"}"
    entries+=$infra_trend_entry
fi
# Build badge metadata (hashes + mtimes) for freshness / integrity.
# Note: Only compute for files that exist; skipped otherwise.
typeset -a META_HASHES
typeset -a META_MTIMES
compute_badge_meta() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0
    local hash mtime
    # Portable hash & mtime (BSD stat vs GNU stat)
    if command -v shasum >/dev/null 2>&1; then
        hash=$(shasum -a 256 "$file" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        hash=$(sha256sum "$file" | awk '{print $1}')
    else
        hash="unknown"
    fi
    mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo 0)
    META_HASHES+=("\"$key\":\"$hash\"")
    META_MTIMES+=("\"$key\":$mtime")
}

compute_badge_meta docs/badges/perf.json perf
compute_badge_meta docs/badges/perf-ledger.json perf_ledger
compute_badge_meta docs/badges/perf-drift.json perf_drift
compute_badge_meta docs/badges/structure.json structure
compute_badge_meta docs/badges/hooks.json hooks
compute_badge_meta docs/badges/security.json security
compute_badge_meta docs/badges/infra-health.json infra
compute_badge_meta docs/badges/infra-trend.json infra_trend

(
    printf '{"generated_utc":"%s","badges":{' "$(date -u +%FT%TZ)";
    if (( ${#entries[@]} > 0 )); then
        printf '%s' "${(j:,:.)entries}"
    fi
    printf ',"hashes":{'
    if (( ${#META_HASHES[@]} > 0 )); then
        printf '%s' "${(j:,:.)META_HASHES}"
    fi
    printf '},"mtimes":{'
    if (( ${#META_MTIMES[@]} > 0 )); then
        printf '%s' "${(j:,:.)META_MTIMES}"
    fi
    printf '}}\n'
) > "$OUT"
echo "[badges-summary] Wrote $OUT" >&2
