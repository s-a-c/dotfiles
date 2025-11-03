#!/usr/bin/env bash
# Test the post-initialization approach for ZLE and Starship

echo "=== Post-Initialization Final Test ==="
echo

cd ${HOME}/.config/zsh

# Check module setup
echo "=== Module Setup Check ==="
echo "ZLE module: $(ls -la .zshrc.d/05.5-zle-initialization.zsh 2>/dev/null | cut -d' ' -f1 || echo 'missing')"
echo "Post-init module: $(ls -la .zshrc.d/99-post-initialization.zsh 2>/dev/null | cut -d' ' -f1 || echo 'missing')"

echo

# Test full startup with post-initialization
echo "=== Full Startup Test with Post-Initialization ==="
timeout 20s bash -c '
ZDOTDIR="${HOME}/.config/zsh"
export ZDOTDIR
echo "Testing full startup with post-initialization..."
zsh -i -c "
echo \"=== Final Status Check ===\"
echo \"ZLE_VERSION: \${ZLE_VERSION:-not_set}\"
echo \"ZLE_READY: \${ZLE_READY:-not_set}\"
echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
echo \"STARSHIP_INITIALIZED: \${STARSHIP_INITIALIZED:-not_set}\"
echo \"POST_INITIALIZATION_LOADED: \${_POST_INITIALIZATION_LOADED:-not_set}\"

echo
echo \"=== System Health ===\"
echo \"System health: \${SYSTEM_HEALTH_STATUS:-not_available}\"
echo \"ZLE status: \${ZLE_INIT_STATUS:-not_available}\"

echo
echo \"=== Widget Check ===\"
if [[ -n \${widgets+x} ]]; then
    echo \"Widgets count: \${#widgets[@]}\"
    echo \"zle-keymap-select: \${widgets[zle-keymap-select]:-not_found}\"
    echo \"zle-line-init: \${widgets[zle-line-init]:-not_found}\"
    echo \"zle-line-finish: \${widgets[zle-line-finish]:-not_found}\"
else
    echo \"Widgets array not available\"
fi

echo
echo \"=== Post-Init Self-Test ===\"
if command -v test_post_initialization >/dev/null 2>&1; then
    test_post_initialization
else
    echo \"Post-initialization self-test function not available\"
fi

exit
" 2>&1
'

echo
echo "=== Final Test Complete ==="
