#!/usr/bin/env zsh
# Emergency shell startup bypass script
# This creates a minimal .zshrc that allows you to get a working shell
# UPDATED: Consistent with .zshenv and ZDOTDIR structure

# Source .zshenv to ensure consistent environment
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

echo "🚨 Creating emergency minimal zsh configuration..."

# Use ZDOTDIR from .zshenv, with fallback
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ZSHRC_FILE="$ZDOTDIR/.zshrc"

# Create backup of current .zshrc using safe_date if available
if [[ -f "$ZSHRC_FILE" ]]; then
    if declare -f safe_date >/dev/null 2>&1; then
        backup_suffix=$(safe_date "+%Y%m%d_%H%M%S")
    else
        backup_suffix=$(date "+%Y%m%d_%H%M%S" 2>/dev/null || zsh_debug_echo "backup")
    fi
    cp "$ZSHRC_FILE" "${ZSHRC_FILE}.backup.${backup_suffix}"
        zsh_debug_echo "✅ Backed up existing .zshrc to ${ZSHRC_FILE}.backup.${backup_suffix}"
fi

# Create minimal .zshrc that uses .zshenv settings
cat > "$ZSHRC_FILE" << 'EOF'
# Emergency minimal zsh configuration
# This bypasses problematic plugin loading while using .zshenv settings

# Source the environment setup (should already be loaded, but ensure it's available)
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options only (universal options already set in .zshenv)
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# History settings - use values from .zshenv, don't override
# HISTFILE, HISTSIZE, SAVEHIST already set in .zshenv with correct values
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Use ZSH_COMPDUMP from .zshenv for consistency
autoload -Uz compinit
if [[ -n "$ZSH_COMPDUMP" ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit
fi

# PATH already configured in .zshenv - no additional setup needed

# Basic prompt
PS1='%n@%m %1~ %# '

echo "✅ Emergency zsh session active"
echo "💡 Run 'fix-zsh-full' to restore full configuration when ready"

# Create function to restore full config
fix-zsh-full() {
        zsh_debug_echo "🔧 Restoring full zsh configuration..."

    # Restore original .zshrc if backup exists
    local backup_file=$(ls -t "${ZDOTDIR}/.zshrc.backup."* 2>/dev/null | head -1)
    if [[ -n "$backup_file" ]]; then
        cp "$backup_file" "${ZDOTDIR}/.zshrc"
            zsh_debug_echo "✅ Restored .zshrc from $backup_file"
    else
            zsh_debug_echo "❌ No backup found to restore"
        return 1
    fi

    # Clear zgenom cache using paths from .zshenv
    if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
        rm -rf "$ZGEN_DIR"
            zsh_debug_echo "✅ Cleared zgenom cache at $ZGEN_DIR"
    else
            zsh_debug_echo "⚠️ ZGEN_DIR not set or directory not found"
    fi

        zsh_debug_echo "💡 Start a new shell session to test full configuration"
}
EOF

echo "✅ Created emergency minimal .zshrc at $ZSHRC_FILE"
echo ""
echo "🎯 Next steps:"
echo "1. Start a new zsh session (should work now)"
echo "2. In the new session, run 'fix-zsh-full' to restore full config"
echo "3. Test the restored configuration"
