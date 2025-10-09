#!/usr/bin/env zsh
# Deprecated Starship wrapper (shim)
## This wrapper is deprecated. Use unified 520-prompt-starship.zsh directly.
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Delegate to unified implementation without altering autoinit semantics
if [[ -r ${ZDOTDIR:-$HOME}/.zshrc.d.00/520-prompt-starship.zsh ]]; then
  source ${ZDOTDIR:-$HOME}/.zshrc.d.00/520-prompt-starship.zsh
else
  zf::debug "# [starship-wrapper] unified prompt file missing at ${ZDOTDIR:-$HOME}/.zshrc.d.00/520-prompt-starship.zsh"
fi

zf::debug "# [starship-wrapper] deprecated wrapper sourced (no suppression applied)"

return 0
