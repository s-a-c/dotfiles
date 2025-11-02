# ZSH Configuration Architecture Overview
Date: 2025-08-30
Status: Baseline Architecture Documented (Pre-Redesign Consolidation Still Pending)

## 1. High-Level Architecture
Startup phases (current state):
1. /usr/bin/env zsh invoked (interactive or non-interactive)
2. .zshenv (XDG setup, PATH baseline, history vars, plugin manager paths, helper functions)
3. .zshrc
   - Enable optional profiling (zprof)
   - Instant prompt (p10k) preload if cache present
   - Load pre-plugin fragments (.zshrc.pre-plugins.d/*)
   - Initialize zgenom (plugin manager)
   - Source .zgen-setup (plugin definitions & builds)
   - Load post-plugin fragments (.zshrc.d/*)
   - Finalization: PATH dedupe, prompt configuration, self-update checks
4. Prompt ready (TTFP)
5. (Planned) Deferred async tasks (perf capture, advanced integrity) after first prompt

Design Style: Modular directory-driven sourcing via load-shell-fragments using glob expansion; numeric prefixes partially enforce order (inconsistent across directories).

## 2. Active Configuration Inventory
| Layer | Path | Files / Description |
|-------|------|---------------------|
| Core Env | .zshenv | XDG dirs, PATH, history, safe wrappers (safe_git), plugin manager root resolution |
| Main Orchestrator | .zshrc | Pre/post fragment loader, plugin init, aliases, completion zstyles, SSH key mgmt, prompt, update checks |
| Pre-Plugin Fragments | .zshrc.pre-plugins.d | 00_00..20_11 (12 files) path fixes, fzf, lazy frameworks, SSH agent prep, git config, direnv, gh/copilot, macOS defaults deferral |
| Post-Plugin Fragments | .zshrc.d | 5 active: integrity core+advanced, options, essential plugins ensure, prompt |
| Plugin Manager | .zgen-setup + vendored zgenom | Defines plugin list & builds cache |
| Security Registry | security/plugin-registry | trusted-plugins.json, default-trusted.json |
| Tool Scripts | bin/ | 18 operational scripts for diagnostics, performance, integrity, repair |
| Test Harness | tests/ | Structured by category (style, perf, security, validation, miscellany) phased directories |
| Tools (Aux) | tools/ | perf-capture, rebuild-completions, weekly-security-maintenance, generate-perf-badge, run-nightly-maintenance, notifier |

## 3. Disabled / Legacy Fragment Inventory Summary
52 legacy files in .zshrc.d.disabled including: environment sanitization, duplicate path logic, segmented function libraries (00_70/72/74), UI alias/keybinding splits, plugin deferred components, performance monitoring, review cycles, validation, splash. These represent fragmentation, duplication, and inconsistent numbering.

## 4. Sourcing Hierarchy & Order
```mermaid
flowchart TD
    A[Invoke zsh] --> B[.zshenv]
    B --> C[.zshrc]
    C --> D[Pre-Plugin Fragments]\n.zshrc.pre-plugins.d
    D --> E[zgenom init]\n(plugin cache/build)
    E --> F[.zgen-setup]\n(plugin definitions)
    F --> G[Post-Plugin Fragments]\n.zshrc.d
    G --> H[Prompt + Finalization]\n(p10k, updates)
    H --> I[User Interaction]
```

## 5. Completion System Workflow (Current)
compinit is intentionally suppressed from automatic autoload (ZGEN_AUTOLOAD_COMPINIT=0 in .zshenv). Completion zstyles are defined directly in .zshrc after plugin loading. Some completion plugin scripts (e.g. cached _bun) may trigger autoload of compinit internally. Unified target is single explicit compinit after fpath settled.

## 6. Design Patterns
- Directory-driven modular sourcing (load-shell-fragments) with pattern `dir/*(N)` ignoring non-existent.
- Numeric prefix but inconsistent spacing/jumps (00_20 → 00_60 → 20_04 → 30_30), harming readability and insertion planning.
- Early environment normalization inside .zshenv reduces duplication but legacy duplicates remain disabled.
- Lazy functional dispatch (planned) not yet centralized; async tasks not yet established (scripts exist but not integrated into live flow).

## 7. Identified Architectural Issues
| Severity | Issue | Impact | Recommendation |
|----------|-------|--------|---------------|
| Critical | Dual integrity modules (00_20 & 00_21) synchronous | Startup CPU & I/O | Split-phase with deferred heavy hashing (planned 80-security-validation) |
| Critical | Fragmentation (5 active + 52 legacy) | Cognitive load, file stat overhead | Consolidate into ~10 redesign modules |
| Major | Inconsistent prefix increments | Ordering ambiguity | Adopt 00,05,10,... mapping |
| Major | Completion zstyles in .zshrc mixed with other logic | Maintenance burden | Move to dedicated completion-history module |
| Major | Prompt file mixes UI + completion styling | Coupling | Separate prompt vs completion modules |
| Major | Options spread historically | Potential drift | Single options file (05-interactive-options) |
| Major | Legacy function splits (core/utility/tool) | Excess sourcing | Merge into core-functions (autoload/lazy) |
| Major | No centralized async dispatcher | Hard to add deferred tasks | Introduce simple queue or background trigger wrapper |
| Minor | Backup & .bak fragments in disabled dir | Noise | Purge or archive outside runtime tree |
| Minor | Duplicated path adjustments (legacy) | Redundant operations | Keep only .zshenv logic |
| Minor | Mixed naming (aliases vs keybindings vs UI) | Inconsistency | Standardize camel→kebab naming |

## 8. Safe Git Wrapper Status
safe_git implemented in .zshenv prioritizing /opt/homebrew/bin/git > /usr/local/bin/git > system git. No _lazy_gitwrapper symbol present; redundant wrappers not found.

## 9. Performance Considerations (Baseline Observations)
- Non-interactive optimized path ~47ms (reported) vs interactive ~2650ms pre-optimizations (historic). Dominant costs: plugin manager initialization + prompt initialization + integrity hashing.
- Opportunity: Deferred hashing & performance monitoring (moved post first prompt), starship/p10k conditional loading validations, zcompile optional pass.

## 10. Completion Audit (Summary)
Search results show compinit references only in archives/backups and plugin completion cache. Active configuration controls auto-compinit via ZGEN_AUTOLOAD_COMPINIT=0. Need explicit single compinit invocation in future completion-history module with guard:
```zsh
if [[ -z ${_COMPINIT_RAN:-} ]]; then
  autoload -U compinit && compinit -C
  _COMPINIT_RAN=1
fi
```
All sessions should point to a shared compdump path set by ZGEN_CUSTOM_COMPDUMP (${ZSH_CACHE_DIR}/zcompdump_${ZSH_VERSION}). Ensure directory existence and consistent permissions.

## 11. Proposed Module Consolidation (Target)
See redesign plan (implementation-plan.md) Section 1; target 00..90 modules enumerated with responsibilities.

## 12. Dependency & Interaction Mapping
| Module (Proposed) | Depends On | Provides |
|-------------------|-----------|----------|
| 00-security-integrity | .zshenv | Minimal registry, safe logging |
| 05-interactive-options | 00 | setopt/unsetopt, history config |
| 10-core-functions | 00 | shared helpers, async dispatch |
| 20-essential-plugins | zgenom cache | idempotent ensure & guard |
| 30-development-env | 10 | SSH/VCS/tool exports |
| 40-aliases-keybindings | 05,10 | user commands shortcuts |
| 50-completion-history | zgenom loaded fpath | compinit guard + zstyles + hist tuning |
| 60-ui-prompt | starship/p10k | theme/prompt assembly |
| 70-performance-monitoring | 10 | capture timing, benchmark cmds |
| 80-security-validation | 00,10 | deep hashing, tamper detection |
| 90-splash | all prior | final banner/report |

## 13. Improvements Roadmap (Extract)
| Phase | Focus | Key Deliverables |
|-------|-------|------------------|
| 1–2 | Baseline + Backup | Metrics, immutable snapshot |
| 3 | Skeleton | Guarded empty module set |
| 4–5 | Migration | Core + feature parity |
| 6 | Deferred/Async | Background integrity & perf hooks |
| 7 | Validation | ≥20% startup reduction verified |
| 8 | Promotion | Directory swap & tags |
| 9 | Documentation | Final reports & maintenance guide |
| 10–12 | CI/CD+Enhancements | Workflows, badges, zcompile, diff alerts, maintenance cron |

## 14. Risk Matrix (Condensed)
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Startup regression | Medium | High | Performance gate test & rollback tag |
| Missed function migration | Low | Medium | whence audit + unit tests |
| Security regression (deferred hashing) | Low | High | Minimal early stub & user command status |
| Async race | Low | Medium | Single state var + serialized queue |

## 15. Action Items (Architecture-Specific)
| ID | Action | Priority | Effort | Status |
|----|--------|----------|--------|--------|
| A1 | Introduce single compinit guard in new completion module | ⬛ | 10m | Pending |
| A2 | Consolidate function libs -> 10-core-functions | ⬛ | 45m | Pending |
| A3 | Implement async hashing queue | 🔶 | 60m | Pending |
| A4 | Relocate completion zstyles | 🔶 | 20m | Pending |
| A5 | Remove backup *.bak fragments from disabled dir | 🔵 | 10m | Pending |
| A6 | Add structure drift test (file count/prefix) | 🔶 | 25m | Pending |
| A7 | Add compdump path validation test | 🔵 | 15m | Pending |
| A8 | Add memory sampling harness (optional) | ⚪ | 40m | Pending |

## 16. Cross-References
- Detailed Tasking: implementation-plan.md
- Issues & Recommendations: ../review/issues.md
- Completion Audit: ../review/completion-audit.md
- Testing Strategy: ../testing/strategy.md

---
(End of architecture overview)
