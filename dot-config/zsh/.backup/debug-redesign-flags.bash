#!/usr/bin/env bash
set -euo pipefail

echo "Debugging redesign flag states and actual loading..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== Checking redesign flags in .zshenv ==="
grep -n "ZSH_ENABLE.*REDESIGN" .zshenv | head -5

echo ""
echo "=== What flags are actually set during startup ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"PREPLUGIN_REDESIGN: \${ZSH_ENABLE_PREPLUGIN_REDESIGN:-UNSET}\"
    echo \"POSTPLUGIN_REDESIGN: \${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-UNSET}\"
    echo \"POSTPLUGIN_REDESIGN status: \$(( \${+ZSH_ENABLE_POSTPLUGIN_REDESIGN} ))\"
    exit
" 2>/dev/null'

echo ""
echo "=== What directories exist ==="
echo "REDESIGN directory: $(ls -la .zshrc.d.REDESIGN/ 2>/dev/null | wc -l || echo 'MISSING') files"
echo "Legacy .zshrc.d directory: $(ls -la .zshrc.d/ 2>/dev/null | wc -l || echo 'MISSING') files"
echo "Legacy consolidated modules: $(ls -la .zshrc.d.legacy/consolidated-modules/ 2>/dev/null | wc -l || echo 'MISSING') files"

echo ""
echo "=== Which directory is actually being loaded? ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -E "(load-shell-fragments.*zshrc\.d|Using.*REDESIGN)" | \
    head -5 || echo "No clear loading pattern found"

echo ""
echo "=== How is starship being loaded? ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -x -i -c "exit" 2>&1' | \
    grep -B2 -A2 "starship\|06-user-interface" | \
    head -10 || echo "No starship loading pattern found"