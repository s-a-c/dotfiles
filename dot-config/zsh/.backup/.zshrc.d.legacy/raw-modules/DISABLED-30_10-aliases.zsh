#!/usr/bin/env zsh
# Aliases Configuration - Essential shortcuts and 030-improvements
# This file provides useful aliases without impacting performance
# Load time target: <30ms

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        zf::debug "Warning: Numbered files detected - check for redirection typos"
    fi
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
alias path='zf::debug $PATH | tr ":" "\n" | sort'
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
alias path='zf::debug $PATH | tr ":" "\n" | sort'
alias fpath='zf::debug $fpath | tr " " "\n" | sort'
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

# Essential navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~="cd ~"
alias -- -="cd -"

# Advanced navigation with zoxide integration
if command_exists z; then
    alias cd='z'
    alias 1='cd -1'
    alias 2='cd -2'
    alias 3='cd -3'
    alias 4='cd -4'
    alias 5='cd -5'
    alias 6='cd -6'
    alias 7='cd -7'
    alias 8='cd -8'
    alias 9='cd -9'
fi

# Directory listing aliases (check for modern alternatives)
if command_exists eza; then
    # Base eza with consistent styling
    alias eza='eza --classify --color=always --color-scale --group-directories-first --hyperlink --icons'

    # Basic listings
    alias l='eza'                                    # Simple list
    alias ls='eza --git'                            # List with git status
    alias la='eza --git --all'                      # List all with git status
    alias ll='eza --long --header --git --all'      # Long format with all files

    # Date sorting
    alias lD='eza --long --header --git --sort=date'
    alias lDa='eza --long --header --git --sort=date --all'
    alias lDr='eza --long --header --git --sort=date --reverse'
    alias lDra='eza --long --header --git --sort=date --reverse --all'

    # Size sorting
    alias lS='eza --long --header --git --sort=size'
    alias lSa='eza --long --header --git --sort=size --all'
    alias lSr='eza --long --header --git --sort=size --reverse'
    alias lSra='eza --long --header --git --sort=size --reverse --all'

    # Type sorting
    alias lT='eza --long --header --git --sort=type'
    alias lTa='eza --long --header --git --sort=type --all'
    alias lTr='eza --long --header --git --sort=type --reverse'
    alias lTra='eza --long --header --git --sort=type --reverse --all'

    # Extension sorting
    alias lx='eza --long --header --git --sort=extension'
    alias lxa='eza --long --header --git --sort=extension --all'
    alias lX='eza --long --header --git --sort=extension --reverse'
    alias lXa='eza --long --header --git --sort=extension --reverse --all'

    # Unsorted (filesystem order)
    alias lU='eza --long --header --git --sort=none'
    alias lUa='eza --long --header --git --sort=none --all'
    alias lUr='eza --long --header --git --sort=none --reverse'
    alias lUra='eza --long --header --git --sort=none --reverse --all'

    # Tree listings
    alias lt='eza --long --header --git --tree'
    alias lta='eza --long --header --git --tree --all'
    alias ltr='eza --long --header --git --tree --reverse'
    alias ltra='eza --long --header --git --tree --reverse --all'
    alias treea='eza --long --header --git --tree --all'
elif command_exists exa; then
    alias ls='exa --color=auto --group-directories-first'
    alias ll='exa -l --color=auto --group-directories-first'
    alias la='exa -la --color=auto --group-directories-first'
    alias lt='exa -T --color=auto --group-directories-first'
    alias l='exa -la --color=auto --group-directories-first'
else
    # Fallback to traditional ls with colors
    if [[ "$OSTYPE" == "darwin"* ]]; then
        alias ls='ls -G'
        alias ll='ls -lG'
        alias la='ls -laG'
    else
        alias ls='ls --color=auto'
        alias ll='ls -l --color=auto'
        alias la='ls -la --color=auto'
    fi
    alias l='la'
fi

# File operations (safe defaults)
alias cp='cp -i'    # Interactive copy
alias ln='ln -i'    # Interactive link
alias mv='mv -i'    # Interactive move
alias mkdir='mkdir -p'  # Create parent directories
alias md='mkdir -p'     # Short form

# File removal (with trash-cli integration)
if command_exists trash-put; then
    alias rm='trash-put'
    alias trash='trash-put'
else
    alias rm='rm -i'    # Interactive remove
fi

# System utilities with modern alternatives
alias grep='grep --color'
alias ip='ip --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias less='less -R'
alias diff='diff --color=auto'

# Process management
alias ps='ps aux'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias pgrep='pgrep -f'
alias topc='top -o cpu'
alias topm='top -o vsize'

# Network utilities
alias ping='ping -c 5'
alias wget='wget -c'

# Modern alternatives
if command_exists bat; then
    alias cat='bat --paging=never --style=plain'
    # alias man=batman  # Commented out - man is excluded from aliasing
    alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
elif command_exists batcat; then
    alias cat='batcat --paging=never --style=plain'
    alias less='batcat --paging=always'
fi

