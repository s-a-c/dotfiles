#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test VSCode/Cursor terminal detection and PATH fixing

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

assert_path_starts_with() {
    local expected_prefix="$1"
    local message="${2:-PATH should start with $expected_prefix}"

    # Get first element of PATH
    local first_path="${PATH%%:*}"

    if [[ "$first_path" == "$expected_prefix" ]]; then
        assert_passes "$message"
    else
        assert_fails "$message (got: $first_path)"
    fi
}

# Test: VSCode terminal detection
test_vscode_detection() {
    echo "Running: test_vscode_detection"

    export TERM_PROGRAM="vscode"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Source the terminal integration module
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "VSCode module sources successfully"
    else
        assert_fails "VSCode module should source successfully"
    fi
}

# Test: VSCode PATH fixing (PATH should be re-fixed to have system dirs first)
test_vscode_path_fixing() {
    echo "Running: test_vscode_path_fixing"

    export TERM_PROGRAM="vscode"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Simulate corrupted PATH (extension dirs first)
    export PATH="/some/extension/dir:/another/extension/.bin:/opt/homebrew/bin:/usr/bin:/bin"

    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # Verify PATH now starts with /opt/homebrew/bin
    assert_path_starts_with "/opt/homebrew/bin" "VSCode should fix PATH to start with /opt/homebrew/bin"
}

# Test: VSCode env guard function is defined
test_vscode_env_guard() {
    echo "Running: test_vscode_env_guard"

    export TERM_PROGRAM="vscode"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || return 1

    # Verify env guard function is defined
    if typeset -f __zf_vscode_env_guard >/dev/null 2>&1; then
        assert_passes "VSCode env guard function is defined"
    else
        assert_fails "VSCode env guard function should be defined"
    fi
}

# Test: Idempotency
test_vscode_idempotency() {
    echo "Running: test_vscode_idempotency"

    export TERM_PROGRAM="vscode"
    unset _ZF_TERMINAL_INTEGRATION_DONE

    # Source twice
    if source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null &&  \
       source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" 2>/dev/null; then
        assert_passes "VSCode module is idempotent"
    else
        assert_fails "VSCode module should be idempotent"
    fi
}

# Run tests
test_vscode_detection
test_vscode_path_fixing
test_vscode_env_guard
test_vscode_idempotency

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
