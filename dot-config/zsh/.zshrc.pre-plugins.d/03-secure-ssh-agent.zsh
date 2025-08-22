#!/usr/bin/env zsh
# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}
#=============================================================================
# File: 03-secure-ssh-agent.zsh
# Purpose: Secure SSH agent management with comprehensive security validations
# Dependencies: macOS system ssh-agent, ssh-add
# Author: Configuration management system  
# Last Modified: 2025-08-21
# Security Level: HIGH - Implements secure agent management patterns
#=============================================================================

## 1. Secure SSH Agent Management System

[[ "$ZSH_DEBUG" == "1" ]] && {
    printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2
    echo "# [security] Loading secure SSH agent management" >&2
}

# 1.1. Security Configuration
[[ -z "$SSH_AGENT_ENV_FILE" ]] && readonly SSH_AGENT_ENV_FILE="${HOME}/.ssh/ssh-agent-env"
[[ -z "$SSH_AGENT_LOCK_FILE" ]] && readonly SSH_AGENT_LOCK_FILE="${HOME}/.ssh/ssh-agent.lock"
[[ -z "$SSH_AGENT_MAX_AGE" ]] && readonly SSH_AGENT_MAX_AGE=86400  # 24 hours in seconds
[[ -z "$SSH_KEY_PATH" ]] && readonly SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"

# 1.2. Secure SSH Agent Setup Function
_secure_ssh_setup() {
    local operation="${1:-auto}"
    local debug_mode="${ZSH_DEBUG:-0}"
    
    [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Starting secure SSH agent setup ($operation)" >&2
    
    # 1.2.1. Validate environment safety
    if ! _validate_ssh_environment; then
        echo "# [secure-ssh] ⚠️  Environment validation failed, skipping SSH agent setup" >&2
        return 1
    fi
    
    # 1.2.2. Handle agent reuse vs creation
    case "$operation" in
        "force")
            _create_new_ssh_agent
            ;;
        "auto"|*)
            if _is_ssh_agent_usable; then
                [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ Using existing SSH agent" >&2
                return 0
            else
                _create_new_ssh_agent
            fi
            ;;
    esac
}

