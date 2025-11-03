# Comprehensive Testing Strategy
Date: 2025-08-31
Status: Expanded (Supersedes condensed copy)

## 1. Purpose & Scope
Provide exhaustive, automated assurance that the ZSH configuration redesign (pre & post plugin phases) achieves: performance targets, structural minimalism, functional parity, single compinit execution, deferred security validation, and safe promotion with rollback. Covers legacy freeze, redesign skeleton, migration, and post-promotion stabilization.

## 2. Test Taxonomy
| Layer | Purpose | Example Artifacts | Fail Impact |
|-------|---------|-------------------|-------------|
| Design | File counts, naming, ordering, sentinel guards | structure tests phase03 | Structural regression blocks merge |
| Unit | Pure functions / lazy wrappers / hash scheduling | future tests/unit/*.zsh | Logic defect localized |
| Feature | User-visible commands & wrappers (e.g., plugin_security_status) | tests/feature/*.zsh (planned) | User workflow break |
| Integration | End-to-end startup (toggles, compinit, pre/post selection) | run-all-tests.zsh harness | Startup flow mismatch |
| Performance | Startup timing, segment deltas, regression detection | tools/perf-capture.zsh, perf-regression-check.zsh | Perf gate failure |
| Security | Integrity baseline & deferred deep scan state | future tests/security/*.zsh | Security regression |
| Maintenance | Drift (inventory, checksums) + docs governance | phase03 drift & checksum tests, docs lints | Baseline mutation |

## 3. Guard & State Variables
| Variable | Type | Meaning | Test Coverage |
|----------|------|---------|---------------|
| _COMPINIT_DONE | sentinel int | Ensures compinit executed once | compinit audit tests (pre + future post) |
| _ASYNC_PLUGIN_HASH_STATE | enum(IDLE|QUEUED|RUNNING|COMPLETED|FAILED) | Deferred integrity lifecycle | security tests (future) |
| ZSH_ENABLE_PREPLUGIN_REDESIGN | flag | Toggle redesigned pre-plugin directory | integration toggle tests |
| ZSH_ENABLE_POSTPLUGIN_REDESIGN | flag | Toggle redesigned post-plugin directory | integration toggle tests |
| ZSH_REDESIGN | umbrella flag (future) | Enables both redesign halves | promotion guard (future) |
| _LOADED_* | sentinel per file | Prevent double sourcing & ensures idempotency | structure tests |

## 4. Structural Validation Rules
| Rule | Pre-Plugin | Post-Plugin | Enforcement |
|------|-----------|------------|-------------|
| File Count | 8 (00,05,10,15,20,25,30,40-reserved) | 11 (00..90) | structure tests |
| Numeric Ascending | Strict monotonic (leading zero tolerated) | Strict monotonic | structure tests |
| Reserved Slot | 40-pre-plugin-reserved present | N/A | pre-plugin structure test |
| Sentinels | Each file defines/sets _LOADED_* or guard block | Same | future sentinel audit |
| Drift | Legacy inventories exact match snapshots | Same | drift tests |

## 5. Performance Methodology
| Aspect | Approach | Tool | Threshold |
|--------|---------|------|-----------|
| Baseline Capture | 10 filtered runs, discard outliers (IQR) | tools/perf-capture.zsh | Establish mean/stddev |
| Redesign Evaluation | A/B toggles off/on (pre then post) | perf-capture + diff | ≥20% total improvement required |
| Regression Gate | Compare current to stored baseline mean | perf-regression-check.zsh | FAIL if >5% slower |
| Segment Timing | Pre vs Post plugin time slices (hooks) | 70-performance-monitoring (future) | Post-plugin ≤500ms |
| Async Impact | Prompt time minus start vs with async enabled | perf capture + hook logs | No increase in prompt TTFP >1% |

## 6. Compinit Assurance
| Test | Goal | Mechanism | Pass Criteria |
|------|------|-----------|--------------|
| test-preplugin-no-compinit | Ensure no premature compinit in pre redesign skeleton | Source redesign pre path only | No compinit run; sentinel absent |
| future test-postplugin-compinit | Ensure exactly one compinit after redesign toggle | Launch full shell w/ redesign | _COMPINIT_DONE=1 and single zcompdump write |
| completion-order audit | Confirm compinit after fpath finalization | Parse debug log markers | Ordering invariant holds |

## 7. Security & Integrity Tests (Planned)
| Scenario | Expected State | Verification |
|----------|----------------|-------------|
| Startup pre-prompt | _ASYNC_PLUGIN_HASH_STATE in IDLE or QUEUED | Check variable before first prompt |
| Post first prompt + delay | State transitions to RUNNING → COMPLETED | Poll with timeout (≤5s) |
| Hash mismatch simulation | Report enumerates diff & sets FAILED | Inject modified plugin file copy |
| User command query | plugin_security_status outputs human summary | Command exit 0 & structured output |

## 8. Drift & Immutability
| Artifact | Freeze Mechanism | Test |
|----------|------------------|------|
| preplugin-inventory.txt | Line list (excludes comments) | test-preplugin-drift |
| postplugin-inventory.txt | Same | test-postplugin-drift |
| postplugin-disabled-inventory.txt | Full disabled archive snapshot | test-postplugin-disabled-drift |
| legacy-checksums.sha256 | SHA256 of .zshrc + legacy dirs | test-legacy-checksums |

Checksum mismatch or inventory deviation = immediate CI failure.

## 9. Toggle & Promotion Testing
| Phase | Toggles | Required Tests |
|-------|---------|---------------|
| Pre-skeleton | none | Baseline perf + drift |
| Pre-plugin A/B | ZSH_ENABLE_PREPLUGIN_REDESIGN | perf A/B + structure + drift |
| Post-plugin A/B | Both toggles | perf delta + post structure + drift |
| Promotion | ZSH_REDESIGN (future) | Promotion guard script (all gates) |

## 10. Tooling Summary
| Tool Script | Purpose |
|-------------|---------|
| run-all-tests.zsh | Orchestrates all tests with logging |
| perf-capture.zsh | Timed launch harness (N runs) |
| perf-regression-check.zsh | Compare captured metrics vs baseline |
| verify-legacy-checksums.zsh | Ensure frozen set unchanged |
| (future) generate-legacy-checksums.zsh | Rebuild checksum snapshot at promotion |
| generate-structure-audit.zsh | Machine-readable structure report |
| docs-governance-lint.zsh | Link & presence validation |

## 11. Reporting & Artifacts
| Artifact | Format | Source |
|----------|--------|--------|
| perf-baseline.json | JSON (mean,stddev,runs) | perf-capture baseline mode |
| perf-current.json | JSON | perf-capture on branch |
| structure-audit.json | JSON (counts, files) | generate-structure-audit.zsh |
| test-results-*.log | Text | run-all-tests harness |
| legacy-checksums.sha256 | Text (SHA256 lines) | generator script |

## 12. Failure Handling Workflow
1. Detect failure (CI log / local run).
2. Classify: Structural | Performance | Security | Drift | Functional.
3. Gather artifact set: latest perf JSON, structure audit, failing test log excerpt.
4. Bisect or module toggle isolation (binary enabling of redesign sets) for perf/security.
5. Open issue with classification label and attach artifacts.
6. Patch; re-run targeted tests first, then full suite.

## 13. Coverage Roadmap
| Milestone | New Tests Added |
|-----------|-----------------|
| Phase Skeleton | Structure + drift + checksums |
| Phase Pre-Plugin Core | Path-safety unit tests (planned) |
| Phase Lazy Framework | Lazy dispatcher unit tests |
| Phase Post-Plugin Core | Compinit single-run & options parity |
| Phase Async Security | State machine transitions & failure injection |
| Promotion | Promotion guard meta-test (aggregates gates) |
| Post-Promotion | Stability & memory sampling (optional) |

## 14. Performance Test Configuration
| Parameter | Quick Mode | Full Mode |
|-----------|-----------|-----------|
| Runs | 3 | 10 |
| Warmup Discard | 0 (fast feedback) | 1 optional |
| Outlier Filter | None | IQR (exclude beyond 1.5×IQR) |
| Output File | perf-quick.json | perf-current.json |
| Gate Applied | Advisory only | Enforced |

## 15. Metrics Acceptance Gates
| Metric | Gate | Rationale |
|--------|------|-----------|
| startup_mean_ms | ≤baseline*0.80 | Hard success criterion |
| regression_delta | ≤+5% vs previous promoted | Prevent silent regressions |
| post_plugin_cost_ms | ≤500 | Maintain minimal post layer weight |
| compinit_count | 1 | Avoid duplicate expensive init |
| async_scan_delay_ms | >0 | Ensure deferral is real |

## 16. Logging Conventions
| Marker | Location | Meaning |
|--------|----------|---------|
| [pre-plugin] | Pre redesign files | Stage identification |
| [post-plugin] | Post redesign loader branch | Toggle path active |
| PERF_START / PERF_PROMPT | Hook (future 70 module) | Time boundaries |
| SECURITY_ASYNC_QUEUE | 80 module | Deferred scan queued |

Tests parse logs for ordering & timing assertions.

## 17. Risk-Based Prioritization
Critical: Single compinit, baseline drift, checksum integrity, performance regression.
Medium: Async scan timing, lazy loader correctness.
Low: Cosmetic splash presence, alias grouping.

## 18. Open Test Gaps (To Be Implemented)
| Gap | Planned Test ID | Target Phase |
|-----|-----------------|--------------|
| Lazy node first-call loads nvm | UT-LAZY-NODE-001 | Pre-plugin lazy framework |
| SSH agent no duplicate process | FT-SSH-AGENT-001 | Pre-plugin merge |
| plugin_security_status states | SEC-STATUS-001 | Async validation phase |
| Promotion guard aggregate | GOV-PROMOTE-001 | Promotion |
| Memory/RSS snapshot | PERF-MEM-001 | Post-promotion |

## 19. Exit Criteria (Testing Perspective)
All gates pass (Section 15), drift & checksum tests green, structural file counts stable, security deferred scan verified non-blocking, documentation updated, promotion guard test passes.

## 20. Cross-References
| Topic | File |
|-------|------|
| Implementation Plan | implementation-plan.md |
| Rollback Decision Tree | rollback-decision-tree.md |
| Gating Flags | gating-flags.md |
| Post-Plugin Analysis | post-plugin-redesign-analysis.md |
| Diagrams | diagrams.md |
| Baseline Metrics Plan | baseline-metrics-plan.md |

---
**Navigation:** [← Previous: Implementation Entry Criteria](implementation-entry-criteria.md) | [Next: Rollback Decision Tree →](rollback-decision-tree.md) | [Top](#) | [Back to Index](../README.md)

---
(End comprehensive testing strategy)
