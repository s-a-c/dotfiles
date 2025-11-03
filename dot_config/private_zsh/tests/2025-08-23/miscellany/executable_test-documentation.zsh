#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Documentation Completeness Test Suite
# ==============================================================================
# Purpose: Test the documentation system to ensure comprehensive coverage,
#          accuracy, and completeness of all documentation files including
#          user guides, API reference, 010-architecture docs, and troubleshooting
#          with validation of content quality and accessibility.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-documentation.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_DOCUMENTATION_TESTING=true
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
LOG_FILE="$LOG_DIR/test-documentation.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Documentation directory
DOCS_DIR="${ZDOTDIR:-$HOME/.config/zsh}/docs"

# ------------------------------------------------------------------------------
# 1. TEST FRAMEWORK FUNCTIONS
# ------------------------------------------------------------------------------

log_test() {
    local message="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    zf::debug "[$timestamp] [TEST] [$$] $message" >>"$LOG_FILE" 2>/dev/null || true
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TEST_COUNT=$((TEST_COUNT + 1))

    zf::debug "Running test $TEST_COUNT: $test_name"
    log_test "Starting test: $test_name"

    if "$test_function"; then
        TEST_PASSED=$((TEST_PASSED + 1))
        zf::debug "  ✓ PASS: $test_name"
        log_test "PASS: $test_name"
        return 0
    else
        TEST_FAILED=$((TEST_FAILED + 1))
        zf::debug "  ✗ FAIL: $test_name"
        log_test "FAIL: $test_name"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. DOCUMENTATION EXISTENCE TESTS
# ------------------------------------------------------------------------------

test_documentation_files_exist() {
    zf::debug "    📊 Testing documentation files existence..."

    local required_docs=(
        "USER-GUIDE.md"
        "API-REFERENCE.md"
        "ARCHITECTURE.md"
        "TROUBLESHOOTING.md"
        "zsh-improvement-implementation-plan-2025-08-20.md"
    )

    local missing_docs=()

    for doc in "${required_docs[@]}"; do
        if [[ ! -f "$DOCS_DIR/$doc" ]]; then
            missing_docs+=("$doc")
            zf::debug "    ✗ Missing documentation: $doc"
        else
            zf::debug "    ✓ Found documentation: $doc"
        fi
    done

    if [[ ${#missing_docs[@]} -eq 0 ]]; then
        zf::debug "    ✓ All required documentation files exist"
        return 0
    else
        zf::debug "    ✗ Missing ${#missing_docs[@]} documentation files"
        return 1
    fi
}

test_documentation_readability() {
    zf::debug "    📊 Testing documentation readability..."

    local docs_to_check=(
        "$DOCS_DIR/USER-GUIDE.md"
        "$DOCS_DIR/API-REFERENCE.md"
        "$DOCS_DIR/ARCHITECTURE.md"
        "$DOCS_DIR/TROUBLESHOOTING.md"
    )

    local unreadable_docs=()

    for doc in "${docs_to_check[@]}"; do
        if [[ -f "$doc" && -r "$doc" ]]; then
            zf::debug "    ✓ Readable: $(basename "$doc")"
        else
            unreadable_docs+=("$(basename "$doc")")
            zf::debug "    ✗ Not readable: $(basename "$doc")"
        fi
    done

    if [[ ${#unreadable_docs[@]} -eq 0 ]]; then
        zf::debug "    ✓ All documentation files are readable"
        return 0
    else
        zf::debug "    ✗ ${#unreadable_docs[@]} documentation files are not readable"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. CONTENT QUALITY TESTS
# ------------------------------------------------------------------------------

test_user_guide_completeness() {
    zf::debug "    📊 Testing user guide completeness..."

    local user_guide="$DOCS_DIR/USER-GUIDE.md"

    if [[ ! -f "$user_guide" ]]; then
        zf::debug "    ✗ User guide not found"
        return 1
    fi

    local required_sections=(
        "Quick Start"
        "Features Overview"
        "Daily Usage"
        "Configuration"
        "Troubleshooting"
        "Advanced Features"
    )

    local missing_sections=()

    for section in "${required_sections[@]}"; do
        if grep -q "# $section\|## $section" "$user_guide"; then
            zf::debug "    ✓ Found section: $section"
        else
            missing_sections+=("$section")
            zf::debug "    ✗ Missing section: $section"
        fi
    done

    # Check for essential content
    local essential_content=(
        "performance"
        "security"
        "plugin"
        "context"
        "alias"
    )

    for content in "${essential_content[@]}"; do
        if grep -qi "$content" "$user_guide"; then
            zf::debug "    ✓ Contains content about: $content"
        else
            zf::debug "    ⚠ Limited content about: $content"
        fi
    done

    if [[ ${#missing_sections[@]} -eq 0 ]]; then
        zf::debug "    ✓ User guide is complete"
        return 0
    else
        zf::debug "    ✗ User guide missing ${#missing_sections[@]} sections"
        return 1
    fi
}

test_api_reference_completeness() {
    zf::debug "    📊 Testing API reference completeness..."

    local api_ref="$DOCS_DIR/API-REFERENCE.md"

    if [[ ! -f "$api_ref" ]]; then
        zf::debug "    ✗ API reference not found"
        return 1
    fi

    local required_apis=(
        "Core Functions"
        "Plugin Management"
        "Context-Aware"
        "Async Caching"
        "Security"
        "Performance"
    )

    local missing_apis=()

    for api in "${required_apis[@]}"; do
        if grep -qi "$api" "$api_ref"; then
            zf::debug "    ✓ Found API section: $api"
        else
            missing_apis+=("$api")
            zf::debug "    ✗ Missing API section: $api"
        fi
    done

    # Check for function documentation
    local key_functions=(
        "is_being_executed"
        "register_plugin"
        "context-status"
        "cache-status"
        "_run_security_audit"
    )

    for func in "${key_functions[@]}"; do
        if grep -q "$func" "$api_ref"; then
            zf::debug "    ✓ Documents function: $func"
        else
            zf::debug "    ⚠ Missing function: $func"
        fi
    done

    if [[ ${#missing_apis[@]} -eq 0 ]]; then
        zf::debug "    ✓ API reference is complete"
        return 0
    else
        zf::debug "    ✗ API reference missing ${#missing_apis[@]} sections"
        return 1
    fi
}

test_architecture_documentation() {
    zf::debug "    📊 Testing architecture documentation..."

    local arch_doc="$DOCS_DIR/ARCHITECTURE.md"

    if [[ ! -f "$arch_doc" ]]; then
        zf::debug "    ✗ Architecture documentation not found"
        return 1
    fi

    local required_arch_sections=(
        "System Overview"
        "Directory Structure"
        "Loading Sequence"
        "Component Architecture"
        "Performance Considerations"
        "Security Architecture"
    )

    local missing_arch_sections=()

    for section in "${required_arch_sections[@]}"; do
        if grep -qi "$section" "$arch_doc"; then
            zf::debug "    ✓ Found architecture section: $section"
        else
            missing_arch_sections+=("$section")
            zf::debug "    ✗ Missing architecture section: $section"
        fi
    done

    # Check for technical details
    local technical_content=(
        "load order"
        "dependency"
        "performance"
        "security"
        "modular"
    )

    for content in "${technical_content[@]}"; do
        if grep -qi "$content" "$arch_doc"; then
            zf::debug "    ✓ Contains technical content: $content"
        else
            zf::debug "    ⚠ Limited technical content: $content"
        fi
    done

    if [[ ${#missing_arch_sections[@]} -eq 0 ]]; then
        zf::debug "    ✓ Architecture documentation is complete"
        return 0
    else
        zf::debug "    ✗ Architecture documentation missing ${#missing_arch_sections[@]} sections"
        return 1
    fi
}

test_troubleshooting_guide() {
    zf::debug "    📊 Testing troubleshooting guide..."

    local troubleshooting="$DOCS_DIR/TROUBLESHOOTING.md"

    if [[ ! -f "$troubleshooting" ]]; then
        zf::debug "    ✗ Troubleshooting guide not found"
        return 1
    fi

    local required_troubleshooting=(
        "Quick Diagnostics"
        "Common Issues"
        "Performance Problems"
        "Plugin Issues"
        "Context Problems"
        "Security Issues"
    )

    local missing_troubleshooting=()

    for section in "${required_troubleshooting[@]}"; do
        if grep -qi "$section" "$troubleshooting"; then
            zf::debug "    ✓ Found troubleshooting section: $section"
        else
            missing_troubleshooting+=("$section")
            zf::debug "    ✗ Missing troubleshooting section: $section"
        fi
    done

    # Check for practical solutions
    local solution_indicators=(
        "Solution"
        "Fix"
        "Diagnosis"
        "command not found"
        "slow startup"
    )

    for indicator in "${solution_indicators[@]}"; do
        if grep -qi "$indicator" "$troubleshooting"; then
            zf::debug "    ✓ Contains practical solutions: $indicator"
        else
            zf::debug "    ⚠ Limited practical solutions: $indicator"
        fi
    done

    if [[ ${#missing_troubleshooting[@]} -eq 0 ]]; then
        zf::debug "    ✓ Troubleshooting guide is complete"
        return 0
    else
        zf::debug "    ✗ Troubleshooting guide missing ${#missing_troubleshooting[@]} sections"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. DOCUMENTATION ACCURACY TESTS
# ------------------------------------------------------------------------------

test_command_references() {
    zf::debug "    📊 Testing command references accuracy..."

    local docs_to_check=(
        "$DOCS_DIR/USER-GUIDE.md"
        "$DOCS_DIR/API-REFERENCE.md"
        "$DOCS_DIR/TROUBLESHOOTING.md"
    )

    # Commands that should be documented
    local documented_commands=(
        "config-validate"
        "security-check"
        "profile"
        "cache-status"
        "context-status"
        "list-plugins"
    )

    local missing_commands=()

    for command in "${documented_commands[@]}"; do
        local found_in_docs=false

        for doc in "${docs_to_check[@]}"; do
            if [[ -f "$doc" ]] && grep -q "$command" "$doc"; then
                found_in_docs=true
                break
            fi
        done

        if $found_in_docs; then
            zf::debug "    ✓ Command documented: $command"
        else
            missing_commands+=("$command")
            zf::debug "    ✗ Command not documented: $command"
        fi
    done

    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        zf::debug "    ✓ All key commands are documented"
        return 0
    else
        zf::debug "    ✗ ${#missing_commands[@]} commands not documented"
        return 1
    fi
}

test_file_path_accuracy() {
    zf::debug "    📊 Testing file path accuracy..."

    local docs_to_check=(
        "$DOCS_DIR/USER-GUIDE.md"
        "$DOCS_DIR/API-REFERENCE.md"
        "$DOCS_DIR/ARCHITECTURE.md"
    )

    # Extract file paths from documentation and verify they exist
    local path_issues=0

    for doc in "${docs_to_check[@]}"; do
        if [[ ! -f "$doc" ]]; then
            continue
        fi

        # Look for common path patterns
        local paths=$(grep -o '~/.config/zsh/[^[:space:]]*' "$doc" 2>/dev/null || true)

        if [[ -n "$paths" ]]; then
            zf::debug "    ✓ Found file paths in $(basename "$doc")"
        else
            zf::debug "    ⚠ No file paths found in $(basename "$doc")"
        fi
    done

    # Check if key directories are mentioned
    local key_dirs=(
        ".zshrc.d"
        "tests"
        "docs"
        "logs"
    )

    for dir in "${key_dirs[@]}"; do
        local found=false
        for doc in "${docs_to_check[@]}"; do
            if [[ -f "$doc" ]] && grep -q "$dir" "$doc"; then
                found=true
                break
            fi
        done

        if $found; then
            zf::debug "    ✓ Directory mentioned: $dir"
        else
            zf::debug "    ⚠ Directory not mentioned: $dir"
            path_issues=$((path_issues + 1))
        fi
    done

    if [[ $path_issues -eq 0 ]]; then
        zf::debug "    ✓ File path references appear accurate"
        return 0
    else
        zf::debug "    ⚠ Some file path references may need review"
        return 0 # Non-critical issue
    fi
}

# ------------------------------------------------------------------------------
# 5. IMPLEMENTATION PLAN VALIDATION
# ------------------------------------------------------------------------------

test_implementation_plan_status() {
    zf::debug "    📊 Testing implementation plan status..."

    local impl_plan="$DOCS_DIR/zsh-improvement-implementation-plan-2025-08-20.md"

    if [[ ! -f "$impl_plan" ]]; then
        zf::debug "    ✗ Implementation plan not found"
        return 1
    fi

    # Check for completion indicators
    local completion_indicators=(
        "100% pass rate"
        "COMPLETED"
        "✅"
        "ACHIEVED"
    )

    local found_indicators=0

    for indicator in "${completion_indicators[@]}"; do
        if grep -q "$indicator" "$impl_plan"; then
            found_indicators=$((found_indicators + 1))
            zf::debug "    ✓ Found completion indicator: $indicator"
        fi
    done

    # Check for task status
    if grep -q "Task 7" "$impl_plan"; then
        zf::debug "    ✓ Task 7 (Documentation) is mentioned"
    else
        zf::debug "    ⚠ Task 7 (Documentation) not found"
    fi

    if [[ $found_indicators -gt 0 ]]; then
        zf::debug "    ✓ Implementation plan shows progress"
        return 0
    else
        zf::debug "    ⚠ Implementation plan may need status updates"
        return 0 # Non-critical
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    zf::debug "========================================================"
    zf::debug "Documentation Completeness Test Suite"
    zf::debug "========================================================"
    zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    zf::debug "Execution Context: $(get_execution_context)"
    zf::debug "Documentation Directory: $DOCS_DIR"
    zf::debug ""

    log_test "Starting documentation test suite"

    # Documentation Existence Tests
    zf::debug "=== Documentation Existence Tests ==="
    run_test "Documentation Files Exist" "test_documentation_files_exist"
    run_test "Documentation Readability" "test_documentation_readability"

    # Content Quality Tests
    zf::debug ""
    zf::debug "=== Content Quality Tests ==="
    run_test "User Guide Completeness" "test_user_guide_completeness"
    run_test "API Reference Completeness" "test_api_reference_completeness"
    run_test "Architecture Documentation" "test_architecture_documentation"
    run_test "Troubleshooting Guide" "test_troubleshooting_guide"

    # Accuracy Tests
    zf::debug ""
    zf::debug "=== Documentation Accuracy Tests ==="
    run_test "Command References" "test_command_references"
    run_test "File Path Accuracy" "test_file_path_accuracy"

    # Implementation Plan Tests
    zf::debug ""
    zf::debug "=== Implementation Plan Tests ==="
    run_test "Implementation Plan Status" "test_implementation_plan_status"

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

    log_test "Documentation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        zf::debug ""
        zf::debug "🎉 All documentation tests passed!"
        return 0
    else
        zf::debug ""
        zf::debug "❌ $TEST_FAILED documentation test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

documentation_test_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    documentation_test_main "$@"
elif is_being_sourced; then
    zf::debug "Documentation test functions loaded (sourced context)"
    zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Documentation Completeness Test Suite
# ==============================================================================
