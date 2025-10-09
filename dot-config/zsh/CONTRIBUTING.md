Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

CONTRIBUTING — zsh configuration (stow-managed)
===============================================

Purpose
-------
This file documents the contribution workflow and conventions for the zsh
configuration stored at:

  ~/dotfiles/dot-config/zsh

The repository is designed to be the canonical source for your Zsh runtime,
which you deploy with GNU Stow so that:

  ~/.config/zsh -> ~/dotfiles/dot-config/zsh

Follow these guidelines to keep the repo easy to maintain, testable, and
compatible with stow and your local ZDOTDIR runtime.

Quick start (stow)
------------------
From the repository root (~/dotfiles/dot-config):

  # Create the runtime symlink: ~/.config/zsh -> ~/dotfiles/dot-config/zsh
  stow -t $HOME/.config zsh

  # To remove the stow symlinks for zsh:
  stow -t $HOME/.config -D zsh

If you prefer to stow into $HOME directly (alternate workflows), do it
consistently across machines and document it here.

Canonical layout and where to add files
--------------------------------------
Keep the canonical config and source files inside this `zsh/` directory.

Common directories and intended usage:
- `zsh/.zshenv`  — early, shell-agnostic environment setup (XDG defaults, ZDOTDIR)
- `zsh/.zshrc`   — interactive shell setup (plugins, prompt, completion)
- `zsh/.zshrc.d/` — modular fragments loaded after main initialization (user extensions)
- `zsh/.zshrc.pre-plugins.d/` — fragments loaded before plugins (override plugin defaults)
- `zsh/.zshrc.work.d/` — optional work-specific fragments
- `zsh/.zqs-zgenom/` and `zsh/zgenom/` — vendored zgenom/zgen-compatible files (if present)
- `zsh/.env/`    — environment files that should be loaded into all shells (kept under ZDOTDIR)
- `zsh/.zsh_functions`, `zsh/.zsh_aliases` — helper files sourced by .zshrc

Rules for new files and fragments
---------------------------------
1. Place new persistent configuration inside `zsh/`. Stow will manage symlinks
   into `~/.config/zsh`, which is the runtime ZDOTDIR.
2. For small per-concern snippets, add files into:
   - `zsh/.zshrc.pre-plugins.d/` to override default behaviour before plugins load.
   - `zsh/.zshrc.d/` to extend or change behaviour after plugins load.
   - Use `zsh/.zshrc.work.d/` for ephemeral or workplace-specific fragments.
3. Avoid creating duplicate files or top-level symlinks that duplicate files
   inside `zsh/` (these confuse stow and other tools). Keep a single canonical copy.
4. Add documentation/comments to any new fragment explaining purpose and any
   platform assumptions (macOS/Linux).

Environment / secrets / .env
----------------------------
- Sensitive data and API keys may be kept under `zsh/.env/` (this directory is
  sourced by `.zshenv` when present). Prefer `zsh/.env/*.env` with secure
  permissions (600).
- If you intentionally keep .env files outside the repo (central secret store),
  document that in `README-ZDOTDIR.md` and ensure `.gitignore` prevents leaking.
- Do not source external secret files from the repo without documenting the dependency.

zgenom / plugin manager guidance
-------------------------------
- The initialization logic prefers local vendored zgenom under `ZDOTDIR`:
  1) `$ZDOTDIR/.zqs-zgenom`
  2) `$ZDOTDIR/zgenom`
  3) `${HOME}/.zgenom` (fallback)
- If you add/modify vendored zgenom code, keep it under `zsh/` so stow can
  deploy a consistent layout. Avoid creating duplicate top-level symlinks.

Debugging & testing locally
---------------------------
- After stowing, open a fresh shell and check:
  - `echo $ZDOTDIR` -> should be `~/.config/zsh` (or your intended stow target)
  - `zsh -i -c 'source $ZDOTDIR/.zshenv; echo $ZDOTDIR; echo $ZSH_COMPDUMP'` for non-interactive checks.
- Use `set -x` and `ZSH_DEBUG=1` to get more verbose logs when developing.
- If you add new functions/modules, lint them locally with shellcheck (recommended).
- For completion plugins, test `compinit`/`zstyle` interactions in a sandboxed shell
  before committing (avoid global changes that lengthen every shell start).

