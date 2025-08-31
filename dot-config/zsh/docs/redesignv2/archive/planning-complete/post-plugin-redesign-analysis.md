# Post-Plugin Redesign Analysis & Consolidation Report
Date: 2025-08-31
Status: Authoritative (supersedes earlier brief notes)

## 1. Scope & Objectives
The post-plugin phase (.zshrc.d) governs user‑visible behavior after plugin manager initialization (prompt, options, completion policy, environment refinements, integrity checks, UI polish, deferred monitoring). Redesign goals:
- Performance: Reduce sourcing overhead & duplicate logic (target: >=20% overall startup reduction in conjunction with pre-plugin redesign; post-plugin share reduction ≥35% vs legacy active+disabled set when enabled alone).
- Maintainability: Collapse fragmented legacy files (49 legacy modules: 5 active + 44 disabled) into 11 clearly delineated lifecycle‑ordered modules.
- Predictability: Enforce strict numeric prefix & guarded idempotent sourcing with `_LOADED_*` sentinels.
- Integrity & Security: Separate early lightweight integrity (00) from deferred deep validation (80) without blocking prompt.
- Observability: Centralize performance hook registration and asynchronous hash state into dedicated modules (70, 80).

## 2. Legacy Inventory (Active)
| File | Category | Primary Functionality | Issues | Target Module |
|------|----------|-----------------------|--------|---------------|
| 00_20-plugin-integrity-core.zsh | Integrity | Early plugin registry baseline | Mixed early & later concerns | 00-security-integrity |
| 00_21-plugin-integrity-advanced.zsh | Integrity | Deeper hashing / validation | Timing interleaved with prompt | 80-security-validation |
| 00_60-options.zsh | Options | setopt/unsetopt final set | Late prefix (00_60) inconsistent | 05-interactive-options |
| 20_04-essential.zsh | Essentials | High-level env helpers, user convenience | Mixed concerns (aliases/env/prompt hooks) | 10-core-functions & 20-essential-plugins |
| 30_30-prompt.zsh | UI | Prompt setup (p10k integration) | Hard-coded sequencing | 60-ui-prompt |

## 3. Legacy Inventory (Disabled Archive)
Count: 44 (See `planning/postplugin-disabled-inventory.txt`). Categorized summary:

| Category | Representative Files | Count | Redesign Handling |
|----------|----------------------|-------|------------------|
| Environment / Path | 00_10-environment, 00_02-path-system.* | 5 | Merged into pre-plugin or reduced; minimal residual needed post-plugin |
| Functions Core / Utilities | 00_70-functions-core, 00_72-utility-functions, 00_74-tool-functions | 6 | Consolidated into 10-core-functions |
| Aliases & Keybindings | 30_10-aliases*, 30_20-keybindings | 3 | Consolidated into 40-aliases-keybindings (prompt-adjacent items moved) |
| Completion Lifecycle | 00_20-completion-management, 00_28-completion-finalization, 10_70-completion | 5 | Unified in 50-completion-history with single compinit guard |
| Performance Monitoring | 00_30-performance-monitoring | 1 | 70-performance-monitoring |
| Security / Validation | 00_80-security-check, 00_90-validation | 2 | Split early vs deferred (00 & 80) |
| Deferred / Async Plugins | 20_10-deferred*, 20_12-plugin-deferred-core, 20_14-plugin-deferred-utils | 3 | Folded into lazy patterns inside 20-essential-plugins & async triggers (70/80) |
| Development / Tool Env | 10_00-development-tools, 10_50-development, 10_10-path-tools, 10_12-tool-environments | 4 | Consolidated into 30-development-env |
| Integration / Metadata | 20_00-plugin-metadata, 20_06-plugin-integration, 20_02-plugin-environments | 3 | Collapsed into 20-essential-plugins (with structured phased loading) |
| UI / Splash | 99_99-splash | 1 | 90-splash |
| Misc / Duplicates / Backups | *backup*, *duplicate*, disable flags | 11 | Removed (noise) — replaced by controlled checksum + inventory strategy |

