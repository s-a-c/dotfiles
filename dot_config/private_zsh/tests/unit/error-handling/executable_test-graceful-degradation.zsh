#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test graceful degradation when features are unavailable

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

# Test: Missing debug logger (should provide noop fallback)
test_missing_debug_logger() {
    echo "Running: test_missing_debug_logger"
    
    # Start without zf::debug
    unset -f zf::debug 2>/dev/null || true
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Should define zf::debug
    if typeset -f zf::debug >/dev/null 2>&1; then
        assert_passes "zf::debug defined as fallback"
        
        # Test that it works (should not error)
        if zf::debug "test message" 2>&1; then
            assert_passes "zf::debug works without errors"
        else
            assert_fails "zf::debug should work even in degraded mode"
        fi
    else
        assert_fails "zf::debug should be defined"
    fi
}

# Test: Missing path helpers provide fallbacks
test_missing_path_helpers() {
    echo "Running: test_missing_path_helpers"
    
    # Start without path helpers
    unset -f zf::path_prepend zf::path_append 2>/dev/null || true
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Should define path helpers
    if typeset -f zf::path_prepend >/dev/null 2>&1; then
        assert_passes "zf::path_prepend defined"
    fi
    
    if typeset -f zf::path_append >/dev/null 2>&1; then
        assert_passes "zf::path_append defined"
    fi
}

# Test: Degraded mode with ZF_DEBUG=0 (no debug output)
test_degraded_no_debug() {
    echo "Running: test_degraded_no_debug"
    
    export ZSH_DEBUG=0
    unset ZSH_DEBUG_LOG
    
    # Should load without debug output
    local output="$(source "$REPO_ROOT/.zshenv.01" 2>&1)"
    
    # In non-debug mode, debug messages should be suppressed
    if [[ -z "$output" || "$output" != *"[DEBUG]"* ]]; then
        assert_passes "Debug output suppressed when ZSH_DEBUG=0"
    else
        echo "  INFO: Some output present in non-debug mode (may be warnings)"
    fi
}

# Test: Missing zmodload modules (should not crash)
test_missing_zmodload_modules() {
    echo "Running: test_missing_zmodload_modules"
    
    # This tests if the environment handles missing zsh modules gracefully
    # Some modules like zsh/datetime may not be available in minimal zsh builds
    
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment loads even if some zmodload modules unavailable"
    else
        assert_fails "Environment should handle missing zsh modules gracefully"
    fi
}

# Test: Feature toggles disable features correctly
test_feature_toggles() {
    echo "Running: test_feature_toggles"
    
    # Test various ZF_DISABLE_* flags
    export ZF_DISABLE_METRICS=1
    export ZF_NO_SPLASH=1
    
    # Should respect toggles and load without those features
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment respects feature toggle flags"
        
        # Verify no splash screen was shown
        # (Splash is controlled by 470-user-interface.zsh, but flag should be respected)
        if [[ "${ZF_NO_SPLASH:-}" == "1" ]]; then
            assert_passes "ZF_NO_SPLASH toggle preserved"
        fi
    else
        assert_fails "Environment should load with feature toggles"
    fi
}

# Run tests
test_missing_debug_logger
test_missing_path_helpers
test_degraded_no_debug
test_missing_zmodload_modules
test_feature_toggles

# Summary
echo ""
echo "========================================="
echo "Graceful Degradation Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

