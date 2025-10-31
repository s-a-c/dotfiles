#!/usr/bin/env zsh
# test-async-manifest-integrity.zsh
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate integrity between the async manifest (docs/redesignv2/async/manifest.json)
#   and the runtime async dispatcher registration in Phase A (shadow mode).
#
# COVERED INVARIANTS:
#   I1: Manifest file exists and is readable.
#   I2: jq tool available (otherwise test SKIP – cannot parse JSON deterministically).
#   I3: Each task with enabled==true in manifest is registered at runtime after bootstrap.
#   I4: No registered runtime task (shadow mode) is absent from manifest enabled list.
#   I5: Integrity section "expected_active_shadow_tasks" matches enabled==true set.
#   I6: Planned future tasks (integrity.planned_future_tasks) are NOT (yet) enabled (defensive).
#   I7: No duplicate task IDs in manifest.
#   I8: Each enabled task has required fields: id,label,priority,timeout_ms,feature_flag.
#
# EXIT CODES:
#   0 = PASS (all invariants satisfied or acceptable SKIP)
#   1 = FAIL (one or more invariants violated)
#   2 = SKIP (prerequisite tool missing – jq)
#
# NOTES:
#   - Phase A shadow mode keeps synchronous originals; this test only checks registration parity.
#   - Future phases may extend to verify timeout_ms bounds or overhead budgets.
#
# USAGE:
#   Invoked by performance test runner. No arguments expected.

set -u

# ------------- Helpers ------------------------------------------------------

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0
FAIL_MESSAGES=()

_colorize() {
  local code="$1"; shift
  if [[ -t 1 ]]; then
    case "$code" in
      green) print -Pn "%F{2}$*%f" ;;
      red) print -Pn "%F{1}$*%f" ;;
      yellow) print -Pn "%F{3}$*%f" ;;
      blue) print -Pn "%F{4}$*%f" ;;
      *) print -- "$*" ;;
    esac
  else
    print -- "$*"
  fi
}

pass() { ((PASS_COUNT++)); _colorize green "PASS: $*"; }
fail() { ((FAIL_COUNT++)); FAIL_MESSAGES+=("$*"); _colorize red "FAIL: $*"; }
warn() { ((WARN_COUNT++)); _colorize yellow "WARN: $*"; }
skip() { ((SKIP_COUNT++)); _colorize blue "SKIP: $*"; }

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

# ------------- Locate Manifest ----------------------------------------------

REPO_ROOT="${ZSH_ASYNC_TEST_REPO_ROOT:-}"
if [[ -z "${REPO_ROOT}" ]]; then
  # Heuristic: traverse upward looking for dot-config/zsh/docs/redesignv2
  REPO_ROOT="$PWD"
  integer depth=0
  while (( depth < 8 )); do
    if [[ -d "${REPO_ROOT}/dot-config/zsh/docs/redesignv2" ]]; then
      break
    fi
    REPO_ROOT="${REPO_ROOT%/*}"
    ((depth++))
  done
fi

MANIFEST_REL="dot-config/zsh/docs/redesignv2/async/manifest.json"
MANIFEST_PATH="${REPO_ROOT}/${MANIFEST_REL}"

if [[ ! -r "${MANIFEST_PATH}" ]]; then
  fail "I1 manifest missing or unreadable at ${MANIFEST_PATH}"
  finish
fi
pass "I1 manifest present"

# ------------- Prerequisite Tools ------------------------------------------

if ! command -v jq >/dev/null 2>&1; then
  skip "I2 jq not available; cannot parse JSON – test skipped"
  finish
fi
pass "I2 jq available"

# ------------- Parse Manifest ----------------------------------------------

# Collect enabled task ids
ENABLED_TASK_IDS=("${(@f)$(jq -r '.tasks[] | select(.enabled==true) | .id' "${MANIFEST_PATH}")}")
ALL_TASK_IDS=("${(@f)$(jq -r '.tasks[].id' "${MANIFEST_PATH}")}")

# Dedup check (I7)
typeset -A seen_ids
dup_found=0
for id in "${ALL_TASK_IDS[@]}"; do
  if (( ${+seen_ids[$id]} )); then
    dup_found=1
    fail "I7 duplicate task id in manifest: ${id}"
  else
    seen_ids[$id]=1
  fi
done
(( dup_found == 0 )) && pass "I7 no duplicate task IDs"

