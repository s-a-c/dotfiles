#!/usr/bin/env zsh
# Final verification script to ensure everything is working

echo "🔍 Final verification of zsh configuration..."

# Test 1: Check if .zshenv loads without errors
echo "✓ Testing .zshenv loading..."
/opt/homebrew/bin/zsh -c 'source ~/.zshenv &&     zf::debug "✅ .zshenv loaded successfully"' || zf::debug "❌ .zshenv has errors"

# Test 2: Check if full shell starts without exiting
echo "✓ Testing full shell startup..."
/opt/homebrew/bin/zsh -i -c 'echo "✅ Interactive shell started successfully";     zf::debug "Shell PID: $$"' || zf::debug "❌ Shell startup failed"

# Test 3: Check if zgenom cache is clean
echo "✓ Checking zgenom cache state..."
if [[ -f ~/.config/zsh/.zgenom/init.zsh ]]; then
    local plugin_count=$(grep -c "zgenom load\|zgenom oh-my-zsh" ~/.config/zsh/.zgenom/init.zsh 2>/dev/null || zf::debug "0")
        zf::debug "📊 Zgenom cache exists with $plugin_count plugin entries"

    # Check for the massive duplication issue
    local duplicate_check=$(grep -c "supercrabtree/k" ~/.config/zsh/.zgenom/init.zsh 2>/dev/null || zf::debug "0")
    if [[ $duplicate_check -gt 5 ]]; then
            zf::debug "⚠️  Warning: Possible plugin duplication detected ($duplicate_check k plugin entries)"
    else
            zf::debug "✅ Plugin duplication appears resolved"
    fi
else
        zf::debug "📝 No zgenom cache found - will regenerate on next startup"
fi

# Test 4: Check if k plugin works
echo "✓ Testing k plugin functionality..."
/opt/homebrew/bin/zsh -i -c 'type k &>/dev/null &&     zf::debug "✅ k command available" || zf::debug "ℹ️  k command not yet available (will load after cache regeneration)"'

# Test 5: Verify the readlink-f fix
echo "✓ Testing readlink-f function..."
/opt/homebrew/bin/zsh -c 'source ~/.zshenv && type readlink-f &>/dev/null &&     zf::debug "✅ readlink-f function/alias available" || zf::debug "❌ readlink-f issue persists"'

echo ""
echo "🎯 Summary:"
echo "The immediate startup issues should now be resolved."
echo "If you see any ❌ errors above, we'll need to address them."
echo "Otherwise, your zsh should work normally!"
echo ""
echo "💡 To complete the setup:"
echo "1. Start a new zsh session: /opt/homebrew/bin/zsh"
echo "2. Let zgenom regenerate its cache (may take a moment on first run)"
echo "3. Test that 'k' command works for directory listings"
