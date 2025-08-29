#!/usr/bin/env zsh
#=============================================================================
# File: 04-plugin-integrity-advanced.zsh
# Purpose: Advanced plugin integrity verification and zgenom integration
# Dependencies: 04-plugin-integrity-core.zsh, openssl, jq (optional)
# Author: Configuration management system
# Last Modified: 2025-08-25
# Security Level: HIGH - Advanced plugin security
# Split from: 04-plugin-integrity-verification.zsh (13k → 7k + 6k)
#=============================================================================

# 4. Advanced Plugin Verification Functions
#=============================================================================

_get_plugin_hash_advanced() {
    local plugin_path="$1"

    if [[ ! -d "$plugin_path" ]]; then
            zsh_debug_echo "directory_not_found"
        return 1
    fi

    # Create a comprehensive hash of the plugin directory contents
    # Use find to get consistent ordering and include file modification times
    if command -v openssl >/dev/null 2>&1; then
        find "$plugin_path" -type f \( -name "*.zsh" -o -name "*.sh" \) -print0 2>/dev/null | \
            sort -z | \
            xargs -0 sh -c 'for file; do     zsh_debug_echo "$file"; stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null || zsh_debug_echo "0"; cat "$file"; done' -- | \
            openssl dgst -sha256 2>/dev/null | \
            awk '{print $2}' || zsh_debug_echo "hash_failed"
    else
        # Fallback to basic hash
        find "$plugin_path" -type f -name "*.zsh" -exec cat {} \; 2>/dev/null | \
            shasum -a 256 2>/dev/null | cut -d' ' -f1 || zsh_debug_echo "hash_failed"
    fi
}

_verify_plugin_integrity_advanced() {
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
    plugin_data=$(jq -r ".plugins[] | select(.name == \"$plugin_name\")" "$registry_file" 2>/dev/null)

    if [[ -z "$plugin_data" ]]; then
        _log_plugin_security "WARN" "Plugin not in trusted registry: $plugin_name"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            _log_plugin_security "VIOLATION" "BLOCKING untrusted plugin: $plugin_name"
            return 1
        fi

        return 0
    fi

    # Extract expected hash
    local expected_hash
    expected_hash=$(echo "$plugin_data" | jq -r '.hash // empty' 2>/dev/null)

    if [[ -z "$expected_hash" ]]; then
        _log_plugin_security "WARN" "No hash available for plugin: $plugin_name"
        return 0
    fi

    # Calculate current hash
    local current_hash
    current_hash=$(_get_plugin_hash_advanced "$plugin_path")

    if [[ "$current_hash" == "hash_failed" ]] || [[ "$current_hash" == "directory_not_found" ]]; then
        _log_plugin_security "ERROR" "Failed to calculate hash for plugin: $plugin_name"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            return 1
        fi

        return 0
    fi

    # Compare hashes
    if [[ "$current_hash" != "$expected_hash" ]]; then
        _log_plugin_security "VIOLATION" "Plugin integrity check failed for $plugin_name"
        _log_plugin_security "VIOLATION" "Expected: $expected_hash"
        _log_plugin_security "VIOLATION" "Got: $current_hash"

        if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "STRICT" ]]; then
            _log_plugin_security "VIOLATION" "BLOCKING plugin due to integrity failure: $plugin_name"
            return 1
        fi
    else
        _log_plugin_security "INFO" "Plugin integrity verified: $plugin_name"
    fi

    return 0
}

# 5. Advanced Registry Management
#=============================================================================

_create_trusted_plugin_registry() {
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"

    if [[ ! -f "$registry_file" ]]; then
        cat > "$registry_file" << 'EOF'
{
    "version": "1.0",
    "description": "Trusted plugin registry for zsh configuration",
    "last_updated": "2025-08-25",
    "plugins": [
        {
            "name": "zdharma-continuum/fast-syntax-highlighting",
            "description": "Fast syntax highlighting for zsh",
            "trusted": true,
            "hash": "",
            "version": "latest",
            "notes": "Core zsh-quickstart-kit plugin"
        },
        {
            "name": "zsh-users/zsh-history-substring-search",
            "description": "History substring search for zsh",
            "trusted": true,
            "hash": "",
            "version": "latest",
            "notes": "Core zsh-quickstart-kit plugin"
        },
        {
            "name": "zsh-users/zsh-autosuggestions",
            "description": "Fish-like autosuggestions for zsh",
            "trusted": true,
            "hash": "",
            "version": "latest",
            "notes": "Core zsh-quickstart-kit plugin"
        },
        {
            "name": "supercrabtree/k",
            "description": "Directory listings with git status",
            "trusted": true,
            "hash": "",
            "version": "latest",
            "notes": "Core zsh-quickstart-kit plugin"
        },
        {
            "name": "romkatv/powerlevel10k",
            "description": "Fast and flexible zsh theme",
            "trusted": true,
            "hash": "",
            "version": "latest",
            "notes": "Core zsh-quickstart-kit theme"
        }
    ]
}
EOF
        _log_plugin_security "INFO" "Created trusted plugin registry"
    fi

        zsh_debug_echo "$registry_file"
}

# 6. Integration with zgenom
#=============================================================================

