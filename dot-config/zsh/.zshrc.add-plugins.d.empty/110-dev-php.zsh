#!/usr/bin/env zsh
# 110-dev-php.zsh - PHP Development Environment for ZSH REDESIGN v2
# Phase 3A: PHP Environment (Herd + Traditional)
# Refactored from legacy 010-add-plugins.zsh (lines 54-69)
# PRE_PLUGIN_DEPS: none (Herd manages PHP environment)
# POST_PLUGIN_DEPS: 040-dev-php.zsh (Herd integration, Laravel aliases)
# RESTART_REQUIRED: no

# Check for post-plugin dependencies
_check_php_post_plugin_deps() {
  local missing_deps=()

  # Check if PHP post-plugin configuration exists
  if [[ ! -f "${ZDOTDIR}/.zshrc.d/040-dev-php.zsh" ]]; then
    missing_deps+=("040-dev-php.zsh (Herd integration & Laravel aliases)")
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo ""
    echo "💡 OPTIONAL: PHP post-plugin enhancements available"
    echo "📋 Recommended post-plugin additions:"
    for dep in "${missing_deps[@]}"; do
      echo "   - $dep"
    done
    echo "🔧 Add to .zshrc.d/ for enhanced PHP/Laravel integration"
    echo ""
  fi
}

# Skip if OMZ plugins disabled
if [[ "${ZSH_DISABLE_OMZ_PLUGINS:-0}" == "1" ]]; then
  zf::debug "# [dev-php] OMZ dev plugins disabled via ZSH_DISABLE_OMZ_PLUGINS=1"
  return 0
fi

# Check for optional post-plugin enhancements
_check_php_post_plugin_deps

zf::debug "# [dev-php] Loading PHP development environment..."

# Composer & Laravel (only if zgenom function present)
if typeset -f zgenom >/dev/null 2>&1; then
  zgenom oh-my-zsh plugins/composer || zf::debug "# [dev-php] composer plugin load failed"
  zgenom oh-my-zsh plugins/laravel || zf::debug "# [dev-php] laravel plugin load failed"
else
  zf::debug "# [dev-php] zgenom absent; skipping composer/laravel plugins"
fi

# Herd integration (primary PHP environment)
# Note: Herd NVM integration handled in 030-dev-node.zsh
if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/nvm" ]]; then
  zf::debug "# [dev-php] Herd environment detected"
  export HERD_PHP_PATH="/Users/s-a-c/Library/Application Support/Herd/bin"
  [[ -d "$HERD_PHP_PATH" ]] && export PATH="$HERD_PHP_PATH:$PATH"
  # Herd per-version INI scan directory exports (guarded)
  if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/php/84" ]]; then
    export HERD_PHP_84_INI_SCAN_DIR="/Users/s-a-c/Library/Application Support/Herd/config/php/84/"
    zf::debug "# [dev-php] Herd PHP 8.4 INI scan dir set"
  fi
  if [[ -d "/Users/s-a-c/Library/Application Support/Herd/config/php/85" ]]; then
    export HERD_PHP_85_INI_SCAN_DIR="/Users/s-a-c/Library/Application Support/Herd/config/php/85/"
    zf::debug "# [dev-php] Herd PHP 8.5 INI scan dir set"
  fi
fi

zf::debug "# [dev-php] PHP development environment loaded"

return 0
