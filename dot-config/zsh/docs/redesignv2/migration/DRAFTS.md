# Redesign Migration Drafts — module, tools, and CI workflow drafts
#
# Location: dotfiles/dot-config/zsh/docs/redesignv2/migration/DRAFTS.md
# Purpose: Drafts of module scripts, tools, and GitHub Actions workflow YAMLs
# for review before any edits are performed in the repository.
#
# Owner: s-a-c
# Branch target (for eventual commits): feature/zsh-refactor-configuration
#
# NOTE: These are *drafts only*. No files will be modified until you approve
# each draft and give explicit instruction to implement/push them.
#
# ---------------------------------------------------------------------------
# 1) Draft module: `.zshrc.d.REDESIGN/70-shim-removal.zsh`
#
# Intent:
# - Provide a runtime-only shim-disabling guard that prevents legacy shim
#   fragment loading during opt-in redesign sessions (ZSH_USE_REDESIGN=1).
# - Non-destructive: does not rename/delete files on disk. Instead it prevents
#   legacy shims from being sourced at runtime and exposes inspection helpers.
# - Exported helpers:
#   - `zred::shim::list`     — print shim candidates and reasoning
#   - `zred::shim::disable`  — apply runtime disable for known shim loaders
#   - `zred::shim::enable`   — reverse runtime disable in current shell session
#
# Safety: idempotent, guarded behind `ZSH_USE_REDESIGN`. No on-disk changes.
#
# Draft content (plain script):
#
# ------------------------ begin 70-shim-removal.zsh --------------------------
#!/usr/bin/env zsh
# .zshrc.d.REDESIGN/70-shim-removal.zsh
# Runtime shim disable guard (F-A5)
#
# Guard: only active when ZSH_USE_REDESIGN=1
if [[ "${ZSH_USE_REDESIGN:-0}" != "1" ]]; then
  return 0
fi
# Idempotent sentinel
if [[ -n "${_ZRED_SHIM_REMOVAL_LOADED:-}" ]]; then
  return 0
fi
_ZRED_SHIM_REMOVAL_LOADED=1

# Internal storage
typeset -A _zred_shim_state
_zred_shim_state[disabled]=0

# Known legacy shim loader filenames or loader function names.
# This list is conservative — add more entries only after review.
_zred_shim_candidates=(
  ".zshrc.d/shims"                  # generic shim dir (example)
  ".zshrc.d/legacy-shim.zsh"        # legacy single-file shim example
  "load_legacy_shims"               # legacy loader function name
)

# Public: list shim candidates and current runtime status
zred::shim::list() {
  printf '%s\n' "Redesign shim candidates (runtime view):"
  for candidate in "${_zred_shim_candidates[@]}"; do
    if [[ -f "${ZDOTDIR}/${candidate}" || -f "${ZDOTDIR}/${candidate}.zsh" ]]; then
      status="file-present"
    elif whence -w "${candidate}" >/dev/null 2>&1; then
      status="loader-function"
    else
      status="missing"
    fi
    printf ' - %s (%s)\n' "${candidate}" "${status}"
  done
}

# Internal: record original hook states so we can restore
_zred_shim_original_precmd=${precmd_functions[*]:-}
_zred_shim_original_prompt=${PROMPT:-}

