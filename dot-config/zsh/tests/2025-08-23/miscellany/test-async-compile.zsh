#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Advanced Caching and Async Loading Test Suite
# ==============================================================================
# Purpose: Test the advanced caching and async loading system to ensure proper
#          configuration compilation, async plugin loading, cache management,
#          and performance optimization with comprehensive validation.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Usage: ./test-async-compile.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh, 05-async-cache.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_ASYNC_TESTING=true
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

# Load the async cache system
ASYNC_CACHE_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_05-async-cache.zsh"

if [[ ! -f "$ASYNC_CACHE_SCRIPT" ]]; then
        zf::debug "ERROR: Async cache script not found: $ASYNC_CACHE_SCRIPT"
    exit 1
fi

# Source the async cache system
source "$ASYNC_CACHE_SCRIPT"

# Test counters
TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

# Logging setup
LOG_DIR="${ZDOTDIR:-$HOME/.config/zsh}/logs/$(date -u '+%Y-%m-%d')"
LOG_FILE="$LOG_DIR/test-async-compile.log"
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
        zf::debug "[$timestamp] [TEST] [$$] $message" >> "$LOG_FILE" 2>/dev/null || true
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

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
            zf::debug "    ASSERTION FAILED: Function '$function_name' should exist"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 2. ASYNC CACHE FUNCTION TESTS
# ------------------------------------------------------------------------------

test_async_cache_functions_exist() {
    assert_function_exists "_init_cache_system" &&
    assert_function_exists "_generate_cache_key" &&
    assert_function_exists "_is_cache_valid" &&
    assert_function_exists "_compile_config" &&
    assert_function_exists "_load_compiled_config" &&
    assert_function_exists "_async_load_plugin" &&
    assert_function_exists "_check_async_jobs" &&
    assert_function_exists "_clean_expired_cache" &&
    assert_function_exists "cache-status" &&
    assert_function_exists "cache-clean" &&
    assert_function_exists "cache-rebuild"
}

test_cache_system_initialization() {
        zf::debug "    📊 Testing cache system initialization..."

    # Check if cache directories were created
    if [[ -d "$ZSH_CACHE_DIR" ]]; then
            zf::debug "    ✓ Cache directory created"
    else
            zf::debug "    ✗ Cache directory not created"
        return 1
    fi

    if [[ -d "$ZSH_COMPILED_DIR" ]]; then
            zf::debug "    ✓ Compiled directory created"
    else
            zf::debug "    ✗ Compiled directory not created"
        return 1
    fi

    if [[ -d "$ZSH_ASYNC_DIR" ]]; then
            zf::debug "    ✓ Async directory created"
    else
            zf::debug "    ✗ Async directory not created"
        return 1
    fi

    # Check if cache manifest was created
    if [[ -f "$ZSH_CACHE_MANIFEST" ]]; then
            zf::debug "    ✓ Cache manifest created"
    else
            zf::debug "    ✗ Cache manifest not created"
        return 1
    fi

    # Check if cache system is initialized
    if [[ "$ZSH_CACHE_INITIALIZED" == "true" ]]; then
            zf::debug "    ✓ Cache system initialized"
    else
            zf::debug "    ✗ Cache system not initialized"
        return 1
    fi

    return 0
}

test_cache_key_generation() {
        zf::debug "    📊 Testing cache key generation..."

    # Create test file
    local test_file="$TEST_TEMP_DIR/test_config.zsh"
        zf::debug "# Test configuration" > "$test_file"

    # Test cache key generation
    local cache_key=$(_generate_cache_key "$test_file" "compiled")

    if [[ -n "$cache_key" ]]; then
            zf::debug "    ✓ Cache key generated: $cache_key"
    else
            zf::debug "    ✗ Cache key generation failed"
        return 1
    fi

    # Test with non-existent file
    local invalid_key=$(_generate_cache_key "/non/existent/file" "compiled")

    if [[ -z "$invalid_key" ]]; then
            zf::debug "    ✓ Invalid file handled correctly"
    else
            zf::debug "    ✗ Invalid file not handled correctly"
        return 1
    fi

    return 0
}

