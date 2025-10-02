#!/usr/bin/env bash
set -euo pipefail

echo "Testing starship function execution with debug..."
cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== Testing with ZSH_DEBUG enabled ==="
timeout 15s bash -c 'ZDOTDIR="$PWD" ZSH_DEBUG=1 zsh -i -c "exit" 2>&1' | \
    grep -E "(EXT-DEBUG|starship|Starship|setup_starship)" | \
    tail -10 > starship_debug.log 2>/dev/null || echo "Starship debug search completed"

if [[ -f starship_debug.log && -s starship_debug.log ]]; then
    echo "Starship debug output:"
    cat starship_debug.log
    echo ""
else
    echo "No starship debug output found"
fi

echo "=== Testing if starship command is available ==="
timeout 5s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Starship command: \$(command -v starship || echo NOT_FOUND)\"
    echo \"Starship version: \$(starship --version 2>/dev/null || echo NOT_AVAILABLE)\"
    exit
" 2>/dev/null' || echo "Starship availability check failed"

echo ""
echo "=== Manual test of the exact starship init command ==="
timeout 5s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Testing starship init directly:\"
    starship init zsh | head -5 || echo \"starship init failed\"
    exit
" 2>/dev/null' || echo "Manual starship test failed"

# Cleanup
rm -f starship_debug.log