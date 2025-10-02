#!/usr/bin/env bash
# Debug why Starship isn't initializing in full environment

echo "=== Starship Debug Test ==="
echo

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Test the external integrations module directly
echo "=== Testing External Integrations Module ==="
timeout 15s bash -c '
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
export ZDOTDIR
zsh -i -c "
echo \"External integrations loaded: \${_EXTERNAL_INTEGRATIONS_LOADED:-not_set}\"
echo \"External integrations function available: \$(command -v setup_starship_prompt >/dev/null && echo yes || echo no)\"

echo
echo \"Testing setup_starship_prompt function directly:\"
setup_starship_prompt
echo \"After running setup_starship_prompt:\"
echo \"  STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
echo \"  PS1 length: \${#PS1}\"

exit
" 2>&1
'

echo
echo "=== Debug Complete ==="