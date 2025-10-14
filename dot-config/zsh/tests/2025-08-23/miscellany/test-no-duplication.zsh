<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Duplication Detection Test Suite
# ==============================================================================
# Purpose: Scan configuration files for duplicate patterns, overlapping
#          configurations, and 020-consolidation opportunities to eliminate
#          redundancy and improve maintainability.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-21
# Version: 1.0
# Usage: ./test-no-duplication.zsh (execute) or source test-... (source)
# Dependencies: 01-source-execute-detection.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. INITIALIZE TESTING ENVIRONMENT
# ------------------------------------------------------------------------------

# Set 040-testing flag to prevent initialization conflicts
export ZSH_SOURCE_EXECUTE_TESTING=true
export ZSH_DEBUG=false

# Load the source/execute detection system
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
LOG_FILE="$LOG_DIR/test-no-duplication.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Configuration paths
ZSH_CONFIG_ROOT="${ZDOTDIR:-$HOME/.config/zsh}"
ZSHRC_DIR="$ZSH_CONFIG_ROOT/.zshrc.d"

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

get_config_files() {
    find "$ZSHRC_DIR" -name "*.zsh" -type f 2>/dev/null | sort
}

# ------------------------------------------------------------------------------
# 2. FZF CONFIGURATION DUPLICATION TESTS
# ------------------------------------------------------------------------------

test_fzf_configuration_duplication() {
    local fzf_files=()
    local fzf_configs=()

<<<<<<< HEAD
        zf::debug "    📊 Analyzing FZF configuration duplication..."
=======
        zsh_debug_echo "    📊 Analyzing FZF configuration duplication..."
>>>>>>> origin/develop

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue

        if grep -q "FZF\|fzf" "$config_file" 2>/dev/null; then
            fzf_files+=("$config_file")

            # Check for specific FZF patterns
            local patterns_found=0

            # FZF environment variables
            if grep -q "export FZF_" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): FZF environment variables"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): FZF environment variables"
>>>>>>> origin/develop
            fi

            # FZF keybindings
            if grep -q "fzf.*widget\|bindkey.*fzf" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): FZF keybindings"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): FZF keybindings"
>>>>>>> origin/develop
            fi

            # FZF command configuration
            if grep -q "FZF_DEFAULT_COMMAND\|FZF_CTRL_" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): FZF command configuration"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): FZF command configuration"
>>>>>>> origin/develop
            fi

            fzf_configs+=($patterns_found)
        fi
    done < <(get_config_files)

    local total_fzf_files=${#fzf_files[@]}
    local total_patterns=0
    for pattern_count in "${fzf_configs[@]}"; do
        total_patterns=$((total_patterns + pattern_count))
    done

<<<<<<< HEAD
        zf::debug "    📊 FZF analysis: $total_fzf_files files contain FZF config, $total_patterns total patterns"
=======
        zsh_debug_echo "    📊 FZF analysis: $total_fzf_files files contain FZF config, $total_patterns total patterns"
>>>>>>> origin/develop

    # Pass if FZF configuration is reasonably consolidated (≤3 files with significant config)
    local significant_configs=0
    for pattern_count in "${fzf_configs[@]}"; do
        [[ $pattern_count -ge 2 ]] && significant_configs=$((significant_configs + 1))
    done

<<<<<<< HEAD
        zf::debug "    📊 Significant FZF configs: $significant_configs files"
=======
        zsh_debug_echo "    📊 Significant FZF configs: $significant_configs files"
>>>>>>> origin/develop
    [[ $significant_configs -le 3 ]]
}

# ------------------------------------------------------------------------------
# 3. GIT CONFIGURATION DUPLICATION TESTS
# ------------------------------------------------------------------------------

test_git_configuration_duplication() {
    local git_files=()
    local git_configs=()

<<<<<<< HEAD
        zf::debug "    📊 Analyzing Git configuration duplication..."
=======
        zsh_debug_echo "    📊 Analyzing Git configuration duplication..."
>>>>>>> origin/develop

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue

        if grep -q "git.*config\|GIT_\|git.*alias" "$config_file" 2>/dev/null; then
            git_files+=("$config_file")

            # Check for specific Git patterns
            local patterns_found=0

            # Git global config commands
            if grep -q "git config --global" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): Git global configuration"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): Git global configuration"
>>>>>>> origin/develop
            fi

            # Git environment variables
            if grep -q "export GIT_" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): Git environment variables"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): Git environment variables"
>>>>>>> origin/develop
            fi

            # Git aliases
            if grep -q "git.*alias\|alias.*git" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): Git aliases"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): Git aliases"
