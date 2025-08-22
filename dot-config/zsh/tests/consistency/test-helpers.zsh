#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Standard Helpers Test Suite
# ==============================================================================
# Purpose: Comprehensive test suite for standardized helper library with
#          integrated source/execute detection and context-aware testing
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.1.0
# Usage: ./test-helpers.zsh (execute) or source test-helpers.zsh (source)
#
# This test suite validates all functions in the standard helpers library
# to ensure reliability, performance, and correct integration with the
# existing ZSH configuration system and source/execute detection.
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Set testing flag to prevent initialization conflicts
export ZSH_HELPERS_TESTING="1"  # Disable auto-initialization for testing
export ZSH_SOURCE_EXECUTE_TESTING="true"
export ZSH_DEBUG="0"             # Suppress debug output during tests

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
    echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT" >&2
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# 1. Test Setup and Configuration
#=============================================================================

# 1.2. Test results tracking
declare -a TEST_RESULTS
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0

# 1.3. Test utilities
test_start() {
    local test_name="$1"
    echo "Running: $test_name"
    ((TESTS_RUN++))
}

test_pass() {
    local test_name="$1"
    TEST_RESULTS+=("✅ $test_name")
    ((TESTS_PASSED++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    TEST_RESULTS+=("❌ $test_name: $reason")
    ((TESTS_FAILED++))
}

# 1.4. Save current working directory
ORIGINAL_PWD="$(pwd)"

# 1.5. Load helper library for testing
# Use relative path from current working directory
HELPER_LIB=".zshrc.d/00-core/00-standard-helpers.zsh"

if ! source "$HELPER_LIB" 2>/dev/null; then
    echo "FATAL: Cannot load helper library for testing"
    echo "Current directory: $(pwd)"
    echo "Helper library path: $HELPER_LIB"
    echo "File exists: $(test -f "$HELPER_LIB" && echo 'YES' || echo 'NO')"
    exit 1
fi

# 2. Test Functions
#=============================================================================

# 2.1. Test Core Utility Functions
test_core_utilities() {
    test_start "Core Utilities - UTC Timestamp"
    local timestamp="$(utc_timestamp)"
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ UTC$ ]]; then
        test_pass "UTC Timestamp format"
    else
        test_fail "UTC Timestamp format" "Got: $timestamp"
    fi

    test_start "Core Utilities - Safe Logging"
    local test_log_file="/tmp/test-helper-log-$$"
    safe_log "$test_log_file" "Test message" "2025-08-21 12:00:00 UTC"
    if [[ -f "$test_log_file" ]] && grep -q "Test message" "$test_log_file"; then
        test_pass "Safe Logging"
        rm -f "$test_log_file"
    else
        test_fail "Safe Logging" "Log file not created or message not found"
    fi

    test_start "Core Utilities - Debug Logging"
    # Debug logging requires ZSH_DEBUG=1 to output
    local original_debug="$ZSH_DEBUG"
    export ZSH_DEBUG="1"
    local debug_output="$(debug_log "test" "debug message" "INFO" 2>&1)"
    export ZSH_DEBUG="$original_debug"
    if [[ "$debug_output" == *"debug message"* ]]; then
        test_pass "Debug Logging"
    else
        test_fail "Debug Logging" "Debug message not output correctly"
    fi
}