if command_exists fd; then
    alias find='fd'
fi

if command_exists rg; then
    alias grep='rg'
elif command_exists ag; then
    alias grep='ag'
fi

# Git aliases (if git is available)
if command_exists git; then
    alias g='git'
    alias ga='git add'
    alias gaa='git add --all'
    alias gb='git branch'
    alias gc='git commit -v'
    alias gca='git commit -v -a'
    alias gcm='git commit -m'
    alias gco='git checkout'
    alias gd='git diff'
    alias gf='git fetch'
    alias gl='git pull'
    alias gp='git push'
    alias gs='git status'
    alias gst='git status'
    alias glg='git log --oneline --graph --decorate'
fi

# GitHub Copilot CLI integration
# LAZY LOADED: Now handled by ~/.config/zsh/.zshrc.pre-plugins.d/06-lazy-gh-copilot.zsh
# GitHub Copilot aliases (ghcs, ghce) are loaded only when first used
if command_exists gh; then
    zf::debug "# [gh-copilot] Lazy loading enabled (see 06-lazy-gh-copilot.zsh)"
fi

# Development aliases
if command_exists code; then
    alias c='code'
    alias code.='code .'
fi
if command_exists code-insiders; then
    alias c-i='code-insiders'
    alias c-i.='code-insiders .'
fi

# Neovim configurations and alternatives
if command_exists nvim; then
    unalias bob 2>/dev/null || true
    # Use nvimvenv if available, otherwise fallback to nvim
    if command_exists nvimvenv; then
        alias nvim='nvimvenv'
    fi
    alias vim='nvim'
    alias vi='nvim'
    alias ksnvim='NVIM_APPNAME=nvim-Kickstart nvim'
    alias lmnvim='NVIM_APPNAME=nvim-Lazyman nvim'
    alias lznvim='NVIM_APPNAME=nvim-Lazyvim nvim'
    alias minvim='NVIM_APPNAME=nvim-Mini nvim'
    alias nvnvim='NVIM_APPNAME=nvim-NvChad nvim'
    alias rlnvim='NVIM_APPNAME=nvim-RadleyLewis nvim'
    alias scnvim='NVIM_APPNAME=nvim-Sin-Cy nvim'
elif command_exists vim; then
    alias vim='/run/current-system/sw/bin/vim'
    alias vi='/run/current-system/sw/bin/vim'
fi

# Package management (macOS Homebrew)
if command_exists brew; then
    alias brewup='brew update && brew upgrade && brew cleanup'
    alias brewinfo='brew leaves | xargs brew desc --eval-all'

    # Extended brew aliases
    alias ba='brew autoremove'
    alias bci='brew info --cask'
    alias bcin='brew install --cask'
    alias bcl='brew list --cask'
    alias bcn='brew cleanup'
    alias bco='brew outdated --cask'
    alias bcrin='brew reinstall --cask'
    alias bcubc='brew upgrade --cask && brew cleanup'
    alias bcubo='brew update && brew outdated --cask'
    alias bcup='brew upgrade --cask'
    alias bfu='brew upgrade --formula'
    alias bi='brew install'
    alias bl='brew list'
    alias bo='brew outdated'
    alias brewp='brew pin'
    alias brewsp='brew list --pinned'
    alias bsl='brew services list'
    alias bsoff='brew services stop'
    alias bsoffa='brew services stop --all'
    alias bson='brew services start'
    alias bsr='brew services run'
    alias bu='brew update'
    alias bubc='brew upgrade && brew cleanup'
    alias bubo='brew update && brew outdated'
    alias bubu='brew update && brew outdated && brew upgrade && brew cleanup'
    alias bubug='brew update && brew outdated && brew upgrade --greedy && brew cleanup'
    alias bugbc='brew upgrade --greedy && brew cleanup'
    alias bup='brew upgrade'
    alias buz='brew uninstall --zap'
fi

# Docker aliases (if docker available)
if command_exists docker; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpa='docker ps -a'
    alias di='docker images'
    alias drm='docker rm'
    alias drmi='docker rmi'
fi

# Desk workspace management
if command_exists desk; then
    alias d..='desk ..'
    alias d.='desk .'
    alias d='desk'
fi

# PHP development aliases
if command_exists php; then
    alias partisan='php artisan'
    alias phart='php artisan'
    alias tinker='php tinker'
fi

# History management
alias disablehistory='function zshaddhistory() {  return 1 }'
alias enablehistory='unset -f zshaddhistory'
alias h='history'

# System information
alias j='jobs -l'
alias path='zf::debug -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'

# Quick config access
alias zshconfig='"$EDITOR" "$ZDOTDIR/zsh_zshrc.zsh"'
alias zshreload='source "$ZDOTDIR/zsh_zshrc.zsh"'

# System shortcuts
alias reload='exec $SHELL'
alias cls='clear'
alias c='clear'

# Performance monitoring
alias zshbench='for i in $(seq 1 10); do time $SHELL -i -c exit; done'

zf::debug "# [30-ui] Aliases configured"
