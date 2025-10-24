#!/usr/bin/env zsh
#=============================================================================
# File: test-macos-defaults.zsh
# Purpose: 2.1 Test deferred macOS defaults execution system
# Dependencies: macOS (Darwin), deferred execution scripts
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# 2.1 Working Directory Management - Save current working directory
export ORIGINAL_CWD="$(pwd)"

# 2.2 Test setup and initialization
_test_setup() {
    # Setup logging
    local log_date=$(date -u +%Y-%m-%d)
    local log_time=$(date -u +%H-%M-%S)
    export LOG_DIR="${HOME}/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/test-macos-defaults_$log_time.log"

    # Create log directory
    mkdir -p "$LOG_DIR"

    # Start logging (both STDOUT and STDERR)
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)

    zf::debug "🧪 Testing Deferred macOS Defaults Execution System"
    zf::debug "=================================================="
    zf::debug "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    zf::debug "📋 Log File: $LOG_FILE"
    zf::debug ""

    # Verify macOS environment
    if [[ "$(uname)" != "Darwin" ]]; then
        zf::debug "❌ Error: This test requires macOS (Darwin) system"
        exit 1
    fi

    # Test configuration paths
    export CONFIG_BASE="${HOME}/.config/zsh"
    export SETUP_SCRIPT="$CONFIG_BASE/bin/macos-defaults-setup.zsh"
    export WRAPPER_SCRIPT="$CONFIG_BASE/.zshrc.pre-plugins.d/03-macos-defaults-deferred.zsh"
    export MARKER_FILE="$CONFIG_BASE/.macos-defaults-last-run"

    export TESTS_PASSED=0
    export TESTS_FAILED=0
}

# 2.3 Test deferred execution wrapper script exists and is configured properly
_test_wrapper_exists() {
    zf::debug "1. Testing wrapper script existence and configuration..."

    if [[ -f "$WRAPPER_SCRIPT" ]]; then
        zf::debug "   ✅ Wrapper script exists: $WRAPPER_SCRIPT"
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ Wrapper script missing: $WRAPPER_SCRIPT"
        ((TESTS_FAILED++))
        return 1
    fi

    if [[ -x "$SETUP_SCRIPT" ]]; then
        zf::debug "   ✅ Setup script exists and is executable: $SETUP_SCRIPT"
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ Setup script missing or not executable: $SETUP_SCRIPT"
        ((TESTS_FAILED++))
        return 1
    fi

    # Test that wrapper script has the deferred function
    if grep -q "_deferred_macos_defaults" "$WRAPPER_SCRIPT"; then
        zf::debug "   ✅ Wrapper script contains deferred function"
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ Wrapper script missing deferred function"
        ((TESTS_FAILED++))
    fi

    zf::debug ""
}

# 2.4 Test first run behavior (marker file missing)
_test_first_run() {
    zf::debug "2. Testing first run behavior (no marker file)..."

    # Clear any existing marker file
    if [[ -f "$MARKER_FILE" ]]; then
        zf::debug "   🗑️  Removing existing marker file: $MARKER_FILE"
        rm -f "$MARKER_FILE"
    fi

    # Source the wrapper function
    zf::debug "   📥 Sourcing wrapper function..."
    source "$WRAPPER_SCRIPT"

    # Check if marker file was created after sourcing
    if [[ -f "$MARKER_FILE" ]]; then
        zf::debug "   ✅ Marker file created on first run: $MARKER_FILE"
        zf::debug "   📄 Marker content: $(cat "$MARKER_FILE")"
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ Marker file not created on first run"
        ((TESTS_FAILED++))
    fi

    # Check for log output that indicates setup ran
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Running macOS defaults setup" "$latest_log"; then
            zf::debug "   ✅ Log shows setup script executed on first run"
            ((TESTS_PASSED++))
        else
            zf::debug "   ❌ Log does not show setup script execution"
            ((TESTS_FAILED++))
        fi
    else
        zf::debug "   ❌ No deferred execution log file found"
        ((TESTS_FAILED++))
    fi

    zf::debug ""
}

