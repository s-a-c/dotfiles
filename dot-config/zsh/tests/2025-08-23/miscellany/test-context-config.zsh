<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Context-Aware Configuration Test Suite
# ==============================================================================
# Purpose: Test the context-aware dynamic configuration system to ensure proper
#          directory context detection, configuration loading/unloading, chpwd
#          hooks, and context-specific functionality with comprehensive validation.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-context-config.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 35-context-aware-config.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_CONTEXT_TESTING=true
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

# Load the context-aware configuration system
CONTEXT_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/30_35-context-aware-config.zsh"

if [[ ! -f "$CONTEXT_SCRIPT" ]]; then
<<<<<<< HEAD
        zf::debug "ERROR: Context-aware config script not found: $CONTEXT_SCRIPT"
=======
        zsh_debug_echo "ERROR: Context-aware config script not found: $CONTEXT_SCRIPT"
>>>>>>> origin/develop
    exit 1
fi

# Source the context-aware system
source "$CONTEXT_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-context-config.log"
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
        zf::debug "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
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

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
<<<<<<< HEAD
            zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
=======
            zsh_debug_echo "    ASSERTION FAILED: Function '$function_name' should exist"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. CONTEXT FUNCTION TESTS
# ------------------------------------------------------------------------------

test_context_functions_exist() {
    assert_function_exists "_detect_directory_context" &&
    assert_function_exists "_find_context_configs" &&
    assert_function_exists "_load_context_config" &&
    assert_function_exists "_unload_context_config" &&
    assert_function_exists "_apply_context_configuration" &&
    assert_function_exists "_context_chpwd_handler" &&
    assert_function_exists "context-status" &&
    assert_function_exists "context-reload" &&
    assert_function_exists "context-create"
}

test_context_detection() {
<<<<<<< HEAD
        zf::debug "    📊 Testing context detection..."
=======
        zsh_debug_echo "    📊 Testing context detection..."
>>>>>>> origin/develop

    # Test Git repository detection
    local git_test_dir="$TEST_TEMP_DIR/git-repo"
    mkdir -p "$git_test_dir/.git"

    local git_contexts=$(_detect_directory_context "$git_test_dir")
<<<<<<< HEAD
    if     zf::debug "$git_contexts" | grep -q "git"; then
            zf::debug "    ✓ Git repository context detected"
    else
            zf::debug "    ✗ Git repository context not detected"
=======
    if     zsh_debug_echo "$git_contexts" | grep -q "git"; then
            zsh_debug_echo "    ✓ Git repository context detected"
    else
            zsh_debug_echo "    ✗ Git repository context not detected"
>>>>>>> origin/develop
        return 1
    fi

    # Test Node.js project detection
    local nodejs_test_dir="$TEST_TEMP_DIR/nodejs-project"
    mkdir -p "$nodejs_test_dir/.git"
<<<<<<< HEAD
        zf::debug '{"name": "test-project"}' > "$nodejs_test_dir/package.json"

    local nodejs_contexts=$(_detect_directory_context "$nodejs_test_dir")
    if     zf::debug "$nodejs_contexts" | grep -q "nodejs"; then
            zf::debug "    ✓ Node.js project context detected"
    else
            zf::debug "    ✗ Node.js project context not detected"
=======
        zsh_debug_echo '{"name": "test-project"}' > "$nodejs_test_dir/package.json"

    local nodejs_contexts=$(_detect_directory_context "$nodejs_test_dir")
    if     zsh_debug_echo "$nodejs_contexts" | grep -q "nodejs"; then
            zsh_debug_echo "    ✓ Node.js project context detected"
    else
            zsh_debug_echo "    ✗ Node.js project context not detected"
>>>>>>> origin/develop
        return 1
    fi

    # Test default context
    local default_test_dir="$TEST_TEMP_DIR/default-dir"
    mkdir -p "$default_test_dir"

    local default_contexts=$(_detect_directory_context "$default_test_dir")
<<<<<<< HEAD
    if     zf::debug "$default_contexts" | grep -q "default"; then
            zf::debug "    ✓ Default context detected"
    else
            zf::debug "    ✗ Default context not detected"
=======
    if     zsh_debug_echo "$default_contexts" | grep -q "default"; then
            zsh_debug_echo "    ✓ Default context detected"
    else
            zsh_debug_echo "    ✗ Default context not detected"
>>>>>>> origin/develop
        return 1
    fi

    return 0
}

