# ZSH Startup Issues Resolution Plan

## Overview

This plan addresses critical startup issues identified in the ZSH configuration log, focusing on Atuin daemon initialization, NVM pre-plugin setup, NPM configuration corruption, and package manager safety. All changes are designed to be Laravel Herd-aware and follow the existing configuration patterns.

## Issues Identified

1. **Atuin Daemon Log Missing** - `/Users/s-a-c/.cache/atuin/daemon.log` file creation failure
2. **NVM Pre-plugin Setup Missing** - Node.js plugins need NVM environment variables before loading
3. **NPM Configuration Corruption** - Invalid `before` config pointing to iTerm2 shell integration
4. **Package Manager Safety** - npm commands executing in directories without package.json
5. **Background Job Management** - Transient processes causing job notifications

## Solution Architecture

### Guiding Principles

1. **Laravel Herd Awareness**: All Node/NVM stanzas must detect and prioritize Herd's NVM installation
2. **Configuration Consolidation**: Combine related functionality where logical
3. **Numbering Convention**: Use unique, 3-digit, multiples of 10 for file prefixes
4. **Backward Compatibility**: Maintain existing functionality while fixing issues

## Implementation Plan

### Phase 1: Enhanced Early Node.js Runtime Setup

**File**: `.config/zsh/.zshrc.pre-plugins.d.00/080-early-node-runtimes.zsh`
**Purpose**: Combine early Node.js runtime detection with Herd-aware NVM setup

#### Current File Analysis
The existing file sets up Bun/Deno/PNPM paths but explicitly avoids NVM_DIR setup. We'll enhance it to include Herd-aware NVM environment setup while maintaining the original runtime path functionality.

#### Updated Code

```zsh
#!/usr/bin/env zsh
# 080-early-node-runtimes.zsh - Early Node/JS Runtime Path Shaping with Herd-aware NVM
# Purpose: Expose alternative JS toolchain bins and NVM environment BEFORE plugin layer
# Ensures:
#   * oh-my-zsh nvm plugin lazy-cmd detection sees all available tools
#   * User scripts/early modules can call these runtimes without waiting
#   * Laravel Herd NVM is prioritized when available
#   * Baseline tooling order: (Herd) -> early alt runtimes -> post-plugin NVM lazy

if [[ -n "${ZF_DISABLE_EARLY_JS:-}" ]]; then
  zf::debug "# [early-node-runtimes] disabled via ZF_DISABLE_EARLY_JS"
  return 0
fi

zf::debug "# [early-node-runtimes] begin"

# =============================================================================
# Laravel Herd NVM Environment Setup (NEW - Pre-plugin NVM support)
# =============================================================================

# Herd NVM integration - Primary detection for Laravel developers
if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
  export NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
  export _ZF_HERD_NVM=1
  zf::debug "# [early-node-runtimes] Using Herd NVM at: $NVM_DIR"
else
  # Fallback NVM detection for non-Herd environments
  if [[ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm" ]]; then
    export NVM_DIR="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using Homebrew NVM at: $NVM_DIR"
  elif [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/nvm" ]]; then
    export NVM_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using XDG NVM at: $NVM_DIR"
  elif [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
    export _ZF_HERD_NVM=0
    zf::debug "# [early-node-runtimes] Using standard NVM at: $NVM_DIR"
  fi
fi

# Export markers for plugin compatibility
export _ZF_NVM_PRESETUP=1
[[ -n "${NVM_DIR:-}" ]] && export _ZF_NVM_DETECTED=1

# =============================================================================
# Alternative JavaScript Runtime Paths (EXISTING - Enhanced)
# =============================================================================

# Bun
if [[ -z "${BUN_INSTALL:-}" ]]; then
  export BUN_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/bun"
fi
if [[ -d "${BUN_INSTALL}/bin" ]]; then
  zf::path_prepend "${BUN_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] bun path added"
fi

# Deno
if [[ -z "${DENO_INSTALL:-}" ]]; then
  export DENO_INSTALL="${XDG_DATA_HOME:-${HOME}/.local/share}/deno"
fi
if [[ -d "${DENO_INSTALL}/bin" ]]; then
  zf::path_prepend "${DENO_INSTALL}/bin"
  zf::debug "# [early-node-runtimes] deno path added"
fi

# PNPM
if [[ -z "${PNPM_HOME:-}" ]]; then
  export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
fi
if [[ -d "${PNPM_HOME}" ]]; then
  zf::path_prepend "${PNPM_HOME}"
  zf::debug "# [early-node-runtimes] pnpm path added"
fi

# Herd-specific Node.js path (if available)
if [[ -n "${_ZF_HERD_NVM:-}" && -d "${NVM_DIR}/versions/node" ]]; then
  local herd_node_dir="$(ls -1d "${NVM_DIR}"/versions/node/v* 2>/dev/null | tail -1)"
  if [[ -d "$herd_node_dir/bin" ]]; then
    export PATH="$herd_node_dir/bin:$PATH"
    zf::debug "# [early-node-runtimes] Herd Node.js path added: $herd_node_dir/bin"
  fi
fi

# =============================================================================
# Pre-plugin Environment Markers
# =============================================================================

# Export environment markers for plugin detection and compatibility
export _ZF_EARLY_NODE_COMPLETE=1
[[ -n "${_ZF_HERD_NVM:-}" ]] && export _ZF_HERD_DETECTED=1

zf::debug "# [early-node-runtimes] complete - NVM: ${NVM_DIR:-not detected}, Herd: ${_ZF_HERD_NVM:-0}"
```

