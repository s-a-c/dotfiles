# ZSH Redesign — Migration README (migrate-to-redesign)

Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

This document explains the supported ways to enable and disable the ZSH redesign:
- Ad-hoc (session-only) evaluation — zero-disk-impact quick test
- Safer persisted enable/disable using the repo tooling (recommended)
- CI / automation patterns (non-interactive, safe-by-default)

All commands below assume you are in the repository root:
cd /Users/s-a-c/dotfiles

Paths and tools referenced
- Migration tool: `dot-config/zsh/tools/migrate-to-redesign.sh`
- Deactivate helper: `dot-config/zsh/tools/deactivate-redesign.sh`
- Activate helper (if present): `dot-config/zsh/tools/activate-redesign.sh`
- Redesign environment snippet (managed): `dot-config/zsh/tools/redesign-env.sh`
- Default ZDOTDIR for tests and CI: `dot-config/zsh`
- Migration logs: `dot-config/zsh/tools/migration.log`
- Backups: by default the tool writes to `~/.local/share/zsh/redesign-migration` unless `--backup-dir` specified

Notes about safety and policy
- The migration tool is non-destructive by default: it performs a `--dry-run` preview unless `--apply` is explicitly requested.
- When `--apply` is used the tool creates a timestamped backup before making changes.
- An interactive checklist is required for non-forced `--apply` runs. For automation use `--force` or set `MIGRATE_FORCE=1`.
- Every AI-authored artifact and user-facing script in this flow includes the project policy acknowledgement.

1) Ad-hoc (temporary) evaluation — safe, no disk writes
Use these flows when you want to try the redesign only for the current shell session.

- Option 1 — spawn a new interactive shell with redesign enabled:
  ZDOTDIR="$PWD/dot-config/zsh" ZSH_USE_REDESIGN=1 zsh -i

  What this does:
  - Starts a new shell with redesign feature flags in environment.
  - No files are modified on disk.
  - Exit to return to normal shell.

- Option 2 — source the redesign environment snippet into an existing shell:
  source ./dot-config/zsh/tools/redesign-env.sh

  Verify:
  - echo $ZSH_USE_REDESIGN           # should print 1 in the session
  - env | grep ZSH_USE_REDESIGN

Disable for the session:
- exit the shell, or:
  unset ZSH_USE_REDESIGN

2) Safer persisted enable / disable (recommended)
This flow uses the repository tooling, preserves backups, and records actions.

A. Preview (dry-run)
- Always start with a dry-run preview; it shows a unified diff or before/after:
  dot-config/zsh/tools/migrate-to-redesign.sh --dry-run --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log"

- Review the preview. Confirm it only adds the managed snippet bounded by:
  # >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>
  ...
  # <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<

B. Apply (interactive by default)
- Run the interactive apply to persist the redesign:
  dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log"

- The tool will:
  - Create a timestamped backup in the chosen backup dir.
  - Append the managed `REDESIGN-ENV` snippet to the provided target file.
  - Log the operation to the migration log.

- Interactive checklist:
  - When not run with `--force` or `MIGRATE_FORCE=1` you will be prompted to type an explicit confirmation (e.g., `I AGREE` or `I ACCEPT` depending on the tool version).
  - This prevents accidental, automated changes to user files.

C. Verify after apply
- Confirm snippet presence:
  grep -n "REDESIGN-ENV (managed by activate-redesign.sh)" "$HOME/.zshenv" || true

- Inspect the migration log:
  sed -n '1,200p' dot-config/zsh/tools/migration.log

D. Deactivate/restore
- Preferred: use the provided deactivate helper which is the inverse of activation:
  dot-config/zsh/tools/deactivate-redesign.sh --disable --zshenv "$HOME/.zshenv" --log "dot-config/zsh/tools/migration.log"

- Or restore from latest backup:
  dot-config/zsh/tools/migrate-to-redesign.sh --restore --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log"

- After restore, verify the `REDESIGN-ENV` block is gone and the previous content is restored.

E. Testing tip: use a disposable target before applying to your real home file
- Create a disposable test file and apply there:
  cp -p "$HOME/.zshenv" "$HOME/.zshenv.test" || printf "# test\n" > "$HOME/.zshenv.test"
  dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$HOME/.zshenv.test" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log"
  tail -n 80 "$HOME/.zshenv.test"

