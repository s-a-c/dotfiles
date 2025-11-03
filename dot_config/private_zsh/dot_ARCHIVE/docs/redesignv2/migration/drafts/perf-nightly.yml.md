# Draft: .github/workflows/perf-nightly.yml
#
# Purpose:
# - Scheduled nightly perf capture for the redesign feature branch.
# - Runs the perf harness with `ZSH_USE_REDESIGN=1` and uploads ledger artifacts as GitHub workflow artifacts.
# - This is a draft for review and will be added to the feature branch only when approved.
#
# Notes:
# - The workflow is intentionally conservative: it tolerates missing perf scripts and emits placeholder artifacts so the job never fails purely due to missing runner-side helpers.
# - Artifacts are uploaded but NOT copied into the repository. The job writes to the runner workspace (tools/perf/ledgers/) and uploads that directory as an artifact.
# - The workflow is intended to run only for the feature branch `feature/zsh-refactor-configuration` by default; manual dispatch is supported.
#
# Reviewer guidance:
# - Confirm the perf capture command (here: `./tools/perf-capture.sh`) and output path.
# - Confirm any additional runner packages (jq, zip, etc.) required by the perf scripts.
# - Decide on artifact retention settings in the repository settings if different from the default.

```.config/zsh/.github/workflows/perf-nightly.yml#L1-240
name: Redesign — nightly perf

on:
  schedule:
    - cron: '0 4 * * *'   # Daily at 04:00 UTC
  workflow_dispatch:

jobs:
  nightly-perf:
    name: Nightly perf capture (redesign)
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/feature/zsh-refactor-configuration' || github.event_name == 'workflow_dispatch'
    env:
      ZSH_USE_REDESIGN: '1'
      # Point ZDOTDIR at the repo-local zsh config for deterministic runs
      ZDOTDIR: '${{ github.workspace }}/dot-config/zsh'

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update -y
          # jq is useful for post-processing JSON ledgers; add other deps as needed
          sudo apt-get install -y jq zip || true

      - name: Prepare perf ledger dir
        working-directory: ./dot-config/zsh
        run: |
          mkdir -p ./tools/perf/ledgers
          ls -la ./tools/perf || true

      - name: Run perf harness (capture)
        working-directory: ./dot-config/zsh
        env:
          PERF_LEDGER_DIR: ./tools/perf/ledgers
        run: |
          # Prefer the canonical perf-capture script if present; tolerate absence.
          if [[ -x ./tools/perf-capture.sh ]]; then
            ./tools/perf-capture.sh --output ./tools/perf/ledgers/perf-ledger-$(date -u +%Y%m%dT%H%M%SZ).json || true
          elif [[ -x ./tools/perf-capture-dryrun.zsh ]]; then
            ./tools/perf-capture-dryrun.zsh --output ./tools/perf/ledgers/perf-ledger-$(date -u +%Y%m%dT%H%M%SZ).json || true
          else
            # Emit a placeholder to ensure artifact upload always has content
            echo '{"note":"perf-capture helper missing on runner", "timestamp":"'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"}' > ./tools/perf/ledgers/perf-ledger-$(date -u +%Y%m%dT%H%M%SZ).json
          fi
          # List ledgers for visibility
          ls -la ./tools/perf/ledgers || true

      - name: Run shim audit (optional)
        working-directory: ./dot-config/zsh
        run: |
          # Emit shim audit if bench-shim-audit exists
          if [[ -x ./tools/bench-shim-audit.zsh ]]; then
            ./tools/bench-shim-audit.zsh --output-json ./docs/redesignv2/migration/shim-audit-$(date -u +%Y%m%d).json || true
          else
            echo '{"note":"shim-audit missing"}' > ./docs/redesignv2/migration/shim-audit-$(date -u +%Y%m%d).json
          fi
        continue-on-error: true

      - name: Upload perf ledger artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: perf-ledgers-nightly-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/ledgers/

      - name: Upload shim-audit artifact (if any)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: shim-audit-nightly-${{ github.run_id }}
          path: dot-config/zsh/docs/redesignv2/migration/shim-audit-*.json

      - name: Post-run housekeeping (optional)
        working-directory: ./dot-config/zsh
        run: |
          # Optionally trim local ledger store on runner (keeps runner workspace small)
          # Keep last 14 files (change number as needed)
          ls -1t tools/perf/ledgers/* 2>/dev/null | tail -n +15 | xargs -r rm -f || true
