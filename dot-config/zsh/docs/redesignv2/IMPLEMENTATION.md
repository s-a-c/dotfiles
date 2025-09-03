# ZSH Configuration Redesign – Consolidated Implementation Guide
Version: 2.1  
Status: Stage 2 Implementation Complete – Pre-Plugin 00–30 content landed (baseline metrics + tag pending)  
Last Updated: 2025-09-02 (Single Source of Truth; early instrumentation + perf-diff observe integrated)  
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

NOTE (Early Instrumentation Pull-Forward):
Two helper modules (`01-segment-lib-bootstrap.zsh`, `02-guidelines-checksum.zsh`) reside in the pre-plugin directory to enable early segmentation & policy checksum export. They are NOT counted toward the stable “8 pre-plugin + 11 post-plugin” architectural budget and may be merged or repositioned during Stage 5.

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
| Async Engine | 🟡 Shadow (Phase A) Active | Dispatcher + manifest + shadow tasks & tests landed; async runs in shadow (no sync deferrals yet) |
| Pre-Plugin Content Migration | ⏳ In Progress | Skeleton modules populated; migrating legacy logic |
| Performance Baseline | ✅ Captured | Baseline metrics available |
| Documentation Consolidation | ✅ v2 Structure | `redesignv2/` new canonical hub |
| Promotion Readiness | ⏳ Far | Requires completion through Stage 6 |
| Risk Posture | Controlled | Rollback + checksum freeze in place |

### 1.1 Instrumentation Snapshot (Early Stage 5 Pulled Forward)

Currently emitted (mean sample) segment labels (from `perf-current-segments.txt` / observe mode):
- Core lifecycle: `pre_plugin_total`, `post_plugin_total`, `prompt_ready`
- Hotspot instrumentation: `compinit`, `p10k_theme` (theme sourcing)
- Plugin manager / post-plugin scaffolding: `zgenom-init` (if present)
- Layered module markers (coarse still visible via post-plugin breakdown): `20-essential`, `30-dev-env`, `50-completion-history`
- Policy / governance marker: `policy_guidelines_checksum` (meta, appears when checksum exported)
- Planned / conditional (instrumented but may not always appear): `gitstatus_init` (module `65-vcs-gitstatus-instrument.zsh`, segment shown only when gitstatus plugin detected)

Coverage Status:
- Minimum required high-level trio (pre, post, prompt) present ✅
- Critical hotspot segments (compinit, p10k_theme) present ✅
- VCS status segment instrumentation implemented (file present) but not yet observed in baseline sample (likely plugin path not detected) ⚠️ (informational)
- Guidelines checksum marker present in segment file when checksum environment exported (ensures policy correlation)

Next Additions (planned instrumentation expansion):
- `gitstatus_init` (ensure plugin path resolution test)
- Additional heavy plugin groups (syntax highlighting, history backend) once identified
- Async security scan scheduling markers (post prompt) in later Stage 5/6 work

This snapshot will be updated when new hotspot segments are added or when observe → warn/gate mode transitions occur.

---

## 2. Architecture & Stage Roadmap

### 2.1 Stage Overview (End-to-End)

| Stage | Label Tag | Scope | Exit Conditions | Status |
|-------|-----------|-------|-----------------|--------|
| 1 | `refactor-stage1-complete` | Skeletons, tests, tooling, CI, verification | All infra tests PASS & tag created | ✅ Done |
| 2 | `refactor-stage2-preplugin` | Implement pre-plugin 00–30 content | Path safety, lazy framework, node stubs, integrations, ssh-agent; capture preplugin baseline & tag | ✅ Code Complete (baseline & tag pending) |
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

### 3.2 Stage 2 – Pre-Plugin Content Migration (Implementation Complete – baseline & tag pending)
> Note: `lazy_register` now supports a `--force` flag (added in Stage 2 enhancement) allowing forced lazy wrapping of already-present binaries (e.g. `direnv`, `gh`) to ensure consistent first-call instrumentation and loader state tracking. This capability is exercised in `25-lazy-integrations.zsh` to unify behavior and simplify future performance / correctness tests.

