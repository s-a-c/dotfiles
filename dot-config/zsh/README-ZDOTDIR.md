Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

# ZDOTDIR: canonical location and notes

> ⚠ Documentation Migration In Progress  
> The legacy redesign documentation under `docs/redesign/` is deprecated.  
> All new work, artifacts (badges, metrics, checksums, inventories), and stage specs now live under:  
> `docs/redesignv2/` (artifacts: `docs/redesignv2/artifacts/{badges,metrics,checksums,inventories}`)  
> Current Stage: see [Stage 3 Core Scope](docs/redesignv2/stages/stage-3-core.md).  
> During the soft migration phase tooling prefers redesignv2; artifacts are bridged back to legacy paths for backward compatibility.  
> Avoid adding new non‑deprecated content under `docs/redesign/`.


Overview
--------
This directory (`zsh/`) is the canonical source for your Zsh configuration in this repository.
You manage your runtime configuration with GNU Stow so that:

- Canonical (repo) location: `~/dotfiles/dot-config/zsh`
- Stowed/runtime location: `~/.config/zsh` (created by `stow` from the repo)

Typical stow usage (example)
---------------------------
From `~/dotfiles/dot-config` run:

    stow -t $HOME -S dot-config             # or
    cd ~/dotfiles/dot-config/zsh && stow -t $HOME/.config zsh

This will create `~/.config/zsh` as a symlink pointing to `~/dotfiles/dot-config/zsh`, which is the intended runtime `ZDOTDIR`.

What changed
------------
- Removed redundant symlink: `zsh/.zgenom` (was a symlink pointing to `zgenom/`).
  - Action: symlink removed to reduce duplicate references and avoid confusion with stow-managed layout.
  - Removal timestamp (local): 2025-08-28T15:39:03+01:00
  - Note: the `zgenom/` directory (the actual plugin manager code) remains present in the repository. Removing the `.zgenom` symlink only removes a redundant reference — it does not delete any plugin data.

Rationale
---------
Because you manage `~/.config/zsh` using stow from `~/dotfiles/dot-config/zsh`, the canonical files should live under `zsh/` in this repo. Top-level or duplicate symlinks that point to the same content create ambiguity for stow and for other tooling; removing that duplication keeps the canonical layout clean.

If you intended a different canonical location for zgenom (e.g. a per-user `~/.zgenom`), the init logic in `.zshenv` and `.zshrc` supports fallback locations such as `${HOME}/.zgenom`. The local plugin manager code (`zgenom/`) remains available for vendored/local installs.

Backup / audit note
-------------------
No plugin data was deleted. If you want an audit record or backup of the removed symlink, create a small text file recording the removal:

Example (manual) backup file you can create before committing:

- `zsh/.zgenom.removed-2025-08-28T15-39-03.txt` containing:
  ```
  Removed symlink: zsh/.zgenom -> zgenom
  Removal time: 2025-08-28T15:39:03+01:00
  Reason: redundant duplicate reference; canonicalized ZDOTDIR layout (stow-managed)
  ```

Files to review after this change
---------------------------------
- `zsh/.zshenv` — sets localized `ZDOTDIR` and `ZGEN_DIR` variables; it canonicalizes `ZDOTDIR` when possible.
- `zsh/.zshrc` — plugin initialization looks for `ZDOTDIR/.zqs-zgenom`, `ZDOTDIR/zgenom`, or `${HOME}/.zgenom` in that order.
- `zgenom/` — the vendored plugin manager directory remains in the repo and can be used if desired.

Suggested commit message
------------------------
Use this message when you commit the README and the symlink removal:

    zsh: document canonical ZDOTDIR layout; remove redundant .zgenom symlink

If you want a more verbose message (include context/time and reasoning):

    zsh: remove redundant top-level .zgenom symlink and document ZDOTDIR layout
    - Removed duplicate symlink `zsh/.zgenom` (now relying on `zgenom/` directory)
    - Add README documenting canonical repo (`~/dotfiles/dot-config/zsh`) → runtime (`~/.config/zsh`) layout
    - Rationale: avoid duplicate references and make stow-managed layout the single source of truth
    - Removal timestamp: 2025-08-28T15:39:03+01:00

Notes / recommended follow-ups
------------------------------
- If you want `ZDOTDIR` fully self-contained for stow, ensure any `.env` files or other external references are located inside `zsh/.env/` (or intentionally symlinked to your centralized secrets store).
- If you prefer, I can also create a short `CONTRIBUTING` or `README` section explaining how to use stow with this repo; tell me if you'd like that added.

