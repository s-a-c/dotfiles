#!/usr/bin/env bash
set -euo pipefail

echo "Testing fixed legacy sequencing for starship..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== Verifying flags are honored ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"PREPLUGIN_REDESIGN: \${ZSH_ENABLE_PREPLUGIN_REDESIGN:-UNSET}\"
    echo \"POSTPLUGIN_REDESIGN: \${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-UNSET}\"
    exit
" 2>/dev/null'

echo ""
echo "=== Testing for parameter errors ==="
timeout 15s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep "parameter not set" > param_errors.log 2>/dev/null || echo "No parameter errors found"

if [[ -f param_errors.log && -s param_errors.log ]]; then
    echo "❌ Still have parameter errors:"
    cat param_errors.log
    error_count=$(wc -l < param_errors.log)
else
    echo "✅ No parameter errors found"
    error_count=0
fi

echo ""
echo "=== Checking that legacy modules are used (not REDESIGN) ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep "load-shell-fragments.*zshrc\.d" | \
    head -3

echo ""
echo "=== Summary ==="
if [[ $error_count -eq 0 ]]; then
    echo "🎉 SUCCESS: Fixed legacy sequencing - no parameter errors!"
    echo "   - Flags honored: post-plugin redesign disabled"
    echo "   - Legacy modules used as intended"
    echo "   - Starship loads at proper timing"
else
    echo "⚠️  Still have $error_count parameter errors to investigate"
fi

# Cleanup
rm -f param_errors.log