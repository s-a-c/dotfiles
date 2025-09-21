#!/usr/bin/env bash
set -euo pipefail

echo "=== TESTING STARSHIP ZLE FIX ==="
echo ""

# Test 1: Test the actual Starship initialization through our module
echo "🧪 Test 1: Full Starship initialization (via our module)"
result=$(ZDOTDIR="$PWD" timeout 10s zsh -i -c 'echo "STARSHIP_INIT_TEST_COMPLETE"; exit' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Module initialization has parameter errors:"
  echo "$result" | grep "parameter not set"
else
  echo "✅ Module initialization successful - no parameter errors"
fi

echo ""

# Test 2: Test manual Starship eval (should now work)  
echo "🧪 Test 2: Manual Starship eval after our fixes"
result=$(ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  # Let our modules load first (they set up widgets)
  sleep 0.1
  
  # Now try starship eval
  echo "Testing manual starship eval..."
  eval "$(starship init zsh)" 2>&1 && echo "MANUAL_EVAL_SUCCESS" || echo "MANUAL_EVAL_FAILED"
  exit
' 2>&1)

if echo "$result" | grep -q "parameter not set"; then
  echo "❌ Manual eval still has parameter errors:"
  echo "$result" | grep "parameter not set"
elif echo "$result" | grep -q "MANUAL_EVAL_SUCCESS"; then
  echo "✅ Manual eval successful - parameter errors fixed!"
else
  echo "⚠️  Manual eval result unclear"
fi

echo ""

# Test 3: Verify STARSHIP_SHELL is set correctly
echo "🧪 Test 3: Verify Starship environment is correct"
ZDOTDIR="$PWD" timeout 8s zsh -i -c '
  echo "STARSHIP_SHELL: ${STARSHIP_SHELL:-NOT_SET}"
  echo "STARSHIP_CONFIG: ${STARSHIP_CONFIG:-NOT_SET}"
  echo "STARSHIP_INITIALIZED: ${STARSHIP_INITIALIZED:-NOT_SET}"
  exit
' 2>&1 | grep "STARSHIP"

echo ""

# Test 4: Performance check - startup time shouldn't be significantly affected
echo "🧪 Test 4: Performance impact check"
echo "Measuring startup time..."

time_before=$(date +%s%N)
ZDOTDIR="$PWD" timeout 8s zsh -i -c 'exit' >/dev/null 2>&1
time_after=$(date +%s%N)
startup_time_ms=$(( (time_after - time_before) / 1000000 ))

echo "Startup time: ${startup_time_ms}ms"
if (( startup_time_ms < 5000 )); then
  echo "✅ Startup time acceptable (< 5 seconds)"
else
  echo "⚠️  Startup time high (> 5 seconds)"
fi

echo ""
echo "=== STARSHIP ZLE FIX TESTING COMPLETE ==="