#!/bin/bash
# Test script to verify ZSH interactive startup

echo "=== Testing ZSH Interactive Startup ==="

# Test 1: Basic interactive with explicit message
echo "Test 1: Basic interactive test"
if timeout 15s /opt/homebrew/bin/zsh -i -c 'echo "INTERACTIVE_SUCCESS"; sleep 1; exit 0' 2>&1 | grep -q "INTERACTIVE_SUCCESS"; then
    echo "  ✅ Interactive ZSH reaches prompt successfully"
else
    echo "  ❌ Interactive ZSH failed to reach prompt or timed out"
fi

# Test 2: Check if ZSH hangs
echo "Test 2: Hang detection test"
if timeout 5s /opt/homebrew/bin/zsh -i -c 'exit 0' >/dev/null 2>&1; then
    echo "  ✅ ZSH exits cleanly without hanging"
else
    echo "  ❌ ZSH appears to hang or timeout"
fi

# Test 3: Check zgenom status
echo "Test 3: Zgenom functionality"
if timeout 10s /opt/homebrew/bin/zsh -i -c 'command -v zgenom >/dev/null && echo "ZGENOM_OK"' 2>&1 | grep -q "ZGENOM_OK"; then
    echo "  ✅ Zgenom is accessible in interactive shell"
else
    echo "  ⚠️  Zgenom not accessible or timeout"
fi

echo "=== Test Complete ==="