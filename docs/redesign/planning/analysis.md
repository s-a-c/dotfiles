# ZSH Configuration Refactor Analysis

Repository Base: $ZDOTDIR = ${XDG_CONFIG_HOME}/zsh (resolved at runtime)
Frameworks: zsh-quickstart-kit + zgenom
Scope: Post-plugin configuration reorganization (.zshrc.d & legacy .zshrc.d.disabled)
Date: 2025-08-29

---
## 1. Current State Inventory

### 1.1 Active `.zshrc.d/` Modules
| Load Order | File | Primary Purpose | Key Concerns |
|------------|------|-----------------|--------------|
| 00_20 | 00_20-plugin-integrity-core.zsh | Core plugin integrity registry & basic hash verification | Split logic (core vs advanced) increases file I/O & parsing overhead; synchronous hashing |
| 00_21 | 00_21-plugin-integrity-advanced.zsh | Advanced hashing, registry management, zgenom hook scaffolding | Duplicates some core helpers; jq/openssl conditional paths; potential performance hit at startup |
| 00_60 | 00_60-options.zsh | Interactive-only option settings & comprehensive commented reference | Large block of commented documentation (fine) but could be lazily readable; number misaligned (00_60 after 00_21) |
| 20_04 | 20_04-essential.zsh | Regenerate & load *essential* plugin subset; emergency safe mode file generation | Potential overlap with zgenom bootstrap; writes file every load (cat >) |
| 30_30 | 30_30-prompt.zsh | Prompt selection (Starship/P10k/fallback) + UI zstyles + theme environment | Mixed concerns (completion styling, prompt modes, colorization) |

### 1.2 Disabled `.zshrc.d.disabled/` (Representative Classification)
All files retained for legacy reference. Functionality inferred from inspection of representative samples (spot readings performed) & naming conventions.

| Prefix Group | Files (Representative) | Purpose Summary | Consolidation Target |
|--------------|-----------------------|-----------------|----------------------|
| 00_02 PATH & Helpers | 00_02-path-system.*, 00_02-standard-helpers.zsh | Early path layering & helper funcs now handled in .zshenv | Remove (superseded) |
| 00_04 Logging | 00_04-unified-logging.zsh | Central logging helpers | Integrate minimal logging into security/perf modules |
| 00_10 / 00_50 Env Hygiene | 00_10-environment.zsh, 00_50-environment-sanitization.zsh | Environment variable defaults & cleanup | Merge into .zshenv (already mostly migrated) |
| 00_12 Source Detection | 00_12-source-execute-detection.zsh | Detect sourcing vs execution | If still needed, lightweight function in core functions file |
| 00_14 Git/Homebrew Priority | 00_14-git-homebrew-priority.zsh | PATH precedence for tools | Already enforced in .zshenv; retire |
| 00_20 Completion Mgmt | 00_20-completion-management.zsh | Compinit gating, cache mgmt | Fold into new 40-completion-history module or prompt UI if minimal |
| 00_22 Async Cache | 00_22-async-cache.zsh | Async caching wrapper utilities | Evaluate necessity; keep lazily loadable |
| 00_28 Completion Finalization | 00_28-completion-finalization.* | Final zstyle tweaks | Merge with prompt/UI styling |
| 00_30 Performance Monitoring | 00_30-performance-monitoring.zsh | Timing & profiling hooks | Become dedicated 70-performance-monitoring.zsh (lazy triggers) |
| 00_40 Review Cycles | 00_40-review-cycles.zsh | Review / audit scheduling | Either cron/out-of-band script or integrate into performance module lazily |
| 00_70 / 00_72 / 00_74 Functions | *functions-core*, *utility*, *tool* | Function libraries segmented by type | Merge into single 30-functions.zsh using autoload/lazy wrappers |
| 00_76 Context-Aware Config | 00_76-context-aware-config.zsh | Conditional config by context (host, CI, etc.) | Integrate detection helpers into core functions; apply in dependent modules only when invoked |
| 00_80 Security Check | 00_80-security-check.zsh | Security hardening (umask, perms) | Consolidate with plugin integrity into 00-security-integrity.zsh |
| 00_90 Validation | 00_90-validation.zsh | Post-load validation tasks | Move to 80-security-validation.zsh (after perf & UI) |
| 10_x Development | 10_00-development-tools.zsh, 10_10-path-tools.zsh, 10_12-tool-environments.zsh, 10_14-git-vcs-config.zsh, 10_16-atuin-init.zsh, 10_50-development.zsh, 10_60-ssh-agent-macos.zsh, 10_70-completion.zsh | Toolchain env exports, VCS settings, Atuin, SSH agent config, completion extras | Merge: 40-development-env.zsh (with conditional lazy loads) |
| 20_x Plugin Staging | 20_00-plugin-metadata.zsh, 20_02-plugin-environments.zsh, 20_06-plugin-integration.zsh, 20_10-deferred.zsh, 20_12-plugin-deferred-core.zsh, 20_14-plugin-deferred-utils.zsh | Deferred plugin hooks & metadata | Keep minimal deferred loader stub; move advanced logic into plugin integrity or functions module (lazy) |
| 30_x UI | 30_00-ui-enhancements.zsh, 30_10-aliases.zsh, 30_20-keybindings.zsh | Aliases, keymaps, UI niceties | Merge into 50-aliases-keybindings.zsh + 60-ui-prompt.zsh |
| 90_x Maintenance | 90_00-disable-zqs-autoupdate.zsh, 90_90-zqs-command.zsh.duplicate-backup | Autoupdate toggles / duplicates | Replace with settings flag or remove duplicates |
| 99_99 Splash | 99_99-splash.zsh | Final banner | Becomes 90-splash.zsh |

