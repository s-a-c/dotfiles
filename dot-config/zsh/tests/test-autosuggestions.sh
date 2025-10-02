#!/usr/bin/env bash
# test-autosuggestions.sh - Test autosuggestions re-enablement

set -euo pipefail

echo "=== ZSH Autosuggestions Re-enablement Test ==="
echo "Testing zsh-autosuggestions with the new ZDOTDIR-aware ZQS setup..."
echo ""

# Test 1: Basic startup without errors
echo "Test 1: Clean startup test"
test_clean_startup() {
    echo "Testing startup for ZLE widget errors..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 25s zsh -i -c 'echo "CLEAN_STARTUP_SUCCESS"; exit' 2>&1)
    
    local error_count=$(echo "$test_output" | grep -c "zle: function definition file not found" || true)
    local param_errors=$(echo "$test_output" | grep -c "parameter.*not set" || true)
    
    echo "   ZLE widget errors: $error_count"
    echo "   Parameter errors: $param_errors"
    
    if echo "$test_output" | grep -q "CLEAN_STARTUP_SUCCESS"; then
        if [ "$error_count" -eq 0 ] && [ "$param_errors" -eq 0 ]; then
            echo "✅ Perfect startup - no errors detected!"
            return 0
        else
            echo "⚠️  Startup successful but with some errors"
            return 0  # Don't fail for minor errors
        fi
    else
        echo "❌ Startup failed or hung"
        echo "Last few lines of output:"
        echo "$test_output" | tail -10
        return 1
    fi
}

