# ZSH Redesign Architecture (Consolidated)
Version: 2.0  
Status: Authoritative Design Reference  
Last Updated: 2025-01-03

This document defines the architectural intent, structural rules, performance strategies, and extensibility model for the ZSH configuration redesign. It supersedes scattered legacy rationale fragments and is the **single design source** unless superseded by a future version entry in the Change Log.

> If any implementation artifact diverges from principles here, the implementation must be aligned or an explicit architecture decision (ADR-style entry) added to the Decision Log section.

---

## 1. Purpose

Establish a lean, deterministic, testable shell configuration with:
- Predictable startup cost (≥20% reduction vs baseline).
- Strict layering (pre vs post plugin responsibilities).
- Deferred heavy work (IO, hashing, network) until *after* first prompt.
- Observable integrity (fingerprints + async validation).
- Easily auditable change surface (structured inventories, checksums).

---

## 2. Core Principles

| Principle | Description | Enforcement Mechanism |
|-----------|-------------|-----------------------|
| Determinism | Fixed set of 19 modules (8 + 11) with stable numeric ordering | Structure audit + sentinel test |
| Separation of Concerns | Pre-plugin: environment preparation & deferral; Post-plugin: functionality, UX, monitoring | Directory split + gating flags |
| Least Early Work | Only essential path, option, and stub definitions before first prompt | Pre-plugin performance budget |
| Single Responsibility Modules | Each file has 1 cohesive task family | Naming schema + review |
| Explicit Deferment | Expensive operations queued (hashing, plugin scans, nvm load) | Lazy framework + async state machine |
| Observable State | Instrumentation emits machine-parseable logs | perf & async log formats |
| Reversible Change | Inventories + checksums allow rollback validation | verify-legacy-checksums script |
| Guard Discipline | Every module sets a unique sentinel variable | sentinel tests |
| Test-Driven Hard Gates | Architecture rules codified as tests (structure, compinit, perf) | CI gating workflows |
| Zero Hidden Coupling | Imports avoided; communication via environment or global state contract | Published variable contract |

---

## 3. Module Taxonomy

### 3.1 Pre-Plugin (Foundational / Deferral Layer)
| Order | File | Category | Responsibilities | Explicit Exclusions |
|-------|------|----------|------------------|---------------------|
| 00 | path-safety | Path Hygiene | Normalize, deduplicate, early invariants | Plugin logic, aliases |
| 05 | fzf-init | UX Stubs | Keybind placeholders (no heavy load) | Completion initialization |
| 10 | lazy-framework | Infra | Dispatcher, registry, first-call loader | Runtime-specific code |
| 15 | node-runtime-env | Runtime Stubs | nvm/npm lazy shells | Direct `nvm use` invocation |
| 20 | macos-defaults-deferred | OS Integration | Schedule macOS defaults sync safely | Immediate `defaults write` |
| 25 | lazy-integrations | Integrations | direnv/git/copilot wrappers | Direct remote calls |
| 30 | ssh-agent | Security / Session | Single-agent detection & spawn control | Loading keys unprompted |
| 40 | pre-plugin-reserved | Future | Reserved for expansion or dynamic adaptation | Any active logic now |

### 3.2 Post-Plugin (Functional / UX / Validation Layer)
| Order | File | Layer | Description |
|-------|------|-------|-------------|
| 00 | security-integrity | Light Integrity | Schedule baseline fingerprint, define hooks |
| 05 | interactive-options | Shell Behavior | `setopt`, `unsetopt`, `zstyle`, line-edit tuning |
| 10 | core-functions | User API | Helper functions, common wrappers |
| 20 | essential-plugins | Plugin Augment | Post-load plugin glue, env adjustments |
| 30 | development-env | Toolchains | Go/Rust/Node/Python path surfacing |
| 40 | aliases-keybindings | Productivity | Aliases, `bindkey` customizations |
| 50 | completion-history | Completion Core | Single guarded `compinit`, history policies |
| 60 | ui-prompt | Presentation | Prompt (e.g. p10k), color theme finalization |
| 70 | performance-monitoring | Telemetry | Timing capture, segment emission, TTFP metrics |
| 80 | security-validation | Deep Integrity | Deferred hashing, diffs, trust status commands |
| 90 | splash | Cosmetic | Optional info banner / version stamp |

---

## 4. Load Phases

| Phase | Time Boundary | Allowed Activities | Prohibited Activities |
|-------|---------------|--------------------|-----------------------|
| Phase A (Pre-Plugin) | Startup → Before plugin manager restore | Path setup, stubs, deferrals, guards | Remote IO, hashing, compinit |
| Phase B (Plugin Restore) | Plugin manager execution | Plugin caching/restore only | Module side-effects outside manager |
| Phase C (Post-Plugin Core) | Immediately after restore | Options, functions, env layering | Heavy hashing, benchmarking |
| Phase D (User Readiness) | First prompt rendered | Minimal overhead only | Blocking tasks |
| Phase E (Deferred Async) | After first prompt | Hash scans, deep analysis, telemetry refines | UI-blocking loops, synchronous network retries |

