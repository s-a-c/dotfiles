#!/usr/bin/env zsh
# 210-SSH-AND-SECURITY.ZSH - Inlined (was sourcing 75-ssh-and-security.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n ${_LOADED_SSH_SECURITY_REDESIGN:-} ]]; then return 0; fi
export _LOADED_SSH_SECURITY_REDESIGN=1
_ssh_debug(){ [[ -n ${ZSH_DEBUG:-} ]] && zf::debug "[SSH-SECURITY] $1" || true; }
_ssh_debug "Loading SSH agent and security setup (v2.0.0)"
if [[ -z ${_SSH_AGENT_LEGACY_GUARD_APPLIED:-} ]]; then
  _SSH_AGENT_LEGACY_GUARD_APPLIED=1
  local _legacy_agent_files=("$HOME/.ssh/ssh-agent" "$ZDOTDIR/.ssh/ssh-agent")
  local _f
  for _f in "${_legacy_agent_files[@]}"; do
    if [[ -f "$_f" && -r "$_f" ]]; then
      if [[ -z ${SSH_AUTH_SOCK:-} || -z ${SSH_AGENT_PID:-} ]]; then
        _ssh_debug "Sourcing legacy ssh-agent env file: $_f"
        source "$_f" 2>/dev/null || true
      else
        _ssh_debug "Skipping legacy env file: $_f"
      fi
    fi
  done
  unset _legacy_agent_files _f
fi

export SSH_AGENT_TIMEOUT="${SSH_AGENT_TIMEOUT:-3600}"
export SSH_AUTH_SOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-$USER"

_setup_ssh_agent(){
  _ssh_debug "Setting up SSH agent"
  if [[ -n ${SSH_AGENT_PID:-} ]] && kill -0 "${SSH_AGENT_PID}" 2>/dev/null; then
    _ssh_debug "SSH agent already running (PID: $SSH_AGENT_PID)"
    return 0
  fi

  if [[ -S ${SSH_AUTH_SOCK:-} ]]; then
    if ssh-add -l >/dev/null 2>&1; then
      _ssh_debug "Connected to existing SSH agent via socket"
      return 0
    else
      _ssh_debug "Stale SSH socket, cleaning"
      unset SSH_AUTH_SOCK SSH_AGENT_PID
    fi
  fi

  if [[ -f "$SSH_AUTH_SOCK_FILE" ]]; then
    source "$SSH_AUTH_SOCK_FILE" 2>/dev/null || true
    if [[ -S ${SSH_AUTH_SOCK:-} ]] && ssh-add -l >/dev/null 2>&1; then
      _ssh_debug "Restored SSH agent from persistent socket"
      return 0
    fi
  fi

  _ssh_debug "Starting new SSH agent"
  eval "$(ssh-agent -s -t "$SSH_AGENT_TIMEOUT")" >/dev/null
  if [[ -n ${SSH_AGENT_PID:-} && -n ${SSH_AUTH_SOCK:-} ]]; then
    {
      echo "export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'"
      echo "export SSH_AGENT_PID='$SSH_AGENT_PID'"
    } > "$SSH_AUTH_SOCK_FILE"
    chmod 600 "$SSH_AUTH_SOCK_FILE"
    _ssh_debug "SSH agent started (PID: $SSH_AGENT_PID, Socket: $SSH_AUTH_SOCK)"
    _load_ssh_keys
    return 0
  else
    _ssh_debug "Failed to start SSH agent"
    return 1
  fi
}

_load_ssh_keys(){
  local -a key_files=("$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ecdsa")
  local loaded_keys=0 key_file
  for key_file in "${key_files[@]}"; do
    if [[ -f "$key_file" && -r "$key_file" ]]; then
      if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}')"; then
        if SSH_ASKPASS="" ssh-add -t "$SSH_AGENT_TIMEOUT" "$key_file" >/dev/null 2>&1; then
          _ssh_debug "Loaded SSH key: ${key_file:t}"
          ((loaded_keys++))
        else
          _ssh_debug "Failed to load SSH key: ${key_file:t}"
        fi
      else
        _ssh_debug "SSH key already loaded: ${key_file:t}"
        ((loaded_keys++))
      fi
    fi
  done
  _ssh_debug "SSH keys loaded: $loaded_keys"
}

if [[ ${ZSH_ENABLE_SSH_AGENT:-1} == 1 ]]; then
  _setup_ssh_agent
else
  _ssh_debug "SSH agent disabled by ZSH_ENABLE_SSH_AGENT"
