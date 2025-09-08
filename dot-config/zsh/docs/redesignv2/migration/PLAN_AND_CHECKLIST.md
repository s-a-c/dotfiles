# Redesign Migration: Plan and Checklist

This document captures the migration plan for enabling and validating the ZSH redesign (opt-in) within the feature branch `feature/zsh-refactor-configuration`, plus the results of the read-only scan used to prepare a safe, non-destructive implementation. Save and review these items before any edits or pushes are made.

Owner: `s-a-c`  
Repo root: `~/dotfiles/`  
Project root for ZSH: `$ZDOTDIR = ~/dotfiles/dot-config/zsh/`

**NOTE: All scripts and tests have been consolidated to project root (`$ZDOTDIR`) for consistency.**

---

## Goals (short)
- Implement and validate F-A3 / F-A4 / F-A5 (completion/history, UI/prompt, shim removal runtime guard) in-branch under `.zshrc.d.REDESIGN`.
- Provide `$ZDOTDIR/tools/deactivate-redesign.sh` and `$ZDOTDIR/tools/migrate-to-redesign.sh` (non-destructive; `--dry-run` / `--apply`).
- Add CI workflows to exercise the redesign in-branch (flagged runs) and nightly perf tests that upload artifacts.
- Provide an artifact-bundling workflow to package 7-day ledgers for PR evidence.
- Capture microbench baselines and run local tests first.

Constraints and safety rules:
- All changes must be opt-in via `ZSH_USE_REDESIGN=1`.
- No destructive file system removals without explicit approval.
- Runtime-only shim disabling for evaluation; on-disk replacements only via `migrate-to-redesign.sh --apply` after review.
- Local tests must run and pass before pushing incremental commits.

---

## Read-only scan summary (key findings)
The following items are the principal outputs of the read-only inspection (paths and highlights). These are included so you can verify the exact state that the plan targets.

- Redesign module loader toggles:
  - `$ZDOTDIR/.zshrc` — contains gating for `.zshrc.pre-plugins.d.REDESIGN` and `.zshrc.d.REDESIGN` and logic to auto-enable post-plugin redesign when pre-plugin redesign is active.

- Redesign modules present (post-plugin redesign directory):
  - `$ZDOTDIR/.zshrc.d.REDESIGN/` (observed files)
    - `00-security-integrity.zsh`
    - `05-interactive-options.zsh`
    - `10-core-functions.zsh`
    - `20-essential-plugins.zsh`
    - `30-development-env.zsh`
    - `40-aliases-keybindings.zsh`
    - `40-runtime-optimization.zsh` (skeleton exists and already guarded by `ZSH_USE_REDESIGN`)
    - `50-completion-history.zsh` (exists)
    - `55-compinit-instrument.zsh`
    - `60-p10k-instrument.zsh`
    - `60-ui-prompt.zsh` (already exists; accounted for)
    - `65-vcs-gitstatus-instrument.zsh`
    - `70-performance-monitoring.zsh`
    - `80-security-validation.zsh`
    - `85-post-plugin-boundary.zsh`
    - `90-splash.zsh`
    - `95-prompt-ready.zsh`

- Activation / migration helper:
  - `$ZDOTDIR/tools/activate-redesign.sh` — present and implements snippet injection, environment file generation, and status/backup helpers. This is the existing activation script referenced in docs.

- Bench / shim audit:
  - `$ZDOTDIR/tools/bench-shim-audit.zsh` — present; performs shim detection and can emit JSON artifacts used by gating. Current audit result: 1 shim detected (`zf::script_dir`; minimal, 1-line). Migration readiness remains conditional pending review.

- Tests and test harness:
  - Test runner and suites exist under `$ZDOTDIR/tests/` (many test files and categories observed, including integration/performance/security tests).
  - `$ZDOTDIR/tests/run-all-tests.zsh` and `$ZDOTDIR/tests/run-integration-tests.sh` (or similar runner entrypoints) are referenced in docs — local test commands provided in docs.

---

## Test Suite Catalogue & Path Resolution

The test suite is organized into subfolders by category. When referencing or running tests, ensure you use the correct subfolder path. Some tests may be referenced in documentation or runner output as if they are directly under `unit/`, but they may actually reside in `unit/core/` or `unit/tdd/`.

**Catalogue of key test files:**

