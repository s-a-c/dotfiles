#!/usr/bin/env bash
set -euo pipefail

echo "Testing starship with error reporting..."
cd /Users/s-a-c/.config/zsh

echo "=== Test starship init with error reporting ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep -E "(starship|error|failed)" | \
    tail -5 || echo "No starship errors found"

echo ""
echo "=== Test manual starship init to see error ==="
timeout 8s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Testing starship init with errors shown:\"
    starship init zsh | head -3 || echo \"starship init command failed\"
    exit
" 2>&1' | tail -8 || echo "Manual starship test failed"