Scope Achieved (00–30):
- 00-path-safety.zsh (enhanced invariants I1–I8; tests green)
- 05-fzf-init.zsh (no-compinit guarantee verified)
- 10-lazy-framework.zsh (registry, recursion guard, negative path coverage)
- 15-node-runtime-env.zsh (lazy nvm/npm detection chain, no early heavy sourcing)
- 20-macos-defaults-deferred.zsh (scheduling skeleton – real async hook deferred to Stage 5)
- 25-lazy-integrations.zsh (direnv / gh / git config stubs – richer lazy_register integration deferred)
- 30-ssh-agent.zsh (idempotent consolidation; spawn/reuse tests)
- Early instrumentation helpers (pulled forward, excluded from canonical count): 01-segment-lib-bootstrap.zsh, 02-guidelines-checksum.zsh

Task Status:
| Task | Status | Notes |
|------|--------|-------|
| Path normalization merge & tests | ✅ | Invariants enforced |
| FZF lightweight init (no compinit) | ✅ | Sentinel checks pass |
| Lazy framework production dispatcher | ✅ | Negative & recursion tests |
| Node env lazy stubs | ✅ | Detection + first-use path |
| macOS defaults deferral enhanced | ✅ | Post-prompt hook registered (deferred async scheduling skeleton) |
| Lazy integrations enhanced | ✅ | lazy_register + fallback wrappers (direnv/gh) landed |
| SSH agent consolidation | ✅ | Single spawn/reuse invariant |
| Early instrumentation bootstrap | ✅ | Observe mode only |
| Preplugin baseline capture (`preplugin-baseline.json`) | ⏳ | Pending multi-sample run |
| Stage tag creation (`refactor-stage2-preplugin`) | ⏳ | Pending baseline artifact commit |

Exit (Final) Requirements To Close Stage 2:
1. Capture and commit `preplugin-baseline.json` (recommend multi-sample; derive mean & stdev).
2. (Optional) Refresh perf / structure badges if they consume pre-plugin metrics.
3. Create and push tag `refactor-stage2-preplugin`.

Deferred to Later Stages:
- Attach post-first-prompt async scheduling for macOS defaults (Stage 5).
- Convert integration stubs to `lazy_register` loaders + add corresponding state transition tests (Stage 4/5).
- Integrate pre-plugin cost assertion into perf guard once baseline committed.

Success Metrics (when baseline captured):
| Aspect | Gate |
|--------|------|
| Pre-plugin run cost | ≤ legacy pre-plugin baseline (target -10%) |
| Lazy framework calls | First invocation loads; subsequent constant |
| Path normalization | No duplicate logical dirs; tests green |
| Agent duplication | 0 spurious spawns with existing valid socket |

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
- Baseline captured before structural migration (see `perf-baseline.json`).
- Segmentation expanded early (Stage 2) to reduce risk before optimization phase.
- Tracked segments now include lifecycle totals + hotspot sub-segments (compinit, p10k_theme, gitstatus_init (conditional), plus layered module markers).
- Post-plugin cost is currently high (≈5s mean) and will be reduced iteratively; original Stage 6 absolute target (≤500ms) retained but now treated as final Phase “Budget” goal with interim phases.
- Regression guard (perf-diff) currently in observe (non-failing) mode; gating will ratchet in later phases.
- Instrumentation overhead kept minimal (segment-lib adds negligible cost; target <5ms aggregate).

#### 4.1.1 Interim Performance Roadmap (Phased Activation)

| Phase | Mode | Criteria / Actions | Failure Effect | Status |
|-------|------|--------------------|----------------|--------|
| Phase 0 | Observe | Collect `perf-current-segments.txt`, establish `perf-baseline-segments.txt` | None (informational) | ✅ Active |
| Phase 1 | Warn | Enable `promotion-guard-perf.sh` warn thresholds (abs Δ, pct Δ, new segment allow) | Non-failing warnings | ⏳ Pending (after 2 stable baselines) |
| Phase 2 | Gate | Fail on regressions beyond thresholds when `PROMOTION_GUARD_PERF_FAIL=1` | Stage / PR block | ⏳ Planned |
| Phase 3 | Budget | Enforce absolute per-segment + aggregate budgets (hard fail) | Promotion block | ⏳ Planned |
| Phase 4 | Adaptive (Optional) | Auto-adjust rolling baseline after approved gate passes | Conditional | ⏳ Optional |

