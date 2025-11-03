#!/usr/bin/env zsh
# ==============================================================================
# test-core-function-count-refactored.zsh
#
# TEST_MODE: zsh-f-compatible
# DEPENDENCIES: self-contained (sources only what it tests)
#
# Purpose:
#   Tests the core function count in a completely isolated environment.
#   This refactored version works with `zsh -f` (no startup files).
#
# Usage:
#   zsh -f test-core-function-count-refactored.zsh
#   ZDOTDIR=/path/to/config zsh -f test-core-function-count-refactored.zsh
#
# Validation:
#   FC1: Module present (else SKIP)
#   FC2: Module sources successfully
#   FC3: Function count meets minimum threshold
#   FC4: (Optional) Golden count comparison if provided
#   FC5: Function fingerprint for change detection
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Test Environment Setup (Self-Contained)
# ------------------------------------------------------------------------------

# Determine paths without relying on environment
TEST_NAME="$(basename "$0" .zsh)"
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

# Navigate up from tests/unit/core to find repo root
REPO_ROOT="$(cd "$TEST_DIR/../../.." && pwd)"

# Allow ZDOTDIR override, but default to repo root
ZDOTDIR="${ZDOTDIR:-$REPO_ROOT}"

# Set minimal PATH for required commands (grep, sed, etc.)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"

# Test configuration
CORE_FN_MIN_EXPECT="${CORE_FN_MIN_EXPECT:-5}"
CORE_FN_GOLDEN_COUNT="${CORE_FN_GOLDEN_COUNT:-}"
CORE_FN_ALLOW_GROWTH="${CORE_FN_ALLOW_GROWTH:-0}"
DEBUG="${DEBUG:-0}"

# ------------------------------------------------------------------------------
# Test Utilities (No External Dependencies)
# ------------------------------------------------------------------------------

# Simple debug function
debug_echo() {
    [[ "$DEBUG" == "1" ]] && echo "[DEBUG] $*" >&2
}

# Test result tracking
PASS_LIST=()
FAIL_LIST=()

pass() {
    local test_name="$1"
    local details="${2:-}"
    PASS_LIST+=("$test_name")
    echo "PASS: $test_name${details:+ $details}"
}

fail() {
    local test_name="$1"
    local details="${2:-}"
    FAIL_LIST+=("$test_name")
    echo "FAIL: $test_name${details:+ $details}"
}

# ------------------------------------------------------------------------------
# Module Discovery
# ------------------------------------------------------------------------------

debug_echo "TEST_DIR: $TEST_DIR"
debug_echo "REPO_ROOT: $REPO_ROOT"
debug_echo "ZDOTDIR: $ZDOTDIR"

# Look for the core functions module in multiple possible locations
POSSIBLE_PATHS=(
    "$ZDOTDIR/.zshrc.d.REDESIGN/10-core-functions.zsh"
    "$ZDOTDIR/modules/10-core-functions.zsh"
    "$ZDOTDIR/lib/core-functions.zsh"
)

MODULE_FILE=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        MODULE_FILE="$path"
        debug_echo "Found module at: $MODULE_FILE"
        break
    fi
done

# ------------------------------------------------------------------------------
# Test FC1: Module Present
# ------------------------------------------------------------------------------

if [[ -z "$MODULE_FILE" ]]; then
    echo "SKIP: Core functions module not found in any expected location"
    echo "Searched paths:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  - $path"
    done
    exit 0
fi

pass "FC1 module-present" "($MODULE_FILE)"

# ------------------------------------------------------------------------------
# Test FC2: Module Sources Successfully
# ------------------------------------------------------------------------------

# Create isolated environment for sourcing
(
    # Source in subshell to avoid pollution
    set +e  # Don't exit on source failure
    source "$MODULE_FILE" 2>/dev/null
    exit $?
) && source_result=0 || source_result=$?

if [[ $source_result -eq 0 ]]; then
    pass "FC2 module-sourced"
    # Now source for real to test functions
    source "$MODULE_FILE"
else
    fail "FC2 module-sourced" "(exit code: $source_result)"
    echo "TEST RESULT: FAIL"
    exit 1
fi

# ------------------------------------------------------------------------------
# Test FC3: Function Count Meets Minimum
# ------------------------------------------------------------------------------

# Count functions with zf:: prefix (or other expected patterns)
function_count=0
function_names=()

# Get all function names
# Use built-in zsh functionality to avoid external dependencies
for func in ${(ok)functions}; do
    # Check if it matches expected patterns
    if [[ "$func" == zf::* ]] || [[ "$func" == zsh_* ]] || [[ "$func" == safe_* ]]; then
        ((function_count++))
        function_names+=("$func")
        debug_echo "Found function: $func"
    fi
done

debug_echo "Total function count: $function_count"
debug_echo "Minimum expected: $CORE_FN_MIN_EXPECT"

if [[ $function_count -ge $CORE_FN_MIN_EXPECT ]]; then
    pass "FC3 meets-minimum" "count=$function_count min=$CORE_FN_MIN_EXPECT"
else
    fail "FC3 below-minimum" "count=$function_count min=$CORE_FN_MIN_EXPECT"
fi

# ------------------------------------------------------------------------------
# Test FC4: Golden Count Comparison (Optional)
# ------------------------------------------------------------------------------

if [[ -n "$CORE_FN_GOLDEN_COUNT" ]]; then
    if [[ $function_count -eq $CORE_FN_GOLDEN_COUNT ]]; then
        pass "FC4 golden-match" "count=$function_count golden=$CORE_FN_GOLDEN_COUNT"
    elif [[ $function_count -gt $CORE_FN_GOLDEN_COUNT ]]; then
        if [[ "$CORE_FN_ALLOW_GROWTH" == "1" ]]; then
            pass "FC4 golden-growth" "count=$function_count golden=$CORE_FN_GOLDEN_COUNT (growth allowed)"
        else
            fail "FC4 unexpected-growth" "count=$function_count golden=$CORE_FN_GOLDEN_COUNT"
        fi
    else
        fail "FC4 regression" "count=$function_count golden=$CORE_FN_GOLDEN_COUNT"
    fi
else
    pass "FC4 golden-unset" "(skipped)"
fi

# ------------------------------------------------------------------------------
# Test FC5: Function Fingerprint
# ------------------------------------------------------------------------------

# Create a fingerprint of function names for change detection
if [[ ${#function_names[@]} -gt 0 ]]; then
    # Sort and create a simple hash without external commands
    # Use zsh's built-in string manipulation
    sorted_names=(${(o)function_names[@]})  # o flag sorts the array
    fingerprint="${(j:_:)sorted_names}"      # Join with underscore
    # Create a simple checksum using zsh internals
    fingerprint="${#fingerprint}_${#sorted_names}_${sorted_names[1]}_${sorted_names[-1]}"
    pass "FC5 fingerprint=$fingerprint"
else
    fail "FC5 no-functions-to-fingerprint"
fi

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

echo ""
echo "SUMMARY: passes=${#PASS_LIST[@]} fails=${#FAIL_LIST[@]} count=$function_count min=$CORE_FN_MIN_EXPECT golden=${CORE_FN_GOLDEN_COUNT:-<unset>} growth_allowed=$CORE_FN_ALLOW_GROWTH"

if [[ ${#FAIL_LIST[@]} -eq 0 ]]; then
    echo "TEST RESULT: PASS"
    exit 0
else
    echo "TEST RESULT: FAIL"
    exit 1
fi
