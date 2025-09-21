#!/usr/bin/env bash
set -euo pipefail

echo "=== STARSHIP ZLE INITIALIZATION ANALYSIS ==="
echo ""

# Test 1: Check what starship init zsh generates
echo "🧪 Test 1: Analyzing starship init zsh output"
starship_init=$(starship init zsh 2>/dev/null)
echo "Starship init script length: ${#starship_init} characters"
echo ""
echo "Looking for ZLE widget references:"
echo "$starship_init" | grep -n "widgets\[" || echo "No direct widgets[] references found"
echo ""
echo "Looking for ZLE-related function calls:"
echo "$starship_init" | grep -nE "(zle |add-zsh-hook|autoload)" || echo "No ZLE function calls found"
echo ""

# Test 2: Check ZLE state during different initialization phases
echo "🧪 Test 2: Testing ZLE state during initialization"
ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "=== ZLE State Check ==="
  echo "ZLE_VERSION: ${ZLE_VERSION:-not_set}"
  echo "Interactive: $([[ -o interactive ]] && echo yes || echo no)"
  echo "Widgets array exists: $([[ -n "${widgets:-}" ]] && echo yes || echo no)"
  if [[ -n "${widgets:-}" ]]; then
    echo "Widgets count: ${#widgets[@]}"
    echo "Sample widgets: ${(k)widgets[1,5]}"
  fi
  exit
' 2>&1

echo ""

# Test 3: Test starship init at different points
echo "🧪 Test 3: Testing starship init timing"
echo "Before ZLE ready:"
ZDOTDIR="$PWD" timeout 5s zsh -c '
  echo "Non-interactive shell test"
  starship_code=$(starship init zsh 2>/dev/null)
  echo "Starship init successful in non-interactive: $([[ $? -eq 0 ]] && echo yes || echo no)"
  exit
' 2>&1

echo ""
echo "In interactive shell (potential error):"
ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "Interactive shell starship test"
  starship_code=$(starship init zsh 2>&1)
  if echo "$starship_code" | grep -q "parameter not set"; then
    echo "❌ Starship init has parameter errors"
    echo "$starship_code" | grep "parameter not set"
  else
    echo "✅ Starship init successful in interactive shell"
  fi
  exit
' 2>&1

echo ""

# Test 4: Check the exact line causing the error
echo "🧪 Test 4: Finding the problematic line"
echo "Extracting line 67 from starship init:"
starship_line_67=$(starship init zsh 2>/dev/null | sed -n '67p' || echo "Line 67 not found")
echo "Line 67: $starship_line_67"

echo ""
echo "=== STARSHIP ZLE ANALYSIS COMPLETE ==="