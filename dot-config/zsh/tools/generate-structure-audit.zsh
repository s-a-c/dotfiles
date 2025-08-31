#!/usr/bin/env zsh
# generate-structure-audit.zsh
# -----------------------------------------------------------------------------
# Purpose:
#   Scan active/REDESIGN zsh module directories and produce a structural audit
#   in both Markdown (human) and JSON (machine) forms, plus a shields.io badge.
#
# Outputs (created/updated):
#   Preferred (v2):
#     docs/redesignv2/artifacts/metrics/structure-audit.md    (markdown table + summary marker)
#     docs/redesignv2/artifacts/metrics/structure-audit.json  (modules, violations, totals)
#     docs/redesignv2/artifacts/badges/structure.json         (badge endpoint)
#   Legacy (fallback if v2 paths absent):
#     docs/redesign/metrics/structure-audit.md
#     docs/redesign/metrics/structure-audit.json
#     docs/redesign/badges/structure.json
#
# Summary Marker (appended to markdown):
#   <!-- STRUCTURE-AUDIT: total=<n> violations=<n> order_issue=<0|1> generated=<ts> json=metrics/structure-audit.json -->
#   Promotion guard parses this line for cross-file consistency.
#
# Behavior:
#   - Detects duplicate numeric prefixes (sequential repetition) -> violation
#   - Detects ordering anomalies (prefix monotonicity breaks) -> order_issue=1
#   - Counts modules; emits red badge if any violations or ordering issue
#   - Exits non-zero (3) only when structural violations present (keeps CI strict)
#   - Provides fallback minimal artifacts via trap on unexpected error
#
# Exit Codes:
#   0  Success / green badge
#   3  Structural violations (red badge emitted)
#   (Other codes reserved for future explicit error branches; trap ensures artifacts.)
#
# Usage:
#   tools/generate-structure-audit.zsh
#   (No arguments currently; future flags may include --dir, --json-only, etc.)
#
# Changelog (key recent changes):
#   - Localized option changes (emulate -L) to prevent leaking NO_RCS outside script
#   - Added machine-readable summary marker parsed by promotion-guard
#   - Added robust error trap writing minimal placeholder artifacts on failure
#   - Refactored into _structure_audit_main function for isolation & testability
# -----------------------------------------------------------------------------

# (Localize option changes inside function using emulate -L)

# NOTE: Removed global `setopt NO_RCS NO_GLOBAL_RCS`; localization below.

