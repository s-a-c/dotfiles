# Redesign Migration: Plan and Checklist (Updated)

Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

This document captures the migration plan for enabling and validating the ZSH redesign (opt-in) on branch `feature/zsh-refactor-configuration`. It provides explicit next steps and the exact commands you can run to preview, apply, verify, and revert changes safely. Follow each step in order and only progress after you confirm the prior step's outputs.

Owner: `s-a-c`  
Repo root (work tree): `~/dotfiles/`  
ZSH project root: `ZDOTDIR=~/dotfiles/dot-config/zsh/`

Principles
- Safe-by-default: tools default to `--dry-run` until you explicitly `--apply`.
- Backups: every `--apply` creates timestamped backups before mutating files.
- Interactive guard: non-forced `--apply` prompts you to confirm.
- CI behavior: prefer env-flagging (`ZSH_USE_REDESIGN=1`) in CI instead of mutating user homes. Use `--force` or `MIGRATE_FORCE=1` in non-interactive automation.

Important paths
- ZSH project: `dot-config/zsh`
- Tools:
  - `dot-config/zsh/tools/migrate-to-redesign.sh`
  - `dot-config/zsh/tools/deactivate-redesign.sh`
  - `dot-config/zsh/tools/activate-redesign.sh` (if present)
  - `dot-config/zsh/tools/redesign-env.sh` (managed snippet source)
- Tests: `dot-config/zsh/tests/run-all-tests.zsh`
- Logs: `dot-config/zsh/logs` (test logs), `dot-config/zsh/tools/migration.log` (migration log)
- Backups: default `~/.local/share/zsh/redesign-migration` unless `--backup-dir` set

Quick safety checklist (pre-flight)
- [ ] Work on branch `feature/zsh-refactor-configuration`
- [ ] Ensure the repo is clean or changes are intentionally staged
- [ ] Compute and record guidelines checksum if you need to re-acknowledge policy (AGENT.md requirement)
- [ ] Make a disposable test target before applying to your real `~/.zshenv`

Section A — Git & workspace setup (commands)
1. Switch to working branch and confirm status:
   ```
   cd ~/dotfiles
   git fetch origin
   git switch feature/zsh-refactor-configuration
   git status --porcelain
   git log --oneline -n 5
   ```
2. Create a workspace snapshot (optional, for fast rollback):
   ```
   git stash push -m "pre-redesign-snapshot: $(date -u +%Y%m%dT%H%M%SZ)"
   ```

Section B — Local dry-run & discovery (commands)
1. Prepare environment used by test runners and tools:
   ```
   cd ~/dotfiles
   export ZDOTDIR="$PWD/dot-config/zsh"
   export ZSH_CACHE_DIR="$HOME/.cache/zsh"
   export ZSH_LOG_DIR="$ZDOTDIR/logs"
   mkdir -p "$ZSH_CACHE_DIR" "$ZSH_LOG_DIR" "$ZDOTDIR/docs/redesignv2/artifacts/metrics"
   ```
2. Run design-only tests (non-destructive smoke):
   ```
   ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --design-only | tee "$ZSH_LOG_DIR/design-only.run.log"
   ```
   - Expected: exit code `0` and design tests pass.
   - Inspect: `dot-config/zsh/logs/design-only.run.log`
3. Run the migrate tool in dry-run mode, preview patch against a disposable target:
   ```
   TEST_ZSHENV="$HOME/.zshenv.migrate_test"
   cp -p "$HOME/.zshenv" "$TEST_ZSHENV" 2>/dev/null || printf "# empty test\n" > "$TEST_ZSHENV"
   dot-config/zsh/tools/migrate-to-redesign.sh --dry-run --zshenv "$TEST_ZSHENV" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log" | tee "$ZSH_LOG_DIR/migrate-dryrun.log"
   ```
   - Verify the preview shows only the managed `REDESIGN-ENV` snippet.
   - Look for markers:
     - `# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>`
     - `# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<`

Section C — Backup-only & apply (interactive) (commands)
1. Create a timestamped backup of the disposable test target:
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --backup --zshenv "$TEST_ZSHENV" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log"
   ls -l "$PWD/dot-config/zsh/.backups/redesign-test"
   ```
2. Apply interactively (the script prompts you to type `I AGREE` or `I ACCEPT` depending on version):
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$TEST_ZSHENV" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log"
   ```
   - When prompted, type the exact phrase requested to continue.
   - After apply, inspect:
     ```
     tail -n 80 "$TEST_ZSHENV"
     sed -n '1,200p' dot-config/zsh/tools/migration-test.log
     ```
3. Verify idempotency by re-running dry-run:
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --dry-run --zshenv "$TEST_ZSHENV" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" | tee "$ZSH_LOG_DIR/migrate-dryrun2.log"
   ```
   - Expected: tool reports snippet already present and no changes.

Section D — Restore / Deactivate (commands)
1. Restore the most recent backup for the disposable target:
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --restore --zshenv "$TEST_ZSHENV" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log"
   tail -n 80 "$TEST_ZSHENV"
   ```
2. Use the deactivate helper (if you applied to your real `~/.zshenv`):
   ```
   dot-config/zsh/tools/deactivate-redesign.sh --disable --zshenv "$HOME/.zshenv" --log "dot-config/zsh/tools/migration.log"
   ```
   - Confirm the `REDESIGN-ENV` block is removed:
     ```
     grep -n "REDESIGN-ENV (managed by activate-redesign.sh)" "$HOME/.zshenv" || echo "Snippet removed or not present"
     ```

