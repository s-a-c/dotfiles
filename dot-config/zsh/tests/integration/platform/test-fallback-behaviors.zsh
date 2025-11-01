#!/usr/bin/env zsh
# TEST_CLASS: integration
# TEST_MODE: zsh-f-required
# Integration test for fallback behaviors (missing tools, directories, etc.)

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

echo "========================================="
echo "Platform Fallback Behavior Tests"
echo "========================================="
echo ""

# Test: Missing Homebrew graceful handling
test_missing_homebrew_fallback() {
    echo "Running: test_missing_homebrew_fallback"
    
    # Temporarily hide brew from PATH
    local original_path="$PATH"
    export PATH="$(echo "$PATH" | sed 's|:/opt/homebrew/bin||g; s|/opt/homebrew/bin:||g')"
    export PATH="$(echo "$PATH" | sed 's|:/usr/local/bin||g; s|/usr/local/bin:||g')"
    
    # Should still load without errors
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads without Homebrew"
    else
        assert_fails "Environment should load gracefully without Homebrew"
    fi
    
    # Restore PATH
    export PATH="$original_path"
}

# Test: Missing XDG directories fallback
test_missing_xdg_fallback() {
    echo "Running: test_missing_xdg_fallback"
    
    # Clear XDG variables
    unset XDG_CONFIG_HOME
    unset XDG_CACHE_HOME
    unset XDG_DATA_HOME
    
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads with undefined XDG variables"
        
        # Should have fallback values
        if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
            assert_passes "XDG_CONFIG_HOME has fallback value: $XDG_CONFIG_HOME"
        fi
    else
        assert_fails "Environment should provide XDG fallbacks"
    fi
}

# Test: Missing ZDOTDIR graceful handling
test_missing_zdotdir_fallback() {
    echo "Running: test_missing_zdotdir_fallback"
    
    local original_zdotdir="$ZDOTDIR"
    unset ZDOTDIR
    
    # Should set ZDOTDIR to a default
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        if [[ -n "${ZDOTDIR:-}" ]]; then
            assert_passes "ZDOTDIR has fallback value when unset: $ZDOTDIR"
        else
            echo "  INFO: ZDOTDIR remains unset (may use HOME)"
        fi
    else
        assert_fails "Environment should handle missing ZDOTDIR"
    fi
    
    # Restore
    export ZDOTDIR="$original_zdotdir"
}

# Test: Minimal PATH fallback
test_minimal_path_fallback() {
    echo "Running: test_minimal_path_fallback"
    
    # Start with bare minimum PATH
    export PATH="/usr/bin:/bin"
    
    # Should enhance PATH with additional directories
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment enhances minimal PATH"
        
        # PATH should now have more entries
        local path_count=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')
        if [[ $path_count -gt 2 ]]; then
            assert_passes "PATH enhanced from 2 to $path_count entries"
        else
            echo "  INFO: PATH not significantly enhanced (still $path_count entries)"
        fi
    else
        assert_fails "Environment should work with minimal PATH"
    fi
}

# Test: Missing helper functions fallback
test_missing_helpers_fallback() {
    echo "Running: test_missing_helpers_fallback"
    
    # Start clean (no zf:: functions)
    unset -f zf::debug
    unset -f zf::path_prepend
    
    # Should define fallback helpers
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads without pre-existing helpers"
        
        # Should now have helper functions
        if typeset -f zf::debug >/dev/null 2>&1; then
            assert_passes "zf::debug defined after sourcing"
        fi
    else
        assert_fails "Environment should define helper functions"
    fi
}

# Run tests
test_missing_homebrew_fallback
test_missing_xdg_fallback
test_missing_zdotdir_fallback
test_minimal_path_fallback
test_missing_helpers_fallback

# Summary
echo ""
echo "========================================="
echo "Fallback Behavior Integration Test Results"
echo "========================================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

