# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Essential Commands for Development

### 1.1. Performance Testing and Benchmarking

```bash
# Repository-specific performance capture (preferred)
tools/perf-capture.zsh

# Multi-sample performance capture
tools/perf-capture-multi-simple.zsh -n 5

# Module emission selftest
tools/perf-module-fire-selftest.zsh --json

# ZSH profiling with zprof
echo '.zqs-zprof-enabled' > .zqs-zprof-enabled
ZDOTDIR=$PWD zsh -i -c 'zprof'
rm .zqs-zprof-enabled

# Built-in timing (baseline fallback)
TIMEFMT=$'%U user %S sys %P cpu %*E total'
ZDOTDIR=$PWD time zsh -i -c exit
```

### 1.2. Test Suite Execution

```bash
# Comprehensive test runner
tests/run-all-tests.zsh

# Specific test categories
tests/run-all-tests.zsh --design-only      # Structure and sentinel validation
tests/run-all-tests.zsh --unit-only        # Unit tests
tests/run-all-tests.zsh --performance-only # Performance regression tests
tests/run-all-tests.zsh --security-only    # Async state and integrity tests

# Single test execution (with bats available)
bats tests/design/test-redesign-sentinels.zsh
bats tests/performance/test-segment-regression.zsh

# Syntax validation
zsh -n .zshrc
zsh -n .zshenv
```

### 1.3. Structure Validation and Governance

```bash
# Structure audit and promotion guard
tools/generate-structure-audit.zsh
tools/promotion-guard.zsh

# Badge generation
tools/generate-summary-badges.zsh
tools/generate-governance-badge.zsh

# Path resolution enforcement
tools/enforce-path-resolution.zsh

# Legacy checksum verification
tools/verify-legacy-checksums.zsh
```

### 1.4. Plugin Management (zgenom)

```bash
# Run in isolated shell with repo config
ZDOTDIR=$PWD zsh -i

# Inside that shell:
zgenom status          # Check plugin status
zgenom list            # List loaded plugins
zgenom update          # Update plugins
zgenom reset           # Reset plugin cache
zgenom save            # Save current state
zgenom clean           # Clean unused plugins
```

### 1.5. Development Utilities

```bash
# Clear ZSH caches
tools/clear-zsh-cache.zsh

# Integrity hash verification
tools/integrity-hash-preplugin.zsh

# Health check
tools/health-check.zsh

# Variance evaluation
tools/preplugin-variance-eval.zsh
```

## 2. High-Level Architecture Overview

### 2.1. Redesign Scope and Current Status

The project is transforming a fragmented 40+ file ZSH configuration into a deterministic **modular system**:

- **Current Reality**: 10 pre-plugin + 16 post-plugin modules (evolving)
- **Target Architecture**: 8 pre-plugin + 11 post-plugin modules
- **Performance Target**: ≥20% startup improvement (from 4772ms baseline to ≤3817ms)
- **Project Stage**: Stage 2 complete, Stage 3 in progress

