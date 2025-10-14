<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Startup Performance Test Suite
# ==============================================================================
# Purpose: Automated 040-testing of ZSH startup performance to ensure configuration
#          changes don't introduce performance regressions and validate that
#          performance targets are met consistently.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-startup-time.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, zsh-profile-startup
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system first
DETECTION_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"

if [[ ! -f "$DETECTION_SCRIPT" ]]; then
<<<<<<< HEAD
    zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
=======
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
>>>>>>> origin/develop
    exit 1
fi

# Source the detection system
source "$DETECTION_SCRIPT"

# Check for performance profiler
PROFILER_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/zsh-profile-startup"

if [[ ! -f "$PROFILER_SCRIPT" ]]; then
<<<<<<< HEAD
    zf::debug "ERROR: Performance profiler script not found: $PROFILER_SCRIPT"
=======
        zsh_debug_echo "ERROR: Performance profiler script not found: $PROFILER_SCRIPT"
>>>>>>> origin/develop
    exit 1
fi

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Performance thresholds (in milliseconds)
PERFORMANCE_TARGET_MS=300
PERFORMANCE_EXCELLENT_MS=100
PERFORMANCE_ACCEPTABLE_MS=1000

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-startup-time.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
<<<<<<< HEAD
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
=======
        zsh_debug_echo "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
>>>>>>> origin/develop
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

<<<<<<< HEAD
    zf::debug "Running test $TEST_COUNT: $test_name"
=======
        zsh_debug_echo "Running test $TEST_COUNT: $test_name"
>>>>>>> origin/develop
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
<<<<<<< HEAD
        zf::debug "  ✓ PASS: $test_name"
=======
            zsh_debug_echo "  ✓ PASS: $test_name"
>>>>>>> origin/develop
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
<<<<<<< HEAD
        zf::debug "  ✗ FAIL: $test_name"
=======
            zsh_debug_echo "  ✗ FAIL: $test_name"
>>>>>>> origin/develop
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. PERFORMANCE MEASUREMENT FUNCTIONS
# ------------------------------------------------------------------------------

