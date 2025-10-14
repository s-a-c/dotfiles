<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
#=============================================================================
# File: test-git-cache.zsh
# Purpose: 2.3.2 Dedicated test for git configuration caching functionality
# Dependencies: git, zsh with lazy git config system
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# ******* Working Directory Management - Save current working directory
original_cwd="$(pwd)"

# ******* Configuration and logging setup
config_base="/Users/s-a-c/.config/zsh"
log_date=$(date -u +%Y-%m-%d)
log_time=$(date -u +%H-%M-%S)
log_dir="$config_base/logs/$log_date"
log_file="$log_dir/test-git-cache_$log_time.log"

# ******* Setup logging directories
mkdir -p "$log_dir"

# ******* Test Configuration
test_results=()
test_count=0
passed_count=0
failed_count=0

# ******* Utility Functions
log_test() {
    local test_name="$1"
    local test_status="$2"
    local details="$3"

    test_count=$((test_count + 1))

    if [[ "$test_status" == "PASS" ]]; then
        passed_count=$((passed_count + 1))
<<<<<<< HEAD
            zf::debug "✅ Test $test_count: $test_name - PASSED"
        [[ -n "$details" ]] &&     zf::debug "   Details: $details"
    else
        failed_count=$((failed_count + 1))
            zf::debug "❌ Test $test_count: $test_name - FAILED"
        [[ -n "$details" ]] &&     zf::debug "   Error: $details"
=======
            zsh_debug_echo "✅ Test $test_count: $test_name - PASSED"
        [[ -n "$details" ]] &&     zsh_debug_echo "   Details: $details"
    else
        failed_count=$((failed_count + 1))
            zsh_debug_echo "❌ Test $test_count: $test_name - FAILED"
        [[ -n "$details" ]] &&     zsh_debug_echo "   Error: $details"
>>>>>>> origin/develop
    fi

    test_results+=("$test_count: $test_name - $test_status")
}

# ******* Test Functions

test_git_cache_file_location() {
    local expected_cache_file="$config_base/.cache/git-config-cache"

    if [[ -d "$config_base/.cache" ]]; then
        log_test "Git cache directory exists" "PASS" "Cache directory found at $config_base/.cache"
        return 0
    else
        log_test "Git cache directory exists" "FAIL" "Cache directory not found at $config_base/.cache"
        return 1
    fi
}

test_git_config_wrapper_loaded() {
    # Check if the git wrapper function exists
    if declare -f git >/dev/null 2>&1; then
        log_test "Git wrapper function loaded" "PASS" "git() function is defined"
        return 0
    else
        log_test "Git wrapper function loaded" "FAIL" "git() function not found"
        return 1
    fi
}

test_lazy_cache_function_exists() {
    # Check if the cache function exists
    if declare -f _cache_git_config >/dev/null 2>&1; then
        log_test "Lazy cache function exists" "PASS" "_cache_git_config() function is defined"
        return 0
    else
        log_test "Lazy cache function exists" "FAIL" "_cache_git_config() function not found"
        return 1
    fi
}

test_git_refresh_function_exists() {
    # Check if the refresh function exists
    if declare -f git-refresh-config >/dev/null 2>&1; then
        log_test "Git refresh function exists" "PASS" "git-refresh-config() function is defined"
        return 0
    else
        log_test "Git refresh function exists" "FAIL" "git-refresh-config() function not found"
        return 1
    fi
}

test_cache_generation() {
    local cache_file="$config_base/.cache/git-config-cache"

    # Clear existing cache
    [[ -f "$cache_file" ]] && rm -f "$cache_file"

    # Trigger cache generation by running git config command
    cd "$config_base"
    git config user.name >/dev/null 2>&1

    if [[ -f "$cache_file" ]]; then
        log_test "Cache generation on git command" "PASS" "Cache file created at $cache_file"
        return 0
    else
        log_test "Cache generation on git command" "FAIL" "Cache file not created after git command"
        return 1
    fi
}

test_cache_content_format() {
    local cache_file="$config_base/.cache/git-config-cache"

    if [[ ! -f "$cache_file" ]]; then
        log_test "Cache content format" "SKIP" "No cache file to test"
        return 0
    fi

    # Check if cache contains expected export statements
    local exports_found=0
    local expected_exports=("GIT_AUTHOR_NAME" "GIT_AUTHOR_EMAIL" "GIT_COMMITTER_NAME" "GIT_COMMITTER_EMAIL")

    for export_var in "${expected_exports[@]}"; do
        if grep -q "export $export_var=" "$cache_file"; then
            exports_found=$((exports_found + 1))
        fi
    done

    if [[ $exports_found -eq 4 ]]; then
        log_test "Cache content format" "PASS" "All 4 expected export statements found in cache"
        return 0
    else
        log_test "Cache content format" "FAIL" "Only $exports_found/4 expected export statements found"
        return 1
    fi
}

