#!/usr/bin/env zsh
# Final defensive guard for STARSHIP variables (REDESIGN)
# Loaded late to reassert presence if any plugin unset them.
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}

_zqs__final_starship_precmd_guard() {
  if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
  if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
}
if (( ! ${precmd_functions[(I)_zqs__final_starship_precmd_guard]} )); then
  precmd_functions+=( _zqs__final_starship_precmd_guard )
fi
