#!/bin/bash
# debug-early-termination.zsh - Find where shell exits prematurely

echo "=== ZSH Early Termination Debug ==="

ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"

# Test 1: Check if .zshenv causes exit
echo "Test 1: .zshenv only"
timeout 5 env ZDOTDIR="$ZDOTDIR" zsh --no-rcs -c 'source $ZDOTDIR/.zshenv && echo "SUCCESS: .zshenv completed" && exit 0' 2>&1
echo "Exit code: $?"
echo

# Test 2: Check early .zshrc sections
echo "Test 2: .zshrc first 100 lines"
timeout 5 env ZDOTDIR="$ZDOTDIR" zsh -c 'head -100 $ZDOTDIR/.zshrc | zsh && echo "SUCCESS: First 100 lines OK"' 2>&1
echo "Exit code: $?"
echo

# Test 3: Interactive mode with exit trace
echo "Test 3: Interactive with exit trace"
cat > /tmp/test-zshrc << 'EOF'
echo "=== Starting .zshrc ==="
trap 'echo "EXIT trapped at line $LINENO"' EXIT
set -e  # Exit on any error
source /Users/s-a-c/dotfiles/dot-config/zsh/.zshrc
echo "=== .zshrc completed ==="
EOF

timeout 10 env ZDOTDIR="$ZDOTDIR" zsh -c 'source /tmp/test-zshrc' 2>&1 | head -50
echo "Exit code: $?"
echo

# Test 4: Check for specific error patterns
echo "Test 4: Looking for syntax errors"
cd "$ZDOTDIR"
zsh -n .zshenv && echo ".zshenv syntax OK" || echo ".zshenv syntax ERROR"
zsh -n .zshrc && echo ".zshrc syntax OK" || echo ".zshrc syntax ERROR"

# Check for common problematic patterns
echo
echo "Test 5: Looking for exit/return commands"
grep -n "exit\|return.*[0-9]" .zshrc | head -5
echo

echo "Test 6: Looking for set -e or errexit"
grep -n "set -e\|errexit\|set.*-.*e" .zshrc .zshenv 2>/dev/null | head -5

echo
echo "=== Debug complete ==="

# Cleanup
rm -f /tmp/test-zshrc