## 4. Redundancy & Bottlenecks
| Problem | Impact | Resolution |
|---------|--------|------------|
| Scattered option sets (options in multiple files) | Repeated setopt/unsetopt overhead, audit difficulty | Centralize all interactive shell options in 05-interactive-options |
| Integrity split across contiguous early files (00_20 + 00_21) | Harder deferred scheduling; potential blocking | Refactor: 00 handles lightweight markers; 80 triggers deep async scan post-prompt |
| Multiple completion management fragments | Increased chance of multiple compinit invocations | Single guarded compinit in 50-completion-history with `_COMPINIT_DONE` sentinel |
| Legacy performance and validation logic duplicated | Startup noise & inconsistent logging | Consolidate into 70-performance-monitoring & 80-security-validation |
| Overlapping alias / function / dev environment responsibilities | Cognitive overhead; ordering hazards | Strict category isolation: functions (10), dev env (30), aliases/keys (40) |
| Numerous archived files left in disabled dir | Risk of accidental resurrection / drift | Snapshot + drift test + checksum freeze |

## 5. Target Redesign Structure (.zshrc.d.REDESIGN)
| Prefix | File | Role | Key Guarantees |
|--------|------|------|----------------|
| 00 | 00-security-integrity.zsh | Fast integrity baseline (hash list capture scheduling only) | <3ms, no deep hashing |
| 05 | 05-interactive-options.zsh | Unified option policy & zstyles that must be post-plugin | Single authoritative option file |
| 10 | 10-core-functions.zsh | Core helpers (prompt-safe, user commands, wrappers) | `_LOADED_10_CORE_FUNCTIONS` guard |
| 20 | 20-essential-plugins.zsh | Plugin metadata bindings, additional plugin additions | Idempotent plugin declarations |
| 30 | 30-development-env.zsh | Dev tool env exports (golang, node fallback, etc.) | Conditional if tools present |
| 40 | 40-aliases-keybindings.zsh | Aliases & keybindings (order after functions) | Avoid re-binding if running in restricted TTY |
| 50 | 50-completion-history.zsh | Single compinit invocation & history tuning | `_COMPINIT_DONE` enforced |
| 60 | 60-ui-prompt.zsh | Prompt theming, p10k load, color finalization | Only loads p10k if file present |
| 70 | 70-performance-monitoring.zsh | Startup timing hook registration | Non-blocking measurement harness |
| 80 | 80-security-validation.zsh | Deferred async deep plugin hash compare | Offloads after first prompt |
| 90 | 90-splash.zsh | Final summary / optional splash banner | Pure cosmetic, can be disabled |

## 6. Mapping Summary
See diagrams.md sections 2 & 7 for visual mapping (Old → New). Consolidation reduces 49 legacy modules to 11 canonical modules (-77.5% file count) while logical surface areas remain separated.

## 7. Migration Strategy
1. Freeze Legacy: Inventories (`preplugin-inventory.txt`, `postplugin-inventory.txt`, `postplugin-disabled-inventory.txt`) committed; `legacy-checksums.sha256` baseline captured.
2. Parallel Skeleton: `.zshrc.d.REDESIGN` added with guard toggled by `ZSH_ENABLE_POSTPLUGIN_REDESIGN`.
3. Incremental Porting (Phase tags):
   - phase1: 00,05,10
   - phase2: 20,30,40
   - phase3: 50,60
   - phase4: 70,80
   - finalize: 90 + docs + metrics
