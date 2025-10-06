# ZSH Redesign – Feature Developer Guide

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

> Authoritative reference for creating, extending, testing, and maintaining Stage 4 Feature Layer modules.  
> All contributors MUST follow this guide exactly; deviations require explicit approval and synchronized catalog + tracker updates.

---

## 1. Purpose

The Feature Layer introduces modular, opt-in capabilities above the stabilized core. It must:
- Preserve deterministic startup behavior.
- Contain failures (never abort shell).
- Remain measurable (performance deltas tracked).
- Be fully test-driven (`zsh -f` compatible).
- Respect policy + compliance (checksum headers, sensitive rule citations).

---

## 2. Feature Module Overview

A “feature” is a self-contained capability unit implemented as a Zsh script providing:
- Static metadata (single-line variables).
- Contract functions (naming conventions).
- Clear enable/disable semantics.
- Optional lifecycle hooks (preload / postprompt / teardown).
- Deterministic registration into the central registry.

Features DO NOT:
- Mutate global user-visible state before their `feature_<name>_init` is invoked.
- Introduce uncontrolled background jobs.
- Hard-depend on external binaries without graceful fallback.

---

## 3. Directory & File Conventions

| Path | Purpose |
|------|---------|
| `feature/<name>.zsh` | Primary feature module |
| `feature/registry/feature-registry.zsh` | Central registry scaffold |
| `feature/feature-status.zsh` | Introspection / reporting command |
| `tests/feature/<name>/` | All tests for the feature (contract, enablement, failure containment, perf delta) |
| `docs/redesignv2/feature/CATALOG.md` | Source of truth inventory (must update when adding/modifying features) |
| `docs/redesignv2/feature/DEVELOPER_GUIDE.md` | This guide |
| `_TEMPLATE_FEATURE_MODULE.zsh` | Canonical contract template (do not modify in place) |

---

## 4. Metadata Specification

Every feature module MUST define the following (single line each — no trailing comments):

```
FEATURE_NAME="noop"
FEATURE_VERSION="0.1.0"
FEATURE_PHASE="1"
FEATURE_DEPENDS=""
FEATURE_DEFAULT_ENABLED="yes"
FEATURE_DEFERRED="no"
FEATURE_DESCRIPTION="Short concise summary"
FEATURE_CATEGORY="misc"
FEATURE_SINCE_STAGE="4"
FEATURE_GUID="uuid-or-stable-id"
```

Rules:
- `FEATURE_NAME`: lowercase, hyphen or underscore if needed, unique.
- `FEATURE_PHASE`: integer (1=early, 2=standard interactive, 3=deferred/async).
- `FEATURE_DEPENDS`: space-separated feature names; empty if none.
- `FEATURE_DEFAULT_ENABLED`: `yes` or `no`.
- `FEATURE_DEFERRED`: `yes` if logic primarily after first prompt; else `no`.
- `FEATURE_GUID`: non-rotating unique identifier (uuidv4 or deterministic).
- `FEATURE_CATEGORY`: one of: `prompt`, `history`, `navigation`, `completion`, `integration`, `keybinding`, `search`, `safety`, `telemetry`, `extensibility`, `misc`.

---

## 5. Contract Functions

| Function | Required | Purpose |
|----------|----------|---------|
| `feature_<name>_metadata` | Yes | Emits key=value lines (no spaces) |
| `feature_<name>_is_enabled` | Yes | Returns 0 if enabled, 1 otherwise |
| `feature_<name>_register` | Yes | Adds feature to registry (no visible side effects) |
| `feature_<name>_init` | Yes | Applies all user-visible changes |
| `feature_<name>_preload` | Optional | Lightweight pre-init (no side effects ideally) |
| `feature_<name>_postprompt` | Optional | Deferred logic after first prompt |
| `feature_<name>_teardown` | Optional | Reverts user-visible state (for tests / dynamic disable) |
| `feature_<name>_self_check` | Optional | Internal invariants (0=ok) |
| `feature_<name>__test_inject_failure` | Optional | Test-only deterministic failure injection |

Rules:
- No alias/keybinding/env/prompt side effects before `*_init`.
- Registration must be idempotent (multiple calls safe).
- Init must be idempotent (multiple calls should not duplicate state).
- Failure injection helper must never run outside tests (do not auto-call).

---

## 6. Enablement Semantics (Precedence Order)

