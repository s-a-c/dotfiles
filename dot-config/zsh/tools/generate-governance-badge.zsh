#!/usr/bin/env zsh
# generate-governance-badge.zsh
#
# Combined Governance Badge / Meta Summary (Draft)
#
# PURPOSE:
#   Produce a single Shields-compatible JSON badge + rich JSON payload
#   aggregating key redesign governance signals:
#     - Performance drift (perf-drift.json)
#     - Budget / ledger status (perf-ledger.json)
#     - Variance / enforcement mode (derived or external future variance-state.json)
#     - Micro benchmark regression snapshot (bench-core-baseline.json vs optional current)
#
#   The badge condenses multi-signal health into one quick-to-scan indicator
#   for maintainers and promotion guard pre-checks.
#
# OUTPUT MODES:
#   1. Badge JSON (default): minimal fields for Shields endpoint
#   2. Extended JSON (--extended / GOV_BADGE_EXTENDED=1): includes schema + stats + badge
#
# BADGE MESSAGE FORMAT (examples):
#   "ok"
#   "warn regress=2 max=7.1% budget=0"
#   "fail max=15.2% over=3"
#
# SEVERITY LOGIC (defaults, configurable):
#   FAIL when any:
#     - max_regression_pct >= FAIL_REG_THRESH (default 10)
#     - over_budget_count > 0 AND variance_mode == gate
#     - microbench_worst_ratio >= MICRO_FAIL_FACTOR (default 3.0) (if micro active & no shims)
#   WARN when (and no FAIL):
#     - max_regression_pct >= WARN_REG_THRESH (default 5)
#     - over_budget_count > 0 (observe/warn mode)
#     - microbench_worst_ratio >= MICRO_WARN_FACTOR (default 2.0)
#     - shimmed_count > 0 (micro baseline not finalized)
#
# EXIT CODES:
#   0 success
#   1 usage / argument error
#   2 processing / parsing failure (unexpected malformed JSON)
#
# REQUIRED / OPTIONAL INPUT FILES (auto-detected unless overridden):
#   perf drift badge:   docs/redesignv2/artifacts/badges/perf-drift.json
#   perf ledger:        docs/redesignv2/artifacts/metrics/perf-ledger.json
#   micro bench base:   docs/redesignv2/artifacts/metrics/bench-core-baseline.json
#   variance (future):  docs/redesignv2/artifacts/badges/variance-state.json (optional)
#
# ARGUMENTS:
#   --output <file>     Write badge JSON to file (default prints to stdout)
#   --extended          Emit extended governance JSON (badge + stats)
#   --badge-only        Force simple badge JSON even if extended env set
#   --help              Show help
#
# ENVIRONMENT OVERRIDES:
#   GOV_BADGE_OUTPUT                (path)
#   GOV_BADGE_EXTENDED=1            (extended JSON)
#   GOV_BADGE_BADGE_ONLY=1          (force minimal)
#   GOV_BADGE_BASE_DIR              (root for docs/redesignv2) default: current working directory
#
#   GOV_DRIFT_FILE                  (path to perf-drift.json)
#   GOV_LEDGER_FILE                 (path to perf-ledger.json)
#   GOV_MICRO_BASELINE_FILE         (bench-core-baseline.json)
#   GOV_VARIANCE_FILE               (variance-state.json or NONE)
#
#   WARN_REG_THRESH=5               (%)
#   FAIL_REG_THRESH=10              (%)
#   MICRO_WARN_FACTOR=2.0
#   MICRO_FAIL_FACTOR=3.0
#
#   GOV_COLOR_OK=green GOV_COLOR_WARN=yellow GOV_COLOR_FAIL=red GOV_COLOR_UNKNOWN=lightgrey
#
# SAFETY:
#   Read-only. No network. Degrades gracefully if inputs missing.
#
# SCHEMA (extended):
# {
#   "schema":"governance-badge.v1",
#   "generated_at":"UTC_ISO8601",
#   "sources":{ ... },
#   "stats":{
#     "regressions":0,
#     "max_regression_pct":0.0,
#     "over_budget_count":0,
#     "variance_mode":"observe|warn|gate|unknown",
#     "microbench_regress_count":0,
#     "microbench_worst_ratio":1.0,
#     "shimmed":0
#   },
#   "badge":{"label":"governance","message":"ok","color":"green"}
# }
#
# NOTE:
#   - The micro benchmark regression count / ratio are placeholders until a
#     dedicated "current" capture vs baseline diff path is standardized.
#   - For now, only baseline (shimmed_count) is inspected (no drift compare).
#
# FUTURE ENHANCEMENTS:
#   - Direct integration of perf-diff JSON (skip double parse perf-drift badge)
#   - Historical trend deltas
#   - Rolling micro bench drift detection
#   - Adaptive threshold gating
#
set -euo pipefail

