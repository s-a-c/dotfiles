#!/usr/bin/env zsh
# 250-dev-github.zsh - GitHub CLI Integration for ZSH REDESIGN v2
# Phase 3D: GitHub Integration
# Refactored from legacy 010-add-plugins.zsh (lines 62-63)

# Skip if OMZ plugins disabled
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" ]]; then
  zf::debug "# [dev-github] OMZ dev plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
  return 0
fi

zf::debug "# [dev-github] Loading GitHub CLI integration..."

# P2.3 Optimization: Defer GitHub CLI plugin loading
# Defers with 2-second delay for occasional GitHub operations
# Estimated savings: ~60ms

: "${ZF_DISABLE_GITHUB_DEFER:=0}"

if [[ "${ZF_DISABLE_GITHUB_DEFER}" == "1" ]]; then
  # Eager loading (original behavior)
  if typeset -f zgenom >/dev/null 2>&1; then
    zgenom oh-my-zsh plugins/gh || zf::debug "# [dev-github] gh plugin load failed"
    zf::debug "# [dev-github] GitHub CLI plugin loaded eagerly (defer disabled)"
  else
    zf::debug "# [dev-github] zgenom absent; skipping gh plugin"
  fi
else
  # Deferred loading (optimized)
  if typeset -f zgenom >/dev/null 2>&1 && typeset -f zsh-defer >/dev/null 2>&1; then
    zsh-defer -t 2 zgenom oh-my-zsh plugins/gh
    zf::debug "# [dev-github] GitHub CLI plugin deferred (2s delay)"
  elif typeset -f zgenom >/dev/null 2>&1; then
    # Fallback: load eagerly if zsh-defer not available
    zgenom oh-my-zsh plugins/gh || zf::debug "# [dev-github] gh plugin load failed"
    zf::debug "# [dev-github] GitHub CLI plugin loaded eagerly (zsh-defer unavailable)"
  else
    zf::debug "# [dev-github] zgenom absent; skipping gh plugin"
  fi
fi

# GitHub Copilot CLI alias integration (optional)
# Guarded: only if gh present AND copilot subcommand available (GitHub CLI version dependent)
if command -v gh >/dev/null 2>&1; then
  if gh help copilot >/dev/null 2>&1; then
    if eval "$(gh copilot alias -- zsh)" 2>/dev/null; then
      zf::debug "# [dev-github] Copilot alias integration active"
    else
      zf::debug "# [dev-github] Copilot alias setup failed (non-fatal)"
    fi
  else
    zf::debug "# [dev-github] Copilot subcommand not available in this gh build"
  fi
fi

zf::debug "# [dev-github] GitHub CLI integration loaded"

return 0
