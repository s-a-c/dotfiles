# CI Integration Guide - Performance Regression Classifier

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

## Overview

This guide documents how to integrate the enhanced performance regression classifier (`tools/perf-regression-classifier.zsh`) into CI workflows for automated performance monitoring.

## Features

- **Multi-metric monitoring**: Track prompt_ready, pre_plugin_total, post_plugin_total, deferred_total
- **Flexible modes**: Observe (report-only) or Enforce (fail on regression)
- **Baseline management**: Automatic baseline creation and per-metric tracking
- **JSON artifacts**: Machine-readable output for dashboards and trend analysis

## Basic Integration

### GitHub Actions Example

```yaml
name: Performance Regression Check
on:
  pull_request:
  push:
    branches: [main]

jobs:
  perf-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup ZSH
        run: |
          sudo apt-get update
          sudo apt-get install -y zsh
          
      - name: Run Performance Classifier
        id: perf
        run: |
          cd dot-config/zsh
          ./tools/perf-regression-classifier.zsh \
            --runs 5 \
            --metrics prompt_ready,pre_plugin_total,post_plugin_total \
            --mode observe \
            --json-out artifacts/perf-results.json
            
      - name: Upload Performance Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: performance-results
          path: |
            dot-config/zsh/artifacts/perf-results.json
            dot-config/zsh/artifacts/metrics/*.json
```

### Enforce Mode (Fail on Regression)

```yaml
      - name: Run Performance Check (Enforce)
        run: |
          cd dot-config/zsh
          ./tools/perf-regression-classifier.zsh \
            --runs 5 \
            --metrics prompt_ready,pre_plugin_total,post_plugin_total \
            --mode enforce \
            --warn-threshold 10 \
            --fail-threshold 25
```

## Configuration Options

### Command Line Arguments

| Option | Default | Description |
|--------|---------|-------------|
| `--runs N` | 5 | Number of startup samples to capture |
| `--metrics LIST` | prompt_ready | Comma-separated metrics to monitor |
| `--mode MODE` | observe | observe (report-only) or enforce (exit codes) |
| `--warn-threshold PCT` | 10 | Percentage delta to trigger WARN status |
| `--fail-threshold PCT` | 25 | Percentage delta to trigger FAIL status |
| `--baseline-dir PATH` | artifacts/metrics | Directory for baseline JSON files |
| `--json-out FILE` | (none) | Path for JSON summary output |
| `--quiet` | false | Suppress non-essential output |

### Exit Codes

- **0**: OK or any status in observe mode
- **2**: WARN status in enforce mode
- **3**: FAIL status in enforce mode
- **1**: Error or invalid usage

## Baseline Management

### Initial Baseline Creation

On first run without existing baselines, the classifier automatically creates baseline files:

```
artifacts/metrics/
├── prompt_ready-baseline.json
├── pre_plugin_total-baseline.json
├── post_plugin_total-baseline.json
└── deferred_total-baseline.json
```

### Baseline Update Strategy

1. **Automatic**: Remove baseline files to trigger re-baseline
2. **Manual**: Update JSON files with new acceptable values
3. **PR-based**: Use separate baseline directories for branches

Example PR workflow:
```bash
# Use branch-specific baselines
./tools/perf-regression-classifier.zsh \
  --baseline-dir "artifacts/metrics/${GITHUB_HEAD_REF:-main}"
```

## Multi-Metric Analysis

### JSON Output Schema

```json
{
  "overall_status": "WARN",
  "worst_metric": "post_plugin_total_ms",
  "worst_delta_pct": 12.3,
  "warn_threshold_pct": 10,
  "fail_threshold_pct": 25,
  "runs": 5,
  "mode": "observe",
  "metrics": {
    "prompt_ready_ms": {
      "status": "OK",
      "delta_pct": 2.1,
      "mean_ms": 341,
      "median_ms": 340,
      "stddev_ms": 6.2,
      "rsd_pct": 1.8,
      "baseline_mean_ms": 334,
      "values": [335, 340, 342, 345, 343]
    },
    "post_plugin_total_ms": {
      "status": "WARN",
      "delta_pct": 12.3,
      "mean_ms": 208,
      "median_ms": 207,
      "stddev_ms": 8.5,
      "rsd_pct": 4.1,
      "baseline_mean_ms": 185,
      "values": [202, 207, 210, 215, 206]
    }
  },
  "generated_at": "2025-01-10T15:30:00Z",
  "baseline_dir": "artifacts/metrics"
}
```

### Status Aggregation

The overall status is the worst-case of all monitored metrics:
- If any metric is FAIL → overall FAIL
- Else if any metric is WARN → overall WARN  
- Else if all metrics are OK → overall OK
- Special case: BASELINE_CREATED if new baselines were created

## Advanced Integration

### Dependency Export Integration

```yaml
      - name: Export Dependencies
        run: |
          cd dot-config/zsh
          ./tools/deps-export.zsh --format json \
            --output artifacts/dependencies.json
            
      - name: Performance Check with Context
        run: |
          cd dot-config/zsh
          # Add dependency count to commit message if regression
          DEPS=$(jq '.stats.total' artifacts/dependencies.json)
          echo "Total dependencies: $DEPS"
          ./tools/perf-regression-classifier.zsh \
            --metrics prompt_ready,pre_plugin_total,post_plugin_total
```

### Slack/Discord Notifications

