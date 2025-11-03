# scratch

```zsh
# CodeQL
if [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/codeql" ]]; then
  zf::path_prepend "${XDG_DATA_HOME:-${HOME}/.local/share}/codeql"
  zf::debug "# [dev-systems] CodeQL configured"
fi
```

```zsh
# Is Starship installed and discoverable?
command -v starship || echo "starship not found"
```

```zsh
# What do the guard flags look like right now?
echo "ZSH_DISABLE_STARSHIP=${ZSH_DISABLE_STARSHIP:-unset} ZSH_STARSHIP_SUPPRESS_AUTOINIT=${ZSH_STARSHIP_SUPPRESS_AUTOINIT:-unset}"
```

```zsh
# Is a Powerlevel10k config present (will cause Starship to defer)?
test -f "${ZDOTDIR:-$HOME}/.p10k.zsh" && echo "p10k config present" || echo "p10k config not found"
```

```zsh
# Was a deferred Starship init hook registered (when p10k exists)?
typeset -f zf::prompt_init_deferred >/dev/null && echo "defer hook present" || echo "defer hook not present"
```

```zsh
# If needed: manually trigger Starship init (safe and idempotent)
typeset -f zf::prompt_init >/dev/null && zf::prompt_init || true
```

```zsh
# Confirm Starship is active after init/defer
echo "STARSHIP_SHELL=${STARSHIP_SHELL:-unset}"
```

```zsh
typeset -f zf::prompt_init_deferred >/dev/null && echo "defer hook present" || echo "defer hook not present"
```

```zsh
typeset -f zf::prompt_init >/dev/null && zf::prompt_init || true
```

```zsh
echo "__ZF_PROMPT_INIT_DONE=${__ZF_PROMPT_INIT_DONE:-unset}  STARSHIP_SHELL=${STARSHIP_SHELL:-unset}"
typeset -f starship_precmd >/dev/null && echo "starship precmd present" || echo "starship precmd not present"
typeset -f zf::prompt_init_deferred >/dev/null && echo "defer hook present" || echo "defer hook not present"
```

```zsh
export ZSH_DEBUG=1 
zf::prompt_init || true
```

```zsh
unset __ZF_PROMPT_INIT_DONE
active_520="${ZDOTDIR:-$HOME}/.zshrc.d/520-prompt-starship.zsh"
source "$active_520"
typeset -f zf::prompt_init_deferred >/dev/null && echo "defer hook present" || echo "defer hook not present"
```
