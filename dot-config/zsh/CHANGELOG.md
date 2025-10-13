# ZSH Configuration Refactor Changelog

All notable changes for the ongoing refactor are documented here. This file complements component-specific logs (e.g. `CHANGELOG.starship.md`).

## 2025-10-13

### Changed

- **Options consolidation** - Merged all ZSH option configuration into a unified architecture.
  - Consolidated all 50 unique options from `401-options-override.zsh` into `400-options.zsh`
  - Converted `401-options-override.zsh` to a minimal user override template with 10 example customizations
  - Reorganized `400-options.zsh` into 11 logical sections for better discoverability
  - Added comprehensive documentation for each option including description, default, recommendation, and rationale
  - Special handling for `WARN_CREATE_GLOBAL` remains (delayed to `990-restore-warn.zsh` to avoid vendor script warnings)
  - Updated `docs/160-option-files-comparison.md` to serve as historical record and migration guide
  - **Migration**: Users who modified old 401 file should extract personal customizations to new 401 template (see migration guide)
  - **Rationale**: Eliminates confusion between baseline and user customization, provides single source of truth, simplifies maintenance

### Fixed

- **WARN_CREATE_GLOBAL startup warnings** - Eliminated all "scalar parameter created globally in function" warnings during shell initialization.
  - Added comprehensive variable predeclarations in `.zshenv` for vendor-created globals (`_ZF_ATUIN`, `_ZF_ATUIN_KEYBINDS`, `__fzf_completion_options`, `__fzf_key_bindings_options`, `_zqs_fragment`, `svalue`)
  - Created `.zshrc.pre-plugins.d/005-load-fragments-no-warn.zsh` to override `load-shell-fragments()` with `LOCAL_OPTIONS no_warn_create_global`
  - Created `.zshrc.pre-plugins.d/006-zqs-get-setting-no-warn.zsh` to override `_zqs-get-setting()` with proper local variable declarations
  - Commented out early `setopt WARN_CREATE_GLOBAL` in `.zshrc.d/401-options-override.zsh` (delayed to `990-restore-warn.zsh`)
  - Fixed `shell_health_check()` in `.zshrc.d/540-user-interface.zsh` to use `[[ -o EXTENDED_GLOB ]]` instead of grep-based check
- **Insecure directory permissions** - Fixed world-writable `~/.local/share/composer` directory (chmod 777 → 755) to silence Ruby security warnings.
- **Missing configuration files** - Created empty `~/.Xresources` to prevent colorscript sed errors.

### Added

- Comprehensive troubleshooting documentation in `docs/150-troubleshooting-startup-warnings.md` covering:
  - WARN_CREATE_GLOBAL mechanics and function context issues
  - Complete solution architecture with predeclaration, override, and delayed activation strategies
  - FZF integration warning resolution
  - Directory permission best practices
  - Prevention strategies and automated testing approaches
- Option files comparison documentation in `docs/160-option-files-comparison.md` covering:
  - Complete comparison of `400-options.zsh` vs `401-options-override.zsh`
  - 50 total unique options across 7 categories
  - Load order and override behavior
  - Philosophy and design rationale for two-file approach
  - Practical recommendations for customization

### Changed

- Updated `docs/README.md`, `docs/000-index.md`, and `docs/030-activation-flow.md` to reference new troubleshooting guide.
- Updated `docs/210-issues-inconsistencies.md` to mark WARN_CREATE_GLOBAL issue as resolved with complete implementation details.
- Added Quick Troubleshooting section to `docs/README.md` for common startup issues.

### Notes

- `WARN_CREATE_GLOBAL` remains active after startup to catch issues in user code while vendor scripts load cleanly.
- Function override pattern in `.zshrc.pre-plugins.d/005-*.zsh` can be applied to other vendor functions as needed.
- All variable predeclarations use `typeset -g` for scalars and `typeset -ga` for arrays.

## 2025-10-08

### Added

- Starship suppression mode via `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1`.
- Runtime tests: `test_starship_suppression_mode.zsh`, expanded wrapper shim checks.
- Central Starship prompt initialization file `520-prompt-starship.zsh` consolidating legacy fragments.
- Stale guard auto-repair (clears guard if mismatched STARSHIP_SHELL then re-inits).
- Global changelog (this file) and dedicated Starship changelog.
- Centralized Powerlevel10k hint fragment `445-p10k-hint.zsh` with `ZSH_SHOW_P10K_HINT` toggle (default off) to replace scattered echo lines.

### Changed

- Unified prompt initialization order ensures functions exist prior to gating.
- Wrapper shim now suppressed (pending full removal) to prevent premature guard setting.
- Documentation: Updated implementation plan with unique subtask headings & suppression semantics.

### Removed

- Legacy compatibility fragment `055-starship-compat.zsh` (mapping done inline now).
- Duplicate p10k configure echo lines from `.zshrc` / `.zshrc.local` (consolidated).

### Planned / Pending

- Removed deprecated `starship-init-wrapper.zsh` and its wrapper shim test; unified file is the sole entry point.
- Introduce CI workflow to automatically run runtime tests on push/PR.

### Notes

- Metrics logging remains conditional on writable `artifacts/metrics` directory.
- Force immediate flag `ZSH_STARSHIP_FORCE_IMMEDIATE=1` unchanged and compatible with suppression (export force after manual init when needed).

## 2025-10-09

### Changed

- `.zshrc` is now a symlink to the vendored quickstart kit at `zsh-quickstart-kit/zsh/.zshrc` to eliminate duplication and drift.
- `.zshrc.local` reduced to a minimal late-override stub; guidance added to use layered fragments for most changes.

### Rationale

- Keeps updates to the vendored kit seamless while preserving a single, predictable late override hook.