### 1.3 Observed Issues
- Fragmentation: 40+ disabled fragments → cognitive load & file I/O overhead.
- Redundant Environment & PATH logic (now centralized in .zshenv but lingering duplicates remain).
- Plugin integrity split across two immediate-load modules (can unify with phased/lazy advanced checks).
- Essential plugin regeneration logic in 20_04 duplicates zgenom bootstrap responsibilities.
- Prompt module mixes theming, completion styling, and unrelated UI exports.
- Lack of strict naming convention alignment (00_20, 00_21 then jump to 00_60, 20_04, 30_30).
- Some modules write files unconditionally at every startup (e.g., emergency safe mode cat > …) increasing startup time & disk churn.

### 1.4 Potential Performance Bottlenecks
| Source | Impact | Optimization Strategy |
|--------|--------|----------------------|
| Multiple early hash computations (plugin integrity) | CPU + I/O | Defer advanced hashing to background or on-demand CLI function |
| Numerous small sourced files | Stat + open cost | Merge into ~10 logically grouped modules |
| Repeated file writing (emergency safe mode) | I/O | Generate only if missing or stale checksum changes |
| Unconditional registry parsing w/ jq check | Startup branching | Cache detection; lazy advanced validation |
| Prompt module heavy initialization (Starship eval or P10k) | Latency | Instant prompt already in place; ensure non-blocking defers for advanced UI styling |

---
## 2. Design Principles for Redesign
1. Minimalism: Only files that encode clear, separable concerns.
2. Deterministic Ordering: Two-digit numeric prefixes in 10-step increments allow insertion room.
3. Lazy Expansion: Functions defined early; heavy work (hashing, scans) triggered by explicit commands or asynchronous post-prompt hook.
4. Single Source of Truth: Environment & global options in .zshenv; interactive-only in one options file.
5. Safety First: Security & integrity initialization early but in lightweight mode; deep checks deferred.
6. Measurable Gains: Track startup time before/after using existing performance scripts.

---
## 3. Proposed New `.zshrc.d.REDESIGN` Structure
Target: 10 files (vs 5 active + 40 archived) balancing granularity and clarity.

| Order | File | Scope | Rationale |
|-------|------|-------|-----------|
| 00 | 00-security-integrity.zsh | Core security (umask, minimal plugin integrity stubs, logging setup) | Early, lightweight, sets hooks only |
| 05 | 05-interactive-options.zsh | All interactive-only setopt/unsetopt | Consolidates options (from 00_60) |
| 10 | 10-core-functions.zsh | Core helpers (safe_* wrappers, context detection, async dispatch) | Unifies functions-core/utility/tool/context files |
| 20 | 20-essential-plugins.zsh | Conditional essential plugin ensure/regenerate (lean) | Refined from 20_04-essential (idempotent, no repeated writes) |
| 30 | 30-development-env.zsh | Dev tooling paths, VCS, SSH/Atuin, tool env exports | Merge of 10_x group |
| 40 | 40-aliases-keybindings.zsh | Aliases, keymaps, globalias, conditional features | Consolidates 30_10 & 30_20 |
| 50 | 50-completion-history.zsh | Completion zstyles & history fine-tune (interactive) | Decouple from prompt file; unify completion mgmt & finalization |
| 60 | 60-ui-prompt.zsh | Prompt/theming selection, UI color, styles, starship/p10k fallback | Cleaner prompt separation |
| 70 | 70-performance-monitoring.zsh | Deferred timing capture, zprof toggle, perf commands | From 00_30-performance-monitoring |
| 80 | 80-security-validation.zsh | Deferred deep plugin hash, registry verification, integrity scan commands | Advanced part of previous 00_21 moved late & lazy |
| 90 | 90-splash.zsh | Final banner & update check trigger | Former splash, non-critical last |

