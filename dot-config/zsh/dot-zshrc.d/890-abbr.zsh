## [abbr]
## [abbr.save_begin]
abbr >|"${ZDOTDIR}/saved_abbr_begin.zsh"

abbr cd=z
abbr -g --quiet g="git"
abbr import-git-aliases -g --quiet --prefix "git "
abbr import-aliases --quiet

## [abbr.save_end]
abbr >|"${ZDOTDIR}/saved_abbr_end.zsh"

## [abbr.alias-unset]
unalias -m '*'
