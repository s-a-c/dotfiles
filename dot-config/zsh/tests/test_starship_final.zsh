#!/usr/bin/env bash
# Final test for Starship prompt after P10k conflict fix

echo "=== Final Starship Prompt Test ==="
echo

cd ${HOME}/dotfiles/dot-config/zsh

# Test Starship prompt setup in current configuration
ZDOTDIR="$PWD" timeout 15s zsh -i -c '
echo "=== Starship Configuration Test ==="
echo "Starship available: $(command -v starship >/dev/null && echo yes || echo no)"
echo "STARSHIP_SHELL: ${STARSHIP_SHELL:-not set}"
echo "STARSHIP_CONFIG: ${STARSHIP_CONFIG:-not set}"

echo
echo "=== Prompt Variables ==="
echo "PS1 length: ${#PS1}"
echo "PROMPT length: ${#PROMPT}"
echo "PS1 starts with: ${PS1:0:100}..."
echo "PROMPT starts with: ${PROMPT:0:100}..."

echo
echo "=== P10k Status ==="
echo "P10k theme active: $([[ -n "${POWERLEVEL9K_MODE:-}" ]] && echo yes || echo no)"
echo "POWERLEVEL9K_MODE: ${POWERLEVEL9K_MODE:-not set}"

echo
echo "=== Module Status ==="
echo "External integrations loaded: $([[ -n "${_EXTERNAL_INTEGRATIONS_LOADED:-}" ]] && echo yes || echo no)"
echo "UI module loaded: $([[ -n "${_USER_INTERFACE_LOADED:-}" ]] && echo yes || echo no)"

echo
echo "=== Final Test: Display Current Prompt ==="
echo "Current directory: $PWD"
echo "Prompt ready - exiting to show final prompt"
exit
' 2>&1

echo
echo "=== Starship Test Complete ==="
