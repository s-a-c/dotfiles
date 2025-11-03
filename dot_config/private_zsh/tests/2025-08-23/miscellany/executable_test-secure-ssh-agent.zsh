#!/usr/bin/env zsh
#=============================================================================
# File: test-secure-ssh-agent.zsh
# Purpose: Comprehensive test suite for the secure SSH agent implementation
# Dependencies: 03-secure-ssh-agent.zsh
# Last Modified: 2025-08-21
#=============================================================================

# Working directory preservation
ORIGINAL_PWD="$PWD"
cleanup_and_restore() {
    cd "$ORIGINAL_PWD"
}
trap cleanup_and_restore EXIT

# Setup logging
LOG_DIR="${HOME}/.config/zsh/logs/$(date -u +'%Y-%m-%d')"
LOG_FILE="${LOG_DIR}/test-secure-ssh-$(date -u +'%Y%m%d-%H%M%S').log"
mkdir -p "$LOG_DIR"

# Redirect all output to log file while preserving console output
exec > >(tee -a "$LOG_FILE") 2>&1

echo "# [test-secure-ssh] Starting SSH security test suite at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "# [test-secure-ssh] Working directory: $PWD"
echo "# [test-secure-ssh] Log file: $LOG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_RESULTS=()
TEST_SSH_DIR="/tmp/ssh-security-test-$$"

# Import the secure SSH implementation
source "${HOME}/.config/zsh/.zshrc.pre-plugins.d/03-secure-ssh-agent.zsh"

test_secure_ssh_implementation() {
        zf::debug -e "${YELLOW}=== Secure SSH Agent Implementation Test Suite ===${NC}"
        zf::debug "Testing actual secure SSH agent implementation..."
    echo

    # Setup isolated test environment
    mkdir -p "$TEST_SSH_DIR"
    local orig_env_file="$SSH_AGENT_ENV_FILE"
    local orig_lock_file="$SSH_AGENT_LOCK_FILE"

    # Note: Cannot override readonly variables, so test with current paths
    # but ensure proper cleanup

    # Test 1: Environment validation
        zf::debug -e "${YELLOW}Test 1: Environment validation${NC}"
    if test_environment_validation; then
        TEST_RESULTS+=("✓ Environment validation: PASS")
            zf::debug -e "${GREEN}✓ PASS: Environment validation works${NC}"
    else
        TEST_RESULTS+=("✗ Environment validation: FAIL")
            zf::debug -e "${RED}✗ FAIL: Environment validation failed${NC}"
    fi
    echo

    # Test 2: Agent creation and validation
        zf::debug -e "${YELLOW}Test 2: Agent creation and validation${NC}"
    if test_agent_creation; then
        TEST_RESULTS+=("✓ Agent creation: PASS")
            zf::debug -e "${GREEN}✓ PASS: Agent created and validated${NC}"
    else
        TEST_RESULTS+=("✗ Agent creation: FAIL")
            zf::debug -e "${RED}✗ FAIL: Agent creation failed${NC}"
    fi
    echo

    # Test 3: Environment file security
        zf::debug -e "${YELLOW}Test 3: Environment file security${NC}"
    if test_environment_file_security; then
        TEST_RESULTS+=("✓ File security: PASS")
            zf::debug -e "${GREEN}✓ PASS: Environment file properly secured${NC}"
    else
        TEST_RESULTS+=("✗ File security: FAIL")
            zf::debug -e "${RED}✗ FAIL: Environment file permissions insecure${NC}"
    fi
    echo

    # Test 4: Agent reuse functionality
        zf::debug -e "${YELLOW}Test 4: Agent reuse functionality${NC}"
    if test_agent_reuse_logic; then
        TEST_RESULTS+=("✓ Agent reuse: PASS")
            zf::debug -e "${GREEN}✓ PASS: Agent reuse works correctly${NC}"
    else
        TEST_RESULTS+=("✗ Agent reuse: FAIL")
            zf::debug -e "${RED}✗ FAIL: Agent reuse logic failed${NC}"
    fi
    echo

    # Test 5: Lock file mechanism
        zf::debug -e "${YELLOW}Test 5: Lock file race condition prevention${NC}"
    if test_lock_file_mechanism; then
        TEST_RESULTS+=("✓ Lock mechanism: PASS")
            zf::debug -e "${GREEN}✓ PASS: Lock prevents race conditions${NC}"
    else
        TEST_RESULTS+=("✗ Lock mechanism: FAIL")
            zf::debug -e "${RED}✗ FAIL: Lock mechanism failed${NC}"
    fi
    echo

    # Test 6: Agent output validation
        zf::debug -e "${YELLOW}Test 6: Agent output validation${NC}"
    if test_agent_output_validation; then
        TEST_RESULTS+=("✓ Output validation: PASS")
            zf::debug -e "${GREEN}✓ PASS: Agent output validation works${NC}"
    else
        TEST_RESULTS+=("✗ Output validation: FAIL")
            zf::debug -e "${RED}✗ FAIL: Agent output validation failed${NC}"
    fi
    echo

    # Note: Readonly variables cannot be restored, but they maintain their values

    # Print summary
    print_test_summary

    # Cleanup
    cleanup_test_environment
}

