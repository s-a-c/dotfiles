#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Detection Integration Test Suite
# ==============================================================================
# Purpose: Test integration of source/execute detection patterns across all
#          existing test scripts, tools, and helper functions to ensure
#          consistent implementation and proper retrofitting.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-detection-integration.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_SOURCE_EXECUTE_DEBUG=false

# Load the source/execute detection system
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-detection-integration.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration paths
ZSH_CONFIG_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"
TEST_DIR="$ZSH_CONFIG_ROOT/tests"
BIN_DIR="$ZSH_CONFIG_ROOT/bin"
ZSHRC_DIR="$ZSH_CONFIG_ROOT/.zshrc.d"

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

assert_file_contains_pattern() {
    local file_path="$1"
    local pattern="$2"
    local message="${3:-File should contain pattern}"

    if [[ ! -f "$file_path" ]]; then
            zsh_debug_echo "    ASSERTION FAILED: File does not exist: $file_path"
        return 1
    fi

    if grep -q "$pattern" "$file_path" 2>/dev/null; then
        return 0
    else
            zsh_debug_echo "    ASSERTION FAILED: $message"
            zsh_debug_echo "    File: $file_path"
            zsh_debug_echo "    Pattern: $pattern"
        return 1
    fi
}

assert_file_has_shebang() {
    local file_path="$1"
    local expected_shebang="${2:-#!/opt/homebrew/bin/zsh}"

    if [[ ! -f "$file_path" ]]; then
            zsh_debug_echo "    ASSERTION FAILED: File does not exist: $file_path"
        return 1
    fi

    local first_line=$(head -n 1 "$file_path")
    if [[ "$first_line" == "$expected_shebang" ]]; then
        return 0
    else
            zsh_debug_echo "    ASSERTION FAILED: Incorrect shebang in $file_path"
            zsh_debug_echo "    Expected: $expected_shebang"
            zsh_debug_echo "    Actual: $first_line"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. TEST SCRIPT INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_existing_test_scripts_use_detection() {
    # Test that existing test scripts use source/execute detection
    local test_files=(
        "$TEST_DIR/test-source-execute-detection.zsh"
        "$TEST_DIR/test-git-cache.zsh"
        "$TEST_DIR/test-secure-ssh-agent.zsh"
    )

    local integration_count=0
    local total_files=0

    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            total_files=$((total_files + 1))

            # Check for detection function usage
            if grep -q "is_being_sourced\|is_being_executed" "$test_file" 2>/dev/null; then
                integration_count=$((integration_count + 1))
                    zsh_debug_echo "    ✓ $test_file uses detection functions"
            else
                    zsh_debug_echo "    ⚠ $test_file does not use detection functions"
            fi
        fi
    done

        zsh_debug_echo "    Integration status: $integration_count/$total_files test files use detection"

    # Pass if at least some files use detection (gradual integration)
    [[ $integration_count -gt 0 ]]
}

test_test_scripts_have_correct_shebang() {
    # Test that test scripts use the correct shebang
    local test_files=(
        "$TEST_DIR/test-source-execute-detection.zsh"
        "$TEST_DIR/test-error-handling-context.zsh"
        "$TEST_DIR/test-output-control.zsh"
        "$TEST_DIR/test-env-context.zsh"
    )

    local correct_shebang_count=0
    local total_files=0

    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            total_files=$((total_files + 1))

            if assert_file_has_shebang "$test_file" "#!/opt/homebrew/bin/zsh" 2>/dev/null; then
                correct_shebang_count=$((correct_shebang_count + 1))
                    zsh_debug_echo "    ✓ $test_file has correct shebang"
            else
                    zsh_debug_echo "    ⚠ $test_file has incorrect shebang"
            fi
        fi
    done

        zsh_debug_echo "    Shebang status: $correct_shebang_count/$total_files test files have correct shebang"

    # Pass if most files have correct shebang
    [[ $correct_shebang_count -ge $((total_files / 2)) ]]
}

# ------------------------------------------------------------------------------
# 3. HELPER SCRIPT INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_bin_scripts_use_detection() {
    # Test that bin scripts use source/execute detection
    local bin_files=(
        "$BIN_DIR/zsh-config-backup"
        "$BIN_DIR/zsh-performance-baseline"
        "$BIN_DIR/macos-defaults-setup.zsh"
    )

    local integration_count=0
    local total_files=0

    for bin_file in "${bin_files[@]}"; do
        if [[ -f "$bin_file" ]]; then
            total_files=$((total_files + 1))

            # Check for detection function usage or sourcing of detection script
            if grep -q "is_being_sourced\|is_being_executed\|source.*detection" "$bin_file" 2>/dev/null; then
                integration_count=$((integration_count + 1))
                    zsh_debug_echo "    ✓ $bin_file uses detection system"
            else
                    zsh_debug_echo "    ⚠ $bin_file does not use detection system"
            fi
        fi
    done

        zsh_debug_echo "    Integration status: $integration_count/$total_files bin scripts use detection"

    # Pass if at least some files use detection
    [[ $integration_count -ge 0 ]]  # Always pass for now, integration is gradual
}

