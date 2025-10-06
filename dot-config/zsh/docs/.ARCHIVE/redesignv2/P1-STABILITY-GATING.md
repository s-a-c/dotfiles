# P1 - Stability/Gating Implementation

## 1. Overview

P1 - Stability/Gating implements comprehensive stability and quality assurance measures for the ZSH configuration system. This includes core module hardening, automated testing, and performance regression monitoring.

## 2. Components

### 2.1. Core Module Hardening (P1.1)

**Location**: `.zshrc.pre-plugins.d.REDESIGN/01-error-handling-framework.zsh`, `.zshrc.pre-plugins.d.REDESIGN/02-module-hardening.zsh`

**Features**:
- Robust error handling with severity levels (DEBUG, INFO, WARN, ERROR, CRITICAL, FATAL)
- Module health tracking and monitoring
- Validation framework for functions, commands, environment variables, and directories
- Automated recovery mechanisms
- Performance impact monitoring
- Integration with performance logging system

**Key Functions**:
- `zf_error()` - Central error logging with severity levels
- `zf_module_load_start()` / `zf_module_load_complete()` - Module lifecycle tracking
- `zf_validate_*()` functions - Comprehensive validation framework
- `zf_health_check()` - System health assessment
- `zf_trigger_recovery()` - Automated recovery procedures

### 2.2. Manifest Test Escalation (P1.2)

**Location**: `tools/manifest-test-escalation.zsh`

**Features**:
- Hierarchical test suite organization (critical, essential, performance, integration, compatibility)
- Automatic test discovery and execution
- Parallel test execution with configurable job limits
- Performance regression detection
- Escalation triggers based on failure thresholds
- Comprehensive test reporting and aggregation

**Test Categories**:
- **Critical**: Core functionality that must always work
- **Essential**: Important features with higher failure tolerance
- **Performance**: Startup time and performance validation
- **Integration**: Cross-module compatibility tests
- **Compatibility**: Environment and system compatibility

**Escalation Rules**:
- Critical failures: Escalate immediately (threshold: 1 failure)
- Essential failures: Escalate after 2 failures
- Performance issues: Escalate after 5 failures
- Integration issues: Escalate after 10 failures
- Compatibility issues: Escalate after 20 failures

### 2.3. Performance Regression Monitoring (P1.3)

**Location**: `tools/performance-regression-monitor.zsh`

**Features**:
- Historical performance trend analysis
- Regression detection with configurable thresholds
- Integration with variance-state.json monitoring
- Automated baseline management
- Performance alerting and escalation
- CI/CD integration support

**Thresholds**:
- Regression threshold: 15% performance degradation
- RSD warning threshold: 8%
- RSD critical threshold: 15%
- Load time warning: 1.5s
- Load time critical: 3s

## 3. Integration Points

### 3.1. Pre-Plugin Integration

The error handling framework is loaded early in the startup sequence via `.zshrc.pre-plugins.d.REDESIGN/`:

```bash
# Load order:
# 01-error-handling-framework.zsh  - Core error handling and validation
# 02-module-hardening.zsh          - Function hardening and monitoring
```

### 3.2. Performance Monitoring Integration

All P1 components integrate with the existing performance monitoring system:

- Error events are logged to `$PERF_SEGMENT_LOG` when enabled
- Module load times are tracked and reported
- Performance regressions trigger alerts
- Variance state monitoring provides RSD trend analysis

### 3.3. Test Integration

Test files are organized under `tests/` directory:

```
tests/
├── critical/
│   └── core-module-loading.test.zsh
├── essential/
│   └── error-handling.test.zsh
├── performance/
│   └── startup-time.test.zsh
├── integration/
└── compatibility/
```

## 4. Usage Guide

### 4.1. Running Health Checks

```bash
# Source the error framework (in a separate tab/window)
source .zshrc.pre-plugins.d.REDESIGN/01-error-handling-framework.zsh

# Check overall system health
zf_health_check "all" "true"

# Check specific module
zf_health_check "core-functions" "true"
```

