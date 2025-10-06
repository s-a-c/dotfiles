# ZSH Redesign Architecture (Consolidated)

## Part 08.19.10 — Classifier, Badges, and CI Updates

This section summarizes the latest stabilization and CI publishing work that complements the architecture:

- GOAL profiles and gating (flags-driven)
  - Profiles: streak, governance, explore, ci — applied via `apply_goal_profile` internal flags (ALLOW_SYNTHETIC_SEGMENTS, REQUIRE_ALL_METRICS, HARD_STRICT, STRICT_PHASED, SOFT_MISSING_OK, JSON_PARTIAL_OK, EPHEMERAL_FLAG).
  - Observe mode: always exit 0; Enforce mode: exit reflects worst status and strict gating (e.g., governance/ci disallow synthetic and require all metrics).
- Single-metric JSON parity (always-before-exit)
  - Single-metric path now writes JSON before any enforce-mode exit, matching multi-metric ordering (deterministic artifacts in CI even on failure).
- Capture-runner noise suppression
  - Prompt-ready capture stderr noise (“bad math expression”) is suppressed without altering capture logic or metrics.
- Dynamic badges
  - goal-state badge (docs/redesignv2/artifacts/badges/goal-state.json): governance/ci/streak/explore compact state mapping.
  - summary-goal badge (docs/redesignv2/artifacts/badges/summary-goal.json): composes goal-state and folds in perf drift badge (perf-drift.json) and structure badge (structure.json) as suffixes; overall color reflects worst severity across these signals.
- CI integration and publishing
  - Strict classifier workflow (macOS): GOAL=ci enforce emits perf-current.json and goal-state badge.
  - Nightly/push publisher (Ubuntu): runs classifier, generates goal-state and summary-goal, ensures perf-drift and structure badges, publishes artifacts to gh-pages with an index.
  - Post-publish step: auto-updates root README to replace placeholder Shields endpoints with the repo’s actual `/<org>/<repo>/gh-pages/badges/...` URLs after the badges land on gh-pages.

Shields endpoints (placeholders in docs; auto-resolved in README after first gh-pages publish):
- Goal-state: https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/goal-state.json
- Summary-goal: https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/summary-goal.json
Version: 2.2
Status: Authoritative Design Reference
Last Updated: 2025-09-10 (Part 08.19 – Logging migration complete & instrumentation status refresh)

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

