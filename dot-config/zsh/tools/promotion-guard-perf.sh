#!/usr/bin/env bash
# promotion-guard-perf.sh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Non-failing performance promotion guard hook (Stage: OBSERVE ONLY).
#   Integrates perf-diff regression reporting into a promotion / CI pipeline
#   without yet enforcing hard failures. Emits structured summary that future
#   stages can parse once gating turns on.
#
# FUNCTION:
#   1. Locate current and baseline segment timing files.
#   2. Run perf-diff in warn-only mode (regression thresholds configurable).
#   3. Emit clearly delimited BEGIN/END block for log parsing.
#   4. Exit 0 unless a fatal infrastructure error occurs (missing tool/script).
#
# WHEN TO FAIL (FUTURE):
#   - After confidence in instrumentation: enable FAIL mode (see TODO).
#   - Optionally require minimum segment coverage (e.g., presence of compinit, p10k_theme).
#
# INPUTS (Environment Variables):
#   PROMOTION_GUARD_PERF_BASELINE        Path to baseline segments file
#   PROMOTION_GUARD_PERF_CURRENT         Path to current segments file (auto-detect if unset)
#   PROMOTION_GUARD_PERF_DIFF            Path to perf-diff.sh (auto-detect if unset)
#   PROMOTION_GUARD_PERF_THRESHOLD_ABS   Override absolute delta ms (default 75)
#   PROMOTION_GUARD_PERF_THRESHOLD_PCT   Override percentage delta (default 25)
#   PROMOTION_GUARD_PERF_NEW_ALLOW       Override new segment allow ms (default 150)
#   PROMOTION_GUARD_PERF_VERBOSE=1       Extra diagnostics
#   PROMOTION_GUARD_PERF_FAIL=1          (FUTURE) Enforce failure on regressions (currently ignored)
#
# AUTO-DETECTION ORDER:
#   Current segments:
#     1. $PROMOTION_GUARD_PERF_CURRENT
#     2. $ZDOTDIR/docs/redesignv2/artifacts/metrics/perf-current-segments.txt
#     3. $ZDOTDIR/docs/redesign/metrics/perf-current-segments.txt
#   Baseline:
#     1. $PROMOTION_GUARD_PERF_BASELINE
#     2. Same directories but 'perf-baseline-segments.txt'
#
# OUTPUT FORMAT (Delimited Block):
#   --- PERF_GUARD_BEGIN ---
#   status=OK|SKIP|ERROR
#   mode=observe
#   baseline=<path or empty>
#   current=<path or empty>
#   thresholds abs=<ms> pct=<pct>% new_allow=<ms>
#   regressions=<count or n/a>
#   new_segments=<count or n/a>
#   removed_segments=<count or n/a>
#   improvements=<count or n/a>
#   multi_samples=<int|n/a>
#   multi_post_plugin_mean=<ms|n/a>
#   multi_post_plugin_stddev=<ms|n/a>
#   async_tasks_total=<int|n/a>
#   async_tasks_done=<int|n/a>
#   async_tasks_fail=<int|n/a>
#   async_tasks_timeout=<int|n/a>
#   async_overhead_ms=<ms|n/a>
#   sync_path_total_ms=<ms|n/a>
#   sync_reduction_pct=<pct|n/a>
#   summary=<short human line>
#   (diff lines excerpt...)
#   --- PERF_GUARD_END ---
#
# EXIT CODES:
#   0  Always (unless an unexpected internal error occurs)
#   2  (Reserved for future FAIL mode)
#
# SECURITY / POLICY:
#   - Read-only usage of metrics artifacts.
#   - No network access.
#   - Compliant with project orchestration policy (checksum embedded above).
#
# TODO (Future Phases):
#   - Enforce FAIL mode based on PROMOTION_GUARD_PERF_FAIL or pipeline stage.
#   - Integrate JSON output from perf-diff (--json) for machine parsing.
#   - Add coverage thresholds (required set of segment labels).
#   - Persist rolling baselines or auto-update baseline after approval.
#
set -euo pipefail

# ------------- Helpers -------------
log() {
  echo "[perf-guard] $*"
}
debug() {
  [[ "${PROMOTION_GUARD_PERF_VERBOSE:-0}" == "1" ]] && log "DEBUG: $*"
}

colorize() {
  local color="$1"; shift
  if [[ -t 1 ]]; then
    case "$color" in
      red)    printf '\033[31m%s\033[0m\n' "$*" ;;
      green)  printf '\033[32m%s\033[0m\n' "$*" ;;
      yellow) printf '\033[33m%s\033[0m\n' "$*" ;;
      *)      printf '%s\n' "$*" ;;
    esac
  else
    printf '%s\n' "$*"
  fi
}

