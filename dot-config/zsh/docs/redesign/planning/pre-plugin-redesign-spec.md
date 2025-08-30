# Pre-Plugin Redesign Specification
Date: 2025-08-30
Status: Planning (Draft – to be Frozen after approval)

## 1. Scope
Redesign of `.zshrc.pre-plugins.d` into `.zshrc.pre-plugins.d.redesigned` mirroring principles used for `.zshrc.d.REDESIGN`:
- Deterministic numeric prefixes
- Consolidation of fragmented early path / framework prep scripts
- Early minimal surface; heavy logic deferred post plugin load if possible

## 2. Goals
| Goal | Metric / Evidence |
|------|-------------------|
| Reduce file count | 12 → 8 (target) |
| Normalize ordering | Unique ascending prefixes (00..30 + reserved 40) |
| Avoid premature heavy loads | No compinit, no plugin hashing, no Homebrew env scans > needed |
| Enable Node (nvm/npm) lazy activation | Provide consolidated lazy wrapper (single file) |

## 3. Current Inventory Snapshot
```
00_00-critical-path-fix.zsh
00_01-path-resolution-fix.zsh
00_05-path-guarantee.zsh
00_10-fzf-setup.zsh
00_30-lazy-loading-framework.zsh
10_10-nvm-npm-fix.zsh
10_20-macos-defaults-deferred.zsh
10_30-lazy-direnv.zsh
10_40-lazy-git-config.zsh
10_50-lazy-gh-copilot.zsh
20_10-ssh-agent-core.zsh
20_11-ssh-agent-security.zsh
```

## 4. Target Structure (Skeleton)
```
.zshrc.pre-plugins.d.redesigned/
  00-path-safety.zsh
  05-fzf-init.zsh
  10-lazy-framework.zsh
  15-node-runtime-env.zsh
  20-macos-defaults-deferred.zsh
  25-lazy-integrations.zsh
  30-ssh-agent.zsh
  40-pre-plugin-reserved.zsh (placeholder, optional)
```

## 5. Responsibility Allocation
| File | Responsibility | Key Constraints |
|------|----------------|-----------------|
| 00-path-safety | PATH normalization + critical resolution fixes | Must not rely on plugins; idempotent |
| 05-fzf-init | Fzf environment & key bindings (light) | Skip install/update detection if too slow |
| 10-lazy-framework | Lazy loader framework bootstrap only | <5ms budget |
| 15-node-runtime-env | nvm + npm + candidate node tools (bun) lazy wrappers | No immediate `nvm.sh` sourcing |
| 20-macos-defaults-deferred | Schedule macOS defaults adjustments (background or on-demand) | Detect OS first; skip on non-macOS |
| 25-lazy-integrations | direnv, git config caching, gh/copilot lazy wrappers | Each wrapper sets a single-use hook |
| 30-ssh-agent | Consolidated core & security hardening (key perms) | Avoid starting agent if already running |
| 40-pre-plugin-reserved | Future insertion slot | Remains guarded & empty |

## 6. Guard Pattern
Shared with post-plugin spec:
```zsh
[[ -n ${_LOADED_<UPPER_SLUG>:-} ]] && return
_LOADED_<UPPER_SLUG>=1
```

## 7. Node / NVM Reactivation Strategy
- Provide stub `nvm()` function that lazy-sources `nvm.sh` and completion on first invocation.
- Re-enable `npm` plugin logic by ensuring PATH hook executes only after nvm loads (or using existing system Node if present).
- Maintain environment variables:
  - `NVM_AUTO_USE=true`
  - `NVM_LAZY_LOAD=true` (documented sentinel)
  - Provide zstyle hints (kept if using OMZ plugin internally) inside the lazy wrapper file.

## 8. Performance Budget (Indicative)
| File | Budget (ms) | Notes |
|------|-------------|-------|
| 00-path-safety | 2 | Simple shell ops only |
| 05-fzf-init | 4 | Guard detection; skip reinstall logic |
| 10-lazy-framework | 5 | Minimal alias/function definitions |
| 15-node-runtime-env | 3 | Only define functions; no sourcing heavy scripts |
| 25-lazy-integrations | 5 | Each lazy stub <1ms |
| 30-ssh-agent | 8 | Conditional start only if needed |

## 9. Migration Strategy (High-Level)
1. Create redesign directory & guarded empty files.
2. Move and merge content incrementally (single commit per file) with tests (design + any unit wrappers).
3. Add integration test verifying no `compinit` string executed pre-plugin stage.
4. A/B measure pre-plugin cumulative time (simple timestamp in .zshrc wrappers) before and after.

## 10. Testing Additions
| Test | Purpose |
|------|---------|
| test-preplugins-structure.zsh | Validate 8 target files present (when flag enabled) |
| test-preplugins-no-compinit.zsh | Fail if `compinit` appears in trace pre plugin init |
| test-nvm-lazy-load.zsh | Ensure calling `nvm version` triggers sourcing exactly once |

## 11. Rollback Procedure (Pre-Plugin Only)
- Rename `.zshrc.pre-plugins.d.redesigned` → `.zshrc.pre-plugins.d.failed-<timestamp>`
- Restore original `.zshrc.pre-plugins.d` (unchanged baseline) – no cross-impact with post-plugin modules.

## 12. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Over-merge causing large file complexity | Harder navigation | Keep line count heuristic (<250 lines) |
| Node wrappers sourcing unexpectedly | Startup slowdown | Guard for interactive invocation only |
| Agent start race | Multiple agents | PID file / env var detection before start |

## 13. Freeze Criteria
Spec frozen once design tests merged and implementation-entry-criteria doc acknowledges readiness.

---
**Navigation:** [← Previous: Prefix Reorg Spec](prefix-reorg-spec.md) | [Next: Plugin Loading Optimization →](plugin-loading-optimization.md) | [Top](#) | [Back to Index](../README.md)

---
(End pre-plugin redesign specification)
