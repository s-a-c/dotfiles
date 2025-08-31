# Prefix Reorganization Specification
Date: 2025-08-30
Status: Planning (Frozen Once Approved)
Scope: Numeric prefix normalization for BOTH pre-plugin (`.zshrc.pre-plugins.d`) and post-plugin (`.zshrc.d`) module sets prior to migration into redesigned directories.

## 1. Objectives
- Eliminate irregular prefix jumps (e.g., 00_20 → 00_60 → 20_04) that obscure intended ordering.
- Provide future insertion slots without renumber churn (increments of 5–10 early, wider spacing later if needed).
- Establish deterministic, documented mapping (old → new) enabling automated renames & rollback.
- Prepare a uniform guard & sentinel pattern per file.

## 2. Principles
| Principle | Description |
|-----------|-------------|
| Monotonic | Strictly ascending numeric prefixes illustrate load sequence intuitively. |
| Sparse Early | Use smaller increments early (5) where churn is likely; larger later (10). |
| Category Grouping | Cluster related responsibilities (path safety, framework, env/tooling, security). |
| Stable Contracts | New names become the contract; legacy names referenced only in mapping & rollback docs. |

## 3. Post-Plugin Mapping (Active + Legacy Consolidation)
Target already defined (11 modules). Mapping table consolidates current & disabled fragments representative categories:

| Old / Legacy Source (Representative) | New Module | Notes |
|-------------------------------------|------------|-------|
| 00_20-plugin-integrity-core / 00_21-plugin-integrity-advanced | 00-security-integrity.zsh / 80-security-validation.zsh | Split-phase (early stub vs deferred heavy) |
| 00_60-options.zsh | 05-interactive-options.zsh | Pure options centralization |
| 20_04-essential.zsh | 20-essential-plugins.zsh | Idempotent ensure logic |
| 30_30-prompt.zsh | 60-ui-prompt.zsh | Prompt isolated from completion styling |
| 30_10-aliases.zsh + 30_20-keybindings.zsh | 40-aliases-keybindings.zsh | Merged UI interaction layer |
| 00_30-performance-monitoring.zsh (disabled) | 70-performance-monitoring.zsh | Reactivated lite metrics & hooks |
| *_functions (00_70/72/74) | 10-core-functions.zsh | Consolidated helpers |
| 10_x development env group | 30-development-env.zsh | Toolchain & VCS/SSH gating |
| completion-management / finalization | 50-completion-history.zsh | Guarded compinit + zstyles |
| 99_99-splash.zsh | 90-splash.zsh | Terminal banner / finalization |

## 4. Pre-Plugin Mapping (Current → Proposed)
Current pre-plugin files (12):
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
Proposed normalized set (8 files):
| Old Sources | New Module | Rationale |
|-------------|------------|-----------|
| 00_00-critical-path-fix + 00_01-path-resolution-fix + 00_05-path-guarantee | 00-path-safety.zsh | Merge path & resolution hardening; reduce 3 I/O stats to 1 file |
| 00_10-fzf-setup | 05-fzf-init.zsh | Early but after path safety; small isolated concern |
| 00_30-lazy-loading-framework | 10-lazy-framework.zsh | Framework bootstrap positioned after tooling basics |
| 10_10-nvm-npm-fix + (reactivated npm/nvm plugin stubs) | 15-node-runtime-env.zsh | Unified Node ecosystem lazy hooks (nvm, npm autoload, shim) |
| 10_20-macos-defaults-deferred | 20-macos-defaults-deferred.zsh | Deferral stays, renumber for gap spacing |
| 10_30-lazy-direnv + 10_40-lazy-git-config + 10_50-lazy-gh-copilot | 25-lazy-integrations.zsh | Combine light lazy wrappers (direnv, git cfg, gh/copilot) |
| 20_10-ssh-agent-core + 20_11-ssh-agent-security | 30-ssh-agent.zsh | Single SSH agent orchestration & security checks |
| (Reserved future pre-plugin slot) | 40-pre-plugin-reserved.zsh (optional placeholder) | Insertion point without renumber; starts empty guard |

