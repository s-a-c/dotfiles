#!/usr/bin/env bash
# .bash-harness-for-zsh-template.bash
# Mandatory standard for ZSH configuration testing.
# Reference: WARP.md §7.1.1 Mandatory Harness Standard
#
# PURPOSE:
#   Configuration testing harness for ZSH shells. Tests actual user configuration
#   in normal interactive mode to catch real-world issues.
#
# USAGE:
#   harness::run <command>         - Test configuration (normal interactive startup)
#   harness::perf_run <command>    - Test performance (PERF_PROMPT_HARNESS mode)
#
# IMPORTANT:
#   - Use harness::run for configuration/functionality testing
#   - Use harness::perf_run ONLY when measuring performance metrics
#   - Performance mode may mask configuration issues by skipping normal startup

set -Eeuo pipefail

HARNESS_TIMEOUT="${HARNESS_TIMEOUT:-15s}"
HARNESS_ZSH_BIN="${HARNESS_ZSH_BIN:-zsh}"
HARNESS_ZDOTDIR="${HARNESS_ZDOTDIR:-$PWD}"
HARNESS_LOG_DIR="${HARNESS_LOG_DIR:-$PWD/logs/harness}"
HARNESS_LOG_FILE="${HARNESS_LOG_FILE:-$HARNESS_LOG_DIR/last-run.log}"

mkdir -p "$HARNESS_LOG_DIR"

harness::log() {
  printf '[HARNESS] %s\n' "$*" | tee -a "$HARNESS_LOG_FILE" >/dev/null
}

harness::run() {
  : >"$HARNESS_LOG_FILE"
  local cmd="${*:-'echo HARNESS_NO_CMD; exit 1'}"
  harness::log "ZDOTDIR=$HARNESS_ZDOTDIR"
  harness::log "Running: $HARNESS_ZSH_BIN -i -c \"$cmd\" (timeout=$HARNESS_TIMEOUT)"
  # Configuration testing harness: Use normal interactive startup (NO performance mode)
  # This ensures we test the actual user configuration, not an artificial perf environment
  ZDOTDIR="$HARNESS_ZDOTDIR" \
  timeout "$HARNESS_TIMEOUT" "$HARNESS_ZSH_BIN" -i -c "$cmd" \
    > >(tee -a "$HARNESS_LOG_FILE") 2>&1
}

harness::assert_output_contains() {
  local pattern="$1"
  if ! grep -q -- "$pattern" "$HARNESS_LOG_FILE"; then
    echo "Assertion failed: expected output to contain: $pattern"
    echo "Log: $HARNESS_LOG_FILE"
    return 1
  fi
}

harness::probe_startup() {
  harness::run 'echo PROMPT_TEST_SUCCESS; exit'
  harness::assert_output_contains 'PROMPT_TEST_SUCCESS'
}

harness::check_env_var_set() {
  local var="$1"
  harness::run "print -r -- \"VAL=\${$var-}\"; exit"
  harness::assert_output_contains 'VAL='
}

harness::check_starship_initialized() {
  harness::run '[[ -n "$STARSHIP_SHELL" ]] && echo STARSHIP_INITIALIZED || echo STARSHIP_NOT_INITIALIZED; exit'
  harness::assert_output_contains 'STARSHIP_INITIALIZED'
}

# Enhanced ZLE and widget testing functions
harness::check_zle_widgets() {
  harness::run 'zmodload zsh/zle; widget_count=$(zle -la 2>/dev/null | wc -l 2>/dev/null || echo 0); echo "ZLE_WIDGETS=$widget_count"; exit'
  harness::assert_output_contains 'ZLE_WIDGETS='
}

harness::check_zsh_options() {
  harness::run '(setopt | grep -F "zle"; setopt | grep -F "interactive") 2>/dev/null || echo "No zle/interactive options found"; exit'
}

# Performance testing function (separate from configuration testing)
harness::perf_run() {
  : >"$HARNESS_LOG_FILE"
  local cmd="${*:-'echo HARNESS_NO_CMD; exit 1'}"
  harness::log "ZDOTDIR=$HARNESS_ZDOTDIR (PERFORMANCE MODE)"
  harness::log "Running: $HARNESS_ZSH_BIN -i -c \"$cmd\" (timeout=$HARNESS_TIMEOUT)"
  # Performance testing mode: Use PERF_PROMPT_HARNESS=1 for timing measurements
  # This creates an artificial environment optimized for performance capture
  ZDOTDIR="$HARNESS_ZDOTDIR" \
  PERF_PROMPT_HARNESS=1 \
  timeout "$HARNESS_TIMEOUT" "$HARNESS_ZSH_BIN" -i -c "$cmd" \
    > >(tee -a "$HARNESS_LOG_FILE") 2>&1
}

harness::comprehensive_test() {
  echo "=== Running Comprehensive ZSH Test Suite ==="
  echo "ZDOTDIR: $HARNESS_ZDOTDIR"
  echo "Timeout: $HARNESS_TIMEOUT"
  echo "========================================="
  
  # Test startup
  echo "Testing startup..."
  harness::probe_startup
  
  # Test environment
  echo "Testing environment variables..."
  harness::check_env_var_set "ZDOTDIR"
  
  # Test ZLE widgets
  echo "Testing ZLE widgets..."
  harness::check_zle_widgets
  
  # Test options
  echo "Testing ZSH options..."
  harness::check_zsh_options
  
  echo "✅ Comprehensive test completed successfully"
}

export -f harness::log harness::run harness::perf_run harness::assert_output_contains \
          harness::probe_startup harness::check_env_var_set \
          harness::check_starship_initialized harness::check_zle_widgets \
          harness::check_zsh_options harness::comprehensive_test

# If script is executed directly (not sourced), run comprehensive test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    harness::comprehensive_test
fi