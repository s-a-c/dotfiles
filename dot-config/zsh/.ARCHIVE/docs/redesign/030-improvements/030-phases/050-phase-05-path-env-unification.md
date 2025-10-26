# Phase 05: Path & Environment Unification (▲ P1)

Return: [Index](../../README.md) | Prev: [Phase 04 Variants & Finalizer](040-phase-04-styling-variants-and-finalizer.md) | Next: [Phase 06 Performance & Monitoring](phase-06-performance-and-monitoring.md)

Goal: Converge on a single, predictable PATH and core environment variable initialization strategy that is idempotent, deduplicated, and early enough for plugin resolution while deferring expensive probes. Reduce redundancy and eliminate drift across fragments.

Primary Tasks: TASK-MAJ-03 (unify PATH), TASK-MAJ-08 (earlier PATH dedup), TASK-MIN-08 (conditional LC_ALL), TASK-MIN-09 (single HISTFILE), plus related cleanup side quests.

## 1. Current Issues (From Findings)
- Multiple fragments append/prepend to PATH causing order churn.
- Dedup logic (if any) is inconsistent or late in startup.
- HISTFILE and locale exports appear in more than one place.
- Potential risk of unintentionally shadowing system binaries when user bin paths are repeatedly prepended.

## 2. Strategy Overview
1. Establish canonical early environment file (e.g. `.zshenv` or earliest sourced fragment) for deterministic base PATH.
2. Gather all path contributors (core system, package managers, language runtimes, user tools) into a declarative list.
3. Generate PATH once; apply dedup; export. Subsequent fragments MUST NOT modify PATH (enforced by guard function).
4. Provide helper `add_path_once <dir>` (rare exceptions) that logs if used post-lock.
5. Normalize environment exports (LC_ALL, LANG, HISTFILE) in a single place with conditional logic.

## 3. Hierarchical Task Breakdown
| Epic | Task | Subtasks | Effort | Impact | Status |
|------|------|----------|--------|--------|--------|
| Canonical Definition | Inventory existing PATH edits | Grep fragments for `PATH=` and `export PATH` | ⚡ | 🧹 | ⬜ |
|  | Declarative list file | `env/path-decl.zsh` array `PATH_SEGMENTS=(...)` | ⚡ | 🧹 | ⬜ |
|  | Build & export | Join with ':'; dedup preserving first occurrence | 🕒 | PERF | ⬜ |
| Dedup Logic | Implement dedup function | `_dedup_path` stable/first-wins algorithm | ⚡ | PERF | ⬜ |
|  | Measure before/after length | Log counts when DEBUG_PATH=1 | ⚡ | 🧹 | ⬜ |
| Path Locking | Add lock variable | `PATH_LOCKED=1` after construction | ⚡ | 🔧 | ⬜ |
|  | Guard mutation | Wrapper warns & ignores late modifications | ⚡ | 🧹 | ⬜ |
| Env Unification | Single HISTFILE export | Relocate to canonical env file; remove duplicates | ⚡ | 🧹 | ⬜ |
|  | Conditional LC_ALL/LANG | Only export if not already set by user or locale not C | ⚡ | 🧹 | ⬜ |
|  | Shell options grouping | Collocate related `setopt`/history controls for clarity | 🕒 | 🧹 | ⬜ |
| Testing | Path duplication test | Spawn shell; assert no repeated segments | ⚡ | PERF | ⬜ |
|  | Late mutation test | Attempt PATH add post-lock → expect warning & unchanged PATH | ⚡ | 🔧 | ⬜ |
|  | HISTFILE singular test | Grep startup trace for single HISTFILE definition | ⚡ | 🧹 | ⬜ |
| Tooling | Path diff script | `tools/path-audit.zsh` dumps pre/post arrays | ⚡ | 🧹 | ⬜ |
| Docs | Architecture update | Add Path & Env standard section | ⚡ | 🧹 | ⬜ |

## 4. PATH Construction Pseudocode
```zsh
# env/path-decl.zsh
PATH_SEGMENTS=( \
  /usr/local/sbin \
  /usr/local/bin \
  /usr/bin \
  /bin \
  "$HOME/bin" \
  "$HOME/.local/bin" \
  # Package managers (conditionally) \
  "$HOMEBREW_PREFIX/bin" \
  "$GOBIN" \
)
# Filter empties
local filtered=()
for p in "${PATH_SEGMENTS[@]}"; do [[ -n $p && -d $p ]] && filtered+=$p; done
# Dedup (first wins)
local seen=(); local out=()
for p in "${filtered[@]}"; do [[ -n ${seen[$p]:-} ]] && continue; seen[$p]=1; out+=$p; done
export PATH="${(j/:/)out}"; PATH_LOCKED=1
```

## 5. TDD Plan
| Test | Purpose | Criteria |
|------|---------|----------|
| test-path-dedup.zsh | Ensure no duplicates | awk uniqueness check passes |
| test-path-lock.zsh | Late mutation prevention | PATH unchanged; warning issued |
| test-histfile-single.zsh | Single HISTFILE export | Count == 1 |
| test-locale-conditional.zsh | Ensure LC_ALL not overriding user | If preset before shell, value preserved |

## 6. Implementation Sequence
| Step | Action | Commit Message |
|------|--------|---------------|
| 1 | Inventory existing PATH mutations | chore(env): inventory current PATH edits |
| 2 | Add path declaration file + build logic | feat(env): add declarative path builder with dedup |
| 3 | Introduce lock + guard | feat(env): add PATH lock and mutation guard |
| 4 | Consolidate HISTFILE & locale exports | refactor(env): unify HISTFILE and locale exports |
| 5 | Remove legacy scattered PATH edits | refactor(env): remove redundant PATH modifications |
| 6 | Add tests & audit tool | test(env): add path dedup and lock tests |
| 7 | Docs & plan progress | docs(env): document path/env unification completion |

## 7. Rollback Strategy
| Failure | Symptom | Rollback |
|---------|---------|----------|
| Missing essential bin | Command not found | Re-add segment via whitelist file; re-run |
| Over-aggressive dedup | Needed variant path removed | Add targeted allow-after-lock function |
| Locale regression | Sorting/encoding issues | Restore previous locale exports from backup |

## 8. Metrics
| Metric | Target |
|--------|--------|
| Duplicate PATH entries | 0 |
| PATH segments (post-filter) | Within ±2 of baseline unique count |
| Startup delta from path logic | < +10ms |

## 9. Documentation Updates
| Doc | Change |
|-----|--------|
| architecture/overview.md | Note unified path builder |
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Update TASK-MAJ-03/08, MIN-08/09 |

## 10. Exit Checklist
- [ ] Single PATH build early
- [ ] No duplicate segments
- [ ] Guard prevents late mutations
- [ ] HISTFILE single definition
- [ ] Locale exports conditional
- [ ] Tests green twice
- [ ] Docs updated & plan advanced

---
Generated: 2025-08-24
