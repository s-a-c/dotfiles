#!/usr/bin/env zsh
# -----------------------------------------------------------------------------
# 15-starship-and-fsh-post.zsh (Post-Plugin stage, always loaded)
# - Seed Starship status variables before any prompt logic
# - Rebind fast-syntax-highlighting after all widgets exist
# -----------------------------------------------------------------------------

# Idempotency guard
if [[ -n "${_ZQS_POSTPLUGIN_STARSHIP_FSH_LOADED:-}" ]]; then
  return 0
fi
export _ZQS_POSTPLUGIN_STARSHIP_FSH_LOADED=1

# ---------- Starship variable seeder hook (centralized) ----------
# We now rely on the global declarations in `.zshenv`. This hook just re-asserts
# integer typing (only if missing) & ensures array exists without clobbering.
_zqs__seed_starship_vars_precmd() {
  if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
  if ! (( ${+STARSHIP_DURATION_MS} )); then typeset -gi STARSHIP_DURATION_MS=0; fi
  if ! (( ${+STARSHIP_CMD_EXIT_REASON} )); then typeset -gi STARSHIP_CMD_EXIT_REASON=0; fi
  if ! (( ${+STARSHIP_CMD_START_TIME} )); then typeset -gi STARSHIP_CMD_START_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_END_TIME} )); then typeset -gi STARSHIP_CMD_END_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_BG} )); then typeset -gi STARSHIP_CMD_BG=0; fi
  if ! (( ${+STARSHIP_CMD_JOBS} )); then typeset -gi STARSHIP_CMD_JOBS=0; fi
  if ! (( ${+STARSHIP_JOBS_COUNT} )); then typeset -gi STARSHIP_JOBS_COUNT=0; fi
  if ! (( ${+STARSHIP_CMD_SIG} )); then typeset -gi STARSHIP_CMD_SIG=0; fi
  if ! (( ${+STARSHIP_CMD_ERR} )); then typeset -gi STARSHIP_CMD_ERR=0; fi
  if ! (( ${+STARSHIP_CMD_ERRMSG} )); then typeset -g STARSHIP_CMD_ERRMSG=''; fi
  if ! (( ${+STARSHIP_CMD_ERRNO} )); then typeset -gi STARSHIP_CMD_ERRNO=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCODE} )); then typeset -gi STARSHIP_CMD_ERRCODE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCTX} )); then typeset -g STARSHIP_CMD_ERRCTX=''; fi
  if ! (( ${+STARSHIP_CMD_ERRFUNC} )); then typeset -g STARSHIP_CMD_ERRFUNC=''; fi
  if ! (( ${+STARSHIP_CMD_ERRLINE} )); then typeset -gi STARSHIP_CMD_ERRLINE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRFILE} )); then typeset -g STARSHIP_CMD_ERRFILE=''; fi
  if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
    # If debug enabled, log a concise trace (avoids flooding). Only log when var newly created.
    if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
      print -r -- "[STARSHIP-GUARD][precmd] status=${STARSHIP_CMD_STATUS} pipect=${#STARSHIP_PIPE_STATUS[@]}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
    fi
}
if (( ${+precmd_functions} )); then
  local -a _pf
  for _f in "${precmd_functions[@]}"; do
    [[ "$_f" == "_zqs__seed_starship_vars_precmd" ]] || _pf+=("$_f")
  done
  precmd_functions=( _zqs__seed_starship_vars_precmd ${_pf[@]} )
  unset _pf _f
else
  precmd_functions=( _zqs__seed_starship_vars_precmd )
fi

