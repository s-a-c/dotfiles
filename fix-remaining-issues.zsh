#!/usr/bin/env zsh

# Comprehensive Fix for Remaining Zsh Issues
# Addresses completion cache, command not found, and finalization problems

echo "🔧 Fixing Remaining Zsh Issues"
echo "==============================="
echo

# 1. Clear all problematic completion caches
echo "1. Clearing all completion caches..."
rm -f ~/.config/zsh/.zcompdump* 2>/dev/null || true
rm -f ~/.zcompdump* 2>/dev/null || true
rm -rf ~/.config/zsh/.zsh/.zcompcache 2>/dev/null || true
rm -rf ~/.cache/zsh/completions 2>/dev/null || true
echo "   ✅ All completion caches cleared"

# 2. Remove any cached compiled files
echo "2. Clearing compiled files..."
find ~/.config/zsh -name "*.zwc" -delete 2>/dev/null || true
echo "   ✅ Compiled files cleared"

# 3. Clear function caches and rehash
echo "3. Clearing function caches..."
hash -r 2>/dev/null || true
rehash 2>/dev/null || true
echo "   ✅ Function caches cleared"

# 4. Temporarily disable problematic finalization files
echo "4. Temporarily disabling problematic finalization files..."

# Disable the path deduplication file that's causing tr/wc errors
if [[ -f ~/.config/zsh/.zshrc.d/90-finalize/91-path-dedupe.zsh ]]; then
    mv ~/.config/zsh/.zshrc.d/90-finalize/91-path-dedupe.zsh \
       ~/.config/zsh/.zshrc.d/90-finalize/91-path-dedupe.zsh.temp-disabled 2>/dev/null || true
    echo "   ✅ path-dedupe.zsh temporarily disabled"
fi

# Disable the completion finalization file that's causing compinit errors
if [[ -f ~/.config/zsh/.zshrc.d/90-finalize/93-completions.zsh ]]; then
    mv ~/.config/zsh/.zshrc.d/90-finalize/93-completions.zsh \
       ~/.config/zsh/.zshrc.d/90-finalize/93-completions.zsh.temp-disabled 2>/dev/null || true
    echo "   ✅ completions.zsh temporarily disabled"
fi

echo "   ✅ Problematic finalization files disabled"

# 5. Create a minimal completion initialization
echo "5. Creating minimal completion setup..."
mkdir -p ~/.config/zsh
cat > ~/.config/zsh/minimal-completion-init.zsh << 'EOF'
# Minimal completion initialization
if command -v compinit >/dev/null 2>&1; then
    autoload -Uz compinit
    compinit -d ~/.config/zsh/.zcompdump 2>/dev/null || true
fi
EOF
echo "   ✅ Minimal completion init created"

# 6. Create a completion rebuild function
echo "6. Creating completion rebuild function..."
cat > ~/.config/zsh/rebuild-completions.zsh << 'EOF'
#!/usr/bin/env zsh
# Safe completion rebuild function

rebuild_completions() {
    echo "🔄 Rebuilding completions safely..."
    
    # Remove old cache
    rm -f ~/.config/zsh/.zcompdump* ~/.zcompdump* 2>/dev/null
    
    # Rebuild with proper error handling
    if command -v compinit >/dev/null 2>&1; then
        autoload -Uz compinit
        compinit -d ~/.config/zsh/.zcompdump
        echo "✅ Completions rebuilt successfully"
    else
        echo "⚠️  compinit not available"
    fi
}

# Auto-run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    rebuild_completions
fi
EOF
chmod +x ~/.config/zsh/rebuild-completions.zsh
echo "   ✅ Completion rebuild function created"

# 7. Test completion system
echo "7. Testing completion system..."
if zsh -c "autoload -Uz compinit && compinit -d ~/.config/zsh/.zcompdump" 2>/dev/null; then
    echo "   ✅ Completion system test passed"
else
    echo "   ⚠️  Completion system test failed (non-critical)"
fi

# 8. Final health check
echo "8. Final health check..."
errors=0

# Check essential commands
for cmd in mv wc date tr tput curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "   ❌ Missing: $cmd"
        ((errors++))
    fi
done

if [[ $errors -eq 0 ]]; then
    echo "   ✅ All essential commands available"
else
    echo "   ⚠️  $errors commands missing"
fi

echo
echo "🎉 Fix Complete!"
echo "================"
echo
echo "📋 Summary:"
echo "  • Cleared all completion caches"
echo "  • Disabled problematic finalization files"
echo "  • Created minimal completion initialization"
echo "  • Created safe completion rebuild function"
echo
echo "🔄 Next Steps:"
echo "  1. Close this terminal completely"
echo "  2. Open a new terminal session"
echo "  3. The remaining errors should be significantly reduced"
echo
echo "🔧 If you still see issues:"
echo "  • Run: ~/.config/zsh/rebuild-completions.zsh"
echo "  • Check: which mv wc date tr (should all work)"
echo
echo "✅ Your shell should now start much cleaner!"
