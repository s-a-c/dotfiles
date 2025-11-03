# Script Consolidation & Migration Plan
Date: 2025-08-30
Status: Draft (Pre-Execution)

## 1. Goals
- Reduce active post-plugin modules from 5 (+52 legacy disabled) to 11 clearly defined redesign modules.
- Eliminate redundant/legacy fragments while maintaining functional parity.
- Provide reversible, auditable steps (each commit references task ID and has green tests).

## 2. Source → Target Mapping
| Current / Legacy File(s) | Target Module | Action | Notes |
|--------------------------|---------------|--------|-------|
| 00_20-plugin-integrity-core.zsh | 00-security-integrity.zsh | Rename + slim | Keep minimal registry bootstrap only |
| 00_21-plugin-integrity-advanced.zsh | 80-security-validation.zsh | Migrate deferred logic | Convert heavy hashing to async trigger |
| 00_60-options.zsh | 05-interactive-options.zsh | Rename | Remove doc clutter to docs/options.md (optional) |
| 20_04-essential.zsh | 20-essential-plugins.zsh | Refactor | Ensure idempotent regeneration (timestamp/hash check) |
| 30_30-prompt.zsh | 60-ui-prompt.zsh | Extract + isolate | Move completion zstyles out |
| 00_30-performance-monitoring.zsh (disabled) | 70-performance-monitoring.zsh | Reactivate (modern) | Provide lightweight hooks only |
| 30_10-aliases.zsh + 30_20-keybindings.zsh | 40-aliases-keybindings.zsh | Merge | Remove redundant comments |
| *_functions (00_70/72/74) | 10-core-functions.zsh | Merge & categorize | Introduce autoload patterns if needed |
| 10_x development tool env sets | 30-development-env.zsh | Merge + conditionals | Lazy execute heavy detection |
| completion-management / finalization | 50-completion-history.zsh | Merge & guard | Introduce single compinit guard |
| splash (99_99-splash) | 90-splash.zsh | Rename | Ensure minimal cost |

## 3. Execution Phases
| Phase | Step | Description | Safety | Rollback |
|-------|------|-------------|--------|----------|
| 3 | Skeleton | Create empty modules with guards | Test: structure_modules (fails until all present) | Remove directory |
| 4 | Core Migration | Move security, options, functions | Unit & design tests green | Reset to baseline branch |
| 5 | Feature Migration | Move plugins, dev env, aliases, completion, prompt | Parity checklist start | Revert last N commits |
| 6 | Deferred | Add perf + advanced integrity | Async timing tests pass | Drop 70/80 modules |
| 7 | Validation | Performance A/B | perf_threshold test | Re-run baseline tag |
| 8 | Promotion | Swap directories | Tag recorded | Rename back & revert tag |

## 4. Guard Pattern
Each new module header:
```zsh
# <nn>-<description>.zsh
[[ -n ${_LOADED_<UPPER_ID>:-} ]] && return
_LOADED_<UPPER_ID>=1
```

## 5. File Movement Procedure (Per File)
1. Write failing design/structure test expecting new filename.
2. Create new file with header + TODO body.
3. Move relevant code blocks (minimal) + adapt variable namespaces.
4. Write/adjust unit tests for migrated functions.
5. Remove or comment legacy version; run tests.
6. Commit (refactor(scope): message) referencing task row.

## 6. Integrity Module Split Strategy
- Core (00): Avoid directory-wide hashing; only ensure registry dirs & stub commands.
- Validation (80): Provide `plugin_scan_now` & `plugin_hash_update`. Add async job after first prompt if not invoked manually.
- Shared helpers live in 10-core-functions (hash utility discovery, safe logging).

## 7. Completion System Integration
- Move all zstyle statements from .zshrc to 50-completion-history.
- Implement guarded compinit (see completion-audit.md).
- Create integration test ensuring `_COMPINIT_DONE=1` after startup and compdump exists.

## 8. Prompt Isolation
- Extract non-completion UI variables into 60-ui-prompt.
- Delay expensive theme initialization until after basic environment (consider starship + instant prompt synergy).

## 9. Performance Monitoring
- 70-performance-monitoring only registers precmd hook measuring delta from shell start to first prompt + subsequent prompts.
- Expose `perf_sample_startup` & `perf_report_latest` functions for tests.

## 10. Removal & Archival Policy
| Type | Action |
|------|--------|
| Pure duplicate (e.g., *.bak) | Delete (document hash in removal commit) |
| Obsolete path/env fragments | Delete after verifying .zshenv coverage |
| Split function libraries | Removed after merge commit (commit references removal rationale) |
| Deferred or heavy logic | Only appears in 80 module after migration |

## 11. Validation Checklist
| Check | Method |
|-------|--------|
| File count = 11 | structure test |
| No duplicate prefixes | structure test |
| Single compinit run | integration + log grep |
| Startup ≤ 80% baseline | performance test |
| Integrity stub present early | grep for stub function in first-phase log |
| Async deep scan deferred | timing log absence before first prompt |

## 12. Risks & Mitigations
| Risk | Mitigation |
|------|-----------|
| Silent missing function post-merge | whence audit + unit tests for each exported helper |
| Performance regression after merge burst | Commit in small logical steps + perf quick gate locally |
| Async job interfering with prompt | Use `() { ... } &!` with minimal environment copy; record start timestamp |

## 13. Success Criteria
- All modules present & guarded.
- Parity tests green (aliases, completions, prompt, history, integrity status).
- Performance improvement test passes (≥20%).
- Legacy directory archived and not sourced.

---
(End consolidation plan)