1. `ZSH_FEATURES_DISABLE` contains `all` → forced disable.
2. Per-feature override variable: `ZSH_FEATURE_<UPPER_NAME>_ENABLED` (interpreted via truthy/falsey normalization).
3. `ZSH_FEATURES_DISABLE` explicit membership.
4. `ZSH_FEATURES_ENABLE` explicit membership.
5. `FEATURE_DEFAULT_ENABLED` fallback.

Truthiness mapping (accepted as “true”): `1 true yes on enable enabled`.  
False: `0 false no off disable disabled ""`.

All list variables support both comma and space separation. Convert for matching:
```
" ${ZSH_FEATURES_DISABLE//,/ } " == *" ${FEATURE_NAME} "*
```

---

## 7. Failure Containment Pattern

Future invocation wrapper (planned) will:
- Wrap each lifecycle call in a boundary.
- Capture exit code; log non-zero as error (feature-level, not global failure).
- Continue to next feature even if one fails.

Within `feature_<name>_init`:
```
{
  # main logic
} always {
  # finalization / state flag
}
```

Failure injection test uses `feature_<name>__test_inject_failure` returning a known sentinel (e.g. 42) to assert containment.

---

## 8. Performance Requirements

| Concern | Rule |
|---------|------|
| Aggregate startup | Must not exceed +15% over baseline (334ms → ~384ms) in early Stage 4 |
| Single feature sync cost | >20ms requires deferral or optimization justification |
| Deferred work | Must not block prompt readiness |
| Telemetry overhead | When enabled, added cost <5ms (goal) |
| Heavy external calls | MUST be deferred or cached (e.g. git, filesystem scans) |

Instrumentation (later phase) will assign per-feature timing. Prepare code structure so instrumentation wrappers can wrap `feature_<name>_init` without refactor.

---

## 9. Testing Requirements

Before marking a feature “Done”:

| Test Type | Purpose | Required |
|-----------|---------|----------|
| Contract | Metadata + required functions presence | Yes |
| Enable/Disable Semantics | Precedence logic validation | Yes (if not trivial) |
| Failure Containment | Failure injection path doesn’t corrupt session | Yes (if failure helper provided) |
| Dependency Resolution | Works with declared dependencies (no cycles) | Yes (indirect via registry tests) |
| Performance Delta | If synchronous cost suspected >20ms | Conditional |
| Deferred Behavior | Postprompt tasks do not block first prompt | If `FEATURE_DEFERRED=yes` |
| Self-Check | Optional invariant test (0 success) | Recommended |

All tests must run under `zsh -f` via `run-all-tests-v2.zsh`.

Naming pattern:
```
tests/feature/<name>/test-<name>-contract.zsh
tests/feature/<name>/test-<name>-enable-disable.zsh
tests/feature/<name>/test-<name>-failure-containment.zsh
tests/perf/<name>-delta.zsh (if needed)
```

---

## 10. Adding a New Feature (Checklist)

1. Add row to `feature/CATALOG.md` (Status=Planned).
2. Copy `_TEMPLATE_FEATURE_MODULE.zsh` → `feature/<name>.zsh`.
3. Replace placeholders; generate GUID.
4. Implement minimal contract (init may be a stub).
5. Add enable/disable + contract tests.
6. Run: `ZDOTDIR=dot-config/zsh zsh tests/run-all-tests-v2.zsh --category feature` (or full run).
7. Update catalog Status → In Progress.
8. Implement real logic (keep within performance budget).
9. Add failure containment + performance tests if needed.
10. Finalize docs (developer guide not needed for every feature—only catalog).
11. Update catalog Status → Done.
12. Commit with compliance header intact (checksum updated if guidelines changed).
13. Open PR referencing catalog diff & test evidence.

---

## 11. Allowed Side Effects (Init Phase Only)

| Type | Allowed? | Notes |
|------|----------|-------|
| Functions | Yes | Must use namespace or clear naming (avoid collisions) |
| Aliases | Preferably avoid | Use only if feature-specific & documented |
| Environment variables | Yes (scoped or prefixed) | Avoid overriding user exports silently |
| Keybindings | Yes | Provide reversible teardown |
| Prompt modifications | Only prompt-category features | Use structured segment registration (planned) |
| External processes | Only if essential | Must be asynchronous or cached |
| PATH mutation | Rare | Cite guideline rule in a comment with file:line reference |
| Background jobs | Discouraged | Must have cleanup and no zombie risk |

---

## 12. Registry Integration Notes