# Public: apply runtime disable (no on-disk changes)
zred::shim::disable() {
  # Idempotent
  if (( _zred_shim_state[disabled] == 1 )); then
    echo "zred::shim::disable: already disabled in this session"
    return 0
  fi

  # Example mechanism: prevent legacy loader functions from running by
  # overriding them with harmless passthroughs that log when invoked.
  for candidate in "${_zred_shim_candidates[@]}"; do
    # If the loader is a function, shadow it
    if whence -w "${candidate}" >/dev/null 2>&1; then
      eval "function ${candidate}() { zsh_debug_echo \"# [redesign] prevented legacy loader: ${candidate}\"; return 0; }"
    fi
    # If the candidate is a file fragment that could be sourced by a generic loader,
    # set a sentinel variable to indicate it should be skipped by any guarded loaders.
    sentinel_var="_ZRED_SKIP_$(echo "${candidate}" | tr '/.-' '_')"
    export "${(kv)sentinel_var}"=1 2>/dev/null || true
  done

  # Example: remove potential shim entries from precmd_functions if present
  if (( ${#precmd_functions[@]} )); then
    local -a filtered
    for f in "${precmd_functions[@]}"; do
      if [[ "${_zred_shim_candidates[(R)${f}]}" != "" ]]; then
        zsh_debug_echo "# [redesign] removing shim precmd function: ${f}"
        continue
      fi
      filtered+=("$f")
    done
    precmd_functions=("${filtered[@]}")
  fi

  _zred_shim_state[disabled]=1
  echo "zred::shim::disable: runtime shim disabling applied (no on-disk changes)"
}

# Public: enable back to original state (session-only)
zred::shim::enable() {
  if (( _zred_shim_state[disabled] == 0 )); then
    echo "zred::shim::enable: not disabled in this session"
    return 0
  fi

  # Restore any original loader functions by unsetting the overrides
  for candidate in "${_zred_shim_candidates[@]}"; do
    if whence -w "${candidate}" >/dev/null 2>&1; then
      unset -f "${candidate}" 2>/dev/null || true
    fi
    sentinel_var="_ZRED_SKIP_$(echo "${candidate}" | tr '/.-' '_')"
    unset "${sentinel_var}" 2>/dev/null || true
  done

  # Attempt to restore precmd_functions from the saved snapshot (best-effort)
  if [[ -n "${_zred_shim_original_precmd:-}" ]]; then
    precmd_functions=("${(@s: :)_zred_shim_original_precmd}")
  fi

  _zred_shim_state[disabled]=0
  echo "zred::shim::enable: runtime shim disabling reverted in this session"
}

# Export minimal usage helper
zred::shim::help() {
  cat <<'EOF'
zred::shim::list      — list shim candidates and runtime status
zred::shim::disable   — disable shim loading at runtime (non-destructive)
zred::shim::enable    — re-enable shim loading in current session
EOF
}
# ------------------------- end 70-shim-removal.zsh ---------------------------


# ---------------------------------------------------------------------------
# 2) Draft tool: `tools/deactivate-redesign.sh`
#
# Intent:
# - Exact inverse of `tools/activate-redesign.sh` as documented.
# - Remove injected snippet from the user's `~/.zshenv` (`ZSHENV_PATH`), restore backup if one was created.
# - Provide `--dry-run`, `--backup`, `--restore`, `--status` operations for parity with activate script.
#
# Draft (shell script excerpt):
#
# ------------------------- begin deactivate-redesign.sh ---------------------
#!/usr/bin/env zsh
# tools/deactivate-redesign.sh
# Inverse of activate-redesign.sh — read-only draft for review.
set -euo pipefail
ZSHENV_PATH="${ZDOTDIR:-$HOME}/.zshenv"
BACKUP_DIR="${HOME}/.local/share/redesign-backups"
REDESIGN_MARKER="# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>"
DRY_RUN=0

print_help() {
  cat <<EOF
Usage: $0 [--dry-run] --disable | --backup | --restore | --status

Commands:
  --disable    Remove redesign injection snippet from your zshenv (restore to backup if available)
  --backup     Create a backup copy of current zshenv into ${BACKUP_DIR}
  --restore    Restore most recent backup for zshenv
  --status     Show whether redesign snippet exists in ${ZSHENV_PATH}
  --dry-run    Print actions without making changes
EOF
}

# Minimal argument parsing
if (( $# == 0 )); then
  print_help; exit 1
fi

# Simple implementations: for review only
# --disable: remove snippet marker block if present (awk approach used in activate helper)
# --backup: copy zshenv to backup dir with timestamp
# --restore: restore latest backup
# --status: grep for marker

# Implementation omitted here for brevity; real script will mirror activate-redesign's behavior.
# -------------------------- end deactivate-redesign.sh ---------------------


# ---------------------------------------------------------------------------
# 3) Draft tool: `tools/migrate-to-redesign.sh`
#
# Intent:
# - Non-destructive migration helper. Defaults to `--dry-run`.
# - `--apply` updates user config to enable the redesign by injecting a managed snippet
#   into the user's `~/.zshenv` that sources the repo-provided env wrapper (as done by
#   `activate-redesign.sh`).
# - Behavior:
#   - `--dry-run` : show exact file changes that would be made.
#   - `--apply`   : create backup, inject snippet, log entry in `tools/migration.log`.
#   - `--restore` : restore from the created backup.
#
# Draft (outline):
#
# -------------------------- begin migrate-to-redesign.sh --------------------
#!/usr/bin/env zsh
# tools/migrate-to-redesign.sh
set -euo pipefail
DRY_RUN=1
APPLY=0
RESTORE=0
BACKUP_DIR="${HOME}/.local/share/zsh/redesign-migration"
ZSHENV_PATH="${ZDOTDIR:-$HOME}/.zshenv"
MIGRATION_LOG="tools/migration.log"
REDESIGN_ENV_FILE="\${PWD}/dot-config/zsh/tools/redesign-env.sh"  # example path referenced by activate-redesign

print_help() {
  cat <<EOF
Usage: $0 [--dry-run] [--apply] [--restore] [--help]

--dry-run  Show planned changes (default).
--apply    Perform migration: backup, inject snippet to enable redesign, log migration.
--restore  Restore previous backup created by this tool.
--help     Show this help.
EOF
}

# Parsing omitted for brevity in this draft.

# When --apply:
# 1) mkdir -p "${BACKUP_DIR}"
# 2) cp "${ZSHENV_PATH}" "${BACKUP_DIR}/zshenv.$(date -u +%Y%m%dT%H%M%SZ).bak"
# 3) Inject snippet between markers (same snippet format as activate-redesign.sh)
# 4) Append migration entry to ${MIGRATION_LOG} describing changes and timestamp

# When --dry-run:
#  - Print the snippet and show the patch (diff style) without writing files.
# --------------------------- end migrate-to-redesign.sh ---------------------


# ---------------------------------------------------------------------------
# 4) Draft GitHub Actions workflow: `.github/workflows/redesign-flagged.yml`
#
# Intent:
# - Branch-scoped (feature branch) workflow that runs when pushes occur on the
#   feature branch or when manually dispatched with `use_redesign: true`.
# - Sets `ZSH_USE_REDESIGN=1` for all jobs.
# - Runs unit & integration tests and a light perf smoke.
# - Uploads any perf ledger artifacts produced to GitHub Actions artifact storage.
#
# Draft YAML (annotated)
#
# -------------------------- begin redesign-flagged.yml ----------------------
name: Redesign (flagged) — Branch CI

on:
  push:
    branches:
      - 'feature/zsh-refactor-configuration'
  workflow_dispatch:
    inputs:
      use_redesign:
        description: 'Run with redesign enabled'
        required: true
        default: 'true'

jobs:
  test-redesign:
    runs-on: ubuntu-latest
    env:
      ZSH_USE_REDESIGN: '1'
      # Ensure ZDOTDIR points to repo-local zsh config for reliable tests
      ZDOTDIR: '${{ github.workspace }}/dot-config/zsh'
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Set up shell dependencies
        run: |
          sudo apt-get update -y
          sudo apt-get install -y bats coreutils git

      - name: Run unit tests
        working-directory: ./dot-config/zsh
        run: |
          ./tests/run-all-tests.zsh --unit-only

      - name: Run integration tests (design & prompt)
        working-directory: ./dot-config/zsh
        run: |
          ./tests/run-all-tests.zsh --design-only --timeout-secs 60

      - name: Run perf smoke (capture ledger)
        working-directory: ./dot-config/zsh
        env:
          PERF_LEDGER_DIR: ./tools/perf/ledgers
        run: |
          mkdir -p ./tools/perf/ledgers
          ./tools/perf-capture-dryrun.zsh --output ./tools/perf/ledgers/perf-ledger-${{ github.run_id }}.json || true

      - name: Upload perf ledger artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: perf-ledger-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/ledgers/
# --------------------------- end redesign-flagged.yml -----------------------


# ---------------------------------------------------------------------------
# 5) Draft GitHub Actions workflow: `.github/workflows/perf-nightly.yml`
#
# Intent:
# - Scheduled nightly job that runs perf harness with `ZSH_USE_REDESIGN=1` on
#   the feature branch and uploads the ledger artifact(s).
#
# Draft YAML (annotated)
#
# --------------------------- begin perf-nightly.yml -------------------------
name: Redesign — nightly perf

on:
  schedule:
    - cron: '0 4 * * *'    # daily at 04:00 UTC
  workflow_dispatch:

jobs:
  nightly-perf:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/feature/zsh-refactor-configuration' || github.event_name == 'workflow_dispatch'
    env:
      ZSH_USE_REDESIGN: '1'
      ZDOTDIR: '${{ github.workspace }}/dot-config/zsh'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update -y
          sudo apt-get install -y jq

      - name: Run perf harness (nightly capture)
        working-directory: ./dot-config/zsh
        run: |
          mkdir -p ./tools/perf/ledgers
          ./tools/perf-capture.sh --output ./tools/perf/ledgers/perf-ledger-$(date -u +%Y%m%dT%H%M%SZ).json

      - name: Upload ledger artifact
        uses: actions/upload-artifact@v4
        with:
          name: perf-ledger-nightly-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/ledgers/
# ---------------------------- end perf-nightly.yml --------------------------


# ---------------------------------------------------------------------------
# 6) Draft GitHub Actions workflow: `.github/workflows/bundle-ledgers.yml`
#
# Intent:
# - Manual workflow to assemble the last N ledger artifacts into a single
#   evidence bundle (zip) for PR attachment. Since GitHub Actions cannot easily
#   fetch arbitrary artifacts from other runs without the API, this draft
#   assumes that the invoker provides the artifact names or that the job is
#   run on a runner that already has the ledger files checked out (e.g., a
#   long-running self-hosted runner).
# - The workflow accepts `ledger_paths` input (multi-line) listing artifact
#   names or paths to include in the bundle. This keeps the job simple and
#   avoids duplicating artifacts in the repo.
#
# Draft YAML (annotated)
#
# ------------------------- begin bundle-ledgers.yml -------------------------
name: Bundle redesign ledgers

on:
  workflow_dispatch:
    inputs:
      ledger_paths:
        description: 'Newline-separated list of ledger paths (relative to repo) or artifact names to include'
        required: true
        default: ''

jobs:
  bundle:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Prepare bundle directory
        run: |
          mkdir -p ./tools/perf/bundles
          rm -f ./tools/perf/bundles/* || true

      - name: Copy specified ledgers into bundle dir
        run: |
          printf '%s\n' "${{ github.event.inputs.ledger_paths }}" | while IFS= read -r p; do
            if [[ -z "$p" ]]; then continue; fi
            if [[ -f "$p" ]]; then
              cp "$p" ./tools/perf/bundles/
            else
              echo "Warning: ledger path not found: $p"
            fi
          done

      - name: Create zip bundle
        run: |
          cd ./tools/perf
          zip -r redesign-ledgers-bundle-${{ github.run_id }}.zip bundles || true

      - name: Upload bundle artifact
        uses: actions/upload-artifact@v4
        with:
          name: redesign-ledgers-bundle-${{ github.run_id }}
          path: dot-config/zsh/tools/perf/redesign-ledgers-bundle-${{ github.run_id }}.zip
# -------------------------- end bundle-ledgers.yml --------------------------


# ---------------------------------------------------------------------------
# 7) Test & run plan (how I will run locally once drafts are approved)
#
# Local commands to run (from repo root `dotfiles/`):
# - Shim audit:
#     ./dot-config/zsh/tools/bench-shim-audit.zsh --output-json dot-config/zsh/docs/redesignv2/migration/shim-audit.json
#
# - Run design and unit tests:
#     ./dot-config/zsh/tests/run-all-tests.zsh --design-only
#     ./dot-config/zsh/tests/run-all-tests.zsh --unit-only
#
# - Perf smoke run (local):
#     cd dot-config/zsh
#     mkdir -p tools/perf/ledgers
#     ./tools/perf-capture-dryrun.zsh --output ./tools/perf/ledgers/perf-ledger-local.json
#
# - Migrate dry-run demonstration:
#     tools/migrate-to-redesign.sh --dry-run
#
# After running locally and confirming outputs, I will post the test logs and proposed commits for your review.
#
# ---------------------------------------------------------------------------
# 8) Next steps (after you approve these drafts)
#
# - I will split each draft into a separate file in this `docs/redesignv2/migration/` folder
#   (so you can review each file individually).
# - Once you explicitly approve any draft, I will implement it in the feature branch
#   with a single commit per artifact, run local tests, and paste outputs for your sign-off
#   before pushing to `origin/feature/zsh-refactor-configuration`.
#
# Please review these drafts and tell me which items you approve or want modified.
# If you approve, I will:
#  - write each draft out as files under `docs/redesignv2/migration/` (so you can diff)
#  - then wait for final approval to implement changes in-branch
#
# End of DRAFTS.md