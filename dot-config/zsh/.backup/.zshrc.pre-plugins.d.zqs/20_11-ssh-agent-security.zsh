#!/usr/bin/env zsh
#=============================================================================
# File: 03-ssh-agent-security.zsh
# Purpose: Advanced SSH agent security features and utilities
# Dependencies: 03-ssh-agent-core.zsh, macOS system ssh-agent, ssh-add
# Author: Configuration management system
# Last Modified: 2025-08-25
# Security Level: HIGH - Advanced secure agent management
# Split from: 03-secure-ssh-agent.zsh (15k → 8k + 7k)
#=============================================================================

## 1. Advanced SSH Agent Security Features

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [security] Loading advanced SSH agent security"
}

# 1.6. File Locking for Race Condition Prevention
_acquire_ssh_lock() {
    local timeout=10
    local counter=0

    while (( counter < timeout )); do
        if (set -C;     zf::debug $$ > "$SSH_AGENT_LOCK_FILE") 2>/dev/null; then
            return 0
        fi

        # Check if lock is stale (older than 30 seconds)
        if [[ -f "$SSH_AGENT_LOCK_FILE" ]]; then
            local lock_age
            lock_age=$(( $(date +%s) - $(stat -f "%m" "$SSH_AGENT_LOCK_FILE" 2>/dev/null || zf::debug 0) ))
            if (( lock_age > 30 )); then
                rm -f "$SSH_AGENT_LOCK_FILE" 2>/dev/null
                continue
            fi
        fi

        sleep 1
        ((counter++))
    done

    return 1
}

_release_ssh_lock() {
    rm -f "$SSH_AGENT_LOCK_FILE" 2>/dev/null
}

# 1.7. Secure Agent Output Validation
_validate_agent_output() {
    local env_file="$1"

    # 1.7.1. Check file exists and is readable
    if [[ ! -f "$env_file" ]] || [[ ! -r "$env_file" ]]; then
        zf::debug "# [secure-ssh] ❌ Agent environment file not accessible"
        return 1
    fi

    # 1.7.2. Validate file contains only expected environment variables
    local line_count
    line_count=$(wc -l < "$env_file")
    if (( line_count > 10 )); then
        zf::debug "# [secure-ssh] ❌ Agent environment file too large ($line_count lines)"
        return 1
    fi

    # 1.7.3. Validate SSH_AUTH_SOCK and SSH_AGENT_PID format
    if ! grep -q '^SSH_AUTH_SOCK=/.*; export SSH_AUTH_SOCK;$' "$env_file"; then
        zf::debug "# [secure-ssh] ❌ Invalid SSH_AUTH_SOCK format in agent output"
        return 1
    fi

    if ! grep -q '^SSH_AGENT_PID=[0-9]*; export SSH_AGENT_PID;$' "$env_file"; then
        zf::debug "# [secure-ssh] ❌ Invalid SSH_AGENT_PID format in agent output"
        return 1
    fi

    return 0
}

# 1.8. Advanced Agent Cleanup
_cleanup_existing_agents_advanced() {
    local debug_mode="${ZSH_DEBUG:-0}"

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Advanced cleanup of existing agents"

    # 1.8.1. Kill existing agent if PID is known
    if [[ -n "$SSH_AGENT_PID" ]] && kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        kill "$SSH_AGENT_PID" 2>/dev/null
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Killed existing agent (PID: $SSH_AGENT_PID)"
    fi

    # 1.8.2. Remove environment file
    rm -f "$SSH_AGENT_ENV_FILE" 2>/dev/null

    # 1.8.3. Unset environment variables
    unset SSH_AUTH_SOCK SSH_AGENT_PID
}

