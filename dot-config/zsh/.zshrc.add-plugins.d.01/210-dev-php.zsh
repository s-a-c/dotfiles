#!/usr/bin/env zsh
# Filename: 210-dev-php.zsh
# Purpose:  Skip if OMZ plugins disabled
# Phase:    Plugin activation (.zshrc.add-plugins.d/)
# Toggles:  ZF_DISABLE_PHP_LAZY_LOAD

zf::debug "# [dev-php] Loading PHP development environment..."

# Skip if OMZ plugins disabled
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" ]]; then
  zf::debug "# [dev-php] OMZ dev plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
  return 0
fi

# P2.3 Optimization: Lazy-load PHP plugins on first use
# Instead of loading immediately, create wrapper functions that load on-demand
# Estimated savings: ~80ms

: "${ZF_DISABLE_PHP_LAZY_LOAD:=0}"

if [[ "${ZF_DISABLE_PHP_LAZY_LOAD}" == "1" ]]; then
  # Eager loading (original behavior)
  if typeset -f zgenom >/dev/null 2>&1; then
    zgenom oh-my-zsh plugins/composer || zf::debug "# [dev-php] composer plugin load failed"
    zgenom oh-my-zsh plugins/laravel || zf::debug "# [dev-php] laravel plugin load failed"
    zf::debug "# [dev-php] PHP plugins loaded eagerly (lazy-load disabled)"
  else
    zf::debug "# [dev-php] zgenom absent; skipping composer/laravel plugins"
  fi
else
  # Lazy loading via command wrappers
  typeset -g _zf_php_plugins_loaded=0

  _zf_load_php_plugins() {
    if ((_zf_php_plugins_loaded == 0)) && typeset -f zgenom >/dev/null 2>&1; then
      zf::debug "# [dev-php] Loading PHP plugins on-demand..."
      zgenom oh-my-zsh plugins/composer || zf::debug "# [dev-php] composer plugin load failed"
      zgenom oh-my-zsh plugins/laravel || zf::debug "# [dev-php] laravel plugin load failed"
      _zf_php_plugins_loaded=1
      zf::debug "# [dev-php] PHP plugins loaded on-demand"
    fi
  }

  # Wrapper for composer command (primary trigger)
  composer() {
    _zf_load_php_plugins
    unfunction composer 2>/dev/null || true
    composer "$@"
  }

  # Optional: Wrapper for Laravel installer (if installed globally)
  if command -v laravel >/dev/null 2>&1; then
    laravel() {
      _zf_load_php_plugins
      unfunction laravel 2>/dev/null || true
      laravel "$@"
    }
    zf::debug "# [dev-php] Created lazy-load wrappers for composer and laravel"
  else
    zf::debug "# [dev-php] Created lazy-load wrapper for composer"
  fi
fi

zf::debug "# [dev-php] PHP development environment configured"

return 0
