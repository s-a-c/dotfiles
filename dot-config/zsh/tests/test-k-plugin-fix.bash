#!/usr/bin/env bash
set -euo pipefail

echo "=== K PLUGIN AND HANGING FIX TEST ==="
echo "Testing fixes for k plugin conflicts and startup hanging..."
echo ""

# Test 1: Warp Terminal simulation
echo "🧪 Test 1: Warp Terminal k plugin conflict fix"
echo "   (Should not show k plugin parse errors)"

timeout 20s bash -c '
    export ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
    export TERM_PROGRAM="WarpTerminal"
    
    echo "Starting ZSH in simulated Warp Terminal..."
    zsh -i -c "
        echo \"✅ ZSH startup completed in Warp Terminal simulation\"
        echo \"Pre-plugin Warp compat: \${WARP_PRE_PLUGIN_COMPAT_APPLIED:-not_applied}\"
        echo \"k stub created: \${WARP_K_STUB_CREATED:-no}\"
        echo \"k function available: $([[ -n \"\${functions[k]:-}\" ]] && echo yes || echo no)\"
        if [[ -n \"\${functions[k]:-}\" ]]; then
            echo \"Testing k function...\"
            k --help 2>/dev/null | head -2 || echo \"k function exists but help not available\"
        fi
        echo \"k alias available: $([[ -n \"\${aliases[k]:-}\" ]] && echo yes || echo no)\"
        exit
    " 2>&1
' || echo "❌ Warp Terminal test failed"

echo ""

# Test 2: Normal terminal (should load k plugin normally)
echo "🧪 Test 2: Normal terminal k plugin loading"
echo "   (Should load k plugin without conflicts)"

timeout 15s bash -c '
    export ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
    unset TERM_PROGRAM
    
    echo "Starting ZSH in normal terminal..."
    zsh -i -c "
        echo \"✅ ZSH startup completed in normal terminal\"
        echo \"k function available: $([[ -n \"\${functions[k]:-}\" ]] && echo yes || echo no)\"
        echo \"k alias available: $([[ -n \"\${aliases[k]:-}\" ]] && echo yes || echo no)\"
        if [[ -n \"\${functions[k]:-}\" ]]; then
            echo \"k plugin loaded successfully\"
        fi
        exit
    " 2>&1
' || echo "❌ Normal terminal test failed"

echo ""

# Test 3: Check for parse errors
echo "🧪 Test 3: Parse error detection"
echo "   (Should not show 'parse error near' messages)"

parse_errors=$(timeout 10s bash -c '
    export ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
    export TERM_PROGRAM="WarpTerminal"
    zsh -i -c "exit" 2>&1 | grep -i "parse error" || true
' 2>&1)

if [[ -z "$parse_errors" ]]; then
    echo "✅ No parse errors detected"
else
    echo "❌ Parse errors found:"
    echo "$parse_errors"
fi

echo ""

# Test 4: BASH_COMPAT error check
echo "🧪 Test 4: BASH_COMPAT error check"
echo "   (Should not show 'compatibility value out of range' messages)"

bash_errors=$(timeout 10s bash -c '
    export ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
    zsh -i -c "exit" 2>&1 | grep -i "compatibility value out of range" || true
' 2>&1)

if [[ -z "$bash_errors" ]]; then
    echo "✅ No BASH_COMPAT errors detected"
else
    echo "❌ BASH_COMPAT errors found:"
    echo "$bash_errors"
fi

echo ""
echo "=== TEST SUMMARY ==="
echo "K plugin conflict fix: Pre-plugin stub function approach"
echo "BASH_COMPAT fix: Removed problematic variable from .zshenv"
echo "Autopair fix: Parameters initialized in core infrastructure"
echo ""
echo "If all tests pass, startup issues should be resolved!"