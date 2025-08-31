# Script Consolidation & Migration Plan (Consolidated Copy)
Date: 2025-08-30
Status: Draft (Pre-Execution)

(Replicated from original docs/consolidation/plan.md for centralized redesign documentation.)

## 1. Goals
- Reduce active post-plugin modules from 5 (+52 legacy disabled) to 11 clearly defined redesign modules.
- Eliminate redundant/legacy fragments while maintaining functional parity.
- Provide reversible, auditable steps (each commit references task ID and has green tests).

## 2. Source → Target Mapping
(Abbreviated — see original for full mapping.)
| Current / Legacy | Target | Action | Notes |
|------------------|--------|--------|-------|
| 00_20-plugin-integrity-core | 00-security-integrity | Rename + slim | Minimal registry bootstrap |
| 00_21-plugin-integrity-advanced | 80-security-validation | Deferred logic | Async triggering |
| 00_60-options | 05-interactive-options | Rename | Centralize interactive options |
| 20_04-essential | 20-essential-plugins | Refactor | Idempotent ensure |
| 30_30-prompt | 60-ui-prompt | Isolate | Move completion styles out |
| 00_30-performance-monitoring (disabled) | 70-performance-monitoring | Reactivate | Lightweight hooks |
| 30_10-aliases + 30_20-keybindings | 40-aliases-keybindings | Merge | Reduce fragmentation |
| *_functions splits | 10-core-functions | Merge | Autoload / lazy wrappers |
| 10_x dev env set | 30-development-env | Merge | Conditional heavy logic |
| completion-management/finalization | 50-completion-history | Merge & guard | Single compinit guard |
| splash | 90-splash | Rename | Minimal final banner |

## 3. Execution Phases (Summary)
Skeleton → Core Migration → Feature Migration → Deferred → Validation → Promotion.

## 4. Guard Pattern
```
[[ -n ${_LOADED_<UPPER_ID>:-} ]] && return
_LOADED_<UPPER_ID>=1
```

## 5. Integrity Split Strategy
Early (00) stub; deferred (80) deep scan & commands; shared utilities in 10-core-functions.

## 6. Completion Integration
Guarded single compinit in 50-completion-history; zstyles migrated from .zshrc.

## 7. Performance Monitoring
70 module registers precmd hook & exposes sampling functions.

## 8. Validation Checklist (Abbrev)
- File count = 11
- Single compinit run
- Startup ≤ 80% baseline
- Deferred hashing confirmed

## 9. Risks (Abbrev)
Missing function (whence audit), perf regression (quick gate), async interference (state var), silent hash failure (status command).

## 10. Cross-References
| Topic | Link |
|-------|------|
| Implementation Plan | ../planning/implementation-plan.md |
| Final Report | ../planning/final-report.md |
| Migration Checklist | ../planning/migration-checklist.md |
| Issues Review | ../review/issues.md |
| Testing Strategy | ../planning/testing-strategy.md |
| Architecture Overview | ../architecture-overview.md |

---
**Navigation:** [← Previous: Architecture Overview](../architecture-overview.md) | [Next: Issues Review →](../review/issues.md) | [Top](#) | [Back to Index](../README.md)

---
(End consolidation plan copy)
