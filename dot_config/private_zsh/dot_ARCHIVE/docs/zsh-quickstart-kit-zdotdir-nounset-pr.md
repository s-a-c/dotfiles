# PR: Make zsh-quickstart-kit ZDOTDIR-aware and nounset-resilient

This change makes core zsh-quickstart-kit files work seamlessly when users set ZDOTDIR to a custom configuration directory, and hardens them against `setopt nounset` (error on unset parameters).

## Summary of changes

Files modified:
- zsh/.zshrc
  - Replace hardcoded `~/...` paths to zsh config files with `${ZDOTDIR:-$HOME}/...`
  - Guard variable tests with nounset-safe expansions (`${VAR-}`, `${VAR:-default}`, `(( ${+VAR} ))`)
  - Examples:
    - `~/.zqs-zprof-enabled`, `~/.zqs-debug-mode`, `~/.zqs-settings-path`, `~/.zqs-settings`
    - `~/.zshrc.pre-plugins.d`, `~/.zshrc.add-plugins.d`, `~/.zshrc.d`, `~/.zshrc.$(uname).d`, `~/.zshrc.work.d`
    - `~/.zgen-setup`, `~/.zsh_functions`, `~/.zsh_aliases`, `~/.sh_aliases`
    - `~/.zsh/completions` cache path, `~/.zsh-completions(.d)`
    - `~/.macos_aliases(.d)`, `~/.osx_aliases(.d)`
    - `~/.zsh_history`, `~/.zsh-quickstart-last-update`, `~/.p10k.zsh`
  - Nounset fixes in common tests:
    - `[[ -z "$LSCOLORS" ]]` -> `[[ -z ${LSCOLORS-} ]]`
    - `[[ -z "$SSH_CLIENT" ]]` -> `[[ -z ${SSH_CLIENT-} ]]`
    - `[[ -z "$GENCOMPL_PY" ]]` -> `[[ -z ${GENCOMPL_PY-} ]]`
    - `[[ -n "$ZSH_COMPLETION_HACK" ]]` -> `[[ -n ${ZSH_COMPLETION_HACK-} ]]`
    - `[[ -z "$TREE_IGNORE" ]]` -> `[[ -z ${TREE_IGNORE-} ]]`
    - `[[ -n "$GOPATH" ]]` -> `[[ -n ${GOPATH-} ]]`
    - `[[ -n "$DESK_ENV" ]]` -> `[[ -n ${DESK_ENV-} ]]`
  - Function `load-shell-fragments` now guards `$1` with `${1-}` and properly quotes paths
- zsh/.zgen-setup
  - Default zgenom parent and data dir honor ZDOTDIR: `ZGEN_DIR=${ZGEN_DIR:-${ZDOTDIR:-$HOME}/.zgenom}`
  - Use `${ZDOTDIR:-$HOME}` for prompt change marker, additional-plugins, OMZ gating, plugin directories, and zgen init timestamps
  - Respect ZDOTDIR for local overrides: `.zgen-local-plugins`, `.zsh-quickstart-local-plugins`
  - Use ZDOTDIR-relative GENCOMPL_FPATH (`${ZDOTDIR:-$HOME}/.zsh/complete`)
  - Nounset-safe tests for `need_update`
- zsh/.zsh_aliases
  - Only set VISUAL if EDITOR is set (nounset-safe):
    - `if (( ${+EDITOR} )); then export VISUAL="$EDITOR"; fi`
  - Source `${ZDOTDIR:-$HOME}/.zsh_aliases.local` instead of `~/.zsh_aliases.local`
- zsh/.zsh_functions
  - Source `${ZDOTDIR:-$HOME}/.zsh_functions.local` instead of `~/.zsh_functions.local`

Behavior when ZDOTDIR is unset remains identical because `${ZDOTDIR:-$HOME}` falls back to `$HOME`.

