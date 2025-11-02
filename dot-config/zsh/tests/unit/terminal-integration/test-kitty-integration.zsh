#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test Kitty terminal detection via TERM environment variable

set -euo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

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

# Test: Kitty terminal detection via TERM=xterm-kitty
test_kitty_detection() {
    echo "Running: test_kitty_detection"
    
    export TERM="xterm-kitty"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Verify Kitty-specific variable is set
    assert_var_set "KITTY_SHELL_INTEGRATION" "Kitty should set KITTY_SHELL_INTEGRATION"
    assert_var_equals "KITTY_SHELL_INTEGRATION" "enabled" "Kitty shell integration should be 'enabled'"
}

# Test: Non-Kitty TERM should not set Kitty variables
test_non_kitty_term() {
    echo "Running: test_non_kitty_term"
    
    export TERM="xterm-256color"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset KITTY_SHELL_INTEGRATION
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Kitty variable should not be set
    if [[ -z "${KITTY_SHELL_INTEGRATION:-}" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: KITTY_SHELL_INTEGRATION not set for non-Kitty terminal"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: KITTY_SHELL_INTEGRATION should not be set for non-Kitty terminal"
    fi
}

# Test: Idempotency
test_kitty_idempotency() {
    echo "Running: test_kitty_idempotency"
    
    export TERM="xterm-kitty"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Source twice
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    assert_var_equals "KITTY_SHELL_INTEGRATION" "enabled" "Kitty flag should remain 'enabled' after double-sourcing"
}

# Run tests
test_kitty_detection
test_non_kitty_term
test_kitty_idempotency

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

