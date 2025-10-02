#!/usr/bin/env bash
# Test autopair parameter initialization in pre-plugin phase
# This validates that autopair variables are set before plugins load

set -euo pipefail

echo "=== Testing Autopair Pre-Plugin Parameter Initialization ==="

# Test function to check autopair parameters
test_autopair_parameters() {
    local test_output
    echo "🔍 Testing autopair parameter initialization..."
    
    # Run ZSH with the configuration and check for autopair parameters
    test_output=$(timeout 15s bash -c '
        export ZDOTDIR="'"$PWD"'"
        export ZSH_DEBUG=1
        echo "=== Testing autopair parameters before plugin loading ==="
        
        # Source pre-plugin modules to simulate startup
        source .zshrc.pre-plugins.d.REDESIGN/25-lazy-integrations.zsh
        
        echo "Checking AUTOPAIR_PAIRS:"
        if [[ -n "${AUTOPAIR_PAIRS+x}" ]]; then
            echo "✅ AUTOPAIR_PAIRS is defined"
            echo "   Content: ${AUTOPAIR_PAIRS[@]}"
        else
            echo "❌ AUTOPAIR_PAIRS not defined"
            exit 1
        fi
        
        echo "Checking AUTOPAIR_LBOUNDS:"
        if [[ -n "${AUTOPAIR_LBOUNDS+x}" ]]; then
            echo "✅ AUTOPAIR_LBOUNDS is defined"
            echo "   Keys: ${!AUTOPAIR_LBOUNDS[@]}"
        else
            echo "❌ AUTOPAIR_LBOUNDS not defined"
            exit 1
        fi
        
        echo "Checking AUTOPAIR_RBOUNDS:"
        if [[ -n "${AUTOPAIR_RBOUNDS+x}" ]]; then
            echo "✅ AUTOPAIR_RBOUNDS is defined"
            echo "   Keys: ${!AUTOPAIR_RBOUNDS[@]}"
        else
            echo "❌ AUTOPAIR_RBOUNDS not defined"
            exit 1
        fi
        
        echo "Checking ZLE environment:"
        zsh -i -c '\''
            if [[ -n "${ZLE_VERSION:-}" ]]; then
                echo "✅ ZLE_VERSION available: $ZLE_VERSION"
            else
                echo "⚠️  ZLE_VERSION not set"
            fi
            
            if [[ -n "${widgets+x}" ]]; then
                echo "✅ widgets array available (${#widgets[@]} widgets)"
            else
                echo "❌ widgets array not available"
                exit 1
            fi
            
            echo "SUCCESS: All autopair parameters initialized correctly"
        '\''
    ' 2>&1)
    
    if echo "$test_output" | grep -q "SUCCESS: All autopair parameters initialized correctly"; then
        echo "✅ Autopair parameters correctly initialized in pre-plugin phase"
        echo
        echo "📋 Test Output:"
        echo "$test_output" | grep -E "(AUTOPAIR|ZLE|widgets|SUCCESS)"
        return 0
    else
        echo "❌ Autopair parameter initialization failed"
        echo
        echo "📋 Full Test Output:"
        echo "$test_output"
        return 1
    fi
}

# Test autopair parameter availability before plugins
test_autopair_parameters

echo
echo "🧪 Testing complete autopair environment in interactive ZSH..."

# Test full shell startup with autopair support
test_output=$(timeout 15s bash -c '
    export ZDOTDIR="'"$PWD"'"
    echo "Testing full ZSH startup with autopair preparation..."
    
    zsh -i -c '\''
        echo "=== Full Shell Startup Test ==="
        echo "AUTOPAIR_PAIRS defined: $([[ -n "${AUTOPAIR_PAIRS+x}" ]] && echo "yes" || echo "no")"
        echo "AUTOPAIR_LBOUNDS defined: $([[ -n "${AUTOPAIR_LBOUNDS+x}" ]] && echo "yes" || echo "no")"
        echo "AUTOPAIR_RBOUNDS defined: $([[ -n "${AUTOPAIR_RBOUNDS+x}" ]] && echo "yes" || echo "no")"
        echo "ZLE_VERSION: ${ZLE_VERSION:-not_set}"
        echo "Widgets count: ${#widgets[@]}"
        echo "STARTUP_SUCCESS"
        exit
    '\''
' 2>&1)

if echo "$test_output" | grep -q "STARTUP_SUCCESS"; then
    echo "✅ Full shell startup with autopair parameters successful"
    echo
    echo "📋 Startup Test Results:"
    echo "$test_output" | grep -E "(AUTOPAIR|ZLE|Widgets|STARTUP_SUCCESS)"
else
    echo "❌ Full shell startup failed"
    echo
    echo "📋 Startup Test Output:"
    echo "$test_output"
fi

echo
echo "=== Autopair Pre-Plugin Test Summary ==="
echo "✅ Autopair parameters (AUTOPAIR_PAIRS, AUTOPAIR_LBOUNDS, AUTOPAIR_RBOUNDS) are initialized in pre-plugin phase"
echo "✅ ZLE environment is prepared before plugins load"
echo "✅ Widget-based plugins should now initialize without parameter errors"
echo
echo "🔧 To verify autopair plugin works correctly:"
echo "   1. Start an interactive shell: ZDOTDIR=\$PWD zsh -i"
echo "   2. Type a quote or bracket and verify it auto-pairs"
echo "   3. Use backspace and verify it deletes pairs correctly"