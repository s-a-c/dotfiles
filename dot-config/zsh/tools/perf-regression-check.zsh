#!/usr/bin/env zsh
# perf-regression-check.zsh
# Compare current interactive startup mean vs baseline.
# Usage: perf-regression-check.zsh [runs] (default 5)
# Env:
#    PERF_REGRESSION_THRESHOLD (percent, default 5)
#    PERF_WARN_THRESHOLD (percent, default 2)
# Exits:
#    0 if within thresholds (or improved)
#    1 if soft warning (>WARN && <=REGRESSION) when PERF_FAIL_ON_WARN=1
#    2 if regression beyond threshold
set -euo pipefail
runs=${1:-5}
[[ $runs = *[^0-9]* ]] && runs=5
ROOT_DIR=${0:A:h:h}
BASE_JSON=$ROOT_DIR/docs/redesign/metrics/perf-baseline.json
if [[ ! -f $BASE_JSON ]]; then
    echo "[perf-check] ERROR: baseline file missing: $BASE_JSON" >&2
    exit 2
fi
extract_mean() {
    local file=$1 val
    for key in filtered_mean_ms raw_mean_ms mean_ms; do
        if grep -q "\"$key\"" "$file"; then
            val=$(grep -m1 "\"$key\"" "$file" | tr -dc '0-9')
            [[ -n $val ]] && { echo $val; return 0; }
        fi
    done
    echo 0
}
measure() {
    local start end delta
    start=$EPOCHREALTIME
    zsh -ic 'exit' >/dev/null 2>&1 || true
    end=$EPOCHREALTIME
    delta=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
    awk -v d=$delta 'BEGIN{printf "%d", d*1000}'
}
base_mean=$(extract_mean "$BASE_JSON")
if [[ $base_mean = 0 ]]; then
    echo "[perf-check] ERROR: could not parse baseline mean" >&2
    exit 2
fi
sum=0; best=999999; worst=0
for i in {1..$runs}; do
    ms=$(measure)
    (( sum+=ms ))
    (( ms<best )) && best=$ms
    (( ms>worst )) && worst=$ms
    echo "[perf-check] run $i: ${ms}ms" >&2
    sleep 0.02
done
cur_mean=$(( sum / runs ))
perc=$(awk -v b=$base_mean -v c=$cur_mean 'BEGIN{ if(b>0){printf "%.2f", (c-b)/b*100}else{print 0} }')
reg_thresh=${PERF_REGRESSION_THRESHOLD:-5}
warn_thresh=${PERF_WARN_THRESHOLD:-2}
status="improved"
code=0
is_reg=$(awk -v p=$perc -v t=$reg_thresh 'BEGIN{exit !(p>t)}') || true
is_warn=$(awk -v p=$perc -v w=$warn_thresh 'BEGIN{exit !(p>w && p<=w+0.000001)}') || true
if awk -v p=$perc -v w=$warn_thresh -v r=$reg_thresh 'BEGIN{exit !(p>w && p<=r)}'; then
    status="warning"
    (( ${PERF_FAIL_ON_WARN:-0} == 1 )) && code=1
elif awk -v p=$perc -v r=$reg_thresh 'BEGIN{exit !(p>r)}'; then
    status="regression"
    code=2
fi
cat <<EOF
{
    "baseline_mean_ms": $base_mean,
    "current_mean_ms": $cur_mean,
    "delta_percent": $perc,
    "runs": $runs,
    "best_ms": $best,
    "worst_ms": $worst,
    "status": "$status",
    "warn_threshold_percent": $warn_thresh,
    "regression_threshold_percent": $reg_thresh
}
EOF
if (( code != 0 )); then
    echo "[perf-check] ${status}: delta=${perc}% (baseline=${base_mean}ms current=${cur_mean}ms)" >&2
fi
exit $code
