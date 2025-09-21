#!/usr/bin/env bash
set -euo pipefail

echo "=== TESTING PARAMETER ERROR FIXES ==="
echo ""

# Test 1: Check for unset parameter errors in startup
echo "🧪 Test 1: Checking for parameter errors in basic startup"
result=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c 'echo "STARTUP_COMPLETE"; exit' 2>&1)
errors=$(echo "$result" | grep -E "(parameter not set|unset)" || true)

if [[ -n "$errors" ]]; then
  echo "❌ Parameter errors found:"
  echo "$errors"
  echo ""
else
  echo "✅ No parameter errors in basic startup"
  echo ""
fi

# Test 2: Check specific problematic variables are now defined
echo "🧪 Test 2: Verifying defensive guards are active"
ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "POWERLEVEL9K_PROMPT_ADD_NEWLINE: ${POWERLEVEL9K_PROMPT_ADD_NEWLINE:-NOT_SET}"
  echo "INSIDE_EMACS: ${INSIDE_EMACS:-NOT_SET}"
  echo "EMACS: ${EMACS:-NOT_SET}"
  typeset -f warp_title >/dev/null && echo "warp_title function: DEFINED" || echo "warp_title function: NOT_DEFINED"
  exit
' 2>&1 | tail -4

echo ""

# Test 3: Test Warp terminal environment handling
echo "🧪 Test 3: Testing Warp terminal integration"
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
  echo "✅ Running in Warp terminal - testing integration"
  result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c 'echo "WARP_TEST_COMPLETE"; exit' 2>&1)
  errors=$(echo "$result" | grep -E "(parameter not set|unset)" || true)
  
  if [[ -n "$errors" ]]; then
    echo "❌ Warp integration errors found:"
    echo "$errors"
  else
    echo "✅ No Warp integration errors"
  fi
else
  echo "ℹ️  Not running in Warp terminal, skipping Warp-specific test"
fi

echo ""

# Test 4: Test prompt evaluation without errors
echo "🧪 Test 4: Testing prompt evaluation"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c 'eval "$(starship init zsh)"; echo "PROMPT_EVAL_COMPLETE"; exit' 2>&1)
errors=$(echo "$result" | grep -E "(parameter not set|unset)" || true)

if [[ -n "$errors" ]]; then
  echo "❌ Prompt evaluation errors found:"
  echo "$errors"
else
  echo "✅ No prompt evaluation errors"
fi

echo ""
echo "=== PARAMETER ERROR TESTING COMPLETE ==="