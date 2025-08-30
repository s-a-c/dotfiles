#!/usr/bin/env zsh
# test-plugin-order.zsh
# Design test: ensure add-plugins script declares expected ordered sequence (static parse)
set -euo pipefail
SCRIPT="$ZDOTDIR/.zshrc.add-plugins.d/010-add-plugins.zsh"
: ${ZDOTDIR:=${XDG_CONFIG_HOME:-$HOME/.config}/zsh}
SCRIPT="$ZDOTDIR/.zshrc.add-plugins.d/010-add-plugins.zsh"
if [[ ! -f $SCRIPT ]]; then
    echo "SKIP add-plugins script missing"; exit 0
fi
expected=(
    'hlissner/zsh-autopair'
    'composer'
    'laravel'
    'gh'
    'iterm2'
    'nvm'
    'npm'
    'aliases'
    'eza'
    'zoxide'
    'fzf'
    'mroth/evalcache'
    'mafredri/zsh-async'
    'romkatv/zsh-defer'
)
# Parse loads in order ignoring gated abbr plugin
actual=()
while IFS= read -r line; do
    case $line in
        (zgenom\ load\ hlissner/zsh-autopair*) actual+=("hlissner/zsh-autopair") ;;
        (zgenom\ oh-my-zsh\ plugins/composer*) actual+=("composer") ;;
        (zgenom\ oh-my-zsh\ plugins/laravel*) actual+=("laravel") ;;
        (zgenom\ oh-my-zsh\ plugins/gh*) actual+=("gh") ;;
        (zgenom\ oh-my-zsh\ plugins/iterm2*) actual+=("iterm2") ;;
        (zgenom\ oh-my-zsh\ plugins/nvm*) actual+=("nvm") ;;
        (zgenom\ oh-my-zsh\ plugins/npm*) actual+=("npm") ;;
        (zgenom\ oh-my-zsh\ plugins/aliases*) actual+=("aliases") ;;
        (zgenom\ oh-my-zsh\ plugins/eza*) actual+=("eza") ;;
        (zgenom\ oh-my-zsh\ plugins/zoxide*) actual+=("zoxide") ;;
        (zgenom\ oh-my-zsh\ plugins/fzf*) actual+=("fzf") ;;
        (zgenom\ load\ mroth/evalcache*) actual+=("mroth/evalcache") ;;
        (zgenom\ load\ mafredri/zsh-async*) actual+=("mafredri/zsh-async") ;;
        (zgenom\ load\ romkatv/zsh-defer*) actual+=("romkatv/zsh-defer") ;;
    esac
done < "$SCRIPT"
# Compare sequences (prefix must match expected order but may omit gated items based on flags)
# Build filtered expected list honoring flags
filtered_expected=()
for item in "${expected[@]}"; do
    if [[ $item == nvm || $item == npm ]]; then
        [[ ${ZSH_ENABLE_NVM_PLUGINS:-1} == 1 ]] || continue
    fi
    filtered_expected+=("$item")
done
if [[ "${actual[*]}" != "${filtered_expected[*]}" ]]; then
    echo "FAIL plugin order mismatch" >&2
    echo "Expected: ${filtered_expected[*]}" >&2
    echo "Actual:     ${actual[*]}" >&2
    exit 1
fi
echo "PASS plugin order (${#actual} entries)"
