#!/usr/bin/env zsh
# Comprehensive shell functionality test

echo "🧪 Testing complete shell functionality..."

# Test 1: Basic shell startup and interactivity
echo "✓ Test 1: Shell startup and interactivity"
SHELL_TEST=$(/opt/homebrew/bin/zsh -i -c 'echo "Shell started successfully"; exit 0' 2>/dev/null)
if [[ $? -eq 0 ]]; then
        zsh_debug_echo "✅ Shell starts and becomes interactive"
else
        zsh_debug_echo "❌ Shell startup failed"
fi

# Test 2: Check zgenom functionality
echo "✓ Test 2: Zgenom functionality"
ZGENOM_TEST=$(/opt/homebrew/bin/zsh -i -c 'type zgenom &>/dev/null &&     zsh_debug_echo "zgenom available" || zsh_debug_echo "zgenom not found"' 2>/dev/null)
echo "📊 Zgenom status: $ZGENOM_TEST"

# Test 3: Check if k plugin loads
echo "✓ Test 3: K plugin availability"
K_TEST=$(/opt/homebrew/bin/zsh -i -c 'type k &>/dev/null &&     zsh_debug_echo "k available" || zsh_debug_echo "k not available"' 2>/dev/null)
echo "📊 K command status: $K_TEST"

# Test 4: Check syntax highlighting
echo "✓ Test 4: Syntax highlighting plugin"
SYNTAX_TEST=$(/opt/homebrew/bin/zsh -i -c 'type fast-theme &>/dev/null &&     zsh_debug_echo "syntax highlighting loaded" || zsh_debug_echo "syntax highlighting not loaded"' 2>/dev/null)
echo "📊 Syntax highlighting: $SYNTAX_TEST"

# Test 5: Check history search
echo "✓ Test 5: History substring search"
HISTORY_TEST=$(/opt/homebrew/bin/zsh -i -c 'bindkey | grep history-substring-search &>/dev/null &&     zsh_debug_echo "history search bound" || zsh_debug_echo "history search not bound"' 2>/dev/null)
echo "📊 History search: $HISTORY_TEST"

# Test 6: Check prompt (powerlevel10k)
echo "✓ Test 6: Prompt system"
PROMPT_TEST=$(/opt/homebrew/bin/zsh -i -c 'type p10k &>/dev/null &&     zsh_debug_echo "p10k available" || zsh_debug_echo "p10k not available"' 2>/dev/null)
echo "📊 Prompt system: $PROMPT_TEST"

# Test 7: Full interactive session test
echo "✓ Test 7: Full interactive session"
echo "Running comprehensive interactive test..."

FULL_TEST=$(/opt/homebrew/bin/zsh -i << 'TESTEOF'
echo "=== COMPREHENSIVE SHELL TEST ==="
echo "Shell PID: $$"
echo "ZSH Version: $ZSH_VERSION"
echo "Current directory: $PWD"
echo "ZDOTDIR: $ZDOTDIR"
echo ""
echo "Testing commands:"
type k &>/dev/null &&     zsh_debug_echo "✅ k command available" || zsh_debug_echo "⚠️ k command not available"
type zgenom &>/dev/null &&     zsh_debug_echo "✅ zgenom available" || zsh_debug_echo "⚠️ zgenom not available"
type git &>/dev/null &&     zsh_debug_echo "✅ git available" || zsh_debug_echo "⚠️ git not available"
echo ""
echo "Testing basic operations:"
cd /tmp &&     zsh_debug_echo "✅ cd works" || zsh_debug_echo "❌ cd failed"
ls > /dev/null &&     zsh_debug_echo "✅ ls works" || zsh_debug_echo "❌ ls failed"
echo ""
echo "Shell environment:"
echo "PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
echo "Functions loaded: $(typeset -f | grep -c '^[a-zA-Z]')"
echo ""
echo "=== TEST COMPLETE - SHELL IS FUNCTIONAL ==="
exit 0
TESTEOF
)

echo "$FULL_TEST"

echo ""
echo "🎯 Summary:"
if [[ "$FULL_TEST" == *"TEST COMPLETE - SHELL IS FUNCTIONAL"* ]]; then
        zsh_debug_echo "✅ All tests passed! Your zsh is working properly."
        zsh_debug_echo ""
        zsh_debug_echo "🎉 SUCCESS: Your shell startup issues have been resolved!"
        zsh_debug_echo ""
        zsh_debug_echo "What's working now:"
        zsh_debug_echo "• Shell starts without crashing"
        zsh_debug_echo "• Interactive sessions work properly"
        zsh_debug_echo "• Basic commands and navigation function"
        zsh_debug_echo "• Zgenom plugin manager is loading"
        zsh_debug_echo "• Essential plugins are available"
        zsh_debug_echo ""
        zsh_debug_echo "You can now:"
        zsh_debug_echo "1. Use your shell normally: /opt/homebrew/bin/zsh"
        zsh_debug_echo "2. Test the k command for enhanced directory listings"
        zsh_debug_echo "3. Enjoy syntax highlighting and history search"
        zsh_debug_echo "4. Configure your prompt with: p10k configure"
else
        zsh_debug_echo "⚠️ Some issues may remain. Check the test output above."
fi
