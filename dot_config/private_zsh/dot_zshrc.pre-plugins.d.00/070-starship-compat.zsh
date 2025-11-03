#!/usr/bin/env zsh
# 060-starship-compat.zsh - Legacy Starship env compatibility & diagnostics
# Phase: pre-plugins (ensures mapping before prompt layer in post-plugin phase)
# Purpose:
#   - Map legacy ZF_ENABLE_STARSHIP=1 -> ZSH_DISABLE_STARSHIP=0 when unset
#   - Provide optional .zshenv multi-load diagnostics guard marker
# Dependencies: zf::debug (from .zshenv), none hard required

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# .zshenv multi-load trace marker (only note on subsequent hits)
if [[ -n ${__ZF_ZSHENV_ONCE:-} && -z ${__ZF_ZSHENV_ONCE_NOTICE:-} ]]; then
  # If .zshenv set the marker earlier we can surface one-time debug here
  : # placeholder if we decide to surface additional info later
fi

# Legacy variable mapping (only if new var not explicitly set)
if [[ -z ${ZSH_DISABLE_STARSHIP+x} && ${ZF_ENABLE_STARSHIP:-0} == 1 ]]; then
  export ZSH_DISABLE_STARSHIP=0
  zf::debug "# [starship-compat] Mapped legacy ZF_ENABLE_STARSHIP=1 -> ZSH_DISABLE_STARSHIP=0"
fi

return 0
