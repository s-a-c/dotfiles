#!/usr/bin/env zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Provide a stub for the deprecated _expand_alias widget if referenced by plugins.

# Only register widget if ZLE is properly initialized and interactive
if [[ -o interactive ]] && zmodload -i zsh/zle 2>/dev/null; then
  if ! zle -l 2>/dev/null | command grep -q '^_expand_alias$' 2>/dev/null; then
    _expand_alias() {
      zle expand-or-complete 2>/dev/null || true
    }
    # Register widget with error handling
    if typeset -f _expand_alias >/dev/null 2>&1; then
      zle -N _expand_alias 2>/dev/null || true
      [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[WIDGET][stub] _expand_alias provided" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
  fi
fi
