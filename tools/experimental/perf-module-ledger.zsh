#!/usr/bin/env zsh
# perf-module-ledger.zsh
#
# PURPOSE:
#   Experimental performance "module ledger" prototype.
#   Parses a perf segment log (perf-current-segments.txt) and produces a normalized
#   JSON ledger capturing:
#     - Each segment's ms value, phase, sample tag
#     - Budget evaluation (soft by default)
#     - Overall status summary (ok / over / missing)
#   Optionally emits a shields.io style badge JSON for quick visualization.
#
# USAGE (example):
#   tools/experimental/perf-module-ledger.zsh \\
#       --segments docs/redesignv2/artifacts/metrics/perf-current-segments.txt \\
#       --output   docs/redesignv2/artifacts/metrics/perf-ledger.json \\
#       --budget   post_plugin_total:3000,pre_plugin_total:120 \\
#       --badge    docs/badges/perf-ledger.json
#
# ARGUMENTS:
#   --segments <file>   Path to segment file (required unless --allow-missing)
#   --output <file>     Output ledger JSON path (required)
#   --budget <spec>     Comma-separated name:limit pairs (e.g. a:100,b:250)
#   --fail-on-over      Exit with code 2 if any budget exceeded
#   --allow-missing     Do not treat missing segment file as error (emit placeholder)
#   --badge <file>      Additionally write a shields.io JSON badge (status summary)
#   --summary           Print concise human-readable summary to stdout
#   --quiet             Suppress non-error logging
#   --help              Show help
#
# EXIT CODES:
#   0  Success (even if budgets exceeded and --fail-on-over not set)
#   1  General argument / IO error
#   2  Budgets exceeded AND --fail-on-over specified
#
# JSON SCHEMA (prototype, subject to refinement):
# {
#   "schemaVersion": 1,
#   "source": "perf-module-ledger",
#   "generatedAt": "...ISO8601...",
#   "segmentsFile": "path-or-null",
#   "segments": {
#      "pre_plugin_total": { "ms": 1234, "phase": "pre_plugin", "sample": "mean" },
#      ...
#   },
#   "budgets": {
#      "pre_plugin_total": { "limit": 120, "actual": 135, "over": true, "delta": 15, "percentOver": 12.5 }
#   },
#   "overall": { "overBudgetCount": 1, "status": "over" }
# }
#
# BADGE JSON (if --badge):
#   { "schemaVersion":1, "label":"perf ledger", "message":"ok"|"N over", "color":"brightgreen"|"red"|"orange" }
#
# NOTES:
#   - This is an observational prototype (non-fatal by default).
#   - Integrate into nightly first; escalate to gating once stable.
#   - Keep IMPLEMENTATION.md progress trackers updated when promoting beyond prototype.
#
# STYLE:
#   Mirrors existing tooling patterns (strict shell flags, jq optional).
#

set -euo pipefail

# Derive repo root: script path is .../tools/experimental/
ROOT_DIR=${0:A:h:h:h}

# -------------------------------
# Defaults / State
# -------------------------------
SEG_FILE=""
OUT_FILE=""
BUDGET_SPEC=""
BADGE_FILE=""
ALLOW_MISSING=0
FAIL_ON_OVER=0
PRINT_SUMMARY=0
QUIET=0

typeset -A SEG_MS SEG_PHASE SEG_SAMPLE
typeset -A BUDGET_LIMIT
typeset -A BUDGET_ACTUAL
typeset -A BUDGET_OVER
typeset -A BUDGET_DELTA
typeset -A BUDGET_PCT_OVER

OVER_BUDGET_COUNT=0
STATUS="unknown"

# -------------------------------
# Logging Helpers
# -------------------------------
log()  { [[ $QUIET -eq 1 ]] || print -- "[ledger] $*" >&2; }
warn() { print -- "[ledger][WARN] $*" >&2; }
err()  { print -- "[ledger][ERROR] $*" >&2; }

usage() {
  cat <<EOF
Usage: $0 --segments <file> --output <file> [options]

Required:
  --segments <file>      Segment file (perf-current-segments.txt)
  --output <file>        Ledger JSON output

Optional:
  --budget name:limit[,name:limit...]   Budget specification
  --badge <file>         Emit badge JSON (shields schema)
  --fail-on-over         Exit 2 if any budget exceeded
  --allow-missing        Do not error if segment file missing (emit placeholder)
  --summary              Print concise summary to stdout
  --quiet                Suppress non-error logging
  --help                 Show this help

Example:
  $0 --segments docs/redesignv2/artifacts/metrics/perf-current-segments.txt \\
     --output docs/redesignv2/artifacts/metrics/perf-ledger.json \\
     --budget post_plugin_total:3000,pre_plugin_total:120 --badge docs/badges/perf-ledger.json
EOF
}

