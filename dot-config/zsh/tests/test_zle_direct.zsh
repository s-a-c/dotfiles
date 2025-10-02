#!/usr/bin/env bash
# Direct test of ZLE module with detailed debugging

echo "=== ZLE Module Direct Test ==="
echo

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Test ZLE module directly
timeout 15s bash -c '
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
export ZDOTDIR
export ZSH_DEBUG=1
echo "Testing ZLE module directly..."
zsh -i -c "
# Source the ZLE module directly to see debug output
source .zshrc.d.legacy/consolidated-modules/05.5-zle-initialization.zsh

echo
echo \"=== After Direct ZLE Module Load ===\"
echo \"ZLE_READY: \${ZLE_READY:-not_set}\"
echo \"ZLE_VERSION: \${ZLE_VERSION:-not_set}\"
echo \"_ZLE_INITIALIZATION_LOADED: \${_ZLE_INITIALIZATION_LOADED:-not_set}\"
echo \"Interactive mode: \$([[ -o interactive ]] && echo yes || echo no)\"
echo \"Widgets array exists: \$([[ -n \${widgets+x} ]] && echo yes || echo no)\"
if [[ -n \${widgets+x} ]]; then
    echo \"Widgets count: \${#widgets[@]}\"
    echo \"zle-keymap-select: \${widgets[zle-keymap-select]:-not_found}\"
fi

echo
echo \"=== Running ZLE Self-Test ===\"
test_zle_initialization

exit
" 2>&1
'

echo
echo "=== Direct Test Complete ==="