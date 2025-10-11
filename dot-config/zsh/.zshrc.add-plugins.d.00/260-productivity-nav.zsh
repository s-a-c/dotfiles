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

if typeset -f zgenom >/dev/null 2>&1; then
  zgenom oh-my-zsh plugins/aliases || zf::debug "# [productivity-nav] aliases plugin load failed"
  zgenom oh-my-zsh plugins/eza || zf::debug "# [productivity-nav] eza plugin load failed"
  zgenom oh-my-zsh plugins/zoxide || zf::debug "# [productivity-nav] zoxide plugin load failed"
else
  zf::debug "# [productivity-nav] zgenom absent; skipping aliases/eza/zoxide"
fi

# Marker for dual-path productivity system.
# Fallback direct module (310-navigation.zsh) checks this to skip duplicate nav/eza/zoxide setup.
# See: plan-of-attack.md -> "Productivity Layer Dual-Path Strategy".
_ZF_PM_NAV_LOADED=1
zf::debug "# [productivity-nav] Directory navigation and file management loaded"

return 0