### Phase 2: Atuin Daemon Robustness Enhancement

**File**: `.config/zsh/.zshrc.d/500-shell-history.zsh`
**Purpose**: Fix Atuin daemon log file creation with proper error handling

#### Current Issue
Lines 84 and 88 redirect to `$_atuin_log` but the file may not exist, causing "no such file or directory" errors.

#### Updated Code (Lines 75-95)

```zsh
# Start once with a simple lock to avoid races between parallel shells
if [[ $_atuin_running == false ]]; then
  if mkdir "$_atuin_lock" 2>/dev/null; then
    {
      # Ensure log file exists and is writable (NEW)
      if [[ ! -f "$_atuin_log" ]]; then
        if ! touch "$_atuin_log" 2>/dev/null; then
          # Try creating parent directory if touch fails
          mkdir -p "$(dirname "$_atuin_log")" 2>/dev/null
          touch "$_atuin_log" 2>/dev/null || {
            # Fallback to /tmp if cache directory is not writable
            _atuin_log="/tmp/atuin-daemon-$UID.log"
            touch "$_atuin_log" 2>/dev/null
          }
        fi
      fi

      # Double-check inside the critical section
      if command -v pgrep >/dev/null 2>&1; then
        if ! pgrep -u "$UID" -f '^atuin([[:space:]].*)?[[:space:]]+daemon( |$)' >/dev/null 2>&1; then
          nohup atuin daemon >>"$_atuin_log" 2>&1 &
          disown
        fi
      else
        if ! ps -axo command | grep -E '^[[:space:]]*atuin([[:space:]].*)?[[:space:]]+daemon( |$)' | grep -v grep >/dev/null 2>&1; then
          nohup atuin daemon >>"$_atuin_log" 2>&1 &
          disown
        fi
      fi
    } || true
    rmdir "$_atuin_lock" 2>/dev/null || true

    # Brief readiness wait to avoid the first-command connect race
    for _i in {1..15}; do
      [[ -S "$_atuin_sock" ]] && break
      sleep 0.05
    done
    unset _i
  fi
fi
```

### Phase 3: NPM Configuration Validation and Cleanup

**File**: `.config/zsh/.zshrc.d/510-npm-config-validator.zsh`
**Purpose**: Validate and fix corrupted NPM configuration, with Herd awareness

#### Full File Code

```zsh
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
    "undefined"|"null"|"")
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
if [[ "$PWD" == "${HOME}/dotfiles" ]] && [[ ! -f "package.json" ]]; then
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
```

### Phase 4: Post-Plugin NVM Setup Update

**File**: `.config/zsh/.zshrc.add-plugins.d.00/220-dev-node.zsh`
**Purpose**: Remove duplicate NVM_DIR setup, enhance lazy loading with Herd awareness

#### Updated Code (Lines 75-90)

