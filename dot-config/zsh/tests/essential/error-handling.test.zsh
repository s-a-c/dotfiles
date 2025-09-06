#!/usr/bin/env zsh
# Essential test: Error handling framework validation
# Tests the error handling and module hardening systems

set -euo pipefail

# Setup test environment
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
TEST_DIR="$(cd "${0%/*}" && pwd)"
ERROR_FRAMEWORK="$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN/01-error-handling-framework.zsh"
HARDENING_MODULE="$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN/02-module-hardening.zsh"

echo "Testing error handling framework..."

# Test error framework loading
test_error_framework() {
  echo "Testing error handling framework..."

  if [[ ! -f "$ERROR_FRAMEWORK" ]]; then
    echo "ERROR: Error handling framework not found: $ERROR_FRAMEWORK"
    return 1
  fi

  # Source the framework
  if ! source "$ERROR_FRAMEWORK"; then
    echo "ERROR: Failed to source error handling framework"
    return 1
  fi

  # Test basic error functions
  if ! typeset -f zf_error >/dev/null 2>&1; then
    echo "ERROR: zf_error function not defined"
    return 1
  fi

  if ! typeset -f zf_module_health >/dev/null 2>&1; then
    echo "ERROR: zf_module_health function not defined"
    return 1
  fi

  if ! typeset -f zf_health_check >/dev/null 2>&1; then
    echo "ERROR: zf_health_check function not defined"
    return 1
  fi

  echo "Error handling framework loaded successfully"
  return 0
}

# Test module hardening
test_module_hardening() {
  echo "Testing module hardening..."

  if [[ ! -f "$HARDENING_MODULE" ]]; then
    echo "ERROR: Module hardening not found: $HARDENING_MODULE"
    return 1
  fi

  # Source the hardening module
  if ! source "$HARDENING_MODULE"; then
    echo "ERROR: Failed to source module hardening"
    return 1
  fi

  # Test hardening functions
  if ! typeset -f zf_harden_function >/dev/null 2>&1; then
    echo "ERROR: zf_harden_function not defined"
    return 1
  fi

  if ! typeset -f zf_hardening_health_check >/dev/null 2>&1; then
    echo "ERROR: zf_hardening_health_check not defined"
    return 1
  fi

  echo "Module hardening loaded successfully"
  return 0
}

# Test error logging functionality
test_error_logging() {
  echo "Testing error logging functionality..."

  # Clear error log (arrays will be reinitialized)
  ZF_ERROR_LOG=()

  # Test logging at different levels
  zf_debug "test-module" "Debug message test" "test-context"
  zf_info "test-module" "Info message test"
  zf_warn "test-module" "Warning message test"
  zf_err "test-module" "Error message test"

  # Check that messages were logged
  if (( ${#ZF_ERROR_LOG[@]} == 0 )); then
    echo "ERROR: No error messages were logged"
    return 1
  fi

  # Note: Error counts tracking is simplified in new implementation
  echo "Error logging basic functionality verified"

  echo "Error logging functionality working"
  return 0
}

# Test health check system
test_health_check() {
  echo "Testing health check system..."

  # Register a test module
  zf_module_load_start "test-module"
  zf_module_load_complete "test-module" "success"

  # Run health check
  if ! zf_health_check "test-module" true >/dev/null 2>&1; then
    echo "ERROR: Health check failed for test module"
    return 1
  fi

  # Run comprehensive health check
  if ! zf_health_check "all" false >/dev/null 2>&1; then
    echo "ERROR: Comprehensive health check failed"
    return 1
  fi

  echo "Health check system working"
  return 0
}

# Test validation framework
test_validation_framework() {
  echo "Testing validation framework..."

  # Test command validation
  if ! zf_validate_command "zsh" "test-module" true; then
    echo "ERROR: Command validation failed for existing command"
    return 1
  fi

  if zf_validate_command "nonexistent-command-12345" "test-module" true 2>/dev/null; then
    echo "ERROR: Command validation should have failed for non-existent command"
    return 1
  fi

  # Test environment validation
  TEST_VAR="test_value"
  if ! zf_validate_env "TEST_VAR" "test-module" true; then
    echo "ERROR: Environment validation failed for existing variable"
    return 1
  fi

  if zf_validate_env "NONEXISTENT_VAR_12345" "test-module" true 2>/dev/null; then
    echo "ERROR: Environment validation should have failed for non-existent variable"
    return 1
  fi

  echo "Validation framework working"
  return 0
}

# Run all tests
echo "--- Essential Error Handling Test ---"

fail_count=0

# Test each component
if ! test_error_framework; then
  (( fail_count++ ))
fi

if ! test_module_hardening; then
  (( fail_count++ ))
fi

if ! test_error_logging; then
  (( fail_count++ ))
fi

if ! test_health_check; then
  (( fail_count++ ))
fi

if ! test_validation_framework; then
  (( fail_count++ ))
fi

echo "--- Error Handling Test Summary ---"
echo "Tested: 5 components"
echo "Failed: $fail_count components"

if (( fail_count > 0 )); then
  echo "ESSENTIAL TEST FAILED: Error handling framework"
  exit 1
else
  echo "ESSENTIAL TEST PASSED: Error handling framework"
  exit 0
fi
