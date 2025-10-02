#!/usr/bin/env bash

# ZSH Test Harness - Following repository rules
# This script tests ZSH configuration using bash harness to avoid crashing tabs

set -e

echo "=== ZSH Configuration Test Harness ==="
echo "Testing from: $(pwd)"
echo "Current shell: $0"
echo

# Test 1: Basic ZSH startup validation
test_zsh_startup() {
    echo "🧪 Test 1: ZSH Startup Validation"
    local test_output
    test_output=$(timeout 10s bash -c '
        export ZDOTDIR="$PWD"
        echo "Testing ZSH startup..."
        zsh -i -c "echo PROMPT_TEST_SUCCESS; exit"
    ' 2>&1)
    
    if echo "$test_output" | grep -q "PROMPT_TEST_SUCCESS"; then
        echo "✅ ZSH startup successful"
        return 0
    else
        echo "❌ ZSH startup failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 2: Environment validation
test_zsh_environment() {
    echo "🧪 Test 2: Environment Validation"
    ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "=== Environment Test ==="
        echo "ZDOTDIR: $ZDOTDIR"
        echo "ZSH_ENABLE_PREPLUGIN_REDESIGN: $ZSH_ENABLE_PREPLUGIN_REDESIGN"
        echo "ZSH_ENABLE_POSTPLUGIN_REDESIGN: $ZSH_ENABLE_POSTPLUGIN_REDESIGN"
        echo "USER_INTERFACE_VERSION: $USER_INTERFACE_VERSION"
        echo "Starship available: $(command -v starship >/dev/null && echo yes || echo no)"
        exit
    '
}

# Test 3: Starship initialization check
test_starship_init() {
    echo "🧪 Test 3: Starship Initialization"
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 15s zsh -i -c '
        if [[ -n "$STARSHIP_SHELL" ]]; then
            echo "STARSHIP_INITIALIZED"
        else
            echo "STARSHIP_NOT_INITIALIZED"
        fi
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "STARSHIP_INITIALIZED"; then
        echo "✅ Starship prompt initialized"
        return 0
    else
        echo "⚠️  Starship not initialized or not detected"
        echo "Output: $test_output"
        return 1
    fi
}

# Main test execution
main() {
    echo "Starting ZSH configuration tests using bash harness..."
    echo "Repository: $(pwd)"
    echo
    
    # Run tests
    test_zsh_startup || echo "❌ Startup test failed"
    echo
    
    test_zsh_environment || echo "❌ Environment test failed"
    echo
    
    test_starship_init || echo "❌ Starship test failed"
    echo
    
    echo "=== Test Harness Complete ==="
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi