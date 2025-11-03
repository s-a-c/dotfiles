#!/usr/bin/env bash
# ==============================================================================
# POST-STARTUP HANG DETECTION TEST HARNESS
# ==============================================================================
# Purpose: Enhanced test harness to detect hanging issues after ZSH startup
# Author: ZSH Configuration Repair System
# Created: 2025-09-22
# ==============================================================================

set -euo pipefail

# Configuration
readonly ZDOTDIR="${HOME}/.config/zsh"
readonly TIMEOUT_STARTUP=45  # Generous timeout for startup completion
readonly TIMEOUT_POST=15     # Shorter timeout for post-startup responsiveness
readonly TEST_LOG="/tmp/zsh-hang-test.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$TEST_LOG"
}

# Test startup completion
test_startup_completion() {
    log_info "Testing ZSH startup completion..."
    
    local startup_output
    if startup_output=$(timeout "$TIMEOUT_STARTUP" bash -c "
        ZDOTDIR='$ZDOTDIR' zsh -i -c 'echo \"STARTUP_COMPLETE_MARKER\"; exit' 2>&1
    "); then
        if echo \"$startup_output\" | grep -q "STARTUP_COMPLETE_MARKER"; then
            log_success "ZSH startup completed successfully"
            return 0
        else
            log_error "ZSH startup completed but no completion marker found"
            echo "$startup_output" | tail -20 >> "$TEST_LOG"
            return 1
        fi
    else
        log_error "ZSH startup timed out after ${TIMEOUT_STARTUP}s"
        echo "$startup_output" | tail -20 >> "$TEST_LOG"
        return 1
    fi
}

# Test post-startup responsiveness
test_post_startup_responsiveness() {
    log_info "Testing post-startup responsiveness..."
    
    # Use expect-like approach with a longer session
    local test_script=$(cat << 'EOF'
        set -o pipefail
        
        # Start ZSH in background with a pseudoterminal
        exec {zsh_fd}< <(
            ZDOTDIR="$ZDOTDIR" script -q /dev/null zsh -i 2>&1 | 
            sed -u 's/\r$//' | 
            sed -u '/^Script started/d' | 
            sed -u '/^Script done/d'
        )
        
        # Function to read from ZSH with timeout
        read_with_timeout() {
            local timeout=$1
            local line
            if read -t "$timeout" -u $zsh_fd line; then
                echo "$line"
                return 0
            else
                return 1
            fi
        }
        
        # Wait for startup to complete (look for prompt)
        local startup_lines=0
        local max_startup_lines=200
        local found_ready=false
        
        while [[ $startup_lines -lt $max_startup_lines ]]; do
            if line=$(read_with_timeout 1); then
                echo "[STARTUP] $line" >&2
                startup_lines=$((startup_lines + 1))
                
                # Look for indicators that startup is complete
                if [[ "$line" =~ (Ready|ready|\$|%|➜|>|#) ]]; then
                    found_ready=true
                    break
                fi
            else
                # No output for 1 second, might be ready
                break
            fi
        done
        
        if [[ "$found_ready" == "false" ]]; then
            echo "STARTUP_TIMEOUT" >&2
            exit 1
        fi
        
        # Send a simple command and wait for response
        echo "echo POST_STARTUP_TEST_COMPLETE" >&$zsh_fd
        
        # Wait for response
        local response_lines=0
        local max_response_lines=10
        local found_complete=false
        
        while [[ $response_lines -lt $max_response_lines ]]; do
            if line=$(read_with_timeout 3); then
                echo "[RESPONSE] $line" >&2
                response_lines=$((response_lines + 1))
                
                if [[ "$line" =~ POST_STARTUP_TEST_COMPLETE ]]; then
                    found_complete=true
                    break
                fi
            else
                echo "RESPONSE_TIMEOUT" >&2
                exit 1
            fi
        done
        
        if [[ "$found_complete" == "true" ]]; then
            echo "POST_STARTUP_SUCCESS"
        else
            echo "POST_STARTUP_FAILURE"
            exit 1
        fi
        
        # Cleanup
        exec {zsh_fd}<&-
EOF
    )
    
    local test_result
    if test_result=$(timeout "$TIMEOUT_POST" bash -c "ZDOTDIR='$ZDOTDIR'; $test_script" 2>>"$TEST_LOG"); then
        if echo "$test_result" | grep -q "POST_STARTUP_SUCCESS"; then
            log_success "Post-startup responsiveness test passed"
            return 0
        else
            log_error "Post-startup responsiveness test failed"
            echo "$test_result" >> "$TEST_LOG"
            return 1
        fi
    else
        log_error "Post-startup responsiveness test timed out"
        return 1
    fi
}

# Test for specific hanging indicators
test_hanging_indicators() {
    log_info "Testing for known hanging indicators..."
    
    local hang_test_output
    if hang_test_output=$(timeout 20 bash -c "
        ZDOTDIR='$ZDOTDIR' zsh -i -c 'echo \"Testing parameters...\"; echo \"WSL_DISTRO_NAME=\${WSL_DISTRO_NAME:-UNSET}\"; exit' 2>&1
    "); then
        # Check for parameter errors that could cause hanging
        local param_errors=0
        
        if echo "$hang_test_output" | grep -q "parameter not set"; then
            log_warning "Found 'parameter not set' errors in output"
            echo "$hang_test_output" | grep "parameter not set" >> "$TEST_LOG"
            param_errors=$((param_errors + 1))
        fi
        
        if echo "$hang_test_output" | grep -q "warp_bootstrapped.*WSL_DISTRO_NAME"; then
            log_error "Found WSL_DISTRO_NAME parameter error (common cause of hanging)"
            param_errors=$((param_errors + 1))
        fi
        
        if echo "$hang_test_output" | grep -q "widgets.*parameter not set"; then
            log_warning "Found widgets parameter error"
            param_errors=$((param_errors + 1))
        fi
        
        if [[ $param_errors -gt 0 ]]; then
            log_error "Found $param_errors parameter-related issues that could cause hanging"
            return 1
        else
            log_success "No hanging indicators detected"
            return 0
        fi
    else
        log_error "Hanging indicator test timed out - likely hanging detected"
        return 1
    fi
}

# Main test function
run_hang_detection_tests() {
    log_info "Starting post-startup hang detection tests..."
    echo "Test started at: $(date)" > "$TEST_LOG"
    
    local test_failures=0
    
    # Test 1: Basic startup completion
    if ! test_startup_completion; then
        test_failures=$((test_failures + 1))
    fi
    
    # Test 2: Post-startup responsiveness
    if ! test_post_startup_responsiveness; then
        test_failures=$((test_failures + 1))
    fi
    
    # Test 3: Known hanging indicators
    if ! test_hanging_indicators; then
        test_failures=$((test_failures + 1))
    fi
    
    echo -e "\n=== TEST SUMMARY ===" | tee -a "$TEST_LOG"
    if [[ $test_failures -eq 0 ]]; then
        log_success "All hang detection tests passed!"
        echo "Test completed at: $(date)" >> "$TEST_LOG"
        return 0
    else
        log_error "Failed $test_failures out of 3 tests"
        echo "Test completed at: $(date)" >> "$TEST_LOG"
        echo -e "\nFull test log available at: $TEST_LOG"
        return 1
    fi
}

# Script execution
main() {
    if [[ $# -gt 0 ]] && [[ "$1" == "--help" ]]; then
        cat << EOF
Usage: $0 [--help]

Enhanced test harness to detect ZSH post-startup hanging issues.

This script performs three types of tests:
1. Startup completion - Verifies ZSH can start and exit cleanly
2. Post-startup responsiveness - Tests shell responsiveness after startup
3. Hanging indicators - Checks for known causes of hanging

Test log will be saved to: $TEST_LOG
EOF
        exit 0
    fi
    
    cd "$ZDOTDIR" || {
        echo "Error: Cannot access ZDOTDIR: $ZDOTDIR"
        exit 1
    }
    
    run_hang_detection_tests
}

main "$@"
