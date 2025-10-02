#!/opt/homebrew/bin/bash
# test-zsh-from-bash.bash - Test launching ZSH from bash

echo "=== ZSH Launch Test from Bash ==="
echo "Current shell: $0"
echo "Parent process: $$"
echo "ZDOTDIR will be: /Users/s-a-c/dotfiles/dot-config/zsh"
echo

# Test 1: Direct ZSH launch with command
echo "Test 1: Direct ZSH with immediate command"
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" timeout 10 zsh -c 'echo "ZSH COMMAND SUCCESS: $(date)"'
echo "Exit code: $?"
echo

# Test 2: Interactive ZSH launch (should show prompt)
echo "Test 2: Interactive ZSH launch (will timeout after 5 seconds)"
echo "Looking for: any signs of startup completing or hanging..."
echo "---"

ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" timeout 5 zsh -i &
ZSH_PID=$!
echo "ZSH launched with PID: $ZSH_PID"

# Monitor the process
sleep 1
if kill -0 "$ZSH_PID" 2>/dev/null; then
    echo "After 1s: ZSH process $ZSH_PID is still running"
    sleep 2
    if kill -0 "$ZSH_PID" 2>/dev/null; then
        echo "After 3s: ZSH process $ZSH_PID is still running (good sign - interactive shell started)"
        sleep 2
        if kill -0 "$ZSH_PID" 2>/dev/null; then
            echo "After 5s: ZSH process $ZSH_PID is still running - killing it"
            kill "$ZSH_PID" 2>/dev/null
        fi
    else
        echo "After 3s: ZSH process exited (early termination detected)"
    fi
else
    echo "After 1s: ZSH process exited immediately (very early termination)"
fi

wait "$ZSH_PID" 2>/dev/null
ZSH_EXIT_CODE=$?
echo "Final ZSH exit code: $ZSH_EXIT_CODE"
echo

# Test 3: ZSH with debug output
echo "Test 3: ZSH with debug output to see where it stops"
echo "---"
ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" timeout 10 bash -c '
    echo "Launching ZSH with debug output..."
    exec zsh -x -i
' 2>&1 | head -30
echo "Debug test completed"
echo

echo "=== Test Summary ==="
echo "If Test 1 succeeded but Test 2 failed, there's an interactive startup issue"
echo "If both failed, there's a fundamental ZSH config problem"
echo "If Test 3 shows where execution stops, we can pinpoint the issue"