#!/usr/bin/env zsh
# ============================================================================
# test-interactive-options.zsh
#
# Purpose:
#   Validate Stage 3 interactive options module (05-interactive-options.zsh)
#   for:
#     - Idempotency (re-sourcing produces no option diff)
#     - Guard & sentinel variable correctness
#     - Absence of premature compinit execution
#     - Reservation marker for future single compinit module
#
# Assertions:
#   A1: Module sources successfully (guard variable set)
#   A2: Baseline options applied (ZSH_INTERACTIVE_OPTIONS_APPLIED=1)
#   A3: Re-sourcing module is idempotent (no option diff)
#   A4: compinit not executed ( _COMPINIT_DONE unset )
#   A5: Reservation marker ZSH_COMPINIT_RESERVED=1
#
# Output:
#   PASS:/FAIL: lines per assertion + summary
#
# Exit Codes:
#   0 on full pass, 1 if any assertion fails or preconditions not met
#
# Style:
#   4-space indentation (EditorConfig conformity)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
MODULE_REL_PATH=".zshrc.d.REDESIGN/POSTPLUGIN/05-interactive-options.zsh"
MODULE_PATH="${ZSH_DIR}/${MODULE_REL_PATH}"

if [[ ! -d "${ZSH_DIR}" ]]; then
    print -u2 "FAIL: prerequisite - ZSH_DIR not found at ${ZSH_DIR}"
    exit 1
fi
if [[ ! -f "${MODULE_PATH}" ]]; then
    print -u2 "FAIL: prerequisite - interactive options module missing at ${MODULE_PATH}"
    exit 1
fi
if [[ ! -f "${ZSH_DIR}/.zshenv" ]]; then
    print -u2 "FAIL: prerequisite - .zshenv missing at ${ZSH_DIR}/.zshenv"
    exit 1
fi

# Build payload executed in a pristine environment.
read -r -d '' ZSH_PAYLOAD <<'__ZSH_EOF__'
set -euo pipefail

_fail=()
_pass=()

pass() { _pass+=("$1"); }
fail() { _fail+=("$1"); }

# Source interactive options module in a clean context.
# .zshenv has already been sourced automatically by zsh startup (-f ignores .zshrc only).
if ! source "$TEST_INTERACTIVE_MODULE"; then
    fail "A1: source-module (initial source failed)"
else
    if [[ "${ZSH_INTERACTIVE_OPTIONS_GUARD:-}" == "1" ]]; then
        pass "A1: source-module"
    else
        fail "A1: source-module (guard not set)"
    fi
fi

# A2: Baseline applied
if [[ "${ZSH_INTERACTIVE_OPTIONS_APPLIED:-}" == "1" ]]; then
    pass "A2: baseline-applied"
else
    fail "A2: baseline-applied (flag not set)"
fi

# Prepare snapshot files
_snapshot_dir="$(mktemp -d 2>/dev/null || mktemp -t interopts)"
before_snap="${_snapshot_dir}/before.txt"
after_snap="${_snapshot_dir}/after.txt"

# Snapshot function must exist
if typeset -f zf::opt_snapshot >/dev/null 2>&1; then
    zf::opt_snapshot > "${before_snap}"
else
    fail "A3: idempotent (zf::opt_snapshot missing)"
fi

# Re-source module (should be idempotent)
if ! source "$TEST_INTERACTIVE_MODULE"; then
    fail "A3: idempotent (re-source failed)"
fi

# Capture after snapshot
if typeset -f zf::opt_snapshot >/dev/null 2>&1; then
    zf::opt_snapshot > "${after_snap}"
fi

# Compute diff using comm (sorted outputs expected)
if [[ -s "${before_snap}" && -s "${after_snap}" ]]; then
    # Lines only in AFTER (additions) or only in BEFORE (removals)
    added="$(comm -13 "${before_snap}" "${after_snap}" || true)"
    removed="$(comm -23 "${before_snap}" "${after_snap}" || true)"
    if [[ -z "${added}" && -z "${removed}" ]]; then
        pass "A3: idempotent"
    else
        fail "A3: idempotent (option drift detected)"
        [[ -n "${added}" ]] && print "DIFF-ADDED: ${added}" >&2
        [[ -n "${removed}" ]] && print "DIFF-REMOVED: ${removed}" >&2
    fi
else
    fail "A3: idempotent (snapshots missing)"
fi

# A4: compinit not executed
if [[ -z "${_COMPINIT_DONE:-}" ]]; then
    pass "A4: no-compinit"
else
    fail "A4: no-compinit (_COMPINIT_DONE set prematurely)"
fi

# A5: reservation marker exists
if [[ "${ZSH_COMPINIT_RESERVED:-}" == "1" ]]; then
    pass "A5: reservation-marker"
else
    fail "A5: reservation-marker (ZSH_COMPINIT_RESERVED missing)"
fi

# Emit results
for p in "${_pass[@]}"; do
    print "PASS: ${p}"
done
for f in "${_fail[@]}"; do
    print "FAIL: ${f}"
done

print "---"
print "SUMMARY: passes=${#_pass[@]} fails=${#_fail[@]}"

# Exit code
(( ${#_fail[@]} == 0 )) || exit 1
exit 0
__ZSH_EOF__

set +e
RAW_OUTPUT="$(
    env -i \
        HOME="$HOME" \
        ZDOTDIR="$ZSH_DIR" \
        TEST_INTERACTIVE_MODULE="$MODULE_PATH" \
        PATH="" \
        TERM=dumb \
        ZSH_DEBUG=0 \
        zsh -dfc "${ZSH_PAYLOAD}"
)"
rc=$?
set -e

print -- "${RAW_OUTPUT}"

if (( rc != 0 )); then
    print -u2 "TEST RESULT: FAIL (rc=${rc})"
    exit $rc
fi

print "TEST RESULT: PASS"
exit 0
