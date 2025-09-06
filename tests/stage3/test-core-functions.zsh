#!/usr/bin/env zsh
# ============================================================================
# test-core-functions.zsh
#
# Purpose:
#   Validate Stage 3 core functions module (10-core-functions.zsh) for:
#     - Successful sourcing & sentinel variables
#     - ensure_cmd positive / negative behavior
#     - ensure_cmd caching (negative result persists until cache entry removed)
#     - Assertion helper (success, failure non-fatal, failure with ZF_ASSERT_EXIT=1)
#     - Timing helpers (time_block / with_timing)
#
# Assertions (AX):
#   A1: Module sources and guard set
#   A2: ensure_cmd finds an existing command (printf)
#   A3: ensure_cmd negative miss returns 1 for a fake command
#   A4: ensure_cmd caches negative result (still fails after command appears in PATH)
#   A5: ensure_cmd succeeds after cache entry is cleared and command exists
#   A6: zf::assert passes for true condition
#   A7: zf::assert returns failure (non-fatal) for false condition
#   A8: zf::assert with ZF_ASSERT_EXIT=1 still returns failure (captured) for false condition
#   A9: zf::time_block captures a numeric duration (ms)
#   A10: zf::with_timing runs command and returns its exit code (0)
#
# Exit Code:
#   0 if all assertions pass, 1 otherwise.
#
# Style:
#   4-space indentation (EditorConfig compliance)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"
ZSH_DIR="${REPO_ROOT}/dot-config/zsh"
CORE_FN_REL=".zshrc.d.REDESIGN/POSTPLUGIN/10-core-functions.zsh"
CORE_FN_PATH="${ZSH_DIR}/${CORE_FN_REL}"

if [[ ! -f "${ZSH_DIR}/.zshenv" ]]; then
    print -u2 "FAIL: prerequisite - .zshenv missing (${ZSH_DIR}/.zshenv)"
    exit 1
fi
if [[ ! -f "${CORE_FN_PATH}" ]]; then
    print -u2 "FAIL: prerequisite - core functions module missing (${CORE_FN_PATH})"
    exit 1
fi

read -r -d '' ZSH_PAYLOAD <<'__ZSH_EOF__'
set -euo pipefail

_pass=()
_fail=()

pass() { _pass+=("$1"); }
fail() { _fail+=("$1"); }

# Source core functions ( .zshenv already sourced automatically )
if ! source "$TEST_CORE_FUNCTIONS_MODULE"; then
    fail "A1: source-module (sourcing failed)"
else
    if [[ "${ZSH_CORE_FUNCTIONS_GUARD:-}" == "1" ]]; then
        pass "A1: source-module"
    else
        fail "A1: source-module (guard not set)"
    fi
fi

# A2: ensure_cmd positive (printf should exist)
if zf::ensure_cmd printf "should exist"; then
    pass "A2: ensure_cmd-positive"
else
    fail "A2: ensure_cmd-positive (printf not detected)"
fi

# Choose a fake command unlikely to exist
FAKE_CMD="__zf_fake_cmd_$$"

# A3: initial miss
if zf::ensure_cmd "${FAKE_CMD}"; then
    fail "A3: ensure_cmd-negative (unexpected success)"
else
    pass "A3: ensure_cmd-negative"
fi

# Create the fake command AFTER first miss (should remain cached as miss)
FAKE_BIN_DIR="$(mktemp -d 2>/dev/null || mktemp -t fakebin)"
echo '#!/usr/bin/env zsh\necho FAKE' > "${FAKE_BIN_DIR}/${FAKE_CMD}"
chmod +x "${FAKE_BIN_DIR}/${FAKE_CMD}"
# Prepend new dir so the command would now resolve if not cached
PATH="${FAKE_BIN_DIR}:$PATH"
export PATH

# A4: Cached negative result (should still fail)
if zf::ensure_cmd "${FAKE_CMD}"; then
    fail "A4: ensure_cmd-cache-negative (unexpected success; cache miss not preserved)"
else
    pass "A4: ensure_cmd-cache-negative"
fi

# Clear cache entry to simulate fresh lookup
if typeset -p _zf_cmd_cache >/dev/null 2>&1; then
    unset "_zf_cmd_cache[cmd_${FAKE_CMD}]" || true
fi

# A5: Should now succeed (command exists on PATH)
if zf::ensure_cmd "${FAKE_CMD}" "appeared after cache purge"; then
    pass "A5: ensure_cmd-post-cache-purge"
else
    fail "A5: ensure_cmd-post-cache-purge (still failing after cache purge)"
fi

# A6: Assertion success
if zf::assert '[[ 2 -eq 2 ]]' "2==2 expected"; then
    pass "A6: assert-success"
else
    fail "A6: assert-success (returned non-zero)"
fi

# A7: Assertion failure (should not abort, returns 1)
if zf::assert '[[ 3 -eq 4 ]]' "intentional fail"; then
    fail "A7: assert-failure (unexpected success)"
else
    pass "A7: assert-failure"
fi

# A8: Assertion failure with ZF_ASSERT_EXIT=1 (should still be capturable as non-zero)
export ZF_ASSERT_EXIT=1
if zf::assert '[[ 5 -eq 6 ]]' "intentional fail strict"; then
    fail "A8: assert-failure-strict (unexpected success)"
else
    pass "A8: assert-failure-strict"
fi
unset ZF_ASSERT_EXIT || true

# A9: time_block measurement
elapsed_ms=""
if zf::time_block elapsed_ms sleep 0.01; then
    if [[ -n "$elapsed_ms" && "$elapsed_ms" =~ ^[0-9]+$ ]]; then
        pass "A9: time-block"
    else
        fail "A9: time-block (elapsed_ms invalid: '${elapsed_ms}')"
    fi
else
    fail "A9: time-block (wrapper failed)"
fi

# A10: with_timing wrapper (no segment emission forced)
export ZF_WITH_TIMING_EMIT=0
if zf::with_timing "core_functions_test_label" sleep 0.005; then
    pass "A10: with-timing"
else
    fail "A10: with-timing (returned non-zero)"
fi
unset ZF_WITH_TIMING_EMIT || true

# Emit Results
for p in "${_pass[@]}"; do
    print "PASS: $p"
done
for f in "${_fail[@]}"; do
    print "FAIL: $f"
done

print "---"
print "SUMMARY: passes=${#_pass[@]} fails=${#_fail[@]}"

(( ${#_fail[@]} == 0 )) || exit 1
exit 0
__ZSH_EOF__

set +e
RAW_OUTPUT="$(
    env -i \
        HOME="$HOME" \
        ZDOTDIR="$ZSH_DIR" \
        TEST_CORE_FUNCTIONS_MODULE="$CORE_FN_PATH" \
        PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
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