### 3.1 Lazy Loading Hooks
- Use precmd & zsh/async (if available) to trigger advanced plugin hashing after first prompt.
- Provide user commands: `plugin_scan_now`, `plugin_hash_update <name>` for on-demand operations.

### 3.2 File Minimization Justification
Merging function libraries lowers disk reads; separating UI/prompt from completion clarifies editing surface and reduces risk of regression when changing theme logic.

---
## 4. Migration Strategy

### 4.1 Preparation
1. Create backup snapshot: copy existing `.zshrc.d` to `.zshrc.d.backup-<timestamp>`.
2. Preserve disabled legacy: keep `.zshrc.d.disabled` untouched (read-only archive).
3. Record baseline metrics: run performance test script (e.g., `bin/test-performance.zsh` or existing perf harness) 5 times → compute mean & stddev.

### 4.2 Execution Steps (High-Level)
1. Create `.zshrc.d.REDESIGN/` directory.
2. Draft new module files with merged content skeleton & TODO markers where deep logic moves.
3. Implement lazy advanced security (move heavy hash to background function triggered post-prompt).
4. Redirect `.zshrc` loader (temporarily via export `ZSH_REDESIGN=1`) to source redesign directory (conditional branch) for A/B testing.
5. Validate functionality parity (aliases, completions, prompt, plugin load, integrity commands, SSH agent, history behavior).
6. Once validated, rename current `.zshrc.d` → `.zshrc.d.legacy-final` and promote `.zshrc.d.REDESIGN` → `.zshrc.d`.

### 4.3 Rollback Plan
- Single command rollback: move new `.zshrc.d` aside and restore `.zshrc.d.backup-<timestamp>`.
- Keep a generated diff report (store in `docs/redesign/planning/diff-report-<timestamp>.txt`).
- Re-run baseline performance script to confirm restored state.

### 4.4 Integrity & Safety Guards
| Risk | Mitigation |
|------|------------|
| Missing function after merge | Provide temporary shim file logging accesses to unknown symbols |
| Performance regression | Compare mean startup time ± stddev; abort if reduction < 10% in test phase |
| Security check disabled inadvertently | Keep minimal stub verifying registry dir existence in early file |
| Race condition in async hash | Use background job flag & status variable; expose `plugin_security_status` to view progress |

---
## 5. Expected Improvements & Metrics
| Area | Baseline (Est.) | Target | Method |
|------|-----------------|--------|--------|
| Startup Time (cold) | X ms (measure) | -20% | `time zsh -i -c exit` (n=10) |
| Number of sourced post-plugin files | 5 active + 40 legacy | 10 active | Directory count |
| Hashing CPU at startup | Immediate full scan | Deferred/on-demand | Observe `ps` / measured startup CPU profile |
| File writes during startup | Emergency file always rewritten | Conditional (only if absent) | Inspect logs / `fs_usage` sample |
| User cognitive load | >45 fragmented modules | 10 logical modules | Count + documentation clarity survey |

---
## 6. Redundancy & Removal Summary
| Legacy Component | Disposition | Justification |
|------------------|------------|---------------|
| PATH manipulation fragments | Remove | Centralized in .zshenv |
| Multiple function split files | Merge into 10-core-functions | Lower I/O & simpler navigation |
| Split plugin integrity (core/advanced) | Split-phase (00 + 80) | Early lightweight + deferred heavy |
| Emergency safe mode unconditional write | Conditional write-if-missing | Avoid repeated disk churn |
| Completion scattered settings | Unified (50-completion-history) | Predictable edit surface |

---
## 7. Open Questions / Assumptions
| Item | Assumption |
|------|------------|
| Performance harness path | `bin/test-performance.zsh` or `tests/performance/*` available; adjust if different |
| Async availability | If `zmodload zsh/system` / `zmodload zsh/zpty` not available, fallback to synchronous post-first-prompt run |
| jq / openssl presence | Optional enhancements; system may have them (macOS + Homebrew). Provide fallback pathways |

---
## 8. Next Actions
1. Approve proposed structure & naming.
2. Implement skeletal files under `.zshrc.d.REDESIGN` with migration guards.
3. Add instrumentation & background hash job.
4. Run A/B performance & integrity validation.
5. Finalize promotion + generate diff report.

---
Generated as part of redesign planning deliverables.
