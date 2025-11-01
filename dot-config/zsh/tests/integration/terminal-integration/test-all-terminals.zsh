#!/usr/bin/env zsh
# TEST_CLASS: integration
# TEST_MODE: zsh-f-required
# Integration test covering all supported terminal types

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

# Helper: Test a terminal type
test_terminal_type() {
    local term_program="$1"
    local term_value="${2:-xterm-256color}"
    local expected_var="$3"
    local description="$4"
    
    echo "Testing: $description (TERM_PROGRAM=$term_program)"
    
    # Clean state
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset WARP_IS_LOCAL_SHELL_SESSION
    unset WEZTERM_SHELL_INTEGRATION
    unset GHOSTTY_SHELL_INTEGRATION
    unset KITTY_SHELL_INTEGRATION
    
    export TERM_PROGRAM="$term_program"
    export TERM="$term_value"
    
    # Source module
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "$description: Module sources successfully"
        
        # Check expected variable if specified
        if [[ -n "$expected_var" ]]; then
            if [[ -n "${(P)expected_var:-}" ]]; then
                assert_passes "$description: Expected variable $expected_var is set"
            else
                assert_fails "$description: Expected variable $expected_var should be set"
            fi
        fi
    else
        assert_fails "$description: Module should source successfully"
    fi
}

# Test all supported terminals
echo "========================================="
echo "Testing All Supported Terminal Types"
echo "========================================="
echo ""

# Warp
test_terminal_type "WarpTerminal" "xterm-256color" "WARP_IS_LOCAL_SHELL_SESSION" "Warp Terminal"

# WezTerm
test_terminal_type "WezTerm" "xterm-256color" "WEZTERM_SHELL_INTEGRATION" "WezTerm"

# Ghostty
test_terminal_type "ghostty" "xterm-256color" "GHOSTTY_SHELL_INTEGRATION" "Ghostty"

# Kitty (uses TERM instead of TERM_PROGRAM)
echo "Testing: Kitty Terminal (TERM=xterm-kitty)"
unset _ZF_TERMINAL_INTEGRATION_DONE
unset KITTY_SHELL_INTEGRATION
unset TERM_PROGRAM
export TERM="xterm-kitty"

if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
    assert_passes "Kitty: Module sources successfully"
    if [[ -n "${KITTY_SHELL_INTEGRATION:-}" ]]; then
        assert_passes "Kitty: KITTY_SHELL_INTEGRATION is set"
    else
        assert_fails "Kitty: KITTY_SHELL_INTEGRATION should be set"
    fi
else
    assert_fails "Kitty: Module should source successfully"
fi

# iTerm2
test_terminal_type "iTerm.app" "xterm-256color" "" "iTerm2"

# VSCode/Cursor
echo "Testing: VSCode/Cursor"
unset _ZF_TERMINAL_INTEGRATION_DONE
export TERM_PROGRAM="vscode"
export TERM="xterm-256color"

if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
    assert_passes "VSCode: Module sources successfully"
    
    # Check if PATH was fixed
    if [[ "$PATH" == /opt/homebrew/bin:* || "$PATH" == /usr/local/bin:* ]]; then
        assert_passes "VSCode: PATH was fixed to start with system directories"
    else
        assert_fails "VSCode: PATH should be fixed to start with system directories"
    fi
    
    # Check if env guard function exists
    if typeset -f __zf_vscode_env_guard >/dev/null 2>&1; then
        assert_passes "VSCode: Env guard function is defined"
    else
        assert_fails "VSCode: Env guard function should be defined"
    fi
else
    assert_fails "VSCode: Module should source successfully"
fi

# Unknown terminal (should handle gracefully)
test_terminal_type "UnknownTerminal" "xterm-256color" "" "Unknown Terminal (graceful handling)"

# Empty TERM_PROGRAM (should handle gracefully)
echo "Testing: Empty TERM_PROGRAM"
unset _ZF_TERMINAL_INTEGRATION_DONE
unset TERM_PROGRAM
export TERM="xterm-256color"

if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
    assert_passes "Empty TERM_PROGRAM: Module sources successfully"
else
    assert_fails "Empty TERM_PROGRAM: Module should source successfully"
fi

# Test idempotency across all terminals
echo ""
echo "Testing Idempotency..."
unset _ZF_TERMINAL_INTEGRATION_DONE
export TERM_PROGRAM="WarpTerminal"

if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null && \
   source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
    assert_passes "Idempotency: Module can be sourced multiple times"
else
    assert_fails "Idempotency: Module should handle multiple sourcing"
fi

# Summary
echo ""
echo "========================================="
echo "Integration Test Results"
echo "========================================="
echo "Total: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

