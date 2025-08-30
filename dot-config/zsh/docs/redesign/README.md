# ZSH Redesign Documentation Index (Consolidated)
Date: 2025-08-30
Status: Planning Complete (Implementation Not Yet Begun)

## Baseline Performance Summary
Baseline captured (timestamp in metrics/perf-baseline.json):
- filtered_mean_ms: 4772ms
- filtered_relative_stddev: 2.62%
- discarded_count: 0 (no outliers removed)
Improvement gate: redesign accepted when startup_mean <= 3817ms (80% of baseline). Badge: docs/redesign/badges/perf.json (served via workflow).

### Badge Endpoints (Shields Examples)
Replace <ORG>/<REPO> with actual repository slug once remote is configured:
- Perf Badge: https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<ORG>/<REPO>/gh-pages/badges/perf.json
- Structure Badge: https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<ORG>/<REPO>/gh-pages/badges/structure.json
- Summary Badge: https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<ORG>/<REPO>/gh-pages/badges/summary.json

## 1. Core Planning Documents
| Doc | Purpose |
|-----|---------|
| planning/analysis.md | Current-state inventory & rationale |
| planning/final-report.md | Executive summary & strategy |
| planning/implementation-plan.md | Phased actionable plan |
| planning/master-plan.md | High-level improvement roadmap |
| planning/consolidation plan (../consolidation/plan.md) | Source → target mapping |
| planning/prefix-reorg-spec.md | Prefix normalization & mapping |
| planning/pre-plugin-redesign-spec.md | Pre-plugin consolidation plan (12→8) |
| planning/plugin-loading-optimization.md | Optimized plugin loading & lazy Node/npm strategy |
| planning/baseline-metrics-plan.md | Baseline capture protocol |
| planning/compinit-audit-plan.md | Single-run compinit verification |
| planning/rollback-decision-tree.md | Mermaid rollback decision flow |
| planning/implementation-entry-criteria.md | Entry gate checklist |
| planning/testing-strategy.md | Test taxonomy & thresholds |
| planning/migration-checklist.md | Migration verification & checklist |
| planning/diagrams.md | Comprehensive visual architecture & flows |

## 2. Architecture & Reviews
| Doc | Purpose |
|-----|---------|
| architecture-overview.md | Startup phases & module dependencies |
| review/issues.md | Issues & risk classifications |
| review/completion-audit.md | Completion system audit & guard plan |

## 3. Supplemental / Optional
| Doc | Purpose |
|-----|---------|
| planning/optional-next-steps.md (TBD) | CI/CD scaffold (future to copy) |
| badges/ | Generated shield endpoints (perf, structure, summary) |
| metrics/ | Baseline & current metrics artifacts |
| glossary.md | Terminology & abbreviations reference |

## 4. Module Target Structures
Post-plugin (planned 11): 00,05,10,20,30,40,50,60,70,80,90
Pre-plugin (planned 8): 00,05,10,15,20,25,30,(40 reserved)

## 5. Key Guard Variables
| Var | Description |
|-----|-------------|
| _COMPINIT_DONE | Ensures single compinit run |
| _ASYNC_PLUGIN_HASH_STATE | Async integrity scan state |
| ZSH_REDESIGN | Loader flag (to be introduced) |
| ZSH_ENABLE_PREPLUGIN_REDESIGN | Gate for redesigned pre-plugin skeleton activation |
| ZSH_ENABLE_NVM_PLUGINS | Toggles nvm & npm plugin activation (with lazy wrappers) |
| ZSH_NODE_LAZY | Retain lazy Node stubs even if plugins load |
| ZSH_ENABLE_ABBR | Optional reintroduction of abbreviation plugin |
| _LOADED_<MODULE> | Per-file sentinel guard |

## 6. Performance Gates
- Baseline captured via baseline-metrics-plan (mean 4772ms ±2.62%)
- Redesign accepted only if startup_mean <= baseline_mean * 0.80 (<=3817ms)
- CI/perf badge fails >5% regression

## 7. Integrity Strategy
Early (00) minimal stub → Deferred (80) async deep hashing; user commands (planned) `plugin_security_status`, `plugin_scan_now`.

## 8. Testing Summary (See testing-strategy)
Design, Unit, Feature, Integration, Performance, Security, Maintenance categories with threshold enforcement.

