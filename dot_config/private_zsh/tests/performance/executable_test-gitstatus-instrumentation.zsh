#!/usr/bin/env zsh
# test-gitstatus-instrumentation.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate that the git status backend instrumentation (65-vcs-gitstatus-instrument.zsh)
#   emits a SEGMENT line with label `gitstatus_init` when a gitstatus plugin script
#   is present and sourced during redesigned post-plugin startup. Ensures hotspot
#   timing coverage for VCS prompt backend cold initialization (critical for performance
#   regression detection and future budget enforcement).
#
# SCOPE:
#   - Detects presence of a gitstatus plugin file using the same candidate resolution
#   - (Used by instrumentation module) OR honors explicit override via ZSH_GITSTATUS_PROBE_PATH.
#   - Launches an interactive redesign harness with PERF_SEGMENT_LOG capture and early
#   - exit after first prompt (PERF_PROMPT_HARNESS).
#   - Parses emitted SEGMENT lines for `gitstatus_init`.
#
# INVARIANTS:
#   I1: Gitstatus plugin file exists (else test SKIP).
#   I2: SEGMENT line with name=gitstatus_init present.
#   I3: ms value numeric (>=0).
#   I4 (soft): ms < 5000 (sanity upper bound; warn if exceeded).
#
# EXIT CODES:
#   0 PASS or SKIP
#   1 FAIL (any required invariant violated when plugin present)
#
# NOTES:
#   - Does not assert absolute performance budget (handled by gating phases).
#   - If multiple plugin candidates exist only the first readable path is used.
#   - Safe for repeated CI execution.
#
# FUTURE EXTENSIONS:
#   - Distinguish sourcing cost vs daemon readiness delay (split segments).
#   - Add variance sampling once multi-run capture implemented.
#
# -----------------------------------------------------------------------------
set -euo pipefail
#
# Color helpers
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi
#
pass() { print "${GREEN}PASS${RESET}: $*"; }
fail() { print "${RED}FAIL${RESET}: $*"; FAILURES+=("$*"); }
warn() { print "${YELLOW}WARN${RESET}: $*"; }
info() { print "${YELLOW}INFO${RESET}: $*"; }
#
FAILURES=()
#
# Resolve ZDOTDIR (expect redesigned layout)
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
#
# Determine candidate plugin paths (align with instrumentation module)
CANDIDATES=()
if [[ -n "${ZSH_GITSTATUS_PROBE_PATH:-}" ]]; then
  CANDIDATES+=("${ZSH_GITSTATUS_PROBE_PATH}")
else
  base="${ZDOTDIR}"
  home="${HOME}"
  CANDIDATES+=(
    "${base}/.zsh/gitstatus/gitstatus.plugin.zsh"
    "${base}/.zsh/plugins/gitstatus/gitstatus.plugin.zsh"
    "${base}/plugins/gitstatus/gitstatus.plugin.zsh"
    "${base}/gitstatus/gitstatus.plugin.zsh"
    "${home}/.cache/gitstatus/gitstatus.plugin.zsh"
    "${home}/.oh-my-zsh/custom/plugins/gitstatus/gitstatus.plugin.zsh"
    "${home}/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/gitstatus.plugin.zsh"
  )
fi
#
GITSTATUS_PLUGIN=""
for f in "${CANDIDATES[@]}"; do
  if [[ -r "$f" ]]; then
    GITSTATUS_PLUGIN="$f"
    break
  fi
done
#
if [[ -z "${GITSTATUS_PLUGIN}" ]]; then
  print "${YELLOW}SKIP${RESET}: I1 gitstatus plugin file not found – instrumentation segment not expected."
  exit 0
fi
pass "I1 gitstatus plugin detected: ${GITSTATUS_PLUGIN}"
#
# Create temporary segment log
SEG_LOG=$(mktemp -t gitstatus-segments.XXXXXX)
trap 'rm -f "$SEG_LOG" 2>/dev/null || true' EXIT
#
# Launch redesigned shell harness
ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
PERF_PROMPT_HARNESS=1 \
PERF_SEGMENT_LOG="$SEG_LOG" \
ZSH_GITSTATUS_PROBE_PATH="$GITSTATUS_PLUGIN" \
bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run "exit"' >/dev/null 2>&1 || true
#
if [[ ! -s "$SEG_LOG" ]]; then
  fail "Segment log empty – instrumentation harness did not run or failed"
else
  info "Segment log size: $(stat -f '%z' "$SEG_LOG" 2>/dev/null || stat -c '%s' "$SEG_LOG" 2>/dev/null) bytes"
fi
#
# Extract gitstatus_init segment
SEG_LINE=$(grep -E '^SEGMENT name=gitstatus_init ' "$SEG_LOG" || true)
if [[ -z "$SEG_LINE" ]]; then
  fail "I2 missing SEGMENT line for gitstatus_init (module 65-vcs-gitstatus-instrument.zsh may not have executed)"
else
  pass "I2 SEGMENT line present for gitstatus_init"
  # Extract ms value
  MS_VALUE=$(print -- "$SEG_LINE" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p')
  if [[ -z "$MS_VALUE" || ! "$MS_VALUE" =~ ^[0-9]+$ ]]; then
    fail "I3 invalid or missing ms for gitstatus_init (line: $SEG_LINE)"
  else
    pass "I3 ms value numeric (ms=${MS_VALUE})"
    if (( MS_VALUE >= 5000 )); then
      warn "I4 ms value unusually high (>=5000ms) – investigate gitstatus daemon initialization (ms=${MS_VALUE})"
    else
      pass "I4 ms value within sanity threshold (<5000ms)"
    fi
  fi
fi
#
# Optional: show first segment lines for debugging context
CONTEXT=$(grep '^SEGMENT ' "$SEG_LOG" | head -10 || true)
if [[ -n "$CONTEXT" ]]; then
  info "First SEGMENT lines (context):"
  print -- "$CONTEXT"
fi
#
print ""
if (( ${#FAILURES[@]} == 0 )); then
  print "${BOLD}${GREEN}PASS${RESET}: gitstatus instrumentation test successful."
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#FAILURES[@]} invariant(s) failed:"
  for f in "${FAILURES[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation suggestions:"
  print "  * Ensure 65-vcs-gitstatus-instrument.zsh is sourced in redesigned post-plugin sequence."
  print "  * Verify PERF_SEGMENT_LOG and PERF_PROMPT_HARNESS=1 are set during test run."
  print "  * Confirm gitstatus plugin file is readable and not short-circuited by prior sentinel."
  print "  * Validate segment-lib.zsh loads before the instrumentation module for unified emission."
  exit 1
fi
