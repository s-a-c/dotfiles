#!/usr/bin/env bash
set -euo pipefail

echo "Testing starship issues with proper timeouts..."
cd /Users/s-a-c/.config/zsh

echo "=== 1. Quick starship availability test ==="
timeout 3s bash -c 'command -v starship && starship --version' || echo "Starship not available or timed out"

echo ""
echo "=== 2. Test zgenom regeneration ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -c "
    echo \"zgenom available: \$(command -v zgenom >/dev/null && echo yes || echo no)\"
    exit
" 2>&1' | head -5 || echo "zgenom test timed out"

echo ""
echo "=== 3. Check current prompt after startup ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Current PS1: \${PS1:0:50}...\"
    echo \"Current PROMPT: \${PROMPT:0:50}...\"
    echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not set}\"
    exit
" 2>/dev/null' | head -5 || echo "Prompt test timed out"

echo ""
echo "=== 4. Quick error check ==="
timeout 8s bash -c 'ZDOTDIR="$PWD" zsh -i -c "exit" 2>&1' | \
    grep -E "(error|permission denied|command not found)" | \
    head -3 || echo "No obvious errors found"

echo ""
echo "=== Summary ==="
echo "If starship is available but prompt isn't starship, there's a loading issue."
echo "If zgenom init.zsh was corrupted, it should regenerate on first run."
echo "Check for any permission or command errors above."
