#!/usr/bin/env zsh
# 430-navigation-tools.zsh
#
# Purpose:
#   Configures and initializes modern navigation tools like `zoxide` and `fzf`
#   to enhance shell productivity.
#
# Features:
#   - `zoxide`: Initializes the smart `cd` command.
#   - `fzf`: Sets up keybindings (Ctrl-T, Ctrl-R, Alt-C) and fuzzy completions.
#   - Configurable `FZF_DEFAULT_OPTS` for a consistent look and feel.
#
# Toggles:
#   - `ZF_DISABLE_NAVIGATION=1`: Disables zoxide integration.
#   - `ZF_DISABLE_FZF=1`: Disables fzf integration.

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- zoxide ---
if [[ "${ZF_DISABLE_NAVIGATION:-0}" != 1 ]] && command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  zf::debug "# [nav] zoxide initialized"
fi

# --- fzf ---
if [[ "${ZF_DISABLE_FZF:-0}" != 1 ]] && [[ -z "${_ZF_PM_FZF_LOADED:-}" ]]; then
  # Set default options
  : ${FZF_DEFAULT_OPTS:="--height 40% --border"}
  export FZF_DEFAULT_OPTS

  # Source key bindings and completions from standard locations
  for _fzf_base in "${HOME}/.fzf" "/opt/homebrew/opt/fzf"; do
    if [[ -d "${_fzf_base}" ]]; then
      [[ -r "${_fzf_base}/shell/completion.zsh" ]] && source "${_fzf_base}/shell/completion.zsh"
      [[ -r "${_fzf_base}/shell/key-bindings.zsh" ]] && source "${_fzf_base}/shell/key-bindings.zsh"
      zf::debug "# [nav] fzf integration sourced from ${_fzf_base}"
      break
    fi
  done
  unset _fzf_base
fi

return 0
