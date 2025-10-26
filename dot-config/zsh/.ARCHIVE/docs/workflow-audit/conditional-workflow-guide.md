# Conditional Workflow Execution Guide

## Overview

GitHub Actions supports multiple methods to conditionally run workflows based on file changes. This ensures efficient CI/CD by only running relevant tests when specific parts of the codebase change.

## Methods for Conditional Execution

### 1. Path Filters (Recommended)

Use `paths` and `paths-ignore` filters in the workflow trigger configuration.

#### Example: ZSH-specific workflow

```yaml
name: ZSH Kit CI

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
      - '!dot-config/zsh/docs/**'  # Exclude docs
  pull_request:
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
```

#### Example: Multiple path conditions

```yaml
on:
  push:
    paths:
      - 'dot-config/zsh/**'
      - 'scripts/zsh-*.sh'
      - 'tests/zsh/**'
    paths-ignore:
      - '**/*.md'
      - '**/docs/**'
```

### 2. Job-Level Conditions

Use `if` conditions at the job level to check for changes dynamically.

#### Example: Using changed files

```yaml
jobs:
  check-changes:
    runs-on: ubuntu-latest
    outputs:
      zsh-changed: ${{ steps.changes.outputs.zsh }}
      nix-changed: ${{ steps.changes.outputs.nix }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: changes
        with:
          filters: |
            zsh:
              - 'dot-config/zsh/**'
            nix:
              - 'dot-config/nix-darwin/**'

  zsh-tests:
    needs: check-changes
    if: needs.check-changes.outputs.zsh-changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Run ZSH tests
        run: echo "Running ZSH tests"
```

### 3. Matrix Strategy with Path Detection

Run different test suites based on what changed.

```yaml
jobs:
  detect-modules:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
      - id: set-matrix
        run: |
          # Detect which modules have changes
          MODULES=()
          
          if git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep -q "dot-config/zsh/"; then
            MODULES+=("zsh")
          fi
          
          if git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep -q "dot-config/nix-darwin/"; then
            MODULES+=("nix")
          fi
          
          if git diff --name-only ${{ github.event.before }} ${{ github.sha }} | grep -q "dot-config/ai/"; then
            MODULES+=("ai")
          fi
          
          echo "matrix={\"module\":$(printf '%s\n' "${MODULES[@]}" | jq -R . | jq -s .)}" >> $GITHUB_OUTPUT

  test-modules:
    needs: detect-modules
    if: needs.detect-modules.outputs.matrix != '{"module":[]}'
    strategy:
      matrix: ${{ fromJson(needs.detect-modules.outputs.matrix) }}
    runs-on: ubuntu-latest
    steps:
      - name: Test ${{ matrix.module }}
        run: |
          echo "Testing ${{ matrix.module }} module"
```

### 4. Workflow Dispatch with Inputs

Allow manual triggering with specific module selection.

```yaml
on:
  workflow_dispatch:
    inputs:
      module:
        description: 'Module to test'
        required: true
        default: 'all'
        type: choice
        options:
          - all
          - zsh
          - nix
          - ai
      skip-cache:
        description: 'Skip cache'
        required: false
        default: false
        type: boolean
```

## Best Practices

### 1. Combine Path Filters with Always-Run Core Tests

```yaml
name: CI Core
on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  # Always run core tests
  core-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Security scan
        run: ./scripts/security-scan.sh
      
      - name: Lint common files
        run: ./scripts/lint-common.sh

  # Only run if ZSH files changed
  zsh-tests:
    runs-on: ubuntu-latest
    if: |
      github.event_name == 'push' ||
      (github.event_name == 'pull_request' && 
       contains(github.event.pull_request.labels.*.name, 'zsh') ||
       contains(github.event.pull_request.title, '[zsh]'))
    steps:
      - name: Run ZSH tests
        run: ./scripts/test-zsh.sh
```

### 2. Use Negative Path Filters

Exclude non-code changes from triggering workflows:

```yaml
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - '.github/ISSUE_TEMPLATE/**'
      - 'LICENSE'
      - '.gitignore'
```

### 3. Centralized Path Configuration

Create a reusable workflow with path configurations:

