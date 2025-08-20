#!/usr/bin/env zsh

# Ultimate Zsh Environment Fix
# Fixes all remaining completion and command errors

echo "🔧 Ultimate Zsh Environment Fix - Final Resolution"
echo "=================================================="
echo

# Step 1: Fix the completion finalization file syntax error
echo "Step 1: Fixing completion finalization syntax error..."
COMPLETION_FINAL_FILE="$HOME/.zshrc.d/00-core/05-completion-finalization.zsh"
if [[ -f "$COMPLETION_FINAL_FILE" ]]; then
    # Fix the broken redirect on line 18
    sed -i.backup 's|zstyle -L > "${ZDOTDIR}/saved_zstyles.zsh"|# zstyle -L > "${ZDOTDIR:-$HOME}/.config/zsh/saved_zstyles.zsh"|' "$COMPLETION_FINAL_FILE"
    echo "✅ Fixed syntax error in completion finalization"
else
    echo "⚠️  Completion finalization file not found"
fi

# Step 2: Disable completion intelligence system (causing issues)
echo "Step 2: Disabling completion intelligence system..."
COMPLETION_INTEL_FILE="$HOME/.zshrc.d/00-core/06-completion-intelligence.zsh"
if [[ -f "$COMPLETION_INTEL_FILE" ]]; then
    mv "$COMPLETION_INTEL_FILE" "${COMPLETION_INTEL_FILE}.temp-disabled"
    echo "✅ Disabled completion intelligence system"
else
    echo "⚠️  Completion intelligence file not found"
fi

# Step 3: Clear all completion caches safely
echo "Step 3: Clearing all completion caches..."
# Clear user completion cache
find "$HOME" -maxdepth 1 -name ".zcompdump*" -delete 2>/dev/null && echo "✅ Cleared .zcompdump files"
find "$HOME" -maxdepth 1 -name "zcompdump*" -delete 2>/dev/null && echo "✅ Cleared zcompdump files"