Section E — Promote to account default (safer flow)
Only after you have validated the disposable test and local tests pass:
1. Dry-run against real `~/.zshenv`:
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --dry-run --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log" | tee "$ZSH_LOG_DIR/migrate-home-dryrun.log"
   ```
2. Interactive apply to your real `~/.zshenv` (recommended):
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log"
   ```
3. Verify:
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --status --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign"
   tail -n 80 "$HOME/.zshenv"
   ```

Section F — CI / automation patterns & commands
Preferred approach: enable redesign via env vars in CI without mutating user homes.
1. Example GitHub Actions job snippet:
   ```yaml
   env:
     ZSH_USE_REDESIGN: '1'
     MIGRATE_FORCE: '1'         # optional; allow non-interactive tool usage if needed
   jobs:
     run-tests:
       runs-on: ubuntu-latest
       defaults:
         run:
           working-directory: dot-config/zsh
       steps:
         - uses: actions/checkout@v4
         - name: Run design tests with redesign enabled
           run: |
             export ZDOTDIR="$PWD"
             export ZSH_CACHE_DIR="$HOME/.cache/zsh"
             export ZSH_USE_REDESIGN=1
             ./tests/run-all-tests.zsh --design-only
   ```
2. If you must apply a workspace-local zshenv in CI (ephemeral):
   ```
   dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$PWD/dot-config/zsh/.zshenv.ci" --backup-dir "$PWD/dot-config/zsh/.backups/ci-redesign" --log "dot-config/zsh/tools/migration-ci.log" --force
   ZDOTDIR="$PWD/dot-config/zsh" ./tests/run-all-tests.zsh --design-only
   ```

Section G — Tests to run after enabling
Run the full local execution plan in this order (from repo root):
```
cd ~/dotfiles

# Design
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --design-only | tee "$ZSH_LOG_DIR/design-only.run.log"

# Unit
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --unit-only | tee "$ZSH_LOG_DIR/unit-only.run.log"

# Integration
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tests/run-all-tests.zsh" --integration-only | tee "$ZSH_LOG_DIR/integration-only.run.log"

# Perf smoke (dry-run capture)
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tools/perf-capture.zsh" --dry-run --iterations 5 | tee "$ZSH_LOG_DIR/perf-smoke.dryrun.log"

# Shim audit (produce artifact)
ZDOTDIR="$PWD/dot-config/zsh" "$ZDOTDIR/tools/bench-shim-audit.zsh" --output-json "$ZDOTDIR/docs/redesignv2/artifacts/metrics/shim-audit.json" | tee "$ZSH_LOG_DIR/shim-audit.log"
```

Acceptance criteria before pushing
- Design, unit, and integration tests pass locally (exit code `0`).
- `migrate-to-redesign.sh --dry-run` preview looks correct for both test and home targets.
- Backups were created and verify-able.
- `--apply` and `--restore` behave as expected on disposable targets.
- Shim audit output within acceptable threshold (document exceptions).
- Policy acknowledgement header present in any AI-authored artifacts and commit messages (see commit templates below).
- All CI workflows that will run are configured to use repo-relative paths and `defaults.run.working-directory: dot-config/zsh` where required.

Commit message guidance (include policy ack)
- Each AI-authored commit message MUST include the policy acknowledgement header. Use this template for commits that add/modify AI-authored files:
  ```
  <scope>: <short summary>

  Long description of change, verification steps, and test results.

  Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
  ```
- Example:
  ```
  tools: add interactive checklist to migrate-to-redesign.sh

  - Add interactive confirmation to --apply
  - Add --force and MIGRATE_FORCE env override for CI
  - Make script executable

  Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
  ```

Rollback plan
- If you applied to `~/.zshenv` and encounter problems:
  1. Restore from backup created by the tool:
     ```
     dot-config/zsh/tools/migrate-to-redesign.sh --restore --zshenv "$HOME/.zshenv" --backup-dir "<same-backup-dir>"
     ```
  2. If `--restore` fails, inspect backup directory and restore appropriate file manually:
     ```
     ls -1t <backup-dir> | head -n 5
     cp -p "<backup-file>" "$HOME/.zshenv"
     ```
  3. Re-run tests and validate the environment.

Next steps (actionable items you can approve now)
1. Review this updated plan and confirm: `Approve plan`.
2. I will then:
   - Generate any remaining draft artifacts (CI YAMLs and module drafts) as read-only files under `dot-config/zsh/docs/redesignv2/migration/` for review.
   - Run the local test suite and collect logs for your review.
3. After you review drafts and logs, approve a focused commit (one-topic-per-commit) and I will:
   - Push the commit(s) to `feature/zsh-refactor-configuration`.
   - Coordinate the first CI run for the flagged workflow.

Notes & references
- The migration tooling uses the markers:
  - `SNIPPET_START: # >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>`
  - `SNIPPET_END:   # <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<`
  Keep these markers intact when inspecting or editing files to ensure `deactivate-redesign.sh` can reliably remove the injected block.
- Keep all automation referencing repo paths relative to `dot-config/zsh/`. Use `defaults.run.working-directory: dot-config/zsh` for GitHub Actions jobs where possible.

If you approve this plan, reply with:
- `Approve plan` — I will produce remaining drafts and run the local test suite as described.
- Or specify modifications (e.g., different backup location, retention policy, or alternate CI behavior) and I will update the plan accordingly.
