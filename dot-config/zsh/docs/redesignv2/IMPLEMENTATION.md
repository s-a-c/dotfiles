# ZSH Configuration Redesign – Consolidated Implementation Guide
Version: 2.0  
Status: Stage 1 Complete – Stage 2 Ready to Begin  
Last Updated: 2025-01-03 (Single Source of Truth)

This document *replaces and consolidates* the prior `master-plan.md`, `implementation-plan.md`, `final-report.md`, and `IMPLEMENTATION_PROGRESS.md`. It is the authoritative reference for execution, progress tracking, and promotion readiness of the redesign effort.

Related indexes:
- Navigation & overview: `README.md`
- Architecture & design principles: `ARCHITECTURE.md`
- Operational reference (commands, glossary, troubleshooting): `REFERENCE.md`

---

## 0. Executive Summary

The ZSH configuration is being refactored from a fragmented legacy layout (dozens of loosely ordered files) into a deterministic, test-driven, **modular 19-file system**:
- **Pre-plugin phase (8 files)**: Prepare environment, defer heavy work, establish lazy frameworks.
- **Post-plugin phase (11 files)**: Functional layering (security → options → runtime → completion → UI → performance → async validation → cosmetic).

Primary measurable targets:

| Objective | Baseline | Target | Evidence Source | Gate |
|-----------|----------|--------|-----------------|------|
| Startup mean (ms) | 4772ms | ≤3817ms (≥20% reduction) | `artifacts/metrics/perf-baseline.json`, `perf-current.json` | Promotion |
| Pre-plugin consolidation | 12 legacy fragments | 8 modules | Inventory diff | Stage 2 exit |
| Post-plugin consolidation | >25 active/latent | 11 modules | Structure audit | Stage 5 exit |
| Compinit executions | >1 risk | Exactly 1 | Compinit tests | Stage 5 exit |
| Deferred security hashing | Blocking at startup | Fully post-first prompt | Async logs & tests | Stage 6 gate |
| Regression control | None | ≤5% allowed | perf regression tests | Ongoing |
| Sentinel discipline | Inconsistent guards | 100% modules guarded | Sentinel test | Stage 3+ ongoing |
| Documentation drift | Ad-hoc | Consolidated, versioned | Lint & index | Ongoing |

---

## 1. Current Status Snapshot

| Category | State | Notes |
|----------|-------|-------|
| Structural Skeleton | ✅ Complete | 8 + 11 redesign directories present with guards |
| Test Infrastructure | ✅ Complete | 6 categories (design/unit/feature/integration/security/performance) |
| Tooling Enhancements | ✅ Complete | Promotion guard, perf segment capture, verification script |
| CI Workflow (structure) | ✅ Active | Structure badge workflow operational |
| Async Engine | ⏳ Pending | State machine test scaffolds in place (no engine content yet) |
| Pre-Plugin Content Migration | 🎯 Ready | Stage 2 tasks queued |
| Performance Baseline | ✅ Captured | Baseline metrics available |
| Documentation Consolidation | ✅ v2 Structure | `redesignv2/` new canonical hub |
| Promotion Readiness | ⏳ Far | Requires completion through Stage 6 |
| Risk Posture | Controlled | Rollback + checksum freeze in place |

---

## 2. Architecture & Stage Roadmap

### 2.1 Stage Overview (End-to-End)

| Stage | Label Tag | Scope | Exit Conditions | Status |
|-------|-----------|-------|-----------------|--------|
| 1 | `refactor-stage1-complete` | Skeletons, tests, tooling, CI, verification | All infra tests PASS & tag created | ✅ Done |
| 2 | `refactor-stage2-preplugin` | Implement pre-plugin 00–30 content | Path safety merged, lazy framework validated, pre-plugin baseline defined | 🎯 Ready |
| 3 | `refactor-stage3-core` | Post 00/05/10 core modules | Security skeleton, interactive options, core functions implemented | ⏳ Pending |
| 4 | `refactor-stage4-features` | Post 20/30/40 feature layers | Plugin config, dev env exports, aliases/keybindings stable | ⏳ Pending |
| 5 | `refactor-stage5-ui-perf` | Post 50/60/70/80/90 (completion, UI, perf, async, splash) | Single compinit PASS, async queued & non-blocking | ⏳ Pending |
| 6 | `refactor-stage6-promotion-ready` | A/B validation + gates | All metrics & security gates PASS, promotion guard PASS | ⏳ Pending |
| 7 | `refactor-promotion-complete` | Toggle enable + checksum snapshot + archive legacy | New checksums + legacy archived + docs updated | ⏳ Pending |
| 8* | `refactor-cleanup` | (Optional) Drift test retirement, doc pruning | Lean stable footprint | ⏳ Optional |