print_help() {
  sed -n '1,160p' "$0" | grep -E '^#( |$)' | sed 's/^# \{0,1\}//'
  cat <<EOF

Usage:
  $0 [--output file] [--extended] [--badge-only]

Examples:
  $0 --extended --output docs/redesignv2/artifacts/badges/governance.json
  GOV_BADGE_EXTENDED=1 $0 > governance.json

EOF
}

# ---------------- Defaults / Args ----------------
: "${GOV_BADGE_BASE_DIR:=${PWD}}"

OUTPUT_FILE=""
EXTENDED="${GOV_BADGE_EXTENDED:-0}"
BADGE_ONLY="${GOV_BADGE_BADGE_ONLY:-0}"

while (( $# )); do
  case "$1" in
    --output) shift; OUTPUT_FILE="${1:-}";;
    --extended) EXTENDED=1;;
    --badge-only) BADGE_ONLY=1;;
    --help|-h) print_help; exit 0;;
    --) shift; break;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 1;;
  esac
  shift || true
done

# Paths
default_root="$GOV_BADGE_BASE_DIR/docs/redesignv2/artifacts"
: "${GOV_DRIFT_FILE:=${default_root}/badges/perf-drift.json}"
: "${GOV_LEDGER_FILE:=${default_root}/metrics/perf-ledger.json}"
: "${GOV_MICRO_BASELINE_FILE:=${default_root}/metrics/bench-core-baseline.json}"
: "${GOV_VARIANCE_FILE:=${default_root}/badges/variance-state.json}"

# Thresholds
: "${WARN_REG_THRESH:=5}"
: "${FAIL_REG_THRESH:=10}"
: "${MICRO_WARN_FACTOR:=2.0}"
: "${MICRO_FAIL_FACTOR:=3.0}"

# Colors
: "${GOV_COLOR_OK:=green}"
: "${GOV_COLOR_WARN:=yellow}"
: "${GOV_COLOR_FAIL:=red}"
: "${GOV_COLOR_UNKNOWN:=lightgrey}"

label="governance"

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

# ---------------- Helpers ----------------
num_or_zero() {
  local v=$1
  [[ "$v" =~ ^-?[0-9]+([.][0-9]+)?$ ]] || { echo 0; return 0; }
  echo "$v"
}

read_json_field_jq() {
  local file=$1 jq_expr=$2 default=${3:-}
  if (( have_jq )); then
    jq -r "$jq_expr // empty" "$file" 2>/dev/null || true
  else
    # very light fallback attempt
    grep -E "\"$jq_expr\"" "$file" 2>/dev/null | head -1 | sed -E 's/.*"'$jq_expr'"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' || true
  fi
}

extract_drift() {
  # perf-drift badge (already flattened)
  local f=$1
  local regressions=0 max_pct=0
  local ok=0
  if [[ -f "$f" ]]; then
    ok=1
    if (( have_jq )); then
      # "message":"2 warn (+7.1% max)"
      local msg
      msg=$(jq -r '.message // empty' "$f" 2>/dev/null || true)
      if [[ -n "$msg" ]]; then
        # Extract first integer (regressions)
        regressions=$(echo "$msg" | sed -n 's/^\([0-9]\+\).*/\1/p')
        [[ -z "$regressions" ]] && regressions=0
        # Extract +X.Y% max
        local pct
        pct=$(echo "$msg" | sed -n 's/.*+ \{0,1\}\([0-9]\+\(\.[0-9]\+\)\?\)% max.*/\1/p' | tr -d '+')
        [[ -z "$pct" ]] && pct=$(echo "$msg" | sed -n 's/.*+\([0-9]\+\(\.[0-9]\+\)\?\)% max.*/\1/p')
        [[ -z "$pct" ]] && pct=0
        max_pct="$pct"
      fi
    else
      local msg
      msg=$(grep -E '"message"' "$f" 2>/dev/null | sed -E 's/.*"message"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' | head -1)
      if [[ -n "$msg" ]]; then
        regressions=$(echo "$msg" | sed -n 's/^\([0-9]\+\).*/\1/p')
        [[ -z "$regressions" ]] && regressions=0
        local pct
        pct=$(echo "$msg" | sed -n 's/.*+\([0-9]\+\(\.[0-9]\+\)\?\)% max.*/\1/p')
        [[ -z "$pct" ]] && pct=0
        max_pct="$pct"
      fi
    fi
  fi
  echo "$ok;$regressions;$max_pct"
}

