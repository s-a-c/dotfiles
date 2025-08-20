# UI Enhancements and User Experience - POST-PLUGIN PHASE
# This file consolidates user interface, aliases, and keybindings after plugins load
# CONSOLIDATED FROM: 010-aliases.zsh + UI configurations + keybindings

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [ui-enhancements] Configuring user interface after plugins" >&2
}

## [ui-enhancements.aliases] - Smart aliases that can override plugin aliases
# ENHANCED FROM: 010-aliases.zsh
# These aliases run after plugins load so they can override plugin-provided aliases

# Core system aliases (can override plugin versions)
alias ls='eza --classify --color=always --color-scale --group-directories-first --icons'
alias ll='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git'
alias la='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git --all'
alias lt='eza --classify --color=always --color-scale --group-directories-first --icons --tree --level=2'
alias l='eza --classify --color=always --color-scale --group-directories-first --icons --long --header --git --all'

# Enhanced navigation (can override plugin versions)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias cd..='cd ..'
alias cd...='cd ../..'

# File operations with safety
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias ln='ln -i'

# Enhanced grep with colors
alias grep='grep --color=always'
alias egrep='egrep --color=always'
alias fgrep='fgrep --color=always'

## [ui-enhancements.development] - Development workflow aliases
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
alias gba='git branch --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'

# Docker aliases (enhance plugin versions)
if command -v docker >/dev/null 2>&1; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias drmi='docker rmi'
    alias drm='docker rm'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'
fi

# Kubernetes aliases (enhance plugin versions)
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kdp='kubectl describe pod'
    alias kds='kubectl describe service'
    alias kdd='kubectl describe deployment'
    alias kaf='kubectl apply -f'
    alias kdf='kubectl delete -f'
fi

## [ui-enhancements.productivity] - Productivity enhancement aliases
# Quick editing
alias e='$EDITOR'
alias v='nvim'
alias vim='nvim'
alias vi='nvim'

# System information
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n" | sort'
alias fpath='echo $fpath | tr " " "\n" | sort'
alias h='history'
alias hg='history | grep'
alias ps='ps aux'
alias psg='ps aux | grep'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias ports='netstat -tuln'

# Quick directories
alias home='cd ~'
alias desktop='cd ~/Desktop'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'
alias projects='cd ~/Projects'
alias dotfiles='cd ~/dotfiles'

## [ui-enhancements.macos-specific] - macOS-specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS system aliases
    alias flush='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
    alias show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    alias spotlight='sudo mdutil -i on / && sudo mdutil -E /'
    alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

    # Homebrew aliases - Force ARM homebrew on Apple Silicon
    if [[ "$(/usr/bin/uname -m)" == "arm64" ]] && [[ -x "/opt/homebrew/bin/brew" ]]; then
        # On Apple Silicon, always use ARM homebrew
        alias brew='/opt/homebrew/bin/brew'
    fi
    
    if command -v brew >/dev/null 2>&1; then
        alias br='brew'
        alias bri='brew install'
        alias bru='brew uninstall'
        alias brs='brew search'
        alias brinfo='brew info'
        alias brup='brew update && brew upgrade'
        alias brclean='brew cleanup'
    fi

    # Quick app launches
    alias finder='open -a Finder'
    alias safari='open -a Safari'
    alias chrome='open -a "Google Chrome"'
    alias code='open -a "Visual Studio Code"'
fi

## [ui-enhancements.keybindings] - Enhanced keybindings after plugins load
# Plugin-aware keybindings that work with loaded plugins

# History search (works with history-substring-search plugin if loaded)
if command -v history-substring-search-up >/dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up      # Up arrow
    bindkey '^[[B' history-substring-search-down    # Down arrow
    bindkey '^P' history-substring-search-up        # Ctrl+P
    bindkey '^N' history-substring-search-down      # Ctrl+N
else
    # Fallback to standard history search
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
bindkey '^_' undo                          # Ctrl+_

# Word navigation
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^[[H' beginning-of-line           # Home
bindkey '^[[F' end-of-line                 # End

## [ui-enhancements.functions] - Enhanced utility functions
# DISABLED: Custom functions that wrap/override system commands can cause conflicts
# These functions are commented out to prevent interference with system commands
# and plugin functionality. Use the original system commands or plugin-provided alternatives.

# DISABLED: Smart cd with automatic ls (renamed to avoid conflicts)
# Use 'cds' instead of overriding 'cd'
# cds() {
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

# DISABLED: Process finding and killing
# psgrep() {
#     ps aux | grep -v grep | grep "$1"
# }

# DISABLED: Process killing helper
# killps() {
#     local pid
#     pid=$(ps aux | grep -v grep | grep "$1" | awk '{print $2}')
#     if [[ -n "$pid" ]]; then
#         echo "Killing process $pid"
#         kill "$pid"
#     else
#         echo "No process found matching: $1"
#     fi
# }

# DISABLED: Extract various archive formats (many plugins provide this)
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
# typeset -gf cds mkcd ff fd psgrep killps extract

# NOTE: No custom command wrappers are defined in this configuration.
# Use the original system commands, installed tools (fd, fzf, eza, etc.),
# or plugin-provided alternatives instead.

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

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [ui-enhancements] ✅ User interface and experience enhancements configured" >&2
