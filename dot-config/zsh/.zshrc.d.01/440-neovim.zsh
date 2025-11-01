#!/usr/bin/env zsh
# Filename: 440-neovim.zsh
# Purpose:  Integrates the Neovim ecosystem into the shell. This script sets default editors, configures Neovim profiles, and provides helper functions for a seamless development experience. Features: - Sets `EDITOR`, `VISUAL`, and `GIT_EDITOR` to `nvim`. - Gated aliases for Neovim profiles (Lazyman, Kickstart, etc.) that are defined only when their configuration directories exist. - `nvprofile` function to launch any Neovim profile by name. - Integration with `bob` (Neovim version manager). - `zf::nvimvenv` wrapper (aliased to `nvim`) to automatically handle Python virtual environments within Neovim sessions. Toggles: - `ZF_DISABLE_NVIM=1`: Disables all Neovim integration. - `ZF_DISABLE_NVIM_VENV_ALIAS=1`: Prevents aliasing `nvim` to the virtualenv wrapper.
# Phase:    Post-plugin (.zshrc.d/)
# Toggles:  ZF_DISABLE_NVIM

if [[ "${ZF_DISABLE_NVIM:-0}" == 1 ]]; then
  return 0
fi

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

export EDITOR="nvim"
export VISUAL="nvim"
export GIT_EDITOR="nvim"

# --- Neovim Profile Management ---
_zf_nv_xdg_cfg="${XDG_CONFIG_HOME:-${HOME}/.config}"

# Generic dispatcher for profiles
nvprofile() {
  local tail="$1"; shift || true
  if [[ -z "$tail" ]]; then
    print -u2 'Usage: nvprofile <ProfileName> [args]'
    return 1
  fi
  local prof="nvim-${tail}"
  local dir="${_zf_nv_xdg_cfg}/${prof}"
  if [[ -d "$dir" ]]; then
    NVIM_APPNAME="$prof" nvim "$@"
  else
    print -u2 "nvprofile: profile '${prof}' not found at '${dir}'"
    return 1
  fi
}

# Gated aliases for specific profiles (defined in .zshenv)
# zf::nvim_alias_if_exists is called from .zshenv to ensure aliases are available early.

# --- Bob (Neovim version manager) ---
if [[ -d "${HOME}/.local/share/bob" ]]; then
  zf::path_prepend "${HOME}/.local/share/bob"
  : "${BOB_CONFIG:=${_zf_nv_xdg_cfg}/bob/config.json}"
  export BOB_CONFIG
  zf::debug "# [nvim] Bob (Neovim version manager) configured"
fi

# --- Lazyman-specific Sourcing ---
if [[ -r "${_zf_nv_xdg_cfg}/nvim-Lazyman/.lazymanrc" ]]; then
  source "${_zf_nv_xdg_cfg}/nvim-Lazyman/.lazymanrc"
  zf::debug "# [nvim] Sourced Lazyman .lazymanrc"
fi

# --- Virtualenv-aware nvim Wrapper ---
# The zf::nvimvenv function is defined in .zshenv for global availability.
# This section just creates the alias.
if [[ "${ZF_DISABLE_NVIM_VENV_ALIAS:-0}" != 1 ]] && command -v nvim >/dev/null 2>&1; then
  alias nvim='zf::nvimvenv'
  export _ZF_NVIM_VENV_ALIAS=1
  zf::debug "# [nvim] Aliased nvim to virtualenv-aware wrapper"
else
  export _ZF_NVIM_VENV_ALIAS=0
fi

unset _zf_nv_xdg_cfg
return 0