*Stage 8 is optional hardening/cleanup after adoption.

### 2.2 Module Sequencing Logic
1. **Early path stability** ensures subsequent modules assume normalized environment.
2. **Lazy mechanics before heavy runtimes** (Node, direnv) prevents unnecessary early cost.
3. **Security integrity (light) precedes functional augmentation** but defers heavy hashing.
4. **Completion & prompt unify late** to guarantee single compinit and stable UI.
5. **Performance capture & async scanning** near end to avoid polluting early timing.

---

## 3. Detailed Stage Execution

### 3.1 Stage 1 (Completed) – Foundation
Delivered:
- Inventories & checksum freeze.
- Redesign skeleton directories (guards + ordering).
- Sentinel audit & structure tests.
- Segment-aware perf capture tool.
- Async state test scaffolding.
- Promotion guard (structure + perf + checksum + async precondition logic).
- Central verification script.

Artifacts:
- Tag: `refactor-stage1-complete`
- Metrics: `artifacts/metrics/perf-baseline.json`
- Structure: `artifacts/metrics/structure-audit.json`

### 3.2 Stage 2 – Pre-Plugin Content Migration
Goals:
- Collapse legacy path fix scripts into `00-path-safety.zsh`.
- Implement minimal FZF init (no remote clones, no compinit).
- Build production lazy dispatcher (`10-lazy-framework.zsh`).
- Add node/npm lazy stubs & deferral semantics.
- Wrap integrations (direnv/git/copilot) with idempotent shims.
- Harden SSH agent consolidation (single spawn logic).

Success Metrics:
| Aspect | Gate |
|--------|------|
| Pre-plugin run cost | ≤ legacy pre-plugin baseline (target -10%) |
| Lazy framework calls | First call triggers load; subsequent calls constant cost |
| Path normalization | No duplicate PATH segments; tests green |
| Agent duplication | 0 new processes when socket present |

Exit Steps:
1. Run full test suite (all green).
2. Capture `preplugin-baseline.json`.
3. Tag `refactor-stage2-preplugin`.

### 3.3 Stage 3 – Post-Plugin Core
Focus modules: `00-security-integrity`, `05-interactive-options`, `10-core-functions`.

Key Deliverables:
- Security baseline stub: schedule (not run) deep plugin integrity scan task.
- Centralized `setopt` / `unsetopt` & zstyles (no path/environment contamination).
- Core utility functions with namespace-safe patterns.

### 3.4 Stage 4 – Feature Layer
Focus modules: `20-essential-plugins`, `30-development-env`, `40-aliases-keybindings`.

Key Deliverables:
- Plugin post-load augmentations (no early side-effects).
- Development toolchain discovery (Go/Rust/Python/Cargo/NPM).
- Consistent alias taxonomy + keybinding override map.

### 3.5 Stage 5 – UI, Completion & Async
Focus modules: `50`, `60`, `70`, `80`, `90`.

| Module | Responsibility | Critical Gate |
|--------|----------------|---------------|
| 50-completion-history | Single guarded compinit + history settings | `_COMPINIT_DONE=1` exactly once |
| 60-ui-prompt | Prompt init isolation (p10k etc.) | No double initialization |
| 70-performance-monitoring | Precise segment capture (precmd hooks) | Adds <5ms overhead |
| 80-security-validation | Deferred deep hashing & integrity diff | Starts only after first prompt |
| 90-splash | Optional ephemeral output | Fully suppressible |

### 3.6 Stage 6 – Promotion Readiness
Tasks:
- A/B capture (legacy toggles off vs redesign on).
- Validate performance delta meets gate.
- Async engine verified non-blocking & complete.
- Promotion guard PASS with all criteria.

### 3.7 Stage 7 – Promotion & Archive
Actions:
1. Enable redesign toggles by default.
2. Generate new checksum snapshot (shifting "legacy" baseline).
3. Archive old directories (`*.legacy.YYYYMMDD`).
4. Update final performance & summary badges.
5. Announce new stable architecture.

---

## 4. Cross-Cutting Strategies

### 4.1 Performance Strategy
- Baseline captured before structural migration.
- Segments tracked: total, pre-plugin, post-plugin.
- Threshold enforcement: Post-plugin segment target ≤500ms average.
- Regression guard fails >5% variance (rolling baseline acceptable after stabilization).

