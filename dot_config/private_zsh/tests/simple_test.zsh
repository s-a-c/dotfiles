#!/usr/bin/env zsh

# Source the test framework
source tests/lib/test-framework.zsh

# Define a dummy test function
test_dummy() {
  echo "Inside dummy test function"
  test_start "dummy test"
  test_pass
}

# Run the dummy test
test_suite_start "dummy-suite"
test_dummy
test_suite_end
