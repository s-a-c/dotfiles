# Glossary (Redesign Documentation)
> **DEPRECATED**: This legacy glossary has been superseded by `docs/redesignv2/REFERENCE.md` (operational terms) and `docs/redesignv2/ARCHITECTURE.md` (architectural concepts).  
> Retained only for historical context. Do not update; add new or revised terminology exclusively in the redesignv2 documentation set.

Date: 2025-08-30
Status: Deprecated (Frozen – superseded by redesignv2)

## Core Terms
| Term | Definition | Notes |
|------|------------|-------|
| Baseline | Original performance & structure snapshot prior to migration | Stored as perf-baseline.json + structure-audit.json |
| Promotion | Moment redesigned directory becomes primary active source | Guarded by promotion-guard script |
| Skeleton | Initial creation of empty guarded target module files | Ensures deterministic file count & ordering |
| Guard Sentinel | `_LOADED_<MODULE>` variable preventing double sourcing | Pattern mandated by tests |
| Compinit Guard | Single-run gate using `_COMPINIT_DONE` variable | Enforces one completion initialization |
| Deferred Integrity | Post-first-prompt deep plugin hash verification | Implemented by 80-security-validation |
| Lazy Loader | Function/alias stub delaying cost until first actual use | Reduces TTFP and mean startup time |
| TTFP | Time To First Prompt | Primary user-facing latency metric |
| Perf Hook | `precmd` sampling mechanism appending deltas to log | Drives longitudinal performance tracking |
| Rollback Tag | Annotated git tag created during rollback (e.g. rollback-DATE) | Ensures reproducibility & audit trail |
| Redesign Flag | `ZSH_REDESIGN` env var gating new vs legacy modules | Allows A/B verification |
| Pre-Plugin Flag | `ZSH_ENABLE_PREPLUGIN_REDESIGN` toggles new pre-plugin skeleton | Enables gradual rollout |
| Node Plugin Flag | `ZSH_ENABLE_NVM_PLUGINS` controls nvm/npm plugin activation | Guard against perf regressions |
| Node Lazy Flag | `ZSH_NODE_LAZY` retains lazy stub behavior even with plugins | Minimizes cold start cost |
| Abbr Enable Flag | `ZSH_ENABLE_ABBR` reintroduces abbreviation plugin when stable | Default off pending fix |
| Pre-Plugin Phase | Scripts sourced before plugin manager initialization | Optimization target for early latency |
| Post-Plugin Phase | Ordered module chain after plugin load | Primary functional consolidation area |
| Async Queue | Background work scheduling mechanism | Initially for deep integrity hashing |
| Integrity Stub | Lightweight early hash presence / registry check | Loaded in 00-security-integrity |
| Structure Audit | Generated artifact enumerating active modules & order | Used for drift detection & CI badge |
| Node Lazy Stub | `nvm()` function deferring sourcing nvm.sh until needed | Part of 15-node-runtime-env |
| Integration Wrapper | Unified lazy hooks for direnv, git config, gh/copilot | Consolidated in 25-lazy-integrations |
| Agent Consolidation | Combined ssh agent start + security hardening script | Implemented in 30-ssh-agent |

## Testing & Validation Terms
| Term | Definition | Notes |
|------|------------|-------|
| Design Test | Verifies structural/document constraints | Runs pre-migration & promotion |
| Integration Test | Exercises multiple modules end-to-end | Ensures parity & guards regressions |
| Performance Test | Captures timing metrics over multiple runs | Applies variance threshold (<12% RSD) |
| Security Test | Validates plugin hash state & integrity transitions | Depends on async scan completion |
| Maintenance Test | Ensures scheduled tasks / cron wrappers still functional | Post-promotion ongoing gate |

## Metrics & Thresholds
| Metric | Target | Rationale |
|--------|--------|-----------|
| Startup Mean Reduction | ≥20% vs baseline | Justifies redesign complexity |
| Regression Gate | >5% triggers fail | Early warning threshold |
| Variation RSD | <12% | Ensures timing stability |
| File Count (Post-Plugin) | 11 | Predictable module map |
| File Count (Pre-Plugin) | 8 (+reserved) | Minimal early footprint |

## Notation
| Symbol | Meaning |
|--------|---------|
| 🔐 | Early security / integrity stub |
| 🛡️ | Advanced / deferred security validation |
| ⚙️ | Options / configuration module |
| 🧰 | Core reusable functions |
| 🧩 | Plugin aggregation / ensures |
| 🛠️ | Development environment tooling |
| ⌨️ | Aliases & keybindings |
| 📘 | Completion & history management |
| 🎨 | UI / prompt elements |
| 🧪 | Performance monitoring hooks |
| ✅ | Finalization / splash |

## Cross-Link Map
| Related Doc | Purpose |
|-------------|--------|
| planning/analysis.md | Origins of many terms |
| planning/testing-strategy.md | Formal test category definitions |
| planning/diagrams.md | Visual symbol usage |
| planning/implementation-plan.md | Phase nomenclature |
| review/issues.md | Severity taxonomy |
| review/completion-audit.md | Guard & completion terminology |

---
**Navigation:** [← Previous: Architecture Overview](architecture-overview.md) | [Next: Analysis →](planning/analysis.md) | [Top](#) | [Back to Index](README.md)
