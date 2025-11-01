#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test WezTerm terminal detection and WEZTERM_SHELL_INTEGRATION export

set -euo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Self-contained assertions  
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

# Test: WezTerm terminal detection
test_wezterm_detection() {
    echo "Running: test_wezterm_detection"
    
    # Set up WezTerm environment
    export TERM_PROGRAM="WezTerm"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Source the terminal integration module
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Verify WezTerm-specific variable is set
    assert_var_set "WEZTERM_SHELL_INTEGRATION" "WezTerm should set WEZTERM_SHELL_INTEGRATION"
    assert_var_equals "WEZTERM_SHELL_INTEGRATION" "1" "WezTerm shell integration flag should be 1"
    
    # Verify idempotency guard is set
    assert_var_set "_ZF_TERMINAL_INTEGRATION_DONE" "Idempotency guard should be set"
}

# Test: Idempotency
test_wezterm_idempotency() {
    echo "Running: test_wezterm_idempotency"
    
    export TERM_PROGRAM="WezTerm"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Source twice
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Should still work correctly
    assert_var_equals "WEZTERM_SHELL_INTEGRATION" "1" "WezTerm flag should remain 1 after double-sourcing"
}

# Test: Non-WezTerm terminal should not set WezTerm variables
test_non_wezterm_terminal() {
    echo "Running: test_non_wezterm_terminal"
    
    export TERM_PROGRAM="NotWezTerm"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset WEZTERM_SHELL_INTEGRATION
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # WezTerm variable should not be set
    if [[ -z "${WEZTERM_SHELL_INTEGRATION:-}" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: WEZTERM_SHELL_INTEGRATION not set for non-WezTerm terminal"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: WEZTERM_SHELL_INTEGRATION should not be set for non-WezTerm terminal"
    fi
}

# Run tests
test_wezterm_detection
test_wezterm_idempotency
test_non_wezterm_terminal

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

# Exit with appropriate code
[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