- **Unit Tests**
  - `$ZDOTDIR/tests/unit/core/test-path-append-invariant.zsh`
  - `$ZDOTDIR/tests/unit/core/test-trust-anchors.zsh`
  - `$ZDOTDIR/tests/unit/tdd/test-fzf-no-compinit.zsh`
  - (plus others in `core/` and `tdd/`)

- **Integration Tests**
  - `$ZDOTDIR/tests/integration/test-compinit-single-run.zsh`
  - `$ZDOTDIR/tests/integration/test-postplugin-compinit-single-run.zsh`
  - `$ZDOTDIR/tests/integration/test-prompt-ready-single-emission.zsh`

- **Other Categories**
  - `$ZDOTDIR/tests/path/phase05/` (path normalization, dedup, lock, etc.)
  - `$ZDOTDIR/tests/design/` (sentinels, idempotency)
  - `$ZDOTDIR/tests/feature/`, `$ZDOTDIR/tests/critical/`, `$ZDOTDIR/tests/essential/`

**Test Runner Entrypoints**
- `$ZDOTDIR/tests/run-all-tests.zsh`
- `$ZDOTDIR/tests/run-integration-tests.sh`

---

## Troubleshooting: Path Issues

- If a test appears missing, check the relevant subfolder (e.g., `unit/core/`, `unit/tdd/`) rather than assuming it is directly under `unit/`.
- If you encounter path duplication in logs (e.g., `dot-config/dot-config/...`), review the test runner's working directory (`cwd`) and the value of `ZDOTDIR`. Ensure that relative paths are constructed correctly and do not concatenate repo root with config root more than once.
- When running tests manually, always set `ZDOTDIR` to the repo-local config directory for deterministic sourcing:
  ```
  ZDOTDIR=$PWD/dot-config/zsh $ZDOTDIR/tests/run-all-tests.zsh --unit-only
  ```
- For integration tests, confirm that any required modules or scripts exist in the expected locations before running.

---

- Docs and implementation plan:
  - `$ZDOTDIR/docs/redesignv2/IMPLEMENTATION.md` and `README.md` include the fast-track table and details for FT-01..FT-12.
  - `$ZDOTDIR/docs/redesignv2` contains artifacts, badges, and metrics directories (baseline metrics available).

- CI and workflows:
  - Project-root ZSH workflows are in place and updated (zsh-Redesign — nightly perf, zsh-Nightly Metrics Refresh, zsh-Perf & Structure CI, zsh-Structure Badge Generation). Repository-wide governance workflows are also present (repo-Variance Nightly, repo-Perf Ledger Nightly). A read‑only bundling workflow draft (draft-bundle-ledgers.yml) is available under `$ZDOTDIR/docs/redesignv2/migration/`.

- Notable sentinels / guards in code:
  - `ZSH_USE_REDESIGN` and `ZSH_ENABLE_PREPLUGIN_REDESIGN` / `ZSH_ENABLE_POSTPLUGIN_REDESIGN` are already used as gating variables in the codebase.
  - `_COMPINIT_DONE` sentinel is expected in the design to ensure single compinit.

---

## Proposed update to the plan (incorporating your clarifications)
You confirmed:
- `$ZDOTDIR/.zshrc.d.REDESIGN/60-ui-prompt.zsh` already exists and should be accounted for.
- `$ZDOTDIR/tools/migrate-to-redesign.sh` should update user config to enable redesign; it will be non-destructive with `--dry-run` and `--apply`.
- CI artifacts (for ledger bundling) should not be duplicated inside the repo; use GitHub Actions artifacts and the ZSH cache on runners as needed.
- Run local tests first before making commits/pushes.
- You require explicit approval before any changes are made.

With these confirmations, the plan below is updated to avoid duplicates and to be safe-by-default.

---

## Detailed safe plan (one-step-per-approval)
All *read-only* work will be performed first and presented for approval before any edits.

Step 0 — Read-only scan (COMPLETE)
- Produce this plan and the checklist (this file).
- Produce a shim inventory (from `tools/bench-shim-audit.zsh`) and list modules that are already implemented.
- List tests and test runner entry points.

