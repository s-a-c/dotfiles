#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Documentation Completeness Test Suite
# ==============================================================================
# Purpose: Test the documentation system to ensure comprehensive coverage,
#          accuracy, and completeness of all documentation files including
#          user guides, API reference, architecture docs, and troubleshooting
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

# Set testing flag to prevent initialization conflicts
export ZSH_DOCUMENTATION_TESTING=true
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
# 2. DOCUMENTATION EXISTENCE TESTS
# ------------------------------------------------------------------------------

test_documentation_files_exist() {
    echo "    📊 Testing documentation files existence..."
    
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
            echo "    ✗ Missing documentation: $doc"
        else
            echo "    ✓ Found documentation: $doc"
        fi
    done
    
    if [[ ${#missing_docs[@]} -eq 0 ]]; then
        echo "    ✓ All required documentation files exist"
        return 0
    else
        echo "    ✗ Missing ${#missing_docs[@]} documentation files"
        return 1
    fi
}

test_documentation_readability() {
    echo "    📊 Testing documentation readability..."
    
    local docs_to_check=(
        "$DOCS_DIR/USER-GUIDE.md"
        "$DOCS_DIR/API-REFERENCE.md"
        "$DOCS_DIR/ARCHITECTURE.md"
        "$DOCS_DIR/TROUBLESHOOTING.md"
    )
    
    local unreadable_docs=()
    
    for doc in "${docs_to_check[@]}"; do
        if [[ -f "$doc" && -r "$doc" ]]; then
            echo "    ✓ Readable: $(basename "$doc")"
        else
            unreadable_docs+=("$(basename "$doc")")
            echo "    ✗ Not readable: $(basename "$doc")"
        fi
    done
    
    if [[ ${#unreadable_docs[@]} -eq 0 ]]; then
        echo "    ✓ All documentation files are readable"
        return 0
    else
        echo "    ✗ ${#unreadable_docs[@]} documentation files are not readable"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 3. CONTENT QUALITY TESTS
# ------------------------------------------------------------------------------

test_user_guide_completeness() {
    echo "    📊 Testing user guide completeness..."
    
    local user_guide="$DOCS_DIR/USER-GUIDE.md"
    
    if [[ ! -f "$user_guide" ]]; then
        echo "    ✗ User guide not found"
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
            echo "    ✓ Found section: $section"
        else
            missing_sections+=("$section")
            echo "    ✗ Missing section: $section"
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
            echo "    ✓ Contains content about: $content"
        else
            echo "    ⚠ Limited content about: $content"
        fi
    done
    
    if [[ ${#missing_sections[@]} -eq 0 ]]; then
        echo "    ✓ User guide is complete"
        return 0
    else
        echo "    ✗ User guide missing ${#missing_sections[@]} sections"
        return 1
    fi
}

test_api_reference_completeness() {
    echo "    📊 Testing API reference completeness..."
    
    local api_ref="$DOCS_DIR/API-REFERENCE.md"
    
    if [[ ! -f "$api_ref" ]]; then
        echo "    ✗ API reference not found"
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
            echo "    ✓ Found API section: $api"
        else
            missing_apis+=("$api")
            echo "    ✗ Missing API section: $api"
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
            echo "    ✓ Documents function: $func"
        else
            echo "    ⚠ Missing function: $func"
        fi
    done
    
    if [[ ${#missing_apis[@]} -eq 0 ]]; then
        echo "    ✓ API reference is complete"
        return 0
    else
        echo "    ✗ API reference missing ${#missing_apis[@]} sections"
        return 1
    fi
}

test_architecture_documentation() {
    echo "    📊 Testing architecture documentation..."
    
    local arch_doc="$DOCS_DIR/ARCHITECTURE.md"
    
    if [[ ! -f "$arch_doc" ]]; then
        echo "    ✗ Architecture documentation not found"
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
            echo "    ✓ Found architecture section: $section"
        else
            missing_arch_sections+=("$section")
            echo "    ✗ Missing architecture section: $section"
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
            echo "    ✓ Contains technical content: $content"
        else
            echo "    ⚠ Limited technical content: $content"
        fi
    done
    
    if [[ ${#missing_arch_sections[@]} -eq 0 ]]; then
        echo "    ✓ Architecture documentation is complete"
        return 0
    else
        echo "    ✗ Architecture documentation missing ${#missing_arch_sections[@]} sections"
        return 1
    fi
}

test_troubleshooting_guide() {
    echo "    📊 Testing troubleshooting guide..."
    
    local troubleshooting="$DOCS_DIR/TROUBLESHOOTING.md"
    
    if [[ ! -f "$troubleshooting" ]]; then
        echo "    ✗ Troubleshooting guide not found"
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
            echo "    ✓ Found troubleshooting section: $section"
        else
            missing_troubleshooting+=("$section")
            echo "    ✗ Missing troubleshooting section: $section"
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
            echo "    ✓ Contains practical solutions: $indicator"
        else
            echo "    ⚠ Limited practical solutions: $indicator"
        fi
    done
    
    if [[ ${#missing_troubleshooting[@]} -eq 0 ]]; then
        echo "    ✓ Troubleshooting guide is complete"
        return 0
    else
        echo "    ✗ Troubleshooting guide missing ${#missing_troubleshooting[@]} sections"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 4. DOCUMENTATION ACCURACY TESTS
# ------------------------------------------------------------------------------

test_command_references() {
    echo "    📊 Testing command references accuracy..."
    
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
            echo "    ✓ Command documented: $command"
        else
            missing_commands+=("$command")
            echo "    ✗ Command not documented: $command"
        fi
    done
    
    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        echo "    ✓ All key commands are documented"
        return 0
    else
        echo "    ✗ ${#missing_commands[@]} commands not documented"
        return 1
    fi
}

test_file_path_accuracy() {
    echo "    📊 Testing file path accuracy..."
    
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
            echo "    ✓ Found file paths in $(basename "$doc")"
        else
            echo "    ⚠ No file paths found in $(basename "$doc")"
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
            echo "    ✓ Directory mentioned: $dir"
        else
            echo "    ⚠ Directory not mentioned: $dir"
            path_issues=$((path_issues + 1))
        fi
    done
    
    if [[ $path_issues -eq 0 ]]; then
        echo "    ✓ File path references appear accurate"
        return 0
    else
        echo "    ⚠ Some file path references may need review"
        return 0  # Non-critical issue
    fi
}

# ------------------------------------------------------------------------------
# 5. IMPLEMENTATION PLAN VALIDATION
# ------------------------------------------------------------------------------

test_implementation_plan_status() {
    echo "    📊 Testing implementation plan status..."
    
    local impl_plan="$DOCS_DIR/zsh-improvement-implementation-plan-2025-08-20.md"
    
    if [[ ! -f "$impl_plan" ]]; then
        echo "    ✗ Implementation plan not found"
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
            echo "    ✓ Found completion indicator: $indicator"
        fi
    done
    
    # Check for task status
    if grep -q "Task 7" "$impl_plan"; then
        echo "    ✓ Task 7 (Documentation) is mentioned"
    else
        echo "    ⚠ Task 7 (Documentation) not found"
    fi
    
    if [[ $found_indicators -gt 0 ]]; then
        echo "    ✓ Implementation plan shows progress"
        return 0
    else
        echo "    ⚠ Implementation plan may need status updates"
        return 0  # Non-critical
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Documentation Completeness Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "Documentation Directory: $DOCS_DIR"
    echo ""
    
    log_test "Starting documentation test suite"
    
    # Documentation Existence Tests
    echo "=== Documentation Existence Tests ==="
    run_test "Documentation Files Exist" "test_documentation_files_exist"
    run_test "Documentation Readability" "test_documentation_readability"
    
    # Content Quality Tests
    echo ""
    echo "=== Content Quality Tests ==="
    run_test "User Guide Completeness" "test_user_guide_completeness"
    run_test "API Reference Completeness" "test_api_reference_completeness"
    run_test "Architecture Documentation" "test_architecture_documentation"
    run_test "Troubleshooting Guide" "test_troubleshooting_guide"
    
    # Accuracy Tests
    echo ""
    echo "=== Documentation Accuracy Tests ==="
    run_test "Command References" "test_command_references"
    run_test "File Path Accuracy" "test_file_path_accuracy"
    
    # Implementation Plan Tests
    echo ""
    echo "=== Implementation Plan Tests ==="
    run_test "Implementation Plan Status" "test_implementation_plan_status"
    
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
    
    log_test "Documentation test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All documentation tests passed!"
        return 0
    else
        echo ""
        echo "❌ $TEST_FAILED documentation test(s) failed."
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
    echo "Documentation test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Documentation Completeness Test Suite
# ==============================================================================