# ------------- Locate Paths -------------
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
detect_file() {
  local explicit="$1" v2="$2" v1="$3"
  if [[ -n "$explicit" && -f "$explicit" ]]; then
    printf '%s' "$explicit"; return 0
  fi
  if [[ -f "$v2" ]]; then printf '%s' "$v2"; return 0; fi
  if [[ -f "$v1" ]]; then printf '%s' "$v1"; return 0; fi
  printf '' # none
}

CURRENT_SEGMENTS=$(detect_file \
  "${PROMOTION_GUARD_PERF_CURRENT:-}" \
  "${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt" \
  "${ZDOTDIR}/docs/redesign/metrics/perf-current-segments.txt")

BASELINE_SEGMENTS=$(detect_file \
  "${PROMOTION_GUARD_PERF_BASELINE:-}" \
  "${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-baseline-segments.txt" \
  "${ZDOTDIR}/docs/redesign/metrics/perf-baseline-segments.txt")

PERF_DIFF_TOOL="${PROMOTION_GUARD_PERF_DIFF:-${ZDOTDIR}/tools/perf-diff.sh}"

ABS_THR="${PROMOTION_GUARD_PERF_THRESHOLD_ABS:-75}"
PCT_THR="${PROMOTION_GUARD_PERF_THRESHOLD_PCT:-25}"
NEW_ALLOW="${PROMOTION_GUARD_PERF_NEW_ALLOW:-150}"

MODE="observe"

# ------------- Preconditions -------------
status="SKIP"
summary=""
diff_excerpt=""
regressions="n/a"
new_segments="n/a"
removed_segments="n/a"
improvements="n/a"

fatal_skip_reason=""

if [[ -z "$CURRENT_SEGMENTS" ]]; then
  fatal_skip_reason="current segments file not found (run perf capture first)"
elif [[ ! -f "$PERF_DIFF_TOOL" ]]; then
  fatal_skip_reason="perf-diff tool not found at $PERF_DIFF_TOOL"
elif [[ -z "$BASELINE_SEGMENTS" ]]; then
  fatal_skip_reason="baseline segments file not found (establish a baseline)"
fi

if [[ -n "$fatal_skip_reason" ]]; then
  summary="$fatal_skip_reason"
else
  status="OK"
  # ------------- Execute perf-diff (warn-only) -------------
  debug "Running perf-diff: baseline=$BASELINE_SEGMENTS current=$CURRENT_SEGMENTS"
  set +e
  diff_output="$("$PERF_DIFF_TOOL" \
    --baseline "$BASELINE_SEGMENTS" \
    --current "$CURRENT_SEGMENTS" \
    --threshold-abs "$ABS_THR" \
    --threshold-pct "$PCT_THR" \
    --new-allow "$NEW_ALLOW" \
    --warn-only 2>&1)"
  diff_rc=$?
  set -e

  debug "perf-diff rc=$diff_rc"
  # Parse counts from header line: "perf-diff: baseline=... current=... thresholds... results: regressions=X new=Y removed=Z improvements=I unchanged=U"
  header_line=$(printf '%s\n' "$diff_output" | grep -E '^perf-diff:' | head -1 || true)
  if [[ -n "$header_line" ]]; then
    regressions=$(sed -n 's/.* regressions=\([0-9]\+\).*/\1/p' <<<"$header_line")
    new_segments=$(sed -n 's/.* new=\([0-9]\+\).*/\1/p' <<<"$header_line")
    removed_segments=$(sed -n 's/.* removed=\([0-9]\+\).*/\1/p' <<<"$header_line")
    improvements=$(sed -n 's/.* improvements=\([0-9]\+\).*/\1/p' <<<"$header_line")
  fi

  # Build short summary
  summary="regressions=${regressions:-?} new=${new_segments:-?} removed=${removed_segments:-?} improvements=${improvements:-?}"

  # Excerpt first ~25 lines (enough context)
  diff_excerpt=$(printf '%s\n' "$diff_output" | head -25)

  # Decorate console output (non-blocking)
  if [[ -n "$header_line" ]]; then
    if [[ "${regressions:-0}" -gt 0 ]]; then
      colorize yellow "[perf-guard] Observed ${regressions} potential regressions (non-failing observe mode)"
    else
      colorize green "[perf-guard] No regressions above thresholds"
    fi
  else
    colorize red "[perf-guard] perf-diff output missing header (tool issue?)"
  fi
fi

