#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test Ghostty terminal detection and integration script sourcing

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

# Test: Ghostty terminal detection without integration script
test_ghostty_detection_basic() {
    echo "Running: test_ghostty_detection_basic"
    
    export TERM_PROGRAM="ghostty"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    unset GHOSTTY_RESOURCES_DIR
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Verify Ghostty-specific variable is set
    assert_var_set "GHOSTTY_SHELL_INTEGRATION" "Ghostty should set GHOSTTY_SHELL_INTEGRATION"
    assert_var_equals "GHOSTTY_SHELL_INTEGRATION" "1" "Ghostty shell integration flag should be 1"
}

# Test: Ghostty with integration script path (but file doesn't exist)
test_ghostty_integration_missing_file() {
    echo "Running: test_ghostty_integration_missing_file"
    
    export TERM_PROGRAM="ghostty"
    export GHOSTTY_RESOURCES_DIR="/nonexistent/path"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    # Should still set the integration flag even if script is missing
    assert_var_set "GHOSTTY_SHELL_INTEGRATION" "Ghostty should set GHOSTTY_SHELL_INTEGRATION even if script missing"
}

# Test: Idempotency
test_ghostty_idempotency() {
    echo "Running: test_ghostty_idempotency"
    
    export TERM_PROGRAM="ghostty"
    unset _ZF_TERMINAL_INTEGRATION_DONE
    
    # Source twice
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1
    
    assert_var_equals "GHOSTTY_SHELL_INTEGRATION" "1" "Ghostty flag should remain 1 after double-sourcing"
}

# Run tests
test_ghostty_detection_basic
test_ghostty_integration_missing_file
test_ghostty_idempotency

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

