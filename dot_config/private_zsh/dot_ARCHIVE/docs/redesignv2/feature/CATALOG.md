# ZSH Redesign – Feature Catalog

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

> Source of truth for Stage 4 Feature Layer scope, lifecycle, and implementation status.  
> Every feature listed here MUST have: metadata, tests (contract + failure containment if applicable), and documented enable/disable semantics.

---

## Legend

| Column | Meaning |
|--------|---------|
| Phase  | Planned load phase (1 early, 2 standard, 3 deferred/async) |
| Cat    | Category (prompt, history, navigation, completion, integration, keybinding, search, safety, telemetry, extensibility, misc) |
| Status | Planned · In Progress · Done · Deferred · Dropped |
| En?    | Default enablement (Yes/No) |
| Defer  | Whether designated deferred (`postprompt` eligible) |
| GUID   | Stable unique identifier (non-rotating) |

---

## Current Inventory

| Feature Name | Phase | Cat  | Status      | En? | Defer | Depends | GUID                                   | Description |
|--------------|-------|------|-------------|-----|-------|---------|----------------------------------------|-------------|
| noop         | 1     | misc | Done        | Yes | No    | —       | a4c4d4c0-0fa0-4a9a-9e2a-58d5c9e9b6fd | Baseline exemplar feature (contract demo) |
| prompt-core  | 1     | prompt | Planned   | Yes | No    | noop    | (tbd) | Core prompt scaffolding & segment bus |
| history-adv  | 2     | history | Planned  | Yes | No    | noop    | (tbd) | Session + timestamp enrichment & search |
| completion-aug | 2   | completion | Planned | Yes | No | noop | (tbd) | Layered completion improvements / caching |
| keybinding-profiles | 2 | keybinding | Planned | Yes | No | noop | (tbd) | Binding profile sets (vanilla/minimal/power) |
| nav-smartcd  | 2     | navigation | Planned | Yes | No | noop | (tbd) | Smart directory memory + guarded cd |
| fzf-integration | 3  | search | Planned | No  | Yes | nav-smartcd | (tbd) | fzf wrappers (files, dirs, history) |
| git-segment  | 2     | prompt | Planned   | Yes | Yes  | prompt-core | (tbd) | Async / cached git status segment |
| telemetry-core | 3   | telemetry | Planned | No | Yes | noop | (tbd) | Opt-in per-feature timing collection |
| env-runtime-detect | 2 | integration | Planned | No | No | noop | (tbd) | Passive runtime (node/python/rust) scanning |
| direnv-guard | 2     | integration | Planned | No | No | env-runtime-detect | (tbd) | Safe direnv /.env gating |
| safety-boundaries | 1 | safety | Planned | Yes | No | noop | (tbd) | Error boundary + failure containment utilities |
| search-grep-layer | 2 | search | Planned | Yes | No | noop | (tbd) | Portable grep abstraction + fallbacks |
| prompt-rprompt-policy | 2 | prompt | Planned | Yes | No | prompt-core | (tbd) | Dynamic RPROMPT width/context rules |
| prompt-async-post | 3 | prompt | Planned | Yes | Yes | prompt-core git-segment | (tbd) | Deferred async segment refresh manager |
| perf-delta-guard | 3 | telemetry | Planned | No | Yes | telemetry-core | (tbd) | Startup + per-feature delta enforcement |
| plugin-shims | 3     | extensibility | Planned | No | Yes | safety-boundaries | (tbd) | Opt-in wrappers (e.g. autosuggestions) |
| ai-suggestions | (future) | extensibility | Deferred | No | Yes | plugin-shims | (tbd) | AI-assisted inline suggestion hooks (out of Stage 4 scope) |

---

## Status Summary

- Done: 1  
- In Progress: 0 (registry scaffold + tests considered infrastructure, not a feature entry)  
- Planned (Stage 4 scope): 16  
- Deferred beyond Stage 4: 1 (ai-suggestions)  

---

## Phase Grouping Roadmap (Planned)

