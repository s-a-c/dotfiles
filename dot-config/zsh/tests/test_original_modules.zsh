#!/usr/bin/env bash
# Test ZLE with original pre-plugin modules

echo "=== Testing Original Pre-Plugin Modules ==="
echo

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Test with original modules (should now use .zshrc.pre-plugins.d instead of .REDESIGN)
timeout 15s bash -c '
ZSH_ENABLE_PREPLUGIN_REDESIGN=0 ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" zsh -i -c "
echo \"=== Module Selection Test ===\" 
echo \"PREPLUGIN_REDESIGN: \${ZSH_ENABLE_PREPLUGIN_REDESIGN:-not_set}\"
echo \"POSTPLUGIN_REDESIGN: \${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-not_set}\"

echo
echo \"=== ZLE Status with Original Modules ===\" 
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
echo \"Starship available: \$(command -v starship >/dev/null && echo yes || echo no)\"

echo
echo \"=== Manual Starship Init Test ===\" 
if command -v starship >/dev/null 2>&1; then
    echo \"Testing manual Starship initialization...\"
    # Try to initialize starship manually
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
echo "=== Original Modules Test Complete ==="