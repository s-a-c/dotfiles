#!/usr/bin/env zsh
# 510-npm-config-validator.zsh - NPM configuration validation and cleanup
# Purpose: Fix corrupted npm configuration and validate Herd compatibility
# Load Order: 510 (after history setup, before heavy tooling)

if [[ "${ZF_DISABLE_NPM_VALIDATION:-0}" == 1 ]]; then
  return 0
fi

# Only run if npm command is available
if ! command -v npm >/dev/null 2>&1; then
  return 0
fi

# =============================================================================
# Configuration Validation Functions
# =============================================================================

_npm_validate_config() {
  local config_key="$1"
  local expected_value="$2"
  local current_value

  current_value=$(npm config get "$config_key" 2>/dev/null || echo "undefined")

  case "$current_value" in
  "undefined" | "null" | "")
    # Expected unset/invalid values
    return 0
    ;;
  "$expected_value")
    # Already correct
    return 0
    ;;
  *)
    # Invalid value detected
    return 1
    ;;
  esac
}

_npm_fix_config() {
  local config_key="$1"
  local new_value="$2"
  local old_value

  old_value=$(npm config get "$config_key" 2>/dev/null || echo "undefined")

  if npm config set "$config_key" "$new_value" 2>/dev/null; then
    echo "✅ Fixed npm $config_key: '$old_value' → '$new_value'" >&2
    return 0
  else
    echo "⚠️  Failed to fix npm $config_key" >&2
    return 1
  fi
}

# =============================================================================
# Herd Compatibility Checks
# =============================================================================

# Check if we're in a Herd-managed environment
if [[ -n "${_ZF_HERD_NVM:-}" ]] || [[ -n "${_ZF_HERD_DETECTED:-}" ]]; then
  # Herd-specific npm configurations
  export NPM_CONFIG_GLOBALCONFIG="${NVM_DIR}/etc/npmrc"

  # Ensure Herd's npmrc exists and is readable
  if [[ ! -f "$NPM_CONFIG_GLOBALCONFIG" ]]; then
    mkdir -p "$(dirname "$NPM_CONFIG_GLOBALCONFIG")"
    touch "$NPM_CONFIG_GLOBALCONFIG" 2>/dev/null
  fi

  zf::debug "# [npm-validator] Herd environment detected, npmrc: $NPM_CONFIG_GLOBALCONFIG"
fi

# =============================================================================
# Configuration Fixes
# =============================================================================

# Fix corrupted 'before' configuration (primary issue from log)
if ! _npm_validate_config "before" "null"; then
  _npm_fix_config "before" "null"
fi

# Fix other potentially corrupted configurations
local corrupted_configs=(
  "prefix"
  "globalconfig"
  "userconfig"
)

for config in "${corrupted_configs[@]}"; do
  local current_value
  current_value=$(npm config get "$config" 2>/dev/null || echo "undefined")

  # Check for common corruption patterns
  if [[ "$current_value" == *".iterm2"* ]] || [[ "$current_value" == *".zshrc"* ]]; then
    _npm_fix_config "$config" ""
  fi
done

# =============================================================================
# Directory-Specific Safety
# =============================================================================

# Set safe npm defaults for dotfiles directory (no package.json)
if [[ "$PWD" == "/Users/s-a-c/dotfiles" ]] && [[ ! -f "package.json" ]]; then
  export npm_config_package_json_lock=false
  export npm_config_strict_ssl=false
  export npm_config_audit=false
  export npm_config_fund=false
  zf::debug "# [npm-validator] Applied safe defaults for dotfiles directory"
fi

# =============================================================================
# Export Validation Status
# =============================================================================

export _ZF_NPM_VALIDATION_COMPLETE=1
zf::debug "# [npm-validator] NPM configuration validation complete"
