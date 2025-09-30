#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Plugin Metadata Framework Test Suite
# ==============================================================================
# Purpose: Test the enhanced plugin metadata system to ensure proper dependency
#          resolution, conflict detection, plugin registration, and load order
#          management with comprehensive validation of the plugin framework.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-plugin-metadata.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 01-plugin-metadata.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_PLUGIN_TESTING=true
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

# Load the plugin metadata system
PLUGIN_METADATA_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/20_01-plugin-metadata.zsh"

if [[ ! -f "$PLUGIN_METADATA_SCRIPT" ]]; then
    zf::debug "ERROR: Plugin metadata script not found: $PLUGIN_METADATA_SCRIPT"
    exit 1
fi

# Source the plugin metadata system
source "$PLUGIN_METADATA_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-plugin-metadata.log"
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
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
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

    if declare -f "$function_name" >/dev/null; then
        return 0
    else
        zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. PLUGIN METADATA FUNCTION TESTS
# ------------------------------------------------------------------------------

test_plugin_metadata_functions_exist() {
    assert_function_exists "register_plugin" &&
        assert_function_exists "get_plugin_metadata" &&
        assert_function_exists "check_plugin_dependencies" &&
        assert_function_exists "check_plugin_conflicts" &&
        assert_function_exists "resolve_plugin_load_order" &&
        assert_function_exists "load_plugin_with_metadata" &&
        assert_function_exists "list_plugins"
}

test_plugin_registration() {
    zf::debug "    📊 Testing plugin registration..."

    # Clear any existing registry for clean 040-testing
    unset ZSH_PLUGIN_REGISTRY
    typeset -gA ZSH_PLUGIN_REGISTRY

    # Test basic plugin registration
    if register_plugin "test-plugin" "test/plugin" "oh-my-zsh" "" "" "Test plugin for testing"; then
        zf::debug "    ✓ Basic plugin registration successful"
    else
        zf::debug "    ✗ Basic plugin registration failed"
        return 1
    fi

    # Test plugin registration with dependencies
    if register_plugin "dependent-plugin" "test/dependent" "oh-my-zsh" "test-plugin" "" "Plugin with dependencies"; then
        zf::debug "    ✓ Plugin registration with dependencies successful"
    else
        zf::debug "    ✗ Plugin registration with dependencies failed"
        return 1
    fi

    # Test plugin registration with conflicts
    if register_plugin "conflicting-plugin" "test/conflict" "oh-my-zsh" "" "test-plugin" "Plugin with conflicts"; then
        zf::debug "    ✓ Plugin registration with conflicts successful"
    else
        zf::debug "    ✗ Plugin registration with conflicts failed"
        return 1
    fi

    # Verify plugins are registered
    if [[ -n "${ZSH_PLUGIN_REGISTRY[test - plugin]:-}" ]]; then
        zf::debug "    ✓ Plugin metadata stored correctly"
    else
        zf::debug "    ✗ Plugin metadata not stored"
        return 1
    fi

    return 0
}

test_plugin_metadata_retrieval() {
    zf::debug "    📊 Testing plugin metadata retrieval..."

    # Test retrieving existing plugin metadata
    local metadata=$(get_plugin_metadata "test-plugin")
    if [[ -n "$metadata" ]]; then
        zf::debug "    ✓ Plugin metadata retrieval successful"
    else
        zf::debug "    ✗ Plugin metadata retrieval failed"
        return 1
    fi

    # Test retrieving non-existent plugin metadata
    local missing_metadata=$(get_plugin_metadata "non-existent-plugin")
    if [[ -z "$missing_metadata" ]]; then
        zf::debug "    ✓ Non-existent plugin correctly returns empty"
    else
        zf::debug "    ✗ Non-existent plugin should return empty"
        return 1
    fi

    # Verify metadata contains expected fields
    if zf::debug "$metadata" | grep -q '"name": "test-plugin"'; then
        zf::debug "    ✓ Plugin metadata contains correct name"
    else
        zf::debug "    ✗ Plugin metadata missing or incorrect name"
        return 1
    fi

    return 0
}