# 2.5 Test skip behavior (marker file exists and recent)
_test_skip_behavior() {
    zf::debug "3. Testing skip behavior (marker file exists and recent)..."

    # Ensure marker file exists from previous test
    if [[ ! -f "$MARKER_FILE" ]]; then
        zf::debug "   ⚠️  Creating marker file for skip test"
        zf::debug "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$MARKER_FILE"
    fi

    # Count existing log files before test
    local logs_before=$(ls -1 "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | wc -l)

    # Source the wrapper function again
    zf::debug "   📥 Sourcing wrapper function (second time)..."
    source "$WRAPPER_SCRIPT"

    # Check log output for skip message
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Skipping macOS defaults setup" "$latest_log"; then
            zf::debug "   ✅ Log shows setup was skipped on second run"
            ((TESTS_PASSED++))
        else
            zf::debug "   ❌ Log does not show skip behavior"
            ((TESTS_FAILED++))
        fi
    else
        zf::debug "   ❌ No log file found for skip test"
        ((TESTS_FAILED++))
    fi

    zf::debug ""
}

# 2.6 Test script modification detection
_test_modification_detection() {
    zf::debug "4. Testing script modification detection..."

    # Create a backup of the setup script
    local backup_script="$SETUP_SCRIPT.test-backup"
    cp "$SETUP_SCRIPT" "$backup_script"

    # Modify the setup script (add a harmless comment)
    zf::debug "# Test modification $(date)" >>"$SETUP_SCRIPT"

    # Source the wrapper function after modification
    zf::debug "   📥 Sourcing wrapper after script modification..."
    source "$WRAPPER_SCRIPT"

    # Check log output for modification detection
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Setup script modified since last run" "$latest_log"; then
            zf::debug "   ✅ Log shows script modification was detected"
            ((TESTS_PASSED++))
        else
            zf::debug "   ❌ Log does not show modification detection"
            ((TESTS_FAILED++))
        fi
    else
        zf::debug "   ❌ No log file found for modification test"
        ((TESTS_FAILED++))
    fi

    # Restore the original setup script
    mv "$backup_script" "$SETUP_SCRIPT"

    zf::debug ""
}

# 2.7 Test startup time comparison
_test_startup_time() {
    zf::debug "5. Testing startup time with deferred execution..."

    # Test startup time with deferred system (should be fast)
    local start_time=$(date +%s%N)
    source "$WRAPPER_SCRIPT" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))

    zf::debug "   📊 Deferred execution time: ${duration_ms}ms"

    if [[ $duration_ms -lt 100 ]]; then
        zf::debug "   ✅ Deferred execution is fast (< 100ms)"
        ((TESTS_PASSED++))
    else
        zf::debug "   ⚠️  Deferred execution slower than expected (${duration_ms}ms)"
        ((TESTS_FAILED++))
    fi

    zf::debug ""
}

# 2.8 Test log file organization
_test_log_organization() {
    zf::debug "6. Testing log file organization..."

    # Check log directory structure
    if [[ -d "$LOG_DIR" ]]; then
        zf::debug "   ✅ Date-named log directory exists: $LOG_DIR"
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ Date-named log directory missing: $LOG_DIR"
        ((TESTS_FAILED++))
    fi

    # Check for UTC-timestamped log files
    local log_files=($(ls "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null))
    if [[ ${#log_files[@]} -gt 0 ]]; then
        zf::debug "   ✅ UTC-timestamped log files found: ${#log_files[@]} files"
        for log_file in "${log_files[@]}"; do
            zf::debug "     📄 $(basename "$log_file")"
        done
        ((TESTS_PASSED++))
    else
        zf::debug "   ❌ No UTC-timestamped log files found"
        ((TESTS_FAILED++))
    fi

    zf::debug ""
}

# 2.9 Test cleanup and working directory restoration
_test_cleanup() {
    zf::debug "🏁 Test Results Summary"
    zf::debug "======================"
    zf::debug "✅ Tests Passed: $TESTS_PASSED"
    zf::debug "❌ Tests Failed: $TESTS_FAILED"
    zf::debug "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    zf::debug ""

    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || {
            zf::debug "⚠️  Warning: Could not restore original directory: $ORIGINAL_CWD"
            exit 1
        }
    fi

    if ((TESTS_FAILED == 0)); then
        zf::debug "🎉 All deferred macOS defaults tests passed!"
        zf::debug "✅ Task 2.1 (Implement deferred macOS defaults system) - COMPLETE"
        zf::debug ""
        zf::debug "📈 Performance improvements achieved:"
        zf::debug "   - macOS defaults no longer run on every shell startup"
        zf::debug "   - Intelligent caching with 24-hour refresh cycle"
        zf::debug "   - Script modification detection ensures currency"
        zf::debug "   - Comprehensive logging for troubleshooting"
        return 0
    else
        zf::debug "⚠️  Some deferred macOS defaults tests failed"
        zf::debug "❌ Task 2.1 needs attention"
        return 1
    fi
}

# 2.10 Main test execution
main() {
    _test_setup
    _test_wrapper_exists
    _test_first_run
    _test_skip_behavior
    _test_modification_detection
    _test_startup_time
    _test_log_organization
    _test_cleanup
}

# Execute main function if script is run directly (not sourced)
# Use ZSH-specific method to detect if script is being executed vs sourced
if [[ "${ZSH_EVAL_CONTEXT:-}" == toplevel || "${ZSH_EVAL_CONTEXT:-}" == cmdarg* ]]; then
    main "$@"
fi
