#!/usr/bin/env bash
set -euo pipefail

echo "🚨 EMERGENCY: Fixing stow-managed zsh configuration"
echo "=================================================="

BACKUP_DIR="$HOME/.config/zsh-backup-$(date +%Y%m%d-%H%M%S)"
DOTFILES_DIR="$HOME/dotfiles"
TARGET_DIR="$HOME/.config/zsh"

echo "1. Creating backup of current ~/.config/zsh..."
if [[ -e "$TARGET_DIR" ]]; then
    cp -R "$TARGET_DIR" "$BACKUP_DIR"
    echo "✅ Backup created: $BACKUP_DIR"
else
    echo "ℹ️  No existing ~/.config/zsh found"
fi

echo ""
echo "2. Removing current ~/.config/zsh (it should be a stow symlink)..."
if [[ -e "$TARGET_DIR" ]]; then
    rm -rf "$TARGET_DIR"
    echo "✅ Removed $TARGET_DIR"
fi

echo ""
echo "3. Ensuring ~/.config directory exists..."
mkdir -p "$HOME/.config"

echo ""
echo "4. Using stow to create proper symlink..."
cd "$DOTFILES_DIR"
stow -v dot-config

echo ""
echo "5. Verifying the fix..."
if [[ -L "$TARGET_DIR" ]]; then
    TARGET_LINK=$(readlink "$TARGET_DIR")
    echo "✅ SUCCESS: ~/.config/zsh is now a symlink"
    echo "   Points to: $TARGET_LINK"
    echo "   Resolves to: $(realpath "$TARGET_DIR")"
    
    # Test that key files are accessible
    if [[ -f "$TARGET_DIR/.zshrc.d.legacy/consolidated-modules/02-performance-monitoring.zsh" ]]; then
        echo "✅ Legacy performance module accessible via symlink"
    else
        echo "❌ Warning: Legacy performance module not found via symlink"
    fi
    
elif [[ -d "$TARGET_DIR" ]]; then
    echo "❌ ERROR: ~/.config/zsh is still a directory, not a symlink"
    exit 1
else
    echo "❌ ERROR: ~/.config/zsh does not exist after stow"
    exit 1
fi

echo ""
echo "6. Cleaning up any stow conflicts..."
# Check for common stow conflicts
if stow -n -v dot-config 2>&1 | grep -q "WARNING\|ERROR"; then
    echo "⚠️  Stow reports potential conflicts:"
    stow -n -v dot-config
else
    echo "✅ No stow conflicts detected"
fi

echo ""
echo "🎉 CRISIS RESOLVED!"
echo "✅ ~/.config/zsh is now properly stow-managed"
echo "✅ Your git-backed dotfiles are properly symlinked"
echo "✅ Backup preserved at: $BACKUP_DIR"
echo ""
echo "You can now:"
echo "  - Test your zsh configuration: /opt/homebrew/bin/zsh -l"
echo "  - Remove backup if satisfied: rm -rf '$BACKUP_DIR'"