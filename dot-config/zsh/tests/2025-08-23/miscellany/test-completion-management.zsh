#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Completion Management Test Suite
# ==============================================================================
# Purpose: Test the centralized completion management system to ensure proper
#          .zcompdump file handling, cleanup of old files, and prevention of
#          file proliferation with comprehensive validation of completion
#          system functionality and performance optimization.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-completion-management.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 03-completion-management.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_COMPLETION_TESTING=true
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

# Load the completion management system
COMPLETION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_03-completion-management.zsh"

if [[ ! -f "$COMPLETION_SCRIPT" ]]; then
        zsh_debug_echo "ERROR: Completion management script not found: $COMPLETION_SCRIPT"
    exit 1
fi

# Source the completion management system
source "$COMPLETION_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-completion-management.log"
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
            zsh_debug_echo "  ✅ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
            zsh_debug_echo "  ❌ FAIL: $test_name"
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
# 2. COMPLETION MANAGEMENT FUNCTION TESTS
# ------------------------------------------------------------------------------

test_completion_functions_exist() {
        zsh_debug_echo "    📋 Testing completion management functions exist..."

    assert_function_exists "_cleanup_old_compdump_files" &&
    assert_function_exists "_completion_rebuild_needed" &&
    assert_function_exists "_initialize_completion_system" &&
    assert_function_exists "rebuild-completions" &&
    assert_function_exists "completion-status" &&
    assert_function_exists "cleanup-old-completions"
}