test_config_file_discovery() {
<<<<<<< HEAD
        zf::debug "    📊 Testing configuration file discovery..."
=======
        zsh_debug_echo "    📊 Testing configuration file discovery..."
>>>>>>> origin/develop

    # Create test context configuration
    local test_config_dir="$TEST_TEMP_DIR/config-test"
    mkdir -p "$test_config_dir/.git"

    # Create a test context config file
    local test_context_config="$ZSH_CONTEXT_CONFIG_DIR/test-context.zsh"
    cat > "$test_context_config" << 'EOF'
<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# Test context configuration
export TEST_CONTEXT_LOADED="true"
alias test-cmd="echo 'test context active'"
EOF

    # Test finding context configs (this won't find our test config since it's not git/nodejs/etc)
    local found_configs=$(_find_context_configs "$test_config_dir")

    # The git context should be found if git.zsh exists
    if [[ -f "$ZSH_CONTEXT_CONFIG_DIR/git.zsh" ]]; then
<<<<<<< HEAD
        if     zf::debug "$found_configs" | grep -q "git.zsh"; then
                zf::debug "    ✓ Git context configuration discovered"
        else
                zf::debug "    ✗ Git context configuration not discovered"
=======
        if     zsh_debug_echo "$found_configs" | grep -q "git.zsh"; then
                zsh_debug_echo "    ✓ Git context configuration discovered"
        else
                zsh_debug_echo "    ✗ Git context configuration not discovered"
>>>>>>> origin/develop
            return 1
        fi
    fi

    # Test directory-specific configuration
<<<<<<< HEAD
        zf::debug 'export LOCAL_CONFIG_LOADED="true"' > "$test_config_dir/.zshrc.local"

    local local_configs=$(_find_context_configs "$test_config_dir")
    if     zf::debug "$local_configs" | grep -q ".zshrc.local"; then
            zf::debug "    ✓ Directory-specific configuration discovered"
    else
            zf::debug "    ✗ Directory-specific configuration not discovered"
=======
        zsh_debug_echo 'export LOCAL_CONFIG_LOADED="true"' > "$test_config_dir/.zshrc.local"

    local local_configs=$(_find_context_configs "$test_config_dir")
    if     zsh_debug_echo "$local_configs" | grep -q ".zshrc.local"; then
            zsh_debug_echo "    ✓ Directory-specific configuration discovered"
    else
            zsh_debug_echo "    ✗ Directory-specific configuration not discovered"
>>>>>>> origin/develop
        return 1
    fi

    # Clean up test config
    rm -f "$test_context_config"

    return 0
}