### 4.2 Security & Integrity
| Layer | Strategy | Timing |
|-------|----------|--------|
| Early (00-security-integrity) | Lightweight fingerprint scheduling | During startup (no hashing) |
| Deferred (80-security-validation) | Hash & diff of plugin sources | After first prompt |
| Commands | `plugin_security_status`, `plugin_scan_now` | User-invoked or automated |
| State Machine | IDLE → QUEUED → RUNNING → SCANNING → COMPLETE | Logged |
| Non-Blocking Guarantee | No `RUNNING` before prompt marker | Tested via async state tests |

### 4.3 Testing Strategy (Taxonomy)
| Category | Purpose | Representative Test |
|----------|---------|---------------------|
| Design | Structure, sentinels | `test-redesign-sentinels.zsh` |
| Unit | Isolated logic correctness | `test-lazy-framework.zsh` |
| Feature | High-level capability | `test-preplugin-ssh-agent-skeleton.zsh` |
| Integration | Cross-module | `test-postplugin-compinit-single-run.zsh` |
| Security | Async deferred validation | `test-async-state-machine.zsh` |
| Performance | Timing & thresholds | `test-segment-regression.zsh` |
| Maintenance | Drift & checksums | `verify-legacy-checksums.zsh` |

### 4.4 Documentation Governance
- Version 2 layout ensures no duplication of stage roadmap.
- Artifacts separated from narrative.
- Stage-specific docs hold *execution detail*; this guide remains stable.
- Updates to metrics or stage status modify a single section here (Current Status + Stage tables).

---

## 5. Metrics & Gates

| Gate ID | Description | Data Source | PASS Condition | Enforced At |
|---------|-------------|-------------|----------------|-------------|
| G1 | Structure (counts & order) | structure-audit.json | 8 + 11 files, no duplicates | Every commit (CI) |
| G2 | Legacy drift | inventories + checksums | No checksum delta | Pre-promotion & periodic |
| G3 | Single compinit | Compinit tests | Exactly one run | Stage 5 exit |
| G4 | Async deferral | Async logs | No RUNNING pre-prompt | Stage 5/6 |
| G5 | Perf improvement | perf-current vs baseline | ≥20% reduction | Stage 6 |
| G6 | Segment budgets | perf-current.json | post_plugin_cost ≤ 500ms | Stage 6 |
| G7 | Regression control | perf regression test | Δ ≤ 5% vs rolling baseline | Continuous |
| G8 | Sentinel compliance | design test | 100% modules guarded | Continuous |
| G9 | Tool health | verification script | All checks PASS | Pre-stage close |

---

## 6. Risk & Mitigation Matrix

| Risk | Phase | Likelihood | Impact | Mitigation | Early Signal |
|------|-------|------------|--------|------------|--------------|
| Silent structural drift | 2–7 | Medium | High | Inventory + checksum lock | Drift test fail |
| Over-eager async start | 5–6 | Low | Medium | Explicit deferral hook | RUNNING pre-prompt |
| Double compinit | 5 | Low | Medium | `_COMPINIT_DONE` guard + tests | Timestamp mismatch |
| Plugin load latency spike | 4–5 | Medium | Medium | Lazy wrappers; perf audit | Segment regression |
| PATH contamination | 2 | Medium | Medium | Path safety tests | Duplicate entries |
| Test flakiness (perf) | 2–6 | Medium | Low | Trim outliers; sample size | Stddev > threshold |
| Disabled rollbacks adoption drift | 6–7 | Low | High | Tag every stage | Missing tag |
| Doc divergence | 2–7 | Medium | Low | Single source consolidation | Lint mismatch |

---

## 7. Tooling & Automation Inventory

| Tool | Purpose | Maturity | Notes |
|------|---------|----------|-------|
| `perf-capture.zsh` | Startup & segment timing | Stable | Writes current metrics |
| `promotion-guard.zsh` | Final eligibility gate | Extended | Checks structure + perf + checksum + async |
| `verify-implementation.zsh` | Quick health snapshot | Stable | Developer convenience |
| `generate-structure-audit.zsh` | Structure enumeration | Stable | Feeds badges |
| `verify-legacy-checksums.zsh` | Drift detection | Stable | Fails on mutation |
| `run-all-tests.zsh` | Unified test runner | Stable | Category filters |
| `perf-regression-check.zsh` | Δ evaluation | Stable | Enforces ≤5% |
| (Planned) `stage-runner.zsh` | Semi-auto stage operations | Pending | Useful from Stage 3 onward |

---

