Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

<!--
  ZSH Project PR Template
  - Use this template when your change primarily targets the ZSH project at: dot-config/zsh/
  - If your change is repo-wide (CI/security/tooling/docs across the whole repo), use the repo default template.
  - Title guidance: Use one of feat/, fix/, docs/, chore/ followed by a short summary.
-->

# ZSH Project Pull Request

## Purpose
Briefly explain the problem this PR solves for the ZSH project and the value it delivers.

## Scope
- Affected paths/modules (keep concise):  
  - dot-config/zsh/<subpath> …
- Feature flags or env toggles introduced/changed (if any):  
  - ZSH_USE_REDESIGN, SELFTEST_HARD_FAIL, PERF_* …

## Summary of changes
- [ ] Key change 1 (file/behavior)
- [ ] Key change 2 (file/behavior)
- [ ] Key change 3 (file/behavior)

## Linked issues / tickets
- Closes: #<issue-number>
- Related: #<issue-number>
- Design/docs references: <links>

---

## Structure & layout validation
Confirm ZSH structure and invariants remain valid.

- How verified:
  - Locally:
    ```
    cd dot-config/zsh
    tools/generate-structure-audit.zsh
    ```
  - CI artifact(s): docs/redesignv2/artifacts/metrics/structure-audit.json and badges/structure.json (or legacy docs/redesign/* bridged)
- Notes (if violations or ordering issues observed):
  - …

## Performance & variance evidence
Provide current data points if your change can affect startup cost, plugin phases, or prompt readiness.

- Perf badge (endpoint JSON):  
  - docs/redesignv2/artifacts/badges/perf.json
  - Shields endpoint:
    ```
    https://img.shields.io/endpoint?url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/raw/gh-pages/badges/perf.json
    ```
- Regression check (informational gate in CI):  
  - docs/redesignv2/artifacts/metrics/perf-regression.json
- Variance state + governance badges:  
  - docs/redesignv2/artifacts/badges/variance-state.json  
  - docs/redesignv2/artifacts/badges/governance.json
- Perf ledger (budgets; nightly prototype):  
  - docs/redesignv2/artifacts/metrics/perf-ledger.json
- Drift badge (if historical segments available):  
  - docs/redesignv2/artifacts/badges/perf-drift.json
- Microbench baseline (when core helpers changed):  
  - docs/redesignv2/artifacts/metrics/bench-core-baseline.json

Notes / interpretation:
- …

## Tests
- Unit tests:
  ```
  cd dot-config/zsh
  ./tests/run-all-tests.zsh --unit-only
  ```
- Design & integration (fast path):
  ```
  ./tests/run-all-tests.zsh --design-only --timeout-secs 60
  ```
- Any added/updated tests (paths and focus):
  - …
- Manual verification steps:
  1. …
  2. …

## Implementation notes
- Notable design decisions / trade-offs:
  - …
- New/updated scripts and entry points:
  - tools/<name>.zsh, tests/<path>, .zshrc.*.REDESIGN/*
- Config changes (env vars, secrets, CI settings):
  - …

## Backward compatibility & migration
- Breaking changes (explicitly call out):
  - …
- Migration steps or scripts:
  - …
- Flags/toggles to ease rollout:
  - …

## Risks & mitigations
- Functional/operational/performance risks:
  - …
- Mitigations / rollback strategy:
  - …

## Documentation updates
- README/docs updates needed?
- Changelog entry scope
- User-facing notes (if any)

---

## Evidence bundle (attach links or artifacts)
- CI run(s) and artifact links
- Perf/variance/ledger JSON snapshots
- Structure audit JSON and badge
- Any logs or human-readable summaries (e.g., structure-audit.md)

## Reviewer guidance
- Suggested reading order in the diff
- Focus areas (structure invariants, perf segments, plugin phases, prompt emissions)
- Known gaps or follow-ups

### Recommended reviewers
- ZSH owners: @owner1 @owner2
- Performance/Tooling: @perf-expert
- QA: @qa

---

## Checklist (ZSH project)
- [ ] Structure audit passes (no violations, ordering OK)
- [ ] Perf regression within threshold (see perf-regression.json)
- [ ] Variance/governance badges generated (CI will refresh)
- [ ] Perf ledger unaffected or updated budgets documented (if relevant)
- [ ] Microbench baseline updated only if justified (core helpers changed)
- [ ] Unit and design/integration tests pass locally
- [ ] CI is green (lint/unit/integration/security)
- [ ] Docs updated (README/docs/CHANGELOG) as needed
- [ ] Rollback plan documented
- [ ] Acknowledgement header included at the top with the current checksum

<!--
Notes for authors:
- Prefer redesignv2 artifact roots; legacy docs/redesign paths are bridged during migration.
- Keep evidence focused and reproducible. Link CI artifacts whenever possible.
-->