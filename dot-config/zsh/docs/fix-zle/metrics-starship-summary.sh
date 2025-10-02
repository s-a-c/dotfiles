#!/usr/bin/env bash
# metrics-starship-summary.sh - Summarize starship init timing metrics
# Reads artifacts/metrics/starship-init.log (TSV: ISO8601\tkey\tvalue)
# Outputs human-readable summary or JSON (with --json)
set -euo pipefail
JSON=0
LOG="$(dirname "${BASH_SOURCE[0]}")/../artifacts/metrics/starship-init.log"

for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    --log=*) LOG="${arg#--log=}" ;;
  esac
done

if [[ ! -f "$LOG" ]]; then
  if (( JSON == 1 )); then
    echo '{"status":"missing","count":0}'
  else
    echo "No log file: $LOG" >&2
  fi
  exit 0
fi

mapfile -t values < <(awk -F'\t' '$2=="starship_init_ms" {print $3}' "$LOG" | grep -E '^[0-9]+$' )
count=${#values[@]}
if (( count == 0 )); then
  if (( JSON == 1 )); then
    echo '{"status":"empty","count":0}'
  else
    echo "No numeric entries" >&2
  fi
  exit 0
fi

# Compute stats
min=${values[0]}
max=${values[0]}
sum=0
for v in "${values[@]}"; do
  (( v < min )) && min=$v || true
  (( v > max )) && max=$v || true
  sum=$(( sum + v ))
done
mean=$(( sum / count ))
# median / p95 require sorted copy
sorted=($(printf '%s\n' "${values[@]}" | sort -n))
mid=$(( count / 2 ))
if (( count % 2 == 1 )); then
  median=${sorted[$mid]}
else
  # even: average middle two
  m1=${sorted[$(( mid - 1 ))]}
  m2=${sorted[$mid]}
  median=$(( (m1 + m2) / 2 ))
fi
p95_index=$(( (95 * count + 99) / 100 - 1 ))
(( p95_index < 0 )) && p95_index=0
(( p95_index >= count )) && p95_index=$(( count - 1 ))
p95=${sorted[$p95_index]}

if (( JSON == 1 )); then
  printf '{"status":"ok","count":%s,"min":%s,"max":%s,"mean":%s,"median":%s,"p95":%s}' \
    "$count" "$min" "$max" "$mean" "$median" "$p95"
  echo
else
  cat <<EOF
Starship Init Timing Summary
Log: $LOG
Entries: $count
Min:    ${min} ms
Max:    ${max} ms
Mean:   ${mean} ms
Median: ${median} ms
P95:    ${p95} ms
EOF
fi