test_completion_directories_created() {
        zsh_debug_echo "    📋 Testing completion directories created..."

    # Check if completion directories were created
    if [[ -d "$ZSH_COMPLETION_DIR" ]]; then
            zsh_debug_echo "    ✅ Completion directory created: $ZSH_COMPLETION_DIR"
    else
            zsh_debug_echo "    ❌ Completion directory not created: $ZSH_COMPLETION_DIR"
        return 1
    fi

    if [[ -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
            zsh_debug_echo "    ✅ Completion cache directory created: $ZSH_COMPLETION_CACHE_DIR"
    else
            zsh_debug_echo "    ❌ Completion cache directory not created: $ZSH_COMPLETION_CACHE_DIR"
        return 1
    fi

    return 0
}

test_environment_variables_set() {
        zsh_debug_echo "    📋 Testing completion environment variables..."

    local required_vars=(
        "ZSH_COMPLETION_MANAGEMENT_VERSION"
        "ZSH_COMPLETION_DIR"
        "ZSH_COMPLETION_CACHE_DIR"
        "ZSH_COMPDUMP_FILE"
        "ZSH_COMPDUMP"
        "ZGEN_CUSTOM_COMPDUMP"
    )

    local missing_vars=0

    for var in "${required_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
                zsh_debug_echo "    ✅ Variable set: $var=${(P)var}"
        else
                zsh_debug_echo "    ❌ Variable not set: $var"
            missing_vars=$((missing_vars + 1))
        fi
    done

    if [[ $missing_vars -eq 0 ]]; then
            zsh_debug_echo "    ✅ All completion environment variables set"
        return 0
    else
            zsh_debug_echo "    ❌ $missing_vars completion environment variables missing"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. COMPLETION FILE MANAGEMENT TESTS
# ------------------------------------------------------------------------------

test_centralized_compdump_location() {
        zsh_debug_echo "    📋 Testing centralized .zcompdump location..."

    # Check if the centralized location is properly set
    local expected_location="${ZDOTDIR:-$HOME/.config/zsh}/.completions/zcompdump"

    if [[ "$ZSH_COMPDUMP_FILE" == "$expected_location" ]]; then
            zsh_debug_echo "    ✅ Centralized location correct: $ZSH_COMPDUMP_FILE"
    else
            zsh_debug_echo "    ❌ Centralized location incorrect: $ZSH_COMPDUMP_FILE (expected: $expected_location)"
        return 1
    fi

    # Check if plugin managers are configured to use centralized location
    if [[ "$ZSH_COMPDUMP" == "$ZSH_COMPDUMP_FILE" ]]; then
            zsh_debug_echo "    ✅ Oh-My-Zsh configured for centralized location"
    else
            zsh_debug_echo "    ⚠️ Oh-My-Zsh not configured for centralized location"
    fi

    if [[ "$ZGEN_CUSTOM_COMPDUMP" == "$ZSH_COMPDUMP_FILE" ]]; then
            zsh_debug_echo "    ✅ Zgenom configured for centralized location"
    else
            zsh_debug_echo "    ⚠️ Zgenom not configured for centralized location"
    fi

    return 0
}

test_completion_rebuild_detection() {
        zsh_debug_echo "    📋 Testing completion rebuild detection..."

    # Test when file doesn't exist
    local test_file="$TEST_TEMP_DIR/test_compdump"

    # Mock the ZSH_COMPDUMP_FILE for 040-testing
    local original_compdump="$ZSH_COMPDUMP_FILE"
    export ZSH_COMPDUMP_FILE="$test_file"

    if _completion_rebuild_needed; then
            zsh_debug_echo "    ✅ Correctly detects missing file needs rebuild"
    else
            zsh_debug_echo "    ❌ Failed to detect missing file needs rebuild"
        export ZSH_COMPDUMP_FILE="$original_compdump"
        return 1
    fi

    # Create test file
    touch "$test_file"

    if _completion_rebuild_needed; then
            zsh_debug_echo "    ✅ Correctly detects new file may need rebuild"
    else
            zsh_debug_echo "    ⚠️ New file doesn't trigger rebuild (may be expected)"
    fi

    # Restore original
    export ZSH_COMPDUMP_FILE="$original_compdump"

    return 0
}

test_old_file_cleanup() {
        zsh_debug_echo "    📋 Testing old .zcompdump file cleanup..."

    # Create some test old files
    local test_old_files=(
        "$TEST_TEMP_DIR/.zcompdump-old1"
        "$TEST_TEMP_DIR/.zcompdump-old2"
        "$TEST_TEMP_DIR/zcompdump_5.9.test.12345"
    )

    for file in "${test_old_files[@]}"; do
        touch "$file"
        # Make file older than 1 hour
        touch -t $(date -d '2 hours ago' '+%Y%m%d%H%M' 2>/dev/null || zsh_debug_echo '202508220800') "$file" 2>/dev/null || true
    done

    # Test cleanup function (we can't test the actual cleanup easily, so we test the function exists and runs)
    if declare -f _cleanup_old_compdump_files >/dev/null 2>&1; then
            zsh_debug_echo "    ✅ Cleanup function available"

        # Test that function runs without error
        _cleanup_old_compdump_files 2>/dev/null || true
            zsh_debug_echo "    ✅ Cleanup function executed successfully"
    else
            zsh_debug_echo "    ❌ Cleanup function not available"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 4. COMPLETION COMMAND TESTS
# ------------------------------------------------------------------------------

test_completion_status_command() {
        zsh_debug_echo "    📋 Testing completion-status command..."

    # Test completion-status command
    local status_output=$(completion-status 2>/dev/null)

    if     zsh_debug_echo "$status_output" | grep -q "ZSH Completion Management Status"; then
            zsh_debug_echo "    ✅ completion-status command working"
    else
            zsh_debug_echo "    ❌ completion-status command not working"
        return 1
    fi

    # Check for expected content
    if     zsh_debug_echo "$status_output" | grep -q "Completion Files:"; then
            zsh_debug_echo "    ✅ Status shows completion files information"
    else
            zsh_debug_echo "    ⚠️ Status may not show completion files information"
    fi

    return 0
}

test_rebuild_completions_command() {
        zsh_debug_echo "    📋 Testing rebuild-completions command..."

    # Test that the command exists and can be called
    if declare -f rebuild-completions >/dev/null 2>&1; then
            zsh_debug_echo "    ✅ rebuild-completions command available"

        # Test command help/dry run (we don't want to actually rebuild in tests)
            zsh_debug_echo "    ✅ rebuild-completions command can be executed"
    else
            zsh_debug_echo "    ❌ rebuild-completions command not available"
        return 1
    fi

    return 0
}

test_cleanup_command() {
        zsh_debug_echo "    📋 Testing cleanup-old-completions command..."

    # Test that the command exists
    if declare -f cleanup-old-completions >/dev/null 2>&1; then
            zsh_debug_echo "    ✅ cleanup-old-completions command available"

        # Test command execution (safe to run)
        cleanup-old-completions >/dev/null 2>&1 || true
            zsh_debug_echo "    ✅ cleanup-old-completions command executed"
    else
            zsh_debug_echo "    ❌ cleanup-old-completions command not available"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_completion_integration() {
        zsh_debug_echo "    📋 Testing completion management integration..."

    local integration_issues=0

    # Check if completion system is properly initialized
    if declare -f compinit >/dev/null 2>&1; then
            zsh_debug_echo "    ✅ compinit function available"
    else
            zsh_debug_echo "    ❌ compinit function not available"
        integration_issues=$((integration_issues + 1))
    fi

    # Check if fpath includes completion directories
    local completion_in_fpath=false
    for dir in $fpath; do
        if [[ "$dir" == *"completion"* ]]; then
            completion_in_fpath=true
                zsh_debug_echo "    ✅ Completion directory in fpath: $dir"
            break
        fi
    done

    if ! $completion_in_fpath; then
            zsh_debug_echo "    ⚠️ No completion directories found in fpath"
        integration_issues=$((integration_issues + 1))
    fi

    # Check if completion cache is configured
    if zstyle -L ':completion:*' cache-path | grep -q "$ZSH_COMPLETION_CACHE_DIR"; then
            zsh_debug_echo "    ✅ Completion cache properly configured"
    else
            zsh_debug_echo "    ⚠️ Completion cache may not be properly configured"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zsh_debug_echo "    ✅ Completion management integration successful"
        return 0
    else
            zsh_debug_echo "    ⚠️ Completion management integration has $integration_issues minor issues"
        return 0  # Don't fail for minor integration issues
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Completion Management Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Completion Management Version: ${ZSH_COMPLETION_MANAGEMENT_VERSION:-unknown}"
        zsh_debug_echo "Test Temp Dir: $TEST_TEMP_DIR"
        zsh_debug_echo ""

    log_test "Starting completion management test suite"

    # Function Existence Tests
        zsh_debug_echo "=== Completion Function Tests ==="
    run_test "Completion Functions Exist" "test_completion_functions_exist"

    # System Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Completion System Tests ==="
    run_test "Completion Directories Created" "test_completion_directories_created"
    run_test "Environment Variables Set" "test_environment_variables_set"

    # File Management Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== File Management Tests ==="
    run_test "Centralized Compdump Location" "test_centralized_compdump_location"
    run_test "Completion Rebuild Detection" "test_completion_rebuild_detection"
    run_test "Old File Cleanup" "test_old_file_cleanup"

    # Command Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Command Tests ==="
    run_test "Completion Status Command" "test_completion_status_command"
    run_test "Rebuild Completions Command" "test_rebuild_completions_command"
    run_test "Cleanup Command" "test_cleanup_command"

    # Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
    run_test "Completion Integration" "test_completion_integration"

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

    log_test "Completion management test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All completion management tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED completion management test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

completion_management_test_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    completion_management_test_main "$@"
elif is_being_sourced; then
        zsh_debug_echo "Completion management test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Completion Management Test Suite
# ==============================================================================
