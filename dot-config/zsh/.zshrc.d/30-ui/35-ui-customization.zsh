# UI Customization - POST-PLUGIN PHASE
# User interface, aliases, and keybindings AFTER plugins are loaded
# ENHANCED FROM: 010-aliases.zsh + UI configurations

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [ui-customization] Configuring user interface after plugins" >&2
}

## [ui-customization.aliases] - Smart aliases that can override plugin aliases
# These aliases run after plugins load so they can override plugin-provided aliases

# Core system aliases (can override plugin versions)
alias ls='eza --classify --color=always --color-scale --group-directories-first --icons'
alias ll='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git'
alias la='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git --all'
alias lt='eza --classify --color=always --color-scale --group-directories-first --icons --tree --level=2'
alias l='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git --all'

# Enhanced navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# File operations with safety
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Enhanced grep with colors
alias grep='grep --color=always'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'

## [ui-customization.development] - Development workflow aliases
# Git aliases (enhance any plugin-provided git aliases)
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gca='git commit -v --amend'
alias gco='git checkout'
alias gcom='git checkout main || git checkout master'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'

# Docker aliases (enhance plugin versions)
if command -v docker >/dev/null 2>&1; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'
fi

# Kubernetes aliases (enhance plugin versions)
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'
fi

## [ui-customization.productivity] - Productivity enhancement aliases
# Quick editing
alias e='$EDITOR'
alias v='nvim'
alias vim='nvim'
alias vi='nvim'

# System information
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n" | sort'
alias h='history'
alias hg='history | grep'
alias df='df -h'
alias du='du -sh'

# Quick directories
alias home='cd ~'
alias desktop='cd ~/Desktop'
alias downloads='cd ~/Downloads'
alias projects='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'

## [ui-customization.macos-specific] - macOS-specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias flush='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
    alias show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

    if command -v brew >/dev/null 2>&1; then
        alias br='brew'
        alias bri='brew install'
        alias bru='brew uninstall'
        alias brs='brew search'
        alias brup='brew update && brew upgrade'
        alias brclean='brew cleanup'
    fi
fi

## [ui-customization.keybindings] - Enhanced keybindings after plugins load

# History search (works with history-substring-search plugin if loaded)
if command -v history-substring-search-up >/dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up      # Up arrow
    bindkey '^[[B' history-substring-search-down    # Down arrow
    bindkey '^P' history-substring-search-up        # Ctrl+P
    bindkey '^N' history-substring-search-down      # Ctrl+N
else
    bindkey '^[[A' up-line-or-history
    bindkey '^[[B' down-line-or-history
    bindkey '^P' up-line-or-history
    bindkey '^N' down-line-or-history
fi

# FZF keybindings (only if FZF is available)
if command -v fzf >/dev/null 2>&1; then
    bindkey '^T' fzf-file-widget           # Ctrl+T for file selection
    bindkey '^R' fzf-history-widget        # Ctrl+R for history search
    bindkey '\ec' fzf-cd-widget            # Alt+C for directory navigation
fi

# Enhanced editing keybindings
bindkey '^A' beginning-of-line             # Ctrl+A
bindkey '^E' end-of-line                   # Ctrl+E
bindkey '^K' kill-line                     # Ctrl+K
bindkey '^U' kill-whole-line               # Ctrl+U
bindkey '^W' backward-kill-word            # Ctrl+W
bindkey '^Y' yank                          # Ctrl+Y

# Word navigation
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^[[H' beginning-of-line           # Home
bindkey '^[[F' end-of-line                 # End

## [ui-customization.functions] - Enhanced utility functions
# DISABLED: These functions are duplicates and can cause conflicts
# All custom command wrappers have been disabled to prevent interference

# DISABLED: Smart cd with automatic ls (renamed to avoid conflicts)
# Use 'cds' instead of overriding 'cd'
# cds2() {
#     builtin cd "$@" && ls
# }

# DISABLED: Quick directory creation and navigation
# mkcd() {
#     mkdir -p "$1" && cd "$1"
# }

# DISABLED: Enhanced file finding (conflicts with fd command)
# ff() {
#     find . -name "*$1*" -type f
# }

# DISABLED: Enhanced directory finding (conflicts with fd command)
# fd() {
#     find . -name "*$1*" -type d
# }

# DISABLED: Extract various archive formats
# extract() {
#     if [[ -f "$1" ]]; then
#         case "$1" in
#             *.tar.bz2)  tar xjf "$1"      ;;
#             *.tar.gz)   tar xzf "$1"      ;;
#             *.bz2)      bunzip2 "$1"      ;;
#             *.rar)      unrar x "$1"      ;;
#             *.gz)       gunzip "$1"       ;;
#             *.tar)      tar xf "$1"       ;;
#             *.tbz2)     tar xjf "$1"      ;;
#             *.tgz)      tar xzf "$1"      ;;
#             *.zip)      unzip "$1"        ;;
#             *.Z)        uncompress "$1"   ;;
#             *.7z)       7z x "$1"         ;;
#             *)          echo "Cannot extract '$1'" ;;
#         esac
#     else
#         echo "File '$1' not found"
#     fi
# }

# DISABLED: Export enhanced functions
# typeset -gf cds2 mkcd ff fd extract

# NOTE: No custom command wrappers are defined outside of official plugins.

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

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui-customization] ✅ User interface and experience enhancements configured" >&2