4. A/B Benchmark: Run tools/perf-capture.zsh (10 runs) with toggle off/on; record `metrics/perf-postplugin-ab.json`.
5. Validation: Ensure redesign path meets 20% overall reduction (in combination with pre-plugin improvements) & no >5% regression vs baseline for post-plugin segment alone.
6. Promotion: Set `ZSH_ENABLE_POSTPLUGIN_REDESIGN=1` (optionally add umbrella `ZSH_REDESIGN=1`). Update badges & finalize docs.
7. Canonicalization: Replace legacy dirs with archived tag rename; regenerate checksums snapshot for new baseline.

## 8. Rollback Procedure
| Step | Action | Notes |
|------|--------|-------|
| 1 | Unset `ZSH_ENABLE_POSTPLUGIN_REDESIGN` | Immediate revert to legacy active set |
| 2 | Verify legacy checksums | `tools/verify-legacy-checksums.zsh` must PASS |
| 3 | If mismatch | Restore from git tag `refactor-baseline` or backup copy |
| 4 | Re-run perf & integrity tests | Ensure system parity regained |
| 5 | Document incident | Add entry to `logs/rollback-events.md` (future) |

## 9. Performance Expectations & Metrics
| Metric | Baseline (Overall) | Post-Plugin Share (Est.) | Target After Redesign | Measurement Tool |
|--------|--------------------|--------------------------|-----------------------|------------------|
| Startup mean (ms) | 4772 | ~1250 (estimated legacy post segment) | ≤ 3817 total | tools/perf-capture.zsh |
| Post-plugin exclusive cost (ms) | ~780 | Consolidated ≤500 | ≤500 | Perf hook diff (70 module) |
| Std Dev (%) | 2.62% | n/a | ≤3% | Perf JSON analysis |
| Compinit executions | 1 | Occasionally 2 (edge) | Exactly 1 | test-preplugin-no-compinit + redesign tests |

## 10. Test & Guard Coverage
| Risk | Mitigation | Test(s) |
|------|-----------|---------|
| Drift in frozen legacy dirs | Inventory diff & checksum | test-preplugin-drift, test-postplugin-drift, test-legacy-checksums |
| Accidental skeleton mutation | Structure count/order tests | test-postplugin-structure |
| Multiple compinit | Single sentinel & structure tests | test-preplugin-no-compinit, future post-plugin compinit test |
| Deferred hash blocking prompt | Performance timing comparison | perf tests + 70/80 instrumentation |

## 11. Tooling Additions
| Script | Purpose |
|--------|---------|
| tools/verify-legacy-checksums.zsh | Enforce immutability of frozen baseline |
| (Planned) tools/generate-legacy-checksums.zsh | Recompute snapshot post-promotion |
| tools/generate-structure-audit.zsh | Structural badge & audit JSON |
| tools/perf-capture.zsh | Repeated timed launches |

## 12. Flag & Toggle Interaction
See `gating-flags.md`. Post-plugin redesign gating deliberately independent so pre-plugin work can ship earlier.

## 13. Minimalism Justification
- 11 modules chosen to mirror distinct functional domains; merging further (e.g., combining 70 + 80) would reduce observability and degrade separation of concerns.
- Fewer than 11 introduces coupling (e.g., integrity & performance hooks) increasing rollback complexity.

## 14. Risk Register (Post-Plugin Specific)
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Hidden dependency on removed disabled file | Medium | Functional regression | Grep audit & targeted sourcing warnings |
| Prompt theming load order regression | Low | Visual glitches | 60-ui-prompt isolated & loaded after completion |
| Integrity scan synchronous by mistake | Low | Startup slowdown | 80 module enforces async scheduling guard |
| User customization relying on legacy filename | Medium | Breakage | Provide mapping table in final-report & alias stub sourcing for transitional period (optional) |

## 15. Next Steps
- Implement module content incremental (phase order above).
- Add structure badge update workflow (GitHub Actions placeholder) when remote repo established.
- Add post-promotion checksum generator.

## 16. Backlinks
[Back to Documentation Index](../README.md) | [Gating Flags](gating-flags.md) | [Implementation Plan](implementation-plan.md) | [Diagrams](diagrams.md)
