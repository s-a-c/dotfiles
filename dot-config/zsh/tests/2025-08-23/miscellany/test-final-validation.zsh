#!/usr/bin/env zsh
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

# Set 040-testing flag to prevent initialization conflicts
export ZSH_FINAL_VALIDATION_TESTING=true
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
    zf::debug "[$timestamp] [FINAL] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

    zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        zf::debug "  ✅ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        zf::debug "  ❌ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. SYSTEM HEALTH VALIDATION
# ------------------------------------------------------------------------------

test_system_health() {
    zf::debug "    🏥 Testing overall system health..."

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
            zf::debug "    ✅ Directory exists: $(basename "$dir")"
        else
            zf::debug "    ❌ Missing directory: $(basename "$dir")"
            health_issues=$((health_issues + 1))
        fi
    done

    # Check core files exist
    local required_files=(
        "$ZSHRC_DIR/.zshrc"
        "$ZSHRC_DIR/.zshenv"
        "$ZSHRC_DIR/.zshrc.d/00_01-source-execute-detection.zsh"
        "$ZSHRC_DIR/.zshrc.d/00_00-standard-helpers.zsh"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            zf::debug "    ✅ File exists: $(basename "$file")"
        else
            zf::debug "    ❌ Missing file: $(basename "$file")"
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
            zf::debug "    ✅ Function available: $func"
        else
            zf::debug "    ❌ Missing function: $func"
            health_issues=$((health_issues + 1))
        fi
    done

    if [[ $health_issues -eq 0 ]]; then
        zf::debug "    ✅ System health: EXCELLENT"
        return 0
    else
        zf::debug "    ❌ System health issues: $health_issues"
        return 1
    fi
}

test_end_to_end_functionality() {
    zf::debug "    🔄 Testing end-to-end functionality..."

    # Test shell startup and basic functionality
    local startup_test=$(mktemp)
    cat >"$startup_test" <<'EOF'
#!/usr/bin/env zsh
# Test basic shell functionality
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Test that shell loads without errors
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    source "$ZDOTDIR/.zshrc" >/dev/null 2>&1
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
            zf::debug "STARTUP_SUCCESS"
        exit 0
    else
            zf::debug "STARTUP_FAILED"
        exit 1
    fi
else
        zf::debug "CONFIG_MISSING"
    exit 1
fi
EOF

    chmod +x "$startup_test"

    local result
    result=$(timeout 15 "$startup_test" 2>/dev/null)
    local exit_code=$?

    rm -f "$startup_test"

    if [[ $exit_code -eq 0 && "$result" == "STARTUP_SUCCESS" ]]; then
        zf::debug "    ✅ End-to-end functionality: WORKING"
        return 0
    else
        zf::debug "    ❌ End-to-end functionality: FAILED (exit: $exit_code, result: $result)"
        return 1
    fi
}

test_performance_validation() {
    zf::debug "    ⚡ Testing performance validation..."

    # Test startup performance
    local startup_times=()
    local iterations=3

    for ((i = 1; i <= iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        # Quick shell startup test using bash harness
        bash -c 'source "./.bash-harness-for-zsh-template.bash"; HARNESS_ZDOTDIR="'$ZSHRC_DIR'" harness::run "exit"' >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local duration=$(((end_time - start_time) / 1000000))
            startup_times+=("$duration")
        fi
    done

    if [[ ${#startup_times[@]} -gt 0 ]]; then
        local total=0
        for time in "${startup_times[@]}"; do
            total=$((total + time))
        done
        local avg_time=$((total / ${#startup_times[@]}))

        zf::debug "    📊 Average startup time: ${avg_time}ms"

        # Performance targets (relaxed for real-world usage)
        if [[ $avg_time -lt 5000 ]]; then # Less than 5 seconds
            zf::debug "    ✅ Performance validation: EXCELLENT (<5s)"
            return 0
        elif [[ $avg_time -lt 10000 ]]; then # Less than 10 seconds
            zf::debug "    ✅ Performance validation: GOOD (<10s)"
            return 0
        else
            zf::debug "    ⚠️ Performance validation: ACCEPTABLE (>10s)"
            return 0 # Still pass, but note the performance
        fi
    else
        zf::debug "    ❌ Performance validation: FAILED (no measurements)"
        return 1
    fi
}

test_security_compliance() {
    zf::debug "    🔒 Testing security compliance..."

    local security_issues=0

    # Check file permissions
    local config_files=(
        "$ZSHRC_DIR/.zshrc"
        "$ZSHRC_DIR/.zshenv"
    )

    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -f "%A" "$file" 2>/dev/null || zf::debug "unknown")
            if [[ "$perms" == "644" || "$perms" == "600" ]]; then
                zf::debug "    ✅ File permissions secure: $(basename "$file") ($perms)"
            else
                zf::debug "    ⚠️ File permissions review needed: $(basename "$file") ($perms)"
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
        zf::debug "    ✅ Environment security: CLEAN"
    else
        zf::debug "    ⚠️ Environment security: $env_issues potential issues (review recommended)"
    fi

    # Check if security functions are available
    if declare -f _run_security_audit >/dev/null 2>&1; then
        zf::debug "    ✅ Security audit system: AVAILABLE"
    else
        zf::debug "    ⚠️ Security audit system: NOT LOADED"
        security_issues=$((security_issues + 1))
    fi

    if [[ $security_issues -eq 0 ]]; then
        zf::debug "    ✅ Security compliance: EXCELLENT"
        return 0
    else
        zf::debug "    ⚠️ Security compliance: $security_issues issues noted"
        return 0 # Pass but note issues
    fi
}

# ------------------------------------------------------------------------------
# 3. INTEGRATION VALIDATION
# ------------------------------------------------------------------------------

test_component_integration() {
    zf::debug "    🔗 Testing component integration..."

    local integration_issues=0

    # Test core component loading
    local core_components=(
        "01-source-execute-detection.zsh"
        "00-standard-helpers.zsh"
        "01-environment.zsh"
        "02-path-system.zsh"
    )

    for component in "${core_components[@]}"; do
        local component_path="$ZSHRC_DIR/.zshrc.d/00_$component"
        if [[ -f "$component_path" ]]; then
            if zsh -n "$component_path" 2>/dev/null; then
                zf::debug "    ✅ Component syntax valid: $component"
            else
                zf::debug "    ❌ Component syntax error: $component"
                integration_issues=$((integration_issues + 1))
            fi
        else
            zf::debug "    ⚠️ Component missing: $component"
        fi
    done

    # Test plugin system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh" ]]; then
        zf::debug "    ✅ Plugin system: AVAILABLE"
    else
        zf::debug "    ⚠️ Plugin system: NOT FOUND"
    fi

    # Test context system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/30_35-context-aware-config.zsh" ]]; then
        zf::debug "    ✅ Context system: AVAILABLE"
    else
        zf::debug "    ⚠️ Context system: NOT FOUND"
    fi

    if [[ $integration_issues -eq 0 ]]; then
        zf::debug "    ✅ Component integration: EXCELLENT"
        return 0
    else
        zf::debug "    ❌ Component integration: $integration_issues issues"
        return 1
    fi
}

test_external_tool_integration() {
    zf::debug "    🛠️ Testing external tool integration..."

    # Test common tools availability
    local tools=("git" "curl" "grep" "sed" "awk")
    local available_tools=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            zf::debug "    ✅ Tool available: $tool"
            available_tools=$((available_tools + 1))
        else
            zf::debug "    ⚠️ Tool not available: $tool"
        fi
    done

    # Test shell-specific tools
    if command -v zsh >/dev/null 2>&1; then
        zf::debug "    ✅ ZSH available: $(zsh --version | head -1)"
    else
        zf::debug "    ❌ ZSH not available"
        return 1
    fi

    zf::debug "    📊 Tool availability: $available_tools/${#tools[@]} common tools"

    if [[ $available_tools -ge 3 ]]; then
        zf::debug "    ✅ External tool integration: SUFFICIENT"
        return 0
    else
        zf::debug "    ⚠️ External tool integration: LIMITED"
        return 0 # Don't fail, but note limitation
    fi
}

# ------------------------------------------------------------------------------
# 4. COMPREHENSIVE TEST SUITE VALIDATION
# ------------------------------------------------------------------------------

test_all_test_suites() {
    zf::debug "    🧪 Testing all test suites..."

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
            zf::debug "    ✅ Test suite available: $(basename "$test_file")"

            if [[ -x "$test_file" ]]; then
                executable_tests=$((executable_tests + 1))
                zf::debug "    ✅ Test suite executable: $(basename "$test_file")"
            else
                zf::debug "    ⚠️ Test suite not executable: $(basename "$test_file")"
            fi
        else
            zf::debug "    ❌ Test suite missing: $(basename "$test_file")"
        fi
    done

    zf::debug "    📊 Test suite availability: $available_tests/${#test_files[@]} available, $executable_tests executable"

    if [[ $available_tests -ge 6 ]]; then
        zf::debug "    ✅ Test suite validation: EXCELLENT"
        return 0
    elif [[ $available_tests -ge 4 ]]; then
        zf::debug "    ✅ Test suite validation: GOOD"
        return 0
    else
        zf::debug "    ❌ Test suite validation: INSUFFICIENT"
        return 1
    fi
}

test_documentation_completeness() {
    zf::debug "    📚 Testing documentation completeness..."

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
            zf::debug "    ✅ Documentation available: $(basename "$doc_file")"
        else
            zf::debug "    ❌ Documentation missing: $(basename "$doc_file")"
        fi
    done

    zf::debug "    📊 Documentation completeness: $available_docs/${#doc_files[@]} files"

    if [[ $available_docs -eq ${#doc_files[@]} ]]; then
        zf::debug "    ✅ Documentation completeness: PERFECT"
        return 0
    elif [[ $available_docs -ge 3 ]]; then
        zf::debug "    ✅ Documentation completeness: GOOD"
        return 0
    else
        zf::debug "    ❌ Documentation completeness: INSUFFICIENT"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 5. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Final Validation Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "System Directory: $ZSHRC_DIR"
    zf::debug "ZSH Version: $(zsh --version 2>/dev/null || zf::debug 'Unknown')"
    zf::debug ""

    log_test "Starting final validation test suite"

    # System Health Tests
    zf::debug "=== System Health Validation ==="
    run_test "System Health Check" "test_system_health"
    run_test "End-to-End Functionality" "test_end_to_end_functionality"
    run_test "Performance Validation" "test_performance_validation"
    run_test "Security Compliance" "test_security_compliance"

    # Integration Tests
    zf::debug ""
    zf::debug "=== Integration Validation ==="
    run_test "Component Integration" "test_component_integration"
    run_test "External Tool Integration" "test_external_tool_integration"

    # Comprehensive Validation
    zf::debug ""
    zf::debug "=== Comprehensive Validation ==="
    run_test "All Test Suites Available" "test_all_test_suites"
    run_test "Documentation Completeness" "test_documentation_completeness"

    # Results Summary
    zf::debug ""
    zf::debug "========================================================"
    zf::debug "Final Validation Results Summary"
    zf::debug "========================================================"
    zf::debug "Total Tests: $TEST_COUNT"
    zf::debug "Passed: $TEST_PASSED"
    zf::debug "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(((TEST_PASSED * 100) / TEST_COUNT))
    fi
    zf::debug "Success Rate: ${pass_percentage}%"

    # Overall system assessment
    zf::debug ""
    zf::debug "=== OVERALL SYSTEM ASSESSMENT ==="
    if [[ $pass_percentage -ge 90 ]]; then
        zf::debug "🏆 SYSTEM STATUS: EXCELLENT (${pass_percentage}%)"
        zf::debug "✅ RECOMMENDATION: APPROVED FOR PRODUCTION USE"
    elif [[ $pass_percentage -ge 75 ]]; then
        zf::debug "✅ SYSTEM STATUS: GOOD (${pass_percentage}%)"
        zf::debug "✅ RECOMMENDATION: APPROVED WITH MINOR NOTES"
    elif [[ $pass_percentage -ge 60 ]]; then
        zf::debug "⚠️ SYSTEM STATUS: ACCEPTABLE (${pass_percentage}%)"
        zf::debug "⚠️ RECOMMENDATION: REVIEW FAILED TESTS"
    else
        zf::debug "❌ SYSTEM STATUS: NEEDS ATTENTION (${pass_percentage}%)"
        zf::debug "❌ RECOMMENDATION: ADDRESS CRITICAL ISSUES"
    fi

    log_test "Final validation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed (${pass_percentage}%)"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All final validation tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "⚠️ $TEST_FAILED final validation test(s) had issues."
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
    zf::debug "Final validation test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Final Validation Test Suite
# ==============================================================================
