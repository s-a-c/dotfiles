#!/usr/bin/env zsh
# =============================================================================
# test-sentinels-idempotency-stage3-core.zsh
#
# Category: design
#
# Purpose:
#   Validates structural sentinel variables and idempotent load behavior for
#   the Stage 3 core trio modules in the post‑plugin redesign path:
#     - 00-security-integrity.zsh
#     - 05-interactive-options.zsh
#     - 10-core-functions.zsh
#
# What This Test Enforces (Current Scope):
#   S1: All three module files exist (else SKIP – environment / sequencing issue).
#   S2: Sourcing each module sets its sentinel variable.
#   S3: Re-sourcing modules does NOT remove any original PATH segments
#       (append-only invariant) and does not shrink PATH length.
#   S4: For the options module:
#         - zf::options_snapshot (if available) produces identical snapshots
#           before and after the second source (idempotent option state).
#   S5: For the core functions module:
#         - zf::list_functions (if available) returns the same ordered list
#           on re-source (no mutation / duplication).
#   S6: Security module deferred task registration is stable (no duplicate
#       entries in ZF_DEFERRED_TASKS for key 'security_integrity_check').
#
# Non-Goals (Future Enhancements):
#   - Deep checksum / hashing validation
#   - Golden option snapshot enforcement (handled elsewhere)
#   - Function definition fingerprint drift guard (unit namespace tests cover basics)
#
# Skip Conditions:
#   - TDD_SKIP_STAGE3_SENTINELS=1
#
# Exit Codes:
#   0 = PASS (or SKIP)
#   1 = FAIL (one or more invariants violated)
#
# Integration Notes:
#   - Complements existing unit tests (namespace, option snapshot, path append).
#   - Provides higher-level structural assurance early in the design test phase.
#
# Update Policy:
#   - If module sentinel naming changes, update SENTINELS map below.
#   - If new Stage 3 foundational modules are added, extend this test carefully.
#
# =============================================================================

set -euo pipefail

if [[ "${TDD_SKIP_STAGE3_SENTINELS:-0}" == "1" ]]; then
  print "SKIP: stage3 sentinel/idempotency test skipped (TDD_SKIP_STAGE3_SENTINELS=1)"
  exit 0
fi

# Quiet debug shim (used by other tests sometimes)
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

PASS=()
FAIL=()
SKIP=()

pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }
skip() { SKIP+=("$1"); }

# -----------------------------------------------------------------------------
# Repo Root Resolution
# -----------------------------------------------------------------------------
SCRIPT_SRC="${(%):-%N}"
# Try helper from core functions if preloaded
if typeset -f zf::script_dir >/dev/null 2>&1; then
  THIS_DIR="$(zf::script_dir "$SCRIPT_SRC")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
  THIS_DIR="$(resolve_script_dir "$SCRIPT_SRC")"
else
  THIS_DIR="${SCRIPT_SRC:h}"
fi
REPO_ROOT="$(cd "$THIS_DIR/../../../.." && pwd -P 2>/dev/null)"

# -----------------------------------------------------------------------------
# Module Definitions
# -----------------------------------------------------------------------------
typeset -A MODULES SENTINELS
MODULES=(
  security "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/00-security-integrity.zsh"
  options  "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/05-interactive-options.zsh"
  corefunc "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/10-core-functions.zsh"
)
SENTINELS=(
  security _LOADED_00_SECURITY_INTEGRITY
  options  _LOADED_05_INTERACTIVE_OPTIONS
  corefunc _LOADED_10_CORE_FUNCTIONS
)

MISSING=0
for key path in ${(kv)MODULES}; do
  if [[ ! -f "$path" ]]; then
    fail "S1 missing-module-${key} (${path})"
    (( MISSING++ ))
  fi
done
if (( MISSING == 0 )); then
  pass "S1 all-modules-present"
fi

if (( MISSING > 0 )); then
  # Infrastructure issue; treat as skip to avoid noisy cascade
  print "SUMMARY: One or more Stage 3 modules missing – skipping deeper checks."
  for f in "${FAIL[@]}"; do print "FAIL: $f"; done
  exit 0
fi

# -----------------------------------------------------------------------------
# Helper: stable env snapshots
# -----------------------------------------------------------------------------
snapshot_path_segments() {
  # Ordered colon-separated segments as array lines
  local s
  for s in ${(s/:/)PATH}; do
    print -- "$s"
  done
}

path_contains_all_original() {
  # Args: orig_snapshot_lines current_snapshot_lines
  local orig="$1" cur="$2"
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    grep -Fx -- "$line" <<<"$cur" >/dev/null 2>&1 || return 1
  done <<< "$orig"
  return 0
}

# -----------------------------------------------------------------------------
# First Source (record baseline state)
# -----------------------------------------------------------------------------
ORIG_PATH_LINES="$(snapshot_path_segments)"
ORIG_PATH_COUNT=$(print "$ORIG_PATH_LINES" | grep -c . || true)

typeset -A FIRST_SNAPSHOT_OPTIONS    # option=state lines from zf::options_snapshot (if available)
FIRST_OPTIONS_RAW=""
typeset -A FIRST_CORE_FUNCS
FIRST_CORE_FUNCS_RAW=""

