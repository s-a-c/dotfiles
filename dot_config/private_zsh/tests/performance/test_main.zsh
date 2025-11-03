#!/usr/bin/env zsh

# Mock compdef if it doesn't exist in this non-interactive shell
if ! command -v compdef &> /dev/null; then
  compdef() {
    # This is a mock for testing purposes.
    :
  }
fi

# Source the test framework
source tests/lib/test-framework.zsh

# Source the kilocode memory bank system
source .zshrc.d.01/520-kilocode-020-memory-bank.zsh

# Source the test file
source tests/performance/kilocode-020-memory-bank.test.zsh

# Run the tests
test_suite_start "kilocode-memory-bank"
test_storage
test_indexing
test_version_control
test_search
test_cli
test_performance
test_scalability
test_stress
test_suite_end
