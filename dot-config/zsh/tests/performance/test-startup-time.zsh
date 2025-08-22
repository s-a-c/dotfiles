#!/usr/bin/env zsh
#=============================================================================
# File: test-startup-time.zsh
# Purpose: Automated testing of ZSH startup time performance
# Dependencies: zsh, bc
# Author: Configuration management system
# Last Modified: 2025-01-08
#=============================================================================

# Save and restore working directory, set up logging
_test_original_pwd="$(pwd)"
_test_log_date="$(date '+%Y-%m-%d')"
_test_log_dir="$HOME/.config/zsh/logs/$_test_log_date"
_test_log_file="$_test_log_dir/test-startup-time-$(date '+%H-%M-%S').log"

# Ensure log directory exists
[[ ! -d "$_test_log_dir" ]] && mkdir -p "$_test_log_dir"

# Output to both log file and console (simplified for debugging)
# exec > >(tee -a "$_test_log_file") 2>&1

# Test setup and initialization
_test_setup() {
    echo "==============================================================================" 
    echo "ZSH Startup Time Performance Test"
    echo "Started: $(date)"
    echo "Log file: $_test_log_file"
    echo "=============================================================================="
    
    # Check for required dependencies
    if ! command -v bc >/dev/null 2>&1; then
        echo "❌ ERROR: bc is required for calculations but not found"
        exit 1
    fi
    
    # Create temporary directory for test files
    _test_temp_dir="/tmp/zsh-startup-test.$$"
    mkdir -p "$_test_temp_dir"
}

# Function to measure startup time with different configurations
_test_startup_performance() {
    echo
    echo "📊 Testing ZSH startup performance..."
    
    local iterations=5
    local config_dir="$HOME/.config/zsh"
    
    # Test 1: Current configuration
    echo "  Test 1: Current configuration (${iterations} iterations)"
    _measure_config_startup "$config_dir/zshrc" $iterations "current"
    
    # Test 2: Minimal configuration (if exists)
    if [[ -f "$config_dir/minimal.zsh" ]]; then
        echo "  Test 2: Minimal configuration (${iterations} iterations)"
        _measure_config_startup "$config_dir/minimal.zsh" $iterations "minimal"
    fi
    
    # Test 3: No configuration (baseline)
    echo "  Test 3: No configuration baseline (${iterations} iterations)"
    _measure_config_startup "/dev/null" $iterations "none"
}

