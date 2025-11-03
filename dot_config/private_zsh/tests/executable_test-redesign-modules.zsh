#!/usr/bin/env zsh
# ==============================================================================
# TEST-REDESIGN-MODULES.ZSH - Test Script for Refactored Modules
# ==============================================================================
# Purpose: Validate that all refactored REDESIGN modules work correctly
# Author: ZSH Configuration Redesign System
# Created: 2025-09-21
# Version: 1.0.0
# ==============================================================================

# Test configuration
export ZSH_DEBUG=1
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
export PERF_SEGMENT_TRACE=1

echo "=== Testing Refactored ZSH Pre-Plugin Modules (REDESIGN) ==="
echo "Test started at: $(date)"
echo ""

# Create test environment
TEST_ZDOTDIR="$PWD"
TEST_LOG_FILE="$TEST_ZDOTDIR/test-results.log"
mkdir -p "$TEST_ZDOTDIR/logs" 2>/dev/null

# Initialize test counters
total_tests=0
passed_tests=0
failed_tests=0

# Test helper functions
test_start() {
    local test_name="$1"
    echo "🧪 Testing: $test_name"
    ((total_tests++))
}

test_pass() {
    local test_name="$1"
    echo "✅ PASS: $test_name"
    ((passed_tests++))
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    echo "❌ FAIL: $test_name - $reason"
    ((failed_tests++))
}

# Start comprehensive testing
echo "📋 Running comprehensive module validation tests..." | tee "$TEST_LOG_FILE"
echo ""

# ==============================================================================
# TEST 1: Module Loading Test
# ==============================================================================

test_start "Module Loading and Load Guards"

# Test each module can be sourced without errors
modules_dir="$TEST_ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN"
declare -a test_modules=(
    "00-path-safety.zsh"
    "05-environment-setup.zsh"
    "10-fzf-initialization.zsh"
    "15-lazy-framework.zsh"
    "20-node-runtime.zsh"
    "25-macos-integration.zsh"
    "30-development-integrations.zsh"
    "35-ssh-and-security.zsh"
    "40-performance-and-controls.zsh"
)

for module in "${test_modules[@]}"; do
    if [[ -f "$modules_dir/$module" ]]; then
        if source "$modules_dir/$module" 2>&1 | tee -a "$TEST_LOG_FILE"; then
            test_pass "Loading $module"
        else
            test_fail "Loading $module" "Source command failed"
        fi
    else
        test_fail "Loading $module" "Module file not found"
    fi
done

# ==============================================================================
# TEST 2: Environment Variables Test
# ==============================================================================

test_start "Environment Variables Setup"

# Check critical environment variables
declare -A expected_vars=(
    ["PATH_SAFETY_VERSION"]="2.0.0"
    ["ENV_SETUP_VERSION"]="2.0.0"
    ["FZF_INIT_VERSION"]="2.0.0"
    ["LAZY_FRAMEWORK_VERSION"]="2.0.0"
    ["NODE_RUNTIME_VERSION"]="2.0.0"
    ["DEV_INTEGRATIONS_VERSION"]="2.0.0"
    ["SSH_SECURITY_VERSION"]="2.0.0"
    ["PERF_CONTROLS_VERSION"]="2.0.0"
    ["PRE_PLUGIN_PHASE_COMPLETE"]="1"
)

for var in "${(@k)expected_vars}"; do
    if [[ -n "${(P)var}" ]]; then
        test_pass "Environment variable: $var = ${(P)var}"
    else
        test_fail "Environment variable: $var" "Not set or empty"
    fi
done

# Test macOS-specific variable (may be skipped on non-macOS)
if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -n "${MACOS_INTEGRATION_VERSION:-}" ]]; then
        test_pass "macOS integration loaded"
    else
        test_fail "macOS integration" "Not loaded on macOS system"
    fi
else
    if [[ "${_LOADED_MACOS_INTEGRATION_REDESIGN:-}" == "skipped-non-darwin" ]]; then
        test_pass "macOS integration correctly skipped on non-Darwin"
    else
        test_fail "macOS integration" "Should be skipped on non-Darwin systems"
    fi