---

## 5. Dependency & Coupling Rules

1. **No backward references**: Higher-numbered modules cannot be sourced by lower ones.
2. **State Hand-Off Only**: Communication via environment variables or global associative arrays prefixed:
   - `_LOADED_*` (sentinel)
   - `_ASYNC_PLUGIN_HASH_STATE`
   - `_COMPINIT_DONE`
3. **No cross-module `source`**: Each file stands alone; composition happens via numeric ordered sourcing in driver (`.zshrc`).
4. **Stable Public Contract** (documented in REFERENCE.md):
   - Lazy registration API: `lazy_register <symbol> <loader-script>`
   - Async status command contract (future): `plugin_security_status`.

---

## 6. Lazy Loading Framework Architecture

| Component | Function |
|-----------|---------|
| Registry (`_LAZY_REGISTRY`) | Map from function name → loader code snippet |
| Dispatcher | Interim function body that self-replaces on first invoke |
| Load Guard (`_LAZY_LOADED`) | Prevents duplicate loader invocation |
| Error Handling | Emits error & non-zero exit if loader fails to define target |
| Test Coverage | Unit tests assert first-call semantics, argument propagation, failure modes |

Design Constraints:
- **No recursion**: Loader must replace stub before re-invocation.
- **Deterministic Cost**: Post-first-load calls must not allocate or parse new code.
- **Instrumentation Ready**: Future enhancement may timestamp first-load for perf sampling.

---

## 7. Async Security Validation

| Aspect | Design |
|--------|--------|
| State Machine | IDLE → QUEUED → RUNNING → SCANNING → COMPLETE (→ CLEANUP optional) |
| Queue Trigger | Post-plugin scheduling (module 00/80 interplay) |
| Deferral Guarantee | No `RUNNING` before prompt marker `PERF_PROMPT:COMPLETE` |
| Logging Format | `ASYNC_STATE:<STATE> <EPOCH_FLOAT>` lines + queue marker `SECURITY_ASYNC_QUEUE` |
| Hash Strategy (Future) | Fingerprint plugin directories, diff with baseline snapshot |
| Commands (Planned) | `plugin_security_status`, `plugin_scan_now` |
| Non-Blocking Rule | All hashing in subshell/background; main shell not waiting |
| Tests | Initial+state-machine tests ensure ordering and monotonic timestamps |

---

## 8. Performance & Instrumentation

Instrumentation Names:
- `PRE_PLUGIN_COMPLETE <ms>` (optional future)
- `POST_PLUGIN_COMPLETE <ms>`
- `PERF_PROMPT:COMPLETE <EPOCH_FLOAT>`
- Segment metrics stored in `perf-current.json`.

Budgets:
| Segment | Target |
|---------|--------|
| Pre-plugin | ≤400ms |
| Post-plugin (functional) | ≤500ms |
| Async startup overhead up to prompt | ~0ms (must defer) |

Regression Guard:
- Accepts ≤5% delta; failing results block promotion stage.

---

## 9. Testing Alignment Matrix

| Architectural Rule | Test / Mechanism |
|--------------------|------------------|
| Sentinel presence | `test-redesign-sentinels.zsh` |
| Single compinit | `test-postplugin-compinit-single-run.zsh` |
| Async deferral | `test-async-initial-state.zsh` |
| State transitions | `test-async-state-machine.zsh` |
| Perf thresholds | `test-segment-regression.zsh` |
| Lazy semantics | `test-lazy-framework.zsh` |
| SSH agent correctness | `test-preplugin-ssh-agent-skeleton.zsh` |
| Legacy invariants | `verify-legacy-checksums.zsh` |
| Structure integrity | `promotion-guard.zsh` + structure audit |

---

## 10. Configuration Flags & Gating

| Variable | Purpose | Scope | Future Default |
|----------|---------|-------|----------------|
| `ZSH_ENABLE_PREPLUGIN_REDESIGN` | Toggle redesigned pre-plugin tree | Migration | Enabled post Stage 2 |
| `ZSH_ENABLE_POSTPLUGIN_REDESIGN` | Toggle redesigned post-plugin tree | Migration | Enabled post Stage 5 |
| `ZSH_NODE_LAZY` | Preserve lazy Node stubs even if early load occurs | Performance | On |
| `ZSH_ENABLE_NVM_PLUGINS` | Enable nvm/npm integration loading | User choice | On |
| `ZSH_ENABLE_ABBR` | Optional abbreviation plugin | Feature | Off (opt-in) |
| (Planned) `ZSH_DISABLE_SPLASH` | Disable splash module | Cosmetic | Off |

---

## 11. Sentinel & Guard Patterns

