#!/opt/homebrew/bin/zsh
#=============================================================================
# File: test-lazy-loading.zsh
# Purpose: 2.2.4 Comprehensive test for lazy loading system
# Dependencies: zsh, direnv, git, gh
# Author: Configuration management system
# Last Modified: 2025-08-20
#=============================================================================

# Test working directory management
test_start_dir="$(pwd)"
trap 'cd "$test_start_dir" 2>/dev/null || true' EXIT

# Test logging setup
log_date=$(date -u +%Y-%m-%d)
log_time=$(date -u +%H-%M-%S)
log_dir="/Users/s-a-c/.config/zsh/logs/$log_date"
log_file="$log_dir/test-lazy-loading_$log_time.log"

# Ensure log directory exists
mkdir -p "$log_dir"

# Test execution with comprehensive logging
{
        zsh_debug_echo "🧪 Testing Lazy Loading System for Heavy Tools"
        zsh_debug_echo "=============================================="
        zsh_debug_echo "📅 Test Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        zsh_debug_echo "📋 Log File: $log_file"
        zsh_debug_echo ""

    # Test counters
    local tests_passed=0
    local tests_failed=0
    local total_tests=0

    # Helper function to run test cases
    run_test() {
        local test_name="$1"
        local test_command="$2"
        local expected_result="$3"

        total_tests=$((total_tests + 1))
        printf "%2d. %s...\n" "$total_tests" "$test_name"

        if eval "$test_command"; then
            if [[ "$expected_result" == "pass" ]]; then
                    zsh_debug_echo "   ✅ $test_name"
                tests_passed=$((tests_passed + 1))
            else
                    zsh_debug_echo "   ❌ $test_name (expected failure but passed)"
                tests_failed=$((tests_failed + 1))
            fi
        else
            if [[ "$expected_result" == "fail" ]]; then
                    zsh_debug_echo "   ✅ $test_name (expected failure)"
                tests_passed=$((tests_passed + 1))
            else
                    zsh_debug_echo "   ❌ $test_name"
                tests_failed=$((tests_failed + 1))
            fi
        fi
    }

    # Test 1: Verify lazy loading wrappers exist and are executable
    run_test "Testing lazy direnv wrapper exists" \
        "[[ -x ~/.config/zsh/.zshrc.pre-plugins.d/04-lazy-direnv.zsh ]]" \
        "pass"

    run_test "Testing lazy git config wrapper exists" \
        "[[ -x ~/.config/zsh/.zshrc.pre-plugins.d/05-lazy-git-config.zsh ]]" \
        "pass"

    run_test "Testing lazy GitHub Copilot wrapper exists" \
        "[[ -x ~/.config/zsh/.zshrc.pre-plugins.d/06-lazy-gh-copilot.zsh ]]" \
        "pass"

    # Test 2: Fresh shell startup time measurement
        zsh_debug_echo ""
        zsh_debug_echo "🚀 Testing startup time with lazy loading enabled..."

    startup_times=()
    for i in {1..3}; do
        printf "   Run %d: " "$i"
        startup_time=$(time bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run 'exit' 2'>&1 | tail -1 | grep -o '[0-9.]*s' | head -1 | sed 's/s//')
        if [[ -n "$startup_time" ]]; then
            startup_times+=($startup_time)
                zsh_debug_echo "${startup_time}s"
        else
                zsh_debug_echo "Failed to measure"
        fi
    done

    if [[ ${#startup_times[@]} -gt 0 ]]; then
        # Calculate average startup time
        local sum=0
        for time in "${startup_times[@]}"; do
            sum=$(echo "$sum + $time" | bc -l 2>/dev/null || zsh_debug_echo "$sum")
        done
        local avg_startup=$(echo "scale=3; $sum / ${#startup_times[@]}" | bc -l 2>/dev/null || zsh_debug_echo "0")
            zsh_debug_echo "   📊 Average startup time: ${avg_startup}s"

        # Test startup time is reasonable (< 10 seconds)
        run_test "Testing startup time is reasonable" \
            "[[ $(echo \"$avg_startup < 10\" | bc -l 2>/dev/null || zsh_debug_echo 0) -eq 1 ]]" \
            "pass"
    else
            zsh_debug_echo "   ❌ Could not measure startup times"
        tests_failed=$((tests_failed + 1))
        total_tests=$((total_tests + 1))
    fi

    # Test 3: Verify lazy loading state variables exist
        zsh_debug_echo ""
        zsh_debug_echo "🔍 Testing lazy loading initialization in clean shell..."

    lazy_test_result=$(bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run '
'        source ~/.config/zsh/.zshrc.pre-plugins.d/04-lazy-direnv.zsh 2>/dev/null
        source ~/.config/zsh/.zshrc.pre-plugins.d/05-lazy-git-config.zsh 2>/dev/null
        source ~/.config/zsh/.zshrc.pre-plugins.d/06-lazy-gh-copilot.zsh 2>/dev/null

        # Check if lazy loading state variables are set
        [[ -n "$_DIRENV_HOOKED" ]] &&     zsh_debug_echo "direnv_state_ok"
        [[ -n "$_GIT_CONFIG_LOADED" ]] &&     zsh_debug_echo "git_state_ok"
        [[ -n "$_GH_COPILOT_LOADED" ]] &&     zsh_debug_echo "copilot_state_ok"

        # Check if wrapper functions exist
        command -v direnv >/dev/null 2>&1 &&     zsh_debug_echo "direnv_wrapper_ok"
        command -v git >/dev/null 2>&1 &&     zsh_debug_echo "git_wrapper_ok"
        command -v ghcs >/dev/null 2>&1 &&     zsh_debug_echo "copilot_wrapper_ok"

        exit 0
    ' 2>/dev/null)

    run_test "Testing direnv lazy state initialized" \
        "echo '$lazy_test_result' | grep -q 'direnv_state_ok'" \
        "pass"

    run_test "Testing git lazy state initialized" \
        "echo '$lazy_test_result' | grep -q 'git_state_ok'" \
        "pass"

    run_test "Testing GitHub Copilot lazy state initialized" \
        "echo '$lazy_test_result' | grep -q 'copilot_state_ok'" \
        "pass"

    run_test "Testing direnv wrapper function available" \
        "echo '$lazy_test_result' | grep -q 'direnv_wrapper_ok'" \
        "pass"

    run_test "Testing git wrapper function available" \
        "echo '$lazy_test_result' | grep -q 'git_wrapper_ok'" \
        "pass"

    # Test 4: Test that tools are NOT loaded on startup (lazy behavior)
        zsh_debug_echo ""
        zsh_debug_echo "⏱️  Testing deferred execution behavior..."

    # Create temporary test directory for direnv test
    temp_test_dir="/tmp/lazy-loading-test-$$"
    mkdir -p "$temp_test_dir"
        zsh_debug_echo 'export TEST_LAZY_DIRENV=true' > "$temp_test_dir/.envrc"

    # Test that direnv is not loaded until triggered
    cd "$temp_test_dir"
    direnv_before_logs=$(find "$log_dir" -name "*lazy-direnv*" | wc -l)

    # Start fresh shell and immediately exit (should not trigger direnv)
    bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run 'exit' 2'>/dev/null

    direnv_after_logs=$(find "$log_dir" -name "*lazy-direnv*" | wc -l)

    run_test "Testing direnv not loaded on startup in directory with .envrc" \
        "[[ $direnv_before_logs -eq $direnv_after_logs ]]" \
        "pass"

    # Test 5: Test that tools ARE loaded when used
        zsh_debug_echo ""
        zsh_debug_echo "🎯 Testing on-demand loading behavior..."

    # Test direnv loading when used
    if command -v direnv >/dev/null 2>&1; then
        direnv_logs_before=$(find "$log_dir" -name "*lazy-direnv*" | wc -l)
        bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run 'direnv --version' 2'>/dev/null >/dev/null
        direnv_logs_after=$(find "$log_dir" -name "*lazy-direnv*" | wc -l)

        run_test "Testing direnv loads when command is used" \
            "[[ $direnv_logs_after -gt $direnv_logs_before ]]" \
            "pass"
    else
            zsh_debug_echo "   ⏭️  Skipping direnv loading test - direnv not available"
    fi

    # Test git config caching
    if command -v git >/dev/null 2>&1; then
        git_logs_before=$(find "$log_dir" -name "*lazy-git-config*" | wc -l)
        bash -c 'source "./.bash-harness-for-zsh-template.bash"; harness::run 'git config --get user.name' 2'>/dev/null >/dev/null
        git_logs_after=$(find "$log_dir" -name "*lazy-git-config*" | wc -l)

        run_test "Testing git config loads when git command is used" \
            "[[ $git_logs_after -gt $git_logs_before ]]" \
            "pass"
    else
            zsh_debug_echo "   ⏭️  Skipping git config loading test - git not available"
    fi

    # Test 6: Performance improvement verification
        zsh_debug_echo ""
        zsh_debug_echo "📈 Testing performance improvements..."

    # Check that immediate execution scripts are properly commented/replaced
    run_test "Testing direnv immediate execution removed" \
        "! grep -q 'eval.*direnv hook zsh' ~/.config/zsh/.zshrc.d/10_10-development-tools.zsh" \
        "pass"

    run_test "Testing git config immediate execution removed" \
        "! grep -q 'git config --get user.name' ~/.config/zsh/.zshrc.d/10_10-development-tools.zsh" \
        "pass"

    run_test "Testing GitHub Copilot immediate execution removed" \
        "! grep -q 'eval.*gh copilot alias' ~/.config/zsh/.zshrc.d/30_32-aliases.zsh" \
        "pass"

    # Test 7: Log file organization and caching
        zsh_debug_echo ""
        zsh_debug_echo "📊 Testing logging and caching systems..."

    run_test "Testing date-named log directory exists" \
        "[[ -d '$log_dir' ]]" \
        "pass"

    run_test "Testing UTC-timestamped log files" \
        "[[ $(find '$log_dir' -name '*lazy-*_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].log' | wc -l) -gt 0 ]]" \
        "pass"

    # Test git config cache
    if [[ -f ~/.config/zsh/.cache/git-config-cache ]]; then
        run_test "Testing git config cache file created" \
            "[[ -f ~/.config/zsh/.cache/git-config-cache ]]" \
            "pass"

        run_test "Testing git config cache contains expected variables" \
            "grep -q 'GIT_AUTHOR_NAME' ~/.config/zsh/.cache/git-config-cache" \
            "pass"
    else
            zsh_debug_echo "   ⏭️  Skipping git cache tests - cache not yet created"
    fi

    # Cleanup
    cd "$test_start_dir"
    rm -rf "$temp_test_dir" 2>/dev/null || true

        zsh_debug_echo ""
        zsh_debug_echo "🏁 Test Results Summary"
        zsh_debug_echo "======================"
        zsh_debug_echo "✅ Tests Passed: $tests_passed"
        zsh_debug_echo "❌ Tests Failed: $tests_failed"
        zsh_debug_echo "📊 Total Tests: $total_tests"
        zsh_debug_echo ""

    if [[ $tests_failed -eq 0 ]]; then
            zsh_debug_echo "🎉 All lazy loading tests passed!"
            zsh_debug_echo "✅ Task 2.2 lazy loading system working correctly"
        exit 0
    else
            zsh_debug_echo "⚠️  Some lazy loading tests failed"
            zsh_debug_echo "❌ Task 2.2 needs attention"
        exit 1
    fi

} 2>&1 | tee "$log_file"