extract_ledger() {
  local f=$1
  local ok=0 over=0
  if [[ -f "$f" ]]; then
    ok=1
    if (( have_jq )); then
      over=$(jq -r '.budget_eval.over_count // .overBudgetCount // 0' "$f" 2>/dev/null || echo 0)
    else
      over=$(grep -E '"over_count"' "$f" 2>/dev/null | sed -n 's/.*"over_count"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' | head -1)
      [[ -z "$over" ]] && over=$(grep -E '"overBudgetCount"' "$f" 2>/dev/null | sed -n 's/.*"overBudgetCount"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' | head -1)
      [[ -z "$over" ]] && over=0
    fi
  fi
  echo "$ok;$over"
}

extract_micro_baseline() {
  local f=$1
  local ok=0 shimmed=0 fn=0
  if [[ -f "$f" ]]; then
    ok=1
    if (( have_jq )); then
      shimmed=$(jq -r '.shimmed_count // 0' "$f" 2>/dev/null || echo 0)
      fn=$(jq -r '.functions | length' "$f" 2>/dev/null || echo 0)
    else
      shimmed=$(grep -E '"shimmed_count"' "$f" | sed -n 's/.*"shimmed_count"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' | head -1)
      [[ -z "$shimmed" ]] && shimmed=0
      fn=$(grep -c '"name"' "$f" 2>/dev/null || echo 0)
    fi
  fi
  echo "$ok;$shimmed;$fn"
}

extract_variance_mode() {
  local f=$1
  local mode="unknown" ok=0
  if [[ -f "$f" ]]; then
    ok=1
    if (( have_jq )); then
      mode=$(jq -r '.mode // .state // empty' "$f" 2>/dev/null || true)
      [[ -z "$mode" ]] && mode="unknown"
    else
      mode=$(grep -E '"(mode|state)"' "$f" 2>/dev/null | head -1 | sed -E 's/.*"(mode|state)"[[:space:]]*:[[:space:]]*"([^"]*)".*/\2/')
      [[ -z "$mode" ]] && mode="unknown"
    fi
  fi
  echo "$ok;$mode"
}

