#!/usr/bin/env zsh
#=============================================================================
# File: test-project-setup.zsh
# Purpose: Verify project setup workspace directories are created correctly
# Dependencies: None
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# Test setup and initialization
_test_setup() {
    # Save current working directory
    export ORIGINAL_CWD="$(pwd)"

    # Setup logging
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    export LOG_DIR="${HOME}/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/test-project-setup_$log_time.log"

    # Create log directory
    mkdir -p "$LOG_DIR"

    # Start logging
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)

        zf::debug "🧪 Testing ZSH Configuration Implementation Project Setup"
        zf::debug "======================================================"
        zf::debug "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zf::debug "📋 Log File: $LOG_FILE"
        zf::debug ""

    local base_dir="${HOME}/.config/zsh"
    export ZSH_CONFIG_BASE="$base_dir"
    export TESTS_PASSED=0
    export TESTS_FAILED=0
}

# Test directory structure creation
_test_directory_structure() {
        zf::debug "\n1. Testing directory structure creation..."

    local expected_dirs=(
        "$ZSH_CONFIG_BASE/docs/implementation"
        "$ZSH_CONFIG_BASE/tests/performance"
        "$ZSH_CONFIG_BASE/tests/security"
        "$ZSH_CONFIG_BASE/tests/consistency"
        "$ZSH_CONFIG_BASE/tests/validation"
        "$ZSH_CONFIG_BASE/tests/advanced"
        "$ZSH_CONFIG_BASE/tests/integration"
    )

    for dir in "${expected_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
                zf::debug "   ✅ Directory exists: $dir"
            ((TESTS_PASSED++))
        else
                zf::debug "   ❌ Directory missing: $dir"
            ((TESTS_FAILED++))
        fi
    done
}

# Test directory permissions
_test_directory_permissions() {
        zf::debug "\n2. Testing directory permissions..."

    local test_dirs=(
        "$ZSH_CONFIG_BASE/tests/performance"
        "$ZSH_CONFIG_BASE/tests/security"
        "$ZSH_CONFIG_BASE/tests/consistency"
        "$ZSH_CONFIG_BASE/tests/validation"
        "$ZSH_CONFIG_BASE/tests/advanced"
        "$ZSH_CONFIG_BASE/tests/integration"
    )

    for dir in "${test_dirs[@]}"; do
        if [[ -d "$dir" && -w "$dir" && -r "$dir" ]]; then
                zf::debug "   ✅ Directory permissions OK: $dir"
            ((TESTS_PASSED++))
        else
                zf::debug "   ❌ Directory permissions incorrect: $dir"
            ((TESTS_FAILED++))
        fi
    done
}

# Test implementation tracking file creation
_test_implementation_tracking() {
        zf::debug "\n3. Testing implementation tracking setup..."

    local plan_file="$ZSH_CONFIG_BASE/docs/zsh-improvement-implementation-plan-2025-08-20.md"

    if [[ -f "$plan_file" ]]; then
            zf::debug "   ✅ Implementation plan exists: $plan_file"
        ((TESTS_PASSED++))

        # Check if file contains the tracking table
        if grep -q "Implementation Tracking Table" "$plan_file"; then
                zf::debug "   ✅ Implementation tracking table found"
            ((TESTS_PASSED++))
        else
                zf::debug "   ❌ Implementation tracking table not found"
            ((TESTS_FAILED++))
        fi

        # Check if file contains success criteria
        if grep -q "Success Criteria" "$plan_file"; then
                zf::debug "   ✅ Success criteria section found"
            ((TESTS_PASSED++))
        else
                zf::debug "   ❌ Success criteria section not found"
            ((TESTS_FAILED++))
        fi
    else
            zf::debug "   ❌ Implementation plan missing: $plan_file"
        ((TESTS_FAILED++))
    fi
}

# Test cleanup
_test_cleanup() {
        zf::debug "\n🏁 Test Results Summary"
        zf::debug "======================"
        zf::debug "✅ Tests Passed: $TESTS_PASSED"
        zf::debug "❌ Tests Failed: $TESTS_FAILED"
        zf::debug "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || zf::debug "Warning: Could not restore original directory: $ORIGINAL_CWD"
    fi

    if (( TESTS_FAILED == 0 )); then
            zf::debug "\n🎉 All project setup tests passed!"
            zf::debug "✅ Task 1.1 (Create implementation workspace directories) - COMPLETE"
        return 0
    else
            zf::debug "\n⚠️  Some project setup tests failed"
            zf::debug "❌ Task 1.1 needs attention"
        return 1
    fi
}

# Main test execution
main() {
    _test_setup
    _test_directory_structure
    _test_directory_permissions
    _test_implementation_tracking
    _test_cleanup
}

[[ "${(%):-%N}" == "$0" ]] && main "$@"
