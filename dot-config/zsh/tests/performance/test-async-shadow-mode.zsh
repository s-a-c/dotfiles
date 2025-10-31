#!/usr/bin/env zsh
# test-async-shadow-mode.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate Phase A async shadow mode invariants:
#     - Shadow mode does not materially inflate prompt_ready latency.
#     - Required synchronous performance segments still present (no regression).
#     - Async shadow tasks emit start/done segments.
#     - No async influence when ASYNC_MODE=off (baseline).
#
# INVARIANTS:
#   I1: Baseline capture (ASYNC_MODE=off) succeeded and produced required segments.
#   I2: Shadow capture (ASYNC_MODE=shadow) succeeded and produced required segments.
#   I3: Required segments appear in BOTH captures: pre_plugin_total, post_plugin_total, prompt_ready, compinit, p10k_theme (compinit / p10k_theme may be optional in broader suite, but here we assert to surface regressions early).
#   I4: prompt_ready delta (shadow - baseline) <= ${ASYNC_SHADOW_PROMPT_DELTA_MAX:-50} ms (fail if exceeded).
#   I5: For every enabled async manifest task (enabled==true), shadow output contains async_task_<id>_start and async_task_<id>_done (or _fail/_timeout accepted, but start must exist).
#   I6: No async_task_<id>_* segments appear in baseline capture (warn if they do).
#   I7: Shadow capture did NOT remove any required segment present in baseline.
#
# EXIT CODES:
#   0 PASS, 1 FAIL (any invariant broken), 2 SKIP (tooling missing).
#
# NOTES:
#   - Uses perf-capture-multi.zsh with --single for speed (Phase A structural test, not variance test).
#   - Assumes repository root (heuristic search) or ZSH_ASYNC_TEST_REPO_ROOT preset.
#   - This test is intentionally strict to surface regressions early; if flakiness occurs
#     adjust ASYNC_SHADOW_PROMPT_DELTA_MAX margin or refine capture harness.
#
# ENV OVERRIDES:
#   ASYNC_SHADOW_PROMPT_DELTA_MAX  Maximum allowed additional ms for prompt_ready (default 50)
#   ASYNC_DEBUG_VERBOSE            If set, enables extra logging during captures
#
set -u

###############################################################################
# Helper Functions
###############################################################################

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0
FAIL_MESSAGES=()

_color() {
  local c="$1"; shift
  if [[ -t 1 ]]; then
    case "$c" in
      red) print -Pn "%F{1}$*%f" ;;
      green) print -Pn "%F{2}$*%f" ;;
      yellow) print -Pn "%F{3}$*%f" ;;
      blue) print -Pn "%F{4}$*%f" ;;
      *) print -- "$*" ;;
    esac
  else
    print -- "$*"
  fi
}

pass() { ((PASS_COUNT++)); _color green "PASS: $*"; }
fail() { ((FAIL_COUNT++)); FAIL_MESSAGES+=("$*"); _color red "FAIL: $*"; }
warn() { ((WARN_COUNT++)); _color yellow "WARN: $*"; }
skip() { ((SKIP_COUNT++)); _color blue "SKIP: $*"; }

finish() {
  print ""
  print "Summary: PASS=${PASS_COUNT} FAIL=${FAIL_COUNT} WARN=${WARN_COUNT} SKIP=${SKIP_COUNT}"
  if (( FAIL_COUNT > 0 )); then
    print "Failure Details:"
    for m in "${FAIL_MESSAGES[@]}"; do
      print " - $m"
    done
    exit 1
  fi
  if (( SKIP_COUNT > 0 && PASS_COUNT == 0 && FAIL_COUNT == 0 )); then
    exit 2
  fi
  exit 0
}

###############################################################################
# Locate Repo Root
###############################################################################

REPO_ROOT="${ZSH_ASYNC_TEST_REPO_ROOT:-}"
if [[ -z "${REPO_ROOT}" ]]; then
  REPO_ROOT="$PWD"
  integer depth=0
  while (( depth < 8 )); do
    if [[ -d "${REPO_ROOT}/dot-config/zsh/tools" && -d "${REPO_ROOT}/dot-config/zsh/docs/redesignv2" ]]; then
      break
    fi
    REPO_ROOT="${REPO_ROOT%/*}"
    ((depth++))
  done