fi
if [[ ! -f $HOME/.ssh/config ]]; then _ssh_debug "Creating basic SSH client configuration"; mkdir -p $HOME/.ssh; chmod 700 $HOME/.ssh; cat > $HOME/.ssh/config <<'EOF'
# Default SSH client configuration
Host *
	Protocol 2
	PubkeyAuthentication yes
	PasswordAuthentication no
	ChallengeResponseAuthentication no
	UsePAM yes
	Compression yes
	ServerAliveInterval 60
	ServerAliveCountMax 3
	ControlMaster auto
	ControlPath ~/.ssh/master-%r@%h:%p
	ControlPersist 600
	HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521
	KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
	MACs umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
	Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
EOF
chmod 644 $HOME/.ssh/config; _ssh_debug "Created SSH client configuration"; fi
alias ssh-agent-status='ssh-add -l' ssh-agent-kill='ssh-agent -k' ssh-keys-list='ssh-add -l' ssh-keys-remove='ssh-add -D'
ssh_connect(){ local host=$1; [[ -z $host ]] && { echo 'Usage: ssh_connect <host>' >&2; return 1; }; _ssh_debug "Connecting to: $host"; if ! ssh-add -l >/dev/null 2>&1; then _ssh_debug 'No SSH keys loaded, attempting to load'; _load_ssh_keys; fi; [[ -n ${ZSH_DEBUG:-} ]] && ssh -v $host || ssh $host; }
if command -v gpgconf >/dev/null 2>&1 && gpgconf --list-options gpg-agent | grep -q enable-ssh-support; then _ssh_debug "GPG agent SSH support available"; use_gpg_ssh(){ _ssh_debug 'Switching to GPG agent for SSH'; unset SSH_AGENT_PID; export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"; _ssh_debug 'SSH_AUTH_SOCK set to GPG agent socket'; }; [[ ${USE_GPG_SSH_AGENT:-0} == 1 ]] && use_gpg_ssh; fi
generate_ssh_key(){ local key_type=${1:-ed25519} comment=${2:-$USER@$(hostname)} filename=${3:-id_$key_type}; _ssh_debug "Generating SSH key type=$key_type"; case $key_type in ed25519) ssh-keygen -t ed25519 -C $comment -f $HOME/.ssh/$filename;; rsa) ssh-keygen -t rsa -b 4096 -C $comment -f $HOME/.ssh/$filename;; ecdsa) ssh-keygen -t ecdsa -b 521 -C $comment -f $HOME/.ssh/$filename;; *) echo 'Unsupported key type' >&2; return 1;; esac; if [[ -f $HOME/.ssh/$filename ]]; then chmod 600 $HOME/.ssh/$filename; chmod 644 $HOME/.ssh/$filename.pub; _ssh_debug "SSH key generated: $filename"; fi }
ssh_security_audit(){ _ssh_debug 'Running SSH security audit'; local issues=0; if [[ $(stat -c %a $HOME/.ssh 2>/dev/null) != 700 ]]; then echo '⚠️  SSH directory permissions should be 700'; ((issues++)); fi; for key in $HOME/.ssh/id_*; do [[ -f $key && $key != *.pub ]] || continue; local perms; perms=$(stat -c %a $key 2>/dev/null); [[ $perms == 600 ]] || { echo "⚠️  Private key permissions should be 600: $key ($perms)"; ((issues++)); }; done; if [[ -f $HOME/.ssh/config ]]; then local config_perms; config_perms=$(stat -c %a $HOME/.ssh/config 2>/dev/null); [[ $config_perms == 644 || $config_perms == 600 ]] || { echo "⚠️  SSH config permissions should be 600 or 644: $config_perms"; ((issues++)); }; fi; for key in $HOME/.ssh/id_*.pub; do [[ -f $key ]] || continue; local key_info key_strength; key_info=$(ssh-keygen -lf $key 2>/dev/null); key_strength=$(echo $key_info | awk '{print $1}'); if [[ $key == *id_rsa* && -n $key_strength && $key_strength -lt 2048 ]]; then echo "⚠️  RSA key too weak: $key ($key_strength bits)"; ((issues++)); fi; done; [[ $issues -eq 0 ]] && echo '✅ SSH security audit passed' || echo "❌ SSH security audit found $issues issues"; return $issues }
_cleanup_ssh_agent(){ if [[ -n ${SSH_AGENT_PID:-} && ${ZSH_SSH_AGENT_PERSIST:-1} == 0 ]]; then _ssh_debug 'Cleaning up SSH agent on exit'; ssh-agent -k >/dev/null 2>&1; rm -f $SSH_AUTH_SOCK_FILE 2>/dev/null; fi }
[[ ${ZSH_SSH_AGENT_PERSIST:-1} == 0 ]] && trap _cleanup_ssh_agent EXIT
export SSH_SECURITY_VERSION="2.0.0" SSH_SECURITY_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
_ssh_debug "SSH agent and security setup ready"
unset -f _ssh_debug
return 0