### Stage 4 Sprint 2 Status (Part 08.19 Refresh)
- Logging homogeneity complete: legacy underscore wrappers removed; gate test green (no `ZF_LOG_LEGACY_USED`)
- Real segment probes active (anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total` + granular feature/dev/env/security segments)
- Deferred dispatcher skeleton operational (one-shot postprompt; `DEFERRED id=<id> ms=<int> rc=<rc>` telemetry lines stable)
- Structured telemetry flags available (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) — inert when unset (zero overhead)
- Multi-metric performance classifier in observe mode (Warn 10% / Fail 25%); enforce activation pending 3× OK streak (S4-33)
- Dependency export & DOT generator integrated (`zf::deps::export`)
- Privacy appendix published & referenced; redaction whitelist stabilized
- Baseline unchanged: 334ms cold start (RSD 1.9%) — no regression after new instrumentation

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
- **Test infrastructure upgraded:** All modules and tests validated for standards-compliant isolation (`zsh -f`), CI compatibility, and robust reporting.
- **Logging namespace migration complete:** Legacy underscore wrappers removed; homogeneity gate enforced (no remaining underscore logging calls; gate tests green).
- **Instrumentation status:** Real segment probes emitted (phase + granular), deferred dispatcher skeleton active (one-shot postprompt, `deferred_total` captured), multi-metric performance classifier in observe mode (OK/WARN/FAIL thresholds 10% / 25%); enforce-mode activation (S4-33) pending 3× consecutive OK streak (governance row to be appended to PERFORMANCE_LOG).

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
| **Standards-Compliant Test Infrastructure** | All tests run in isolated shells (`zsh -f`), explicit dependency declaration, robust reporting | Upgraded runner, CI enforcement, documentation migration |

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

### 8.1 Multi‑Metric Classifier Governance

The performance regression classifier evaluates four primary metrics each run:
| Metric Key | Source Derivation | Baseline Artifact | Typical Budget (delta vs baseline) |
|------------|-------------------|-------------------|------------------------------------|
| `pre_plugin_total_ms` | Anchors `pre_plugin_start` → `pre_plugin_total` | `artifacts/metrics/pre_plugin_total-baseline.json` | Warn 10% / Fail 25% |
| `post_plugin_total_ms` | Post‑plugin functional span until boundary emission | `artifacts/metrics/post_plugin_total-baseline.json` | Warn 10% / Fail 25% |
| `prompt_ready_ms` | Sum (pre + post + prompt finishing delta) | `artifacts/metrics/prompt_ready-baseline.json` | Warn 10% / Fail 25% |
| `deferred_total_ms` | Deferred dispatcher batch (first pass) | `artifacts/metrics/deferred_total-baseline.json` | Warn 10% / Fail 25% |

Classifier Modes:
- observe: Always exits 0; creates missing baselines (first run) – status may be `BASELINE_CREATED`.
- enforce: Fails build on WARN/FAIL thresholds (WARN = non‑zero exit chosen by workflow policy; FAIL = hard failure).

Baseline Integrity & Schema Tests (CI Step “Telemetry Governance”):
- `tests/performance/telemetry/test-classifier-baselines.zsh` (with `ENFORCE_BASELINES=1`) ensures required baseline JSON files exist & are sane.
- `tests/performance/telemetry/test-structured-telemetry-schema.zsh` enforces allowed structured telemetry keys (privacy guard).

README / Reference Synchronization:
- Canonical segment & disable‑flag table lives in REFERENCE.md §5.3.
- `tools/sync-readme-segments.zsh` mirrors §5.3 into README inside managed markers to prevent drift (future CI `--check` gate).

Enforce‑Mode Activation Requirements:
1. 3× consecutive classifier overall `OK` runs (no WARN/FAIL).
2. Baseline integrity + schema tests green.
3. No pending segment definition changes.
4. RSD (variance) stable (≤5%) across recent prompt_ready samples.
5. README sync check passes (`tools/sync-readme-segments.zsh --check`).

Governance Logging:
- Activation recorded as a `governance` row in PERFORMANCE_LOG (Type=governance; Scope=performance-classifier) with zero Δ values.
- Any WARN/FAIL in enforce mode requires either mitigation (feature optimization) or regression investigation row.

Rollback Path:
- Temporarily re‑run classifier in observe mode (manual dispatch) if environmental noise suspected.
- Never delete baseline files unless intentionally re‑baselining; create a governance note if re‑baselining is required.

Privacy & Schema Evolution:
- New telemetry keys must: (a) be added to REFERENCE §5.3.2, (b) updated in privacy appendix, (c) allowed by schema validator, (d) included in sync script output.

Future Enhancements (Planned):
- Percentile capture (P50/P95) per metric
- Streak badge for enforce‑mode eligibility
- Trend slope detector for early drift warnings

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
| Structured Telemetry Channel | `ZSH_LOG_STRUCTURED` gated JSON emission | Opt-in only; schema changes require Privacy Appendix + Change Log update; zero overhead when disabled |

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
| 2025-09-10 | 2.2 | Stage 4 Sprint 2: segment anchors (pre_plugin_start, post_plugin_total, prompt_ready, deferred_total), deferred dispatcher, structured telemetry flags, privacy appendix published |
| 2025-01-03 | 2.0 | Initial consolidated architecture reference (migration to redesignv2) |

---

## 20. Navigation

[← README (Overview)](README.md) | [Implementation Guide →](IMPLEMENTATION.md) | [Reference](REFERENCE.md)

---
*End of Architecture Document*
