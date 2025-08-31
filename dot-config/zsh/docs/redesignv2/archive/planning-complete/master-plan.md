# Master Improvement Plan (Consolidated Copy)
Date: 2025-08-30
Status: Implementation In Progress

## Objectives
- ≥20% startup reduction (gate: startup_mean <= 0.80 * baseline)
- Consolidate into 11 post-plugin + 8 pre-plugin modules (frozen counts)
- Single guarded compinit + deferred integrity (no blocking hash pre-prompt)
- Automated regression & drift detection (structure, inventory, checksums, perf)

## Phases (Execution Stages)
| Stage | Label Tag | Scope | Key Exit Conditions | Commit Close-Out Example |
|-------|-----------|-------|---------------------|--------------------------|
| 0 | refactor-baseline | Inventories, checksum freeze | pre/post inventories + legacy-checksums.sha256 committed | chore(redesign): baseline freeze artifacts |
| 1 | refactor-skeleton | Parallel skeleton dirs (8+11) | Structure tests green, toggles present | feat(redesign): add skeleton redesign trees |
| 2 | refactor-pre-core | Pre-plugin 00/05/10 path + lazy framework | Path merged, lazy dispatcher stub tests pass | feat(pre): merge path safety & lazy dispatcher |
| 3 | refactor-pre-features | Remaining pre (15/20/25/30) | Lazy node, integrations, ssh agent stubs validated | feat(pre): add node/env + integrations + ssh agent |
| 4 | refactor-post-core | Post 00/05/10 core content | Security/options/functions implemented | feat(post): implement early security/options/functions |
| 5 | refactor-post-features | Post 20/30/40 | Essential plugins/dev env/aliases grouped | feat(post): add feature layer modules |
| 6 | refactor-completion-ui | Post 50/60 | Single compinit test PASS, prompt isolated | feat(post): unify completion & prompt |
| 7 | refactor-async-perf | Post 70/80 | Perf hook records, async state machine QUEUED->COMPLETED | perf(post): add perf + async validation |
| 8 | refactor-splash | Post 90 | Cosmetic splash optional & guard documented | chore(post): add splash module |
| 9 | refactor-perf-ab | A/B metrics capture | perf-postplugin-ab.json & preplugin-baseline collected | perf: capture A/B redesign metrics |
| 10 | refactor-guard | Promotion guard extended | promotion-guard passes (structure+perf+checksums+async) | chore(guard): extend promotion guard |
| 11 | refactor-validation | Final readiness | All gates green, report generated | docs(report): promotion readiness summary |
| 12 | refactor-promotion | Enable toggles default | New checksum snapshot generated | feat(redesign): promote redesigned config |

## Plan Freeze Milestone (Pre-Execution Gate)
All planning artifacts present & cross-linked BEFORE any skeleton commits. (See implementation-entry-criteria.md)

## Key Tasks (Expanded)
- Structural: maintain file counts, order monotonic, sentinel coverage.
- Drift: inventories + checksum verification each CI.
- Performance: baseline capture, segment timing, regression guard.
- Async Integrity: state machine IDLE->QUEUED->RUNNING->COMPLETED post-prompt.
- Testing: taxonomy coverage (design/unit/feature/integration/perf/security/maintenance).
- Promotion Guard: aggregate structure, perf delta, checksum, async deferral.

## Metrics & Evidence
| Metric | Baseline Artifact | Target | Current Status |
|--------|-------------------|--------|----------------|
| startup_mean_ms | perf-baseline.json | -20% | Pending post-feature phases |
| pre_plugin_file_count | preplugin-inventory.txt | 8 redesign | Skeleton met |
| post_plugin_file_count | postplugin-inventory.txt | 11 redesign | Skeleton met |
| compinit_runs | compinit tests | 1 | Legacy PASS / redesign TBD |
| async_deferred | async state test | >0ms delay | Pending async phase |

## Risks (Focused)
| Risk | Mitigation | Detection |
|------|-----------|-----------|
| Silent legacy drift | Checksums + inventory diff | drift & checksum tests |
| Multiple compinit | Single sentinel + tests | compinit test suite |
| Async blocking prompt | Defer queue after prompt hook | perf hooks + state test |
| Performance regression | Regression guard + bisect | perf-regression-check.zsh |

## Testing Strategy Link
See testing-strategy.md (expanded) for taxonomy & gates.

## Acceptance / Exit Checklist
- File counts stable (8 + 11)
- Single compinit
- Async validation deferred
- ≥20% startup improvement
- Promotion guard PASS
- Documentation updated & cross-linked

---
**Navigation:** [← Previous: Implementation Plan](implementation-plan.md) | [Next: Migration Checklist →](migration-checklist.md) | [Top](#) | [Back to Index](../README.md)
