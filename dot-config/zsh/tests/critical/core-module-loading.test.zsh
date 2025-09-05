#!/usr/bin/env zsh
# Critical test: Core module loading
# This test ensures all critical core modules load correctly

set -euo pipefail

# Setup test environment
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
TEST_DIR="$(cd "${0%/*}" && pwd)"
SOURCE_DIR="$ZDOTDIR/.zshrc.d.REDESIGN"

# Test that core modules load correctly
echo "Testing core module loading..."

# Function to test module loading
test_module_load() {
  local module_path="$1"
  local module_name="$(basename "$module_path" .zsh)"
  
  if [[ ! -f "$module_path" ]]; then
    echo "ERROR: Module file not found: $module_path"
    return 1
  fi
  
  echo "Testing module: $module_name"
  
  # Capture current variable state
  local sentinel_var="_LOADED_${module_name//-/_}"
  sentinel_var="${sentinel_var:u}"
  local original_value="${(P)sentinel_var:-unset}"
  
  # Reset the sentinel if needed
  if [[ "$original_value" != "unset" ]]; then
    unset "$sentinel_var"
  fi
  
  # Source the module
  if ! source "$module_path"; then
    echo "ERROR: Failed to source module: $module_path"
    return 1
  fi
  
  # Check sentinel is set
  if [[ -z "${(P)sentinel_var:-}" ]]; then
    echo "ERROR: Module sentinel not set after loading: $sentinel_var"
    return 1
  fi
  
  # Source again to test idempotency
  if ! source "$module_path"; then
    echo "ERROR: Failed to source module idempotently: $module_path"
    return 1
  fi
  
  echo "Module $module_name loaded successfully"
  return 0
}

# Test essential core modules
essential_modules=(
  "00-security-integrity.zsh"
  "10-core-functions.zsh"
  "20-essential-plugins.zsh"
)

fail_count=0

for module in "${essential_modules[@]}"; do
  if ! test_module_load "$SOURCE_DIR/$module"; then
    (( fail_count++ ))
  fi
done

echo "--- Core Module Load Test Summary ---"
echo "Tested: ${#essential_modules[@]} modules"
echo "Failed: $fail_count modules"

if (( fail_count > 0 )); then
  echo "CRITICAL TEST FAILED: Core module loading"
  exit 1
else
  echo "CRITICAL TEST PASSED: Core module loading"
  exit 0
fi
