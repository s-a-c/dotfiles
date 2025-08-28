# Testing Strategy & Validation Framework

Return: [Index](../README.md) | See: [Improvement Plan](../030-improvements/010-comprehensive-improvement-plan.md) | [Completion System](../010-architecture/030-completion-system.md)
Generated: 2025-08-23

## 0. Legend (Shared)
- Status: ⬜ NOT_STARTED | 🔄 IN_PROGRESS | ✅ COMPLETE | ⛔ BLOCKED | ⏸️ DEFERRED
- Priority: ❗ Critical | ▲ Major | ▪ Minor
- Effort: ⚡ QF | 🕒 S | ⏳ M | 🧱 L
- Impact: 🚀 PERF | 🧹 MAINT | 🔧 FUNC | 🔐 SEC | 🎨 UX

## 1. Goals
Ensure reliability, performance, and ordering guarantees of the modular ZSH configuration with automated and manual tests that prevent regressions (especially single `compinit`, canonical dump path, correct phase ordering, PATH uniqueness, and styling timing).

## 2. Test Categories
| Category | Focus | Key Assertions | Phase |
|----------|-------|----------------|-------|
| Startup / Initialization | Order, single compinit, PATH/fpath state | One compinit; canonical dump; no dup PATH | Phase 01 |
| Configuration Loading | Fragments sourced once & ordered | Expected list; no early styling | Phase 01 |
| Function & Alias Behavior | Core helper correctness | Idempotent PATH, functions return success | Ongoing |
| Completion System | Dump rebuild heuristics; locks | Rebuild on age; skip when fresh | Phase 01 |
| Styling Extraction | Lossless module extraction | Pre vs post zstyle snapshot == | Phase 02 |
| Styling Palette/API | Palette name substitution; API safety | All literals replaced; snapshot stable | Phase 03 |
| Styling Variants & Fallback | Variant diff restricted to palette | Fallback triggers; variant switch passes | Phase 04 |
| PATH & Env Hygiene | Unified logic / duplicates removed | Early uniqueness; no late drift | Phase 05 |
| Performance Regression | Timing budgets (cold/warm) | Within tolerance windows | Multi |
| Security / Hygiene | Hook sanitization scoped | Non-warp hooks preserved | Phase 01 |
| Documentation Sync | Docs list matches fs | Added/removed files flagged | Continuous |

## 3. Tooling & Harness
| Layer | Approach |
|-------|----------|
| Orchestration | Shell scripts in `tests/` (pattern: test-*.zsh) |
| Timing | `zsh -i -c exit` wrapped with `time` or `zmodload zsh/zprof` (optional) |
| Parallelism | `env ZSH_TEST_PARALLEL=1` + background subshell spawns |
| Snapshot Diff | Persist JSON/YAML snapshot of ordering & zstyles for comparison |
| Metrics Logging | Append results to `logs/TEST-METRICS-<date>.log` |

## 4. Core Automated Tests (Proposed Files)
| File | Purpose | Status | Phase |
|------|---------|--------|-------|
| tests/startup/test-single-compinit.zsh | Assert single compinit | PLANNED | 01 |
| tests/startup/test-ordering.zsh | Validate sourcing order | PLANNED | 01 |
| tests/completion/test-rebuild-heuristics.zsh | Age vs skip logic | PLANNED | 01 |
| tests/completion/test-lock-contention.zsh | Concurrency safety | PLANNED | 01 |
| tests/styling/test-style-equivalence.zsh | Extraction parity | PLANNED | 02 |
| tests/styling/test-style-palette-mapping.zsh | Palette substitution coverage | PLANNED | 03 |
| tests/styling/test-style-api-idempotent.zsh | API idempotency | PLANNED | 03 |
| tests/styling/test-style-variant-switch.zsh | Variant diffs limited | PLANNED | 04 |
| tests/styling/test-style-fallback-lowcolor.zsh | Low-color fallback | PLANNED | 04 |
| tests/env/test-path-dedup.zsh | Path uniqueness early/late | PLANNED | 05 |
| tests/perf/test-startup-timing.zsh | Timing guardrails | PLANNED | Multi |
| tests/security/test-warp-hook-safety.zsh | Warp sanitization scope | PLANNED | 01 |
| tests/docs/test-doc-sync.zsh | Docs/fs sync | PLANNED | Continuous |