Pattern: `_LOADED_<UPPERCASE_FILE_NAME_WITH_DASHES_AS_UNDERSCORES>`
- Example: `40-aliases-keybindings.zsh` → `_LOADED_40_ALIASES_KEYBINDINGS`
- Pre-plugin optional prefix variant may include domain-specific naming.
- Guard idiom:
  ```zsh
  [[ -n ${_LOADED_XX_NAME:-} ]] && return
  _LOADED_XX_NAME=1
  ```

---

## 12. Naming Conventions

| Element | Pattern |
|---------|---------|
| Module files | `NN-description.zsh` (two-digit padded) |
| Internal helpers | `_zsh_<domain>_<verb>` |
| Globals | Upper snake with domain prefix (`_ASYNC_*`, `_LAZY_*`) |
| Logs (future) | `logs/perf-*.log`, `logs/async-state.log` |
| Badges JSON | `perf.json`, `structure.json`, `summary.json` |

---

## 13. Design Risk Mitigations (Built-in)

| Risk | Mitigation |
|------|------------|
| Hidden coupling | Strict numeric isolation; no cross-source |
| Unexpected early cost | Pre-plugin budget test + perf sampling |
| Multiple integrity scans | State machine gating |
| Plugin breakage via alias overlap | Aliases isolated to `40` after plugin restore |
| Undetected drift | Checksums + inventory freeze |
| Performance flakiness | Multiple run aggregation & stddev filtering |

---

## 14. Extension Points

| Extension | Mechanism | Constraints |
|-----------|-----------|------------|
| Add-on Module | Insert new numeric slot (avoid collisions) | Must update structure audit tests |
| Lazy Loader | `lazy_register name 'loader code'` | Loader must define final real function |
| Security Command | Add to 80 module post-scan dispatch | Must not block when data stale |
| Perf Hook | Precmd injection in 70 module | <5ms overhead |
| Splash Enhancement | 90 module optional info provider | Must respect disable flag |

---

## 15. Forward-Looking Enhancements (Non-Blocking)

| Enhancement | Rationale | Stage Candidate |
|-------------|-----------|-----------------|
| Memory/RSS sampling | Validate footprint improvements | Post Stage 6 |
| Plugin provenance hashing | Strengthen supply chain trust | Stage 6 extension |
| Interactive health command | On-demand status summary | Stage 5+ |
| Graph export (dependency map) | Visual auditing | Post-promotion |
| Stage runner orchestration script | Reduce manual operations | Stage 3+ |

---

## 16. Decision Log (Condensed ADR Index)

| ID | Date | Decision | Rationale | Status |
|----|------|----------|-----------|--------|
| ADR-001 | 2025-01-03 | Numeric rigid layering (8+11) | Predictable load & governance | Accepted |
| ADR-002 | 2025-01-03 | Single compinit centralization (50) | Eliminate duplicate overhead | Accepted |
| ADR-003 | 2025-01-03 | Deferred deep hashing (80 post prompt) | Avoid blocking startup | Accepted |
| ADR-004 | 2025-01-03 | Lazy dispatcher + self-replacement | Minimize warm path cost | Accepted |
| ADR-005 | 2025-01-03 | Artifact/data separation (artifacts/) | Reduce doc noise & churn risk | Accepted |
| ADR-006 | 2025-01-03 | Checksum freeze before content port | Establish rollback anchor | Accepted |

(Extend table as decisions evolve.)

---

## 17. Glossary Quick Map

| Term | Definition |
|------|------------|
| TTFP | Time To First Prompt |
| Segment Timing | Discrete measurement of pre vs post plugin loads |
| Sentinel | Guard variable marking file loaded once |
| Deferred Hashing | Integrity verification after initial user readiness |
| Lazy Loader | Stub replaced on first invocation with real implementation |
| Promotion | Enabling redesigned trees as defaults + regenerating baseline |
| Structure Audit | JSON summary of module count/order/violations |

*See REFERENCE.md for full glossary.*

---

## 18. Compliance Checklist (Architecture → Tests)

| Architecture Requirement | Enforced By | Status |
|--------------------------|-------------|--------|
| 19 total modules | Structure audit | ✅ |
| Sentinels present | Sentinel test | ✅ |
| Single compinit | Compinit single-run test | Pending (content stage) |
| Deferred hashing | Async initial state test | Pending (content) |
| Lazy substitution | Lazy framework unit test | ✅ |
| Performance regression control | Segment regression test | ✅ |
| Checksums stable until promotion | Checksum verify script | ✅ |

---

## 19. Change Log

| Date | Version | Summary |
|------|---------|---------|
| 2025-01-03 | 2.0 | Initial consolidated architecture reference (migration to redesignv2) |

---

## 20. Navigation

[← README (Overview)](README.md) | [Implementation Guide →](IMPLEMENTATION.md) | [Reference](REFERENCE.md)

---
*End of Architecture Document*