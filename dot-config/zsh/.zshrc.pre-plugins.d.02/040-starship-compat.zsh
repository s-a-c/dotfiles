#!/usr/bin/env zsh
# Filename: 040-starship-compat.zsh
# Purpose:  Provides backward compatibility for Starship prompt configuration and Features: - Maps the legacy `ZF_ENABLE_STARSHIP=1` variable to the current `ZSH_DISABLE_STARSHIP=0` to ensure the prompt is enabled correctly if the old setting is still in use. Nounset Safety: All parameter expansions are guarded.
# Phase:    Pre-plugin (.zshrc.pre-plugins.d/)
# Toggles:  ZF_ENABLE_STARSHIP

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# .zshenv multi-load trace marker
if [[ -n ${__ZF_ZSHENV_ONCE:-} && -z ${__ZF_ZSHENV_ONCE_NOTICE:-} ]]; then
  zf::debug "# [starship-compat] Diagnostic: .zshenv appears to have been loaded more than once."
  __ZF_ZSHENV_ONCE_NOTICE=1
fi

# Legacy variable mapping (only if new var is not explicitly set)
if [[ -z ${ZSH_DISABLE_STARSHIP+x} && ${ZF_ENABLE_STARSHIP:-0} == 1 ]]; then
  export ZSH_DISABLE_STARSHIP=0
  zf::debug "# [starship-compat] Mapped legacy ZF_ENABLE_STARSHIP=1 -> ZSH_DISABLE_STARSHIP=0"
fi

return 0
