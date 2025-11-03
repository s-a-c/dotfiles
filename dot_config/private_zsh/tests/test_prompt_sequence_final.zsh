#!/usr/bin/env bash
# Test for prompt sequence timing and P10k/Starship conflict

echo "=== Prompt Sequence Conflict Test ==="
echo

cd ${HOME}/.config/zsh

# Run ZSH startup with verbose prompt debugging
ZDOTDIR="$PWD" timeout 15s zsh -i -c '
echo "=== Prompt Loading Sequence ==="
echo "Starship available: $(command -v starship >/dev/null && echo yes || echo no)"
echo "P10k config file: $([[ -f "$ZDOTDIR/.p10k.zsh" ]] && echo exists || echo missing)"
echo

echo "=== Testing Starship init directly ==="
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
    echo "STARSHIP_SHELL after direct init: $STARSHIP_SHELL"
    echo "PS1 starts with: ${PS1:0:50}..."
    echo "PROMPT starts with: ${PROMPT:0:50}..."
fi

echo

echo "=== External Integrations Module ==="
if [[ -f "$ZDOTDIR/.zshrc.d.legacy/raw-modules/ACTIVE-03_04-external-integrations.zsh" ]]; then
    grep -n "starship" "$ZDOTDIR/.zshrc.d.legacy/raw-modules/ACTIVE-03_04-external-integrations.zsh"
fi

echo

echo "=== Prompt Module ==="
if [[ -f "$ZDOTDIR/.zshrc.d.legacy/raw-modules/ACTIVE-30_30-prompt.zsh" ]]; then
    echo "Lines with starship/p10k:"
    grep -n -E "(starship|p10k)" "$ZDOTDIR/.zshrc.d.legacy/raw-modules/ACTIVE-30_30-prompt.zsh"
fi

echo

echo "=== Current Prompt State ==="
echo "Final STARSHIP_SHELL: $STARSHIP_SHELL"
echo "Final PS1 starts with: ${PS1:0:100}..."
echo "Final PROMPT starts with: ${PROMPT:0:100}..."

exit
' 2>&1

echo
echo "=== Conflict Analysis Complete ==="