# 1.3. Environment Validation
_validate_ssh_environment() {
    local debug_mode="${ZSH_DEBUG:-0}"
    
    # 1.3.1. Check SSH directory and permissions
    if [[ ! -d "${HOME}/.ssh" ]]; then
        echo "# [secure-ssh] ❌ SSH directory not found" >&2
        return 1
    fi
    
    # 1.3.2. Verify SSH directory has secure permissions (700)
    local ssh_perms
    ssh_perms=$(stat -f "%p" "${HOME}/.ssh" 2>/dev/null)
    if [[ "${ssh_perms: -3}" != "700" ]]; then
        echo "# [secure-ssh] ⚠️  SSH directory permissions not secure (should be 700)" >&2
        chmod 700 "${HOME}/.ssh" 2>/dev/null || {
            echo "# [secure-ssh] ❌ Failed to secure SSH directory permissions" >&2
            return 1
        }
    fi
    
    # 1.3.3. Verify SSH key exists and has secure permissions
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        echo "# [secure-ssh] ❌ SSH key not found: $SSH_KEY_PATH" >&2
        return 1
    fi
    
    local key_perms
    key_perms=$(stat -f "%p" "$SSH_KEY_PATH" 2>/dev/null)
    if [[ "${key_perms: -3}" != "600" ]]; then
        echo "# [secure-ssh] ⚠️  SSH key permissions not secure (should be 600)" >&2
        chmod 600 "$SSH_KEY_PATH" 2>/dev/null || {
            echo "# [secure-ssh] ❌ Failed to secure SSH key permissions" >&2
            return 1
        }
    fi
    
    [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ Environment validation passed" >&2
    return 0
}

# 1.4. SSH Agent Usability Check
_is_ssh_agent_usable() {
    local debug_mode="${ZSH_DEBUG:-0}"
    
    # 1.4.1. First try to load existing environment if variables are unset
    if [[ -z "$SSH_AUTH_SOCK" ]] || [[ -z "$SSH_AGENT_PID" ]]; then
        if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
            [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Loading existing environment file" >&2
            source "$SSH_AGENT_ENV_FILE" >/dev/null 2>&1
        fi
    fi
    
    # 1.4.2. Check if environment variables are now set
    if [[ -z "$SSH_AUTH_SOCK" ]] || [[ -z "$SSH_AGENT_PID" ]]; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Agent environment variables not set" >&2
        return 1
    fi
    
    # 1.4.3. Validate SSH_AUTH_SOCK exists and is accessible
    if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] SSH_AUTH_SOCK socket not accessible" >&2
        return 1
    fi
    
    # 1.4.4. Verify agent process is actually running
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] SSH agent process not running" >&2
        return 1
    fi
    
    # 1.4.5. Test agent functionality (allow "no keys loaded" as success)
    local ssh_add_result
    /usr/bin/ssh-add -l >/dev/null 2>&1
    ssh_add_result=$?
    if [[ $ssh_add_result -ne 0 ]] && [[ $ssh_add_result -ne 1 ]]; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] SSH agent not responsive (exit code: $ssh_add_result)" >&2
        return 1
    fi
    
    # 1.4.6. Check if environment file is recent (within max age)
    if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
        local file_age
        file_age=$(( $(date +%s) - $(stat -f "%m" "$SSH_AGENT_ENV_FILE" 2>/dev/null || echo 0) ))
        if (( file_age > SSH_AGENT_MAX_AGE )); then
            [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Agent environment file too old ($file_age seconds)" >&2
            return 1
        fi
    fi
    
    [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ SSH agent is usable" >&2
    return 0
}

# 1.5. Secure Agent Creation
_create_new_ssh_agent() {
    local debug_mode="${ZSH_DEBUG:-0}"
    
    [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Creating new SSH agent" >&2
    
    # 1.5.1. Implement file locking to prevent race conditions
    if ! _acquire_ssh_lock; then
        echo "# [secure-ssh] ⚠️  Could not acquire lock, SSH agent setup in progress elsewhere" >&2
        sleep 1
        # Try to use existing agent after brief wait
        if _is_ssh_agent_usable; then
            return 0
        else
            echo "# [secure-ssh] ❌ Failed to acquire lock and no usable agent found" >&2
            return 1
        fi
    fi
    
    # 1.5.2. Clean up any existing agents securely
    _cleanup_existing_agents
    
    # 1.5.3. Create new agent environment file securely
    local temp_env_file
    temp_env_file=$(mktemp "${SSH_AGENT_ENV_FILE}.XXXXXX") || {
        echo "# [secure-ssh] ❌ Failed to create temporary environment file" >&2
        _release_ssh_lock
        return 1
    }
    
    # 1.5.4. Start new SSH agent with secure permissions
    if ! /usr/bin/ssh-agent -s > "$temp_env_file"; then
        echo "# [secure-ssh] ❌ Failed to start SSH agent" >&2
        rm -f "$temp_env_file"
        _release_ssh_lock
        return 1
    fi
    
    # 1.5.5. Validate and sanitize agent output before sourcing
    if ! _validate_agent_output "$temp_env_file"; then
        echo "# [secure-ssh] ❌ SSH agent output validation failed" >&2
        rm -f "$temp_env_file"
        _release_ssh_lock
        return 1
    fi
    
    # 1.5.6. Set secure permissions on environment file
    chmod 600 "$temp_env_file" || {
        echo "# [secure-ssh] ❌ Failed to set secure permissions on agent environment" >&2
        rm -f "$temp_env_file"
        _release_ssh_lock
        return 1
    }
    
    # 1.5.7. Atomically move temp file to final location
    if ! mv "$temp_env_file" "$SSH_AGENT_ENV_FILE"; then
        echo "# [secure-ssh] ❌ Failed to move agent environment file" >&2
        rm -f "$temp_env_file"
        _release_ssh_lock
        return 1
    fi
    
    # 1.5.7a. Ensure final file has secure permissions (macOS mv sometimes resets permissions)
    chmod 600 "$SSH_AGENT_ENV_FILE" || {
        echo "# [secure-ssh] ❌ Failed to set secure permissions on final environment file" >&2
        _release_ssh_lock
        return 1
    }
    
    # 1.5.8. Source the validated environment file
    source "$SSH_AGENT_ENV_FILE"
    
    # 1.5.9. Add SSH key securely
    if ! _add_ssh_key_secure; then
        echo "# [secure-ssh] ❌ Failed to add SSH key" >&2
        _release_ssh_lock
        return 1
    fi
    
    # 1.5.10. Final validation
    if _is_ssh_agent_usable; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ New SSH agent created successfully" >&2
        _release_ssh_lock
        return 0
    else
        echo "# [secure-ssh] ❌ New SSH agent failed validation" >&2
        _release_ssh_lock
        return 1
    fi
}

# 1.6. File Locking for Race Condition Prevention
_acquire_ssh_lock() {
    local timeout=10
    local counter=0
    
    while (( counter < timeout )); do
        if (set -C; echo $$ > "$SSH_AGENT_LOCK_FILE") 2>/dev/null; then
            return 0
        fi
        
        # Check if lock is stale (older than 30 seconds)
        if [[ -f "$SSH_AGENT_LOCK_FILE" ]]; then
            local lock_age
            lock_age=$(( $(date +%s) - $(stat -f "%m" "$SSH_AGENT_LOCK_FILE" 2>/dev/null || echo 0) ))
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
        echo "# [secure-ssh] ❌ Agent environment file not accessible" >&2
        return 1
    fi
    
    # 1.7.2. Validate file contains only expected environment variables
    local line_count
    line_count=$(wc -l < "$env_file")
    if (( line_count > 10 )); then
        echo "# [secure-ssh] ❌ Agent environment file too large ($line_count lines)" >&2
        return 1
    fi
    
    # 1.7.3. Validate SSH_AUTH_SOCK and SSH_AGENT_PID format
    if ! grep -q '^SSH_AUTH_SOCK=/.*; export SSH_AUTH_SOCK;$' "$env_file"; then
        echo "# [secure-ssh] ❌ Invalid SSH_AUTH_SOCK format in agent output" >&2
        return 1
    fi
    
    if ! grep -q '^SSH_AGENT_PID=[0-9][0-9]*; export SSH_AGENT_PID;$' "$env_file"; then
        echo "# [secure-ssh] ❌ Invalid SSH_AGENT_PID format in agent output" >&2
        return 1
    fi
    
    # 1.7.4. Validate no suspicious content (except in SSH_ lines and echo Agent pid line)
    if grep '[;&|`$()]' "$env_file" | grep -v '^SSH_' | grep -v '^echo Agent pid [0-9][0-9]*;$' | grep -q .; then
        echo "# [secure-ssh] ❌ Suspicious content detected in agent output" >&2
        return 1
    fi
    
    return 0
}

# 1.8. Secure Agent Cleanup
_cleanup_existing_agents() {
    local debug_mode="${ZSH_DEBUG:-0}"
    
    [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] Cleaning up existing agents" >&2
    
    # 1.8.1. Kill agents owned by current user only
    pkill -U "$(id -u)" ssh-agent 2>/dev/null || true
    
    # 1.8.2. Clean up stale environment files
    if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
        rm -f "$SSH_AGENT_ENV_FILE" 2>/dev/null
    fi
    
    # 1.8.3. Unset environment variables
    unset SSH_AUTH_SOCK SSH_AGENT_PID
}

# 1.9. Secure Key Addition
_add_ssh_key_secure() {
    local debug_mode="${ZSH_DEBUG:-0}"
    
    # 1.9.1. Verify key exists and is secure
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        echo "# [secure-ssh] ❌ SSH key not found: $SSH_KEY_PATH" >&2
        return 1
    fi
    
    # 1.9.2. Add key with timeout to prevent hanging
    local timeout_cmd
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout 30"
    else
        timeout_cmd=""
    fi
    
    # 1.9.3. Try with Apple Keychain first (macOS)
    if $timeout_cmd /usr/bin/ssh-add --apple-use-keychain "$SSH_KEY_PATH" 2>/dev/null; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ SSH key added with Apple Keychain" >&2
        return 0
    fi
    
    # 1.9.4. Fallback to standard ssh-add
    if $timeout_cmd /usr/bin/ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
        [[ "$debug_mode" == "1" ]] && echo "# [secure-ssh] ✅ SSH key added (standard)" >&2
        return 0
    fi
    
    echo "# [secure-ssh] ❌ Failed to add SSH key" >&2
    return 1
}

# 1.10. Public Management Functions
secure_ssh_restart() {
    echo "# [secure-ssh] Restarting SSH agent..."
    _secure_ssh_setup "force"
}

secure_ssh_status() {
    echo "=== Secure SSH Agent Status ==="
    echo "Environment Variables:"
    echo "  SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-'<unset>'}"
    echo "  SSH_AGENT_PID: ${SSH_AGENT_PID:-'<unset>'}"
    
    echo "Process Status:"
    if [[ -n "$SSH_AGENT_PID" ]]; then
        if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
            echo "  ✅ Agent process running (PID: $SSH_AGENT_PID)"
        else
            echo "  ❌ Agent process not found (PID: $SSH_AGENT_PID)"
        fi
    else
        echo "  ❌ No agent PID set"
    fi
    
    echo "Socket Status:"
    if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
        echo "  ✅ Socket accessible: $SSH_AUTH_SOCK"
    else
        echo "  ❌ Socket not accessible: ${SSH_AUTH_SOCK:-'<unset>'}"
    fi
    
    echo "Loaded Keys:"
    /usr/bin/ssh-add -l 2>/dev/null || echo "  ❌ No keys loaded or agent not accessible"
    
    echo "Environment File:"
    if [[ -f "$SSH_AGENT_ENV_FILE" ]]; then
        local file_age
        file_age=$(( $(date +%s) - $(stat -f "%m" "$SSH_AGENT_ENV_FILE" 2>/dev/null || echo 0) ))
        echo "  ✅ Environment file exists (age: ${file_age}s)"
    else
        echo "  ❌ Environment file not found"
    fi
}

secure_ssh_test() {
    echo "# [secure-ssh] Testing SSH connectivity..."
    
    echo "GitHub SSH Test:"
    if ssh -o ConnectTimeout=10 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "  ✅ GitHub SSH connection successful"
    else
        echo "  ❌ GitHub SSH connection failed"
        return 1
    fi
    
    echo "Key Verification:"
    local key_count
    key_count=$(/usr/bin/ssh-add -l 2>/dev/null | wc -l)
    if (( key_count > 0 )); then
        echo "  ✅ SSH keys loaded ($key_count)"
    else
        echo "  ❌ No SSH keys loaded"
        return 1
    fi
    
    return 0
}

## 2. Initialization

# 2.1. Set up secure SSH agent on shell startup
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%N}" == *"secure-ssh-agent"* ]]; then
    # Script being executed directly or sourced for testing
    :
else
    # Normal shell startup - run secure SSH setup
    _secure_ssh_setup "auto"
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [security] ✅ Secure SSH agent management loaded" >&2