Step 1 — Drafts generated (read-only)
- Draft content has been generated as read-only files under `$ZDOTDIR/docs/redesignv2/migration/` and is ready for review and approval.
  - Proposed module files:
    - `$ZDOTDIR/.zshrc.d.REDESIGN/50-completion-history.zsh` — (exists) will be audited and updated if required.
    - `$ZDOTDIR/.zshrc.d.REDESIGN/60-ui-prompt.zsh` — (exists) will be audited and extended only if needed.
    - `$ZDOTDIR/.zshrc.d.REDESIGN/70-shim-removal.zsh` — new runtime-only shim guard (non-destructive).
  - Proposed tool scripts (in `$ZDOTDIR/tools/`):
    - `$ZDOTDIR/tools/deactivate-redesign.sh` — exact inverse operations of `activate-redesign.sh` (restore backups, remove injected snippet).
    - `$ZDOTDIR/tools/migrate-to-redesign.sh` — `--dry-run` / `--apply` modes; `--apply` will modify user config to enable redesign (e.g., inject managed snippet into `~/.zshenv` / backup original). Writes a migration log `$ZDOTDIR/tools/migration.log`.
  - Proposed CI workflows (.github/workflows/ in-branch only):
    - `redesign-flagged.yml` — run tests with `ZSH_USE_REDESIGN=1` when branch is `feature/zsh-refactor-configuration` or via manual dispatch with `use_redesign: true`.
    - `perf-nightly.yml` — nightly job that runs perf harness with `ZSH_USE_REDESIGN=1` and uploads artifacts (GitHub Actions artifacts). Artifacts are not duplicated in repo; the job will collect ledgers from the runner workspace and upload them as workflow artifacts.
    - `bundle-ledgers.yml` — workflow to gather last 7 ledger artifacts and package them into a single zip for PR attach (manual `workflow_dispatch`).

Step 2 — Local tests & adjustments (after your approval)
- Run the following locally (from repo root `~/dotfiles/`):
  - Structure & design tests:
    - `$ZDOTDIR/tests/run-all-tests.zsh --design-only`
  - Unit tests:
    - `$ZDOTDIR/tests/run-all-tests.zsh --unit-only`
  - Integration tests:
    - `$ZDOTDIR/tests/run-integration-tests.sh --timeout-secs 30 --verbose`
  - Performance smoke & bench harness:
    - Follow `$ZDOTDIR/docs/redesignv2/README.md` microbench commands (e.g., perf-capture dry-run).
  - Shim audit:
    - `$ZDOTDIR/tools/bench-shim-audit.zsh --output-json $ZDOTDIR/docs/redesignv2/artifacts/metrics/shim-audit.json`
- Collect results and attach to the planned commit messages and CI job run notes.

Step 3 — Implement small, incremental commits (post-approval)
- One commit per independent change:
  - Add `$ZDOTDIR/.zshrc.d.REDESIGN/70-shim-removal.zsh` (runtime guard).
  - Add `$ZDOTDIR/tools/deactivate-redesign.sh`.
  - Add `$ZDOTDIR/tools/migrate-to-redesign.sh` (dry-run only initially).
  - Add CI workflow YAMLs (flagged & perf nightly & bundler).
  - Add tests or adjust existing tests to exercise idempotency and sentinel guards.
- Run local tests after each commit. Only push after local tests pass and you have approved the push.

Step 4 — Perf baseline capture and ledger gating
- Use existing bench harness to capture microbench baseline (non-shimmed version) and store as CI artifact and local baseline JSON in `$ZDOTDIR/docs/redesignv2/artifacts/metrics/bench-core-baseline.json`.
- Ensure `$ZDOTDIR/tools/bench-shim-audit.zsh` reports `shim_count == 0` (or document exceptions and gated thresholds).
- Run nightly perf on the branch for 7 days to produce the ledger history required for PR evidence.

Step 5 — Bundle evidence and prepare PR
- After 7-day stability gate and passing tests, use `bundle-ledgers.yml` to produce the evidence package (drift badge, stage3-exit-report, seven ledger snapshots, microbench baseline).
- Prepare PR to `develop` with the evidence bundle attached and follow the remediation PR template if necessary.

---

## Checklist: items to produce, confirm, and sign-off before any edits
The following checklist must be completed and each item explicitly approved by you before edits are made and pushed to `origin/feature/zsh-refactor-configuration`.

