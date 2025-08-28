# Phase 02: Styling Modularization – Extraction (▲ P1)

Return: [Index](../../README.md) | Prev: [Phase 01 Completion Cleanup](010-phase-01-completion-core-cleanup.md) | Next: [Phase 03 Palette & API](030-phase-03-styling-palette-and-api.md)

Goal: Extract the monolithic styling (zstyle) definitions into logically separated style module files (still direct zstyle usage) under `40-styles/` while preserving exact behavior.

## 1. Hierarchical Task Breakdown
| Epic | Task | Subtasks | Effort | Impact | Status |
|------|------|----------|--------|--------|--------|
| File layout scaffolding | Create `40-styles/` dir | Add placeholder modules (completion, matching, git, process, fzf, overrides) | ⚡ | 🧹 | ⬜ |
|  | Legacy backup | Move original monolithic file to `.legacy` with timestamp | ⚡ | 🧹 | ⬜ |
| Logical grouping | Completion core extraction | Copy only completion behavioral zstyles → `20-completion-styles.zsh` | 🕒 | 🧹 | ⬜ |
|  | Matching styles | Move matcher-list, accept-exact, menu select → `25-completion-matching.zsh` | 🕒 | 🧹 | ⬜ |
|  | Git user-commands | Move git zstyle user-commands list → `30-git-styles.zsh` | ⚡ | 🧹 | ⬜ |
|  | Process / system | Move process list-colors, processes tags → `35-process-styles.zsh` | 🕒 | 🧹 | ⬜ |
|  | fzf-tab overrides | Isolate fzf-tab selectors → `40-fzf-tab-styles.zsh` | ⚡ | 🧹 | ⬜ |
|  | Prompt overrides | p10k specific styling to `70-p10k-overrides.zsh` | ⚡ | 🎨 | ⬜ |
| Integrity | Preserve order semantics | Insert numeric prefixes mirroring original evaluation dependencies | ⚡ | 🔧 | ⬜ |
|  | Stamp each module | Header comments: origin lines hash (sha256 snippet) for traceability | 🕒 | 🧹 | ⬜ |
| Verification | Style equivalence snapshot | Pre-extraction `zstyle -L` snapshot baseline | ⚡ | 🔧 | ⬜ |
|  | Post-extraction snapshot | Diff vs baseline: zero diff expected | ⚡ | 🔧 | ⬜ |
|  | Add `test-style-equivalence.zsh` (temporary) | Fails if diff non-empty | ⚡ | 🚀 | ⬜ |

## 2. TDD Plan
| Test | Purpose | Pre-State | Post-State |
|------|---------|----------|-----------|
| test-style-equivalence.zsh | Ensure extraction is lossless | Fails (no baseline) | Pass (no diff) |
| test-load-order-smoke.zsh | Verify modules sourced after plugins | Absent | Pass once modules present |

### test-style-equivalence Skeleton
```bash
#!/usr/bin/env zsh
set -euo pipefail
BASELINE="$ZDOTDIR/saved_zstyles.baseline"
CURRENT="$ZDOTDIR/saved_zstyles.current"
# Collect if missing (first run establishes baseline)
if [[ ! -f $BASELINE ]]; then
  zstyle -L >| $BASELINE
      zsh_debug_echo "Baseline created; re-run for comparison"; exit 1
fi
zstyle -L >| $CURRENT
diff -u $BASELINE $CURRENT &&     zsh_debug_echo "PASS style equivalence" || {     zsh_debug_echo "FAIL style diff"; exit 1; }
```

## 3. VCS / Branch Strategy
| Step | Git Action | jj Mirror | Commit Message |
|------|-----------|-----------|----------------|
| 1 | `git switch -c phase02-styling-extraction` | `jj branch create phase02-styling` | chore(styling): scaffold 40-styles directory |
| 2 | Add legacy backup + baseline snapshot | `jj describe -m "chore(styling): backup legacy monolithic styling"` | chore(styling): backup legacy styling block |
| 3 | Extract completion + matching modules | `git commit -m 'refactor(styling): extract completion & matching modules'` | refactor(styling): extract completion & matching |
| 4 | Extract git/process/fzf/prompt modules | ... | refactor(styling): extract git/process/fzf/prompt modules |
| 5 | Add equivalence test & baseline | ... | test(styling): add style equivalence harness |
| 6 | Snapshot diff verification pass | ... | chore(styling): confirm extraction parity |
| 7 | Docs update (phase progress) | ... | docs(styling): document Phase 02 extraction |

## 4. Rollback Strategy
| Issue | Detection | Rollback |
|-------|-----------|----------|
| Missing style segment | Diff shows removed lines | Restore from legacy file selective block |
| Ordering regression | Completion behavior changed | Temporarily source legacy file before modules |

## 5. Metrics
| Metric | Target |
|--------|--------|
| Style diff lines | 0 |
| Startup styling parse delta | ±10ms |

## 6. Documentation
| Doc | Update |
|-----|--------|
| styling-architecture.md | Mark Phase 02 complete section when done |
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Update TASK-MAJ-02 progress |
| [Script Consolidation Plan](../020-script-consolidation-plan.md) | Note extraction milestone |

## 7. Exit Checklist
- [ ] Modules created & sourced in correct order
- [ ] Equivalence test green twice consecutively
- [ ] Legacy file retained (.legacy) for Phase 03 reference
- [ ] Plan & styling architecture docs updated

## 8. Appendix A – Module Header Template
```zsh
# Module: 40-styles/20-completion-styles.zsh
# Source: legacy 05-completion-finalization.zsh lines 15-120 (sha256: <short>)
# Phase: 02 extraction
# NOTE: Direct zstyle calls; will convert to registration Phase 03
```

## 9. Appendix B – Commit Template
```text
refactor(styling): extract <domain> styles

Context:
- Origin: legacy monolithic style file
- Domain: <domain>
- Verification: style equivalence diff = 0

Refs: TASK-MAJ-02
```

---
Generated: 2025-08-24