fi

if [[ ! -d "${REPO_ROOT}/dot-config/zsh/tools" ]]; then
  skip "Repository root with expected tools directory not found"
  finish
fi

PERF_TOOL="${REPO_ROOT}/dot-config/zsh/tools/perf-capture-multi.zsh"
if [[ ! -x "${PERF_TOOL}" && ! -r "${PERF_TOOL}" ]]; then
  skip "perf-capture-multi.zsh not present/executable at ${PERF_TOOL}"
  finish
fi

ASYNC_DISPATCHER="${REPO_ROOT}/dot-config/zsh/tools/async-dispatcher.zsh"
ASYNC_TASKS_FILE="${REPO_ROOT}/dot-config/zsh/tools/async-tasks.zsh"
if [[ ! -r "${ASYNC_DISPATCHER}" || ! -r "${ASYNC_TASKS_FILE}" ]]; then
  skip "Async dispatcher or tasks file missing (expected Phase A artifacts)"
  finish
fi

MANIFEST="${REPO_ROOT}/dot-config/zsh/docs/redesignv2/async/manifest.json"
if [[ ! -r "${MANIFEST}" ]]; then
  skip "Async manifest missing at ${MANIFEST}"
  finish
fi

###############################################################################
# Extract Enabled Async Task IDs (Manifest)
###############################################################################

if command -v jq >/dev/null 2>&1; then
  ENABLED_TASK_IDS=("${(@f)$(jq -r '.tasks[] | select(.enabled==true) | .id' "${MANIFEST}")}")