# Parallel preexec guard to catch resets between command dispatch and next precmd
_zqs__seed_starship_vars_preexec() {
  if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
  if ! (( ${+STARSHIP_DURATION_MS} )); then typeset -gi STARSHIP_DURATION_MS=0; fi
  if ! (( ${+STARSHIP_CMD_EXIT_REASON} )); then typeset -gi STARSHIP_CMD_EXIT_REASON=0; fi
  if ! (( ${+STARSHIP_CMD_START_TIME} )); then typeset -gi STARSHIP_CMD_START_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_END_TIME} )); then typeset -gi STARSHIP_CMD_END_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_BG} )); then typeset -gi STARSHIP_CMD_BG=0; fi
  if ! (( ${+STARSHIP_CMD_JOBS} )); then typeset -gi STARSHIP_CMD_JOBS=0; fi
  if ! (( ${+STARSHIP_JOBS_COUNT} )); then typeset -gi STARSHIP_JOBS_COUNT=0; fi
  if ! (( ${+STARSHIP_CMD_SIG} )); then typeset -gi STARSHIP_CMD_SIG=0; fi
  if ! (( ${+STARSHIP_CMD_ERR} )); then typeset -gi STARSHIP_CMD_ERR=0; fi
  if ! (( ${+STARSHIP_CMD_ERRMSG} )); then typeset -g STARSHIP_CMD_ERRMSG=''; fi
  if ! (( ${+STARSHIP_CMD_ERRNO} )); then typeset -gi STARSHIP_CMD_ERRNO=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCODE} )); then typeset -gi STARSHIP_CMD_ERRCODE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCTX} )); then typeset -g STARSHIP_CMD_ERRCTX=''; fi
  if ! (( ${+STARSHIP_CMD_ERRFUNC} )); then typeset -g STARSHIP_CMD_ERRFUNC=''; fi
  if ! (( ${+STARSHIP_CMD_ERRLINE} )); then typeset -gi STARSHIP_CMD_ERRLINE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRFILE} )); then typeset -g STARSHIP_CMD_ERRFILE=''; fi
  if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
  if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
    print -r -- "[STARSHIP-GUARD][preexec] status=${STARSHIP_CMD_STATUS} pipect=${#STARSHIP_PIPE_STATUS[@]}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  fi
}

# Inject preexec guard first if not already present
if (( ${+preexec_functions} )); then
  if (( ! ${preexec_functions[(I)_zqs__seed_starship_vars_preexec]} )); then
    preexec_functions=(_zqs__seed_starship_vars_preexec ${preexec_functions[@]})
  fi
else
  preexec_functions=(_zqs__seed_starship_vars_preexec)
fi

