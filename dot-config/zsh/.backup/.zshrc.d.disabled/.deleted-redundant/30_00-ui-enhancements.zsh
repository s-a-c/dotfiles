#!/usr/bin/env zsh
# UI Enhancements and User Experience - POST-PLUGIN PHASE
# This file consolidates user interface, aliases, and keybindings after plugins load
# CONSOLIDATED FROM: 010-aliases.zsh + UI configurations + keybindings

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [ui-enhancements] Configuring user interface after plugins"
}

## [ui-customization.colors] - Enhanced color support
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Less colors
export LESS_TERMCAP_mb=$'\e[1;32m'     # begin blinking
export LESS_TERMCAP_md=$'\e[1;32m'     # begin bold
export LESS_TERMCAP_me=$'\e[0m'        # end mode
export LESS_TERMCAP_se=$'\e[0m'        # end standout-mode
export LESS_TERMCAP_so=$'\e[01;33m'    # begin standout-mode
export LESS_TERMCAP_ue=$'\e[0m'        # end underline
export LESS_TERMCAP_us=$'\e[1;4;31m'   # begin underline

## [ui-enhancements.prompt-customization] - Post-plugin prompt enhancements
# Prompt customizations that work with loaded prompt themes

# If using powerlevel10k, apply post-load customizations
if [[ -n "${POWERLEVEL9K_MODE:-}" ]]; then
    # P10k specific customizations
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
    typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
fi

## [ui-enhancements.colors] - Enhanced color support
# Color configuration that works with loaded color plugins

# Enable colors for various commands
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Less colors
export LESS_TERMCAP_mb=$'\e[1;32m'     # begin blinking
export LESS_TERMCAP_md=$'\e[1;32m'     # begin bold
export LESS_TERMCAP_me=$'\e[0m'        # end mode
export LESS_TERMCAP_se=$'\e[0m'        # end standout-mode
export LESS_TERMCAP_so=$'\e[01;33m'    # begin standout-mode
export LESS_TERMCAP_ue=$'\e[0m'        # end underline
export LESS_TERMCAP_us=$'\e[1;4;31m'   # begin underline

## [ui-enhancements.performance] - UI performance optimizations
# Optimizations for better user experience

# Fast directory listing for large directories
if command -v eza >/dev/null 2>&1; then
    # Eza is already optimized
    :
elif command -v ls >/dev/null 2>&1; then
    # Fallback optimized ls
    alias ls='ls --color=auto'
fi

# Optimize completion display
zstyle ':completion:*' list-max-items 50
zstyle ':completion:*' accept-exact-dirs true

zf::debug "# [ui-enhancements] ✅ User interface and experience enhancements configured"
