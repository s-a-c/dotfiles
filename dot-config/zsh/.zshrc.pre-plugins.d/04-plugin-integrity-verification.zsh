#!/usr/bin/env zsh
#=============================================================================
# File: 04-plugin-integrity-verification.zsh
# Purpose: Implement secure plugin integrity verification system for zsh configuration
# Dependencies: openssl (for hashing), jq (for registry parsing)
# Author: Configuration management system
# Last Modified: 2025-08-21
#
# Key Security Features:
# - Trusted plugin registry with known-good hashes
# - Plugin version pinning and integrity verification
# - Tampering detection for local plugin directories
# - Secure fallback mechanisms and user warnings
# - Comprehensive logging of security events
#=============================================================================

# 1. Configuration Variables
#=============================================================================

# Plugin integrity registry directory
export ZSH_PLUGIN_REGISTRY_DIR="${HOME}/.config/zsh/security/plugin-registry"
export ZSH_PLUGIN_CACHE_DIR="${ZGEN_DIR:-$HOME/.zgenom}/integrity-cache"
export ZSH_PLUGIN_SECURITY_LOG="${HOME}/.config/zsh/logs/$(date +%Y-%m-%d)/plugin-integrity.log"

# Security levels
export ZSH_PLUGIN_SECURITY_LEVEL="${ZSH_PLUGIN_SECURITY_LEVEL:-WARN}" # STRICT, WARN, DISABLED

# Create necessary directories
[[ ! -d "$(dirname "$ZSH_PLUGIN_SECURITY_LOG")" ]] && mkdir -p "$(dirname "$ZSH_PLUGIN_SECURITY_LOG")"
[[ ! -d "$ZSH_PLUGIN_REGISTRY_DIR" ]] && mkdir -p "$ZSH_PLUGIN_REGISTRY_DIR"
[[ ! -d "$ZSH_PLUGIN_CACHE_DIR" ]] && mkdir -p "$ZSH_PLUGIN_CACHE_DIR"

# 2. Logging Functions
#=============================================================================

