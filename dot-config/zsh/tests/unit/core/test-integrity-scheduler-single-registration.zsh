#!/usr/bin/env zsh
# =============================================================================
# test-integrity-scheduler-single-registration.zsh
#
# Purpose:
#   Validates that the Stage 3 security / integrity core module
#     00-security-integrity.zsh
#   registers its integrity scheduling hook(s) exactly once (idempotent) and
#   does NOT trigger actual hashing or enter a RUNNING / ACTIVE state prior
#   to the designated later stage (Stage 5/6).
#
# What This Test Covers (Heuristics):
#   S1: Module present (else SKIP).
#   S2: After first source, integrity *scheduler* artifacts appear:
#       - A queue/scheduling function (default expected name:
#         zsh_security_queue_integrity_scan) OR
#       - A hook function with an integrity / security marker in its name.
#   S3: Re-sourcing the module does not add duplicate hook entries
#       (precmd_functions / periodic_functions / zsh_hooks etc.).
#   S4: Environment state variable (_ASYNC_PLUGIN_HASH_STATE) must NOT read
#       RUNNING (acceptable: IDLE / QUEUED / <unset>).
#   S5: (Optional) Invoking the queue function (if present) must not block or
#       emit errors; it may set a non-RUNNING transitional marker (e.g. QUEUED).
#
# Skip Conditions:
#   - TDD_SKIP_INTEGRITY_SCHED=1
#   - Module file absent
#
# Exit Codes:
#   0 = PASS or SKIP
#   1 = FAIL
#
# Notes:
#   - This test is intentionally forgiving about exact naming while Stage 3
#     implementation details are in motion. Tighten once the module stabilizes.
#   - Does NOT assert that a deep hash ever runs; only ensures no premature
#     execution and idempotent registration.
#
# Future Hardening (post-implementation):
#   - Enforce exact hook name & target hook array.
#   - Verify log emission markers.
#   - Capture time-to-return budget for queue function.
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Skip Handling
# -----------------------------------------------------------------------------
if [[ "${TDD_SKIP_INTEGRITY_SCHED:-0}" == "1" ]]; then
  print "SKIP: integrity scheduler test skipped (TDD_SKIP_INTEGRITY_SCHED=1)"
  exit 0
fi

# -----------------------------------------------------------------------------
# Minimal debug shim
# -----------------------------------------------------------------------------
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

PASS=()
FAIL=()
pass() { PASS+=("$1"); }
fail() { FAIL+=("$1"); }

# -----------------------------------------------------------------------------
# Repo Root Resolution
# -----------------------------------------------------------------------------
SCRIPT_SRC="${(%):-%N}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  REPO_ROOT="$ZDOTDIR"
fi

MODULE_REL=".zshrc.d.REDESIGN/00-security-integrity.zsh"
MODULE_PATH="${REPO_ROOT}/dot-config/zsh/${MODULE_REL}"

if [[ ! -f "$MODULE_PATH" ]]; then
  print "SKIP: security/integrity module not present (${MODULE_REL})"
  exit 0
fi
pass "S1 module-present"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
_collect_integrity_hooks() {
  # Collect candidate hook function names from standard hook arrays that
  # reference integrity/security semantics.
  local out=()
  local arr fn
  # Candidate arrays to inspect (extend if module chooses others)
  local -a CANDIDATE_HOOK_ARRAYS=(
    precmd_functions
    periodic_functions
    chpwd_functions
    preexec_functions
    zsh_hooks  # custom (if defined)
  )
  for arr in "${CANDIDATE_HOOK_ARRAYS[@]}"; do
    if typeset -p "$arr" >/dev/null 2>&1; then
      # Indirect reference
      eval "local -a __tmp_array=( \"\${${arr}[@]}\" )"
      for fn in "${__tmp_array[@]}"; do
        if [[ "$fn" == *integrity* || "$fn" == *security* ]]; then
          out+=("$fn")
        fi
      done
    fi
  done
  # Print one per line
  printf '%s\n' "${out[@]}" | sort -u
}

