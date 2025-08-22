#!/opt/homebrew/bin/zsh
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
    export LOG_DIR="/Users/s-a-c/.config/zsh/logs/$log_date"
    export LOG_FILE="$LOG_DIR/test-macos-defaults_$log_time.log"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Start logging (both STDOUT and STDERR)
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "🧪 Testing Deferred macOS Defaults Execution System"
    echo "=================================================="
    echo "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "📋 Log File: $LOG_FILE"
    echo ""
    
    # Verify macOS environment
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "❌ Error: This test requires macOS (Darwin) system" >&2
        exit 1
    fi
    
    # Test configuration paths
    export CONFIG_BASE="/Users/s-a-c/.config/zsh"
    export SETUP_SCRIPT="$CONFIG_BASE/bin/macos-defaults-setup.zsh"
    export WRAPPER_SCRIPT="$CONFIG_BASE/.zshrc.pre-plugins.d/03-macos-defaults-deferred.zsh"
    export MARKER_FILE="$CONFIG_BASE/.macos-defaults-last-run"
    
    export TESTS_PASSED=0
    export TESTS_FAILED=0
}

# 2.3 Test deferred execution wrapper script exists and is configured properly
_test_wrapper_exists() {
    echo "1. Testing wrapper script existence and configuration..."
    
    if [[ -f "$WRAPPER_SCRIPT" ]]; then
        echo "   ✅ Wrapper script exists: $WRAPPER_SCRIPT"
        ((TESTS_PASSED++))
    else
        echo "   ❌ Wrapper script missing: $WRAPPER_SCRIPT"
        ((TESTS_FAILED++))
        return 1
    fi
    
    if [[ -x "$SETUP_SCRIPT" ]]; then
        echo "   ✅ Setup script exists and is executable: $SETUP_SCRIPT"
        ((TESTS_PASSED++))
    else
        echo "   ❌ Setup script missing or not executable: $SETUP_SCRIPT"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Test that wrapper script has the deferred function
    if grep -q "_deferred_macos_defaults" "$WRAPPER_SCRIPT"; then
        echo "   ✅ Wrapper script contains deferred function"
        ((TESTS_PASSED++))
    else
        echo "   ❌ Wrapper script missing deferred function"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# 2.4 Test first run behavior (marker file missing)
_test_first_run() {
    echo "2. Testing first run behavior (no marker file)..."
    
    # Clear any existing marker file
    if [[ -f "$MARKER_FILE" ]]; then
        echo "   🗑️  Removing existing marker file: $MARKER_FILE"
        rm -f "$MARKER_FILE"
    fi
    
    # Source the wrapper function
    echo "   📥 Sourcing wrapper function..."
    source "$WRAPPER_SCRIPT"
    
    # Check if marker file was created after sourcing
    if [[ -f "$MARKER_FILE" ]]; then
        echo "   ✅ Marker file created on first run: $MARKER_FILE"
        echo "   📄 Marker content: $(cat "$MARKER_FILE")"
        ((TESTS_PASSED++))
    else
        echo "   ❌ Marker file not created on first run"
        ((TESTS_FAILED++))
    fi
    
    # Check for log output that indicates setup ran
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Running macOS defaults setup" "$latest_log"; then
            echo "   ✅ Log shows setup script executed on first run"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Log does not show setup script execution"
            ((TESTS_FAILED++))
        fi
    else
        echo "   ❌ No deferred execution log file found"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# 2.5 Test skip behavior (marker file exists and recent)
_test_skip_behavior() {
    echo "3. Testing skip behavior (marker file exists and recent)..."
    
    # Ensure marker file exists from previous test
    if [[ ! -f "$MARKER_FILE" ]]; then
        echo "   ⚠️  Creating marker file for skip test"
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$MARKER_FILE"
    fi
    
    # Count existing log files before test
    local logs_before=$(ls -1 "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | wc -l)
    
    # Source the wrapper function again
    echo "   📥 Sourcing wrapper function (second time)..."
    source "$WRAPPER_SCRIPT"
    
    # Check log output for skip message
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Skipping macOS defaults setup" "$latest_log"; then
            echo "   ✅ Log shows setup was skipped on second run"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Log does not show skip behavior"
            ((TESTS_FAILED++))
        fi
    else
        echo "   ❌ No log file found for skip test"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# 2.6 Test script modification detection
_test_modification_detection() {
    echo "4. Testing script modification detection..."
    
    # Create a backup of the setup script
    local backup_script="$SETUP_SCRIPT.test-backup"
    cp "$SETUP_SCRIPT" "$backup_script"
    
    # Modify the setup script (add a harmless comment)
    echo "# Test modification $(date)" >> "$SETUP_SCRIPT"
    
    # Source the wrapper function after modification
    echo "   📥 Sourcing wrapper after script modification..."
    source "$WRAPPER_SCRIPT"
    
    # Check log output for modification detection
    local latest_log=$(ls -1t "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null | head -1)
    if [[ -f "$latest_log" ]]; then
        if grep -q "Setup script modified since last run" "$latest_log"; then
            echo "   ✅ Log shows script modification was detected"
            ((TESTS_PASSED++))
        else
            echo "   ❌ Log does not show modification detection"
            ((TESTS_FAILED++))
        fi
    else
        echo "   ❌ No log file found for modification test"
        ((TESTS_FAILED++))
    fi
    
    # Restore the original setup script
    mv "$backup_script" "$SETUP_SCRIPT"
    
    echo ""
}

# 2.7 Test startup time comparison
_test_startup_time() {
    echo "5. Testing startup time with deferred execution..."
    
    # Test startup time with deferred system (should be fast)
    local start_time=$(date +%s%N)
    source "$WRAPPER_SCRIPT" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration_ns=$((end_time - start_time))
    local duration_ms=$((duration_ns / 1000000))
    
    echo "   📊 Deferred execution time: ${duration_ms}ms"
    
    if [[ $duration_ms -lt 100 ]]; then
        echo "   ✅ Deferred execution is fast (< 100ms)"
        ((TESTS_PASSED++))
    else
        echo "   ⚠️  Deferred execution slower than expected (${duration_ms}ms)"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# 2.8 Test log file organization
_test_log_organization() {
    echo "6. Testing log file organization..."
    
    # Check log directory structure
    if [[ -d "$LOG_DIR" ]]; then
        echo "   ✅ Date-named log directory exists: $LOG_DIR"
        ((TESTS_PASSED++))
    else
        echo "   ❌ Date-named log directory missing: $LOG_DIR"
        ((TESTS_FAILED++))
    fi
    
    # Check for UTC-timestamped log files
    local log_files=($(ls "$LOG_DIR"/deferred-macos-defaults_*.log 2>/dev/null))
    if [[ ${#log_files[@]} -gt 0 ]]; then
        echo "   ✅ UTC-timestamped log files found: ${#log_files[@]} files"
        for log_file in "${log_files[@]}"; do
            echo "     📄 $(basename "$log_file")"
        done
        ((TESTS_PASSED++))
    else
        echo "   ❌ No UTC-timestamped log files found"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# 2.9 Test cleanup and working directory restoration
_test_cleanup() {
    echo "🏁 Test Results Summary"
    echo "======================"
    echo "✅ Tests Passed: $TESTS_PASSED"
    echo "❌ Tests Failed: $TESTS_FAILED"
    echo "📊 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    # Restore original working directory
    if [[ -n "$ORIGINAL_CWD" ]]; then
        cd "$ORIGINAL_CWD" || {
            echo "⚠️  Warning: Could not restore original directory: $ORIGINAL_CWD" >&2
            exit 1
        }
    fi
    
    if (( TESTS_FAILED == 0 )); then
        echo "🎉 All deferred macOS defaults tests passed!"
        echo "✅ Task 2.1 (Implement deferred macOS defaults system) - COMPLETE"
        echo ""
        echo "📈 Performance improvements achieved:"
        echo "   - macOS defaults no longer run on every shell startup"
        echo "   - Intelligent caching with 24-hour refresh cycle"
        echo "   - Script modification detection ensures currency"
        echo "   - Comprehensive logging for troubleshooting"
        return 0
    else
        echo "⚠️  Some deferred macOS defaults tests failed"
        echo "❌ Task 2.1 needs attention"
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
# In zsh, use $0 instead of BASH_SOURCE
if [[ "${0##*/}" == "test-macos-defaults.zsh" ]]; then
    main "$@"
fi
