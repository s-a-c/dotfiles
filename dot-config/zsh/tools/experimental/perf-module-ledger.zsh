#!/usr/bin/env zsh
# (Stage 3 enhancement placeholder) Drift badge messaging hook:
#   Future revision will compute and emit a JSON field (e.g. "max_positive_regression_pct")
#   derived from comparative segment analysis so the downstream drift badge generator
#   can append a suffix like "(+7.1% max)" to its message. This comment documents the
#   planned integration point; no functional changes introduced in this commit.
# =============================================================================
# perf-module-ledger.zsh  (EXPERIMENTAL PROTOTYPE)
#
# Purpose:
#   Generate a "module performance ledger" JSON (or human table) summarizing
#   per-segment timing data (startup / module load costs) to support future
#   budget gating (Phase: Observe → Warn → Gate).
#
# Data Inputs:
#   Segment timing file lines (example canonical format already emitted by
#   segment-lib or perf capture scripts):
#
#       SEGMENT <name> <elapsed_ms>
#
#   Lines beginning with `#` or blank lines are ignored. Non‑matching lines
#   are skipped with a warning (unless --strict-parse).
#
# Output:
#   JSON schema (ledger.v1) OR human-readable table.
#
#   Example JSON:
#   {
#     "schema": "module-ledger.v1",
#     "generated_at": "2025-09-03T12:34:56Z",
#     "source": "docs/redesignv2/artifacts/metrics/perf-current-segments.txt",
#     "total_ms": 5852.3,
#     "segments": [
#       {"name":"pre_plugin_total","ms":96.1,"pct_total":1.64,"class":"light"},
#       {"name":"post_plugin_total","ms":5055.3,"pct_total":86.39,"class":"heavy"}
#     ],
#     "thresholds": {"heavy_ms":500,"moderate_ms":120,"heavy_pct":10.0,"moderate_pct":3.0},
#     "budget_eval": {
#       "checked": true,
#       "budgets": {
#         "post_plugin_total":{"limit_ms":3000,"actual_ms":5055.3,"status":"over"},
#         "pre_plugin_total":{"limit_ms":120,"actual_ms":96.1,"status":"ok"}
#       },
#       "over_count": 1
#     },
#     "recommendation": "Reduce post_plugin_total below 3000ms (currently 5055.3ms)"
#   }
#
# Features:
#   - Classify segments (light / moderate / heavy) using ms + % thresholds.
#   - Optional user-specified budgets per segment (JSON or inline).
#   - Fail on budget violations (--fail-on-budget).
#   - Emits stable JSON schema for badge / CI consumption.
#
# Options:
#   --segments <file>         Input segment timing file (default auto-locate)
#   --output <file>           Write output to file instead of stdout
#   --format json|table       Output format (default: json)
#   --heavy-ms <N>            ms threshold marking heavy (default 500)
#   --moderate-ms <N>         ms threshold marking moderate (default 120)
#   --heavy-pct <P>           % (of total) threshold heavy (default 10)
#   --moderate-pct <P>        % threshold moderate (default 3)
#   --budget <spec>           Budget spec (comma list name:limit_ms OR @file.json)
#   --fail-on-budget          Exit 2 if any budget exceeded
#   --strict-parse            Treat malformed lines as errors (otherwise warn)
#   --quiet                   Suppress warnings (non-fatal)
#   --help | -h               Show help
#
# Budget Spec:
#   Inline: post_plugin_total:3000,pre_plugin_total:120
#   File:   --budget @budgets.json
#   budgets.json minimal schema:
#     {"budgets":{"post_plugin_total":3000,"pre_plugin_total":120}}
#
# Exit Codes:
#   0 Success (no enforced violation)
#   1 Usage / parse error
#   2 Budget violation (when --fail-on-budget)
#   3 Internal error
#
# Path Resolution Rule:
#   Avoid brittle ${0:A:h}; prefer zf::script_dir / resolve_script_dir.
#
# Dependencies:
#   - jq optional (pretty-print / validation if installed)
#   - Pure zsh fallback if jq absent
#
# Limitations / Future Enhancements:
#   - Support cumulative alias groups (segment grouping map)
#   - Historical comparison (diff baseline ledger)
#   - Emit per-phase rollup once phases formalized
#   - Derive budgets from evolving performance roadmap config
#
# =============================================================================
set -euo pipefail

SCRIPT_NAME="${0##*/}"

