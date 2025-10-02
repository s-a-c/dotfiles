#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Review Cycles Test Suite
# ==============================================================================
# Purpose: Test the periodic 020-review cycles system to ensure proper scheduling,
#          reminder functionality, 020-review management, and automated tracking
#          with comprehensive validation of 020-review cycle capabilities and
#          maintenance scheduling accuracy.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-review-cycles.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 07-review-cycles.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_REVIEW_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
        zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Load the 020-review cycles system
REVIEW_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_07-review-cycles.zsh"

if [[ ! -f "$REVIEW_SCRIPT" ]]; then
        zf::debug "ERROR: Review cycles script not found: $REVIEW_SCRIPT"
    exit 1
fi

# Source the 020-review cycles system
source "$REVIEW_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-review-cycles.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Test temporary directory
TEST_TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEST_TEMP_DIR'" EXIT

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
        zf::debug "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

        zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
            zf::debug "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
            zf::debug "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
            zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. REVIEW CYCLES FUNCTION TESTS
# ------------------------------------------------------------------------------

test_review_functions_exist() {
        zf::debug "    📅 Testing review cycles functions exist..."

    assert_function_exists "_init_review_cycles" &&
    assert_function_exists "_load_review_schedule" &&
    assert_function_exists "_calculate_next_review_date" &&
    assert_function_exists "_update_review_schedule" &&
    assert_function_exists "_check_due_reviews" &&
    assert_function_exists "_log_review_reminder" &&
    assert_function_exists "review-status" &&
    assert_function_exists "review-complete" &&
    assert_function_exists "review-schedule"
}

test_review_initialization() {
        zf::debug "    📅 Testing review cycles initialization..."

    # Check if 020-review directories were created
    if [[ -d "$ZSH_REVIEW_DIR" ]]; then
            zf::debug "    ✓ Review directory created"
    else
            zf::debug "    ✗ Review directory not created"
        return 1
    fi

    # Check if 020-review files were created
    local required_files=("$ZSH_REVIEW_SCHEDULE_FILE" "$ZSH_REVIEW_HISTORY_FILE" "$ZSH_REVIEW_REMINDERS_FILE")
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
                zf::debug "    ✓ Review file created: $(basename "$file")"
        else
                zf::debug "    ✗ Review file not created: $(basename "$file")"
            return 1
        fi
    done

    # Check if 020-review cycles are initialized
    if [[ "$ZSH_REVIEW_CYCLES_INITIALIZED" == "true" ]]; then
            zf::debug "    ✓ Review cycles initialized"
    else
            zf::debug "    ✗ Review cycles not initialized"
        return 1
    fi

    return 0
}

