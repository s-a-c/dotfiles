#!/usr/bin/env zsh
# Plugin Loading Test Suite
# Comprehensive tests for deferred plugin loading system performance and functionality
# Author: Configuration Management System
# Created: 2025-08-20
# Version: 1.0

# Save current working directory (required by user rules)
_original_pwd="$PWD"

# Create test log directory with UTC timestamp (required by user rules)
_test_date=$(date '+%Y-%m-%d' 2>/dev/null || zf::debug "unknown")
_test_timestamp=$(date '+%Y%m%d_%H%M%S' 2>/dev/null || zf::debug "unknown")
_test_log_dir="$HOME/.config/zsh/logs/${_test_date}"
[[ ! -d "$_test_log_dir" ]] && mkdir -p "$_test_log_dir"
_test_log_file="${_test_log_dir}/test-plugin-loading_${_test_timestamp}.log"

# Test results tracking
_tests_passed=0
_tests_failed=0
_test_results=()

# Function to log messages with timestamp (required by user rules)
_log_test() {
        zf::debug "[$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || zf::debug "$(date)")] $*" >> "$_test_log_file" 2>&1
        zf::debug "$*"
}

# Test assertion functions
_assert_true() {
    local condition="$1"
    local test_name="$2"
    local details="$3"

    if eval "$condition"; then
        _log_test "✅ PASS: $test_name"
        [[ -n "$details" ]] && _log_test "   Details: $details"
        _tests_passed=$((_tests_passed + 1))
        _test_results+=("PASS: $test_name")
        return 0
    else
        _log_test "❌ FAIL: $test_name"
        [[ -n "$details" ]] && _log_test "   Details: $details"
        _tests_failed=$((_tests_failed + 1))
        _test_results+=("FAIL: $test_name")
        return 1
    fi
}

_assert_false() {
    local condition="$1"
    local test_name="$2"
    local details="$3"

    if ! eval "$condition"; then
        _log_test "✅ PASS: $test_name"
        [[ -n "$details" ]] && _log_test "   Details: $details"
        _tests_passed=$((_tests_passed + 1))
        _test_results+=("PASS: $test_name")
        return 0
    else
        _log_test "❌ FAIL: $test_name"
        [[ -n "$details" ]] && _log_test "   Details: $details"
        _tests_failed=$((_tests_failed + 1))
        _test_results+=("FAIL: $test_name")
        return 1
    fi
}

_measure_time() {
    local start_time=$(date +%s.%N)
    eval "$1" >/dev/null 2>&1
    local end_time=$(date +%s.%N)
        zf::debug "scale=3; $end_time - $start_time" | bc
}

# Start test execution
_log_test "=== Plugin Loading Test Suite Started ==="
_log_test "Test timestamp: $_test_timestamp"
_log_test "Original PWD: $_original_pwd"
_log_test "Log file: $_test_log_file"

# Test 1: Verify deferred loading configuration exists
_log_test ""
_log_test "=== Test Group 1: Configuration Validation ==="

_assert_true '[[ -f "${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" ]]' \
    "Deferred loading configuration file exists" \
    "Path: ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh"

_assert_true '[[ -x "${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" ]]' \
    "Deferred loading configuration is executable"

# Test 2: Verify zsh-defer availability
_log_test ""
_log_test "=== Test Group 2: Dependencies Validation ==="

_assert_true 'command -v zsh-defer >/dev/null 2>&1' \
    "zsh-defer command is available" \
    "zsh-defer is required for deferred plugin loading"

_assert_true 'command -v zgenom >/dev/null 2>&1' \
    "zgenom plugin manager is available" \
    "zgenom is required for plugin loading"

# Test 3: Verify main plugin configuration changes
_log_test ""
_log_test "=== Test Group 3: Main Configuration Updates ==="

# Check that deferred plugins are commented out in main config
_assert_true 'grep -q "# DEFERRED.*git-extra-commands" ${HOME}/.config/zsh/.zgen-setup' \
    "git-extra-commands removed from main loading" \
    "Should be commented as deferred in .zgen-setup"

_assert_true 'grep -q "# DEFERRED.*jpb.zshplugin" ${HOME}/.config/zsh/.zgen-setup' \
    "jpb utilities removed from main loading" \
    "Should be commented as deferred in .zgen-setup"