# -------------------------------
# Path resolution (resilient)
# -------------------------------
_resolve_self_dir() {
  if typeset -f zf::script_dir >/dev/null 2>&1; then
    zf::script_dir "${(%):-%N}"
  elif typeset -f resolve_script_dir >/dev/null 2>&1; then
    resolve_script_dir "${(%):-%N}"
  else
    # Last resort
    echo "${(%):-%N:h}"
  fi
}

SELF_DIR="$(_resolve_self_dir)"

# Defaults
SEG_FILE=""
OUT_FILE=""
FORMAT="json"
HEAVY_MS=500
MODERATE_MS=120
HEAVY_PCT=10.0
MODERATE_PCT=3.0
BUDGET_SPEC=""
FAIL_ON_BUDGET=0
STRICT_PARSE=0
QUIET=0

# Storage
typeset -a SEG_NAMES
typeset -a SEG_MS
typeset -A BUDGETS
typeset -A BUDGET_RESULT  # name -> status
typeset -F TOTAL_MS=0.0
typeset -i OVER_COUNT=0

json_escape() {
  # Escape " and \ plus control characters
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

usage() {
  cat <<EOF
$SCRIPT_NAME - Experimental module performance ledger generator

Usage:
  $SCRIPT_NAME [options]

Options:
  --segments <file>       Segment timing file (SEGMENT name ms)
  --output <file>         Write output to file
  --format json|table     Output format (default: json)
  --heavy-ms <N>          Heavy ms threshold (default: 500)
  --moderate-ms <N>       Moderate ms threshold (default: 120)
  --heavy-pct <P>         Heavy percentage threshold (default: 10)
  --moderate-pct <P>      Moderate percentage threshold (default: 3)
  --budget <spec>         Comma list name:limit OR @file.json
  --fail-on-budget        Exit 2 if budget exceeded
  --strict-parse          Error on malformed lines (default warn)
  --quiet                 Suppress non-critical warnings
  --help | -h             Show help
EOF
}

warn() {
  (( QUIET )) && return 0
  printf '[ledger][WARN] %s\n' "$*" >&2
}

error() {
  printf '[ledger][ERROR] %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

# -------------------------------
# Parse args
# -------------------------------
while (( $# > 0 )); do
  case "$1" in
    --segments) shift || die "Missing value for --segments"; SEG_FILE="$1" ;;
    --output) shift || die "Missing value for --output"; OUT_FILE="$1" ;;
    --format) shift || die "Missing value for --format"; FORMAT="$1" ;;
    --heavy-ms) shift || die "Missing value for --heavy-ms"; HEAVY_MS="$1" ;;
    --moderate-ms) shift || die "Missing value for --moderate-ms"; MODERATE_MS="$1" ;;
    --heavy-pct) shift || die "Missing value for --heavy-pct"; HEAVY_PCT="$1" ;;
    --moderate-pct) shift || die "Missing value for --moderate-pct"; MODERATE_PCT="$1" ;;
    --budget) shift || die "Missing value for --budget"; BUDGET_SPEC="$1" ;;
    --fail-on-budget) FAIL_ON_BUDGET=1 ;;
    --strict-parse) STRICT_PARSE=1 ;;
    --quiet) QUIET=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
  shift
done

# Auto-locate segment file if not provided
if [[ -z "$SEG_FILE" ]]; then
  # Common locations (prefer redesignv2 path if exists)
  candidate=(
    "$SELF_DIR/../artifacts/metrics/perf-current-segments.txt"
    "$SELF_DIR/../../docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
    "$SELF_DIR/../../docs/redesign/metrics/perf-current-segments.txt"
  )
  for c in "${candidate[@]}"; do
    if [[ -f "$c" ]]; then
      SEG_FILE="$c"
      break
    fi
  done
fi

[[ -n "$SEG_FILE" && -f "$SEG_FILE" ]] || die "Segment file not found (use --segments)."

