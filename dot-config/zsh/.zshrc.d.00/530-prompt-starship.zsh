#!/usr/bin/env zsh
# 520-prompt-starship.zsh - Unified Starship prompt initialization (post-plugin phase)
# Merged from 410-starship-prompt.zsh and starship-init-wrapper.zsh
# Purpose: Robust, idempotent Starship prompt setup with deferred init and widget patching
# Phase: Post-plugin augmentation
# Dependencies: starship binary, ZSH_DISABLE_STARSHIP env toggle, Powerlevel10k guard

## Starship Prompt Activation (refined gating)
# Semantics:
#   ZSH_DISABLE_STARSHIP=1  -> Hard disable (no init, no hooks)
#   ZSH_DISABLE_STARSHIP=0* -> Enable; if p10k present, defer to precmd; else immediate
#   ZSH_STARSHIP_SUPPRESS_AUTOINIT=1 -> Provide functions only (no automatic init / hook registration); caller must invoke zf::prompt_init manually
#   ZSH_STARSHIP_FORCE_DEFER=1 -> Force deferral via precmd hook even if .p10k.zsh absent (or after guard repair)
# Deprecated: ZF_ENABLE_STARSHIP (no effect)

# (Moved gating BELOW function definitions so zf::prompt_init always exists when sourced.)

# Debug helper (no-op if not defined)
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# If a parent shell exported the guard, but no starship hook is present here,
# treat it as stale and clear it so deferral can be re-armed in this shell.
if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]] && ! typeset -f starship_precmd >/dev/null 2>&1; then
  zf::debug "# [starship] clearing inherited __ZF_PROMPT_INIT_DONE (no starship_precmd present)"
  unset __ZF_PROMPT_INIT_DONE
fi

