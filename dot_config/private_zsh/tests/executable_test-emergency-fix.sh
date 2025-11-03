#!/usr/bin/env bash
# test-emergency-fix.sh - Bash test harness for emergency ZLE widget fix

set -euo pipefail

echo "=== Emergency ZLE Widget Fix Test Harness ==="
echo "Testing ZSH startup with emergency fix applied..."
echo ""

# Clear caches first
echo "Clearing ZSH caches..."
tools/clear-zsh-cache.zsh
echo ""

# Test 1: Basic startup validation
echo "Test 1: Basic ZSH startup test"
test_zsh_startup() {
    local test_output
    test_output=$(timeout 15s bash -c '
        export ZDOTDIR="'"$PWD"'"
        echo "Starting ZSH with emergency fix..."
        zsh -i -c "echo STARTUP_SUCCESS; exit" 2>&1
    ')
    
    if echo "$test_output" | grep -q "STARTUP_SUCCESS"; then
        echo "✅ ZSH startup successful"
        
        # Check for reduced errors
        local error_count
        error_count=$(echo "$test_output" | grep -c "zle: function definition file not found" || true)
        echo "   Error count: $error_count ZLE widget errors"
        
        if [ "$error_count" -eq 0 ]; then
            echo "✅ PERFECT: Zero ZLE widget errors detected!"
        elif [ "$error_count" -lt 10 ]; then
            echo "✅ Significantly reduced error count (< 10)"
        else
            echo "⚠️  Still many errors ($error_count)"
        fi
        
        return 0
    else
        echo "❌ ZSH startup failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 2: Environment variable validation
echo "Test 2: Emergency fix environment variables"
test_emergency_env() {
    ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "=== Emergency Fix Environment ==="
        echo "ZSH_AUTOSUGGEST_DISABLE: $ZSH_AUTOSUGGEST_DISABLE"
        echo "DISABLE_AUTO_SUGGESTIONS: $DISABLE_AUTO_SUGGESTIONS"  
        echo "GITSTATUS_DISABLE: $GITSTATUS_DISABLE"
        
        # Test if emergency functions exist
        if declare -f _zsh_autosuggest_bind_widget >/dev/null; then
            echo "✅ Emergency no-op function _zsh_autosuggest_bind_widget exists"
        else
            echo "❌ Emergency no-op function missing"
        fi
        
        exit
    '
}

# Test 3: Starship initialization with fix
echo ""
echo "Test 3: Starship initialization with emergency fix"
test_starship_with_fix() {
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 20s zsh -i -c '
        echo "Testing Starship with emergency fix..."
        if [[ -n "$STARSHIP_SHELL" ]]; then
            echo "STARSHIP_INITIALIZED"
        else
            echo "STARSHIP_NOT_INITIALIZED"
        fi
        
        # Test prompt display
        echo "Prompt test complete"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "STARSHIP_INITIALIZED"; then
        echo "✅ Starship prompt initialized with emergency fix"
    else
        echo "⚠️  Starship status unclear with emergency fix"
    fi
    
    # Check for parameter errors
    if echo "$test_output" | grep -q "parameter.*not set"; then
        echo "⚠️  Still some parameter errors present"
    else
        echo "✅ No parameter errors detected"
    fi
    
    echo "Sample output:"
    echo "$test_output" | head -10
}

# Test 4: Plugin status validation
echo ""  
echo "Test 4: Plugin disabling validation"
test_plugin_status() {
    ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "=== Plugin Status Check ==="
        
        # Check if zsh-autosuggestions is actually disabled
        if [[ -n "$ZSH_AUTOSUGGEST_DISABLE" ]]; then
            echo "✅ zsh-autosuggestions disabled via ZSH_AUTOSUGGEST_DISABLE"
        fi
        
        if [[ -n "$DISABLE_AUTO_SUGGESTIONS" ]]; then
            echo "✅ zsh-autosuggestions disabled via DISABLE_AUTO_SUGGESTIONS"  
        fi
        
        if [[ -n "$GITSTATUS_DISABLE" ]]; then
            echo "✅ gitstatus disabled via GITSTATUS_DISABLE"
        fi
        
        # Test if zgenom shows plugins as disabled
        echo "Zgenom plugin status:"
        zgenom list 2>/dev/null | head -5 || echo "zgenom not accessible"
        
        exit
    '
}

# Run all tests
echo ""
echo "Running test suite..."
echo "=================================="

test_zsh_startup
echo ""
test_emergency_env  
echo ""
test_starship_with_fix
echo ""
test_plugin_status

echo ""
echo "=== Test Summary ==="
echo "Emergency ZLE widget fix has been applied to:"
echo "  - /Users/s-a-c/.config/zsh/.zshrc.d/90-zqs-quickstart-compat.zsh"
echo ""
echo "Next steps:"
echo "1. If errors are significantly reduced, the emergency fix is working"
echo "2. For permanent solution, investigate plugin loading order in zgenom"
echo "3. Consider re-enabling plugins one by one after fixing ZLE initialization"
echo ""
echo "To test interactively: ZDOTDIR=$PWD zsh -i"
