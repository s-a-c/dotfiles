# Draft: .github/workflows/redesign-flagged.yml
#
# Purpose:
# - Branch-scoped CI workflow to exercise the redesign code paths in-branch.
# - Runs unit + design/integration tests and a light perf smoke when `ZSH_USE_REDESIGN=1`.
# - Intended for review only; this is a draft. No files will be modified until you approve.
#
# Notes for reviewers:
# - The workflow is intended to live at `.github/workflows/redesign-flagged.yml` in the feature branch.
# - It is configured to run on pushes to the feature branch and via manual dispatch.
# - It sets `ZSH_USE_REDESIGN=1` and `ZDOTDIR` to the repo-local zsh config for deterministic test runs.
# - Perf ledgers are written to `dot-config/zsh/tools/perf/ledgers/` in the runner workspace and uploaded as GitHub artifacts.
#
# Draft YAML content (for review):
```.config/zsh/.github/workflows/redesign-flagged.yml#L1-240
name: Redesign (flagged) — Branch CI

# Runs on pushes to the feature branch and when manually dispatched.
on:
  push:
    branches:
      - 'feature/zsh-refactor-configuration'
  workflow_dispatch:
    inputs:
      use_redesign:
        description: 'Run with redesign enabled (true/false)'
        required: true
        default: 'true'

jobs:
  test-redesign:
    name: Test (redesign enabled)
    runs-on: ubuntu-latest
    env:
      # Ensure the redesign path is exercised
      ZSH_USE_REDESIGN: '1'
      # Point ZDOTDIR to the repo-local zsh configuration for deterministic sourcing
      ZDOTDIR: '${{ github.workspace }}/dot-config/zsh'
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup environment (dependencies)
        run: |
          sudo apt-get update -y
          sudo apt-get install -y jq bats

      - name: Show environment info
        run: |
          echo "ZDOTDIR=${ZDOTDIR}"
          echo "ZSH_USE_REDESIGN=${ZSH_USE_REDESIGN}"
          pwd
          ls -la dot-config/zsh || true

      - name: Run unit tests
        working-directory: ./dot-config/zsh
        run: |
          ./tests/run-all-tests.zsh --unit-only

      - name: Run design & integration tests (fast)
        working-directory: ./dot-config/zsh
        run: |
          ./tests/run-all-tests.zsh --design-only --timeout-secs 60

      - name: Shim audit (emit JSON)
        working-directory: ./dot-config/zsh
        run: |
          mkdir -p dot-config/zsh/docs/redesignv2/migration
          ./tools/bench-shim-audit.zsh --output-json dot-config/zsh/docs/redesignv2/migration/shim-audit.json || true

      - name: Perf smoke (capture ledger - best-effort)
        working-directory: ./dot-config/zsh
        env:
          PERF_LEDGER_DIR: ./tools/perf/ledgers
        run: |
          mkdir -p ./tools/perf/ledgers
          # Use existing perf-capture helper if available; tolerate failures.
          if [[ -x ./tools/perf-capture-dryrun.zsh ]]; then
            ./tools/perf-capture-dryrun.zsh --output ./tools/perf/ledgers/perf-ledger-${{ github.run_id }}.json || true
          else
            echo '{"note":"perf-capture script not present or not executable"}' > ./tools/perf/ledgers/perf-ledger-${{ github.run_id }}.json
          fi

      - name: Upload shim-audit.json artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: shim-audit-${{ github.run_id }}
          path: dot-config/zsh/docs/redesignv2/migration/shim-audit.json

      - name: Upload perf ledger artifacts (if any)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: perf-ledgers-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/ledgers/

      - name: Archive test logs
        if: always()
        run: |
          mkdir -p .github/test-logs
          # Collect any test output artifacts or logs created by the test runner
          cp -a dot-config/zsh/logs .github/test-logs 2>/dev/null || true
        continue-on-error: true

      - name: Upload test logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-logs-${{ github.run_id }}
          path: .github/test-logs/
