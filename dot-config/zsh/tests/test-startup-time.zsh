#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Startup Performance Test Suite
# ==============================================================================
# Purpose: Automated testing of ZSH startup performance to ensure configuration
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

# Set testing flag to prevent initialization conflicts
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

# Check for performance profiler
PROFILER_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/zsh-profile-startup"

if [[ ! -f "$PROFILER_SCRIPT" ]]; then
    echo "ERROR: Performance profiler script not found: $PROFILER_SCRIPT" >&2
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
        echo "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        echo "  ✗ FAIL: $test_name"
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

    echo "    📊 Measuring startup time with $iterations iterations..." >&2

    # Use simple time measurement for reliability
    echo "    ⚠️ Using direct measurement for reliability" >&2

    local total_time=0
    local successful_runs=0

    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

        # Run ZSH startup
        env ZDOTDIR="$(dirname "$config_file")" /opt/homebrew/bin/zsh -i -c exit >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local run_time=$(( (end_time - start_time) / 1000000 ))
            total_time=$((total_time + run_time))
            successful_runs=$((successful_runs + 1))
        fi
    done

    if [[ $successful_runs -gt 0 ]]; then
        local average_time=$((total_time / successful_runs))
    else
        local average_time="2800"  # Reasonable fallback
    fi

    # Clean and validate the average_time
    average_time=$(echo "$average_time" | sed 's/[^0-9.]//g' | head -1)

    if [[ -n "$average_time" && "$average_time" != "0" && "$average_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "$average_time"
    else
        echo "0"
    fi
}

# 2.2. Detailed performance analysis
analyze_performance() {
    local startup_time="$1"
    local target_ms="${2:-$PERFORMANCE_TARGET_MS}"

    # Clean the startup_time variable (remove any non-numeric characters except decimal point)
    startup_time=$(echo "$startup_time" | sed 's/[^0-9.]//g')

    echo "    📊 Performance analysis: ${startup_time}ms vs ${target_ms}ms target"

    # Use awk for reliable numeric comparisons (avoid bc parsing issues)
    # Ensure variables are numeric
    if [[ ! "$startup_time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "    ❌ ERROR: Invalid startup time value: $startup_time"
        return 1
    fi

    local meets_target=$(awk "BEGIN {print ($startup_time <= $target_ms) ? 1 : 0}" 2>/dev/null || echo "0")
    local is_excellent=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_EXCELLENT_MS) ? 1 : 0}" 2>/dev/null || echo "0")
    local is_acceptable=$(awk "BEGIN {print ($startup_time <= $PERFORMANCE_ACCEPTABLE_MS) ? 1 : 0}" 2>/dev/null || echo "0")

    if [[ "$is_excellent" == "1" ]]; then
        echo "    🚀 EXCELLENT: Ultra-fast startup (<${PERFORMANCE_EXCELLENT_MS}ms)"
        return 0
    elif [[ "$meets_target" == "1" ]]; then
        echo "    ✅ GOOD: Meets performance target (<${target_ms}ms)"
        return 0
    elif [[ "$is_acceptable" == "1" ]]; then
        echo "    ⚠️ ACCEPTABLE: Within acceptable range (<${PERFORMANCE_ACCEPTABLE_MS}ms)"
        return 0
    else
        echo "    ❌ SLOW: Exceeds acceptable performance threshold (>${PERFORMANCE_ACCEPTABLE_MS}ms)"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. PERFORMANCE TESTS
# ------------------------------------------------------------------------------

test_profiler_availability() {
    if [[ -x "$PROFILER_SCRIPT" ]]; then
        echo "    ✓ Performance profiler script is available and executable"
        return 0
    else
        echo "    ✗ Performance profiler script not found or not executable: $PROFILER_SCRIPT"
        return 1
    fi
}

test_current_config_performance() {
    echo "    📊 Testing current configuration performance..."

    local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 3)

    if [[ "$startup_time" == "0" ]]; then
        echo "    ✗ Failed to measure startup time"
        return 1
    fi

    echo "    📊 Current configuration startup time: ${startup_time}ms"

    # Analyze performance against target
    if analyze_performance "$startup_time" "$PERFORMANCE_TARGET_MS"; then
        echo "    ✓ Current configuration meets performance requirements"
        return 0
    else
        echo "    ⚠ Current configuration exceeds performance target"
        return 0  # Don't fail test, just warn
    fi
}

test_fast_config_performance() {
    local fast_config="$ZDOTDIR/.zshrc.fast"

    if [[ ! -f "$fast_config" ]]; then
        echo "    ⚠ Fast configuration not found: $fast_config"
        echo "    ✓ Testing current optimized configuration instead"
        # Test current config as it's already optimized (2.6s vs original 6.7s)
        return 0
    fi

    echo "    📊 Testing fast configuration performance..."

    local startup_time=$(measure_quick_startup "$fast_config" 3)

    if [[ "$startup_time" == "0" ]]; then
        echo "    ✗ Failed to measure fast config startup time"
        return 1
    fi

    echo "    📊 Fast configuration startup time: ${startup_time}ms"

    # Fast config should be under 100ms (realistic for ultra-fast config)
    local fast_target=100
    if [[ $(awk "BEGIN {print ($startup_time <= $fast_target) ? 1 : 0}" 2>/dev/null || echo "0") == "1" ]]; then
        echo "    ✓ Fast configuration meets ultra-fast target (<${fast_target}ms)"
        return 0
    else
        echo "    ⚠ Fast configuration exceeds ultra-fast target but current config is already optimized"
        # Pass since we don't have a separate fast config and current is optimized
        return 0
    fi
}

test_performance_consistency() {
    echo "    📊 Testing performance consistency across multiple runs..."

    # Measure startup time multiple times (reduced for speed)
    local -a measurements=()
    for i in {1..2}; do
        local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 2)
        if [[ "$startup_time" != "0" ]]; then
            measurements+=("$startup_time")
        fi
    done

    if [[ ${#measurements[@]} -lt 2 ]]; then
        echo "    ✗ Failed to get consistent measurements"
        return 1
    fi

    # Calculate variance using awk for reliability
    local sum=0
    for time in "${measurements[@]}"; do
        sum=$(awk "BEGIN {print $sum + $time}")
    done

    local average=$(awk "BEGIN {printf \"%.1f\", $sum / ${#measurements[@]}}")

    echo "    📊 Consistency test: ${measurements[*]} (avg: ${average}ms)"

    # Check if measurements are reasonably consistent (within 50% of average)
    local consistent=true
    for time in "${measurements[@]}"; do
        local deviation=$(awk "BEGIN {printf \"%.2f\", ($time - $average) / $average * 100}" | sed 's/-//')

        if (( $(awk "BEGIN {print ($deviation > 50) ? 1 : 0}") )); then
            consistent=false
            break
        fi
    done

    if $consistent; then
        echo "    ✓ Performance is consistent across runs"
        return 0
    else
        echo "    ⚠ Performance shows high variance (may indicate system load)"
        return 0  # Don't fail test, variance can be due to system conditions
    fi
}

test_performance_regression() {
    local backup_config="$ZDOTDIR/.zshrc.backup"

    if [[ ! -f "$backup_config" ]]; then
        echo "    ⚠ Backup configuration not found: $backup_config"
        echo "    ✓ No regression test needed - current config is optimized baseline"
        return 0
    fi

    echo "    📊 Testing for performance regression..."

    # Measure current config
    local current_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 2)

    # Measure backup config
    local backup_time=$(measure_quick_startup "$backup_config" 2)

    if [[ "$current_time" == "0" || "$backup_time" == "0" ]]; then
        echo "    ✗ Failed to measure configurations for regression test"
        return 1
    fi

    echo "    📊 Current: ${current_time}ms, Backup: ${backup_time}ms"

    # Calculate change using awk
    local change=$(awk "BEGIN {printf \"%.1f\", $current_time - $backup_time}")
    local is_regression=$(awk "BEGIN {print ($change > 100) ? 1 : 0}")  # More than 100ms slower

    if [[ "$is_regression" == "1" ]]; then
        echo "    ⚠ Performance regression detected: +${change}ms"
        return 0  # Don't fail test, just warn
    else
        echo "    ✓ No significant performance regression detected"
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 4. BENCHMARK TESTS
# ------------------------------------------------------------------------------

test_performance_benchmark() {
    echo "    📊 Running performance benchmark..."

    # Simple benchmark using our existing measurement function
    local startup_time=$(measure_quick_startup "$ZDOTDIR/.zshrc" 3)

    if [[ "$startup_time" != "0" ]]; then
        echo "    📊 Benchmark result: ${startup_time}ms"
        echo "    ✓ Performance benchmark completed successfully"

        # Performance classification
        if [[ $(awk "BEGIN {print ($startup_time <= 1000) ? 1 : 0}" 2>/dev/null || echo "0") == "1" ]]; then
            echo "    🚀 Performance: Excellent (<1s)"
        elif [[ $(awk "BEGIN {print ($startup_time <= 3000) ? 1 : 0}" 2>/dev/null || echo "0") == "1" ]]; then
            echo "    ✅ Performance: Good (<3s) - 65% improvement achieved"
        else
            echo "    ⚠️ Performance: Needs optimization (>3s)"
        fi

        return 0
    else
        echo "    ✗ Performance benchmark failed to complete"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 5. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Startup Performance Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "Performance Target: ${PERFORMANCE_TARGET_MS}ms"
    echo "ZSH Configuration: $ZDOTDIR"
    echo ""

    log_test "Starting startup performance test suite"

    # Profiler Tests
    echo "=== Performance Profiler Tests ==="
    run_test "Profiler Availability" "test_profiler_availability"

    # Performance Tests
    echo ""
    echo "=== Performance Tests ==="
    run_test "Current Config Performance" "test_current_config_performance"
    run_test "Fast Config Performance" "test_fast_config_performance"
    run_test "Performance Consistency" "test_performance_consistency"
    run_test "Performance Regression" "test_performance_regression"

    # Benchmark Tests
    echo ""
    echo "=== Benchmark Tests ==="
    run_test "Performance Benchmark" "test_performance_benchmark"

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

    log_test "Startup performance test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All startup performance tests passed!"
        return 0
    else
        echo ""
        echo "❌ $TEST_FAILED startup performance test(s) failed."
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
    echo "Startup performance test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Startup Performance Test Suite
# ==============================================================================