Repository inspection & drafts
- [ ] Full list of files drafted and available under `$ZDOTDIR/docs/redesignv2/migration/DRAFT_INDEX.md`. (Generated; review pending)
- [ ] Drafts of `$ZDOTDIR/tools/deactivate-redesign.sh` and `$ZDOTDIR/tools/migrate-to-redesign.sh` are available for review. (Generated; review pending)
- [ ] Draft module contents (including `70-shim-removal.zsh`) are available for review. (Generated; review pending)

Tests & local validation
- [ ] Confirm local test commands to run (I will run and paste the outputs). (Pending)
- [ ] Run `bench-shim-audit` and attach the JSON output and summary. (Pending)
- [ ] Run unit & integration tests (all passing locally) before any push. (Pending)

CI / workflows
- [ ] Draft CI workflow YAMLs have been generated for approval (flagging rules and artifact policies). (Generated; review pending)
- [ ] Confirm GitHub artifact retention / job permissions. (Pending)

Migration behavior & safety
- [ ] Confirm `$ZDOTDIR/tools/migrate-to-redesign.sh --apply` exact mechanism (what files to inject/modify and backup locations). (Pending)
- [ ] Confirm `$ZDOTDIR/tools/deactivate-redesign.sh` restores original `~/.zshenv` snippet exactly. (Pending)

Shim policy
- [ ] Confirm that runtime-only shim disabling (via `70-shim-removal.zsh`) is acceptable as first step. (Pending)
- [ ] Confirm that on-disk removal of shims is only allowed after a separate explicit approval. (Required; default: No on-disk removals.) (Confirmed by you earlier)

Push & commit policy
- [ ] For each planned commit, I will run local tests and paste the test output for your sign-off before pushing that commit. (Pending)
- [ ] When you approve a push, I will push to `origin/feature/zsh-refactor-configuration` with one commit per topic and clear messages. (Pending)

---

## Immediate next steps (read-only)
The following artifacts have been prepared as read-only drafts; no repository changes have been made pending your explicit approval. Drafts are deduplicated for implementation (flat draft-* files are canonical; the annotated `drafts/*.md` renderings can be removed after approval):
1. Exact file list and content drafts for:
   - `$ZDOTDIR/.zshrc.d.REDESIGN/70-shim-removal.zsh`
   - `$ZDOTDIR/tools/deactivate-redesign.sh`
   - `$ZDOTDIR/tools/migrate-to-redesign.sh`
   - `$ZDOTDIR/.github/workflows/redesign-flagged.yml`
   - `$ZDOTDIR/.github/workflows/perf-nightly.yml`
   - `$ZDOTDIR/.github/workflows/bundle-ledgers.yml`
2. A plan for test execution and the commands I will run locally, with expected outputs.
3. A shim inventory summary produced by `$ZDOTDIR/tools/bench-shim-audit.zsh` (JSON and short summary).

I will post the drafts in this directory (`$ZDOTDIR/docs/redesignv2/migration/`) as separate files for your review before making any code changes.

---

## Approve to proceed with the read-only draft generation
Reply with one of the following explicit commands:

- `Approve plan and produce drafts` — I will generate the drafts (module scripts, tool scripts, and CI YAMLs) and post them as read-only text files in `$ZDOTDIR/docs/redesignv2/migration/` for your review.
- `Modify plan: <details>` — specify any changes you want in the plan before drafts are created.
- `Abort` — cancel this operation.

I will wait for your explicit instruction before generating the drafts or making any modifications.

--- 

Appendix: quick references
- Redesign gating variable: `ZSH_USE_REDESIGN`
- Redesign directories:
  - Pre-plugin redesign: `~/.zshrc.pre-plugins.d.REDESIGN` / repo: `$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN`
  - Post-plugin redesign: `~/.zshrc.d.REDESIGN` / repo: `$ZDOTDIR/.zshrc.d.REDESIGN`
- Activation helper: `$ZDOTDIR/tools/activate-redesign.sh`
- Shim audit helper: `$ZDOTDIR/tools/bench-shim-audit.zsh`
- Perf ledgers destination (CI artifacts): `$ZDOTDIR/tools/perf/ledgers/` (runner workspace path referenced in docs)
- Test harness entrypoints: `$ZDOTDIR/tests/run-all-tests.zsh`, `$ZDOTDIR/tests/run-integration-tests.sh`