#### 4.1.2 Initial (Soft) Segment Budget Targets (Subject to Refinement)

| Segment | Current Mean (ms)* | Interim Soft Target | Final Budget Goal | Notes |
|---------|--------------------|---------------------|-------------------|-------|
| post_plugin_total | ~5055 | ≤ 3000 (Phase 1–2) | ≤ 500 | Multi-pronged reduction (defer heavy loads, async) |
| compinit | 15 | ≤ 400 | ≤ 250 | Fast strategy already low; secure mode future impact |
| p10k_theme | 7 | ≤ 900 | ≤ 600 | Room reserved for prompt customization expansion |
| gitstatus_init | (n/a / missing) | ≤ 250 | ≤ 150 | Will measure once segment reliably emitted |
| pre_plugin_total | 96 | ≤ 120 | ≤ 100 | Already within targets; keep guard |
| prompt_ready (total) | 5852 | ≤ 3500 | ≤ 1000 | Will fall as post-plugin shrinks & async defers work |

*Current mean values sourced from latest `perf-current-segments.txt` (observe run). Missing segments treated as “to be measured” before hard budgets activate.

#### 4.1.3 Gating & Threshold Evolution
- Observe → Warn trigger: Two consecutive runs with <5% variance (stdev/mean) on lifecycle totals.
- Warn → Gate trigger: Baseline refresh + validation tests for required segment coverage (compinit, p10k_theme, gitstatus_init (if applicable)).
- Gate → Budget trigger: 3 successful gate cycles (no regressions) OR targeted optimization PR(s) hitting interim soft target for post_plugin_total.
- Budget Enforcement: Introduce gate G6 (existing) plus per-segment hard ceilings (compinit, p10k_theme, gitstatus_init) with immediate fail on exceedance.

#### 4.1.4 Additional Planned Enhancements
- Multi-sample capture implemented via `perf-capture-multi.zsh` (N≥3 samples) with stdev aggregation output to `perf-multi-current.json`.
- Rolling variance test implemented (`test-multi-sample-variance.zsh`) to gate observe → warn transition (checks relative stddev & stability thresholds).
- perf-diff JSON emission implemented (`perf-diff.sh --json`) with stable schema (regressions/new/removed/improvements/unchanged) consumed by promotion guard now and intended for future automated gating correlation (e.g., combining regression + budget signals).
- Budget enforcement via `perf-segment-budget.sh` (interim/final phases; integrates with Gate G6 when ENFORCE=1)

All changes to thresholds / budgets must be reflected here and in gate tests to maintain TDD alignment.

Optional Pre-Plugin Budget Override Guidance:
To begin enforcing or tightening the pre-plugin phase cost before final budgets activate, you can layer a provisional budget on top of the Stage 2 baseline without waiting for full Phase 3 gating.

Recommended workflow:
1. Capture / refresh baseline:
   tools/preplugin-baseline-capture.zsh
   jq '.mean_ms' docs/redesignv2/artifacts/metrics/preplugin-baseline.json
2. Choose an interim ceiling (e.g. mean * 1.10 for 10% headroom).
3. Run budget check locally (observe):
   BUDGET_PRE_PLUGIN_TOTAL=<ceiling_ms> ./tools/perf-segment-budget.sh
4. Enforce in CI (adds hard gate once stable):
   BUDGET_PRE_PLUGIN_TOTAL=<ceiling_ms> ENFORCE=1 ./tools/perf-segment-budget.sh
5. Pair with variance/regression test:
   tests/run-all-tests.zsh --performance-only
   (test-preplugin-baseline-threshold.zsh ensures <= allowed regression percentage)

Tightening Strategy:
- Start with +10% over baseline.
- After 3 consecutive green runs (low variance), reduce to +5%.
- When optimization work lands (e.g., further path pruning or lazy loader improvements), recalc baseline and repeat.
- Final target should align with Interim budget (≤120ms) then converge toward Final budget (≤100ms) as specified in the Performance Roadmap once consistent.

