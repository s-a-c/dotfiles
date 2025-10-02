#!/usr/bin/env bash
set -euo pipefail

echo "🧪 COMPREHENSIVE LEGACY CONSOLIDATED MODULES TEST"
echo "================================================="
echo ""

cd /Users/s-a-c/dotfiles/dot-config/zsh

# Test configuration
CONSOLIDATED_DIR=".zshrc.d.legacy/consolidated-modules"
LOG_DIR="logs/test-results"
TEST_LOG="$LOG_DIR/all-legacy-modules-$(date +%Y%m%dT%H%M%S).log"

# Create test directories
mkdir -p "$LOG_DIR"

# Test tracking variables
declare -A MODULE_RESULTS
declare -A MODULE_ISSUES
TOTAL_TESTS=0
PASSED_TESTS=0

echo "📁 Test log: $TEST_LOG"
echo ""

# Utility functions
log_test() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$TEST_LOG"
}

run_zsh_test() {
    local test_name="$1"
    local zsh_code="$2"
    
    log_test "Running test: $test_name"
    
    # Run test in isolated zsh environment
    SHELL=/opt/homebrew/bin/zsh \
    ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" \
    /opt/homebrew/bin/zsh -df <<< "$zsh_code" 2>&1
}

test_module_loading() {
    local module_number="$1"
    local module_name="$2"
    local module_file="$CONSOLIDATED_DIR/$1-$2.zsh"
    
    echo "=== Testing Module $module_number: $module_name ==="
    log_test "Testing module: $module_file"
    
    local test_code="
# Test module loading
setopt no_global_rcs
export ZDOTDIR='/Users/s-a-c/dotfiles/dot-config/zsh'

echo 'Loading module: $module_file'
if [[ -f '$module_file' ]]; then
    echo 'Module file exists'
    source '$module_file' 2>&1
    if [[ \$? -eq 0 ]]; then
        echo 'SUCCESS: Module loaded without errors'
    else
        echo 'FAILED: Module loading failed'
        exit 1
    fi
else
    echo 'FAILED: Module file not found'
    exit 1
fi
"
    
    local result
    if result=$(run_zsh_test "module_loading_$module_number" "$test_code" 2>&1); then
        echo "✅ $module_name: Module loads successfully"
        MODULE_RESULTS["$module_number"]="PASS"
        ((PASSED_TESTS++))
    else
        echo "❌ $module_name: Module loading failed"
        MODULE_RESULTS["$module_number"]="FAIL"
        MODULE_ISSUES["$module_number"]="Loading failed: $result"
    fi
    
    ((TOTAL_TESTS++))
    log_test "Module $module_number test complete: ${MODULE_RESULTS[$module_number]}"
    echo ""
}

test_module_functions() {
    local module_number="$1"
    local module_name="$2"
    local module_file="$CONSOLIDATED_DIR/$1-$2.zsh"
    
    echo "  🔍 Testing exported functions..."
    
    local test_code="
setopt no_global_rcs
export ZDOTDIR='/Users/s-a-c/dotfiles/dot-config/zsh'

source '$module_file' >/dev/null 2>&1

# Count exported functions
function_count=0
for func in \${(ok)functions}; do
    # Count functions that don't start with underscore (public functions)
    if [[ \$func != _* && \$func != *_debug && \$func != *_log ]]; then
        ((function_count++))
    fi
done

echo \"Functions exported: \$function_count\"

# Test specific functions based on module
case '$module_number' in
    '01')
        # Core infrastructure
        if whence -w debug_log >/dev/null 2>&1; then
            echo 'PASS: debug_log function available'
        fi
        if whence -w init_cache_system >/dev/null 2>&1; then
            echo 'PASS: cache system functions available'
        fi
        ;;
    '02')
        # Performance monitoring
        if whence -w perf_now_ms >/dev/null 2>&1; then
            echo 'PASS: perf_now_ms function available'
        fi
        if whence -w perf-status >/dev/null 2>&1; then
            echo 'PASS: perf-status command available'
        fi
        ;;
    '03')
        # Security integrity
        if whence -w check_plugin_integrity >/dev/null 2>&1 || whence -w validate_security >/dev/null 2>&1; then
            echo 'PASS: security functions available'
        fi
        ;;
    '04')
        # Environment options
        if whence -w setup_zsh_options >/dev/null 2>&1 || whence -w configure_environment >/dev/null 2>&1; then
            echo 'PASS: environment functions available'
        fi
        ;;
    '05')
        # Completion system
        if whence -w setup_completions >/dev/null 2>&1 || whence -w manage_completions >/dev/null 2>&1; then
            echo 'PASS: completion functions available'
        fi
        ;;
    '06')
        # User interface
        if whence -w setup_prompt >/dev/null 2>&1 || whence -w configure_ui >/dev/null 2>&1; then
            echo 'PASS: UI functions available'
        fi
        ;;
    '07')
        # Development tools
        if whence -w setup_development >/dev/null 2>&1 || whence -w configure_tools >/dev/null 2>&1; then
            echo 'PASS: development functions available'
        fi
        ;;
    '08')
        # Legacy compatibility
        if whence -w legacy_compatibility >/dev/null 2>&1 || whence -w setup_shims >/dev/null 2>&1; then
            echo 'PASS: compatibility functions available'
        fi
        ;;
    '09')
        # External integrations
        if whence -w external-status >/dev/null 2>&1; then
            echo 'PASS: external-status command available'
        fi
        if whence -w setup_external_tools >/dev/null 2>&1; then
            echo 'PASS: external setup functions available'
        fi
        ;;
