# Script Consolidation & Normalization Plan

Return: [Index](../README.md) | Related: [Improvement Plan](010-comprehensive-improvement-plan.md) | [Findings](../020-review/010-findings.md)
Generated: 2025-08-23
**Updated: 2025-08-24 - Reflects current renamed script structure**

## Status Update: Script Renaming Complete ✅

**The `.zshrc.d/` scripts have been successfully renamed with the new underscore-based convention:**
- Format: `{category}_{priority}-{descriptive-name}.zsh`
- Categories: `00` (core), `10` (tools), `20` (plugins), `30` (ui), `90` (finalization)

## 1. Objectives
- ✅ **COMPLETE**: Flatten multi-purpose logic into clearly delimited phase files.
- ✅ **COMPLETE**: Implement new underscore-based naming convention for better sorting.
- 🔄 **IN PROGRESS**: Remove redundant or disabled fragments after documentation.
- 🔄 **IN PROGRESS**: Ensure a single, discoverable location for completion, styling, PATH, and sanitization logic.
- ✅ **COMPLETE**: Preserve reproducibility (ordering invariants) while reducing file count and cognitive load.

## 2. Current Script Structure (Updated)

### Core Scripts (`00_*`)
| Current File | Purpose | Status |
|--------------|---------|--------|
| `00_00-standard-helpers.zsh` | Basic helper functions | ✅ Renamed |
| `00_01-environment.zsh` | Environment variables | ✅ Renamed |
| `00_01-source-execute-detection.zsh` | Script execution detection | ✅ Renamed |
| `00_02-path-system.zsh` | PATH management | ✅ Renamed |
| `00_03-completion-management.zsh` | Completion system | ✅ Renamed |
| `00_03-options.zsh` | ZSH options | ✅ Renamed |
| `00_04-functions-core.zsh` | Core functions | ✅ Renamed |
| `00_05-async-cache.zsh` | Async caching system | ✅ Renamed |
| `00_05-completion-finalization.zsh` | Completion finalization | ✅ Renamed |
| `00_06-performance-monitoring.zsh` | Performance tracking | ✅ Renamed |
| `00_07-review-cycles.zsh` | Review system | ✅ Renamed |
| `00_07-utility-functions.zsh` | Utility functions | ✅ Renamed |
| `00_08-environment-sanitization.zsh` | Environment cleanup | ✅ Renamed |
| `00_99-security-check.zsh` | Security validation | ✅ Renamed |
| `00_99-validation.zsh` | Final validation | ✅ Renamed |

### Tool Scripts (`10_*`)
| Current File | Purpose | Status |
|--------------|---------|--------|
| `10_10-development-tools.zsh` | Development environment | ✅ Renamed |
| `10_11-path-tools.zsh` | Path utilities | ✅ Renamed |
| `10_12-tool-environments.zsh` | Tool-specific environments | ✅ Renamed |
| `10_13-git-vcs-config.zsh` | VCS configuration | ✅ Renamed |
| `10_14-homebrew.zsh` | Homebrew setup | ✅ Renamed |
| `10_15-development.zsh` | Development tools | ✅ Renamed |
| `10_15-ssh-agent-macos.zsh` | SSH agent for macOS | ✅ Renamed |
| `10_17-completion.zsh` | Tool completions | ✅ Renamed |

### Plugin Scripts (`20_*`)
| Current File | Purpose | Status |
|--------------|---------|--------|
| `20_01-plugin-metadata.zsh` | Plugin metadata | ✅ Renamed |
| `20_20-plugin-environments.zsh` | Plugin environments | ✅ Renamed |
| `20_22-essential.zsh` | Essential plugins | ✅ Renamed |
| `20_23-plugin-integration.zsh` | Plugin integration | ✅ Renamed |
| `20_24-deferred.zsh` | Deferred plugin loading | ✅ Renamed |

### UI Scripts (`30_*`)
| Current File | Purpose | Status |
|--------------|---------|--------|
| `30_30-prompt-ui-config.zsh` | Prompt configuration | ✅ Renamed |
| `30_31-prompt.zsh` | Prompt setup | ✅ Renamed |
| `30_32-aliases.zsh` | Aliases | ✅ Renamed |
| `30_33-ui-enhancements.zsh` | UI enhancements | ✅ Renamed |
| `30_34-keybindings.zsh` | Key bindings | ✅ Renamed |
| `30_35-context-aware-config.zsh` | Context-aware configuration | ✅ Renamed |
| `30_35-ui-customization.zsh` | UI customization | ✅ Renamed |

### Finalization Scripts (`90_*`)
| Current File | Purpose | Status |
|--------------|---------|--------|
| `90_99-splash.zsh.disabled` | Splash screen (disabled) | ⚠️ Review needed |

## 3. Remaining Consolidation Tasks

### Files Still Needing Review/Action
| Category | Current File(s) | Action | Rationale |
|----------|-----------------|--------|-----------|
| Early completion init | .zshrc.pre-plugins.d/01-completion-init.zsh | Neutralize (stub) then delete after 2 cycles | Duplicate compinit |
| Completion fallback | `10_17-completion.zsh` | Remove fallback branch; keep style augment | Single authority |
| Styling (monolithic) | `00_05-completion-finalization.zsh` | Split into modules + palette (phased) | Modularity, testability |
| Env sanitization | pre-plugins/05-environment-sanitization, `00_08-environment-sanitization.zsh` | Merge into core sanitization | Duplication |
| Utility functions | `00_07-utility-functions.zsh` + `00_04-functions-core.zsh` | Evaluate merge (optional) | Consolidation |
| Disabled splash | `90_99-splash.zsh.disabled` | Keep archived in docs or remove | Low value |

