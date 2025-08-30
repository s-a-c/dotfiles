# Testing Strategy (Consolidated Copy)
Date: 2025-08-30
Status: Initial Strategy Established

(Condensed copy; authoritative tests will reference this path.)

## Categories
| Category | Focus |
|----------|-------|
| Design | Structure/naming/guards |
| Unit | Core helpers |
| Feature | User-facing commands |
| Integration | Startup path, compinit single-run |
| Performance | Startup thresholds/regressions |
| Security | Registry integrity, deferred hashing |
| Maintenance | Drift/memory (future) |

## Key Guard Variables
`_COMPINIT_DONE`, `_ASYNC_PLUGIN_HASH_STATE`, `ZSH_REDESIGN`.

## Performance Modes
Quick (3 runs) pre-commit; Full (10 runs) CI. Threshold: redesign <= 80% baseline mean; regression fail >5% slower vs baseline.

## Structure Assertions
- 11 redesign files (post-promotion) numeric prefixes
- Unique ascending prefixes
- Guard sentinel `_LOADED_` in each file

## Single Compinit Test Concept
Source completion module twice → ensure `_COMPINIT_DONE=1` once and compdump file exists.

## Deferred Integrity Test Concept
Capture timestamp before prompt; ensure advanced hashing not run pre-first prompt; confirm state variable transitions afterwards.

## 13. Cross-References
| Topic | File |
|-------|------|
| Architecture | ../architecture/overview.md |
| Issues Review | ../review/issues.md |
| Completion Audit | ../review/completion-audit.md |
| Consolidation Plan | ../consolidation/plan.md |
| Master Improvement Plan | ../improvements/master-plan.md |

---
**Navigation:** [← Previous: Implementation Entry Criteria](implementation-entry-criteria.md) | [Next: Rollback Decision Tree →](rollback-decision-tree.md) | [Top](#) | [Back to Index](../README.md)

---
(End testing strategy copy)
