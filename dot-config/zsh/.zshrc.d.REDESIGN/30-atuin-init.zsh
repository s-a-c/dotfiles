#!/usr/bin/env zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Atuin integration (enhanced history search & sync)
# Load Order: ~30 (after basic tool env, before prompt & git UI specifics)

[[ -n ${_ZQS_ATUIN_INIT_LOADED:-} ]] && return 0
_ZQS_ATUIN_INIT_LOADED=1
[[ $- != *i* ]] && return 0

if ! command -v atuin >/dev/null 2>&1; then
  [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[ATUIN][skip] binary not found" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  return 0
fi

autoload -U add-zsh-hook
zmodload zsh/datetime 2>/dev/null || true

_zsh_autosuggest_strategy_atuin() { suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --limit 1 --search-mode prefix 2>/dev/null); }
if (( ${+ZSH_AUTOSUGGEST_STRATEGY} )); then
  ZSH_AUTOSUGGEST_STRATEGY=(atuin "${ZSH_AUTOSUGGEST_STRATEGY[@]}")
else
  ZSH_AUTOSUGGEST_STRATEGY=(atuin)
fi

export ATUIN_SESSION=$(atuin uuid 2>/dev/null)
ATUIN_HISTORY_ID=""

_atuin_preexec() {
  local id
  id=$(atuin history start -- "$1" 2>/dev/null)
  ATUIN_HISTORY_ID="$id"
  __atuin_preexec_time=${EPOCHREALTIME-}
}
_atuin_precmd() {
  local EXIT=$? __atuin_precmd_time=${EPOCHREALTIME-}
  [[ -z ${ATUIN_HISTORY_ID:-} ]] && return 0
  local duration=""
  if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
    printf -v duration %.0f $(( ( __atuin_precmd_time - __atuin_preexec_time ) * 1000000000 ))
  fi
  (ATUIN_LOG=error atuin history end --exit $EXIT ${duration:+--duration=$duration} -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
  ATUIN_HISTORY_ID=""
}
add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd  _atuin_precmd

_atuin_search() {
  emulate -L zsh
  zle -I
  local output
  output=$(ATUIN_SHELL_ZSH=t ATUIN_LOG=error ATUIN_QUERY=$BUFFER atuin search -i 3>&1 1>&2 2>&3)
  zle reset-prompt
  if [[ -n $output ]]; then
    RBUFFER=""; LBUFFER=$output
    if [[ $LBUFFER == __atuin_accept__:* ]]; then
      LBUFFER=${LBUFFER#__atuin_accept__:}; zle accept-line
    fi
  fi
}
_atuin_search_vicmd() { _atuin_search --keymap-mode=vim-normal; }
_atuin_search_viins() { _atuin_search --keymap-mode=vim-insert; }

_atuin_up_search() {
  if [[ $BUFFER != *$'\n'* ]]; then _atuin_search --shell-up-key-binding "$@"; else zle up-line; fi
}
_atuin_up_search_vicmd() { _atuin_up_search --keymap-mode=vim-normal; }
_atuin_up_search_viins() { _atuin_up_search --keymap-mode=vim-insert; }

zle -N atuin-search _atuin_search
zle -N atuin-search-vicmd _atuin_search_vicmd
zle -N atuin-search-viins _atuin_search_viins
zle -N atuin-up-search _atuin_up_search
zle -N atuin-up-search-vicmd _atuin_up_search_vicmd
zle -N atuin-up-search-viins _atuin_up_search_viins
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

bindkey -M emacs '^[[A'  atuin-up-search
bindkey -M vicmd '^[[A'  atuin-up-search-vicmd
bindkey -M viins '^[[A'  atuin-up-search-viins
bindkey -M emacs '^[OA'  atuin-up-search
bindkey -M vicmd '^[OA'  atuin-up-search-vicmd
bindkey -M viins '^[OA'  atuin-up-search-viins
bindkey -M vicmd 'k'     atuin-up-search-vicmd

[[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[ATUIN][init] integration active session=$ATUIN_SESSION" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