test_dependency_resolution() {
    zf::debug "    📊 Testing dependency resolution..."

    # Test plugin with satisfied dependencies
    local dep_result=0
    check_plugin_dependencies "dependent-plugin" || dep_result=$?

    if [[ $dep_result -eq 0 ]]; then
        zf::debug "    ✓ Dependencies correctly satisfied"
    else
        zf::debug "    ✗ Dependencies should be satisfied but aren't"
        return 1
    fi

    # Test plugin with missing dependencies
    register_plugin "missing-dep-plugin" "test/missing" "oh-my-zsh" "non-existent-dependency" "" "Plugin with missing deps"

    local missing_dep_result=0
    check_plugin_dependencies "missing-dep-plugin" || missing_dep_result=$?

    if [[ $missing_dep_result -eq 2 ]]; then
        zf::debug "    ✓ Missing dependencies correctly detected"
    else
        zf::debug "    ✗ Missing dependencies not detected properly (result: $missing_dep_result)"
        return 1
    fi

    return 0
}

test_conflict_detection() {
    zf::debug "    📊 Testing conflict detection..."

    # Test plugin with conflicts
    local conflict_result=0
    check_plugin_conflicts "conflicting-plugin" || conflict_result=$?

    if [[ $conflict_result -eq 2 ]]; then
        zf::debug "    ✓ Plugin conflicts correctly detected"
    else
        zf::debug "    ✗ Plugin conflicts not detected properly (result: $conflict_result)"
        return 1
    fi

    # Test plugin without conflicts
    local no_conflict_result=0
    check_plugin_conflicts "test-plugin" || no_conflict_result=$?

    if [[ $no_conflict_result -eq 0 ]]; then
        zf::debug "    ✓ No conflicts correctly identified"
    else
        zf::debug "    ✗ False conflicts detected (result: $no_conflict_result)"
        return 1
    fi

    return 0
}

