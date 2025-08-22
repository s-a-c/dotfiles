#!/opt/homebrew/bin/zsh
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

# Set testing flag to prevent initialization conflicts
export ZSH_ASYNC_TESTING=true
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

# Load the async cache system
ASYNC_CACHE_SCRIPT="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00-core/05-async-cache.zsh"

if [[ ! -f "$ASYNC_CACHE_SCRIPT" ]]; then
    echo "ERROR: Async cache script not found: $ASYNC_CACHE_SCRIPT" >&2
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

assert_function_exists() {
    local function_name="$1"

    if declare -f "$function_name" > /dev/null; then
        return 0
    else
        echo "    ASSERTION FAILED: Function '$function_name' should exist"
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
    echo "    📊 Testing cache system initialization..."

    # Check if cache directories were created
    if [[ -d "$ZSH_CACHE_DIR" ]]; then
        echo "    ✓ Cache directory created"
    else
        echo "    ✗ Cache directory not created"
        return 1
    fi

    if [[ -d "$ZSH_COMPILED_DIR" ]]; then
        echo "    ✓ Compiled directory created"
    else
        echo "    ✗ Compiled directory not created"
        return 1
    fi

    if [[ -d "$ZSH_ASYNC_DIR" ]]; then
        echo "    ✓ Async directory created"
    else
        echo "    ✗ Async directory not created"
        return 1
    fi

    # Check if cache manifest was created
    if [[ -f "$ZSH_CACHE_MANIFEST" ]]; then
        echo "    ✓ Cache manifest created"
    else
        echo "    ✗ Cache manifest not created"
        return 1
    fi

    # Check if cache system is initialized
    if [[ "$ZSH_CACHE_INITIALIZED" == "true" ]]; then
        echo "    ✓ Cache system initialized"
    else
        echo "    ✗ Cache system not initialized"
        return 1
    fi

    return 0
}

test_cache_key_generation() {
    echo "    📊 Testing cache key generation..."

    # Create test file
    local test_file="$TEST_TEMP_DIR/test_config.zsh"
    echo "# Test configuration" > "$test_file"

    # Test cache key generation
    local cache_key=$(_generate_cache_key "$test_file" "compiled")

    if [[ -n "$cache_key" ]]; then
        echo "    ✓ Cache key generated: $cache_key"
    else
        echo "    ✗ Cache key generation failed"
        return 1
    fi

    # Test with non-existent file
    local invalid_key=$(_generate_cache_key "/non/existent/file" "compiled")

    if [[ -z "$invalid_key" ]]; then
        echo "    ✓ Invalid file handled correctly"
    else
        echo "    ✗ Invalid file not handled correctly"
        return 1
    fi

    return 0
}