# 2.2. Test Command and File Existence Functions
test_existence_functions() {
    test_start "Existence Functions - Command Detection"
    if has_command "echo" && ! has_command "nonexistent_command_12345"; then
        test_pass "Command Detection"
    else
        test_fail "Command Detection" "Failed to detect commands correctly"
    fi

    test_start "Existence Functions - Command Caching"
    # Test that cache works by checking if second call is faster
    local start_time="$SECONDS"
    has_command "echo"
    local first_call_time=$(( SECONDS - start_time ))

    start_time="$SECONDS"
    has_command "echo"
    local second_call_time=$(( SECONDS - start_time ))

    # Second call should be faster due to caching (or at least not slower)
    if (( second_call_time <= first_call_time + 1 )); then
        test_pass "Command Caching"
    else
        test_fail "Command Caching" "Second call not faster: $first_call_time vs $second_call_time"
    fi

    test_start "Existence Functions - File Detection"
    local test_file="/tmp/test-readable-file-$$"
    echo "test" > "$test_file"
    chmod 644 "$test_file"

    if has_readable_file "$test_file" && ! has_readable_file "/nonexistent/file/12345"; then
        test_pass "File Detection"
    else
        test_fail "File Detection" "Failed to detect files correctly"
    fi
    rm -f "$test_file"

    test_start "Existence Functions - Directory Detection"
    local test_dir="/tmp/test-accessible-dir-$$"
    mkdir -p "$test_dir"
    chmod 755 "$test_dir"

    if has_accessible_dir "$test_dir" && ! has_accessible_dir "/nonexistent/dir/12345"; then
        test_pass "Directory Detection"
    else
        test_fail "Directory Detection" "Failed to detect directories correctly"
    fi
    rmdir "$test_dir"

    test_start "Existence Functions - Path Security"
    if ! is_secure_path_component "." && \
       ! is_secure_path_component "/tmp" && \
       is_secure_path_component "/usr/bin"; then
        test_pass "Path Security Validation"
    else
        test_fail "Path Security Validation" "Insecure paths not detected correctly"
    fi
}

# 2.3. Test Environment Variable Management
test_environment_functions() {
    test_start "Environment Functions - Idempotent Export"
    unset ZSH_TEST_VAR_12345
    export_if_unset "ZSH_TEST_VAR_12345" "first_value"
    export_if_unset "ZSH_TEST_VAR_12345" "second_value"

    if [[ "$ZSH_TEST_VAR_12345" == "first_value" ]]; then
        test_pass "Idempotent Export"
    else
        test_fail "Idempotent Export" "Variable was overwritten: $ZSH_TEST_VAR_12345"
    fi
    unset ZSH_TEST_VAR_12345

    test_start "Environment Functions - Export with Validation"
    # Create a validator function that only allows "valid"
    test_validator() {
        [[ "$1" == "valid" ]]
    }

    export_with_validation "ZSH_TEST_VAR_VALID" "valid" "test_validator"
    local valid_result=$?
    export_with_validation "ZSH_TEST_VAR_INVALID" "invalid" "test_validator"
    local invalid_result=$?

    if (( valid_result == 0 )) && (( invalid_result != 0 )) && [[ "$ZSH_TEST_VAR_VALID" == "valid" ]]; then
        test_pass "Export with Validation"
    else
        test_fail "Export with Validation" "Validation not working correctly"
    fi
    unset ZSH_TEST_VAR_VALID ZSH_TEST_VAR_INVALID

    test_start "Environment Functions - Safe Unset"
    export ZSH_TEST_UNSET_VAR="test_value"
    safe_unset "ZSH_TEST_UNSET_VAR"
    safe_unset "ZSH_NONEXISTENT_VAR"  # Should not error

    if [[ -z "$ZSH_TEST_UNSET_VAR" ]]; then
        test_pass "Safe Unset"
    else
        test_fail "Safe Unset" "Variable not unset: $ZSH_TEST_UNSET_VAR"
    fi

    test_start "Environment Functions - Sensitive Variable Detection"
    if is_sensitive_variable "MY_PASSWORD" && \
       is_sensitive_variable "API_TOKEN" && \
       is_sensitive_variable "SSH_KEY" && \
       ! is_sensitive_variable "NORMAL_VAR"; then
        test_pass "Sensitive Variable Detection"
    else
        test_fail "Sensitive Variable Detection" "Pattern matching not working correctly"
    fi
}