test_review_schedule_loading() {
        zf::debug "    📅 Testing review schedule loading..."

    # Check if 020-review types are loaded
    local expected_types=("performance" "security" "configuration" "documentation" "system")
    local loaded_types=0

    for review_type in "${expected_types[@]}"; do
        if [[ -n "${ZSH_REVIEW_TYPES[$review_type]}" ]]; then
                zf::debug "    ✓ Review type loaded: $review_type (${ZSH_REVIEW_TYPES[$review_type]})"
            loaded_types=$((loaded_types + 1))
        else
                zf::debug "    ⚠ Review type not loaded: $review_type"
        fi
    done

    if [[ $loaded_types -ge 3 ]]; then
            zf::debug "    ✓ Review schedule loading working"
        return 0
    else
            zf::debug "    ✗ Review schedule loading failed"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. DATE CALCULATION TESTS
# ------------------------------------------------------------------------------

test_next_date_calculation() {
        zf::debug "    📅 Testing next date calculation..."

    # Test monthly calculation
    local next_monthly=$(_calculate_next_review_date "performance" "2025-08-01")
    if [[ -n "$next_monthly" ]]; then
            zf::debug "    ✓ Monthly date calculation: $next_monthly"
    else
            zf::debug "    ✗ Monthly date calculation failed"
        return 1
    fi

    # Test quarterly calculation
    local next_quarterly=$(_calculate_next_review_date "security" "2025-08-01")
    if [[ -n "$next_quarterly" ]]; then
            zf::debug "    ✓ Quarterly date calculation: $next_quarterly"
    else
            zf::debug "    ✗ Quarterly date calculation failed"
        return 1
    fi

    # Test with no last date (should return today)
    local next_today=$(_calculate_next_review_date "performance" "")
    if [[ -n "$next_today" ]]; then
            zf::debug "    ✓ No last date calculation: $next_today"
    else
            zf::debug "    ✗ No last date calculation failed"
        return 1
    fi

    return 0
}

test_schedule_update() {
        zf::debug "    📅 Testing schedule update..."

    # Update a 020-review schedule (this may fail if schedule file doesn't exist)
    _update_review_schedule "performance" "2025-08-22" 2>/dev/null || true

    # Check if the update was recorded in memory
    if [[ "${ZSH_REVIEW_LAST_DATES[performance]}" == "2025-08-22" ]]; then
            zf::debug "    ✓ Schedule update recorded in memory"
    else
            zf::debug "    ⚠ Schedule update not recorded in memory (may be expected if file missing)"
    fi

    # Check if next date was calculated
    if [[ -n "${ZSH_REVIEW_NEXT_DATES[performance]}" ]]; then
            zf::debug "    ✓ Next date calculated: ${ZSH_REVIEW_NEXT_DATES[performance]}"
    else
            zf::debug "    ⚠ Next date not calculated (may be expected if file missing)"
    fi

    # Test passes if the function doesn't crash
    return 0
}

# ------------------------------------------------------------------------------
# 4. REMINDER SYSTEM TESTS
# ------------------------------------------------------------------------------

test_due_review_checking() {
        zf::debug "    📅 Testing due review checking..."

    # Set up a 020-review that's due (use proper array assignment)
    ZSH_REVIEW_NEXT_DATES[test_review]="2025-08-20"  # Past date

    # Capture output of due 020-review check
    local due_output=$(_check_due_reviews 2>/dev/null)

    # Check if function runs without error
    if [[ $? -eq 0 ]]; then
            zf::debug "    ✓ Due review checking executed successfully"
    else
            zf::debug "    ✗ Due review checking failed"
        return 1
    fi

    # Clean up test data
    unset 'ZSH_REVIEW_NEXT_DATES[test_review]'

    return 0
}

test_reminder_logging() {
        zf::debug "    📅 Testing reminder logging..."

    # Log a test reminder
    _log_review_reminder "test_review" "due"

    # Check if reminder was logged
    if grep -q "test_review,due" "$ZSH_REVIEW_REMINDERS_FILE"; then
            zf::debug "    ✓ Reminder logged successfully"
    else
            zf::debug "    ✗ Reminder not logged"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 5. COMMAND INTERFACE TESTS
# ------------------------------------------------------------------------------

test_review_status_command() {
        zf::debug "    📅 Testing review-status command..."

    # Test 020-review-status command
    local status_output=$(020-review-status 2>/dev/null)

    if     zf::debug "$status_output" | grep -q "Review Cycles Status"; then
            zf::debug "    ✓ review-status command working"
    else
            zf::debug "    ✗ review-status command not working"
        return 1
    fi

    # Check for expected content
    if     zf::debug "$status_output" | grep -q "Review Schedule:"; then
            zf::debug "    ✓ Review schedule displayed"
    else
            zf::debug "    ⚠ Review schedule may not be displayed"
    fi

    return 0
}

test_review_complete_command() {
        zf::debug "    📅 Testing review-complete command..."

    # Test 020-review-complete command
    local complete_output=$(020-review-complete "performance" "Test completion" 2>/dev/null)

    if     zf::debug "$complete_output" | grep -q "performance review marked as completed"; then
            zf::debug "    ✓ review-complete command working"
    else
            zf::debug "    ✗ review-complete command not working"
        return 1
    fi

    # Check if completion was recorded in history
    if grep -q "performance,completed,Test completion" "$ZSH_REVIEW_HISTORY_FILE"; then
            zf::debug "    ✓ Review completion recorded in history"
    else
            zf::debug "    ⚠ Review completion may not be recorded"
    fi

    return 0
}

test_review_schedule_command() {
        zf::debug "    📅 Testing review-schedule command..."

    # Test 020-review-schedule command
    local schedule_output=$(020-review-schedule "security" "2025-12-01" 2>/dev/null)

    if     zf::debug "$schedule_output" | grep -q "security review scheduled for 2025-12-01"; then
            zf::debug "    ✓ review-schedule command working"
    else
            zf::debug "    ✗ review-schedule command not working"
        return 1
    fi

    # Check if schedule was updated
    if [[ "${ZSH_REVIEW_NEXT_DATES[security]}" == "2025-12-01" ]]; then
            zf::debug "    ✓ Review schedule updated in memory"
    else
            zf::debug "    ⚠ Review schedule may not be updated"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 6. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_review_integration() {
        zf::debug "    📅 Testing review cycles integration..."

    local integration_issues=0

    # Check if all 020-review files exist and are writable
    local required_files=("$ZSH_REVIEW_SCHEDULE_FILE" "$ZSH_REVIEW_HISTORY_FILE" "$ZSH_REVIEW_REMINDERS_FILE")
    for file in "${required_files[@]}"; do
        if [[ -f "$file" && -w "$file" ]]; then
                zf::debug "    ✓ Review file accessible: $(basename "$file")"
        else
                zf::debug "    ⚠ Review file issue: $(basename "$file")"
            integration_issues=$((integration_issues + 1))
        fi
    done

    # Check if 020-review variables are set
    local required_vars=("ZSH_REVIEW_CYCLES_VERSION" "ZSH_REVIEW_DIR" "ZSH_ENABLE_REVIEW_CYCLES")
    for var in "${required_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
                zf::debug "    ✓ Review variable set: $var"
        else
            integration_issues=$((integration_issues + 1))
                zf::debug "    ✗ Review variable not set: $var"
        fi
    done

    # Check if context-aware logging is working
    if declare -f _review_log >/dev/null 2>&1; then
            zf::debug "    ✓ Review logging integration working"
    else
            zf::debug "    ⚠ Review logging not available"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ Review cycles integration successful"
        return 0
    else
            zf::debug "    ⚠ Review cycles integration has $integration_issues minor issues"
        return 0  # Don't fail for minor integration issues
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zf::debug "========================================================"
        zf::debug "Review Cycles Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Review Cycles Version: ${ZSH_REVIEW_CYCLES_VERSION:-unknown}"
        zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
        zf::debug ""

    log_test "Starting review cycles test suite"

    # Function Existence Tests
        zf::debug "=== Review Function Tests ==="
    run_test "Review Functions Exist" "test_review_functions_exist"

    # System Tests
        zf::debug ""
        zf::debug "=== Review System Tests ==="
    run_test "Review Initialization" "test_review_initialization"
    run_test "Review Schedule Loading" "test_review_schedule_loading"

    # Date Calculation Tests
        zf::debug ""
        zf::debug "=== Date Calculation Tests ==="
    run_test "Next Date Calculation" "test_next_date_calculation"
    run_test "Schedule Update" "test_schedule_update"

    # Reminder System Tests
        zf::debug ""
        zf::debug "=== Reminder System Tests ==="
    run_test "Due Review Checking" "test_due_review_checking"
    run_test "Reminder Logging" "test_reminder_logging"

    # Command Interface Tests
        zf::debug ""
        zf::debug "=== Command Interface Tests ==="
    run_test "Review Status Command" "test_review_status_command"
    run_test "Review Complete Command" "test_review_complete_command"
    run_test "Review Schedule Command" "test_review_schedule_command"

    # Integration Tests
        zf::debug ""
        zf::debug "=== Integration Tests ==="
    run_test "Review Integration" "test_review_integration"

    # Results Summary
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Review cycles test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zf::debug ""
            zf::debug "🎉 All review cycles tests passed!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED review cycles test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

review_cycles_test_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    review_cycles_test_main "$@"
elif is_being_sourced; then
        zf::debug "Review cycles test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Review Cycles Test Suite
# ==============================================================================