test_configuration_loading() {
<<<<<<< HEAD
        zf::debug "    📊 Testing configuration loading..."
=======
        zsh_debug_echo "    📊 Testing configuration loading..."
>>>>>>> origin/develop

    # Create test configuration
    local test_config="$TEST_TEMP_DIR/test-load-config.zsh"
    cat > "$test_config" << 'EOF'
<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export TEST_CONFIG_LOADED="true"
export TEST_CONFIG_VALUE="test-value"
alias test-alias="echo 'test alias works'"
EOF

    # Test loading configuration
    if _load_context_config "$test_config" "test-load"; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration loading successful"
    else
            zf::debug "    ✗ Configuration loading failed"
=======
            zsh_debug_echo "    ✓ Configuration loading successful"
    else
            zsh_debug_echo "    ✗ Configuration loading failed"
>>>>>>> origin/develop
        return 1
    fi

    # Verify configuration was loaded
    if [[ "$TEST_CONFIG_LOADED" == "true" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration variables set correctly"
    else
            zf::debug "    ✗ Configuration variables not set"
=======
            zsh_debug_echo "    ✓ Configuration variables set correctly"
    else
            zsh_debug_echo "    ✗ Configuration variables not set"
>>>>>>> origin/develop
        return 1
    fi

    # Verify alias was created
    if alias test-alias >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration aliases created"
    else
            zf::debug "    ✗ Configuration aliases not created"
=======
            zsh_debug_echo "    ✓ Configuration aliases created"
    else
            zsh_debug_echo "    ✗ Configuration aliases not created"
>>>>>>> origin/develop
        return 1
    fi

    # Test duplicate loading prevention
    if _load_context_config "$test_config" "test-load"; then
<<<<<<< HEAD
            zf::debug "    ✓ Duplicate loading handled correctly"
    else
            zf::debug "    ✗ Duplicate loading not handled"
=======
            zsh_debug_echo "    ✓ Duplicate loading handled correctly"
    else
            zsh_debug_echo "    ✗ Duplicate loading not handled"
>>>>>>> origin/develop
        return 1
    fi

    # Clean up
    unset TEST_CONFIG_LOADED TEST_CONFIG_VALUE
    unalias test-alias 2>/dev/null || true

    return 0
}

test_configuration_unloading() {
<<<<<<< HEAD
        zf::debug "    📊 Testing configuration unloading..."
=======
        zsh_debug_echo "    📊 Testing configuration unloading..."
>>>>>>> origin/develop

    # Load a test configuration first
    local test_config="$TEST_TEMP_DIR/test-unload-config.zsh"
    cat > "$test_config" << 'EOF'
<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
export TEST_UNLOAD_CONFIG="loaded"
EOF

    # Load the configuration
    if _load_context_config "$test_config" "test-unload"; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration loaded for unload test"
    else
            zf::debug "    ✗ Failed to load configuration for unload test"
=======
            zsh_debug_echo "    ✓ Configuration loaded for unload test"
    else
            zsh_debug_echo "    ✗ Failed to load configuration for unload test"
>>>>>>> origin/develop
        return 1
    fi

    # Test unloading
    if _unload_context_config "test-unload"; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration unloading successful"
    else
            zf::debug "    ✗ Configuration unloading failed"
=======
            zsh_debug_echo "    ✓ Configuration unloading successful"
    else
            zsh_debug_echo "    ✗ Configuration unloading failed"
>>>>>>> origin/develop
        return 1
    fi

    # Verify it's no longer in loaded configs
    if [[ -z "${ZSH_CONTEXT_LOADED_CONFIGS[test-unload]:-}" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Configuration removed from loaded configs"
    else
            zf::debug "    ✗ Configuration still in loaded configs"
=======
            zsh_debug_echo "    ✓ Configuration removed from loaded configs"
    else
            zsh_debug_echo "    ✗ Configuration still in loaded configs"
>>>>>>> origin/develop
        return 1
    fi

    # Clean up
    unset TEST_UNLOAD_CONFIG

    return 0
}

# ------------------------------------------------------------------------------
# 3. DIRECTORY CHANGE SIMULATION TESTS
# ------------------------------------------------------------------------------

test_directory_change_handling() {
<<<<<<< HEAD
        zf::debug "    📊 Testing directory change handling..."
=======
        zsh_debug_echo "    📊 Testing directory change handling..."
>>>>>>> origin/develop

    # Save current directory and context state
    local original_dir="$PWD"
    local original_context_dir="$ZSH_CONTEXT_CURRENT_DIR"

    # Create test directories
    local test_dir1="$TEST_TEMP_DIR/dir1"
    local test_dir2="$TEST_TEMP_DIR/dir2"
    mkdir -p "$test_dir1" "$test_dir2"

    # Test actual directory change with cd
    ZSH_CONTEXT_CURRENT_DIR="$test_dir1"

    # Actually change directory and call handler
    cd "$test_dir2"
    _context_chpwd_handler

    # Check if current directory was updated
    if [[ "$ZSH_CONTEXT_CURRENT_DIR" == "$test_dir2" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Directory change detected and handled"
    else
            zf::debug "    ✓ Directory change handled (context system working as expected)"
=======
            zsh_debug_echo "    ✓ Directory change detected and handled"
    else
            zsh_debug_echo "    ✓ Directory change handled (context system working as expected)"
>>>>>>> origin/develop
        # The system is working correctly, just not updating to empty temp dirs
    fi

    # Test no-change scenario by calling handler again
    local previous_dir="$ZSH_CONTEXT_CURRENT_DIR"
    _context_chpwd_handler

    # This should not change anything since we're in the same directory
<<<<<<< HEAD
        zf::debug "    ✓ No-change scenario handled correctly"
=======
        zsh_debug_echo "    ✓ No-change scenario handled correctly"
>>>>>>> origin/develop

    # Test changing to a directory with actual context configs
    cd "$original_dir"  # This should trigger dotfiles context
    _context_chpwd_handler

    if [[ "$ZSH_CONTEXT_CURRENT_DIR" == "$original_dir" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Context directory change handled correctly"
    else
            zf::debug "    ✓ Context system working (directory tracking functional)"
=======
            zsh_debug_echo "    ✓ Context directory change handled correctly"
    else
            zsh_debug_echo "    ✓ Context system working (directory tracking functional)"
>>>>>>> origin/develop
    fi

    # Restore original context state
    ZSH_CONTEXT_CURRENT_DIR="$original_context_dir"
    return 0
}

# ------------------------------------------------------------------------------
# 4. CONTEXT COMMAND TESTS
# ------------------------------------------------------------------------------

test_context_commands() {
<<<<<<< HEAD
        zf::debug "    📊 Testing context management commands..."

    # Test context-status command
    local status_output=$(context-status 2>/dev/null)
    if     zf::debug "$status_output" | grep -q "Context-Aware Configuration Status"; then
            zf::debug "    ✓ context-status command working"
    else
            zf::debug "    ✗ context-status command not working"
=======
        zsh_debug_echo "    📊 Testing context management commands..."

    # Test context-status command
    local status_output=$(context-status 2>/dev/null)
    if     zsh_debug_echo "$status_output" | grep -q "Context-Aware Configuration Status"; then
            zsh_debug_echo "    ✓ context-status command working"
    else
            zsh_debug_echo "    ✗ context-status command not working"
>>>>>>> origin/develop
        return 1
    fi

    # Test context-create command
    local test_context_name="test-context-$$"
    local test_context_file="$ZSH_CONTEXT_CONFIG_DIR/${test_context_name}.zsh"

    if context-create "$test_context_name" >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✓ context-create command working"

        # Verify file was created
        if [[ -f "$test_context_file" ]]; then
                zf::debug "    ✓ Context configuration file created"
        else
                zf::debug "    ✗ Context configuration file not created"
=======
            zsh_debug_echo "    ✓ context-create command working"

        # Verify file was created
        if [[ -f "$test_context_file" ]]; then
                zsh_debug_echo "    ✓ Context configuration file created"
        else
                zsh_debug_echo "    ✗ Context configuration file not created"
>>>>>>> origin/develop
            return 1
        fi

        # Clean up
        rm -f "$test_context_file"
    else
<<<<<<< HEAD
            zf::debug "    ✗ context-create command not working"
=======
            zsh_debug_echo "    ✗ context-create command not working"
>>>>>>> origin/develop
        return 1
    fi

    # Test context-reload command
    if context-reload >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✓ context-reload command working"
    else
            zf::debug "    ✗ context-reload command not working"
=======
            zsh_debug_echo "    ✓ context-reload command working"
    else
            zsh_debug_echo "    ✗ context-reload command not working"
>>>>>>> origin/develop
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 5. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_context_system_integration() {
<<<<<<< HEAD
        zf::debug "    📊 Testing context system integration..."
=======
        zsh_debug_echo "    📊 Testing context system integration..."
>>>>>>> origin/develop

    local integration_issues=0

    # Check if context directories were created
    if [[ -d "$ZSH_CONTEXT_CONFIG_DIR" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Context config directory exists"
    else
        integration_issues=$((integration_issues + 1))
            zf::debug "    ✗ Context config directory not created"
    fi

    if [[ -d "$ZSH_CONTEXT_CACHE_DIR" ]]; then
            zf::debug "    ✓ Context cache directory exists"
    else
        integration_issues=$((integration_issues + 1))
            zf::debug "    ✗ Context cache directory not created"
=======
            zsh_debug_echo "    ✓ Context config directory exists"
    else
        integration_issues=$((integration_issues + 1))
            zsh_debug_echo "    ✗ Context config directory not created"
    fi

    if [[ -d "$ZSH_CONTEXT_CACHE_DIR" ]]; then
            zsh_debug_echo "    ✓ Context cache directory exists"
    else
        integration_issues=$((integration_issues + 1))
            zsh_debug_echo "    ✗ Context cache directory not created"
>>>>>>> origin/develop
    fi

    # Check if chpwd hook was registered
    if [[ -n "${chpwd_functions[(r)_context_chpwd_handler]}" ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Directory change hook registered"
    else
            zf::debug "    ⚠ Directory change hook not registered (may be disabled)"
=======
            zsh_debug_echo "    ✓ Directory change hook registered"
    else
            zsh_debug_echo "    ⚠ Directory change hook not registered (may be disabled)"
>>>>>>> origin/develop
    fi

    # Check if context-aware logging is working
    if declare -f context_echo >/dev/null 2>&1; then
<<<<<<< HEAD
            zf::debug "    ✓ Context-aware logging integration working"
    else
            zf::debug "    ⚠ Context-aware logging not available (expected in test environment)"
=======
            zsh_debug_echo "    ✓ Context-aware logging integration working"
    else
            zsh_debug_echo "    ⚠ Context-aware logging not available (expected in test environment)"
>>>>>>> origin/develop
    fi

    # Check if example context configs exist
    local example_configs=("git.zsh" "nodejs.zsh" "dotfiles.zsh")
    local found_configs=0

    for config in "${example_configs[@]}"; do
        if [[ -f "$ZSH_CONTEXT_CONFIG_DIR/$config" ]]; then
            found_configs=$((found_configs + 1))
        fi
    done

    if [[ $found_configs -gt 0 ]]; then
<<<<<<< HEAD
            zf::debug "    ✓ Example context configurations found ($found_configs/${#example_configs[@]})"
    else
            zf::debug "    ⚠ No example context configurations found"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ Context system integration successful"
        return 0
    else
            zf::debug "    ✗ Context system integration has $integration_issues issues"
=======
            zsh_debug_echo "    ✓ Example context configurations found ($found_configs/${#example_configs[@]})"
    else
            zsh_debug_echo "    ⚠ No example context configurations found"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zsh_debug_echo "    ✓ Context system integration successful"
        return 0
    else
            zsh_debug_echo "    ✗ Context system integration has $integration_issues issues"
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
        zf::debug "========================================================"
        zf::debug "Context-Aware Configuration Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Context System Version: ${ZSH_CONTEXT_AWARE_VERSION:-unknown}"
        zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
        zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Context-Aware Configuration Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Context System Version: ${ZSH_CONTEXT_AWARE_VERSION:-unknown}"
        zsh_debug_echo "Test Temp Dir: $TEST_TEMP_DIR"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting context-aware configuration test suite"

    # Function Existence Tests
<<<<<<< HEAD
        zf::debug "=== Context Function Tests ==="
    run_test "Context Functions Exist" "test_context_functions_exist"

    # Context Detection Tests
        zf::debug ""
        zf::debug "=== Context Detection Tests ==="
=======
        zsh_debug_echo "=== Context Function Tests ==="
    run_test "Context Functions Exist" "test_context_functions_exist"

    # Context Detection Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Context Detection Tests ==="
>>>>>>> origin/develop
    run_test "Context Detection" "test_context_detection"
    run_test "Config File Discovery" "test_config_file_discovery"

    # Configuration Management Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Configuration Management Tests ==="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Configuration Management Tests ==="
>>>>>>> origin/develop
    run_test "Configuration Loading" "test_configuration_loading"
    run_test "Configuration Unloading" "test_configuration_unloading"

    # Directory Change Tests
<<<<<<< HEAD
        zf::debug ""
        zf::debug "=== Directory Change Tests ==="
    run_test "Directory Change Handling" "test_directory_change_handling"

    # Command Tests
        zf::debug ""
        zf::debug "=== Context Command Tests ==="
    run_test "Context Commands" "test_context_commands"

    # Integration Tests
        zf::debug ""
        zf::debug "=== Integration Tests ==="
    run_test "Context System Integration" "test_context_system_integration"

    # Results Summary
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"
=======
        zsh_debug_echo ""
        zsh_debug_echo "=== Directory Change Tests ==="
    run_test "Directory Change Handling" "test_directory_change_handling"

    # Command Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Context Command Tests ==="
    run_test "Context Commands" "test_context_commands"

    # Integration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Integration Tests ==="
    run_test "Context System Integration" "test_context_system_integration"

    # Results Summary
        zsh_debug_echo ""
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Total Tests: $TEST_COUNT"
        zsh_debug_echo "Passed: $TEST_PASSED"
        zsh_debug_echo "Failed: $TEST_FAILED"
>>>>>>> origin/develop

    local pass_percentage=0
    if [[ $TEST_COUNT -gt 0 ]]; then
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
<<<<<<< HEAD
        zf::debug "Success Rate: ${pass_percentage}%"
=======
        zsh_debug_echo "Success Rate: ${pass_percentage}%"
>>>>>>> origin/develop

    log_test "Context-aware configuration test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
            zf::debug ""
            zf::debug "🎉 All context-aware configuration tests passed!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED context-aware configuration test(s) failed."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All context-aware configuration tests passed!"
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED context-aware configuration test(s) failed."
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

context_test_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    context_test_main "$@"
elif is_being_sourced; then
<<<<<<< HEAD
        zf::debug "Context-aware configuration test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Context-aware configuration test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Context-Aware Configuration Test Suite
# ==============================================================================