>>>>>>> origin/develop
            fi

            git_configs+=($patterns_found)
        fi
    done < <(get_config_files)

    local total_git_files=${#git_files[@]}
    local total_patterns=0
    for pattern_count in "${git_configs[@]}"; do
        total_patterns=$((total_patterns + pattern_count))
    done

<<<<<<< HEAD
        zf::debug "    📊 Git analysis: $total_git_files files contain Git config, $total_patterns total patterns"
=======
        zsh_debug_echo "    📊 Git analysis: $total_git_files files contain Git config, $total_patterns total patterns"
>>>>>>> origin/develop

    # Pass if Git configuration is reasonably consolidated (≤2 files with significant config)
    local significant_configs=0
    for pattern_count in "${git_configs[@]}"; do
        [[ $pattern_count -ge 2 ]] && significant_configs=$((significant_configs + 1))
    done

<<<<<<< HEAD
        zf::debug "    📊 Significant Git configs: $significant_configs files"
=======
        zsh_debug_echo "    📊 Significant Git configs: $significant_configs files"
>>>>>>> origin/develop
    [[ $significant_configs -le 2 ]]
}

# ------------------------------------------------------------------------------
# 4. PATH MANIPULATION DUPLICATION TESTS
# ------------------------------------------------------------------------------

test_path_manipulation_duplication() {
    local path_files=()
    local path_configs=()

<<<<<<< HEAD
        zf::debug "    📊 Analyzing PATH manipulation duplication..."
=======
        zsh_debug_echo "    📊 Analyzing PATH manipulation duplication..."
>>>>>>> origin/develop

    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue

        if grep -q "PATH.*=" "$config_file" 2>/dev/null; then
            path_files+=("$config_file")

            # Check for specific PATH patterns
            local patterns_found=0

            # Direct PATH assignment
            if grep -q "export PATH=" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): Direct PATH assignment"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): Direct PATH assignment"
>>>>>>> origin/develop
            fi

            # PATH prepending/appending
            if grep -q "PATH.*:\|:.*PATH" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found + 1))
<<<<<<< HEAD
                    zf::debug "    ⚠ $(basename "$config_file"): PATH modification"
=======
                    zsh_debug_echo "    ⚠ $(basename "$config_file"): PATH modification"
>>>>>>> origin/develop
            fi

            # Helper function usage
            if grep -q "path_prepend\|path_append" "$config_file" 2>/dev/null; then
                patterns_found=$((patterns_found - 1))  # Subtract because this is good
<<<<<<< HEAD
                    zf::debug "    ✓ $(basename "$config_file"): Uses PATH helper functions"
=======
                    zsh_debug_echo "    ✓ $(basename "$config_file"): Uses PATH helper functions"
>>>>>>> origin/develop
            fi

            path_configs+=($patterns_found)
        fi
    done < <(get_config_files)

    local total_path_files=${#path_files[@]}
    local total_patterns=0
    for pattern_count in "${path_configs[@]}"; do
        total_patterns=$((total_patterns + pattern_count))
    done

<<<<<<< HEAD
        zf::debug "    📊 PATH analysis: $total_path_files files modify PATH, $total_patterns problematic patterns"
=======
        zsh_debug_echo "    📊 PATH analysis: $total_path_files files modify PATH, $total_patterns problematic patterns"
>>>>>>> origin/develop

    # Pass if PATH manipulation is reasonably consolidated (≤5 problematic patterns)
    [[ $total_patterns -le 5 ]]
}

# ------------------------------------------------------------------------------
# 5. ENVIRONMENT VARIABLE DUPLICATION TESTS
# ------------------------------------------------------------------------------

test_environment_variable_duplication() {
    local env_vars=()
    local duplicate_vars=()

<<<<<<< HEAD
        zf::debug "    📊 Analyzing environment variable duplication..."
=======
        zsh_debug_echo "    📊 Analyzing environment variable duplication..."
>>>>>>> origin/develop

    # Collect all exported variables
    while IFS= read -r config_file; do
        [[ -f "$config_file" ]] || continue

        while IFS= read -r line; do
            if [[ "$line" =~ export[[:space:]]+([A-Z_][A-Z0-9_]*)= ]]; then
                local var_name="${match[1]}"
                env_vars+=("$var_name:$(basename "$config_file")")
            fi
        done < "$config_file"
    done < <(get_config_files)

    # Find duplicates
    local -A var_counts
    for var_entry in "${env_vars[@]}"; do
        local var_name="${var_entry%%:*}"
        var_counts[$var_name]=$((${var_counts[$var_name]:-0} + 1))
    done

    local duplicate_count=0
    for var_name in "${(@k)var_counts}"; do
        if [[ ${var_counts[$var_name]} -gt 1 ]]; then
            duplicate_count=$((duplicate_count + 1))
<<<<<<< HEAD
                zf::debug "    ⚠ $var_name: exported in ${var_counts[$var_name]} files"
=======
                zsh_debug_echo "    ⚠ $var_name: exported in ${var_counts[$var_name]} files"
>>>>>>> origin/develop

            # Show which files
            for var_entry in "${env_vars[@]}"; do
                if [[ "$var_entry" =~ ^$var_name: ]]; then
<<<<<<< HEAD
                        zf::debug "      - ${var_entry#*:}"
=======
                        zsh_debug_echo "      - ${var_entry#*:}"
>>>>>>> origin/develop
                fi
            done
        fi
    done

<<<<<<< HEAD
        zf::debug "    📊 Environment variable analysis: $duplicate_count variables exported in multiple files"
=======
        zsh_debug_echo "    📊 Environment variable analysis: $duplicate_count variables exported in multiple files"
>>>>>>> origin/develop

    # Pass if reasonable number of duplicates (≤3 acceptable for common vars like PATH, EDITOR)
    [[ $duplicate_count -le 3 ]]
}

