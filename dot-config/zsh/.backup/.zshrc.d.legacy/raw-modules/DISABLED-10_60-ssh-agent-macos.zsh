#!/usr/bin/env zsh
# SSH Agent Management - macOS System Version (Avoids FIDO Key Issues)
# This script ensures we use the macOS system ssh-agent instead of Homebrew version
# and explicitly avoids loading FIDO keys that require user interaction

# Load source/execute detection utils if present (optional)
{
    DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [ -r "$DETECTION_SCRIPT" ]; then
        export ZSH_SOURCE_EXECUTE_TESTING=false
        source "$DETECTION_SCRIPT"
    fi
}

[[ "$ZSH_DEBUG" == "1" ]] && {
        zf::debug "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    zf::debug "# [ssh-agent] Setting up macOS SSH agent"
}

## [tools.ssh-agent-macos] - macOS SSH agent setup
{
    zf::debug "# [tools.ssh-agent-macos]"

    # Function to start ssh-agent properly on macOS
    function start-ssh-agent-macos() {
        local ssh_env_file="${HOME}/.ssh/ssh-agent-env"

        zf::debug "Starting macOS ssh-agent..."

        # Kill any existing ssh-agents
        pkill ssh-agent 2>/dev/null || true

        # Remove old environment file
        command rm -f "$ssh_env_file"

        # Start new ssh-agent using macOS system version (not Homebrew)
        /usr/bin/ssh-agent -s > "$ssh_env_file"
        source "$ssh_env_file" >/dev/null

        # Add only the regular ed25519 key (explicitly exclude FIDO keys)
        zf::debug "Adding regular SSH key (avoiding FIDO keys)..."
        /usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519 2>/dev/null || {
            zf::debug "Warning: Could not add SSH key to keychain"
            /usr/bin/ssh-add ~/.ssh/id_ed25519
        }

        zf::debug "SSH agent started successfully:"
        ssh-add -l
    }

    # Function to check ssh-agent status
    function check-ssh-agent() {
        zf::debug "SSH Agent Status:"
        zf::debug "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
        zf::debug "SSH_AGENT_PID: $SSH_AGENT_PID"
        zf::debug "SSH Agent Process:"
        ps -p "$SSH_AGENT_PID" 2>/dev/null || zf::debug "No process found with PID $SSH_AGENT_PID"
        zf::debug "SSH Keys loaded:"
        ssh-add -l 2>/dev/null || zf::debug "No keys loaded or agent not accessible"
    }

    # Function to test SSH connection
    function test-ssh-github() {
        zf::debug "Testing SSH connection to GitHub..."
        ssh -T git@github.com 2>&1
    }

    # Auto-start ssh-agent if needed
    local ssh_env_file="${HOME}/.ssh/ssh-agent-env"

    # Check if ssh-agent is running and accessible
    if [[ -n "$SSH_AUTH_SOCK" ]] && /usr/bin/ssh-add -l &>/dev/null; then
        zf::debug "# [tools.ssh-agent-macos] Using existing agent"
    else
        zf::debug "# [tools.ssh-agent-macos] Starting new agent"

        # Try to source existing environment file first
        if [[ -f "$ssh_env_file" ]]; then
            source "$ssh_env_file" >/dev/null
            # Check if this agent is still working
            if ! /usr/bin/ssh-add -l &>/dev/null; then
                # Agent is dead, start a new one
                start-ssh-agent-macos >/dev/null
            fi
        else
            # No environment file, start new agent
            start-ssh-agent-macos >/dev/null
        fi
    fi
}

zf::debug "# [ssh-agent] ✅ macOS SSH agent setup complete"
