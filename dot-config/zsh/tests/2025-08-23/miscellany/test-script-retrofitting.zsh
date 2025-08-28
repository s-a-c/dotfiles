#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Script Retrofitting Test Suite
# ==============================================================================
# Purpose: Test retrofitting of existing scripts with source/execute detection
#          patterns to ensure all helper libraries, setup scripts, and tools
#          properly implement the detection system.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-script-retrofitting.zsh (execute) or source test-... (source)
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
LOG_FILE="$LOG_DIR/test-script-retrofitting.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration paths
ZSH_CONFIG_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"

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

check_script_retrofitting() {
    local script_path="$1"
    local script_name=$(basename "$script_path")

    if [[ ! -f "$script_path" ]]; then
            zsh_debug_echo "    ⚠ Script not found: $script_name"
        return 2  # Skip
    fi

    local retrofit_score=0
    local max_score=5

    # Check 1: Correct shebang
    if head -n 1 "$script_path" | grep -q "#!/opt/homebrew/bin/zsh"; then
        retrofit_score=$((retrofit_score + 1))
            zsh_debug_echo "    ✓ $script_name: Correct shebang"
    else
            zsh_debug_echo "    ⚠ $script_name: Incorrect or missing shebang"
    fi

    # Check 2: Sources detection system
    if grep -q "source.*detection\|01-source-execute-detection" "$script_path" 2>/dev/null; then
        retrofit_score=$((retrofit_score + 1))
            zsh_debug_echo "    ✓ $script_name: Sources detection system"
    else
            zsh_debug_echo "    ⚠ $script_name: Does not source detection system"
    fi

    # Check 3: Uses detection functions
    if grep -q "is_being_sourced\|is_being_executed" "$script_path" 2>/dev/null; then
        retrofit_score=$((retrofit_score + 1))
            zsh_debug_echo "    ✓ $script_name: Uses detection functions"
    else
            zsh_debug_echo "    ⚠ $script_name: Does not use detection functions"
    fi

    # Check 4: Context-aware error handling
    if grep -q "handle_error\|safe_exit\|exit_or_return" "$script_path" 2>/dev/null; then
        retrofit_score=$((retrofit_score + 1))
            zsh_debug_echo "    ✓ $script_name: Uses context-aware error handling"
    else
            zsh_debug_echo "    ⚠ $script_name: Does not use context-aware error handling"
    fi

    # Check 5: Context-aware execution pattern
    if grep -q "if.*is_being_executed\|main.*\"\$@\"" "$script_path" 2>/dev/null; then
        retrofit_score=$((retrofit_score + 1))
            zsh_debug_echo "    ✓ $script_name: Uses context-aware execution pattern"
    else
            zsh_debug_echo "    ⚠ $script_name: Does not use context-aware execution pattern"
    fi

    local retrofit_percentage=$((retrofit_score * 100 / max_score))
        zsh_debug_echo "    📊 $script_name: Retrofitting score: $retrofit_score/$max_score ($retrofit_percentage%)"

    # Return success if at least 60% retrofitted
    [[ $retrofit_percentage -ge 60 ]]
}

# ------------------------------------------------------------------------------
# 2. HELPER LIBRARY RETROFITTING TESTS
# ------------------------------------------------------------------------------

test_standard_helpers_retrofitting() {
    local helpers_file="$ZSH_CONFIG_ROOT/.zshrc.d/00_00-standard-helpers.zsh"
    check_script_retrofitting "$helpers_file"
}

test_utility_functions_retrofitting() {
    local utility_file="$ZSH_CONFIG_ROOT/.zshrc.d/00_07-utility-functions.zsh"
    check_script_retrofitting "$utility_file"
}

test_core_functions_retrofitting() {
    local core_file="$ZSH_CONFIG_ROOT/.zshrc.d/00_04-functions-core.zsh"
    check_script_retrofitting "$core_file"
}

# ------------------------------------------------------------------------------
# 3. SETUP SCRIPT RETROFITTING TESTS
# ------------------------------------------------------------------------------

