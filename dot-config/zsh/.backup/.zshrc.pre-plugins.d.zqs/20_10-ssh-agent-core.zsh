#!/usr/bin/env zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 03-ssh-agent-core.zsh
# Purpose: Core SSH agent management with essential functionality
# Dependencies: macOS system ssh-agent, ssh-add
# Author: Configuration management system
# Last Modified: 2025-08-25
# Security Level: HIGH - Core secure agent management
# Split from: 03-secure-ssh-agent.zsh (15k → 8k + 7k)
#=============================================================================

## 1. Core SSH Agent Management System

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [security] Loading core SSH agent management"
}

# 1.1. Security Configuration
[[ -z "$SSH_AGENT_ENV_FILE" ]] && readonly SSH_AGENT_ENV_FILE="${HOME}/.ssh/ssh-agent-env"
[[ -z "$SSH_AGENT_LOCK_FILE" ]] && readonly SSH_AGENT_LOCK_FILE="${HOME}/.ssh/ssh-agent.lock"
[[ -z "$SSH_AGENT_MAX_AGE" ]] && readonly SSH_AGENT_MAX_AGE=86400  # 24 hours in seconds
[[ -z "$SSH_KEY_PATH" ]] && readonly SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"

# 1.2. Core SSH Agent Setup Function
_secure_ssh_setup() {
    local operation="${1:-auto}"
    local debug_mode="${ZSH_DEBUG:-0}"

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Starting secure SSH agent setup ($operation)"

    # 1.2.1. Validate environment safety
    if ! _validate_ssh_environment; then
        zf::debug "# [secure-ssh] ⚠️  Environment validation failed, skipping SSH agent setup"
        return 1
    fi

    # 1.2.2. Handle agent reuse vs creation
    case "$operation" in
        "force")
            _create_new_ssh_agent
            ;;
        "auto"|*)
            if ! _is_ssh_agent_usable; then
                _create_new_ssh_agent
            else
                [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ Using existing SSH agent"
            fi
            ;;
    esac
}

# 1.3. Environment Validation
_validate_ssh_environment() {
    local debug_mode="${ZSH_DEBUG:-0}"

    # 1.3.1. Check SSH directory and permissions
    if [[ ! -d "${HOME}/.ssh" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ SSH directory does not exist"
        return 1
    fi

    # 1.3.2. Verify SSH directory permissions (should be 700)
    local ssh_perms=$(stat -f "%OLp" "${HOME}/.ssh" 2>/dev/null)
    if [[ "$ssh_perms" != "700" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ⚠️  SSH directory permissions are $ssh_perms (should be 700)"
        # Auto-fix permissions
        chmod 700 "${HOME}/.ssh" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ Failed to fix SSH directory permissions"
            return 1
        fi
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ Fixed SSH directory permissions to 700"
    fi

    # 1.3.3. Check for required commands
    if ! command -v ssh-agent >/dev/null 2>&1; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ ssh-agent command not found"
        return 1
    fi

    if ! command -v ssh-add >/dev/null 2>&1; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ ssh-add command not found"
        return 1
    fi

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ Environment validation passed"
    return 0
}

# 1.4. SSH Agent Usability Check
_is_ssh_agent_usable() {
    local debug_mode="${ZSH_DEBUG:-0}"

    # 1.4.1. First try to load existing environment if variables are unset
    if [[ -z "$SSH_AUTH_SOCK" ]] || [[ -z "$SSH_AGENT_PID" ]]; then
        if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Loading SSH environment from $SSH_AGENT_ENV_FILE"
            source "$SSH_AGENT_ENV_FILE" >/dev/null 2>&1
        fi
    fi

    # 1.4.2. Check if we have the required environment variables
    if [[ -z "$SSH_AUTH_SOCK" ]] || [[ -z "$SSH_AGENT_PID" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ SSH agent environment variables not set"
        return 1
    fi

    # 1.4.3. Check if the socket exists and is accessible
    if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ SSH agent socket does not exist: $SSH_AUTH_SOCK"
        return 1
    fi

    # 1.4.4. Check if the agent process is actually running
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ SSH agent process $SSH_AGENT_PID is not running"
        return 1
    fi

    # 1.4.5. Test agent communication
    if ! ssh-add -l >/dev/null 2>&1; then
        local exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ⚠️  SSH agent is running but cannot connect"
            return 1
        elif [[ $exit_code -eq 1 ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ SSH agent is running (no keys loaded)"
        else
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ SSH agent is running with keys"
        fi
    fi

    # 1.4.6. Check agent age (optional security measure)
    if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
        local env_age=$(( $(date +%s) - $(stat -f %m "$SSH_AGENT_ENV_FILE" 2>/dev/null || zf::debug 0) ))
        if [[ $env_age -gt $SSH_AGENT_MAX_AGE ]]; then
            [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ⚠️  SSH agent is older than $SSH_AGENT_MAX_AGE seconds, will recreate"
            return 1
        fi
    fi

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ SSH agent is usable"
    return 0
}

# 1.5. Basic Agent Creation (Advanced features in 03-ssh-agent-security.zsh)
_create_new_ssh_agent() {
    local debug_mode="${ZSH_DEBUG:-0}"

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Creating new SSH agent"

    # 1.5.1. Clean up any existing agents first
    _cleanup_existing_agents 2>/dev/null

    # 1.5.2. Start new agent (basic version - advanced locking in security module)
    local agent_output
    agent_output=$(ssh-agent -s 2>/dev/null)

    if [[ $? -ne 0 ]] || [[ -z "$agent_output" ]]; then
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ❌ Failed to start SSH agent"
        return 1
    fi

    # 1.5.3. Save and load environment
        zf::debug "$agent_output" > "$SSH_AGENT_ENV_FILE"
    source "$SSH_AGENT_ENV_FILE"

    # 1.5.4. Add key if available
    if [[ -f "$SSH_KEY_PATH" ]]; then
        ssh-add "$SSH_KEY_PATH" >/dev/null 2>&1
        [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ SSH key added"
    fi

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] ✅ New SSH agent created"
    return 0
}

# Basic cleanup function (advanced version in security module)
_cleanup_existing_agents() {
    local debug_mode="${ZSH_DEBUG:-0}"

    [[ "$debug_mode" == "1" ]] && zf::debug "# [secure-ssh] Basic cleanup of existing agents"

    # Remove environment file
    rm -f "$SSH_AGENT_ENV_FILE" 2>/dev/null

    # Unset environment variables
    unset SSH_AUTH_SOCK SSH_AGENT_PID
}

## 2. Public Interface

# Simple restart function
secure_ssh_restart() {
    zf::debug "# [secure-ssh] Restarting SSH agent..."
    _secure_ssh_setup "force"
}

## 3. Initialization

# 3.1. Set up secure SSH agent on shell startup
if [[ "${(%):-%N}" == "$0" ]] || [[ "${(%):-%N}" == *"ssh-agent-core"* ]]; then
    # Script being executed directly or sourced for testing
    :
else
    # Normal shell startup - run secure SSH setup
    _secure_ssh_setup "auto"
fi

[[ "$ZSH_DEBUG" == "1" ]] && {
    zf::debug "# [security] Core SSH agent management loaded"
    printf "# ------ %s --------------------------------\n" "$0"
}
