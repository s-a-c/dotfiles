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
    export LOG_DIR="/Users/s-a-c/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/test-project-setup_$log_time.log"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Start logging
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "🧪 Testing ZSH Configuration Implementation Project Setup"
    echo "======================================================"
    echo "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "📋 Log File: $LOG_FILE"
    echo ""
    
    local base_dir="/Users/s-a-c/.config/zsh"
    export ZSH_CONFIG_BASE="$base_dir"
    export TESTS_PASSED=0
    export TESTS_FAILED=0
}

# Test directory structure creation
_test_directory_structure() {
    echo "\n1. Testing directory structure creation..."
    
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
            echo "   ✅ Directory exists: $dir"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Directory missing: $dir"
            ((TESTS_FAILED++))
        fi
    done
}

# Test directory permissions
_test_directory_permissions() {
    echo "\n2. Testing directory permissions..."
    
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
            echo "   ✅ Directory permissions OK: $dir"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Directory permissions incorrect: $dir"
            ((TESTS_FAILED++))
        fi
    done
}

# Test implementation tracking file creation
_test_implementation_tracking() {
    echo "\n3. Testing implementation tracking setup..."
    
    local plan_file="$ZSH_CONFIG_BASE/docs/zsh-improvement-implementation-plan-2025-08-20.md"
    
    if [[ -f "$plan_file" ]]; then
        echo "   ✅ Implementation plan exists: $plan_file"
        ((TESTS_PASSED++))
        
        # Check if file contains the tracking table
        if grep -q "Implementation Tracking Table" "$plan_file"; then
            echo "   ✅ Implementation tracking table found"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Implementation tracking table not found"
            ((TESTS_FAILED++))
        fi
        
        # Check if file contains success criteria
        if grep -q "Success Criteria" "$plan_file"; then
            echo "   ✅ Success criteria section found"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Success criteria section not found"
            ((TESTS_FAILED++))
        fi
    else
        echo "   ❌ Implementation plan missing: $plan_file"
        ((TESTS_FAILED++))
    fi
}

# Test cleanup
_test_cleanup() {
    echo "\n🏁 Test Results Summary"
    echo "======================"
    echo "✅ Tests Passed: $TESTS_PASSED"
    echo "❌ Tests Failed: $TESTS_FAILED"
    echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || echo "Warning: Could not restore original directory: $ORIGINAL_CWD" >&2
    fi
    
    if (( TESTS_FAILED == 0 )); then
        echo "\n🎉 All project setup tests passed!"
        echo "✅ Task 1.1 (Create implementation workspace directories) - COMPLETE"
        return 0
    else
        echo "\n⚠️  Some project setup tests failed"
        echo "❌ Task 1.1 needs attention"
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

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
