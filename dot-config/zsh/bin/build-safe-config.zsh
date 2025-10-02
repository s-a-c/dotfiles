#!/usr/bin/env zsh
# Step-by-step plugin restoration to identify the problematic component
# UPDATED: Consistent with .zshenv configuration

# Source .zshenv to ensure consistent environment
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

echo "🔧 Building safe, working zsh configuration step by step..."

# Use paths and functions from .zshenv
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ZSHRC_FILE="$ZDOTDIR/.zshrc"

# Add compinit guard function to prevent duplicate calls (avoids conflict with .zshenv)
safe_compinit() {
    # Only run compinit if it hasn't been run already in this session
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        # Use ZSH_COMPDUMP from .zshenv if available
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
            zf::debug "✅ compinit initialized"
    else
            zf::debug "⚠️ compinit already initialized, skipping"
    fi
}

# Test current minimal shell first
echo "✓ Testing current minimal shell..."
MINIMAL_TEST=$(/opt/homebrew/bin/zsh -i -c 'echo "MINIMAL_WORKS"; exit 0' 2>/dev/null)
if [[ "$MINIMAL_TEST" != *"MINIMAL_WORKS"* ]]; then
        zf::debug "❌ Minimal shell not working. Please run diagnose-early-exit.zsh first."
    exit 1
fi
echo "✅ Minimal shell confirmed working"

# Create progressive configuration steps
echo "📝 Creating step-by-step configuration..."

# Step 1: Add basic zgenom without plugins
cat > "${ZSHRC_FILE}.step1" << 'EOF'
# Step 1: Basic shell + zgenom framework (no plugins)
# Source .zshenv to get consistent environment variables
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options only (universal options already in .zshenv)
setopt AUTO_CD INTERACTIVE_COMMENTS

# History options for interactive shell (base history config already in .zshenv)
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# REMOVED: Conflicting history variables - use values from .zshenv instead
# HISTFILE, HISTSIZE, SAVEHIST are already set in .zshenv with correct values

# Safe compinit with guard
safe_compinit() {
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        # Use ZSH_COMPDUMP from .zshenv for consistency
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
    fi
}

safe_compinit

# PATH is already configured in .zshenv - no additional setup needed

PS1='[STEP1] %n@%m %1~ %# '
echo "✅ Step 1: Basic shell working"
EOF

# Step 2: Add zgenom framework
cat > "${ZSHRC_FILE}.step2" << 'EOF'
# Step 2: Add zgenom framework (no plugins yet)
# Source .zshenv and step 1 configuration
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options
setopt AUTO_CD INTERACTIVE_COMMENTS
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Safe compinit
safe_compinit() {
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
    fi
}

safe_compinit

# Add zgenom setup using paths from .zshenv
if [[ -f "$ZGEN_SOURCE/zgenom.zsh" ]]; then
    source "$ZGEN_SOURCE/zgenom.zsh"
        zf::debug "✅ zgenom framework loaded"
else
        zf::debug "❌ zgenom not found at $ZGEN_SOURCE"
fi

PS1='[STEP2] %n@%m %1~ %# '
echo "✅ Step 2: zgenom framework working"
EOF

# Step 3: Add essential plugins one by one
cat > "${ZSHRC_FILE}.step3" << 'EOF'
# Step 3: Add essential plugins gradually
# Source .zshenv and step 2 configuration
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options
setopt AUTO_CD INTERACTIVE_COMMENTS
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Safe compinit
safe_compinit() {
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
    fi
}

safe_compinit

# Load zgenom with essential plugins
if [[ -f "$ZGEN_SOURCE/zgenom.zsh" ]]; then
    source "$ZGEN_SOURCE/zgenom.zsh"

    if ! zgenom saved; then
            zf::debug "Loading essential plugins..."

        # Framework
        zgenom oh-my-zsh

        # Essential Oh-My-ZSH plugins (known to work)
        zgenom oh-my-zsh plugins/git
        zgenom oh-my-zsh plugins/colored-man-pages

        # macOS specific
        if [[ $(uname -s) == "Darwin" ]]; then
            zgenom oh-my-zsh plugins/macos
        fi

        zgenom save
    fi

        zf::debug "✅ Essential plugins loaded"
fi

PS1='[STEP3] %n@%m %1~ %# '
echo "✅ Step 3: Basic shell + essential plugins"
EOF

# Step 4: Add syntax highlighting and history search
cat > "${ZSHRC_FILE}.step4" << 'EOF'
# Step 4: Add syntax highlighting and history features
# Source .zshenv and step 3 configuration
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options
setopt AUTO_CD INTERACTIVE_COMMENTS
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Safe compinit
safe_compinit() {
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
    fi
}

safe_compinit

