#!/usr/bin/env zsh
# generate-structure-audit.zsh
# Produce a JSON summary of current module structure for CI artifacts.
# Scans redesign directory if present, else active .zshrc.d.
# Fields:
#    - target_dir
#    - module_count
#    - expected_count (if redesign present we assume 11, else null)
#    - modules: [{name,prefix,has_guard}]
#    - duplicate_prefixes: [..]
#    - missing_guards: count
#    - timestamp_utc
#
# Usage: tools/generate-structure-audit.zsh [--expect 11] [--output docs/redesign/metrics/structure-audit.json]
set -euo pipefail
EXPECT=""
OUT="docs/redesign/metrics/structure-audit.json"
while [[ $# -gt 0 ]]; do
    case $1 in
        --expect) EXPECT=$2; shift 2 ;;
        --output) OUT=$2; shift 2 ;;
        -h|--help)
            sed -n '1,40p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [[ -d .zshrc.d.REDESIGN ]]; then
    DIR=.zshrc.d.REDESIGN
    [[ -z $EXPECT ]] && EXPECT=11
elif [[ -d .zshrc.d ]]; then
    DIR=.zshrc.d
fi

if [[ -z ${DIR:-} ]]; then
    echo "No module directory found (.zshrc.d or .zshrc.d.REDESIGN)." >&2
    mkdir -p "${OUT:h}" || true
    cat > "$OUT" <<EOF
{"target_dir":null,"module_count":0,"modules":[],"duplicate_prefixes":[],"missing_guards":0,"expected_count":${EXPECT:-null},"timestamp_utc":"$(date -u +%FT%TZ)"}
EOF
    exit 0
fi

mkdir -p "${OUT:h}" || true
modules=(${DIR}/*.zsh(N))
typeset -A seen guard_missing
json_modules=()
for f in "${modules[@]}"; do
    bn=${f:t}
    if [[ $bn =~ '^([0-9]{2})' ]]; then
        pfx=${match[1]}
    else
        pfx="NA"
    fi
    (( seen[$pfx]++ ))
    if grep -q '_LOADED_' "$f" 2>/dev/null; then
        has_guard=true
    else
        has_guard=false
    fi
    json_modules+="{\"name\":\"$bn\",\"prefix\":\"$pfx\",\"has_guard\":$has_guard}"
done

dup=()
for k in ${(k)seen}; do
    if (( seen[$k] > 1 )) && [[ $k != NA ]]; then
        dup+="\"$k\""
    fi
done

missing_guard_count=$(grep -L '_LOADED_' ${DIR}/*.zsh 2>/dev/null | wc -l | tr -d ' ' || echo 0)
modcount=${#modules[@]}
[[ -z $EXPECT ]] && exp_json=null || exp_json=$EXPECT

cat > "$OUT" <<EOF
{
    "target_dir": "${DIR}",
    "module_count": ${modcount},
    "expected_count": ${exp_json},
    "modules": [$(IFS=,; echo ${json_modules[*]})],
    "duplicate_prefixes": [$(IFS=,; echo ${dup[*]})],
    "missing_guards": ${missing_guard_count},
    "timestamp_utc": "$(date -u +%FT%TZ)"
}
EOF

echo "Wrote structure audit to $OUT" >&2
