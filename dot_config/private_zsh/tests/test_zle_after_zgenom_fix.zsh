#!/usr/bin/env bash
# Test ZLE after proper zgenom configuration

echo "=== Testing ZLE After Zgenom Fix ==="
echo

cd ${HOME}/.config/zsh

# Test with properly configured zgenom
timeout 20s bash -c '
ZDOTDIR="${HOME}/.config/zsh"
export ZDOTDIR
echo "Testing ZLE with proper zgenom configuration..."
zsh -i -c "
echo \"=== ZLE Status After Zgenom Fix ===\"
echo \"ZLE_VERSION: \${ZLE_VERSION:-not_set}\"
echo \"ZLE_READY: \${ZLE_READY:-not_set}\"
echo \"Interactive: \$([[ -o interactive ]] && echo yes || echo no)\"

echo
echo \"=== Widget Check ===\"
if [[ -n \${widgets+x} ]]; then
    echo \"Widgets array available: yes\"
    echo \"Widgets count: \${#widgets[@]}\"
    echo \"zle-keymap-select: \${widgets[zle-keymap-select]:-not_found}\"
    echo \"zle-line-init: \${widgets[zle-line-init]:-not_found}\"
    echo \"zle-line-finish: \${widgets[zle-line-finish]:-not_found}\"
else
    echo \"Widgets array available: no\"
fi

echo
echo \"=== Starship Test ===\"
echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
echo \"STARSHIP_INITIALIZED: \${STARSHIP_INITIALIZED:-not_set}\"
echo \"Starship available: \$(command -v starship >/dev/null && echo yes || echo no)\"

echo
echo \"=== System Health ===\"
echo \"System health: \${SYSTEM_HEALTH_STATUS:-not_available}\"
echo \"Post-init loaded: \${_POST_INITIALIZATION_LOADED:-not_set}\"

echo
echo \"=== Manual Starship Test ===\"
if command -v starship >/dev/null 2>&1; then
    echo \"Testing manual Starship initialization...\"
    starship_script=\$(starship init zsh 2>/dev/null)
    echo \"Starship script length: \${#starship_script}\"
    if [[ -n \"\$starship_script\" ]]; then
        eval \"\$starship_script\" 2>/dev/null
        echo \"After manual init - STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
    else
        echo \"Failed to generate starship init script\"
    fi
else
    echo \"Starship not available\"
fi

exit
" 2>&1
'

echo
echo "=== ZLE Test After Zgenom Fix Complete ==="