**Note**: Module counts currently exceed the target architecture as the redesign is still stabilizing. See [Governance and Variance Tracking](#55-governance-and-variance-tracking) for current status.

### 2.2. Layered Architecture

**Pre-Plugin Phase** (.zshrc.pre-plugins.d.REDESIGN/):
- Environment preparation and safety
- Lazy loading framework initialization
- Path normalization and deduplication
- SSH agent setup
- Deferred heavy operations

**Post-Plugin Phase** (.zshrc.d.REDESIGN/):
- Security integrity and validation
- Interactive shell options
- Core function definitions
- Plugin integration
- Development environments
- Aliases and keybindings
- Completion system
- UI and prompt configuration
- Performance monitoring
- Async security validation

### 2.3. Key Design Principles

- **Strict Separation of Concerns**: Pre-plugin prepares, post-plugin delivers
- **Lazy Loading**: Heavy operations deferred until after first prompt
- **Async Security Validation**: Background integrity checks
- **Performance Budgets**: Pre-plugin ≤400ms, post-plugin ≤500ms
- **Observable Instrumentation**: Segment timing and badge generation
- **Test-Driven Gates**: Architecture rules enforced via CI

### 2.4. Feature Flags and Toggles

Enable the redesigned modules:
```bash
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1
```

Performance and debugging flags:
```bash
export PERF_SEGMENT_LOG="$ZDOTDIR/logs/perf-segments.log"  # Enable segment logging
export PERF_SEGMENT_TRACE=1                                # Trace segment emission
export DEBUG_ZSH_REDESIGN=1                                # Enable debug output
export ZSH_DEBUG=1                                          # Comprehensive debug mode
```

## 3. Key Directory Structure

### 3.1. Configuration Modules

**.zshrc.pre-plugins.d.REDESIGN/** (10 modules - currently above target):
```
00-path-safety.zsh              # Path normalization and safety
01-segment-lib-bootstrap.zsh    # Early instrumentation
02-guidelines-checksum.zsh      # Policy checksum export
05-fzf-init.zsh                 # FZF initialization stubs
10-lazy-framework.zsh           # Lazy loading dispatcher
15-node-runtime-env.zsh         # Node.js environment stubs
20-macos-defaults-deferred.zsh  # macOS settings (deferred)
25-lazy-integrations.zsh        # Git/direnv/copilot wrappers
30-ssh-agent.zsh                # SSH agent management
40-pre-plugin-reserved.zsh      # Future expansion
```

**.zshrc.d.REDESIGN/** (16 modules - currently above target):
```
00-security-integrity.zsh       # Light integrity checks
05-interactive-options.zsh      # Shell options and behavior
10-core-functions.zsh           # Helper functions and API
20-essential-plugins.zsh        # Plugin integration
30-development-env.zsh          # Development toolchains
40-aliases-keybindings.zsh      # Productivity shortcuts
50-completion-history.zsh       # Completion and history
55-compinit-instrument.zsh      # Completion instrumentation
60-p10k-instrument.zsh          # Prompt instrumentation
60-ui-prompt.zsh                # Prompt and theme
65-vcs-gitstatus-instrument.zsh # VCS status instrumentation
70-performance-monitoring.zsh   # Performance capture
80-security-validation.zsh      # Deep integrity validation
85-post-plugin-boundary.zsh     # Post-plugin marker
90-splash.zsh                   # Optional splash screen
95-prompt-ready.zsh             # Prompt readiness marker
```

### 3.2. Documentation

**docs/redesignv2/** - Authoritative documentation:
- `IMPLEMENTATION.md` - Execution plan and progress tracking
- `ARCHITECTURE.md` - Design principles and patterns
- `REFERENCE.md` - Operational commands and troubleshooting
- `stages/` - Stage-specific documentation
- `artifacts/` - Performance metrics, badges, inventories

### 3.3. Tooling

**tools/** - Development and validation utilities:
- `perf-capture*.zsh` - Performance measurement
- `generate-*-badge.zsh` - Badge generation
- `promote-guard.zsh` - Stage gate validation
- `test-*.zsh` - Testing utilities
- `async-*.zsh` - Async framework tools

**tests/** - Comprehensive test suite:
- `design/` - Structure and sentinel tests
- `unit/` - Component unit tests
- `integration/` - Cross-component tests
- `performance/` - Regression and budget tests
- `security/` - Async state and integrity tests
- `style/` - Code quality and standards

## 4. Important Configuration Flags

### 4.1. Redesign Toggles

```bash
# Enable redesigned module trees
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1

# Feature toggles
export ZSH_NODE_LAZY=1              # Keep Node.js lazy loading active
export ZSH_ENABLE_NVM_PLUGINS=1     # Enable nvm/npm integration
export ZSH_ENABLE_ABBR=0            # Abbreviation plugin (opt-in)
```

### 4.2. Performance and Debugging

```bash
# Performance monitoring
export PERF_SEGMENT_LOG="$ZDOTDIR/logs/perf-current.log"
export PERF_SEGMENT_TRACE=1         # Emit segment tracing
export PERF_PROMPT_HARNESS=1        # Performance harness mode
export PERF_CAPTURE_FAST=1          # Skip heavy plugin initialization

# Debug modes
export ZSH_DEBUG=1                  # Comprehensive debug output
export DEBUG_ZSH_REDESIGN=1         # Redesign-specific debug info
export ZSH_SESSION_ID="custom-id"   # Custom session identifier

# Async control
export ASYNC_MODE="shadow"          # shadow|off|on - async dispatcher mode
export ASYNC_DEBUG_VERBOSE=1        # Verbose async logging
```

### 4.3. CI and Badge Integration

```bash
# Badge and governance control
export PERF_DIFF_FAIL_ON_REGRESSION=1  # Fail on performance regression
export SELFTEST_HARD_FAIL=1            # Hard fail on module emission tests
export PERF_OUTLIER_FACTOR=1.5         # Outlier detection sensitivity
```

## 5. Documentation References

### 5.1. Core Documentation

- **[IMPLEMENTATION.md](docs/redesignv2/IMPLEMENTATION.md)** - Current progress and rolling 7-day plan
- **[ARCHITECTURE.md](docs/redesignv2/ARCHITECTURE.md)** - Design principles and module taxonomy
- **[REFERENCE.md](docs/redesignv2/REFERENCE.md)** - Operational commands and troubleshooting

### 5.2. Stage Documentation

- **[Stage 1: Foundation](docs/redesignv2/stages/stage-1-foundation.md)** - ✅ Complete
- **[Stage 2: Pre-Plugin](docs/redesignv2/stages/stage-2-preplugin.md)** - ✅ Complete
- **[Stage 3: Core](docs/redesignv2/stages/stage-3-core.md)** - 🚧 In Progress

### 5.3. Specialized Documentation

- **[RISK-ASYNC-PLAN.md](docs/redesignv2/RISK-ASYNC-PLAN.md)** - Async enablement strategy
- **Performance Artifacts** - `docs/redesignv2/artifacts/metrics/`
- **Badge Endpoints** - `docs/redesignv2/artifacts/badges/`

### 5.4. Legacy References

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution workflow and stow usage
- **[CRUSH.md](CRUSH.md)** - Legacy build/lint/test commands
- **[README-ZDOTDIR.md](README-ZDOTDIR.md)** - ZDOTDIR structure and stow setup

## 6. Governance and Variance Tracking

### 6.1. Current Module Discrepancy

**Expected**: 8 pre-plugin + 11 post-plugin = 19 modules
**Actual**: 10 pre-plugin + 16 post-plugin = 26 modules

This variance is tracked in the ongoing redesign process. The additional modules include:
- Instrumentation helpers (01-segment-lib-bootstrap.zsh, 02-guidelines-checksum.zsh)
- Performance boundary markers (85-post-plugin-boundary.zsh)
- Instrumentation modules (55-compinit-instrument.zsh, 60-p10k-instrument.zsh, 65-vcs-gitstatus-instrument.zsh)
- Prompt readiness (95-prompt-ready.zsh)

### 6.2. Badge Status

Monitor project health via generated badges:
- **Performance**: Startup time vs baseline
- **Structure**: Module organization and drift
- **Governance**: Aggregated health signals
- **Modules**: Segment emission and prompt markers

### 6.3. Variance State Tracking

The project uses variance-state.json to track performance stability and determine when to escalate from observe → warn → gate enforcement modes.

---

## 7. ZSH Testing Requirements

### 7.1. Policy
- All ZSH configuration testing MUST be performed using bash test harnesses that launch interactive ZSH sessions.
- Test harnesses should validate prompt display, environment variables, and interactive functionality.
- Avoid manual tab switching or interactive debugging - use automated validation instead.

### 7.1.1. Mandatory Harness Standard (.bash-harness-for-zsh-template.bash)

- All ZSH configuration testing MUST use the repository-standard Bash harness:
  `./.bash-harness-for-zsh-template.bash`
- Direct invocations of interactive ZSH in tests (e.g., `zsh -i -c "..."`) are prohibited outside this harness.
- Tests MUST source the harness and use its functions (e.g., `harness::run`, `harness::probe_startup`).
- The CI gate (`tools/enforce-harness-usage.bash`) enforces compliance.

**Example (Bats)**:

```bash
source "./.bash-harness-for-zsh-template.bash"

@test "ZSH startup succeeds" {
  harness::probe_startup
}
```

**Example (Bash)**:

```bash
#!/usr/bin/env bash
source "./.bash-harness-for-zsh-template.bash"
harness::run 'echo PROMPT_TEST_SUCCESS; exit'
harness::assert_output_contains 'PROMPT_TEST_SUCCESS'
```

### 7.2. Test Harness Requirements
- Use bash scripts to launch ZSH with `ZDOTDIR=$PWD` for isolated testing.
- Capture and verify that interactive prompts are displayed correctly.
- Validate expected environment variables are set during startup.
- Test both successful initialization and error conditions.
- Provide clear pass/fail status with diagnostic output.

### 7.3. Test Harness Examples

```bash
# Basic ZSH startup test harness
#!/usr/bin/env bash
test_zsh_startup() {
    local test_output
    test_output=$(timeout 10s bash -c '
        export ZDOTDIR="$PWD"
        echo "Testing ZSH startup..."
        zsh -i -c "echo PROMPT_TEST_SUCCESS; exit"
    ' 2>&1)
    
    if echo "$test_output" | grep -q "PROMPT_TEST_SUCCESS"; then
        echo "✅ ZSH startup successful"
        return 0
    else
        echo "❌ ZSH startup failed"
        echo "Output: $test_output"
        return 1
    fi
}

# Environment validation test
test_zsh_environment() {
    ZDOTDIR="$PWD" zsh -i -c '
        echo "=== Environment Test ==="
        echo "ZDOTDIR: $ZDOTDIR"
        echo "ZSH_ENABLE_PREPLUGIN_REDESIGN: $ZSH_ENABLE_PREPLUGIN_REDESIGN"
        echo "ZSH_ENABLE_POSTPLUGIN_REDESIGN: $ZSH_ENABLE_POSTPLUGIN_REDESIGN"
        echo "USER_INTERFACE_VERSION: $USER_INTERFACE_VERSION"
        echo "Starship available: $(command -v starship >/dev/null && echo yes || echo no)"
        exit
    '
}

# Starship initialization test
test_starship_init() {
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 15s zsh -i -c '
        if [[ -n "$STARSHIP_SHELL" ]]; then
            echo "STARSHIP_INITIALIZED"
        else
            echo "STARSHIP_NOT_INITIALIZED"
        fi
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "STARSHIP_INITIALIZED"; then
        echo "✅ Starship prompt initialized"
        return 0
    else
        echo "⚠️  Starship not initialized or not detected"
        echo "Output: $test_output"
        return 1
    fi
}
```

### 7.4. Operational Checklist
- Use bash test harnesses for all ZSH configuration validation.
- Run tests with proper timeout limits (10-15 seconds) to prevent hangs.
- Capture both stdout and stderr for diagnostic purposes.
- Validate environment variables are set correctly during startup.
- Test Starship initialization by checking `$STARSHIP_SHELL` variable.

### 7.5. CI Harness Enforcement

The mandatory harness standard is enforced through automated CI checks:

- **Self-Test**: `tools/selftest-harness.bash` validates the harness functions correctly
- **Compliance Gate**: `tools/enforce-harness-usage.bash` scans for direct `zsh -i` usage in tests
- **GitHub Actions Integration**: Both scripts run automatically in CI workflows
- **Violation Detection**: CI fails if any test bypasses the harness requirement

**Manual Enforcement Commands**:

```bash
# Test the harness itself
bash tools/selftest-harness.bash

# Check for harness compliance
bash tools/enforce-harness-usage.bash

# Run full harness test suite
bash .bash-harness-for-zsh-template.bash
```

---

## Appendices

### Appendix A: Session Rules and Safe-Run Conventions

When following this guide, adhere to terminal session rules:

1. **Single Session**: Use one terminal session for all operations to maintain context
2. **Process Tracking**: Monitor active processes; avoid spawning unnecessary background jobs
3. **Safe Isolation**: Use `ZDOTDIR=$PWD zsh -i` to test configurations without affecting your live shell
4. **Cleanup**: Run `tools/clear-zsh-cache.zsh` between test runs to ensure clean state

### Appendix B: Troubleshooting Common Issues

**Performance Issues**:
- Clear completions: `rm -rf $ZDOTDIR/.zcompdump*`
- Reset zgenom: `ZDOTDIR=$PWD zsh -i -c 'zgenom reset'`
- Check segment logs: `tail -f $ZDOTDIR/logs/perf-current.log`

**Module Loading Issues**:
- Verify flags: `echo $ZSH_ENABLE_PREPLUGIN_REDESIGN $ZSH_ENABLE_POSTPLUGIN_REDESIGN`
- Check sentinel guards: `tools/test-marker-presence.zsh`
- Run structure audit: `tools/generate-structure-audit.zsh`

**Test Failures**:
- Clear test caches: `rm -rf $ZDOTDIR/logs/test-results`
- Check permissions: `chmod +x tests/**/*.zsh`
- Isolate failing test: `bats path/to/failing/test.zsh`

### Appendix C: CI and Badge Integration

The project integrates with CI workflows for:

- **Performance regression testing** via `ci-perf-segments.yml`
- **Structure validation** via `perf-structure-ci.yml`
- **Badge generation** for performance, governance, and module health
- **Nightly governance reports** with variance tracking

Badge artifacts are stored in `docs/redesignv2/artifacts/badges/` and consumed by GitHub Pages or external services.

**Integration Points**:
- Performance: `tools/perf-capture-multi-simple.zsh --json`
- Governance: `tools/generate-governance-badge.zsh`
- Module Health: `tools/perf-module-fire-selftest.zsh --json`

---

**Repository**: /Users/s-a-c/dotfiles/dot-config/zsh
**Last Updated**: 2025-09-05
**Stage Status**: Stage 2 Complete, Stage 3 In Progress
**Performance Target**: ≥20% improvement (4772ms → ≤3817ms)
