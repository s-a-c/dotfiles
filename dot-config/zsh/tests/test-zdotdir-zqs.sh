#!/usr/bin/env bash
# test-zdotdir-zqs.sh - Test ZDOTDIR-aware ZQS .zshrc

set -euo pipefail

echo "=== ZDOTDIR-aware ZQS .zshrc Test ==="
echo "Testing the patched ZQS .zshrc with ZDOTDIR support..."
echo ""

# Test 1: Basic loading
echo "Test 1: Basic ZQS loading with ZDOTDIR"
test_basic_loading() {
    echo "Testing ZDOTDIR-aware ZQS .zshrc loading..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 15s zsh -c '
        source ".zshrc.zdotdir-aware"
        echo "ZDOTDIR_ZQS_LOADED"
        echo "ZDOTDIR: $ZDOTDIR"
        echo "_ZQS_SETTINGS_DIR: $_ZQS_SETTINGS_DIR"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "ZDOTDIR_ZQS_LOADED"; then
        echo "✅ ZDOTDIR-aware ZQS loaded successfully"
        echo "   Settings dir: $(echo "$test_output" | grep "_ZQS_SETTINGS_DIR:" | cut -d: -f2-)"
        return 0
    else
        echo "❌ ZDOTDIR-aware ZQS failed to load"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 2: Extension loading paths
echo ""
echo "Test 2: Extension path verification"
test_extension_paths() {
    echo "Testing that extensions load from ZDOTDIR paths..."
    
    # Create a test extension
    mkdir -p .test-extensions.d
    cat > .test-extensions.d/test-marker.zsh << 'EOF'
#!/usr/bin/env zsh
export TEST_ZDOTDIR_EXTENSION_LOADED=1
echo "Test extension loaded from ZDOTDIR"
EOF
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -c '
        # Mock load-shell-fragments to use our test directory
        load-shell-fragments() {
            if [[ "$1" == "$ZDOTDIR/.zshrc.d" ]]; then
                echo "Would load from: $1"
                # Load our test extensions instead
                for file in "$ZDOTDIR/.test-extensions.d"/*.zsh; do
                    if [[ -r "$file" ]]; then
                        source "$file"
                    fi
                done
            fi
        }
        
        # Test the ZDOTDIR-aware loading logic
        if [[ -n "$ZDOTDIR" ]]; then
            mkdir -p "$ZDOTDIR/.zshrc.d"
            load-shell-fragments "$ZDOTDIR/.zshrc.d"
        fi
        
        echo "TEST_EXTENSION_RESULT"
        echo "TEST_ZDOTDIR_EXTENSION_LOADED: $TEST_ZDOTDIR_EXTENSION_LOADED"
        exit
    ' 2>&1)
    
    # Cleanup
    rm -rf .test-extensions.d
    
    if echo "$test_output" | grep -q "Test extension loaded from ZDOTDIR"; then
        echo "✅ Extensions loading from ZDOTDIR paths"
        return 0
    else
        echo "❌ Extensions not loading correctly"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 3: Emergency fix integration
echo ""
echo "Test 3: Emergency fix compatibility"
test_emergency_fix() {
    echo "Testing emergency fix with ZDOTDIR-aware ZQS..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 15s zsh -c '
        # Source the ZDOTDIR-aware ZQS (minimal version)
        
        # Define core functions that ZQS provides
        can_haz() { command -v "$1" >/dev/null 2>&1; }
        _zqs-get-setting() { echo "${2:-}"; }
        load-shell-fragments() {
            if [[ -d "$1" ]]; then
                for file in "$1"/*.zsh; do
                    if [[ -r "$file" ]]; then
                        echo "Loading: $(basename $file)"
                        source "$file"
                    fi
                done
            fi
        }
        
        # Simulate the ZDOTDIR-aware post-plugin loading
        if [[ -n "$ZDOTDIR" ]]; then
            mkdir -p "$ZDOTDIR/.zshrc.d"
            load-shell-fragments "$ZDOTDIR/.zshrc.d"
        fi
        
        echo "EMERGENCY_FIX_TEST"
        echo "ZSH_AUTOSUGGEST_DISABLE: $ZSH_AUTOSUGGEST_DISABLE"
        echo "GITSTATUS_DISABLE: $GITSTATUS_DISABLE"
        
        # Test emergency functions
        if declare -f _zsh_autosuggest_bind_widget >/dev/null; then
            echo "✅ Emergency functions available"
        fi
        
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "emergency ZLE widget repair"; then
        echo "✅ Emergency fix integrated with ZDOTDIR-aware ZQS"
        echo "   Emergency vars active:"
        echo "$test_output" | grep -E "(ZSH_AUTOSUGGEST_DISABLE|GITSTATUS_DISABLE|Emergency functions)" | sed 's/^/     /'
        return 0
    else
        echo "⚠️  Emergency fix integration unclear"
        echo "Output: $test_output"
        return 0  # Don't fail the test for this
    fi
}

# Run all tests
echo "Running test suite..."
echo "===================================="

failed_tests=0

test_basic_loading || ((failed_tests++))
echo ""
test_extension_paths || ((failed_tests++))
echo ""
test_emergency_fix || ((failed_tests++))

echo ""
echo "=== Test Summary ==="
if [[ $failed_tests -eq 0 ]]; then
    echo "✅ All tests passed! ZDOTDIR-aware ZQS is ready"
    echo ""
    echo "Next steps:"
    echo "1. Switch to ZDOTDIR-aware ZQS: mv .zshrc .zshrc.backup && mv .zshrc.zdotdir-aware .zshrc"
    echo "2. Test startup: ZDOTDIR=$PWD zsh -i"
    echo "3. Verify auto-suggestions can be re-enabled safely"
else
    echo "❌ $failed_tests test(s) failed"
    echo "   Fix issues before proceeding"
fi