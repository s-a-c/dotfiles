#!/usr/bin/env zsh
# perf-harness-minimal.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v<placeholder_checksum>
#
# PURPOSE:
#   Ultra‑minimal, deterministic Zsh startup instrumentation harness for perf-capture tooling.
#   Bypasses the heavy interactive framework (.zshrc plugin manager, integrity scans, themes)
#   while still emitting lifecycle timing markers that downstream aggregation expects.
#
# DESIGN:
#   This script is executed directly (non-interactively) by perf-capture when PERF_CAPTURE_FAST=1.
#   It:
#     1. Establishes a safe environment & PATH.
#     2. Creates (or appends to) a segment log file if requested.
#     3. Synthesizes PRE / POST plugin markers (fast path).
#     4. Loads prompt-ready instrumentation file (if available) and triggers capture.
#     5. Emits PROMPT_READY_COMPLETE marker (real if instrumentation present, synthetic otherwise).
#     6. Exits immediately (no interactive shell spawned) so cold/warm measurements are stable & fast.
#
# OUTPUT (when PERF_SEGMENT_LOG or --segment-log provided):
#   PRE_PLUGIN_COMPLETE <ms>
#   POST_PLUGIN_COMPLETE <ms>
#   SEGMENT name=pre_plugin_total ms=<ms> phase=pre_plugin sample=mean
#   SEGMENT name=post_plugin_total ms=<ms> phase=post_plugin sample=post_plugin
#   PROMPT_READY_COMPLETE <ms_from_pre_end>
#   SEGMENT name=prompt_ready ms=<ms_from_pre_end> phase=prompt sample=mean
#
# EXIT CODES:
#   0 Success
#   1 Bad usage / unsupported option
#   2 Failed to write segment log
#
# ENVIRONMENT (respected):
#   ZDOTDIR                 Base config dir (default: $HOME/.config/zsh)
#   PERF_SEGMENT_LOG        Destination log path (overridden by --segment-log)
#   PERF_SYNTH_PRE_PCT      Fraction of total synthetic pre time (default 0.30)
#   PERF_SYNTH_TOTAL_MS     Override total synthetic ms (auto-calculated if unset)
#
# SECURITY:
#   - No network usage
#   - Writes only inside provided log path
#
# NOTE:
#   Actual cold/warm wall times are measured outside this harness (perf-capture).
#   This harness only produces segmentation markers quickly.
#
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_NAME="${0##*/}"

usage() {
  cat <<EOF
$SCRIPT_NAME - Minimal Zsh perf instrumentation harness

Usage: $SCRIPT_NAME [--segment-log <path>] [--debug]

Options:
  --segment-log <path>   Explicit segment log destination (overrides PERF_SEGMENT_LOG)
  --debug                Verbose stderr diagnostics
  --help                 Show this help and exit

Environment overrides:
  ZDOTDIR                 Base config directory (default: \$HOME/.config/zsh)
  PERF_SEGMENT_LOG        Segment log file path (if --segment-log not provided)
  PERF_SYNTH_PRE_PCT      Fraction (0.0-1.0) synthetic pre segment (default 0.30)
  PERF_SYNTH_TOTAL_MS     Total synthetic time; if unset, real elapsed used (fast execution)

Markers emitted (if log specified):
  PRE_PLUGIN_COMPLETE, POST_PLUGIN_COMPLETE, PROMPT_READY_COMPLETE and SEGMENT lines.

EOF
}

DEBUG=0
CLI_SEGMENT_LOG=""

while (( $# > 0 )); do
  case "$1" in
    --segment-log)
      shift || { echo "Missing value after --segment-log" >&2; exit 1; }
      CLI_SEGMENT_LOG="$1"
      ;;
    --debug)
      DEBUG=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

log_debug() {
  (( DEBUG )) && printf '[%s][debug] %s\n' "$SCRIPT_NAME" "$*" >&2
}

# ---------------- Environment & Paths ----------------
ZDOTDIR="${ZDOTDIR:-${HOME}/.config/zsh}"
export ZDOTDIR

# Minimal safe PATH (append standard bins if missing)
add_path_segment() {
  case ":$PATH:" in
    *":$1:"*) ;; # already
    *) PATH="${PATH}:$1";;
  esac
}
for core_dir in /usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin; do
  [[ -d "$core_dir" ]] && add_path_segment "$core_dir"
done
export PATH

SEGMENT_LOG="${CLI_SEGMENT_LOG:-${PERF_SEGMENT_LOG:-}}"
if [[ -n "$SEGMENT_LOG" ]]; then
  mkdir -p -- "$(dirname -- "$SEGMENT_LOG")" 2>/dev/null || true
  if ! touch "$SEGMENT_LOG" 2>/dev/null; then
    echo "ERROR: Cannot write segment log: $SEGMENT_LOG" >&2
    exit 2
  fi
fi

# Synthetic timing parameters
PRE_PCT="${PERF_SYNTH_PRE_PCT:-0.30}"
float_re='^([0-9]*\.[0-9]+|[0-9]+(\.[0-9]*)?)$'
[[ "$PRE_PCT" =~ $float_re ]] || PRE_PCT="0.30"
# Clamp
awk_clamp() {
  awk -v v="$1" -v lo="$2" -v hi="$3" 'BEGIN{ if(v<lo)v=lo; if(v>hi)v=hi; printf "%.6f", v }'
}
PRE_PCT=$(awk_clamp "$PRE_PCT" 0.05 0.90)