# Source each module if sentinel not already set (still safe if set)
for key path in ${(kv)MODULES}; do
  # shellcheck disable=SC1090
  if ! . "$path" 2>/dev/null; then
    fail "S2 source-failed-${key}"
  else
    pass "S2 source-ok-${key}"
  fi
done

# Verify sentinels
for key sentinel in ${(kv)SENTINELS}; do
  if [[ -n "${(P)sentinel:-}" ]]; then
    pass "S2 sentinel-set-${key}"
  else
    fail "S2 sentinel-missing-${key} (${sentinel})"
  fi
done

# Capture option snapshot if function present
if typeset -f zf::options_snapshot >/dev/null 2>&1; then
  FIRST_OPTIONS_RAW="$(zf::options_snapshot 2>/dev/null || true)"
  if [[ -n "$FIRST_OPTIONS_RAW" ]]; then
    while IFS= read -r l; do
      [[ -z "$l" ]] && continue
      FIRST_SNAPSHOT_OPTIONS["${l%%=*}"]="$l"
    done <<< "$FIRST_OPTIONS_RAW"
    pass "S4a captured-initial-option-snapshot"
  else
    fail "S4a empty-initial-option-snapshot"
  fi
else
  skip "S4a options-snapshot-function-missing"
fi

# Capture core functions list
if typeset -f zf::list_functions >/dev/null 2>&1; then
  FIRST_CORE_FUNCS_RAW="$(zf::list_functions 2>/dev/null || true)"
  if [[ -n "$FIRST_CORE_FUNCS_RAW" ]]; then
    while IFS= read -r fn; do
      [[ -z "$fn" ]] && continue
      FIRST_CORE_FUNCS["$fn"]=1
    done <<< "$FIRST_CORE_FUNCS_RAW"
    pass "S5a captured-initial-core-func-list"
  else
    fail "S5a empty-initial-core-func-list"
  fi
else
  skip "S5a core-function-list-helper-missing"
fi

# Security deferred task key if present
INITIAL_DEFERRED_VAL="${ZF_DEFERRED_TASKS[security_integrity_check]:-<unset>}"

# -----------------------------------------------------------------------------
# Second Source (idempotency)
# -----------------------------------------------------------------------------
for key path in ${(kv)MODULES}; do
  # shellcheck disable=SC1090
  if ! . "$path" 2>/dev/null; then
    fail "S3 resource-failed-${key}"
  else
    pass "S3 resource-ok-${key}"
  fi
done

# -----------------------------------------------------------------------------
# PATH Invariant (append-only / non-destructive)
# -----------------------------------------------------------------------------
CUR_PATH_LINES="$(snapshot_path_segments)"
CUR_PATH_COUNT=$(print "$CUR_PATH_LINES" | grep -c . || true)

if (( CUR_PATH_COUNT < ORIG_PATH_COUNT )); then
  fail "S3 path-length-decreased before=${ORIG_PATH_COUNT} after=${CUR_PATH_COUNT}"
else
  pass "S3 path-length-nonshrinking before=${ORIG_PATH_COUNT} after=${CUR_PATH_COUNT}"
fi

if path_contains_all_original "$ORIG_PATH_LINES" "$CUR_PATH_LINES"; then
  pass "S3 original-path-segments-retained"
else
  fail "S3 original-path-segment-loss"
fi

# -----------------------------------------------------------------------------
# Options Snapshot Idempotency
# -----------------------------------------------------------------------------
if [[ -n "${FIRST_OPTIONS_RAW:-}" ]]; then
  SECOND_OPTIONS_RAW="$(zf::options_snapshot 2>/dev/null || true)"
  if [[ -z "$SECOND_OPTIONS_RAW" ]]; then
    fail "S4b second-snapshot-empty"
  else
    if diff -u <(print -- "$FIRST_OPTIONS_RAW") <(print -- "$SECOND_OPTIONS_RAW") >/dev/null 2>&1; then
      pass "S4b option-snapshot-stable"
    else
      fail "S4b option-snapshot-drift"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Core Functions Idempotency
# -----------------------------------------------------------------------------
if [[ -n "${FIRST_CORE_FUNCS_RAW:-}" ]]; then
  SECOND_CORE_FUNCS_RAW="$(zf::list_functions 2>/dev/null || true)"
  if [[ -z "$SECOND_CORE_FUNCS_RAW" ]]; then
    fail "S5b second-core-func-list-empty"
  else
    if diff -u <(print -- "$FIRST_CORE_FUNCS_RAW") <(print -- "$SECOND_CORE_FUNCS_RAW") >/dev/null 2>&1; then
      pass "S5b core-func-list-stable"
    else
      fail "S5b core-func-list-drift"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Deferred Task Stability (Security Module)
# -----------------------------------------------------------------------------
SECOND_DEFERRED_VAL="${ZF_DEFERRED_TASKS[security_integrity_check]:-<unset>}"
if [[ "$INITIAL_DEFERRED_VAL" == "$SECOND_DEFERRED_VAL" ]]; then
  pass "S6 deferred-task-stable (${SECOND_DEFERRED_VAL})"
else
  fail "S6 deferred-task-mutated before=${INITIAL_DEFERRED_VAL} after=${SECOND_DEFERRED_VAL}"
fi

# -----------------------------------------------------------------------------
# Reporting
# -----------------------------------------------------------------------------
for s in "${SKIP[@]}"; do
  print "SKIP: $s"
done
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} skips=${#SKIP[@]}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
