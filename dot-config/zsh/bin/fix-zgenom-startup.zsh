#!/usr/bin/env zsh
# Emergency fix for corrupted zgenom startup
# This script fixes the immediate startup issues

echo "🔧 Fixing zgenom startup issues..."

# Remove corrupted zgenom cache
if [[ -d ~/.config/zsh/.zgenom ]]; then
        zf::debug "📂 Backing up current zgenom directory..."
    mv ~/.config/zsh/.zgenom ~/.config/zsh/.zgenom.backup.$(date +%Y%m%d_%H%M%S)
fi

# Remove any stale init files
rm -f ~/.config/zsh/.zgenom/init.zsh

echo "✅ Corrupted cache removed"
echo "💡 Next shell startup will regenerate clean zgenom cache"
echo ""
echo "To complete the fix:"
echo "1. Start a new zsh session"
echo "2. Let zgenom regenerate its cache (will take a moment)"
echo "3. Verify k command works: k"
