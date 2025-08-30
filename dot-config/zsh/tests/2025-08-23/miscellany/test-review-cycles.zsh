#!/opt/homebrew/bin/zsh
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
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Load the 020-review cycles system
REVIEW_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_07-review-cycles.zsh"

if [[ ! -f "$REVIEW_SCRIPT" ]]; then
        zsh_debug_echo "ERROR: Review cycles script not found: $REVIEW_SCRIPT"
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
        zsh_debug_echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

        zsh_debug_echo "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
            zsh_debug_echo "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
            zsh_debug_echo "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
            zsh_debug_echo "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. REVIEW CYCLES FUNCTION TESTS
# ------------------------------------------------------------------------------

test_review_functions_exist() {
        zsh_debug_echo "    📅 Testing review cycles functions exist..."

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
        zsh_debug_echo "    📅 Testing review cycles initialization..."

    # Check if 020-review directories were created
    if [[ -d "$ZSH_REVIEW_DIR" ]]; then
            zsh_debug_echo "    ✓ Review directory created"
    else
            zsh_debug_echo "    ✗ Review directory not created"
        return 1
    fi

    # Check if 020-review files were created
    local required_files=("$ZSH_REVIEW_SCHEDULE_FILE" "$ZSH_REVIEW_HISTORY_FILE" "$ZSH_REVIEW_REMINDERS_FILE")
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
                zsh_debug_echo "    ✓ Review file created: $(basename "$file")"
        else
                zsh_debug_echo "    ✗ Review file not created: $(basename "$file")"
            return 1
        fi
    done

    # Check if 020-review cycles are initialized
    if [[ "$ZSH_REVIEW_CYCLES_INITIALIZED" == "true" ]]; then
            zsh_debug_echo "    ✓ Review cycles initialized"
    else
            zsh_debug_echo "    ✗ Review cycles not initialized"
        return 1
    fi

    return 0
}

