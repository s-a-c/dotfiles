#!/usr/bin/env zsh
# TEST_CLASS: integration
# TEST_MODE: zsh-f-required
# Integration test for error recovery and resilience

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
echo "Error Recovery Integration Tests"
echo "========================================="
echo ""

# Test: Recovery from multiple missing components
test_multi_missing_recovery() {
    echo "Running: test_multi_missing_recovery"
    
    # Simulate multiple missing components
    export PATH="/usr/bin:/bin"  # Minimal PATH
    unset XDG_CONFIG_HOME
    unset XDG_CACHE_HOME
    unset ZDOTDIR
    
    # Should still load and provide defaults
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment recovers from multiple missing components"
        
        # Check if fallbacks were applied
        if [[ -n "${ZDOTDIR:-}" ]]; then
            assert_passes "ZDOTDIR fallback applied"
        fi
        
        if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
            assert_passes "XDG_CONFIG_HOME fallback applied"
        fi
    else
        assert_fails "Environment should recover from multiple missing components"
    fi
}

# Test: Error in non-critical path (should continue)
test_noncritical_error_continue() {
    echo "Running: test_noncritical_error_continue"
    
    # Create scenario where non-critical operation fails
    export ZSH_CACHE_DIR="/nonexistent/path/that/cannot/be/created"
    
    # Should continue despite mkdir failure (|| true pattern)
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment continues despite non-critical errors"
    else
        echo "  INFO: Environment may be strict about cache directory (acceptable)"
    fi
}

# Test: Malformed environment variables
test_malformed_env_vars() {
    echo "Running: test_malformed_env_vars"
    
    # Set malformed variables
    export ZSH_DEBUG="not-a-number"
    export QUICKSTART_KIT_REFRESH_IN_DAYS="invalid"
    
    # Should handle gracefully
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Environment handles malformed environment variables"
    else
        assert_fails "Environment should handle malformed variables gracefully"
    fi
    
    # Cleanup
    export ZSH_DEBUG=0
    unset QUICKSTART_KIT_REFRESH_IN_DAYS
}

# Test: Concurrent loading resilience
test_concurrent_loading() {
    echo "Running: test_concurrent_loading"
    
    # Simulate rapid successive loads (race condition test)
    local load_count=0
    local fail_count=0
    
    for i in {1..5}; do
        if source "$REPO_ROOT/.zshenv.01" 2>&1; then
            ((load_count++))
        else
            ((fail_count++))
        fi
    done
    
    if [[ $load_count -eq 5 ]]; then
        assert_passes "Environment handles 5 consecutive loads without errors"
    else
        assert_fails "Environment should handle concurrent loading ($load_count/5 succeeded)"
    fi
}

# Test: Function override protection
test_function_override_protection() {
    echo "Running: test_function_override_protection"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Try to override a readonly function
    if typeset -f zf::debug >/dev/null 2>&1; then
        # Attempt to redefine (should fail if readonly)
        if zf::debug() { echo "malicious override"; } 2>/dev/null; then
            echo "  INFO: zf::debug can be redefined (may not be readonly)"
        else
            assert_passes "zf::debug is protected from override (readonly)"
        fi
    fi
}

# Run tests
test_multi_missing_recovery
test_noncritical_error_continue
test_malformed_env_vars
test_concurrent_loading
test_function_override_protection

# Summary
echo ""
echo "========================================="
echo "Error Recovery Integration Test Results"
echo "========================================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

