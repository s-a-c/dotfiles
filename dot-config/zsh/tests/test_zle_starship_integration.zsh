#!/usr/bin/env bash
# Test the new ZLE initialization module and Starship integration

echo "=== ZLE + Starship Integration Test ==="
echo

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Check that the symlink was created
echo "=== Module Setup Check ==="
if [[ -L .zshrc.d/05.5-zle-initialization.zsh ]]; then
    echo "✅ ZLE initialization module symlinked"
    ls -la .zshrc.d/05.5-zle-initialization.zsh
else
    echo "❌ ZLE initialization module symlink missing"
fi

echo

# Test ZLE initialization in full environment
echo "=== ZLE + Starship Integration Test ==="
timeout 20s bash -c '
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
export ZDOTDIR
echo "Testing ZLE initialization with Starship..."
zsh -i -c "
echo \"=== ZLE Initialization Status ===\" 
echo \"ZLE_READY: \${ZLE_READY:-not_set}\"
echo \"ZLE_VERSION: \${ZLE_VERSION:-not_set}\"
echo \"ZLE_INIT_STATUS: \${ZLE_INIT_STATUS:-not_set}\"
echo \"ZLE module loaded: \${_ZLE_INITIALIZATION_LOADED:-not_set}\"

echo
echo \"=== Widget Check ===\"
echo \"Widgets array size: \${#widgets[@]}\"
echo \"zle-keymap-select widget: \${widgets[zle-keymap-select]:-not_found}\"

echo
echo \"=== Starship Status ===\"
echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
echo \"PS1 length: \${#PS1}\"

echo
echo \"=== Testing ZLE Self-Test ===\"
test_zle_initialization

echo
echo \"=== Manual Starship Test ===\"
if [[ \"\${ZLE_READY:-0}\" == \"1\" ]]; then
    echo \"ZLE is ready - testing Starship initialization manually...\"
    starship_init=\$(starship init zsh)
    echo \"Starship init script length: \${#starship_init}\"
    eval \"\$starship_init\"
    echo \"After manual init - STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
else
    echo \"ZLE not ready - skipping manual Starship test\"
fi

exit
" 2>&1 | grep -E "(ZLE|Starship|STARSHIP|✅|❌|⚠️|===)"
'

echo
echo "=== Integration Test Complete ==="