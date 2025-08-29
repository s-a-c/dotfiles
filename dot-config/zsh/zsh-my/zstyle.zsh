## [zstyle] ## {{{
## [zstyle.documentation]
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzutil-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzstyle-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzsh-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzle-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fcompctl-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fcompwid-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fcomplist-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fcompcore-Module
## - https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fcompctl-Module
## [zstyle.Fuzzy matching of completions]
#compinit
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'
## zstyle.Pretty completions]
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle ':completion:*' use-cache true
zstyle ':completion:*' rehash true
## [zstyle.Do menu-driven completion]
zstyle ':completion:*' menu select
## [zstyle.Color completion for some things]
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
## [zstyle.fzf-tab]
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

#autoload bashcompinit && bashcompinit
#autoload -Uz compinit
## }}}  ## [zstyle]