test_cache_timestamp_validation() {
    local cache_file="$config_base/.cache/git-config-cache"

    if [[ ! -f "$cache_file" ]]; then
        log_test "Cache timestamp validation" "SKIP" "No cache file to test"
        return 0
    fi

    # Get cache file timestamp
    local cache_timestamp
    if command -v stat >/dev/null 2>&1; then
<<<<<<< HEAD
        cache_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zf::debug "0")
=======
        cache_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zsh_debug_echo "0")
>>>>>>> origin/develop
        local current_timestamp=$(date +%s)
        local age_seconds=$((current_timestamp - cache_timestamp))
        local age_minutes=$((age_seconds / 60))

        if [[ $age_minutes -lt 60 ]]; then
            log_test "Cache timestamp validation" "PASS" "Cache is $age_minutes minutes old (< 60 minute TTL)"
            return 0
        else
            log_test "Cache timestamp validation" "FAIL" "Cache is $age_minutes minutes old (> 60 minute TTL)"
            return 1
        fi
    else
        log_test "Cache timestamp validation" "SKIP" "stat command not available"
        return 0
    fi
}

test_cache_refresh_functionality() {
    local cache_file="$config_base/.cache/git-config-cache"

    # Ensure cache exists first
    if [[ ! -f "$cache_file" ]]; then
        cd "$config_base" && git config user.name >/dev/null 2>&1
    fi

    if [[ ! -f "$cache_file" ]]; then
        log_test "Cache refresh functionality" "SKIP" "Could not create cache file for testing"
        return 0
    fi

    # Get original timestamp
<<<<<<< HEAD
    local original_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zf::debug "0")
=======
    local original_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zsh_debug_echo "0")
>>>>>>> origin/develop

    # Wait a moment to ensure timestamp difference
    sleep 1

    # Refresh cache
    git-refresh-config >/dev/null 2>&1

    # Get new timestamp
<<<<<<< HEAD
    local new_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zf::debug "0")
=======
    local new_timestamp=$(stat -f %m "$cache_file" 2>/dev/null || zsh_debug_echo "0")
>>>>>>> origin/develop

    if [[ "$new_timestamp" -gt "$original_timestamp" ]]; then
        log_test "Cache refresh functionality" "PASS" "Cache file timestamp updated after refresh"
        return 0
    else
        log_test "Cache refresh functionality" "FAIL" "Cache file timestamp not updated after refresh"
        return 1
    fi
}

test_environment_variable_export() {
    local cache_file="$config_base/.cache/git-config-cache"

    # Clear any existing git env vars
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

    # Ensure cache exists and source it
    if [[ -f "$cache_file" ]]; then
        source "$cache_file"
    else
        cd "$config_base" && git config user.name >/dev/null 2>&1
        [[ -f "$cache_file" ]] && source "$cache_file"
    fi

    # Check if environment variables are set
    local vars_set=0
    local expected_vars=("GIT_AUTHOR_NAME" "GIT_AUTHOR_EMAIL" "GIT_COMMITTER_NAME" "GIT_COMMITTER_EMAIL")

    for var_name in "${expected_vars[@]}"; do
        if [[ -n "${(P)var_name}" ]]; then
            vars_set=$((vars_set + 1))
        fi
    done

    if [[ $vars_set -eq 4 ]]; then
        log_test "Environment variable export" "PASS" "All 4 git environment variables are set"
        return 0
    else
        log_test "Environment variable export" "FAIL" "Only $vars_set/4 git environment variables are set"
        return 1
    fi
}

test_git_command_trigger_patterns() {
    # Test which git commands trigger the cache loading
    local triggering_commands=("commit" "log" "show" "config")
    local cache_file="$config_base/.cache/git-config-cache"

    # Clear cache
    [[ -f "$cache_file" ]] && rm -f "$cache_file"

    local triggered_count=0
    for cmd in "${triggering_commands[@]}"; do
        # Clear cache before each test
        [[ -f "$cache_file" ]] && rm -f "$cache_file"

        # Try the command (expect it might fail, but cache should be created)
        cd "$config_base" && git "$cmd" --help >/dev/null 2>&1 || true

        if [[ -f "$cache_file" ]]; then
            triggered_count=$((triggered_count + 1))
        fi
    done

    if [[ $triggered_count -gt 0 ]]; then
        log_test "Git command trigger patterns" "PASS" "$triggered_count/${#triggering_commands[@]} commands triggered cache creation"
        return 0
    else
        log_test "Git command trigger patterns" "FAIL" "None of the expected commands triggered cache creation"
        return 1
    fi
}

