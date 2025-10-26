# Phase 03: Styling Palette & Registration API (▲ P1)

Return: [Index](../../README.md) | Prev: [Phase 02 Styling Extraction](020-phase-02-styling-modularization-extraction.md) | Next: [Phase 04 Variants & Finalizer](phase-04-styling-variants-and-finalizer.md)

Goal: Introduce a palette abstraction + style registration API to replace direct `zstyle` calls, enabling theme variants, low‑color fallbacks, and diffable snapshots while keeping functional parity with Phase 02 output.

Primary Tasks (Plan Mapping): TASK-MAJ-11, TASK-MAJ-12, TASK-MAJ-13 (prep groundwork), TASK-MIN-07 (palette tokens), TASK-MIN-11 (future snapshot test placeholder).

## 1. Hierarchical Task Breakdown
| Epic | Task | Subtasks | Effort | Impact | Status |
|------|------|----------|--------|--------|--------|
| Palette Core | Define palette schema | Decide variable naming (`PALETTE_<GROUP>_<NAME>`); doc comments | 🕒 | 🧹 | ⬜ |
|  | Seed base palette | Extract color codes from legacy styles → map to tokens | 🕒 | 🧹 | ⬜ |
|  | Introduce indirection | Replace literals in style modules with references (sed script assist) | ⏳ | 🧹 | ⬜ |
| Registration API | API function scaffold | `register_style <domain> <key> <value>` storing declarative map | ⚡ | 🧹 | ⬜ |
|  | Deferred application layer | Build `apply_registered_styles` that emits `zstyle` lines in stable order | 🕒 | PERF | ⬜ |
|  | Collision detection | Warn (stderr) on duplicate domain+key unless identical value | ⚡ | 🧹 | ⬜ |
| Migration | Wrap existing modules | Convert each extracted module to use `register_style` instead of direct `zstyle` | ⏳ | 🧹 | ⬜ |
|  | Legacy shim | Provide function translating old `zstyle` lines (Phase 02) → API for rollback | ⚡ | 🔧 | ⬜ |
| Integrity | Snapshot baseline (API) | Capture `zstyle -L` after API migration; diff vs Phase 02 baseline = 0 | ⚡ | 🔧 | ⬜ |
|  | Order determinism test | Ensure emitted order stable (sorted by domain/key) | ⚡ | 🧹 | ⬜ |
| Tooling | Script: extract colors | `tools/style-extract-palette.zsh` builds draft mapping with frequency counts | 🕒 | 🧹 | ⬜ |
|  | Validation script | `tools/style-validate.zsh` checks for stray literals not tokenized | ⚡ | 🧹 | ⬜ |
| Testing | API unit test | Register + apply → grep expected style; idempotent re-run | ⚡ | 🔧 | ⬜ |
|  | Collision test | Two different values same key → non-zero exit (or warning mode) | ⚡ | 🔧 | ⬜ |
| Docs | Architecture update | Add API lifecycle & order guarantees to styling-architecture | ⚡ | 🧹 | ⬜ |

## 2. API Contract (Initial)
Inputs:
- register_style <domain> <key> <value>
State:
- In-memory associative array (domain:key → value)
Outputs:
- Application phase emits `zstyle ':completion:*:<key>' <value>` (exact existing patterns preserved)
Error Modes:
- Duplicate conflicting entry → warning + retain first (non-fatal) Phase 03; escalate to error in Phase 04.
Success Criteria:
- Post-apply snapshot identical to Phase 02 snapshot.

## 3. TDD Plan
| Test | Purpose | Pre-State | Post-State |
|------|---------|----------|-----------|
| test-style-api-basic.zsh | Ensure register/apply results in correct `zstyle -L` line | Absent | Pass |
| test-style-api-idempotent.zsh | Second apply does not duplicate or reorder | N/A | Pass |
| test-style-api-collision.zsh | Conflicting registration triggers warning | N/A | Pass (warn) |
| test-style-snapshot-equiv.zsh | Baseline equivalence vs Phase 02 | Fails (no API) | Pass |

## 4. Implementation Sequence
| Step | Action | Commit Message |
|------|--------|---------------|
| 1 | Add palette schema doc + empty file | docs(styling): introduce palette schema draft |
| 2 | Create register/apply functions (no migration) | feat(styling): add style registration API scaffolding |
| 3 | Tool to extract color literals | chore(styling): add palette extraction helper |
| 4 | Seed palette + map highest frequency literals | feat(styling): seed base palette tokens |
| 5 | Migrate one module (completion) to API | refactor(styling): migrate completion styles to registration API |
| 6 | Migrate remaining modules | refactor(styling): migrate remaining style modules to API |
| 7 | Add snapshot equivalence test | test(styling): add API equivalence snapshot test |
| 8 | Validate order determinism | test(styling): add order stability test |
| 9 | Docs update & phase checklist | docs(styling): document Phase 03 completion |

## 5. Rollback Strategy
| Failure | Symptom | Rollback |
|---------|---------|----------|
| API migration changes output | Snapshot diff >0 | Temporarily source Phase 02 legacy modules (shim) |
| Order instability | Styles appear reordered across shells | Add explicit sort; re-run |
| Collision logic too strict | Unexpected warnings | Downgrade to notice until Phase 04 |

## 6. Metrics
| Metric | Target |
|--------|--------|
| Snapshot diff lines | 0 |
| Additional startup cost (ms) | < +5ms |
| Palette coverage (% literals replaced) | ≥ 80% Phase 03 |

## 7. Documentation Updates
| Doc | Change |
|-----|--------|
| styling-architecture.md | New Palette & API section |
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Progress TASK-MAJ-11/12, MIN-07 |
| review/findings.md | Mark styling modular risk reduced |

## 8. Exit Checklist
- [ ] All modules migrated to API
- [ ] Palette coverage ≥ target
- [ ] Snapshot equivalence green twice
- [ ] Order determinism test green
- [ ] Docs updated & tasks advanced

## 9. Appendix A – Example API Usage
```zsh
# palette.zsh
PALETTE_CORE_ACCENT='#5fd7ff'

# register usage
register_style completion match-original 'matcher-list m:{a-z}={A-Z}'
```

## 10. Appendix B – Collision Handling Snippet
```zsh
if [[ -n ${_STYLE_REG[$k]:-} && ${_STYLE_REG[$k]} != "$v" ]]; then
  print -u2 "[style-api][warn] collision for $k: '${_STYLE_REG[$k]}' vs '$v' (keeping first)"
  return 0
fi
_STYLE_REG[$k]="$v"
```

---
Generated: 2025-08-24