Environment Overrides Recap:
- BUDGET_PRE_PLUGIN_TOTAL=<ms> sets explicit ceiling.
- PREPLUGIN_ALLOWED_REGRESSION_PCT=<pct> adjusts threshold for test-preplugin-baseline-threshold.zsh.
- ALLOW_MISSING_GITSTATUS_INIT=1 (optional) avoids false negatives while early segments still stabilizing.

Rationale:
Applying a provisional enforced budget early reduces the window for silent regressions and creates immediate feedback loops for incremental refactors (e.g. forced lazy wrapping with lazy_register --force in module 25). This incremental ratcheting preserves TDD discipline while converging on promotion-grade performance guarantees.

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
| Performance | Timing, segmentation integrity, observe→warn gating | `test-segment-regression.zsh`, `test-required-segment-labels.zsh`, `test-promotion-guard-perf-block.zsh`, `test-multi-sample-variance.zsh`, `test-p10k-instrumentation.zsh`, `test-gitstatus-instrumentation.zsh` |
| Maintenance | Drift & checksums | `verify-legacy-checksums.zsh` |

### 4.4 Documentation Governance
- Version 2 layout ensures no duplication of stage roadmap.
- Artifacts separated from narrative.
- Stage-specific docs hold *execution detail*; this guide remains stable.
- Updates to metrics or stage status modify a single section here (Current Status + Stage tables).

---

### 4.5 Test-Driven Development (TDD) Policy

All implementation and migration activity MUST follow disciplined TDD:

| Aspect | Requirement | Enforcement |
|--------|-------------|------------|
| Test First | A failing or absent test must be added/updated before implementing or modifying functionality | PR review + Gate G10 |
| Minimal Delta | Only write tests sufficient to express the next functional expectation | Code review |
| Red → Green → Refactor | Commit sequence SHOULD show (a) failing test introduction (b) implementation pass (c) optional refactor without behavior change | Commit history audit |
| Coverage of Gates | Every Gate (G1–G9) must have at least one explicit test asserting PASS/FAIL behavior | Test inventory |
| Regression Reproduction | Bugs require a reproducing failing test before fix | PR checklist |
| Determinism | New tests must be stable across ≥3 consecutive runs (no timing flake) | CI run-all-tests |
| Isolation | Unit tests avoid sourcing full runtime unless explicitly integration/feature category | Category taxonomy |
| Documentation Sync | When adding a new test category or gate test, update this section if policy expands | Review checklist |

TDD Workflow (Micro Loop):
1. Identify requirement / defect.
2. Add or modify the smallest failing test expressing the unmet behavior (commit: test-only).
3. Implement code to satisfy test (commit: feat/fix).
4. Refactor for clarity/perf without changing behavior (commit: refactor).
5. Validate full suite (design/unit/feature/integration/security/performance).
6. Update artifacts & docs only after tests are green.

Failure to supply a preceding failing test for a functional change blocks Stage exit or promotion readiness.

## 5. Metrics & Gates