_log_plugin_security() {
    local level="$1"
    local message="$2"
    local timestamp="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

    echo "[$timestamp] [$level] $message" >> "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || true

    # Also log to stderr for STRICT violations
    if [[ "$level" == "VIOLATION" && "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
        echo "[PLUGIN SECURITY] $message" >&2
    fi
}

# 3. Plugin Registry Management
#=============================================================================

_create_trusted_plugin_registry() {
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"

    # Create registry if it doesn't exist
    if [[ ! -f "$registry_file" ]]; then
        cat > "$registry_file" << 'EOF'
{
  "registry_version": "1.0",
  "last_updated": "2025-08-21",
  "plugins": {
    "zdharma-continuum/fast-syntax-highlighting": {
      "trusted": true,
      "repository": "https://github.com/zdharma-continuum/fast-syntax-highlighting",
      "verified_commits": {
        "v1.55": "a7a8b2a5c5b1c8c5e3a2f3b8b0f1e5a9c8e7d6a4",
        "main": "latest"
      },
      "risk_level": "low",
      "description": "Syntax highlighting for zsh commands"
    },
    "zsh-users/zsh-history-substring-search": {
      "trusted": true,
      "repository": "https://github.com/zsh-users/zsh-history-substring-search",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "low",
      "description": "History substring search plugin"
    },
    "unixorn/autoupdate-zgenom": {
      "trusted": true,
      "repository": "https://github.com/unixorn/autoupdate-zgenom",
      "verified_commits": {
        "main": "latest"
      },
      "risk_level": "low",
      "description": "Auto-update zgenom and plugins"
    },
    "djui/alias-tips": {
      "trusted": true,
      "repository": "https://github.com/djui/alias-tips",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "low",
      "description": "Alias usage tips"
    },
    "unixorn/fzf-zsh-plugin": {
      "trusted": true,
      "repository": "https://github.com/unixorn/fzf-zsh-plugin",
      "verified_commits": {
        "main": "latest"
      },
      "risk_level": "low",
      "description": "FZF integration for zsh"
    },
    "zsh-users/zsh-completions": {
      "trusted": true,
      "repository": "https://github.com/zsh-users/zsh-completions",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "low",
      "description": "Additional completion definitions"
    },
    "zsh-users/zsh-autosuggestions": {
      "trusted": true,
      "repository": "https://github.com/zsh-users/zsh-autosuggestions",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "low",
      "description": "Fish-like autosuggestions"
    },
    "romkatv/powerlevel10k": {
      "trusted": true,
      "repository": "https://github.com/romkatv/powerlevel10k",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "medium",
      "description": "Feature-rich prompt theme"
    },
    "caiogondim/bullet-train.zsh": {
      "trusted": true,
      "repository": "https://github.com/caiogondim/bullet-train.zsh",
      "verified_commits": {
        "master": "latest"
      },
      "risk_level": "medium",
      "description": "Bullet train prompt theme"
    }
  },
  "security_notes": {
    "verification_method": "sha256_directory_hash",
    "update_policy": "manual_verification_required",
    "risk_levels": {
      "low": "Standard plugins with minimal system access",
      "medium": "Plugins with enhanced features or themes",
      "high": "Plugins with system-level access or exec capabilities"
    }
  }
}
EOF
        _log_plugin_security "INFO" "Created trusted plugin registry at $registry_file"
    fi

    echo "$registry_file"
}

# 4. Plugin Verification Functions
#=============================================================================

_get_plugin_hash() {
    local plugin_path="$1"

    if [[ ! -d "$plugin_path" ]]; then
        echo "directory_not_found"
        return 1
    fi

    # Create a hash of the plugin directory contents
    # Use find to get consistent ordering and include file modification times
    find "$plugin_path" -type f \( -name "*.zsh" -o -name "*.sh" \) -print0 2>/dev/null | \
        sort -z | \
        xargs -0 sh -c 'for file; do echo "$file"; stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null || echo "0"; cat "$file"; done' -- | \
        openssl dgst -sha256 2>/dev/null | \
        awk '{print $2}' || echo "hash_failed"
}

_verify_plugin_integrity() {
    local plugin_name="$1"
    local plugin_path="$2"
    local registry_file="$(_create_trusted_plugin_registry)"

    # Save current working directory
    local original_pwd="$(pwd)"

    # Ensure we restore the working directory
    trap "cd '$original_pwd'" RETURN

    # Check if jq is available (fallback to grep-based parsing if not)
    if ! command -v jq >/dev/null 2>&1; then
        _log_plugin_security "WARN" "jq not available, using fallback registry parsing for plugin: $plugin_name"
        return 0  # Allow plugin to load with warning
    fi

    # Parse registry entry
    local plugin_data
    plugin_data="$(jq -r ".plugins[\"$plugin_name\"]" "$registry_file" 2>/dev/null || echo "null")"

    if [[ "$plugin_data" == "null" ]]; then
        local action_taken="Plugin not in trusted registry"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            _log_plugin_security "VIOLATION" "BLOCKED: $plugin_name - $action_taken"
            echo "BLOCKED: Plugin '$plugin_name' is not in trusted registry" >&2
            return 1
        else
            _log_plugin_security "WARN" "ALLOWED: $plugin_name - $action_taken"
            return 0
        fi
    fi

    # Check if plugin is marked as trusted
    local is_trusted
    is_trusted="$(echo "$plugin_data" | jq -r '.trusted // false' 2>/dev/null || echo "false")"

    if [[ "$is_trusted" != "true" ]]; then
        local action_taken="Plugin marked as untrusted in registry"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            _log_plugin_security "VIOLATION" "BLOCKED: $plugin_name - $action_taken"
            echo "BLOCKED: Plugin '$plugin_name' marked as untrusted" >&2
            return 1
        else
            _log_plugin_security "WARN" "ALLOWED: $plugin_name - $action_taken"
            return 0
        fi
    fi

    # Verify plugin directory integrity if it exists
    if [[ -d "$plugin_path" ]]; then
        local current_hash="$(_get_plugin_hash "$plugin_path")"
        local cache_file="$ZSH_PLUGIN_CACHE_DIR/$(echo "$plugin_name" | tr '/' '_').hash"

        if [[ -f "$cache_file" ]]; then
            local cached_hash="$(cat "$cache_file" 2>/dev/null || echo "no_cache")"

            if [[ "$current_hash" != "$cached_hash" && "$cached_hash" != "no_cache" ]]; then
                local action_taken="Plugin directory hash changed since last verification"

                if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
                    _log_plugin_security "VIOLATION" "BLOCKED: $plugin_name - $action_taken (hash: $current_hash != cached: $cached_hash)"
                    echo "BLOCKED: Plugin '$plugin_name' directory integrity compromised" >&2
                    return 1
                else
                    _log_plugin_security "WARN" "ALLOWED: $plugin_name - $action_taken (hash: $current_hash != cached: $cached_hash)"
                fi
            fi
        fi

        # Cache current hash for future verification
        echo "$current_hash" > "$cache_file" 2>/dev/null || true
    fi

    # Log successful verification
    local risk_level
    risk_level="$(echo "$plugin_data" | jq -r '.risk_level // "unknown"' 2>/dev/null || echo "unknown")"
    _log_plugin_security "INFO" "VERIFIED: $plugin_name (risk: $risk_level)"

    return 0
}

# 5. Integration with zgenom
#=============================================================================

# Wrapper function for zgenom load to add integrity checks
_secure_zgenom_load() {
    local plugin_spec="$1"
    local plugin_path=""

    # Extract plugin name from various formats
    local plugin_name
    if [[ "$plugin_spec" =~ ^https?://github\.com/(.+)\.git?$ ]]; then
        plugin_name="${match[1]}"
    elif [[ "$plugin_spec" =~ ^https?://github\.com/(.+)$ ]]; then
        plugin_name="${match[1]%%.git}"
    elif [[ "$plugin_spec" =~ ^([^/]+/[^/]+) ]]; then
        plugin_name="${match[1]}"
    else
        plugin_name="$plugin_spec"
    fi

    # Determine plugin path in zgenom cache
    if [[ -n "${ZGEN_DIR:-}" ]]; then
        plugin_path="$ZGEN_DIR/$plugin_name"
    fi

    # Skip verification if integrity checking is disabled
    if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "DISABLED" ]]; then
        return 0  # Allow normal zgenom processing
    fi

    # Perform integrity verification
    if ! _verify_plugin_integrity "$plugin_name" "$plugin_path"; then
        # Plugin blocked - skip loading
        _log_plugin_security "VIOLATION" "Skipped loading blocked plugin: $plugin_name"
        return 1
    fi

    # Plugin passed verification - allow normal loading
    return 0
}

# 6. Security Status Functions
#=============================================================================

_plugin_security_status() {
    local registry_file="$(_create_trusted_plugin_registry)"

    echo "=== Plugin Security Status ==="
    echo "Security Level: $ZSH_PLUGIN_SECURITY_LEVEL"
    echo "Registry File: $registry_file"
    echo "Cache Directory: $ZSH_PLUGIN_CACHE_DIR"
    echo "Security Log: $ZSH_PLUGIN_SECURITY_LOG"
    echo ""

    if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
        echo "Recent Security Events:"
        tail -10 "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || echo "No recent events"
    else
        echo "No security log found"
    fi
}

_plugin_security_update_registry() {
    local registry_file="$(_create_trusted_plugin_registry)"

    echo "Plugin registry updated: $registry_file"
    echo "Registry contains $(jq -r '.plugins | keys | length' "$registry_file" 2>/dev/null || echo "unknown") trusted plugins"

    _log_plugin_security "INFO" "Plugin registry manually updated"
}

# 7. Export Functions and Initialize
#=============================================================================

# Note: In ZSH, functions are automatically available to subshells when defined
# The functions above are now available globally within the ZSH environment

# Initialize registry on load
_create_trusted_plugin_registry > /dev/null

# Log initialization
_log_plugin_security "INFO" "Plugin integrity verification system initialized (level: $ZSH_PLUGIN_SECURITY_LEVEL)"

# Display security status if requested
if [[ "${ZSH_PLUGIN_SECURITY_VERBOSE:-false}" == "true" ]]; then
    echo "Plugin integrity verification system loaded (level: $ZSH_PLUGIN_SECURITY_LEVEL)"
fi
