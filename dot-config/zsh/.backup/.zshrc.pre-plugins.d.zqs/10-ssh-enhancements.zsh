#!/usr/bin/env zsh
# 10-ssh-enhancements.zsh - Enhanced SSH key management for ZQS
# Part of the migration to symlinked ZQS .zshrc

# =================================================================================
# === SSH Key Management Enhancements (Override ZQS defaults) ===
# =================================================================================

# Note: ZQS .zshrc already provides load-our-ssh-keys and onepassword-agent-check functions
# Instead of overriding them, we'll enhance the SSH experience through settings and hooks

# Set ZQS settings to enable features we want
if command -v _zqs-set-setting >/dev/null 2>&1; then
    # Enable 1Password SSH agent by default
    _zqs-set-setting use-1password-ssh-agent true

    # Enable SSH key loading
    _zqs-set-setting load-ssh-keys true

    # Enable SSH key listing
    _zqs-set-setting list-ssh-keys true
fi

# Function to add timeout protection to ssh-add -l calls
# This can be used by other scripts or called manually
_safe_ssh_add_list() {
    local timeout_cmd=""
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 1"
    fi

    if [[ -n "$timeout_cmd" ]]; then
        $timeout_cmd ssh-add -l 2>/dev/null || echo "(ssh-agent not responding)"
    else
        ssh-add -l 2>/dev/null || echo "(ssh-agent not available)"
    fi
}

zf::debug "# [pre-plugin-ext] SSH enhancements loaded (timeout protection active)"
