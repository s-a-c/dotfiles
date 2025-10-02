#!/opt/homebrew/bin/bash
# fix-zgenom-state.bash - Fix persistent zgenom rebuild issue

echo "=== FIXING ZGENOM STATE ==="

cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "1. Current zgenom state:"
ls -la .zqs-zgenom/init.zsh 2>/dev/null || echo "   init.zsh missing"
echo

echo "2. Forcing clean zgenom reset..."
# Remove the compiled init file to force a clean rebuild
rm -f .zqs-zgenom/init.zsh
echo "   Deleted init.zsh"

echo "3. Disabling performance monitoring that causes rebuild loops..."
# Create a temporary zshenv without the PERF variables
cat > /tmp/clean-zshenv << 'EOF'
# Temporarily disable performance monitoring for zgenom rebuild
export PERF_SEGMENT_LOG=""
export PERF_SEGMENT_TRACE=""  
export PERF_PROMPT_HARNESS=""
export PERF_CAPTURE_FAST=""
EOF

echo "4. Running ZSH with clean environment to rebuild zgenom..."
timeout 30 env ZDOTDIR="$PWD" zsh -c '
source /tmp/clean-zshenv
source .zshrc
echo "ZGENOM REBUILD COMPLETED"
' && echo "   Rebuild successful" || echo "   Rebuild timed out or failed"

rm -f /tmp/clean-zshenv

echo "5. Checking if init.zsh was created:"
if [[ -f .zqs-zgenom/init.zsh ]]; then
    echo "   ✅ init.zsh created: $(stat -f "%Sm" .zqs-zgenom/init.zsh)"
    echo "   Size: $(wc -c < .zqs-zgenom/init.zsh) bytes"
else
    echo "   ❌ init.zsh not created"
fi

echo

echo "6. Testing if rebuild loop is fixed..."
timeout 10 env ZDOTDIR="$PWD" zsh -i -c 'echo "TEST COMPLETED"' 2>&1 | grep -E "(Creating|Compiling|zgenom save)" && echo "   ❌ Still rebuilding" || echo "   ✅ No longer rebuilding"

echo
echo "=== ZGENOM FIX COMPLETE ==="
echo "If the test shows '✅ No longer rebuilding', the issue is fixed."
echo "If it still shows rebuilding, there may be a deeper zgenom configuration issue."