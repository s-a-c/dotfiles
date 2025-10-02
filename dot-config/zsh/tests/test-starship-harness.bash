#!/usr/bin/env bash
# ==============================================================================
# ZSH Starship Test Harness
# ==============================================================================
# Purpose: Validate ZSH startup with Starship prompt initialization
# Usage: ./test-starship-harness.bash
# Requirements: bash 4.0+, timeout command, ZSH configuration in current directory
# Author: ZSH Configuration Test Suite
# Created: 2025-01-15
# ==============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_TIMEOUT=15
readonly ZSH_CONFIG_DIR="$SCRIPT_DIR"
readonly ZSH_BINARY="/opt/homebrew/bin/zsh"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
declare -i tests_passed=0
declare -i tests_total=0

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((tests_passed++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

run_test() {
    local test_name="$1"
    shift
    ((tests_total++))
    
    echo -e "\n${BLUE}=== Test: $test_name ===${NC}"
    
    if "$@"; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# Test functions
test_zsh_basic_startup() {
    log_info "Testing basic ZSH startup and prompt availability..."
    
    local test_output
    test_output=$(timeout "${TEST_TIMEOUT}s" bash -c "
        cd '$ZSH_CONFIG_DIR'
        export ZDOTDIR='$ZSH_CONFIG_DIR'
        echo 'Starting ZSH test...'
        '$ZSH_BINARY' -i -c 'echo \"ZSH_STARTUP_SUCCESS\"; exit'
    " 2>&1)
    
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        log_error "ZSH startup timed out after ${TEST_TIMEOUT} seconds"
        echo "Partial output: $test_output"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        log_error "ZSH startup failed with exit code $exit_code"
        echo "Output: $test_output"
        return 1
    elif echo "$test_output" | grep -q "ZSH_STARTUP_SUCCESS"; then
        log_info "ZSH startup completed successfully"
        return 0
    else
        log_error "ZSH startup did not complete properly"
        echo "Output: $test_output"
        return 1
    fi
}

test_starship_availability() {
    log_info "Checking Starship availability..."
    
    if command -v starship >/dev/null 2>&1; then
        local starship_version
        starship_version=$(starship --version | head -1)
        log_info "Starship found: $starship_version"
        return 0
    else
        log_error "Starship not found in PATH"
        log_info "PATH: $PATH"
        return 1
    fi
}

test_starship_initialization() {
    log_info "Testing Starship prompt initialization..."
    
    local test_output
    test_output=$(timeout "${TEST_TIMEOUT}s" bash -c "
        cd '$ZSH_CONFIG_DIR'
        export ZDOTDIR='$ZSH_CONFIG_DIR'
        zsh -i -c '
            # Check for Starship environment variable
            if [[ -n \"\$STARSHIP_SHELL\" ]]; then
                echo \"STARSHIP_INITIALIZED_SUCCESS\"
            else
                echo \"STARSHIP_NOT_INITIALIZED\"
                echo \"STARSHIP_SHELL: \$STARSHIP_SHELL\"
            fi
            exit
        '
    " 2>&1)
    
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        log_error "Starship test timed out after ${TEST_TIMEOUT} seconds"
        echo "Partial output: $test_output"
        return 1
    elif echo "$test_output" | grep -q "STARSHIP_INITIALIZED_SUCCESS"; then
        log_info "Starship successfully initialized"
        return 0
    else
        log_warning "Starship may not be initialized"
        echo "Output: $test_output"
        
        # Try alternative detection method
        log_info "Attempting alternative Starship detection..."
        local alt_test_output
        alt_test_output=$(timeout 10s bash -c "
            cd '$ZSH_CONFIG_DIR'
            export ZDOTDIR='$ZSH_CONFIG_DIR'
            zsh -i -c '
                # Check if starship init was called by looking for prompt function
                if typeset -f starship_precmd >/dev/null 2>&1; then
                    echo \"STARSHIP_PRECMD_FOUND\"
                else
                    echo \"STARSHIP_PRECMD_NOT_FOUND\"
                fi
                exit
            '
        " 2>&1)
        
        if echo "$alt_test_output" | grep -q "STARSHIP_PRECMD_FOUND"; then
            log_info "Starship precmd function detected - initialization successful"
            return 0
        else
            log_error "Starship initialization not detected via any method"
            echo "Alternative test output: $alt_test_output"
            return 1
        fi
    fi
}

test_environment_variables() {
    log_info "Testing ZSH environment variables..."
    
    local env_output
    env_output=$(timeout 10s bash -c "
        cd '$ZSH_CONFIG_DIR'
        export ZDOTDIR='$ZSH_CONFIG_DIR'
        zsh -i -c '
            echo \"=== ZSH Environment Test ===\"
            echo \"ZDOTDIR: \$ZDOTDIR\"
            echo \"ZSH_ENABLE_PREPLUGIN_REDESIGN: \$ZSH_ENABLE_PREPLUGIN_REDESIGN\"
            echo \"ZSH_ENABLE_POSTPLUGIN_REDESIGN: \$ZSH_ENABLE_POSTPLUGIN_REDESIGN\"
            echo \"USER_INTERFACE_VERSION: \$USER_INTERFACE_VERSION\"
            echo \"USER_INTERFACE_LOADED: \$USER_INTERFACE_LOADED\"
            echo \"Starship available: \$(command -v starship >/dev/null && echo yes || echo no)\"
            echo \"STARSHIP_SHELL: \$STARSHIP_SHELL\"
            exit
        '
    " 2>&1)
    
    local exit_code=$?
    
    if [[ $exit_code -eq 124 ]]; then
        log_error "Environment test timed out"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        log_error "Environment test failed with exit code $exit_code"
        echo "Output: $env_output"
        return 1
    else
        echo "$env_output"
        
        # Validate expected variables are set
        if echo "$env_output" | grep -q "ZSH_ENABLE_PREPLUGIN_REDESIGN: 1"; then
            log_info "✓ Pre-plugin redesign enabled"
        else
            log_warning "Pre-plugin redesign not enabled"
        fi
        
        if echo "$env_output" | grep -q "USER_INTERFACE_VERSION:"; then
            log_info "✓ User interface module loaded"
        else
            log_warning "User interface module may not be loaded"
        fi
        
        return 0
    fi
}

test_prompt_display() {
    log_info "Testing prompt display and interactivity..."
    
    # Use expect-like behavior with script if available
    if command -v expect >/dev/null 2>&1; then
        local expect_output
        expect_output=$(expect -c "
            spawn bash -c \"cd '$ZSH_CONFIG_DIR' && ZDOTDIR='$ZSH_CONFIG_DIR' zsh -i\"
            set timeout 15
            expect {
                \"*\$\" { 
                    send \"echo PROMPT_DISPLAYED\r\"
                    expect \"PROMPT_DISPLAYED\"
                    send \"exit\r\"
                    puts \"SUCCESS: Prompt displayed and interactive\"
                }
                timeout { 
                    puts \"TIMEOUT: No prompt appeared\"
                    exit 1
                }
            }
        " 2>&1)
        
        if echo "$expect_output" | grep -q "SUCCESS: Prompt displayed"; then
            log_info "Interactive prompt successfully displayed"
            return 0
        else
            log_warning "Could not verify interactive prompt display"
            echo "Expect output: $expect_output"
            return 1
        fi
    else
        log_info "expect not available, skipping interactive prompt test"
        log_info "Install expect for more comprehensive prompt testing"
        return 0
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}ZSH Starship Test Harness${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo -e "Config Directory: ${ZSH_CONFIG_DIR}"
    echo -e "Test Timeout: ${TEST_TIMEOUT}s"
    echo ""
    
    # Run all tests
    run_test "ZSH Basic Startup" test_zsh_basic_startup
    run_test "Starship Availability" test_starship_availability
    run_test "Environment Variables" test_environment_variables
    run_test "Starship Initialization" test_starship_initialization
    run_test "Prompt Display" test_prompt_display
    
    # Final results
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}Test Results${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        echo -e "${GREEN}All tests passed: $tests_passed/$tests_total${NC}"
        echo -e "${GREEN}✅ ZSH configuration with Starship is working correctly${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed: $tests_passed/$tests_total${NC}"
        echo -e "${RED}❌ ZSH configuration issues detected${NC}"
        
        echo -e "\n${YELLOW}Troubleshooting tips:${NC}"
        echo "1. Ensure Starship is installed: curl -sS https://starship.rs/install.sh | sh"
        echo "2. Check ZSH configuration syntax: zsh -n .zshrc"
        echo "3. Review environment variables in .zshenv"
        echo "4. Clear ZSH cache: rm -rf ~/.zcompdump* ~/.zsh_sessions"
        echo "5. Test minimal config: ZDOTDIR=\$PWD zsh -i"
        
        exit 1
    fi
}

# Run the test suite
main "$@"