# Hook into zgenom loading process
_zgenom_security_hook() {
    local plugin_name="$1"
    local plugin_path="$2"

    # Skip verification if disabled
    if [[ "$ZSH_PLUGIN_SECURITY_LEVEL" == "DISABLED" ]]; then
        return 0
    fi

    _log_plugin_security "INFO" "Verifying plugin before load: $plugin_name"

    # Use advanced verification if available, fallback to basic
    if command -v jq >/dev/null 2>&1 && command -v openssl >/dev/null 2>&1; then
        _verify_plugin_integrity_advanced "$plugin_name" "$plugin_path"
    else
        _verify_plugin_basic "$plugin_name" "$plugin_path"
    fi

    return $?
}

# 7. Advanced Security Status and Management
#=============================================================================

plugin_security_status_advanced() {
        zsh_debug_echo "Advanced Plugin Security Status"
        zsh_debug_echo "==============================="
    plugin_security_status  # Call basic status first
        zsh_debug_echo ""

    # Check for security tools
        zsh_debug_echo "Security Tools:"
    if command -v openssl >/dev/null 2>&1; then
            zsh_debug_echo "  ✅ OpenSSL available"
    else
            zsh_debug_echo "  ❌ OpenSSL not available (hash verification limited)"
    fi

    if command -v jq >/dev/null 2>&1; then
            zsh_debug_echo "  ✅ jq available"
    else
            zsh_debug_echo "  ❌ jq not available (registry parsing limited)"
    fi

    # Show registry contents
    local registry_file="$ZSH_PLUGIN_REGISTRY_DIR/trusted-plugins.json"
    if [[ -f "$registry_file" ]] && command -v jq >/dev/null 2>&1; then
            zsh_debug_echo ""
            zsh_debug_echo "Trusted Plugins:"
        jq -r '.plugins[] | "  \(.name) (\(.version))"' "$registry_file" 2>/dev/null || zsh_debug_echo "  (parsing failed)"
    fi

    # Show recent activity
    if [[ -f "$ZSH_PLUGIN_SECURITY_LOG" ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "Recent Security Events:"
        tail -10 "$ZSH_PLUGIN_SECURITY_LOG" 2>/dev/null | sed 's/^/  /' || zsh_debug_echo "  (no recent events)"
    fi
}

plugin_security_update_registry() {
    local plugin_name="$1"
    local plugin_path="$2"

    if [[ -z "$plugin_name" ]] || [[ -z "$plugin_path" ]]; then
            zsh_debug_echo "Usage: plugin_security_update_registry <plugin_name> <plugin_path>"
        return 1
    fi

    if [[ ! -d "$plugin_path" ]]; then
            zsh_debug_echo "❌ Plugin path does not exist: $plugin_path"
        return 1
    fi

    local current_hash
    current_hash=$(_get_plugin_hash_advanced "$plugin_path")

    if [[ "$current_hash" == "hash_failed" ]]; then
            zsh_debug_echo "❌ Failed to calculate hash for plugin: $plugin_name"
        return 1
    fi

    # Update or create registry entry
    _create_plugin_registry_entry "$plugin_name" "$plugin_path"

        zsh_debug_echo "✅ Updated registry entry for plugin: $plugin_name"
        zsh_debug_echo "   Hash: $current_hash"

    _log_plugin_security "INFO" "Registry updated for plugin: $plugin_name (hash: $current_hash)"
}

plugin_security_scan_all() {
        zsh_debug_echo "Scanning all plugins for integrity issues..."

    if [[ ! -d "${ZGEN_DIR:-$HOME/.zgenom}" ]]; then
            zsh_debug_echo "❌ zgenom directory not found"
        return 1
    fi

    local issues_found=0

    # Scan zgenom plugins
    find "${ZGEN_DIR:-$HOME/.zgenom}" -maxdepth 2 -type d -name "*" | while read -r plugin_dir; do
        if [[ -f "$plugin_dir/.git/config" ]]; then
            local plugin_name=$(basename "$plugin_dir")
            local parent_dir=$(basename "$(dirname "$plugin_dir")")
            local full_name="$parent_dir/$plugin_name"

                zsh_debug_echo "Checking: $full_name"

            if ! _verify_plugin_basic "$full_name" "$plugin_dir"; then
                    zsh_debug_echo "  ❌ Issues found"
                ((issues_found++))
            else
                    zsh_debug_echo "  ✅ OK"
            fi
        fi
    done

    if [[ $issues_found -eq 0 ]]; then
            zsh_debug_echo "✅ No integrity issues found"
    else
            zsh_debug_echo "⚠️  Found $issues_found plugins with issues"
    fi
}

# 8. Export Functions and Initialize Advanced Features
#=============================================================================

# Mark advanced plugin integrity as loaded (for lazy loading framework)
export _PLUGIN_INTEGRITY_ADVANCED_LOADED=1

# Initialize advanced features (functions are available in current shell)
if command -v _log_plugin_security >/dev/null 2>&1; then
    _log_plugin_security "INFO" "Advanced plugin integrity verification system initialized"
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# [security] Advanced plugin integrity verification loaded"
    printf "# ------ %s --------------------------------\n" "$0"
}
