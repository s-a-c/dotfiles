#!/usr/bin/env zsh
# run-multi-classifier-and-update.sh
# Compliant with /Users/s-a-c/.config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Helper utility to execute multiple sequential performance classifier runs
#   (observe mode), updating the perf classifier status JSON after each run to
#   build / advance the OK streak toward governance activation.
#
# FEATURES:
#   - Runs N sequential classifier captures (each with configurable sample count)
#   - After each run:
#       * Updates perf_classifier_status.json using update-performance-status script
#       * Displays current overall status & streak
#   - Aborts early if an OVERALL status other than OK appears (to avoid wasting time)
#   - Optional target streak watch (warns if target already satisfied)
#
# USAGE:
#   ./tools/run-multi-classifier-and-update.sh
#   ./tools/run-multi-classifier-and-update.sh --runs 2 --samples 5
#   ./tools/run-multi-classifier-and-update.sh --runs 2 --metrics prompt_ready,pre_plugin_total
#
# OPTIONS:
#   --runs N             Number of classifier executions to perform (default: 2)
#   --samples N          Samples per classifier run (classifier --runs) (default: 5)
#   --metrics LIST       Comma-separated metric names (default: prompt_ready,pre_plugin_total,post_plugin_total,deferred_total)
#   --status-json PATH   Status JSON (default: docs/redesignv2/artifacts/metrics/perf_classifier_status.json)
#   --classifier PATH    Classifier script path (default: tools/perf-regression-classifier.zsh)
#   --updater PATH       Update script path (default: tools/update-performance-status.zsh)
#   --target-streak N    Passive goal display (does not loop until achieved; default: 3)
#   --quiet              Reduce progress chatter
#   -h|--help            Show help
#
# EXIT CODES:
#   0 success (all runs processed; streak advanced or unchanged)
#   2 aborted early due to non-OK overall status
#   3 usage / argument error
#
# NOTES:
#   - Observe mode only (enforce flip should occur via governance activation PR)
#   - Append-only semantics for perf log handled externally; this script only updates JSON artifact
#   - Safe re-entrancy: re-running continues from current ok_streak_current
#
set -euo pipefail

# ---------------- Defaults ----------------
RUN_COUNT=2
SAMPLES_PER_RUN=5
METRICS="prompt_ready,pre_plugin_total,post_plugin_total,deferred_total"
STATUS_JSON="docs/redesignv2/artifacts/metrics/perf_classifier_status.json"
CLASSIFIER="tools/perf-regression-classifier.zsh"
UPDATER="tools/update-performance-status.zsh"
TARGET_STREAK=3
QUIET=0

# ---------------- Utility Logging ----------------
log_info() { (( QUIET )) || print -r -- "[multi-classifier][info] $*" >&2; }
log_warn() { print -r -- "[multi-classifier][warn] $*" >&2; }
log_err()  { print -r -- "[multi-classifier][err]  $*" >&2; }

usage() {
  grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------- Arg Parsing ----------------
while (( $# )); do
  case "$1" in
    --runs) shift; RUN_COUNT="${1:-}";;
    --runs=*) RUN_COUNT="${1#*=}";;
    --samples) shift; SAMPLES_PER_RUN="${1:-}";;
    --samples=*) SAMPLES_PER_RUN="${1#*=}";;
    --metrics) shift; METRICS="${1:-}";;
    --metrics=*) METRICS="${1#*=}";;
    --status-json) shift; STATUS_JSON="${1:-}";;
    --status-json=*) STATUS_JSON="${1#*=}";;
    --classifier) shift; CLASSIFIER="${1:-}";;
    --classifier=*) CLASSIFIER="${1#*=}";;
    --updater) shift; UPDATER="${1:-}";;
    --updater=*) UPDATER="${1#*=}";;
    --target-streak) shift; TARGET_STREAK="${1:-}";;
    --target-streak=*) TARGET_STREAK="${1#*=}";;
    --quiet) QUIET=1;;
    -h|--help) usage;;
    *)
      log_err "Unknown argument: $1"
      exit 3
      ;;
  esac
  shift
done

