#!/usr/bin/env bash
set -euo pipefail

echo "=== TESTING STARSHIP: EVAL VS SOURCE ==="
echo ""

# Test 1: Current approach with eval (should show the error)
echo "🧪 Test 1: Current eval approach"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "Testing eval approach..."
  starship_code=$(starship init zsh 2>/dev/null)
  if eval "$starship_code" 2>&1; then
    echo "✅ Eval approach successful"
  else
    echo "❌ Eval approach failed"
  fi
  exit
' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Eval approach has parameter errors:"
  echo "$result" | grep "parameter not set"
else
  echo "✅ Eval approach successful"
fi

echo ""

# Test 2: Source approach with temporary file
echo "🧪 Test 2: Source approach with temp file"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "Testing source approach..."
  starship_code=$(starship init zsh 2>/dev/null)
  temp_file=$(mktemp /tmp/starship_init.XXXXXX)
  echo "$starship_code" > "$temp_file"
  
  if source "$temp_file" 2>&1; then
    echo "✅ Source approach successful"
    rm -f "$temp_file"
  else
    echo "❌ Source approach failed"
    rm -f "$temp_file"
  fi
  exit
' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Source approach has parameter errors:"
  echo "$result" | grep "parameter not set"
else
  echo "✅ Source approach successful"
fi

echo ""

# Test 3: Deferred eval approach (after a brief delay)
echo "🧪 Test 3: Deferred eval approach"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "Testing deferred eval approach..."
  starship_code=$(starship init zsh 2>/dev/null)
  
  # Brief delay to let ZLE fully initialize
  sleep 0.1
  
  if eval "$starship_code" 2>&1; then
    echo "✅ Deferred eval approach successful"
  else
    echo "❌ Deferred eval approach failed"
  fi
  exit
' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Deferred eval has parameter errors:"
  echo "$result" | grep "parameter not set"
else
  echo "✅ Deferred eval approach successful"
fi

echo ""

# Test 4: Check what happens if we pre-populate the widgets array properly
echo "🧪 Test 4: Pre-populated widgets array approach"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "Testing pre-populated widgets approach..."
  
  # Force ZLE to be available
  autoload -Uz zle 2>/dev/null || true
  
  # Ensure widgets array exists with proper structure
  typeset -gA widgets 2>/dev/null || true
  widgets[zle-keymap-select]="" 2>/dev/null || true
  
  starship_code=$(starship init zsh 2>/dev/null)
  if eval "$starship_code" 2>&1; then
    echo "✅ Pre-populated widgets approach successful"
  else
    echo "❌ Pre-populated widgets approach failed"  
  fi
  exit
' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Pre-populated widgets has parameter errors:"
  echo "$result" | grep "parameter not set"
else
  echo "✅ Pre-populated widgets approach successful"
fi

echo ""
echo "=== COMPARISON COMPLETE ==="