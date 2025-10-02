# Function Catalog (v3)

Comprehensive inventory of notable functions across `.zshenv`, `.zshrc`, and `.zgen-setup`. For each: signature, purpose, key dependencies, and primary callers.

Legend
- Scope: [core] early boot; [loader] flow control; [settings] config store; [plugins] manager; [ui] user-facing
- Dependencies abbreviations: env=environment vars, ext=external commands, zmod=zsh module, pm=plugin manager

## .zshenv (core bootstrap)

- zsh_debug_echo(msg...)
  - Purpose: Minimal debug logger; optionally logs to `$ZSH_DEBUG_LOG` when `ZSH_DEBUG=1`
  - Deps: env
  - Scope: [core]

- _path_remove(paths...)
  - Purpose: Remove occurrences of path components from PATH (safe, multi-pass)
  - Deps: env (PATH)
  - Scope: [core]

- _path_append(paths...)
  - Purpose: Append path components (dedupe first)
  - Deps: _path_remove; env (PATH)
  - Scope: [core]

- _path_prepend(paths...)
  - Purpose: Prepend path components (dedupe first)
  - Deps: _path_remove; env (PATH)
  - Scope: [core]

- path_dedupe([--verbose] [--dry-run])
  - Purpose: De-duplicate PATH preserving first occurrence order
  - Deps: env (PATH)
  - Scope: [core]

- resolve_script_dir([path_or_script])
  - Purpose: Robust canonical directory resolution (symlink-aware)
  - Deps: ext(readlink), zsh parameter expansion
  - Scope: [core]

- zf::script_dir([path_or_script])
  - Purpose: Namespaced helper wrapper around resolve_script_dir
  - Scope: [core]

- has_command(cmd), command_exists(cmd)
  - Purpose: Existence checks with tiny cache `_zsh_command_cache`
  - Deps: `command -v`
  - Scope: [core]

- safe_git(args...)
  - Purpose: Prefer system git under common prefixes, fallback to `command git`
  - Scope: [core]

- _lazy_gitwrapper(args...)
  - Purpose: Back-compat shim -> `safe_git`
  - Scope: [core]

## .zshrc (entry, settings, loader)

- can_haz(cmd)
  - Purpose: Quick existence test (uses `which`)
  - Deps: ext(which)
  - Scope: [core]

- zqs-debug(msg...)
  - Purpose: Emit debug messages when `~/.zqs-debug-mode` present
  - Scope: [core]

- load-shell-fragments(dir)
  - Purpose: Source every readable file from a directory
  - Deps: ext(ls), `source` semantics (no filtering)
  - Callers: multiple directory loaders (pre-plugins, post-plugins, OS/work)
  - Risk: sources backups/disabled files. See recommendations.
  - Scope: [loader]

- _zqs-get-setting(name [default])
  - Purpose: Read setting from `_ZQS_SETTINGS_DIR` or echo default
  - Deps: ext(cat)
  - Used by: OMZ toggle, diff-so-fancy toggle, zmv autoload, ssh-askpass, update checks, etc.
  - Scope: [settings]

- _zqs-set-setting(name value), _zqs-delete-setting(name), _zqs-purge-setting(name)
  - Purpose: Create/update/delete settings files
  - Deps: ext(mkdir, rm)
  - Scope: [settings]

- _zqs-update-stale-settings-files()
  - Purpose: Migrate legacy flags/files to new settings
  - Deps: ext(sed, rm)
  - Scope: [settings]

- zsh-quickstart-select-bullet-train(), zsh-quickstart-select-powerlevel10k()
  - Purpose: Switch prompt family; mark for `init.zsh` rebuild
  - Deps: _zqs-set-setting; _zqs-trigger-init-rebuild
  - Scope: [ui]

- zqs-quickstart-... helpers (enable/disable bindkeys, control-c decorator, ssh-askpass)
  - Purpose: Feature toggles via settings
  - Scope: [settings]

- onepassword-agent-check(), load-our-ssh-keys()
  - Purpose: SSH agent configuration and key loading
  - Deps: ext(op, keychain, ssh-agent, ssh-add, find)
  - Scope: [core]

- globalias() + ZLE widget wiring
  - Purpose: Inline alias expansion
  - Deps: zle
  - Scope: [ui]

- _load-lastupdate-from-file(path), _update-zsh-quickstart(), _check-for-zsh-quickstart-update()
  - Purpose: Self-update cadence and execution
  - Deps: ext(date, expr, git)
  - Scope: [core]

- zqs() (CLI dispatcher)
  - Purpose: Entry point for user commands (update, settings, cleanup)
  - Deps: zgenom and update helpers
  - Scope: [core]

## .zgen-setup (plugin manager)

- warn-about-prompt-change()
  - Purpose: One-time prompt family announcement
  - Scope: [ui]

- load-starter-plugin-list()
  - Purpose: Compose starter plugin set (optional OMZ, zsh-users, helpers, p10k)
  - Deps: zgenom; `_zqs-get-setting`
  - Scope: [plugins]

- setup-zgen-repos()
  - Purpose: Choose between user local plugin list vs starter list
  - Deps: `source` of user files
  - Scope: [plugins]

- get_file_modification_time(file)
  - Purpose: Cross-platform `stat` implementation (BSD/Linux)
  - Scope: [plugins]

## Call Graph Highlights

- `.zshrc` → `load-shell-fragments` → pre-plugins dir → `.zgen-setup` → zgenom → `~/.zgenom/init.zsh` → `.zshrc` resumes → post-plugins dir
- `.zshenv` defines helpers used widely by both `.zshrc` and `.zgen-setup`
- `zqs()` calls: update routines, zgenom helpers, and settings ops

## Public vs Private Conventions

- Public/stable: `_zqs-get/set/delete/purge-setting`, `zqs` CLI, PATH helpers, script-dir helpers
- Private/loader internals: `load-shell-fragments`, update internals, migration helpers

## Gaps / Opportunities

- Replace external tools (`cat`, `expr`, `date`) with zsh built-ins where possible for speed and portability
- Harden `load-shell-fragments` to filter by `*.zsh(N-.L)` and ignore `*.disabled`, dotfiles, and non-regular files
- Settings function could support comments and typed values; consider `zmodload zsh/mapfile`

