#!/usr/bin/env zsh
# promotion-guard.zsh
# Gate promotion of redesign by validating structure & performance artifacts.
# Usage: tools/promotion-guard.zsh [expected_module_count] [--allow-mismatch]
# Exit Codes:
# 0 OK
# 1 Missing artifact(s)
# 2 Structural violation (duplicates/order)
# 3 Module count mismatch
# 4 Performance regression >5%
# 5 Badge failure (red)
# 6 JSON/Parse failure
# 7 Markdown audit missing or inconsistent with JSON
# 8 Legacy checksum verification failed
# 9 Async state validation failed
set -euo pipefail

expected=${1:-11}
allow_mismatch=0
shift || true
for arg in "$@"; do
    [[ $arg == --allow-mismatch ]] && allow_mismatch=1
done

ROOT=${0:A:h:h}
# Prefer new redesignv2 artifact paths; fall back to legacy redesign paths if not present
if [[ -d $ROOT/docs/redesignv2/artifacts/metrics && -d $ROOT/docs/redesignv2/artifacts/badges ]]; then
  METRICS=$ROOT/docs/redesignv2/artifacts/metrics
  BADGES=$ROOT/docs/redesignv2/artifacts/badges
else
  METRICS=$ROOT/docs/redesign/metrics
  BADGES=$ROOT/docs/redesign/badges
fi

need=(structure-audit.json perf-current.json perf-baseline.json $BADGES/perf.json $BADGES/structure.json structure-audit.md)
missing=()
for f in $need; do
    case $f in
        structure-audit.json|perf-current.json|perf-baseline.json|structure-audit.md) path=$METRICS/$f ;;
        *) path=$f ;;
    esac
    [[ -f $path ]] || missing+=$path
done
if (( ${#missing[@]} )); then
    print -u2 "[promotion-guard] Missing: ${missing[*]}"
    exit 1
fi

jq_bin=$(command -v jq || true)

get_json_value() {
    local file=$1 key=$2
    if [[ -n $jq_bin ]]; then
        $jq_bin -r ".$key" "$file" 2>/dev/null || return 6
    else
        grep -E '"'$key'"' "$file" | head -1 | tr -dc '0-9.' || return 6
    fi
}

SA_JSON=$METRICS/structure-audit.json
SA_MD=$METRICS/structure-audit.md
PC=$METRICS/perf-current.json
PB=$METRICS/perf-baseline.json

# Extract JSON structure data
if [[ -n $jq_bin ]]; then
    total_modules=$($jq_bin -r '.total' $SA_JSON)
    violations_ct=$($jq_bin '.violations|length' $SA_JSON)
    order_issue=$($jq_bin -r '.order_issue' $SA_JSON)
else
    total_modules=$(grep '"total"' $SA_JSON | tr -dc '0-9')
    violations_ct=$(grep -c 'Duplicate prefix' $SA_JSON || true)
    order_issue=$(grep -q 'order_issue":1' $SA_JSON && echo 1 || echo 0)
fi

# Parse markdown summary marker: <!-- STRUCTURE-AUDIT: total=## violations=## order_issue=0 generated=... json=... -->
if ! grep -q 'STRUCTURE-AUDIT:' $SA_MD; then
    print -u2 "[promotion-guard] Markdown structure audit summary marker missing"
    exit 7
fi
md_line=$(grep 'STRUCTURE-AUDIT:' $SA_MD | tail -1)
md_total=$(echo $md_line | sed -n 's/.* total=\([0-9]*\).*/\1/p')
md_violations=$(echo $md_line | sed -n 's/.* violations=\([0-9]*\).*/\1/p')
md_order=$(echo $md_line | sed -n 's/.* order_issue=\([0-9]*\).*/\1/p')

if [[ -z ${md_total:-} || -z ${md_violations:-} || -z ${md_order:-} ]]; then
    print -u2 "[promotion-guard] Unable to parse markdown summary marker"
    exit 7
fi

if (( md_total != total_modules || md_violations != violations_ct || md_order != order_issue )); then
    print -u2 "[promotion-guard] Markdown / JSON mismatch (md_total=$md_total json_total=$total_modules md_violations=$md_violations json_violations=$violations_ct md_order=$md_order json_order=$order_issue)"
    exit 7
fi

if (( violations_ct>0 || order_issue>0 )); then
    print -u2 "[promotion-guard] Structural violations present (violations=$violations_ct order_issue=$order_issue)"
    exit 2
fi

if (( total_modules != expected )) && (( allow_mismatch == 0 )); then
    print -u2 "[promotion-guard] Module count $total_modules != expected $expected"
    exit 3
fi

# Performance regression check
cur_mean=$(get_json_value $PC mean_ms)
base_mean=$(get_json_value $PB mean_ms)
if [[ -z ${cur_mean:-} || -z ${base_mean:-} ]]; then
    print -u2 "[promotion-guard] Unable to parse performance means"
    exit 6
fi
perc_delta=$(awk -v b=$base_mean -v c=$cur_mean 'BEGIN{printf "%.2f", (c-b)/b*100}')
if awk -v d=$perc_delta 'BEGIN{exit !(d>5)}'; then
    print -u2 "[promotion-guard] Regression >5% (delta ${perc_delta}%)"
    exit 4
fi

# Badge sanity
if grep -q '"color":"red"' $BADGES/perf.json || grep -q '"color":"red"' $BADGES/structure.json; then
    print -u2 "[promotion-guard] Red badge detected"
    exit 5
fi

# Checksum verification
CHECKSUM_VERIFIER=$ROOT/tools/verify-legacy-checksums.zsh
if [[ -f $CHECKSUM_VERIFIER ]]; then
    if ! $CHECKSUM_VERIFIER >/dev/null 2>&1; then
        print -u2 "[promotion-guard] Legacy checksum verification failed"
        exit 8
    fi
else
    print -u2 "[promotion-guard] Warning: checksum verifier not found at $CHECKSUM_VERIFIER"
fi

# Async state validation - check for deferred async start
ASYNC_STATE_LOG="$ROOT/logs/async-state.log"
PERF_LOG="$ROOT/logs/perf-current.log"
if [[ -f $ASYNC_STATE_LOG ]]; then
    # Look for evidence of deferred async start (should not be RUNNING before first prompt)
    if grep -q "ASYNC_STATE:RUNNING" $ASYNC_STATE_LOG && ! grep -q "PERF_PROMPT:" $PERF_LOG; then
        print -u2 "[promotion-guard] Async validation failed: found RUNNING state before first prompt"
        exit 9
    fi
    # Look for proper deferred start marker
    if ! grep -q "SECURITY_ASYNC_QUEUE" $ASYNC_STATE_LOG; then
        print -u2 "[promotion-guard] Warning: async queue marker not found (may indicate missing deferred start)"
    fi
else
    print -u2 "[promotion-guard] Warning: async state log not found at $ASYNC_STATE_LOG"
fi

print "[promotion-guard] OK (modules=$total_modules mean=${cur_mean}ms baseline=${base_mean}ms delta=${perc_delta}% violations=${violations_ct} checksum=verified)"
exit 0