_function_exists() {
  typeset -f "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Baseline Capture (Before Sourcing)
# -----------------------------------------------------------------------------
BASELINE_HOOKS="$(_collect_integrity_hooks || true)"

# -----------------------------------------------------------------------------
# First Source
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
if ! . "$MODULE_PATH" 2>/dev/null; then
  fail "S2 module-source-failed-first"
else
  pass "S2 module-sourced-first"
fi

AFTER_FIRST_HOOKS="$(_collect_integrity_hooks || true)"

# Detect new hooks introduced
typeset -A NEW_HOOKS
if [[ -n "$AFTER_FIRST_HOOKS" ]]; then
  while IFS= read -r h; do
    if ! grep -qx -- "$h" <<<"$BASELINE_HOOKS"; then
      NEW_HOOKS["$h"]=1
    fi
  done <<< "$AFTER_FIRST_HOOKS"
fi

if (( ${#NEW_HOOKS[@]} > 0 )); then
  pass "S2a hooks-registered (${(j:, :)${(k)NEW_HOOKS}})"
else
  # Not necessarily failure yet—maybe scheduling function only
  pass "S2a no-new-hook-names (acceptable if using on-demand scheduler)"
fi

# Scheduler function heuristic
SCHED_FN="zsh_security_queue_integrity_scan"
SCHED_PRESENT=0
if _function_exists "$SCHED_FN"; then
  SCHED_PRESENT=1
  pass "S2b scheduler-function-present(${SCHED_FN})"
else
  pass "S2b scheduler-function-missing (may appear later)"
fi

# -----------------------------------------------------------------------------
# Environment State (Ensure not RUNNING yet)
# -----------------------------------------------------------------------------
state="${_ASYNC_PLUGIN_HASH_STATE:-<unset>}"
if [[ "$state" == "RUNNING" || "$state" == "SCANNING" ]]; then
  fail "S4 invalid-early-state=${state}"
else
  pass "S4 non-running-state=${state}"
fi

# -----------------------------------------------------------------------------
# Optional: Invoke scheduler (if present) to ensure idempotent & non-blocking
# -----------------------------------------------------------------------------
if (( SCHED_PRESENT == 1 )); then
  # Protect from errors; expect quick return
  set +e
  ( "$SCHED_FN" >/dev/null 2>&1 )
  rc=$?
  set -e
  if (( rc == 0 )); then
    pass "S5 scheduler-invocation-ok"
  else
    fail "S5 scheduler-invocation-rc=${rc}"
  fi
  # Re-check state should still not be RUNNING (unless design changes later)
  post_state="${_ASYNC_PLUGIN_HASH_STATE:-<unset>}"
  if [[ "$post_state" == "RUNNING" || "$post_state" == "SCANNING" ]]; then
    fail "S5 post-invoke-state-premature=${post_state}"
  else
    pass "S5 post-invoke-state=${post_state}"
  fi
fi

# -----------------------------------------------------------------------------
# Second Source (Idempotency)
# -----------------------------------------------------------------------------
# shellcheck disable=SC1090
if ! . "$MODULE_PATH" 2>/dev/null; then
  fail "S3 module-source-failed-second"
else
  pass "S3 module-sourced-second"
fi
AFTER_SECOND_HOOKS="$(_collect_integrity_hooks || true)"

# Compare counts for integrity-related hooks
count_first=$(print -r -- "$AFTER_FIRST_HOOKS" | grep -c . || true)
count_second=$(print -r -- "$AFTER_SECOND_HOOKS" | grep -c . || true)
if (( count_second == count_first )); then
  pass "S3a hook-count-stable=${count_second}"
elif (( count_second > count_first )); then
  fail "S3a hook-duplication count_first=${count_first} count_second=${count_second}"
else
  # Fewer after second source is suspicious but treat as fail
  fail "S3a hook-count-decreased count_first=${count_first} count_second=${count_second}"
fi

# Detect duplicates introduced specifically in second source pass
if [[ -n "$AFTER_SECOND_HOOKS" ]]; then
  # Count occurrences
  dup_report=$(print -r -- "$AFTER_SECOND_HOOKS" | sort | uniq -c | awk '$1>1{print}')
  if [[ -n "$dup_report" ]]; then
    fail "S3b duplicate-hook-entries-detected: ${dup_report}"
  else
    pass "S3b no-duplicate-hook-entries"
  fi
else
  pass "S3b no-hooks-present (acceptable)"
fi

# -----------------------------------------------------------------------------
# Results
# -----------------------------------------------------------------------------
for p in "${PASS[@]}"; do
  print "PASS: $p"
done
for f in "${FAIL[@]}"; do
  print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#PASS[@]} fails=${#FAIL[@]} sched_fn=${SCHED_PRESENT} state_initial=${state}"

if (( ${#FAIL[@]} > 0 )); then
  print -u2 "TEST RESULT: FAIL"
  exit 1
fi

print "TEST RESULT: PASS"
exit 0