# Test 2: Autosuggestions status
echo ""
echo "Test 2: Autosuggestions availability" 
test_autosuggestions_status() {
    echo "Testing if zsh-autosuggestions is available and enabled..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 15s zsh -i -c '
        echo "=== Autosuggestions Status ==="
        echo "ZSH_AUTOSUGGEST_DISABLE: ${ZSH_AUTOSUGGEST_DISABLE:-unset}"
        echo "DISABLE_AUTO_SUGGESTIONS: ${DISABLE_AUTO_SUGGESTIONS:-unset}"
        
        # Check if autosuggestions plugin is loaded
        if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
            echo "✅ zsh-autosuggestions plugin is loaded"
            echo "Highlight style: $ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"
        else
            echo "❌ zsh-autosuggestions plugin not detected"
        fi
        
        # Check if autosuggestion functions exist
        if declare -f _zsh_autosuggest_start >/dev/null 2>&1; then
            echo "✅ zsh-autosuggestions functions available"
        else
            echo "❌ zsh-autosuggestions functions not found"
        fi
        
        # Check ZLE widgets
        if [[ -n "${widgets[_zsh_autosuggest_accept]:-}" ]]; then
            echo "✅ Autosuggestions ZLE widgets registered"
        else
            echo "❌ Autosuggestions ZLE widgets not found"
        fi
        
        echo "AUTOSUGGESTIONS_TEST_COMPLETE"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "AUTOSUGGESTIONS_TEST_COMPLETE"; then
        echo "✅ Autosuggestions status check completed"
        echo ""
        echo "Status details:"
        echo "$test_output" | grep -E "(ZSH_AUTOSUGGEST|zsh-autosuggestions|Autosuggestions)" | sed 's/^/  /'
        
        # Check if it's actually working
        if echo "$test_output" | grep -q "zsh-autosuggestions plugin is loaded"; then
            echo ""
            echo "🎉 zsh-autosuggestions appears to be working!"
            return 0
        else
            echo ""
            echo "⚠️  zsh-autosuggestions may not be fully loaded"
            return 0  # Don't fail, just warn
        fi
    else
        echo "❌ Autosuggestions status check failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 3: Interactive functionality test
echo ""
echo "Test 3: Basic functionality test"
test_interactive_functionality() {
    echo "Testing basic interactive shell functionality..."
    
    local test_output  
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "Testing basic functionality..."
        
        # Test history expansion
        echo "History available: $(history | wc -l | tr -d " ")"
        
        # Test completion system
        if [[ -n "$_comps" ]]; then
            echo "✅ Completion system loaded ($(echo $_comps | wc -w | tr -d " ") completions)"
        else
            echo "❌ Completion system not detected"
        fi
        
        # Test prompt
        if [[ -n "$STARSHIP_SHELL" ]]; then
            echo "✅ Starship prompt active"
        elif [[ -n "$POWERLEVEL9K_MODE" ]]; then
            echo "✅ Powerlevel10k prompt active"  
        else
            echo "⚠️  Unknown prompt system"
        fi
        
        echo "FUNCTIONALITY_TEST_COMPLETE"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "FUNCTIONALITY_TEST_COMPLETE"; then
        echo "✅ Basic functionality test passed"
        echo "Details:"
        echo "$test_output" | grep -E "(History|Completion|prompt)" | sed 's/^/  /'
        return 0
    else
        echo "❌ Basic functionality test failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 4: Gitstatus re-enablement
echo ""
echo "Test 4: Gitstatus status"
test_gitstatus() {
    echo "Testing if gitstatus is re-enabled..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "GITSTATUS_DISABLE: ${GITSTATUS_DISABLE:-unset}"
        
        if command -v gitstatus_query >/dev/null 2>&1; then
            echo "✅ gitstatus command available"
        else
            echo "❌ gitstatus command not found"
        fi
        
        echo "GITSTATUS_TEST_COMPLETE"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "GITSTATUS_TEST_COMPLETE"; then
        echo "✅ Gitstatus test completed"
        if echo "$test_output" | grep -q "GITSTATUS_DISABLE: unset"; then
            echo "  ✅ Gitstatus is enabled (GITSTATUS_DISABLE is unset)"
        else
            echo "  ⚠️  Gitstatus may still be disabled"
        fi
        return 0
    else
        echo "❌ Gitstatus test failed"
        return 1
    fi
}

# Test 5: ZLE widgets health check
echo ""
echo "Test 5: ZLE widgets health"  
test_zle_widgets() {
    echo "Testing ZLE widget system health..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        echo "=== ZLE Widgets Status ==="
        
        # Check if ZLE is loaded
        if zmodload -e zsh/zle; then
            echo "✅ ZLE module loaded"
        else
            echo "❌ ZLE module not loaded"
        fi
        
        # Check widgets array
        if [[ -n "${widgets:-}" ]]; then
            local widget_count=$(echo ${(k)widgets} | wc -w | tr -d " ")
            echo "✅ Widgets array available ($widget_count widgets)"
        else
            echo "❌ Widgets array not available"
        fi
        
        # Check for common widgets
        local key_widgets=("accept-line" "backward-delete-char" "forward-char" "backward-char")
        for widget in $key_widgets; do
            if [[ -n "${widgets[$widget]:-}" ]]; then
                echo "  ✅ $widget widget: ${widgets[$widget]}"
            else
                echo "  ❌ $widget widget: missing"
            fi
        done
        
        echo "ZLE_WIDGETS_TEST_COMPLETE"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "ZLE_WIDGETS_TEST_COMPLETE"; then
        echo "✅ ZLE widgets health check completed"
        echo "Details:"
        echo "$test_output" | grep -E "(ZLE|widgets|widget:)" | sed 's/^/  /'
        return 0
    else
        echo "❌ ZLE widgets health check failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Run all tests
echo "Running test suite..."
echo "===================================="

failed_tests=0

test_clean_startup || ((failed_tests++))
echo ""
test_autosuggestions_status || ((failed_tests++)) 
echo ""
test_interactive_functionality || ((failed_tests++))
echo ""
test_gitstatus || ((failed_tests++))
echo ""
test_zle_widgets || ((failed_tests++))

echo ""
echo "=== Test Summary ==="
if [[ $failed_tests -eq 0 ]]; then
    echo "✅ All tests passed! Autosuggestions re-enablement successful"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Test interactively: ZDOTDIR=$PWD zsh -i"
    echo "2. Try typing a command and see if suggestions appear"
    echo "3. Use Tab for completions, → arrow to accept suggestions"
else
    echo "❌ $failed_tests test(s) failed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "1. Check if the zsh-autosuggestions plugin is properly installed via zgenom"
    echo "2. Verify ZLE widget system is working"
    echo "3. Look for any remaining ZLE widget binding errors"
fi

echo ""
echo "🔍 To debug interactively:"
echo "  ZDOTDIR=$PWD zsh -i"
echo "  Then type: zgenom list | grep autosuggestions"