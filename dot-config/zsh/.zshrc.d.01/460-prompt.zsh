#!/usr/bin/env zsh
# 460-prompt.zsh
#
# Purpose:
#   Manages the shell prompt, primarily by initializing Starship. This script
#   handles the complexities of when and how to load the prompt, with special
#   considerations for compatibility with Powerlevel10k.
#
# Features:
#   - Robust, idempotent Starship initialization (`zf::starship_init_safe`).
#   - Deferred loading via `precmd` hook when Powerlevel10k is detected,
#     preventing conflicts.
#   - Patches problematic ZLE widget access in Starship's init script.
#   - Captures and logs Starship initialization time for performance monitoring.
#   - Manages Starship configuration templating and symlinks.
#   - Includes a weekly health check for the Starship prompt.
#
# Toggles:
#   - `ZSH_DISABLE_STARSHIP=1`: Hard disables Starship.
#   - `ZSH_SHOW_P10K_HINT=1`: Shows a hint to run `p10k configure` if Starship
#     is disabled and no .p10k.zsh file exists.

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Starship Configuration Management ---
if [[ "${ZSH_DISABLE_STARSHIP:-0}" != 1 ]] && command -v starship >/dev/null 2>&1; then
  local _dotcfg_root="${ZDOTDIR:h}"
  local _starship_dir="${_dotcfg_root}/starship"
  local _gen_dir="${_starship_dir}/generated"
  mkdir -p -- "${_gen_dir}" 2>/dev/null

  local _template="${_starship_dir}/starship.base.toml"
  local _generated="${_gen_dir}/starship.generated.toml"
  local _symlink_target="${_dotcfg_root}/starship.toml"

  if [[ -f "${_template}" ]]; then
    local _tz="$(_zqs-get-setting starship-utc-offset +0)"
    if sed "s/__UTC_OFFSET__/${_tz}/g" "${_template}" >|"${_generated}"; then
      ln -sfn "${_generated}" "${_symlink_target}" 2>/dev/null
      zf::debug "# [prompt] Generated Starship config with UTC offset: ${_tz}"
    fi
  fi

  : "${STARSHIP_CACHE:=${XDG_CACHE_HOME:-$HOME/.cache}/starship}"
  export STARSHIP_CACHE
  mkdir -p -- "${STARSHIP_CACHE}" 2>/dev/null
fi

# --- Starship Initialization ---
if [[ "${ZSH_DISABLE_STARSHIP:-0}" != 1 ]] && command -v starship >/dev/null 2>&1; then
  # The zf::starship_init_safe function is defined in .zshenv for global availability.
  # This logic determines whether to call it immediately or defer it.
  if [[ -f "${ZDOTDIR:-$HOME}/.p10k.zsh" && -z "${ZSH_STARSHIP_FORCE_IMMEDIATE:-}" ]]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    if typeset -f add-zsh-hook >/dev/null 2>&1; then
      zf::debug "# [prompt] Deferring Starship init due to p10k presence"
      # The zf::starship_init_safe function is now called directly via the hook
      # to prevent conflicts with p10k.
      add-zsh-hook precmd zf::starship_init_safe
    else
      zf::starship_init_safe # Fallback if add-zsh-hook is missing
    fi
  else
    zf::debug "# [prompt] Initializing Starship immediately"
    zf::starship_init_safe
  fi
else
  # --- Powerlevel10k Hint ---
  if [[ ${ZSH_SHOW_P10K_HINT:-0} == 1 && ! -f "${ZDOTDIR:-$HOME}/.p10k.zsh" ]]; then
    echo "Starship is disabled. Run 'p10k configure' to set up Powerlevel10k."
  fi
fi

# --- Starship Health Check ---
if [[ -o interactive && "${STARSHIP_HEALTH_DISABLE:-0}" != 1 ]] && command -v starship >/dev/null 2>&1; then
  local _cache_dir="${ZDOTDIR:-$HOME}/.cache/starship"
  local _log_dir="${ZDOTDIR:-$HOME}/logs"
  local _stamp_file="${_cache_dir}/health-last-run"
  local _log_file="${_log_dir}/starship-health.log"
  mkdir -p -- "${_cache_dir}" "${_log_dir}" 2>/dev/null

  local _now=$(date +%s)
  local _days="${STARSHIP_HEALTH_INTERVAL_DAYS:-7}"
  local _interval=$((_days * 86400))
  local _last
  [[ -r "${_stamp_file}" ]] && read -r _last <"${_stamp_file}" || _last=0

  if ((_now - _last > _interval)); then
    local _warns
    _warns=$(STARSHIP_LOG=warn starship prompt >/dev/null 2>&1)
    if [[ -n "${_warns}" ]]; then
      echo "⚠️ Starship health check found issues. See: ${_log_file}"
      {
        printf '=== %s ===\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '%s\n\n' "${_warns}"
      } >>"${_log_file}" 2>/dev/null
    fi
    printf '%s\n' "${_now}" >|"${_stamp_file}" 2>/dev/null
    zf::debug "# [prompt] Starship health check performed"
  fi
fi

return 0