Commit messages & PRs
---------------------
- Use concise subject lines and a short body describing rationale and effect.
- Suggested subject for these housekeeping changes:

  Short:
  zsh: document canonical ZDOTDIR layout; remove redundant .zgenom symlink

  Verbose:
  zsh: remove redundant top-level .zgenom symlink and document ZDOTIR layout
  - Removed duplicate symlink `zsh/.zgenom` (now relying on `zgenom/` directory)
  - Add `zsh/README-ZDOTDIR.md` documenting canonical repo (`~/dotfiles/dot-config/zsh`) → runtime (`~/.config/zsh`) layout
  - Add `zsh/.zgenom.removed-<timestamp>.txt` as a backup/audit note
  - Add `zsh/USAGE.md` with stow instructions
  - Rationale: avoid duplicate references and make stow-managed layout the single source of truth

PR checklist
------------
Before requesting review, ensure:
- [ ] New files live under `zsh/` and respect the fragment conventions.
- [ ] No duplicate top-level symlinks were introduced.
- [ ] Any `.env` or secret files are either excluded from git or documented.
- [ ] Tests or manual checks were performed for new plugin or completion code.
- [ ] You included an appropriate commit message and PR description.

Code style / conventions
------------------------
- Write POSIX/pure-zsh-compatible fragments where possible (avoid unnecessary external calls).
- Prefer builtin/zsh features (`autoload`, `typeset`, zsh glob qualifiers) for performance.
- Keep platform-specific branches explicit with clear comments (e.g., macOS-only code guarded by `[[ "$(uname -s)" == "Darwin" ]]`).

Audit & backups
---------------
When removing symlinks or performing canonicalization changes, keep a small
audit file documenting:
- what was removed
- timestamp
- reason
- which canonical path remains

Example filename: `zsh/.zgenom.removed-2025-08-28T15-39-03.txt`

Security & privacy
------------------
- Do not commit private keys, passwords, or long-lived secrets. Use your secret
  manager or a private store outside the repo.
- If you must reference external credential files, document where they are and
  ensure they are excluded by `.gitignore`.

Support / questions
-------------------
If you're unsure where to put something or how a change will affect startup
behaviour, open an issue or a draft PR and tag me for review. Small changes to
`.zshenv` and early startup code can affect non-interactive services — test with
a clean shell session.

## Maintenance: Cleaning Ephemeral Artifacts

A helper script `tools/clean-zsh-refactor.sh` performs safe cleanup of generated metrics and log artifacts. It is dry-run by default.

Usage examples:

```
# List planned deletions for all default scopes (logs + artifacts)
./tools/clean-zsh-refactor.sh

# Actually delete artifact JSON/metrics only
./tools/clean-zsh-refactor.sh --scope artifacts --apply

# Keep newest 5 baseline_* log metric files, delete older ones
./tools/clean-zsh-refactor.sh --scope logs --retain 5 --apply

# Include cache directories (.context-cache, .zsh-evalcache, etc.)
./tools/clean-zsh-refactor.sh --purge-caches --apply

# Protect a specific file from deletion
./tools/clean-zsh-refactor.sh --keep artifacts/smoke.json --apply
```

Scopes:
- `logs` – files `logs/baseline_*` and dated subdirectories `logs/YYYY-MM-DD/`
- `artifacts` – JSON files at `artifacts/` root and everything under `artifacts/metrics/`
- `caches` – cache dirs (only when `--purge-caches`): `.context-cache/`, `.zsh-evalcache/`, `.performance/`, `.augment/`
- `all` – union of logs + artifacts, plus caches if `--purge-caches` supplied

Flags:
- `--dry-run` (default) Show planned deletions
- `--apply` Perform deletions
- `--scope <name>` Restrict scope (logs|artifacts|caches|all)
- `--retain <N>` Keep newest N `baseline_*` log files (older removed)
- `--keep <pattern>` Protect specific relative path (may repeat)
- `--purge-caches` Add cache directories to deletion set
- `--list-scopes` Show scope summary

Safety guards:
- Never deletes outside repository root
- Requires explicit `--apply` to perform destructive action
- Pattern-based keeps evaluated after retention filtering

Please prefer this script over ad‑hoc `rm -rf` to avoid accidental loss of tracked data.

Policy acknowledgement
----------------------
Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

END
