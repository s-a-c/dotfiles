#!/usr/bin/env bash
#
# carapace_timing_harness.sh
#
# Purpose:
#   Measure startup timing and widget counts with and without Carapace styling enabled
#   (guarded by unified variable ZF_DISABLE_CARAPACE_STYLES) for the ZSH configuration.
#
# Overview:
#   - Spawns fresh login+interactive zsh shells (zsh -lic) so the normal .zshrc path runs.
#   - Uses symlinked layer directories (.zshrc.pre-plugins.d -> versioned set, etc.).
#   - DOES NOT manually source individual module directories (avoids divergence from real startup).
#   - Collects:
#       * Timing (using zsh TIMEFMT + reserved word 'time') – with automatic fallback to internal EPOCHREALTIME delta if the reserved word output is suppressed
#       * Widget count (post-init after full normal initialization)
#   - Writes results to a log file (~/.cache/zsh/logs/carapace_timing.log by default).
#   - Produces a summary and delta (with-style minus no-style).
#
# Usage:
#   ./carapace_timing_harness.sh
#   RUN_WARM=1 ./carapace_timing_harness.sh
#   ./carapace_timing_harness.sh RUN_WARM=1
#
# Optional Environment Variables:
#   ZDOTDIR                       Override if config lives elsewhere.
#   LOG_FILE                      Override output log file path.
#   WIDGET_THRESHOLD              Expected minimum widget count (default 416).
#   RUN_WARM=1                    Perform an additional warm pair of runs (without clearing log).
#   KEEP_OLD_LOG=1                Append instead of truncating existing log.
#   FORCE_STYLE_DISABLE_VAR=1     Also export legacy disable var for backward compatibility.
#
# Exit Codes:
#   0  Success & threshold satisfied
#   1  Failure (threshold not met or structural error)
#
# Policy / Design Notes:
#   - Nounset-safe (bash set -u)
#   - Minimal external deps (bash, zsh, wc, grep, awk, mkdir, date, tee)
#   - Realistic measurement: always exercises the actual .zshrc chain.
#
# Integration:
#   Commit under docs/fix-zle/tests/; reference results in plan-of-attack Phase 7 section.
#
set -euo pipefail

###############################################################################
# Configuration
###############################################################################

DEFAULT_ZDOTDIR="${HOME}/.config/zsh"
ZDOTDIR="${ZDOTDIR:-$DEFAULT_ZDOTDIR}"

LOG_DIR_DEFAULT="${HOME}/.cache/zsh/logs"
LOG_FILE="${LOG_FILE:-${LOG_DIR_DEFAULT}/carapace_timing.log}"

WIDGET_THRESHOLD="${WIDGET_THRESHOLD:-416}"
RUN_WARM="${RUN_WARM:-0}"
KEEP_OLD_LOG="${KEEP_OLD_LOG:-0}"

# TIMEFMT we inject inside zsh; includes: elapsed, user, sys, CPU%
# %*E is extended elapsed; %U user seconds; %S sys seconds; %P CPU%
ZSH_TIMEFMT='startup(%m): %*E user:%U sys:%S cpu:%P'
# ---------------------------------------------------------------------------
# Argument KEY=VALUE parsing (supports lightweight overrides without exporting)
# Recognized keys: RUN_WARM, WIDGET_THRESHOLD, LOG_FILE
# Example:
#   ./carapace_timing_harness.sh RUN_WARM=1
# Environment variables still take precedence if set before invocation.
for arg in "$@"; do
  case "$arg" in
    RUN_WARM=0|RUN_WARM=1)
      RUN_WARM="${arg#RUN_WARM=}"
      ;;
    WIDGET_THRESHOLD=*)
      WIDGET_THRESHOLD="${arg#WIDGET_THRESHOLD=}"
      ;;
    LOG_FILE=*)
      LOG_FILE="${arg#LOG_FILE=}"
      ;;
    *)
      ;;
  esac
done
# Positional arguments are not otherwise used; clear them to avoid confusion.
set --

###############################################################################
# Helpers
###############################################################################

err() { printf >&2 "[carapace-harness][error] %s\n" "$*"; }
info() { printf "[carapace-harness] %s\n" "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Required command '$1' not found"; exit 1; }
}

