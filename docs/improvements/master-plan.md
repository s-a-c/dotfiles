# Master Improvement Plan
<!-- TOC -->
- [1. Objectives](#1-objectives)
- [2. Phased Roadmap (High-Level)](#2-phased-roadmap-high-level)
- [3. Task Register (Detailed)](#3-task-register-detailed)
- [4. Metrics & Evidence](#4-metrics--evidence)
- [5. Risk & Mitigation Matrix](#5-risk--mitigation-matrix)
- [6. Testing Strategy (Summary)](#6-testing-strategy-summary)
- [7. Automation Hooks](#7-automation-hooks)
- [8. Acceptance / Exit Checklist](#8-acceptance--exit-checklist)
- [9. Deferred / Optional (Reassess Post-Promotion)](#9-deferred--optional-reassess-post-promotion)
- [10. Documentation Cross-Refs](#10-documentation-cross-refs)
- [Appendix A: Tooling References](#appendix-a-tooling-references)
<!-- /TOC -->
Date: 2025-08-30
Status: Planning – Foundational Docs Complete, Implementation Pending

## 1. Objectives
- Achieve ≥20% interactive startup time reduction vs baseline
- Consolidate active fragments into 11 redesign modules
- Enforce single `compinit` invocation & shared compdump
- Provide measurable, test-backed improvements (performance, security, structure)
- Automate regression detection (performance + integrity)

## 2. Phased Roadmap (High-Level)
| Phase | Goal | Key Outputs | Exit Criteria |
|-------|------|-------------|---------------|
| 1 Baseline | Capture metrics & env snapshot | baseline metrics JSON + env list | Perf JSON + logs committed |
| 2 Backup | Immutable snapshot | `.zshrc.d.backup-<ts>` | Diff == 0 vs active dir |
| 3 Skeleton | Module scaffolding | 11 guarded empty files | Structure test green |
| 4 Core Migration | Security stub, options, functions | 00 / 05 / 10 populated | Unit tests pass |
| 5 Feature Migration | Plugins/dev/aliases/completion/prompt | 20 / 30 / 40 / 50 / 60 modules | Parity checklist started |
| 6 Deferred Features | Perf + advanced integrity | 70 / 80 modules | Async tests green |
| 7 Validation | Verify performance improvement | perf-current.json | ≥20% improvement |
| 8 Promotion | Activate redesign | directory rename + tag | Rollback simulation pass |
| 9 Docs | Finalize documentation | final-report, metrics | All docs committed |
| 10 CI/CD | Automated gates | GA workflows + badges | All workflows green |
| 11 Enhancements | zcompile, diff alerts, schema | scripts+tests | Drift guard test green |
| 12 Maintenance | Cron & notifications | nightly/weekly jobs | Summaries & emails generated |

## 3. Task Register (Detailed)
| ID | Task | Priority | Effort | Dependencies | Definition of Done |
|----|------|----------|--------|--------------|--------------------|
| T1 | Capture baseline performance | ⬛ | 15m | None | perf-baseline.json created |
| T2 | Env snapshot (critical vars) | 🔵 | 10m | T1 | env snapshot file committed |
| T3 | Backup active directory | ⬛ | 5m | T1 | backup diff identical |
| T4 | Create redesign skeleton | ⬛ | 10m | T3 | 11 files + guard headers |
| T5 | Add structure design test | 🔶 | 10m | T4 | test_structure_modules PASS |
| T6 | Migrate security core stub | 🔶 | 15m | T4 | stub loads; unit test PASS |
| T7 | Migrate options | 🔵 | 20m | T4 | options test PASS |
| T8 | Migrate core functions | 🔶 | 40m | T4 | whence audit unique |
| T9 | Migrate essential plugins | 🔶 | 30m | T6–T8 | no force rebuild; test PASS |
| T10 | Migrate dev env | 🔵 | 30m | T8 | SSH/Atuin behave unchanged |
| T11 | Merge aliases/keybindings | 🔵 | 20m | T8 | alias expansion parity |
| T12 | Implement completion-history | 🔶 | 25m | T8 | single compinit guard test PASS |
| T13 | Isolate UI prompt | 🔶 | 30m | T8 | prompt parity test PASS |
| T14 | Add perf monitoring hook | 🔵 | 20m | T8 | timing log entries present |
| T15 | Add advanced integrity async | 🔶 | 40m | T6,T8 | async test PASS; no TTFP delta |
| T16 | Performance A/B test | ⬛ | 15m | T9–T15 | ≥20% improvement |
| T17 | Promotion & tag | ⬛ | 5m | T16 | tag + rollback simulation |
| T18 | Final diff + metrics docs | 🔵 | 20m | T17 | final-report updated |
| T19 | Implement CI core workflow | ⬛ | 30m | T5–T13 | workflow green |
| T20 | Performance workflow & badge | 🔶 | 30m | T16 | badge JSON updated nightly |
| T21 | Security workflow | 🔵 | 25m | T15 | nightly scan email on fail |
| T22 | Pre-commit hook distribution | 🔶 | 10m | T5 | hook aborts on regression |
| T23 | zcompile pass (optional) | 🔵 | 30m | T17 | compiled modules produce ≤ baseline time |
| T24 | Plugin diff alert | 🔶 | 35m | T15 | diff alert test PASS |
| T25 | JSON schema validation | 🔵 | 25m | T24 | invalid registry blocks CI |
| T26 | Memory sampling harness | ⚪ | 25m | T14 | RSS logged & diffable |
| T27 | Structure drift guard test | 🔶 | 10m | T17 | CI fails on drift |
| T28 | Nightly cron integration | 🔵 | 20m | T20–T21 | nightly logs present |
| T29 | Weekly security cron | 🔵 | 15m | T21 | weekly log & email |
| T30 | Log rotation script | ⚪ | 15m | T28 | archives created |
| T31 | Health summary aggregator | 🔵 | 25m | T28–T29 | summary-latest.md committed |
| T32 | Regression sentinel script | 🔶 | 15m | T16 | exit non-zero >10% drift |

## 4. Metrics & Evidence
| Metric | Baseline Artifact | Target Artifact | Threshold |
|--------|-------------------|-----------------|-----------|
| Startup mean ms | perf-baseline.json | perf-current.json | -20% or better |
| File count active | manual count | structure-audit.json | =11 |
| Compinit runs | trace log | integration test output | =1 |
| Integrity async delay | timing log | timing log | > first prompt timestamp |
| Perf regression | quick perf JSON | badge delta | ≤5% daily drift |

## 5. Risk & Mitigation Matrix
| Risk | Trigger | Mitigation | Contingency |
|------|---------|-----------|------------|
| Hidden regression masked by variance | noisy timing | 10-run CI median & stddev tracking | require retest if stddev > 2x baseline |
| Async process crash silently | background failure | capture exit status + log | fallback synchronous scan |
| Over-consolidation reduces clarity | large module | keep size heuristics (<300 lines) | split by responsibility number slot remaining |
| Badge misreports due to missing baseline | file deleted | protect baseline file (chmod a-w) | reconstruct from backup metrics logs |

## 6. Testing Strategy (Summary)
See `../testing/strategy.md` for full taxonomy. Key guard tests: structure, compinit single-run, perf threshold, integrity deferred, async non-blocking, parity (aliases/prompt/history), regression sentinel.

## 7. Automation Hooks
| Hook | Purpose | Failure Action |
|------|---------|----------------|
| pre-commit | Fast tests + quick perf | Block commit |
| ci-core | Full category test matrix | Block merge |
| ci-performance | Drift detection + badge | Email + fail job |
| ci-security | Integrity & tamper tests | Email + fail job |
| nightly cron | Perf + light security summary | Email; no immediate block |
| weekly cron | Deep security & compdump refresh | Email; escalate if violations |

## 8. Acceptance / Exit Checklist
| Item | Status Marker |
|------|---------------|
| All core phases 1–9 complete | tags present |
| Performance improvement achieved | perf test PASS |
| Single compinit verified | integration log PASS |
| All enhancement tests green | CI matrix PASS |
| Maintenance automation active | cron logs + emails |

## 9. Deferred / Optional (Reassess Post-Promotion)
- Multi-shell (bash/fish) portability mapping
- Advanced security: signature-based plugin validation
- Performance flamegraph integration (zsh -x sampling)

## 10. Documentation Cross-Refs
| Topic | File |
|-------|------|
| Architecture | ../architecture/overview.md |
| Issues Review | ../review/issues.md |
| Completion Audit | ../review/completion-audit.md |
| Consolidation | ../consolidation/plan.md |
| Testing Strategy | ../testing/strategy.md |
| Final Report | ../redesign/planning/final-report.md |

## Appendix A: Tooling References
| Tool / Script | Purpose | Location | Notes |
|---------------|---------|----------|-------|
| commit-skeleton.zsh | Suggests branch + commit commands for a task | tools/commit-skeleton.zsh | Use `--dry` to preview |
| dry-run-promotion-check.zsh | Verifies readiness (baseline, backup, tests) pre-promotion | tools/dry-run-promotion-check.zsh | `--no-perf` to skip perf gate |
| generate-perf-badge.zsh | Produces shields.io JSON badge | tools/generate-perf-badge.zsh | Uses jq if available |
| run-nightly-maintenance.zsh | Aggregates perf + light security + email | tools/run-nightly-maintenance.zsh | Cron friendly |
| notify-email.zsh | Unified email or stdout fallback | tools/notify-email.zsh | Prefers neomutt -> mail -> stdout |
| minimal-completion-init.zsh | Single-run guarded compinit helper | tools/minimal-completion-init.zsh | Sets `_COMPINIT_DONE` |
| dry-run structure drift test | Permissive structural warning (design) | tests/style/phase06/test-structure-drift.zsh | Non-blocking pre-promotion |

[Back to Documentation Index](../README.md)

---
(End master improvement plan)
