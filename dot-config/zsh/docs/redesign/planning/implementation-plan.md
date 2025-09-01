# ZSH Configuration Redesign – Implementation Plan
Date: 2025-08-29
Status: Planning (Original detailed version mirrored here; trimmed for core actionable content.)

## 1. Task Breakdown & Sequencing

### 1.0 Pre-Plugin Track (Explicit)
| ID | Task | Description | Priority | Progress | Safety / Preconditions | Validation Step | Rollback Reference |
|----|------|-------------|----------|----------|------------------------|-----------------|--------------------|
| [P0](#matrix-p0) | Pre-Plugin Inventory | Snapshot existing `.zshrc.pre-plugins.d` listing to inventory file | ⬛ | ⬜ | Baseline (1) complete | File `preplugin-inventory.txt` created & committed | 7.2 |
| [P1](#matrix-p1) | Pre-Plugin Skeleton | Create `.zshrc.pre-plugins.d.redesigned` guarded empty files (00..40) | ⬛ | ⬜ | P0 complete | 8 files present + guards | 7.3 |
| [P2](#matrix-p2) | Path & FZF Merge | Migrate 00-path-safety / 05-fzf-init content | 🔶 | ⬜ | P1 | New files source cleanly (zsh -n) | 7.3 |
| [P3](#matrix-p3) | Lazy Framework + Node Stubs | Implement 10-lazy-framework & 15-node-runtime-env stubs | 🔶 | ⬜ | P1 | Lazy commands register; no sourcing nvm yet | 7.3 |
| [P4](#matrix-p4) | Integrations Consolidation | direnv/git/copilot unify into 25-lazy-integrations | 🔵 | ⬜ | P2,P3 | First invocation loads real command; idempotent | 7.3 |
| [P5](#matrix-p5) | SSH Agent Consolidation | Merge ssh-agent-core/security to 30-ssh-agent | 🔵 | ⬜ | P1 | No duplicate agent spawn; keys preserved | 7.3 |
| [P6](#matrix-p6) | Pre-Plugin Timing Baseline | Capture pre-plugin timing before promotion | 🔵 | ⬜ | P2–P5 | preplugin-baseline.json produced | 7.5 |
| [P7](#matrix-p7) | Enable Loader Flag | Conditional sourcing of redesigned pre-plugin set | 🔶 | ⬜ | P1 | Flag toggles old vs new; tests pass | 7.3 |

> NOTE: Pre-plugin tasks P0–P7 interleave with core phases 1–4; ensure baseline & backup precede any migration writes.

## 1. Phased Task Breakdown (Condensed)
| Phase | Core Outcome | Key Modules / Artifacts | Exit Gate |
|-------|--------------|-------------------------|-----------|
| 1 Baseline | Metrics snapshot | perf-baseline.json | Perf JSON present, variance OK |
| 2 Backup | Immutable copy | .zshrc.d.backup-TS | Diff = 0 |
| 3 Skeleton | 11 guarded files | .zshrc.d.REDESIGN/* | Structure test green |
| 4 Phase1 Core | security/options/functions | 00/05/10 | Core unit tests pass |
| 5 Phase2 Features | plugins/dev/aliases/completion/prompt | 20/30/40/50/60 | Parity checklist green |
| 6 Deferred/Async | perf + integrity advanced | 70/80 | Async non-blocking test pass |
| 7 Validation | ≥20% speed gain | perf-current.json | Threshold test pass |
| 8 Promotion | Directory swap | activated redesign | Tag + rollback sim |
| 9 Docs Finalize | Updated reports | final-report.md | Docs index updated |
| 10 CI/CD | Workflows & badges | actions yml + badges | All workflows green |
| 11 Enhancements | zcompile/diff/schema/memory | scripts/tests | Enhancement tests pass |
| 12 Maintenance | Cron + sentinel | maintenance scripts | Nightly/weekly logs |

## 2. Safety & Rollback (Abbrev)
- Backup: copy & chmod a-w
- Guards: `_LOADED_*` sentinel in each module
- Perf gate: fail if >5% regression (promotion guard / perf workflow)
- Rollback: restore backup dir + reset tag `refactor-baseline`

## 3. Key Design / Structure Tests
- File count (11) & prefix pattern
- Unique prefixes & monotonic ordering
- Guard sentinel presence
- Single compinit execution

## 4. Performance Validation
10-run mean, discard first if warm-up; require redesign_mean <= baseline_mean * 0.80.

## 5. Async / Integrity
Early (00) stub only; deferred (80) triggered post-first prompt; state tracked via `_ASYNC_PLUGIN_HASH_STATE`.

## 6. Required Planning Docs (All Present Here)
analysis.md, diagrams.md, final-report.md, *-spec.md, baseline-metrics-plan.md, compinit-audit-plan.md, plugin-loading-optimization.md, implementation-entry-criteria.md, rollback-decision-tree.md, master-plan.md, consolidation plan, testing strategy, architecture overview.

## 7. Promotion Entry Checklist (Snapshot)
See implementation-entry-criteria.md (authoritative). All criteria must be ✅.

## 8. Tagging Strategy
- `refactor-baseline`
- `refactor-skeleton`
- `refactor-phase1` ... `refactor-phase2`
- `refactor-async`
- `refactor-validation`
- `refactor-promotion`

## 9. Commit Conventions
`type(scope): summary` with scopes: security, perf, prompt, completion, integrity, migration, async, docs.

## 10. Open Test Gaps (To Fill in Enhancements)
- RSS sampling baseline
- Structure drift sentinel
- Plugin diff alert logic

## 12. (NEW) Phase Exit Criteria (Augmented)
| Phase / Track | Existing Criteria | Added TDD/Git Criteria | New Automation Criteria |
|---------------|-------------------|------------------------|-------------------------|
| Pre-Plugin Skeleton (P1) | 8 files created | Design test allows legacy + new | – |
| Pre-Plugin Migration (P2–P5) | Functions merged; no compinit | Lazy node test, integration no-compinit test | – |
| Pre-Plugin Timing (P6) | JSON baseline captured | perf parser test added | – |

## 17. (NEW) Reference Documents
Cross-links: pre-plugin-redesign-spec.md, plugin-loading-optimization.md, prefix-reorg-spec.md, baseline-metrics-plan.md, migration-checklist.md.

---
**Navigation:** [← Previous: Final Report](final-report.md) | [Next: Master Plan →](master-plan.md) | [Top](#) | [Back to Index](../README.md)
