#!/usr/bin/env zsh
# 410-completions.zsh
#
# Purpose:
#   Initializes the Zsh completion system (`compinit`) and integrates the
#   Carapace completion engine if available. This script ensures that advanced
#   completions are ready before other tools and plugins require them.
#
# Features:
#   - Guarded `compinit` initialization to run only once.
#   - Fast path for `compinit` using `-C` to skip regeneration if the dump file is valid.
#   - Automatic integration of Carapace for rich, context-aware completions.
#   - Optional, configurable styling for Carapace completions via environment variables.
#
# Toggles:
#   - `ZF_DISABLE_CARAPACE=1`: Disables Carapace integration.
#   - `ZF_DISABLE_CARAPACE_STYLES=1`: Disables Carapace styling.
#   - `ZF_CARAPACE_STYLE_MODE=<mode>`: Sets a predefined style (e.g., colorful, mono).

# Compliant with AI-GUIDELINES.md v09f72e258e7b5a3c2c7e81ff2e0501fee4a5ed8a9d1a9123ad6d2c6e237748d4

# --- Personal Completions Directory (Prepended before compinit) ---
# Create a secure, user-controlled directory for custom completion functions and
# ensure it is prepended to fpath so your completions take precedence.
{
  local _pc_guard="${SERENA_PERSONAL_SITEFUNCS_ENABLE-1}"
  [[ "$_pc_guard" = 1 ]] || true
  if [[ "$_pc_guard" = 1 ]]; then
    local _pc_dir
    _pc_dir="${SERENA_PERSONAL_SITEFUNCS_DIR-${ZDOTDIR-$HOME}/.zsh/site-functions.personal}"
    mkdir -p -- "$_pc_dir" 2>/dev/null || true
    chmod 700 "$_pc_dir" 2>/dev/null || true
    if (( ${fpath[(Ie)$_pc_dir]} == 0 )); then
      fpath=( "$_pc_dir" $fpath )
    fi
    unset _pc_dir
  fi
  unset _pc_guard
}

# --- Completion System Initialization ---
if [[ -z "${__ZF_COMPINIT_DONE:-}" ]] && ! typeset -f compdef >/dev/null 2>&1; then
  if autoload -Uz compinit 2>/dev/null; then
    if compinit -i -C 2>/dev/null; then
      __ZF_COMPINIT_DONE=1
      zf::debug "# [completions] compinit initialized (fast)"
    elif compinit -i 2>/dev/null; then
      __ZF_COMPINIT_DONE=1
      zf::debug "# [completions] compinit initialized (fallback)"
    else
      zf::debug "# [completions] compinit failed"
    fi
  else
    zf::debug "# [completions] autoload compinit not available"
  fi
fi

# --- Carapace Integration ---
if [[ "${ZF_DISABLE_CARAPACE:-0}" != 1 ]] && command -v carapace >/dev/null 2>&1; then
  eval "$(carapace _carapace)"
  zf::debug "# [completions] Carapace integration enabled"

  # Carapace Styling
  if [[ "${ZF_DISABLE_CARAPACE_STYLES:-0}" != 1 ]]; then
    local _cfg_root="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local _user_styles_file="${_cfg_root}/carapace/styles.yaml"

    if [[ ! -f "${_user_styles_file}" || "${ZF_CARAPACE_FORCE:-0}" == 1 ]]; then
      local _mode="${ZF_CARAPACE_STYLE_MODE:-default}"
      case "${_mode}" in
        colorful) export CARAPACE_COLORS="group=magenta:bold,border=cyan,flag=blue:bold,option=blue,argument=green:value,command=yellow:bold,file=white,dir=cyan:bold" ;;
        mono) export CARAPACE_COLORS="group=white,border=white,flag=white,option=white,argument=white,command=white,file=white,dir=white" ;;
        minimal) export CARAPACE_COLORS="group=default,border=default,flag=default,option=default,argument=default,command=default,file=default,dir=default" ;;
        *) export CARAPACE_COLORS="group=blue:bold,border=240,flag=cyan,option=cyan,argument=green,command=yellow,file=default,dir=blue" ;;
      esac
      export _ZF_CARAPACE_STYLES=1 _ZF_CARAPACE_STYLE_MODE="${_mode}"
      zf::debug "# [completions] Carapace style mode '${_mode}' applied"
    else
      zf::debug "# [completions] Carapace user styles file found; skipping automatic styling"
    fi
    unset _cfg_root _user_styles_file _mode
  fi
fi

return 0