```yaml
      - name: Parse Performance Results
        id: parse
        if: always()
        run: |
          cd dot-config/zsh
          STATUS=$(jq -r .overall_status artifacts/perf-results.json)
          WORST=$(jq -r .worst_metric artifacts/perf-results.json)
          DELTA=$(jq -r .worst_delta_pct artifacts/perf-results.json)
          echo "status=$STATUS" >> $GITHUB_OUTPUT
          echo "summary=Status: $STATUS, Worst: $WORST ($DELTA%)" >> $GITHUB_OUTPUT
          
      - name: Notify Slack
        if: steps.parse.outputs.status != 'OK'
        uses: slack-action@v1
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK }}
          message: |
            Performance regression detected!
            ${{ steps.parse.outputs.summary }}
```

### Badge Generation

```yaml
      - name: Generate Performance Badge
        run: |
          cd dot-config/zsh
          STATUS=$(jq -r .overall_status artifacts/perf-results.json)
          COLOR="green"
          [[ "$STATUS" == "WARN" ]] && COLOR="yellow"
          [[ "$STATUS" == "FAIL" ]] && COLOR="red"
          
          # Generate badge JSON
          cat > docs/badges/perf.json <<EOF
          {
            "schemaVersion": 1,
            "label": "performance",
            "message": "$STATUS",
            "color": "$COLOR"
          }
          EOF
```

## Troubleshooting

### Common Issues

1. **Missing segments**: Ensure all required modules are sourced in capture runner
2. **High variance**: Increase `--runs` or investigate environment noise
3. **Baseline drift**: Consider time-based baseline decay or rolling averages

### Debug Mode

Enable debug output:
```bash
PERF_CLASSIFIER_DEBUG=1 ./tools/perf-regression-classifier.zsh --runs 3
```

### Manual Segment Verification

Check if segments are being generated:
```bash
PERF_SEGMENT_LOG=/tmp/test.log zsh -f -c '
  source dot-config/zsh/.zshrc.pre-plugins.d.REDESIGN/00-path-safety.zsh
  source dot-config/zsh/.zshrc.pre-plugins.d.REDESIGN/40-pre-plugin-reserved.zsh
  cat $PERF_SEGMENT_LOG
'
```

## Best Practices

1. **Consistent Environment**: Use same OS/hardware for comparisons
2. **Adequate Samples**: Use at least 5 runs (more for high-variance environments)
3. **Baseline Hygiene**: Review baselines quarterly or after major changes
4. **Gradual Enforcement**: Start with observe mode, then tighten thresholds
5. **Metric Selection**: Monitor metrics relevant to your performance goals

## Migration from v1

The enhanced classifier is backward compatible with v1 usage:

```bash
# Old v1 style (still works)
./perf-regression-classifier.zsh \
  --baseline artifacts/metrics/perf-baseline.json \
  --metric prompt_ready_ms

# New v2 style (recommended)  
./perf-regression-classifier.zsh \
  --metrics prompt_ready,post_plugin_total \
  --baseline-dir artifacts/metrics
```

---
 
For additional help, run: `./tools/perf-regression-classifier.zsh --help`

## Git Flow + CI Sync Checklist

This checklist aligns CI behavior with a Git Flow model (feature → develop) while keeping the repository default branch on `main` for predictable workflow dispatch and protections.

- Branching model
  - Feature branches are created from `develop` and PR’d back to `develop`.
  - Keep the remote default branch as `main` (simplifies dispatch and repo UX).

- Sync ALL workflow files to both `main` and `develop`
  - Create two small PRs that only modify `.github/**`:
    - “Sync workflows to main” (enables manual dispatch because default=main)
    - “Sync workflows to develop” (ensures PRs to develop run updated workflows)
  - Use a scoped restore so only workflow files change:
    - `git restore --source feature/zsh-refactor-configuration --staged --worktree .github`

- Expand triggers to include develop
  - In key workflows (e.g., publisher and perf-classifier), include `develop`:
    ```yaml
    on:
      push:
        branches: [ main, master, develop ]
      pull_request:
        branches: [ main, master, develop ]
      workflow_dispatch: {}
    ```
  - Keep auto-commit and README post-publish steps gated to `main/master`:
    - Example: `if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'`

- Manual dispatch usage
  - Dispatch uses workflow definitions from the repository’s default branch (`main`), but runs against any ref:
    ```bash
    gh workflow run zsh-badges-and-metrics.yml --ref feature/zsh-refactor-configuration
    gh run list --workflow zsh-badges-and-metrics.yml --limit 5
    gh run watch --workflow zsh-badges-and-metrics.yml
    ```

- Publisher guardrails (already implemented)
  - Integration check: `summary-goal.json` must exist whenever `goal-state.json` exists (fail if missing).
  - Red severity guardrail: fail when `summary-goal.json` color is `red` or `isError: true`.

- Validation steps after sync
  - On PRs targeting `develop`:
    - Verify both badges are produced:
      - `badges/goal-state.json`
      - `badges/summary-goal.json`
    - Confirm the integration check passes and severity guardrail behaves correctly.
    - Ensure logs are clean (capture-runner noise suppressed).
    - Run the suffix test locally if needed:
      - `zsh dot-config/zsh/tests/performance/badges/test-summary-goal-suffix.zsh`
  - On merges to `main`:
    - Confirm README endpoint placeholders auto-resolve.
    - Confirm gh-pages publishes indexes and badges as expected.

- Notes and safeguards
  - Do not switch the repository default branch to `develop`; instead:
    - Keep `main` as default for dispatch consistency.
    - Maintain consistent workflows on both `main` and `develop` via `.github` sync.
  - Consider concurrency keys to reduce duplicate runs from `push` and `pull_request` on the same commit.
  - If you want to restrict gh-pages publishes to `main`, wrap publish steps in a branch guard.