# Robust Starship initialization (with widget patching and metrics)
starship_init_safe() {
  zf::debug "# [starship] init entry (force=${ZSH_STARSHIP_FORCE_IMMEDIATE:-0} disable=${ZSH_DISABLE_STARSHIP:-0})"
  if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]]; then
    zf::debug "# [prompt] starship init skipped (already done)"
    return 0
  fi
  local _zf_start_time _zf_end_time _zf_elapsed_ms
  _zf_start_time="${EPOCHREALTIME:-}"
  local starship_bin
  starship_bin="$(command -v starship 2>/dev/null || true)"
  [[ -z "$starship_bin" && -x "$HOME/.local/share/cargo/bin/starship" ]] && starship_bin="$HOME/.local/share/cargo/bin/starship"
  if [[ -z "$starship_bin" ]]; then
    echo "# Starship not available" >&2
    return 1
  fi
  local init_script
  init_script="$($starship_bin init zsh 2>/dev/null)"
  if [[ -z "$init_script" ]]; then
    echo "# Starship init generation failed" >&2
    return 1
  fi
  # If inherited from parent shell (e.g. bash), clear so starship sets correct value
  if [[ ${STARSHIP_SHELL:-} != "" && ${STARSHIP_SHELL} != "starship" ]]; then
  zf::debug "# [starship] clearing inherited STARSHIP_SHELL='${STARSHIP_SHELL}'"
    unset STARSHIP_SHELL 2>/dev/null || true
  fi
  # Patch problematic ZLE widget access
  local safe_init_script
  safe_init_script="${init_script//\${widgets\[zle-keymap-select\]#user:}/\${widgets[zle-keymap-select]:-}}"
  safe_init_script="${safe_init_script//\${widgets\[zle-keymap-select\]:-}#user:/\${widgets[zle-keymap-select]:-}}"
  eval "$safe_init_script"
  _zf_end_time="${EPOCHREALTIME:-}"
  if [[ -n "$_zf_start_time" && -n "_zf_end_time" ]]; then
    local s1=${_zf_start_time%%.*} us1=${_zf_start_time#*.}
    local s2=${_zf_end_time%%.*}   us2=${_zf_end_time#*.}
    us1="${us1}000000"; us1=${us1:0:6}
    us2="${us2}000000"; us2=${us2:0:6}
    local total_us=$(( (10#$s2*1000000 + 10#$us2) - (10#$s1*1000000 + 10#$us1) ))
    if (( total_us >= 0 )); then
      _zf_elapsed_ms=$(( total_us / 1000 ))
      export _ZF_STARSHIP_INIT_MS=$_zf_elapsed_ms
    fi
  fi
  # Mark init done for this shell only (do not export into environment)
  typeset -g __ZF_PROMPT_INIT_DONE=1
  # Normalize STARSHIP_SHELL (some upstream versions set 'zsh'; tests & diagnostics expect 'starship')
  if [[ ${STARSHIP_SHELL:-} != "starship" ]]; then
    zf::debug "# [starship] normalizing STARSHIP_SHELL='${STARSHIP_SHELL:-unset}' -> 'starship'"
    STARSHIP_SHELL=starship
  fi
  if [[ -n ${_ZF_STARSHIP_INIT_MS:-} ]]; then
  zf::debug "# [prompt] starship initialized (${_ZF_STARSHIP_INIT_MS}ms)"
    if [[ -z ${ZF_DISABLE_METRICS:-} ]]; then
      local metrics_dir="${ZDOTDIR:-$HOME}/dot-config/zsh/artifacts/metrics"
      if [[ -d "$metrics_dir" && -w "$metrics_dir" ]]; then
        {
          printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "starship_init_ms" "${_ZF_STARSHIP_INIT_MS}" || true
        } >> "$metrics_dir/starship-init.log" 2>/dev/null || true
        if [[ -f "$metrics_dir/starship-init.log" ]]; then
          local sz
          sz=$(wc -c <"$metrics_dir/starship-init.log" 2>/dev/null || echo 0)
          if [[ -n "$sz" && "$sz" -gt 65536 ]]; then
            tail -n 500 "$metrics_dir/starship-init.log" > "$metrics_dir/.starship-init.tmp" 2>/dev/null || true
            mv "$metrics_dir/.starship-init.tmp" "$metrics_dir/starship-init.log" 2>/dev/null || true
          fi
        fi
      fi
    fi
  else
  zf::debug "# [prompt] starship initialized"
  fi
}

# Namespaced entrypoint
zf::prompt_init() { starship_init_safe "$@"; }

# --- Gating & Activation (moved to ensure functions defined) ---
# Legacy variable removed; ZF_ENABLE_STARSHIP is deprecated and ignored.

# Hard disable path
if [[ ${ZSH_DISABLE_STARSHIP:-0} == 1 ]]; then
  zf::debug "# [starship] skip: disabled via ZSH_DISABLE_STARSHIP=1"
  return 0
fi

# Suppression path (deliver functions only; skip all auto-init logic below)
if [[ ${ZSH_STARSHIP_SUPPRESS_AUTOINIT:-0} == 1 ]]; then
  zf::debug "# [starship] suppress: functions exported; no auto init (ZSH_STARSHIP_SUPPRESS_AUTOINIT=1)"
  return 0
fi

# Guard: duplicate (with stale repair)
if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]]; then
  if [[ ${STARSHIP_SHELL:-} != starship ]]; then
  zf::debug "# [starship] stale guard detected (STARSHIP_SHELL='${STARSHIP_SHELL:-unset}'); clearing for re-init"
    unset __ZF_PROMPT_INIT_DONE 2>/dev/null || true
  else
    return 0
  fi
fi

# Binary presence check
if ! command -v starship >/dev/null 2>&1; then
  zf::debug "# [starship] skip: binary not found in PATH"
  return 0
fi

# Prompt activation logic (supports forced deferral)
if [[ ${ZSH_STARSHIP_FORCE_DEFER:-0} == 1 && -z ${ZSH_STARSHIP_FORCE_IMMEDIATE:-} ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null || true
  if typeset -f add-zsh-hook >/dev/null 2>&1; then
  zf::debug "# [starship] defer: forced (ZSH_STARSHIP_FORCE_DEFER=1)"
    zf::prompt_init_deferred() { add-zsh-hook -d precmd zf::prompt_init_deferred 2>/dev/null || true; zf::prompt_init || starship_init_safe || true; }
    add-zsh-hook precmd zf::prompt_init_deferred
  else
  zf::debug "# [starship] defer failed: add-zsh-hook missing; falling back to immediate"
    zf::prompt_init 2>/dev/null || starship_init_safe 2>/dev/null || true
  fi
elif [[ -f ${ZDOTDIR:-$HOME}/.p10k.zsh && -z ${ZSH_STARSHIP_FORCE_IMMEDIATE:-} ]]; then
  autoload -Uz add-zsh-hook 2>/dev/null || true
  if whence -w add-zsh-hook >/dev/null 2>&1; then
  zf::debug "# [starship] defer: p10k present (precmd hook registered)"
    zf::prompt_init_deferred() { add-zsh-hook -d precmd zf::prompt_init_deferred 2>/dev/null || true; zf::prompt_init || starship_init_safe || true; }
    add-zsh-hook precmd zf::prompt_init_deferred
  else
  zf::debug "# [starship] init: p10k present but no add-zsh-hook; immediate fallback"
    zf::prompt_init 2>/dev/null || starship_init_safe 2>/dev/null || true
  fi
else
  if [[ -n ${ZSH_STARSHIP_FORCE_IMMEDIATE:-} && -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]]; then
  zf::debug "# [starship] force: immediate override despite p10k (ZSH_STARSHIP_FORCE_IMMEDIATE set)"
  else
  zf::debug "# [starship] init: immediate (no p10k detected)"
  fi
  zf::prompt_init 2>/dev/null || starship_init_safe 2>/dev/null || true
fi