# 2.4. Test PATH Management Functions
test_path_functions() {
    test_start "PATH Functions - Setup"
    local original_path="$PATH"

    test_start "PATH Functions - Path Prepend"
    local test_path="/test/prepend/path"
    path_prepend "$test_path" false  # Skip validation for test
    if [[ ":$PATH:" == *":$test_path:"* ]] && [[ "$PATH" == "$test_path:"* ]]; then
        test_pass "Path Prepend"
    else
        test_fail "Path Prepend" "Path not prepended correctly"
    fi

    # Test idempotency
    local path_before_second="$PATH"
    path_prepend "$test_path" false
    if [[ "$PATH" == "$path_before_second" ]]; then
        test_pass "Path Prepend Idempotency"
    else
        test_fail "Path Prepend Idempotency" "Path was duplicated"
    fi

    test_start "PATH Functions - Path Append"
    local append_path="/test/append/path"
    path_append "$append_path" false  # Skip validation for test
    if [[ ":$PATH:" == *":$append_path:"* ]] && [[ "$PATH" == *":$append_path" ]]; then
        test_pass "Path Append"
    else
        test_fail "Path Append" "Path not appended correctly"
    fi

    test_start "PATH Functions - Path Remove"
    path_remove "$test_path"
    if [[ ":$PATH:" != *":$test_path:"* ]]; then
        test_pass "Path Remove"
    else
        test_fail "Path Remove" "Path not removed correctly"
    fi

    test_start "PATH Functions - Path Clean"
    export PATH="$original_path:/nonexistent/path1:/nonexistent/path2"
    path_clean
    if [[ ":$PATH:" != *":/nonexistent/path1:"* ]] && [[ ":$PATH:" != *":/nonexistent/path2:"* ]]; then
        test_pass "Path Clean"
    else
        test_fail "Path Clean" "Non-existent paths not removed"
    fi

    # Restore original PATH
    export PATH="$original_path"
}

# 2.5. Test Safe Operations and Error Handling
test_safe_operations() {
    test_start "Safe Operations - Safe Source (Success)"
    local test_source_file="/tmp/test-source-$$"
    echo "export ZSH_TEST_SOURCED_VAR='sourced_value'" > "$test_source_file"

    safe_source "$test_source_file"
    if [[ "$ZSH_TEST_SOURCED_VAR" == "sourced_value" ]]; then
        test_pass "Safe Source (Success)"
    else
        test_fail "Safe Source (Success)" "File not sourced correctly"
    fi
    rm -f "$test_source_file"
    unset ZSH_TEST_SOURCED_VAR

    test_start "Safe Operations - Safe Source (Missing File)"
    safe_source "/nonexistent/file/12345"
    local missing_result=$?
    if (( missing_result == 0 )); then  # Should not fail for missing optional file
        test_pass "Safe Source (Missing File)"
    else
        test_fail "Safe Source (Missing File)" "Should not fail for missing optional file"
    fi

    test_start "Safe Operations - Safe Execute"
    if safe_execute "5" "echo test" echo "test_message" >/dev/null; then
        test_pass "Safe Execute"
    else
        test_fail "Safe Execute" "Failed to execute simple command"
    fi

    test_start "Safe Operations - Retry Operation"
    # Create a script that fails twice then succeeds
    local retry_script="/tmp/retry-test-$$"
    cat > "$retry_script" << 'EOF'
#!/usr/bin/env zsh
ATTEMPTS_FILE="/tmp/retry-attempts-$$"
if [[ ! -f "$ATTEMPTS_FILE" ]]; then
    echo "1" > "$ATTEMPTS_FILE"
    exit 1
elif [[ "$(cat "$ATTEMPTS_FILE")" == "1" ]]; then
    echo "2" > "$ATTEMPTS_FILE"
    exit 1
else
    rm -f "$ATTEMPTS_FILE"
    exit 0
fi
EOF
    chmod +x "$retry_script"

    if retry_operation 3 0.1 "test retry" "$retry_script" >/dev/null 2>&1; then
        test_pass "Retry Operation"
    else
        test_fail "Retry Operation" "Retry mechanism not working"
    fi
    rm -f "$retry_script" "/tmp/retry-attempts-$$"
}

