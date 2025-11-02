#!/usr/bin/env zsh
# Filename: 480-history.zsh
# Purpose:  Configures and enhances shell history, with optional integration for `atuin` for a more powerful, synchronized history experience. Features: - Sets modern Zsh history options (`APPEND_HISTORY`, `SHARE_HISTORY`, etc.). - Integrates `atuin` if installed, enabling synchronized, searchable history. - Automatically starts the `atuin` daemon in the background. - Enables `atuin` keybindings by default (Ctrl-R for search). Toggles: - `ZF_DISABLE_HISTORY_ENHANCE=1`: Disables this entire module. - `ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1`: Disables `atuin` keybindings.
# Phase:    Post-plugin (.zshrc.d/)
# Toggles:  ZF_DISABLE_HISTORY_ENHANCE

if [[ "${ZF_DISABLE_HISTORY_ENHANCE:-0}" == 1 ]]; then
  return 0
fi

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Atuin Integration ---
if command -v atuin >/dev/null 2>&1; then
  # Start atuin daemon if not already running
  if [[ $- == *i* ]] && ! pgrep -f "atuin daemon" >/dev/null 2>&1; then
    atuin daemon --disable-up-arrow &> /dev/null &
    disown
    zf::debug "# [history] Atuin daemon started"
  fi

  # Initialize atuin
  if [[ "${ZF_HISTORY_ATUIN_DISABLE_KEYBINDS:-0}" == 1 ]]; then
    eval "$(atuin init zsh --disable-up-arrow)"
    export _ZF_ATUIN_KEYBINDS=0
    zf::debug "# [history] Atuin initialized (keybinds disabled)"
  else
    eval "$(atuin init zsh)"
    export _ZF_ATUIN_KEYBINDS=1
    zf::debug "# [history] Atuin initialized (keybinds enabled)"
  fi
  export _ZF_ATUIN=1
fi

return 0