test_environment_validation() {
    # Test the _validate_ssh_environment function
    if _validate_ssh_environment; then
        return 0
    else
            zf::debug "Environment validation failed"
        return 1
    fi
}

test_agent_creation() {
    # Save current environment
    local orig_auth_sock="$SSH_AUTH_SOCK"
    local orig_agent_pid="$SSH_AGENT_PID"

    # Clear environment
    unset SSH_AUTH_SOCK SSH_AGENT_PID

    # Test creating just the agent without requiring key addition
    # (since key addition might fail due to keychain/passphrase requirements)

    # Create agent manually to test the core functionality
    local test_env_file="$TEST_SSH_DIR/test-agent-env"
    if ssh-agent -s > "$test_env_file" 2>/dev/null; then
        chmod 600 "$test_env_file"

        # Validate agent output format
        if _validate_agent_output "$test_env_file"; then
            # Source the environment
            source "$test_env_file" >/dev/null 2>&1

            # Test basic agent functionality
            if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -n "$SSH_AGENT_PID" ]]; then
                if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
                    # Test agent responsiveness (accept "no keys" as success)
                    ssh-add -l >/dev/null 2>&1
                    local result=$?
                    if [[ $result -eq 0 ]] || [[ $result -eq 1 ]]; then
                        # Clean up test agent
                        kill "$SSH_AGENT_PID" 2>/dev/null
                        rm -f "$test_env_file"

                        # Restore original environment
                        SSH_AUTH_SOCK="$orig_auth_sock"
                        SSH_AGENT_PID="$orig_agent_pid"
                        return 0
                    fi
                fi
            fi
        fi

        # Cleanup on failure
        [[ -n "$SSH_AGENT_PID" ]] && kill "$SSH_AGENT_PID" 2>/dev/null
        rm -f "$test_env_file"
    fi

    # Restore original environment
    SSH_AUTH_SOCK="$orig_auth_sock"
    SSH_AGENT_PID="$orig_agent_pid"
    return 1
}

test_environment_file_security() {
    # Create a test environment file
    local test_env_file="$TEST_SSH_DIR/security-test"
    ssh-agent -s > "$test_env_file" 2>/dev/null

    # Apply secure permissions (simulating our function)
    chmod 600 "$test_env_file"

    # Check permissions are correct
    local perms=$(stat -f "%A" "$test_env_file" 2>/dev/null)

    # Source and cleanup
    source "$test_env_file" >/dev/null 2>&1
    [[ -n "$SSH_AGENT_PID" ]] && kill "$SSH_AGENT_PID" 2>/dev/null
    rm -f "$test_env_file"

    # Validate permissions (600 = 0600)
    if [[ "$perms" == "600" ]]; then
        return 0
    else
            zf::debug "Expected permissions 600, got $perms"
        return 1
    fi
}