# 2.6. Test Performance and Caching Functions
test_performance_functions() {
    test_start "Performance Functions - Clear Cache"
    # Populate cache first
    has_command "echo"
    clear_helper_cache

    # Check that cache is actually cleared
    if [[ -z "${_zsh_helper_cache[cmd_echo]}" ]]; then
        test_pass "Clear Cache"
    else
        test_fail "Clear Cache" "Cache not cleared properly"
    fi

    test_start "Performance Functions - Time Function"
    # Test timing a simple function
    test_timed_function() {
        sleep 0.1
        return 42
    }

    local original_debug="$ZSH_DEBUG"
    export ZSH_DEBUG="1"
    local timing_output="$(time_helper_function test_timed_function 2>&1)"
    export ZSH_DEBUG="$original_debug"
    local timing_result=$?

    if (( timing_result == 42 )) && [[ "$timing_output" == *"test_timed_function completed"* ]]; then
        test_pass "Time Function"
    else
        test_fail "Time Function" "Timing or return value incorrect"
    fi

    test_start "Performance Functions - Performance Marker"
    local perf_log="/tmp/test-perf-$$"
    export ZSH_PERF_LOG="$perf_log"
    perf_marker "test_marker"

    if [[ -f "$perf_log" ]] && grep -q "MARKER: test_marker" "$perf_log"; then
        test_pass "Performance Marker"
    else
        test_fail "Performance Marker" "Performance marker not logged"
    fi
    rm -f "$perf_log"
    unset ZSH_PERF_LOG
}

# 2.7. Test Validation Functions
test_validation_functions() {
    test_start "Validation Functions - Helper Validation"
    if validate_helpers; then
        test_pass "Helper Validation"
    else
        test_fail "Helper Validation" "Helper validation failed"
    fi

    test_start "Validation Functions - Self Test"
    # Capture self-test output and check return code
    local self_test_output="$(test_helpers 2>&1)"
    local self_test_result=$?

    if (( self_test_result == 0 )) && [[ "$self_test_output" == *"✅"* ]]; then
        test_pass "Self Test"
    else
        test_fail "Self Test" "Self test failed or no success markers found"
    fi
}

# 2.8. Test Integration and Real-World Usage
test_integration() {
    test_start "Integration - Real File Operations"
    # Test with actual configuration file using ZDOTDIR
    local real_file="$HELPER_LIB"
    if has_readable_file "$real_file"; then
        test_pass "Real File Operations"
    else
        test_fail "Real File Operations" "Cannot read actual helper file"
    fi

    test_start "Integration - Environment Variable Patterns"
    # Test with actual environment variables
    local env_count=0
    for var in $(env | head -10 | cut -d= -f1); do
        if [[ -n "$var" ]]; then
            # Should not crash on real environment variables
            is_sensitive_variable "$var" || true
            ((env_count++))
        fi
    done

    if (( env_count > 0 )); then
        test_pass "Environment Variable Patterns"
    else
        test_fail "Environment Variable Patterns" "No environment variables processed"
    fi

    test_start "Integration - PATH Validation"
    # Test with current PATH
    local path_components=0
    local IFS=":"
    local path_array=(${=PATH})

    for component in "${path_array[@]}"; do
        if [[ -n "$component" ]]; then
            # Should not crash on real PATH components
            is_secure_path_component "$component" || true
            ((path_components++))
        fi
    done

    if (( path_components > 0 )); then
        test_pass "PATH Validation"
    else
        test_fail "PATH Validation" "No PATH components processed"
    fi
}

# 3. Main Test Execution
#=============================================================================

main() {
    echo "========================================================"
    echo "ZSH Standard Helpers Library Test Suite"
    echo "========================================================"
    echo "Timestamp: $(utc_timestamp)"
    echo "Execution Context: $(get_execution_context)"
    echo "Helper Library Version: ${ZSH_HELPERS_VERSION:-unknown}"
    echo ""

    # Run all test categories
    test_core_utilities
    test_existence_functions
    test_environment_functions
    test_path_functions
    test_safe_operations
    test_performance_functions
    test_validation_functions
    test_integration

    # Restore working directory
    cd "$ORIGINAL_PWD"

    # Display results
    echo
    echo "=== Test Results Summary ==="
    for result in "${TEST_RESULTS[@]}"; do
        echo "$result"
    done

    echo
    echo "=== Test Statistics ==="
    echo "Total Tests: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"

    if (( TESTS_FAILED == 0 )); then
        echo "✅ All tests passed!"
        return 0
    else
        local pass_rate=$(( TESTS_PASSED * 100 / TESTS_RUN ))
        echo "❌ $TESTS_FAILED test(s) failed (${pass_rate}% pass rate)"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
    echo "Standard helpers test functions loaded (sourced context)"
    echo "Available functions: main, test_*, individual test categories"
    echo "Current execution context: $(get_execution_context)"
fi
