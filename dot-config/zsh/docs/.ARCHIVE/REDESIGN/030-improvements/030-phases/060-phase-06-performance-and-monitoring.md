# Phase 06: Performance & Monitoring (▲ P1)

Return: [Index](../../README.md) | Prev: [Phase 05 Path & Env Unification](050-phase-05-path-env-unification.md) | Next: *N/A*

Goal: Establish reliable, automated performance + behavioral monitoring around startup time, completion rebuild frequency, style system integrity, and regression detection (safety nets for previous phases). Implement lightweight telemetry (local only) and test harnesses that fail fast on perf drift or functional regressions.

Primary Tasks (Mapping): TASK-MAJ-10 (single compinit trace test), TASK-MIN-06 (lock contention test), plus expanded KPI capture from Plan §6 and style snapshot tests (TASK-MIN-11 after earlier phases). Complements completion, styling, path work with guardrails.

## 1. Scope Overview
| Area | Metric | Tooling | Threshold |
|------|--------|---------|-----------|
| Startup (cold) | wall ms | timing harness wrapper around `zsh -i -c exit` | - target improvements preserved |
| Startup (warm) | wall ms | second invocation w/ cached compdump | drift < +10% |
| compinit count | occurrences | PS4 trace grep | must equal 1 |
| Compdump reuse | rebuild ratio | test toggling timestamps | only aged dumps rebuild |
| Style system | snapshot diff lines | before/after finalizer apply | 0 (default variant) |
| Variant overhead | ms added | trace timestamp around finalizer | < +15ms |
| PATH dedup | duplicates | parse PATH into set | 0 |

## 2. Hierarchical Task Breakdown
| Epic | Task | Subtasks | Effort | Impact | Status |
|------|------|----------|--------|--------|--------|
| Timing Harness | Create perf script | `tools/perf-capture.zsh` capturing cold/warm metrics JSON | ⚡ | 🚀 | ⬜ |
|  | Baseline store | Keep last N snapshots in `logs/perf/` with date | ⚡ | 🧹 | ⬜ |
| Completion Metrics | Single compinit test | Reuse Phase 01 skeleton; integrate into CI grouping | ⚡ | 🚀 | ⬜ |
|  | Lock contention test | Parallel shell spawn; detect single rebuild | 🕒 | 🚀 | ⬜ |
| Style Integrity | Snapshot diff test (final) | Ensure default variant unchanged | ⚡ | 🎨 | ⬜ |
|  | Variant timing | Add finalizer duration export & assert thresholds | ⚡ | PERF | ⬜ |
| PATH Verification | Dedup test | Ensure zero duplicates persisted | ⚡ | 🧹 | ⬜ |
|  | Mutation guard test | Attempt late PATH edit fails | ⚡ | 🔧 | ⬜ |
| Reporting | Aggregate report script | `tools/health-check.zsh` extended to include perf | 🕒 | 🧹 | ⬜ |
|  | Drift alert | If cold startup > baseline + 15%, emit warning | ⚡ | 🚀 | ⬜ |
| Logging | Structured JSON | Use `jq`-friendly lines for perf entries | 🕒 | 🧹 | ⬜ |
| Docs | Add monitoring section | Document metrics + thresholds | ⚡ | 🧹 | ⬜ |

## 3. Performance Capture Script (Concept)
```zsh
#!/usr/bin/env zsh
set -euo pipefail
OUT_DIR=${ZDOTDIR:-$HOME/.config/zsh}/logs/perf
mkdir -p $OUT_DIR
stamp=$(date +%Y%m%dT%H%M%S)
# Cold
cold_ms=$({ time zsh -ic 'exit' >/dev/null 2>&1 } 2>&1 | awk '/real/ {print $2}')
# Warm (assumes compdump now cached)
warm_ms=$({ time zsh -ic 'exit' >/dev/null 2>&1 } 2>&1 | awk '/real/ {print $2}')
cat > $OUT_DIR/$stamp.json <<EOF
{"timestamp":"$stamp","cold":"$cold_ms","warm":"$warm_ms"}
EOF
# Optional drift check vs latest baseline
```
(Note: Convert shell `time` to ms via parsing or use `zmodload zsh/datetime` for higher precision.)

## 4. Test Additions (Sketches)
```bash
# tests/perf/test-single-compinit.zsh
set -euo pipefail
PS4='+TRACE+ %N:%i ' zsh -xic 'echo READY' &> $TMPDIR/trace.$$ || true
(( $(grep -c 'compinit' $TMPDIR/trace.$$) == 1 )) || {     zsh_debug_echo FAIL; exit 1; }
```

```bash
# tests/perf/test-lock-contention.zsh
set -euo pipefail
run(){ zsh -ic 'echo RUN' >/dev/null 2>&1; }
run & run & wait
# Inspect logs or compdump mtime count; ensure no race artifacts
```

## 5. Implementation Sequence
| Step | Action | Commit Message |
|------|--------|---------------|
| 1 | Add perf capture script | feat(perf): add startup perf capture tool |
| 2 | Add single compinit + lock tests | test(perf): add completion perf guard tests |
| 3 | Add style snapshot final test | test(perf): add final style snapshot guard |
| 4 | Extend health-check with perf summary | feat(perf): integrate perf summary into health-check |
| 5 | Add drift detection & alert | feat(perf): add baseline drift alert (+15%) |
| 6 | Docs update & phase exit | docs(perf): document monitoring framework |

## 6. Rollback Strategy
| Failure | Symptom | Rollback |
|---------|---------|----------|
| False positive drift | Frequent alerts without real change | Increase threshold or median baseline calc |
| Timing noise | Unstable metrics | Add 5-run average; store raw samples |
| Test flakiness (race) | Sporadic lock contention fail | Increase retry or add jitter; investigate serialization |

## 7. Metrics Enhancements (Optional Next)
| Enhancement | Value |
|------------|-------|
| p95 startup tracking | Smooths noise |
| Flamegraph integration | Deep dive slowdowns |
| Async plugin load trace | Identify deferred cost |

## 8. Exit Checklist
- [ ] Perf capture script producing JSON records
- [ ] Single compinit test green
- [ ] Lock contention test reliable (≥5 runs)
- [ ] Style snapshot + variant timing tests green
- [ ] Drift detection warns only on real regression
- [ ] Documentation updated & plan advanced

## 9. Documentation Updates
| Doc | Change |
|-----|--------|
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Mark TASK-MAJ-10 progress |
| testing/strategy.md | Add performance harness section |
| architecture/completion-system.md | Add monitoring note |

---
Generated: 2025-08-24