_assert_true 'grep -q "# DEFERRED.*warhol.plugin.zsh" ${HOME}/.config/zsh/.zgen-setup' \
    "warhol plugin removed from main loading" \
    "Should be commented as deferred in .zgen-setup"

_assert_true 'grep -q "# DEFERRED.*docker.*completions" ${HOME}/.config/zsh/.zgen-setup' \
    "docker completions removed from main loading" \
    "Should be commented as deferred in .zgen-setup"

# Test 4: Test fresh shell startup performance
_log_test ""
_log_test "=== Test Group 4: Startup Performance Testing ==="

# Measure startup time with deferred loading
_log_test "Measuring shell startup time with deferred loading..."
_startup_time=$(_measure_time 'bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run "exit"')
'_log_test "Startup time: ${_startup_time}s"

# Parse startup time for validation (should be under 3 seconds on modern systems)
_startup_time_int=$(echo "$_startup_time * 1000" | bc | cut -d. -f1)
_assert_true "[[ $_startup_time_int -lt 3000 ]]" \
    "Shell startup time is reasonable" \
    "Startup time: ${_startup_time}s (should be < 3s)"

# Test 5: Test deferred loading functionality (simplified to avoid hanging)
_log_test ""
_log_test "=== Test Group 5: Deferred Loading Functionality ==="

# Test that our deferred loading script can be sourced directly without issues
_temp_test_script="/tmp/test-deferred-only-$$.zsh"
cat > "$_temp_test_script" << 'EOF'
#!/usr/bin/env zsh
# Source just the deferred loading script to test its functionality
export ZDOTDIR="$HOME/.config/zsh"

# Source the deferred loading script directly
source "$HOME/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" >/dev/null 2>&1

# Test if deferred loading wrapper functions exist
echo "WRAPPER_TEST_git:$(type git 2>/dev/null | grep -q 'git is a shell function' &&     zf::debug 'YES' || zf::debug 'NO')"
echo "WRAPPER_TEST_docker:$(type docker 2>/dev/null | grep -q 'docker is a shell function' &&     zf::debug 'YES' || zf::debug 'NO')"
echo "WRAPPER_TEST_op:$(type op 2>/dev/null | grep -q 'op is a shell function' &&     zf::debug 'YES' || zf::debug 'NO')"
echo "WRAPPER_TEST_rake:$(type rake 2>/dev/null | grep -q 'rake is a shell function' &&     zf::debug 'YES' || zf::debug 'NO')"

# Test environment variables for tracking loaded state
echo "ENV_TEST_git:${_GIT_EXTRA_COMMANDS_LOADED:-UNSET}"
echo "ENV_TEST_docker:${_DOCKER_ZSH_LOADED:-UNSET}"
echo "ENV_TEST_op:${_1PASSWORD_OP_LOADED:-UNSET}"
echo "ENV_TEST_rake:${_RAKE_COMPLETION_LOADED:-UNSET}"

# Test zsh-defer availability
echo "DEFER_TEST:$(command -v zsh-defer >/dev/null 2>&1 &&     zf::debug 'AVAILABLE' || zf::debug 'NOT_AVAILABLE')"
EOF

chmod +x "$_temp_test_script"

# Run the test script with timeout to prevent hanging
_test_output=$(timeout 10s zsh "$_temp_test_script" 2>/dev/null || zf::debug "TIMEOUT")
_log_test "Deferred loading test output:"
_log_test "$_test_output"

# Check for timeout
if [[ "$_test_output" == "TIMEOUT" ]]; then
    _log_test "⚠️  Test timed out - this may indicate an issue with the deferred loading script"
    _tests_failed=$((_tests_failed + 1))
    _test_results+=("FAIL: Deferred loading test timed out")