### 4.2. Running Tests

```bash
# Run all tests (in a separate tab/window)
tools/manifest-test-escalation.zsh run

# Run specific category
tools/manifest-test-escalation.zsh run critical

# Run with custom parallelism and timeout
tools/manifest-test-escalation.zsh run --parallel 8 --timeout 60

# Generate test report
tools/manifest-test-escalation.zsh report
```

### 4.3. Performance Monitoring

```bash
# Check system health (in a separate tab/window)
tools/performance-regression-monitor.zsh health

# Collect current metrics and store in history
tools/performance-regression-monitor.zsh monitor

# Detect performance regressions
tools/performance-regression-monitor.zsh detect

# Update performance baseline
tools/performance-regression-monitor.zsh baseline update

# Analyze trends over last 7 days
tools/performance-regression-monitor.zsh trends 7
```

## 5. Configuration

### 5.1. Error Handling Configuration

```bash
# Error logging
ZF_MIN_LOG_LEVEL=2              # WARN and above (default)
ZF_ERROR_LOG_MAX=100            # Maximum log entries to keep

# Performance monitoring integration
ZF_PERF_MONITOR_ERRORS=1        # Enable error event logging
ZF_ERROR_RECOVERY_ENABLED=1     # Enable automated recovery
```

### 5.2. Test Configuration

```bash
# Test execution
TEST_TIMEOUT=30                 # Test timeout in seconds
TEST_PARALLEL=4                 # Parallel job limit
TEST_VERBOSE=0                  # Verbose output (0/1)
TEST_ESCALATION_ENABLED=1       # Enable escalation

# Test directories
TEST_SUITE_DIR="$ZDOTDIR/tests"
TEST_RESULTS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/test-results"
```

### 5.3. Performance Monitoring Configuration

```bash
# Regression thresholds
PERF_REGRESSION_THRESHOLD=15      # 15% regression threshold
PERF_RSD_WARNING_THRESHOLD=0.08   # 8% RSD warning
PERF_RSD_CRITICAL_THRESHOLD=0.15  # 15% RSD critical

# Monitoring
PERF_MONITORING_ENABLED=1         # Enable monitoring
PERF_ALERT_ENABLED=1             # Enable alerts
PERF_BASELINE_AUTO_UPDATE=1      # Auto-update baselines

# History retention
PERF_HISTORY_RETENTION_DAYS=30   # Keep 30 days of history
```

## 6. Artifacts and Output

### 6.1. Error Handling Artifacts

- `/tmp/zf_module_*_health` - Module health tracking files
- Error log buffer in memory (rotated automatically)
- Performance event logs in `$PERF_SEGMENT_LOG`

### 6.2. Test Artifacts

- `docs/redesignv2/artifacts/test-results/*.result.json` - Individual test results
- `docs/redesignv2/artifacts/test-results/test-report-*.json` - Aggregated reports
- `docs/redesignv2/artifacts/test-results/escalations.log` - Escalation events
- `docs/redesignv2/artifacts/test-results/CRITICAL_ALERT` - Critical failure alerts

### 6.3. Performance Monitoring Artifacts

- `docs/redesignv2/artifacts/metrics/performance-baseline.json` - Performance baseline
- `docs/redesignv2/artifacts/metrics/history/perf-metrics-*.json` - Historical data
- `docs/redesignv2/artifacts/metrics/alerts/regression-alert-*.json` - Regression alerts
- `docs/redesignv2/artifacts/metrics/reports/trend-analysis-*.json` - Trend reports

## 7. Maintenance Procedures

### 7.1. Daily Maintenance

1. Check system health: `tools/performance-regression-monitor.zsh health`
2. Collect performance metrics: `tools/performance-regression-monitor.zsh monitor`
3. Review any critical alerts in test results directory
4. Clean up old test artifacts if needed

