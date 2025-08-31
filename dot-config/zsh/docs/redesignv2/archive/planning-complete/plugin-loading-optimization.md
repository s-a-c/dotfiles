# Plugin Loading Optimization Plan
Date: 2025-08-30
Status: Planning (Draft)

## 1. Objectives
Optimize ordering and conditional activation of plugins declared in `.zshrc.add-plugins.d/010-add-plugins.zsh`, reintroducing `npm` and `nvm` functionality via lazy-loading patterns while preserving stability and minimizing startup latency.

## 2. Current State Summary
- Single add-plugins file orchestrates phased sequence (Core → Dev → File Mgmt → Completion → Performance).
- `npm` and `nvm` plugins commented out due to conflicts / performance.
- Lazy framework & node environment partial handling occurs in pre-plugin fragments.

## 3. Constraints
| Constraint | Rationale |
|------------|-----------|
| Maintain deterministic dependency order | Some plugins modify environment needed by later ones |
| Avoid synchronous heavy Node environment initialization | Prevent startup slowdown |
| Ensure evalcache precedes async frameworks | Cache benefits early loads |
| Preserve syntax-highlighting order comment contract | Avoid visual / functional regressions |

## 4. Proposed Phased Model (Refined)
| Phase | Name | Responsibilities | Notes |
|-------|------|------------------|-------|
| 01 | Core Ergonomics | autopair, abbrev (if resurrected with guard) | Abbr reintroduction gated behind fix flag |
| 02 | Dev Environment Base | composer, laravel, gh, iterm2 | Lightweight pure shell plugins only |
| 03 | Node Ecosystem (Lazy) | nvm, npm stubs, bun / corepack awareness | Provide wrappers; full load on first node command |
| 04 | Navigation & Files | aliases, eza, zoxide | Keep alias override precedence |
| 05 | Completion & FZF | fzf plugin (ensures fzf key-bindings) | Must precede completion-history module load (post-plugin redesign) |
| 06 | Performance / Async | evalcache, zsh-async, zsh-defer | Order fixed for cache → async queue → deferral |

## 5. Lazy NVM/NPM Strategy
1. Move combined wrappers into `15-node-runtime-env.zsh` (pre-plugin redesign) establishing stub `nvm()`.
2. In plugin phase, register plugin definitions conditionally:
```zsh
if [[ ${ZSH_ENABLE_NVM_PLUGINS:-1} == 1 ]]; then
  zgenom oh-my-zsh plugins/nvm
  zgenom oh-my-zsh plugins/npm
fi
```
3. Guard environment collision: ensure `NPM_CONFIG_PREFIX` not force-set when nvm handles versions.
4. Add lightweight function `node_first_use_init` invoked by `nvm` stub after sourcing to install default global packages / run one-time tasks (optional, deferred).

## 6. Abbreviation Plugin Reintroduction (Optional)
- Root cause prior recursion (job table overflow) to be investigated; planning placeholder variable: `ZSH_ABBR_SAFE=0` until fixed.
- Introduce diagnostic wrapper counting expansions to identify loops; abort after threshold.

## 7. Future Enhancement Flags
| Flag | Purpose | Default |
|------|---------|--------|
| ZSH_ENABLE_NVM_PLUGINS | Toggle nvm/npm plugin loading | 1 |
| ZSH_ENABLE_ABBR | Conditional abbr load after fix | 0 |
| ZSH_NODE_LAZY | Keep Node lazy wrappers even if plugin loads | 1 |

## 8. Performance Measurement Plan
| Metric | Method | Requirement |
|--------|--------|-------------|
| Added latency from reactivating nvm/npm | 10-run mean diff before & after enabling | <5% regression allowed (perf guard) |
| First `node` command overhead | Time `node -v` initial vs second call | Initial <1500ms, second <150ms |

## 9. Testing Additions
| Test | Category | Purpose |
|------|----------|---------|
| test-plugin-order.zsh | design | Validate ordering array matches spec |
| test-nvm-lazy-wrapper.zsh | unit/integration | Ensure stub replaced after first call |
| test-node-first-use-init.zsh | feature | Confirm optional init does not re-run |

## 10. Migration Steps (Planning Only)
1. Add feature flags (env defaults) in `.zshenv` (deferred until implementation phase).
2. Introduce design test enumerating expected phase names (allow legacy while flag disabled).
3. Split heavy Node logic into pre-plugin redesign file executed before plugin definitions but without sourcing nvm.
4. Reactivate plugin lines guarded by `[[ ${ZSH_ENABLE_NVM_PLUGINS:-1} == 1 ]]`.
5. Capture performance delta and adjust gating if regression >5%.

## 11. Rollback
- Disable by setting `ZSH_ENABLE_NVM_PLUGINS=0` and commenting additions; structure tests still pass as disabled condition doesn’t alter file count.

## 12. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Reintroduced recursion (abbr) | Shell instability | Keep disabled by default; add recursion guard counter |
| Node plugin overhead > threshold | Slower startup | Keep lazy wrappers; optionally drop plugin back to stub mode |
| Flag drift (undocumented) | Confusion | Document in final-report & README variable tables |

## 13. Open Questions
| Question | Pending Decision |
|----------|------------------|
| Include corepack activation in lazy wrapper? | Evaluate after baseline Node performance measured |
| Add caching for `nvm ls` results? | Possibly in performance phase (70 module) |

---
**Navigation:** [← Previous: Pre-Plugin Redesign Spec](pre-plugin-redesign-spec.md) | [Next: Baseline Metrics Plan →](baseline-metrics-plan.md) | [Top](#) | [Back to Index](../README.md)

---
(End plugin loading optimization plan)
