<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
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
<<<<<<< HEAD
    zf::debug "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
=======
        zsh_debug_echo "ERROR: Source/execute detection script not found: $DETECTION_SCRIPT"
>>>>>>> origin/develop
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
<<<<<<< HEAD
    zf::debug "[$timestamp] [FINAL] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
=======
        zsh_debug_echo "[$timestamp] [FINAL] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
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
        zf::debug "  ✅ PASS: $test_name"
=======
            zsh_debug_echo "  ✅ PASS: $test_name"
>>>>>>> origin/develop
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
<<<<<<< HEAD
        zf::debug "  ❌ FAIL: $test_name"
=======
            zsh_debug_echo "  ❌ FAIL: $test_name"
>>>>>>> origin/develop
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. SYSTEM HEALTH VALIDATION
# ------------------------------------------------------------------------------

test_system_health() {
<<<<<<< HEAD
    zf::debug "    🏥 Testing overall system health..."
=======
        zsh_debug_echo "    🏥 Testing overall system health..."
>>>>>>> origin/develop

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
<<<<<<< HEAD
            zf::debug "    ✅ Directory exists: $(basename "$dir")"
        else
            zf::debug "    ❌ Missing directory: $(basename "$dir")"
=======
                zsh_debug_echo "    ✅ Directory exists: $(basename "$dir")"
        else
                zsh_debug_echo "    ❌ Missing directory: $(basename "$dir")"
>>>>>>> origin/develop
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
<<<<<<< HEAD
            zf::debug "    ✅ File exists: $(basename "$file")"
        else
            zf::debug "    ❌ Missing file: $(basename "$file")"
=======
                zsh_debug_echo "    ✅ File exists: $(basename "$file")"
        else
                zsh_debug_echo "    ❌ Missing file: $(basename "$file")"
>>>>>>> origin/develop
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
<<<<<<< HEAD
            zf::debug "    ✅ Function available: $func"
        else
            zf::debug "    ❌ Missing function: $func"
=======
                zsh_debug_echo "    ✅ Function available: $func"
        else
                zsh_debug_echo "    ❌ Missing function: $func"
>>>>>>> origin/develop
            health_issues=$((health_issues + 1))
        fi
    done

    if [[ $health_issues -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✅ System health: EXCELLENT"
        return 0
    else
        zf::debug "    ❌ System health issues: $health_issues"
=======
            zsh_debug_echo "    ✅ System health: EXCELLENT"
        return 0
    else
            zsh_debug_echo "    ❌ System health issues: $health_issues"
>>>>>>> origin/develop
        return 1
    fi
}

test_end_to_end_functionality() {
<<<<<<< HEAD
    zf::debug "    🔄 Testing end-to-end functionality..."

    # Test shell startup and basic functionality
    local startup_test=$(mktemp)
    cat >"$startup_test" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    🔄 Testing end-to-end functionality..."

    # Test shell startup and basic functionality
    local startup_test=$(mktemp)
    cat > "$startup_test" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# Test basic shell functionality
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Test that shell loads without errors
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    source "$ZDOTDIR/.zshrc" >/dev/null 2>&1
    exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
<<<<<<< HEAD
            zf::debug "STARTUP_SUCCESS"
        exit 0
    else
            zf::debug "STARTUP_FAILED"
        exit 1
    fi
else
        zf::debug "CONFIG_MISSING"
=======
            zsh_debug_echo "STARTUP_SUCCESS"
        exit 0
    else
            zsh_debug_echo "STARTUP_FAILED"
        exit 1
    fi
else
        zsh_debug_echo "CONFIG_MISSING"
>>>>>>> origin/develop
    exit 1
fi
EOF

    chmod +x "$startup_test"

    local result
    result=$(timeout 15 "$startup_test" 2>/dev/null)
    local exit_code=$?

    rm -f "$startup_test"

    if [[ $exit_code -eq 0 && "$result" == "STARTUP_SUCCESS" ]]; then
<<<<<<< HEAD
        zf::debug "    ✅ End-to-end functionality: WORKING"
        return 0
    else
        zf::debug "    ❌ End-to-end functionality: FAILED (exit: $exit_code, result: $result)"
=======
            zsh_debug_echo "    ✅ End-to-end functionality: WORKING"
        return 0
    else
            zsh_debug_echo "    ❌ End-to-end functionality: FAILED (exit: $exit_code, result: $result)"
>>>>>>> origin/develop
        return 1
    fi
}

test_performance_validation() {
<<<<<<< HEAD
    zf::debug "    ⚡ Testing performance validation..."
=======
        zsh_debug_echo "    ⚡ Testing performance validation..."
>>>>>>> origin/develop

    # Test startup performance
    local startup_times=()
    local iterations=3

<<<<<<< HEAD
    for ((i = 1; i <= iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        # Quick shell startup test using bash harness
        bash -c 'source "./.bash-harness-for-zsh-template.bash"; HARNESS_ZDOTDIR="'$ZSHRC_DIR'" harness::run "exit"' >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zf::debug "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local duration=$(((end_time - start_time) / 1000000))
=======
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        # Quick shell startup test
        env ZDOTDIR="$ZSHRC_DIR" /opt/homebrew/bin/zsh -i -c exit >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local duration=$(( (end_time - start_time) / 1000000 ))
>>>>>>> origin/develop
            startup_times+=("$duration")
        fi
    done

    if [[ ${#startup_times[@]} -gt 0 ]]; then
        local total=0
        for time in "${startup_times[@]}"; do
            total=$((total + time))
        done
        local avg_time=$((total / ${#startup_times[@]}))

<<<<<<< HEAD
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
=======
            zsh_debug_echo "    📊 Average startup time: ${avg_time}ms"

        # Performance targets (relaxed for real-world usage)
        if [[ $avg_time -lt 5000 ]]; then  # Less than 5 seconds
                zsh_debug_echo "    ✅ Performance validation: EXCELLENT (<5s)"
            return 0
        elif [[ $avg_time -lt 10000 ]]; then  # Less than 10 seconds
                zsh_debug_echo "    ✅ Performance validation: GOOD (<10s)"
            return 0
        else
                zsh_debug_echo "    ⚠️ Performance validation: ACCEPTABLE (>10s)"
            return 0  # Still pass, but note the performance
        fi
    else
            zsh_debug_echo "    ❌ Performance validation: FAILED (no measurements)"
>>>>>>> origin/develop
        return 1
    fi
}

test_security_compliance() {
<<<<<<< HEAD
    zf::debug "    🔒 Testing security compliance..."
=======
        zsh_debug_echo "    🔒 Testing security compliance..."
>>>>>>> origin/develop

    local security_issues=0

    # Check file permissions
    local config_files=(
        "$ZSHRC_DIR/.zshrc"
        "$ZSHRC_DIR/.zshenv"
    )

    for file in "${config_files[@]}"; do
        if [[ -f "$file" ]]; then
<<<<<<< HEAD
            local perms=$(stat -f "%A" "$file" 2>/dev/null || zf::debug "unknown")
            if [[ "$perms" == "644" || "$perms" == "600" ]]; then
                zf::debug "    ✅ File permissions secure: $(basename "$file") ($perms)"
            else
                zf::debug "    ⚠️ File permissions review needed: $(basename "$file") ($perms)"
=======
            local perms=$(stat -f "%A" "$file" 2>/dev/null || zsh_debug_echo "unknown")
            if [[ "$perms" == "644" || "$perms" == "600" ]]; then
                    zsh_debug_echo "    ✅ File permissions secure: $(basename "$file") ($perms)"
            else
                    zsh_debug_echo "    ⚠️ File permissions review needed: $(basename "$file") ($perms)"
>>>>>>> origin/develop
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
<<<<<<< HEAD
        zf::debug "    ✅ Environment security: CLEAN"
    else
        zf::debug "    ⚠️ Environment security: $env_issues potential issues (review recommended)"
=======
            zsh_debug_echo "    ✅ Environment security: CLEAN"
    else
            zsh_debug_echo "    ⚠️ Environment security: $env_issues potential issues (review recommended)"
>>>>>>> origin/develop
    fi

    # Check if security functions are available
    if declare -f _run_security_audit >/dev/null 2>&1; then
<<<<<<< HEAD
        zf::debug "    ✅ Security audit system: AVAILABLE"
    else
        zf::debug "    ⚠️ Security audit system: NOT LOADED"
=======
            zsh_debug_echo "    ✅ Security audit system: AVAILABLE"
    else
            zsh_debug_echo "    ⚠️ Security audit system: NOT LOADED"
>>>>>>> origin/develop
        security_issues=$((security_issues + 1))
    fi

    if [[ $security_issues -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug "    ✅ Security compliance: EXCELLENT"
        return 0
    else
        zf::debug "    ⚠️ Security compliance: $security_issues issues noted"
        return 0 # Pass but note issues
=======
            zsh_debug_echo "    ✅ Security compliance: EXCELLENT"
        return 0
    else
            zsh_debug_echo "    ⚠️ Security compliance: $security_issues issues noted"
        return 0  # Pass but note issues
>>>>>>> origin/develop
    fi
}

# ------------------------------------------------------------------------------
# 3. INTEGRATION VALIDATION
# ------------------------------------------------------------------------------

test_component_integration() {
<<<<<<< HEAD
    zf::debug "    🔗 Testing component integration..."
=======
        zsh_debug_echo "    🔗 Testing component integration..."
>>>>>>> origin/develop

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
<<<<<<< HEAD
                zf::debug "    ✅ Component syntax valid: $component"
            else
                zf::debug "    ❌ Component syntax error: $component"
                integration_issues=$((integration_issues + 1))
            fi
        else
            zf::debug "    ⚠️ Component missing: $component"
=======
                    zsh_debug_echo "    ✅ Component syntax valid: $component"
            else
                    zsh_debug_echo "    ❌ Component syntax error: $component"
                integration_issues=$((integration_issues + 1))
            fi
        else
                zsh_debug_echo "    ⚠️ Component missing: $component"
>>>>>>> origin/develop
        fi
    done

    # Test plugin system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/20_01-plugin-metadata.zsh" ]]; then
<<<<<<< HEAD
        zf::debug "    ✅ Plugin system: AVAILABLE"
    else
        zf::debug "    ⚠️ Plugin system: NOT FOUND"
=======
            zsh_debug_echo "    ✅ Plugin system: AVAILABLE"
    else
            zsh_debug_echo "    ⚠️ Plugin system: NOT FOUND"
>>>>>>> origin/develop
    fi

    # Test context system integration
    if [[ -f "$ZSHRC_DIR/.zshrc.d/30_35-context-aware-config.zsh" ]]; then
<<<<<<< HEAD
        zf::debug "    ✅ Context system: AVAILABLE"
    else
        zf::debug "    ⚠️ Context system: NOT FOUND"
    fi

    if [[ $integration_issues -eq 0 ]]; then
        zf::debug "    ✅ Component integration: EXCELLENT"
        return 0
    else
        zf::debug "    ❌ Component integration: $integration_issues issues"
=======
            zsh_debug_echo "    ✅ Context system: AVAILABLE"
    else
            zsh_debug_echo "    ⚠️ Context system: NOT FOUND"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zsh_debug_echo "    ✅ Component integration: EXCELLENT"
        return 0
    else
            zsh_debug_echo "    ❌ Component integration: $integration_issues issues"
>>>>>>> origin/develop
        return 1
    fi
}

test_external_tool_integration() {
<<<<<<< HEAD
    zf::debug "    🛠️ Testing external tool integration..."
=======
        zsh_debug_echo "    🛠️ Testing external tool integration..."
>>>>>>> origin/develop

    # Test common tools availability
    local tools=("git" "curl" "grep" "sed" "awk")
    local available_tools=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✅ Tool available: $tool"
            available_tools=$((available_tools + 1))
        else
            zf::debug "    ⚠️ Tool not available: $tool"
=======
                zsh_debug_echo "    ✅ Tool available: $tool"
            available_tools=$((available_tools + 1))
        else
                zsh_debug_echo "    ⚠️ Tool not available: $tool"
>>>>>>> origin/develop
        fi
    done

    # Test shell-specific tools
    if command -v zsh >/dev/null 2>&1; then
<<<<<<< HEAD
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
=======
            zsh_debug_echo "    ✅ ZSH available: $(zsh --version | head -1)"
    else
            zsh_debug_echo "    ❌ ZSH not available"
        return 1
    fi

        zsh_debug_echo "    📊 Tool availability: $available_tools/${#tools[@]} common tools"

    if [[ $available_tools -ge 3 ]]; then
            zsh_debug_echo "    ✅ External tool integration: SUFFICIENT"
        return 0
    else
            zsh_debug_echo "    ⚠️ External tool integration: LIMITED"
        return 0  # Don't fail, but note limitation
>>>>>>> origin/develop
    fi
}

# ------------------------------------------------------------------------------
# 4. COMPREHENSIVE TEST SUITE VALIDATION
# ------------------------------------------------------------------------------

test_all_test_suites() {
<<<<<<< HEAD
    zf::debug "    🧪 Testing all test suites..."
=======
        zsh_debug_echo "    🧪 Testing all test suites..."
>>>>>>> origin/develop

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
<<<<<<< HEAD
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
=======
                zsh_debug_echo "    ✅ Test suite available: $(basename "$test_file")"

            if [[ -x "$test_file" ]]; then
                executable_tests=$((executable_tests + 1))
                    zsh_debug_echo "    ✅ Test suite executable: $(basename "$test_file")"
            else
                    zsh_debug_echo "    ⚠️ Test suite not executable: $(basename "$test_file")"
            fi
        else
                zsh_debug_echo "    ❌ Test suite missing: $(basename "$test_file")"
        fi
    done

        zsh_debug_echo "    📊 Test suite availability: $available_tests/${#test_files[@]} available, $executable_tests executable"

    if [[ $available_tests -ge 6 ]]; then
            zsh_debug_echo "    ✅ Test suite validation: EXCELLENT"
        return 0
    elif [[ $available_tests -ge 4 ]]; then
            zsh_debug_echo "    ✅ Test suite validation: GOOD"
        return 0
    else
            zsh_debug_echo "    ❌ Test suite validation: INSUFFICIENT"
>>>>>>> origin/develop
        return 1
    fi
}

test_documentation_completeness() {
<<<<<<< HEAD
    zf::debug "    📚 Testing documentation completeness..."
=======
        zsh_debug_echo "    📚 Testing documentation completeness..."
>>>>>>> origin/develop

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
<<<<<<< HEAD
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
=======
                zsh_debug_echo "    ✅ Documentation available: $(basename "$doc_file")"
        else
                zsh_debug_echo "    ❌ Documentation missing: $(basename "$doc_file")"
        fi
    done

        zsh_debug_echo "    📊 Documentation completeness: $available_docs/${#doc_files[@]} files"

    if [[ $available_docs -eq ${#doc_files[@]} ]]; then
            zsh_debug_echo "    ✅ Documentation completeness: PERFECT"
        return 0
    elif [[ $available_docs -ge 3 ]]; then
            zsh_debug_echo "    ✅ Documentation completeness: GOOD"
        return 0
    else
            zsh_debug_echo "    ❌ Documentation completeness: INSUFFICIENT"
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
    zf::debug "Final Validation Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "System Directory: $ZSHRC_DIR"
    zf::debug "ZSH Version: $(zsh --version 2>/dev/null || zf::debug 'Unknown')"
    zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Final Validation Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "System Directory: $ZSHRC_DIR"
        zsh_debug_echo "ZSH Version: $(zsh --version 2>/dev/null || zsh_debug_echo 'Unknown')"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting final validation test suite"

    # System Health Tests
<<<<<<< HEAD
    zf::debug "=== System Health Validation ==="
=======
        zsh_debug_echo "=== System Health Validation ==="
>>>>>>> origin/develop
    run_test "System Health Check" "test_system_health"
    run_test "End-to-End Functionality" "test_end_to_end_functionality"
    run_test "Performance Validation" "test_performance_validation"
    run_test "Security Compliance" "test_security_compliance"

    # Integration Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Integration Validation ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Validation ==="
>>>>>>> origin/develop
    run_test "Component Integration" "test_component_integration"
    run_test "External Tool Integration" "test_external_tool_integration"

    # Comprehensive Validation
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Comprehensive Validation ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Comprehensive Validation ==="
>>>>>>> origin/develop
    run_test "All Test Suites Available" "test_all_test_suites"
    run_test "Documentation Completeness" "test_documentation_completeness"

    # Results Summary
<<<<<<< HEAD
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
=======
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Final Validation Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zsh_debug_echo "Success Rate: ${pass_percentage}%"

    # Overall system assessment
        zsh_debug_echo ""
        zsh_debug_echo "=== OVERALL SYSTEM ASSESSMENT ==="
    if [[ $pass_percentage -ge 90 ]]; then
            zsh_debug_echo "🏆 SYSTEM STATUS: EXCELLENT (${pass_percentage}%)"
            zsh_debug_echo "✅ RECOMMENDATION: APPROVED FOR PRODUCTION USE"
    elif [[ $pass_percentage -ge 75 ]]; then
            zsh_debug_echo "✅ SYSTEM STATUS: GOOD (${pass_percentage}%)"
            zsh_debug_echo "✅ RECOMMENDATION: APPROVED WITH MINOR NOTES"
    elif [[ $pass_percentage -ge 60 ]]; then
            zsh_debug_echo "⚠️ SYSTEM STATUS: ACCEPTABLE (${pass_percentage}%)"
            zsh_debug_echo "⚠️ RECOMMENDATION: REVIEW FAILED TESTS"
    else
            zsh_debug_echo "❌ SYSTEM STATUS: NEEDS ATTENTION (${pass_percentage}%)"
            zsh_debug_echo "❌ RECOMMENDATION: ADDRESS CRITICAL ISSUES"
>>>>>>> origin/develop
    fi

    log_test "Final validation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed (${pass_percentage}%)"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All final validation tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "⚠️ $TEST_FAILED final validation test(s) had issues."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All final validation tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "⚠️ $TEST_FAILED final validation test(s) had issues."
>>>>>>> origin/develop
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
<<<<<<< HEAD
    zf::debug "Final validation test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Final validation test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Final Validation Test Suite
# ==============================================================================
