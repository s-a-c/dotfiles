#!/usr/bin/env zsh
#=============================================================================
# File: 04-plugin-integrity-core.zsh
# Purpose: Core plugin integrity verification system for zsh configuration
# Dependencies: openssl (for hashing), jq (for registry parsing)
# Author: Configuration management system
# Last Modified: 2025-08-25
# Security Level: HIGH - Core plugin security
# Split from: 04-plugin-integrity-verification.zsh (13k → 7k + 6k)
#=============================================================================

# PERF_CAPTURE_FAST short-circuit:
# When enabled (used by perf-capture tooling) skip all core integrity
# directory setup and hashing to minimize startup latency.

# Prevent multiple loading
[[ -n "${_LOADED_00_20_PLUGIN_INTEGRITY_CORE:-}" ]] && return 0

if [[ "${PERF_CAPTURE_FAST:-0}" == "1" ]]; then
  typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }
  zsh_debug_echo "# [plugin-integrity-core][perf-capture-fast] Skipping core plugin integrity verification (PERF_CAPTURE_FAST=1)"
  return 0
fi
# 1. Configuration Variables
#=============================================================================

# Plugin integrity registry directory
export ZSH_PLUGIN_REGISTRY_DIR="${HOME}/.config/zsh/security/plugin-registry"
export ZSH_PLUGIN_CACHE_DIR="${ZGEN_DIR:-$HOME/.zgenom}/integrity-cache"
export ZSH_PLUGIN_SECURITY_LOG="${HOME}/.config/zsh/logs/$(safe_date +%Y-%m-%d)/plugin-integrity.log"

# Security levels
export ZSH_PLUGIN_SECURITY_LEVEL="${ZSH_PLUGIN_SECURITY_LEVEL:-WARN}" # STRICT, WARN, DISABLED

# Create necessary directories
[[ ! -d "$(safe_dirname "$ZSH_PLUGIN_SECURITY_LOG")" ]] && safe_mkdir -p "$(safe_dirname "$ZSH_PLUGIN_SECURITY_LOG")"
[[ ! -d "$ZSH_PLUGIN_REGISTRY_DIR" ]] && safe_mkdir -p "$ZSH_PLUGIN_REGISTRY_DIR"
[[ ! -d "$ZSH_PLUGIN_CACHE_DIR" ]] && safe_mkdir -p "$ZSH_PLUGIN_CACHE_DIR"

# 2. Core Logging Functions
#=============================================================================

_log_plugin_security() {
    local level="$1"
    local message="$2"
    local timestamp="$(safe_date -u '+    %FT%T %Z')"

        zsh_debug_echo "[$timestamp] [$level] $message" >> "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || true

    # Also log to stderr for STRICT violations
    if [[ "$level" == "VIOLATION" && "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            zsh_debug_echo "[PLUGIN SECURITY] $message"
    fi
}

# 3. Basic Plugin Registry Management
#=============================================================================

_create_plugin_registry_entry() {
    local plugin_name="$1"
    local plugin_path="$2"
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/${plugin_name}.json"

    if [[ ! -d "$plugin_path" ]]; then
        _log_plugin_security "ERROR" "Plugin path does not exist: $plugin_path"
        return 1
    fi

    # Calculate basic hash of plugin directory
    local plugin_hash
    if command -v shasum >/dev/null 2>&1; then
        plugin_hash=$(find "$plugin_path" -type f -name "*.zsh" -exec shasum -a 256 {} \; 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        plugin_hash=$(find "$plugin_path" -type f -name "*.zsh" -exec sha256sum {} \; 2>/dev/null | sha256sum | cut -d' ' -f1)
    else
        _log_plugin_security "WARN" "No hash utility available for plugin verification"
        return 1
    fi

    # Create basic registry entry
    cat > "$registry_file" << EOF
{
    "name": "$plugin_name",
    "path": "$plugin_path",
    "hash": "$plugin_hash",
    "created": "$(safe_date -u '+    %FT%T %Z')",
    "version": "unknown",
    "trusted": false,
    "notes": "Auto-generated entry - manual verification required"
}
EOF

    _log_plugin_security "INFO" "Created registry entry for plugin: $plugin_name"
    return 0
}

_get_plugin_registry_info() {
    local plugin_name="$1"
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/${plugin_name}.json"

    if [[ ! -f "$registry_file" ]]; then
        return 1
    fi

    # Simple JSON parsing without jq dependency
    local hash=$(grep '"hash"' "$registry_file" | sed 's/.*"hash": *"\([^"]*\)".*/\1/')
    local trusted=$(grep '"trusted"' "$registry_file" | sed 's/.*"trusted": *\([^,}]*\).*/\1/')

        zsh_debug_echo "hash:$hash"
        zsh_debug_echo "trusted:$trusted"
    return 0
}

_verify_plugin_basic() {
    local plugin_name="$1"
    local plugin_path="$2"

    # Skip verification if disabled
    if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "DISABLED" ]]; then
        return 0
    fi

    # Check if plugin directory exists
    if [[ ! -d "$plugin_path" ]]; then
        _log_plugin_security "ERROR" "Plugin directory missing: $plugin_path"
        return 1
    fi

    # Get registry info
    local registry_info
    registry_info=$(_get_plugin_registry_info "$plugin_name")

    if [[ $? -ne 0 ]]; then
        _log_plugin_security "WARN" "No registry entry for plugin: $plugin_name"

        # Auto-create entry in WARN mode
        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "WARN" ]]; then
            _create_plugin_registry_entry "$plugin_name" "$plugin_path"
        fi

        return 0
    fi

    # Extract hash from registry info
    local expected_hash=$(echo "$registry_info" | grep "^hash:" | cut -d: -f2)
    local is_trusted=$(echo "$registry_info" | grep "^trusted:" | cut -d: -f2)

    # Calculate current hash
    local current_hash
    if command -v shasum >/dev/null 2>&1; then
        current_hash=$(find "$plugin_path" -type f -name "*.zsh" -exec shasum -a 256 {} \; 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        current_hash=$(find "$plugin_path" -type f -name "*.zsh" -exec sha256sum {} \; 2>/dev/null | sha256sum | cut -d' ' -f1)
    else
        _log_plugin_security "WARN" "Cannot verify plugin hash - no hash utility available"
        return 0
    fi

    # Compare hashes
    if [[ "$current_hash" != "$expected_hash" ]]; then
        _log_plugin_security "VIOLATION" "Plugin hash mismatch for $plugin_name (expected: $expected_hash, got: $current_hash)"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
                zsh_debug_echo "[PLUGIN SECURITY] BLOCKING plugin $plugin_name due to hash mismatch"
            return 1
        fi
    else
        _log_plugin_security "INFO" "Plugin verification passed: $plugin_name"
    fi

    return 0
}

