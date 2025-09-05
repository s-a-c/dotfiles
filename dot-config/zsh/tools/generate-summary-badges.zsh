#!/usr/bin/env zsh
# generate-summary-badges.zsh
# Combine existing badges (perf, structure) into summary.json
set -euo pipefail
ROOT=${0:A:h:h}
# Migration preamble: prefer redesignv2 artifacts (create proactively), fallback to legacy if creation fails
PREFERRED_BADGES=$ROOT/docs/redesignv2/artifacts/badges
LEGACY_BADGES=$ROOT/docs/redesign/badges
mkdir -p "$PREFERRED_BADGES" 2>/dev/null || true
if [[ -d "$PREFERRED_BADGES" ]]; then
  BADGES=$PREFERRED_BADGES
else
  BADGES=$LEGACY_BADGES
fi
mkdir -p "$BADGES"
# Metrics roots for module-fire selftest JSON
PREFERRED_METRICS=$ROOT/docs/redesignv2/artifacts/metrics
LEGACY_METRICS=$ROOT/docs/redesign/metrics
if [[ -d "$PREFERRED_METRICS" ]]; then
  METRICS=$PREFERRED_METRICS
else
  METRICS=$LEGACY_METRICS
fi
PERF=$BADGES/perf.json
STRUCT=$BADGES/structure.json
MODULE_FIRE_BADGE=$BADGES/module-fire.json
SUMMARY=$BADGES/summary.json
MODULE_FIRE_METRICS=$METRICS/module-fire.json

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

# Derive module-fire badge from selftest metrics (if present)
module_msg="unknown"
module_color="lightgrey"
if [[ -f "$MODULE_FIRE_METRICS" ]]; then
  if [[ -n $jq_bin ]]; then
    emits_seg=$($jq_bin -r '.diagnostics.emits_granular_segments // 0' "$MODULE_FIRE_METRICS" 2>/dev/null)
    emits_pr=$($jq_bin -r '.diagnostics.emits_native_prompt // 0' "$MODULE_FIRE_METRICS" 2>/dev/null)
  else
    emits_seg=$(grep -o '"emits_granular_segments" *: *[01]' "$MODULE_FIRE_METRICS" 2>/dev/null | sed 's/.*: *//;q')
    emits_pr=$(grep -o '"emits_native_prompt" *: *[01]' "$MODULE_FIRE_METRICS" 2>/dev/null | sed 's/.*: *//;q')
    [[ -z "${emits_seg:-}" ]] && emits_seg=0
    [[ -z "${emits_pr:-}" ]] && emits_pr=0
  fi
  if [[ "$emits_seg" = "1" && "$emits_pr" = "1" ]]; then
    module_msg="ok"
    module_color="green"
  elif [[ "$emits_seg" = "1" || "$emits_pr" = "1" ]]; then
    if [[ "$emits_seg" = "0" ]]; then module_msg="prompt_only"; else module_msg="segments_only"; fi
    module_color="yellow"
  else
    module_msg="missing"
    module_color="red"
  fi
fi

# Write module-fire badge
cat > "$MODULE_FIRE_BADGE" <<EOF
{"schemaVersion":1,"label":"modules","message":"$module_msg","color":"$module_color"}
EOF
echo "[summary-badge] wrote $MODULE_FIRE_BADGE" >&2

# Summary color precedence: red > yellow > others
if [[ -f $PERF ]] && grep -q '"color":"red"' $PERF; then color=red; fi
if [[ -f $STRUCT ]] && grep -q '"color":"red"' $STRUCT; then color=red; fi
if [[ "$module_color" = "red" ]]; then color=red; fi
if [[ "$color" != "red" ]]; then
  if [[ -f $PERF ]] && grep -q '"color":"yellow"' $PERF; then color=yellow; fi
  if [[ -f $STRUCT ]] && grep -q '"color":"yellow"' $STRUCT; then color=yellow; fi
  if [[ "$module_color" = "yellow" ]]; then color=yellow; fi
fi

# Build summary including module-fire status
cat > $SUMMARY <<EOF
{"schemaVersion":1,"label":"zsh status","message":"perf:${perf_msg} | struct:${struct_msg} | modules:${module_msg}","color":"$color"}
EOF

echo "[summary-badge] wrote $SUMMARY" >&2
