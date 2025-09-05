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

## 7. Dedicated Warp Tab Requirements

### 7.1. Policy
- All tests and any ad-hoc executions related to the zsh redesign MUST be run in a separate, dedicated Warp tab.
- Use a single, reusable tab titled "zsh-redesign" to preserve isolation, logs, and focus.
- This requirement integrates with our terminal session management standards.

### 7.2. Naming and Setup
- Create a new tab and set its title to "zsh-redesign".
- Keep this tab persistent and reuse it for all zsh redesign runs.
- Optional: Apply a distinct tab color/label if your Warp setup supports it.
- Reference: Warp documentation [https://www.warp.dev/docs](https://www.warp.dev/docs)

### 7.3. Session Management Mapping (Compliance with Terminal Session Rules)
- **Single Session**: Work within a single terminal window when possible. Use the "zsh-redesign" tab as the single dedicated session for redesign tasks; avoid extra windows.
- **New Terminal Condition**: Only create the "zsh-redesign" tab if it does not already exist and creation will not disrupt active processes. Document the reason for creating the tab (e.g., "Initialize dedicated zsh-redesign tab").
- **Persistence**: Keep the "zsh-redesign" tab persistent across runs to minimize clutter and context switching.
- **Reuse Verification**: Before creating a new tab, check for an existing "zsh-redesign" tab and reuse it.
- **Redundancy Check**: Close unused tabs. Confirm no active processes before closing the "zsh-redesign" tab.
- **Process Tracking**: Monitor active processes in the "zsh-redesign" tab. Document session purpose in the tab title if needed (e.g., "zsh-redesign: tests").

### 7.4. Usage Examples (Run ONLY in the "zsh-redesign" tab)

```bash
# Comprehensive test runner
tests/run-all-tests.zsh

# Specific test categories
tests/run-all-tests.zsh --design-only      # Structure and sentinel validation
tests/run-all-tests.zsh --unit-only        # Unit tests
tests/run-all-tests.zsh --performance-only # Performance regression tests
tests/run-all-tests.zsh --security-only    # Async state and integrity tests

# Performance testing and benchmarking
tools/perf-capture.zsh
tools/perf-capture-multi-simple.zsh -n 5
tools/perf-module-fire-selftest.zsh --json

# Structure validation and governance
tools/generate-structure-audit.zsh
tools/promotion-guard.zsh
tools/enforce-path-resolution.zsh

# Development utilities
tools/clear-zsh-cache.zsh
tools/health-check.zsh
tools/preplugin-variance-eval.zsh

# Plugin management (zgenom)
ZDOTDIR=$PWD zsh -i  # Run in isolated shell with repo config

# ZSH profiling with zprof
echo '.zqs-zprof-enabled' > .zqs-zprof-enabled
ZDOTDIR=$PWD zsh -i -c 'zprof'
rm .zqs-zprof-enabled

# Built-in timing (baseline fallback)
TIMEFMT=$'%U user %S sys %P cpu %*E total'
ZDOTDIR=$PWD time zsh -i -c exit
```

### 7.5. Operational Checklist
- Verify the "zsh-redesign" tab exists; create it if absent and safe to do so.
- Ensure no other tabs are performing redesign tests; keep a single dedicated tab.
- Reuse the tab for all redesign test runs.
- Before closing, ensure no active processes and capture logs as needed.
- Run `tools/clear-zsh-cache.zsh` between test runs to ensure clean state.

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
