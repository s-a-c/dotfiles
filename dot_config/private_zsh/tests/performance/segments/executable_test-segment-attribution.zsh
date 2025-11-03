#!/usr/bin/env zsh
# test-segment-attribution.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate initial real segment attribution & deferred aggregation:
#     1. pre_plugin_start anchor emitted exactly once.
#     2. prompt_ready segment emitted exactly once (with PROMPT_READY_COMPLETE).
#     3. deferred_total segment emitted exactly once.
#     4. All DEFERRED job lines appear BEFORE deferred_total segment.
#     5. deferred_total ms >= sum of individual DEFERRED job durations.
#
# SCOPE:
#   Focused attribution test – sources only minimal modules needed to exercise
#   phase anchors & deferred dispatcher (00, 95, 96).
#
# ASSUMPTIONS:
#   - Dummy deferred job "dummy-warm" registered by 96-deferred-dispatch.zsh.
#   - 00-path-safety establishes ZSH_START_MS.
#
# OUTPUT:
#   Prints PASS/FAIL lines; exits non-zero on failure.
#
# NOTE:
#   This is a lightweight test and does NOT attempt to replicate full .zshrc
#   orchestration; it calls internal hook functions directly to avoid reliance
#   on add-zsh-hook availability in a -f environment.

set -euo pipefail

fail() {
  print -r -- "FAIL: $*" >&2
  exit 1
}

warn() {
  print -r -- "WARN: $*" >&2
}

pass() {
  print -r -- "PASS: $*"
}

# ---------------------------------------------------------------------------
# Setup temp workspace
# ---------------------------------------------------------------------------
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t segtest)"
LOG_FILE="${TMP_DIR}/perf-segments.log"
export PERF_SEGMENT_LOG="$LOG_FILE"
: > "$LOG_FILE" || fail "Unable to create PERF_SEGMENT_LOG at $LOG_FILE"

ZDOTDIR_ROOT="${PWD}/dot-config/zsh"
PRE_DIR="${ZDOTDIR_ROOT}/.zshrc.pre-plugins.d.REDESIGN"
POST_DIR="${ZDOTDIR_ROOT}/.zshrc.d.REDESIGN"

[[ -r "${PRE_DIR}/00-path-safety.zsh" ]] || fail "Missing 00-path-safety.zsh"
[[ -r "${POST_DIR}/95-prompt-ready.zsh" ]] || fail "Missing 95-prompt-ready.zsh"
[[ -r "${POST_DIR}/96-deferred-dispatch.zsh" ]] || fail "Missing 96-deferred-dispatch.zsh"

# Source minimal modules
source "${PRE_DIR}/00-path-safety.zsh"
source "${POST_DIR}/95-prompt-ready.zsh"
source "${POST_DIR}/96-deferred-dispatch.zsh"

# Sanity anchors
[[ -n ${ZSH_START_MS:-} ]] || fail "ZSH_START_MS not set by pre-plugin start module"

# Manually invoke internal hooks in deterministic order
typeset -f __pr__capture_prompt_ready >/dev/null 2>&1 || fail "prompt-ready hook function missing"
typeset -f __zsh_deferred_run_once >/dev/null 2>&1 || fail "deferred dispatcher function missing"

__pr__capture_prompt_ready
__zsh_deferred_run_once

# Flush to ensure log writes are visible
sync 2>/dev/null || true

[[ -s "$LOG_FILE" ]] || fail "PERF_SEGMENT_LOG empty – expected segment lines"

# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
grep_once() {
  local pat="$1" label="$2"
  local count
  count=$(grep -Fc -- "$pat" "$LOG_FILE" || true)
  [[ "$count" -eq 1 ]] || fail "Expected exactly 1 occurrence of '$label' (pattern: $pat) found $count"
}

extract_ms_from_segment() {
  # Usage: extract_ms_from_segment label
  local label="$1"
  grep -E "^SEGMENT name=${label} " "$LOG_FILE" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

# 1. Single occurrence checks
grep_once "SEGMENT name=pre_plugin_start "  "pre_plugin_start segment"
grep_once "SEGMENT name=prompt_ready "      "prompt_ready segment"
grep_once "SEGMENT name=deferred_total "    "deferred_total segment"

# 2. Ensure PROMPT_READY_COMPLETE present (legacy marker)
grep -q "^PROMPT_READY_COMPLETE " "$LOG_FILE" || fail "Missing PROMPT_READY_COMPLETE marker"

# 3. Order: All DEFERRED job lines must precede deferred_total segment
deferred_total_line=$(grep -n "^SEGMENT name=deferred_total " "$LOG_FILE" | cut -d: -f1 | head -n1)
if grep -n "^DEFERRED id=" "$LOG_FILE" >/dev/null 2>&1; then
  while IFS= read -r dl; do
    dln=${dl%%:*}
    if (( dln > deferred_total_line )); then
      fail "Found DEFERRED job line after deferred_total segment (line $dln > $deferred_total_line)"
    fi
  done < <(grep -n "^DEFERRED id=" "$LOG_FILE")
else
  warn "No DEFERRED id= lines found – expected dummy-warm job"
fi

# 4. deferred_total ms >= sum individual DEFERRED ms
deferred_total_ms=$(extract_ms_from_segment "deferred_total")
[[ -n "$deferred_total_ms" ]] || fail "Could not parse deferred_total ms value"

sum_jobs=0
while IFS= read -r line; do
  ms=$(print -r -- "$line" | sed -n 's/.* ms=\([0-9]\+\) .*/\1/p')
  [[ -n "$ms" ]] && (( sum_jobs += ms ))
done < <(grep "^DEFERRED id=" "$LOG_FILE" || true)

if (( sum_jobs > 0 )); then
  if (( deferred_total_ms < sum_jobs )); then
    fail "deferred_total ms (${deferred_total_ms}) < sum of job ms (${sum_jobs})"
  fi
else
  # If no jobs, deferred_total should be 0
  if (( deferred_total_ms != 0 )); then
    fail "deferred_total ms (${deferred_total_ms}) expected 0 with no jobs"
  fi
fi

# 5. Basic non-negative sanity
for label in pre_plugin_start prompt_ready deferred_total; do
  val=$(extract_ms_from_segment "$label")
  [[ "$val" =~ ^[0-9]+$ ]] || fail "Non-numeric ms value for $label: '$val'"
done

# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------
pass "segment attribution & deferred aggregation checks passed"
exit 0