Runtime compatibility note
--------------------------
To maintain runtime compatibility during the `.zgenom` → `zgenom` layout conversion, we provide a small, idempotent bootstrap script and Makefile helper that create a compatibility symlink `.zgenom -> zgenom`. This preserves existing runtime paths (and fixes errors like missing plugin files under `.zgenom`) without reverting the repository-level change that canonicalized the `zgenom/` directory.

Bootstrapping the compatibility symlink
-------------------------------------
- Repo-level (create the symlink inside the repository):
  - From the repository root:
    - Dry-run: `bash zsh/bin/ensure-zgenom-symlink.sh --repo --dry-run`
    - Create: `bash zsh/bin/ensure-zgenom-symlink.sh --repo`
    - To replace an existing non-symlink path: add `--force`
  - Makefile helper:
    - `make -C zsh ensure-zgenom-symlink MODE=repo`

- Runtime/stowed (create the symlink in your runtime ZDOTDIR, recommended in most cases):
  - Prefer passing an explicit ZDOTDIR or rely on the environment:
    - Example (env): `ZDOTDIR=~/.config/zsh bash zsh/bin/ensure-zgenom-symlink.sh --runtime`
    - Example (explicit): `bash zsh/bin/ensure-zgenom-symlink.sh --runtime --zdotdir ~/.config/zsh`
  - Makefile helper:
    - `make -C zsh ensure-zgenom-symlink MODE=runtime`

Script and Makefile locations
-----------------------------
- `zsh/bin/ensure-zgenom-symlink.sh` — idempotent script with options: `--zdotdir`, `--repo`, `--runtime`, `--target`, `--force`, and `--dry-run`.
- `zsh/Makefile` — includes `ensure-zgenom-symlink` and convenience targets to run the bootstrap script from the repo.

Recommended workflow
--------------------
1. Stow your config (example):
       cd ~/dotfiles/dot-config && stow -t $HOME -S dot-config
   or:
       cd ~/dotfiles/dot-config/zsh && stow -t $HOME/.config zsh

2. Ensure runtime compatibility (recommended):
       make -C zsh ensure-zgenom-symlink MODE=runtime
   or run the script directly:
       bash zsh/bin/ensure-zgenom-symlink.sh --runtime --zdotdir "$ZDOTDIR"

3. Verify the symlink and plugin files:
       ls -la ~/.config/zsh/.zgenom
       ls -la ~/.config/zsh/zgenom/djui/alias-tips/___/alias-tips.py

Notes and caveats
-----------------
- Repo-level symlink: adding a tracked `.zgenom` symlink to the repository defeats the purpose of removing the duplicate symlink; prefer the runtime symlink unless you intentionally want `.zgenom` committed.
- `.gitignore`: if `.zgenom` is ignored in `.gitignore`, committing a repo-level symlink will either require removing that ignore entry or forcing the add (`git add -f .zgenom`).
- CI / automation: prefer calling the bootstrap script (or the Makefile target) from your CI/bootstrap step so test runners and automation have the same compatibility layer.

Policy acknowledgement
----------------------
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

Pre-push hook (optional)
------------------------
A sample pre-push hook to block accidental direct pushes to 'main' and detect a resurrected HEAD:main refspec is (when present) located at the root-level `../../.githooks/pre-push` (relative to this README).

Enable it (local repository) with:
    git config core.hooksPath .githooks

One-off override examples (use sparingly):
    ALLOW_MAIN_PUSH=1 git push origin HEAD:main                    # allow a single direct push to main
    ALLOW_HEAD_REFSPEC=1 git push                                  # ignore a transient HEAD:main refspec (remove it instead)

Environment toggles:
- ALLOW_MAIN_PUSH=1          permit a single direct main push (otherwise blocked)
- ALLOW_HEAD_REFSPEC=1       bypass refspec (HEAD:main) protection temporarily
- BLOCK_ALIAS_FINDINGS=1     treat suspicious push aliases as fatal (default is warn)
- ALLOW_ALIAS_WARN=0         escalate alias findings to blocking (with BLOCK_ALIAS_FINDINGS=1)

Recommended workflow:
1. Keep pushes on feature branches; open PRs into main.
2. Remove any remote.origin.push entries like HEAD:main:
       git config --unset-all remote.origin.push
3. (Optional) Add a global safe push behavior:
       git config --global push.default current

This hook is an advisory safeguard complementing the repository’s documented migration & security guidelines.