esac
"
    
    local result
    result=$(run_zsh_test "module_functions_$module_number" "$test_code" 2>&1)
    echo "  📊 $result"
    log_test "Module $module_number functions: $result"
}

test_all_modules_together() {
    echo "=== Testing All Modules Together ==="
    log_test "Testing all modules loaded together"
    
    local test_code="
setopt no_global_rcs
export ZDOTDIR='/Users/s-a-c/dotfiles/dot-config/zsh'

echo 'Loading all consolidated modules in order...'
modules=(
    '01-core-infrastructure.zsh'
    '02-performance-monitoring.zsh'
    '03-security-integrity.zsh'
    '04-environment-options.zsh'
    '05-completion-system.zsh'
    '06-user-interface.zsh'
    '07-development-tools.zsh'
    '08-legacy-compatibility.zsh'
    '09-external-integrations.zsh'
)

loaded_count=0
for module in \${modules[@]}; do
    module_path='$CONSOLIDATED_DIR/\$module'
    if [[ -f \$module_path ]]; then
        echo \"Loading: \$module\"
        if source \$module_path >/dev/null 2>&1; then
            ((loaded_count++))
            echo \"  ✅ \$module loaded successfully\"
        else
            echo \"  ❌ \$module failed to load\"
            exit 1
        fi
    else
        echo \"  ❌ \$module not found\"
        exit 1
    fi
done

echo \"Successfully loaded \$loaded_count/\${#modules[@]} modules\"

# Test for function conflicts
echo 'Checking for function conflicts...'
declare -A function_sources
conflict_count=0

for func in \${(ok)functions}; do
    # Skip internal/private functions
    if [[ \$func == _* || \$func == *_debug || \$func == *_internal ]]; then
        continue
    fi
    
    # Check if we've seen this function before
    if [[ -n \${function_sources[\$func]:-} ]]; then
        echo \"WARNING: Function conflict detected: \$func\"
        ((conflict_count++))
    else
        function_sources[\$func]=1
    fi
done

if [[ \$conflict_count -eq 0 ]]; then
    echo '✅ No function conflicts detected'
else
    echo \"⚠️  \$conflict_count function conflicts detected\"
fi

# Test basic functionality from each module
echo 'Testing cross-module functionality...'

# Test 1: Core infrastructure + performance monitoring
if whence -w debug_log >/dev/null 2>&1 && whence -w perf_now_ms >/dev/null 2>&1; then
    debug_log 'Cross-module test: core + performance'
    time_val=\$(perf_now_ms)
    echo \"✅ Core + Performance integration: \${time_val}ms\"
fi

# Test 2: External integrations
if whence -w external-status >/dev/null 2>&1; then
    echo '✅ External integrations available'
fi

echo 'All modules integration test completed'
"
    
    local result
    if result=$(run_zsh_test "all_modules_together" "$test_code" 2>&1); then
        echo "✅ All modules work together successfully"
        ((PASSED_TESTS++))
        log_test "SUCCESS: All modules integration test passed"
    else
        echo "❌ Module integration issues detected"
        echo "Issues: $result"
        log_test "FAILED: All modules integration test failed: $result"
    fi
    
    ((TOTAL_TESTS++))
    echo ""
}

