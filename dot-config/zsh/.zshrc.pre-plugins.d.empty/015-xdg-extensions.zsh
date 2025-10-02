#!/usr/bin/env zsh
# 015-xdg-extensions.zsh - Early XDG-based environment enhancements
# Phase: 1 (auxiliary – follows core safety modules, precedes plugin loading)
#
# Purpose:
#   Provide early, idempotent exports for XDG-aware tooling that benefit from
#   a predictable configuration location before plugins and later environment
#   layers run. Currently focused on ripgrep configuration auto-discovery.
#
# Features Implemented:
#   - RIPGREP_CONFIG_PATH auto-export (if not already set) using common
#     XDG layouts:
#       • $XDG_CONFIG_HOME/ripgrep/ripgreprc
#       • $XDG_CONFIG_HOME/ripgrep/config
#
# Guarding & Safety:
#   - Nounset-safe expansions using ${var:-}
#   - Idempotent via _ZF_XDG_EXTENSIONS_DONE sentinel
#   - Does not create or mutate directories (avoids unintended side-effects)
#
# Debugging:
#   - Emits a debug line when a ripgrep config file is detected (if zf::debug exists)
#
# Conventions:
#   - Does NOT fail if paths are absent (silent skip)
#   - Leaves any pre-existing RIPGREP_CONFIG_PATH untouched
#
# Future Extension (if needed):
#   - Centralize other XDG-driven tool configs (e.g., fd, bat, stylua) with
#     the same minimal, guarded pattern.
#
# Success Criteria:
#   - Sourcing this file never produces errors under 'set -u'
#   - RIPGREP_CONFIG_PATH is available early when a config file exists
#
# -----------------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_XDG_EXTENSIONS_DONE:-} ]] && return 0
_ZF_XDG_EXTENSIONS_DONE=1

# Provide minimal debug stub if missing
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Ensure XDG_CONFIG_HOME fallback (do not create directories here)
: "${XDG_CONFIG_HOME:=${HOME}/.config}"

# Auto-detect ripgrep configuration if not already defined
if [[ -z ${RIPGREP_CONFIG_PATH:-} ]]; then
  # Candidate paths (ordered preference)
  local _rg_candidate1="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"
  local _rg_candidate2="${XDG_CONFIG_HOME}/ripgrep/config"

  if [[ -f "${_rg_candidate1}" ]]; then
    export RIPGREP_CONFIG_PATH="${_rg_candidate1}"
  elif [[ -f "${_rg_candidate2}" ]]; then
    export RIPGREP_CONFIG_PATH="${_rg_candidate2}"
  fi

  [[ -n ${RIPGREP_CONFIG_PATH:-} ]] && zf::debug "# [xdg-extensions] RIPGREP_CONFIG_PATH=${RIPGREP_CONFIG_PATH}"
  unset _rg_candidate1 _rg_candidate2
fi

return 0