# --- Starship precmd instrumentation wrapper (AI-authored) ---
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Goal: capture & neutralize late nounset reintroduction around starship's own
# precmd functions to prevent intermittent 'parameter not set' for STARSHIP_CMD_STATUS.
_zqs__starship_precmd_wrapper() {
  # Generic wrapper body reused for each detected starship precmd function.
  local _target_fn="$1"; shift || true
  local _had_nounset=0 _rc=0
  # Prefer core grep shim if defined (avoids alias edge cases entirely)
  if typeset -f zf::core_grep >/dev/null 2>&1; then
    set -o | zf::core_grep -q '^nounset *on' && { _had_nounset=1; unsetopt nounset; }
  else
    if set -o | command grep -q '^nounset *on'; then _had_nounset=1; unsetopt nounset; fi
  fi
  # Extended variable surface (idempotent, tolerate unset)
  if ! (( ${+STARSHIP_CMD_STATUS} )); then typeset -gi STARSHIP_CMD_STATUS=0; fi
  if ! (( ${+STARSHIP_DURATION_MS} )); then typeset -gi STARSHIP_DURATION_MS=0; fi
  if ! (( ${+STARSHIP_CMD_EXIT_REASON} )); then typeset -gi STARSHIP_CMD_EXIT_REASON=0; fi
  if ! (( ${+STARSHIP_CMD_START_TIME} )); then typeset -gi STARSHIP_CMD_START_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_END_TIME} )); then typeset -gi STARSHIP_CMD_END_TIME=0; fi
  if ! (( ${+STARSHIP_CMD_BG} )); then typeset -gi STARSHIP_CMD_BG=0; fi
  if ! (( ${+STARSHIP_CMD_JOBS} )); then typeset -gi STARSHIP_CMD_JOBS=0; fi
  if ! (( ${+STARSHIP_JOBS_COUNT} )); then typeset -gi STARSHIP_JOBS_COUNT=0; fi
  if ! (( ${+STARSHIP_CMD_SIG} )); then typeset -gi STARSHIP_CMD_SIG=0; fi
  if ! (( ${+STARSHIP_CMD_ERR} )); then typeset -gi STARSHIP_CMD_ERR=0; fi
  if ! (( ${+STARSHIP_CMD_ERRMSG} )); then typeset -g STARSHIP_CMD_ERRMSG=''; fi
  if ! (( ${+STARSHIP_CMD_ERRNO} )); then typeset -gi STARSHIP_CMD_ERRNO=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCODE} )); then typeset -gi STARSHIP_CMD_ERRCODE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRCTX} )); then typeset -g STARSHIP_CMD_ERRCTX=''; fi
  if ! (( ${+STARSHIP_CMD_ERRFUNC} )); then typeset -g STARSHIP_CMD_ERRFUNC=''; fi
  if ! (( ${+STARSHIP_CMD_ERRLINE} )); then typeset -gi STARSHIP_CMD_ERRLINE=0; fi
  if ! (( ${+STARSHIP_CMD_ERRFILE} )); then typeset -g STARSHIP_CMD_ERRFILE=''; fi
  if ! (( ${+STARSHIP_PIPE_STATUS} )); then typeset -ga STARSHIP_PIPE_STATUS; STARSHIP_PIPE_STATUS=(); fi
  if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
    print -r -- "[STARSHIP-WRAP][precmd][before] f=${_target_fn} nounset=${_had_nounset} +STATUS=$(( ${+STARSHIP_CMD_STATUS} )) val=${STARSHIP_CMD_STATUS} fails=${STARSHIP_WRAP_FAILS:-0}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  fi
  "${_target_fn}" "$@" || _rc=$?
  (( _rc != 0 )) && : ${STARSHIP_WRAP_FAILS:=$(( ${STARSHIP_WRAP_FAILS:-0} + 1 ))}
  if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
    print -r -- "[STARSHIP-WRAP][precmd][after] f=${_target_fn} rc=${_rc} fails=${STARSHIP_WRAP_FAILS:-0} val=${STARSHIP_CMD_STATUS}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  fi
  if (( ${STARSHIP_WRAP_FAILS:-0} >= ${STARSHIP_FALLBACK_THRESHOLD:-3} )) && [[ -z ${STARSHIP_FALLBACK_ACTIVATED:-} ]]; then
    _zqs__activate_starship_fallback "wrapper-failures=${STARSHIP_WRAP_FAILS}"
  fi
  (( _had_nounset )) && set -o nounset || true
  return 0
}

_zqs__wrap_starship_precmd_if_needed() {
  if [[ "${STARSHIP_DISABLE_WRAP:-0}" == 1 ]]; then return 0; fi
  : ${STARSHIP_WRAP_FAILS:=0}
  : ${STARSHIP_FALLBACK_THRESHOLD:=3}
  local f
  for f in prompt_starship_precmd starship_precmd __starship_prompt_command; do
    if whence -w "$f" >/dev/null 2>&1; then
      # Already wrapped? detect by original backup function sentinel
      if [[ -n ${functions[_zqs__orig_${f}]:-} ]]; then return 0; fi
      functions[_zqs__orig_${f}]=${functions[$f]}
      # Create a thin forwarding function calling generic wrapper
      eval "${f}() { _zqs__starship_precmd_wrapper _zqs__orig_${f} \"$@\"; }"
      [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]] && print -r -- "[STARSHIP-WRAP] Installed wrapper for ${f}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
      return 0
    fi
  done
}

# Attempt wrapping each precmd until starship's function appears
if (( ! ${precmd_functions[(I)_zqs__wrap_starship_precmd_if_needed]} )); then
  precmd_functions+=( _zqs__wrap_starship_precmd_if_needed )
