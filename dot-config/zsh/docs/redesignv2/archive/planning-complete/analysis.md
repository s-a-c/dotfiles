# ZSH Configuration Refactor Analysis

Repository Base: $ZDOTDIR = ${XDG_CONFIG_HOME}/zsh (resolved at runtime)
Frameworks: zsh-quickstart-kit + zgenom
Scope: Post-plugin configuration reorganization (.zshrc.d & legacy .zshrc.d.disabled) plus planning foundation for pre-plugin redesign
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
(Representative classification — condensed for brevity; full enumeration retained in legacy archive.)

| Prefix Group | Purpose Summary | Consolidation Target |
|--------------|-----------------|----------------------|
| 00_02 PATH & Helpers | Early path layering & helper funcs now handled in .zshenv | Remove (superseded) |
| 00_04 Logging | Central logging helpers | Integrate minimal logging into security/perf modules |
| 00_10 / 00_50 Env Hygiene | Environment defaults & cleanup | Merge into .zshenv (mostly migrated) |
| 00_12 Source Detection | Detect sourcing vs execution | Lightweight function in core functions file |
| 00_20 / 00_28 Completion Mgmt/Finalization | Compinit gating & zstyles | New 50-completion-history module |
| 00_30 Performance Monitoring | Timing & profiling hooks | 70-performance-monitoring (deferred) |
| 00_70/72/74 Functions | Segmented function libraries | 10-core-functions merge |
| 00_80 Security Check | Security hardening | 00-security-integrity (light) + 80-security-validation (deferred) |
| 10_x Development | Toolchain env, SSH agent, VCS | 30-development-env |
| 30_x UI (aliases/keybindings/prompt) | Aliases & keymaps | 40-aliases-keybindings + 60-ui-prompt |
| 99_99 Splash | Final banner | 90-splash |

### 1.3 Observed Issues
- Fragmentation (5 active + many legacy fragments)
- Redundant ENV/PATH logic now centralized in .zshenv
- Synchronous advanced hashing early in critical path
- Prompt file conflates multiple concerns
- Non-monotonic prefix ordering

### 1.4 Potential Performance Bottlenecks
| Source | Impact | Optimization Strategy |
|--------|--------|----------------------|
| Early hash computations | CPU + I/O | Defer advanced hashing (async) |
| Numerous small files | Stat + open cost | Merge into targeted ~11 modules |
| Repeated file writes | Disk churn | Conditional generation |
| Prompt heavy init | Latency | Isolate & evaluate lazy prompt strategies |

---
## 2. Design Principles for Redesign
1. Minimalism
2. Deterministic Ordering
3. Lazy Expansion
4. Single Source of Truth (.zshenv + focused option file)
5. Safety & Observability
6. Measurable Gains

---
## 3. Proposed New `.zshrc.d.REDESIGN` Structure (Post-Plugin)
- Target: 11 files (00..90) replacing 5 active + legacy ~40
- Rationale per-file (expanded):
  - 00-security-integrity: minimal umask, registry dir ensure, safe logging shim, NO heavy hashing
  - 05-interactive-options: interactive-only set/unset, history policies, shell option convergence
  - 10-core-functions: safe_* wrappers, async dispatch stub, plugin registry helper funcs, feature flags, common logging
  - 20-essential-plugins: idempotent ensure/regenerate with timestamp/hash short-circuit, no unconditional writes
  - 30-development-env: VCS (git), SSH agent mgmt (no duplicate agent), Atuin init, language toolchain env exports (non-blocking)
  - 40-aliases-keybindings: merged aliases, keymaps, globalias, keybinding sanity checks
  - 50-completion-history: single guarded compinit + zstyles + history dedupe fine‑tune
  - 60-ui-prompt: starship/p10k loader, instant prompt synergy, color/style abstraction
  - 70-performance-monitoring: precmd timing capture, perf sample commands, optional zprof trigger
  - 80-security-validation: deferred deep hashing (async), tamper diff, user commands plugin_scan_now / plugin_hash_update
  - 90-splash: concise banner, delta summary (startup ms vs baseline), async status summary once available

### 3.1 Node / NPM Reactivation (Cross-Cut)
Planned division: pre-plugin stub wrappers (15-node-runtime-env) + conditional plugin activation (add-plugins optimization). Lazy strategy ensures first call to `nvm`, `node`, `npm`, or configured lazy-cmd list triggers sourcing only once; performance harness measures first vs subsequent invocation.

### 3.2 Acceptance Criteria Per Module
| Module | Critical Behaviors | Test Category |
|--------|-------------------|---------------|
| 00 | Creates registry dir; sets umask; defines status stub | unit/security |
| 05 | Sets documented options; no unintended unset of safety opts | unit/design |
| 10 | Exports helper funcs; no duplicate symbols; async dispatcher placeholder present | unit |
| 20 | Skips rebuild when cache fresh; rebuild when timestamp/hash stale | feature/perf |
| 30 | Starts agent only when absent; Atuin init idempotent | feature |
| 40 | All legacy aliases preserved; no recursion | feature |
| 50 | Exactly one compinit; compdump path exists; zstyles applied | integration |
| 60 | Prompt selection respected; fallback prompt always renders | integration |
| 70 | Timing log lines appended post first prompt only | perf |
| 80 | Heavy hashing NOT before first prompt; status reports phases | security/perf |
| 90 | Splash displays summary (perf delta + async status) | integration |

