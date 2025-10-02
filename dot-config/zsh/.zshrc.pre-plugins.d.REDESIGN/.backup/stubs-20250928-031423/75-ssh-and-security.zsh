#!/usr/bin/env zsh
# LEGACY STUB: 75-ssh-and-security.zsh (migrated to 210-ssh-and-security.zsh)
return 0
export _LOADED_SSH_SECURITY_REDESIGN=1

# Debug helper
_ssh_debug() {
    [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[SSH-SECURITY] $1" || true
}

_ssh_debug "Loading SSH agent and security setup (v2.0.0)"

# Legacy compatibility guard (AI-authored augmentation)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Rationale: Prevent noisy warnings from historical patterns that `cat` or `source`
# a stale ~/.ssh/ssh-agent env file (seen in legacy backups). We provide a
# harmless shim variable & loader only if file exists. This keeps set -u safe
# and avoids confusing user output (design policy: defensive idempotency).
if [[ -z ${_SSH_AGENT_LEGACY_GUARD_APPLIED:-} ]]; then
    _SSH_AGENT_LEGACY_GUARD_APPLIED=1
    # Common legacy paths that may have been used to persist agent env
    local _legacy_agent_files=("$HOME/.ssh/ssh-agent" "$ZDOTDIR/.ssh/ssh-agent" )
    for _f in "${_legacy_agent_files[@]}"; do # policy: only conditional source (no blind cat)
        if [[ -f "$_f" && -r "$_f" ]]; then
            # Only source if it actually exports the expected vars and ours are unset
            if [[ -z ${SSH_AUTH_SOCK:-} || -z ${SSH_AGENT_PID:-} ]]; then
                _ssh_debug "Sourcing legacy ssh-agent env file: $_f"
                # shellcheck disable=SC1090
                source "$_f" 2>/dev/null || true
            else
                _ssh_debug "Skipping legacy env file (agent already active): $_f"
            fi
        fi
    done
    unset _legacy_agent_files _f
fi

# ==============================================================================
# SECTION 1: SSH AGENT MANAGEMENT
# ==============================================================================

# SSH agent configuration
export SSH_AGENT_TIMEOUT="${SSH_AGENT_TIMEOUT:-3600}"  # 1 hour timeout
export SSH_AUTH_SOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-$USER"

# Enhanced SSH agent setup function
_setup_ssh_agent() {
    local agent_pid=""
    local agent_sock=""

    _ssh_debug "Setting up SSH agent"

    # Check if SSH agent is already running
    if [[ -n "${SSH_AGENT_PID:-}" ]] && kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
        _ssh_debug "SSH agent already running (PID: $SSH_AGENT_PID)"
        return 0
    fi

    # Try to connect to existing agent via socket
    if [[ -S "${SSH_AUTH_SOCK:-}" ]]; then
        # Test if the socket works
        if ssh-add -l >/dev/null 2>&1; then
            _ssh_debug "Connected to existing SSH agent via socket"
            return 0
        else
            _ssh_debug "SSH socket exists but not responsive, cleaning up"
            unset SSH_AUTH_SOCK SSH_AGENT_PID
        fi
    fi

    # Check for persistent SSH agent socket file
    if [[ -f "$SSH_AUTH_SOCK_FILE" ]]; then
        source "$SSH_AUTH_SOCK_FILE"
        if [[ -S "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then
            _ssh_debug "Restored SSH agent from persistent socket"
            return 0
        fi
    fi

    # Start new SSH agent
    _ssh_debug "Starting new SSH agent"
    eval "$(ssh-agent -s -t $SSH_AGENT_TIMEOUT)" >/dev/null

    if [[ -n "${SSH_AGENT_PID:-}" ]] && [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        # Save agent info to file for persistence
        {
            echo "export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'"
            echo "export SSH_AGENT_PID='$SSH_AGENT_PID'"
        } > "$SSH_AUTH_SOCK_FILE"
        chmod 600 "$SSH_AUTH_SOCK_FILE"

        _ssh_debug "SSH agent started (PID: $SSH_AGENT_PID, Socket: $SSH_AUTH_SOCK)"

        # Auto-load common SSH keys if they exist
        _load_ssh_keys

        return 0
    else
        _ssh_debug "Failed to start SSH agent"
        return 1
    fi
}

# Load SSH keys function
_load_ssh_keys() {
    local -a key_files=(
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_ecdsa"
    )

    local loaded_keys=0

    for key_file in "${key_files[@]}"; do
        if [[ -f "$key_file" ]] && [[ -r "$key_file" ]]; then
            # Check if key is already loaded
            if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}')"; then
                # Add key with timeout
                if SSH_ASKPASS="" ssh-add -t "$SSH_AGENT_TIMEOUT" "$key_file" >/dev/null 2>&1; then
                    _ssh_debug "Loaded SSH key: $(basename "$key_file")"
                    ((loaded_keys++))
                else
                    _ssh_debug "Failed to load SSH key: $(basename "$key_file") (may require passphrase)"
                fi
            else
                _ssh_debug "SSH key already loaded: $(basename "$key_file")"
                ((loaded_keys++))
            fi
        fi
    done

    _ssh_debug "SSH keys loaded: $loaded_keys"
    return 0
}

# Initialize SSH agent if enabled
if [[ "${ZSH_ENABLE_SSH_AGENT:-1}" == "1" ]]; then
    _setup_ssh_agent
else
    _ssh_debug "SSH agent disabled by ZSH_ENABLE_SSH_AGENT"
fi

# ==============================================================================
# SECTION 2: SSH CLIENT CONFIGURATION
# ==============================================================================

# SSH client security settings
if [[ ! -f "$HOME/.ssh/config" ]]; then
    _ssh_debug "Creating basic SSH client configuration"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    cat > "$HOME/.ssh/config" <<'EOF'
# Default SSH client configuration
Host *
    # Security settings
    Protocol 2
    PubkeyAuthentication yes
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    UsePAM yes

    # Performance settings
    Compression yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

    # Connection multiplexing
    ControlMaster auto
    ControlPath ~/.ssh/master-%r@%h:%p
    ControlPersist 600

    # Security preferences
    HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    MACs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
EOF
    chmod 644 "$HOME/.ssh/config"
    _ssh_debug "Created SSH client configuration"
fi

# ==============================================================================
# SECTION 3: SSH ALIASES AND FUNCTIONS
# ==============================================================================

# SSH utility aliases
alias ssh-agent-status='ssh-add -l'
alias ssh-agent-kill='ssh-agent -k'
alias ssh-keys-list='ssh-add -l'
alias ssh-keys-remove='ssh-add -D'

# Enhanced SSH function with connection validation
ssh_connect() {
    local host="$1"
    if [[ -z "$host" ]]; then
        echo "Usage: ssh_connect <host>" >&2
        return 1
    fi

    _ssh_debug "Connecting to: $host"

    # Pre-connection validation
    if ! ssh-add -l >/dev/null 2>&1; then
        _ssh_debug "No SSH keys loaded, attempting to load"
        _load_ssh_keys
    fi

    # Connect with verbose output in debug mode
    if [[ -n "${ZSH_DEBUG:-}" ]]; then
        ssh -v "$host"
    else
        ssh "$host"
    fi
}

# ==============================================================================
# SECTION 4: GPG INTEGRATION
# ==============================================================================

# GPG agent integration for SSH
if command -v gpgconf >/dev/null 2>&1; then
    # Check if GPG agent can handle SSH
    if gpgconf --list-options gpg-agent | grep -q "enable-ssh-support"; then
        _ssh_debug "GPG agent SSH support available"

        # Function to use GPG agent for SSH (optional)
        use_gpg_ssh() {
            _ssh_debug "Switching to GPG agent for SSH"
            unset SSH_AGENT_PID
            export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
            _ssh_debug "SSH_AUTH_SOCK set to GPG agent socket"
        }

        # Auto-switch to GPG agent if configured
        if [[ "${USE_GPG_SSH_AGENT:-0}" == "1" ]]; then
            use_gpg_ssh
        fi
    fi
fi

# ==============================================================================
# SECTION 5: SSH SECURITY ENHANCEMENTS
# ==============================================================================

# SSH key generation helper
generate_ssh_key() {
    local key_type="${1:-ed25519}"
    local comment="${2:-$USER@$(hostname)}"
    local filename="${3:-id_$key_type}"

    _ssh_debug "Generating SSH key: type=$key_type, comment=$comment"

    case "$key_type" in
        ed25519)
            ssh-keygen -t ed25519 -C "$comment" -f "$HOME/.ssh/$filename"
            ;;
        rsa)
            ssh-keygen -t rsa -b 4096 -C "$comment" -f "$HOME/.ssh/$filename"
            ;;
        ecdsa)
            ssh-keygen -t ecdsa -b 521 -C "$comment" -f "$HOME/.ssh/$filename"
            ;;
        *)
            echo "Unsupported key type: $key_type" >&2
            echo "Supported types: ed25519, rsa, ecdsa" >&2
            return 1
            ;;
    esac

    if [[ -f "$HOME/.ssh/$filename" ]]; then
        chmod 600 "$HOME/.ssh/$filename"
        chmod 644 "$HOME/.ssh/$filename.pub"
        _ssh_debug "SSH key generated: $HOME/.ssh/$filename"
    fi
}