# ---------------- Data Extraction ----------------
drift_raw=$(extract_drift "$GOV_DRIFT_FILE")
drift_ok=${drift_raw%%;*}
drift_rest=${drift_raw#*;}
drift_regress=${drift_rest%%;*}
drift_max_pct=${drift_rest#*;}

ledger_raw=$(extract_ledger "$GOV_LEDGER_FILE")
ledger_ok=${ledger_raw%%;*}
ledger_over=${ledger_raw#*;}

micro_raw=$(extract_micro_baseline "$GOV_MICRO_BASELINE_FILE")
micro_ok=${micro_raw%%;*}
micro_rest=${micro_raw#*;}
micro_shimmed=${micro_rest%%;*}
micro_fn=${micro_rest#*;}

variance_raw=$(extract_variance_mode "$GOV_VARIANCE_FILE")
variance_ok=${variance_raw%%;*}
variance_mode=${variance_raw#*;}

# Placeholder micro bench regression stats (future drift compare)
micro_regress_count=0
micro_worst_ratio=1.0

# ---------------- Severity Computation ----------------
max_reg_pct_num=$(num_or_zero "$drift_max_pct")
over_budget_num=$(num_or_zero "$ledger_over")
shimmed_num=$(num_or_zero "$micro_shimmed")

severity="ok"
color="$GOV_COLOR_OK"
details=()

float_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }

if float_ge "$max_reg_pct_num" "$FAIL_REG_THRESH"; then
  severity="fail"; details+=("max=${max_reg_pct_num}%")
fi

if [[ "$severity" != "fail" ]] && float_ge "$max_reg_pct_num" "$WARN_REG_THRESH"; then
  severity="warn"; details+=("max=${max_reg_pct_num}%")
fi

# Budget gating logic
if (( over_budget_num > 0 )); then
  if [[ "$variance_mode" == "gate" ]]; then
    severity="fail"
    details+=("over=${over_budget_num}")
  else
    [[ "$severity" == "ok" ]] && severity="warn"
    details+=("over=${over_budget_num}")
  fi
fi

# Micro benchmark heuristic (only if no shims)
if (( micro_ok )) && (( shimmed_num > 0 )); then
  # shim presence = warn (cannot trust ratios)
  if [[ "$severity" == "ok" ]]; then
    severity="warn"
  fi
  details+=("shimmed=${shimmed_num}")
fi

# (Future) ratio thresholds - placeholder uses worst_ratio (currently 1.0)
if (( micro_ok )) && (( shimmed_num == 0 )); then
  if float_ge "$micro_worst_ratio" "$MICRO_FAIL_FACTOR"; then
    severity="fail"; details+=("micro_ratio=${micro_worst_ratio}")
  elif float_ge "$micro_worst_ratio" "$MICRO_WARN_FACTOR"; then
    [[ "$severity" == "ok" ]] && severity="warn"
    details+=("micro_ratio=${micro_worst_ratio}")
  fi
fi

case "$severity" in
  fail) color="$GOV_COLOR_FAIL" ;;
  warn) color="$GOV_COLOR_WARN" ;;
  ok)   color="$GOV_COLOR_OK" ;;
  *)    color="$GOV_COLOR_UNKNOWN" ;;
esac

message="$severity"
if (( ${#details[@]} )); then
  message="$message ${details[*]}"
fi

# If nothing available at all, degrade message
if (( ! drift_ok && ! ledger_ok && ! micro_ok )); then
  message="no-data"
  color="$GOV_COLOR_UNKNOWN"
fi

# ---------------- Emit JSON ----------------
emit_badge_only() {
  printf '{"label":"%s","message":"%s","color":"%s"}\n' \
    "$label" \
    "$(printf '%s' "$message" | sed 's/"/\\"/g')" \
    "$color"
}

emit_extended() {
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)
  cat <<JSON
{
  "schema": "governance-badge.v1",
  "generated_at": "$ts",
  "sources": {
    "perf_drift": "$( [[ $drift_ok == 1 ]] && echo "$GOV_DRIFT_FILE" || echo "missing" )",
    "perf_ledger": "$( [[ $ledger_ok == 1 ]] && echo "$GOV_LEDGER_FILE" || echo "missing" )",
    "variance_state": "$( [[ $variance_ok == 1 ]] && echo "$GOV_VARIANCE_FILE" || echo "derived")",
    "micro_bench": "$( [[ $micro_ok == 1 ]] && echo "$GOV_MICRO_BASELINE_FILE" || echo "missing" )"
  },
  "stats": {
    "regressions": $(num_or_zero "$drift_regress"),
    "max_regression_pct": $(num_or_zero "$max_reg_pct_num"),
    "over_budget_count": $(num_or_zero "$over_budget_num"),
    "variance_mode": "$(printf '%s' "$variance_mode")",
    "microbench_regress_count": $(num_or_zero "$micro_regress_count"),
    "microbench_worst_ratio": $(num_or_zero "$micro_worst_ratio"),
    "shimmed": $(num_or_zero "$shimmed_num")
  },
  "badge": {
    "label": "$label",
    "message": "$(printf '%s' "$message" | sed 's/"/\\"/g')",
    "color": "$color"
  }
}
JSON
}

want_extended=0
if (( EXTENDED )) && (( BADGE_ONLY == 0 )); then
  want_extended=1
fi

output_content=""
if (( want_extended )); then
  output_content="$(emit_extended)"
else
  output_content="$(emit_badge_only)"
fi

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")" 2>/dev/null || true
  printf '%s\n' "$output_content" >| "$OUTPUT_FILE"
  printf 'Wrote governance badge JSON: %s\n' "$OUTPUT_FILE" >&2
else
  printf '%s\n' "$output_content"
fi

exit 0