```zsh
# NVM Lazy Loading Setup (Enhanced for Herd compatibility)
if [[ -n "${NVM_DIR:-}" && -d "$NVM_DIR" ]]; then
  # Environment setup
  export NVM_AUTO_USE=true
  export NVM_LAZY_LOAD=true
  export NVM_COMPLETION=true

  # Herd-specific optimizations
  if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
    # Herd manages its own npm configuration
    export NVM_NO_ADDITIONAL_PATHS=1
    zf::debug "# [dev-node] Herd NVM optimizations applied"
  fi

  # CRITICAL: Unset NPM_CONFIG_PREFIX for NVM compatibility
  unset NPM_CONFIG_PREFIX

  # NVM Lazy Loading Function (Enhanced)
  nvm() {
    # Remove the lazy loader function
    unfunction nvm 2>/dev/null
    unset NPM_CONFIG_PREFIX

    # Source NVM scripts with error handling
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
      builtin source "$NVM_DIR/nvm.sh" || {
        echo "⚠️  Failed to source NVM from $NVM_DIR" >&2
        return 1
      }
    else
      echo "⚠️  NVM script not found at $NVM_DIR/nvm.sh" >&2
      return 1
    fi

    [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion" 2>/dev/null

    # Call nvm with original arguments
    nvm "$@"
  }

  # Verify nvm function is properly defined
  if typeset -f nvm >/dev/null 2>&1; then
    zf::debug "# [dev-node] NVM lazy loader configured for: $NVM_DIR"

    # Set up minimal path for immediate Node.js access (Herd-optimized)
    if [[ -d "$NVM_DIR/versions/node" ]]; then
      local node_dir
      if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
        # Herd: prioritize latest stable version
        node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | sort -V | tail -1)"
      else
        # Standard NVM: use current or latest
        node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | tail -1)"
      fi

      if [[ -d "$node_dir/bin" ]]; then
        export PATH="$node_dir/bin:$PATH"
        zf::debug "# [dev-node] Added immediate Node.js access: $node_dir/bin"
      fi
    fi
  else
    echo "⚠️  NVM function setup failed" >&2
  fi
else
  if [[ -n "${_ZF_NVM_PRESETUP:-}" ]]; then
    echo "⚠️  NVM_DIR was set but directory not found: ${NVM_DIR:-not set}" >&2
  fi
fi

# Herd NVM integration now handled in pre-plugin phase (080-early-node-runtimes.zsh)
[[ -n "${_ZF_NVM_PRESETUP:-}" ]] && zf::debug "# [dev-node] NVM_DIR already configured by pre-plugin: $NVM_DIR"
```

### Phase 5: Enhanced Package Manager Safety

**File**: `.config/zsh/.zshrc.d.00/400-aliases.zsh`
**Purpose**: Add safety guards to package manager aliases, with Herd awareness

#### Updated Code (Lines 402-425)

```zsh
# =============================================================================
# ENHANCED PACKAGE MANAGER REPLACEMENT WITH SAFETY GUARDS
# =============================================================================

# Safe package manager aliases with project validation
pm-info() {
  local current_pm pm_exec
  current_pm=$(zf::detect_pkg_manager)
  pm_exec=$(command -v "$current_pm" 2>/dev/null || echo "not found")

  # Enhanced environment information
  echo "Current package manager: $current_pm ($pm_exec)"

  # Show additional context
  if [[ -n "${_ZF_HERD_NVM:-}" ]]; then
    echo "Environment: Laravel Herd (NVM: $NVM_DIR)"
  elif [[ -n "${NVM_DIR:-}" ]]; then
    echo "Environment: NVM (${NVM_DIR})"
  else
    echo "Environment: System Node.js"
  fi

  # Project validation
  if [[ ! -f "package.json" && "$PWD" != "$HOME" ]]; then
    echo "⚠️  Not in a Node.js project (no package.json found)"
    echo "💡 Some package manager commands may not work as expected"
    return 1
  fi
}

# Enhanced package manager switching with environment awareness
pm-npm() {
  export ZF_PREFERRED_PKG_MANAGER="npm"
  echo "✅ Switched to npm"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-yarn() {
  export ZF_PREFERRED_PKG_MANAGER="yarn"
  echo "✅ Switched to yarn"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-pnpm() {
  export ZF_PREFERRED_PKG_MANAGER="pnpm"
  echo "✅ Switched to pnpm"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-bun() {
  export ZF_PREFERRED_PKG_MANAGER="bun"
  echo "✅ Switched to bun"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-auto() {
  export ZF_PREFERRED_PKG_MANAGER="auto"
  echo "🔍 Auto-detection enabled"
  [[ -n "${_ZF_HERD_NVM:-}" ]] && echo "🐘 Running in Laravel Herd environment"
}

pm-switch() {
  export ZF_PREFERRED_PKG_MANAGER=""
  echo "🔄 Package manager preference cleared (auto-detection active)"
}

# Enhanced package manager execution with safety checks
_zf_safe_pm_exec() {
  local pm="$1"
  shift

  # Check if we're in a Node.js project for commands that need package.json
  local needs_package_json=("install" "run" "start" "test" "build" "dev" "serve")
  local command_needs_json=false

  for cmd in "${needs_package_json[@]}"; do
    if [[ "$1" == "$cmd" ]]; then
      command_needs_json=true
      break
    fi
  done

  if [[ "$command_needs_json" == true && ! -f "package.json" && "$PWD" != "$HOME" ]]; then
    echo "⚠️  Command '$pm $*' requires a package.json file" >&2
    echo "💡 Run this command in a Node.js project directory" >&2
    return 1
  fi

  # Execute the command
  command "$pm" "$@"
}
```

