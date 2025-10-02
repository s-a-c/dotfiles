#!/bin/bash
# Baseline Test - Test minimal .zshenv to confirm it works
# Execute: bash docs/fix-zle/test-baseline.sh

echo "=== BASELINE TEST: Minimal .zshenv ==="
echo "Testing known-good minimal configuration..."
echo ""

# Switch to complete minimal configuration
echo "1. Switching to complete minimal configuration..."
ln -sf .zshenv.minimal.complete .zshenv
ln -sf .zshrc.minimal .zshrc
echo "✅ Linked .zshenv to: $(readlink .zshenv)"
echo "✅ Linked .zshrc to: $(readlink .zshrc)"
echo ""

# Test basic zsh startup
echo "2. Testing basic zsh startup..."
echo "About to start interactive zsh with complete minimal configuration"
echo "Commands to run in the zsh session:"
echo "  echo 'Minimal test - ZLE widgets available:' \$(zle -la 2>/dev/null | wc -l || echo 0)"
echo "  test_func() { echo 'test widget'; }"
echo "  zle -N test_func && echo '✅ ZLE widget creation: SUCCESS' || echo '❌ ZLE widget creation: FAILED'"
echo "  realpath \$(which grep) 2>/dev/null && echo '✅ grep command works' || echo '❌ grep command issue'"
echo "  echo 'ZDOTDIR='\$ZDOTDIR"
echo "  echo 'PWD='\$PWD"
echo "  exit"
echo ""
echo "Press Enter to start zsh session, then run the commands above..."
read -p ""

ZDOTDIR="$PWD" zsh -i

echo ""
echo "=== BASELINE TEST COMPLETE ==="
echo "Please record the results in docs/fix-zle/results/baseline-results.txt"
echo "Next: Run bash docs/fix-zle/test-full-initial.sh"