## 9. Implementation Entry (See implementation-entry-criteria)
All criteria must be ✅ before first rename/migration commit.

## 10. Rollback
Decision flow: rollback-decision-tree.md; requires preserved perf-current.json & structure-audit.json; tag rollback-DATE annotated.

## 11. Consolidation Status
All planning docs consolidated under this directory. Original external copies (if any) are now superseded by these.

## 12. Cross-Link Map
| Doc | Back Link Present | Key Outbound Links |
|-----|-------------------|--------------------|
| [planning/migration-checklist.md](planning/migration-checklist.md) | ✔ Back to Index | [implementation-plan.md](planning/implementation-plan.md), [final-report.md](planning/final-report.md), [prefix-reorg-spec.md](planning/prefix-reorg-spec.md), [pre-plugin-redesign-spec.md](planning/pre-plugin-redesign-spec.md) |
| [planning/implementation-plan.md](planning/implementation-plan.md) | ✔ Back to Index | [migration-checklist.md](planning/migration-checklist.md), [baseline-metrics-plan.md](planning/baseline-metrics-plan.md) |
| [planning/final-report.md](planning/final-report.md) | ✔ Back to Index | [migration-checklist.md](planning/migration-checklist.md), [implementation-plan.md](planning/implementation-plan.md) |
| [planning/analysis.md](planning/analysis.md) | ✔ Back to Index | [prefix-reorg-spec.md](planning/prefix-reorg-spec.md), [plugin-loading-optimization.md](planning/plugin-loading-optimization.md) |
| [planning/prefix-reorg-spec.md](planning/prefix-reorg-spec.md) | ✔ Back to Index | [migration-checklist.md](planning/migration-checklist.md), [implementation-entry-criteria.md](planning/implementation-entry-criteria.md) |
| [planning/pre-plugin-redesign-spec.md](planning/pre-plugin-redesign-spec.md) | ✔ Back to Index | [plugin-loading-optimization.md](planning/plugin-loading-optimization.md) |
| [planning/plugin-loading-optimization.md](planning/plugin-loading-optimization.md) | ✔ Back to Index | [pre-plugin-redesign-spec.md](planning/pre-plugin-redesign-spec.md), [implementation-plan.md](planning/implementation-plan.md) |
| [planning/compinit-audit-plan.md](planning/compinit-audit-plan.md) | ✔ Back to Index | [testing-strategy.md](planning/testing-strategy.md) |
| [planning/rollback-decision-tree.md](planning/rollback-decision-tree.md) | ✔ Back to Index | [implementation-plan.md](planning/implementation-plan.md), [migration-checklist.md](planning/migration-checklist.md) |
| [planning/implementation-entry-criteria.md](planning/implementation-entry-criteria.md) | ✔ Back to Index | [migration-checklist.md](planning/migration-checklist.md), [baseline-metrics-plan.md](planning/baseline-metrics-plan.md) |
| [planning/testing-strategy.md](planning/testing-strategy.md) | ✔ Back to Index | [implementation-plan.md](planning/implementation-plan.md), [migration-checklist.md](planning/migration-checklist.md) |
| [planning/diagrams.md](planning/diagrams.md) | ✔ Back to Index | [analysis.md](planning/analysis.md), [final-report.md](planning/final-report.md) |
| [review/issues.md](review/issues.md) | ✔ Back to Index | [migration-checklist.md](planning/migration-checklist.md), [implementation-plan.md](planning/implementation-plan.md) |
| [review/completion-audit.md](review/completion-audit.md) | ✔ Back to Index | [testing-strategy.md](planning/testing-strategy.md), [compinit-audit-plan.md](planning/compinit-audit-plan.md) |
| [architecture-overview.md](architecture-overview.md) | ✔ Back to Index | [diagrams.md](planning/diagrams.md) |
| [glossary.md](glossary.md) | ✔ Back to Index | [analysis.md](planning/analysis.md) |

(Add new docs using the pattern: first heading, optional TOC, then a `[Back to Documentation Index](../README.md)` link at bottom.)

---
**Navigation:** Previous: _Index_ | [Next → Analysis](planning/analysis.md) | [Top](#) | [Back to Index](README.md)

---
(End redesign documentation index)
