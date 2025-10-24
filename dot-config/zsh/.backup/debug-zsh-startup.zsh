#!/bin/bash
# debug-zsh-startup.zsh - Test harness to debug ZSH startup issues

set -e

ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/zsh-startup.log"

echo "=== ZSH Startup Debug Test Harness ==="
echo "ZDOTDIR: $ZDOTDIR"
echo "Temp dir: $TEMP_DIR"
echo "Log file: $LOG_FILE"
echo

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Test 1: Minimal zsh with no config
echo "Test 1: Minimal zsh (no config files)"
timeout 10 zsh -c 'echo "SUCCESS: Minimal zsh works"' 2>&1 || echo "FAILED: Minimal zsh failed"
echo

# Test 2: With ZDOTDIR but skip .zshrc
echo "Test 2: With ZDOTDIR, .zshenv only"
timeout 10 env ZDOTDIR="$ZDOTDIR" zsh --no-rcs -c 'source $ZDOTDIR/.zshenv && echo "SUCCESS: .zshenv loaded"' 2>&1 | head -20 || echo "FAILED: .zshenv test failed"
echo

# Test 3: Full startup with timeout
echo "Test 3: Full startup with debug output (10s timeout)"
timeout 10 env ZDOTDIR="$ZDOTDIR" ZSH_DEBUG=1 zsh -i -c 'echo "SUCCESS: Full startup completed"' > "$LOG_FILE" 2>&1 &
PID=$!

# Monitor the process
sleep 2
if kill -0 "$PID" 2>/dev/null; then
    echo "Process still running after 2s..."
    sleep 3
    if kill -0 "$PID" 2>/dev/null; then
        echo "Process still running after 5s, killing..."
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
        echo "RESULT: Startup hung or took too long"
    else
        wait "$PID" 2>/dev/null || true
        echo "RESULT: Process completed after 2-5s"
    fi
else
    wait "$PID" 2>/dev/null || true
    echo "RESULT: Process completed quickly (under 2s)"
fi

echo
echo "=== Last 30 lines of startup log ==="
tail -30 "$LOG_FILE" 2>/dev/null || echo "No log file created"

echo
echo "=== First 30 lines of startup log ==="
head -30 "$LOG_FILE" 2>/dev/null || echo "No log file created"

echo
echo "=== Error analysis ==="
if [[ -f "$LOG_FILE" ]]; then
    echo "Log file size: $(wc -l < "$LOG_FILE") lines"
    
    # Look for common error patterns
    if grep -i "error\|failed\|cannot\|permission denied" "$LOG_FILE" >/dev/null 2>&1; then
        echo "Errors found in log:"
        grep -i "error\|failed\|cannot\|permission denied" "$LOG_FILE" | head -10
    else
        echo "No obvious errors found in log"
    fi
    
    # Look for where it might have stopped
    if grep -E "(ssh-agent|gpg|plugins)" "$LOG_FILE" | tail -5; then
        echo "Last operations before potential hang:"
        grep -E "(ssh-agent|gpg|plugins)" "$LOG_FILE" | tail -5
    fi
else
    echo "No log file was created - startup failed immediately"
fi

echo
echo "=== Test complete ==="