# Test Coverage Improvement Plan

**Target: 85% → 90%+** | **P2 Issue 4.2 Resolution**

---

## 📋 Table of Contents

<details>
<summary>Expand Table of Contents</summary>

- [1. Executive Summary](#1-executive-summary)
- [2. Current Coverage Analysis](#2-current-coverage-analysis)
  - [2.1. Coverage by Module Type](#21-coverage-by-module-type)
  - [2.2. Gap Analysis](#22-gap-analysis)
- [3. Priority Areas for Improvement](#3-priority-areas-for-improvement)
  - [3.1. Terminal Integration (70% → 90%)](#31-terminal-integration-70--90)
  - [3.2. Platform-Specific Code (60% → 85%)](#32-platform-specific-code-60--85)
  - [3.3. Error Handling Paths (75% → 90%)](#33-error-handling-paths-75--90)
- [4. Implementation Plan](#4-implementation-plan)
  - [4.1. Week 1-2: Terminal Integration Tests](#41-week-1-2-terminal-integration-tests)
  - [4.2. Week 3-4: Platform-Specific Tests](#42-week-3-4-platform-specific-tests)
  - [4.3. Week 5-6: Error Path Tests](#43-week-5-6-error-path-tests)
- [5. Test Structure Guidelines](#5-test-structure-guidelines)
- [6. Success Metrics](#6-success-metrics)
- [Related Documentation](#related-documentation)

</details>

---

## 1. Executive Summary

**Current State**: ~85% test coverage
**Target State**: 90%+ test coverage
**Timeline**: 6 weeks (2-3 hours/week)
**Effort**: ~18-20 hours total

**Primary Gaps**:
1. Terminal integration modules (70% coverage) - **Most critical**
2. Platform-specific code (60% coverage) - **Moderate priority**
3. Error handling paths (75% coverage) - **Lower priority**

**Strategy**: Focus on high-value, low-hanging fruit first (terminal integration), then address platform-specific and error paths.

---

## 2. Current Coverage Analysis

### 2.1. Coverage by Module Type

| Module Category | Current Coverage | Target | Gap |
|-----------------|------------------|--------|-----|
| Core helpers | 95% ✅ | 95% | 0% |
| Module loading | 85% ⚠️ | 90% | +5% |
| **Terminal integration** | **70%** 🔴 | **90%** | **+20%** |
| Navigation | 80% ⚠️ | 90% | +10% |
| **Platform-specific** | **60%** 🔴 | **85%** | **+25%** |
| **Error handling** | **75%** 🔴 | **90%** | **+15%** |
| Completions | 75% 🔴 | 85% | +10% |

### 2.2. Gap Analysis

**Highest Impact Improvements**:

1. **Terminal Integration (70% → 90%)** = +20% points
   - File: `.zshrc.d.01/420-terminal-integration.zsh`
   - Missing: Detection logic for each terminal type
   - Missing: Integration script sourcing validation
   - Missing: Edge cases (unknown terminals, missing vars)

2. **Platform-Specific Code (60% → 85%)** = +25% points
   - File: `.zshrc.Darwin.d/*` (macOS-specific)
   - Missing: macOS-specific feature tests
   - Missing: Cross-platform compatibility validation
   - Missing: Fallback behavior tests

3. **Error Handling (75% → 90%)** = +15% points
   - Files: Various error paths across modules
   - Missing: Failure scenario tests
   - Missing: Graceful degradation validation
   - Missing: Error message verification

**Total potential improvement**: +60% points of coverage
**Needed for 90% target**: ~15-20% points

---

## 3. Priority Areas for Improvement

### 3.1. Terminal Integration (70% → 90%)

**File**: `.zshrc.d.01/420-terminal-integration.zsh`

**Current Gaps**:
- ❌ Warp terminal detection not tested
- ❌ WezTerm integration not tested
- ❌ Ghostty integration not tested
- ❌ Kitty integration not tested
- ❌ iTerm2 integration not tested
- ❌ VSCode terminal integration not tested
- ❌ Unknown terminal fallback not tested

**Required Tests**:

```bash
# tests/unit/terminal-integration/test-warp-detection.zsh
# Test Warp terminal detection and WARP_IS_LOCAL_SHELL_SESSION export

# tests/unit/terminal-integration/test-wezterm-detection.zsh
# Test WezTerm detection and WEZTERM_SHELL_INTEGRATION export

# tests/unit/terminal-integration/test-ghostty-integration.zsh
# Test Ghostty detection, integration script sourcing

# tests/unit/terminal-integration/test-unknown-terminal.zsh
# Test graceful handling of unknown terminals

# tests/integration/terminal-integration/test-all-terminals.zsh
# Integration test covering all terminal types
```

**Estimated Effort**: 8-10 hours

### 3.2. Platform-Specific Code (60% → 85%)

**Files**: `.zshrc.Darwin.d/*` (macOS-specific modules)

**Current Gaps**:
- ❌ macOS-specific PATH modifications not tested
- ❌ Homebrew integration not tested on macOS
- ❌ XDG directory fallbacks not tested
- ❌ Cross-platform compatibility not validated

**Required Tests**:

```bash
# tests/unit/platform/test-macos-paths.zsh
# Test macOS-specific PATH setup

# tests/unit/platform/test-homebrew-integration.zsh
# Test Homebrew detection and configuration

# tests/integration/platform/test-cross-platform.zsh
# Test that core functionality works on both macOS and Linux
```

**Estimated Effort**: 6-8 hours

### 3.3. Error Handling Paths (75% → 90%)

**Files**: Various modules with error handling

**Current Gaps**:
- ❌ Plugin load failure not tested
- ❌ Missing dependency handling not tested
- ❌ File not found scenarios not tested
- ❌ Permission denied scenarios not tested

**Required Tests**:

```bash
# tests/unit/error-handling/test-plugin-load-failure.zsh
# Test graceful handling of plugin load failures

# tests/unit/error-handling/test-missing-dependencies.zsh
# Test behavior when required commands/files are missing

# tests/unit/error-handling/test-permission-errors.zsh
# Test handling of permission-denied scenarios
```

**Estimated Effort**: 4-6 hours

---

## 4. Implementation Plan

### 4.1. Week 1-2: Terminal Integration Tests

**Goal**: Add tests for all supported terminal emulators

**Week 1**:
- ✅ Create `tests/unit/terminal-integration/` directory
- ✅ Write tests for Warp, WezTerm, Ghostty detection
- ✅ Write tests for environment variable exports
- ✅ Validate idempotency guards

**Week 2**:
- ✅ Write tests for Kitty, iTerm2, VSCode integration
- ✅ Write test for unknown terminal fallback
- ✅ Create integration test covering all terminals
- ✅ Validate coverage increase (70% → 85%+)

**Deliverables**:
- 7 new unit test files
- 1 integration test file
- Coverage increase: +15%

### 4.2. Week 3-4: Platform-Specific Tests

**Goal**: Add tests for macOS-specific and cross-platform code

**Week 3**:
- ✅ Create `tests/unit/platform/` directory
- ✅ Write tests for macOS PATH modifications
- ✅ Write tests for Homebrew integration
- ✅ Write tests for XDG directory fallbacks

**Week 4**:
- ✅ Create `tests/integration/platform/` directory
- ✅ Write cross-platform compatibility tests
- ✅ Test fallback behaviors
- ✅ Validate coverage increase (60% → 80%+)

**Deliverables**:
- 4 new unit test files
- 2 integration test files
- Coverage increase: +20%

### 4.3. Week 5-6: Error Path Tests

**Goal**: Add tests for error handling and edge cases

**Week 5**:
- ✅ Create `tests/unit/error-handling/` directory
- ✅ Write tests for plugin load failures
- ✅ Write tests for missing dependencies
- ✅ Write tests for permission errors

**Week 6**:
- ✅ Write tests for other edge cases discovered during work
- ✅ Final validation of 90%+ coverage
- ✅ Documentation updates
- ✅ Celebrate achieving 90%+ coverage 🎉

**Deliverables**:
- 5 new unit test files
- Coverage increase: +10%
- **Total coverage: 90%+**

---

## 5. Test Structure Guidelines

All new tests must follow the `zsh -f` compatibility standard:

```bash
#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required

set -euo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

# Source ONLY the unit being tested
source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh" || exit 1

# Self-contained assertions
typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion}"

    if [[ "$expected" == "$actual" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: $message"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: $message"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
    fi
}

assert_var_set() {
    local var_name="$1"
    local message="${2:-Variable $var_name should be set}"

    if [[ -n "${(P)var_name}" ]]; then
        ((PASS_COUNT++))
        echo "✓ PASS: $message"
    else
        ((FAIL_COUNT++))
        echo "✗ FAIL: $message"
    fi
}

# Test logic here
test_warp_detection() {
    export TERM_PROGRAM="WarpTerminal"
    source "$REPO_ROOT/.zshrc.d.01/420-terminal-integration.zsh"
    assert_var_set "WARP_IS_LOCAL_SHELL_SESSION" "Warp should set WARP_IS_LOCAL_SHELL_SESSION"
    assert_equals "1" "$WARP_IS_LOCAL_SHELL_SESSION" "Warp session flag should be 1"
}

# Run tests
test_warp_detection

# Summary
echo ""
echo "========================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

# Exit with appropriate code
[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1
```

---

## 6. Success Metrics

**Quantitative Goals**:
- ✅ Achieve 90%+ overall coverage
- ✅ Achieve 85%+ coverage in all module categories
- ✅ Zero coverage regressions
- ✅ All new tests pass on first run

**Qualitative Goals**:
- ✅ Tests are self-contained and `zsh -f` compatible
- ✅ Tests have clear, descriptive names
- ✅ Tests include helpful failure messages
- ✅ Tests run quickly (<1s each)

**Validation**:
```bash
# Run all tests and measure coverage
./bin/run-all-tests.sh

# Generate coverage report
./bin/coverage-report.sh

# Verify 90%+ achievement
grep "Total coverage" coverage-report.txt
# Expected: "Total coverage: 90.5%"
```

---

## Related Documentation

- [Testing Guide](100-testing-guide.md) - Complete testing framework documentation
- [Roadmap](900-roadmap.md) - Issue 4.2: Test Coverage Below 90%
- [Development Guide](090-development-guide.md) - How to add new tests

---

**Navigation:** [← Testing Guide](100-testing-guide.md) | [Top ↑](#test-coverage-improvement-plan) | [Roadmap →](900-roadmap.md)

---

*Compliant with AI-GUIDELINES.md (v1.0 2025-10-31)*
*Implementation ready - Begin with Week 1-2 terminal integration tests*