```yaml
# .github/workflows/paths-config.yml
name: Path Configuration

on:
  workflow_call:
    outputs:
      zsh-paths:
        description: "Paths for ZSH module"
        value: |
          dot-config/zsh/**
          scripts/zsh-*.sh
          .github/workflows/zsh-*.yml
      nix-paths:
        description: "Paths for Nix module"
        value: |
          dot-config/nix-darwin/**
          *.nix
          .github/workflows/nix-*.yml
```

## Migration Strategy for Current Workflows

### Phase 1: Move and Add Path Filters

1. Move workflows from `dot-config/zsh/.github/workflows/` to `.github/workflows/`
2. Add path filters to each moved workflow:

```yaml
# Example for zsh-test-redesign.yml after moving
name: ZSH - Test Redesign (opt-in)

on:
  push:
    branches:
      - 'feature/zsh-refactor-configuration'
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-test-redesign.yml'
  pull_request:
    branches:
      - 'develop'
      - 'main'
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-test-redesign.yml'
```

### Phase 2: Consolidate Related Workflows

Group related workflows with job conditions:

```yaml
name: Performance CI Suite

on:
  push:
    paths:
      - 'dot-config/zsh/**'
      - 'scripts/perf-*.sh'
  schedule:
    - cron: '0 2 * * *'  # Nightly

jobs:
  perf-quick:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Quick performance check
        run: ./scripts/perf-quick.sh

  perf-comprehensive:
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    steps:
      - name: Comprehensive performance analysis
        run: ./scripts/perf-comprehensive.sh
```

### Phase 3: Add Skip Logic

Allow workflows to be skipped via commit messages:

```yaml
jobs:
  check-skip:
    runs-on: ubuntu-latest
    outputs:
      skip: ${{ steps.check.outputs.skip }}
    steps:
      - id: check
        run: |
          if [[ "${{ github.event.head_commit.message }}" == *"[skip ci]"* ]]; then
            echo "skip=true" >> $GITHUB_OUTPUT
          else
            echo "skip=false" >> $GITHUB_OUTPUT
          fi

  zsh-tests:
    needs: check-skip
    if: needs.check-skip.outputs.skip == 'false'
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: ./test.sh
```

## Monitoring and Optimization

### 1. Track Workflow Usage

Add a job to track which paths trigger workflows:

```yaml
  track-usage:
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Log trigger info
        run: |
          echo "Workflow: ${{ github.workflow }}"
          echo "Trigger: ${{ github.event_name }}"
          echo "Changed files: "
          git diff --name-only ${{ github.event.before }} ${{ github.sha }} || true
```

### 2. Regular Review

- Review workflow run history monthly
- Identify workflows that run unnecessarily
- Refine path filters based on actual usage

## Example: Complete ZSH Workflow with Conditions

```yaml
name: ZSH Kit CI

on:
  push:
    branches: [main, develop, 'feature/zsh-*']
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
      - 'scripts/zsh/**'
  pull_request:
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
  workflow_dispatch:
    inputs:
      force-full-test:
        description: 'Run all tests regardless of changes'
        required: false
        default: false
        type: boolean

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      core-changed: ${{ steps.filter.outputs.core }}
      perf-changed: ${{ steps.filter.outputs.perf }}
      docs-changed: ${{ steps.filter.outputs.docs }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            core:
              - 'dot-config/zsh/core/**'
              - 'dot-config/zsh/lib/**'
            perf:
              - 'dot-config/zsh/tools/bench-*.zsh'
              - 'dot-config/zsh/performance/**'
            docs:
              - 'dot-config/zsh/docs/**'
              - 'dot-config/zsh/**/*.md'

  core-tests:
    needs: detect-changes
    if: |
      needs.detect-changes.outputs.core-changed == 'true' ||
      github.event.inputs.force-full-test == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run core tests
        working-directory: dot-config/zsh
        run: ./test-core.sh

  perf-tests:
    needs: detect-changes
    if: |
      needs.detect-changes.outputs.perf-changed == 'true' ||
      github.event.inputs.force-full-test == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run performance tests
        working-directory: dot-config/zsh
        run: ./test-performance.sh

  build-docs:
    needs: detect-changes
    if: needs.detect-changes.outputs.docs-changed == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build documentation
        run: echo "Building docs..."
```

## Conclusion

Implementing conditional workflows will:
1. Reduce unnecessary CI runs
2. Speed up feedback for developers
3. Lower CI costs
4. Allow more comprehensive tests for specific modules without impacting overall CI time

Start with simple path filters and gradually add more sophisticated conditions based on your team's needs.