#!/usr/bin/env zsh
# Diagnostic helper: debug-starship-status.zsh
# Prints current values of STARSHIP_CMD_* variables & pipe status safely.
# Usage: source this file then run: debug_starship_status

if ! typeset -f debug_starship_status >/dev/null 2>&1; then
  debug_starship_status() {
    emulate -L zsh
    setopt no_unset
    local v
    local -a vars=(
      STARSHIP_CMD_STATUS STARSHIP_DURATION_MS STARSHIP_CMD_EXIT_REASON
      STARSHIP_CMD_START_TIME STARSHIP_CMD_END_TIME STARSHIP_CMD_BG
      STARSHIP_CMD_JOBS STARSHIP_CMD_PIPESTATUS STARSHIP_CMD_SIG
      STARSHIP_CMD_ERR STARSHIP_CMD_ERRMSG STARSHIP_CMD_ERRNO
      STARSHIP_CMD_ERRCODE STARSHIP_CMD_ERRCTX STARSHIP_CMD_ERRFUNC
      STARSHIP_CMD_ERRLINE STARSHIP_CMD_ERRFILE
    )
    printf '--- Starship Status Diagnostics ---\n'
    for v in ${vars[@]}; do
      if (( ${+parameters[$v]} )); then
        printf '%-24s = %q\n' "$v" "${(P)v}"
      else
        printf '%-24s = <UNSET>\n' "$v"
      fi
    done
    if (( ${+STARSHIP_PIPE_STATUS} )); then
      printf '%-24s = (%s)\n' STARSHIP_PIPE_STATUS "${STARSHIP_PIPE_STATUS[@]}"
    fi
    printf '-----------------------------------\n'
  }
fi

# Auto-run when ZSH_DEBUG=1 & interactive
if [[ -o interactive && ${ZSH_DEBUG:-0} == 1 ]]; then
  debug_starship_status 2>/dev/null || true
fi