3) CI / automation (safer defaults + recommended patterns)
Principles:
- Do not mutate user home in CI. Prefer environment flagging or workspace-local files.
- For non-interactive runs, set MIGRATE_FORCE=1 or pass `--force`.

A. Preferred: enable redesign solely by environment variables in CI
- Set env vars and run tests using the repo ZDOTDIR. Example GitHub Actions snippet:
  env:
    ZSH_USE_REDESIGN: '1'
    MIGRATE_FORCE: '1'
  steps:
    - uses: actions/checkout@v4
    - name: Run design tests with redesign enabled
      run: |
        export ZDOTDIR="$PWD/dot-config/zsh"
        export ZSH_USE_REDESIGN=1
        export ZSH_CACHE_DIR="$HOME/.cache/zsh"
        ./tests/run-all-tests.zsh --design-only

B. If you must persist a workspace-local zshenv in CI (ephemeral workspace)
- Use the migrate tool with `--force` and an explicit workspace-local target:
  dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$PWD/dot-config/zsh/.zshenv.ci" --backup-dir "$PWD/dot-config/zsh/.backups/ci-redesign" --log "dot-config/zsh/tools/migration-ci.log" --force

4) Acceptance checklist (what to confirm before concluding the migration is good)
- [ ] Dry-run preview was inspected and only the intended managed snippet will be added.
- [ ] A readable, timestamped backup is created before any on-disk modification.
- [ ] Migration log contains an `apply` entry with target and backup path.
- [ ] `--status` reports snippet present after apply.
- [ ] Restore/deactivate correctly restores prior state and logs a `restore`.
- [ ] Unit, integration and design tests pass with redesign enabled (for CI: run with env override).
- [ ] No secrets or tokens were leaked or written to logs/backups.

5) Troubleshooting & FAQ
- Permission denied running the tool:
  chmod +x dot-config/zsh/tools/migrate-to-redesign.sh

- No `diff` available for dry-run preview:
  The tool will fall back to showing before/after file dumps. Install `diffutils` if desired.

- Backups not found on restore:
  Ensure you specify the same `--backup-dir` used at apply time; list the directory to inspect timestamps:
  ls -1t dot-config/zsh/.backups/redesign*

- How to inspect exactly what was added:
  awk '/REDESIGN-ENV \\(managed by activate-redesign.sh\\)/{p=1} p{print} /<<< REDESIGN-ENV/{exit}' "$HOME/.zshenv"

6) Implementation pointers (for reviewers / operators)
- The tool uses the markers:
  SNIPPET_START: `# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>`
  SNIPPET_END:   `# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<`
  These must not be edited by hand if you expect `deactivate-redesign.sh` to work reliably.

- Interactive vs automated:
  - Manual runs: prefer interactive checklist (default).
  - Automation: use `--force` or `MIGRATE_FORCE=1` to bypass prompts.

- Logs and artifacts:
  - Migration actions are appended to the migration log provided via `--log` (default `tools/migration.log` when run from zsh dir).
  - Backups default to `~/.local/share/zsh/redesign-migration` unless changed with `--backup-dir`.

7) Example quick flows (copy/paste)

- Preview, then interactive apply (to real ~/.zshenv):
  dot-config/zsh/tools/migrate-to-redesign.sh --dry-run --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign"
  dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$HOME/.zshenv" --backup-dir "$PWD/dot-config/zsh/.backups/redesign" --log "dot-config/zsh/tools/migration.log"

- Test on disposable file:
  cp -p "$HOME/.zshenv" "$HOME/.zshenv.test" || printf "# test\n" > "$HOME/.zshenv.test"
  dot-config/zsh/tools/migrate-to-redesign.sh --apply --zshenv "$HOME/.zshenv.test" --backup-dir "$PWD/dot-config/zsh/.backups/redesign-test" --log "dot-config/zsh/tools/migration-test.log"

- CI example (enable by env only):
  export ZDOTDIR="$PWD/dot-config/zsh"
  export ZSH_USE_REDESIGN=1
  export ZSH_CACHE_DIR="$HOME/.cache/zsh"
  ./tests/run-all-tests.zsh --design-only

8) Contact & escalation
- If a restore does not produce the expected content, collect:
  - the migration log entry,
  - the backup file (e.g., `.backups/redesign/<target>.<timestamp>.bak`),
  - the test run logs under `dot-config/zsh/logs/`.
- Open an issue or ping the repo owner with these artifacts for assistance.

End of README