test_load_order_resolution() {
    zf::debug "    📊 Testing load order resolution..."

    # Test load order resolution with dependencies
    local load_order=$(resolve_plugin_load_order "dependent-plugin" "test-plugin")

    if zf::debug "$load_order" | grep -q "test-plugin.*dependent-plugin"; then
        zf::debug "    ✓ Load order correctly resolved with dependencies first"
    else
        zf::debug "    ✗ Load order resolution failed"
        zf::debug "    Expected: test-plugin before dependent-plugin"
        zf::debug "    Got: $load_order"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. PLUGIN LISTING TESTS
# ------------------------------------------------------------------------------

test_plugin_listing() {
    zf::debug "    📊 Testing plugin listing functionality..."

    # Test simple listing
    local simple_list=$(list_plugins "simple")
    if zf::debug "$simple_list" | grep -q "test-plugin"; then
        zf::debug "    ✓ Simple plugin listing working"
    else
        zf::debug "    ✗ Simple plugin listing failed"
        return 1
    fi

    # Test detailed listing
    local detailed_list=$(list_plugins "detailed")
    if zf::debug "$detailed_list" | grep -q "Plugin: test-plugin"; then
        zf::debug "    ✓ Detailed plugin listing working"
    else
        zf::debug "    ✗ Detailed plugin listing failed"
        return 1
    fi

    # Test JSON listing
    local json_list=$(list_plugins "json")
    if zf::debug "$json_list" | grep -q '"test-plugin":'; then
        zf::debug "    ✓ JSON plugin listing working"
    else
        zf::debug "    ✗ JSON plugin listing failed"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 4. CONFIGURATION TESTS
# ------------------------------------------------------------------------------

test_plugin_configuration() {
    zf::debug "    📊 Testing plugin configuration options..."

    # Test strict dependency mode
    local original_strict="$ZSH_PLUGIN_STRICT_DEPENDENCIES"
    export ZSH_PLUGIN_STRICT_DEPENDENCIES=true

    local strict_result=0
    check_plugin_dependencies "missing-dep-plugin" || strict_result=$?

    if [[ $strict_result -eq 1 ]]; then
        zf::debug "    ✓ Strict dependency mode working"
    else
        zf::debug "    ✗ Strict dependency mode not working (result: $strict_result)"
        export ZSH_PLUGIN_STRICT_DEPENDENCIES="$original_strict"
        return 1
    fi

    # Restore original setting
    export ZSH_PLUGIN_STRICT_DEPENDENCIES="$original_strict"

    # Test conflict resolution modes
    local original_conflict="$ZSH_PLUGIN_CONFLICT_RESOLUTION"
    export ZSH_PLUGIN_CONFLICT_RESOLUTION="error"

    local error_result=0
    check_plugin_conflicts "conflicting-plugin" || error_result=$?

    if [[ $error_result -eq 1 ]]; then
        zf::debug "    ✓ Error conflict resolution mode working"
    else
        zf::debug "    ✗ Error conflict resolution mode not working (result: $error_result)"
        export ZSH_PLUGIN_CONFLICT_RESOLUTION="$original_conflict"
        return 1
    fi

    # Restore original setting
    export ZSH_PLUGIN_CONFLICT_RESOLUTION="$original_conflict"

    return 0
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_plugin_framework_integration() {
    zf::debug "    📊 Testing plugin framework integration..."

    # Test that the framework integrates with existing systems
    local integration_issues=0

    # Check if plugin registry directory was created
    if [[ -d "$ZSH_PLUGIN_REGISTRY_DIR" ]]; then
        zf::debug "    ✓ Plugin registry directory created"
    else
        integration_issues=$((integration_issues + 1))
        zf::debug "    ✗ Plugin registry directory not created"
    fi

    # Check if metadata file exists
    if [[ -f "$ZSH_PLUGIN_METADATA_FILE" ]]; then
        zf::debug "    ✓ Plugin metadata file exists"
    else
        integration_issues=$((integration_issues + 1))
        zf::debug "    ✗ Plugin metadata file not created"
    fi

    # Check if dependency cache exists
    if [[ -f "$ZSH_PLUGIN_DEPENDENCY_CACHE" ]]; then
        zf::debug "    ✓ Plugin dependency cache exists"
    else
        integration_issues=$((integration_issues + 1))
        zf::debug "    ✗ Plugin dependency cache not created"
    fi

    # Check if context-aware logging is working
    if declare -f context_echo >/dev/null 2>&1; then
        zf::debug "    ✓ Context-aware logging integration working"
    else
        zf::debug "    ⚠ Context-aware logging not available (expected in test environment)"
    fi

    if [[ $integration_issues -eq 0 ]]; then
        zf::debug "    ✓ Plugin framework integration successful"
        return 0
    else
        zf::debug "    ✗ Plugin framework integration has $integration_issues issues"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Plugin Metadata Framework Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Plugin Metadata Version: ${ZSH_PLUGIN_METADATA_VERSION:-unknown}"
    zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
    zf::debug ""

    log_test "Starting plugin metadata framework test suite"

    # Function Existence Tests
    zf::debug "=== Plugin Metadata Function Tests ==="
    run_test "Plugin Metadata Functions Exist" "test_plugin_metadata_functions_exist"

    # Plugin Registration Tests
    zf::debug ""
    zf::debug "=== Plugin Registration Tests ==="
    run_test "Plugin Registration" "test_plugin_registration"
    run_test "Plugin Metadata Retrieval" "test_plugin_metadata_retrieval"

    # Dependency and Conflict Tests
    zf::debug ""
    zf::debug "=== Dependency and Conflict Tests ==="
    run_test "Dependency Resolution" "test_dependency_resolution"
    run_test "Conflict Detection" "test_conflict_detection"
    run_test "Load Order Resolution" "test_load_order_resolution"

    # Plugin Management Tests
    zf::debug ""
    zf::debug "=== Plugin Management Tests ==="
    run_test "Plugin Listing" "test_plugin_listing"
    run_test "Plugin Configuration" "test_plugin_configuration"

    # Integration Tests
    zf::debug ""
    zf::debug "=== Integration Tests ==="
    run_test "Plugin Framework Integration" "test_plugin_framework_integration"

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
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi
    zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Plugin metadata framework test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All plugin metadata framework tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED plugin metadata framework test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
    zf::debug "Plugin metadata framework test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Plugin Metadata Framework Test Suite
# ==============================================================================
