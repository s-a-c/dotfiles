#!/usr/bin/env zsh
# Targeted fix for shell early exit issue

echo "🔍 Investigating shell early exit issue..."

# Create a minimal test .zshrc that bypasses all plugins temporarily
echo "📝 Creating diagnostic .zshrc..."

# Backup current .zshrc
cp ~/.zshrc ~/.zshrc.pre-diagnostic.backup

# Create minimal diagnostic .zshrc
cat > ~/.zshrc << 'EOF'
# Minimal diagnostic .zshrc - no plugins, just basic functionality

# Source environment
[[ -f ~/.zshenv ]] && source ~/.zshenv

# Basic zsh options
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt EXTENDED_GLOB

# Basic history
HISTFILE="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Basic completions
autoload -Uz compinit
compinit

# Simple prompt
PS1='%n@%m %1~ %# '

# Test function to verify shell is working
test-shell() {
        zsh_debug_echo "✅ Shell is fully functional!"
        zsh_debug_echo "Shell PID: $$"
        zsh_debug_echo "ZSH Version: $ZSH_VERSION"
        zsh_debug_echo "ZDOTDIR: $ZDOTDIR"
        zsh_debug_echo "Interactive: $([[ -o interactive ]] &&     zsh_debug_echo "YES" || zsh_debug_echo "NO")"
}

echo "🎯 Minimal shell loaded - test with 'test-shell' command"
EOF

echo "✅ Created minimal diagnostic .zshrc"

# Test the minimal shell
echo "🧪 Testing minimal shell (no plugins)..."
MINIMAL_TEST=$(/opt/homebrew/bin/zsh -i -c 'echo "MINIMAL_SHELL_TEST_START";     zsh_debug_echo "PID: $$";     zsh_debug_echo "VERSION: $ZSH_VERSION";     zsh_debug_echo "MINIMAL_SHELL_TEST_END"' 2>&1)

echo "📊 Minimal shell test result:"
echo "$MINIMAL_TEST"

if [[ "$MINIMAL_TEST" == *"MINIMAL_SHELL_TEST_END"* ]]; then
        zsh_debug_echo "✅ Minimal shell works perfectly!"
        zsh_debug_echo ""
        zsh_debug_echo "🔍 The issue is in your plugin configuration, not core shell functionality."
        zsh_debug_echo ""
        zsh_debug_echo "Next steps:"
        zsh_debug_echo "1. Test this minimal shell: /opt/homebrew/bin/zsh"
        zsh_debug_echo "2. If it works, gradually add back functionality"
        zsh_debug_echo "3. Use 'restore-original-config' to restore full config when ready"

    # Create restore function
    cat > ~/.restore-original-config << 'EOF'
#!/usr/bin/env zsh
echo "🔄 Restoring original configuration..."
if [[ -f ~/.zshrc.pre-diagnostic.backup ]]; then
    cp ~/.zshrc.pre-diagnostic.backup ~/.zshrc
        zsh_debug_echo "✅ Original .zshrc restored"
        zsh_debug_echo "💡 Start a new shell to test full configuration"
else
        zsh_debug_echo "❌ No backup found"
fi
rm -f ~/.restore-original-config
EOF
    chmod +x ~/.restore-original-config

else
        zsh_debug_echo "❌ Even minimal shell has issues!"
        zsh_debug_echo "This suggests a fundamental problem in .zshenv or shell setup."
        zsh_debug_echo ""
        zsh_debug_echo "Debug info:"
        zsh_debug_echo "$MINIMAL_TEST"
fi

echo ""
echo "🔧 Current status:"
echo "• Minimal shell configuration active"
echo "• Original config backed up to ~/.zshrc.pre-diagnostic.backup"
echo "• Test with: /opt/homebrew/bin/zsh"
echo "• Restore with: /opt/homebrew/bin/zsh ~/.restore-original-config"
