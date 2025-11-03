#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test XDG Base Directory specification compliance

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

# Test: XDG_CONFIG_HOME default
test_xdg_config_home_default() {
    echo "Running: test_xdg_config_home_default"
    
    unset XDG_CONFIG_HOME
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Should default to ~/.config
    if [[ "${XDG_CONFIG_HOME:-}" == "${HOME}/.config" ]]; then
        assert_passes "XDG_CONFIG_HOME defaults to ~/.config"
    else
        assert_fails "XDG_CONFIG_HOME should default to ~/.config (got: ${XDG_CONFIG_HOME:-<empty>})"
    fi
}

# Test: XDG_CACHE_HOME default
test_xdg_cache_home_default() {
    echo "Running: test_xdg_cache_home_default"
    
    unset XDG_CACHE_HOME
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Should default to ~/.cache
    if [[ "${XDG_CACHE_HOME:-}" == "${HOME}/.cache" ]]; then
        assert_passes "XDG_CACHE_HOME defaults to ~/.cache"
    else
        assert_fails "XDG_CACHE_HOME should default to ~/.cache (got: ${XDG_CACHE_HOME:-<empty>})"
    fi
}

# Test: XDG_DATA_HOME default
test_xdg_data_home_default() {
    echo "Running: test_xdg_data_home_default"
    
    unset XDG_DATA_HOME
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Should default to ~/.local/share
    if [[ "${XDG_DATA_HOME:-}" == "${HOME}/.local/share" ]]; then
        assert_passes "XDG_DATA_HOME defaults to ~/.local/share"
    else
        assert_fails "XDG_DATA_HOME should default to ~/.local/share (got: ${XDG_DATA_HOME:-<empty>})"
    fi
}

# Test: XDG directories are created
test_xdg_directories_created() {
    echo "Running: test_xdg_directories_created"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Check if directories exist (or can be created)
    local dirs=("$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            assert_passes "Directory exists: $dir"
        else
            echo "  INFO: Directory not created yet: $dir (may be lazy)"
        fi
    done
}

# Test: ZSH_CACHE_DIR uses XDG_CACHE_HOME
test_zsh_cache_uses_xdg() {
    echo "Running: test_zsh_cache_uses_xdg"
    
    export XDG_CACHE_HOME="/tmp/test-xdg-cache"
    unset ZSH_CACHE_DIR
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # ZSH_CACHE_DIR should be under XDG_CACHE_HOME
    if [[ "${ZSH_CACHE_DIR:-}" == "$XDG_CACHE_HOME"/zsh* ]] || [[ "${ZSH_CACHE_DIR:-}" == "$XDG_CACHE_HOME"* ]]; then
        assert_passes "ZSH_CACHE_DIR uses XDG_CACHE_HOME"
    else
        assert_fails "ZSH_CACHE_DIR should use XDG_CACHE_HOME (got: ${ZSH_CACHE_DIR:-<empty>})"
    fi
}

# Run tests
test_xdg_config_home_default
test_xdg_cache_home_default
test_xdg_data_home_default
test_xdg_directories_created
test_zsh_cache_uses_xdg

# Summary
echo ""
echo "========================================="
echo "XDG Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

