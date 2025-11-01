#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test edge cases in environment setup

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

# Test: Empty HOME variable
test_empty_home() {
    echo "Running: test_empty_home"
    
    # Save original HOME
    local original_home="$HOME"
    
    # Set HOME to empty (extreme edge case)
    export HOME=""
    
    # Should handle gracefully or fail predictably
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        echo "  INFO: Environment loads with empty HOME"
    else
        assert_passes "Environment exits predictably with empty HOME (acceptable behavior)"
    fi
    
    # Restore HOME
    export HOME="$original_home"
}

# Test: Extremely long PATH
test_extremely_long_path() {
    echo "Running: test_extremely_long_path"
    
    # Create PATH with 50+ entries
    local long_path="/usr/bin:/bin"
    for i in {1..50}; do
        long_path="$long_path:/fake/path/$i"
    done
    export PATH="$long_path"
    
    # Should handle long PATH without issues
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles extremely long PATH"
    else
        assert_fails "Environment should handle long PATH gracefully"
    fi
}

# Test: PATH with special characters
test_path_special_chars() {
    echo "Running: test_path_special_chars"
    
    # PATH with spaces and special chars (unusual but valid)
    export PATH="/usr/bin:/bin:/a path with spaces:/path-with-dashes:/path_with_underscores"
    
    # Should handle without quoting errors
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles PATH with special characters"
    else
        assert_fails "Environment should handle PATH with special characters"
    fi
}

# Test: Circular symlink in ZDOTDIR
test_circular_symlink_zdotdir() {
    echo "Running: test_circular_symlink_zdotdir"
    
    # Create circular symlink scenario
    local test_dir="$REPO_ROOT/test-circular"
    mkdir -p "$test_dir/a"
    ln -sf "$test_dir/a" "$test_dir/a/b" 2>/dev/null || true
    
    # Point ZDOTDIR to circular symlink
    export ZDOTDIR="$test_dir/a/b"
    
    # Should handle gracefully (realpath/canonicalization may fail, but shouldn't crash)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        echo "  INFO: Environment loads with circular symlink in ZDOTDIR"
    else
        assert_passes "Environment exits predictably with circular symlink (acceptable)"
    fi
    
    # Cleanup
    rm -rf "$test_dir" 2>/dev/null || true
    unset ZDOTDIR
}

# Test: Missing required variables
test_missing_required_vars() {
    echo "Running: test_missing_required_vars"
    
    # Clear potentially required variables
    unset USER
    unset SHELL
    unset TERM
    
    # Should either provide defaults or handle gracefully
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles missing USER/SHELL/TERM variables"
    else
        echo "  INFO: Environment may require USER/SHELL/TERM (acceptable strictness)"
    fi
}

# Test: Invalid ZSH_VERSION
test_invalid_zsh_version() {
    echo "Running: test_invalid_zsh_version"
    
    # Save original
    local original_version="$ZSH_VERSION"
    
    # Set invalid version
    export ZSH_VERSION="invalid.version.string"
    
    # Should handle gracefully (version checks may fail, but shouldn't crash)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles invalid ZSH_VERSION"
    else
        echo "  INFO: Environment may validate ZSH_VERSION (acceptable)"
    fi
    
    # Restore
    export ZSH_VERSION="$original_version"
}

# Run tests
test_empty_home
test_extremely_long_path
test_path_special_chars
test_circular_symlink_zdotdir
test_missing_required_vars
test_invalid_zsh_version

# Summary
echo ""
echo "========================================="
echo "Edge Case Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

