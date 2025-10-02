#!/usr/bin/env zsh
# Robust, idempotent keybindings and ZLE widget definitions
# - Provides safe fallbacks when plugins are absent
# - Ensures widgets exist before binding
# - Keeps bindings compatible with highlighters (load wrappers, not raw names)

# Prevent double-load
if [[ -n ${_ZQS_KEYBINDINGS_LOADED:-} ]]; then
  return 0
fi
export _ZQS_KEYBINDINGS_LOADED=1

# Choose emacs-style by default (can be overridden by user later)
bindkey -e 2>/dev/null || true

# ---------- Helpers ----------
# Ensure a widget exists that calls a function, defining the function if needed
_zqs_define_widget() {
  local wname=$1; shift
  local body=$*
  if ! typeset -f -- "$wname" >/dev/null 2>&1; then
    eval "$wname() { $body }" 2>/dev/null || return 0
  fi
  zle -N "$wname" 2>/dev/null || true
}

# Try to autoload completion helpers used by some widgets
autoload -Uz _expand_alias expand-word 2>/dev/null || true

# ---------- History navigation widgets ----------
# Prefer history-substring-search if present; otherwise use up/down-line-or-history
if typeset -f history-substring-search-up >/dev/null 2>&1; then
  zle -N history-substring-search-up 2>/dev/null || true
  zle -N history-substring-search-down 2>/dev/null || true
  bindkey "$terminfo[kcuu1]" history-substring-search-up 2>/dev/null || true
  bindkey "$terminfo[kcud1]" history-substring-search-down 2>/dev/null || true
else
  bindkey "$terminfo[kcuu1]" up-line-or-history 2>/dev/null || true
  bindkey "$terminfo[kcud1]" down-line-or-history 2>/dev/null || true
fi

# Provide compatibility wrappers for names some themes/plugins expect
_zqs_define_widget up-line-or-beginning-search 'zle up-line-or-history'
_zqs_define_widget down-line-or-beginning-search 'zle down-line-or-history'

# ---------- Global alias expansion on Space ----------
# Define a safe globalias that falls back cleanly if helper functions are missing
_zqs_define_widget globalias '
  # Only expand if buffer ends with space + ALLCAPS token (OMZ convention)
  if [[ $LBUFFER =~ " [A-Z0-9]+$" ]]; then
    zle _expand_alias 2>/dev/null || true
    zle expand-word 2>/dev/null || true
  fi
  zle self-insert
'

# Bind Space to globalias; Ctrl-Space to magic-space; ensure search map stays usable
bindkey ' ' globalias 2>/dev/null || true
bindkey '^ ' magic-space 2>/dev/null || true
bindkey -M isearch ' ' magic-space 2>/dev/null || true

# ---------- Quality-of-life bindings ----------
# Edit current line in $EDITOR
_zqs_define_widget edit-command-line 'emulate -L zsh; [[ -n ${EDITOR:-} ]] || local EDITOR=vi; zle .edit-command-line'
bindkey '^X^E' edit-command-line 2>/dev/null || true

# Fallbacks for common navigation
bindkey '^P' up-line-or-history 2>/dev/null || true
bindkey '^N' down-line-or-history 2>/dev/null || true
bindkey '^A' beginning-of-line 2>/dev/null || true
bindkey '^E' end-of-line 2>/dev/null || true

# ---------- FZF safety fallbacks ----------
# Provide harmless fallbacks when fzf widgets are absent
if [[ -z "${widgets[fzf-completion]:-}" ]]; then
  _zqs__fallback_expand_or_complete() { zle expand-or-complete; }
  zle -N fzf-completion _zqs__fallback_expand_or_complete 2>/dev/null || true
fi
if [[ -z "${widgets[fzf-file-widget]:-}" ]]; then
  _zqs__fallback_fzf_file_widget() { zle push-input; }
  zle -N fzf-file-widget _zqs__fallback_fzf_file_widget 2>/dev/null || true
fi
if [[ -z "${widgets[fzf-history-widget]:-}" ]]; then
  _zqs__fallback_fzf_history_widget() { zle up-line-or-history; }
  zle -N fzf-history-widget _zqs__fallback_fzf_history_widget 2>/dev/null || true
fi
if [[ -z "${widgets[fzf-cd-widget]:-}" ]]; then
  _zqs__fallback_fzf_cd_widget() { zle backward-kill-word; }
  zle -N fzf-cd-widget _zqs__fallback_fzf_cd_widget 2>/dev/null || true
fi

# Keep Right arrow usable even with autosuggestions
bindkey '^[^[[C' forward-word 2>/dev/null || true

# Done

