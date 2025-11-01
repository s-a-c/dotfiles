#!/usr/bin/env zsh
# Filename: 270-productivity-fzf.zsh
# Purpose:  Skip if OMZ plugins disabled
# Phase:    Plugin activation (.zshrc.add-plugins.d/)

if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" ]]; then
  zf::debug "# [productivity-fzf] OMZ fzf plugin disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
  return 0
fi

zf::debug "# [productivity-fzf] Loading FZF fuzzy finder integration..."

if typeset -f zgenom >/dev/null 2>&1; then
  zgenom oh-my-zsh plugins/fzf || zf::debug "# [productivity-fzf] fzf plugin load failed"
else
  zf::debug "# [productivity-fzf] zgenom absent; skipping fzf plugin"
fi

# Marker for dual-path productivity system.
# Fallback direct module (320-fzf.zsh) checks this to skip duplicate FZF keybinding/completion setup.
# See: plan-of-attack.md -> "Productivity Layer Dual-Path Strategy".
_ZF_PM_FZF_LOADED=1
zf::debug "# [productivity-fzf] FZF fuzzy finder integration loaded"

return 0
