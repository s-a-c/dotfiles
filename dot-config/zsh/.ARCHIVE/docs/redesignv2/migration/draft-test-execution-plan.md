# Test Execution Plan for ZSH Redesign Migration

_Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49_

## Overview

This document outlines the exact test commands to run locally before making any commits or pushes to the ZSH redesign migration. All tests must pass before proceeding with implementation.

**Execution Environment:**
- **Repo Root:** `~/dotfiles/`
- **Project Root:** `$ZDOTDIR = ~/dotfiles/dot-config/zsh/`
- **Working Directory:** Always execute from repo root unless specified

---

## Pre-Test Setup

### Environment Preparation
```bash
# Set required environment variables
export ZDOTDIR="$PWD/dot-config/zsh"
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
export ZSH_LOG_DIR="$ZDOTDIR/logs"
export ZSH_USE_REDESIGN=1

# Create required directories
mkdir -p "$ZSH_CACHE_DIR"
mkdir -p "$ZSH_LOG_DIR"
mkdir -p "$ZDOTDIR/docs/redesignv2/artifacts/metrics"
```

### Verify Prerequisites
```bash
# Check that essential files exist
ls -la "$ZDOTDIR/.zshrc.d.REDESIGN/" | head -5
ls -la "$ZDOTDIR/tools/" | grep -E "(activate|bench|test)" | head -5
ls -la "$ZDOTDIR/tests/" | head -5
```

---

## Test Execution Sequence

### 1. Structure & Design Tests

**Command:**
```bash
cd ~/dotfiles
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --design-only
```

**Expected Output:**
- All design tests pass (✅ PASS)
- Sentinel validation successful
- Idempotency checks pass
- No structural issues detected

**Success Criteria:**
- Exit code: 0
- No test failures
- All redesign modules properly structured

---

### 2. Unit Tests

**Command:**
```bash
cd ~/dotfiles
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --unit-only
```

**Expected Output:**
- Core function tests pass
- Path management tests pass
- Trust anchor tests pass
- TDD tests pass

**Success Criteria:**
- Exit code: 0
- All unit tests pass
- No function collisions detected

**Key Tests to Monitor:**
- `test-path-append-invariant.zsh`
- `test-trust-anchors.zsh`
- `test-fzf-no-compinit.zsh`
- `test-core-functions-manifest.zsh`

---

### 3. Integration Tests

**Command:**
```bash
cd ~/dotfiles
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-integration-tests.sh" --timeout-secs 30 --verbose
```

**Expected Output:**
- Compinit single-run validation
- Post-plugin integration successful
- Prompt-ready emission verified
- No duplicate initialization

**Success Criteria:**
- Exit code: 0
- All integration scenarios pass
- Timing within acceptable limits (< 30 seconds)

**Key Integration Points:**
- `test-compinit-single-run.zsh`
- `test-postplugin-compinit-single-run.zsh`
- `test-prompt-ready-single-emission.zsh`

---

### 4. Performance Smoke Tests

**Commands:**
```bash
cd ~/dotfiles

# Basic startup time test
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tools/perf-capture.zsh" --dry-run --iterations 5

# Microbench baseline (if available)
if [ -f "$ZDOTDIR/tools/capture-baseline-10run.zsh" ]; then
    ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tools/capture-baseline-10run.zsh" --dry-run
fi
```

**Expected Output:**
- Startup time within expected range (< 500ms typical)
- No performance regressions > 15%
- Memory usage stable

**Success Criteria:**
- No performance alerts
- Baseline metrics captured
- Times consistent across runs

---

### 5. Shim Audit

**Command:**
```bash
cd ~/dotfiles
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tools/bench-shim-audit.zsh" --output-json "$ZDOTDIR/docs/redesignv2/artifacts/metrics/shim-audit.json"
```

**Expected Output:**
```json
{
  "timestamp": "2025-01-XX",
  "shim_count": 0,
  "shimmed_commands": [],
  "performance_impact": "none",
  "status": "clean"
}
```

**Success Criteria:**
- `shim_count` should be 0 (or documented exceptions)
- No unexpected shimmed commands
- JSON output valid and complete

---

### 6. Security Validation

**Command:**
```bash
cd ~/dotfiles
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --security-only
```

**Expected Output:**
- Environment sanitization tests pass
- Plugin integrity validation successful
- No security violations detected

**Success Criteria:**
- Exit code: 0
- All security tests pass
- No sensitive data exposed

---

## Expected Test Results Summary

### Passing Test Categories
- ✅ **Design Tests:** All structural validations pass
- ✅ **Unit Tests:** All function-level tests pass  
- ✅ **Integration Tests:** All component interactions pass
- ✅ **Performance Tests:** No regressions, timing acceptable
- ✅ **Shim Audit:** Clean (0 shimmed commands)
- ✅ **Security Tests:** All validation checks pass

### Performance Benchmarks
- **Startup Time:** < 500ms (typical)
- **Memory Usage:** < 50MB RSS (typical)  
- **Module Load Time:** < 100ms total (redesign modules)
- **Shim Count:** 0 (target)

---

## Troubleshooting Guide

### Common Issues & Solutions

**Test Runner Not Found:**
```bash
# Verify test runners exist
ls -la "$ZDOTDIR/tests/run-all-tests.zsh"
ls -la "$ZDOTDIR/tests/run-integration-tests.sh"
```

**Path Issues:**
```bash
# Verify ZDOTDIR is set correctly
echo "ZDOTDIR: $ZDOTDIR"
echo "Should be: $PWD/dot-config/zsh"
```

**Permission Issues:**
```bash
# Make test runners executable
chmod +x "$ZDOTDIR/tests/run-all-tests.zsh"
chmod +x "$ZDOTDIR/tests/run-integration-tests.sh"
chmod +x "$ZDOTDIR/tools/bench-shim-audit.zsh"
```

**Missing Directories:**
```bash
# Create missing directories
mkdir -p "$ZDOTDIR/logs"
mkdir -p "$ZDOTDIR/docs/redesignv2/artifacts/metrics"
```

---

## Test Completion Checklist

Before proceeding with commits, verify:

- [ ] All design tests pass
- [ ] All unit tests pass  
- [ ] All integration tests pass
- [ ] Performance tests complete without regressions
- [ ] Shim audit shows clean result (shim_count = 0)
- [ ] Security validation passes
- [ ] Test artifacts generated in correct locations
- [ ] No test failures or warnings
- [ ] All JSON outputs are valid
- [ ] Performance metrics within acceptable ranges

---

## Post-Test Actions

After all tests pass:

1. **Collect test outputs** for commit message evidence
2. **Review performance metrics** for any concerns
3. **Verify shim audit results** meet requirements  
4. **Check security validation** results
5. **Prepare commit with test evidence** attached

**Test Evidence Location:**
- Logs: `$ZDOTDIR/logs/`
- Metrics: `$ZDOTDIR/docs/redesignv2/artifacts/metrics/`
- Shim Audit: `shim-audit.json`

---

## Next Steps After Tests Pass

1. Present test results for approval
2. Proceed with incremental commits (one feature per commit)
3. Run tests after each commit before pushing
4. Include test evidence in commit messages
5. Only push after explicit approval and passing tests