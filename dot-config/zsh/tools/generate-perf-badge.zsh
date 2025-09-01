#!/usr/bin/env zsh
# generate-perf-badge.zsh
# Measure interactive startup, maintain baseline, emit shields.io JSON badge & metrics
# Outputs:
#    docs/redesign/metrics/perf-current.json (raw numbers)
#    docs/redesign/metrics/perf-baseline.json (if missing)
#    docs/redesign/badges/perf.json (badge)
# Exit non-zero if regression >5% vs baseline (unless ZSH_PERF_ALLOW_REGRESSION=1)

set -euo pipefail
zmodload zsh/datetime 2>/dev/null || true

ROOT_DIR=${0:A:h:h}
DOCS_DIR=$ROOT_DIR/docs/redesign
METRICS_DIR=$DOCS_DIR/metrics
BADGE_DIR=$DOCS_DIR/badges
mkdir -p $METRICS_DIR $BADGE_DIR

runs=${1:-5}
[[ $runs = *[^0-9]* ]] && runs=5

measure() {
    local start end delta
    start=$EPOCHREALTIME
    zsh -ic 'exit' >/dev/null 2>&1 || true
    end=$EPOCHREALTIME
    delta=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    awk -v d=$delta 'BEGIN{printf "%d", d*1000}'
}

echo "[perf-badge] measuring $runs runs..." >&2
local total=0 best=999999 worst=0
local json_runs="["
for i in {1..$runs}; do
    ms=$(measure)
    (( total+=ms ))
    (( ms<best )) && best=$ms
    (( ms>worst )) && worst=$ms
    json_runs+="$ms"; (( i<runs )) && json_runs+=",";
    echo "    run $i: ${ms}ms" >&2
    sleep 0.05
done
json_runs+=']'
mean=$(( total / runs ))
STAMP=$(date +%Y-%m-%dT%H:%M:%S%z)

CUR_JSON=$METRICS_DIR/perf-current.json
BASE_JSON=$METRICS_DIR/perf-baseline.json

# Write current metrics
{
    echo '{'
    echo "    \"timestamp\": \"$STAMP\",";
    echo "    \"runs\": $json_runs,";
    echo "    \"mean_ms\": $mean,";
    echo "    \"best_ms\": $best,";
    echo "    \"worst_ms\": $worst";
    echo '}'
} > $CUR_JSON

echo "[perf-badge] mean=${mean}ms best=${best} worst=${worst}" >&2

# If no baseline yet, seed with current simple JSON (legacy format)
if [[ ! -f $BASE_JSON ]]; then
    cp $CUR_JSON $BASE_JSON
    echo "[perf-badge] baseline created (no regression check)" >&2
fi

# Compatibility extraction: support rich baseline (filtered_mean_ms) or legacy (mean_ms)
extract_mean() {
    local file=$1
    local val
    # Prefer filtered_mean_ms, then raw_mean_ms, then mean_ms
    for key in filtered_mean_ms raw_mean_ms mean_ms; do
        if grep -q "\"$key\"" "$file"; then
            val=$(grep -m1 "\"$key\"" "$file" | tr -dc '0-9')
            [[ -n $val ]] && { echo $val; return 0; }
        fi
    done
    echo 0
}

# New helper to extract relative stddev if present
extract_rel() {
    local file=$1 val
    for key in filtered_relative_stddev raw_relative_stddev relative_stddev; do
        if grep -q "\"$key\"" "$file"; then
            val=$(grep -m1 "\"$key\"" "$file" | sed 's/[^0-9.]*//g' | head -1)
            [[ -n $val ]] && { echo $val; return 0; }
        fi
    done
    echo 0
}

base_mean=$(extract_mean "$BASE_JSON")
cur_mean=$mean
base_rel=$(extract_rel "$BASE_JSON")
[[ -z $base_rel ]] && base_rel=0

if [[ $base_mean = 0 ]]; then
    echo "[perf-badge] WARNING: could not extract baseline mean (defaulting base_mean=cur_mean)" >&2
    base_mean=$cur_mean
fi

# Percentage delta (+ slower, - faster)
perc_delta=$(awk -v b=$base_mean -v c=$cur_mean 'BEGIN{ if (b>0){printf "%.2f", (c-b)/b*100}else{print "0.00"} }')

color=green
if awk -v d=$perc_delta 'BEGIN{exit !(d>5)}'; then
    color=red
elif awk -v d=$perc_delta 'BEGIN{exit !(d>2 && d<=5)}'; then
    color=yellow
fi

improvement_label=$(awk -v d=$perc_delta 'BEGIN{ if(d<0){printf "%.0f%%", -d}else{printf "+%.0f%%", d} }')

var_flag=""
if awk -v r=$base_rel 'BEGIN{exit !(r>12)}'; then
    var_flag=" var!"
fi

BADGE_JSON=$BADGE_DIR/perf.json
cat > $BADGE_JSON <<EOF
{"schemaVersion":1,"label":"zsh startup","message":"${cur_mean}ms ${improvement_label}${var_flag}","color":"${color}"}
EOF

echo "[perf-badge] wrote $BADGE_JSON (delta ${perc_delta}% baseline_rel_stddev=${base_rel}%)" >&2

if [[ ${ZSH_PERF_ALLOW_REGRESSION:-0} != 1 ]]; then
    # Fail if regression >5%
    if awk -v d=$perc_delta 'BEGIN{exit !(d>5)}'; then
        echo "[perf-badge] ERROR: regression >5% (delta ${perc_delta}%)" >&2
        exit 2
    fi
fi
exit 0
