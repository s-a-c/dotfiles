# Gating & Feature Flags
Date: 2025-08-31
Status: Authoritative (kept in sync with .zshrc)

## Purpose
Central reference for all environment variables / flags controlling redesign activation, lazy behaviors, security modes, and migration steps. CI drift & checksum tests depend on this canonical list.

## Flag Inventory
| Flag | Default | Scope | Phase | Effect | Test Coverage |
|------|---------|-------|-------|--------|---------------|
| ZSH_ENABLE_PREPLUGIN_REDESIGN | 0 | Pre-Plugin Loader | Pre-Plugin Migration | Switches from `.zshrc.pre-plugins.d` → `.zshrc.pre-plugins.d.REDESIGN` | test-preplugin-structure, test-preplugin-no-compinit |
| ZSH_ENABLE_POSTPLUGIN_REDESIGN | 0 | Post-Plugin Loader | Post-Plugin Skeleton | Switches from `.zshrc.d` → `.zshrc.d.REDESIGN` | test-postplugin-structure |
| ZSH_REDESIGN | (unset) | Global Toggle (planned) | Promotion | Potential umbrella to enable both redesign phases simultaneously | (future) |
| ZSH_NODE_LAZY | 1 | Lazy Node/NVM | Performance | Keeps Node/npm wrappers lazy even if plugin set loads early | (pending) |
| ZSH_ENABLE_NVM_PLUGINS | 1 | Node Env | Feature | Enables nvm/npm plugin registration if present | (pending) |
| ZSH_ENABLE_ABBR | 0 | Optional Abbreviations | Enhancement | Enables abbreviation plugin (not core) | (future) |
| ZSH_DEBUG | 0 | Diagnostics | Any | Enables verbose debug instrumentation & timing logs | run-all-tests harness |
| _COMPINIT_DONE | sentinel | Completion Guard | Core & Redesign | Ensures single compinit execution | compinit audit tests |
| _ASYNC_PLUGIN_HASH_STATE | IDLE | Integrity Async | Deferred (80) | Tracks async plugin hash scan state | (future security tests) |
| _LOADED_* | sentinel | Module Guard | All Modules | Prevents double-sourcing & drift detection | structure tests |

## Lifecycle States
1. Planning (current) – Flags documented; only pre-plugin toggle active.
2. Skeleton – Both redesign directories exist; toggles individually switch.
3. Dual A/B – Metrics collection under each flag state.
4. Promotion – ZSH_REDESIGN (optional) or both enables set to 1 in user env.
5. Decommission – Legacy dirs archived + checksums updated + inventory retired.

## Promotion Procedure (Summary)
1. Validate performance gate (startup_mean <= baseline * 0.80).
2. Run: tools/verify-legacy-checksums.zsh (must PASS).
3. Enable ZSH_ENABLE_PREPLUGIN_REDESIGN=1, collect 10-run metrics.
4. Enable ZSH_ENABLE_POSTPLUGIN_REDESIGN=1, collect 10-run metrics.
5. (Optional) Set ZSH_REDESIGN=1 once both above validated.
6. Update legacy-checksums.sha256 with new canonical set ONLY after merging redesign as primary.
7. Tag: `refactor-promotion`.

## CI Expectations
| Check | Condition | Fail Mode |
|-------|-----------|-----------|
| Inventory Drift | Any mismatch vs inventory snapshots | STOP: mutated frozen directory |
| Legacy Checksums | Any SHA mismatch | STOP: unplanned edit |
| Structure (Redesign) | Missing or extra skeleton files | STOP: structural regression |
| Gating Doc Sync | Flag absent from table but used in code | WARNING → escalate |

## Updating This Document
1. Add new row to table.
2. Reference new tests (or add them) for coverage.
3. Commit along with associated code/test changes.
4. Ensure testing-strategy.md cross-ref updated.

---
[Back to Documentation Index](../README.md)
