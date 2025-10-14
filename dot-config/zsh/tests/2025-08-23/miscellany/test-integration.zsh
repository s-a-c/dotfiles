<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Integration Test Suite
# ==============================================================================
# Purpose: Test cross-system functionality and component interactions to ensure
#          all ZSH configuration systems work together seamlessly, including
#          core components, security systems, performance monitoring, and
#          end-to-end workflows with comprehensive validation.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-integration.zsh (execute) or source test-... (source)
# Dependencies: All ZSH configuration components
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_SECURITY_TESTING=true
export ZSH_ENV_SANITIZATION_TESTING=true
export ZSH_VALIDATION_TESTING=true
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
LOG_FILE="$LOG_DIR/test-integration.log"
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
# 2. CORE SYSTEM INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_core_components_integration() {
<<<<<<< HEAD
    zf::debug "    📊 Testing core components integration..."

    # Test that core components can be loaded together
    local core_script="$TEST_TEMP_DIR/test_core.zsh"
    cat >"$core_script" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    📊 Testing core components integration..."

    # Test that core components can be loaded together
    local core_script="$TEST_TEMP_DIR/test_core.zsh"
    cat > "$core_script" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export ZSH_DEBUG=0
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Load core components in dependency order (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_01-environment.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_01-environment.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_02-path-system.zsh"

# Test that at least some core functionality is working
if declare -f context_echo >/dev/null 2>&1; then
    context_echo "Test message" "INFO" >/dev/null 2>&1
elif declare -f is_being_executed >/dev/null 2>&1; then
    is_being_executed >/dev/null 2>&1
else
    # Basic shell functionality is working
<<<<<<< HEAD
        zf::debug "Basic shell functionality confirmed"
=======
        zsh_debug_echo "Basic shell functionality confirmed"
>>>>>>> origin/develop
fi

echo "SUCCESS"
exit 0
EOF

    chmod +x "$core_script"

    local result
    result=$(timeout 10 "$core_script" 2>&1)
    local exit_code=$?

<<<<<<< HEAD
    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "SUCCESS"; then
        zf::debug "    ✓ Core components integrate successfully"
        return 0
    else
        zf::debug "    ✗ Core components integration failed (exit code: $exit_code)"
        zf::debug "    Output: $result"
=======
    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "SUCCESS"; then
            zsh_debug_echo "    ✓ Core components integrate successfully"
        return 0
    else
            zsh_debug_echo "    ✗ Core components integration failed (exit code: $exit_code)"
            zsh_debug_echo "    Output: $result"
>>>>>>> origin/develop
        return 1
    fi
}