## 8. Git & Tagging Workflow

| Action | Branch Practice | Tag Pattern | Example |
|--------|-----------------|-------------|---------|
| Stage Work | Feature branch `stage-N-*` | `refactor-stageN-*` | `refactor-stage2-preplugin` |
| Promotion Prep | Fast-forward main | `refactor-stage6-promotion-ready` | As named |
| Final Enable | Main only | `refactor-promotion-complete` | Post toggle |
| Emergency Rollback | Detached or branch | `rollback-YYYYMMDD` | `rollback-20250210` |

Commit Style Examples:
- `feat(pre-plugin): implement node runtime lazy stubs`
- `perf(async): defer security validation to post prompt`
- `chore(tests): add segment regression validation`
- `docs(impl): update Stage 2 task completion status`

---

## 9. Rollback & Recovery

| Scenario | Recommended Action | Data to Preserve | Re-Entry Step |
|----------|--------------------|------------------|---------------|
| Stage failure (functional) | Revert to prior stage tag | Last good perf metrics | Re-apply module diffs in smaller chunks |
| Performance regression | Git bisect across stage commits | perf-current snapshots | Optimize offending module |
| Async race / early RUNNING | Disable async module file | Async logs | Patch scheduler deferral |
| Integrity concerns | Force checksum re-verify | legacy-checksums.sha256 | Diff vs archived snapshot |
| Production instability post-promotion | Checkout legacy archive branch | Archived directory snapshot | Structured re-merging plan |

---

## 10. Contribution Workflow (Internal)

1. Confirm current stage status in `README.md` / this guide.
2. Implement minimal vertical slice (one module or sub-task).
3. Run: `verify-implementation.zsh`.
4. Run full or filtered tests: `tests/run-all-tests.zsh --design-only` + targeted categories.
5. For performance-sensitive changes: `tools/perf-capture.zsh` (compare).
6. Commit using defined message styles.
7. Open review referencing stage ID & sub-task IDs.
8. Tag upon stage completion *after* green test & guard pass.

---

## 11. Promotion Checklist (Stage 6 Gate)

| Category | Check | Status (Now) |
|----------|-------|--------------|
| Structure | 8 + 11 redesign stable | ✅ |
| Drift | Checksums unchanged | ✅ |
| Performance | ≤3817ms startup mean | Pending |
| Segment Budget | post_plugin_cost ≤500ms | Pending |
| Compinit | Single run validated | Pending |
| Async Deferral | No pre-prompt RUNNING | Pending |
| Security Commands | Implemented & logged | Pending |
| Documentation | Synchronized & current | ✅ |
| Guard | `promotion-guard.zsh` PASS | Partial |
| Legacy Archive Plan | Documented | ✅ |

---

## 12. Post-Promotion Transition

| Step | Action | Outcome |
|------|--------|---------|
| 1 | Default enable redesign toggles | Redesign becomes primary |
| 2 | Generate new checksums | Establish redesign as new “legacy” |
| 3 | Archive old directories | Historical diffable backup |
| 4 | Retire drift tests (optional) | Reduce noise |
| 5 | Slim docs | Move stage-specific planning to archive |
| 6 | Announce completion | Communicate stability |

---

## 13. Appendices

### 13.1 Abbreviation Legend
| Symbol | Meaning |
|--------|---------|
| ✅ | Complete |
| 🎯 | Ready / Entry criteria satisfied |
| ⏳ | Pending prior dependency |
| PASS | Gate satisfied |
| Pending | Awaiting implementation or measurement |

### 13.2 Primary File Map (Redesign)
Pre-plugin: `00,05,10,15,20,25,30,40`  
Post-plugin: `00,05,10,20,30,40,50,60,70,80,90`

### 13.3 Not Tracked Here
- Deep architectural rationales → `ARCHITECTURE.md`
- Operational aids & troubleshooting → `REFERENCE.md`
- Historical artifacts → `archive/`

---

## 14. Change Log (This Document)

| Date | Change | Reason |
|------|--------|--------|
| 2025-01-03 | Initial consolidation (v2.0) | Merge of four legacy planning artifacts |
| (Future) | Stage 2 population | Update status & metrics |
| (Future) | Stage 5 compinit success | Mark compinit gate PASS |
| (Future) | Promotion readiness | Gate alignment finalization |

---

**Single Source of Truth**: If any other document conflicts with this guide, this file prevails until explicitly versioned.

[Back to Documentation Index](README.md) | [Architecture](ARCHITECTURE.md) | [Reference](REFERENCE.md)