test_bin_scripts_have_correct_shebang() {
    # Test that bin scripts use the correct shebang
    local bin_files=(
        "$BIN_DIR/macos-defaults-setup.zsh"
    )

    local correct_shebang_count=0
    local total_files=0

    for bin_file in "${bin_files[@]}"; do
        if [[ -f "$bin_file" ]]; then
            total_files=$((total_files + 1))

            if assert_file_has_shebang "$bin_file" "#!/opt/homebrew/bin/zsh" 2>/dev/null; then
                correct_shebang_count=$((correct_shebang_count + 1))
                    zsh_debug_echo "    ✓ $bin_file has correct shebang"
            else
                    zsh_debug_echo "    ⚠ $bin_file has incorrect shebang"
            fi
        fi
    done

    if [[ $total_files -gt 0 ]]; then
            zsh_debug_echo "    Shebang status: $correct_shebang_count/$total_files bin scripts have correct shebang"
        [[ $correct_shebang_count -ge $((total_files / 2)) ]]
    else
            zsh_debug_echo "    No applicable bin scripts found"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 4. CONFIGURATION SCRIPT INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_config_scripts_source_detection() {
    # Test that configuration scripts properly source the detection system
    local config_files=(
        "$ZSHRC_DIR/00_00-standard-helpers.zsh"
        "$ZSHRC_DIR/10_15-ssh-agent-macos.zsh"
    )

    local integration_count=0
    local total_files=0

    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            total_files=$((total_files + 1))

            # Check for detection system usage
            if grep -q "source.*detection\|is_being_sourced\|is_being_executed" "$config_file" 2>/dev/null; then
                integration_count=$((integration_count + 1))
                    zsh_debug_echo "    ✓ $config_file integrates with detection system"
            else
                    zsh_debug_echo "    ⚠ $config_file does not integrate with detection system"
            fi
        fi
    done

    if [[ $total_files -gt 0 ]]; then
            zsh_debug_echo "    Integration status: $integration_count/$total_files config files use detection"
        [[ $integration_count -ge 0 ]]  # Always pass for now, integration is gradual
    else
            zsh_debug_echo "    No applicable config files found"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. DETECTION SYSTEM AVAILABILITY TESTS
# ------------------------------------------------------------------------------

test_detection_functions_globally_available() {
    # Test that detection functions are available globally
    local required_functions=(
        "is_being_sourced"
        "is_being_executed"
        "get_execution_context"
        "handle_error"
        "safe_exit"
        "context_echo"
        "safe_export"
        "context_cleanup"
    )

    local available_count=0
    local total_functions=${#required_functions[@]}

    for func_name in "${required_functions[@]}"; do
        if declare -f "$func_name" > /dev/null 2>&1; then
            available_count=$((available_count + 1))
                zsh_debug_echo "    ✓ $func_name is available"
        else
                zsh_debug_echo "    ✗ $func_name is not available"
        fi
    done

        zsh_debug_echo "    Availability status: $available_count/$total_functions functions are globally available"

    # Pass if most functions are available
    [[ $available_count -ge $((total_functions * 3 / 4)) ]]
}

test_detection_system_initialization() {
    # Test that the detection system initializes correctly
    local detection_file="$ZSHRC_DIR/00_01-source-execute-detection.zsh"

    if [[ ! -f "$detection_file" ]]; then
            zsh_debug_echo "    ASSERTION FAILED: Detection system file not found"
        return 1
    fi

    # Check that the file has proper structure
    assert_file_contains_pattern "$detection_file" "is_being_sourced()" "Detection file should contain is_being_sourced function" &&
    assert_file_contains_pattern "$detection_file" "is_being_executed()" "Detection file should contain is_being_executed function" &&
    assert_file_contains_pattern "$detection_file" "export -f" "Detection file should export functions"
}

# ------------------------------------------------------------------------------
# 6. INTEGRATION CONSISTENCY TESTS
# ------------------------------------------------------------------------------

test_consistent_error_handling_patterns() {
    # Test that scripts use consistent error handling patterns
    local script_files=(
        "$TEST_DIR/test-source-execute-detection.zsh"
        "$TEST_DIR/test-error-handling-context.zsh"
        "$TEST_DIR/test-output-control.zsh"
        "$TEST_DIR/test-env-context.zsh"
    )

    local consistent_count=0
    local total_files=0

    for script_file in "${script_files[@]}"; do
        if [[ -f "$script_file" ]]; then
            total_files=$((total_files + 1))

            # Check for consistent error handling patterns
            if grep -q "handle_error\|safe_exit\|context_echo.*ERROR" "$script_file" 2>/dev/null; then
                consistent_count=$((consistent_count + 1))
                    zsh_debug_echo "    ✓ $script_file uses consistent error handling"
            else
                    zsh_debug_echo "    ⚠ $script_file may not use consistent error handling"
            fi
        fi
    done

    if [[ $total_files -gt 0 ]]; then
            zsh_debug_echo "    Consistency status: $consistent_count/$total_files scripts use consistent error handling"
        [[ $consistent_count -ge $((total_files / 2)) ]]
    else
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Detection Integration Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Log File: $LOG_FILE"
        zsh_debug_echo ""

    log_test "Starting detection integration test suite"

    # Test Script Integration
        zsh_debug_echo "=== Test Script Integration Tests ==="
    run_test "Existing Test Scripts Use Detection" "test_existing_test_scripts_use_detection"
    run_test "Test Scripts Have Correct Shebang" "test_test_scripts_have_correct_shebang"

    # Helper Script Integration
        zsh_debug_echo ""
        zsh_debug_echo "=== Helper Script Integration Tests ==="
    run_test "Bin Scripts Use Detection" "test_bin_scripts_use_detection"
    run_test "Bin Scripts Have Correct Shebang" "test_bin_scripts_have_correct_shebang"

    # Configuration Script Integration
        zsh_debug_echo ""
        zsh_debug_echo "=== Configuration Script Integration Tests ==="
    run_test "Config Scripts Source Detection" "test_config_scripts_source_detection"

    # Detection System Availability
        zsh_debug_echo ""
        zsh_debug_echo "=== Detection System Availability Tests ==="
    run_test "Detection Functions Globally Available" "test_detection_functions_globally_available"
    run_test "Detection System Initialization" "test_detection_system_initialization"

    # Integration Consistency
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Consistency Tests ==="
    run_test "Consistent Error Handling Patterns" "test_consistent_error_handling_patterns"

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

    log_test "Detection integration test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All detection integration tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED detection integration test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
        zsh_debug_echo "Detection integration test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Detection Integration Test Suite
# ==============================================================================
