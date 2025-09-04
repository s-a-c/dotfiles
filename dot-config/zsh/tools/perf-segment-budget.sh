#!/usr/bin/env bash
# perf-segment-budget.sh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Enforce (or dry‑run check) per‑segment and aggregate ZSH startup performance budgets
#   using the normalized SEGMENT lines emitted into perf-current-segments.txt.
#
#   This script prepares Phase 3 (budget) gating by allowing CI / promotion guard
#   to assert that critical hotspots remain below interim or final thresholds.
#
# COVERED SEGMENTS (default set):
#   pre_plugin_total
#   post_plugin_total
#   prompt_ready
#   compinit
#   p10k_theme
#   gitstatus_init   (may be missing if plugin not detected yet)
#
# PHASES:
#   Interim (default): Softer, higher ceilings (optimization in progress)
#   Final (PERF_BUDGET_PHASE=final): Tight, promotion‑ready ceilings
#
# DEFAULT BUDGETS (ms):
#   Phase     | pre_plugin | post_plugin | prompt_ready | compinit | p10k_theme | gitstatus_init
#   Interim   | 120        | 3000        | 3500         | 400      | 900        | 250
#   Final     | 100        | 500         | 1000         | 250      | 600        | 150
#
# ENVIRONMENT OVERRIDES:
#   PERF_SEGMENTS_FILE=</path/to/perf-current-segments.txt>
#   PERF_BUDGET_PHASE=interim|final
#   ENFORCE=1                      Fail (exit 2) on budget violation (default 0 -> report only)
#   BUDGET_<LABEL>=<ms>            Override for a specific label (LABEL uppercased, non-alnum → _)
#   ALLOW_MISSING_<LABEL>=1        Treat missing segment as informational instead of failure
#   FAIL_ON_MISSING=1              Force failure if any required segment missing (default 0)
#   OUTPUT_MODE=text|json          Structured JSON output if 'json'
#
# EXIT CODES:
#   0 Success (all budgets satisfied OR only warnings in non‑enforce mode)
#   1 Infrastructure / usage error (missing file, parse issue)
#   2 Budget failure (when ENFORCE=1 AND one or more budgets violated or required segments missing)
#
# OUTPUT:
#   Delimited block for machine parsing:
#     --- PERF_BUDGET_BEGIN ---
#     status=PASS|FAIL|ERROR
#     phase=<interim|final>
#     enforce=<0|1>
#     segments_file=<path>
#     violations=<int>
#     missing_required=<int>
#     (per-segment lines: segment=<name> ms=<value|missing> budget=<budget|n/a> status=PASS|FAIL|MISSING reason=<text>)
#     summary=<short line>
#     --- PERF_BUDGET_END ---
#
#   If OUTPUT_MODE=json a single JSON object is printed instead of text block.
#
# USAGE:
#   ./perf-segment-budget.sh                  # Dry run (observe)
#   ENFORCE=1 ./perf-segment-budget.sh        # Enforce budgets (CI gate)
#   PERF_BUDGET_PHASE=final ENFORCE=1 ./perf-segment-budget.sh
#
# NOTES:
#   - Budgets should be kept in sync with IMPLEMENTATION.md Performance Roadmap.
#   - Missing gitstatus_init is common early; allow via ALLOW_MISSING_GITSTATUS_INIT=1 until stable.
#   - For new segments simply add them to the SEGMENTS array with a budget.
#
# FUTURE ENHANCEMENTS:
#   - Automatic suggestion of updated budgets based on statistical multi-sample aggregates.
#   - Tiered severity (soft vs hard budgets).
#   - Integration with perf-diff JSON output for contextual regressions.
#
set -euo pipefail

SCRIPT_NAME="${0##*/}"

log() { printf '[perf-budget] %s\n' "$*"; }
err() { printf '[perf-budget][error] %s\n' "$*" >&2; }

