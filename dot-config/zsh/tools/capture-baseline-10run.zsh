#!/usr/bin/env zsh
# capture-baseline-10run.zsh
# Collect N interactive startup timings (default 11 total, discard first warm-up) and produce baseline JSON.
# Adds robust outlier filtering (MAD) and records both raw & filtered statistics.
# JSON fields:
#        timestamp, raw_runs, raw_mean_ms, raw_stddev_ms, raw_relative_stddev,
#        filtered_runs, filtered_mean_ms, filtered_stddev_ms, filtered_relative_stddev,
#        discarded_count, discard_rule
# Exit codes: 0 success; 1 insufficient runs; 2 arg / processing error.

set -euo pipefail
setopt pipe_fail

RAW_COUNT=11    # total runs INCLUDING warm runs to discard
# Prefer new redesignv2 artifact paths if present; fallback to legacy locations
if [[ -d docs/redesignv2/artifacts/metrics ]]; then
  OUT_FILE="docs/redesignv2/artifacts/metrics/perf-baseline.json"
  RAW_LOG="docs/redesignv2/artifacts/metrics/startup-times-raw.txt"
else
  OUT_FILE="docs/redesign/metrics/perf-baseline.json"
  RAW_LOG="docs/redesign/planning/startup-times-raw.txt"
fi
QUIET=0
WARM_DISCARD=1  # number of leading runs to discard
PREWARM=1       # do a separate prewarm shell not counted

usage() { cat <<EOF
Usage: $0 [--runs N>=11] [--out path] [--quiet] [--warm K>=1] [--no-prewarm]
    Collect N startup timings; discard K warm-up runs; compute raw + filtered stats.
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --runs) RAW_COUNT=$2; shift 2 ;;
        --out) OUT_FILE=$2; shift 2 ;;
        --quiet) QUIET=1; shift ;;
        --warm) WARM_DISCARD=$2; shift 2 ;;
        --no-prewarm) PREWARM=0; shift ;;
        --help) usage; exit 0 ;;
        *) echo "[baseline] Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if (( RAW_COUNT < 11 )); then
    echo "[baseline] ERROR: --runs must be >=11" >&2; exit 2
fi
if (( WARM_DISCARD < 1 )); then
    echo "[baseline] ERROR: --warm must be >=1" >&2; exit 2
fi
if (( WARM_DISCARD >= RAW_COUNT )); then
    echo "[baseline] ERROR: warm runs (K=$WARM_DISCARD) must be < total runs (N=$RAW_COUNT)" >&2; exit 2
fi

mkdir -p "${RAW_LOG%/*}" "${OUT_FILE%/*}" || true
: > "$RAW_LOG"
log() { (( QUIET )) || echo "$@" >&2; }

if (( PREWARM )); then
    log "[baseline] prewarm interactive shell (not recorded)"
    zsh -i -c exit >/dev/null 2>&1 || true
    for cand in "$PWD/.zqs-zgenom/init.zsh" "$HOME/.zgenom/init.zsh" "$PWD/.zgenom/init.zsh"; do
        [[ -f $cand ]] && { touch "$cand" && log "[baseline] touched init cache: $cand"; }
    done
fi

log "[baseline] collecting $RAW_COUNT runs (discarding first $WARM_DISCARD warm run(s))"
for i in {1..$RAW_COUNT}; do
    log "[baseline] run $i"
    /usr/bin/time -p zsh -i -c exit 2>> "$RAW_LOG" || true
    # keep touching init to stabilize plugin rebuild heuristics
    for cand in "$PWD/.zqs-zgenom/init.zsh" "$HOME/.zgenom/init.zsh" "$PWD/.zgenom/init.zsh"; do
        [[ -f $cand ]] && touch "$cand"
    done
