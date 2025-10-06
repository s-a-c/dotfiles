# Draft: .github/workflows/bundle-ledgers.yml
#
# Purpose:
# - Manual workflow to assemble specified ledger files into a single evidence bundle (zip)
#   suitable for attaching to a PR or archiving as part of the 7-day ledger evidence package.
# - This is a read-only draft for review. It assumes the invoker will provide ledger file
#   paths (relative to the repository) when dispatching the workflow. This design avoids
#   relying on GitHub's artifact APIs to fetch artifacts from arbitrary runs.
#
# Notes for reviewers:
# - The workflow is intentionally manual (`workflow_dispatch`) and requires an input
#   `ledger_paths` containing newline-separated ledger file paths relative to the repo root.
# - The workflow will copy those files (if present) into a temporary bundles directory and
#   create a zip archive `redesign-ledgers-bundle-<run_id>.zip` which it uploads as a workflow artifact.
# - The job tolerates missing paths by emitting warnings; it's conservative and non-destructive.
# - If you prefer automatic artifact retrieval from previous workflow runs, that requires
#   GitHub API calls and authentication; this draft avoids that complexity and favors manual
#   invocation with explicit paths.
#
# Reviewer guidance:
# - Confirm the expected input format (newline-separated ledger paths).
# - Confirm the bundle naming convention and whether additional metadata (stage3-exit-report, badges)
#   should be included automatically when present in the listed paths.
# - Confirm artifact retention policy is acceptable in repository settings.
#
# Draft workflow YAML:
```/dev/null/bundle-ledgers.yml#L1-220
name: Bundle redesign ledgers

on:
  workflow_dispatch:
    inputs:
      ledger_paths:
        description: |
          Newline-separated list of ledger file paths (relative to repo root) to include in the bundle.
          Example:
            dot-config/zsh/tools/perf/ledgers/perf-ledger-20250901.json
            dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit-20250901.json
        required: true
        default: ''

jobs:
  bundle:
    name: Bundle ledgers into zip
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Prepare bundle workspace
        run: |
          mkdir -p dot-config/zsh/tools/perf/bundles
          rm -f dot-config/zsh/tools/perf/bundles/* || true

      - name: Copy specified ledgers into bundle dir
        shell: bash
        run: |
          set -euo pipefail
          echo "Provided ledger paths:"
          printf '%s\n' "${{ github.event.inputs.ledger_paths }}" | sed '/^\s*$/d' | nl -ba -w2 -s': ' || true
          # Copy each provided path into the bundle directory if it exists
          printf '%s\n' "${{ github.event.inputs.ledger_paths }}" | while IFS= read -r p; do
            # Skip empty lines
            if [[ -z "${p// /}" ]]; then
              continue
            fi
            # Normalize possible leading/trailing spaces
            p_trim="$(echo "$p" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [[ -f "$p_trim" ]]; then
              echo " - Including: $p_trim"
              cp -a "$p_trim" dot-config/zsh/tools/perf/bundles/
            else
              echo " - Warning: ledger path not found: $p_trim"
            fi
          done

      - name: Add optional metadata files if present
        run: |
          # Common evidence filenames we might include automatically if present
          meta_files=(
            "dot-config/zsh/docs/redesignv2/artifacts/stage3-exit-report.json"
            "dot-config/zsh/docs/redesignv2/artifacts/badges/perf.json"
            "dot-config/zsh/docs/redesignv2/artifacts/badges/governance.json"
          )
          for mf in "${meta_files[@]}"; do
            if [[ -f "$mf" ]]; then
              echo " - Adding metadata file: $mf"
              cp -a "$mf" dot-config/zsh/tools/perf/bundles/ || true
            fi
          done

      - name: Create zip bundle
        run: |
          set -euo pipefail
          cd dot-config/zsh/tools/perf
          BUNDLE_NAME="redesign-ledgers-bundle-${{ github.run_id }}.zip"
          if [[ -d bundles && $(ls -A bundles || true) ]]; then
            zip -r "$BUNDLE_NAME" bundles || true
            echo "Created bundle: $PWD/$BUNDLE_NAME"
            ls -lh "$BUNDLE_NAME" || true
          else
            echo "No files were copied into bundles/; creating empty placeholder bundle."
            printf '%s\n' '{"note":"empty bundle - no files found","run_id":"'"${{ github.run_id }}"'","timestamp":"'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"}' > bundles/placeholder.json
            zip -r "$BUNDLE_NAME" bundles || true
            echo "Created placeholder bundle: $PWD/$BUNDLE_NAME"
            ls -lh "$BUNDLE_NAME" || true
          fi

      - name: Upload ledger bundle artifact
        uses: actions/upload-artifact@v4
        with:
          name: redesign-ledgers-bundle-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/redesign-ledgers-bundle-${{ github.run_id }}.zip

      - name: Output summary
        run: |
          echo "Bundle job complete. Artifact: redesign-ledgers-bundle-${{ github.run_id }}"
          echo "If you need the bundle attached to a PR, download the artifact from the workflow run and attach to the PR manually."