## 5. Guard & Sentinel Pattern
Each redesigned file begins with:
```zsh
# <prefix>-<slug>.zsh
[[ -n ${_LOADED_<UPPER_SLUG>:-} ]] && return
_LOADED_<UPPER_SLUG>=1
```
Sentinels unique per file; tests assert presence.

## 6. Naming Validation Rules (Design Tests)
| Rule | Pattern | Reason |
|------|---------|--------|
| Prefix width | `^[0-9]{2}` | Consistency, sorting |
| Hyphen slug | `^[0-9]{2}-[a-z0-9-]+\.zsh$` | Readability & portability |
| No duplicate prefix (post-migration) | Set uniqueness | Ordering clarity |
| File count targets | Pre-plugin=8, Post-plugin=11 | Drift guard |

## 7. Rollback Map (Automated Script Inputs)
Provide machine-readable mapping (YAML snippet) for rename scripts:
```yaml
pre_plugin_map:
  00_00-critical-path-fix.zsh: 00-path-safety.zsh
  00_01-path-resolution-fix.zsh: 00-path-safety.zsh
  00_05-path-guarantee.zsh: 00-path-safety.zsh
  00_10-fzf-setup.zsh: 05-fzf-init.zsh
  00_30-lazy-loading-framework.zsh: 10-lazy-framework.zsh
  10_10-nvm-npm-fix.zsh: 15-node-runtime-env.zsh
  10_20-macos-defaults-deferred.zsh: 20-macos-defaults-deferred.zsh
  10_30-lazy-direnv.zsh: 25-lazy-integrations.zsh
  10_40-lazy-git-config.zsh: 25-lazy-integrations.zsh
  10_50-lazy-gh-copilot.zsh: 25-lazy-integrations.zsh
  20_10-ssh-agent-core.zsh: 30-ssh-agent.zsh
  20_11-ssh-agent-security.zsh: 30-ssh-agent.zsh
post_plugin_map:
  00_20-plugin-integrity-core.zsh: 00-security-integrity.zsh
  00_21-plugin-integrity-advanced.zsh: 80-security-validation.zsh
  00_60-options.zsh: 05-interactive-options.zsh
  20_04-essential.zsh: 20-essential-plugins.zsh
  30_30-prompt.zsh: 60-ui-prompt.zsh
  (aliases_group): 40-aliases-keybindings.zsh
```

## 8. Approval & Freeze Criteria
This spec is considered FROZEN when:
- Design tests referencing target counts are merged (even if files not yet created).
- Implementation entry criteria checklist (separate doc) is satisfied.
- Sign-off recorded by maintainer in commit message `docs(prefix): freeze prefix spec`.
Further changes require new version suffix (v2) and migration note.

## 9. Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Partial rename leaving dangling legacy file | Mixed sourcing & double execution | Dry-run rename script + structure test BEFORE promotion |
| Collisions in merged files (functions) | Overwritten functions silently | Temporary shim logging duplicate definitions pre-refactor |
| Future slot exhaustion | Forced renumber churn | Reserved placeholders (40-pre-plugin-reserved, 90-splash) |

## 10. Next Steps
1. Merge design tests asserting target pre-plugin file count (8) & naming rules (still allowing legacy until flag set).
2. Implement skeleton `.zshrc.pre-plugins.d.REDESIGN/` directory with guarded empty files.
3. Run structure audit extension to include pre-plugin set (enhance tool plan – not yet coded).
4. Execute baseline performance capture BEFORE first rename.

---
**Navigation:** [← Previous: Migration Checklist](migration-checklist.md) | [Next: Pre-Plugin Redesign Spec →](pre-plugin-redesign-spec.md) | [Top](#) | [Back to Index](../README.md)

---
(End prefix reorganization specification)