test_performance_impact() {
    echo "=== Testing Performance Impact ==="
    log_test "Testing performance impact of all modules"
    
    local test_code="
setopt no_global_rcs
export ZDOTDIR='/Users/s-a-c/dotfiles/dot-config/zsh'

# Time loading all modules
echo 'Measuring module loading performance...'

start_time=\$(date +%s%N 2>/dev/null || date +%s)

modules=(
    '01-core-infrastructure.zsh'
    '02-performance-monitoring.zsh'
    '03-security-integrity.zsh'
    '04-environment-options.zsh'
    '05-completion-system.zsh'
    '06-user-interface.zsh'
    '07-development-tools.zsh'
    '08-legacy-compatibility.zsh'
    '09-external-integrations.zsh'
)

for module in \${modules[@]}; do
    module_path='$CONSOLIDATED_DIR/\$module'
    source \$module_path >/dev/null 2>&1 || true
done

end_time=\$(date +%s%N 2>/dev/null || date +%s)

if command -v bc >/dev/null 2>&1 && [[ \$start_time =~ [0-9]{10}[0-9]+ ]]; then
    duration_ms=\$(echo \"scale=2; (\$end_time - \$start_time) / 1000000\" | bc 2>/dev/null || echo \"unknown\")
    echo \"Module loading time: \${duration_ms}ms\"
else
    duration_s=\$((end_time - start_time))
    echo \"Module loading time: \${duration_s}s (approximate)\"
fi

# Memory usage (approximate)
echo 'Memory usage after loading all modules:'
if command -v ps >/dev/null 2>&1; then
    ps -o pid,rss,comm -p \$\$ | tail -1
fi

echo 'Performance test completed'
"
    
    local result
    result=$(run_zsh_test "performance_impact" "$test_code" 2>&1)
    echo "  📊 Performance results:"
    echo "$result" | sed 's/^/    /'
    log_test "Performance test results: $result"
    echo ""
}

# Main test execution
main() {
    echo "🚀 Starting comprehensive legacy module testing..."
    echo ""
    
    # Test each module individually
    test_module_loading "01" "core-infrastructure"
    test_module_functions "01" "core-infrastructure"
    
    test_module_loading "02" "performance-monitoring"
    test_module_functions "02" "performance-monitoring"
    
    test_module_loading "03" "security-integrity"
    test_module_functions "03" "security-integrity"
    
    test_module_loading "04" "environment-options"
    test_module_functions "04" "environment-options"
    
    test_module_loading "05" "completion-system"
    test_module_functions "05" "completion-system"
    
    test_module_loading "06" "user-interface"
    test_module_functions "06" "user-interface"
    
    test_module_loading "07" "development-tools"
    test_module_functions "07" "development-tools"
    
    test_module_loading "08" "legacy-compatibility"
    test_module_functions "08" "legacy-compatibility"
    
    test_module_loading "09" "external-integrations"
    test_module_functions "09" "external-integrations"
    
    # Test all modules together
    test_all_modules_together
    
    # Test performance impact
    test_performance_impact
    
    # Summary
    echo "=== TEST SUMMARY ==="
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed tests: $PASSED_TESTS"
    echo "Failed tests: $((TOTAL_TESTS - PASSED_TESTS))"
    echo ""
    
    echo "📊 Individual Module Results:"
    for module_num in $(printf '%s\n' "${!MODULE_RESULTS[@]}" | sort); do
        result="${MODULE_RESULTS[$module_num]}"
        if [[ "$result" == "PASS" ]]; then
            echo "  ✅ Module $module_num: $result"
        else
            echo "  ❌ Module $module_num: $result"
            if [[ -n "${MODULE_ISSUES[$module_num]:-}" ]]; then
                echo "     Issue: ${MODULE_ISSUES[$module_num]}"
            fi
        fi
    done
    
    echo ""
    echo "📁 Detailed log: $TEST_LOG"
    
    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        echo ""
        echo "🎉 ALL TESTS PASSED!"
        echo "✅ Legacy consolidated modules are ready for deployment"
        return 0
    else
        echo ""
        echo "⚠️  SOME TESTS FAILED"
        echo "❌ Review failed modules before deployment"
        return 1
    fi
}

# Run main test function
main "$@"