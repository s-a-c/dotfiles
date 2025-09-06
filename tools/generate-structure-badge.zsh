#!/usr/bin/env zsh
# generate-structure-badge.zsh
# Produce a shields.io JSON badge summarizing structure health.
# Inputs:
#     --audit <file>     (default: docs/redesign/metrics/structure-audit.json)
#     --output <file>    (default: docs/badges/structure.json)
#     --strict                 Treat partial (module_count < expected) as warning (orange) else green only when complete
# Exit codes: always 0 (non-fatal) unless --fail-on-error is added and audit file missing.
set -euo pipefail
AUDIT=docs/redesign/metrics/structure-audit.json
OUT=docs/badges/structure.json
STRICT=0
FAIL=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --audit) AUDIT=$2; shift 2 ;;
        --output) OUT=$2; shift 2 ;;
        --strict) STRICT=1; shift ;;
        --fail-on-error) FAIL=1; shift ;;
        -h|--help)
            sed -n '1,40p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

mkdir -p "${OUT:h}" || true

if [[ ! -f $AUDIT ]]; then
    echo "[structure-badge] Audit file missing: $AUDIT" >&2
    if (( FAIL )); then exit 2; fi
    echo '{"schemaVersion":1,"label":"structure","message":"no-audit","color":"lightgrey"}' > "$OUT"
    exit 0
fi

# Lightweight JSON parsing without jq (fallback); prefer jq if available.
get_field() {
    local key=$1
    if command -v jq >/dev/null 2>&1; then
        jq -r --arg k "$key" '.[$k]' "$AUDIT" 2>/dev/null || true
    else
        # crude grep
        grep -E '"'$key'"' "$AUDIT" | head -n1 | sed 's/.*"'$key'"[ ]*:[ ]*"\?//; s/"\?,.*$//' | tr -d '"'
    fi
}

module_count=$(get_field module_count)
expected_count=$(get_field expected_count)
missing_guards=$(get_field missing_guards)
# duplicate prefixes: array length
if command -v jq >/dev/null 2>&1; then
    dup_len=$(jq '.duplicate_prefixes | length' "$AUDIT")
else
    dup_line=$(grep 'duplicate_prefixes' "$AUDIT" | head -n1)
    dup_len=$(echo "$dup_line" | tr -cd ',' | wc -c | awk '{print ($1==0?0:$1+1)}')
fi

# Determine status
color=lightgrey
status="partial"

# Logic priorities:
# Red if duplicates, missing guards, or module_count > expected
if { [[ -n $expected_count && $expected_count != null ]] && (( module_count > expected_count )); } || (( dup_len > 0 )) || (( missing_guards > 0 )); then
    color=red
    status="drift"
else
    # Completed & clean
    if [[ -n $expected_count && $expected_count != null ]] && (( module_count == expected_count )); then
        color=brightgreen
        status="complete"
    else
        # Partial
        color=$([[ $STRICT -eq 1 ]] && echo orange || echo yellow)
        status=$([[ $STRICT -eq 1 ]] && echo partial || echo wip)
    fi
fi

message="${module_count}/${expected_count:-?} ${status}"
cat > "$OUT" <<EOF
{"schemaVersion":1,"label":"structure","message":"$message","color":"$color"}
EOF

echo "[structure-badge] Wrote $OUT ($message)" >&2
exit 0