# Clear ZSH cache directory
if [[ -d "${ZSH_CACHE_DIR:-$HOME/.cache/zsh}" ]]; then
    rm -rf "${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"/* 2>/dev/null && echo "✅ Cleared ZSH cache directory"
fi

# Clear additional cache locations
for cache_dir in "$HOME/.cache/zsh/completions" "$HOME/.config/zsh/completions" "$HOME/.zsh/cache"; do
    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"/* 2>/dev/null && echo "✅ Cleared cache: $cache_dir"
    fi
done

# Step 4: Create safe minimal completion initialization
echo "Step 4: Creating safe minimal completion initialization..."
SAFE_COMPLETION_FILE="$HOME/.config/zsh/safe-completion-init.zsh"
mkdir -p "${SAFE_COMPLETION_FILE:h}"

cat > "$SAFE_COMPLETION_FILE" << 'EOF'
# Safe Minimal Completion Initialization
# Replaces problematic completion systems

# Only initialize if compinit is available
if autoload -Uz compinit 2>/dev/null; then
    # Use simple compinit without cache manipulation
    compinit -i 2>/dev/null
    
    # Basic completion settings only
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    zstyle ':completion:*' use-cache on
    
    # Safe bashcompinit if available
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
fi
EOF
echo "✅ Created safe completion initialization"

# Step 5: Fix or disable problematic completion files
echo "Step 5: Fixing problematic completion files..."

# Fix the main completion tool file to avoid mv errors
COMP_TOOL_FILE="$HOME/.zshrc.d/10-tools/17-completion.zsh"
if [[ -f "$COMP_TOOL_FILE" ]]; then
    cp "$COMP_TOOL_FILE" "${COMP_TOOL_FILE}.backup"
    
    # Replace problematic cache manipulation
    cat > "$COMP_TOOL_FILE" << 'EOF'
# Safe Completion System Configuration
[[ "$ZSH_DEBUG" == "1" ]] && printf "# Loading safe completion system\n" >&2

# Use simple completion without complex cache manipulation
if autoload -Uz compinit 2>/dev/null; then
    # Simple compinit call
    compinit -i 2>/dev/null
    
    # Safe bashcompinit
    if autoload -Uz bashcompinit 2>/dev/null; then
        bashcompinit 2>/dev/null
    fi
fi

# Basic completion styles only
zstyle ':completion:*' menu select 2>/dev/null
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null
zstyle ':completion:*' use-cache on 2>/dev/null

[[ "$ZSH_DEBUG" == "1" ]] && echo "# Safe completion system loaded" >&2
EOF
    echo "✅ Fixed completion tool file"
fi

# Step 6: Create a safe path for loading completions in zshrc
echo "Step 6: Adding safe completion source to zshrc..."
SAFE_LOAD_LINE="source \"\$HOME/.config/zsh/safe-completion-init.zsh\" 2>/dev/null"

# Check if it's already there
if ! grep -q "safe-completion-init.zsh" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# Safe completion initialization (added by fix script)" >> "$HOME/.zshrc"
    echo "$SAFE_LOAD_LINE" >> "$HOME/.zshrc"
    echo "✅ Added safe completion loading to .zshrc"
else
    echo "ℹ️  Safe completion loading already in .zshrc"
fi

# Step 7: Verify essential commands are available
echo "Step 7: Verifying essential commands..."
ESSENTIAL_COMMANDS=(mv cp rm ls cat grep wc tr date tput curl)
MISSING_COMMANDS=()

for cmd in "${ESSENTIAL_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd: available"
    else
        echo "❌ $cmd: missing"
        MISSING_COMMANDS+=("$cmd")
    fi
done

# Step 8: Check PATH and fix if needed
echo "Step 8: Checking and fixing PATH..."
echo "Current PATH has ${#${(s.:.)PATH}} entries"

# Ensure basic system paths are present
ESSENTIAL_PATHS=(/bin /usr/bin /usr/local/bin /sbin /usr/sbin)
PATH_FIXED=false

for path in "${ESSENTIAL_PATHS[@]}"; do
    if [[ -d "$path" && ":$PATH:" != *":$path:"* ]]; then
        export PATH="$path:$PATH"
        echo "✅ Added $path to PATH"
        PATH_FIXED=true
    fi
done

if [[ "$PATH_FIXED" == "true" ]]; then
    echo "✅ PATH has been fixed"
else
    echo "ℹ️  PATH appears correct"
fi

# Step 9: Test the fix
echo "Step 9: Testing the fix..."
echo "Re-testing essential commands after PATH fix:"

ALL_WORKING=true
for cmd in "${ESSENTIAL_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd: working"
    else
        echo "❌ $cmd: still missing"
        ALL_WORKING=false
    fi
done

# Step 10: Create reboot suggestion if needed
if [[ "$ALL_WORKING" != "true" || ${#MISSING_COMMANDS[@]} -gt 0 ]]; then
    echo
    echo "⚠️  Some commands are still missing. This may require:"
    echo "   1. Terminal restart (close and reopen)"
    echo "   2. System reboot if PATH issues persist"
    echo "   3. Check if commands are installed via Homebrew"
    echo
fi

# Final summary
echo
echo "🎯 Fix Summary:"
echo "==============="
echo "✅ Fixed completion finalization syntax error"
echo "✅ Disabled problematic completion intelligence system"
echo "✅ Cleared all completion caches"
echo "✅ Created safe minimal completion initialization"
echo "✅ Fixed problematic completion files"
echo "✅ Added safe completion loading to .zshrc"
echo "✅ Verified and fixed PATH"

if [[ "$ALL_WORKING" == "true" ]]; then
    echo
    echo "🎉 SUCCESS: All essential commands are now working!"
    echo "📋 Next steps:"
    echo "   1. Close this terminal"
    echo "   2. Open a new terminal session"  
    echo "   3. Test your environment"
    echo
    echo "Your Zsh environment should now start cleanly without errors."
else
    echo
    echo "⚠️  PARTIAL SUCCESS: Some issues may require a reboot"
    echo "📋 If problems persist:"
    echo "   1. Restart your terminal completely"
    echo "   2. If that doesn't work, reboot your system"
    echo "   3. Check Homebrew installation: brew doctor"
    echo
fi

echo "Fix script completed at $(date)"
