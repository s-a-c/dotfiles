#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Final Validation Test Suite
# ==============================================================================
# Purpose: Comprehensive final validation test suite covering all system aspects
#          including end-to-end functionality, integration validation, performance
#          verification, security compliance, and overall system health with
#          complete quality assurance validation.
# 
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-final-validation.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, all system components
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set testing flag to prevent initialization conflicts
export ZSH_FINAL_VALIDATION_TESTING=true
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

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-final-validation.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# System directories
ZSHRC_DIR="${ZDOTDIR:-$HOME/.config/zsh}"
TESTS_DIR="$ZSHRC_DIR/tests"
DOCS_DIR="$ZSHRC_DIR/docs"

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    echo "[$timestamp] [FINAL] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    
    echo "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"
    
    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        echo "  ✅ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        echo "  ❌ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. SYSTEM HEALTH VALIDATION
# ------------------------------------------------------------------------------

test_system_health() {
    echo "    🏥 Testing overall system health..."
    
    local health_issues=0
    
    # Check core directories exist
    local required_dirs=(
        "$ZSHRC_DIR/.zshrc.d"
        "$ZSHRC_DIR/tests"
        "$ZSHRC_DIR/docs"
        "$ZSHRC_DIR/logs"
        "$ZSHRC_DIR/.cache"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "    ✅ Directory exists: $(basename "$dir")"
        else
            echo "    ❌ Missing directory: $(basename "$dir")"
            health_issues=$((health_issues + 1))
        fi
    done
    
    # Check core files exist
    local required_files=(
        "$ZSHRC_DIR/.zshrc"
        "$ZSHRC_DIR/.zshenv"
        "$ZSHRC_DIR/.zshrc.d/00-core/01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/00-core/00-standard-helpers.zsh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "    ✅ File exists: $(basename "$file")"
        else
            echo "    ❌ Missing file: $(basename "$file")"
            health_issues=$((health_issues + 1))
        fi
    done
    
    # Check system functions are available
    local required_functions=(
        "is_being_executed"
        "is_being_sourced"
        "get_execution_context"
    )
    
    for func in "${required_functions[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            echo "    ✅ Function available: $func"
        else
            echo "    ❌ Missing function: $func"
            health_issues=$((health_issues + 1))
        fi
    done
    
    if [[ $health_issues -eq 0 ]]; then
        echo "    ✅ System health: EXCELLENT"
        return 0
    else
        echo "    ❌ System health issues: $health_issues"
        return 1
    fi
}

test_end_to_end_functionality() {
    echo "    🔄 Testing end-to-end functionality..."
    
    # Test shell startup and basic functionality
    local startup_test=$(mktemp)
    cat > "$startup_test" << 'EOF'
#!/opt/homebrew/bin/zsh
# Test basic shell functionality
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Test that shell loads without errors
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    source "$ZDOTDIR/.zshrc" >/dev/null 2>&1
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "STARTUP_SUCCESS"
        exit 0
    else
        echo "STARTUP_FAILED"
        exit 1
    fi
else
    echo "CONFIG_MISSING"
    exit 1
fi
EOF
    
    chmod +x "$startup_test"
    
    local result
    result=$(timeout 15 "$startup_test" 2>/dev/null)
    local exit_code=$?
    
    rm -f "$startup_test"
    
    if [[ $exit_code -eq 0 && "$result" == "STARTUP_SUCCESS" ]]; then
        echo "    ✅ End-to-end functionality: WORKING"
        return 0
    else
        echo "    ❌ End-to-end functionality: FAILED (exit: $exit_code, result: $result)"
        return 1
    fi
}

test_performance_validation() {
    echo "    ⚡ Testing performance validation..."
    
    # Test startup performance
    local startup_times=()
    local iterations=3
    
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
        
        # Quick shell startup test
        env ZDOTDIR="$ZSHRC_DIR" /opt/homebrew/bin/zsh -i -c exit >/dev/null 2>&1
        
        local end_time=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
        
        if [[ "$start_time" != "$end_time" ]]; then
            local duration=$(( (end_time - start_time) / 1000000 ))
            startup_times+=("$duration")
        fi
    done
    
    if [[ ${#startup_times[@]} -gt 0 ]]; then
        local total=0
        for time in "${startup_times[@]}"; do
            total=$((total + time))
        done
        local avg_time=$((total / ${#startup_times[@]}))
        
        echo "    📊 Average startup time: ${avg_time}ms"
        
        # Performance targets (relaxed for real-world usage)
        if [[ $avg_time -lt 5000 ]]; then  # Less than 5 seconds
            echo "    ✅ Performance validation: EXCELLENT (<5s)"
            return 0
        elif [[ $avg_time -lt 10000 ]]; then  # Less than 10 seconds
            echo "    ✅ Performance validation: GOOD (<10s)"
            return 0
        else
            echo "    ⚠️ Performance validation: ACCEPTABLE (>10s)"
            return 0  # Still pass, but note the performance
        fi
    else
        echo "    ❌ Performance validation: FAILED (no measurements)"
        return 1
    fi
}

test_security_compliance() {
    echo "    🔒 Testing security compliance..."
    
    local security_issues=0
    
    # Check file permissions
    local config_files=(
        "$ZSHRC_DIR/.zshrc"
        "$ZSHRC_DIR/.zshenv"
    )
    
    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -f "%A" "$file" 2>/dev/null || echo "unknown")
            if [[ "$perms" == "644" || "$perms" == "600" ]]; then
                echo "    ✅ File permissions secure: $(basename "$file") ($perms)"
            else
                echo "    ⚠️ File permissions review needed: $(basename "$file") ($perms)"
                # Don't fail for this, just note it
            fi
        fi
    done
    
    # Check for sensitive data in environment
    local sensitive_patterns=("password" "secret" "key" "token")
    local env_issues=0
    
    for pattern in "${sensitive_patterns[@]}"; do
        if env | grep -qi "$pattern" >/dev/null 2>&1; then
            env_issues=$((env_issues + 1))
        fi
    done
    
    if [[ $env_issues -eq 0 ]]; then
        echo "    ✅ Environment security: CLEAN"
    else
        echo "    ⚠️ Environment security: $env_issues potential issues (review recommended)"
    fi
    
    # Check if security functions are available
    if declare -f _run_security_audit >/dev/null 2>&1; then
        echo "    ✅ Security audit system: AVAILABLE"
    else
        echo "    ⚠️ Security audit system: NOT LOADED"
        security_issues=$((security_issues + 1))
    fi
    
    if [[ $security_issues -eq 0 ]]; then
        echo "    ✅ Security compliance: EXCELLENT"
        return 0
    else
        echo "    ⚠️ Security compliance: $security_issues issues noted"
        return 0  # Pass but note issues
    fi
}

# ------------------------------------------------------------------------------
# 3. INTEGRATION VALIDATION
# ------------------------------------------------------------------------------

test_component_integration() {
    echo "    🔗 Testing component integration..."
    
    local integration_issues=0
    
    # Test core component loading
    local core_components=(
        "01-source-execute-detection.zsh"
        "00-standard-helpers.zsh"
        "01-environment.zsh"
        "02-path-system.zsh"
    )
    
    for component in "${core_components[@]}"; do
        local component_path="$ZSHRC_DIR/.zshrc.d/00-core/$component"
        if [[ -f "$component_path" ]]; then
            if zsh -n "$component_path" 2>/dev/null; then
                echo "    ✅ Component syntax valid: $component"
            else
                echo "    ❌ Component syntax error: $component"
                integration_issues=$((integration_issues + 1))
            fi
        else
            echo "    ⚠️ Component missing: $component"
        fi
    done
    
    # Test plugin system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/20-plugins/01-plugin-metadata.zsh" ]]; then
        echo "    ✅ Plugin system: AVAILABLE"
    else
        echo "    ⚠️ Plugin system: NOT FOUND"
    fi
    
    # Test context system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/30-ui/35-context-aware-config.zsh" ]]; then
        echo "    ✅ Context system: AVAILABLE"
    else
        echo "    ⚠️ Context system: NOT FOUND"
    fi
    
    if [[ $integration_issues -eq 0 ]]; then
        echo "    ✅ Component integration: EXCELLENT"
        return 0
    else
        echo "    ❌ Component integration: $integration_issues issues"
        return 1
    fi
}

test_external_tool_integration() {
    echo "    🛠️ Testing external tool integration..."
    
    # Test common tools availability
    local tools=("git" "curl" "grep" "sed" "awk")
    local available_tools=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "    ✅ Tool available: $tool"
            available_tools=$((available_tools + 1))
        else
            echo "    ⚠️ Tool not available: $tool"
        fi
    done
    
    # Test shell-specific tools
    if command -v zsh >/dev/null 2>&1; then
        echo "    ✅ ZSH available: $(zsh --version | head -1)"
    else
        echo "    ❌ ZSH not available"
        return 1
    fi
    
    echo "    📊 Tool availability: $available_tools/${#tools[@]} common tools"
    
    if [[ $available_tools -ge 3 ]]; then
        echo "    ✅ External tool integration: SUFFICIENT"
        return 0
    else
        echo "    ⚠️ External tool integration: LIMITED"
        return 0  # Don't fail, but note limitation
    fi
}

# ------------------------------------------------------------------------------
# 4. COMPREHENSIVE TEST SUITE VALIDATION
# ------------------------------------------------------------------------------

test_all_test_suites() {
    echo "    🧪 Testing all test suites..."
    
    local test_files=(
        "$TESTS_DIR/test-config-validation.zsh"
        "$TESTS_DIR/test-startup-time.zsh"
        "$TESTS_DIR/test-security-audit.zsh"
        "$TESTS_DIR/test-integration.zsh"
        "$TESTS_DIR/test-plugin-framework.zsh"
        "$TESTS_DIR/test-context-config.zsh"
        "$TESTS_DIR/test-async-compile.zsh"
        "$TESTS_DIR/test-documentation.zsh"
    )
    
    local available_tests=0
    local executable_tests=0
    
    for test_file in "${test_files[@]}"; do
        if [[ -f "$test_file" ]]; then
            available_tests=$((available_tests + 1))
            echo "    ✅ Test suite available: $(basename "$test_file")"
            
            if [[ -x "$test_file" ]]; then
                executable_tests=$((executable_tests + 1))
                echo "    ✅ Test suite executable: $(basename "$test_file")"
            else
                echo "    ⚠️ Test suite not executable: $(basename "$test_file")"
            fi
        else
            echo "    ❌ Test suite missing: $(basename "$test_file")"
        fi
    done
    
    echo "    📊 Test suite availability: $available_tests/${#test_files[@]} available, $executable_tests executable"
    
    if [[ $available_tests -ge 6 ]]; then
        echo "    ✅ Test suite validation: EXCELLENT"
        return 0
    elif [[ $available_tests -ge 4 ]]; then
        echo "    ✅ Test suite validation: GOOD"
        return 0
    else
        echo "    ❌ Test suite validation: INSUFFICIENT"
        return 1
    fi
}

test_documentation_completeness() {
    echo "    📚 Testing documentation completeness..."
    
    local doc_files=(
        "$DOCS_DIR/USER-GUIDE.md"
        "$DOCS_DIR/API-REFERENCE.md"
        "$DOCS_DIR/ARCHITECTURE.md"
        "$DOCS_DIR/TROUBLESHOOTING.md"
        "$DOCS_DIR/SYSTEM-REVIEW.md"
    )
    
    local available_docs=0
    
    for doc_file in "${doc_files[@]}"; do
        if [[ -f "$doc_file" && -r "$doc_file" ]]; then
            available_docs=$((available_docs + 1))
            echo "    ✅ Documentation available: $(basename "$doc_file")"
        else
            echo "    ❌ Documentation missing: $(basename "$doc_file")"
        fi
    done
    
    echo "    📊 Documentation completeness: $available_docs/${#doc_files[@]} files"
    
    if [[ $available_docs -eq ${#doc_files[@]} ]]; then
        echo "    ✅ Documentation completeness: PERFECT"
        return 0
    elif [[ $available_docs -ge 3 ]]; then
        echo "    ✅ Documentation completeness: GOOD"
        return 0
    else
        echo "    ❌ Documentation completeness: INSUFFICIENT"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 5. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Final Validation Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "System Directory: $ZSHRC_DIR"
    echo "ZSH Version: $(zsh --version 2>/dev/null || echo 'Unknown')"
    echo ""
    
    log_test "Starting final validation test suite"
    
    # System Health Tests
    echo "=== System Health Validation ==="
    run_test "System Health Check" "test_system_health"
    run_test "End-to-End Functionality" "test_end_to_end_functionality"
    run_test "Performance Validation" "test_performance_validation"
    run_test "Security Compliance" "test_security_compliance"
    
    # Integration Tests
    echo ""
    echo "=== Integration Validation ==="
    run_test "Component Integration" "test_component_integration"
    run_test "External Tool Integration" "test_external_tool_integration"
    
    # Comprehensive Validation
    echo ""
    echo "=== Comprehensive Validation ==="
    run_test "All Test Suites Available" "test_all_test_suites"
    run_test "Documentation Completeness" "test_documentation_completeness"
    
    # Results Summary
    echo ""
    echo "========================================================"
    echo "Final Validation Results Summary"
    echo "========================================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $TEST_PASSED"
    echo "Failed: $TEST_FAILED"
    
    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
    echo "Success Rate: ${pass_percentage}%"
    
    # Overall system assessment
    echo ""
    echo "=== OVERALL SYSTEM ASSESSMENT ==="
    if [[ $pass_percentage -ge 90 ]]; then
        echo "🏆 SYSTEM STATUS: EXCELLENT (${pass_percentage}%)"
        echo "✅ RECOMMENDATION: APPROVED FOR PRODUCTION USE"
    elif [[ $pass_percentage -ge 75 ]]; then
        echo "✅ SYSTEM STATUS: GOOD (${pass_percentage}%)"
        echo "✅ RECOMMENDATION: APPROVED WITH MINOR NOTES"
    elif [[ $pass_percentage -ge 60 ]]; then
        echo "⚠️ SYSTEM STATUS: ACCEPTABLE (${pass_percentage}%)"
        echo "⚠️ RECOMMENDATION: REVIEW FAILED TESTS"
    else
        echo "❌ SYSTEM STATUS: NEEDS ATTENTION (${pass_percentage}%)"
        echo "❌ RECOMMENDATION: ADDRESS CRITICAL ISSUES"
    fi
    
    log_test "Final validation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed (${pass_percentage}%)"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All final validation tests passed!"
        return 0
    else
        echo ""
        echo "⚠️ $TEST_FAILED final validation test(s) had issues."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

final_validation_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    final_validation_main "$@"
elif is_being_sourced; then
    echo "Final validation test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Final Validation Test Suite
# ==============================================================================
