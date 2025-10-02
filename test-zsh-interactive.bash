#!/bin/bash

echo "=== ZSH Interactive Test Harness ==="
echo "Testing ZSH interactive startup with ZDOTDIR..."

# Set test parameters
TEST_DIR="/Users/s-a-c/dotfiles/dot-config/zsh"
TIMEOUT_SECONDS=15

echo "Test directory: $TEST_DIR"
echo "Timeout: ${TIMEOUT_SECONDS}s"
echo ""

# Change to test directory
cd "$TEST_DIR" || {
    echo "❌ FAILED: Cannot change to test directory: $TEST_DIR"
    exit 1
}

echo "Current directory: $(pwd)"
echo ""

# Run the interactive ZSH test
echo "🧪 Testing interactive ZSH with command execution..."
echo "Command: ZDOTDIR=\"$PWD\" /opt/homebrew/bin/zsh -i -c 'echo \"SUCCESS!!!\"; exit'"
echo ""

# Capture start time
start_time=$(date +%s)

# Run the test with timeout
if timeout ${TIMEOUT_SECONDS}s bash -c 'ZDOTDIR="$PWD" /opt/homebrew/bin/zsh -i -c '\''echo "SUCCESS!!!"; exit'\''' 2>&1; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo ""
    echo "✅ Test completed successfully in ${duration}s"
else
    exit_code=$?
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    echo ""
    if [ $exit_code -eq 124 ]; then
        echo "❌ TIMEOUT: ZSH did not complete within ${TIMEOUT_SECONDS}s (hung for ${duration}s)"
    else
        echo "❌ FAILED: ZSH exited with code $exit_code after ${duration}s"
    fi
    echo ""
    echo "🔍 This indicates ZSH is not properly reaching interactive mode or executing commands"
fi

echo ""
echo "=== Test Complete ==="