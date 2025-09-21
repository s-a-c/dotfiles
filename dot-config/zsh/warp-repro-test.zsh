#!/bin/bash
# warp-repro-test.zsh - Minimal reproduction of Warp startup issue

echo "=== Warp Issue Reproduction Test ==="

# Test if we can simulate Warp's initialization process
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh"
export ZDOTDIR

# Simulate Warp's environment variables
export TERM_PROGRAM="WarpTerminal"
export WARP_SESSION_ID="test_session_12345"

echo "Environment setup:"
echo "  ZDOTDIR: $ZDOTDIR"
echo "  TERM_PROGRAM: $TERM_PROGRAM"
echo "  WARP_SESSION_ID: $WARP_SESSION_ID"
echo

# Test 1: Full startup with Warp environment
echo "Test 1: Full ZSH startup with Warp environment simulation"
echo "Command: ZDOTDIR=\"$ZDOTDIR\" TERM_PROGRAM=\"WarpTerminal\" zsh -i -c 'echo SUCCESS && PS1=\"test> \" exec zsh'"

timeout 15 env \
    ZDOTDIR="$ZDOTDIR" \
    TERM_PROGRAM="WarpTerminal" \
    WARP_SESSION_ID="test_session_12345" \
    zsh -i -c 'echo "===ZSH STARTED===" && echo "Current shell: $0" && echo "SUCCESS: ZSH fully loaded" && exit 0' 2>&1 | head -50

echo
echo "=== Test completed ==="

# Test 2: Check if there are any errors in normal interactive mode
echo "Test 2: Interactive mode test (should hang if working, will timeout)"
timeout 5 env \
    ZDOTDIR="$ZDOTDIR" \
    zsh -i &
PID=$!
sleep 2
if kill -0 "$PID" 2>/dev/null; then
    echo "SUCCESS: ZSH started interactive mode and is running"
    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null || true
else
    echo "FAILED: ZSH interactive mode exited prematurely"
fi

echo
echo "=== All tests completed ==="