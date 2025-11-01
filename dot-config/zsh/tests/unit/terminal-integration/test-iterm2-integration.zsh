#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test iTerm2 terminal detection and integration script sourcing

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

# Test: iTerm2 terminal detection without integration script
test_iterm2_detection_no_script() {
    echo "Running: test_iterm2_detection_no_script"

    export TERM_PROGRAM="iTerm.app"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Ensure integration script doesn't exist
    rm -f "${HOME}/.iterm2_shell_integration.zsh" 2>/dev/null || true

    # Source should succeed even without integration script
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "iTerm2 module sources successfully without integration script"
    else
        assert_fails "iTerm2 module should source successfully without integration script"
    fi
}

# Test: iTerm2 with integration script
test_iterm2_integration_with_script() {
    echo "Running: test_iterm2_integration_with_script"

    export TERM_PROGRAM="iTerm.app"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Create a mock integration script
    cat > "${HOME}/.iterm2_shell_integration.zsh" <<'EOF'
# Mock iTerm2 integration script
export _ITERM2_INTEGRATION_LOADED=1
EOF

    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # Verify mock script was sourced
    if [[ "${_ITERM2_INTEGRATION_LOADED:-}" == "1" ]]; then
        assert_passes "iTerm2 integration script was sourced"
    else
        assert_fails "iTerm2 integration script should be sourced when present"
    fi

    # Cleanup
    rm -f "${HOME}/.iterm2_shell_integration.zsh"
    unset _ITERM2_INTEGRATION_LOADED
}

# Test: Idempotency
test_iterm2_idempotency() {
    echo "Running: test_iterm2_idempotency"

    export TERM_PROGRAM="iTerm.app"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Source twice
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null &&    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "iTerm2 module is idempotent (can be sourced twice)"
    else
        assert_fails "iTerm2 module should be idempotent"
    fi
}

# Run tests
test_iterm2_detection_no_script
test_iterm2_integration_with_script
test_iterm2_idempotency

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
