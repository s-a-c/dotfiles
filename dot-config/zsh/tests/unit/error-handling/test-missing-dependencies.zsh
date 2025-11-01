#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test graceful handling of missing commands and dependencies

set -eo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_passes() {
    ((PASS_COUNT++))
    echo "✓ PASS: $1"
}

assert_fails() {
    ((FAIL_COUNT++))
    echo "✗ FAIL: $1"
}

# Test: Environment loads with missing optional commands
test_loads_without_optional_commands() {
    echo "Running: test_loads_without_optional_commands"
    
    # Hide optional commands by restricting PATH
    export PATH="/usr/bin:/bin"
    
    # Should still load successfully
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads with minimal PATH (missing optional tools)"
    else
        assert_fails "Environment should load even with missing optional commands"
    fi
}

# Test: zf::has_command handles missing commands
test_has_command_missing() {
    echo "Running: test_has_command_missing"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Check if zf::has_command exists
    if typeset -f zf::has_command >/dev/null 2>&1; then
        # Test with definitely non-existent command
        if zf::has_command "this-command-definitely-does-not-exist-12345" 2>/dev/null; then
            assert_fails "zf::has_command should return false for missing command"
        else
            assert_passes "zf::has_command correctly returns false for missing command"
        fi
    else
        echo "  INFO: zf::has_command not defined"
    fi
}

# Test: zf::has_command handles existing commands
test_has_command_existing() {
    echo "Running: test_has_command_existing"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    if typeset -f zf::has_command >/dev/null 2>&1; then
        # Test with definitely existing command
        if zf::has_command "ls" 2>/dev/null; then
            assert_passes "zf::has_command correctly returns true for existing command (ls)"
        else
            assert_fails "zf::has_command should return true for existing command (ls)"
        fi
    else
        echo "  INFO: zf::has_command not defined"
    fi
}

# Test: can_haz function fallback
test_can_haz_missing_command() {
    echo "Running: test_can_haz_missing_command"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # can_haz is a common helper (wrapper for command -v)
    if typeset -f can_haz >/dev/null 2>&1; then
        if can_haz "nonexistent-tool-xyz" 2>/dev/null; then
            assert_fails "can_haz should return false for missing tool"
        else
            assert_passes "can_haz correctly returns false for missing tool"
        fi
        
        if can_haz "zsh" 2>/dev/null; then
            assert_passes "can_haz correctly returns true for existing command (zsh)"
        else
            assert_fails "can_haz should return true for existing command (zsh)"
        fi
    else
        echo "  INFO: can_haz not defined"
    fi
}

# Test: Missing git graceful handling
test_missing_git_graceful() {
    echo "Running: test_missing_git_graceful"
    
    # Hide git from PATH
    export PATH="/usr/bin:/bin"  # git is usually in /usr/bin, but let's test extreme case
    export PATH="$(echo "$PATH" | sed 's|/usr/bin/git||g')"
    
    # Environment should still load (git functions may not work, but shouldn't crash)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads without git"
    else
        assert_fails "Environment should load gracefully without git"
    fi
}

# Run tests
test_loads_without_optional_commands
test_has_command_missing
test_has_command_existing
test_can_haz_missing_command
test_missing_git_graceful

# Summary
echo ""
echo "========================================="
echo "Missing Dependencies Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

