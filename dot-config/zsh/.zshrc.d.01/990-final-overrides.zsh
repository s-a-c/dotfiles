#!/usr/bin/env zsh
# Filename: 990-final-overrides.zsh
# Purpose:  This is the final script to run in the post-plugin phase. It handles last-minute overrides, cleanup, and safety checks to ensure the shell is in a consistent state. Features: - Restores `WARN_CREATE_GLOBAL` to help catch unintended global variable creation in user scripts and interactive sessions. - Disables automatic updates for ZQS and Oh-My-Zsh if requested, which is useful for CI/CD environments or stable setups. machine-specific or private configurations.
# Phase:    Post-plugin (.zshrc.d/)
# Toggles:  ZF_DISABLE_AUTO_UPDATES

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# --- Restore Warnings ---
# Re-enable WARN_CREATE_GLOBAL after all vendor/plugin scripts have loaded.
if [[ -o interactive ]]; then
  setopt warn_create_global
  zf::debug "# [final] Restored warn_create_global"
fi

# --- Disable Auto-Updates ---
# Respects ZF_DISABLE_AUTO_UPDATES to prevent ZQS and OMZ from auto-updating.
if [[ "${ZF_DISABLE_AUTO_UPDATES:-1}" == "1" ]]; then
  unset QUICKSTART_KIT_REFRESH_IN_DAYS
  export DISABLE_AUTO_UPDATE=true
  zf::debug "# [final] Automatic updates disabled"
fi

# --- Local Overrides ---
# Source a local file for machine-specific tweaks.
local _local_rc="${ZDOTDIR:-$HOME}/.zshrc.local"
if [[ -f "$_local_rc" ]]; then
  source "$_local_rc"
  zf::debug "# [final] Sourced local overrides from ${_local_rc}"
fi
unset _local_rc

zf::debug "# [final] Final overrides script complete"
return 0
