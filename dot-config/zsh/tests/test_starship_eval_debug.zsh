#!/usr/bin/env bash
# Test to debug why eval fails in ZSH environment

echo "=== Starship Eval Debug ==="
echo

cd ${HOME}/dotfiles/dot-config/zsh

# Test eval with full error output
timeout 15s bash -c '
ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"
export ZDOTDIR
zsh -i -c "
echo \"=== Testing Starship Eval in Full Environment ===\"

# Generate starship init
echo \"Generating starship init script...\"
starship_init=\$(starship init zsh)
echo \"Script length: \${#starship_init}\"

echo
echo \"Testing eval with full error output:\"
if eval \"\$starship_init\"; then
    echo \"✅ Eval succeeded\"
    echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
else
    echo \"❌ Eval failed with exit code: \$?\"
fi

echo
echo \"Testing eval with stderr visible:\"
eval \"\$starship_init\" 2>&1
echo \"After eval - STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"

exit
" 2>&1
'

echo
echo "=== Debug Complete ==="
