# Architecture (v3)

This document maps the ZSH configuration architecture in this repository. It builds on redesign v2 (see `../redesignv2/ARCHITECTURE.md`, `REFERENCE.md`) and updates the model to reflect the current codebase.

## High-Level Overview

Startup sequence and ownership:
1) /etc/zshenv (system) → 2) ~/.zshenv (repo: dot-config/zsh/.zshenv) → 3) /etc/zshrc (system) → 4) ~/.zshrc (repo: dot-config/zsh/.zshrc)
5) Pre-plugin modules (ZDOTDIR/.zshrc.pre-plugins.d/*)
6) Plugin manager & plugins (zgenom via ZDOTDIR/.zgen-setup; ~/.zgenom/init.zsh)
7) Post-plugin modules (ZDOTDIR/.zshrc.d/* and OS/work-specific fragment dirs)
8) Prompt integration and finalization

## Module Hierarchy and Responsibilities

- .zshenv (bootstrap)
  - Establishes XDG paths, ZDOTDIR, cache/log dirs
  - Early PATH sanity & dedupe (`path_dedupe`), robust helpers for PATH mgmt (`_path_remove`, `_path_append`, `_path_prepend`)
  - Settings & feature flags (e.g., PREPLUGIN/POSTPLUGIN redesign toggles)
  - Script-dir resolvers (`resolve_script_dir`, `zf::script_dir`) to avoid brittle `${0:A:h}` usage
  - zgenom localization (ZGEN_SOURCE, ZGEN_INIT) and early fpath setup for functions
  - History defaults and minimal safety guards (IFS, LANG/LC, EDITOR/VISUAL)

- .zshrc (entry point & loader)
  - Settings system (ZDOTDIR-aware `_ZQS_SETTINGS_DIR` and `_zqs-*` functions)
  - Core loader function `load-shell-fragments` (sources all files found in target dir)
  - Pre-plugin directory sourcing (ZDOTDIR-aware), OS-specific alias dirs
  - zgenom setup via `.zgen-setup` (ZDOTDIR-aware sourcing)
  - History, options, completion styles, PATH expansion for brew/eza/etc
  - Update checker (`_check-for-zsh-quickstart-update`) and zqs dispatcher/CLI
  - Post-plugin directory sourcing (ZDOTDIR-aware; also OS/work-specific)

- .zshrc.pre-plugins.d/* (pre-plugin modules)
  - Early guard rails: PATH safety, environment setup, lazy framework bootstraps
  - System and developer integrations that must precede plugin manager

- .zgen-setup (plugin manager setup)
  - Clone/load zgenom and build the plugin set
  - Starter plugin list (oh-my-zsh optional, zsh-users plugins, utility plugins, p10k)
  - `setup-zgen-repos` and `load-starter-plugin-list` define plugin composition and order
  - Idempotently rebuilds ~/.zgenom/init.zsh when inputs change

- .zshrc.d/* (post-plugin modules)
  - Core infrastructure, security/integrity, completion system, comprehensive env
  - POSTPLUGIN subdir: security, interactive options, core functions finishing pass

## Startup Flow (narrative)

1. .zshenv normalizes environment and PATH, sets flags, and defines robust helpers. It also localizes zgenom and sets conservative defaults to avoid missing-command failures.
2. .zshrc defines config settings system and a generic loader (`load-shell-fragments`). It loads pre-plugins modules under ZDOTDIR and then sources `.zgen-setup` to prepare plugin ecosystems.
3. Plugin manager composes the plugin set and ensures an init file (caching for speed). The shell then proceeds to post-plugin modules for completion configuration, security checks, and UI/prompt integration.
4. The finalization step dedupes PATH and binds optional iTerm/prompt integration.

## Dependency Relationships

- .zshenv must run first; `.zshrc` assumes helpers and environment are ready.
- `.zshrc` → `load-shell-fragments` → pre-plugins and post-plugins directories
- `.zshrc` → `.zgen-setup` → zgenom → plugins → `~/.zgenom/init.zsh`
- Settings system (`_zqs-get/set/delete/purge-setting`) is used by:
  - Update checks, plugin list decisions, features (e.g., diff-so-fancy, zmv autoloading)

## Data & State Management

- Settings storage: `_ZQS_SETTINGS_DIR` (ZDOTDIR-aware), simple files storing values
- Flags in environment (e.g., QUICKSTART_KIT_REFRESH_IN_DAYS, PRE/POST redesign toggles)
- PATH management functions ensure append/prepend semantics with dedupe
- History, cache, and logs anchored under XDG + ZDOTDIR

## Known Hotspots / Constraints

- `load-shell-fragments` currently sources every readable file in a directory (no pattern filter). This can inadvertently include backups or disabled files. See recommendations to gate by glob pattern and skip `.disabled`/non-*.zsh files.
- External command usage in helper functions (e.g., `cat`, `expr`, `date`) can degrade portability/performance; prefer zsh built-ins when feasible.
- Plugin list logic mixes OMZ and independent plugins; ensure settings gating and idempotence.

## References to v2
- See `../redesignv2/ARCHITECTURE.md` for the prior model.
- See `../redesignv2/STAGE3_STATUS_ASSESSMENT.md` and `../redesignv2/tracking/STAGE3_COMPLETION_SUMMARY.md` for migration status.