---
## 4. Migration Strategy (Summary)
Baseline → Backup → Skeleton → Phase 1 (security/options/functions) → Phase 2 (plugins/dev/aliases/completion/prompt) → Deferred (perf/integrity) → Validation → Promotion → Docs.

---
## 5. Expected Improvements & Metrics
| Area | Baseline | Target |
|------|----------|--------|
| Startup Mean | Measure | -20% |
| Active Post-Plugin Files | 5 (active) | 11 logical modules |
| Early CPU Hashing | Full | Stub only |

---
## 6. Redundancy & Removal Summary
See consolidation/plan.md for mapping.

---
## 7. Open Questions / Assumptions
| Item | Assumption |
|------|-----------|
| Async availability | zsh/async optional; fallback safe |
| jq/openssl presence | Optional enhancements only |

---
## 8. Pre-Plugin Redesign (Expanded)
Planned directory `.zshrc.pre-plugins.d.REDESIGN` (8 files). Goals: collapse 12 → 8; ensure zero compinit; provide lazy infra.

| New File | Detailed Responsibilities | Deferred / Guarded Elements |
|----------|--------------------------|-----------------------------|
| 00-path-safety | PATH normalization, elimination of duplicates (final dedupe skipped here), early HOME/HOMEBREW detection, realpath fallbacks | No network / toolversion probing |
| 05-fzf-init | FZF key-bindings & env var exports if installed; skip install scripts; fail gracefully if missing | No git clone / install attempts |
| 10-lazy-framework | Define generic lazy-loader helper (register command stub → loads real impl on first call), schedule post-prompt tasks list | No plugin sourcing here |
| 15-node-runtime-env | Provide stub nvm(), npm() wrappers; configure NVM_DIR detection chain; set NVM_AUTO_USE, lazy styles; first call sources nvm.sh & bash_completion | No nvm.sh sourcing at load time |
| 20-macos-defaults-deferred | Queue macOS defaults audit only if macOS; background job; log results (skip on non-mac) | Deferred execution via zsh/async when available |
| 25-lazy-integrations | direnv wrapper (loads on first entering a dir with .envrc), git config cache warm stub, gh/copilot lazy alias | No network hits until invocation |
| 30-ssh-agent | Detect existing agent; launch if absent; permission check on keys; export SSH_AUTH_SOCK | No key generation |
| 40-pre-plugin-reserved | Guard-only placeholder (future instrumentation) | N/A |

Performance budget (aggregate pre-plugin) ≤ 35ms target (baseline capture to confirm).

### 8.1 Pre-Plugin Test Additions
- Structure test ensuring 8 files (flag‑gated until active)
- `test-preplugins-no-compinit.zsh`: grep trace output; assert no compinit call
- `test-nvm-lazy-load.zsh`: call `nvm current` twice → second call < first time; stub replaced.

### 8.2 Interaction With Post-Plugin Phase
Node plugin activation (nvm/npm) from add-plugins file behind `ZSH_ENABLE_NVM_PLUGINS`; if disabled, lazy stubs still function using local node; design test ensures order (stub pre-plugin before plugin definitions).

---
## 9. Add-Plugins Optimization (Expanded)
Detailed phased layout added (see plugin-loading-optimization.md). Implementation tasks integrate into Implementation Plan phases P4–P6 (pre-plugin) and main Phase 5.

| Phase | Plugin Group | Load Conditions | Guard Variables |
|-------|--------------|-----------------|-----------------|
| 01 | Core ergonomics (autopair, abbr?) | Always (abbr only if `ZSH_ENABLE_ABBR=1`) | `_LOADED_CORE_ERGO` |
| 02 | Dev base (composer, laravel, gh, iterm2) | Always | `_LOADED_DEV_BASE` |
| 03 | Node ecosystem (nvm/npm) | `ZSH_ENABLE_NVM_PLUGINS=1` else skip | `_LOADED_NODE_PLUGINS` |
| 04 | Nav & files (aliases, eza, zoxide) | Always | `_LOADED_NAV_FILES` |
| 05 | Completion & fzf | Always before completion-history | `_LOADED_COMP_STACK` |
| 06 | Perf/Async (evalcache, async, defer) | Always last | `_LOADED_PERF_ASYNC` |

Each phase appended to an ordered array for design test verification.

### 9.1 Cross-Links
See also: pre-plugin-redesign-spec.md (early phase consolidation), plugin-loading-optimization.md (phase sequence), implementation-plan.md (task IDs), prefix-reorg-spec.md (naming invariants).

---
**Navigation:** [← Previous: Index](../README.md) | [Next: Diagrams →](diagrams.md) | [Top](#) | [Back to Index](../README.md)