# 1.9. Secure Key Addition with Validation
_add_ssh_key_secure() {
    local debug_mode="${ZSH_DEBUG:-0}"

    # 1.9.1. Verify key exists and is secure
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ SSH key not found: $SSH_KEY_PATH"
        return 1
    fi

    # 1.9.2. Check key permissions (should be 600)
    local key_perms=$(stat -f "%OLp" "$SSH_KEY_PATH" 2>/dev/null)
    if [[ "$key_perms" != "600" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ⚠️  SSH key permissions are $key_perms (should be 600)"
        chmod 600 "$SSH_KEY_PATH" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ Failed to fix SSH key permissions"
            return 1
        fi
    fi

    # 1.9.3. Add key with timeout
    if timeout 10 ssh-add "$SSH_KEY_PATH" >/dev/null 2>&1; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ SSH key added successfully"
        return 0
    fi

    zf::debug "# [secure-ssh] ❌ Failed to add SSH key"
    return 1
}

# 1.10. Advanced Public Management Functions
secure_ssh_restart_advanced() {
    zf::debug "# [secure-ssh] Advanced restart with full cleanup..."

    # Acquire lock for safe restart
    if _acquire_ssh_lock; then
        _cleanup_existing_agents_advanced
        _secure_ssh_setup "force"
        _release_ssh_lock
    else
        zf::debug "# [secure-ssh] ❌ Could not acquire lock for restart"
        return 1
    fi
}

secure_ssh_status() {
        zf::debug "SSH Agent Status:"
        zf::debug "=================="

    if [[ -n "$SSH_AUTH_SOCK" ]]; then
            zf::debug "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
    else
            zf::debug "SSH_AUTH_SOCK: (not set)"
    fi

    if [[ -n "$SSH_AGENT_PID" ]]; then
            zf::debug "SSH_AGENT_PID: $SSH_AGENT_PID"
        if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
                zf::debug "Agent Process: ✅ Running"
        else
                zf::debug "Agent Process: ❌ Not running"
        fi
    else
            zf::debug "SSH_AGENT_PID: (not set)"
    fi

    if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
        local env_age=$(( $(date +%s) - $(stat -f %m "$SSH_AGENT_ENV_FILE" 2>/dev/null || zf::debug 0) ))
            zf::debug "Environment File: ✅ Exists (${env_age}s old)"
    else
            zf::debug "Environment File: ❌ Missing"
    fi

        zf::debug ""
        zf::debug "Loaded Keys:"
    ssh-add -l 2>/dev/null || zf::debug "No keys loaded or agent not accessible"
}

secure_ssh_add_key() {
    local key_path="${1:-$SSH_KEY_PATH}"

    if [[ ! -f "$key_path" ]]; then
            zf::debug "❌ Key not found: $key_path"
        return 1
    fi

    if _add_ssh_key_secure; then
            zf::debug "✅ Key added successfully: $key_path"
    else
            zf::debug "❌ Failed to add key: $key_path"
        return 1
    fi
}

secure_ssh_remove_all_keys() {
    if ssh-add -D >/dev/null 2>&1; then
            zf::debug "✅ All keys removed from agent"
    else
            zf::debug "❌ Failed to remove keys from agent"
        return 1
    fi
}

# 1.11. Enhanced Agent Creation with Full Security
_create_new_ssh_agent_secure() {
    local debug_mode="${ZSH_DEBUG:-0}"

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Creating new SSH agent with full security"

    # 1.11.1. Acquire lock to prevent race conditions
    if ! _acquire_ssh_lock; then
        zf::debug "# [secure-ssh] ❌ Could not acquire lock for agent creation"
        return 1
    fi

    # 1.11.2. Clean up any existing agents
    _cleanup_existing_agents_advanced

    # 1.11.3. Start new agent
    local agent_output
    agent_output=$(ssh-agent -s 2>/dev/null)

    if [[ $? -ne 0 ]] || [[ -z "$agent_output" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ Failed to start SSH agent"
        _release_ssh_lock
        return 1
    fi

    # 1.11.4. Save agent output to temporary file first
    local temp_env_file="${SSH_AGENT_ENV_FILE}.tmp"
        zf::debug "$agent_output" > "$temp_env_file"

    # 1.11.5. Validate agent output
    if ! _validate_agent_output "$temp_env_file"; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ Agent output validation failed"
        rm -f "$temp_env_file"
        _release_ssh_lock
        return 1
    fi

    # 1.11.6. Move validated file to final location
    mv "$temp_env_file" "$SSH_AGENT_ENV_FILE"
    chmod 600 "$SSH_AGENT_ENV_FILE"

    # 1.11.7. Load environment
    source "$SSH_AGENT_ENV_FILE"

    # 1.11.8. Add key securely
    if [[ -f "$SSH_KEY_PATH" ]]; then
        _add_ssh_key_secure
    fi

    # 1.11.9. Release lock
    _release_ssh_lock

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ Secure SSH agent created successfully"
    return 0
}

## 2. Override core functions with secure versions (if desired)

# Uncomment to use advanced secure agent creation by default
# alias _create_new_ssh_agent='_create_new_ssh_agent_secure'
# alias _cleanup_existing_agents='_cleanup_existing_agents_advanced'

# Mark advanced SSH security as loaded (for lazy loading framework)
export _SSH_AGENT_SECURITY_ADVANCED_LOADED=1

[[ "$ZSH_DEBUG" == "1" ]] && {
    zf::debug "# [security] Advanced SSH agent security loaded"
    printf "# ------ %s --------------------------------\n" "$0"
}
