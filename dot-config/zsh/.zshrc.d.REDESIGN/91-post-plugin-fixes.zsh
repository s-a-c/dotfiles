# 91-post-plugin-fixes.zsh
# Purpose: Reinforce prompt status variable and keymap setup after plugins load.
# This file is loaded late in the zqs/zgenom startup sequence (post-plugin phase).
#
# Re-seed critical prompt status variables (in case plugins unset or override)
if ! (( ${+STARSHIP_CMD_STATUS}     )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
if ! (( ${+STARSHIP_DURATION_MS}    )); then typeset -gi STARSHIP_DURATION_MS=0; fi
if ! (( ${+STARSHIP_CMD_EXIT_REASON})); then typeset -gi STARSHIP_CMD_EXIT_REASON=0; fi
if ! (( ${+STARSHIP_CMD_START_TIME} )); then typeset -gi STARSHIP_CMD_START_TIME=0; fi
if ! (( ${+STARSHIP_CMD_END_TIME}   )); then typeset -gi STARSHIP_CMD_END_TIME=0; fi
if ! (( ${+STARSHIP_CMD_BG}         )); then typeset -gi STARSHIP_CMD_BG=0; fi
if ! (( ${+STARSHIP_CMD_JOBS}       )); then typeset -gi STARSHIP_CMD_JOBS=0; fi
if ! (( ${+STARSHIP_CMD_PIPESTATUS} )); then typeset -gi STARSHIP_CMD_PIPESTATUS=0; fi
if ! (( ${+STARSHIP_CMD_SIG}        )); then typeset -gi STARSHIP_CMD_SIG=0; fi
if ! (( ${+STARSHIP_CMD_ERR}        )); then typeset -gi STARSHIP_CMD_ERR=0; fi
if ! (( ${+STARSHIP_CMD_ERRNO}      )); then typeset -gi STARSHIP_CMD_ERRNO=0; fi
if ! (( ${+STARSHIP_CMD_ERRCODE}    )); then typeset -gi STARSHIP_CMD_ERRCODE=0; fi
if ! (( ${+STARSHIP_CMD_ERRLINE}    )); then typeset -gi STARSHIP_CMD_ERRLINE=0; fi
if ! (( ${+STARSHIP_CMD_ERRMSG}     )); then typeset -g  STARSHIP_CMD_ERRMSG=""; fi
if ! (( ${+STARSHIP_CMD_ERRCTX}     )); then typeset -g  STARSHIP_CMD_ERRCTX=""; fi
if ! (( ${+STARSHIP_CMD_ERRFUNC}    )); then typeset -g  STARSHIP_CMD_ERRFUNC=""; fi
if ! (( ${+STARSHIP_CMD_ERRFILE}    )); then typeset -g  STARSHIP_CMD_ERRFILE=""; fi

# Re-enforce ZLE widget and keymap setup (in case plugins unset or override)
if [[ -o interactive ]]; then
  zmodload -i zsh/zleparameter 2>/dev/null || true
  # Only (re)declare if parameter truly unset; avoid clobbering if ZLE already owns it
  if ! (( ${+ZLE_WIDGETS} )); then typeset -gA ZLE_WIDGETS; fi
  if ! (( ${+ZLE_KEYMAPS} )); then typeset -gA ZLE_KEYMAPS; fi
  if zmodload -i zsh/zle 2>/dev/null; then
    if [[ -z "${ZSH_FORCE_VI_MODE:-}" ]]; then
      bindkey -e 2>/dev/null || true
    fi

    # Diagnostic & fallback: ensure Right Arrow (ESC [ C) is bound to forward-char.
    # Some plugin/widget interactions (autopair, history search) have been observed
    # to leave it unbound on certain terminals (wezterm, warp) under redesign mode.
    # We'll attempt a small set of common escape sequences for cursor-right.
    local _seq
    local -a _candidate_right=( $'\e[C' $'\eOC' $'^[C' )
    local _have_binding=0
    for _seq in "${_candidate_right[@]}"; do
      if bindkey | grep -F "${_seq}" >/dev/null 2>&1; then
        _have_binding=1; break
      fi
    done
    if (( !_have_binding )); then
      for _seq in "${_candidate_right[@]}"; do
        bindkey "${_seq}" forward-char 2>/dev/null || true
      done
      if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
        print -r -- "[KEYBIND][repair] installed forward-char for right-arrow sequences" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
      fi
    fi
    unset _seq _candidate_right _have_binding

    # Instrumentation: log current nounset state & STARSHIP var existence
    if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
      print -r -- "[INSTRUMENT][post-plugin] nounset=$([[ -o nounset ]] && echo 1 || echo 0) +STARSHIP_CMD_STATUS=$(( ${+STARSHIP_CMD_STATUS} ))" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
  fi
fi

# Final defensive guard in case something unset STARSHIP_CMD_STATUS after plugins
if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi

if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
  print -r -- "[POST-PLUGINS] STARSHIP_CMD_STATUS=${STARSHIP_CMD_STATUS}" >>"${ZSH_DEBUG_LOG:-/dev/null}" 2>/dev/null || true
fi

# Ensure ultra guard stays first in precmd (some later modules may have prepended themselves)
if (( ${+precmd_functions} )); then
  if (( ${precmd_functions[(I)_zqs__preprompt_ultra_guard]} )); then
    # Rebuild with ultra guard first followed by unique remainder
    local -a _pf_new
    _pf_new=( _zqs__preprompt_ultra_guard )
    local f
    for f in "${precmd_functions[@]}"; do
      [[ $f == _zqs__preprompt_ultra_guard ]] && continue
      [[ ${_pf_new[(I)$f]} -ne 0 ]] && continue
      _pf_new+=("$f")
    done
    precmd_functions=( "${_pf_new[@]}" )
    unset _pf_new f
  fi
fi

# ---------------------------------------------------------------------------
# Missing widget remediation: Some environments expect 'globalias' (from various
# historical snippets) bound to <SPACE>. If it's absent, space may appear dead.
# We detect absence & ensure space inserts literal space.
# ---------------------------------------------------------------------------
if [[ -o interactive ]]; then
  zmodload -i zsh/zle 2>/dev/null || true
  if ! zle -l 2>/dev/null | command grep -q '^globalias$' 2>/dev/null; then
    bindkey ' ' self-insert 2>/dev/null || true
    if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
      print -r -- "[POST-PLUGINS] globalias widget absent; bound <SPACE> to self-insert" >>"${ZSH_DEBUG_LOG:-/dev/null}" 2>/dev/null || true
    fi
  fi
fi