# ---------------- Timing Helpers ----------------
epoch_ms() {
  # Prefer EPOCHREALTIME if zsh/datetime available
  if typeset -p EPOCHREALTIME >/dev/null 2>&1; then
    print -r -- "$EPOCHREALTIME" | awk -F. '{ms = ($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
  else
    printf '%s000' "$(date +%s 2>/dev/null || echo 0)"
  fi
}

zmodload zsh/datetime 2>/dev/null || true
START_MS=$(epoch_ms)

# ---------------- Instrumentation Load ----------------
PROMPT_READY_LOADED=0
if [[ -f "$ZDOTDIR/.zshrc.d.REDESIGN/95-prompt-ready.zsh" ]]; then
  # shellcheck disable=SC1090
  source "$ZDOTDIR/.zshrc.d.REDESIGN/95-prompt-ready.zsh" || true
  PROMPT_READY_LOADED=1
  log_debug "Loaded prompt-ready instrumentation"
else
  log_debug "Prompt-ready instrumentation not found"
fi

# Segment library (optional granular support)
if [[ -f "$ZDOTDIR/tools/segment-lib.zsh" ]]; then
  # shellcheck disable=SC1090
  source "$ZDOTDIR/tools/segment-lib.zsh" || true
  log_debug "Loaded segment-lib (optional)"
fi

# ---------------- Synthetic PRE/POST ----------------
END_PRE_MS=$(epoch_ms)
TOTAL_MS=""
if [[ -n "${PERF_SYNTH_TOTAL_MS:-}" && "${PERF_SYNTH_TOTAL_MS}" =~ ^[0-9]+$ && "${PERF_SYNTH_TOTAL_MS}" -gt 0 ]]; then
  TOTAL_MS="${PERF_SYNTH_TOTAL_MS}"
else
  # Real elapsed so far acts as baseline total if extremely short, inflate to minimum (50ms)
  NOW_MS=$(epoch_ms)
  RAW_DELTA=$(( NOW_MS - START_MS ))
  (( RAW_DELTA < 50 )) && RAW_DELTA=50
  TOTAL_MS="$RAW_DELTA"
fi

PRE_MS=$(awk -v t="$TOTAL_MS" -v p="$PRE_PCT" 'BEGIN{printf "%d", t*p}')
(( PRE_MS < 1 )) && PRE_MS=1
POST_MS="$TOTAL_MS"   # For minimal harness we approximate post == total (no further staged work)
PROMPT_DELTA_MS=$POST_MS

# ---------------- Prompt Ready Capture (Real If Possible) ----------------
if (( PROMPT_READY_LOADED )); then
  # If function exists, invoke to produce real marker; else synthetic used below
  if typeset -f __pr__capture_prompt_ready >/dev/null 2>&1; then
    # Provide segment log & context to instrumentation
    export PERF_SEGMENT_LOG="${SEGMENT_LOG:-}"
    PERF_SAMPLE_CONTEXT="mean"
    export PERF_SAMPLE_CONTEXT
    __pr__capture_prompt_ready 2>/dev/null || true
    # If instrumentation exported PROMPT_READY_DELTA_MS use it; else fallback
    if [[ -n "${PROMPT_READY_DELTA_MS:-}" && "${PROMPT_READY_DELTA_MS}" =~ ^[0-9]+$ ]]; then
      PROMPT_DELTA_MS=$PROMPT_READY_DELTA_MS
    fi
  fi
fi

# Ensure logical monotonic ordering: PRE <= POST, PROMPT <= POST (or clamp)
(( PRE_MS > POST_MS )) && PRE_MS=$POST_MS
(( PROMPT_DELTA_MS > POST_MS )) && PROMPT_DELTA_MS=$POST_MS
(( PROMPT_DELTA_MS < PRE_MS )) && PROMPT_DELTA_MS=$PRE_MS

# ---------------- Emit Markers ----------------
if [[ -n "$SEGMENT_LOG" ]]; then
  {
    print "PRE_PLUGIN_COMPLETE ${PRE_MS}"
    print "SEGMENT name=pre_plugin_total ms=${PRE_MS} phase=pre_plugin sample=mean"
    print "POST_PLUGIN_COMPLETE ${POST_MS}"
    print "SEGMENT name=post_plugin_total ms=${POST_MS} phase=post_plugin sample=post_plugin"
    print "PROMPT_READY_COMPLETE ${PROMPT_DELTA_MS}"
    print "SEGMENT name=prompt_ready ms=${PROMPT_DELTA_MS} phase=prompt sample=mean"
  } >>"$SEGMENT_LOG" 2>/dev/null || {
    echo "ERROR: Failed writing to segment log $SEGMENT_LOG" >&2
    exit 2
  }
  log_debug "Markers written to $SEGMENT_LOG (pre=${PRE_MS} post=${POST_MS} prompt=${PROMPT_DELTA_MS})"
else
  log_debug "SEGMENT_LOG not set; markers suppressed"
fi

exit 0
