# ZSH Test Design Guide

## Core Principle: Tests Should Run with `zsh -f`

All tests should be executable with `zsh -f` (no startup files) to ensure:
- **Isolation**: Tests run in a clean, predictable environment
- **Speed**: No startup overhead (~334ms per test eliminated)
- **Reliability**: Failures are due to actual issues, not environment
- **Portability**: Tests work in any environment (CI, local, different users)
- **Clarity**: Explicit dependencies make tests self-documenting

## Test Categories and Requirements

### 1. Unit Tests
**Requirement**: MUST run with `zsh -f`

```zsh
#!/usr/bin/env zsh
# Unit test template
set -euo pipefail

# Minimal environment setup
ZDOTDIR="${ZDOTDIR:-$(dirname "$(dirname "$(realpath "$0")")")}"
TEST_DIR="$(dirname "$(realpath "$0")")"

# Source ONLY what you're testing
source "$ZDOTDIR/modules/specific-module.zsh" || exit 1

# Test the module
# ...
```

### 2. Integration Tests
**Requirement**: SHOULD run with `zsh -f` + minimal setup

```zsh
#!/usr/bin/env zsh
# Integration test template
set -euo pipefail

# Setup test environment
ZDOTDIR="${ZDOTDIR:-$(dirname "$(dirname "$(realpath "$0")")")}"
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-/tmp/zsh-test-$$}"
export ZSH_LOG_DIR="${ZSH_LOG_DIR:-/tmp/zsh-test-logs-$$}"

# Source multiple components being tested together
source "$ZDOTDIR/modules/component1.zsh" || exit 1
source "$ZDOTDIR/modules/component2.zsh" || exit 1

# Test interaction
# ...

# Cleanup
rm -rf "$ZSH_CACHE_DIR" "$ZSH_LOG_DIR"
```

### 3. End-to-End Tests
**Requirement**: MAY require full environment (use sparingly)

```zsh
#!/usr/bin/env zsh
# E2E test - only for testing full shell startup
set -euo pipefail

# These tests specifically test the full environment
# and should be clearly marked as such
echo "E2E Test: Requires full .zshenv"

# Use a subprocess to test full initialization
zsh -c 'source ~/.zshenv; test_something'
```

## Required Test Structure

### 1. Self-Contained Setup
Every test MUST set up its own environment:

```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Standard test setup - NO assumptions about environment
TEST_NAME="$(basename "$0" .zsh)"
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
ZDOTDIR="${ZDOTDIR:-$REPO_ROOT}"

# Create test-specific temp directories if needed
TEST_TEMP="/tmp/zsh-test-${TEST_NAME}-$$"
mkdir -p "$TEST_TEMP"
trap "rm -rf '$TEST_TEMP'" EXIT INT TERM

# Define any functions the test needs
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }
```

### 2. Explicit Dependencies
Tests MUST explicitly source what they need:

```zsh
# BAD - Assumes functions exist
if command_exists git; then  # Where does command_exists come from?
    # ...
fi

# GOOD - Explicitly sources or defines what's needed
source "$ZDOTDIR/modules/core-functions.zsh" || {
    # Or define inline if simple
    command_exists() { command -v "$1" >/dev/null 2>&1; }
}

if command_exists git; then
    # ...
fi
```

### 3. Clear Success/Failure Reporting
Tests MUST report results clearly:

```zsh
# Test result tracking
PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "PASS: $1"
    ((PASS_COUNT++))
}

fail() {
    echo "FAIL: $1"
    ((FAIL_COUNT++))
}

# ... run tests ...

# Final summary
echo "SUMMARY: passes=$PASS_COUNT fails=$FAIL_COUNT"
if [[ $FAIL_COUNT -eq 0 ]]; then
    echo "TEST RESULT: PASS"
    exit 0
else
    echo "TEST RESULT: FAIL"
    exit 1
fi
```

## Anti-Patterns to Avoid

### ❌ Don't Assume Environment Variables

```zsh
# BAD
MODULE_PATH="$ZDOTDIR/modules"  # Assumes ZDOTDIR is set

# GOOD
ZDOTDIR="${ZDOTDIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MODULE_PATH="$ZDOTDIR/modules"
```