## 5. Example Test Patterns
### Single compinit Trace Technique
1. Run shell with `set -x` and PS4 including `$FUNCNAME`.
2. Grep for `compinit(` occurrences.
3. Expect count == 1.

Pseudo-snippet:
```
#!/usr/bin/env zsh
PS4='+TRACE+ %N:%i:%f '> trace.log
set -x
zsh -i -c 'echo READY' &> trace.out
set +x
grep -c 'compinit' trace.out | read count
(( count == 1 )) || {     zsh_debug_echo "FAIL duplicate compinit ($count)"; exit 1 }
echo "PASS single compinit"
```

### Rebuild Heuristic
- `touch -mt 202401010000` canonical dump -> expect rebuild log phrase.
- Immediately rerun → expect fast path (no rebuild log).

### Lock Contention
Run two background shells simultaneously and ensure:
- Only one prints "Rebuilding completion system".
- Both exit with success, dump not corrupted (non-zero size, valid first line pattern).

## 6. Expected Baseline Metrics
| Metric | Target | Failure Threshold |
|--------|--------|-------------------|
| Cold startup (ms) | < 700ms (example placeholder) | > 900ms |
| Warm startup (ms) | < 450ms | > 600ms |
| Compinit count | 1 | != 1 |
| PATH duplicates | 0 | > 0 |
| Dump rebuild interval | >= configured days unless forced | Rebuild when not expected |

(Note: Replace placeholder times after first capture with empirical values + 20% tolerance.)

## 7. Manual Verification Checklist
| Step | Check | Pass Criteria |
|------|-------|---------------|
| 1 | `echo $ZSH_COMPDUMP` | Matches canonical central path |
| 2 | `ls -1 $ZSH_COMPDUMP*` | Only canonical dump (+ optional .zwc) |
| 3 | `completion-status` | Shows 0 old .zcompdump files |
| 4 | Launch parallel shells | No error messages; consistent dump size |
| 5 | Run `rebuild-completions` | Dump timestamp increases; compiled file updated |
| 6 | Inspect prompt rendering | Styles applied; no missing colors |

## 8. Cross-Platform Strategy
- Guard Linux-only checks (e.g., `/run/user/<uid>`) with presence tests.
- Provide stubs for macOS-exclusive commands in Linux CI (e.g., `scutil`).
- Abstract OS queries into helper function for test reuse.

## 9. Integration with Task Plan
| Task | Test Tie-In | Phase |
|------|-------------|-------|
| TASK-CRIT-01 | test-single-compinit | 01 |
| TASK-CRIT-03 | test-ordering, test-path-dedup | 01 / 05 |
| TASK-MAJ-02 | test-style-equivalence.zsh | 02 |
| TASK-MAJ-11 | test-style-palette-mapping.zsh | 03 |
| TASK-MAJ-12 | test-style-api-idempotent.zsh | 03 |
| TASK-MAJ-13 | test-style-variant-switch.zsh, test-style-fallback-lowcolor.zsh | 04 |
| TASK-MAJ-06 | test-rebuild-heuristics.zsh | 01 |
| TASK-MAJ-09 | test-rebuild-heuristics.zsh | 01 |
| TASK-MAJ-10 | test-single-compinit.zsh | 01 |
| TASK-MIN-07 | test-style-palette-mapping.zsh | 03 |
| TASK-MIN-11 | style-equivalence (phase 4 snapshot diff) | 04 |
| TASK-MIN-12 | test-style-variant-switch.zsh | 04 |
| TASK-MIN-13 | test-style-fallback-lowcolor.zsh | 04 |
| TASK-MIN-06 | test-lock-contention.zsh | 01 |
| TASK-MIN-05 | extend rebuild heuristics test | 01 |

## 12. Exit Criteria for Test Phase Completion
| Criterion | Definition | Phase |
|-----------|------------|-------|
| Minimal suite passing | All phase tests green | Each phase end |
| Metrics persisted | Added to logs/TEST-METRICS* | Continuous |
| Style snapshot parity | No diff after extraction | 02 |
| Palette substitution completeness | No raw RGB codes left (except palette core) | 03 |
| Variant diff isolation | Only palette lines differ | 04 |
| PATH uniqueness proven | Dedup counts 0 both early/late | 05 |
| Single compinit invariant | Count=1 across three runs | 01+ |

---
