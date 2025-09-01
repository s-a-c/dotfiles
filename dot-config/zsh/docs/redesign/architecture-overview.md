# Architecture Overview (Consolidated Copy)
Date: 2025-08-30
Status: Planning (Pre-Migration)

Summary of startup phases, module responsibilities, and redesign targets (see original architecture/overview.md for exhaustive detail).

## Startup Phases (Current)
1. .zshenv (env, XDG, paths, history, plugin mgr paths)
2. .zshrc (loader, pre-plugin fragments, plugin manager init, post-plugin fragments, prompt)
3. Prompt ready (TTFP)
4. (Planned) Deferred async tasks (perf + integrity)

## Redesign Targets
- Post-plugin: 11 modules (00..90)
- Pre-plugin: planned 8 modules (00..40) in `.zshrc.pre-plugins.d.redesigned`
- Add-plugins optimization: phased lazy Node/npm reactivation (see plugin-loading-optimization.md)

## Key Issues Addressed
| Issue | Resolution |
|-------|-----------|
| Fragmentation | Merge & deterministic prefixes |
| Early heavy hashing | Defer to async (80-security-validation) |
| Prompt & completion coupling | Separation (50 vs 60) |
| Multiple function libs | 10-core-functions consolidation |
| Compinit guard absence | 50-completion-history single-run guard |

## Dependency Mapping (Simplified)
| Module | Depends | Provides |
|--------|---------|----------|
| 00-security-integrity | .zshenv | Minimal registry, logging stubs |
| 05-interactive-options | 00 | setopt/unsetopt, history config |
| 10-core-functions | 00 | helper functions, async dispatch |
| 20-essential-plugins | zgenom cache | ensure/regenerate minimal set |
| 30-development-env | 10 | dev tools env, SSH, VCS |
| 40-aliases-keybindings | 05,10 | alias + keymap layer |
| 50-completion-history | zgenom fpath ready | compinit guard + zstyles |
| 60-ui-prompt | starship/p10k | prompt theming |
| 70-performance-monitoring | 10 | timing capture hooks |
| 80-security-validation | 00,10 | async deep hashing |
| 90-splash | all prior | final banner |

## Cross-References
| Topic | Link |
|-------|------|
| Implementation Plan | planning/implementation-plan.md |
| Final Report | planning/final-report.md |
| Analysis | planning/analysis.md |
| Diagrams | planning/diagrams.md |
| Issues Review | review/issues.md |
| Completion Audit | review/completion-audit.md |
| Consolidation Plan | consolidation/plan.md |
| Testing Strategy | planning/testing-strategy.md |
| Migration Checklist | planning/migration-checklist.md |
| Prefix Reorg Spec | planning/prefix-reorg-spec.md |
| Pre-Plugin Redesign Spec | planning/pre-plugin-redesign-spec.md |

---
**Navigation:** [← Previous: README Index](README.md) | [Next: Consolidation Plan →](consolidation/plan.md) | [Top](#) | [Back to Index](README.md)

---
(End architecture overview copy)
