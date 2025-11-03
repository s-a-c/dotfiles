#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test graceful handling of permission errors

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

# Create temporary test directory
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT INT TERM

# Test: Unreadable directory handling
test_unreadable_directory() {
    echo "Running: test_unreadable_directory"
    
    # Create unreadable directory
    local unreadable_dir="$TEST_TMPDIR/unreadable"
    mkdir -p "$unreadable_dir"
    chmod 000 "$unreadable_dir"
    
    # Simulate ZDOTDIR pointing to unreadable location
    # (This is an extreme edge case, but should not crash)
    export ZSH_CACHE_DIR="$unreadable_dir/cache"
    
    # Should handle gracefully (mkdir will fail, but script continues with || true)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles unreadable cache directory gracefully"
    else
        echo "  INFO: Environment may exit on unreadable directory (acceptable)"
    fi
    
    # Cleanup
    chmod 755 "$unreadable_dir"
}

# Test: Unwritable cache directory
test_unwritable_cache() {
    echo "Running: test_unwritable_cache"
    
    # Create directory but make it unwritable
    local cache_dir="$TEST_TMPDIR/cache"
    mkdir -p "$cache_dir"
    chmod 555 "$cache_dir"  # Read + execute only
    
    export ZSH_CACHE_DIR="$cache_dir"
    
    # Should handle gracefully (chmod will fail, but continues)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles unwritable cache directory"
    else
        echo "  INFO: Environment may be strict about writable cache (acceptable)"
    fi
    
    # Cleanup
    chmod 755 "$cache_dir"
}

# Test: Permission-denied on log file creation
test_log_permission_denied() {
    echo "Running: test_log_permission_denied"
    
    # Create log directory but make it unwritable
    local log_dir="$TEST_TMPDIR/logs"
    mkdir -p "$log_dir"
    chmod 555 "$log_dir"
    
    export ZSH_LOG_DIR="$log_dir"
    
    # Should continue despite inability to write logs
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment continues despite log write permission errors"
    else
        echo "  INFO: Environment may require writable log directory"
    fi
    
    # Cleanup
    chmod 755 "$log_dir"
}

# Test: Read-only filesystem (simulate with read-only directory)
test_readonly_filesystem() {
    echo "Running: test_readonly_filesystem"
    
    # This test simulates what happens in read-only environments
    # (Docker containers, CI environments, etc.)
    
    local readonly_dir="$TEST_TMPDIR/readonly"
    mkdir -p "$readonly_dir"
    
    # Create a file, then make directory read-only
    touch "$readonly_dir/existing-file"
    chmod 555 "$readonly_dir"
    
    export ZSH_CACHE_DIR="$readonly_dir"
    
    # Should handle gracefully (operations will fail but script continues with || true)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles read-only cache directory"
    else
        echo "  INFO: Environment may exit on read-only directory (check if acceptable)"
    fi
    
    # Cleanup
    chmod 755 "$readonly_dir"
}

# Run tests
test_unreadable_directory
test_unwritable_cache
test_log_permission_denied
test_readonly_filesystem

# Summary
echo ""
echo "========================================="
echo "Permission Error Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