### ❌ Don't Rely on User's PATH

```zsh
# BAD
git rev-parse --show-toplevel  # Assumes git is in PATH

# GOOD
if command -v git >/dev/null 2>&1; then
    git rev-parse --show-toplevel
else
    # Fallback without git
    cd "$(dirname "$0")/../.." && pwd
fi
```

### ❌ Don't Use Undefined Functions

```zsh
# BAD
zsh_debug_echo "Starting test"  # Where is this defined?

# GOOD
# Define what you need
zsh_debug_echo() { [[ "${DEBUG:-0}" == "1" ]] && echo "$@" >&2; }
zsh_debug_echo "Starting test"
```

### ❌ Don't Pollute Global Namespace

```zsh
# BAD
result="test"  # Global variable

# GOOD
local result="test"  # Local to function
# Or use namespacing
TEST_RESULT="test"  # Clearly test-related
```

## Test Execution Modes

### Mode 1: Direct Execution (Fastest)
```bash
zsh -f test-name.zsh
```

### Mode 2: With Minimal Environment
```bash
ZDOTDIR=/path/to/config zsh -f test-name.zsh
```

### Mode 3: Test Runner
```bash
./tests/run-tests-direct.sh --unit-only
```

## Migration Strategy for Existing Tests

### Phase 1: Audit
1. Run each test with `zsh -f`
2. Document what breaks
3. Categorize by fix complexity

### Phase 2: Refactor Priority
1. **High**: Unit tests (should be easiest)
2. **Medium**: Integration tests
3. **Low**: E2E tests (may need full environment)

### Phase 3: Progressive Migration
1. Add setup boilerplate to each test
2. Source required modules explicitly
3. Define or import needed functions
4. Test with `zsh -f`
5. Update test to indicate compatibility

### Compatibility Marker
Add to test header:

```zsh
#!/usr/bin/env zsh
# TEST_MODE: zsh-f-compatible
# DEPENDENCIES: modules/core-functions.zsh
```

## Benefits of This Approach

1. **Speed**: Tests run in milliseconds, not seconds
2. **Reliability**: No flaky failures from environment issues
3. **Clarity**: Dependencies are explicit and documented
4. **Maintainability**: Tests are self-contained units
5. **CI-Friendly**: Perfect for automated testing
6. **Debugging**: Issues are easier to isolate

## Example: Refactored Test

### Before (Requires Full Environment)
```zsh
#!/usr/bin/env zsh
# Assumes everything is loaded

if [[ -z "$ZDOTDIR" ]]; then
    echo "ZDOTDIR not set"
    exit 1
fi

source "$ZDOTDIR/modules/core-functions.zsh"

# Test function count
count=$(declare -f | grep -c "^zf::")
if [[ $count -ge 5 ]]; then
    echo "PASS"
else
    echo "FAIL"
fi
```

### After (zsh -f Compatible)
```zsh
#!/usr/bin/env zsh
# TEST_MODE: zsh-f-compatible
# DEPENDENCIES: self-contained
set -euo pipefail

# Setup
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
MODULE_FILE="$REPO_ROOT/modules/core-functions.zsh"

# Test existence
if [[ ! -f "$MODULE_FILE" ]]; then
    echo "SKIP: Module not found: $MODULE_FILE"
    exit 0
fi

# Source and test
source "$MODULE_FILE"

# Count functions
count=$(declare -f 2>/dev/null | grep -c "^zf::" || echo 0)

# Report
if [[ $count -ge 5 ]]; then
    echo "PASS: Function count = $count (minimum: 5)"
    echo "TEST RESULT: PASS"
    exit 0
else
    echo "FAIL: Function count = $count (minimum: 5)"
    echo "TEST RESULT: FAIL"
    exit 1
fi
```

## Conclusion

By designing tests to run with `zsh -f`, we create a robust, fast, and maintainable test suite. This approach:
- Eliminates the 137× .zshenv loading problem
- Makes tests portable across environments
- Forces clear documentation of dependencies
- Enables fast CI/CD pipelines
- Improves debugging experience

The key is to think of each test as a standalone program that happens to test shell configuration, rather than as something that requires the full shell environment to run.