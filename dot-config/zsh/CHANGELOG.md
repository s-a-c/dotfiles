# ZSH Configuration Refactor Changelog

All notable changes for the ongoing refactor are documented here. This file complements component-specific logs (e.g. `CHANGELOG.starship.md`).

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