`feature_<name>_register` must:
- Call `feature_registry_add` if available.
- Not assume registry already loaded; safe no-op otherwise (a later registry pass may re-register).
- Avoid duplicates (internal guard variable or rely on registry ignoring duplicates).

After adding a feature:
- Run `zsh-features status --table --summary` (once integrated into interactive path) to verify presence.
- Confirm absence of warnings (unknown dependencies, cycles).

---

## 13. Deferred Features

If `FEATURE_DEFERRED="yes"`:
- Primary cost moves to `feature_<name>_postprompt`.
- `feature_<name>_init` sets up minimal scaffolding.
- Must not block the first prompt:
  - Use background subshells or lazy evaluation guards.
  - Avoid long `git`, `find`, or network operations inline.
- Provide tests ensuring prompt readiness timestamp precedes deferred completion markers.

---

## 14. Telemetry (Planned)

Telemetry is opt-in (default OFF). Planned structure:
- Wrapper sets `FEATURE_EXEC_START_NS` / `FEATURE_EXEC_END_NS`.
- Accumulates `ZSH_FEATURE_TIMINGS[name]=<ms>` in associative array.
- Status command extended with `--timings` flag (future).
- Contributors must not bake printing or logging into feature modules; use registry-level instrumentation hook.

---

## 15. Compliance & Policy Practices

Every new feature file MUST begin with:
```
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>
```
Checksum updates require:
- Recomputing guidelines aggregate (CI helper or manual script).
- Updating all touched files’ headers in the same commit.

Sensitive operations mandate inline clickable reference comments:
```
# PATH mutation justified – rule [/Users/.../performance-standards.md](/Users/.../performance-standards.md:42)
```

---

## 16. Common Pitfalls (Avoid)

| Pitfall | Consequence | Fix |
|---------|-------------|-----|
| Performing side effects during registration | Non-deterministic preload | Move logic to init |
| Hidden dependency (undocumented) | Load order breakage | Add to `FEATURE_DEPENDS` |
| Long git calls in init | Startup regression | Defer or cache |
| Hard-coded paths / OS assumptions | Portability failure | Probe & fallback |
| Missing teardown for keybindings | Residual state in tests | Implement `*_teardown` |
| Silent override of user env vars | User confusion | Name-space or conditional export |
| Re-running expensive logic idempotently | Cumulative cost | Add guard flags |

---

## 17. Example: Minimal Realistic Feature Skeleton

```
# feature/example.zsh
# (Header with compliance + checksum)

if [[ -n "${__FEATURE_EXAMPLE_GUARD:-}" ]]; then return 0; fi
__FEATURE_EXAMPLE_GUARD=1

FEATURE_NAME="example"
FEATURE_VERSION="0.1.0"
FEATURE_PHASE="2"
FEATURE_DEPENDS="noop"
FEATURE_DEFAULT_ENABLED="yes"
FEATURE_DEFERRED="no"
FEATURE_DESCRIPTION="Example feature demonstrating pattern"
FEATURE_CATEGORY="misc"
FEATURE_SINCE_STAGE="4"
FEATURE_GUID="b7de4b5d-0f8c-4d6d-b32b-2b9e5f9e3e77"

feature_example_metadata() {
  cat <<EOF
name=$FEATURE_NAME
version=$FEATURE_VERSION
phase=$FEATURE_PHASE
depends=$FEATURE_DEPENDS
default_enabled=$FEATURE_DEFAULT_ENABLED
deferred=$FEATURE_DEFERRED
description=$FEATURE_DESCRIPTION
category=$FEATURE_CATEGORY
since_stage=$FEATURE_SINCE_STAGE
guid=$FEATURE_GUID
EOF
}

feature_example_is_enabled() {
  [[ "${ZSH_FEATURES_DISABLE:-}" == *"all"* ]] && return 1
  if typeset -p ZSH_FEATURE_EXAMPLE_ENABLED >/dev/null 2>&1; then
    case "${ZSH_FEATURE_EXAMPLE_ENABLED}" in
      1|yes|true|enable|enabled) return 0 ;;
      *) return 1 ;;
    esac
  fi
  if [[ " ${ZSH_FEATURES_DISABLE//,/ } " == *" ${FEATURE_NAME} "* ]]; then return 1; fi
  if [[ " ${ZSH_FEATURES_ENABLE//,/ } " == *" ${FEATURE_NAME} "* ]]; then return 0; fi
  case "$FEATURE_DEFAULT_ENABLED" in yes|true|1) return 0 ;; esac
  return 1
}

feature_example_register() {
  if typeset -f feature_registry_add >/dev/null 2>&1; then
    feature_registry_add "$FEATURE_NAME" "$FEATURE_PHASE" "$FEATURE_DEPENDS" "$FEATURE_DEFERRED" "$FEATURE_CATEGORY" "$FEATURE_DESCRIPTION" "$FEATURE_GUID"
  fi
}

feature_example_init() {
  # Export a sample function only when enabled
  if ! feature_example_is_enabled; then return 0; fi
  example::ping() { return 0 }
}

feature_example_teardown() {
  unset -f example::ping 2>/dev/null || true
}

feature_example_register
```