## Rationale
- ZDOTDIR-awareness enables portable configs in non-standard locations (e.g., `$XDG_CONFIG_HOME/zsh`)
- Nounset-resilience prevents startup failures under strict shells (setopt UNSET)
- Backwards compatibility maintained via defaulting to `$HOME` when ZDOTDIR is unset

## How to test

Test matrix:
- A) ZDOTDIR set to custom dir
- B) ZDOTDIR unset (default `$HOME`)

Common setup:
- Ensure your `.zshrc` is a symlink to the kit’s `zsh/.zshrc` (as recommended by zqs docs)

A) ZDOTDIR set
- Run fresh interactive shells twice (first run regenerates caches, second uses caches):
  - `ZDOTDIR="$HOME/.config/zsh" ZSH_FORCE_ZGEN_RESET=1 zsh -i -c exit`
  - `ZDOTDIR="$HOME/.config/zsh" zsh -i -c exit`
- Verify:
  - No `parameter not set` errors
  - Plugins load; prompt renders; history file at `${ZDOTDIR}/.zsh_history`
  - Completion cache at `${ZDOTDIR}/.zsh/cache`
  - `.zgenom/init.zsh` created under `${ZDOTDIR}/.zgenom/`

B) ZDOTDIR unset
- Run from a login/interactive shell with default `$HOME`:
  - `env -u ZDOTDIR ZSH_FORCE_ZGEN_RESET=1 zsh -i -c exit`
  - `env -u ZDOTDIR zsh -i -c exit`
- Verify same outcomes, but paths under `$HOME` instead of `${ZDOTDIR}`

Smoke checks in both scenarios:
- `zqs update-plugins` (via zgenom)
- `zqs check-for-updates` (last-update stamp is at `${ZDOTDIR}/.zsh-quickstart-last-update`)
- Toggle `~/.zqs-zprof-enabled` in the active ZDOTDIR and confirm zprof loads/suppresses

## Suggested branch name and commit message
- Branch: `fix/zdotdir-nounset-resilience`
- Commit message:
  - Title: `Make zsh-quickstart-kit ZDOTDIR-aware and nounset-resilient`
  - Body:
    - "Replace hardcoded HOME paths for zsh config with ${ZDOTDIR:-$HOME} and add nounset-safe guards (${VAR-}, ${VAR:-default}, (( ${+VAR} ))). No behavior change when ZDOTDIR is unset."

## Open the PR upstream

From the kit checkout directory (the repo that contains `zsh/.zshrc`):

1) Create branch and commit
- `git checkout -b fix/zdotdir-nounset-resilience`
- `git add zsh/.zshrc zsh/.zgen-setup zsh/.zsh_aliases zsh/.zsh_functions`
- `git commit -m "Make zsh-quickstart-kit ZDOTDIR-aware and nounset-resilient\n\n- Use \${ZDOTDIR:-$HOME} for config paths\n- Guard unset vars with \${VAR-}/\${VAR:-default}/(( \${+VAR} ))\n- Preserve behavior when ZDOTDIR unset"`

2) Fork and add remote (if not already)
- `gh repo fork --remote --remote-name fork`

3) Push branch
- `git push -u fork fix/zdotdir-nounset-resilience`

4) Create PR
- `gh pr create --base main --head <your-user>:fix/zdotdir-nounset-resilience \
  --title "Make zsh-quickstart-kit ZDOTDIR-aware and nounset-resilient" \
  --body "See description and test plan in the PR. Maintains backward compatibility when ZDOTDIR is unset."`

Manual alternative:
- Open: `https://github.com/unixorn/zsh-quickstart-kit/compare/main...<your-user>:fix/zdotdir-nounset-resilience?expand=1`

## Notes
- Only zsh-configuration-related paths were made ZDOTDIR-aware; non-zsh data (e.g., `~/.ssh`, `~/.aws`) intentionally left under `$HOME`.
- Where feasible, messages mentioning paths were updated to reflect ZDOTDIR usage.
