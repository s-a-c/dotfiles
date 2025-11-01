#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test macOS Homebrew integration and PATH setup

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

# Test: Homebrew PATH detection on macOS
test_homebrew_path_macos() {
    echo "Running: test_homebrew_path_macos"
    
    # Simulate macOS environment
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # Check if Homebrew bin is in PATH
        if [[ ":$PATH:" == *":/opt/homebrew/bin:"* ]] || [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
            assert_passes "Homebrew paths present in macOS PATH"
        else
            assert_fails "Homebrew paths should be in macOS PATH"
        fi
        
        # Check if brew command is available (if Homebrew is installed)
        if command -v brew >/dev/null 2>&1; then
            assert_passes "Homebrew command available"
            
            # Verify brew --prefix matches PATH
            local brew_prefix="$(brew --prefix 2>/dev/null)"
            if [[ -n "$brew_prefix" && ":$PATH:" == *":$brew_prefix/bin:"* ]]; then
                assert_passes "Homebrew prefix matches PATH"
            else
                assert_fails "Homebrew prefix should be in PATH"
            fi
        fi
    else
        echo "  SKIP: Not running on macOS"
    fi
}

# Test: XDG directories fallback
test_xdg_directories() {
    echo "Running: test_xdg_directories"
    
    # Check XDG_CONFIG_HOME is set (should default to ~/.config)
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        assert_passes "XDG_CONFIG_HOME is set: $XDG_CONFIG_HOME"
    else
        echo "  INFO: XDG_CONFIG_HOME not set (will use default ~/.config)"
    fi
    
    # Check XDG_CACHE_HOME is set (should default to ~/.cache)
    if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
        assert_passes "XDG_CACHE_HOME is set: $XDG_CACHE_HOME"
    else
        echo "  INFO: XDG_CACHE_HOME not set (will use default ~/.cache)"
    fi
}

# Test: macOS-specific PATH priorities
test_macos_path_priorities() {
    echo "Running: test_macos_path_priorities"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # System paths should be early in PATH for security
        local first_paths="${PATH%%:*:*:*:*:*}"
        
        if [[ "$first_paths" == *"/opt/homebrew/bin"* ]] || [[ "$first_paths" == *"/usr/local/bin"* ]] || [[ "$first_paths" == *"/usr/bin"* ]]; then
            assert_passes "System paths prioritized in PATH"
        else
            assert_fails "System paths should be prioritized (got: $first_paths)"
        fi
    else
        echo "  SKIP: Not running on macOS"
    fi
}

# Run tests
test_homebrew_path_macos
test_xdg_directories
test_macos_path_priorities

# Summary
echo ""
echo "========================================="
echo "Platform Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