# ******* Main Test Execution
main() {
<<<<<<< HEAD
        zf::debug "=============================================================================="
        zf::debug "Git Configuration Caching Test Suite"
        zf::debug "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zf::debug "=============================================================================="
        zf::debug ""

    # Load the git caching system
    if [[ -f "$config_base/.zshrc.pre-plugins.d/05-lazy-git-config.zsh" ]]; then
            zf::debug "Loading git caching system..."
        source "$config_base/.zshrc.pre-plugins.d/05-lazy-git-config.zsh"
            zf::debug ""
    else
            zf::debug "❌ Git caching system not found at expected location"
            zf::debug ""
    fi

    # Run all tests
        zf::debug "🧪 Running git cache functionality tests..."
        zf::debug ""
=======
        zsh_debug_echo "=============================================================================="
        zsh_debug_echo "Git Configuration Caching Test Suite"
        zsh_debug_echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zsh_debug_echo "=============================================================================="
        zsh_debug_echo ""

    # Load the git caching system
    if [[ -f "$config_base/.zshrc.pre-plugins.d/05-lazy-git-config.zsh" ]]; then
            zsh_debug_echo "Loading git caching system..."
        source "$config_base/.zshrc.pre-plugins.d/05-lazy-git-config.zsh"
            zsh_debug_echo ""
    else
            zsh_debug_echo "❌ Git caching system not found at expected location"
            zsh_debug_echo ""
    fi

    # Run all tests
        zsh_debug_echo "🧪 Running git cache functionality tests..."
        zsh_debug_echo ""
>>>>>>> origin/develop

    test_git_cache_file_location
    test_git_config_wrapper_loaded
    test_lazy_cache_function_exists
    test_git_refresh_function_exists
    test_cache_generation
    test_cache_content_format
    test_cache_timestamp_validation
    test_cache_refresh_functionality
    test_environment_variable_export
    test_git_command_trigger_patterns

<<<<<<< HEAD
        zf::debug ""
        zf::debug "=============================================================================="
        zf::debug "Test Results Summary"
        zf::debug "=============================================================================="
        zf::debug "Total Tests: $test_count"
        zf::debug "Passed: $passed_count"
        zf::debug "Failed: $failed_count"
        zf::debug "Success Rate: $(( (passed_count * 100) / test_count ))%"
        zf::debug ""

    if [[ $failed_count -gt 0 ]]; then
            zf::debug "❌ Some tests failed. Review the details above."
            zf::debug ""
            zf::debug "Failed Tests:"
        for result in "${test_results[@]}"; do
            if [[ "$result" == *"FAILED"* ]]; then
                    zf::debug "  - $result"
            fi
        done
    else
            zf::debug "✅ All tests passed! Git caching system is working correctly."
    fi

        zf::debug ""
        zf::debug "=============================================================================="
        zf::debug "Git cache test completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zf::debug "=============================================================================="
=======
        zsh_debug_echo ""
        zsh_debug_echo "=============================================================================="
        zsh_debug_echo "Test Results Summary"
        zsh_debug_echo "=============================================================================="
        zsh_debug_echo "Total Tests: $test_count"
        zsh_debug_echo "Passed: $passed_count"
        zsh_debug_echo "Failed: $failed_count"
        zsh_debug_echo "Success Rate: $(( (passed_count * 100) / test_count ))%"
        zsh_debug_echo ""

    if [[ $failed_count -gt 0 ]]; then
            zsh_debug_echo "❌ Some tests failed. Review the details above."
            zsh_debug_echo ""
            zsh_debug_echo "Failed Tests:"
        for result in "${test_results[@]}"; do
            if [[ "$result" == *"FAILED"* ]]; then
                    zsh_debug_echo "  - $result"
            fi
        done
    else
            zsh_debug_echo "✅ All tests passed! Git caching system is working correctly."
    fi

        zsh_debug_echo ""
        zsh_debug_echo "=============================================================================="
        zsh_debug_echo "Git cache test completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zsh_debug_echo "=============================================================================="
>>>>>>> origin/develop

    # Return appropriate exit code
    [[ $failed_count -eq 0 ]] && return 0 || return 1
}

# ******* Execute main function with logging
{
    main "$@"
} 2>&1 | tee -a "$log_file"

# ******* Working Directory Restoration
if ! cd "$original_cwd" 2>/dev/null; then
<<<<<<< HEAD
        zf::debug "⚠️  Warning: Could not restore original directory: $original_cwd"
=======
        zsh_debug_echo "⚠️  Warning: Could not restore original directory: $original_cwd"
>>>>>>> origin/develop
    exit_code=1
fi

# Exit with appropriate code
exit $?
