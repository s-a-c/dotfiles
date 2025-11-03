# GitHub Workflow Location Analysis

**Date**: 2025-09-09  
**Purpose**: Review and document the correct placement of GitHub workflow files for CI/CD and QA processes

## Summary

There are workflow files in two locations:
1. **Root directory**: `/Users/s-a-c/dotfiles/.github/workflows/` (correct location for GitHub Actions)
2. **ZSH subdirectory**: `/Users/s-a-c/.config/zsh/.github/workflows/` (not recognized by GitHub)

## Key Finding

**GitHub Actions ONLY recognizes workflow files in the root `.github/workflows/` directory**. Workflows in subdirectories like `dot-config/zsh/.github/workflows/` are not executed by GitHub.

## Current State

### Root `.github/workflows/` (13 workflows - ACTIVE)
These workflows are properly located and will run:

1. **badges-pages.yml** - Badge generation and GitHub Pages deployment
2. **ci-async-guards.yml** - Async guard testing
3. **ci-core.yml** - Core CI pipeline
4. **ci-perf-ledger-nightly.yml** - Nightly performance ledger
5. **ci-perf-segments.yml** - Performance segment testing
6. **ci-performance.yml** - Performance CI
7. **ci-prevent-ledger-commit.yml** - Prevent ledger JSON commits
8. **ci-security.yml** - Security scanning
9. **ci-variance-nightly.yml** - Nightly variance checks
10. **redesign-shim-audit-gate.yml** - Shim audit for redesign (recently moved here)
11. **secret-scan.yml** - Secret scanning
12. **zsh-kit-ci.yml** - ZSH kit testing and performance

### ZSH Subdirectory `dot-config/zsh/.github/workflows/` (8 workflows - INACTIVE)
These workflows are NOT recognized by GitHub and will NOT run:

1. **nightly-metrics.yml** - Nightly metrics collection
2. **perf-nightly.yml** - Nightly performance tests
3. **perf-structure-ci.yml** - Performance structure CI
4. **publish-badges.yml** - Badge publishing
5. **redesign-flagged.yml** - Redesign flag checks
6. **redesign-shim-audit-gate.yml** - Duplicate of root (outdated)
7. **structure-badge.yml** - Structure badge generation
8. **zsh-test-redesign.yml** - ZSH redesign testing

## Issues Identified

1. **Duplicate Workflow**: `redesign-shim-audit-gate.yml` exists in both locations
   - Root version has the fix for `feature/zsh-refactor-configuration`
   - ZSH subdirectory version is outdated

2. **Inactive Workflows**: 7 workflows in the ZSH subdirectory are not running because GitHub doesn't recognize them

3. **Missing CI Coverage**: The inactive workflows suggest missing test coverage for:
   - Nightly metrics
   - Performance structure validation
   - Redesign flag checks
   - Badge publishing

## Conditional Execution Strategy

GitHub Actions supports path-based conditional execution to optimize CI/CD:

1. **Path Filters**: Only run workflows when specific directories change
2. **Job Conditions**: Dynamically check for changes at runtime
3. **Matrix Strategies**: Run different test suites based on what changed

### Example Implementation for ZSH Workflows

```yaml
on:
  push:
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
      - '!dot-config/zsh/docs/**'  # Exclude docs
  pull_request:
    paths:
      - 'dot-config/zsh/**'
      - '.github/workflows/zsh-*.yml'
```

This ensures ZSH-specific workflows only run when ZSH files change, reducing unnecessary CI runs.

## Recommendations

### Immediate Actions

1. **Move all workflows to root directory**:
   ```bash
   # Move unique workflows from zsh subdirectory to root
   mv dot-config/zsh/.github/workflows/nightly-metrics.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/perf-nightly.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/perf-structure-ci.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/publish-badges.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/redesign-flagged.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/structure-badge.yml .github/workflows/
   mv dot-config/zsh/.github/workflows/zsh-test-redesign.yml .github/workflows/
   ```

   After moving, add path filters to each workflow:
   ```yaml
   # Add to each moved workflow's 'on' section
   on:
     push:
       paths:
         - 'dot-config/zsh/**'
         - '.github/workflows/[workflow-name].yml'
   ```

2. **Remove duplicate**: Delete the outdated `redesign-shim-audit-gate.yml` from ZSH subdirectory

3. **Update workflow paths**: Review moved workflows to ensure paths are correct (they may assume different working directories)

### Path Adjustments Needed

Workflows in the ZSH subdirectory may have path assumptions that need updating:
- Working directory defaults
- Script paths
- Artifact paths
- Cache paths

### Consolidation Opportunities

Consider consolidating related workflows:
- `ci-perf-*` workflows could potentially be combined
- Badge-related workflows could be unified
- Nightly workflows could be orchestrated from a single workflow

### Recommended Workflow Organization

After migration, organize workflows by:
1. **Core CI** - Always runs (security, basic tests)
2. **Module-specific** - Runs only when module files change
3. **Nightly/Scheduled** - Comprehensive tests on schedule
4. **Manual dispatch** - On-demand testing with options

Example consolidated structure:
- `.github/workflows/ci-core.yml` - Security, linting, basic tests
- `.github/workflows/ci-zsh.yml` - All ZSH-related tests (with path filters)
- `.github/workflows/ci-nightly.yml` - All nightly jobs combined
- `.github/workflows/ci-performance.yml` - All performance tests (with path filters)

## Other GitHub Files

### Root `.github/` Directory
- **gitleaks.toml** - Secret scanning configuration (correct location)
- **PULL_REQUEST_TEMPLATE.md** - Default PR template (correct location)
- **PULL_REQUEST_TEMPLATE/** - PR template variants (correct location)
  - 000-repo-default.md
  - 010-zsh-project.md
  - config.yml

### ZSH Subdirectory
No other GitHub-related files found in `dot-config/zsh/.github/`

## Conclusion

All workflow files should be moved from `dot-config/zsh/.github/workflows/` to `.github/workflows/` to ensure they are recognized and executed by GitHub Actions. This will restore the intended CI/CD coverage and ensure all quality checks are running as designed.
