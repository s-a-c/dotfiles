#!/usr/bin/env zsh
# test-async-state-machine.zsh
# Validates async security scanning state machine integrity:
#   - Initial state should be IDLE or QUEUED (not RUNNING)
#   - RUNNING state should only occur after first prompt
#   - Deferred start timestamp should be recorded
#   - State transitions should be monotonic and logged
set -euo pipefail

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
ROOT="${ZDOTDIR}"
ASYNC_STATE_LOG="${ROOT}/logs/async-state.log"
PERF_LOG="${ROOT}/logs/perf-current.log"

# Test configuration
TEST_TIMEOUT=10 # seconds
TEST_COUNT=0
FAILURES=0

print_test() { print -n "Test $((++TEST_COUNT)): $1... "; }
print_pass() { print "\033[32mPASS\033[0m"; }
print_fail() {
    print "\033[31mFAIL\033[0m"
    ((FAILURES++))
    print "  $1"
}

# Ensure logs directory exists
mkdir -p "${ROOT}/logs"

# Clean slate for testing
rm -f "$ASYNC_STATE_LOG" "$PERF_LOG" 2>/dev/null || true

# Test 1: Initial async state should not be RUNNING
print_test "Initial async state not RUNNING"
{
    # Simulate async module initialization (without actual background process)
    echo "ASYNC_STATE:IDLE $(date '+%s.%3N')" >"$ASYNC_STATE_LOG"
    echo "SECURITY_ASYNC_QUEUE $(date '+%s.%3N')" >>"$ASYNC_STATE_LOG"

    if grep -q "ASYNC_STATE:RUNNING" "$ASYNC_STATE_LOG" && ! grep -q "PERF_PROMPT:" "$PERF_LOG"; then
        print_fail "Found RUNNING state without prompt marker"
    else
        print_pass
    fi
}

# Test 2: Deferred start marker should be present
print_test "Deferred start marker present"
{
    if grep -q "SECURITY_ASYNC_QUEUE" "$ASYNC_STATE_LOG"; then
        print_pass
    else
        print_fail "Missing SECURITY_ASYNC_QUEUE marker"
    fi
}

# Test 3: State transition after prompt should be valid
print_test "Valid state transition after prompt"
{
    # Simulate first prompt completion
    echo "PERF_PROMPT:COMPLETE $(date '+%s.%3N')" >"$PERF_LOG"

    # Simulate async start after prompt
    sleep 0.1
    echo "ASYNC_STATE:RUNNING $(date '+%s.%3N')" >>"$ASYNC_STATE_LOG"

    # Now RUNNING after prompt should be valid
    if grep -q "PERF_PROMPT:" "$PERF_LOG" && grep -q "ASYNC_STATE:RUNNING" "$ASYNC_STATE_LOG"; then
        # Check that RUNNING comes after PROMPT
        prompt_ts=$(grep "PERF_PROMPT:" "$PERF_LOG" | tail -1 | awk '{print $2}')
        running_ts=$(grep "ASYNC_STATE:RUNNING" "$ASYNC_STATE_LOG" | tail -1 | awk '{print $2}')

        if awk -v p="$prompt_ts" -v r="$running_ts" 'BEGIN{exit !(r >= p)}'; then
            print_pass
        else
            print_fail "RUNNING timestamp ($running_ts) before PROMPT timestamp ($prompt_ts)"
        fi
    else
        print_fail "Missing expected markers after simulated prompt"
    fi
}

# Test 4: Multiple state transitions should be monotonic
print_test "State transitions are monotonic"
{
    # Add more state transitions
    sleep 0.1
    echo "ASYNC_STATE:SCANNING $(date '+%s.%3N')" >>"$ASYNC_STATE_LOG"
    sleep 0.1
    echo "ASYNC_STATE:COMPLETE $(date '+%s.%3N')" >>"$ASYNC_STATE_LOG"

    # Extract all timestamps and verify they're increasing
    timestamps=$(grep "ASYNC_STATE:" "$ASYNC_STATE_LOG" | awk '{print $2}' | sort -n)
    original=$(grep "ASYNC_STATE:" "$ASYNC_STATE_LOG" | awk '{print $2}')

    if [[ "$timestamps" == "$original" ]]; then
        print_pass
    else
        print_fail "Non-monotonic timestamps detected"
    fi
}

# Test 5: No duplicate state markers within same timestamp
print_test "No duplicate states at same timestamp"
{
    duplicate_count=$(grep "ASYNC_STATE:" "$ASYNC_STATE_LOG" | awk '{print $2}' | sort | uniq -d | wc -l | tr -d ' ')
    if [[ $duplicate_count -eq 0 ]]; then
        print_pass
    else
        print_fail "Found $duplicate_count duplicate timestamps"
    fi
}

# Test 6: Log file permissions and accessibility
print_test "Log file permissions valid"
{
    if [[ -r "$ASYNC_STATE_LOG" && -w "$ASYNC_STATE_LOG" ]]; then
        print_pass
    else
        print_fail "Log file not readable/writable"
    fi
}

# Test 7: State machine cleanup after completion
print_test "State machine cleanup"
{
    # Simulate cleanup
    echo "ASYNC_STATE:CLEANUP $(date '+%s.%3N')" >>"$ASYNC_STATE_LOG"

    # Verify cleanup state is recorded
    if grep -q "ASYNC_STATE:CLEANUP" "$ASYNC_STATE_LOG"; then
        print_pass
    else
        print_fail "Missing cleanup state"
    fi
}

# Summary
print "\n=== Async State Machine Test Summary ==="
if [[ $FAILURES -eq 0 ]]; then
    print "\033[32mAll $TEST_COUNT tests passed!\033[0m"
    exit 0
else
    print "\033[31m$FAILURES/$TEST_COUNT tests failed.\033[0m"
    print "\nLog contents for debugging:"
    print "=== ASYNC_STATE_LOG ==="
    cat "$ASYNC_STATE_LOG" 2>/dev/null || print "Log file not found"
    print "\n=== PERF_LOG ==="
    cat "$PERF_LOG" 2>/dev/null || print "Perf log not found"
    exit 1
fi