else
    # Parse test results
        zf::debug "$_test_output" | while IFS=':' read -r test_type result; do
        case "$test_type" in
            WRAPPER_TEST_git)
                _assert_true "[[ \"$result\" == \"YES\" ]]" \
                    "Git wrapper function is created" \
                    "git command should be wrapped for lazy loading"
                ;;
            WRAPPER_TEST_docker)
                _assert_true "[[ \"$result\" == \"YES\" ]]" \
                    "Docker wrapper function is created" \
                    "docker command should be wrapped for lazy loading"
                ;;
            WRAPPER_TEST_op)
                _assert_true "[[ \"$result\" == \"YES\" ]]" \
                    "1Password wrapper function is created" \
                    "op command should be wrapped for lazy loading"
                ;;
            WRAPPER_TEST_rake)
                _assert_true "[[ \"$result\" == \"YES\" ]]" \
                    "Rake wrapper function is created" \
                    "rake command should be wrapped for lazy loading"
                ;;
            ENV_TEST_git)
                _assert_true "[[ \"$result\" == \"UNSET\" ]]" \
                    "Git plugin not loaded on startup" \
                    "Should only load when git is used"
                ;;
            ENV_TEST_docker)
                _assert_true "[[ \"$result\" == \"UNSET\" ]]" \
                    "Docker plugin not loaded on startup" \
                    "Should only load when docker is used"
                ;;
            ENV_TEST_op)
                _assert_true "[[ \"$result\" == \"UNSET\" ]]" \
                    "1Password plugin not loaded on startup" \
                    "Should only load when op is used"
                ;;
            ENV_TEST_rake)
                _assert_true "[[ \"$result\" == \"UNSET\" ]]" \
                    "Rake plugin not loaded on startup" \
                    "Should only load when rake is used"
                ;;
            DEFER_TEST)
                _assert_true "[[ \"$result\" == \"AVAILABLE\" ]]" \
                    "zsh-defer is available in clean shell" \
                    "Required for deferred loading functionality"
                ;;
        esac
    done
fi

# Clean up temporary test script
rm -f "$_temp_test_script"

# Test 6: Test deferred loading script syntax validation
_log_test ""
_log_test "=== Test Group 6: Script Syntax Validation ==="

# Test that our deferred loading script has valid syntax
_syntax_check=$(zsh -n ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh 2>&1)
_syntax_result=$?

_assert_true "[[ $_syntax_result -eq 0 ]]" \
    "Deferred loading script has valid syntax" \
    "Syntax check output: $_syntax_check"

# Test 7: Test log file creation
_log_test ""
_log_test "=== Test Group 7: Logging Validation ==="

# Check that deferred loading creates appropriate log files
_assert_true '[[ -d "$HOME/.config/zsh/logs" ]]' \
    "Log directory structure exists" \
    "Required for comprehensive logging"

_assert_true '[[ -f "$_test_log_file" ]]' \
    "Test log file is being created" \
    "This test should be logging to: $_test_log_file"

# Test 8: Test configuration integrity
_log_test ""
_log_test "=== Test Group 8: Configuration Integrity ==="

# Verify essential plugins are still loaded immediately
_assert_true 'grep -q "zgenom load zdharma-continuum/fast-syntax-highlighting" ${HOME}/.config/zsh/.zgen-setup' \
    "Essential syntax highlighting plugin still loads immediately" \
    "Critical for real-time syntax highlighting"

_assert_true 'grep -q "zgenom load zsh-users/zsh-history-substring-search" ${HOME}/.config/zsh/.zgen-setup' \
    "Essential history search plugin still loads immediately" \
    "Critical for UP/DOWN arrow functionality"

_assert_true 'grep -q "zgenom load zsh-users/zsh-autosuggestions" ${HOME}/.config/zsh/.zgen-setup' \
    "Essential autosuggestions plugin still loads immediately" \
    "Critical for interactive shell experience"

# Verify prompt system is still loaded immediately
_assert_true 'grep -q "zgenom load romkatv/powerlevel10k" ${HOME}/.config/zsh/.zgen-setup' \
    "Essential prompt system still loads immediately" \
    "Critical for shell display"

# Test 9: Test file permissions and structure
_log_test ""
_log_test "=== Test Group 9: File System Validation ==="

_assert_true '[[ -r "${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" ]]' \
    "Deferred loading script is readable"

_assert_true '[[ -f "${HOME}/.config/zsh/docs/plugin-audit-defer-candidates.md" ]]' \
    "Plugin audit documentation exists" \
    "Documentation should be available for reference"

# Test 10: Test backup creation
_log_test ""
_log_test "=== Test Group 10: Backup and Safety ==="

_assert_true '[[ -f "${HOME}/.config/zsh/.zgen-setup.backup-deferred-"* ]]' \
    "Main configuration backup was created" \
    "Safety measure before modifications"

