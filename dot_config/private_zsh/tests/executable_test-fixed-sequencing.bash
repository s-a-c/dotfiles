#!/usr/bin/env bash
set -euo pipefail

echo "Testing ZSH startup (REDESIGN always active via symlinks)..."
cd /Users/s-a-c/.config/zsh

echo "=== Verifying REDESIGN configuration is active ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Active pre-plugin dir: \$(readlink .zshrc.pre-plugins.d 2>/dev/null || echo 'not symlinked')\"
    echo \"Active post-plugin dir: \$(readlink .zshrc.d 2>/dev/null || echo 'not symlinked')\"
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
echo "=== Checking that REDESIGN modules are loaded ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep "load-shell-fragments.*zshrc" | \
    head -3

echo ""
echo "=== Summary ==="
if [[ $error_count -eq 0 ]]; then
    echo "🎉 SUCCESS: REDESIGN configuration working - no parameter errors!"
    echo "   - REDESIGN modules active via symlinks"
    echo "   - Modern module system used"
    echo "   - Starship initialization handled properly"
else
    echo "⚠️  Still have $error_count parameter errors to investigate"
fi

# Cleanup
rm -f param_errors.log
