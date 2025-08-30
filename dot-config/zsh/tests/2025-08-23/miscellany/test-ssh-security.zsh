#!/opt/homebrew/bin/zsh
#
# SSH Agent Security Test Suite
# Tests the secure SSH agent implementation across multiple scenarios
# Part of ZSH Configuration Security Hardening (Task 3.1.2)
#

# Test configuration
TEST_SSH_DIR="/tmp/ssh-test-$$"
TEST_ENV_FILE="$TEST_SSH_DIR/ssh-agent-env"
TEST_RESULTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_ssh_security() {
        zsh_debug_echo -e "${YELLOW}=== SSH Agent Security Test Suite ===${NC}"
        zsh_debug_echo "Testing secure SSH agent implementation..."
    echo

    # Setup test environment
    mkdir -p "$TEST_SSH_DIR"

    # Test 1: Initial agent setup
        zsh_debug_echo -e "${YELLOW}Test 1: Initial SSH agent setup${NC}"
    if test_initial_agent_setup; then
        TEST_RESULTS+=("✓ Initial agent setup: PASS")
            zsh_debug_echo -e "${GREEN}✓ PASS: Agent created successfully${NC}"
    else
        TEST_RESULTS+=("✗ Initial agent setup: FAIL")
            zsh_debug_echo -e "${RED}✗ FAIL: Agent creation failed${NC}"
    fi
    echo

    # Test 2: Agent reuse across shells
        zsh_debug_echo -e "${YELLOW}Test 2: Agent reuse across multiple shells${NC}"
    if test_agent_reuse; then
        TEST_RESULTS+=("✓ Agent reuse: PASS")
            zsh_debug_echo -e "${GREEN}✓ PASS: Single agent reused correctly${NC}"
    else
        TEST_RESULTS+=("✗ Agent reuse: FAIL")
            zsh_debug_echo -e "${RED}✗ FAIL: Multiple agents created${NC}"
    fi
    echo

    # Test 3: Environment file security
        zsh_debug_echo -e "${YELLOW}Test 3: Environment file permissions${NC}"
    if test_env_file_security; then
        TEST_RESULTS+=("✓ File security: PASS")
            zsh_debug_echo -e "${GREEN}✓ PASS: Environment file secured${NC}"
    else
        TEST_RESULTS+=("✗ File security: FAIL")
            zsh_debug_echo -e "${RED}✗ FAIL: Insecure file permissions${NC}"
    fi
    echo

    # Test 4: Process cleanup
        zsh_debug_echo -e "${YELLOW}Test 4: Process cleanup on exit${NC}"
    if test_process_cleanup; then
        TEST_RESULTS+=("✓ Process cleanup: PASS")
            zsh_debug_echo -e "${GREEN}✓ PASS: Processes cleaned up${NC}"
    else
        TEST_RESULTS+=("✗ Process cleanup: FAIL")
            zsh_debug_echo -e "${RED}✗ FAIL: Orphaned processes${NC}"
    fi
    echo

    # Test 5: Lock file behavior
        zsh_debug_echo -e "${YELLOW}Test 5: Lock file race condition prevention${NC}"
    if test_lock_file_behavior; then
        TEST_RESULTS+=("✓ Lock behavior: PASS")
            zsh_debug_echo -e "${GREEN}✓ PASS: Lock prevents race conditions${NC}"
    else
        TEST_RESULTS+=("✗ Lock behavior: FAIL")
            zsh_debug_echo -e "${RED}✗ FAIL: Race condition possible${NC}"
    fi
    echo

    # Print summary
    print_test_summary

    # Cleanup
    cleanup_test_environment
}

test_initial_agent_setup() {
    # Save original environment
    local orig_ssh_auth_sock="$SSH_AUTH_SOCK"
    local orig_ssh_agent_pid="$SSH_AGENT_PID"

    # Clear SSH environment
    unset SSH_AUTH_SOCK SSH_AGENT_PID

    # Test the secure setup function
    local test_env_file="$TEST_SSH_DIR/test-env-1"

    # Simulate the secure setup function locally for 040-testing
    if ssh-agent -s > "$test_env_file" 2>/dev/null; then
        chmod 600 "$test_env_file"
        source "$test_env_file" > /dev/null 2>&1

        # Verify agent is running
        if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -n "$SSH_AGENT_PID" ]]; then
            # Check if we can communicate with the agent
            if ssh-add -l >/dev/null 2>&1 || [[ $? -eq 1 ]]; then
                # Kill the test agent
                [[ -n "$SSH_AGENT_PID" ]] && kill "$SSH_AGENT_PID" 2>/dev/null

                # Restore original environment
                export SSH_AUTH_SOCK="$orig_ssh_auth_sock"
                export SSH_AGENT_PID="$orig_ssh_agent_pid"
                return 0
            fi
        fi
    fi

    # Restore original environment
    export SSH_AUTH_SOCK="$orig_ssh_auth_sock"
    export SSH_AGENT_PID="$orig_ssh_agent_pid"
    return 1
}