# ------------------------------------------------------------------------------
# 6. MAIN TEST EXECUTION
# ------------------------------------------------------------------------------

run_all_tests() {
<<<<<<< HEAD
        zf::debug "========================================================"
        zf::debug "Duplication Detection Test Suite"
        zf::debug "========================================================"
        zf::debug "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zf::debug "Execution Context: $(get_execution_context)"
        zf::debug "Configuration Directory: $ZSHRC_DIR"
        zf::debug ""
=======
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Duplication Detection Test Suite"
        zsh_debug_echo "========================================================"
        zsh_debug_echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo "Configuration Directory: $ZSHRC_DIR"
        zsh_debug_echo ""
>>>>>>> origin/develop

    log_test "Starting duplication detection test suite"

    # FZF Configuration Tests
<<<<<<< HEAD
        zf::debug "=== FZF Configuration Duplication Tests ==="
    run_test "FZF Configuration Duplication" "test_fzf_configuration_duplication"

    # Git Configuration Tests
        zf::debug ""
        zf::debug "=== Git Configuration Duplication Tests ==="
    run_test "Git Configuration Duplication" "test_git_configuration_duplication"

    # PATH Manipulation Tests
        zf::debug ""
        zf::debug "=== PATH Manipulation Duplication Tests ==="
    run_test "PATH Manipulation Duplication" "test_path_manipulation_duplication"

    # Environment Variable Tests
        zf::debug ""
        zf::debug "=== Environment Variable Duplication Tests ==="
    run_test "Environment Variable Duplication" "test_environment_variable_duplication"

    # Results Summary
        zf::debug ""
        zf::debug "========================================================"
        zf::debug "Test Results Summary"
        zf::debug "========================================================"
        zf::debug "Total Tests: $TEST_COUNT"
        zf::debug "Passed: $TEST_PASSED"
        zf::debug "Failed: $TEST_FAILED"
=======
        zsh_debug_echo "=== FZF Configuration Duplication Tests ==="
    run_test "FZF Configuration Duplication" "test_fzf_configuration_duplication"

    # Git Configuration Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Git Configuration Duplication Tests ==="
    run_test "Git Configuration Duplication" "test_git_configuration_duplication"

    # PATH Manipulation Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== PATH Manipulation Duplication Tests ==="
    run_test "PATH Manipulation Duplication" "test_path_manipulation_duplication"

    # Environment Variable Tests
        zsh_debug_echo ""
        zsh_debug_echo "=== Environment Variable Duplication Tests ==="
    run_test "Environment Variable Duplication" "test_environment_variable_duplication"

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

    log_test "Duplication detection test suite completed - $TEST_PASSED/$TEST_COUNT tests passed"

    if [[ $TEST_FAILED -eq 0 ]]; then
<<<<<<< HEAD
            zf::debug ""
            zf::debug "🎉 All duplication detection tests passed!"
            zf::debug "Configuration is reasonably consolidated."
        return 0
    else
            zf::debug ""
            zf::debug "❌ $TEST_FAILED duplication detection test(s) failed."
            zf::debug "Consolidation opportunities identified."
=======
            zsh_debug_echo ""
            zsh_debug_echo "🎉 All duplication detection tests passed!"
            zsh_debug_echo "Configuration is reasonably consolidated."
        return 0
    else
            zsh_debug_echo ""
            zsh_debug_echo "❌ $TEST_FAILED duplication detection test(s) failed."
            zsh_debug_echo "Consolidation opportunities identified."
>>>>>>> origin/develop
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 7. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

main() {
    run_all_tests
}

# Use the detection system to run main only when executed
if is_being_executed; then
    main "$@"
elif is_being_sourced; then
<<<<<<< HEAD
        zf::debug "Duplication detection test functions loaded (sourced context)"
        zf::debug "Available functions: run_all_tests, individual test functions"
=======
        zsh_debug_echo "Duplication detection test functions loaded (sourced context)"
        zsh_debug_echo "Available functions: run_all_tests, individual test functions"
>>>>>>> origin/develop
fi

# ==============================================================================
# END: Duplication Detection Test Suite
# ==============================================================================
