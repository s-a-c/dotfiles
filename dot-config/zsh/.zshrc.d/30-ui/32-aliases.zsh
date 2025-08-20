# Aliases Configuration - Essential shortcuts and improvements
# This file provides useful aliases without impacting performance
# Load time target: <30ms

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    # Add this check to detect errant file creation:
    if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
        echo "Warning: Numbered files detected - check for redirection typos" >&2
    fi
}

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
if command_exists gh; then
    eval "$(gh copilot alias -- zsh)"
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
alias path='echo -e ${PATH//:/\\n}'
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

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [30-ui] Aliases configured" >&2
