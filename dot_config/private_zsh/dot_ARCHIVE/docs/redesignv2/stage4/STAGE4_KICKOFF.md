# ZSH Redesign – Stage 4 Kickoff (Feature Layer Implementation)

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

> This document inaugurates Stage 4 (Feature Layer) following successful completion of Stage 3 stabilization, migration, and compliance hardening.

## 1. Purpose
Establish the Feature Layer: a modular, test-driven, policy-compliant set of higher-level user experience and productivity capabilities that sit above the stable bootstrap and core layers without compromising determinism, performance, or maintainability.

## 2. Stage 3 Baseline (Reference Snapshot)
- Unified test runner: `run-all-tests-v2.zsh` (all legacy references migrated / deprecated)
- Test suite: 67+ tests across 6 categories; all runnable under `zsh -f`
- Performance baseline: 334ms cold startup (variance ~1.9%)
- CI workflows updated and aligned (zsh-test-redesign.yml, kit-ci.yml, zsh-redesign-flagged.yml)
- Policy + compliance headers embedded across artifacts
- Manifest & isolation invariants validated
- Tracking + documentation synchronized (implementation plan, migration checklist, completion summary)

This baseline is the performance + correctness reference for all Stage 4 delta assessments.

## 3. Strategic Objectives for Stage 4
1. Introduce a formally defined Feature Layer architecture (registry, lifecycle, dependency metadata).
2. Enable safe opt-in/opt-out for discrete features (env + internal DSL).
3. Preserve (or improve) performance budget; enforce guardrails.
4. Guarantee graceful degradation on feature failure.
5. Enforce deterministic load ordering and explicit dependency resolution.
6. Provide per-feature test coverage (unit, integration, performance delta).
7. Create a foundation for future profile-based configurations (minimal vs full).

## 4. Principles
| Principle | Description | Enforcement Vector |
|-----------|-------------|--------------------|
| Isolation | No mutation of global UX state before controlled init hook | Contract tests |
| Deterministic Order | Explicit registry order + dependency graph validation | Registry + tests |
| Failure Containment | Exceptions in feature init do not abort shell | Harness wrapper |
| Deferred Loading | Non-critical features load after first prompt | Loader timing |
| Performance Budget | Hard + soft thresholds on cold start & per-feature | Perf tests |
| Test-Driven Onboarding | Feature PR rejected without tests | CI gate |
| Minimal Core Purity | Core remains agnostic of feature specifics | Code reviews |
| Config Transparency | `ZSH_FEATURES_ENABLE` / `ZSH_FEATURES_DISABLE` semantics documented | Docs + tests |
| Policy Compliance | Compliance header + rule citation for sensitive actions | Static check |
| Observability (Opt-In) | Timing / status introspection when enabled | Telemetry module |

## 5. Proposed Feature Inventory (Initial Backlog)

### Prompt / UI
- Modular prompt segments (left/right)
- Async git status + caching
- RPROMPT policy + conditional suppression (narrow widths)

### History & Interaction
- Timestamped + session-scoped history enrichment
- Enhanced incremental + fuzzy search fallback
- Safe pruning / compaction utilities

### Navigation & Filesystem
- Directory stack helpers
- Smart `cd` (memory + validation)
- fzf-driven path/file jump (deferred)

### Completion & Suggestions
- Layered completion augmentations (caching, grouping)
- Dynamic cache warm-up (deferred)

### Toolchain Integration
- Passive runtime/version detector (node, python, rust) — no mutation unless enabled
- Optional direnv /.env guardrail

### Keybindings / Modes
- Binding profile sets (vanilla, minimal, power)
- Vi-mode enhancements (cursor shape + mode indicator prompt segment)

### Search & Filtering
- fzf abstraction layer with graceful fallback
- Grep wrapper with performance + portability heuristics

### Safety / Reliability
- Error boundary wrapper macros
- Self-check enumerator command

### Performance & Telemetry
- Per-feature timing collector (opt-in)
- Startup delta reporter

### Extensibility / Plugin Wrappers
- Thin compatibility shims (zsh-autosuggestions, zsh-syntax-highlighting) — strictly opt-in

### Deferred / Candidate (Evaluate Later)
- AI-assisted suggestion hooks
- Predictive directory ranking

## 6. Architecture & Lifecycle (High-Level)
1. Registry Discovery: Registry file enumerates features (name, path, phase, dependencies, flags).
2. Resolution: Dependency graph validation (detect missing / circular).
3. Load Phases:
   - Phase 0: Core (pre-existing, unchanged)
   - Phase 1: Critical early features (prompt base scaffolding)
   - Phase 2: Standard interactive set (history, completion augmentations)
   - Phase 3: Deferred / async (fzf, telemetry warm-ups)
4. Error Containment: Each feature init wrapped in timing + trap boundary.
5. Post-Load Reporting (optional): Summarize enabled features + timings.