# SSH security audit function
ssh_security_audit() {
    _ssh_debug "Running SSH security audit"

    local issues=0

    # Check SSH directory permissions
    if [[ "$(stat -c %a "$HOME/.ssh" 2>/dev/null)" != "700" ]]; then
        echo "⚠️  SSH directory permissions should be 700: $HOME/.ssh"
        ((issues++))
    fi

    # Check private key permissions
    for key in "$HOME/.ssh"/id_*; do
        if [[ -f "$key" ]] && [[ ! "$key" == *.pub ]]; then
            local perms
            perms="$(stat -c %a "$key" 2>/dev/null)"
            if [[ "$perms" != "600" ]]; then
                echo "⚠️  Private key permissions should be 600: $key (currently $perms)"
                ((issues++))
            fi
        fi
    done

    # Check SSH config permissions
    if [[ -f "$HOME/.ssh/config" ]]; then
        local config_perms
        config_perms="$(stat -c %a "$HOME/.ssh/config" 2>/dev/null)"
        if [[ "$config_perms" != "644" ]] && [[ "$config_perms" != "600" ]]; then
            echo "⚠️  SSH config permissions should be 600 or 644: $HOME/.ssh/config (currently $config_perms)"
            ((issues++))
        fi
    fi

    # Check for weak keys
    for key in "$HOME/.ssh"/id_*.pub; do
        if [[ -f "$key" ]]; then
            local key_info key_strength
            key_info="$(ssh-keygen -lf "$key" 2>/dev/null)"
            key_strength="$(echo "$key_info" | awk '{print $1}')"
            if [[ "$key" =~ id_rsa ]] && [[ -n "$key_strength" ]] && [[ "$key_strength" -lt 2048 ]]; then
                echo "⚠️  RSA key too weak: $key ($key_strength bits, should be ≥2048)"
                ((issues++))
            fi
        fi
    done

    if [[ $issues -eq 0 ]]; then
        echo "✅ SSH security audit passed"
    else
        echo "❌ SSH security audit found $issues issues"
    fi

    return $issues
}

# ==============================================================================
# SECTION 6: CLEANUP ON EXIT
# ==============================================================================

# SSH agent cleanup on shell exit
_cleanup_ssh_agent() {
    if [[ -n "${SSH_AGENT_PID:-}" ]] && [[ "${ZSH_SSH_AGENT_PERSIST:-1}" == "0" ]]; then
        _ssh_debug "Cleaning up SSH agent on exit"
        ssh-agent -k >/dev/null 2>&1
        rm -f "$SSH_AUTH_SOCK_FILE" 2>/dev/null
    fi
}

# Register cleanup function
if [[ "${ZSH_SSH_AGENT_PERSIST:-1}" == "0" ]]; then
    trap _cleanup_ssh_agent EXIT
fi

# ==============================================================================
# MODULE COMPLETION
# ==============================================================================

export SSH_SECURITY_VERSION="2.0.0"
export SSH_SECURITY_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"

_ssh_debug "SSH agent and security setup ready"

# Clean up helper functions
unset -f _ssh_debug

# ==============================================================================
# END OF SSH AND SECURITY MODULE
# ==============================================================================
