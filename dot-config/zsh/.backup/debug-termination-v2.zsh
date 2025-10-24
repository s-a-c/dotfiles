#!/bin/bash
# debug-termination-v2.zsh - Better early termination debugging

echo "=== ZSH Early Termination Debug V2 ==="

ZDOTDIR="${HOME}/dotfiles/dot-config/zsh"

# Test 1: Run with full error tracing
echo "Test 1: Full startup with error tracing"
timeout 15 env ZDOTDIR="$ZDOTDIR" zsh -c '
set -x
set -e
trap "echo ERROR: Exit at line \$LINENO" ERR
echo "Starting ZSH with debug trace..."
source $ZDOTDIR/.zshrc
echo "SUCCESS: Full .zshrc loaded"
' 2>&1 | head -100

echo
echo "Exit code: $?"
echo

# Test 2: Interactive startup test
echo "Test 2: Interactive startup (background process)"
timeout 10 env ZDOTDIR="$ZDOTDIR" zsh -i >/dev/null 2>&1 &
PID=$!
sleep 3

if kill -0 "$PID" 2>/dev/null; then
    echo "SUCCESS: Interactive ZSH started and is running"
    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null || true
else
    echo "FAILED: Interactive ZSH exited early"
fi

echo
echo "Test 3: Step-by-step sourcing test"
cat > /tmp/step-test.zsh << 'EOF'
#!/bin/zsh
echo "Step 1: Starting .zshenv"
source /Users/s-a-c/dotfiles/dot-config/zsh/.zshenv || { echo "ERROR in .zshenv"; exit 1; }
echo "Step 2: .zshenv completed successfully"

echo "Step 3: Starting .zshrc"
source /Users/s-a-c/dotfiles/dot-config/zsh/.zshrc || { echo "ERROR in .zshrc"; exit 1; }
echo "Step 4: .zshrc completed successfully"

echo "SUCCESS: All steps completed"
EOF

timeout 15 env ZDOTDIR="$ZDOTDIR" zsh /tmp/step-test.zsh 2>&1 | tail -20
echo "Step test exit code: $?"

rm -f /tmp/step-test.zsh

echo
echo "=== Debug V2 complete ==="