is_int() { [[ "$1" =~ ^[0-9]+$ ]]; }
for num in "$RUN_COUNT" "$SAMPLES_PER_RUN" "$TARGET_STREAK"; do
  is_int "$num" || { log_err "Numeric argument expected; got '$num'"; exit 3; }
done
(( RUN_COUNT > 0 )) || { log_err "--runs must be > 0"; exit 3; }
(( SAMPLES_PER_RUN > 0 )) || { log_err "--samples must be > 0"; exit 3; }

# ---------------- Path Validation ----------------
[[ -x "$CLASSIFIER" || -f "$CLASSIFIER" ]] || { log_err "Classifier script not found: $CLASSIFIER"; exit 3; }
[[ -x "$UPDATER" || -f "$UPDATER" ]] || { log_err "Updater script not found: $UPDATER"; exit 3; }
[[ -f "$STATUS_JSON" ]] || log_warn "Status JSON not found yet (will be created/overwritten later?): $STATUS_JSON"

# ---------------- Helper: Extract overall status & streak ----------------
extract_overall_status() {
  local file="$1"
  grep -E '"overall_status"' "$file" 2>/dev/null | sed -E 's/.*"overall_status":[[:space:]]*"([^"]+)".*/\1/' | head -n1
}

extract_current_streak() {
  local file="$1"
  grep -E '"ok_streak_current"' "$file" 2>/dev/null | sed -E 's/.*"ok_streak_current":[[:space:]]*([0-9]+).*/\1/' | head -n1
}

# ---------------- Initial Snapshot ----------------
if [[ -f "$STATUS_JSON" ]]; then
  INITIAL_STREAK="$(extract_current_streak "$STATUS_JSON" || true)"
  (( ${INITIAL_STREAK:-0} > 0 )) && log_info "Initial ok_streak_current=${INITIAL_STREAK}"
fi

if [[ -n "${INITIAL_STREAK:-}" && $INITIAL_STREAK -ge $TARGET_STREAK ]]; then
  log_warn "Target streak (${TARGET_STREAK}) already achieved (current=${INITIAL_STREAK}). Runs will still proceed."
fi

# ---------------- Run Loop ----------------
run_index=1
while (( run_index <= RUN_COUNT )); do
  log_info "Run ${run_index}/${RUN_COUNT}: capturing metrics (${METRICS}) with ${SAMPLES_PER_RUN} samples..."
  OUT_FILE="/tmp/perf_classifier_run_${run_index}.$$.out"

  # Execute classifier (observe mode only)
  if ! zsh -f "$CLASSIFIER" \
      --metrics "$METRICS" \
      --runs "$SAMPLES_PER_RUN" \
      --mode observe | tee "$OUT_FILE"; then
    log_err "Classifier invocation failed (non-zero exit). Aborting."
    exit 2
  fi

  # Update status JSON
  if ! zsh -f "$UPDATER" \
      --log "$OUT_FILE" \
      --state "$STATUS_JSON" \
      --json-out "$STATUS_JSON" \
      --require-overall --quiet; then
    log_err "Update script failed to process classifier output."
    exit 2
  fi

  # Parse updated status
  OVERALL="$(extract_overall_status "$STATUS_JSON")"
  STREAK_NOW="$(extract_current_streak "$STATUS_JSON")"

  [[ -z "$OVERALL" ]] && { log_err "Could not parse overall_status from $STATUS_JSON"; exit 2; }
  [[ -z "$STREAK_NOW" ]] && { log_err "Could not parse ok_streak_current from $STATUS_JSON"; exit 2; }

  log_info "Post-run status: overall_status=${OVERALL} ok_streak_current=${STREAK_NOW}"

  if [[ "$OVERALL" != "OK" ]]; then
    log_warn "Non-OK overall status encountered (OVERALL=${OVERALL}). Streak reset likely. Aborting further runs."
    exit 2
  fi

  if (( STREAK_NOW >= TARGET_STREAK )); then
    log_info "Target streak (${TARGET_STREAK}) reached or exceeded (current=${STREAK_NOW}). Remaining planned runs optional."
  fi

  (( run_index++ ))
done

log_info "All ${RUN_COUNT} runs completed. Final ok_streak_current=$(extract_current_streak "$STATUS_JSON")."
exit 0
