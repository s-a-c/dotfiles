#!/usr/bin/env bash
set -euo pipefail

echo "=== COMPREHENSIVE ZSH STARTUP DIAGNOSTICS ==="
echo "Testing different startup scenarios to identify parameter errors"
echo ""

# Test 1: Basic interactive shell (what our harness does)
echo "🧪 Test 1: Basic interactive with immediate exit (harness simulation)"
ZDOTDIR="$PWD" timeout 8s zsh -i -c 'echo "Basic interactive startup complete"; exit' 2>&1 | grep -E "(parameter not set|unset)" && echo "❌ Errors found in basic test" || echo "✅ No errors in basic test"
echo ""

# Test 2: Interactive shell with longer session (closer to real usage)
echo "🧪 Test 2: Interactive shell with brief delay (real session simulation)"
ZDOTDIR="$PWD" timeout 8s zsh -i -c 'sleep 0.5; echo "Extended interactive startup complete"; exit' 2>&1 | grep -E "(parameter not set|unset)" && echo "❌ Errors found in extended test" || echo "✅ No errors in extended test"
echo ""

# Test 3: Check for Warp-specific environment
echo "🧪 Test 3: Checking for Warp Terminal environment variables"
env | grep -i warp || echo "No WARP environment variables detected"
echo "TERM_PROGRAM: ${TERM_PROGRAM:-not_set}"
echo "WARP_HONOR_PS1: ${WARP_HONOR_PS1:-not_set}"
echo ""

# Test 4: Check for Emacs-related environment
echo "🧪 Test 4: Checking for Emacs-related environment variables"
echo "INSIDE_EMACS: ${INSIDE_EMACS:-not_set}"
echo "EMACS: ${EMACS:-not_set}"
echo ""

# Test 5: Interactive session with PS1 evaluation
echo "🧪 Test 5: Interactive session with prompt evaluation"
ZDOTDIR="$PWD" timeout 8s zsh -i -c 'echo "Prompt: $PS1"; exit' 2>&1 | grep -E "(parameter not set|unset)" && echo "❌ Errors found in prompt test" || echo "✅ No errors in prompt test"
echo ""

# Test 6: Check setopt status that might trigger no_unset
echo "🧪 Test 6: Checking shell options that might cause unset errors"
ZDOTDIR="$PWD" timeout 8s zsh -i -c 'setopt | grep -E "(nounset|no_unset)" || echo "no_unset not active"; exit' 2>/dev/null
echo ""

# Test 7: Check the actual files that contain these variables
echo "🧪 Test 7: Searching for problematic variable references"
echo "Looking for POWERLEVEL9K_PROMPT_ADD_NEWLINE..."
find . -name "*.zsh" -exec grep -l "POWERLEVEL9K_PROMPT_ADD_NEWLINE" {} \; 2>/dev/null || echo "Not found in .zsh files"

echo ""
echo "Looking for INSIDE_EMACS references..."
find . -name "*.zsh" -exec grep -l "INSIDE_EMACS" {} \; 2>/dev/null || echo "Not found in .zsh files"

echo ""
echo "Looking for warp_title function..."
find . -name "*.zsh" -exec grep -l "warp_title" {} \; 2>/dev/null || echo "Not found in .zsh files"

echo ""
echo "=== STARTUP DIAGNOSTICS COMPLETE ==="