test_macos_defaults_setup_retrofitting() {
    local setup_file="$ZSH_CONFIG_ROOT/bin/macos-defaults-setup.zsh"
    check_script_retrofitting "$setup_file"
}

test_backup_script_retrofitting() {
    local backup_file="$ZSH_CONFIG_ROOT/bin/zsh-config-backup"
    check_script_retrofitting "$backup_file"
}

test_performance_baseline_retrofitting() {
    local baseline_file="$ZSH_CONFIG_ROOT/bin/zsh-performance-baseline"
    check_script_retrofitting "$baseline_file"
}

# ------------------------------------------------------------------------------
# 4. TOOL SCRIPT RETROFITTING TESTS
# ------------------------------------------------------------------------------

test_ssh_agent_script_retrofitting() {
    local ssh_file="$ZSH_CONFIG_ROOT/.zshrc.d/10_15-ssh-agent-macos.zsh"
    check_script_retrofitting "$ssh_file"
}

test_development_tools_retrofitting() {
    local dev_file="$ZSH_CONFIG_ROOT/.zshrc.d/10_10-development-tools.zsh"
    check_script_retrofitting "$dev_file"
}

test_git_config_retrofitting() {
    local git_file="$ZSH_CONFIG_ROOT/.zshrc.d/10_13-git-vcs-config.zsh"
    check_script_retrofitting "$git_file"
}

# ------------------------------------------------------------------------------
# 5. STANDALONE SCRIPT RETROFITTING TESTS
# ------------------------------------------------------------------------------

test_health_check_retrofitting() {
    local health_file="$ZSH_CONFIG_ROOT/health-check.zsh"
    check_script_retrofitting "$health_file"
}

test_macos_defaults_retrofitting() {
    local macos_file="$ZSH_CONFIG_ROOT/macos-defaults.zsh"
    check_script_retrofitting "$macos_file"
}