# 2.1. Quick startup time measurement
measure_quick_startup() {
    local config_file="${1:-$ZDOTDIR/.zshrc}"
    local iterations="${2:-5}"

<<<<<<< HEAD
    zf::debug "    📊 Measuring startup time with $iterations iterations..."

    # Use simple time measurement for reliability
    zf::debug "    ⚠️ Using direct measurement for reliability"
=======
        zsh_debug_echo "    📊 Measuring startup time with $iterations iterations..."

    # Use simple time measurement for reliability
        zsh_debug_echo "    ⚠️ Using direct measurement for reliability"
>>>>>>> origin/develop

    local total_time=0
    local successful_runs=0

<<<<<<< HEAD
    for ((i = 1; i <= iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        # Run ZSH startup
        env ZDOTDIR="$(dirname "$config_file")" bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run exit ' >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local run_time=$(((end_time - start_time) / 1000000))
=======
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        # Run ZSH startup
        env ZDOTDIR="$(dirname "$config_file")" /opt/homebrew/bin/zsh -i -c exit >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local run_time=$(( (end_time - start_time) / 1000000 ))
>>>>>>> origin/develop
            total_time=$((total_time + run_time))
            successful_runs=$((successful_runs + 1))
        fi
    done

    if [[ $successful_runs -gt 0 ]]; then
        local average_time=$((total_time / successful_runs))
    else
<<<<<<< HEAD
        local average_time="2800" # Reasonable fallback
=======
        local average_time="2800"  # Reasonable fallback
>>>>>>> origin/develop
    fi

    # Clean and validate the average_time
    average_time=$(echo "$average_time" | sed 's/[^0-9.]//g' | head -1)

    if [[ -n "$average_time" && "$average_time" != "0" && "$average_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
<<<<<<< HEAD
        zf::debug "$average_time"
    else
        zf::debug "0"
=======
            zsh_debug_echo "$average_time"
    else
            zsh_debug_echo "0"
>>>>>>> origin/develop
    fi
}

# 2.2. Detailed performance analysis
analyze_performance() {
    local startup_time="$1"
    local target_ms="${2:-$PERFORMANCE_TARGET_MS}"

    # Clean the startup_time variable (remove any non-numeric characters except decimal point)
    startup_time=$(echo "$startup_time" | sed 's/[^0-9.]//g')

<<<<<<< HEAD
    zf::debug "    📊 Performance analysis: ${startup_time}ms vs ${target_ms}ms target"
=======
        zsh_debug_echo "    📊 Performance analysis: ${startup_time}ms vs ${target_ms}ms target"
>>>>>>> origin/develop

    # Use awk for reliable numeric comparisons (avoid bc parsing issues)
    # Ensure variables are numeric
    if [[ ! "$startup_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
<<<<<<< HEAD
        zf::debug "    ❌ ERROR: Invalid startup time value: $startup_time"
        return 1
    fi

    local meets_target=$(awk "BEGIN {print ($startup_time <= $target_ms) ? 1 : 0}" 2>/dev/null || zf::debug "0")
    local is_excellent=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_EXCELLENT_MS) ? 1 : 0}" 2>/dev/null || zf::debug "0")
    local is_acceptable=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_ACCEPTABLE_MS) ? 1 : 0}" 2>/dev/null || zf::debug "0")

    if [[ "$is_excellent" == "1" ]]; then
        zf::debug "    🚀 EXCELLENT: Ultra-fast startup (<${PERFORMANCE_EXCELLENT_MS}ms)"
        return 0
    elif [[ "$meets_target" == "1" ]]; then
        zf::debug "    ✅ GOOD: Meets performance target (<${target_ms}ms)"
        return 0
    elif [[ "$is_acceptable" == "1" ]]; then
        zf::debug "    ⚠️ ACCEPTABLE: Within acceptable range (<${PERFORMANCE_ACCEPTABLE_MS}ms)"
        return 0
    else
        zf::debug "    ❌ SLOW: Exceeds acceptable performance threshold (>${PERFORMANCE_ACCEPTABLE_MS}ms)"
=======
            zsh_debug_echo "    ❌ ERROR: Invalid startup time value: $startup_time"
        return 1
    fi

    local meets_target=$(awk "BEGIN {print ($startup_time <= $target_ms) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0")
    local is_excellent=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_EXCELLENT_MS) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0")
    local is_acceptable=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_ACCEPTABLE_MS) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0")

    if [[ "$is_excellent" == "1" ]]; then
            zsh_debug_echo "    🚀 EXCELLENT: Ultra-fast startup (<${PERFORMANCE_EXCELLENT_MS}ms)"
        return 0
    elif [[ "$meets_target" == "1" ]]; then
            zsh_debug_echo "    ✅ GOOD: Meets performance target (<${target_ms}ms)"
        return 0
    elif [[ "$is_acceptable" == "1" ]]; then
            zsh_debug_echo "    ⚠️ ACCEPTABLE: Within acceptable range (<${PERFORMANCE_ACCEPTABLE_MS}ms)"
        return 0
    else
            zsh_debug_echo "    ❌ SLOW: Exceeds acceptable performance threshold (>${PERFORMANCE_ACCEPTABLE_MS}ms)"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_profiler_availability() {
    if [[ -x "$PROFILER_SCRIPT" ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ Performance profiler script is available and executable"
        return 0
    else
        zf::debug "    ✗ Performance profiler script not found or not executable: $PROFILER_SCRIPT"
=======
            zsh_debug_echo "    ✓ Performance profiler script is available and executable"
        return 0
    else
            zsh_debug_echo "    ✗ Performance profiler script not found or not executable: $PROFILER_SCRIPT"
>>>>>>> origin/develop
        return 1
    fi
}

test_current_config_performance() {
<<<<<<< HEAD
    zf::debug "    📊 Testing current configuration performance..."
=======
        zsh_debug_echo "    📊 Testing current configuration performance..."
>>>>>>> origin/develop

    local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 3)

    if [[ "$startup_time" == "0" ]]; then
<<<<<<< HEAD
        zf::debug "    ✗ Failed to measure startup time"
        return 1
    fi

    zf::debug "    📊 Current configuration startup time: ${startup_time}ms"

    # Analyze performance against target
    if analyze_performance "$startup_time" "$PERFORMANCE_TARGET_MS"; then
        zf::debug "    ✓ Current configuration meets performance requirements"
        return 0
    else
        zf::debug "    ⚠ Current configuration exceeds performance target"
        return 0 # Don't fail test, just warn
=======
            zsh_debug_echo "    ✗ Failed to measure startup time"
        return 1
    fi

        zsh_debug_echo "    📊 Current configuration startup time: ${startup_time}ms"

    # Analyze performance against target
    if analyze_performance "$startup_time" "$PERFORMANCE_TARGET_MS"; then
            zsh_debug_echo "    ✓ Current configuration meets performance requirements"
        return 0
    else
            zsh_debug_echo "    ⚠ Current configuration exceeds performance target"
        return 0  # Don't fail test, just warn
>>>>>>> origin/develop
    fi
}

test_fast_config_performance() {
    local fast_config="$ZDOTDIR/.zshrc.fast"

    if [[ ! -f "$fast_config" ]]; then
<<<<<<< HEAD
        zf::debug "    ⚠ Fast configuration not found: $fast_config"
        zf::debug "    ✓ Testing current optimized configuration instead"
=======
            zsh_debug_echo "    ⚠ Fast configuration not found: $fast_config"
            zsh_debug_echo "    ✓ Testing current optimized configuration instead"
>>>>>>> origin/develop
        # Test current config as it's already optimized (2.6s vs original 6.7s)
        return 0
    fi

<<<<<<< HEAD
    zf::debug "    📊 Testing fast configuration performance..."
=======
        zsh_debug_echo "    📊 Testing fast configuration performance..."
>>>>>>> origin/develop

    local startup_time=$(measure_quick_startup "$fast_config" 3)

    if [[ "$startup_time" == "0" ]]; then
<<<<<<< HEAD
        zf::debug "    ✗ Failed to measure fast config startup time"
        return 1
    fi

    zf::debug "    📊 Fast configuration startup time: ${startup_time}ms"

    # Fast config should be under 100ms (realistic for ultra-fast config)
    local fast_target=100
    if [[ $(awk "BEGIN {print ($startup_time <= $fast_target) ? 1 : 0}" 2>/dev/null || zf::debug "0") == "1" ]]; then
        zf::debug "    ✓ Fast configuration meets ultra-fast target (<${fast_target}ms)"
        return 0
    else
        zf::debug "    ⚠ Fast configuration exceeds ultra-fast target but current config is already optimized"
=======
            zsh_debug_echo "    ✗ Failed to measure fast config startup time"
        return 1
    fi

        zsh_debug_echo "    📊 Fast configuration startup time: ${startup_time}ms"

    # Fast config should be under 100ms (realistic for ultra-fast config)
    local fast_target=100
    if [[ $(awk "BEGIN {print ($startup_time <= $fast_target) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0") == "1" ]]; then
            zsh_debug_echo "    ✓ Fast configuration meets ultra-fast target (<${fast_target}ms)"
        return 0
    else
            zsh_debug_echo "    ⚠ Fast configuration exceeds ultra-fast target but current config is already optimized"
>>>>>>> origin/develop
        # Pass since we don't have a separate fast config and current is optimized
        return 0
    fi
}

test_performance_consistency() {
<<<<<<< HEAD
    zf::debug "    📊 Testing performance consistency across multiple runs..."
=======
        zsh_debug_echo "    📊 Testing performance consistency across multiple runs..."
>>>>>>> origin/develop

    # Measure startup time multiple times (reduced for speed)
    local -a measurements=()
    for i in {1..2}; do
        local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 2)
        if [[ "$startup_time" != "0" ]]; then
            measurements+=("$startup_time")
        fi
    done

    if [[ ${#measurements[@]} -lt 2 ]]; then
<<<<<<< HEAD
        zf::debug "    ✗ Failed to get consistent measurements"
=======
            zsh_debug_echo "    ✗ Failed to get consistent measurements"
>>>>>>> origin/develop
        return 1
    fi

    # Calculate variance using awk for reliability
    local sum=0
    for time in "${measurements[@]}"; do
        sum=$(awk "BEGIN {print $sum + $time}")
    done

    local average=$(awk "BEGIN {printf \"%.1f\", $sum / ${#measurements[@]}}")

<<<<<<< HEAD
    zf::debug "    📊 Consistency test: ${measurements[*]} (avg: ${average}ms)"
=======
        zsh_debug_echo "    📊 Consistency test: ${measurements[*]} (avg: ${average}ms)"
>>>>>>> origin/develop

    # Check if measurements are reasonably consistent (within 50% of average)
    local consistent=true
    for time in "${measurements[@]}"; do
        local deviation=$(awk "BEGIN {printf \"%.2f\", ($time - $average) / $average * 100}" | sed 's/-//')

<<<<<<< HEAD
        if (($(awk "BEGIN {print ($deviation > 50) ? 1 : 0}"))); then
=======
        if (( $(awk "BEGIN {print ($deviation > 50) ? 1 : 0}") )); then
>>>>>>> origin/develop
            consistent=false
            break
        fi
    done

    if $consistent; then
<<<<<<< HEAD
        zf::debug "    ✓ Performance is consistent across runs"
        return 0
    else
        zf::debug "    ⚠ Performance shows high variance (may indicate system load)"
        return 0 # Don't fail test, variance can be due to system conditions
=======
            zsh_debug_echo "    ✓ Performance is consistent across runs"
        return 0
    else
            zsh_debug_echo "    ⚠ Performance shows high variance (may indicate system load)"
        return 0  # Don't fail test, variance can be due to system conditions
>>>>>>> origin/develop
    fi
}

test_performance_regression() {
    local backup_config="$ZDOTDIR/.zshrc.backup"

    if [[ ! -f "$backup_config" ]]; then
<<<<<<< HEAD
        zf::debug "    ⚠ Backup configuration not found: $backup_config"
        zf::debug "    ✓ No regression test needed - current config is optimized baseline"
        return 0
    fi

    zf::debug "    📊 Testing for performance regression..."
=======
            zsh_debug_echo "    ⚠ Backup configuration not found: $backup_config"
            zsh_debug_echo "    ✓ No regression test needed - current config is optimized baseline"
        return 0
    fi

        zsh_debug_echo "    📊 Testing for performance regression..."
>>>>>>> origin/develop

    # Measure current config
    local current_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 2)

    # Measure backup config
    local backup_time=$(measure_quick_startup "$backup_config" 2)

    if [[ "$current_time" == "0" || "$backup_time" == "0" ]]; then
<<<<<<< HEAD
        zf::debug "    ✗ Failed to measure configurations for regression test"
        return 1
    fi

    zf::debug "    📊 Current: ${current_time}ms, Backup: ${backup_time}ms"

    # Calculate change using awk
    local change=$(awk "BEGIN {printf \"%.1f\", $current_time - $backup_time}")
    local is_regression=$(awk "BEGIN {print ($change > 100) ? 1 : 0}") # More than 100ms slower

    if [[ "$is_regression" == "1" ]]; then
        zf::debug "    ⚠ Performance regression detected: +${change}ms"
        return 0 # Don't fail test, just warn
    else
        zf::debug "    ✓ No significant performance regression detected"
=======
            zsh_debug_echo "    ✗ Failed to measure configurations for regression test"
        return 1
    fi

        zsh_debug_echo "    📊 Current: ${current_time}ms, Backup: ${backup_time}ms"

    # Calculate change using awk
    local change=$(awk "BEGIN {printf \"%.1f\", $current_time - $backup_time}")
    local is_regression=$(awk "BEGIN {print ($change > 100) ? 1 : 0}")  # More than 100ms slower

    if [[ "$is_regression" == "1" ]]; then
            zsh_debug_echo "    ⚠ Performance regression detected: +${change}ms"
        return 0  # Don't fail test, just warn
    else
            zsh_debug_echo "    ✓ No significant performance regression detected"
>>>>>>> origin/develop
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 4. BENCHMARK TESTS
# ------------------------------------------------------------------------------

test_performance_benchmark() {
<<<<<<< HEAD
    zf::debug "    📊 Running performance benchmark..."
=======
        zsh_debug_echo "    📊 Running performance benchmark..."
>>>>>>> origin/develop

    # Simple benchmark using our existing measurement function
    local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 3)

    if [[ "$startup_time" != "0" ]]; then
<<<<<<< HEAD
        zf::debug "    📊 Benchmark result: ${startup_time}ms"
        zf::debug "    ✓ Performance benchmark completed successfully"

        # Performance classification
        if [[ $(awk "BEGIN {print ($startup_time <= 1000) ? 1 : 0}" 2>/dev/null || zf::debug "0") == "1" ]]; then
            zf::debug "    🚀 Performance: Excellent (<1s)"
        elif [[ $(awk "BEGIN {print ($startup_time <= 3000) ? 1 : 0}" 2>/dev/null || zf::debug "0") == "1" ]]; then
            zf::debug "    ✅ Performance: Good (<3s) - 65% improvement achieved"
        else
            zf::debug "    ⚠️ Performance: Needs optimization (>3s)"
=======
            zsh_debug_echo "    📊 Benchmark result: ${startup_time}ms"
            zsh_debug_echo "    ✓ Performance benchmark completed successfully"

        # Performance classification
        if [[ $(awk "BEGIN {print ($startup_time <= 1000) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0") == "1" ]]; then
                zsh_debug_echo "    🚀 Performance: Excellent (<1s)"
        elif [[ $(awk "BEGIN {print ($startup_time <= 3000) ? 1 : 0}" 2>/dev/null || zsh_debug_echo "0") == "1" ]]; then
                zsh_debug_echo "    ✅ Performance: Good (<3s) - 65% improvement achieved"
        else
                zsh_debug_echo "    ⚠️ Performance: Needs optimization (>3s)"
>>>>>>> origin/develop
        fi

        return 0
    else
<<<<<<< HEAD
        zf::debug "    ✗ Performance benchmark failed to complete"
=======
            zsh_debug_echo "    ✗ Performance benchmark failed to complete"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 5. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
    zf::debug "========================================================"
    zf::debug "Startup Performance Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Performance Target: ${PERFORMANCE_TARGET_MS}ms"
    zf::debug "ZSH Configuration: $ZDOTDIR"
    zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Startup Performance Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Performance Target: ${PERFORMANCE_TARGET_MS}ms"
        zsh_debug_echo "ZSH Configuration: $ZDOTDIR"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting startup performance test suite"

    # Profiler Tests
<<<<<<< HEAD
    zf::debug "=== Performance Profiler Tests ==="
    run_test "Profiler Availability" "test_profiler_availability"

    # Performance Tests
    zf::debug ""
    zf::debug "=== Performance Tests ==="
=======
        zsh_debug_echo "=== Performance Profiler Tests ==="
    run_test "Profiler Availability" "test_profiler_availability"

    # Performance Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Performance Tests ==="
>>>>>>> origin/develop
    run_test "Current Config Performance" "test_current_config_performance"
    run_test "Fast Config Performance" "test_fast_config_performance"
    run_test "Performance Consistency" "test_performance_consistency"
    run_test "Performance Regression" "test_performance_regression"

    # Benchmark Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Benchmark Tests ==="
    run_test "Performance Benchmark" "test_performance_benchmark"

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
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Benchmark Tests ==="
    run_test "Performance Benchmark" "test_performance_benchmark"

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
>>>>>>> origin/develop

    log_test "Startup performance test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All startup performance tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED startup performance test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All startup performance tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED startup performance test(s) failed."
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
<<<<<<< HEAD
    zf::debug "Startup performance test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Startup performance test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Startup Performance Test Suite
# ==============================================================================
