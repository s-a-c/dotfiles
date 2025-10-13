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
# zf::debug and nvimvenv functions are now globally available from .zshenv.00
# zf::nvimvenv functions moved to .zshenv.00 for global availability
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
# zf::nvimvenv:which function moved to .zshenv.00 for global availability
zf::debug "# [nvimvenv] Helper module loaded"
return 0
