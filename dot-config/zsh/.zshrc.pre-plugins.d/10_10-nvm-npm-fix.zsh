# Fix NVM and NPM_CONFIG_PREFIX conflict + Add Bun to PATH
# This must run before NVM and zsh-abbr plugins load

zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"

# Add Bun to PATH if it exists (needed for zsh-abbr dependencies)
if [[ -d "$HOME/.local/share/bun/bin" ]] && [[ ! "$PATH" == *"$HOME/.local/share/bun/bin"* ]]; then
    export PATH="$HOME/.local/share/bun/bin:$PATH"
    zsh_debug_echo "# Added Bun to PATH for zsh-abbr dependencies"
fi

# Intelligent NPM_CONFIG_PREFIX handling based on NVM presence
# Check for NVM in multiple ways (Herd NVM, Homebrew NVM, manual install)
if [[ -n "${NVM_DIR:-}" ]] || [[ -f "$HOME/.nvm/nvm.sh" ]] || [[ -f "/usr/local/opt/nvm/nvm.sh" ]] || [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    # NVM is available, ensure NPM_CONFIG_PREFIX is not set to avoid conflicts
    if [[ -n "$NPM_CONFIG_PREFIX" ]]; then
        export NPM_CONFIG_PREFIX_BACKUP="$NPM_CONFIG_PREFIX"
        zsh_debug_echo "# Backing up and unsetting NPM_CONFIG_PREFIX for NVM compatibility"
        unset NPM_CONFIG_PREFIX
    fi
    zsh_debug_echo "# NVM detected - NPM_CONFIG_PREFIX kept unset for compatibility"
else
    # No NVM detected, safe to set NPM_CONFIG_PREFIX for global package management
    if [[ -z "$NPM_CONFIG_PREFIX" ]]; then
        export NPM_CONFIG_PREFIX="$HOME/.local/share/npm"
        zsh_debug_echo "# No NVM detected - NPM_CONFIG_PREFIX set to $NPM_CONFIG_PREFIX"
    fi
fi