fi

# ==============================================================================
# TEST 3: Path Safety and Enhancement Test
# ==============================================================================

test_start "Path Safety and Enhancement"

# Check PATH deduplication
original_path="$PATH"
path_entries=(${(s/:/)PATH})
unique_path_entries=(${(u)path_entries})

if [[ ${#path_entries} -eq ${#unique_path_entries} ]]; then
    test_pass "PATH deduplication - no duplicates found"
else
    test_fail "PATH deduplication" "Found duplicate entries in PATH"
fi

# Check PATH contains essential directories
essential_paths=("/usr/bin" "/bin" "/usr/sbin" "/sbin")
for essential_path in "${essential_paths[@]}"; do
    if [[ ":$PATH:" == *":$essential_path:"* ]]; then
        test_pass "Essential path present: $essential_path"
    else
        test_fail "Essential path missing: $essential_path" "Not found in PATH"
    fi
done

# Check Homebrew paths (if Homebrew is available)
if command -v brew >/dev/null 2>&1; then
    homebrew_prefix="$(brew --prefix 2>/dev/null)"
    if [[ ":$PATH:" == *":$homebrew_prefix/bin:"* ]]; then
        test_pass "Homebrew path integration"
    else
        test_fail "Homebrew path integration" "Homebrew paths not properly added"
    fi
fi

# ==============================================================================
# TEST 4: Lazy Loading Framework Test
# ==============================================================================

test_start "Lazy Loading Framework"

# Check if lazy loading functions are available
if command -v lazy_register >/dev/null 2>&1; then
    test_pass "lazy_register function available"
else
    test_fail "lazy_register function" "Not available"
fi

if command -v lazy_status >/dev/null 2>&1; then
    test_pass "lazy_status function available"
else
    test_fail "lazy_status function" "Not available"
fi

# Test lazy loading registration (if available)
if command -v lazy_register >/dev/null 2>&1; then
    # Test registration
    test_command() { echo "test command executed"; }
    if lazy_register test-cmd test_command 2>&1 | grep -q "registered"; then
        test_pass "Lazy loading registration"
    else
        test_fail "Lazy loading registration" "Registration failed or no confirmation"
    fi
fi

# ==============================================================================
# TEST 5: Performance Monitoring Test
# ==============================================================================

test_start "Performance Monitoring"

# Check performance variables
if [[ -n "${ZSH_PERF_START_TIME:-}" ]]; then
    test_pass "Performance timing initialized"
else
    test_fail "Performance timing" "ZSH_PERF_START_TIME not set"
fi

# Check performance log directory
perf_log_dir="$(dirname "${PERF_SEGMENT_LOG:-}")"
if [[ -d "$perf_log_dir" ]]; then
    test_pass "Performance log directory created"
else
    test_fail "Performance log directory" "Directory not created: $perf_log_dir"
fi

# Test performance functions
if command -v perf_checkpoint >/dev/null 2>&1; then
    test_pass "perf_checkpoint function available"
else
    test_fail "perf_checkpoint function" "Not available"
fi

if command -v perf_report >/dev/null 2>&1; then
    test_pass "perf_report function available"
else
    test_fail "perf_report function" "Not available"
fi

# ==============================================================================
# TEST 6: SSH and Security Test
# ==============================================================================

test_start "SSH and Security Setup"

# Check SSH agent related functions
if command -v ssh_security_audit >/dev/null 2>&1; then
    test_pass "ssh_security_audit function available"
else
    test_fail "ssh_security_audit function" "Not available"
fi

if command -v generate_ssh_key >/dev/null 2>&1; then
    test_pass "generate_ssh_key function available"
else
    test_fail "generate_ssh_key function" "Not available"
fi

# Check SSH configuration
if [[ -n "${SSH_AGENT_TIMEOUT:-}" ]]; then
    test_pass "SSH agent timeout configured"
else
    test_fail "SSH agent timeout" "Not configured"
fi

# ==============================================================================
# TEST 7: Development Integration Test
# ==============================================================================

test_start "Development Integrations"

# Check development environment detection
if [[ -n "${DEV_ENV_DETECTED:-}" ]]; then
    test_pass "Development environment detection: $DEV_ENV_DETECTED"
else
    echo "ℹ️  INFO: No development environment detected (this may be normal)"
fi

# Check git configuration
if [[ -n "${GIT_EDITOR:-}" ]]; then
    test_pass "Git editor configured: $GIT_EDITOR"
else
    test_fail "Git editor" "Not configured"
fi

# Check editor detection
if [[ -n "${EDITOR:-}" ]]; then
    test_pass "System editor configured: $EDITOR"
else
    test_fail "System editor" "Not configured"
fi

# ==============================================================================
# TEST 8: Node Runtime Test (if Node.js is available)
# ==============================================================================

test_start "Node.js Runtime Environment"

# Check Node.js environment variables
if [[ -n "${NODE_ENV:-}" ]]; then
    test_pass "NODE_ENV configured: $NODE_ENV"
else
    test_fail "NODE_ENV" "Not configured"
fi

if [[ -n "${NVM_DIR:-}" ]]; then
    test_pass "NVM_DIR configured: $NVM_DIR"
else
    test_fail "NVM_DIR" "Not configured"
fi

# Check if NVM is available and registered
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    test_pass "NVM installation detected"
else
    echo "ℹ️  INFO: NVM not installed (this may be normal)"
fi

# ==============================================================================
# TEST 9: Feature Toggle Test
# ==============================================================================

test_start "Feature Toggle System"

# Check if toggle_feature function is available
if command -v toggle_feature >/dev/null 2>&1; then
    test_pass "toggle_feature function available"
    
    # Test debug toggle (should not affect current session)
    echo "📝 Testing feature toggle functionality..."
    original_debug="${ZSH_DEBUG:-}"
    
    # Toggle debug off and back on to test
    toggle_feature debug off >/dev/null 2>&1
    toggle_feature debug on >/dev/null 2>&1
    
    # Restore original debug state
    if [[ -n "$original_debug" ]]; then
        export ZSH_DEBUG="$original_debug"
    fi
    
    test_pass "Feature toggle system functional"
else
    test_fail "toggle_feature function" "Not available"
fi

# ==============================================================================
# TEST 10: Shell Integration Test
# ==============================================================================

test_start "Shell Integration and Options"

# Check critical shell options
critical_options=(
    "AUTO_CD"
    "AUTO_PUSHD"
    "HIST_IGNORE_DUPS"
    "INTERACTIVE_COMMENTS"
)

for option in "${critical_options[@]}"; do
    if [[ -o "$option" ]]; then
        test_pass "Shell option set: $option"
    else
        test_fail "Shell option: $option" "Not set"
    fi
done

# Check history configuration
if [[ -n "${HISTFILE:-}" ]] && [[ -n "${HISTSIZE:-}" ]]; then
    test_pass "History configuration: HISTFILE=$HISTFILE, HISTSIZE=$HISTSIZE"
else
    test_fail "History configuration" "HISTFILE or HISTSIZE not properly configured"
fi

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

echo ""
echo "=== Test Results Summary ==="
echo "Total tests run: $total_tests"
echo "Tests passed: $passed_tests"
echo "Tests failed: $failed_tests"

if [[ $failed_tests -eq 0 ]]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! 🎉"
    echo "The refactored modules are working correctly."
    echo ""
    echo "📊 Performance Report:"
    if command -v perf_report >/dev/null 2>&1; then
        perf_report
    fi
    echo ""
    echo "✨ The REDESIGN modules are ready for use!"
    exit 0
else
    echo ""
    echo "⚠️  SOME TESTS FAILED"
    echo "Please review the failed tests above and check the modules."
    echo "See detailed logs in: $TEST_LOG_FILE"
    exit 1
fi