# Function to measure startup time for a specific configuration
_measure_config_startup() {
    local config_file="$1"
    local iterations="$2"
    local test_name="$3"
    local times=()
    
    for ((i=1; i<=iterations; i++)); do
        echo -n "    Iteration $i/$iterations: "
        
        # Create temporary test script
        local test_script="$_test_temp_dir/test_$test_name.zsh"
        cat > "$test_script" <<EOF
# Source configuration if it exists
[[ -f "$config_file" && -s "$config_file" ]] && source "$config_file"
# Immediately exit after configuration loading
exit 0
EOF
        
        # Measure startup time
        local start_time=$(date +%s.%N)
        timeout 10s zsh "$test_script" >/dev/null 2>&1
        local exit_code=$?
        local end_time=$(date +%s.%N)
        
        # Calculate duration in milliseconds
        local duration=$(echo "($end_time - $start_time) * 1000" | bc -l 2>/dev/null || echo "0")
        
        if [[ $exit_code -eq 0 ]] && [[ $duration =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$duration > 0" | bc -l 2>/dev/null || echo 0) )); then
            times+=($duration)
            echo "${duration}ms"
        else
            echo "Failed (exit code: $exit_code)"
        fi
    done
    
    # Calculate and report statistics
    if [[ ${#times[@]} -gt 0 ]]; then
        local total=0
        local min=${times[1]}
        local max=${times[1]}
        
        for time in "${times[@]}"; do
            total=$(echo "$total + $time" | bc -l)
            if (( $(echo "$time < $min" | bc -l) )); then
                min=$time
            fi
            if (( $(echo "$time > $max" | bc -l) )); then
                max=$time
            fi
        done
        
        local avg=$(echo "scale=1; $total / ${#times[@]}" | bc -l)
        
        echo "    📈 ${test_name:u} configuration stats:"
        echo "      Successful: ${#times[@]}/$iterations"
        echo "      Average: ${avg}ms"
        echo "      Min/Max: ${min}ms / ${max}ms"
        
        # Store results for comparison
        echo "$avg" > "$_test_temp_dir/avg_${test_name}.txt"
        echo "$min" > "$_test_temp_dir/min_${test_name}.txt"
        echo "$max" > "$_test_temp_dir/max_${test_name}.txt"
    else
        echo "    ❌ No successful measurements for $test_name configuration"
    fi
    
    echo
}

# Function to compare with baseline measurements
_test_compare_with_baseline() {
    echo "📊 Comparing with baseline measurements..."
    
    local baseline_avg_file="$HOME/.config/zsh/logs/baseline_avg_startup.txt"
    if [[ -f "$baseline_avg_file" ]]; then
        local baseline_avg=$(cat "$baseline_avg_file")
        local current_avg_file="$_test_temp_dir/avg_current.txt"
        
        if [[ -f "$current_avg_file" ]]; then
            local current_avg=$(cat "$current_avg_file")
            local difference=$(echo "$current_avg - $baseline_avg" | bc -l)
            local percent_change=$(echo "scale=1; ($difference / $baseline_avg) * 100" | bc -l)
            
            echo "  Baseline average: ${baseline_avg}ms"
            echo "  Current average: ${current_avg}ms"
            echo "  Difference: ${difference}ms"
            echo "  Change: ${percent_change}%"
            
            if (( $(echo "$percent_change < -5" | bc -l) )); then
                echo "  ✅ Improvement detected (>5% faster)"
            elif (( $(echo "$percent_change > 5" | bc -l) )); then
                echo "  ⚠️  Regression detected (>5% slower)"
            else
                echo "  ➖ No significant change (<5%)"
            fi
        else
            echo "  ❌ Current measurements not available for comparison"
        fi
    else
        echo "  ⚠️  No baseline measurements found. Run zsh-performance-baseline first."
    fi
}

# Function to test specific performance bottlenecks
_test_bottleneck_analysis() {
    echo "🔍 Analyzing potential bottlenecks..."
    
    # Check for expensive operations in config
    local config_dir="$HOME/.config/zsh"
    echo "  Scanning for potential bottlenecks:"
    
    # Look for eval statements
    local eval_count=$(grep -r "eval" "$config_dir"/**/*.zsh 2>/dev/null | wc -l || echo 0)
    echo "    eval statements found: $eval_count"
    
    # Look for external command calls
    local external_calls=$(grep -r "\$(.*)" "$config_dir"/**/*.zsh 2>/dev/null | wc -l || echo 0)
    echo "    Command substitutions: $external_calls"
    
    # Look for file operations
    local file_ops=$(grep -r "\[\[ -[fd]" "$config_dir"/**/*.zsh 2>/dev/null | wc -l || echo 0)
    echo "    File existence checks: $file_ops"
    
    # Check for plugin loading
    if [[ -d "$config_dir/plugins" ]]; then
        local plugin_count=$(find "$config_dir/plugins" -maxdepth 1 -type d | wc -l)
        echo "    Plugin directories: $((plugin_count - 1))"
    fi
}

# Function to validate performance targets
_test_validate_targets() {
    echo "🎯 Validating performance targets..."
    
    local current_avg_file="$_test_temp_dir/avg_current.txt"
    if [[ -f "$current_avg_file" ]]; then
        local current_avg=$(cat "$current_avg_file")
        local target_startup=300  # 300ms target
        
        echo "  Current average: ${current_avg}ms"
        echo "  Target: <${target_startup}ms"
        
        if (( $(echo "$current_avg < $target_startup" | bc -l) )); then
            echo "  ✅ Performance target met"
            return 0
        else
            local improvement_needed=$(echo "$current_avg - $target_startup" | bc -l)
            echo "  ❌ Performance target not met (need ${improvement_needed}ms improvement)"
            return 1
        fi
    else
        echo "  ❌ No current measurements available"
        return 1
    fi
}

# Test cleanup
_test_cleanup() {
    echo
    echo "🧹 Cleaning up test environment..."
    
    # Remove temporary directory
    if [[ -n "$_test_temp_dir" && -d "$_test_temp_dir" ]]; then
        rm -rf "$_test_temp_dir"
        echo "  Removed temporary directory: $_test_temp_dir"
    fi
    
    echo "  Test log saved: $_test_log_file"
}

# Main test execution
main() {
    local exit_code=0
    
    _test_setup
    _test_startup_performance
    _test_compare_with_baseline
    _test_bottleneck_analysis
    
    if ! _test_validate_targets; then
        exit_code=1
    fi
    
    _test_cleanup
    
    echo
    echo "=============================================================================="
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ All performance tests passed"
    else
        echo "❌ Some performance tests failed"
    fi
    echo "=============================================================================="
    
    return $exit_code
}

# Restore working directory on exit
trap "cd '$_test_original_pwd'" EXIT

# Execute main function if script is run directly
# Check if script is sourced or executed directly
if [[ "${ZSH_EVAL_CONTEXT:-}" == "toplevel" ]] || [[ "$0" == *"test-startup-time.zsh" ]]; then
    main "$@"
fi