# ------------- Emit Structured Block -------------
# ------------- Optional Multi-Sample Aggregation (perf-capture-multi) -------------
multi_samples="n/a"
multi_post_plugin_mean="n/a"
multi_post_plugin_stddev="n/a"
if [[ -z "$fatal_skip_reason" ]]; then
  multi_file="${PROMOTION_GUARD_PERF_MULTI:-${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-multi-current.json}"
  if [[ -f "$multi_file" ]]; then
    # samples
    multi_samples=$(grep -E '"samples"[[:space:]]*:' "$multi_file" 2>/dev/null | head -1 | sed -E 's/.*"samples"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
    # capture the block for post_plugin_cost_ms
    post_block=$(awk '/"post_plugin_cost_ms"[[:space:]]*:/ {capture=1} capture {print} /"values"[[:space:]]*:/ && capture {exit}' "$multi_file" 2>/dev/null || true)
    if [[ -n "$post_block" ]]; then
      multi_post_plugin_mean=$(printf '%s\n' "$post_block" | grep -E '"mean"[[:space:]]*:' | head -1 | sed -E 's/.*"mean"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
      multi_post_plugin_stddev=$(printf '%s\n' "$post_block" | grep -E '"stddev"[[:space:]]*:' | head -1 | sed -E 's/.*"stddev"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
    fi
  fi
fi

echo "--- PERF_GUARD_BEGIN ---"
echo "status=${status}"
echo "mode=${MODE}"
echo "baseline=${BASELINE_SEGMENTS}"
echo "current=${CURRENT_SEGMENTS}"
echo "thresholds abs=${ABS_THR} pct=${PCT_THR}% new_allow=${NEW_ALLOW}"
echo "regressions=${regressions}"
echo "new_segments=${new_segments}"
echo "removed_segments=${removed_segments}"
echo "improvements=${improvements}"
echo "multi_samples=${multi_samples}"
echo "multi_post_plugin_mean=${multi_post_plugin_mean}"
echo "multi_post_plugin_stddev=${multi_post_plugin_stddev}"
echo "summary=${summary}"
# Async placeholder metrics (Phase A shadow – values derived only if dispatcher env arrays present)
async_tasks_total="n/a"
async_tasks_done="n/a"
async_tasks_fail="n/a"
async_tasks_timeout="n/a"
async_overhead_ms="n/a"
sync_path_total_ms="n/a"
sync_reduction_pct="n/a"

# Detect async dispatcher associative arrays (zsh arrays exported via env not expected; rely on file probe)
# Best-effort: if an async summary file or environment export introduced later, parse here.
if [[ -n "${ASYNC_METRICS_FILE:-}" && -f "${ASYNC_METRICS_FILE:-}" ]]; then
  while IFS='=' read -r k v; do
    case "$k" in
      async_tasks_total) async_tasks_total="$v" ;;
      async_tasks_done) async_tasks_done="$v" ;;
      async_tasks_fail) async_tasks_fail="$v" ;;
      async_tasks_timeout) async_tasks_timeout="$v" ;;
      async_overhead_ms) async_overhead_ms="$v" ;;
      sync_path_total_ms) sync_path_total_ms="$v" ;;
      sync_reduction_pct) sync_reduction_pct="$v" ;;
    esac
  done < <(grep -E '^(async_tasks_total|async_tasks_done|async_tasks_fail|async_tasks_timeout|async_overhead_ms|sync_path_total_ms|sync_reduction_pct)=' "${ASYNC_METRICS_FILE}" 2>/dev/null || true)
fi

echo "async_tasks_total=${async_tasks_total}"
echo "async_tasks_done=${async_tasks_done}"
echo "async_tasks_fail=${async_tasks_fail}"
echo "async_tasks_timeout=${async_tasks_timeout}"
echo "async_overhead_ms=${async_overhead_ms}"
echo "sync_path_total_ms=${sync_path_total_ms}"
echo "sync_reduction_pct=${sync_reduction_pct}"
if [[ -n "$fatal_skip_reason" ]]; then
  echo "reason=${fatal_skip_reason}"
fi
echo "diff_excerpt<<EOF"
printf '%s\n' "$diff_excerpt"
echo "EOF"
echo "--- PERF_GUARD_END ---"

# ------------- EXIT STRATEGY -------------
# Always 0 in observe mode; future: if PROMOTION_GUARD_PERF_FAIL=1 and regressions>0 -> exit 2
if [[ "${PROMOTION_GUARD_PERF_FAIL:-0}" == "1" && "$status" == "OK" && "${regressions:-0}" -gt 0 ]]; then
  # Currently suppressed; uncomment when moving to gating phase:
  # exit 2
  :
fi

exit 0