usage() {
  cat <<EOF
$SCRIPT_NAME - Segment performance budget checker

Environment:
  PERF_SEGMENTS_FILE   Path to perf-current-segments.txt (auto-detected if unset)
  PERF_BUDGET_PHASE    interim (default) | final
  ENFORCE=1            Exit 2 if any violations (default observe mode)
  OUTPUT_MODE=json     Emit JSON instead of text block
  BUDGET_<LABEL>       Override budget for segment label (LABEL uppercased)
  ALLOW_MISSING_<LABEL>=1  Do not fail if that segment is missing
  FAIL_ON_MISSING=1    Treat ANY missing required segment as failure
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

# ---------------- Locate segments file ----------------
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
default_segments_file="$ZDOTDIR/docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
legacy_segments_file="$ZDOTDIR/docs/redesign/metrics/perf-current-segments.txt"

SEGMENTS_FILE="${PERF_SEGMENTS_FILE:-}"
if [[ -z "$SEGMENTS_FILE" ]]; then
  if [[ -f "$default_segments_file" ]]; then
    SEGMENTS_FILE="$default_segments_file"
  elif [[ -f "$legacy_segments_file" ]]; then
    SEGMENTS_FILE="$legacy_segments_file"
  fi
fi

if [[ -z "$SEGMENTS_FILE" || ! -f "$SEGMENTS_FILE" ]]; then
  err "segments file not found (set PERF_SEGMENTS_FILE or run perf-capture tooling)"
  echo "--- PERF_BUDGET_BEGIN ---"
  echo "status=ERROR"
  echo "phase=${PERF_BUDGET_PHASE:-interim}"
  echo "enforce=${ENFORCE:-0}"
  echo "segments_file=${SEGMENTS_FILE:-missing}"
  echo "violations=n/a"
  echo "missing_required=n/a"
  echo "summary=segments file missing"
  echo "--- PERF_BUDGET_END ---"
  exit 1
fi

# ---------------- Define default budgets ----------------
PHASE="${PERF_BUDGET_PHASE:-interim}"
case "$PHASE" in
  final)
    DEF_PRE_PLUGIN=100
    DEF_POST_PLUGIN=500
    DEF_PROMPT_READY=1000
    DEF_COMPINIT=250
    DEF_P10K_THEME=600
    DEF_GITSTATUS_INIT=150
    ;;
  interim|*)
    PHASE="interim"
    DEF_PRE_PLUGIN=120
    DEF_POST_PLUGIN=3000
    DEF_PROMPT_READY=3500
    DEF_COMPINIT=400
    DEF_P10K_THEME=900
    DEF_GITSTATUS_INIT=250
    ;;
esac

# ---------------- Segment list & budgets ----------------
# Order matters for reporting: lifecycle totals first then hotspots
SEGMENTS=(
  pre_plugin_total
  post_plugin_total
  prompt_ready
  compinit
  p10k_theme
  gitstatus_init
)

# Map defaults
declare -A BUDGET_DEFAULT=(
  [pre_plugin_total]="$DEF_PRE_PLUGIN"
  [post_plugin_total]="$DEF_POST_PLUGIN"
  [prompt_ready]="$DEF_PROMPT_READY"
  [compinit]="$DEF_COMPINIT"
  [p10k_theme]="$DEF_P10K_THEME"
  [gitstatus_init]="$DEF_GITSTATUS_INIT"
)

# Allow overrides via environment BUDGET_<LABEL>
get_budget_for() {
  local label="$1" u override_var
  u=$(echo "$label" | tr '[:lower:]-' '[:upper:]_')
  override_var="BUDGET_${u}"
  local val="${!override_var:-}"
  if [[ -n "$val" ]]; then
    echo "$val"
  else
    echo "${BUDGET_DEFAULT[$label]}"
  fi
}

# ---------------- Helpers ----------------
get_segment_ms() {
  # Parse ms value from SEGMENT line; returns empty if not found
  local label="$1"
  local line
  line=$(grep -E "^SEGMENT name=${label} " "$SEGMENTS_FILE" 2>/dev/null | head -1 || true)
  if [[ -z "$line" ]]; then
    echo ""
    return 0
  fi
  echo "$line" | sed -E 's/.* ms=([0-9]+).*/\1/'
}

allow_missing() {
  local label="$1" u
  u=$(echo "$label" | tr '[:lower:]-' '[:upper:]_')
  local var="ALLOW_MISSING_${u}"
  [[ "${!var:-0}" == "1" ]] && return 0 || return 1
}

is_number() { [[ "$1" =~ ^[0-9]+$ ]]; }

