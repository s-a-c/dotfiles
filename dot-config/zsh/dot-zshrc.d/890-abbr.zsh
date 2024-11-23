## [abbr]
abbr >| "${ZDOTDIR}/saved_abbr.zsh"

abbr "cd"="z"
abbr "eza"="eza --classify --color=always --color-scale --group-directories-first --hyperlink --icons"
abbr -g --quiet "g"="git"
abbr import-git-aliases -g --quiet --prefix "git "
abbr import-aliases --quiet
## [abbr.alias-unset]
unalias -m '*'