### 7.2. Weekly Maintenance

1. Run comprehensive test suite: `tools/manifest-test-escalation.zsh run all`
2. Analyze performance trends: `tools/performance-regression-monitor.zsh trends 7`
3. Update performance baseline if stable: `tools/performance-regression-monitor.zsh baseline update`
4. Review and address any degraded modules via health checks

### 7.3. Release Preparation

1. Run full test suite with verbose reporting
2. Ensure all critical and essential tests pass
3. Verify performance metrics are within acceptable ranges
4. Update documentation if new thresholds or procedures are introduced
5. Create performance baseline snapshot for rollback capability

## 8. Troubleshooting

### 8.1. Module Loading Issues

**Symptom**: Module fails to load or shows degraded health
**Resolution**:
1. Check error logs via `zf_health_check`
2. Verify module dependencies are satisfied
3. Check for missing functions or commands via validation framework
4. Review module-specific recovery procedures

### 8.2. Test Failures

**Symptom**: Tests failing or timing out
**Resolution**:
1. Review test result JSON files for specific error details
2. Check escalation logs for patterns
3. Run individual tests with verbose output for debugging
4. Verify test environment and dependencies

### 8.3. Performance Regressions

**Symptom**: Performance alerts or high RSD values
**Resolution**:
1. Review regression alert files for specific metrics affected
2. Check recent changes that might impact performance
3. Run additional performance captures to confirm regression
4. Consider rolling back changes or updating baseline if acceptable

## 9. Integration with CI/CD

### 9.1. Pre-commit Hooks

The test escalation system can be integrated with pre-commit hooks:

```bash
#!/bin/bash
# Run critical tests before commit
tools/manifest-test-escalation.zsh run critical --no-escalation
exit $?
```

### 9.2. CI Pipeline Integration

```yaml
# Example GitHub Actions integration
performance-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Setup ZSH
      run: # ... setup steps
    - name: Run Performance Monitoring
      run: |
        cd dot-config/zsh
        tools/performance-regression-monitor.zsh health
        tools/performance-regression-monitor.zsh monitor
        tools/performance-regression-monitor.zsh detect
    - name: Run Critical Tests
      run: |
        cd dot-config/zsh
        tools/manifest-test-escalation.zsh run critical
```

## 10. Future Enhancements

### 10.1. Planned Improvements

- Integration with external notification systems (Slack, email, etc.)
- Advanced trend analysis with statistical modeling
- Automated rollback capabilities
- Integration with external monitoring platforms
- Enhanced test parallelization and distributed execution

### 10.2. Extensibility Points

- Custom error recovery procedures for specific modules
- Additional test categories and escalation rules
- Custom performance metrics and thresholds
- Integration with external testing frameworks
- Plugin system for custom validation rules

This completes the P1 - Stability/Gating implementation providing comprehensive stability, testing, and monitoring infrastructure for the ZSH configuration system.

## 11. Async Activation Checklist (Stage 3)

The following checklist governs enabling asynchronous facilities (e.g., prompt readiness capture, background initialization) with strict preconditions and staged rollout. The single most important invariant is that compinit is executed exactly once.

### 11.1 Preconditions

- Single compinit precondition (required)
  - Ensure exactly one compinit invocation across the entire startup lifecycle (pre-plugin and post-plugin).
  - Configuration expectations:
    - Plugin manager auto-compinit disabled: `ZGEN_AUTOLOAD_COMPINIT=0`
    - Compinit is invoked from the redesigned completion module only (e.g., `.zshrc.d.REDESIGN/50-completion-history.zsh`), or a single designated module if naming differs.
  - Runtime guard:
    - Track a guard variable around compinit (e.g., `_REDESIGN_COMPINIT_DONE=1`) and early-return on subsequent attempts.
    - Emit a diagnostic once if a duplicate attempt is detected (suppressed in normal interactive sessions).
  - Test coverage:
    - Maintain and run `tests/integration/test-postplugin-compinit-single-run.zsh` to assert a single compinit occurrence.

