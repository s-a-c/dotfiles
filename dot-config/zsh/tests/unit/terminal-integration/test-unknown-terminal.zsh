#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test graceful handling of unknown/unsupported terminals

set -euo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_passes() {
    local message="$1"
    ((PASS_COUNT++))
    echo "✓ PASS: $message"
}

assert_fails() {
    local message="$1"
    ((FAIL_COUNT++))
    echo "✗ FAIL: $message"
}

# Test: Unknown terminal should not cause errors
test_unknown_terminal_no_error() {
    echo "Running: test_unknown_terminal_no_error"
    
    export TERM_PROGRAM="UnknownTerminal"
    export TERM="xterm-256color"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Module should source successfully even for unknown terminals
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "Unknown terminal does not cause sourcing errors"
    else
        assert_fails "Module should handle unknown terminals gracefully"
    fi
    
    # Idempotency guard should still be set
    if [[ -n "${_ZF_TERMINAL_INTEGRATION_DONE:-}" ]]; then
        assert_passes "Idempotency guard set even for unknown terminal"
    else
        assert_fails "Idempotency guard should be set for unknown terminal"
    fi
}

# Test: Empty TERM_PROGRAM should not cause errors
test_empty_term_program() {
    echo "Running: test_empty_term_program"
    
    unset TERM_PROGRAM
    export TERM="xterm-256color"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Module should source successfully with empty TERM_PROGRAM
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "Empty TERM_PROGRAM does not cause errors"
    else
        assert_fails "Module should handle empty TERM_PROGRAM gracefully"
    fi
}

# Test: No terminal-specific variables set for unknown terminal
test_unknown_terminal_no_vars() {
    echo "Running: test_unknown_terminal_no_vars"
    
    export TERM_PROGRAM="UnknownTerminal"
    export TERM="xterm"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset WARP_IS_LOCAL_SHELL_SESSION
    unset WEZTERM_SHELL_INTEGRATION
    unset GHOSTTY_SHELL_INTEGRATION
    unset KITTY_SHELL_INTEGRATION
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Verify no terminal-specific variables were set
    local vars_set=0
    [[ -n "${WARP_IS_LOCAL_SHELL_SESSION:-}" ]] && ((vars_set++))
    [[ -n "${WEZTERM_SHELL_INTEGRATION:-}" ]] && ((vars_set++))
    [[ -n "${GHOSTTY_SHELL_INTEGRATION:-}" ]] && ((vars_set++))
    [[ -n "${KITTY_SHELL_INTEGRATION:-}" ]] && ((vars_set++))
    
    if [[ $vars_set -eq 0 ]]; then
        assert_passes "No terminal-specific variables set for unknown terminal"
    else
        assert_fails "Terminal-specific variables should not be set for unknown terminal ($vars_set set)"
    fi
}

# Test: Idempotency with unknown terminal
test_unknown_terminal_idempotency() {
    echo "Running: test_unknown_terminal_idempotency"
    
    export TERM_PROGRAM="UnknownTerminal"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Source twice
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null && \
       source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "Module is idempotent with unknown terminal"
    else
        assert_fails "Module should be idempotent with unknown terminal"
    fi
}

# Run tests
test_unknown_terminal_no_error
test_empty_term_program
test_unknown_terminal_no_vars
test_unknown_terminal_idempotency

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