done

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# Extract 'real' seconds
real_secs=($(awk '/^real/ {print $2}' "$RAW_LOG"))
if (( ${#real_secs[@]} <= WARM_DISCARD )); then
    echo "[baseline] ERROR: insufficient timing lines" >&2; exit 1
fi

# Convert (skip warm)
raw_ms=()
for (( idx=WARM_DISCARD; idx<${#real_secs[@]}; idx++ )); do
    sec=${real_secs[$idx]}
    ms=$(awk -v s="$sec" 'BEGIN{printf "%d", s*1000}')
    raw_ms+=$ms
done

if (( ${#raw_ms[@]} < 10 )); then
    echo "[baseline] ERROR: need >=10 effective runs (got ${#raw_ms[@]})" >&2; exit 1
fi

raw_n=${#raw_ms[@]}
raw_sum=0; for v in $raw_ms; do (( raw_sum+=v )); done
raw_mean=$(( raw_sum / raw_n ))
raw_ss=0; for v in $raw_ms; do d=$(( v - raw_mean )); (( raw_ss+=d*d )); done
raw_sd=$(awk -v ss=$raw_ss -v n=$raw_n 'BEGIN{printf "%d", (n>0)?sqrt(ss/n):0}')
raw_rel=$(awk -v sd=$raw_sd -v mean=$raw_mean 'BEGIN{ if(mean>0){printf "%.2f", sd/mean*100}else{print "0.00"} }')

# Median & MAD
sorted=(${(on)raw_ms})
mid=$(( raw_n / 2 ))
if (( raw_n % 2 )); then
    median=${sorted[$((mid+1))]}
else
    median=$(( (sorted[$mid] + sorted[$((mid+1))]) / 2 ))
fi
absdev=()
for v in $raw_ms; do dev=$(( v>median ? v-median : median-v )); absdev+=$dev; done
sorted_dev=(${(on)absdev})
mid2=$(( raw_n / 2 ))
if (( raw_n % 2 )); then
    mad=${sorted_dev[$((mid2+1))]}
else
    mad=$(( (sorted_dev[$mid2] + sorted_dev[$((mid2+1))]) / 2 ))
fi
(( mad == 0 )) && mad=1

filtered=(); discarded=0
for v in $raw_ms; do
    dev=$(( v>median ? v-median : median-v ))
    if (( dev <= 3*mad )); then filtered+=$v; else (( discarded++ )); fi
done
if (( ${#filtered[@]} < raw_n/2 )); then
    filtered=(${raw_ms[@]}); discarded=0; discard_rule="none (fallback)"
else
    discard_rule="|v-median|<=3*MAD"
fi

f_n=${#filtered[@]}
f_sum=0; for v in $filtered; do (( f_sum+=v )); done
f_mean=$(( f_sum / f_n ))
f_ss=0; for v in $filtered; do d=$(( v - f_mean )); (( f_ss+=d*d )); done
f_sd=$(awk -v ss=$f_ss -v n=$f_n 'BEGIN{printf "%d", (n>0)?sqrt(ss/n):0}')
f_rel=$(awk -v sd=$f_sd -v mean=$f_mean 'BEGIN{ if(mean>0){printf "%.2f", sd/mean*100}else{print "0.00"} }')

TMP="$OUT_FILE.tmp"
{
    echo '{'
    echo "        \"timestamp\": \"$TS\",";
    echo -n "        \"raw_runs\": ["; for i in {1..$raw_n}; do printf "%s" "${raw_ms[$i]}"; (( i<raw_n )) && printf ","; done; echo "],";
    echo "        \"raw_mean_ms\": $raw_mean,";
    echo "        \"raw_stddev_ms\": $raw_sd,";
    echo "        \"raw_relative_stddev\": $raw_rel,";
    echo -n "        \"filtered_runs\": ["; for i in {1..$f_n}; do printf "%s" "${filtered[$i]}"; (( i<f_n )) && printf ","; done; echo "],";
    echo "        \"filtered_mean_ms\": $f_mean,";
    echo "        \"filtered_stddev_ms\": $f_sd,";
    echo "        \"filtered_relative_stddev\": $f_rel,";
    echo "        \"discarded_count\": $discarded,";
    echo "        \"discard_rule\": \"$discard_rule\"";
    echo '}'
} > "$TMP"
mv "$TMP" "$OUT_FILE"
log "[baseline] wrote $OUT_FILE (raw_mean=${raw_mean}ms raw_rel=${raw_rel}% filtered_mean=${f_mean}ms filtered_rel=${f_rel}%)"

rel_check=$f_rel
variance_ok=0
if command -v bc >/dev/null 2>&1; then
    if (( $(echo "$rel_check <= 12.0" | bc -l) )); then variance_ok=1; fi
else
    if awk -v r=$rel_check 'BEGIN{exit !(r<=12.0)}'; then variance_ok=1; fi
fi
if (( variance_ok )); then
    log "[baseline] variance OK (filtered relative stddev ${rel_check}%)"
else
    log "[baseline] WARNING: filtered relative stddev ${rel_check}% > 12% threshold"
fi

exit 0
