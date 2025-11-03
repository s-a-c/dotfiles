#!/bin/bash

echo "=== Testing direct interactive ZSH ==="
echo "Starting ZSH in background with timeout..."

# Start ZSH in background and check if it reaches interactive state
timeout 10s bash -c '
    (echo "echo INTERACTIVE_SUCCESS" | /opt/homebrew/bin/zsh -i) 2>&1
' &

wait
echo "Test completed."