## 4. Updated Directory Layout (Current Reality)
```text
.zshrc.pre-plugins.d/
  00-fzf-setup.zsh
  01-completion-init.zsh (⚠️ needs neutralization)
  02-nvm-npm-fix.zsh
  03-macos-defaults-deferred.zsh
  03-secure-ssh-agent.zsh
  04-lazy-direnv.zsh
  04-plugin-deferred-loading.zsh
  04-plugin-integrity-verification.zsh
  05-environment-sanitization.zsh (⚠️ merge candidate)
  05-lazy-git-config.zsh
  06-lazy-gh-copilot.zsh

.zshrc.d/
  00_02-standard-helpers.zsh ✅
  00_10-environment.zsh ✅
  00_12-source-execute-detection.zsh ✅
  00_02-path-system.zsh ✅
  00_20-completion-management.zsh ✅ (authoritative compinit)
  00_03-options.zsh ✅
  00_04-functions-core.zsh ✅
  00_22-async-cache.zsh ✅
  00_28-completion-finalization.zsh ⚠️ (styling consolidation target)
  00_30-performance-monitoring.zsh ✅
  00_40-review-cycles.zsh ✅
  00_07-utility-functions.zsh ✅
  00_50-environment-sanitization.zsh ✅
  00_99-security-check.zsh ✅
  00_99-validation.zsh ✅
  10_10-development-tools.zsh ✅
  10_11-path-tools.zsh ✅
  10_12-tool-environments.zsh ✅
  10_14-git-vcs-config.zsh ✅
  10_14-homebrew.zsh ✅
  10_15-development.zsh ✅
  10_15-ssh-agent-macos.zsh ✅
  10_17-completion.zsh ⚠️ (fallback removal target)
  20_00-plugin-metadata.zsh ✅
  20_20-plugin-environments.zsh ✅
  20_22-essential.zsh ✅
  20_23-plugin-integration.zsh ✅
  20_24-deferred.zsh ✅
  30_30-prompt-ui-config.zsh ✅
  30_31-prompt.zsh ✅
  30_32-aliases.zsh ✅
  30_33-ui-enhancements.zsh ✅
  30_34-keybindings.zsh ✅
  00_76-context-aware-config.zsh ✅
  30_35-ui-customization.zsh ✅
  90_99-splash.zsh.disabled ⚠️

.zshrc.add-plugins.d/
  010-add-plugins.zsh ✅ (unchanged)
```

## 5. Updated Migration Steps (Remaining Tasks)
| Step | Action | Status | Verification |
|------|--------|--------|--------------|
| ✅ 1-8 | **COMPLETE**: Rename all .zshrc.d scripts with underscore convention | ✅ Done | All scripts follow `XX_YY-name.zsh` pattern |
| 🔄 9 | Stub early completion file to warning only | Pending | Startup trace: no compinit before central |
| 🔄 10 | Move styling logic from `00_05-completion-finalization.zsh` | Pending | Styles appear post plugin load |
| 🔄 11 | Strip fallback compinit from `10_17-completion.zsh` | Pending | Trace: single compinit |
| 🔄 12 | Merge env sanitization scripts | Pending | No duplicate function names |
| 🔄 13 | Audit disabled files (`90_99-splash.zsh.disabled`) | Pending | Removed or documented |
| 🔄 14 | Add tests for single compinit, style ordering | Pending | Tests green |
| 15 | Phase 1: Extract current zstyle groups into 20/25/30 style modules (direct zstyle still) | Pending | Styles equivalent diff passes |
| 16 | Phase 2: Introduce palette (00-palette-core) + replace literal colors | Pending | Snapshot diff only palette tokens change |
| 17 | Phase 3: Add style API & registration, convert modules to registrations | Pending | style_apply produces identical zstyles |
| 18 | Add finalizer (90-style-finalizer) with guard + snapshot | Pending | saved_zstyles.zsh updated once |
| 19 | Implement variant selection + low-color fallback | Pending | Variant env var switches snapshot palette lines |
| 20 | Remove legacy monolithic file & add rollback shim | Pending | Shim usable; legacy not loaded |
| 21 | Add snapshot diff tests & CI hook | Pending | Test suite passes |
| 22 | Remove shim after 2 stable cycles | Pending | No references remain |

## 6. Success Criteria (Updated)
| Criteria | Target | Current Status |
|----------|--------|-----------------| 
| Script naming convention consistency | 100% underscore format | ✅ Complete |
| Number of compinit invocations | 1 | ⚠️ Needs verification |
| Monolithic styling file referenced | 0 (after consolidation) | ⚠️ Pending |
| Style snapshot drift between shells | None unless variant changes | ⚠️ Pending |

## 7. Next Steps
1. **Verify completion system**: Check that only one compinit occurs
2. **Consolidate styling**: Extract styling from `00_05-completion-finalization.zsh`
3. **Clean up disabled files**: Review `90_99-splash.zsh.disabled`
4. **Merge environment sanitization**: Combine pre-plugins and core sanitization
5. **Update tests**: Ensure all tests reference new script names

---
**Note**: The major script renaming phase is complete. Focus now shifts to functional consolidation and cleanup.