fi

# --- Fallback prompt activation ---
_zqs__activate_starship_fallback() {
  # Only run once
  if [[ -n ${STARSHIP_FALLBACK_ACTIVATED:-} ]]; then return 0; fi
  STARSHIP_FALLBACK_ACTIVATED=1
  : ${STARSHIP_FALLBACK_REASON:=$1}
  # Simple resilient prompt (minimal expansions to avoid errors under set -u)
  PROMPT='%n@%m %~ %# '
  PS1="$PROMPT"
  # Provide a tiny RPROMPT to confirm fallback status visually if desired (opt-in)
  if [[ ${STARSHIP_FALLBACK_SHOW_RPROMPT:-0} == 1 ]]; then
    RPROMPT='(fallback)'
  fi
  if [[ ${ZSH_DEBUG:-0} == 1 && -n ${ZSH_DEBUG_LOG:-} ]]; then
    print -r -- "[STARSHIP-FALLBACK] activated reason=${STARSHIP_FALLBACK_REASON:-unspecified} fails=${STARSHIP_WRAP_FAILS:-0}" >>"$ZSH_DEBUG_LOG" 2>/dev/null || true
  fi
}

# If starship binary absent entirely, preemptively enable fallback (one-time)
if ! command -v starship >/dev/null 2>&1 && [[ -z ${STARSHIP_FALLBACK_ACTIVATED:-} ]]; then
  _zqs__activate_starship_fallback "binary-missing"
fi

# --- Health report function ---
starship_health_report() {
  echo "Starship Health:";
  echo "  wrap_disabled: ${STARSHIP_DISABLE_WRAP:-0}";
  echo "  failures: ${STARSHIP_WRAP_FAILS:-0}";
  echo "  fallback_threshold: ${STARSHIP_FALLBACK_THRESHOLD:-unset}";
  echo "  fallback_active: ${STARSHIP_FALLBACK_ACTIVATED:-0}";
  echo "  fallback_reason: ${STARSHIP_FALLBACK_REASON:-none}";
  echo "  cmd_status_defined: $(( ${+STARSHIP_CMD_STATUS} )) value=${STARSHIP_CMD_STATUS:-unset}";
  echo "  pipe_status_defined: $(( ${+STARSHIP_PIPE_STATUS} )) count=${#STARSHIP_PIPE_STATUS[@]:-0}";
  echo "  starship_binary: $(command -v starship 2>/dev/null || echo 'not found')";
  return 0
}


# ---------- Ensure FSH core is sourced if minus-functions missing ----------
if ! typeset -f -- -fast-highlight-init >/dev/null 2>&1; then
  local fsh_dir="${ZGEN_DIR:-${ZDOTDIR:-$HOME}/.zqs-zgenom}/zdharma-continuum/fast-syntax-highlighting/___"
  if [[ -r "$fsh_dir/fast-highlight" ]]; then
    fpath+="$fsh_dir"
    source "$fsh_dir/fast-highlight"
    [[ -r "$fsh_dir/fast-string-highlight" ]] && source "$fsh_dir/fast-string-highlight"
    typeset -f -- -fast-highlight-fill-option-variables >/dev/null 2>&1 && -fast-highlight-fill-option-variables
  fi
fi

# ---------- Rebind fast-syntax-highlighting widgets after plugins ----------
# Only if requested and the function exists
if [[ -n "${ZSH_FSH_REBIND_LATER:-}" ]] && typeset -f _zsh_highlight_bind_widgets >/dev/null 2>&1; then
  zmodload zsh/zleparameter 2>/dev/null || true
  : ${ZSH_LOG_DIR:=${ZDOTDIR:-$HOME}/logs}
  mkdir -p -- "$ZSH_LOG_DIR" 2>/dev/null || true
  { _zsh_highlight_bind_widgets } > /dev/null 2>>"$ZSH_LOG_DIR/fsh-rebind.log" || true
fi

# End of file