# Load zgenom with syntax highlighting and history search
if [[ -f "$ZGEN_SOURCE/zgenom.zsh" ]]; then
    source "$ZGEN_SOURCE/zgenom.zsh"

    if ! zgenom saved; then
            zf::debug "Loading with syntax highlighting..."

        zgenom oh-my-zsh

        # Load syntax highlighting FIRST
        zgenom load zdharma-continuum/fast-syntax-highlighting

        # Then history search
        zgenom load zsh-users/zsh-history-substring-search

        # Essential OMZ plugins
        zgenom oh-my-zsh plugins/git
        zgenom oh-my-zsh plugins/colored-man-pages

        if [[ $(uname -s) == "Darwin" ]]; then
            zgenom oh-my-zsh plugins/macos
        fi

        zgenom save
    fi

    # Set up history search keybindings
    zmodload zsh/terminfo
    bindkey "$terminfo[kcuu1]" history-substring-search-up
    bindkey "$terminfo[kcud1]" history-substring-search-down

        zf::debug "✅ Syntax highlighting and history search loaded"
fi

PS1='[STEP4] %n@%m %1~ %# '
echo "✅ Step 4: Basic shell + syntax highlighting + history"
EOF

# Step 5: Add the k plugin (our fixed version)
cat > "${ZSHRC_FILE}.step5" << 'EOF'
# Step 5: Add k plugin (directory listing enhancement)
# Source .zshenv and step 4 configuration
[[ -f "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv" ]] && source "${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/.zshenv"

# Use interactive-specific options
setopt AUTO_CD INTERACTIVE_COMMENTS
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# Safe compinit
safe_compinit() {
    if [[ -z "$_COMPINIT_DONE" ]]; then
        autoload -Uz compinit
        if [[ -n "$ZSH_COMPDUMP" ]]; then
            compinit -d "$ZSH_COMPDUMP"
        else
            compinit
        fi
        export _COMPINIT_DONE=1
    fi
}

safe_compinit

# Load zgenom with k plugin
if [[ -f "$ZGEN_SOURCE/zgenom.zsh" ]]; then
    source "$ZGEN_SOURCE/zgenom.zsh"

    if ! zgenom saved; then
            zf::debug "Loading with k plugin..."

        zgenom oh-my-zsh
        zgenom load zdharma-continuum/fast-syntax-highlighting
        zgenom load zsh-users/zsh-history-substring-search

        # Add the k plugin (with our fix)
        zgenom load supercrabtree/k

        zgenom oh-my-zsh plugins/git
        zgenom oh-my-zsh plugins/colored-man-pages

        if [[ $(uname -s) == "Darwin" ]]; then
            zgenom oh-my-zsh plugins/macos
        fi

        zgenom save
    fi

    zmodload zsh/terminfo
    bindkey "$terminfo[kcuu1]" history-substring-search-up
    bindkey "$terminfo[kcud1]" history-substring-search-down

        zf::debug "✅ K plugin loaded for enhanced directory listings"
fi

PS1='[STEP5] %n@%m %1~ %# '
echo "✅ Step 5: All essential features + k plugin"
EOF

# Create test script for each step
cat > ~/.test-config-steps << 'EOF'
#!/usr/bin/env zsh
# Test each configuration step

echo "🧪 Testing configuration steps..."

test_step() {
    local step=$1
    local config_file=~/.zshrc.step${step}

        zf::debug "Testing Step $step..."
    if [[ ! -f "$config_file" ]]; then
            zf::debug "❌ Config file $config_file not found"
        return 1
    fi

    # Copy config for testing
    cp "$config_file" ~/.zshrc

    # Test the configuration
    local result=$(/opt/homebrew/bin/zsh -i -c "echo 'STEP${step}_SUCCESS'; exit 0" 2>/dev/null)

    if [[ "$result" == *"STEP${step}_SUCCESS"* ]]; then
            zf::debug "✅ Step $step works!"
        return 0
    else
            zf::debug "❌ Step $step failed!"
            zf::debug "Debug output:"
        /opt/homebrew/bin/zsh -i -c "echo 'Test'; exit 0"
        return 1
    fi
}

# Test each step
for step in 1 2 3 4 5; do
        zf::debug "----------------------------------------"
    test_step $step
    if [[ $? -ne 0 ]]; then
            zf::debug "🛑 Step $step failed - this is where the problem occurs!"
            zf::debug "Use: cp ~/.zshrc.step$((step-1)) ~/.zshrc"
            zf::debug "To restore to the last working configuration."
        exit 1
    fi
        zf::debug ""
done

echo "🎉 All steps passed! Your configuration is fully working."
echo "Step 5 is now active with all essential features."
EOF

chmod +x ~/.test-config-steps

echo "✅ Created progressive configuration steps"
echo ""
echo "🎯 Next actions:"
echo "1. Test each step: /opt/homebrew/bin/zsh ~/.test-config-steps"
echo "2. This will identify exactly which component causes the issue"
echo "3. Use the last working step as your stable configuration"
echo ""
echo "Configuration files created:"
echo "• ~/.zshrc.step1 - Basic shell + zgenom framework"
echo "• ~/.zshrc.step2 - + Oh-My-ZSH framework"
echo "• ~/.zshrc.step3 - + Essential plugins"
echo "• ~/.zshrc.step4 - + Syntax highlighting & history"
echo "• ~/.zshrc.step5 - + K plugin (full essential setup)"
echo ""
echo "💡 Once we find the working configuration, you'll have a stable, fast zsh setup!"