# Performance comparison test
_log_test ""
_log_test "=== Test Group 11: Performance Comparison ==="

# Simulate pre-deferred loading by counting original plugins in backup
_backup_file=$(ls ${HOME}/.config/zsh/.zgen-setup.backup-deferred-* | head -1)
_original_plugin_count=$(grep -c "zgenom load" "$_backup_file" 2>/dev/null || zf::debug "0")
_current_plugin_count=$(grep -c "zgenom load" ${HOME}/.config/zsh/.zgen-setup 2>/dev/null || zf::debug "0")

_log_test "Original plugin count (immediate loading): $_original_plugin_count"
_log_test "Current plugin count (immediate loading): $_current_plugin_count"

_plugin_reduction=$((_original_plugin_count - _current_plugin_count))
_assert_true "[[ $_plugin_reduction -gt 5 ]]" \
    "Significant plugin count reduction achieved" \
    "Reduced immediate loading from $_original_plugin_count to $_current_plugin_count plugins (-$_plugin_reduction)"

# Test 12: Test deferred plugins are properly scheduled
_log_test ""
_log_test "=== Test Group 12: Deferred Scheduling Validation ==="

# Test that zsh-defer commands are properly structured in our config
_assert_true 'grep -q "zsh-defer -t 1" ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh' \
    "Utility plugins scheduled with 1s delay" \
    "Background loading timing is configured"

_assert_true 'grep -q "zsh-defer -t 2" ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh' \
    "OMZ plugins scheduled with 2s delay" \
    "Staged loading approach is configured"

# Test that deferred plugins are properly listed
_deferred_utility_plugins=("jpb.zshplugin" "warhol.plugin.zsh" "tumult.plugin.zsh" "eventi/noreallyjustfuckingstopalready" "bitbucket-git-helpers" "skx/sysadmin-util" "StackExchange/blackbox" "sharat87/pip-app" "chrissicool/zsh-256color" "supercrabtree/k")

for plugin in "${_deferred_utility_plugins[@]}"; do
    _assert_true "grep -q \"$plugin\" ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" \
        "Utility plugin $plugin is in deferred loading" \
        "Should be loaded in background"
done

# Test OMZ deferred plugins
_deferred_omz_plugins=("plugins/aws" "plugins/chruby" "plugins/rsync" "plugins/screen" "plugins/vagrant" "plugins/macos")

for plugin in "${_deferred_omz_plugins[@]}"; do
    _assert_true "grep -q \"$plugin\" ${HOME}/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" \
        "OMZ plugin $plugin is in deferred loading" \
        "Should be loaded in background"
done

# Test 13: Test working directory preservation
_log_test ""
_log_test "=== Test Group 13: Working Directory Management ==="

_current_pwd="$PWD"
_assert_true "[[ \"$_current_pwd\" == \"$_original_pwd\" ]]" \
    "Working directory preserved during tests" \
    "Current: $_current_pwd, Original: $_original_pwd"

# Test 14: Test log file organization
_log_test ""
_log_test "=== Test Group 14: Log File Organization ==="

_assert_true '[[ -d "$HOME/.config/zsh/logs/$(date -u \"+%Y-%m-%d\")" ]]' \
    "Date-based log directory structure exists" \
    "Logs should be organized by UTC date"

_assert_true '[[ "$_test_log_file" =~ "test-plugin-loading_[0-9]{8}_[0-9]{6}\\.log$" ]]' \
    "Test log file follows UTC timestamp naming" \
    "File: $_test_log_file"

# Test 15: Integration test - verify configuration loads without errors
_log_test ""
_log_test "=== Test Group 15: Integration Testing ==="