---

## 18. Promotion Readiness Conditions (Per Feature)

A feature is “promotion-ready” (eligible for inclusion in a Stage Completion Summary) when:
- Status = Done in catalog.
- All tests green (including global suite).
- No unresolved warnings (unknown dependency, cycle, missing metadata).
- Documented synchronous cost (if measurable).
- Failure containment test (if applicable) passes.
- Teardown does not leave residual state across multiple invocations.

---

## 19. Updating or Refactoring an Existing Feature

1. Mark row in catalog with temporary note `(refactor)` or `(enhancement)`.
2. Add or update tests FIRST (TDD delta).
3. Implement changes (avoid mixing unrelated cleanup).
4. Run full suite + performance smoke.
5. Remove temporary note; keep Status = Done.
6. If performance characteristics changed meaningfully → update Performance Log (if established) & open a delta review note.

---

## 20. Removal / Deprecation Procedure

1. Set Status → Dropped in catalog (retain row; add rationale).
2. Provide compatibility stub if user configs may reference functions.
3. Remove tests or mark them skipped with explicit reason.
4. Document replacement path (if any).
5. Announce in CHANGELOG or Stage Completion Summary.

---

## 21. Open Decisions & Alignment

| Topic | Current Direction |
|-------|-------------------|
| Invocation timing format | Key=value lines aggregated to array (pending implementation) |
| Telemetry storage | Associative array + optional JSON export |
| Error severity levels | Non-zero init: log error, continue |
| Partial dependency disable | Warn; dependent may self-disable gracefully |

Contributors must not implement alternative schemes without updating this section + referencing rationale.

---

## 22. Quick Reference Cheat Sheet

| Action | Command / File |
|--------|----------------|
| List features | `zsh-features status --table --summary` (after integration) |
| Add new feature | Copy template → update metadata → tests → catalog |
| Run feature tests only | Filter by path: `grep -l 'feature/<name>' tests | xargs` (or category runner enhancement) |
| Check enablement precedence | `env ZSH_FEATURES_DISABLE=... ZSH_FEATURES_ENABLE=... zsh -f -c 'source feature/<name>.zsh; feature_<name>_is_enabled; echo $?'` |
| Verify registry order | `zsh -f -c 'source feature/registry/feature-registry.zsh; feature_registry_resolve_order'` |
| Inject failure (test) | `feature_<name>__test_inject_failure` |
| Teardown feature | `feature_<name>_teardown` |

---

## 23. Maintenance Checklist (Weekly)

- [ ] Catalog entries reflect real status & GUIDs.
- [ ] New features use up-to-date checksum.
- [ ] No stale TODO placeholders in committed modules.
- [ ] No direct prompt mutation outside prompt-category features.
- [ ] No unintended increase in startup time (run perf smoke).

---

## 24. Contributor Onboarding Sequence

1. Read this guide + catalog.
2. Study `noop` module (reference implementation).
3. Draft metadata + skeleton in new feature file.
4. Write enable/disable & contract tests before logic.
5. Implement logic incrementally (commit often).
6. Validate with full test suite (include perf).
7. Update catalog & open PR.

---

## 25. Glossary

| Term | Meaning |
|------|---------|
| Feature | Modular capability unit with contract & metadata |
| Registry | Central metadata + dependency manager |
| Phase | Load sequencing tier (1 early, 2 standard, 3 deferred) |
| Deferred | Post-first-prompt or background-loaded component |
| Containment | Preventing feature failure from aborting startup |
| Telemetry | Optional timing collection layer |

---

## 26. Final Notes

This guide is a living artifact. Any structural modification to the Feature Layer (new lifecycle phase, new mandatory contract function, changed performance threshold) MUST be reflected here, in the catalog, and (if behavioral) accompanied by updated tests.

End of document.