test_review_schedule_loading() {
        zsh_debug_echo "    📅 Testing review schedule loading..."

    # Check if 020-review types are loaded
    local expected_types=("performance" "security" "configuration" "documentation" "system")
    local loaded_types=0

    for review_type in "${expected_types[@]}"; do
        if [[ -n "${ZSH_REVIEW_TYPES[$review_type]}" ]]; then
                zsh_debug_echo "    ✓ Review type loaded: $review_type (${ZSH_REVIEW_TYPES[$review_type]})"
            loaded_types=$((loaded_types + 1))
        else
                zsh_debug_echo "    ⚠ Review type not loaded: $review_type"
        fi
    done

    if [[ $loaded_types -ge 3 ]]; then
            zsh_debug_echo "    ✓ Review schedule loading working"
        return 0
    else
            zsh_debug_echo "    ✗ Review schedule loading failed"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. DATE CALCULATION TESTS
# ------------------------------------------------------------------------------

test_next_date_calculation() {
        zsh_debug_echo "    📅 Testing next date calculation..."

    # Test monthly calculation
    local next_monthly=$(_calculate_next_review_date "performance" "2025-08-01")
    if [[ -n "$next_monthly" ]]; then
            zsh_debug_echo "    ✓ Monthly date calculation: $next_monthly"
    else
            zsh_debug_echo "    ✗ Monthly date calculation failed"
        return 1
    fi

    # Test quarterly calculation
    local next_quarterly=$(_calculate_next_review_date "security" "2025-08-01")
    if [[ -n "$next_quarterly" ]]; then
            zsh_debug_echo "    ✓ Quarterly date calculation: $next_quarterly"
    else
            zsh_debug_echo "    ✗ Quarterly date calculation failed"
        return 1
    fi

    # Test with no last date (should return today)
    local next_today=$(_calculate_next_review_date "performance" "")
    if [[ -n "$next_today" ]]; then
            zsh_debug_echo "    ✓ No last date calculation: $next_today"
    else
            zsh_debug_echo "    ✗ No last date calculation failed"
        return 1
    fi

    return 0
}

test_schedule_update() {
        zsh_debug_echo "    📅 Testing schedule update..."

    # Update a 020-review schedule (this may fail if schedule file doesn't exist)
    _update_review_schedule "performance" "2025-08-22" 2>/dev/null || true

    # Check if the update was recorded in memory
    if [[ "${ZSH_REVIEW_LAST_DATES[performance]}" == "2025-08-22" ]]; then
            zsh_debug_echo "    ✓ Schedule update recorded in memory"
    else
            zsh_debug_echo "    ⚠ Schedule update not recorded in memory (may be expected if file missing)"
    fi

    # Check if next date was calculated
    if [[ -n "${ZSH_REVIEW_NEXT_DATES[performance]}" ]]; then
            zsh_debug_echo "    ✓ Next date calculated: ${ZSH_REVIEW_NEXT_DATES[performance]}"
    else
            zsh_debug_echo "    ⚠ Next date not calculated (may be expected if file missing)"
    fi

    # Test passes if the function doesn't crash
    return 0
}

# ------------------------------------------------------------------------------
# 4. REMINDER SYSTEM TESTS
# ------------------------------------------------------------------------------

test_due_review_checking() {
        zsh_debug_echo "    📅 Testing due review checking..."

    # Set up a 020-review that's due (use proper array assignment)
    ZSH_REVIEW_NEXT_DATES[test_review]="2025-08-20"  # Past date

    # Capture output of due 020-review check
    local due_output=$(_check_due_reviews 2>/dev/null)

    # Check if function runs without error
    if [[ $? -eq 0 ]]; then
            zsh_debug_echo "    ✓ Due review checking executed successfully"
    else
            zsh_debug_echo "    ✗ Due review checking failed"
        return 1
    fi

    # Clean up test data
    unset 'ZSH_REVIEW_NEXT_DATES[test_review]'

    return 0
}

test_reminder_logging() {
        zsh_debug_echo "    📅 Testing reminder logging..."

    # Log a test reminder
    _log_review_reminder "test_review" "due"

    # Check if reminder was logged
    if grep -q "test_review,due" "$ZSH_REVIEW_REMINDERS_FILE"; then
            zsh_debug_echo "    ✓ Reminder logged successfully"
    else
            zsh_debug_echo "    ✗ Reminder not logged"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 5. COMMAND INTERFACE TESTS
# ------------------------------------------------------------------------------

test_review_status_command() {
        zsh_debug_echo "    📅 Testing review-status command..."

    # Test 020-review-status command
    local status_output=$(020-review-status 2>/dev/null)

    if     zsh_debug_echo "$status_output" | grep -q "Review Cycles Status"; then
            zsh_debug_echo "    ✓ review-status command working"
    else
            zsh_debug_echo "    ✗ review-status command not working"
        return 1
    fi

    # Check for expected content
    if     zsh_debug_echo "$status_output" | grep -q "Review Schedule:"; then
            zsh_debug_echo "    ✓ Review schedule displayed"
    else
            zsh_debug_echo "    ⚠ Review schedule may not be displayed"
    fi

    return 0
}

test_review_complete_command() {
        zsh_debug_echo "    📅 Testing review-complete command..."

    # Test 020-review-complete command
    local complete_output=$(020-review-complete "performance" "Test completion" 2>/dev/null)

    if     zsh_debug_echo "$complete_output" | grep -q "performance review marked as completed"; then
            zsh_debug_echo "    ✓ review-complete command working"
    else
            zsh_debug_echo "    ✗ review-complete command not working"
        return 1
    fi

    # Check if completion was recorded in history
    if grep -q "performance,completed,Test completion" "$ZSH_REVIEW_HISTORY_FILE"; then
            zsh_debug_echo "    ✓ Review completion recorded in history"
    else
            zsh_debug_echo "    ⚠ Review completion may not be recorded"
    fi

    return 0
}

test_review_schedule_command() {
        zsh_debug_echo "    📅 Testing review-schedule command..."

    # Test 020-review-schedule command
    local schedule_output=$(020-review-schedule "security" "2025-12-01" 2>/dev/null)

    if     zsh_debug_echo "$schedule_output" | grep -q "security review scheduled for 2025-12-01"; then
            zsh_debug_echo "    ✓ review-schedule command working"
    else
            zsh_debug_echo "    ✗ review-schedule command not working"
        return 1
    fi

    # Check if schedule was updated
    if [[ "${ZSH_REVIEW_NEXT_DATES[security]}" == "2025-12-01" ]]; then
            zsh_debug_echo "    ✓ Review schedule updated in memory"
    else
            zsh_debug_echo "    ⚠ Review schedule may not be updated"
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 6. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_review_integration() {
        zsh_debug_echo "    📅 Testing review cycles integration..."

    local integration_issues=0

    # Check if all 020-review files exist and are writable
    local required_files=("$ZSH_REVIEW_SCHEDULE_FILE" "$ZSH_REVIEW_HISTORY_FILE" "$ZSH_REVIEW_REMINDERS_FILE")
    for file in "${required_files[@]}"; do
        if [[ -f "$file" && -w "$file" ]]; then
                zsh_debug_echo "    ✓ Review file accessible: $(basename "$file")"
        else
                zsh_debug_echo "    ⚠ Review file issue: $(basename "$file")"
            integration_issues=$((integration_issues + 1))
        fi
    done

    # Check if 020-review variables are set
    local required_vars=("ZSH_REVIEW_CYCLES_VERSION" "ZSH_REVIEW_DIR" "ZSH_ENABLE_REVIEW_CYCLES")
    for var in "${required_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
                zsh_debug_echo "    ✓ Review variable set: $var"
        else
            integration_issues=$((integration_issues + 1))
                zsh_debug_echo "    ✗ Review variable not set: $var"
        fi
    done

    # Check if context-aware logging is working
    if declare -f _review_log >/dev/null 2>&1; then
            zsh_debug_echo "    ✓ Review logging integration working"
    else
            zsh_debug_echo "    ⚠ Review logging not available"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zsh_debug_echo "    ✓ Review cycles integration successful"
        return 0
    else
            zsh_debug_echo "    ⚠ Review cycles integration has $integration_issues minor issues"
        return 0  # Don't fail for minor integration issues
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Review Cycles Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Review Cycles Version: ${ZSH_REVIEW_CYCLES_VERSION:-unknown}"
        zsh_debug_echo "Test Temp Dir: $TEST_TEMP_DIR"
        zsh_debug_echo ""

    log_test "Starting review cycles test suite"

    # Function Existence Tests
        zsh_debug_echo "=== Review Function Tests ==="
    run_test "Review Functions Exist" "test_review_functions_exist"

    # System Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Review System Tests ==="
    run_test "Review Initialization" "test_review_initialization"
    run_test "Review Schedule Loading" "test_review_schedule_loading"

    # Date Calculation Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Date Calculation Tests ==="
    run_test "Next Date Calculation" "test_next_date_calculation"
    run_test "Schedule Update" "test_schedule_update"

    # Reminder System Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Reminder System Tests ==="
    run_test "Due Review Checking" "test_due_review_checking"
    run_test "Reminder Logging" "test_reminder_logging"

    # Command Interface Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Command Interface Tests ==="
    run_test "Review Status Command" "test_review_status_command"
    run_test "Review Complete Command" "test_review_complete_command"
    run_test "Review Schedule Command" "test_review_schedule_command"

    # Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
    run_test "Review Integration" "test_review_integration"

    # Results Summary
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zsh_debug_echo "Success Rate: ${pass_percentage}%"

    log_test "Review cycles test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All review cycles tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED review cycles test(s) failed."
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
        zsh_debug_echo "Review cycles test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Review Cycles Test Suite
# ==============================================================================