## 7. Performance Guardrails
- Baseline cold start: 334ms
- Hard ceiling (early Stage 4): +15% (≈384ms) — failing CI
- Soft warning: any single feature synchronous init >20ms
- Deferred surface: features exceeding 20ms moved to Phase 3 unless critical
- Telemetry off by default; on-demand to avoid skewed baseline

## 8. Testing Strategy Extensions
New test categories:
- Feature Contract: required functions / metadata
- Dependency Resolution: detect circular / missing
- Failure Containment: simulate thrown error; shell continues
- Enable/Disable Semantics: env toggles respected
- Performance Delta: assert aggregate + per-feature thresholds
- Deferred Load Integrity: prompt arrives before deferred features finalize

## 9. Documentation Artifacts (To Create / Update)
- stage4/STAGE4_KICKOFF.md (this)
- feature/CATALOG.md (enumeration + status)
- feature/DEVELOPER_GUIDE.md (contract + examples)
- tracking/PERFORMANCE_LOG.md (chronological deltas)
- IMPLEMENTATION.md (add Feature Layer Architecture section)
- tracking/TASK_TRACKER.md (Stage 4 lanes)
- tracking/NEXT_STEPS.md (Sprint 1 commitments)

## 10. Implementation Phases (Planned)
| Phase | Focus | Representative Tasks |
|-------|-------|----------------------|
| A | Definition | Registry spec, contract template, env var semantics |
| B | Scaffolding | Directory + template module + loader integration |
| C | Platform Features | Timing wrapper, self-check command, performance test harness |
| D | Core Feature Onboarding | History, prompt base, keybinding profile, completion basics |
| E | Enhancement Wave | fzf integration, git segment caching, telemetry opt-in |
| F | Hardening & Audit | Failure injection, perf stabilization, documentation consolidation |

## 11. Sprint 1 (Immediate Actionable Task List)
1. Create directory scaffolding: `feature/` + `feature/registry/` + tests subtrees.
2. Add feature module template with compliance header + stub contract.
3. Implement minimal registry loader + enable/disable evaluation.
4. Add self-check command (`zsh-features status`).
5. Extend performance test harness with delta assertion.
6. Seed Feature Catalog doc (status columns: Planned / In Progress / Done / Deferred).
7. Update TASK_TRACKER.md with Stage 4 lanes (A–F).
8. Update NEXT_STEPS.md to reflect Sprint 1 scope + acceptance criteria.
9. Amend IMPLEMENTATION.md with Feature Layer Architecture section + link to catalog.
10. Add initial contract + failure containment tests.

Acceptance Criteria (Sprint 1):
- Registry lists at least one sample (noop) feature
- Disabling sample feature prevents its init test from detecting side effects
- Performance harness runs + enforces baseline threshold logic
- Self-check lists features with Enabled/Disabled/Phase columns

## 12. Risk & Mitigation Matrix
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Feature sprawl | Performance + complexity drift | Strict registry + catalog status, perf gates |
| Hidden coupling | Load order fragility | Dependency metadata + circular detection tests |
| Premature optimization | Delayed delivery | Implement baseline first, then refine timing |
| Telemetry overhead | Skewed performance metrics | Default off; sample gating |
| External tool drift | Non-deterministic tests | Fallbacks + skip markers when binaries absent |

## 13. Open Questions (To Resolve Early)
1. Should external plugin wrappers be included in Phase D or shifted to Phase E/F? (Recommendation: Phase E)
2. Telemetry default: off (recommended) — confirm acceptance.
3. Registry ordering: dependency-first resolution with stable alphabetical tie-breaker?
4. AI-assisted suggestions: defer beyond Stage 4? (Recommendation: Defer)

## 14. Policy & Compliance Notes
- All new feature modules MUST include the compliance acknowledgment header exactly as shown above.
- Sensitive operations (PATH mutation, external command execution, plugin shims) MUST cite specific guideline rule references inline (e.g., performance or security rule file + line).
- Drift Detection: If guidelines checksum changes (currently 3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316) before Stage 4 completion summary is published, documents and headers must be re-synced.

## 15. Next Actions (Execution Trigger)
Upon confirmation (already granted), proceed to:
- Implement Sprint 1 tasks sequentially (registry, template, test harness).
- Commit documentation updates with consistent headers.
- Provide interim progress report after Phase B completion.

## 16. Completion Definition for Stage 4
Stage 4 is considered complete when:
- Core feature inventory (agreed scope) implemented & catalog reflects statuses
- All features covered by contract + failure containment tests
- Performance within guardrails; documented deltas stable over 3 consecutive CI runs
- Telemetry (if enabled) validated not to breach thresholds
- Stage 4 completion summary authored with compliance header

---
Maintainer Note: This kickoff document is the authoritative scope anchor for Stage 4. Deviations require explicit tracker updates + catalog synchronization before implementation.

End of document.
