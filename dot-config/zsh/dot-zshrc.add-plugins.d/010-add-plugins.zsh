
[[ -n "$ZSH_DEBUG" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

zgenom load mroth/evalcache
zgenom load olets/zsh-abbr . v6
zgenom ohmyzsh plugins/aliases
zgenom load mafredri/zsh-async
zgenom load hlissner/zsh-autopair
zgenom load olets/zsh-autosuggestions-abbreviations-strategy
zgenom ohmyzsh plugins/bun
zgenom ohmyzsh plugins/charm
zgenom ohmyzsh plugins/colorize
zgenom ohmyzsh plugins/composer
zgenom ohmyzsh plugins/cpanm
zgenom load romkatv/zsh-defer
zgenom ohmyzsh plugins/deno
zgenom load jamesob/desk shell_plugins/zsh
zgenom ohmyzsh plugins/direnv
zgenom ohmyzsh plugins/dotnet
zgenom ohmyzsh plugins/emacs
#zgenom load b4b4r07/enhancd
zgenom ohmyzsh plugins/eza
zgenom ohmyzsh plugins/fzf
zgenom ohmyzsh plugins/gem
zgenom ohmyzsh plugins/gh
zgenom ohmyzsh plugins/git
zgenom ohmyzsh plugins/golang
zgenom ohmyzsh plugins/gpg-agent
zgenom ohmyzsh plugins/isodate
zgenom ohmyzsh plugins/iterm2
zgenom ohmyzsh plugins/kitty
zgenom ohmyzsh plugins/laravel
zgenom ohmyzsh plugins/zsh-navigation-tools
zgenom load chisui/zsh-nix-shell
zgenom ohmyzsh plugins/npm
zgenom ohmyzsh plugins/nvm
zgenom ohmyzsh plugins/perl
zgenom ohmyzsh plugins/pip
zgenom ohmyzsh plugins/rust
zgenom ohmyzsh plugins/screen
zgenom ohmyzsh plugins/ssh
zgenom ohmyzsh plugins/ssh-agent
zgenom ohmyzsh plugins/starship
zgenom ohmyzsh plugins/tailscale
zgenom ohmyzsh plugins/themes
zgenom ohmyzsh plugins/tmux
zgenom ohmyzsh plugins/xcode
zgenom ohmyzsh plugins/zoxide
zgenom load zdharma-continuum/fast-syntax-highlighting