### Phase 1 (Early / Foundational)
- noop (complete)
- prompt-core
- safety-boundaries

### Phase 2 (Standard Interactive)
- history-adv
- completion-aug
- keybinding-profiles
- nav-smartcd
- git-segment (base hooks; async portion may span phase 3)
- env-runtime-detect
- direnv-guard
- search-grep-layer
- prompt-rprompt-policy

### Phase 3 (Deferred / Async / Telemetry)
- fzf-integration
- telemetry-core
- perf-delta-guard
- prompt-async-post
- plugin-shims

### Future / Outside Stage 4
- ai-suggestions (explicitly deferred; requires additional policy & security review)

---

## Feature Lifecycle Requirements

Each feature must provide before marking “In Progress”:
1. Metadata variables (exact variable names consistent with template).
2. Contract functions:
   - `feature_<name>_metadata`
   - `feature_<name>_is_enabled`
   - `feature_<name>_register`
   - `feature_<name>_init`
3. Tests:
   - Contract & metadata extraction
   - Enable/disable semantics (if not purely default)
   - Failure containment (init failure injection or inert path)
   - (If >20ms synchronous cost) performance delta test
4. Compliance header with current guidelines checksum.
5. Catalog entry updated (Status -> In Progress).

Mark “Done” only when:
- All tests pass under `zsh -f` via `run-all-tests-v2.zsh`
- No unbounded synchronous cost >20ms (unless granted exception)
- Dependency graph validated (no warnings / cycles)
- Failure injection test (if supplied) contained correctly

---

## Dependency & Ordering Rules

- Dependencies must be declared in the feature module metadata and are validated by the registry resolver.
- Cycles: Prohibited; will produce ERROR logs and block invocation ordering.
- Disabled dependencies: Allowed only if dependent feature also disables itself or handles the absence gracefully.
- Deferred features (Phase 3) must not block prompt readiness (tested).

---

## Performance Guardrails (Stage 4)

| Guard Type | Threshold | Action |
|------------|-----------|--------|
| Aggregate cold start (interim) | +15% over 334ms | CI fail (planned gate) |
| Single feature synchronous | >20ms | Warning + evaluate deferral |
| Telemetry overhead when enabled | <5ms added | Monitor only |
| Deferred postprompt budget | <100ms cumulative async | Monitor; degrade if exceeded |

Telemetry features (when implemented) must default OFF; enabling must not permanently skew baseline metrics.

---

## Compliance & Policy Reminders

- All sensitive external interactions (spawning processes, PATH amendments) must cite guideline references with file:line style references inline.
- Changes to enablement semantics require corresponding test updates.
- Guidelines checksum changes mandate updating the compliance header (current: 3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316).

---

## Maintenance Workflow

1. Add new feature row (Status=Planned).
2. Implement contract + minimal skeleton -> set Status=In Progress.
3. Add tests; ensure green CI.
4. Optimize & validate performance (if applicable).
5. Update row to Done; link PR number (future column).
6. If removed, set Status=Dropped (retain row for historical audit).
7. If postponed to later stages, set Status=Deferred with rationale.

---

## Planned Future Columns (Not Yet Active)

| Column | Purpose |
|--------|---------|
| PR     | Link to merge PR implementing primary feature scope |
| Added  | Commit/date of initial introduction |
| Delta(ms) | Measured synchronous startup cost contribution |
| Async(ms) | Deferred cumulative async completion time |
| Test IDs | Canonical test file references |

---

## Open Decisions (Tracked)

| Topic | Pending Decision |
|-------|------------------|
| Telemetry default | OFF (needs confirmation when telemetry-core lands) |
| Invocation wrapper timing format | Likely key=value lines aggregated per feature |
| Failure severity policy | Non-zero feature init returns are tolerated; logged with severity=error |
| Partial dependency disable semantics | Warn only vs strict fail – current direction: warn |

---

Maintainers: update this catalog atomically with feature module + test changes to prevent drift.  
End of document.
