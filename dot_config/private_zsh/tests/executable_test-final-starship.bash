#!/usr/bin/env bash
set -euo pipefail

echo "Testing final starship loading issue..."
cd /Users/s-a-c/.config/zsh

echo "=== 1. Test if external integrations module loads ==="
timeout 15s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"External integrations loaded: \${_EXTERNAL_INTEGRATIONS_LOADED:-not loaded}\"
    echo \"ZSH_ENABLE_EXTERNAL_TOOLS: \${ZSH_ENABLE_EXTERNAL_TOOLS:-not set}\"
    echo \"setup_starship_prompt function: \$(declare -f setup_starship_prompt >/dev/null && echo exists || echo missing)\"
    exit
" 2>/dev/null' || echo "External integrations test timed out"

echo ""
echo "=== 2. Test manual starship initialization ==="
timeout 10s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"Testing manual starship init...\"
    if command -v starship >/dev/null; then
        echo \"Starship available, testing init:\"
        eval \"\$(starship init zsh)\" && echo \"Starship init successful\" || echo \"Starship init failed\"
        echo \"STARSHIP_SHELL after manual init: \${STARSHIP_SHELL:-not set}\"
    else
        echo \"Starship command not available\"
    fi
    exit
" 2>/dev/null' || echo "Manual starship test timed out"

echo ""
echo "=== 3. Check current prompt variables ==="
timeout 8s bash -c 'ZDOTDIR="$PWD" zsh -i -c "
    echo \"PS1 length: \${#PS1}\"
    echo \"PROMPT length: \${#PROMPT}\"
    echo \"PS1 starts with: \${PS1:0:30}...\"
    echo \"Functions containing starship: \$(declare -f | grep -c starship || echo 0)\"
    exit
" 2>/dev/null' || echo "Prompt variables test timed out"

echo ""
echo "=== Summary ==="
echo "The zgenom issue is fixed, but starship still not initializing."
echo "Need to check if setup_starship_prompt function exists and gets called."
