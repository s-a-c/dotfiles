#!/usr/bin/env zsh
# generate-summary-badges.zsh
# Combine existing badges (perf, structure) into summary.json
set -euo pipefail
ROOT=${0:A:h:h}
BADGES=$ROOT/docs/redesign/badges
mkdir -p $BADGES
PERF=$BADGES/perf.json
STRUCT=$BADGES/structure.json
SUMMARY=$BADGES/summary.json

jq_bin=$(command -v jq || true)
if [[ -n $jq_bin && -f $PERF && -f $STRUCT ]]; then
  perf_msg=$($jq_bin -r '.message' $PERF)
  struct_msg=$($jq_bin -r '.message' $STRUCT)
else
  # Fallback naive extraction
  perf_msg=$(grep '"message"' $PERF 2>/dev/null | head -1 | sed 's/.*"message":"//;s/".*//')
  struct_msg=$(grep '"message"' $STRUCT 2>/dev/null | head -1 | sed 's/.*"message":"//;s/".*//')
fi

color=blue
if [[ -f $PERF ]] && grep -q '"color":"red"' $PERF; then color=red; fi
if [[ -f $STRUCT ]] && grep -q '"color":"red"' $STRUCT; then color=red; fi

cat > $SUMMARY <<EOF
{"schemaVersion":1,"label":"zsh status","message":"perf:${perf_msg} | struct:${struct_msg}","color":"$color"}
EOF

echo "[summary-badge] wrote $SUMMARY" >&2
