#!/usr/bin/env zsh
# test-p10k-instrumentation.zsh
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate that the Powerlevel10k theme instrumentation module (60-p10k-instrument.zsh)
#   emits a SEGMENT line with label `p10k_theme` when a theme file is present.
#   Ensures hotspot timing coverage for prompt initialization required for
#   performance observe/warn/gate phases (G5a → G6 roadmap).
#
# SCOPE:
#   - Detects presence of a .p10k.zsh configuration file (ZDOTDIR or $HOME).
#   - Launches an interactive redesign harness with PERF_SEGMENT_LOG to trigger
#     instrumentation (non-blocking first prompt exit via PERF_PROMPT_HARNESS=1).
#   - Parses the emitted SEGMENT lines for `p10k_theme`.
#
# INVARIANTS:
#   I1: Theme file exists (otherwise test SKIP – instrumentation not expected to run).
#   I2: SEGMENT line with name=p10k_theme is present.
#   I3: ms value for p10k_theme is a non-negative integer.
#   I4 (soft): ms value is < 5000 (sanity upper bound; failures above treated as anomaly).
#
# EXIT CODES:
#   0 PASS or SKIP (graceful skip when theme not present)
#   1 FAIL (any required invariant violation when theme present)
#
# NOTES:
#   - Does not assert performance budget; only presence & basic sanity.
#   - Safe to run repeatedly; creates and deletes a temporary log file.
#   - If you add a custom theme path override (ZSH_P10K_FILE), exporting it
#     before invoking this test will cause detection to honor that path.
#
# FUTURE EXTENSIONS:
#   - Capture separate cold/warm deltas once multi-sample harness is added.
#   - Add variance checks across multiple invocations (stdev guard).
#
# -----------------------------------------------------------------------------

set -euo pipefail

# Color helpers
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BOLD=""; RESET=""
fi

pass() { print "${GREEN}PASS${RESET}: $*"; }
fail() { print "${RED}FAIL${RESET}: $*"; FAILURES+=("$*"); }
warn() { print "${YELLOW}WARN${RESET}: $*"; }
info() { print "${YELLOW}INFO${RESET}: $*"; }

FAILURES=()

# Resolve ZDOTDIR (default layout)
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Theme file detection order:
#   1. Explicit override ZSH_P10K_FILE (if readable)
#   2. $ZDOTDIR/.p10k.zsh
#   3. $HOME/.p10k.zsh
THEME_FILE=""
if [[ -n "${ZSH_P10K_FILE:-}" && -r "${ZSH_P10K_FILE}" ]]; then
  THEME_FILE="${ZSH_P10K_FILE}"
elif [[ -r "${ZDOTDIR}/.p10k.zsh" ]]; then
  THEME_FILE="${ZDOTDIR}/.p10k.zsh"
elif [[ -r "${HOME}/.p10k.zsh" ]]; then
  THEME_FILE="${HOME}/.p10k.zsh"
fi

if [[ -z "${THEME_FILE}" ]]; then
  print "${YELLOW}SKIP${RESET}: I1 theme file (.p10k.zsh) not found – instrumentation not expected (no failure)."
  exit 0
fi
pass "I1 theme file detected: ${THEME_FILE}"

# Create temporary segment log
SEG_LOG=$(mktemp -t p10k-segments.XXXXXX)
trap 'rm -f "$SEG_LOG" 2>/dev/null || true' EXIT

# Launch redesigned shell with harness to emit segments
# PERF_PROMPT_HARNESS causes early exit after first prompt (95-prompt-ready.zsh)
ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
PERF_PROMPT_HARNESS=1 \
PERF_SEGMENT_LOG="$SEG_LOG" \
ZSH_P10K_FILE="$THEME_FILE" \
bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run "exit"' >/dev/null 2>&1 || true

if [[ ! -s "$SEG_LOG" ]]; then
  fail "Segment log empty – instrumentation harness did not run or failed"
else
  info "Segment log size: $(stat -f '%z' "$SEG_LOG" 2>/dev/null || stat -c '%s' "$SEG_LOG" 2>/dev/null) bytes"
fi

# Extract p10k_theme line
P10K_LINE=$(grep -E '^SEGMENT name=p10k_theme ' "$SEG_LOG" || true)
if [[ -z "$P10K_LINE" ]]; then
  fail "I2 missing SEGMENT line for p10k_theme (instrumentation module 60-p10k-instrument.zsh may not have loaded)"
else
  pass "I2 SEGMENT line present for p10k_theme"
  # Validate ms token
  MS_VALUE=$(print -- "$P10K_LINE" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p')
  if [[ -z "$MS_VALUE" || ! "$MS_VALUE" =~ ^[0-9]+$ ]]; then
    fail "I3 invalid or missing ms value in line: $P10K_LINE"
  else
    pass "I3 ms value numeric (ms=${MS_VALUE})"
    if (( MS_VALUE >= 5000 )); then
      warn "I4 ms value unusually high (>=5000ms) – investigate prompt/theme overhead (ms=${MS_VALUE})"
    else
      pass "I4 ms value within sanity threshold (<5000ms)"
    fi
  fi
fi

# Optional info: show first few segment lines for context
CONTEXT=$(grep '^SEGMENT ' "$SEG_LOG" | head -10 || true)
if [[ -n "$CONTEXT" ]]; then
  info "First SEGMENT lines (context):"
  print -- "$CONTEXT"
fi

print ""
if (( ${#FAILURES[@]} == 0 )); then
  print "${BOLD}${GREEN}PASS${RESET}: p10k instrumentation test successful."
  exit 0
else
  print "${BOLD}${RED}FAIL${RESET}: ${#FAILURES[@]} invariant(s) failed:"
  for f in "${FAILURES[@]}"; do
    print "  - $f"
  done
  print ""
  print "Remediation suggestions:"
  print "  * Ensure 60-p10k-instrument.zsh is present and sourced in post-plugin sequence."
  print "  * Confirm segment-lib.zsh loads before the theme instrumentation module."
  print "  * Verify PERF_PROMPT_HARNESS=1 and PERF_SEGMENT_LOG are set during test invocation."
  print "  * Check that the theme file is readable and not short-circuiting due to prior load sentinel."
  exit 1
fi
