#!/usr/bin/env bash
set -euo pipefail

echo "=== STARTUP HANG FIX TEST ==="
echo "Testing ZSH startup after applying k plugin and BASH_COMPAT fixes..."
echo ""

# Clear zgenom cache to force fresh plugin loading
echo "🧹 Clearing zgenom cache to test fresh plugin loading..."
rm -f /Users/s-a-c/.config/zsh/.zqs-zgenom/init.zsh
echo "   Cache cleared"

echo ""

# Test 1: Basic startup test in normal terminal (bash)
echo "🧪 Test 1: Startup in bash terminal (should succeed)"
timeout 15s bash -c '
    export ZDOTDIR="${HOME}/.config/zsh"
    echo "Starting ZSH in bash terminal..."
    zsh -i -c "
        echo \"SUCCESS: ZSH startup completed in bash terminal\"
        echo \"TERM_PROGRAM: ${TERM_PROGRAM:-not_set}\"
        echo \"k function exists: $([[ -n \"\${functions[k]:-}\" ]] && echo yes || echo no)\"
        echo \"k alias exists: $([[ -n \"\${aliases[k]:-}\" ]] && echo yes || echo no)\"
        exit
    "
' 2>&1 | head -50

echo ""

# Test 2: Startup test simulating Warp Terminal
echo "🧪 Test 2: Startup simulating Warp Terminal (k plugin should be skipped)"
timeout 15s bash -c '
    export ZDOTDIR="${HOME}/.config/zsh"
    export TERM_PROGRAM="WarpTerminal"
    echo "Starting ZSH simulating Warp Terminal..."
    zsh -i -c "
        echo \"SUCCESS: ZSH startup completed in simulated Warp\"
        echo \"TERM_PROGRAM: ${TERM_PROGRAM:-not_set}\"
        echo \"k function exists: $([[ -n \"\${functions[k]:-}\" ]] && echo yes || echo no)\"
        echo \"k alias exists: $([[ -n \"\${aliases[k]:-}\" ]] && echo yes || echo no)\"
        echo \"Pre-plugin Warp compat applied: ${WARP_PRE_PLUGIN_COMPAT_APPLIED:-not_set}\"
        echo \"kubectl available: $([[ -n \"\${commands[kubectl]:-}\" ]] && echo yes || echo no)\"
        exit
    "
' 2>&1 | head -50

echo ""

# Test 3: Autopair parameter test
echo "🧪 Test 3: Autopair parameter error test"
timeout 10s bash -c '
    export ZDOTDIR="${HOME}/.config/zsh"
    echo "Testing autopair parameters..."
    zsh -i -c "
        echo \"Testing autopair function availability...\"
        if [[ -n \"\${functions[_ap-get-pair]:-}\" ]]; then
            echo \"autopair function exists\"
            echo \"AUTOPAIR_PAIRS: \${AUTOPAIR_PAIRS:-not_set}\"
            echo \"AUTOPAIR_LBOUNDS: \${AUTOPAIR_LBOUNDS:-not_set}\"
            echo \"AUTOPAIR_RBOUNDS: \${AUTOPAIR_RBOUNDS:-not_set}\"
        else
            echo \"autopair function not loaded\"
        fi
        exit
    "
' 2>&1

echo ""

# Test 4: Interactive prompt test (check for hanging after prompt appears)
echo "🧪 Test 4: Interactive prompt hanging test (5 second timeout)"
echo "   This test checks if the shell hangs after showing the prompt..."

result=$(timeout 5s bash -c '
    export ZDOTDIR="${HOME}/.config/zsh"
    echo "Testing interactive prompt..."
    
    # Use expect-like behavior with a very short interactive session
    zsh -i -c "
        # Immediately test if we can execute commands
        echo \"PROMPT_READY\"
        date \"+%H:%M:%S - Prompt is responsive\"
        exit
    " 2>&1
' 2>&1) && echo "✅ Prompt test successful" || echo "❌ Prompt test failed or timed out"

echo "Prompt test output:"
echo "$result" | head -20

echo ""
echo "=== STARTUP HANG FIX TEST COMPLETE ==="
echo ""
echo "Summary:"
echo "- BASH_COMPAT issue fixed: removed from .zshenv"
echo "- K plugin conflict fixed: conditionally excluded in Warp"
echo "- Pre-plugin Warp compatibility: applied before plugin loading"
echo "- Autopair parameters: should be properly initialized"
echo ""
echo "If all tests pass, the hanging issue should be resolved."
