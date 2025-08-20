#!/usr/bin/env zsh
# SSH Agent Configuration for Oh My Zsh Plugin
# This must run BEFORE the ssh-agent plugin loads to prevent FIDO key prompts

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [pre-plugins] Configuring ssh-agent plugin" >&2

# Configure ssh-agent plugin to only load specific non-FIDO keys
# and avoid the problematic --apple-load-keychain that tries to load ALL keys
zstyle ':omz:plugins:ssh-agent' agent-forwarding yes
zstyle ':omz:plugins:ssh-agent' autoload yes
zstyle ':omz:plugins:ssh-agent' identities id_ed25519  # Only load the regular Ed25519 key, not FIDO keys
zstyle ':omz:plugins:ssh-agent' lazy yes
zstyle ':omz:plugins:ssh-agent' quiet yes

# Use only --apple-use-keychain, remove the problematic --apple-load-keychain
# --apple-use-keychain: Store passphrases in keychain when adding keys
# DO NOT use --apple-load-keychain: Would load ALL keys from keychain including FIDO keys
zstyle ':omz:plugins:ssh-agent' ssh-add-args --apple-use-keychain

# Additional safeguards to prevent FIDO key access
# Override any default key discovery behavior
zstyle ':omz:plugins:ssh-agent' helper ''
zstyle ':omz:plugins:ssh-agent' lifetime 0

# Set SSH_AUTH_SOCK to prevent plugin from starting a new agent if one exists
# This helps avoid key re-loading during plugin initialization
if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l >/dev/null 2>&1; then
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# [pre-plugins] SSH agent already running with keys, skipping auto-load" >&2
fi

[[ "$ZSH_DEBUG" == "1" ]] && echo "# [pre-plugins] SSH agent configured to avoid FIDO key auto-loading" >&2
