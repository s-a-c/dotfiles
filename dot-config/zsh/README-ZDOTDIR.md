Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

# ZDOTDIR: canonical location and notes

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

Policy acknowledgement
----------------------
Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>