else
  # Fallback (very naive parse) if jq unavailable: attempt to grep ids of enabled true
  ENABLED_TASK_IDS=("${(@f)$(grep -E '"enabled": *true' -B3 "${MANIFEST}" | grep '"id":' | sed -E 's/.*"id": *"([^"]+)".*/\1/')}") || ENABLED_TASK_IDS=()
  warn "jq not available; using fallback grep parse for manifest (may be less robust)"
fi

if (( ${#ENABLED_TASK_IDS[@]} == 0 )); then
  warn "No enabled async tasks in manifest (Phase A may have none) – continuing"
fi

###############################################################################
# Run Baseline (ASYNC_MODE=off)
###############################################################################

BASE_TMP="$(mktemp -t async_shadow_base.XXXXXX)"
SHADOW_TMP="$(mktemp -t async_shadow_shadow.XXXXXX)"

(
  cd "${REPO_ROOT}" || exit 1
  ASYNC_MODE=off ASYNC_DEBUG_VERBOSE=${ASYNC_DEBUG_VERBOSE:-0} \
    "${PERF_TOOL}" --single > "${BASE_TMP}" 2>/dev/null
)
if [[ ! -s "${BASE_TMP}" ]]; then
  fail "I1 baseline capture produced no output"
  finish
fi
pass "I1 baseline capture succeeded"

###############################################################################
# Run Shadow (ASYNC_MODE=shadow)
###############################################################################

(
  cd "${REPO_ROOT}" || exit 1
  ASYNC_MODE=shadow ASYNC_TASKS_AUTORUN=1 ASYNC_DEBUG_VERBOSE=${ASYNC_DEBUG_VERBOSE:-0} \
    "${PERF_TOOL}" --single > "${SHADOW_TMP}" 2>/dev/null
)
if [[ ! -s "${SHADOW_TMP}" ]]; then
  fail "I2 shadow capture produced no output"
  finish
fi
pass "I2 shadow capture succeeded"

###############################################################################
# Parse Required Segments
###############################################################################

REQUIRED_SEGMENTS=(pre_plugin_total post_plugin_total prompt_ready compinit p10k_theme)

_missing_segments() {
  local file="$1" label missing=()
  for label in "${REQUIRED_SEGMENTS[@]}"; do
    if ! grep -q "SEGMENT name=${label} " "$file"; then
      missing+=("$label")
    fi
  done
  print -r -- "${missing[*]}"
}

BASE_MISSING=($(_missing_segments "${BASE_TMP}"))
SHADOW_MISSING=($(_missing_segments "${SHADOW_TMP}"))

if (( ${#BASE_MISSING[@]} > 0 )); then
  fail "I3 baseline missing required segments: ${BASE_MISSING[*]}"
else
  pass "I3 baseline required segments present"
fi

if (( ${#SHADOW_MISSING[@]} > 0 )); then
  fail "I3 shadow missing required segments: ${SHADOW_MISSING[*]}"
else
  pass "I3 shadow required segments present"
fi

###############################################################################
# Prompt Ready Delta (I4)
###############################################################################

_extract_ms() {
  local file="$1" label="$2"
  grep -E "SEGMENT name=${label} " "$file" | sed -n 's/.* ms=\([0-9]\+\).*/\1/p' | head -n1
}

BASE_PR=$(_extract_ms "${BASE_TMP}" prompt_ready)
SHADOW_PR=$(_extract_ms "${SHADOW_TMP}" prompt_ready)

if [[ -z "${BASE_PR}" || -z "${SHADOW_PR}" ]]; then
  fail "I4 unable to parse prompt_ready ms values (base='${BASE_PR}' shadow='${SHADOW_PR}')"
else
  DELTA=$(( SHADOW_PR - BASE_PR ))
  : ${ASYNC_SHADOW_PROMPT_DELTA_MAX:=50}
  if (( DELTA <= ASYNC_SHADOW_PROMPT_DELTA_MAX )); then
    pass "I4 prompt_ready delta ${DELTA}ms ≤ ${ASYNC_SHADOW_PROMPT_DELTA_MAX}ms"
  else
    fail "I4 prompt_ready delta ${DELTA}ms exceeds limit ${ASYNC_SHADOW_PROMPT_DELTA_MAX}ms (BASE=${BASE_PR} SHADOW=${SHADOW_PR})"
  fi
fi

###############################################################################
# Async Task Segment Verification (I5, I6)
###############################################################################

# For each enabled task id expect in SHADOW:
#   async_task_<id>_start
#   async_task_<id>_done (or _fail / _timeout)
ALL_GOOD=1
for tid in "${ENABLED_TASK_IDS[@]}"; do
  start_pat="SEGMENT name=async_task_${tid}_start "
  done_pat="SEGMENT name=async_task_${tid}_done "
  fail_pat="SEGMENT name=async_task_${tid}_fail "
  timeout_pat="SEGMENT name=async_task_${tid}_timeout "

  if ! grep -q "${start_pat}" "${SHADOW_TMP}"; then
    fail "I5 missing start segment for task '${tid}' in shadow capture"
    ALL_GOOD=0
    continue
  fi
  if grep -q "${done_pat}" "${SHADOW_TMP}"; then
    :
  elif grep -q "${fail_pat}" "${SHADOW_TMP}" || grep -q "${timeout_pat}" "${SHADOW_TMP}"; then
    warn "I5 task '${tid}' ended in fail/timeout state (acceptable in Phase A simulation)"
  else
    fail "I5 missing terminal segment (_done/_fail/_timeout) for task '${tid}'"
    ALL_GOOD=0
  fi

  # Baseline should not contain async segments (I6)
  if grep -q "${start_pat}" "${BASE_TMP}"; then
    warn "I6 baseline unexpectedly contains async start segment for '${tid}'"
  fi
done

(( ALL_GOOD )) && (( ${#ENABLED_TASK_IDS[@]} > 0 )) && pass "I5 async start/terminal segments present for all enabled tasks"

###############################################################################
# No required segment removed in shadow (I7)
###############################################################################

REMOVED=()
for label in "${REQUIRED_SEGMENTS[@]}"; do
  if grep -q "SEGMENT name=${label} " "${BASE_TMP}" && ! grep -q "SEGMENT name=${label} " "${SHADOW_TMP}"; then
    REMOVED+=("$label")
  fi
done
if (( ${#REMOVED[@]} > 0 )); then
  fail "I7 required segments missing in shadow that were present in baseline: ${REMOVED[*]}"
else
  pass "I7 no required segments removed in shadow mode"
fi

###############################################################################
# Cleanup & Finish
###############################################################################

rm -f "${BASE_TMP}" "${SHADOW_TMP}" 2>/dev/null || true
finish