# 4. Basic Security Status
#=============================================================================

plugin_security_status() {
        zsh_debug_echo "Plugin Security Status"
        zsh_debug_echo "======================"
        zsh_debug_echo "Security Level: $ZSH_PLUGIN_SECURITY_LEVEL"
        zsh_debug_echo "Registry Dir: $ZSH_PLUGIN_REGISTRY_DIR"
        zsh_debug_echo "Cache Dir: $ZSH_PLUGIN_CACHE_DIR"
        zsh_debug_echo "Log File: $ZSH_PLUGIN_SECURITY_LOG"
        zsh_debug_echo ""

    if [[ -d "$ZSH_PLUGIN_REGISTRY_DIR" ]]; then
        local registry_count=$(find "$ZSH_PLUGIN_REGISTRY_DIR" -name "*.json" | wc -l)
            zsh_debug_echo "Registered Plugins: $registry_count"
    else
            zsh_debug_echo "Registry Directory: Not found"
    fi

    if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
        local log_lines=$(wc -l < "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null || zsh_debug_echo 0)
            zsh_debug_echo "Log Entries: $log_lines"

        # Show recent violations
        local violations=$(grep "VIOLATION" "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null | tail -5)
        if [[ -n "$violations" ]]; then
                zsh_debug_echo ""
                zsh_debug_echo "Recent Violations:"
                zsh_debug_echo "$violations"
        fi
    else
            zsh_debug_echo "Log File: Not found"
    fi
}

# 5. Basic Initialization
#=============================================================================

# Initialize plugin security system
_init_plugin_security() {
    _log_plugin_security "INFO" "Plugin integrity verification system initialized (core)"

    # Create default trusted plugins registry if it doesn't exist
    local default_registry="$ZSH_PLUGIN_REGISTRY_DIR/default-trusted.json"
    if [[ ! -f "$default_registry" ]]; then
        cat > "$default_registry" << 'EOF'
{
    "description": "Default trusted plugins for zsh-quickstart-kit",
    "plugins": [
        "zdharma-continuum/fast-syntax-highlighting",
        "zsh-users/zsh-history-substring-search",
        "zsh-users/zsh-autosuggestions",
        "supercrabtree/k",
        "romkatv/powerlevel10k"
    ],
    "created": "2025-08-25",
    "notes": "Core plugins from zsh-quickstart-kit - generally safe"
}
EOF
        _log_plugin_security "INFO" "Created default trusted plugins registry"
    fi
}

# Initialize if not disabled
if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" != "DISABLED" ]]; then
    _init_plugin_security
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# [security] Core plugin integrity verification loaded"
    printf "# ------ %s --------------------------------
" "$0"
}

# Mark as loaded
readonly _LOADED_00_20_PLUGIN_INTEGRITY_CORE=1