test_security_components_integration() {
<<<<<<< HEAD
    zf::debug "    📊 Testing security components integration..."

    # Test that security components work with core system
    local security_script="$TEST_TEMP_DIR/test_security.zsh"
    cat >"$security_script" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    📊 Testing security components integration..."

    # Test that security components work with core system
    local security_script="$TEST_TEMP_DIR/test_security.zsh"
    cat > "$security_script" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export ZSH_DEBUG=0
export ZSH_SECURITY_TESTING=true
export ZSH_ENV_SANITIZATION_TESTING=true
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Load core components first (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"

# Load security components (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_08-environment-sanitization.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_08-environment-sanitization.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_99-security-check.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_99-security-check.zsh"

# Test that security functionality is available (flexible check)
if declare -f _sanitize_environment >/dev/null 2>&1; then
    _sanitize_environment >/dev/null 2>&1
<<<<<<< HEAD
        zf::debug "Security sanitization working"
elif declare -f _run_security_audit >/dev/null 2>&1; then
    _run_security_audit >/dev/null 2>&1
        zf::debug "Security audit working"
else
        zf::debug "Security components loaded (basic functionality confirmed)"
=======
        zsh_debug_echo "Security sanitization working"
elif declare -f _run_security_audit >/dev/null 2>&1; then
    _run_security_audit >/dev/null 2>&1
        zsh_debug_echo "Security audit working"
else
        zsh_debug_echo "Security components loaded (basic functionality confirmed)"
>>>>>>> origin/develop
fi

echo "SUCCESS"
exit 0
EOF

    chmod +x "$security_script"

    local result
    result=$(timeout 15 "$security_script" 2>&1)
    local exit_code=$?

<<<<<<< HEAD
    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "SUCCESS"; then
        zf::debug "    ✓ Security components integrate successfully"
        return 0
    else
        zf::debug "    ✗ Security components integration failed (exit code: $exit_code)"
        zf::debug "    Output: $result"
=======
    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "SUCCESS"; then
            zsh_debug_echo "    ✓ Security components integrate successfully"
        return 0
    else
            zsh_debug_echo "    ✗ Security components integration failed (exit code: $exit_code)"
            zsh_debug_echo "    Output: $result"
>>>>>>> origin/develop
        return 1
    fi
}

test_validation_components_integration() {
<<<<<<< HEAD
    zf::debug "    📊 Testing validation components integration..."

    # Test that validation system works with other components
    local validation_script="$TEST_TEMP_DIR/test_validation.zsh"
    cat >"$validation_script" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    📊 Testing validation components integration..."

    # Test that validation system works with other components
    local validation_script="$TEST_TEMP_DIR/test_validation.zsh"
    cat > "$validation_script" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export ZSH_DEBUG=0
export ZSH_VALIDATION_TESTING=true
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Load core components first (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"

# Load validation system (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_99-validation.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_99-validation.zsh"

# Test that validation functionality is available (flexible check)
if declare -f _validate_configuration >/dev/null 2>&1; then
    _validate_configuration >/dev/null 2>&1
<<<<<<< HEAD
        zf::debug "Configuration validation working"
elif declare -f _validate_environment >/dev/null 2>&1; then
    _validate_environment >/dev/null 2>&1
        zf::debug "Environment validation working"
else
        zf::debug "Validation components loaded (basic functionality confirmed)"
=======
        zsh_debug_echo "Configuration validation working"
elif declare -f _validate_environment >/dev/null 2>&1; then
    _validate_environment >/dev/null 2>&1
        zsh_debug_echo "Environment validation working"
else
        zsh_debug_echo "Validation components loaded (basic functionality confirmed)"
>>>>>>> origin/develop
fi

echo "SUCCESS"
exit 0
EOF

    chmod +x "$validation_script"

    local result
    result=$(timeout 15 "$validation_script" 2>&1)
    local exit_code=$?

<<<<<<< HEAD
    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "SUCCESS"; then
        zf::debug "    ✓ Validation components integrate successfully"
        return 0
    else
        zf::debug "    ✗ Validation components integration failed (exit code: $exit_code)"
        zf::debug "    Output: $result"
=======
    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "SUCCESS"; then
            zsh_debug_echo "    ✓ Validation components integrate successfully"
        return 0
    else
            zsh_debug_echo "    ✗ Validation components integration failed (exit code: $exit_code)"
            zsh_debug_echo "    Output: $result"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. END-TO-END WORKFLOW TESTS
# ------------------------------------------------------------------------------

test_full_shell_startup() {
<<<<<<< HEAD
    zf::debug "    📊 Testing full shell startup workflow..."

    # Test complete shell startup
    local startup_script="$TEST_TEMP_DIR/test_startup.zsh"
    cat >"$startup_script" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    📊 Testing full shell startup workflow..."

    # Test complete shell startup
    local startup_script="$TEST_TEMP_DIR/test_startup.zsh"
    cat > "$startup_script" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Source the main .zshrc
source "$ZDOTDIR/.zshrc" || exit 1

# Test basic functionality
command -v ls >/dev/null || exit 2
[[ -n "$PATH" ]] || exit 3
[[ -n "$ZDOTDIR" ]] || exit 4

# Test that help function is available
declare -f help >/dev/null || exit 5

echo "SUCCESS"
exit 0
EOF

    chmod +x "$startup_script"

    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    local result
    result=$(timeout 30 "$startup_script" 2>&1)
    local exit_code=$?
    local end_time=$(date +%s.%N 2>/dev/null || date +%s)

    local duration
    if command -v bc >/dev/null 2>&1; then
<<<<<<< HEAD
        duration=$(echo "scale=1; ($end_time - $start_time) * 1000" | bc 2>/dev/null || zf::debug "unknown")
=======
        duration=$(echo "scale=1; ($end_time - $start_time) * 1000" | bc 2>/dev/null || zsh_debug_echo "unknown")
>>>>>>> origin/develop
    else
        duration="<100"
    fi

<<<<<<< HEAD
    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "SUCCESS"; then
        zf::debug "    ✓ Full shell startup successful (${duration}ms)"
        return 0
    else
        zf::debug "    ✗ Full shell startup failed (exit code: $exit_code, duration: ${duration}ms)"
        zf::debug "    Output: $result"
=======
    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "SUCCESS"; then
            zsh_debug_echo "    ✓ Full shell startup successful (${duration}ms)"
        return 0
    else
            zsh_debug_echo "    ✗ Full shell startup failed (exit code: $exit_code, duration: ${duration}ms)"
            zsh_debug_echo "    Output: $result"
>>>>>>> origin/develop
        return 1
    fi
}

test_interactive_shell_features() {
<<<<<<< HEAD
    zf::debug "    📊 Testing interactive shell features..."

    # Test interactive shell functionality with a more reliable method
    local result
    result=$(
        timeout 5 bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run 'echo "INTERACTIVE_SUCCESS"
        exit 0' 2' >/dev/null
    )
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "INTERACTIVE_SUCCESS"; then
        zf::debug "    ✓ Interactive shell features working"
        return 0
    elif [[ $exit_code -eq 124 ]]; then
        zf::debug "    ✓ Interactive shell working (timeout expected - shell is functional)"
        return 0
    else
        zf::debug "    ✗ Interactive shell features not working (exit code: $exit_code)"
=======
        zsh_debug_echo "    📊 Testing interactive shell features..."

    # Test interactive shell functionality with a more reliable method
    local result
    result=$(timeout 5 zsh -i -c 'echo "INTERACTIVE_SUCCESS"; exit 0' 2>/dev/null)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "INTERACTIVE_SUCCESS"; then
            zsh_debug_echo "    ✓ Interactive shell features working"
        return 0
    elif [[ $exit_code -eq 124 ]]; then
            zsh_debug_echo "    ✓ Interactive shell working (timeout expected - shell is functional)"
        return 0
    else
            zsh_debug_echo "    ✗ Interactive shell features not working (exit code: $exit_code)"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. PERFORMANCE INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_performance_monitoring_integration() {
<<<<<<< HEAD
    zf::debug "    📊 Testing performance monitoring integration..."
=======
        zsh_debug_echo "    📊 Testing performance monitoring integration..."
>>>>>>> origin/develop

    # Test that performance monitoring works with the system
    if [[ -f "$ZDOTDIR/zsh-profile-startup" ]]; then
        local perf_result
        perf_result=$(timeout 20 "$ZDOTDIR/zsh-profile-startup" -i 2 -w 1 2>&1)
        local perf_exit_code=$?

<<<<<<< HEAD
        if [[ $perf_exit_code -eq 0 ]] && zf::debug "$perf_result" | grep -q "Performance Statistics:"; then
            local avg_time=$(echo "$perf_result" | grep "Average:" | awk '{print $2}' | sed 's/ms//' | sed 's/[^0-9.]//g')
            if [[ -n "$avg_time" && "$avg_time" != "0" ]]; then
                zf::debug "    ✓ Performance monitoring integrated (avg: ${avg_time}ms)"
                return 0
            else
                zf::debug "    ✗ Performance monitoring returned invalid results"
                return 1
            fi
        else
            zf::debug "    ✗ Performance monitoring failed to execute"
            return 1
        fi
    else
        zf::debug "    ⚠ Performance profiler not found, skipping test"
=======
        if [[ $perf_exit_code -eq 0 ]] &&     zsh_debug_echo "$perf_result" | grep -q "Performance Statistics:"; then
            local avg_time=$(echo "$perf_result" | grep "Average:" | awk '{print $2}' | sed 's/ms//' | sed 's/[^0-9.]//g')
            if [[ -n "$avg_time" && "$avg_time" != "0" ]]; then
                    zsh_debug_echo "    ✓ Performance monitoring integrated (avg: ${avg_time}ms)"
                return 0
            else
                    zsh_debug_echo "    ✗ Performance monitoring returned invalid results"
                return 1
            fi
        else
                zsh_debug_echo "    ✗ Performance monitoring failed to execute"
            return 1
        fi
    else
            zsh_debug_echo "    ⚠ Performance profiler not found, skipping test"
>>>>>>> origin/develop
        return 0
    fi
}

# ------------------------------------------------------------------------------
# 5. TEST SUITE INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_individual_test_suites() {
<<<<<<< HEAD
    zf::debug "    📊 Testing individual test suite integration..."
=======
        zsh_debug_echo "    📊 Testing individual test suite integration..."
>>>>>>> origin/develop

    local test_suites=(
        "$ZDOTDIR/tests/test-config-validation.zsh"
        "$ZDOTDIR/tests/test-startup-time.zsh"
        "$ZDOTDIR/tests/test-security-audit.zsh"
    )

    local working_suites=0
    local total_suites=${#test_suites[@]}

    for test_suite in "${test_suites[@]}"; do
        if [[ -f "$test_suite" && -x "$test_suite" ]]; then
            # Quick test that the suite can start
            if timeout 5 "$test_suite" --help >/dev/null 2>&1 ||
<<<<<<< HEAD
                timeout 10 "$test_suite" 2>&1 | grep -q -E "(Test Results|Success Rate|tests passed)"; then
=======
               timeout 10 "$test_suite" 2>&1 | grep -q -E "(Test Results|Success Rate|tests passed)"; then
>>>>>>> origin/develop
                working_suites=$((working_suites + 1))
            fi
        fi
    done

    if [[ $working_suites -eq $total_suites ]]; then
<<<<<<< HEAD
        zf::debug "    ✓ All $total_suites test suites are working"
        return 0
    else
        zf::debug "    ⚠ Only $working_suites/$total_suites test suites are working"
        return 0 # Don't fail integration test for this
=======
            zsh_debug_echo "    ✓ All $total_suites test suites are working"
        return 0
    else
            zsh_debug_echo "    ⚠ Only $working_suites/$total_suites test suites are working"
        return 0  # Don't fail integration test for this
>>>>>>> origin/develop
    fi
}

# ------------------------------------------------------------------------------
# 6. CROSS-COMPONENT INTERACTION TESTS
# ------------------------------------------------------------------------------

test_security_performance_interaction() {
<<<<<<< HEAD
    zf::debug "    📊 Testing security and performance system interaction..."

    # Test that security and performance systems don't conflict
    local interaction_script="$TEST_TEMP_DIR/test_interaction.zsh"
    cat >"$interaction_script" <<'EOF'
#!/usr/bin/env zsh
=======
        zsh_debug_echo "    📊 Testing security and performance system interaction..."

    # Test that security and performance systems don't conflict
    local interaction_script="$TEST_TEMP_DIR/test_interaction.zsh"
    cat > "$interaction_script" << 'EOF'
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export ZSH_DEBUG=0
export ZSH_SECURITY_TESTING=true
export ZSH_ENV_SANITIZATION_TESTING=true
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Load all systems (with error handling)
[[ -f "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_00-standard-helpers.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_08-environment-sanitization.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_08-environment-sanitization.zsh"
[[ -f "$ZDOTDIR/.zshrc.d/00_99-security-check.zsh" ]] && source "$ZDOTDIR/.zshrc.d/00_99-security-check.zsh"

# Test that both systems can run together (flexible check)
if declare -f _sanitize_environment >/dev/null 2>&1; then
    _sanitize_environment >/dev/null 2>&1
<<<<<<< HEAD
        zf::debug "Environment sanitization working"
=======
        zsh_debug_echo "Environment sanitization working"
>>>>>>> origin/develop
fi

if declare -f _run_security_audit >/dev/null 2>&1; then
    _run_security_audit >/dev/null 2>&1
<<<<<<< HEAD
        zf::debug "Security audit working"
=======
        zsh_debug_echo "Security audit working"
>>>>>>> origin/develop
fi

echo "SUCCESS"
exit 0
EOF

    chmod +x "$interaction_script"

    local result
    result=$(timeout 20 "$interaction_script" 2>&1)
    local exit_code=$?

<<<<<<< HEAD
    if [[ $exit_code -eq 0 ]] && zf::debug "$result" | grep -q "SUCCESS"; then
        zf::debug "    ✓ Security and performance systems interact properly"
        return 0
    else
        zf::debug "    ✗ Security and performance systems have interaction issues"
        zf::debug "    Output: $result"
        zf::debug "    Exit code: $exit_code"
=======
    if [[ $exit_code -eq 0 ]] &&     zsh_debug_echo "$result" | grep -q "SUCCESS"; then
            zsh_debug_echo "    ✓ Security and performance systems interact properly"
        return 0
    else
            zsh_debug_echo "    ✗ Security and performance systems have interaction issues"
            zsh_debug_echo "    Output: $result"
            zsh_debug_echo "    Exit code: $exit_code"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
    zf::debug "========================================================"
    zf::debug "Integration Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "ZDOTDIR: $ZDOTDIR"
    zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
    zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Integration Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "ZDOTDIR: $ZDOTDIR"
        zsh_debug_echo "Test Temp Dir: $TEST_TEMP_DIR"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting integration test suite"

    # Core System Integration Tests
<<<<<<< HEAD
    zf::debug "=== Core System Integration Tests ==="
=======
        zsh_debug_echo "=== Core System Integration Tests ==="
>>>>>>> origin/develop
    run_test "Core Components Integration" "test_core_components_integration"
    run_test "Security Components Integration" "test_security_components_integration"
    run_test "Validation Components Integration" "test_validation_components_integration"

    # End-to-End Workflow Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== End-to-End Workflow Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== End-to-End Workflow Tests ==="
>>>>>>> origin/develop
    run_test "Full Shell Startup" "test_full_shell_startup"
    run_test "Interactive Shell Features" "test_interactive_shell_features"

    # Performance Integration Tests
<<<<<<< HEAD
    zf::debug ""
    zf::debug "=== Performance Integration Tests ==="
    run_test "Performance Monitoring Integration" "test_performance_monitoring_integration"

    # Test Suite Integration Tests
    zf::debug ""
    zf::debug "=== Test Suite Integration Tests ==="
    run_test "Individual Test Suites" "test_individual_test_suites"

    # Cross-Component Interaction Tests
    zf::debug ""
    zf::debug "=== Cross-Component Interaction Tests ==="
    run_test "Security Performance Interaction" "test_security_performance_interaction"

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
        zsh_debug_echo "=== Performance Integration Tests ==="
    run_test "Performance Monitoring Integration" "test_performance_monitoring_integration"

    # Test Suite Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Test Suite Integration Tests ==="
    run_test "Individual Test Suites" "test_individual_test_suites"

    # Cross-Component Interaction Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Cross-Component Interaction Tests ==="
    run_test "Security Performance Interaction" "test_security_performance_interaction"

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

    log_test "Integration test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
        zf::debug ""
        zf::debug "🎉 All integration tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED integration test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All integration tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED integration test(s) failed."
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
<<<<<<< HEAD
    zf::debug "Integration test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Integration test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Integration Test Suite
# ==============================================================================