| Gate ID | Description | Data Source | PASS Condition | Enforced At |
|---------|-------------|-------------|----------------|-------------|
| G1 | Structure (counts & order) | structure-audit.json | 8 + 11 files, no duplicates | Every commit (CI) |
| G2 | Legacy drift | inventories + checksums | No checksum delta | Pre-promotion & periodic |
| G3 | Single compinit | Compinit tests | Exactly one run | Stage 5 exit |
| G4 | Async deferral | Async logs | No RUNNING pre-prompt | Stage 5/6 |
| G5 | Perf improvement | perf-current vs baseline | ≥20% reduction | Stage 6 |
| G5a | Perf diff observe mode active | `promotion-guard-perf.sh` (perf-diff block) | Structured PERF_GUARD block present (status=OK or SKIP) AND segments file discovered (non-failing observe) | Stage 5 (Observe) |
| G6 | Segment budgets | perf-current.json | post_plugin_cost ≤ 500ms | Stage 6 |
| G7 | Regression control | perf regression test | Δ ≤ 5% vs rolling baseline | Continuous |
| G8 | Sentinel compliance | design test | 100% modules guarded | Continuous |
| G9 | Tool health | verification script | All checks PASS | Pre-stage close |
| G10 | TDD policy adherence | Commit/test history, gate tests | Each functional change preceded by failing test; gates covered by explicit tests | Continuous + Stage exits |

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
| `perf-capture.zsh` | Startup & segment timing (cold/warm + breakdown) | Stable | Now emits unified SEGMENT lines + guidelines checksum |
| `promotion-guard.zsh` | Final eligibility gate | Extended | Structure + checksum gates active; perf gating pending (observe mode via perf helper) |
| `verify-implementation.zsh` | Quick health snapshot | Stable | Developer convenience |
| `generate-structure-audit.zsh` | Structure enumeration | Stable | Feeds badges |
| `verify-legacy-checksums.zsh` | Drift detection | Stable | Fails on mutation |
| `run-all-tests.zsh` | Unified test runner | Stable | Category filters |
| `perf-regression-check.zsh` | Δ evaluation | Stable | Legacy; superseded incrementally by perf-diff observe + future gating |
| `segment-lib.zsh` | Unified segment timing helpers | New | Provides start/end, SEGMENT emission, policy checksum export |
| `perf-capture-multi.zsh` | Multi-sample capture & variance stats | New | Produces `perf-multi-current.json` (mean/min/max/stddev) for stability gating |
| `promotion-guard-perf.sh` | Perf diff observe block (G5a) | New | Emits structured PERF_GUARD block + optional multi-sample summary fields |
| `perf-segment-budget.sh` | Segment budget enforcement (Phase 3 prep) | New | Interim/final budgets; dry-run or `ENFORCE=1` hard gating |

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
| Performance | ≤3817ms startup mean | In Progress (Stage 2 partial migration; baseline improvement measurement pending) |
| Segment Budget | post_plugin_cost ≤500ms | Pending |
| Compinit | Single run validated | Pending |
| Async Deferral | No pre-prompt RUNNING | Pending |
| Security Commands | Implemented & logged | Pending |
| Documentation | Synchronized & current | ✅ |
| TDD Gate | Every functional change preceded by failing/absent test update; gates have explicit tests | Partial (path, lazy framework, ssh agent covered; remaining pre-plugin modules pending) |
| Guard | `promotion-guard.zsh` PASS | Partial (structure & checksum gates PASS; perf/async gates pending later stages) |
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
| 2025-09-01 | Stage 2 partial progress (skeletons, lazy stubs) + Adopted TDD policy | Updated goals & status; remaining migration, perf sampling pending; added formal TDD gate |
| 2025-09-02 | Stage 2 progress (path normalization, lazy framework, ssh agent) | Implemented invariants, dispatcher, agent consolidation; tests updated & TDD gate partial PASS |
| 2025-09-02 | Early instrumentation (segment-lib, compinit/p10k/gitstatus segments, perf-diff observe, guidelines checksum export, new tests) | Deep timing & policy integration pulled forward from later stages; baseline for future gating |
| 2025-09-02 | Performance tooling expansion (multi-sample capture, variance & guard tests, budget script) | Added perf-capture-multi, promotion guard multi-sample fields (G5a), variance stability test, structured guard block test, segment budget enforcement (perf-segment-budget) |
| (Future) | Stage 5 compinit success | Mark compinit gate PASS |
| 2025-09-02 | Async Phase A (shadow) activation | Added dispatcher + manifest + shadow task registration, async integrity & shadow mode tests, placeholder sync segment probes, async metrics export & promotion guard async placeholders (no sync deferrals yet) |
| 2025-09-02 | Stage 2 implementation code complete (00–30 modules) | Pre-plugin modules implemented; baseline metrics & tag pending (`preplugin-baseline.json`) |
| 2025-09-02 | Stage 2 enhancements (modules 20 & 25 + preplugin threshold test) | Added deferred macOS defaults hook, lazy_register integration for direnv/gh, and test-preplugin-baseline-threshold.zsh |

---

**Single Source of Truth**: If any other document conflicts with this guide, this file prevails until explicitly versioned.

[Back to Documentation Index](README.md) | [Architecture](ARCHITECTURE.md) | [Reference](REFERENCE.md)