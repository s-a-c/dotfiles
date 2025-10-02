#!/usr/bin/env zsh
# -----------------------------------------------------------------------------
# 15-fsh-rebind-and-starship-guard.zsh (Post-Plugin stage)
# - Rebind fast-syntax-highlighting after all widgets exist to avoid spam
# - Ensure STARSHIP_CMD_STATUS and STARSHIP_PIPE_STATUS are always defined
#   and seed them FIRST in precmd stack to stop "parameter not set" errors
# -----------------------------------------------------------------------------

# Idempotency guard
if [[ -n "${_ZQS_POSTPLUGIN_FSH_STARSHIP_GUARD:-}" ]]; then
  return 0
fi
export _ZQS_POSTPLUGIN_FSH_STARSHIP_GUARD=1

# ---------- Starship variable seeder (first in precmd) ----------
_zqs__seed_starship_vars_precmd() {
  typeset -gi STARSHIP_CMD_STATUS 2>/dev/null || true
  STARSHIP_CMD_STATUS=${STARSHIP_CMD_STATUS:-0}
  typeset -ga STARSHIP_PIPE_STATUS 2>/dev/null || true
  : ${STARSHIP_PIPE_STATUS:=()}
}

# Prepend our seeder to precmd_functions (idempotent)
if (( ${+precmd_functions} )); then
  # Remove any existing occurrence
  local -a _pf
  for _f in "${precmd_functions[@]}"; do
    [[ "$_f" == "_zqs__seed_starship_vars_precmd" ]] || _pf+=("$_f")
  done
  precmd_functions=( _zqs__seed_starship_vars_precmd ${_pf[@]} )
  unset _pf _f
else
  precmd_functions=( _zqs__seed_starship_vars_precmd )
fi

# ---------- Rebind fast-syntax-highlighting widgets after plugins ----------
# Only if plugin was loaded and we planned a rebind.
if [[ -n "${ZSH_FSH_REBIND_LATER:-}" ]] && typeset -f _zsh_highlight_bind_widgets >/dev/null 2>&1; then
  # Ensure needed module is available; suppress any noise
  zmodload zsh/zleparameter 2>/dev/null || true
  # Rebind now; silence stdout, send errors to a log for debugging only
  : ${ZSH_LOG_DIR:=${ZDOTDIR:-$HOME}/logs}
  mkdir -p -- "$ZSH_LOG_DIR" 2>/dev/null || true
  { _zsh_highlight_bind_widgets } > /dev/null 2>>"$ZSH_LOG_DIR/fsh-rebind.log" || true
fi

# End of file

