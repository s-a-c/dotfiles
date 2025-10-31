#!/usr/bin/env zsh
# 260-productivity-nav.zsh - Directory Navigation & File Management for ZSH REDESIGN v2
# Phase 4B: Directory Navigation + FZF
# Refactored from legacy 010-add-plugins.zsh (lines 90-102)

# Skip if OMZ plugins disabled
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" ]]; then
  zf::debug "# [productivity-nav] OMZ file/nav plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
  return 0
fi

zf::debug "# [productivity-nav] Loading directory navigation and file management..."

# P2.3 Optimization: Defer navigation tool plugins
# Defers with 1-second delay for frequently-used but not critical-at-startup tools
# Estimated savings: ~40ms

: "${ZF_DISABLE_NAV_DEFER:=0}"

if [[ "${ZF_DISABLE_NAV_DEFER}" == "1" ]]; then
  # Eager loading (original behavior)
  if typeset -f zgenom >/dev/null 2>&1; then
    zgenom oh-my-zsh plugins/aliases || zf::debug "# [productivity-nav] aliases plugin load failed"
    zgenom oh-my-zsh plugins/eza || zf::debug "# [productivity-nav] eza plugin load failed"
    zgenom oh-my-zsh plugins/zoxide || zf::debug "# [productivity-nav] zoxide plugin load failed"
    zf::debug "# [productivity-nav] Navigation plugins loaded eagerly (defer disabled)"
  else
    zf::debug "# [productivity-nav] zgenom absent; skipping aliases/eza/zoxide"
  fi
else
  # Deferred loading (optimized)
  if typeset -f zgenom >/dev/null 2>&1 && typeset -f zsh-defer >/dev/null 2>&1; then
    zsh-defer -t 1 zgenom oh-my-zsh plugins/aliases
    zsh-defer -t 1 zgenom oh-my-zsh plugins/eza
    zsh-defer -t 1 zgenom oh-my-zsh plugins/zoxide
    zf::debug "# [productivity-nav] Navigation plugins deferred (1s delay)"
  elif typeset -f zgenom >/dev/null 2>&1; then
    # Fallback: load eagerly if zsh-defer not available
    zgenom oh-my-zsh plugins/aliases || zf::debug "# [productivity-nav] aliases plugin load failed"
    zgenom oh-my-zsh plugins/eza || zf::debug "# [productivity-nav] eza plugin load failed"
    zgenom oh-my-zsh plugins/zoxide || zf::debug "# [productivity-nav] zoxide plugin load failed"
    zf::debug "# [productivity-nav] Navigation plugins loaded eagerly (zsh-defer unavailable)"
  else
    zf::debug "# [productivity-nav] zgenom absent; skipping aliases/eza/zoxide"
  fi
fi

# Marker for dual-path productivity system.
# Fallback direct module (310-navigation.zsh) checks this to skip duplicate nav/eza/zoxide setup.
# See: plan-of-attack.md -> "Productivity Layer Dual-Path Strategy".
_ZF_PM_NAV_LOADED=1
zf::debug "# [productivity-nav] Directory navigation and file management configured"

return 0