# Integrity expected active set (I5)
EXPECTED_ACTIVE=("${(@f)$(jq -r '.integrity.expected_active_shadow_tasks[]?' "${MANIFEST_PATH}")}")
# Planned future tasks
PLANNED_FUTURE=("${(@f)$(jq -r '.integrity.planned_future_tasks[]?' "${MANIFEST_PATH}")}")

# Compare EXPECTED_ACTIVE vs ENABLED_TASK_IDS (order-insensitive)
typeset -A set_expected set_enabled
for t in "${EXPECTED_ACTIVE[@]}"; do set_expected[$t]=1; done
for t in "${ENABLED_TASK_IDS[@]}"; do set_enabled[$t]=1; done

mismatch=0
for t in "${EXPECTED_ACTIVE[@]}"; do
  [[ -n ${set_enabled[$t]:-} ]] || { mismatch=1; fail "I5 expected active task '${t}' not enabled"; }
done
for t in "${ENABLED_TASK_IDS[@]}"; do
  [[ -n ${set_expected[$t]:-} ]] || { mismatch=1; fail "I5 enabled task '${t}' not listed in expected_active_shadow_tasks"; }
done
(( mismatch == 0 )) && pass "I5 expected_active_shadow_tasks matches enabled set"

# Planned tasks must NOT be enabled yet (I6)
planned_enabled_conflict=0
for t in "${PLANNED_FUTURE[@]}"; do
  if [[ -n ${set_enabled[$t]:-} ]]; then
    planned_enabled_conflict=1
    fail "I6 planned future task '${t}' is already enabled (should remain disabled in Phase A)"
  fi
done
(( planned_enabled_conflict == 0 )) && pass "I6 planned future tasks remain disabled"

# ------------- Field Validation (I8) ---------------------------------------

missing_fields=0
for id in "${ENABLED_TASK_IDS[@]}"; do
  # For each required field, ensure non-null value
  for field in label priority timeout_ms feature_flag; do
    value=$(jq -r --arg id "$id" --arg f "$field" '.tasks[] | select(.id==$id) | .[$f]' "${MANIFEST_PATH}")
    if [[ -z "${value}" || "${value}" == "null" ]]; then
      missing_fields=1
      fail "I8 enabled task '${id}' missing required field '${field}'"
    fi
  done
done
(( missing_fields == 0 )) && pass "I8 required fields present for all enabled tasks"

# ------------- Runtime Dispatcher Registration (I3/I4) ---------------------

# Prepare environment for shadow bootstrap
export ASYNC_MODE=shadow
export ASYNC_TASKS_AUTORUN=1
export ASYNC_DEBUG_VERBOSE=0

DISPATCHER="${REPO_ROOT}/dot-config/zsh/tools/async-dispatcher.zsh"
TASKS_FILE="${REPO_ROOT}/dot-config/zsh/tools/async-tasks.zsh"

if [[ ! -r "${DISPATCHER}" || ! -r "${TASKS_FILE}" ]]; then
  fail "I3 async dispatcher or tasks file missing (expected at tools/)"
  finish
fi

# Source dispatcher and tasks
source "${DISPATCHER}"
source "${TASKS_FILE}"

# Ensure bootstrap executed (autorun path); fallback call if needed
typeset -f async_tasks_phaseA_shadow_bootstrap >/dev/null 2>&1 && async_tasks_phaseA_shadow_bootstrap

# Collect runtime registered task IDs (keys of __ASYNC_TASK_CMD)
runtime_ids=()
if typeset -p __ASYNC_TASK_CMD >/dev/null 2>&1; then
  runtime_ids=("${(@k)__ASYNC_TASK_CMD}")
fi

# Set membership maps
typeset -A set_runtime
for t in "${runtime_ids[@]}"; do set_runtime[$t]=1; done

# I3: each enabled manifest task registered
i3_fail=0
for t in "${ENABLED_TASK_IDS[@]}"; do
  [[ -n ${set_runtime[$t]:-} ]] || { fail "I3 enabled task '${t}' not registered at runtime"; i3_fail=1; }
done
(( i3_fail == 0 )) && pass "I3 all enabled manifest tasks registered"

# I4: no extra runtime tasks beyond enabled (allow tasks with status planned but disabled, should not register)
i4_fail=0
for t in "${runtime_ids[@]}"; do
  if [[ -z ${set_enabled[$t]:-} ]]; then
    # This could be a violation if task is not expected active
    fail "I4 runtime task '${t}' registered but not enabled in manifest"
    i4_fail=1
  fi
done
(( i4_fail == 0 )) && pass "I4 no unexpected runtime tasks registered"

# ------------- Finalize ----------------------------------------------------

finish
