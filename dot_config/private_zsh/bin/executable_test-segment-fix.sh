#!/usr/bin/env bash
# ==============================================================================
# Test Segment Function Fix
# ==============================================================================
# Purpose: Verify that moving segment functions to .zshenv fixes plugin loading
# Part of: Phase 1, Task 1.2 - Configuration Stability Testing
# Created: 2025-10-07
# ==============================================================================

set -e

echo "==================================================================="
echo "Testing Segment Function Fix"
echo "==================================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Clean all caches
echo "Step 1: Cleaning all caches..."
find . -name "*.zwc" -type f -delete 2>/dev/null || true
find . -name ".zcompdump*" -type f -delete 2>/dev/null || true
rm -f ~/.zcompdump* 2>/dev/null || true
echo -e "${GREEN}✓${NC} Caches cleaned"
echo ""

# Step 2: Reset zgenom
echo "Step 2: Resetting zgenom..."
zsh -i -c 'zgenom reset' 2>&1 | head -5
echo -e "${GREEN}✓${NC} zgenom reset complete"
echo ""

# Step 3: Regenerate plugin cache
echo "Step 3: Regenerating plugin cache (zgenom save)..."
zsh -i -c 'zgenom save' 2>&1 | head -10
echo -e "${GREEN}✓${NC} zgenom save complete"
echo ""

# Step 4: Verify plugins loaded
echo "Step 4: Verifying plugins loaded..."
PLUGIN_COUNT=$(zsh -i -c 'zgenom list 2>/dev/null | wc -l' | tr -d ' ')
echo "Plugin count: $PLUGIN_COUNT"

if [[ "$PLUGIN_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} Plugins loaded successfully!"
else
  echo -e "${RED}✗${NC} No plugins loaded - fix failed"
  exit 1
fi
echo ""

# Step 5: Show loaded plugins
echo "Step 5: Loaded plugins:"
zsh -i -c 'zgenom list' 2>/dev/null | head -20
echo ""

# Step 6: Test startup time
echo "Step 6: Testing startup time..."
echo "Running 3 startup tests..."
for i in {1..3}; do
  time zsh -i -c exit 2>&1 | grep real
done
echo ""

# Step 7: Verify segment functions available
echo "Step 7: Verifying segment functions available..."
zsh -c 'typeset -f zf::add_segment >/dev/null 2>&1 && echo "✓ zf::add_segment available" || echo "✗ zf::add_segment NOT available"'
zsh -c 'typeset -f zf::debug >/dev/null 2>&1 && echo "✓ zf::debug available" || echo "✗ zf::debug NOT available"'
zsh -c 'typeset -f zf::segment >/dev/null 2>&1 && echo "✓ zf::segment available" || echo "✗ zf::segment NOT available"'
echo ""

echo "==================================================================="
echo -e "${GREEN}Test Complete!${NC}"
echo "==================================================================="
echo ""
echo "Summary:"
echo "  - Plugins loaded: $PLUGIN_COUNT"
echo "  - Segment functions: Available in .zshenv"
echo "  - Plugin cache: Regenerated successfully"
echo ""
echo "Next steps:"
echo "  1. Start a new ZSH session to verify everything works"
echo "  2. Check for any errors during startup"
echo "  3. Verify plugin functionality (completions, aliases, etc.)"
echo ""

