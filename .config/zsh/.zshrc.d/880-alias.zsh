## [alias]
## [alias.save]
alias -L >| "${ZDOTDIR}/saved_alias.zsh"

## [alias.bat]
alias -g bathelp='bat --plain --language=help'
function help() {
  "$@" --help 2>&1 | bathelp
}
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
alias man=batman

## [alias.cd]
alias cd='z'
alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

## [alias.brew]
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

## [alias.eza]
alias eza='eza --classify --color=always --color-scale --group-directories-first --hyperlink --icons'
alias l='eza'
alias la='eza --git --all'
alias lD='eza --long --header --git --sort=date'
alias lDa='eza --long --header --git --sort=date --all'
alias lDr='eza --long --header --git --sort=date --reverse'
alias lDra='eza --long --header --git --sort=date --reverse --all'
alias ll='eza --long --header --git --all --level=2'
alias lR='eza --long --header --git --sort=reverse'
alias lRa='eza --long --header --git --sort=reverse --all'
alias lRr='eza --long --header --git --sort=reverse --reverse'
alias lRra='eza --long --header --git --sort=reverse --reverse --all'
alias ls='eza --git'
alias lS='eza --long --header --git --sort=size'
alias lSa='eza --long --header --git --sort=size --all'
alias lSr='eza --long --header --git --sort=size --reverse'
alias lSra='eza --long --header --git --sort=size --reverse --all'
alias lT='eza --long --header --git --sort=type'
alias lt='eza --long --header --git --tree'
alias lTa='eza --long --header --git --sort=type --all'
alias lta='eza --long --header --git --tree --all'
alias lTr='eza --long --header --git --sort=type --reverse'
alias ltr='eza --long --header --git --tree --reverse'
alias lTra='eza --long --header --git --sort=type --reverse --all'
alias ltra='eza --long --header --git --tree --reverse --all'
alias lU='eza --long --header --git --sort=none'
alias lUa='eza --long --header --git --sort=none --all'
alias lUr='eza --long --header --git --sort=none --reverse'
alias lUra='eza --long --header --git --sort=none --reverse --all'
alias lX='eza --long --header --git --sort=extension --reverse'
alias lx='eza --long --header --git --sort=extension'
alias lxa='eza --long --header --git --sort=extension --all'
alias lXa='eza --long --header --git --sort=extension --reverse --all'
alias lXr='eza --long --header --git --sort=extension --reverse'
alias lXra='eza --long --header --git --sort=extension --reverse --all'
alias lZ='eza --long --header --git --sort=extension'
alias lz='eza --long --header --git --sort=extension --reverse'
alias lza='eza --long --header --git --sort=extension --all'
alias lZa='eza --long --header --git --sort=extension --reverse --all'
alias lZr='eza --long --header --git --sort=extension --reverse'
alias lZra='eza --long --header --git --sort=extension --reverse --all'
alias tree='eza --long --header --git --tree'
alias treea='eza --long --header --git --tree --all'

## [alias.history]
alias disablehistory="function zshaddhistory() {  return 1 }"
alias enablehistory="unset -f zshaddhistory"

## [alias.nvim]
alias lmvim="NVIM_APPNAME=nvim-Lazyman nvim"
alias ksvim="NVIM_APPNAME=nvim-Kickstart nvim"

## [alias.trash-cli]
alias rm='echo "This is not the command you are looking for."; false'
alias trash='trash-put'

## [alias.vim]
alias vim="/run/current-system/sw/bin/vim"
alias vi="/run/current-system/sw/bin/vim"

## [alias.unset]
#unalias -m '*'
## [alias.load]
#source ${ZDOTDIR}/saved_aliases.zsh
