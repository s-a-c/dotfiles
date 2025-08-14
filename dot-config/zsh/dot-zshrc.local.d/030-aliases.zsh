## [alias]
## [alias.save_begin]
#alias -L >|"${ZDOTDIR}/saved_alias_begin.zsh"

unset ZSH_DEBUG

[[ -n "$ZSH_DEBUG" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

## [aliases.default]
{
    alias grep='grep --color'
    alias ip='ip --color=auto'

    ## Safe file operations
    alias cp='cp -i'
    alias ln='ln -i'
    alias mv='mv -i'
    alias rm='rm -i'

    ## Directory navigation
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'

    ## List directory contents
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

    ## System information
    alias df='df -h'
    alias du='du -h'
    alias free='free -h'

    ## Process management
    alias ps='ps aux'
    alias pgrep='pgrep -f'

    ## Network
    alias ping='ping -c 5'
    alias wget='wget -c'

    ## Text processing
    alias less='less -R'
    alias diff='diff --color=auto'
}

## [aliases.bat]
{
    #alias -g bathelp='bat --plain --language=help'
    #alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
    alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
    alias man=batman
}

## [alias.cd]
{
    alias cd='z'
    alias -- -='cd -'
    alias '..'='cd ../..'
    alias '...'='cd ../../..'
    alias '....'='cd ../../../..'
    alias '.....'='cd ../../../../..'
    alias 1='cd -1'
    alias 2='cd -2'
    alias 3='cd -3'
    alias 4='cd -4'
    alias 5='cd -5'
    alias 6='cd -6'
    alias 7='cd -7'
    alias 8='cd -8'
    alias 9='cd -9'
}

## [aliases.brew]
{
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
}

## [aliases.desk]
{
    alias d..='desk ..'
    alias d.='desk .'
    alias d='desk'
}

## [aliases.emacs]
{
    ## Start emacs server
    #alias emacs="$(which emacsclient) -c -a '$(which emacs) --daemon ' &"
}

## [aliases.eza]
{
    # Configure eza (modern ls replacement)
    if command -v eza >/dev/null 2>&1; then
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
    fi
}

## [aliases.github.copilot.cli]
{
    if command -v gh >/dev/null 2>&1; then
        eval "$(gh copilot alias -- zsh)"
    fi
}

## [aliases.history]
{
    alias disablehistory='function zshaddhistory() {  return 1 }'
    alias enablehistory='unset -f zshaddhistory'
}

## [aliases.mkdir]
alias md='mkdir -p'

## [aliases.nvim]
{
    alias nvim=nvimvenv
    alias ksnvim='NVIM_APPNAME=nvim-Kickstart nvim'
    alias lmnvim='NVIM_APPNAME=nvim-Lazyman nvim'
    alias lznvim='NVIM_APPNAME=nvim-Lazyvim nvim'
    alias minvim='NVIM_APPNAME=nvim-Mini nvim'
    alias nvnvim='NVIM_APPNAME=nvim-NvChad nvim'
    alias rlnvim='NVIM_APPNAME=nvim-RadleyLewis nvim'
    alias scnvim='NVIM_APPNAME=nvim-Sin-Cy nvim'
}

## [aliases.php]
{
    alias partisan='php artisan'
    alias phart='php artisan'
    alias tinker='php tinker'
}

## [aliases.trash-cli]
{
    # alias rm='echo "This is not the \`rm\` command you are looking for."; false'
    alias rm='trash-put'
    alias trash='trash-put'
}

## [aliases.vim]
{
    alias vim='/run/current-system/sw/bin/vim'
    alias vi='/run/current-system/sw/bin/vim'
}

## [aliases.save_end]
#alias -L >|"${ZDOTDIR}/saved_alias_end.zsh"
