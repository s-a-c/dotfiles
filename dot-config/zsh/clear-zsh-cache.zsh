#!/usr/bin/env zsh
# Zsh Cache Clearing Script
# Use this to force a completely clean Zsh reload after configuration changes

echo "🧹 Clearing all Zsh caches and compiled files..."

# Clear completion dumps
rm -f "${ZDOTDIR:-$HOME/.config/zsh}"/.zcompdump* 2>/dev/null
echo "✅ Completion dumps cleared"

# Clear compiled Zsh files
find "${ZDOTDIR:-$HOME/.config/zsh}" -name "*.zwc" -delete 2>/dev/null
echo "✅ Zsh compiled files cleared"

# Clear zgenom caches
rm -f "${ZDOTDIR:-$HOME/.config/zsh}/.zgenom/sources.zsh" 2>/dev/null
rm -rf "${ZDOTDIR:-$HOME/.config/zsh}/.zgenom"/**/**.zwc 2>/dev/null
echo "✅ Zgenom caches cleared"

# Clear .ng system files and caches
rm -f "${ZDOTDIR:-$HOME/.config/zsh}"/.ng-* 2>/dev/null
echo "✅ NG cache files cleared"

# Clear command hash and rehash
hash -df 2>/dev/null
rehash 2>/dev/null
echo "✅ Command hash cleared and rehashed"

# Unload problematic functions from memory
unfunction select_intelligent_ng_fallback 2>/dev/null
unfunction execute_ng_fallback_strategy 2>/dev/null
unfunction check_ng_prevention_readiness 2>/dev/null
unfunction validate_ng_prevention_effectiveness 2>/dev/null
unfunction initialize_ng_failure_patterns 2>/dev/null
unfunction analyze_ng_system_patterns 2>/dev/null
echo "✅ NG functions unloaded from memory"

# Clear any plugin manager caches
if command -v zgenom >/dev/null 2>&1; then
    echo "🔄 Resetting zgenom..."
    zgenom reset >/dev/null 2>&1
    echo "✅ Zgenom reset complete"
fi

echo ""
echo "🎉 Cache clearing complete!"
echo "💡 Now open a fresh Warp tab or run 'exec zsh' to test"
echo ""
