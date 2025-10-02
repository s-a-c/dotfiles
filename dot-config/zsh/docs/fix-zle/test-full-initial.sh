#!/bin/bash
# Full Initial Test - Test complete .zshenv.full.bisect
# Execute: bash docs/fix-zle/test-full-initial.sh

echo "=== FULL INITIAL TEST: Complete .zshenv ==="
echo "Testing full .zshenv.full.bisect to see if it hangs/fails..."
echo ""

# Switch to full .zshenv
echo "1. Switching to full .zshenv.bisect..."
ln -sf .zshenv.full.bisect .zshenv
echo "✅ Linked to full version: $(readlink .zshenv)"
echo ""

# Test full zsh startup
echo "2. Testing full zsh startup..."
echo "⚠️  WARNING: This may hang! Be ready to Ctrl+C if it doesn't respond within 10 seconds"
echo ""
echo "About to start interactive zsh with FULL .zshenv"
echo "Commands to run in the zsh session (if it starts):"
echo "  echo 'Full test - ZLE widgets available:' \$(zle -la 2>/dev/null | wc -l || echo 0)"
echo "  test_func() { echo 'test widget full'; }"
echo "  zle -N test_func && echo '✅ ZLE widget creation: SUCCESS' || echo '❌ ZLE widget creation: FAILED'"
echo "  realpath \$(which grep) 2>/dev/null && echo '✅ grep command works' || echo '❌ grep command issue'"
echo "  echo 'ZDOTDIR='\$ZDOTDIR"
echo "  echo 'Full .zshenv test completed successfully'"
echo "  exit"
echo ""
echo "If it hangs, press Ctrl+C and record 'HANGS' as the result"
echo "Press Enter to start zsh session..."
read -p ""

# Use timeout to prevent indefinite hangs
timeout 15s bash -c 'ZDOTDIR="$PWD" zsh -i' || echo "❌ TIMEOUT: zsh session timed out after 15 seconds"

echo ""
echo "=== FULL INITIAL TEST COMPLETE ==="
echo "Please record the results in docs/fix-zle/results/full-initial-results.txt"
echo "Results should be one of:"
echo "  - SUCCESS: Started normally, ZLE worked"
echo "  - HANGS: Never got to prompt (timed out)"
echo "  - ERROR: Started but with errors"
echo "  - ZLE_BROKEN: Started but ZLE widget creation failed"
echo ""
echo "Next: If it HANGS or has ZLE issues, run bash docs/fix-zle/test-bisect-point-1.sh"
echo "      If it works perfectly, the issue may be elsewhere"