- Prompt readiness markers (required)
  - PROMPT_READY_COMPLETE must be emitted at most once per shell startup.
  - If an opportunistic post-plugin boundary capture exists, it must be suppressed when a native prompt marker is detected (avoid double emission).
  - Monotonic lifecycle constraint must hold for all captures: `pre_plugin_total_ms ≤ post_plugin_total_ms ≤ prompt_ready_ms`, and all strictly non-zero.

- Segment logging (required)
  - `$PERF_SEGMENT_LOG` must be writable during harness runs.
  - Ensure `SEGMENT` lines are produced for pre, post, and prompt phases, even in headless harness scenarios (adaptive synthesis is allowed for harness-only paths).

- Integrity & security invariants (required)
  - Pre-plugin integrity manifest must pass (generator/test bytes aligned).
  - Async initial-state test suite must be green in the target environment.

### 11.2 Staged Enablement Plan

- Stage A: Observe (non-invasive)
  - Async hooks enabled only for performance harness sessions.
  - Production shells capture markers opportunistically but avoid behavior-altering background work.
  - Gating inputs:
    - Variance mode = observe.
    - N=5 capture per batch, outlier policy active (drop >2× median).
    - Trimmed RSD targets: `pre, post ≤ 0.25` (warn), `≤ 0.40` (gate).

- Stage B: Guard (limited rollout)
  - Enable async for an opt-in cohort (developers or CI-only).
  - Enforce compinit single-run guard; abort or fall back to serial on violation.
  - Gating inputs:
    - Variance mode = guard with 3/3 consecutive stable batches (N=5) at `trimmed RSD ≤ 0.15` for both pre and post.
    - No duplicate PROMPT_READY markers observed.
  - Rollback triggers:
    - RSD exceeds `0.40` for any metric.
    - Compinit duplication or prompt-marker duplication detected.
    - Integrity or security tests regress.

- Stage C: Promote (general availability)
  - Enable async globally once Stage B remains stable for a defined soak period (e.g., 7 days).
  - Keep guards in place; continue collecting variance and integrity signals.

### 11.3 Verification & Tooling

- Variance state and governance badges
  - `docs/redesignv2/artifacts/badges/variance-state.json` must reflect current mode, streak, and RSD metrics (trimmed and raw).
  - `docs/redesignv2/artifacts/badges/governance.json` must show `observe: stable` or `guard: stable` prior to promotion.

- Micro-benchmark signal (non-gating)
  - Maintain `docs/redesignv2/artifacts/metrics/microbench-core.json` for core helper function medians (µs per call).
  - Display a concise range (min–max µs) alongside startup badge to detect drift.

- Tests to run before promotion
  - Integrity: `tests/security/test-preplugin-integrity-hash.zsh`
  - Async initial state: `tests/security/test-async-initial-state.zsh`
  - Compinit single-run: `tests/integration/test-postplugin-compinit-single-run.zsh`
  - Optional: micro-bench smoke test(s) to ensure helper surfaces are loaded.

### 11.4 Operational Guidance

- Logging
  - Use a single progress log for perf sessions (e.g., `perf-single-progress.log`) to track lifecycle and provenance (`markers_observed.prompt_native_any`).
  - Ensure logs are rotated or size-capped to prevent interactive slowdown.

- Configuration toggles (recommended defaults)
  - Production shells: async safe-by-default; background work bounded and idempotent.
  - Harness sessions: explicit env toggles allowed (e.g., `PERF_PROMPT_HARNESS=1`) to force deterministic capture.
  - Prompt approximation fallback disabled for promotion gating; approximation may be used in harness-only paths when native markers are unavailable.

- Rollback
  - Keep a one-line switch to disable async activation and return to serial behavior.
  - Document the switch in the top of the primary async module and in the operations runbook.
