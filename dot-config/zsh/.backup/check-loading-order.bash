#!/usr/bin/env bash
set -euo pipefail

echo "Checking current ZSH module loading order..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== Current active modules loading sequence ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep -E "(\[.*\].*loaded|\[.*\].*Loading|starship|widgets)" | \
    head -20

echo ""
echo "=== Legacy consolidated modules in use ==="
if [[ -d .zshrc.d.legacy/consolidated-modules ]]; then
    ls -la .zshrc.d.legacy/consolidated-modules/ | grep -E "\.zsh$" || echo "No .zsh files found"
fi

echo ""  
echo "=== Redesign post-plugin modules ==="
if [[ -d .zshrc.d.REDESIGN ]]; then
    ls -la .zshrc.d.REDESIGN/ | grep -E "\.zsh$" | head -10 || echo "No .zsh files found"
fi

echo ""
echo "=== Current .zshrc structure ==="
grep -E "(source|\\.|legacy|REDESIGN)" .zshrc | head -10 || echo "No sourcing patterns found"