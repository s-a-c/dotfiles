# Phase 04: Styling Variants & Finalizer (▲ P1)

Return: [Index](../../README.md) | Prev: [Phase 03 Palette & API](030-phase-03-styling-palette-and-api.md) | Next: [Phase 05 Path & Env Unification](phase-05-path-env-unification.md)

Goal: Layer variant selection (themes, low‑color/safe mode) atop the registration API; introduce deterministic finalizer applying ordered styles; remove legacy monolithic fallback while keeping rollback safety window.

Primary Tasks: TASK-MAJ-12 (finalizer), TASK-MAJ-13 (remove legacy block + shim), TASK-MIN-11 (snapshot diff test), TASK-MIN-12 (variant switching logic), TASK-MIN-13 (low-color fallback).

## 1. Hierarchical Task Breakdown
| Epic | Task | Subtasks | Effort | Impact | Status |
|------|------|----------|--------|--------|--------|
| Variant Infra | Variant directory scaffold | `styles/variants/{default,high-contrast,low-color}` placeholder | ⚡ | 🎨 | ⬜ |
|  | Variant loader | `select_style_variant <name>` sets VARIANT + sources file | ⚡ | 🎨 | ⬜ |
|  | Safe detection | Auto low-color if `$TERM` lacks 256 / COLORTERM empty | ⚡ | UX | ⬜ |
| Palette Extension | Token override mechanism | Allow variant file to redefine `PALETTE_*` tokens before apply | 🕒 | UX | ⬜ |
|  | Diff report (debug) | Show which tokens overridden (env flag) | ⚡ | 🧹 | ⬜ |
| Finalizer | Deterministic order | Sort registration map (domain:key) then emit | ⚡ | 🧹 | ⬜ |
|  | Emission metrics | Count styles applied; export `STYLES_APPLIED` | ⚡ | PERF | ⬜ |
|  | Guard & rollback | On non-zero emission error: source legacy shim + warn | ⚡ | 🔧 | ⬜ |
| Legacy Removal | Excise legacy monolithic file | Delete or rename `.legacy` after green snapshot | ⚡ | 🧹 | ⬜ |
|  | Transitional shim | Provide no-op file logging deprecated sourcing attempt | ⚡ | 🧹 | ⬜ |
| Testing | Variant selection test | Force variant=high-contrast → assert token substitution | 🕒 | UX | ⬜ |
|  | Low-color auto test | Simulate `TERM=vt100` → expect low-color variant | 🕒 | UX | ⬜ |
|  | Snapshot stability | Ensure default variant diff = 0 vs Phase 03 | ⚡ | 🔧 | ⬜ |
|  | Override precedence | Variant overrides base but not post-override manual | ⚡ | 🔧 | ⬜ |
| Metrics & Logging | Style timing capture | Measure time (zmodload zsh/datetime) for finalizer | ⚡ | PERF | ⬜ |
|  | Regression threshold | Fail test if > target ms increase | ⚡ | PERF | ⬜ |
| Docs | Update architecture | Add Variant & Finalizer sections | ⚡ | 🧹 | ⬜ |

## 2. Finalizer Contract
Inputs: Registered styles (assoc), active palette tokens, selected variant overrides.
Process:
1. Apply variant palette overrides.
2. Freeze registration map (prevent late mutation).
3. Emit styles in stable sorted order.
4. Record metrics (#styles, ms duration, variant name).
Outputs: Live zstyles identical (default variant) or intentionally variant-modified.
Error Modes: Emission failure (unlikely) → rollback shim.
Success: No diff vs Phase 03 baseline under default variant.

## 3. TDD Plan
| Test | Purpose | Criteria |
|------|---------|----------|
| test-variant-default-equiv.zsh | Default variant parity | Diff = 0 |
| test-variant-high-contrast.zsh | Variant overrides apply | Token subset changed |
| test-variant-low-color-auto.zsh | Auto-detect fallback | Low-color variant chosen |
| test-style-finalizer-order.zsh | Order determinism | Sorted output consistent |
| test-style-finalizer-metrics.zsh | Metrics exported | Vars present & sane |

## 4. Implementation Sequence
| Step | Action | Commit Message |
|------|--------|---------------|
| 1 | Scaffold variants dir + files | chore(styling): scaffold variant directories |
| 2 | Add selection function & auto-detect | feat(styling): add variant selection + auto low-color |
| 3 | Implement finalizer (no removal) | feat(styling): introduce style finalizer w/ metrics |
| 4 | Integrate finalizer into startup order | chore(styling): wire style finalizer into sourcing chain |
| 5 | Add snapshot & order tests | test(styling): add variant and finalizer tests |
| 6 | Remove legacy monolithic file → shim | refactor(styling): remove legacy style block add shim |
| 7 | Docs & checklist | docs(styling): document Phase 04 variants + finalizer |

## 5. Rollback Strategy
| Failure | Symptom | Rollback |
|---------|---------|----------|
| Variant misapplied | Wrong colors reported | Force VARIANT=default env; investigate overrides |
| Performance regression | Finalizer time spikes | Profile; batch emit; revert to Phase 03 emitter |
| Unexpected diff default | Snapshot mismatch | Re-enable legacy shim temporarily |

## 6. Metrics
| Metric | Target |
|--------|--------|
| Finalizer time | < 15ms |
| Snapshot diff (default) | 0 lines |
| High-contrast override count | >= 1 token |

## 7. Documentation Updates
| Doc | Change |
|-----|--------|
| styling-architecture.md | Add variant + finalizer sections |
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Progress tasks MAJ-12/13 MIN-11/12/13 |

## 8. Exit Checklist
- [ ] Default variant parity
- [ ] Variant tests green
- [ ] Legacy file removed & shim active
- [ ] Metrics logged 3 consecutive runs
- [ ] Plan updated

## 9. Appendix – Variant File Template
```zsh
# Variant: high-contrast
# Overrides only
PALETTE_CORE_ACCENT='#ffffff'
PALETTE_CORE_DIM='#444444'
```

---
Generated: 2025-08-24
