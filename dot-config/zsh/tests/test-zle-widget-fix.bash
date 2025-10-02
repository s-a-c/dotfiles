#!/usr/bin/env bash
# Test ZLE widget fix to verify early initialization prevents plugin errors
# This simulates the plugin loading process that was causing errors

set -euo pipefail

echo "=== Testing ZLE Widget Fix ==="

# Test function to simulate plugin widget registration
test_widget_registration() {
    echo "🧪 Testing widget registration after early ZLE initialization..."
    
    # Run ZSH with early ZLE init, then try to register widgets like plugins do
    local test_output
    test_output=$(timeout 10s bash -c '
        export ZDOTDIR="'"$PWD"'"
        export ZSH_DEBUG=1
        echo "=== ZLE Widget Registration Test ==="
        
        # Start an interactive zsh session and test widget registration
        zsh -i -c '\''
            # Source our early ZLE initialization
            source .zshrc.pre-plugins.d.REDESIGN/05-zle-initialization.zsh
            
            echo "ZLE_EARLY_INIT_SUCCESS: $ZLE_EARLY_INIT_SUCCESS"
            echo "Widgets available before plugin simulation: ${#widgets[@]}"
            
            # Simulate what autopair plugin does
            echo "Testing autopair-like widget registration..."
            autopair_test_insert() {
                # Simulate autopair widget
                echo "autopair widget called"
            }
            
            if zle -N autopair-test-insert autopair_test_insert; then
                echo "✅ Autopair widget registration: SUCCESS"
            else
                echo "❌ Autopair widget registration: FAILED"
                exit 1
            fi
            
            # Test bindkey operation like plugins do  
            if bindkey "x" autopair-test-insert; then
                echo "✅ Bindkey operation: SUCCESS"
            else
                echo "❌ Bindkey operation: FAILED"  
                exit 1
            fi
            
            # Simulate what zsh-autosuggestions does
            echo "Testing autosuggestions-like widget registration..."
            autosuggest_test_widget() {
                echo "autosuggestions widget called"  
            }
            
            if zle -N autosuggest-test autosuggest_test_widget; then
                echo "✅ Autosuggestions widget registration: SUCCESS"
            else
                echo "❌ Autosuggestions widget registration: FAILED"
                exit 1
            fi
            
            echo "Final widgets count: ${#widgets[@]}"
            echo "WIDGET_REGISTRATION_TEST_SUCCESS"
            exit
        '\''
    ' 2>&1)
    
    if echo "$test_output" | grep -q "WIDGET_REGISTRATION_TEST_SUCCESS"; then
        echo "✅ Widget registration test PASSED"
        echo
        echo "📋 Test Results:"
        echo "$test_output" | grep -E "(ZLE_EARLY_INIT_SUCCESS|Widgets available|SUCCESS|FAILED)"
        return 0
    else
        echo "❌ Widget registration test FAILED"
        echo  
        echo "📋 Test Output:"
        echo "$test_output"
        return 1
    fi
}

# Test early ZLE initialization effectiveness
test_early_zle_init() {
    echo
    echo "🔍 Testing early ZLE initialization effectiveness..."
    
    # Test that early ZLE init actually prepares widgets properly
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c '
        export ZSH_DEBUG=1
        source .zshrc.pre-plugins.d.REDESIGN/05-zle-initialization.zsh 2>/dev/null
        
        echo "ZLE_EARLY_INIT_SUCCESS: $ZLE_EARLY_INIT_SUCCESS" 
        echo "Total widgets: ${#widgets[@]}"
        
        # Check for key widgets that plugins expect
        local core_widgets=("self-insert" "backward-delete-char" "accept-line" "forward-char")
        local available_widgets=0
        
        for widget in "${core_widgets[@]}"; do
            if [[ -n "${widgets[$widget]:-}" ]]; then
                ((available_widgets++))
                echo "✅ $widget: ${widgets[$widget]}"
            else  
                echo "❌ $widget: MISSING"
            fi
        done
        
        echo "Core widgets available: $available_widgets/${#core_widgets[@]}"
        
        if [[ $available_widgets -eq ${#core_widgets[@]} ]]; then
            echo "EARLY_ZLE_INIT_EFFECTIVE"
        else
            echo "EARLY_ZLE_INIT_INCOMPLETE"
        fi
    ' 2>&1)
    
    if echo "$test_output" | grep -q "EARLY_ZLE_INIT_EFFECTIVE"; then
        echo "✅ Early ZLE initialization is effective"
        echo 
        echo "📋 ZLE Status:"
        echo "$test_output" | grep -E "(ZLE_EARLY_INIT_SUCCESS|Total widgets|Core widgets|✅|❌)"
    else
        echo "⚠️  Early ZLE initialization needs improvement"
        echo
        echo "📋 ZLE Status:" 
        echo "$test_output"
    fi
}

# Run tests
test_early_zle_init
test_widget_registration

echo
echo "=== ZLE Widget Fix Test Summary ==="
echo "✅ Early ZLE initialization module created (05-zle-initialization.zsh)"
echo "✅ Widget registration simulation completed"
echo "✅ This should prevent the 'zle: function definition file not found' errors"
echo
echo "🔧 Next steps:"
echo "   1. Test with full shell startup: ZDOTDIR=\$PWD zsh -i"
echo "   2. Check for reduced widget errors during plugin loading"
echo "   3. Verify autopair and other plugins work correctly"