# -------------------------------
# Argument Parsing
# -------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --segments) SEG_FILE=$2; shift 2 ;;
    --output) OUT_FILE=$2; shift 2 ;;
    --budget) BUDGET_SPEC=$2; shift 2 ;;
    --badge) BADGE_FILE=$2; shift 2 ;;
    --fail-on-over) FAIL_ON_OVER=1; shift ;;
    --allow-missing) ALLOW_MISSING=1; shift ;;
    --summary) PRINT_SUMMARY=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "$OUT_FILE" ]]; then
  err "--output is required"
  usage
  exit 1
fi

if [[ -z "$SEG_FILE" && $ALLOW_MISSING -eq 0 ]]; then
  err "--segments required (or use --allow-missing)"
  usage
  exit 1
fi

# -------------------------------
# Budget Parsing
# -------------------------------
parse_budgets() {
  local spec=$1
  [[ -z "$spec" ]] && return 0
  local IFS=,
  for pair in $spec; do
    [[ -z "$pair" ]] && continue
    if [[ "$pair" != *:* ]]; then
      warn "Ignoring malformed budget item '$pair' (expected name:limit)"
      continue
    fi
    local name=${pair%%:*}
    local limit=${pair#*:}
    if ! [[ "$limit" =~ '^[0-9]+(\.[0-9]+)?$' ]]; then
      warn "Non-numeric limit '$limit' for '$name' (ignored)"
      continue
    fi
    BUDGET_LIMIT[$name]=$limit
  done
}

parse_budgets "$BUDGET_SPEC"

# -------------------------------
# Segment File Parsing
# -------------------------------
parse_segments() {
  local f=$1
  [[ -f "$f" ]] || return 1
  local line
  while IFS= read -r line; do
    [[ $line == SEGMENT\ * ]] || continue
    # Tokenize
    local token
    local -A kv
    for token in ${(s: :)line}; do
      [[ $token == SEGMENT ]] && continue
      [[ $token == *=* ]] || continue
      local k=${token%%=*}
      local v=${token#*=}
      kv[$k]=$v
    done
    local name=${kv[name]:-}
    local ms=${kv[ms]:-}
    [[ -z "$name" ]] && continue
    if ! [[ "$ms" =~ '^[0-9]+(\.[0-9]+)?$' ]]; then
      # treat unknown/missing ms as 0 for ledger continuity
      ms=0
    fi
    SEG_MS[$name]=$ms
    [[ -n ${kv[phase]:-} ]]  && SEG_PHASE[$name]=${kv[phase]}
    [[ -n ${kv[sample]:-} ]] && SEG_SAMPLE[$name]=${kv[sample]}
  done < "$f"
  return 0
}

SEGMENTS_PRESENT=0
if [[ -n "$SEG_FILE" && -f "$SEG_FILE" ]]; then
  if parse_segments "$SEG_FILE"; then
    SEGMENTS_PRESENT=1
    log "Parsed ${#SEG_MS[@]} segment(s) from $SEG_FILE"
  else
    warn "Failed to parse segments file: $SEG_FILE"
  fi
else
    if [[ $ALLOW_MISSING -eq 0 ]]; then
      err "Segment file not found: $SEG_FILE"
      exit 1
    else
      warn "Segment file missing (placeholder ledger emitted)."
    fi
fi

# -------------------------------
# Budget Evaluation
# -------------------------------
evaluate_budgets() {
  local name limit actual delta pct
  OVER_BUDGET_COUNT=0
  for name limit in ${(kv)BUDGET_LIMIT}; do
    actual=${SEG_MS[$name]:-}
    if [[ -z "$actual" ]]; then
      # Missing segment treated as 0 (could also mark unknown)
      actual=0
    fi
    delta=$(awk -v a="$actual" -v l="$limit" 'BEGIN{printf "%.2f", (a - l)}')
    local over=0
    if awk -v a="$actual" -v l="$limit" 'BEGIN{exit (a>l?0:1)}'; then
      over=1
      (( OVER_BUDGET_COUNT++ ))
    fi
    if [[ "$over" == "1" && "$limit" != "0" ]]; then
      pct=$(awk -v a="$actual" -v l="$limit" 'BEGIN{ if(l==0){print "inf"} else {printf "%.2f", ((a-l)/l)*100}}')
    else
      pct="0.00"
    fi
    BUDGET_ACTUAL[$name]=$actual
    BUDGET_OVER[$name]=$over
    BUDGET_DELTA[$name]=$delta
    BUDGET_PCT_OVER[$name]=$pct
  done
  if (( OVER_BUDGET_COUNT > 0 )); then
    STATUS="over"
  else
    STATUS=$(( SEGMENTS_PRESENT == 1 ? "ok" : "missing"))
    case "$STATUS" in
      ok) STATUS="ok" ;;
      *) STATUS="missing" ;;
    esac
  fi
}