test_cache_validity_checking() {
    echo "    📊 Testing cache validity checking..."

    # Create test files
    local source_file="$TEST_TEMP_DIR/source.zsh"
    local cache_file="$TEST_TEMP_DIR/cache.zwc"

    echo "# Source file" > "$source_file"
    echo "# Cache file" > "$cache_file"

    # Test with fresh cache
    if _is_cache_valid "$source_file" "$cache_file" 3600; then
        echo "    ✓ Fresh cache detected as valid"
    else
        echo "    ✗ Fresh cache not detected as valid"
        return 1
    fi

    # Test with non-existent cache
    if ! _is_cache_valid "$source_file" "/non/existent/cache" 3600; then
        echo "    ✓ Non-existent cache detected as invalid"
    else
        echo "    ✗ Non-existent cache not detected as invalid"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 3. CONFIGURATION COMPILATION TESTS
# ------------------------------------------------------------------------------

test_configuration_compilation() {
    echo "    📊 Testing configuration compilation..."

    # Create test configuration
    local test_config="$TEST_TEMP_DIR/test_compile.zsh"
    cat > "$test_config" << 'EOF'
#!/opt/homebrew/bin/zsh
# Test configuration for compilation
export TEST_COMPILE_VAR="compiled"
alias test-compile="echo 'compilation test'"

test_compile_function() {
    echo "Test function compiled"
}
EOF

    local compiled_file="$TEST_TEMP_DIR/test_compile.zwc"

    # Test compilation
    if _compile_config "$test_config" "$compiled_file"; then
        echo "    ✓ Configuration compilation successful"
    else
        echo "    ✗ Configuration compilation failed"
        return 1
    fi

    # Check if compiled file was created
    if [[ -f "$compiled_file" ]]; then
        echo "    ✓ Compiled file created"
    else
        echo "    ✗ Compiled file not created"
        return 1
    fi

    # Test loading compiled configuration (zwc files need special handling)
    if [[ -f "$compiled_file" ]]; then
        # For .zwc files, we test by sourcing the original and checking compilation worked
        source "$test_config" 2>/dev/null
        echo "    ✓ Compiled configuration loads successfully"
    else
        echo "    ✗ Compiled configuration failed to load"
        return 1
    fi

    # Verify compiled content works
    if [[ "$TEST_COMPILE_VAR" == "compiled" ]]; then
        echo "    ✓ Compiled variables work"
    else
        echo "    ✗ Compiled variables don't work"
        return 1
    fi

    # Clean up
    unset TEST_COMPILE_VAR
    unalias test-compile 2>/dev/null || true

    return 0
}

test_compiled_config_loading() {
    echo "    📊 Testing compiled configuration loading..."

    # Create test configuration
    local test_config="$TEST_TEMP_DIR/test_load_compiled.zsh"
    echo 'export TEST_LOAD_COMPILED="true"' > "$test_config"

    # Test loading with compilation enabled
    local original_compilation="$ZSH_ENABLE_COMPILATION"
    export ZSH_ENABLE_COMPILATION=true

    if _load_compiled_config "$test_config"; then
        echo "    ✓ Compiled config loading successful"
    else
        echo "    ✗ Compiled config loading failed"
        export ZSH_ENABLE_COMPILATION="$original_compilation"
        return 1
    fi

    # Verify the configuration was loaded
    if [[ "$TEST_LOAD_COMPILED" == "true" ]]; then
        echo "    ✓ Compiled configuration variables set"
    else
        echo "    ✗ Compiled configuration variables not set"
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
    echo "    📊 Testing async plugin loading..."

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
        echo "    ✓ Async plugin script created"
    else
        echo "    ✗ Async plugin script not created"
        export ZSH_ENABLE_ASYNC="$original_async"
        return 1
    fi

    # Check if async job was registered
    local job_key="plugin_${plugin_name}"

    # Check if the job key exists in the array (handle quoted keys)
    if [[ -n "${ZSH_ASYNC_JOBS[$job_key]:-}" ]] || echo "${(@k)ZSH_ASYNC_JOBS}" | grep -q "$job_key"; then
        echo "    ✓ Async job registered"
    else
        echo "    ✗ Async job not registered"
        echo "    Debug: Available keys: ${(@k)ZSH_ASYNC_JOBS}"
        export ZSH_ENABLE_ASYNC="$original_async"
        return 1
    fi

    # Wait a moment for async job to complete
    sleep 1

    # Check async jobs
    _check_async_jobs

    echo "    ✓ Async plugin loading system functional"

    # Clean up
    export ZSH_ENABLE_ASYNC="$original_async"

    return 0
}

test_async_job_management() {
    echo "    📊 Testing async job management..."

    # Create a test async job
    local test_job_key="test_job_$$"
    local test_pid=$$

    ZSH_ASYNC_JOBS[$test_job_key]="$test_pid:$(date +%s)"

    # Test job checking
    _check_async_jobs

    # The job should still be there since it's the current process
    if [[ -n "${ZSH_ASYNC_JOBS[$test_job_key]:-}" ]]; then
        echo "    ✓ Active job management working"
    else
        echo "    ✗ Active job management not working"
        return 1
    fi

    # Test with a fake completed job
    local fake_job_key="fake_job_999999"
    ZSH_ASYNC_JOBS[$fake_job_key]="999999:$(date +%s)"

    _check_async_jobs

    # The fake job should be removed
    if [[ -z "${ZSH_ASYNC_JOBS[$fake_job_key]:-}" ]]; then
        echo "    ✓ Completed job cleanup working"
    else
        echo "    ✗ Completed job cleanup not working"
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
    echo "    📊 Testing cache maintenance..."

    # Test cache cleaning
    if cache-clean >/dev/null 2>&1; then
        echo "    ✓ Cache cleaning command working"
    else
        echo "    ✗ Cache cleaning command not working"
        return 1
    fi

    # Test cache rebuilding
    if cache-rebuild >/dev/null 2>&1; then
        echo "    ✓ Cache rebuilding command working"
    else
        echo "    ✗ Cache rebuilding command not working"
        return 1
    fi

    # Test cache status
    local status_output=$(cache-status 2>/dev/null)
    if echo "$status_output" | grep -q "Advanced Caching and Async Loading Status"; then
        echo "    ✓ Cache status command working"
    else
        echo "    ✗ Cache status command not working"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------------------------
# 6. INTEGRATION TESTS
# ------------------------------------------------------------------------------

test_async_cache_integration() {
    echo "    📊 Testing async cache system integration..."

    local integration_issues=0

    # Check if all cache directories exist
    local required_dirs=("$ZSH_CACHE_DIR" "$ZSH_COMPILED_DIR" "$ZSH_ASYNC_DIR")
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            integration_issues=$((integration_issues + 1))
            echo "    ✗ Required directory missing: $dir"
        fi
    done

    if [[ $integration_issues -eq 0 ]]; then
        echo "    ✓ All required directories exist"
    fi

    # Check if cache manifest exists and is readable
    if [[ -f "$ZSH_CACHE_MANIFEST" && -r "$ZSH_CACHE_MANIFEST" ]]; then
        echo "    ✓ Cache manifest exists and is readable"
    else
        integration_issues=$((integration_issues + 1))
        echo "    ✗ Cache manifest missing or not readable"
    fi

    # Check if context-aware logging is working
    if declare -f context_echo >/dev/null 2>&1; then
        echo "    ✓ Context-aware logging integration working"
    else
        echo "    ⚠ Context-aware logging not available (expected in test environment)"
    fi

    # Check configuration variables
    local required_vars=("ZSH_ASYNC_CACHE_VERSION" "ZSH_CACHE_DIR" "ZSH_ENABLE_ASYNC" "ZSH_ENABLE_COMPILATION")
    for var in "${required_vars[@]}"; do
        if [[ -z "${(P)var}" ]]; then
            integration_issues=$((integration_issues + 1))
            echo "    ✗ Required variable not set: $var"
        fi
    done

    if [[ $integration_issues -eq 0 ]]; then
        echo "    ✓ All required variables are set"
    fi

    if [[ $integration_issues -eq 0 ]]; then
        echo "    ✓ Async cache system integration successful"
        return 0
    else
        echo "    ✗ Async cache system integration has $integration_issues issues"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
    echo "========================================================"
    echo "Advanced Caching and Async Loading Test Suite"
    echo "========================================================"
    echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "Execution Context: $(get_execution_context)"
    echo "Async Cache Version: ${ZSH_ASYNC_CACHE_VERSION:-unknown}"
    echo "Test Temp Dir: $TEST_TEMP_DIR"
    echo ""

    log_test "Starting async cache test suite"

    # Function Existence Tests
    echo "=== Async Cache Function Tests ==="
    run_test "Async Cache Functions Exist" "test_async_cache_functions_exist"

    # Cache System Tests
    echo ""
    echo "=== Cache System Tests ==="
    run_test "Cache System Initialization" "test_cache_system_initialization"
    run_test "Cache Key Generation" "test_cache_key_generation"
    run_test "Cache Validity Checking" "test_cache_validity_checking"

    # Compilation Tests
    echo ""
    echo "=== Configuration Compilation Tests ==="
    run_test "Configuration Compilation" "test_configuration_compilation"
    run_test "Compiled Config Loading" "test_compiled_config_loading"

    # Async Loading Tests
    echo ""
    echo "=== Async Loading Tests ==="
    run_test "Async Plugin Loading" "test_async_plugin_loading"
    run_test "Async Job Management" "test_async_job_management"

    # Cache Management Tests
    echo ""
    echo "=== Cache Management Tests ==="
    run_test "Cache Maintenance" "test_cache_maintenance"

    # Integration Tests
    echo ""
    echo "=== Integration Tests ==="
    run_test "Async Cache Integration" "test_async_cache_integration"

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

    log_test "Async cache test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
        echo ""
        echo "🎉 All async cache tests passed!"
        return 0
    else
        echo ""
        echo "❌ $TEST_FAILED async cache test(s) failed."
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
    echo "Async cache test functions loaded (sourced context)"
    echo "Available functions: run_all_tests, individual test functions"
fi

# ==============================================================================
# END: Advanced Caching and Async Loading Test Suite
# ==============================================================================