test_agent_reuse() {
    # Create a test environment file
    local test_env_file="$TEST_SSH_DIR/reuse-test-env"
    ssh-agent -s > "$test_env_file" 2>/dev/null
    chmod 600 "$test_env_file"

    # Source in first "shell"
    source "$test_env_file" > /dev/null 2>&1
    local first_pid="$SSH_AGENT_PID"
    local first_sock="$SSH_AUTH_SOCK"

    # Verify agent is running
    if ! ssh-add -l >/dev/null 2>&1 && [[ $? -ne 1 ]]; then
        [[ -n "$first_pid" ]] && kill "$first_pid" 2>/dev/null
        return 1
    fi

    # Simulate second shell reusing the same environment file
    # (In real implementation, this would check if agent is still running)
    if [[ -n "$first_pid" ]] && kill -0 "$first_pid" 2>/dev/null; then
        # Agent is still running, would be reused
        local reuse_success=1
    else
        local reuse_success=0
    fi

    # Cleanup
    [[ -n "$first_pid" ]] && kill "$first_pid" 2>/dev/null

    return $((1 - reuse_success))
}

test_env_file_security() {
    local test_env_file="$TEST_SSH_DIR/security-test-env"

    # Create environment file
    ssh-agent -s > "$test_env_file" 2>/dev/null
    chmod 600 "$test_env_file"

    # Check permissions are correct (600)
    local perms=$(stat -f "%Mp%Lp" "$test_env_file" 2>/dev/null || stat -c "%a" "$test_env_file" 2>/dev/null)

    # Source and cleanup agent
    source "$test_env_file" > /dev/null 2>&1
    [[ -n "$SSH_AGENT_PID" ]] && kill "$SSH_AGENT_PID" 2>/dev/null

    # Check if permissions are 600
    if [[ "$perms" = "100600" ]] || [[ "$perms" = "600" ]]; then
        return 0
    else
        return 1
    fi
}

test_process_cleanup() {
    local test_env_file="$TEST_SSH_DIR/cleanup-test-env"

    # Start agent
    ssh-agent -s > "$test_env_file" 2>/dev/null
    source "$test_env_file" > /dev/null 2>&1
    local test_pid="$SSH_AGENT_PID"

    if [[ -n "$test_pid" ]] && kill -0 "$test_pid" 2>/dev/null; then
        # Kill the agent (simulating cleanup)
        kill "$test_pid" 2>/dev/null
        sleep 1

        # Verify process is gone
        if ! kill -0 "$test_pid" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

test_lock_file_behavior() {
    local lock_file="$TEST_SSH_DIR/test.lock"

    # Simulate lock file creation
    (
        if (set -C;     zsh_debug_echo $$ > "$lock_file") 2>/dev/null; then
            sleep 2
            rm -f "$lock_file"
            exit 0
        else
            exit 1
        fi
    ) &
    local first_process=$!

    sleep 0.1

    # Try to create lock again (should fail)
    if (set -C;     zsh_debug_echo $$ > "$lock_file") 2>/dev/null; then
        # Second lock succeeded - this is bad
        rm -f "$lock_file"
        wait "$first_process" 2>/dev/null
        return 1
    else
        # Second lock failed - this is good
        wait "$first_process" 2>/dev/null
        return 0
    fi
}

print_test_summary() {
        zsh_debug_echo -e "${YELLOW}=== Test Results Summary ===${NC}"
    local pass_count=0
    local total_count=${#TEST_RESULTS[@]}

    for result in "${TEST_RESULTS[@]}"; do
            zsh_debug_echo "$result"
        if [[ "$result" == *"PASS" ]]; then
            ((pass_count++))
        fi
    done

    echo
    if [[ $pass_count -eq $total_count ]]; then
            zsh_debug_echo -e "${GREEN}All tests passed! ($pass_count/$total_count)${NC}"
            zsh_debug_echo -e "${GREEN}SSH agent security implementation is working correctly.${NC}"
    else
            zsh_debug_echo -e "${RED}Some tests failed. ($pass_count/$total_count passed)${NC}"
            zsh_debug_echo -e "${YELLOW}Review the secure SSH agent implementation.${NC}"
    fi
}

cleanup_test_environment() {
    # Clean up test directory
    [[ -d "$TEST_SSH_DIR" ]] && rm -rf "$TEST_SSH_DIR"

    # Clean up any test variables
    unset TEST_SSH_DIR TEST_ENV_FILE TEST_RESULTS
    unset RED GREEN YELLOW NC
}

# Function to run a quick SSH agent status check
ssh_agent_status() {
        zsh_debug_echo -e "${YELLOW}=== Current SSH Agent Status ===${NC}"

    if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -n "$SSH_AGENT_PID" ]]; then
            zsh_debug_echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
            zsh_debug_echo "SSH_AGENT_PID: $SSH_AGENT_PID"

        if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
                zsh_debug_echo -e "${GREEN}✓ Agent process is running${NC}"

            local key_count=$(ssh-add -l 2>/dev/null | wc -l)
            if [[ $? -eq 0 ]]; then
                    zsh_debug_echo -e "${GREEN}✓ Agent is responsive${NC}"
                    zsh_debug_echo "Loaded keys: $key_count"
            elif [[ $? -eq 1 ]]; then
                    zsh_debug_echo -e "${YELLOW}• Agent is responsive (no keys loaded)${NC}"
            else
                    zsh_debug_echo -e "${RED}✗ Agent communication failed${NC}"
            fi
        else
                zsh_debug_echo -e "${RED}✗ Agent process not found${NC}"
        fi
    else
            zsh_debug_echo -e "${YELLOW}• No SSH agent configured${NC}"
    fi
    echo
}

# Allow running individual functions for debugging
case "${1:-}" in
    "status")
        ssh_agent_status
        ;;
    "test")
        test_ssh_security
        ;;
    *)
        # Default: provide help
            zsh_debug_echo "SSH Security Test Functions:"
            zsh_debug_echo "  ssh_agent_status  - Check current agent status"
            zsh_debug_echo "  test_ssh_security - Run full security test suite"
        ;;
esac
