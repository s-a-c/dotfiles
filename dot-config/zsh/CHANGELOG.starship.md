# Starship Prompt Configuration Changelog

## 2025-10-08

### Added

- Unified suppression flag `ZSH_STARSHIP_SUPPRESS_AUTOINIT=1` to expose prompt init functions without automatic initialization or hook registration.
- Runtime test `test_starship_suppression_mode.zsh` validating suppression behavior and manual init path.
- Runtime test `test_starship_stale_guard_repair.zsh` validating auto-repair of stale guard when STARSHIP_SHELL mismatch occurs.
- Centralized p10k hint integration (`ZSH_SHOW_P10K_HINT`) complementing Starship-first flow.

### Changed

- Removed deprecated wrapper `starship-init-wrapper.zsh`; suppression flag usage now documented for direct sourcing of unified fragment.
- Documentation updated to reflect suppression semantics and removal of legacy compat fragment.
- Added stale guard repair logic: if `__ZF_PROMPT_INIT_DONE` is set but `STARSHIP_SHELL!=starship`, the guard is cleared and init retried.

### Removed

- Legacy compatibility fragment `055-starship-compat.zsh` (legacy env mapping now handled directly inside unified file).

### Notes

- Manual initialization after suppression continues to normalize `STARSHIP_SHELL=starship` and set guard `__ZF_PROMPT_INIT_DONE`.
- Force immediate flag `ZSH_STARSHIP_FORCE_IMMEDIATE=1` unchanged; can be combined with suppression by exporting suppression only during sourcing and force flag during manual init.
