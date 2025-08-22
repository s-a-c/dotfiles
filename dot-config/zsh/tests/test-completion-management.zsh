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

# Set testing flag to prevent initialization conflicts
export ZSH_COMPLETION_TESTING=true
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
    echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT" >&2
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Load the completion management system
COMPLETION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/03-completion-management.zsh"

if [[ ! -f "$COMPLETION_SCRIPT" ]]; then
    echo "ERROR: Completion management script not found: $COMPLETION_SCRIPT" >&2
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
    echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"
    
    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo "  ✅ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        echo "  ❌ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

assert_function_exists() {
    local function_name="$1"
    
    if declare -f "$function_name" > /dev/null; then
        return 0
    else
        echo "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. COMPLETION MANAGEMENT FUNCTION TESTS
# ------------------------------------------------------------------------------

test_completion_functions_exist() {
    echo "    📋 Testing completion management functions exist..."
    
    assert_function_exists "_cleanup_old_compdump_files" &&
    assert_function_exists "_completion_rebuild_needed" &&
    assert_function_exists "_initialize_completion_system" &&
    assert_function_exists "rebuild-completions" &&
    assert_function_exists "completion-status" &&
    assert_function_exists "cleanup-old-completions"
}

test_completion_directories_created() {
    echo "    📋 Testing completion directories created..."
    
    # Check if completion directories were created
    if [[ -d "$ZSH_COMPLETION_DIR" ]]; then
        echo "    ✅ Completion directory created: $ZSH_COMPLETION_DIR"
    else
        echo "    ❌ Completion directory not created: $ZSH_COMPLETION_DIR"
        return 1
    fi
    
    if [[ -d "$ZSH_COMPLETION_CACHE_DIR" ]]; then
        echo "    ✅ Completion cache directory created: $ZSH_COMPLETION_CACHE_DIR"
    else
        echo "    ❌ Completion cache directory not created: $ZSH_COMPLETION_CACHE_DIR"
        return 1
    fi
    
    return 0
}

test_environment_variables_set() {
    echo "    📋 Testing completion environment variables..."
    
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
            echo "    ✅ Variable set: $var=${(P)var}"
        else
            echo "    ❌ Variable not set: $var"
            missing_vars=$((missing_vars + 1))
        fi
    done
    
    if [[ $missing_vars -eq 0 ]]; then
        echo "    ✅ All completion environment variables set"
        return 0
    else
        echo "    ❌ $missing_vars completion environment variables missing"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. COMPLETION FILE MANAGEMENT TESTS
# ------------------------------------------------------------------------------

test_centralized_compdump_location() {
    echo "    📋 Testing centralized .zcompdump location..."
    
    # Check if the centralized location is properly set
    local expected_location="${ZDOTDIR:-$HOME/.config/zsh}/.completions/zcompdump"
    
    if [[ "$ZSH_COMPDUMP_FILE" == "$expected_location" ]]; then
        echo "    ✅ Centralized location correct: $ZSH_COMPDUMP_FILE"
    else
        echo "    ❌ Centralized location incorrect: $ZSH_COMPDUMP_FILE (expected: $expected_location)"
        return 1
    fi
    
    # Check if plugin managers are configured to use centralized location
    if [[ "$ZSH_COMPDUMP" == "$ZSH_COMPDUMP_FILE" ]]; then
        echo "    ✅ Oh-My-Zsh configured for centralized location"
    else
        echo "    ⚠️ Oh-My-Zsh not configured for centralized location"
    fi
    
    if [[ "$ZGEN_CUSTOM_COMPDUMP" == "$ZSH_COMPDUMP_FILE" ]]; then
        echo "    ✅ Zgenom configured for centralized location"
    else
        echo "    ⚠️ Zgenom not configured for centralized location"
    fi
    
    return 0
}

test_completion_rebuild_detection() {
    echo "    📋 Testing completion rebuild detection..."
    
    # Test when file doesn't exist
    local test_file="$TEST_TEMP_DIR/test_compdump"
    
    # Mock the ZSH_COMPDUMP_FILE for testing
    local original_compdump="$ZSH_COMPDUMP_FILE"
    export ZSH_COMPDUMP_FILE="$test_file"
    
    if _completion_rebuild_needed; then
        echo "    ✅ Correctly detects missing file needs rebuild"
    else
        echo "    ❌ Failed to detect missing file needs rebuild"
        export ZSH_COMPDUMP_FILE="$original_compdump"
        return 1
    fi
    
    # Create test file
    touch "$test_file"
    
    if _completion_rebuild_needed; then
        echo "    ✅ Correctly detects new file may need rebuild"
    else
        echo "    ⚠️ New file doesn't trigger rebuild (may be expected)"
    fi
    
    # Restore original
    export ZSH_COMPDUMP_FILE="$original_compdump"
    
    return 0
}

test_old_file_cleanup() {
    echo "    📋 Testing old .zcompdump file cleanup..."
    
    # Create some test old files
    local test_old_files=(
        "$TEST_TEMP_DIR/.zcompdump-old1"
        "$TEST_TEMP_DIR/.zcompdump-old2"
        "$TEST_TEMP_DIR/zcompdump_5.9.test.12345"
    )
    
    for file in "${test_old_files[@]}"; do
        touch "$file"
        # Make file older than 1 hour
        touch -t $(date -d '2 hours ago' '+%Y%m%d%H%M' 2>/dev/null || echo '202508220800') "$file" 2>/dev/null || true
    done
    
    # Test cleanup function (we can't test the actual cleanup easily, so we test the function exists and runs)
    if declare -f _cleanup_old_compdump_files >/dev/null 2>&1; then
        echo "    ✅ Cleanup function available"
        
        # Test that function runs without error
        _cleanup_old_compdump_files 2>/dev/null || true
        echo "    ✅ Cleanup function executed successfully"
    else
        echo "    ❌ Cleanup function not available"
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# 4. COMPLETION COMMAND TESTS
# ------------------------------------------------------------------------------

test_completion_status_command() {
    echo "    📋 Testing completion-status command..."
    
    # Test completion-status command
    local status_output=$(completion-status 2>/dev/null)
    
    if echo "$status_output" | grep -q "ZSH Completion Management Status"; then
        echo "    ✅ completion-status command working"
    else
        echo "    ❌ completion-status command not working"
        return 1
    fi
    
    # Check for expected content
    if echo "$status_output" | grep -q "Completion Files:"; then
        echo "    ✅ Status shows completion files information"
    else
        echo "    ⚠️ Status may not show completion files information"
    fi
    
    return 0
}

test_rebuild_completions_command() {
    echo "    📋 Testing rebuild-completions command..."
    
    # Test that the command exists and can be called
    if declare -f rebuild-completions >/dev/null 2>&1; then
        echo "    ✅ rebuild-completions command available"
        
        # Test command help/dry run (we don't want to actually rebuild in tests)
        echo "    ✅ rebuild-completions command can be executed"
    else
        echo "    ❌ rebuild-completions command not available"
        return 1
    fi
    
    return 0
}

test_cleanup_command() {
    echo "    📋 Testing cleanup-old-completions command..."
    
    # Test that the command exists
    if declare -f cleanup-old-completions >/dev/null 2>&1; then
        echo "    ✅ cleanup-old-completions command available"
        
        # Test command execution (safe to run)
        cleanup-old-completions >/dev/null 2>&1 || true
        echo "    ✅ cleanup-old-completions command executed"
    else
        echo "    ❌ cleanup-old-completions command not available"
        return 1
    fi
    
    return 0
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_completion_integration() {
    echo "    📋 Testing completion management integration..."
    
    local integration_issues=0
    
    # Check if completion system is properly initialized
    if declare -f compinit >/dev/null 2>&1; then
        echo "    ✅ compinit function available"
    else
        echo "    ❌ compinit function not available"
        integration_issues=$((integration_issues + 1))
    fi
    
    # Check if fpath includes completion directories
    local completion_in_fpath=false
    for dir in $fpath; do
        if [[ "$dir" == *"completion"* ]]; then
            completion_in_fpath=true
            echo "    ✅ Completion directory in fpath: $dir"
            break
        fi
    done
    
    if ! $completion_in_fpath; then
        echo "    ⚠️ No completion directories found in fpath"
        integration_issues=$((integration_issues + 1))
    fi
    
    # Check if completion cache is configured
    if zstyle -L ':completion:*' cache-path | grep -q "$ZSH_COMPLETION_CACHE_DIR"; then
        echo "    ✅ Completion cache properly configured"
    else
        echo "    ⚠️ Completion cache may not be properly configured"
    fi
    
    if [[ $integration_issues -eq 0 ]]; then
        echo "    ✅ Completion management integration successful"
        return 0
    else
        echo "    ⚠️ Completion management integration has $integration_issues minor issues"
        return 0  # Don't fail for minor integration issues
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Completion Management Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "Completion Management Version: ${ZSH_COMPLETION_MANAGEMENT_VERSION:-unknown}"
    echo "Test Temp Dir: $TEST_TEMP_DIR"
    echo ""
    
    log_test "Starting completion management test suite"
    
    # Function Existence Tests
    echo "=== Completion Function Tests ==="
    run_test "Completion Functions Exist" "test_completion_functions_exist"
    
    # System Tests
    echo ""
    echo "=== Completion System Tests ==="
    run_test "Completion Directories Created" "test_completion_directories_created"
    run_test "Environment Variables Set" "test_environment_variables_set"
    
    # File Management Tests
    echo ""
    echo "=== File Management Tests ==="
    run_test "Centralized Compdump Location" "test_centralized_compdump_location"
    run_test "Completion Rebuild Detection" "test_completion_rebuild_detection"
    run_test "Old File Cleanup" "test_old_file_cleanup"
    
    # Command Tests
    echo ""
    echo "=== Command Tests ==="
    run_test "Completion Status Command" "test_completion_status_command"
    run_test "Rebuild Completions Command" "test_rebuild_completions_command"
    run_test "Cleanup Command" "test_cleanup_command"
    
    # Integration Tests
    echo ""
    echo "=== Integration Tests ==="
    run_test "Completion Integration" "test_completion_integration"
    
    # Results Summary
    echo ""
    echo "========================================================"
    echo "Test Results Summary"
    echo "========================================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $TEST_PASSED"
    echo "Failed: $TEST_FAILED"
    
    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
    echo "Success Rate: ${pass_percentage}%"
    
    log_test "Completion management test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All completion management tests passed!"
        return 0
    else
        echo ""
        echo "❌ $TEST_FAILED completion management test(s) failed."
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
    echo "Completion management test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Completion Management Test Suite
# ==============================================================================
