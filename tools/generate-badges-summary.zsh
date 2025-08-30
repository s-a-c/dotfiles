#!/usr/bin/env zsh
# generate-badges-summary.zsh
# Combine perf + structure badge JSONs (and optionally others) into a single summary JSON.
# Fields:
#     generated_utc, badges: { perf: {message,color}, structure:{message,color} }
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
struct_entry=$(read_badge docs/badges/structure.json structure || true)
[[ -n ${struct_entry:-} ]] && entries+=$struct_entry
(
    printf '{"generated_utc":"%s","badges":{' "$(date -u +%FT%TZ)";
    if (( ${#entries[@]} > 0 )); then
        printf '%s' "${(j:,:.)entries}"
    fi
    printf '}}\n'
) > "$OUT"
echo "[badges-summary] Wrote $OUT" >&2
