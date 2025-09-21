#!/usr/bin/env zsh
# test-idle-trigger-budget.zsh
#
# S4-27 Hard Budget Enforcement Test
#
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# PURPOSE:
#   Verify that the idle trigger stops executing additional tasks once the
#   cumulative elapsed time exceeds ZSH_IDLE_HARD_BUDGET_MS and reports
#   budget_exceeded=1 in the IDLE:SUMMARY line.
#
# VALIDATION POINTS:
#   - budget_exceeded=1 appears in IDLE:SUMMARY
#   - Fewer tasks execute than were registered (early stop)
#   - At least one task executed (non‑trivial run)
#   - Second invocation produces no additional output (idempotent)
#
# SUCCESS CRITERIA (from sprint metrics):
#   - Execution time < 1s overall
#   - Deterministic early stop under an extremely low hard budget
#
# IMPLEMENTATION NOTES:
#   - We set a very low hard budget (e.g. 8ms) and make each task sleep ~20ms.
#     After the first task completes (≈20ms), cumulative > budget, so the runner
#     should stop and mark budget_exceeded=1.
#
# EXIT CODES:
#   0 success
#   1 failure
#
# ------------------------------------------------------------------------------
emulate -L zsh
setopt errexit nounset pipefail

# -----------------------------
# Assertion / Helper Functions
# -----------------------------
_fail() { print -r -- "[FAIL] $*" >&2; exit 1; }
_info() { print -r -- "[INFO] $*" >&2; }
_assert_true() {
  local cond="$1" msg="$2"
  if ! eval "$cond"; then
    _fail "assert_true: $msg"
  fi
}
_assert_contains() {
  local needle="$1" haystack="$2" msg="$3"
  if ! print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    _fail "assert_contains: '$needle' not found :: $msg"
  fi
}
_assert_not_contains() {
  local needle="$1" haystack="$2" msg="$3"
  if print -r -- "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    _fail "assert_not_contains: '$needle' unexpectedly present :: $msg"
  fi
}

# -----------------------------
# Locate & Source Idle Module
# -----------------------------
SCRIPT_PATH="${(%):-%N}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
# Expect: .../dot-config/zsh/tests/performance/idle/
ZSH_ROOT="${SCRIPT_DIR:A:h:h:h}"
IDLE_FILE="${ZSH_ROOT}/.zshrc.d.REDESIGN/97-idle-trigger.zsh"
[[ -r "$IDLE_FILE" ]] || _fail "Idle trigger file not readable: $IDLE_FILE"

source "$IDLE_FILE"
_assert_true '[[ -n ${_LOADED_97_IDLE_TRIGGER:-} ]]' "Idle trigger sentinel not set"

# -----------------------------
# Test Configuration
# -----------------------------
# Very low hard budget to force early stop after first task.
ZSH_IDLE_ENABLE=1
ZSH_IDLE_HARD_BUDGET_MS=8          # ms (intentionally tiny)
ZSH_IDLE_TASK_TIMEOUT_MS=0         # disable timeout flagging (not under test)
ZSH_IDLE_LOG_VERBOSE=0
unset ZSH_LOG_STRUCTURED 2>/dev/null || true

# -----------------------------
# Define Tasks
# Each task ~20ms (sleep 0.02) so first task alone exceeds budget.
# -----------------------------
_budget_task_1() { sleep 0.02 }
_budget_task_2() { sleep 0.02 }
_budget_task_3() { sleep 0.02 }
_budget_task_4() { sleep 0.02 }

# Register tasks (ordering matters; all should NOT run)
zf::idle::register t1 _budget_task_1 "budget test task 1" || _fail "register t1"
zf::idle::register t2 _budget_task_2 "budget test task 2" || _fail "register t2"
zf::idle::register t3 _budget_task_3 "budget test task 3" || _fail "register t3"
zf::idle::register t4 _budget_task_4 "budget test task 4" || _fail "register t4"

TOTAL_REGISTERED=4

# -----------------------------
# Execute (First Run)
# -----------------------------
run_output="$( ( zf::idle::run_if_ready ) 2>&1 )" || _fail "idle run returned non-zero"

# Basic markers
_assert_contains "IDLE:START" "$run_output" "Missing IDLE:START marker"
_assert_contains "IDLE:SUMMARY" "$run_output" "Missing IDLE:SUMMARY marker"

# Budget exceeded flag
_assert_contains "budget_exceeded=1" "$run_output" "Budget exceeded flag not present"

# Count executed tasks by counting IDLE:TASK lines
executed_count="$(print -r -- "$run_output" | grep -c '^IDLE:TASK ' || true)"

# At least one executed
[[ "$executed_count" -ge 1 ]] || _fail "No tasks executed (expected at least 1)"
# Fewer than total registered (early stop)
[[ "$executed_count" -lt "$TOTAL_REGISTERED" ]] || _fail "All tasks executed despite low hard budget (executed=$executed_count)"

_info "Executed tasks: $executed_count (registered=$TOTAL_REGISTERED) – early stop confirmed."

# Validate SUMMARY line reflects total registered tasks (tasks=<TOTAL_REGISTERED>)
# SUMMARY includes tasks=<N> meaning total registered, not executed, so this should match registration size.
summary_line="$(print -r -- "$run_output" | grep 'IDLE:SUMMARY' || true)"
if ! print -r -- "$summary_line" | grep -q "tasks=${TOTAL_REGISTERED}"; then
  _fail "IDLE:SUMMARY tasks field does not match registered count (expected ${TOTAL_REGISTERED})"
fi

# Sanity: Ensure we do NOT see later task ids if early stop happened after the first.
# We expect at most t1 appears. It is possible (though unlikely) timing overshoot allows t2 start;
# so we only assert that at least one of t3 or t4 is absent to prove early cut.
if print -r -- "$run_output" | grep -q "IDLE:TASK id=t3"; then
  # If t3 ran, budget threshold logic failed (would require > ~40ms cumulative).
  _fail "Unexpected execution of t3 (third task) under tiny budget (suggests budget logic failure)"
fi

# -----------------------------
# Idempotent Second Run
# -----------------------------
second_output="$( ( zf::idle::run_if_ready ) 2>&1 )" || _fail "Second run non-zero"
_assert_not_contains "IDLE:START" "$second_output" "Second run should produce no START"
_assert_not_contains "IDLE:TASK" "$second_output" "Second run should produce no TASK lines"
_assert_not_contains "IDLE:SUMMARY" "$second_output" "Second run should produce no SUMMARY"

_info "Hard budget enforcement test passed."
exit 0
