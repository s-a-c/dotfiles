#!/usr/bin/env zsh
# Filename: 280-autopair.zsh
# Purpose:  P2.3 Optimization: Defer autopair to first prompt
# Phase:    Plugin activation (.zshrc.add-plugins.d/)
# Toggles:  ZF_DISABLE_AUTOPAIR_DEFER

zf::debug "# [autopair] Loading autopair functionality..."

# P2.3 Optimization: Defer autopair to first prompt
# ZLE widgets don't need to be available during shell initialization
# Estimated savings: ~20ms

: "${ZF_DISABLE_AUTOPAIR_DEFER:=0}"

if [[ "${ZF_DISABLE_AUTOPAIR_DEFER}" == "1" ]]; then
  # Eager loading (original behavior)
  if typeset -f zgenom >/dev/null 2>&1; then
    zgenom load hlissner/zsh-autopair || zf::debug "# [autopair] autopair plugin load failed"
    zf::debug "# [autopair] Autopair loaded eagerly (defer disabled)"
  else
    zf::debug "# [autopair] zgenom absent; skipping autopair plugin"
  fi
else
  # Deferred loading via precmd hook (loads before first prompt)
  if typeset -f zgenom >/dev/null 2>&1; then
    _zf_load_autopair() {
      zf::debug "# [autopair] Loading autopair on first prompt..."
      zgenom load hlissner/zsh-autopair || zf::debug "# [autopair] autopair plugin load failed"
      add-zsh-hook -d precmd _zf_load_autopair
      unset -f _zf_load_autopair
    }

    # Schedule loading before first prompt
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _zf_load_autopair
    zf::debug "# [autopair] Autopair deferred to first prompt (precmd hook)"
  else
    zf::debug "# [autopair] zgenom absent; skipping autopair plugin"
  fi
fi

zf::debug "# [autopair] Autopair functionality configured"

return 0