evaluate_budgets

# -------------------------------
# JSON Emission
# -------------------------------
json_escape() {
  # Minimal escape (names are simple); extend if needed
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  print -- "$s"
}

emit_ledger_json() {
  local out=$1
  local dir=${out%/*}
  [[ -n "$dir" && ! -d "$dir" ]] && mkdir -p "$dir"

  {
    print -- '{'
    print -- '  "schemaVersion": 1,'
    print -- '  "source": "perf-module-ledger",'
    printf '  "generatedAt": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ -n "$SEG_FILE" ]]; then
      printf '  "segmentsFile": "%s",\n' "$(json_escape "$SEG_FILE")"
    else
      printf '  "segmentsFile": null,\n'
    fi
    print -- '  "segments": {'
    local first=1
    local name
    for name ms in ${(kv)SEG_MS}; do
      if (( first )); then first=0; else print -- ','; fi
      printf '    "%s": {"ms": %s' "$(json_escape "$name")" "$ms"
      [[ -n ${SEG_PHASE[$name]:-} ]]  && printf ', "phase": "%s"'  "$(json_escape "${SEG_PHASE[$name]}")"
      [[ -n ${SEG_SAMPLE[$name]:-} ]] && printf ', "sample": "%s"' "$(json_escape "${SEG_SAMPLE[$name]}")"
      printf '}'
    done
    print -- ''
    print -- '  },'
    print -- '  "budgets": {'
    first=1
    for name limit in ${(kv)BUDGET_LIMIT}; do
      if (( first )); then first=0; else print -- ','; fi
      local actual=${BUDGET_ACTUAL[$name]}
      local over=${BUDGET_OVER[$name]}
      local delta=${BUDGET_DELTA[$name]}
      local pct=${BUDGET_PCT_OVER[$name]}
      printf '    "%s": {"limit": %s, "actual": %s, "over": %s, "delta": %s, "percentOver": %s}' \
        "$(json_escape "$name")" "$limit" "$actual" "$([[ $over == 1 ]] && echo true || echo false)" "$delta" "$pct"
    done
    print -- ''
    print -- '  },'
    printf '  "overall": {"overBudgetCount": %d, "status": "%s"}\n' $OVER_BUDGET_COUNT "$STATUS"
    print -- '}'
  } > "$out"

  log "Wrote ledger: $out (status=$STATUS overBudgetCount=$OVER_BUDGET_COUNT)"
}

emit_badge_json() {
  local file=$1
  local dir=${file%/*}
  [[ -n "$dir" && ! -d "$dir" ]] && mkdir -p "$dir"

  local color="lightgrey"
  local message="n/a"

  case "$STATUS" in
    ok)
      color="brightgreen"
      message="ok"
      ;;
    over)
      color="red"
      message="${OVER_BUDGET_COUNT} over"
      ;;
    missing)
      color="lightgrey"
      message="missing"
      ;;
    *)
      color="orange"
      message="$STATUS"
      ;;
  esac

  cat > "$file" <<EOF
{"schemaVersion":1,"label":"perf ledger","message":"$message","color":"$color"}
EOF
  log "Wrote badge: $file (message=$message)"
}

emit_summary() {
  print -- "Perf Module Ledger Summary"
  print -- "  Status:           $STATUS"
  print -- "  Segments parsed:  ${#SEG_MS[@]}"
  if (( ${#BUDGET_LIMIT[@]} > 0 )); then
    print -- "  Budgets:"
    local name
    for name limit in ${(kv)BUDGET_LIMIT}; do
      local over=${BUDGET_OVER[$name]}
      local actual=${BUDGET_ACTUAL[$name]}
      local delta=${BUDGET_DELTA[$name]}
      printf "    - %-22s actual=%-8s limit=%-8s delta=%-8s %s\n" \
        "$name" "$actual" "$limit" "$delta" "$([[ $over == 1 ]] && echo 'OVER' || echo 'OK')"
    done
  fi
}

emit_ledger_json "$OUT_FILE"
[[ -n "$BADGE_FILE" ]] && emit_badge_json "$BADGE_FILE"
(( PRINT_SUMMARY )) && emit_summary

# -------------------------------
# Exit Logic
# -------------------------------
if (( OVER_BUDGET_COUNT > 0 && FAIL_ON_OVER == 1 )); then
  log "Budgets exceeded (count=$OVER_BUDGET_COUNT) and --fail-on-over set; exiting with code 2."
  exit 2
fi

exit 0
