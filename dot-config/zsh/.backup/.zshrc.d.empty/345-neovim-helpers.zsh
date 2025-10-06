#!/usr/bin/env zsh
# 345-neovim-helpers.zsh - Auxiliary Neovim helpers (virtualenv-aware launcher)
# Phase 5 (Auxiliary) – complements 340-neovim-environment.zsh
#
# Purpose:
#   Provide a virtualenv‑aware Neovim launcher (`zf::nvimvenv`) that automatically
#   activates an existing Python virtual environment for the duration of the Neovim
#   process, then restores the shell environment without polluting the parent shell.
#
#   By default overrides plain `nvim` with this wrapper; opt-out with
#   `ZF_DISABLE_NVIM_VENV_ALIAS=1`.
#
# Features:
#   - Nounset-safe (guards every expansion)
#   - No permanent environment mutation (activation occurs in subshell)
#   - Respects NVIM_APPNAME if already set (does not force profile change)
#   - Falls back gracefully if no virtual environment is active
#   - Automatic alias injection (default enabled; explicit opt-out)
#
# Guards / Idempotency:
#   Uses _ZF_NVIM_HELPERS_DONE sentinel to avoid redefinition spam.
#
# Variables / Toggles:
#   ZF_DISABLE_NVIM_VENV_ALIAS=1     -> prevent automatic alias creation
#   ZF_NVIM_VENV_DEBUG=1             -> extra debug lines (in addition to zf::debug enable)
#   _ZF_NVIM_VENV_ALIAS=1|0          -> marker indicating alias active (1) or not (0)
#
# Exit Behavior:
#   Always returns 0 on sourcing (never aborts the calling startup sequence).
#
# Manual Validation:
#   1) python -m venv .venv && source .venv/bin/activate
#   2) nvim (should route through zf::nvimvenv unless opt-out is set)
#   3) echo $VIRTUAL_ENV (should be unset after Neovim exit in parent shell)
#
# Notes:
#   - This wrapper intentionally avoids trying to “guess” or auto-create virtualenvs.
#   - For performance, it only checks $VIRTUAL_ENV existence + activate script.
#   - If a user wants project auto-detection, that belongs in a higher-level tool.
#
# -----------------------------------------------------------------------------
# Idempotency guard
[[ -n ${_ZF_NVIM_HELPERS_DONE:-} ]] && return 0
_ZF_NVIM_HELPERS_DONE=1
# Provide minimal debug stub if framework not yet defined
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }
# Internal: verbose conditional logging
zf::nvimvenv::_log() {
  if [[ ${ZF_NVIM_VENV_DEBUG:-0} == 1 ]]; then
    zf::debug "$@"
  fi
}
# Virtualenv-aware Neovim launcher
# Usage: zf::nvimvenv [args...]
# Behavior:
#   - If $VIRTUAL_ENV points to a directory containing bin/activate, invoke Neovim
#     inside a subshell with that environment active.
#   - Else just exec Neovim normally (preserves current NVIM_APPNAME if set).
zf::nvimvenv() {
  local _args=("$@")
  if [[ -z ${VIRTUAL_ENV:-} || ! -f ${VIRTUAL_ENV:-}/bin/activate ]]; then
    zf::nvimvenv::_log "# [nvimvenv] No active virtualenv -> plain nvim"
    command nvim "${_args[@]}"
    return $?
  fi
  (
    zf::nvimvenv::_log "# [nvimvenv] Activating virtualenv: ${VIRTUAL_ENV}"
    # shellcheck disable=SC1090
    source "${VIRTUAL_ENV}/bin/activate" 2>/dev/null || {
      zf::nvimvenv::_log "# [nvimvenv] Failed to source activate; continuing without activation"
    }
    if [[ -f "${VIRTUAL_ENV}/.nvimvenv-pre" ]]; then
      # shellcheck disable=SC1090
      source "${VIRTUAL_ENV}/.nvimvenv-pre" 2>/dev/null || true
    fi
    command nvim "${_args[@]}"
  )
  local _rc=$?
  zf::nvimvenv::_log "# [nvimvenv] Completed (exit=${_rc})"
  return $_rc
}
# Virtualenv alias override (default enabled; opt-out with ZF_DISABLE_NVIM_VENV_ALIAS=1)
if [[ "${ZF_DISABLE_NVIM_VENV_ALIAS:-0}" != 1 ]]; then
  if command -v nvim >/dev/null 2>&1; then
    alias nvim='zf::nvimvenv'
    _ZF_NVIM_VENV_ALIAS=1
    zf::debug "# [nvimvenv] Alias nvim='zf::nvimvenv' (default enabled)"
  else
    _ZF_NVIM_VENV_ALIAS=0
    zf::debug "# [nvimvenv] nvim not found; alias not created"
  fi
else
  _ZF_NVIM_VENV_ALIAS=0
  zf::debug "# [nvimvenv] Alias override disabled via ZF_DISABLE_NVIM_VENV_ALIAS"
fi
export _ZF_NVIM_VENV_ALIAS
# Provide a small helper to show effective resolution for diagnostics
zf::nvimvenv:which() {
  if alias nvim 2>/dev/null | grep -q "zf::nvimvenv"; then
    echo "nvim -> zf::nvimvenv (alias active)"
  else
    echo "nvim -> $(command -v nvim 2>/dev/null || echo missing)"
  fi
  if [[ -n ${VIRTUAL_ENV:-} ]]; then
    echo "VIRTUAL_ENV=${VIRTUAL_ENV}"
  else
    echo "VIRTUAL_ENV=(none)"
  fi
}
zf::debug "# [nvimvenv] Helper module loaded"
return 0
