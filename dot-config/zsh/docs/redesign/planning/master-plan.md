# Master Improvement Plan (Consolidated Copy)
Date: 2025-08-30
Status: Planning – Implementation Pending

(Condensed from original; canonical redesign-local reference.)

## Objectives
- ≥20% startup reduction
- Consolidate into 11 post-plugin + planned 8 pre-plugin modules
- Single guarded compinit + deferred integrity
- Automated regression detection

## Phases (High-Level)
(See implementation-plan.md for detailed gating)
1 Baseline → 2 Backup → 3 Skeleton → 4 Core → 5 Feature → 6 Deferred → 7 Validation → 8 Promotion → 9 Docs → 10 CI/CD → 11 Enhancements → 12 Maintenance

## Plan Freeze Milestone (Pre-Execution Gate)
All planning artifacts must be present & cross-linked BEFORE any skeleton or rename commits:
| Artifact | Present | File |
|----------|---------|------|
| Prefix Reorg Spec | ✔ | prefix-reorg-spec.md |
| Pre-Plugin Redesign Spec | ✔ | pre-plugin-redesign-spec.md |
| Compinit Audit Plan | ✔ | compinit-audit-plan.md |
| Baseline Metrics Plan | ✔ | baseline-metrics-plan.md |
| Implementation Entry Criteria | ✔ | implementation-entry-criteria.md |
| Rollback Decision Tree | ✔ | rollback-decision-tree.md |
| Diagrams (complete) | ✔ | diagrams.md |
| Pre-Plugin Inventory Snapshot | ✔ | preplugin-inventory.txt |
| Glossary | ✔ | glossary.md |
| Issues Review | ✔ | review/issues.md |
| Completion Audit | ✔ | review/completion-audit.md |
| Governance Lint Scripts | ✔ | tools/docs-governance-lint.zsh |

Freeze Declaration Procedure:
1. Run docs governance + link lint scripts (must pass).
2. Commit with message: `docs(plan-freeze): declare planning freeze`.
3. Tag `plan-freeze` (annotated) containing hash of all above docs.
4. Only after tag: begin skeleton directory creation on feature branch.

## Key Tasks (Abbrev)
- T1 Baseline capture
- T3 Backup
- T4 Skeleton
- T6 Security stub
- T8 Core functions merge
- T12 Completion-history
- T15 Advanced integrity async
- T16 Perf A/B, T19 CI Core workflow
- T20 Perf workflow + badges
- T24 Plugin diff alert
- T27 Structure drift guard.

## Metrics & Evidence
| Metric | Baseline | Target | Artifact |
|--------|----------|--------|----------|
| startup_mean_ms | perf-baseline.json | -20% | perf-current.json |
| post_plugin_file_count | manual | 11 | structure-audit.json |
| pre_plugin_file_count | 12 | 8 | future preplugin audit |
| compinit_runs | trace | 1 | compinit integration test |

## Risks
Refer to issues.md; core: fragmentation, early hashing, prompt mixing, naming.

## Testing Strategy Link
See testing-strategy.md.

## Acceptance / Exit Checklist (Abbrev)
Baseline, backup, skeleton, perf gain, single compinit, async non-blocking, promotion, docs, CI/CD green, enhancements, maintenance automation.

---
**Navigation:** [← Previous: Implementation Plan](implementation-plan.md) | [Next: Migration Checklist →](migration-checklist.md) | [Top](#) | [Back to Index](../README.md)
