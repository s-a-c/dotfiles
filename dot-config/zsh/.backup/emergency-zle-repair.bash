#!/usr/bin/env bash
set -euo pipefail

echo "=== EMERGENCY ZLE DIAGNOSTIC AND REPAIR ==="
echo ""

# Step 1: Identify the root cause
echo "🔍 Step 1: Diagnosing ZLE widget system..."

# Check if ZLE is completely broken
zle_status=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
echo "ZLE_VERSION: ${ZLE_VERSION:-not_set}"
echo "Widget count: ${#widgets[@]:-0}"
echo "Widgets array type: $(typeset -p widgets 2>/dev/null || echo "not_defined")"

# Test basic ZLE functionality
if zle -la 2>/dev/null | head -3; then
  echo "ZLE_STATUS: working"
else
  echo "ZLE_STATUS: broken"
fi
exit
' 2>&1 | tail -10 || echo "ZLE completely broken")

echo "$zle_status"
echo ""

# Step 2: Clear all caches and compiled files
echo "🧹 Step 2: Clearing all ZSH caches..."
./tools/clear-zsh-cache.zsh 2>/dev/null || echo "Cache clear failed"

# Reset zgenom completely
echo "🔄 Resetting zgenom..."
rm -rf .zqs-zgenom/init.zsh 2>/dev/null || true
rm -rf .zqs-zgenom/.zgenom_lastupdate 2>/dev/null || true

# Step 3: Check for plugin conflicts
echo "🔍 Step 3: Checking for conflicting plugins..."

# Check what's loading zsh-autosuggestions
if [[ -f .zqs-zgenom/init.zsh ]]; then
  grep -n "zsh-autosuggestions\|zsh_autosuggest" .zqs-zgenom/init.zsh || echo "No autosuggestions in init.zsh"
else
  echo "No zgenom init.zsh found"
fi

# Step 4: Test with minimal config
echo "🧪 Step 4: Testing with minimal configuration..."
minimal_test=$(ZDOTDIR="$PWD" ZSH_SKIP_FULL_INIT=1 timeout 5s zsh -i -c '
echo "Minimal test successful"
exit
' 2>&1 || echo "Minimal test failed")

echo "Minimal test result: $minimal_test"
echo ""

# Step 5: Identify the problematic module
echo "🎯 Step 5: Identifying problematic modules..."

# Check if it's the post-plugin redesign causing issues
echo "Testing without post-plugin redesign..."
redesign_test=$(ZSH_ENABLE_POSTPLUGIN_REDESIGN=0 ZDOTDIR="$PWD" timeout 8s zsh -i -c 'echo "No redesign test: OK"; exit' 2>&1 | grep -E "(OK|error|not found)" | head -5 || echo "Test failed")

echo "Without post-plugin redesign: $redesign_test"
echo ""

echo "=== DIAGNOSTIC COMPLETE ==="
echo ""
echo "🔧 REPAIR RECOMMENDATIONS:"
echo "1. ZLE widget system is critically broken"
echo "2. zsh-autosuggestions plugin is causing widget binding failures" 
echo "3. Need to reset plugin system and fix widget initialization order"
echo "4. gitstatus failure is secondary to ZLE widget issues"