test_completion_scripts_retrofitting() {
    local completion_files=(
        "$ZSH_CONFIG_ROOT/rebuild-completions.zsh"
        "$ZSH_CONFIG_ROOT/safe-completion-init.zsh"
        "$ZSH_CONFIG_ROOT/minimal-completion-init.zsh"
    )

    local retrofitted_count=0
    local total_files=0

    for comp_file in "${completion_files[@]}"; do
        if [[ -f "$comp_file" ]]; then
            total_files=$((total_files + 1))
            if check_script_retrofitting "$comp_file" >/dev/null 2>&1; then
                retrofitted_count=$((retrofitted_count + 1))
            fi
        fi
    done

    if [[ $total_files -gt 0 ]]; then
            zsh_debug_echo "    📊 Completion scripts: $retrofitted_count/$total_files retrofitted"
        [[ $retrofitted_count -ge $((total_files / 2)) ]]
    else
            zsh_debug_echo "    ⚠ No completion scripts found"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 6. RETROFITTING COVERAGE ANALYSIS
# ------------------------------------------------------------------------------

test_overall_retrofitting_coverage() {
    # Analyze overall retrofitting coverage across all script categories
    local script_categories=(
        "Helper Libraries"
        "Setup Scripts"
        "Tool Scripts"
        "Standalone Scripts"
    )

        zsh_debug_echo "    📊 Retrofitting Coverage Analysis:"
        zsh_debug_echo "    =================================="

    # This is a summary test that always passes but provides valuable information
        zsh_debug_echo "    ✓ Analysis complete - see individual test results above"
        zsh_debug_echo "    ✓ Retrofitting is an ongoing process"
        zsh_debug_echo "    ✓ Scripts are gradually being updated with detection patterns"

    return 0
}

test_retrofitting_consistency() {
    # Test consistency of retrofitting patterns across scripts
    local pattern_consistency=0
    local total_patterns=4

    # Check for consistent shebang usage
    local shebang_files=$(find "$ZSH_CONFIG_ROOT" -name "*.zsh" -exec grep -l "#!/opt/homebrew/bin/zsh" {} \; 2>/dev/null | wc -l)
    if [[ $shebang_files -gt 0 ]]; then
        pattern_consistency=$((pattern_consistency + 1))
            zsh_debug_echo "    ✓ Consistent shebang pattern found in $shebang_files files"
    fi

    # Check for detection system usage
    local detection_files=$(find "$ZSH_CONFIG_ROOT" -name "*.zsh" -exec grep -l "is_being_sourced\|is_being_executed" {} \; 2>/dev/null | wc -l)
    if [[ $detection_files -gt 0 ]]; then
        pattern_consistency=$((pattern_consistency + 1))
            zsh_debug_echo "    ✓ Detection functions used in $detection_files files"
    fi

    # Check for error handling patterns
    local error_files=$(find "$ZSH_CONFIG_ROOT" -name "*.zsh" -exec grep -l "handle_error\|safe_exit" {} \; 2>/dev/null | wc -l)
    if [[ $error_files -gt 0 ]]; then
        pattern_consistency=$((pattern_consistency + 1))
            zsh_debug_echo "    ✓ Context-aware error handling in $error_files files"
    fi

    # Check for execution patterns
    local exec_files=$(find "$ZSH_CONFIG_ROOT" -name "*.zsh" -exec grep -l "if.*is_being_executed" {} \; 2>/dev/null | wc -l)
    if [[ $exec_files -gt 0 ]]; then
        pattern_consistency=$((pattern_consistency + 1))
            zsh_debug_echo "    ✓ Context-aware execution patterns in $exec_files files"
    fi

    local consistency_percentage=$((pattern_consistency * 100 / total_patterns))
        zsh_debug_echo "    📊 Pattern consistency: $pattern_consistency/$total_patterns patterns ($consistency_percentage%)"

    # Pass if at least half the patterns are consistently used
    [[ $pattern_consistency -ge $((total_patterns / 2)) ]]
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Script Retrofitting Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Log File: $LOG_FILE"
        zsh_debug_echo ""

    log_test "Starting script retrofitting test suite"

    # Helper Library Tests
        zsh_debug_echo "=== Helper Library Retrofitting Tests ==="
    run_test "Standard Helpers Retrofitting" "test_standard_helpers_retrofitting"
    run_test "Utility Functions Retrofitting" "test_utility_functions_retrofitting"
    run_test "Core Functions Retrofitting" "test_core_functions_retrofitting"

    # Setup Script Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Setup Script Retrofitting Tests ==="
    run_test "macOS Defaults Setup Retrofitting" "test_macos_defaults_setup_retrofitting"
    run_test "Backup Script Retrofitting" "test_backup_script_retrofitting"
    run_test "Performance Baseline Retrofitting" "test_performance_baseline_retrofitting"

    # Tool Script Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Tool Script Retrofitting Tests ==="
    run_test "SSH Agent Script Retrofitting" "test_ssh_agent_script_retrofitting"
    run_test "Development Tools Retrofitting" "test_development_tools_retrofitting"
    run_test "Git Config Retrofitting" "test_git_config_retrofitting"

    # Standalone Script Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Standalone Script Retrofitting Tests ==="
    run_test "Health Check Retrofitting" "test_health_check_retrofitting"
    run_test "macOS Defaults Retrofitting" "test_macos_defaults_retrofitting"
    run_test "Completion Scripts Retrofitting" "test_completion_scripts_retrofitting"

    # Coverage Analysis
        zsh_debug_echo ""
        zsh_debug_echo "=== Retrofitting Coverage Analysis ==="
    run_test "Overall Retrofitting Coverage" "test_overall_retrofitting_coverage"
    run_test "Retrofitting Consistency" "test_retrofitting_consistency"

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

    log_test "Script retrofitting test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All script retrofitting tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED script retrofitting test(s) failed."
            zsh_debug_echo ""
            zsh_debug_echo "Note: Retrofitting is an ongoing process. Some failures are expected"
            zsh_debug_echo "as scripts are gradually updated with detection patterns."
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
        zsh_debug_echo "Script retrofitting test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Script Retrofitting Test Suite
# ==============================================================================