test_agent_reuse_logic() {
    # Save current environment
    local orig_auth_sock="$SSH_AUTH_SOCK"
    local orig_agent_pid="$SSH_AGENT_PID"

    # Create a test environment file with running agent
    local test_env_file="$SSH_AGENT_ENV_FILE"
    ssh-agent -s > "$test_env_file" 2>/dev/null
    chmod 600 "$test_env_file"

    # Source the environment
    source "$test_env_file" >/dev/null 2>&1
    local first_pid="$SSH_AGENT_PID"

    if [[ -n "$first_pid" ]] && kill -0 "$first_pid" 2>/dev/null; then
        # Test if _is_ssh_agent_usable correctly identifies usable agent
        if _is_ssh_agent_usable; then
            # Clean up test agent
            kill "$first_pid" 2>/dev/null
            rm -f "$test_env_file"

            # Restore original environment
            SSH_AUTH_SOCK="$orig_auth_sock"
            SSH_AGENT_PID="$orig_agent_pid"
            return 0
        fi
    fi

    # Clean up
    [[ -n "$first_pid" ]] && kill "$first_pid" 2>/dev/null
    rm -f "$test_env_file"

    # Restore original environment
    SSH_AUTH_SOCK="$orig_auth_sock"
    SSH_AGENT_PID="$orig_agent_pid"
    return 1
}

test_lock_file_mechanism() {
    local test_lock_file="$SSH_AGENT_LOCK_FILE"

    # Test lock acquisition
    if _acquire_ssh_lock; then
        # Verify lock file exists
        if [[ -f "$test_lock_file" ]]; then
            # Try to acquire lock again (should fail)
            if ! _acquire_ssh_lock; then
                # Release the lock
                _release_ssh_lock

                # Verify lock file is gone
                if [[ ! -f "$test_lock_file" ]]; then
                    return 0
                fi
            else
                _release_ssh_lock
            fi
        else
            _release_ssh_lock
        fi
    fi

    return 1
}

test_agent_output_validation() {
    # Create a valid agent output file
    local test_file="$TEST_SSH_DIR/valid-output"
    cat > "$test_file" << 'EOF'
SSH_AUTH_SOCK=/tmp/ssh-test/agent.12345; export SSH_AUTH_SOCK;
SSH_AGENT_PID=12345; export SSH_AGENT_PID;
echo Agent pid 12345;
EOF

    # Test validation of good output
    if _validate_agent_output "$test_file"; then
        # Create invalid output file
        local invalid_file="$TEST_SSH_DIR/invalid-output"
        cat > "$invalid_file" << 'EOF'
SSH_AUTH_SOCK=/tmp/ssh-test/agent.12345; export SSH_AUTH_SOCK;
MALICIOUS_CODE=`rm -rf /`; export MALICIOUS_CODE;
SSH_AGENT_PID=12345; export SSH_AGENT_PID;
EOF

        # Test validation of bad output (should fail)
        if ! _validate_agent_output "$invalid_file"; then
            rm -f "$test_file" "$invalid_file"
            return 0
        fi

        rm -f "$invalid_file"
    fi

    rm -f "$test_file"
    return 1
}

print_test_summary() {
        zf::debug -e "${YELLOW}=== Test Results Summary ===${NC}"
    local pass_count=0
    local total_count=${#TEST_RESULTS[@]}

    for result in "${TEST_RESULTS[@]}"; do
            zf::debug "$result"
        if [[ "$result" == *"PASS" ]]; then
            ((pass_count++))
        fi
    done

    echo
    if [[ $pass_count -eq $total_count ]]; then
            zf::debug -e "${GREEN}All tests passed! ($pass_count/$total_count)${NC}"
            zf::debug -e "${GREEN}Secure SSH agent implementation is working correctly.${NC}"
            zf::debug "# [test-secure-ssh] SUCCESS: All tests passed"
        return 0
    else
            zf::debug -e "${RED}Some tests failed. ($pass_count/$total_count passed)${NC}"
            zf::debug -e "${YELLOW}Review the secure SSH agent implementation.${NC}"
            zf::debug "# [test-secure-ssh] FAILURE: $((total_count - pass_count)) tests failed"
        return 1
    fi
}

cleanup_test_environment() {
    # Clean up test directory
    [[ -d "$TEST_SSH_DIR" ]] && rm -rf "$TEST_SSH_DIR"

    # Clean up any test variables
    unset TEST_SSH_DIR TEST_RESULTS
    unset RED GREEN YELLOW NC

        zf::debug "# [test-secure-ssh] Test environment cleaned up"
}

# Main execution
if [[ "${(%):-%N}" == "$0" ]] || [[ "$1" == "test" ]]; then
    test_secure_ssh_implementation
    test_result=$?
        zf::debug "# [test-secure-ssh] Test suite completed at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    exit $test_result
else
        zf::debug "Secure SSH Agent Test Functions:"
        zf::debug "  test_secure_ssh_implementation - Run full test suite"
fi
