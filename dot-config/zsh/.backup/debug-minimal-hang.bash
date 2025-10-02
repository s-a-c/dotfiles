#!/usr/bin/env bash
# Minimal test to isolate what's causing the shell hang

set -euo pipefail

echo "=== Debugging Shell Hang ==="

# Test 1: Try shell without any plugins
echo "🔍 Test 1: Shell with minimal .zshenv only..."
test_minimal() {
    timeout 10s bash -c '
        export ZDOTDIR="'"$PWD"'"
        # Start zsh with minimal initialization
        echo "Starting minimal zsh test..."
        zsh -c "echo \"Minimal shell works\"; exit"
    ' 2>&1
}

if test_minimal | grep -q "Minimal shell works"; then
    echo "✅ Minimal shell startup works"
else
    echo "❌ Even minimal shell hangs - issue in .zshenv"
    exit 1
fi

# Test 2: Test with just .zshrc (no plugins)
echo
echo "🔍 Test 2: Shell with .zshrc but skip plugin loading..."
test_no_plugins() {
    timeout 15s bash -c '
        export ZDOTDIR="'"$PWD"'"
        export PERF_CAPTURE_FAST=1  # Skip plugin loading
        echo "Starting zsh with no plugins..."
        zsh -i -c "echo \"No-plugin shell works\"; exit"
    ' 2>&1
}

if test_no_plugins | grep -q "No-plugin shell works"; then
    echo "✅ Shell without plugins works"
else
    echo "❌ Shell hangs even without plugins"
    echo "Issue is likely in pre-plugin or post-plugin modules"
fi

# Test 3: Check if it's a specific module causing hang
echo
echo "🔍 Test 3: Checking pre-plugin modules for hang..."

# Test pre-plugin modules individually
for module in .zshrc.pre-plugins.d.REDESIGN/*.zsh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module")
        echo "Testing module: $module_name"
        
        test_output=$(timeout 5s bash -c '
            export ZDOTDIR="'"$PWD"'"
            zsh -c "source '"$module"'; echo MODULE_TEST_OK; exit"
        ' 2>&1 || echo "TIMEOUT_OR_ERROR")
        
        if echo "$test_output" | grep -q "MODULE_TEST_OK"; then
            echo "  ✅ $module_name loads successfully"
        else
            echo "  ❌ $module_name causes issues:"
            echo "$test_output" | head -3
        fi
    fi
done

echo
echo "=== Summary ==="
echo "This test helps identify which component is causing the hang."
echo "If even minimal shell fails, issue is in .zshenv"
echo "If no-plugin shell fails, issue is in pre/post-plugin modules"
echo "If specific modules fail, those are the culprits"