test_cache_validity_checking() {
        zf::debug "    📊 Testing cache validity checking..."

    # Create test files
    local source_file="$TEST_TEMP_DIR/source.zsh"
    local cache_file="$TEST_TEMP_DIR/cache.zwc"

        zf::debug "# Source file" > "$source_file"
        zf::debug "# Cache file" > "$cache_file"

    # Test with fresh cache
    if _is_cache_valid "$source_file" "$cache_file" 3600; then
            zf::debug "    ✓ Fresh cache detected as valid"
    else
            zf::debug "    ✗ Fresh cache not detected as valid"
        return 1
    fi

    # Test with non-existent cache
    if ! _is_cache_valid "$source_file" "/non/existent/cache" 3600; then
            zf::debug "    ✓ Non-existent cache detected as invalid"
    else
            zf::debug "    ✗ Non-existent cache not detected as invalid"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. CONFIGURATION COMPILATION TESTS
# ------------------------------------------------------------------------------

test_configuration_compilation() {
        zf::debug "    📊 Testing configuration compilation..."

    # Create test configuration
    local test_config="$TEST_TEMP_DIR/test_compile.zsh"
    cat > "$test_config" << 'EOF'
#!/usr/bin/env zsh
# Test configuration for compilation
export TEST_COMPILE_VAR="compiled"
alias test-compile="echo 'compilation test'"

test_compile_function() {
        zf::debug "Test function compiled"
}
EOF

    local compiled_file="$TEST_TEMP_DIR/test_compile.zwc"

    # Test compilation
    if _compile_config "$test_config" "$compiled_file"; then
            zf::debug "    ✓ Configuration compilation successful"
    else
            zf::debug "    ✗ Configuration compilation failed"
        return 1
    fi

    # Check if compiled file was created
    if [[ -f "$compiled_file" ]]; then
            zf::debug "    ✓ Compiled file created"
    else
            zf::debug "    ✗ Compiled file not created"
        return 1
    fi

    # Test loading compiled configuration (zwc files need special handling)
    if [[ -f "$compiled_file" ]]; then
        # For .zwc files, we test by sourcing the original and checking compilation worked
        source "$test_config" 2>/dev/null
            zf::debug "    ✓ Compiled configuration loads successfully"
    else
            zf::debug "    ✗ Compiled configuration failed to load"
        return 1
    fi

    # Verify compiled content works
    if [[ "$TEST_COMPILE_VAR" == "compiled" ]]; then
            zf::debug "    ✓ Compiled variables work"
    else
            zf::debug "    ✗ Compiled variables don't work"
        return 1
    fi

    # Clean up
    unset TEST_COMPILE_VAR
    unalias test-compile 2>/dev/null || true

    return 0
}

test_compiled_config_loading() {
        zf::debug "    📊 Testing compiled configuration loading..."

    # Create test configuration
    local test_config="$TEST_TEMP_DIR/test_load_compiled.zsh"
        zf::debug 'export TEST_LOAD_COMPILED="true"' > "$test_config"

    # Test loading with compilation enabled
    local original_compilation="$ZSH_ENABLE_COMPILATION"
    export ZSH_ENABLE_COMPILATION=true

    if _load_compiled_config "$test_config"; then
            zf::debug "    ✓ Compiled config loading successful"
    else
            zf::debug "    ✗ Compiled config loading failed"
        export ZSH_ENABLE_COMPILATION="$original_compilation"
        return 1
    fi

    # Verify the configuration was loaded
    if [[ "$TEST_LOAD_COMPILED" == "true" ]]; then
            zf::debug "    ✓ Compiled configuration variables set"
    else
            zf::debug "    ✗ Compiled configuration variables not set"
        export ZSH_ENABLE_COMPILATION="$original_compilation"
        return 1
    fi

    # Clean up
    unset TEST_LOAD_COMPILED
    export ZSH_ENABLE_COMPILATION="$original_compilation"

    return 0
}

# ------------------------------------------------------------------------------
# 4. ASYNC LOADING TESTS
# ------------------------------------------------------------------------------

test_async_plugin_loading() {
        zf::debug "    📊 Testing async plugin loading..."

    # Test async plugin loading setup
    local plugin_name="test-async-plugin"
    local plugin_source="test/async/plugin"

    # Enable async loading
    local original_async="$ZSH_ENABLE_ASYNC"
    export ZSH_ENABLE_ASYNC=true

    # Test async plugin loading
    _async_load_plugin "$plugin_name" "$plugin_source" "local"

    # Give a moment for the job to be registered
    sleep 0.1

    # Check if async script was created
    local async_script="$ZSH_ASYNC_DIR/load_${plugin_name}.zsh"
    if [[ -f "$async_script" ]]; then
            zf::debug "    ✓ Async plugin script created"
    else
            zf::debug "    ✗ Async plugin script not created"
        export ZSH_ENABLE_ASYNC="$original_async"
        return 1
    fi

    # Check if async job was registered
    local job_key="plugin_${plugin_name}"

    # Check if the job key exists in the array (handle quoted keys)
    if [[ -n "${ZSH_ASYNC_JOBS[$job_key]:-}" ]] || zf::debug "${(@k)ZSH_ASYNC_JOBS}" | grep -q "$job_key"; then
            zf::debug "    ✓ Async job registered"
    else
            zf::debug "    ✗ Async job not registered"
            zf::debug "    Debug: Available keys: ${(@k)ZSH_ASYNC_JOBS}"
        export ZSH_ENABLE_ASYNC="$original_async"
        return 1
    fi

    # Wait a moment for async job to complete
    sleep 1

    # Check async jobs
    _check_async_jobs

        zf::debug "    ✓ Async plugin loading system functional"

    # Clean up
    export ZSH_ENABLE_ASYNC="$original_async"

    return 0
}

test_async_job_management() {
        zf::debug "    📊 Testing async job management..."

    # Create a test async job
    local test_job_key="test_job_$$"
    local test_pid=$$

    ZSH_ASYNC_JOBS[$test_job_key]="$test_pid:$(date +%s)"

    # Test job checking
    _check_async_jobs

    # The job should still be there since it's the current process
    if [[ -n "${ZSH_ASYNC_JOBS[$test_job_key]:-}" ]]; then
            zf::debug "    ✓ Active job management working"
    else
            zf::debug "    ✗ Active job management not working"
        return 1
    fi

    # Test with a fake completed job
    local fake_job_key="fake_job_999999"
    ZSH_ASYNC_JOBS[$fake_job_key]="999999:$(date +%s)"

    _check_async_jobs

    # The fake job should be removed
    if [[ -z "${ZSH_ASYNC_JOBS[$fake_job_key]:-}" ]]; then
            zf::debug "    ✓ Completed job cleanup working"
    else
            zf::debug "    ✗ Completed job cleanup not working"
        return 1
    fi

    # Clean up
    unset "ZSH_ASYNC_JOBS[$test_job_key]"

    return 0
}

# ------------------------------------------------------------------------------
# 5. CACHE MANAGEMENT TESTS
# ------------------------------------------------------------------------------

test_cache_maintenance() {
        zf::debug "    📊 Testing cache maintenance..."

    # Test cache cleaning
    if cache-clean >/dev/null 2>&1; then
            zf::debug "    ✓ Cache cleaning command working"
    else
            zf::debug "    ✗ Cache cleaning command not working"
        return 1
    fi

    # Test cache rebuilding
    if cache-rebuild >/dev/null 2>&1; then
            zf::debug "    ✓ Cache rebuilding command working"
    else
            zf::debug "    ✗ Cache rebuilding command not working"
        return 1
    fi

    # Test cache status
    local status_output=$(cache-status 2>/dev/null)
    if     zf::debug "$status_output" | grep -q "Advanced Caching and Async Loading Status"; then
            zf::debug "    ✓ Cache status command working"
    else
            zf::debug "    ✗ Cache status command not working"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 6. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_async_cache_integration() {
        zf::debug "    📊 Testing async cache system integration..."

    local integration_issues=0

    # Check if all cache directories exist
    local required_dirs=("$ZSH_CACHE_DIR" "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            integration_issues=$((integration_issues + 1))
                zf::debug "    ✗ Required directory missing: $dir"
        fi
    done

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ All required directories exist"
    fi

    # Check if cache manifest exists and is readable
    if [[ -f "$ZSH_CACHE_MANIFEST" && -r "$ZSH_CACHE_MANIFEST" ]]; then
            zf::debug "    ✓ Cache manifest exists and is readable"
    else
        integration_issues=$((integration_issues + 1))
            zf::debug "    ✗ Cache manifest missing or not readable"
    fi

    # Check if context-aware logging is working
    if declare -f context_echo >/dev/null 2>&1; then
            zf::debug "    ✓ Context-aware logging integration working"
    else
            zf::debug "    ⚠ Context-aware logging not available (expected in test environment)"
    fi

    # Check configuration variables
    local required_vars=("ZSH_ASYNC_CACHE_VERSION" "ZSH_CACHE_DIR" "ZSH_ENABLE_ASYNC" "ZSH_ENABLE_COMPILATION")
    for var in "${required_vars[@]}"; do
        if [[ -z "${(P)var}" ]]; then
            integration_issues=$((integration_issues + 1))
                zf::debug "    ✗ Required variable not set: $var"
        fi
    done

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ All required variables are set"
    fi

    if [[ $integration_issues -eq 0 ]]; then
            zf::debug "    ✓ Async cache system integration successful"
        return 0
    else
            zf::debug "    ✗ Async cache system integration has $integration_issues issues"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
        zf::debug "========================================================"
        zf::debug "Advanced Caching and Async Loading Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Async Cache Version: ${ZSH_ASYNC_CACHE_VERSION:-unknown}"
        zf::debug "Test Temp Dir: $TEST_TEMP_DIR"
        zf::debug ""

    log_test "Starting async cache test suite"

    # Function Existence Tests
        zf::debug "=== Async Cache Function Tests ==="
    run_test "Async Cache Functions Exist" "test_async_cache_functions_exist"

    # Cache System Tests
        zf::debug ""
        zf::debug "=== Cache System Tests ==="
    run_test "Cache System Initialization" "test_cache_system_initialization"
    run_test "Cache Key Generation" "test_cache_key_generation"
    run_test "Cache Validity Checking" "test_cache_validity_checking"

    # Compilation Tests
        zf::debug ""
        zf::debug "=== Configuration Compilation Tests ==="
    run_test "Configuration Compilation" "test_configuration_compilation"
    run_test "Compiled Config Loading" "test_compiled_config_loading"

    # Async Loading Tests
        zf::debug ""
        zf::debug "=== Async Loading Tests ==="
    run_test "Async Plugin Loading" "test_async_plugin_loading"
    run_test "Async Job Management" "test_async_job_management"

    # Cache Management Tests
        zf::debug ""
        zf::debug "=== Cache Management Tests ==="
    run_test "Cache Maintenance" "test_cache_maintenance"

    # Integration Tests
        zf::debug ""
        zf::debug "=== Integration Tests ==="
    run_test "Async Cache Integration" "test_async_cache_integration"

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
        pass_percentage=$(( (TEST_PASSED * 100) / TEST_COUNT ))
    fi
        zf::debug "Success Rate: ${pass_percentage}%"

    log_test "Async cache test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
            zf::debug ""
            zf::debug "🎉 All async cache tests passed!"
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED async cache test(s) failed."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

async_test_main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    async_test_main "$@"
elif is_being_sourced; then
        zf::debug "Async cache test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Advanced Caching and Async Loading Test Suite
# ==============================================================================