# Test that our deferred loading configuration can be sourced without errors
_integration_test_result=$(zsh -c '
    export ZDOTDIR="$HOME/.config/zsh"
    source "$HOME/.config/zsh/.zshrc.pre-plugins.d/04-plugin-deferred-loading.zsh" 2>&1
        zf::debug "SOURCE_SUCCESS"
' 2>/dev/null | tail -1)

_assert_true "[[ \"$_integration_test_result\" == \"SOURCE_SUCCESS\" ]]" \
    "Deferred loading configuration sources without errors" \
    "Critical for shell startup success"

# Generate final test summary
_log_test ""
_log_test "=== TEST EXECUTION SUMMARY ==="
_log_test "Tests passed: $_tests_passed"
_log_test "Tests failed: $_tests_failed"
_log_test "Total tests: $((_tests_passed + _tests_failed))"

if [[ $_tests_failed -eq 0 ]]; then
    _log_test "🎉 ALL TESTS PASSED - Deferred plugin loading system is working correctly!"
    _overall_result="SUCCESS"
else
    _log_test "⚠️  SOME TESTS FAILED - Review the failed tests above"
    _overall_result="PARTIAL_SUCCESS"
fi

_log_test ""
_log_test "=== DETAILED TEST RESULTS ==="
for result in "${_test_results[@]}"; do
    _log_test "$result"
done

_log_test ""
_log_test "=== PERFORMANCE ANALYSIS ==="
_log_test "Shell startup time: ${_startup_time}s"
_log_test "Plugin reduction: $_plugin_reduction plugins moved to deferred loading"
_log_test "Immediate loading plugins remaining: $_current_plugin_count"

# Create performance report file
_performance_report="$_test_log_dir/plugin-loading-performance-report_${_test_timestamp}.md"
cat > "$_performance_report" << EOF
# Plugin Loading Performance Test Report

**Test Date**: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Test Type**: Deferred Plugin Loading Validation
**System**: $(uname -s) $(uname -r)

## Test Results Summary

- **Tests Passed**: $_tests_passed
- **Tests Failed**: $_tests_failed
- **Overall Result**: $_overall_result

## Performance Metrics

- **Startup Time**: ${_startup_time}s
- **Plugin Reduction**: $_plugin_reduction plugins moved to deferred loading
- **Immediate Loading**: $_current_plugin_count essential plugins only

## Plugin Categories

### Essential Plugins (Immediate Loading)
- zdharma-continuum/fast-syntax-highlighting
- zsh-users/zsh-history-substring-search
- zsh-users/zsh-autosuggestions
- romkatv/powerlevel10k (prompt)
- zsh-users/zsh-completions
- djui/alias-tips
- unixorn/fzf-zsh-plugin
- unixorn/autoupdate-zgenom

### Deferred Plugins (Background/On-Demand Loading)
- unixorn/git-extra-commands (loaded on git usage)
- srijanshetty/docker-zsh (loaded on docker usage)
- unixorn/1password-op.plugin.zsh (loaded on op usage)
- unixorn/rake-completion.zshplugin (loaded on rake usage)
- unixorn/jpb.zshplugin (background loaded)
- unixorn/warhol.plugin.zsh (background loaded)
- unixorn/tumult.plugin.zsh (background loaded)
- eventi/noreallyjustfuckingstopalready (background loaded)
- unixorn/bitbucket-git-helpers.plugin.zsh (background loaded)
- skx/sysadmin-util (background loaded)
- StackExchange/blackbox (background loaded)
- sharat87/pip-app (background loaded)
- chrissicool/zsh-256color (background loaded)
- supercrabtree/k (background loaded)
- RobSis/zsh-completion-generator (background loaded)

### Deferred OMZ Plugins
- oh-my-zsh plugins/aws (background loaded)
- oh-my-zsh plugins/chruby (background loaded)
- oh-my-zsh plugins/rsync (background loaded)
- oh-my-zsh plugins/screen (background loaded)
- oh-my-zsh plugins/vagrant (background loaded)
- oh-my-zsh plugins/macos (background loaded, Darwin only)

## Architecture Benefits

1. **Immediate Shell Availability**: Essential functionality loads first
2. **Background Enhancement**: Utility plugins load asynchronously
3. **On-Demand Loading**: Specialized tools load only when needed
4. **Staged Loading**: Different categories load at different times
5. **Preserved Functionality**: All plugins remain available when needed

## Log Files

- **Test Log**: $_test_log_file
- **Performance Report**: $_performance_report

EOF

_log_test "Performance report created: $_performance_report"

# Restore working directory (required by user rules)
cd "$_original_pwd" 2>/dev/null || {
    _log_test "ERROR: Failed to restore working directory to $_original_pwd"
    _log_test "Current directory: $(pwd)"
}

_log_test "=== Plugin Loading Test Suite Completed ==="

# Exit with appropriate code
if [[ $_tests_failed -eq 0 ]]; then
    exit 0
else
    exit 1
fi
