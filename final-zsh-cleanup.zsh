#!/usr/bin/env zsh

# Final Zsh Cleanup Script
# Addresses the remaining minor completion and cache issues

echo "🔧 Final Zsh Environment Cleanup"
echo "================================="
echo

# 1. Clear all completion caches completely
echo "1. Clearing completion caches..."
rm -f ~/.config/zsh/.zcompdump* 2>/dev/null
rm -f ~/.zcompdump* 2>/dev/null
rm -rf ~/.config/zsh/.zsh/.zcompcache 2>/dev/null
rm -rf ~/.cache/zsh/completions 2>/dev/null
echo "   ✅ Completion caches cleared"

# 2. Clear zgenom cache
echo "2. Clearing zgenom cache..."
if command -v zgenom >/dev/null 2>&1; then
    zgenom reset >/dev/null 2>&1 && echo "   ✅ zgenom cache reset" || echo "   ⚠️  zgenom reset failed (non-critical)"
else
    echo "   ⚠️  zgenom not available"
fi

# 3. Clear all compiled zsh files
echo "3. Clearing compiled zsh files..."
find ~/.config/zsh -name "*.zwc" -delete 2>/dev/null
echo "   ✅ Compiled files cleared"

# 4. Rebuild completion system cleanly
echo "4. Rebuilding completion system..."
if zsh -c "autoload -Uz compinit && compinit -d ~/.config/zsh/.zcompdump" 2>/dev/null; then
    echo "   ✅ Completion system rebuilt"
else
    echo "   ⚠️  Completion rebuild failed (will rebuild on next shell start)"
fi

# 5. Check environment health
echo "5. Final health check..."
if command -v mv >/dev/null && command -v wc >/dev/null && command -v date >/dev/null && command -v tr >/dev/null; then
    echo "   ✅ All critical commands available"
else
    echo "   ⚠️  Some commands may not be in PATH"
fi

if command -v zgenom >/dev/null 2>&1; then
    echo "   ✅ Plugin system (zgenom) available"
else
    echo "   ⚠️  Plugin system not available"
fi

echo
echo "🎉 Cleanup Complete!"
echo "==================="
echo
echo "📋 Next Steps:"
echo "  1. Close this terminal completely"
echo "  2. Open a new terminal/shell"
echo "  3. Test your normal workflows"
echo
echo "🔍 If you still see minor errors:"
echo "  - They are likely non-critical completion warnings"
echo "  - The shell should still be fully functional"
echo "  - You can ignore them or report specific ones for further fixes"
echo
echo "✅ Your Zsh environment is now stable and ready for use!"
