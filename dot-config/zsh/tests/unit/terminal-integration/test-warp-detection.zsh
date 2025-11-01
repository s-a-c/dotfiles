#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test Warp terminal detection and WARP_IS_LOCAL_SHELL_SESSION export

set -euo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Self-contained assertions
typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion}"

    if [[ "$expected" == "$actual" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: $message"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

assert_var_set() {
    local var_name="$1"
    local message="${2:-Variable $var_name should be set}"

    if [[ -n "${(P)var_name:-}" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: $message"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: $message"
    fi
}

assert_var_equals() {
    local var_name="$1"
    local expected="$2"
    local message="${3:-Variable $var_name should equal $expected}"
    local actual="${(P)var_name:-}"

    if [[ "$expected" == "$actual" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: $message"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

# Test: Warp terminal detection
test_warp_detection() {
    echo "Running: test_warp_detection"

    # Set up Warp environment
    export TERM_PROGRAM="WarpTerminal"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Source the terminal integration module
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # Verify Warp-specific variable is set
    assert_var_set "WARP_IS_LOCAL_SHELL_SESSION" "Warp should set WARP_IS_LOCAL_SHELL_SESSION"
    assert_var_equals "WARP_IS_LOCAL_SHELL_SESSION" "1" "Warp session flag should be 1"

    # Verify idempotency guard is set
    assert_var_set "_ZF_TERMINAL_INTEGRATION_DONE" "Idempotency guard should be set"
}

# Test: Idempotency (sourcing twice should not duplicate)
test_warp_idempotency() {
    echo "Running: test_warp_idempotency"

    export TERM_PROGRAM="WarpTerminal"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Source twice
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # Should still work correctly
    assert_var_equals "WARP_IS_LOCAL_SHELL_SESSION" "1" "Warp session flag should remain 1 after double-sourcing"
}

# Test: Non-Warp terminal should not set Warp variables
test_non_warp_terminal() {
    echo "Running: test_non_warp_terminal"

    export TERM_PROGRAM="NotWarp"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset WARP_IS_LOCAL_SHELL_SESSION

    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # WARP variable should not be set
    if [[ -z "${WARP_IS_LOCAL_SHELL_SESSION:-}" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: WARP_IS_LOCAL_SHELL_SESSION not set for non-Warp terminal"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: WARP_IS_LOCAL_SHELL_SESSION should not be set for non-Warp terminal"
    fi
}

# Run tests
test_warp_detection
test_warp_idempotency
test_non_warp_terminal

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

# Exit with appropriate code
[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