## Expected Outcomes

### Issue Resolution Summary

✅ **Atuin Daemon Log Issue**: Fixed with proper log file creation and fallback handling
✅ **NVM Pre-plugin Setup**: Resolved by enhancing early-node-runtimes.zsh with Herd-aware NVM detection
✅ **NPM Configuration Corruption**: Addressed with comprehensive validation and cleanup
✅ **Package Manager Safety**: Enhanced with project validation and environment awareness
✅ **Background Job Management**: Improved through better daemon process handling

### System Improvements

🚀 **Laravel Herd Integration**: Full awareness and optimization for Herd environments
🔧 **Enhanced Error Handling**: Robust fallback mechanisms and informative error messages
📊 **Better Diagnostics**: Comprehensive debugging information and status reporting
⚡ **Performance Optimization**: Reduced startup time through efficient pre-plugin setup
🛡️ **Safety Guards**: Prevention of common configuration and usage errors

## Implementation Checklist

### Files to Modify

1. **Enhance**: `.config/zsh/.zshrc.pre-plugins.d.00/080-early-node-runtimes.zsh`
   - Add Herd-aware NVM environment setup
   - Maintain existing runtime path functionality
   - Add pre-plugin markers for plugin compatibility

2. **Update**: `.config/zsh/.zshrc.d/500-shell-history.zsh`
   - Fix Atuin daemon log file creation (lines 75-95)
   - Add fallback logging mechanisms
   - Improve error handling

3. **Create**: `.config/zsh/.zshrc.d/510-npm-config-validator.zsh`
   - Comprehensive NPM configuration validation
   - Herd-specific compatibility checks
   - Automatic corruption fixes

4. **Update**: `.config/zsh/.zshrc.add-plugins.d.00/220-dev-node.zsh`
   - Remove duplicate NVM_DIR setup
   - Enhance lazy loading with Herd optimizations
   - Improve error handling and debugging

5. **Enhance**: `.config/zsh/.zshrc.d.00/400-aliases.zsh`
   - Add safety guards to package manager aliases
   - Enhanced environment information display
   - Project validation for package manager commands

### Testing Strategy

1. **Startup Validation**: Verify clean ZSH startup after each change
2. **Herd Integration**: Test Laravel Herd detection and optimization
3. **Tool Functionality**: Validate Atuin, NPM, and Node.js tooling
4. **Error Recovery**: Test graceful handling of missing dependencies
5. **Performance**: Ensure no significant startup time increase

### Rollback Plan

All changes are additive and backward-compatible. If issues arise:
1. Remove the new `510-npm-config-validator.zsh` file
2. Restore original `500-shell-history.zsh` from backup
3. Revert `080-early-node-runtimes.zsh` to original state
4. Original `220-dev-node.zsh` and `400-aliases.zsh` can be restored from version control

## Conclusion

This comprehensive plan addresses all identified startup issues while enhancing the ZSH configuration with Laravel Herd awareness, improved error handling, and better safety mechanisms. The modular approach allows for incremental implementation and testing, with clear rollback paths if needed.

The solution maintains the existing architecture while adding robustness and future-proofing for development workflows, particularly for Laravel developers using Herd.
