#!/usr/bin/env zsh
# 445-p10k-hint.zsh - Centralized Powerlevel10k configuration hint (post-plugin phase)
# Phase: Post-plugin augmentation
# Purpose: Avoid scattered echo statements; provide optional p10k configure hint only when Starship is disabled.
# Toggle: ZSH_SHOW_P10K_HINT=1 to show hint when p10k config missing and starship disabled.
#         POWERLEVEL10K_DISABLE_CONFIGURATION_WIZARD can suppress p10k's own wizard but is orthogonal to this hint.
# Behavior:
#   - If ZSH_DISABLE_STARSHIP=1 AND .p10k.zsh missing AND ZSH_SHOW_P10K_HINT=1 => print hint.
#   - Otherwise silent.
# Idempotent: safe to source multiple times.

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

if [[ ${ZSH_DISABLE_STARSHIP:-0} == 1 && ${ZSH_SHOW_P10K_HINT:-0} == 1 ]]; then
  if [[ ! -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]]; then
    zf::debug "# [p10k-hint] showing configuration hint (p10k file missing, starship disabled)"
    echo "Run p10k configure or edit ${ZDOTDIR:-$HOME}/.p10k.zsh to configure your prompt"
  else
    zf::debug "# [p10k-hint] p10k file present; no hint emitted"
  fi
fi

return 0
