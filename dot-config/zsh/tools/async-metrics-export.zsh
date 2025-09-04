#!/usr/bin/env zsh
# async-metrics-export.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Emit a simple key=value metrics file summarizing current async dispatcher
#   state so promotion-guard-perf.sh (or other tooling) can surface early
#   diagnostics in observe / shadow phases.
#
# SCOPE (Phase A / Shadow):
#   - Safe to run even if async dispatcher not loaded (writes placeholder values).
#   - Does NOT attempt to mutate task state or enforce timeouts.
#   - Overhead & sync reduction are placeholders until Phase C+ when real
#     synchronous deferrals begin and attribution deltas are known.
#
# OUTPUT (default path):
#   $ZDOTDIR/docs/redesignv2/artifacts/metrics/async-metrics.txt
#
# KEYS (all always present):
#   async_tasks_total
#   async_tasks_done
#   async_tasks_fail
#   async_tasks_timeout
#   async_tasks_running
#   async_tasks_pending
#   async_overhead_ms            (placeholder or summed durations if available)
#   sync_path_total_ms           (placeholder: parses post_plugin_total if segment log available)
#   sync_reduction_pct           (placeholder: 'n/a' Phase A)
#   overhead_ratio               (placeholder: 'n/a' until baseline sync removal metrics available)
#   export_mode                  (shadow|on|off_detected)
#   timestamp_utc
#
# OPTIONAL ENV VARS:
#   ASYNC_METRICS_FILE           Target file path (override default)
#   ASYNC_SEGMENT_LOG            Explicit segment log to mine for totals (otherwise PERF_SEGMENT_LOG)
#   ASYNC_MODE                   off|shadow|on (informational)
#
# EXIT CODE:
#   0 always (non-fatal exporter)
#
# USAGE:
#   source after async tasks potentially launched, then:
#     zsh tools/async-metrics-export.zsh
#   or add to a late hook (e.g. after initial prompt_ready capture).
#
# SECURITY:
#   - Writes only to metrics file.
#   - No command execution beyond local parsing.
#
set -euo pipefail

# -------------------- Helpers --------------------
_ts_utc() {
  # Portable-ish ISO 8601 without subsecond
  command -v gdate >/dev/null 2>&1 && gdate -u +"%Y-%m-%dT%H:%M:%SZ" || date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_info() {
  [[ -n ${ASYNC_METRICS_VERBOSE:-} ]] && print -- "[async-metrics] $*" >&2
}

# -------------------- Paths ----------------------
: "${ZDOTDIR:=${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

DEFAULT_OUT="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/async-metrics.txt"
OUT_FILE="${ASYNC_METRICS_FILE:-$DEFAULT_OUT}"

# Ensure directory exists
out_dir="${OUT_FILE:h}"
mkdir -p "${out_dir}" 2>/dev/null || true

# Segment log discovery (best-effort)
SEGMENT_LOG="${ASYNC_SEGMENT_LOG:-${PERF_SEGMENT_LOG:-}}"

# -------------------- Detect Dispatcher --------------------
dispatcher_loaded=0
if typeset -p __ASYNC_TASK_STATUS >/dev/null 2>&1; then
  dispatcher_loaded=1
fi

mode="${ASYNC_MODE:-off_detected}"

# Initialize counters
integer total=0 done=0 fail=0 timeout=0 running=0 pending=0
integer overhead_ms=0

if (( dispatcher_loaded )); then
  for id st in ${(kv)__ASYNC_TASK_STATUS}; do
    (( total++ ))
    case "$st" in
      done)
        (( done++ ))
        # If we have duration data, add to overhead (Phase A: approximate)
        if [[ -n ${__ASYNC_TASK_START_MS[$id]:-} && -n ${__ASYNC_TASK_END_MS[$id]:-} ]]; then
          local dur=$(( __ASYNC_TASK_END_MS[$id] - __ASYNC_TASK_START_MS[$id] ))
          (( dur > 0 )) && (( overhead_ms += dur ))
        fi
        ;;
      fail)
        (( fail++ ))
        if [[ -n ${__ASYNC_TASK_START_MS[$id]:-} && -n ${__ASYNC_TASK_END_MS[$id]:-} ]]; then
          local dur=$(( __ASYNC_TASK_END_MS[$id] - __ASYNC_TASK_START_MS[$id] ))
          (( dur > 0 )) && (( overhead_ms += dur ))
        fi
        ;;
      timeout)
        (( timeout++ ))
        if [[ -n ${__ASYNC_TASK_START_MS[$id]:-} && -n ${__ASYNC_TASK_END_MS[$id]:-} ]]; then
          local dur=$(( __ASYNC_TASK_END_MS[$id] - __ASYNC_TASK_START_MS[$id] ))
          (( dur > 0 )) && (( overhead_ms += dur ))
        fi
        ;;
      running) (( running++ )) ;;
      pending) (( pending++ )) ;;
    esac
  done
fi

# -------------------- Derive sync_path_total_ms (Placeholder) ---------------
# Phase A: we have not removed synchronous work, so sync_path_total_ms ~= post_plugin_total
sync_path_total_ms="n/a"
if [[ -z ${SEGMENT_LOG} ]]; then
  # Attempt heuristic discovery: look for most recent perf-current-segments.txt
  cand1="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
  [[ -f $cand1 ]] && SEGMENT_LOG="$cand1"
fi

if [[ -n ${SEGMENT_LOG} && -r ${SEGMENT_LOG} ]]; then
  # Parse post_plugin_total ms
  val=$(grep -E 'SEGMENT name=post_plugin_total ' "${SEGMENT_LOG}" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1)
  [[ -n $val ]] && sync_path_total_ms="$val"
fi

# In Phase A we cannot calculate reduction; set n/a
sync_reduction_pct="n/a"

# -------------------- Write Metrics File ------------------------------------
{
  printf 'async_tasks_total=%s\n'   "$total"
  printf 'async_tasks_done=%s\n'    "$done"
  printf 'async_tasks_fail=%s\n'    "$fail"
  printf 'async_tasks_timeout=%s\n' "$timeout"
  printf 'async_tasks_running=%s\n' "$running"
  printf 'async_tasks_pending=%s\n' "$pending"
  printf 'async_overhead_ms=%s\n'   "$overhead_ms"
  printf 'sync_path_total_ms=%s\n'  "$sync_path_total_ms"
  printf 'sync_reduction_pct=%s\n'  "$sync_reduction_pct"
  printf 'overhead_ratio=%s\n'      "n/a"
  printf 'export_mode=%s\n'         "$mode"
  printf 'timestamp_utc=%s\n'       "$(_ts_utc)"
} >| "${OUT_FILE}" 2>/dev/null || {
  print -- "[async-metrics][warn] Failed to write metrics file: ${OUT_FILE}" >&2
}

_info "Exported async metrics to ${OUT_FILE} (dispatcher_loaded=${dispatcher_loaded} mode=${mode})"

exit 0