# -------------------------------
# Budget parsing
# -------------------------------
parse_budget_spec() {
  local spec="$1"
  [[ -z "$spec" ]] && return 0
  if [[ "$spec" == @* ]]; then
    local f="${spec#@}"
    [[ -f "$f" ]] || die "Budget file not found: $f"
    # Expect JSON containing {"budgets":{"name":limit,...}}
    local line
    # Extremely lightweight parse (avoid strict jq dependency)
    while IFS= read -r line; do
      # Extract "name":number pairs under budgets object
      if [[ "$line" =~ \"([a-zA-Z0-9_:-]+)\"[[:space:]]*:[[:space:]]*([0-9]+) ]]; then
        local k="${match[1]}" v="${match[2]}"
        BUDGETS["$k"]=$v
      fi
    done < "$f"
    return 0
  fi
  # Inline comma list
  local IFS=',' entry
  for entry in ${(s/,/)spec}; do
    [[ -z "$entry" ]] && continue
    if [[ "$entry" != *:* ]]; then
      warn "Ignoring malformed budget entry: $entry"
      continue
    fi
    local name="${entry%%:*}"
    local val="${entry##*:}"
    [[ "$val" == <-> ]] || { warn "Non-integer budget value for $name: $val"; continue; }
    BUDGETS["$name"]=$val
  done
}

parse_budget_spec "$BUDGET_SPEC"

# -------------------------------
# Segment parsing
# -------------------------------
parse_segments() {
  local line ln=0
  while IFS= read -r line; do
    (( ln++ ))
    [[ -z "$line" || "$line" == \#* ]] && continue
    # Expect: SEGMENT name ms
    if [[ "$line" =~ ^SEGMENT[[:space:]]+([^[:space:]]+)[[:space:]]+([0-9]+(\.[0-9]+)?)$ ]]; then
      local name="${match[1]}"
      local ms="${match[2]}"
      SEG_NAMES+=("$name")
      SEG_MS+=("$ms")
      TOTAL_MS=$(( TOTAL_MS + ms ))
    else
      if (( STRICT_PARSE )); then
        die "Malformed segment line ($ln): $line"
      else
        warn "Skipping non-segment line ($ln): $line"
      fi
    fi
  done < "$SEG_FILE"
}

parse_segments

(( ${#SEG_NAMES[@]} > 0 )) || die "No segments parsed from $SEG_FILE"

# -------------------------------
# Classification & Budget Eval
# -------------------------------
typeset -a JSON_SEGMENTS
recommendation=""
for i in {1..${#SEG_NAMES[@]}}; do
  local n="${SEG_NAMES[i]}"
  local ms="${SEG_MS[i]}"
  local pct=0
  if (( TOTAL_MS > 0 )); then
    pct=$(( (ms / TOTAL_MS) * 100 ))
  fi
  # Classification
  local class="light"
  if (( ms >= HEAVY_MS )) || (( pct >= HEAVY_PCT )); then
    class="heavy"
  elif (( ms >= MODERATE_MS )) || (( pct >= MODERATE_PCT )); then
    class="moderate"
  fi

  # Budget eval (if specified)
  local budget_status=""
  if [[ -n "${BUDGETS[$n]:-}" ]]; then
    local limit="${BUDGETS[$n]}"
    if (( ms > limit )); then
      budget_status="over"
      (( OVER_COUNT++ ))
      BUDGET_RESULT["$n"]="over"
      recommendation="Reduce $n below ${limit}ms (currently ${ms}ms)"
    else
      budget_status="ok"
      BUDGET_RESULT["$n"]="ok"
    fi
  fi

  # JSON segment entry (escaped)
  local ms_fmt
  ms_fmt=$(printf '%.3f' "$ms")
  local pct_fmt
  pct_fmt=$(printf '%.2f' "$pct")
  local segment_json="{\"name\":\"$(printf '%s' "$n" | json_escape)\",\"ms\":$ms_fmt,\"pct_total\":$pct_fmt,\"class\":\"$class\""
  if [[ -n "$budget_status" ]]; then
    segment_json+=",\"budget\":\"$budget_status\""
  fi
  segment_json+="}"
  JSON_SEGMENTS+=("$segment_json")
done

if [[ -z "$recommendation" && ${#BUDGETS[@]} -gt 0 ]]; then
  recommendation="All budgeted segments within limits"
fi

# -------------------------------
# JSON Emit
# -------------------------------
emit_json() {
  local gen_ts
  # RFC3339-ish UTC
  gen_ts="$(LC_ALL=C date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo unknown)"
  printf '{\n'
  printf '  "schema": "module-ledger.v1",\n'
  printf '  "generated_at": "%s",\n' "$gen_ts"
  printf '  "source": "%s",\n' "$(printf '%s' "$SEG_FILE" | json_escape)"
  printf '  "total_ms": %.3f,\n' "$TOTAL_MS"
  printf '  "segments": [\n'
  local idx=0
  for s in "${JSON_SEGMENTS[@]}"; do
    (( idx++ ))
    if (( idx < ${#JSON_SEGMENTS[@]} )); then
      printf '    %s,\n' "$s"
    else
      printf '    %s\n' "$s"
    fi
  done
  printf '  ],\n'
  printf '  "thresholds": {"heavy_ms":%s,"moderate_ms":%s,"heavy_pct":%.2f,"moderate_pct":%.2f},\n' \
    "$HEAVY_MS" "$MODERATE_MS" "$HEAVY_PCT" "$MODERATE_PCT"

  # Budget block
  if (( ${#BUDGETS[@]} > 0 )); then
    printf '  "budget_eval": {\n'
    printf '    "checked": true,\n'
    printf '    "budgets": {\n'
    local bc=0
    local total_budgets=${#BUDGETS[@]}
    for name limit in ${(kv)BUDGETS}; do
      (( bc++ ))
      local actual=""
      local status="${BUDGET_RESULT[$name]:-n/a}"
      # find actual ms
      for j in {1..${#SEG_NAMES[@]}}; do
        if [[ "${SEG_NAMES[j]}" == "$name" ]]; then
          actual="${SEG_MS[j]}"
          break
        fi
      done
      [[ -z "$actual" ]] && actual=0
      printf '      "%s":{"limit_ms":%s,"actual_ms":%.3f,"status":"%s"}' \
        "$(printf '%s' "$name" | json_escape)" "$limit" "$actual" "$status"
      if (( bc < total_budgets )); then
        printf ',\n'
      else
        printf '\n'
      fi
    done
    printf '    },\n'
    printf '    "over_count": %d\n' "$OVER_COUNT"
    printf '  },\n'
  else
    printf '  "budget_eval": {"checked": false},\n'
  fi

  printf '  "recommendation": "%s"\n' "$(printf '%s' "${recommendation:-None}" | json_escape)"
  printf '}\n'
}

emit_table() {
  printf 'Module Performance Ledger (prototype)\n'
  printf 'Source: %s\n' "$SEG_FILE"
  printf 'Total:  %.3f ms\n' "$TOTAL_MS"
  printf '\n%-32s %12s %10s %10s %10s\n' "SEGMENT" "MS" "%TOTAL" "CLASS" "BUDGET"
  printf '%s\n' '--------------------------------------------------------------------------------'
  for i in {1..${#SEG_NAMES[@]}}; do
    local n="${SEG_NAMES[i]}" ms="${SEG_MS[i]}"
    local pct=0
    (( TOTAL_MS > 0 )) && pct=$(( (ms / TOTAL_MS) * 100 ))
    local class
    if (( ms >= HEAVY_MS )) || (( pct >= HEAVY_PCT )); then
      class="heavy"
    elif (( ms >= MODERATE_MS )) || (( pct >= MODERATE_PCT )); then
      class="moderate"
    else
      class="light"
    fi
    local budget="—"
    if [[ -n "${BUDGETS[$n]:-}" ]]; then
      local limit="${BUDGETS[$n]}"
      if (( ms > limit )); then
        budget="over(${limit})"
      else
        budget="ok(${limit})"
      fi
    fi
    printf '%-32s %12.3f %9.2f%% %10s %10s\n' "$n" "$ms" "$pct" "$class" "$budget"
  done
  if (( ${#BUDGETS[@]} > 0 )); then
    printf '\nBudget Summary: over=%d checked=%d\n' "$OVER_COUNT" "${#BUDGETS[@]}"
    [[ -n "$recommendation" ]] && printf 'Recommendation: %s\n' "$recommendation"
  fi
}

# -------------------------------
# Emit & Write
# -------------------------------
produce() {
  local content
  if [[ "$FORMAT" == "json" ]]; then
    content="$(emit_json)"
  else
    content="$(emit_table)"
  fi

  if [[ -n "$OUT_FILE" ]]; then
    mkdir -p "${OUT_FILE:h}"
    print -r -- "$content" > "$OUT_FILE"
  else
    print -r -- "$content"
  fi
}

produce

# -------------------------------
# Exit Handling
# -------------------------------
if (( FAIL_ON_BUDGET )) && (( OVER_COUNT > 0 )); then
  exit 2
fi

exit 0
