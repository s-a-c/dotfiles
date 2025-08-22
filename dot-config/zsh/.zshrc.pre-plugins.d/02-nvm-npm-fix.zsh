# Fix NVM and NPM_CONFIG_PREFIX conflict + Add Bun to PATH
# This must run before NVM and zsh-abbr plugins load

[[ "$ZSH_DEBUG" == "1" ]] && printf "# ++++++ %s ++++++++++++++++++++++++++++++++++++\n" "$0" >&2

# Add Bun to PATH if it exists (needed for zsh-abbr dependencies)
if [[ -d "$HOME/.local/share/bun/bin" ]] && [[ ! "$PATH" == *"$HOME/.local/share/bun/bin"* ]]; then
    export PATH="$HOME/.local/share/bun/bin:$PATH"
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# Added Bun to PATH for zsh-abbr dependencies" >&2
fi

# Intelligent NPM_CONFIG_PREFIX handling based on NVM presence
# Check for NVM in multiple ways (Herd NVM, Homebrew NVM, manual install)
if [[ -n "${NVM_DIR:-}" ]] || [[ -f "$HOME/.nvm/nvm.sh" ]] || [[ -f "/usr/local/opt/nvm/nvm.sh" ]] || [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    # NVM is available, ensure NPM_CONFIG_PREFIX is not set to avoid conflicts
    if [[ -n "$NPM_CONFIG_PREFIX" ]]; then
        export NPM_CONFIG_PREFIX_BACKUP="$NPM_CONFIG_PREFIX"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# Backing up and unsetting NPM_CONFIG_PREFIX for NVM compatibility" >&2
        unset NPM_CONFIG_PREFIX
    fi
    [[ "$ZSH_DEBUG" == "1" ]] && echo "# NVM detected - NPM_CONFIG_PREFIX kept unset for compatibility" >&2
else
    # No NVM detected, safe to set NPM_CONFIG_PREFIX for global package management
    if [[ -z "$NPM_CONFIG_PREFIX" ]]; then
        export NPM_CONFIG_PREFIX="$HOME/.local/share/npm"
        [[ "$ZSH_DEBUG" == "1" ]] && echo "# No NVM detected - NPM_CONFIG_PREFIX set to $NPM_CONFIG_PREFIX" >&2
    fi
fi
