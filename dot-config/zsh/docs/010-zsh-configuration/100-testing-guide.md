# Testing Guide

**Test Framework & Best Practices** | **Technical Level: Intermediate-Advanced**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Testing Philosophy](#1-testing-philosophy)
  - [1.1. Core Principle](#11-core-principle)
- [2. The Prime Directive](#2-the-prime-directive)
  - [2.1. Test Execution](#21-test-execution)
  - [2.2. What This Means](#22-what-this-means)
- [3. Test Structure](#3-test-structure)
  - [3.1. Standard Test Template](#31-standard-test-template)
- [4. ✍️ Writing Tests](#4-writing-tests)
  - [4.1. Test File Location](#41-test-file-location)
  - [4.2. Naming Convention](#42-naming-convention)
  - [4.3. Test Categories](#43-test-categories)
- [5. Running Tests](#5-running-tests)
  - [5.1. Run Single Test](#51-run-single-test)
  - [5.2. Run All Tests in Directory](#52-run-all-tests-in-directory)
  - [5.3. Run Complete Test Suite](#53-run-complete-test-suite)
  - [5.4. With Coverage Reporting](#54-with-coverage-reporting)
- [6. Test Coverage](#6-test-coverage)
  - [6.1. Target](#61-target)
  - [6.2. Coverage by Component](#62-coverage-by-component)
  - [6.3. Measuring Coverage](#63-measuring-coverage)
- [7. CI/CD Integration](#7-cicd-integration)
  - [7.1. GitHub Actions Example](#71-github-actions-example)
- [8. ️ Test Utilities](#8-test-utilities)
  - [8.1. Temporary Resources](#81-temporary-resources)
  - [8.2. Custom Assertions](#82-custom-assertions)
- [Related Documentation](#related-documentation)

</details>

---

## 1. 🎯 Testing Philosophy

### 1.1. Core Principle

> 🔴 **THE PRIME DIRECTIVE**: Every test MUST be executable with `zsh -f` (no startup files)

This means:

- ✅ No dependency on `.zshenv`, `.zshrc`
- ✅ No assumptions about user environment
- ✅ Explicit setup of all required state
- ✅ Self-contained execution

**Why?**

- **Speed**: No shell startup overhead (~45s → 0s for test suite)
- **Reliability**: No environmental interference
- **Portability**: Runs anywhere ZSH is installed
- **CI-Friendly**: Perfect for automated testing

---

## 2. 🔴 The Prime Directive

### 2.1. Test Execution

```bash

# Every test MUST pass with this command:

zsh -f /path/to/test.zsh

```

### 2.2. What This Means

```bash

# ❌ WRONG - Depends on .zshrc
#!/usr/bin/env zsh
# This test uses functions from .zshrc

my_configured_function  # Fails with zsh -f!

# ✅ CORRECT - Self-contained
#!/usr/bin/env zsh

set -euo pipefail

# Explicit minimal environment

export PATH="/usr/bin:/bin"

# Source ONLY what's needed

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$REPO_ROOT/.zshrc.d.01/520-my-module.zsh"

# Now test

my_configured_function  # Works!

```

---

## 3. 📝 Test Structure

### 3.1. Standard Test Template

```bash

#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required

# Strict mode

set -euo pipefail

# Minimal environment

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Source ONLY the unit under test

source "$REPO_ROOT/.zshrc.d.01/module-to-test.zsh" || exit 1

# Test framework (self-contained)

typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion}"

    if [[ "$expected" == "$actual" ]]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
        echo "FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

assert_function_exists() {
    local func_name="$1"
    if (( $+functions[$func_name] )); then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
        echo "FAIL: Function '$func_name' not defined"
    fi
}

# ─────────────────────────────────────
# Test Cases
# ─────────────────────────────────────

# Test 1: Function exists

assert_function_exists "my_function"

# Test 2: Function behavior

result=$(my_function "input")
assert_equals "expected output" "$result" "Function output"

# Test 3: Edge cases

result=$(my_function "")
assert_equals "default" "$result" "Empty input handling"

# ─────────────────────────────────────
# Summary
# ─────────────────────────────────────

echo
echo "Tests: $((PASS_COUNT + FAIL_COUNT))"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

# Exit with appropriate code

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

```

---

## 4. ✍️ Writing Tests

### 4.1. Test File Location

```text
tests/
├── unit/                    # Unit tests (single module)
├── integration/             # Integration tests (multiple modules)
└── performance/             # Performance benchmarks

```

### 4.2. Naming Convention

```bash
test-module-name.zsh           # Test for module
test-feature-name.zsh          # Test for feature
test-edge-cases-module.zsh     # Edge case tests

```

### 4.3. Test Categories

#### Unit Tests

Test single module in isolation:

```bash

# tests/unit/test-options.zsh

source "$REPO_ROOT/.zshrc.d.01/400-options.zsh"

# Test specific option was set

assert_equals "1" "$(setopt | grep -c AUTO_CD)" "AUTO_CD enabled"

```

#### Integration Tests

Test multiple modules together:

```bash

# tests/integration/test-completion-integration.zsh

source "$REPO_ROOT/.zshrc.d.01/410-completions.zsh"
source "$REPO_ROOT/.zshrc.d.01/430-navigation-tools.zsh"

# Test they work together
# ...


```

#### Performance Tests

Benchmark operations:

```bash

# tests/performance/test-startup-time.zsh

start=$(($(date +%s%N)/1000000))
source "$REPO_ROOT/.zshrc.d.01/400-options.zsh"
end=$(($(date +%s%N)/1000000))

duration=$((end - start))
assert_less_than 100 "$duration" "Load time under 100ms"

```

---

## 5. 🏃 Running Tests

### 5.1. Run Single Test

```bash
zsh -f tests/unit/test-options.zsh

```

### 5.2. Run All Tests in Directory

```bash
for test in tests/unit/*.zsh; do
    echo "Running: $test"
    zsh -f "$test" || exit 1
done

```

### 5.3. Run Complete Test Suite

```bash

# Run all tests

for test in tests/**/*.zsh; do
    zsh -f "$test" || exit 1
done

```

### 5.4. With Coverage Reporting

```bash

# Enable coverage tracking

export ZSH_TEST_COVERAGE=1

# Run tests

./bin/comprehensive-test.zsh

# View coverage report

cat artifacts/coverage-report.txt

```

---

## 6. 📊 Test Coverage

### 6.1. Target

**🔴 REQUIRED**: 90%+ code coverage

### 6.2. Coverage by Component

| Component | Current Coverage | Target |
|-----------|------------------|--------|
| Core helpers | ~95% | 90%+ |
| Module loading | ~85% | 90%+ |
| Completions | ~75% | 90%+ |
| Navigation | ~80% | 90%+ |

### 6.3. Measuring Coverage

```bash

# Use built-in tools

./bin/test-performance.zsh

# Check specific module

zsh -f tests/unit/test-specific-module.zsh

```

---

## 7. 🔄 CI/CD Integration

### 7.1. GitHub Actions Example

```yaml
name: ZSH Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install ZSH
        run: sudo apt-get install -y zsh

      - name: Run Unit Tests
        run: |
          for test in tests/unit/**/*.zsh; do
            zsh -f "$test" || exit 1
          done

      - name: Run Integration Tests
        run: |
          for test in tests/integration/**/*.zsh; do
            zsh -f "$test" || exit 1
          done

```

---

## 8. 🛠️ Test Utilities

### 8.1. Temporary Resources

```bash

# Create test temp directory

TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT INT TERM

# Use in tests

echo "test content" > "$TEST_TMPDIR/testfile"

```

### 8.2. Custom Assertions

```bash
assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" == *"$needle"* ]]; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
        echo "FAIL: '$haystack' doesn't contain '$needle'"
    fi
}

assert_command_exists() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        ((PASS_COUNT++))
    else
        ((FAIL_COUNT++))
        echo "FAIL: Command '$cmd' not found"
    fi
}

```

---

## 🔗 Related Documentation

- [Development Guide](090-development-guide.md) - Creating features
- [Shell-CLI/020-zsh-testing-standards.md](file:///Users/s-a-c/nc/Documents/notes/obsidian/s-a-c/ai/AI-GUIDELINES/Shell-CLI/020-zsh-testing-standards.md) - Complete testing standards

---

**Navigation:** [← Development Guide](090-development-guide.md) | [Top ↑](#testing-guide) | [Performance Guide →](110-performance-guide.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-30)*