# ---------------- Evaluation ----------------
ENFORCE="${ENFORCE:-0}"
FAIL_ON_MISSING="${FAIL_ON_MISSING:-0}"
OUTPUT_MODE="${OUTPUT_MODE:-text}"

violations=0
missing_required=0
declare -A RESULT_MS
declare -A RESULT_STATUS
declare -A RESULT_REASON
declare -A RESULT_BUDGET

for seg in "${SEGMENTS[@]}"; do
  ms=$(get_segment_ms "$seg")
  budget=$(get_budget_for "$seg")
  RESULT_BUDGET[$seg]="$budget"
  if [[ -z "$ms" ]]; then
    RESULT_MS[$seg]="missing"
    if allow_missing "$seg"; then
      RESULT_STATUS[$seg]="MISSING"
      RESULT_REASON[$seg]="segment not emitted (allowed)"
    else
      RESULT_STATUS[$seg]="MISSING"
      RESULT_REASON[$seg]="segment not emitted"
      ((missing_required++))
    fi
    continue
  fi
  RESULT_MS[$seg]="$ms"
  if ! is_number "$ms"; then
    RESULT_STATUS[$seg]="FAIL"
    RESULT_REASON[$seg]="non-numeric ms"
    ((violations++))
    continue
  fi
  if (( ms <= budget )); then
    RESULT_STATUS[$seg]="PASS"
    RESULT_REASON[$seg]="within budget"
  else
    RESULT_STATUS[$seg]="FAIL"
    RESULT_REASON[$seg]="exceeds budget by $(( ms - budget ))ms"
    ((violations++))
  fi
done

# Determine overall status
overall_status="PASS"
summary_detail="all budgets satisfied"
if (( missing_required > 0 )); then
  summary_detail="${missing_required} required segment(s) missing"
  [[ "$overall_status" == "PASS" ]] && overall_status="FAIL"
fi
if (( violations > 0 )); then
  summary_detail="${violations} budget violation(s); ${summary_detail}"
  overall_status="FAIL"
fi
if [[ "$overall_status" == "PASS" && "$PHASE" == "interim" ]]; then
  summary_detail="${summary_detail} (interim phase)"
fi

exit_code=0
if [[ "$overall_status" == "FAIL" && "$ENFORCE" == "1" ]]; then
  exit_code=2
fi

# ---------------- Output ----------------
if [[ "$OUTPUT_MODE" == "json" ]]; then
  # JSON emission
  echo "{"
  echo "  \"schema\":\"perf-segment-budget.v1\","
  echo "  \"phase\":\"$PHASE\","
  echo "  \"enforce\":$ENFORCE,"
  echo "  \"status\":\"$overall_status\","
  echo "  \"segments_file\":\"$SEGMENTS_FILE\","
  echo "  \"violations\":$violations,"
  echo "  \"missing_required\":$missing_required,"
  echo "  \"results\":["
  first=1
  for seg in "${SEGMENTS[@]}"; do
    [[ $first -eq 1 ]] && first=0 || echo "    ,"
    printf '    { "label":"%s", "ms":"%s", "budget":%s, "status":"%s", "reason":"%s" }' \
      "$seg" "${RESULT_MS[$seg]}" "${RESULT_BUDGET[$seg]}" "${RESULT_STATUS[$seg]}" "${RESULT_REASON[$seg]}"
    echo ""
  done
  echo "  ],"
  echo "  \"summary\":\"$summary_detail\""
  echo "}"
else
  echo "--- PERF_BUDGET_BEGIN ---"
  echo "status=${overall_status}"
  echo "phase=${PHASE}"
  echo "enforce=${ENFORCE}"
  echo "segments_file=${SEGMENTS_FILE}"
  echo "violations=${violations}"
  echo "missing_required=${missing_required}"
  for seg in "${SEGMENTS[@]}"; do
    echo "segment=${seg} ms=${RESULT_MS[$seg]} budget=${RESULT_BUDGET[$seg]} status=${RESULT_STATUS[$seg]} reason=${RESULT_REASON[$seg]}"
  done
  echo "summary=${summary_detail}"
  echo "--- PERF_BUDGET_END ---"
fi

exit "$exit_code"
