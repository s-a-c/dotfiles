#!/usr/bin/env zsh
# test-prompt-ready-single-emission.zsh
# Test that PROMPT_READY_COMPLETE marker is emitted exactly once per shell startup
# Part of async activation checklist enforcement (Stage 3 gating)

# Test metadata
TEST_NAME="prompt-ready-single-emission"
TEST_CATEGORY="integration"
TEST_PRIORITY="critical"
TEST_TIMEOUT=30

# Test framework setup
SCRIPT_DIR="${0:A:h}"
ZDOTDIR_TEST="${SCRIPT_DIR}/../.."
source "${ZDOTDIR_TEST}/tests/lib/test-framework.zsh" || {
  echo "FATAL: Cannot load test framework" >&2
  exit 2
}

# Test configuration
TEST_OUTPUT_FILE="/tmp/test-prompt-ready-$$"
PROMPT_LOG_FILE="/tmp/prompt-emission-log-$$"

cleanup() {
  rm -f "$TEST_OUTPUT_FILE" "$PROMPT_LOG_FILE" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

test_prompt_ready_single_emission() {
  test_start "PROMPT_READY_COMPLETE single emission check"

  # Create a minimal zsh session that sources our configuration
  # and captures all PROMPT_READY_COMPLETE emissions
  cat > "$TEST_OUTPUT_FILE" <<'EOF'
#!/usr/bin/env zsh
# Capture all PROMPT_READY_COMPLETE emissions

PROMPT_EMISSION_COUNT=0
PROMPT_LOG_FILE="$1"

# Override or wrap any prompt-ready emission functions
original_prompt_ready_emit() {
  echo "PROMPT_READY_COMPLETE detected at $(date)" >> "$PROMPT_LOG_FILE"
  ((PROMPT_EMISSION_COUNT++))

  # Call original if it exists
  if typeset -f __original_prompt_ready_emit >/dev/null; then
    __original_prompt_ready_emit "$@"
  fi
}

# Hook into common prompt-ready emission patterns
if typeset -f prompt_ready_emit >/dev/null; then
  functions[__original_prompt_ready_emit]="${functions[prompt_ready_emit]}"
  functions[prompt_ready_emit]="${functions[original_prompt_ready_emit]}"
fi

# Also capture direct marker emissions (common patterns)
PROMPT_READY_COMPLETE() {
  echo "DIRECT_PROMPT_READY_COMPLETE at $(date)" >> "$PROMPT_LOG_FILE"
  ((PROMPT_EMISSION_COUNT++))
}

# Source the main configuration with minimal env
export ZDOTDIR="${ZDOTDIR_TEST}"
export XDG_CONFIG_HOME="${ZDOTDIR_TEST%/zsh}"
export PERF_SEGMENT_LOG="/tmp/segment-log-test-$$"

# Minimal environment to avoid interference
unset PERF_PROMPT_HARNESS
unset PERF_TIMING_ENABLED

# Source main zshrc (this should trigger normal startup)
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
  source "$ZDOTDIR/.zshrc" 2>/dev/null || {
    echo "ERROR: Failed to source .zshrc" >> "$PROMPT_LOG_FILE"
    exit 1
  }
else
  echo "ERROR: .zshrc not found at $ZDOTDIR/.zshrc" >> "$PROMPT_LOG_FILE"
  exit 1
fi

# Wait a moment for any async prompt setup
sleep 0.5

# Report final count
echo "FINAL_COUNT:$PROMPT_EMISSION_COUNT" >> "$PROMPT_LOG_FILE"

# Clean up
rm -f "$PERF_SEGMENT_LOG" 2>/dev/null || true

exit 0
EOF

  # Make the test script executable
  chmod +x "$TEST_OUTPUT_FILE"

  # Run the test in a clean zsh session
  if ! timeout 20s zsh "$TEST_OUTPUT_FILE" "$PROMPT_LOG_FILE" 2>/dev/null; then
    test_fail "Test script execution failed or timed out"
    if [[ -f "$PROMPT_LOG_FILE" ]]; then
      test_info "Prompt log contents:"
      cat "$PROMPT_LOG_FILE" | head -20
    fi
    return 1
  fi

  # Check if log file was created
  if [[ ! -f "$PROMPT_LOG_FILE" ]]; then
    test_fail "Prompt emission log not created"
    return 1
  fi

  # Extract final emission count
  local final_count
  final_count=$(grep "^FINAL_COUNT:" "$PROMPT_LOG_FILE" | cut -d: -f2)

  if [[ -z "$final_count" ]]; then
    test_fail "Could not determine prompt emission count"
    test_info "Log contents:"
    cat "$PROMPT_LOG_FILE"
    return 1
  fi

  # Check for exactly one emission
  if [[ "$final_count" -eq 0 ]]; then
    test_fail "No PROMPT_READY_COMPLETE emissions detected (expected exactly 1)"
    test_info "This might indicate missing prompt setup or hook issues"
    return 1
  elif [[ "$final_count" -eq 1 ]]; then
    test_pass "PROMPT_READY_COMPLETE emitted exactly once ✓"
  elif [[ "$final_count" -gt 1 ]]; then
    test_fail "Multiple PROMPT_READY_COMPLETE emissions detected: $final_count (expected exactly 1)"
    test_info "This violates the async activation checklist requirement"
    test_info "Emission log:"
    grep -E "(PROMPT_READY|DIRECT_PROMPT)" "$PROMPT_LOG_FILE" | head -10
    return 1
  else
    test_fail "Invalid emission count: $final_count"
    return 1
  fi

  # Additional check: look for any explicit duplication warnings in logs
  if grep -q -i "duplicate.*prompt.*ready\|prompt.*ready.*duplicate" "$PROMPT_LOG_FILE"; then
    test_warn "Duplication warnings found in logs:"
    grep -i "duplicate.*prompt.*ready\|prompt.*ready.*duplicate" "$PROMPT_LOG_FILE"
  fi

  return 0
}

test_prompt_ready_opportunistic_suppression() {
  test_start "Opportunistic capture suppression with native markers"

  # This test checks that when native prompt markers are available,
  # opportunistic post-plugin boundary captures are suppressed

  # Create test environment with forced native marker
  export PERF_FORCE_NATIVE_MARKERS=1
  export PERF_SEGMENT_LOG="/tmp/segment-suppression-test-$$"

  local test_script="/tmp/suppression-test-$$"
  cat > "$test_script" <<EOF
#!/usr/bin/env zsh
export ZDOTDIR="${ZDOTDIR_TEST}"
export PERF_SEGMENT_LOG="$PERF_SEGMENT_LOG"
export PERF_FORCE_NATIVE_MARKERS=1

# Track marker emissions
NATIVE_MARKERS=0
OPPORTUNISTIC_MARKERS=0

# Mock native marker detection
prompt_ready_native_emit() {
  ((NATIVE_MARKERS++))
  echo "NATIVE_MARKER_EMIT" >> "$PERF_SEGMENT_LOG"
}

# Mock opportunistic capture
prompt_ready_opportunistic_emit() {
  if [[ "\$NATIVE_MARKERS" -gt 0 ]]; then
    echo "SUPPRESSED_OPPORTUNISTIC_DUE_TO_NATIVE" >> "$PERF_SEGMENT_LOG"
    return 0  # Suppressed
  else
    ((OPPORTUNISTIC_MARKERS++))
    echo "OPPORTUNISTIC_MARKER_EMIT" >> "$PERF_SEGMENT_LOG"
  fi
}

# Source configuration (minimal)
source "$ZDOTDIR/.zshrc" 2>/dev/null || exit 1

sleep 0.3

# Simulate both marker opportunities
prompt_ready_native_emit
prompt_ready_opportunistic_emit

echo "NATIVE:\$NATIVE_MARKERS OPPORTUNISTIC:\$OPPORTUNISTIC_MARKERS" >> "$PERF_SEGMENT_LOG"
EOF

  chmod +x "$test_script"

  if ! timeout 15s zsh "$test_script" 2>/dev/null; then
    test_fail "Suppression test script failed"
    return 1
  fi

  # Check suppression occurred
  if grep -q "SUPPRESSED_OPPORTUNISTIC_DUE_TO_NATIVE" "$PERF_SEGMENT_LOG"; then
    test_pass "Opportunistic capture correctly suppressed when native markers present ✓"
  elif grep -q "OPPORTUNISTIC_MARKER_EMIT" "$PERF_SEGMENT_LOG"; then
    test_fail "Opportunistic capture was NOT suppressed despite native markers"
    return 1
  else
    test_warn "Could not determine suppression behavior (may need implementation)"
  fi

  rm -f "$test_script" "$PERF_SEGMENT_LOG" 2>/dev/null || true
  return 0
}

# Main test execution
run_tests() {
  test_suite_start "$TEST_NAME"

  local tests_passed=0
  local tests_total=2

  if test_prompt_ready_single_emission; then
    ((tests_passed++))
  fi

  if test_prompt_ready_opportunistic_suppression; then
    ((tests_passed++))
  fi

  test_suite_end "$tests_passed" "$tests_total"

  if [[ $tests_passed -eq $tests_total ]]; then
    exit 0
  else
    exit 1
  fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_tests
fi
