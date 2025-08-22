zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' cache-path /Users/s-a-c/.config/zsh/.completions/cache
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")'
zstyle :plugin:fast-syntax-highlighting theme q-jmnemonic
zstyle ':completion:*' use-cache on