_structure_audit_main() {
  emulate -L zsh -o no_rcs -o no_global_rcs
  set -euo pipefail

  # Debug start marker
  print "[structure-audit] start" >&2

  # Resilient repository root resolution
  resolve_root() {
    local script ref candidate i
    ref=${(%):-%x}
    [[ -z $ref || $ref == "zsh" ]] && ref=$0
    script=${ref:A} 2>/dev/null || script=$ref
    candidate=${script:h}
    for i in {1..6}; do
      if [[ -d $candidate/docs/redesign && -d $candidate/tools ]]; then
        print -r -- $candidate
        return 0
      fi
      candidate=${candidate:h}
    done
    if [[ -n ${ZDOTDIR:-} && -d $ZDOTDIR/docs/redesign ]]; then
      print -r -- $ZDOTDIR; return 0
    fi
    if command -v git >/dev/null 2>&1; then
      local gitroot
      gitroot=$(git rev-parse --show-toplevel 2>/dev/null || true)
      if [[ -n $gitroot && -d $gitroot/docs/redesign ]]; then
        print -r -- $gitroot; return 0
      fi
    fi
    print -r -- $PWD
  }

  ROOT_DIR=$(resolve_root)
  # Prefer new redesignv2 artifact paths; fall back to legacy redesign paths if not present.
  if [[ -d $ROOT_DIR/docs/redesignv2/artifacts/metrics && -d $ROOT_DIR/docs/redesignv2/artifacts/badges ]]; then
    DOCS_DIR=$ROOT_DIR/docs/redesignv2
    METRICS_DIR=$DOCS_DIR/artifacts/metrics
    BADGE_DIR=$DOCS_DIR/artifacts/badges
  else
    DOCS_DIR=$ROOT_DIR/docs/redesign
    METRICS_DIR=$DOCS_DIR/metrics
    BADGE_DIR=$DOCS_DIR/badges
  fi
  mkdir -p $METRICS_DIR $BADGE_DIR

  # Trap after dirs known
  TRAPERR() {
    local ec=$?
    print "[structure-audit] ERROR ec=$ec creating minimal audit" >&2
    mkdir -p ${METRICS_DIR:-docs/redesign/metrics} ${BADGE_DIR:-docs/redesign/badges} 2>/dev/null || true
    [[ -f $METRICS_DIR/structure-audit.md ]] || print "# Structure Audit (partial)\n<!-- STRUCTURE-AUDIT: total=0 violations=0 order_issue=0 generated=$(date +%Y-%m-%dT%H:%M:%S%z) json=metrics/structure-audit.json -->" > $METRICS_DIR/structure-audit.md
    [[ -f $METRICS_DIR/structure-audit.json ]] || print '{"generated":"'$(date +%Y-%m-%dT%H:%M:%S%z)'","modules":[],"violations":[],"order_issue":0,"total":0}' > $METRICS_DIR/structure-audit.json
    [[ -f $BADGE_DIR/structure.json ]] || print '{"schemaVersion":1,"label":"modules","message":"0 files","color":"green"}' > $BADGE_DIR/structure.json
    return $ec
  }

  scan_dir() {
    local dir=$1 label=$2
    [[ -d $dir ]] || return 0
    local files
    files=(${dir}/*.zsh(NOn)) || true
    for f in $files; do
      local base=${f:t}
      local prefix=${base%%-*}
      local size=$(wc -c < "$f" | tr -d ' ')
      local mtime=$(date -r "$f" +%Y-%m-%dT%H:%M:%S 2>/dev/null || stat -f %Sm -t %Y-%m-%dT%H:%M:%S "$f")
      print "$label\t$base\t$prefix\t$size\t$mtime\t$f"
    done
  }

  RAW=$(mktemp)
  scan_dir "$ROOT_DIR/.zshrc.d" active > $RAW || true
  scan_dir "$ROOT_DIR/.zshrc.d.REDESIGN" redesign >> $RAW || true

  typeset -A count_prefix
  violations=()
  order_issue=0
  last=-1
  entries=""
  integer total=0
  while IFS=$'\t' read -r scope base prefix size mtime path; do
    [[ -z ${base:-} ]] && continue
    if [[ $prefix == $last ]]; then
      violations+="Duplicate prefix $prefix ($base)"
    fi
    if [[ $last != -1 && $prefix != $last && $prefix < $last ]]; then
      order_issue=1
    fi
    (( count_prefix[$prefix]++ ))
    last=$prefix
    entries+="$scope|$base|$prefix|$size|$mtime|$path\n"
    total=$(( total + 1 ))
  done < $RAW

  MD=$METRICS_DIR/structure-audit.md
  JSON=$METRICS_DIR/structure-audit.json
  : > $MD
  print "# Structure Audit" >> $MD
  print "Generated: $(date +%Y-%m-%dT%H:%M:%S%z)" >> $MD
  print >> $MD
  print "| Scope | File | Prefix | Size (bytes) | Modified | Path |" >> $MD
  print "|-------|------|--------|-------------:|----------|------|" >> $MD

  print '{'"\n" > $JSON
  print '  "generated": "'$(date +%Y-%m-%dT%H:%M:%S%z)'",' >> $JSON
  print '  "modules": [' >> $JSON
  first_json=1

  print -n "$entries" | while IFS='|' read -r scope base prefix size mtime path; do
    [[ -z ${base:-} ]] && continue
    print "| $scope | $base | $prefix | $size | $mtime | $path |" >> $MD
    if (( first_json )); then first_json=0; else print ',' >> $JSON; fi
    printf '    {"scope":"%s","file":"%s","prefix":"%s","size":%s,"mtime":"%s"}' "$scope" "$base" "$prefix" "$size" "$mtime" >> $JSON
    print >> $JSON
  done
  print '  ],' >> $JSON

  print '  "violations": [' >> $JSON
  if (( ${#violations[@]} )); then
    i=0
    for v in ${violations[@]}; do
      (( i>0 )) && print ',' >> $JSON
      printf '    "%s"' "$v" >> $JSON
      print >> $JSON
      (( i++ ))
    done
  fi
  print '  ],' >> $JSON
  print '  "order_issue": '${order_issue:-0}',' >> $JSON
  print '  "total": '${total:-0} >> $JSON
  print '}' >> $JSON

  print >> $MD
  if (( ${#violations[@]} )); then
    print "## Violations" >> $MD
    for v in ${violations[@]}; do print "- $v" >> $MD; done
  fi
  if (( order_issue )); then
    print "\nOrder anomaly detected (non-monotonic prefixes)." >> $MD
  fi

  print "\n<!-- STRUCTURE-AUDIT: total=${total} violations=${#violations[@]} order_issue=${order_issue} generated=$(date +%Y-%m-%dT%H:%M:%S%z) json=metrics/structure-audit.json -->" >> $MD

  color=green
  [[ ${#violations[@]} -gt 0 || $order_issue -eq 1 ]] && color=red
  BADGE=$BADGE_DIR/structure.json
  cat > $BADGE <<EOF
{"schemaVersion":1,"label":"modules","message":"${total:-0} files","color":"$color"}
EOF

  echo "[structure-audit] wrote $MD ($total modules)" >&2

  if [[ $color == red ]]; then
    echo "[structure-audit] structural violations present" >&2
    return 3
  fi
  return 0
}

_structure_audit_main "$@"
rc=$?
exit $rc