parse_seconds() {
  # Convert [[dd:]hh:]mm:ss(.fraction)? to total seconds (float)
  # Input via stdin or first arg
  local in
  if [[ $# -gt 0 ]]; then
    in="$1"
  else
    in="$(cat)"
  fi
  # Normalize by splitting on ':'
  # Accept patterns:
  #   ss
  #   mm:ss
  #   hh:mm:ss
  #   dd:hh:mm:ss
  # We'll process from the right.
  local frac whole parts pcount s=0 mul=1
  # Separate fractional sec
  if [[ "$in" == *.* ]]; then
    whole="${in%%.*}"
    frac="0.${in##*.}"
  else
    whole="$in"
    frac="0"
  fi
  IFS=':' read -r -a parts <<< "$whole"
  pcount=${#parts[@]}
  # Process from right → left
  for (( idx=pcount-1; idx>=0; idx-- )); do
    local val="${parts[idx]}"
    if [[ -z "$val" ]]; then continue; fi
    s=$(( s + val * mul ))
    mul=$(( mul * 60 ))
  done
  # Add fractional component
  # shellcheck disable=SC2003
  awk -v base="$s" -v frac="$frac" 'BEGIN { printf("%.6f", base + frac) }'
}

extract_elapsed_seconds() {
  # Given a "startup(mode): ELAPSED user:..." line, pull ELAPSED and convert
  local line="$1"
  # shellcheck disable=SC2001
  local raw
  raw="$(echo "$line" | sed -E 's/^startup\([^)]*\):[[:space:]]*([^[:space:]]+).*/\1/')"
  parse_seconds "$raw"
}

summarize_delta() {
  local log="$1"

  # New labeled format (startup(<mode>,<pass>): ...)
  local cold_no cold_with warm_no warm_with
  cold_no="$(grep -E '^startup\(no-style,cold\):' "$log" | head -1 || true)"
  cold_with="$(grep -E '^startup\(with-style,cold\):' "$log" | head -1 || true)"
  warm_no="$(grep -E '^startup\(no-style,warm\):' "$log" | tail -1 || true)"
  warm_with="$(grep -E '^startup\(with-style,warm\):' "$log" | tail -1 || true)"

  if [[ -n "$cold_no" && -n "$cold_with" ]]; then
    local t_cold_no t_cold_with delta_cold
    t_cold_no="$(extract_elapsed_seconds "$cold_no")"
    t_cold_with="$(extract_elapsed_seconds "$cold_with")"
    delta_cold="$(awk -v a="$t_cold_with" -v b="$t_cold_no" 'BEGIN { printf("%.6f", a-b) }')"
    printf "\nCold Timing Summary (seconds):\n"
    printf "  no-style : %s\n" "$t_cold_no"
    printf "  with-style: %s\n" "$t_cold_with"
    printf "  delta    : %s (with - no)\n" "$delta_cold"
  fi

  if [[ -n "$warm_no" && -n "$warm_with" ]]; then
    local t_warm_no t_warm_with delta_warm
    t_warm_no="$(extract_elapsed_seconds "$warm_no")"
    t_warm_with="$(extract_elapsed_seconds "$warm_with")"
    delta_warm="$(awk -v a="$t_warm_with" -v b="$t_warm_no" 'BEGIN { printf("%.6f", a-b) }')"
    printf "\nWarm Timing Summary (seconds):\n"
    printf "  no-style : %s\n" "$t_warm_no"
    printf "  with-style: %s\n" "$t_warm_with"
    printf "  delta    : %s (with - no)\n" "$delta_warm"
  fi

  # Backward compatibility (old unlabeled format)
  if [[ -z "$cold_no" && -z "$warm_no" ]]; then
    local no_style with_style
    no_style="$(grep -E '^startup\(no-style\):' "$log" | tail -1 || true)"
    with_style="$(grep -E '^startup\(with-style\):' "$log" | tail -1 || true)"
    if [[ -z "$no_style" || -z "$with_style" ]]; then
      err "Cannot compute delta (missing timing lines)"
      return 1
    fi
    local t_no t_with delta
    t_no="$(extract_elapsed_seconds "$no_style")"
    t_with="$(extract_elapsed_seconds "$with_style")"
    delta="$(awk -v a="$t_with" -v b="$t_no" 'BEGIN { printf("%.6f", a-b) }')"
    printf "\nTiming Summary (seconds):\n"
    printf "  no-style : %s\n" "$t_no"
    printf "  with-style: %s\n" "$t_with"
    printf "  delta    : %s (with - no)\n" "$delta"
  fi
}

check_thresholds() {
  local log="$1"
  local bad=0
  local line count mode
  # Only enforce threshold on total widget lines
  while IFS= read -r line; do
    [[ "$line" != widgets_total=* ]] && continue
    # Format: widgets_total=417 (mode)
    count="$(echo "$line" | sed -E 's/^widgets_total=([0-9]+).*/\1/')"
    mode="$(echo "$line" | sed -E 's/^widgets_total=[0-9]+ \(([^)]+)\).*/\1/')"
    if (( count < WIDGET_THRESHOLD )); then
      err "Widget total below threshold ($WIDGET_THRESHOLD) in mode '$mode': $count"
      bad=1
    fi
  done < <(grep '^widgets_total=' "$log" || true)
  return $bad
}

###############################################################################
# Pre-flight
###############################################################################

require_cmd zsh
require_cmd wc
require_cmd grep
require_cmd awk
require_cmd mkdir
require_cmd date
require_cmd tee

if [[ ! -d "$ZDOTDIR" ]]; then
  err "ZDOTDIR does not exist: $ZDOTDIR"
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

if [[ "$KEEP_OLD_LOG" != "1" ]]; then
  : > "$LOG_FILE"
  info "Log truncated: $LOG_FILE"
else
  info "Appending to existing log: $LOG_FILE"
fi

info "Using ZDOTDIR=$ZDOTDIR"
info "Widget threshold=$WIDGET_THRESHOLD"

###############################################################################
# Core runner
###############################################################################

run_case() {
  local mode="$1"
  local pass_label="${2:-unlabeled}"
  local env_prefix=""
  if [[ "$mode" == "no-style" ]]; then
    env_prefix="ZF_DISABLE_CARAPACE_STYLES=1"
    [[ "${FORCE_STYLE_DISABLE_VAR:-0}" == "1" ]] && env_prefix="$env_prefix ZF_CARAPACE_STYLE_DISABLE=1"
  else
    env_prefix="ZF_DISABLE_CARAPACE_STYLES=0"
    [[ "${FORCE_STYLE_DISABLE_VAR:-0}" == "1" ]] && env_prefix="$env_prefix unset ZF_CARAPACE_STYLE_DISABLE"
  fi

  # Use a temporary zsh fragment sourced inside the FIRST interactive shell to avoid nested quoting problems
  local tmp_fragment
  tmp_fragment="$(mktemp -t carapace-frag-XXXXXX.zsh)"

  cat >"$tmp_fragment" <<'__CAP_FRAG__'
# fragment executes inside already-initialized interactive zsh
set +e
_zf_fallback_start=${EPOCHREALTIME:-0}
TIMEFMT="startup(${MODE},${PASS}): %*E user:%U sys:%S cpu:%P"
time {
  total=$(zle -la 2>/dev/null | wc -l | tr -d "[:space:]")
  user=$(zle -l 2>/dev/null | wc -l | tr -d "[:space:]")
  printf "widgets_total=%s (%s,%s)\n" "$total" "$MODE" "$PASS"
  printf "widgets_user=%s (%s,%s)\n" "$user" "$MODE" "$PASS"
  if [[ -n ${_ZF_LAYER_SET:-} ]]; then
    printf "layer_set=%s (%s,%s)\n" "$_ZF_LAYER_SET" "$MODE" "$PASS"
  fi
}
_zf_fallback_end=${EPOCHREALTIME:-0}
if [[ $_zf_fallback_start != 0 && $_zf_fallback_end != 0 ]]; then
  _zf_elapsed=$(awk -v s="$_zf_fallback_start" -v e="$_zf_fallback_end" 'BEGIN{printf("%.6f",(e-s))}')
  printf "startup(%s,%s): %s user:0 sys:0 cpu:0 fallback=1\n" "$MODE" "$PASS" "$_zf_elapsed"
fi
unset _zf_fallback_start _zf_fallback_end _zf_elapsed
__CAP_FRAG__

  # Run interactive shell and source fragment (dot command) so zle state is complete
  # Rely only on bash for launching; CI only needs zsh available.
  env ZDOTDIR="$ZDOTDIR" MODE="$mode" PASS="$pass_label" bash -c "
    set -euo pipefail
    $env_prefix zsh -lic '. \"$tmp_fragment\"'
  " 2>&1 | tee -a "$LOG_FILE"

  rm -f "$tmp_fragment"
}

cold_pass() {
  info "Cold pass (no-style)"
  run_case no-style cold
  info "Cold pass (with-style)"
  run_case with-style cold
}

warm_pass() {
  info "Warm pass (no-style)"
  run_case no-style warm
  info "Warm pass (with-style)"
  run_case with-style warm
}

###############################################################################
# Execution
###############################################################################

main() {
  info "Beginning timing harness"

  cold_pass

  if [[ "$RUN_WARM" == "1" ]]; then
    info "Executing warm pass (cache/warm path timing)"
    warm_pass
  fi

  echo
  info "Timing lines captured:"
  grep '^startup(' "$LOG_FILE" || info "No timing lines found!"

  summarize_delta "$LOG_FILE" || {
    err "Failed to compute timing delta"
  }

  echo
  info "Widget count lines (total + user):"
  grep '^widgets_total=' "$LOG_FILE" || info "No total widget lines found!"
  grep '^widgets_user=' "$LOG_FILE" || info "No user widget lines found!"
  if grep -q '^layer_set=' "$LOG_FILE"; then
    info "Layer set markers:"
    grep '^layer_set=' "$LOG_FILE" || true
  fi

  if ! check_thresholds "$LOG_FILE"; then
    err "One or more widget counts fell below threshold (${WIDGET_THRESHOLD})"
    status=1
  else
    info "All widget counts meet or exceed threshold (${WIDGET_THRESHOLD})"
    status=0
  fi

  echo
  info "Final log location: $LOG_FILE"
  exit "$status"
}

main "$@"
