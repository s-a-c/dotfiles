#!/usr/bin/env zsh
# 310-navigation.zsh - Phase 4: Navigation utilities (zoxide, eza)
# Conditional exports & aliases for enhanced directory/file navigation

# Skip if plugin-managed navigation layer already initialized (marker from 150-productivity-nav.zsh)
if [[ -n ${_ZF_PM_NAV_LOADED:-} ]]; then
  return 0
fi

if [[ "${ZF_DISABLE_NAVIGATION:-0}" == 1 ]]; then
  return 0
fi

# zoxide initialization (if installed)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# eza aliases (if installed) with opt-out
# Policy: 'ls' is aliased to 'eza' by default for improved UX (rich formatting, colors, optional icons).
# Opt-out: set ZF_DISABLE_EZA_ALIAS=1 before this file is sourced to retain the original coreutils 'ls'.
# Exports: ALIAS_LS_EZA=1 when alias is active; ALIAS_LS_EZA=0 otherwise (queried by smoke / validation tests).
# Rationale: Ensure a consistent modern listing experience while keeping reversibility and explicit test signals.
if command -v eza >/dev/null 2>&1; then
  if [[ ${ZF_DISABLE_EZA_ALIAS:-0} != 1 ]]; then
    export ALIAS_LS_EZA=1
  else
    export ALIAS_LS_EZA=0
  fi
fi

# Manual validation:
#   command -v zoxide && echo 'zoxide ready'
#   ls (should resolve to eza variant if installed)
