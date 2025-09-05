# ZSH Configuration Redesign – Consolidated Implementation Guide

## Progress Update — 2025-09-05

Highlights delivered in this iteration:
1. Post-harness settle and prompt grace
   - Added configurable post-exit settle window (PERF_POST_PLUGIN_SETTLE_MS, default 100–120ms) and prompt grace window (PERF_PROMPT_NATIVE_GRACE_MS, default ~60–80ms) in the single-run harness to catch late segment writes and native PROMPT_READY_COMPLETE markers before fallback.
   - Tracing flags (PERF_SEGMENT_TRACE, PERF_PROMPT_TRACE) emit structured diagnostics to stderr without polluting artifacts.

2. Tightened salvage and zero-diagnose synthesis
   - When lifecycle post is missing but granular POST_PLUGIN_SEGMENT lines exist, synthesize post_plugin_total from segment sums and align prompt_ready_ms accordingly if still zero.
   - Added zero-diagnose logging when all lifecycle values parse to zero; fall back to wall-clock synthesis to avoid all-zero lifecycles.

3. Module-fire selftest and tracer tools
   - New tools:
     - tools/perf-module-fire-selftest.zsh: CI-friendly JSON summary of granular segment emission and native prompt presence, with settle/grace and recommendations.
     - tools/perf-module-tracer.zsh: Human-readable table or JSON summarizing emitted POST_PLUGIN_SEGMENT labels with basic stats.
   - Supports clean JSON mode via a clean shell environment (env -i … /bin/zsh -f) for CI usage.

4. CI gates and new “modules” badge
   - CI workflow now runs the module-fire selftest and stores module-fire.json into metrics.
   - Soft gate warns when granular segments or native prompt are missing; optional hard gate enabled via SELFTEST_HARD_FAIL=1.
   - Badges: generate-summary-badges.zsh now emits modules badge (module-fire.json) and includes modules:<status> in summary.json with color precedence (red > yellow > others).

5. Provenance, percentiles, and stability hardening
   - Refined prompt marker provenance (native, native_equal_post, approx, derived) in perf-current.json; aggregates per-run provenance in multi-run artifacts with counts and summary.
   - Added post_plugin_cost_ms percentiles (p50/p90/p95) and configurable outlier factor (PERF_OUTLIER_FACTOR).
   - Stale lock directory cleanup added to multi-run to prevent filesystem clutter.

Action items reflected in trackers:
- Update Variance Stability Log upon next authentic multi-run with settle/grace enabled; target reduced RSD and increased native marker rates.
- Maintain soft CI gate while emission stabilizes; plan transition to hard gate after sustained success.
- Incorporate module-fire outcomes (emits_granular_segments, emits_native_prompt) into governance status notes.

## 1.2.1 (NEW) Deferred Prompt / Post Marker Enhancement Backlog (Appended)

Context:
The immediate “soonest implementation” changes have been applied:
- Added native post-plugin boundary module: `85-post-plugin-boundary.zsh` (emits `POST_PLUGIN_COMPLETE` + `SEGMENT name=post_plugin_total`).
- Modified perf harness invocation sleep hold: replaced `zsh -i </dev/null` with `zsh -i -c "sleep <delay>"` to allow precmd/prompt instrumentation to fire in headless runs.
- Added `zshexit` fallback hook to `95-prompt-ready.zsh` to ensure a last-chance prompt readiness capture.

Goals of Remaining Backlog:
Stabilize fully native (non-fallback, non-forced) `post_plugin_total` and `prompt_ready` markers across multi-run and advanced harness modes, then retire (or demote) F38 aggregation and forced prompt injection pathways.

Implemented (Current Session):
1. Native post boundary emission (`85-post-plugin-boundary.zsh`).
2. Sleep-based interactive retention window in perf harness (`perf-capture.zsh`).
3. `zshexit` finalization hook for prompt readiness.
4. Adaptive empty segment log wait & salvage (`perf-capture.zsh`: `PERF_SEGMENT_ADAPTIVE_WAIT_MS` + synthesized lifecycle markers when raw log remains empty after grace period).
5. Marker presence validation script added (`tools/test-marker-presence.zsh`) – baseline native marker assertion (pre/post/prompt) with provenance & adaptive detection heuristics.

Regression Note (2025-09-05):
During validation after the sleep-based interactive retention tweak, several runs produced a completely empty segment log (0 bytes) resulting in zero `pre_plugin_cost_ms`, `post_plugin_cost_ms`, and `prompt_ready_ms` (perf-capture fallback path triggered). This indicates the interactive session exited before segment emission modules (40/85/95) executed, or the sleep window was too short for hook scheduling under headless conditions. Immediate remediation tasks have been appended to backlog (R1/R2) to (a) add a marker presence assertion and (b) implement an adaptive wait / direct marker flush before exit.

Pending / Future Tasks:
1. Immediate Boundary Prompt Capture (Option C): Conditional in boundary module — if headless harness detected (`PERF_PROMPT_HARNESS=1` & no prompt marker after short delay) call `__pr__capture_prompt_ready` directly (disabled until empirical confirmation required).
2. Adaptive Interactive Hold (phase 2 – extended): Enhance current adaptive empty-log wait by adding prompt marker polling & configurable timeout (`PERF_PROMPT_READY_TIMEOUT_MS`), and deprecate synthesized lifecycle emission once native stability ≥99%.
3. Marker Presence Assert Test (implemented: `tools/test-marker-presence.zsh`): Next enhancement – integrate into CI gating (warn → fail) and extend to record marker provenance (`native|fallback|adaptive`) for variance filtering.
4. Multi-Run Authenticity Tightening: After ≥2 consecutive authentic runs with native markers, reduce authenticity missing_post majority threshold from 50% to 40% (then possibly 33%).
5. F38 Fallback Scope Reduction: Emit warning + mark fallback usage; downgrade to salvage-only mode once native post stability proven over N=10 aggregate samples.
6. Prompt Force Logic Retirement: Remove `PERF_ALLOW_PROMPT_FORCE_CAPTURE` path after native markers stable; replace with diagnostic error if prompt missing and post present.
7. Harness Race Diagnostics: Add debug mode dumping raw segment log before JSON write to validate ordering / race conditions.
8. Segment Log Integrity Test: Validate segment log does not contain multi-run progress lines and that `POST_PLUGIN_COMPLETE` precedes any prompt readiness emission.
9. Duplicate Marker Guard Test: Ensure `PROMPT_READY_COMPLETE` is emitted exactly once (precmd + zshexit coexistence).
10. Boundary & Prompt Module Consolidation Study: Evaluate merging logic to reduce headless code paths (create decision doc; proceed only if maintenance gain > complexity cost).
11. Governance Badge Update: Add explicit `markers_native=1` flag once forced/approximated paths fully eliminated in advanced multi-run.
12. Variance-State Extension: Record marker provenance per run (`native|forced|fallback`) enabling RSD filtering excluding fallback runs.
13. Harness Flag Documentation: Extend `REFERENCE.md` with `PERF_PROMPT_HARNESS`, `PERF_PROMPT_FORCE_DELAY_MS`, `PERF_ALLOW_PROMPT_FORCE_CAPTURE`, and future `PERF_PROMPT_READY_TIMEOUT_MS`.
14. Adaptive Delay Heuristic: Compute dynamic wait = min( pre_plugin_total * 0.4 , 120ms ) before deciding forced capture (reduces over-wait on fast configs).
15. Outlier Classification Enhancement: Attach marker provenance to outlier detection to ignore artificially forced prompt timings.
16. JSON Schema Annotation: Add `"marker_provenance": {"post_plugin_total":"native|fallback","prompt_ready":"native|forced|approx"}` to `perf-current.json` & aggregated multi-run JSON.
17. Retire Legacy Approximation Flag: Remove `PERF_FORCE_PROMPT_READY_FALLBACK` once zero native prompt rates resolve (<1% over 30 samples).
18. CI Gate (Future): Fail performance job if `markers_native=0` for >2 consecutive nightly runs.
19. Metrics Drift Alert: Add detection if native post mark regresses back to fallback for any PR merge (pre-empt silent regression).
20. Consolidated Marker Timing Delta Test: Verify monotonic ordering pre ≤ post ≤ prompt at sample granularity; fail if inequality violated.

Tracking / Exit Criteria for Backlog Closure:
- Native marker rate (post + prompt) ≥ 99% over rolling 30 advanced multi-run samples.
- F38 fallback not invoked in last 10 runs.
- Forced prompt readiness path unused in last 10 runs.
- Governance badge displays markers_native=1 and no degrade for 14 days.
- All marker provenance tests green in CI (added categories: instrumentation / timing).

(End 1.2.1 Backlog Section)


> Global Documentation Guideline: All ordered lists MUST use numeric Arabic prefixes (`1.`, `2.`, `3.` …).  
> - Do not use auto-renumbering tricks (e.g., repeating `1.` intentionally) in committed sources.  
> - Do not switch to roman numerals or lettered lists.  
> - Preserve sequential numbering in diffs to make semantic list reordering explicit.  
> - If inserting in the middle of an existing ordered list, renumber the following items instead of relying on renderer auto-renumbering.
Version: 2.3  
Status: Stage 2 Complete – Stage 3 In Progress (core hardening, trust anchors, micro-benchmark harness, drift tooling)  
Last Updated: 2025-09-04 (Added micro-benchmark harness stabilization, variance log integration, perf drift badge script, trust anchor read APIs)
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

NOTE (Early Instrumentation Pull-Forward):
Two helper modules (`01-segment-lib-bootstrap.zsh`, `02-guidelines-checksum.zsh`) reside in the pre-plugin directory to enable early segmentation & policy checksum export. They are NOT counted toward the stable “8 pre-plugin + 11 post-plugin” architectural budget and may be merged or repositioned during Stage 5.

This document *replaces and consolidates* the prior `master-plan.md`, `implementation-plan.md`, `final-report.md`, and `IMPLEMENTATION_PROGRESS.md`. It is the authoritative reference for execution, progress tracking, and promotion readiness of the redesign effort. New in v2.2: path resolution enforcement (badge + fail-fast), strict mode (--strict) for advanced audits, helper verification tool, and proactive future plugin path guard test.

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
| Tooling Enhancements | ✅ Complete | Promotion guard, perf segments, path rules badge, helper verifier, strict mode, future plugin guard |
| CI Workflow (structure) | ✅ Active | Structure badge workflow operational |
| Async Engine | 🟡 Shadow (Phase A) Active | Dispatcher + manifest + shadow tasks & tests landed; async runs in shadow (no sync deferrals yet) |
| Pre-Plugin Content Migration | ✅ Complete | Baseline tagged (refactor-stage2-preplugin); path rules enforced repository-wide |
| Stage 3 Core Modules | 🚧 In Progress | Minimal exit (T1–T3) achieved (non-zero lifecycle trio + monotonic + governance variance artifact); remaining: authentic multi-run variance + core hardening (F49→F48→F50, F16, F17) |
| Performance Baseline | ✅ Captured | pre_plugin_total mean=35ms (N=5); optimization pending |
| Governance Badge | ✅ Observe Mode | Explicit variance-state source integrated; awaiting authentic variance before warn transition |
| Variance Mode | observe | Synthetic multi-run replication in place pending F49 loop repair |
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

### 1.2 Next Implementation Tasks (Rolling 7-Day Plan)

(Time horizon: next 7 days; priorities: P0 critical sequence; P1 stability/gating; P2 governance/docs; P3 prep.)

Completed (last 48h):
- Micro-benchmark baseline captured (bench-core-baseline.json; shimmed_count >0).
- Governance badge (extended + shield) active with explicit variance-state source (F40 complete).
- Drift badge integrated (observe mode).
- Monotonic lifecycle ordering validated (pre ≤ post ≤ prompt).
- Variance-state artifact generated (observe mode; synthetic multi-run fallback).
- Lifecycle trio non-zero (fast-track path achieved).

Immediate (P0 – Critical Sequence):
- Authentic variance stabilization (simple harness): Run second multi-sample capture (N=5) with perf-capture-multi-simple.zsh; update Variance Stability Log. Promote pre_plugin_cost_ms decision to candidate if new RSD <5% (or blended RSD across both authentic runs <5%). Investigate post_plugin_total_ms outlier (values 144,141,385) and document cause or mitigation plan before any gating escalation.
1. F49 – Repair perf-capture-multi loop (ensure >1 authentic samples; add watchdog, retry, explicit non-zero post/prompt assertion).
2. F48 – Remove synthetic multi-sample replication hack after F49 (delete cloning logic; governance aggregation treats insufficient samples as “insufficient” not synthetic).
3. F50 – Recompute variance-state.json with authentic RSD; update governance badge (remove synthetic indicators; update stable_run_count).
4. Refresh Variance Stability Log with authentic post_plugin_total & prompt_ready_ms rows (annotate prior synthetic entries as archived).
5. Drift badge threshold annotation (add “(+X% max)” suffix if not yet committed).

Carryover / Adjusted (P1):
- Failure classification mapping for perf-ledger drift (tier: >5% warn, >10% fail) + badge color taxonomy alignment.
- Manifest test escalation: flip CORE_FN_MANIFEST_WARN_ONLY=0 after 48h stable run set.
- Integrate max_positive_regression_pct directly into ledger JSON (F2/F41 path).
- Embed micro-bench worst ratio & drift count into governance extended JSON (prep for F26 gating).
- Prepare authentic multi-run second capture (target ≥2 stable RSD<5% runs to consider warn mode).

P1 Core Module Hardening:
- F16 / F17 path: enumerate shimmed functions vs manifest; draft guard test baseline (warn).
- Add trust anchor listing confirmation test (read-only) – supports upcoming hashing phase.

P2 Governance & Documentation:
- Update README badge legend to reflect explicit variance-state (remove any “derived” wording).
- Stage 3 exit mini-report regeneration after authentic variance run.
- Append synthetic→authentic variance transition footnote in Section 1.3 & 4.1.3.

P3 Preparation for Stage 5:
- Draft interim soft target for post_plugin_total after first authentic multi-run (derive mean, set soft ceiling).
- Outline async activation checklist (single compinit verification precondition, deferred hashing, prompt readiness stability).

Deferred Until Authentic Variance Stabilized (Do Not Start):
- Observe→warn variance gating flip (needs ≥2 authentic low-RSD runs).
- Micro benchmark gating (F22/F26) until shimmed_count == 0.

Exit Signals for This Window:
- Authentic multi-run variance entries present (no synthetic) in log.
- Governance badge unchanged severity after authenticity pivot.
- Recomputed variance-state shows stable_run_count ≥1 (authentic) & RSD <5% pre_plugin_cost_ms.

Escalation Criteria:
- If authentic post_plugin_total still zero after F49 retries: enable PERF_CAPTURE_DEBUG=1 and capture raw segment logs; open F49a follow-up task.

Ownership Notes:
- F49/F48/F50 must land sequentially in one or multiple small PRs; avoid bundling gating toggles in same change set.

- Add README badge row: perf drift, perf ledger, variance decision (observe/warn/gate).
- Prepare Stage 3 readiness checklist file (stages/stage-3-core.md) mirroring exit criteria for quicker PR references.

P2 CI & Automation
- Integrate auto-enable-perf-warn-gate.zsh into nightly ledger workflow (optional dry-run mode) for cross-validation of daytime variance vs nightly variance.
- Add perf-drift.json & perf-ledger.json ingestion into infra-health generator once stability proven (currently perf-ledger is integrated; drift waits for one stabilized week to avoid noise).

### 1.3 Variance Stability Log (Rolling)

Purpose: Trace empirical variance characteristics (multi‑sample runs) that drive observe → warn → gate transitions for performance regression enforcement. Updated only when a new qualifying multi-sample capture (or gating decision) occurs.

Schema (columns):
| Date (UTC) | Samples (N) | Metric | Mean (ms) | Stddev (ms) | RSD (stddev/mean) | Decision | Notes |
|------------|-------------|--------|-----------|-------------|-------------------|----------|-------|

Decision values: observe (collect only), candidate (meets stability thresholds but awaiting confirmation run), enable_warn (flip warn mode), enable_fail (flip hard gating), hold (variance too high), pending (insufficient data).

Initial Entries:

| Date (UTC) | Samples (N) | Metric | Mean (ms) | Stddev (ms) | RSD | Decision | Notes |
|------------|-------------|--------|-----------|-------------|-----|----------|-------|
| 2025-09-04 | 5 (synthetic) | pre_plugin_cost_ms | 85 | ~2–3 | ~0.03 | candidate | Synthetic multi-run replication (fallback); authentic loop fix pending F49. |
| 2025-09-04 | 5 (synthetic) | post_plugin_cost_ms | (synthetic placeholder) | n/a | n/a | hold | Synthetic replication; authentic capture required (F49→F50). |
| 2025-09-04 | 5 (synthetic) | prompt_ready_ms | (synthetic placeholder) | n/a | n/a | hold | Synthetic replication; awaiting authentic emission. |
| 2025-09-04 | n/a | governance_integration | n/a | n/a | n/a | observe | Governance badge active (explicit variance-state; synthetic variance pending authenticity). |
| 2025-09-04 | 3 (authentic simple) | pre_plugin_cost_ms | 352.33 | 18.91 | 0.0537 | observe | Authentic simple multi-run (fallback harness); RSD slightly >5% (5.37%) – collect additional run to qualify for candidate. |
| 2025-09-04 | 3 (authentic simple) | post_plugin_total_ms | 223.33 | 114.32 | 0.5119 | hold | High variance (values 144,141,385) – investigate outlier / capture conditions before gating. |
| 2025-09-04 | 3 (authentic simple) | prompt_ready_ms | 223.33 | 114.32 | 0.5119 | hold | Mirrors post; prompt still approximate (PROMPT_READY marker not emitted). |
| 2025-09-04 | 5 (authentic simple) | pre_plugin_cost_ms | 320.80 | 9.66 | 0.0301 | candidate | Second authentic multi-run; RSD 3.01% (<5%). Prior run 5.37% allowed under two-thirds rule; promoting to candidate. |
| 2025-09-04 | 5 (authentic simple) | post_plugin_total_ms | 145.60 | 4.96 | 0.0341 | observe | Outlier from prior run not reproduced; variance stabilized; remain observe pending confirmation & F54 outlier detector. |
| 2025-09-04 | 5 (authentic simple) | prompt_ready_ms | 145.60 | 4.96 | 0.0341 | observe | Mirrors post_plugin_total_ms; PROMPT_READY marker pending (F39a). |

Next Actions (related to stability):
- Re-run multi-sample after ensuring post_plugin_total and prompt_ready markers are emitted (expect non-zero values).
- If a second consecutive low-RSD (<5%) run with valid post_plugin_total occurs, promote decision for pre_plugin_cost_ms to enable_warn (gating env PERF_DIFF_FAIL_ON_REGRESSION still off until post_plugin_total also stable).
- Add automated extraction of max positive regression to drift badge once non-zero segments stabilized (ties into P1 drift badge enhancement).

Trigger to Update This Log:
- Any multi-sample capture producing non-zero post_plugin_total + prompt_ready_ms.
- Variance recommender output transitions (candidate → enable_warn / enable_fail).
- Introduction of additional metrics (e.g., interactive_ready_ms) once captured.

Additional Entries (Advanced Force-Sync Harness):

| Date (UTC) | Samples (N) | Metric | Mean (ms) | Stddev (ms) | RSD | Decision | Notes |
|------------|-------------|--------|-----------|-------------|-----|----------|-------|
| 2025-09-05 | 3 (advanced) | pre_plugin_cost_ms | 32.00 | 1.41 | 0.0441 | observe | First advanced force-sync authentic multi-run; low variance; segments array empty; PROMPT_READY approximated. |
| 2025-09-05 | 3 (advanced) | post_plugin_total_ms | 299.00 | 188.20 | 0.6294 | hold | High variance; outlier (index 0 value=565 >3.2x median=174); investigate segment emission + deferral. |
| 2025-09-05 | 3 (advanced) | prompt_ready_ms | 299.00 | 188.20 | 0.6294 | hold | Mirrors post; prompt markers absent (approximation fallback drives identical variance). |

Advanced Harness Test Checklist (Skeleton – to be instantiated as scripts):
- [ ] test: perf-multi schema presence (auth_shortfall, partial, rsd_pre, rsd_post, rsd_prompt, outlier.detected)
- [ ] test: auth_shortfall == 0 when samples == requested and all post values > 0
- [ ] test: partial == 0 under same successful conditions
- [ ] test: outlier factor calculation deterministic with fixed sample set
- [ ] test: segment parser emits ≥1 segment when perf sample JSON contains post_plugin_segments entries
- [ ] test: prompt_ready authenticity (fail if approximation fallback triggered when markers expected)
- [ ] test: retry loop (future) collects non-zero post after ≤ PERF_CAPTURE_SAMPLE_RETRIES attempts
- [ ] test: governance badge reflects multi_source=advanced after advanced run
- [ ] test: variance-state (future) alignment between governance badge mode and variance-state.json contents
- [ ] test: cache fingerprint skip logic (run bypass when fingerprint unchanged & file present)

README Badge Legend Stub (to add in README.md on next doc sync):
- Add variance-state.json row (variance) once variance-state artifact exists.
- Update governance.json row to include multi_source (simple|advanced) & authenticity (auth_shortfall, partial).
- Add perf-multi-current (advanced) mention: indicates authentic multi-sample capture source (force-sync/async).
- Clarify drift vs ledger vs variance interplay (badge interdependencies section).

(End 1.3)
- Add caching for multi-sample captures (store last multi-current fingerprint to skip redundant run if unchanged environment).

P2 Risk / Watchlist
- Risk: Function namespace expansion without manifest update → Mitigation: enforce manifest test strict after warm-up.
- Risk: Over-aggressive gating causing false negatives on macOS variance spikes → Mitigation: collect at least 2 weekend samples before enabling fail mode.
- Risk: PATH hygiene regression via external contributions → Mitigation: extend path append invariant test to detect mid-PATH insertions (not just deletions/order changes).

P3 Enhancements / Optional
- Prototype structured JSON emission for test-perf-ledger-drift (machine-readable for promotion guard).
- Add rolling median & MAD calculation to variance recommender (foundation for adaptive gating).
- Add SVG gradient variant for perf drift badge (visual emphasis for WARN vs FAIL).

Blocked / External Dependencies
- None currently blocking P1 items; gating enablement depends on natural variance stabilization (monitor over next 2 multi-sample runs).
- Awaiting first non-zero post_plugin_total snapshots in perf ledger (ensure plugin path conditions satisfied in capture harness).

Exit Signals to Reassess Plan
- PERF_DIFF_FAIL_ON_REGRESSION flipped to 1 on main.
- Two consecutive nightly perf-ledger snapshots with identical overBudgetCount=0.
- Core functions manifest stabilized (no additions for 3 days).

Ownership / Action Cues
- Core module refinements: same PR can batch 00/05/10 minor internal additions if tests updated atomically.
- Performance gating toggle: separate PR (small, easily revertible) once recommender JSON decision == enable_fail.

Metrics to Track This Week
- Variance % (post_plugin_total, prompt_ready)
- Drift counts (warn / fail) per PR
- OverBudgetCount trend (expect stable zero at current soft budgets)
- Core function count & manifest diff frequency (target: no unintentional changes)

(End Section 1.2)

## 2. Architecture & Stage Roadmap

### 2.1 Stage Overview (End-to-End)

| Stage | Label Tag | Scope | Exit Conditions | Status |
|-------|-----------|-------|-----------------|--------|
| 1 | `refactor-stage1-complete` | Skeletons, tests, tooling, CI, verification | All infra tests PASS & tag created | ✅ Done |
| 2 | `refactor-stage2-preplugin` | Implement pre-plugin 00–30 content | Path safety, lazy framework, node stubs, integrations, ssh-agent; baseline captured & tag pushed | ✅ Complete |
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

### 3.2 Stage 2 (Completed) – Pre-Plugin Content Migration
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
| Preplugin baseline capture (`preplugin-baseline.json`) | ✅ | Captured (mean=35ms N=5 tag=refactor-stage2-preplugin) |
| Stage tag creation (`refactor-stage2-preplugin`) | ✅ | Tag pushed & baseline locked |

Stage 2 Completion Summary:
- All pre-plugin modules (00–30) implemented with enhanced invariants, lazy integration wrappers, and ssh-agent idempotency.
- Baseline captured: mean=35ms, stdev=11ms, N=5 (artifact: `preplugin-baseline.json`).
- Tag `refactor-stage2-preplugin` pushed; baseline locked for regression guards.
- Instrumentation helpers (01/02) functioning in observe mode; excluded from canonical module count.
- Documentation and task ledger synchronized; Stage 2 exit criteria fully satisfied.

Post-Completion Notes (Deferred / Follow-ups):
- Regression guard tightened: pre-plugin allowed threshold reduced from +10% to +7%; target +5% after at least one additional low-variance (stdev/mean <5%) multi-sample set.
- Deferred async macOS defaults scheduling (will activate in Stage 5 with post-prompt hook refinement).
- Expand `lazy_register` richer integration behaviors (Stage 4/5).
- Integrate pre-plugin cost assertion directly into perf guard once guard tightening decision made.
- PATH append fix for test harness: ensure `.zshenv` appends (never overwrites) PATH in subshell contexts to guarantee availability of `awk`, `date`, `mkdir` during segment emission (schedule early Stage 3 if not already applied).

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

### Stage 3 Immediate Task List (Core Modules Bootstrap)

Execution Order (initial pass):
1. PATH append fix validation  
   - Confirm `.zshenv` only appends (never overwrites) PATH and preserves required core tool availability (`awk`, `date`, `mkdir`) in subshells.  
   - Add explicit test if not already covered.
2. Implement `00-security-integrity.zsh` (skeleton)  
   - Path hygiene enforcement (append semantics, no destructive rewrites)  
   - Export minimal trust anchor / checksum map reference (no hashing yet)  
   - Register integrity scheduler stub (deferred execution only)  
   - Idempotent sentinel + re-source test.
3. Implement `05-interactive-options.zsh`  
   - Consolidate `setopt` / `unsetopt`, history settings, base completion zstyles  
   - Ensure re-source produces zero diff snapshot (option snapshot test)  
   - Add sentinel guard + option snapshot golden file.
4. Implement `10-core-functions.zsh`  
   - Namespace: `zf::ensure_cmd`, `zf::log` (lightweight), `zf::warn`, minimal timing helper wrappers or adapters to segment-lib (no duplication)  
   - Add assertion utility (e.g. `zf::require`) for internal guards.  
   - Function namespace uniqueness + checksum/hash test.
5. Tests to Add / Finalize  
   - Path append invariant test (pre/post load diff)  
   - Option snapshot diff test (zero unintended changes)  
   - Function namespace uniqueness & idempotency test  
   - Core function count threshold test (CORE_FN_MIN_EXPECT; optional CORE_FN_GOLDEN_COUNT with CORE_FN_ALLOW_GROWTH)  
   - Golden option snapshot enforcement test (compare against `docs/redesignv2/artifacts/golden/options-snapshot-stage3-initial.txt`)  
   - Integrity scheduler single-registration test (no duplicate queue)  
   - Sentinel & idempotency design test (00 / 05 / 10 trio: sentinels, PATH non‑shrink, stable snapshots)  
   - Perf ledger drift comparison test (current vs latest history snapshot)  
   - Core functions manifest name-level drift test (golden manifest)  
   - Perf variance gating recommender (auto-enable-perf-warn-gate.zsh) stability streak logic & state file + integrated env handoff to perf-diff (conditional fail)  
   - Perf drift badge generation (perf-drift.json → SVG) surfaced in perf segments workflow & badges summary  
   - Helper availability test may call `tools/verify-path-helpers.zsh --assert both`.  
   - (Future) Enhanced perf ledger budget regression gate + infra-health badge aggregation verification (activate once variance <5% over ≥2 runs).
6. CI Enhancements  
   - Add non-fatal (observe) job step invoking `verify-path-helpers.zsh --assert any --json`; escalate to `--assert both` once both helpers guaranteed by Stage 3 mid-point.  
   - Introduce experimental perf module ledger capture (observe mode, nightly + PR):  
     `tools/experimental/perf-module-ledger.zsh --segments docs/redesignv2/artifacts/metrics/perf-current-segments.txt --output docs/redesignv2/artifacts/metrics/perf-ledger.json --budget post_plugin_total:3000,pre_plugin_total:120 --badge docs/badges/perf-ledger.json || true`  
   - Include `perf-ledger.json` + `perf-ledger` badge in existing badge summary aggregation (non-fatal).  
   - Gate escalation plan: once variance stable (<5%) and budgets tuned, enable `--fail-on-over` on main only.  
   - (Optional) Dry-run provisional post-plugin early cost ledger JSON (no gating yet).
7. Performance Guard Adjustments  
   - Collect two additional multi-sample runs (variance <5%) → tighten regression guard from +7% to +5%.  
   - Begin capturing early post-plugin partial cost ledger for impending budget planning (ledger artifact becomes historical comparator).  
   - Track over-budget counts trend (ledger `overall.overBudgetCount`) in badge summary for future automated gating signal.
8. Documentation / Reporting  
   - Update README Stage Progress (Post-Plugin Core % as each of 00 / 05 / 10 lands).  
   - Create / refine `stages/stage-3-core.md` with a live checklist mirroring this task list.  
   - Add ledger integration status row to Section 1 snapshot once first successful CI artifact exists (State: "Perf Ledger Prototype ✅ / Observe").  
   - Append Stage 3 readiness checklist to CONTRIBUTOR or implementation artifacts if not already enumerated.
9. Exit Criteria Preparation (Stage 3)  
   - [ ] PATH append invariant PASS  
   - [ ] Security skeleton idempotent  
   - [ ] Option snapshot stable (no drift)  
   - [ ] Core function namespace stable (checksum or count)  
   - [ ] Integrity scheduler registered exactly once  
   - [ ] Pre-plugin + early post-plugin perf within provisional budget (+≤5–8ms allowance)  
   - [ ] Tests added & green
10. Deferral Log (to Stage 4/5)  
   - Deep integrity hashing (Stage 5/6)  
   - Prompt / UI theming (Stage 5)  
   - Async execution activation beyond shadow mode (Stage 5+)  
   - Full segment budget hard gating (Stage 5/6)

Definitions of Done (Stage 3):
- Each new core module loads idempotently (re-source test passes, no side-effects on second load).
- Option snapshot diff returns empty (or only approved stable whitelist lines).
- All new functions reside in `zf::` namespace with no collisions or leakage into global space.
- Integrity scheduler stub presence verified; no execution prior to designated asynchronous activation stage.
- Path enforcement + helper verification both green in CI.

---

### 3.3 Stage 3 – Post-Plugin Core

Scope (Initial Focus Modules):
- `00-security-integrity.zsh`
  - Responsibilities: environment/path hygiene (enforce append-not-overwrite rule), shell option hardening, integrity scan scheduler stub (registration only), trust anchor / checksum map reference.
  - Success Metrics: sanitized PATH preserved post-load; integrity scheduler registered exactly once; zero duplicate hardening operations on re-source.
- `05-interactive-options.zsh`
  - Consolidate `setopt` / `unsetopt`, `zstyle`, history & completion base semantics.
  - Idempotent re-sourcing (sentinel var + diff test).
  - Success Metrics: option snapshot diff = empty; history settings canonical; no unintended env mutations.
- `10-core-functions.zsh`
  - Namespaced helpers (prefix `zf::`) for: safe command presence (`zf::ensure_cmd`), lightweight logging, timing primitive (potential future unification with segment timing), small assertion utilities.
  - Success Metrics: function namespace uniqueness test passes; per-helper overhead ≤1ms (microbench harness).

Non-Goals (Explicit Deferrals):
- Plugin load / feature plugins (Stage 4).
- Async completion / prompt finalization (Stage 5).
- Deep integrity scan execution & promotion gating (Stage 6).
- UI/prompt theming (Stage 5).

Planned Tests & Gates:
- PATH hygiene test (append semantics preserved; no destructive overwrite) – includes verification supporting the PATH append fix task.
- Re-source idempotency tests for each Stage 3 module.
- Option state snapshot: pre vs post module load; golden diff must be approved & stable.
- Function namespace collision & checksum stability test.
- Integrity scheduler single-registration assertion.

Performance Strategy (Stage 3):
- Provisional allowance: +5–8ms over locked pre-plugin baseline before plugins introduced.
- Maintain current +7% regression guard; plan tightening to +5% after 1–2 additional low-variance sample sets (stdev/mean <5%).  
- Dashboard Note (Stage 3): Pre-plugin guard now 7% (yellow band); next tightening gate = additional stable capture set.
- (Deferred) Module cost ledger JSON (target activation early Stage 4 when plugin costs begin).

Documentation / Ledger Updates:
- Add Stage 3 readiness checklist mirroring Stage 2 pattern:
  - [ ] PATH append fix confirmed (or implemented)
  - [ ] Security hardening applied & idempotent
  - [ ] Option snapshot test green
  - [ ] Function namespace tests green
  - [ ] Integrity scheduler registered once
  - [ ] Perf delta within provisional budget
  - [ ] Re-source idempotency verified

Open Decision (Resolved by Defaults):
- Namespace prefix: `zf::` adopted.
- Module cost ledger deferred to Stage 4.
- PATH append fix tracked as first Stage 3 task if still pending.

Upon completion, Stage 3 will establish a stable, secure, option-governed core onto which feature and plugin layers (Stage 4+) can attach without reintroducing baseline or integrity drift.

### 3.x Advanced Multi-Run Harness Status & Future Task List

Status (Advanced Harness – Force-Sync Mode):
- Force-sync path (PERF_CAPTURE_MULTI_FORCE_SYNC=1) now produces authentic multi-sample aggregates (`perf-multi-current.json`) with:
  - Fields: auth_shortfall, partial, rsd_pre, rsd_post, rsd_prompt, outlier block.
  - Authentic sample enforcement active (PERF_CAPTURE_ENFORCE_AUTH=1).
  - Partial handling simplified; retries currently disabled (PERF_CAPTURE_SAMPLE_RETRIES=0).
- Initialization gap resolved (PERF_CAPTURE_ENFORCE_AUTH / PERF_CAPTURE_ALLOW_PARTIAL / PERF_CAPTURE_SAMPLE_RETRIES defaults restored near top).
- Simplified authenticity logic avoids referencing legacy retry_exhausted & synthetic replication flags.
- Outlier detection functioning (median + >2x factor heuristic).
- Segment array currently empty in recent run → requires investigation (either emission absent upstream or parser needs adjustment).
- Prompt readiness still approximated (no PROMPT_READY markers) → inflates prompt variance symmetry with post_plugin_total.

Immediate Follow-Up (Documented as Complete in Code, Pending Secondary Validation):
- [x] Reintroduced default variable initialization.
- [x] Simplified authenticity enforcement & removed synthetic replication remnants.
- [x] Aggregate JSON emits stable schema (auth_shortfall now variable-driven).
- [x] Outlier block populated; factor verified.

Future Tasks (Queued – move to implementation schedule as capacity allows):
1. Segment Emission Restoration  
   - Verify per-run `perf-sample-*.json` still includes `post_plugin_segments`.  
   - If present: debug `segment_iterate_file` awk parser (label & mean_ms extraction).  
   - If absent: re-enable upstream segment export hooks (ensure compinit / theme / vcs segments written).
2. PROMPT_READY Authenticity  
   - Add explicit PROMPT_READY marker hook before final prompt render.  
   - Disable approximation fallback once stable to reduce variance coupling.
3. Minimal Retry Loop (Optional Re-Enable)  
   - Implement bounded retry for zero post/prompt fields (PERF_CAPTURE_SAMPLE_RETRIES>0) without reintroducing synthetic duplication.  
   - Set conservative default (e.g., 1–2) once stable.
4. Async Path Re-Hardening  
   - Reintroduce async child capture with improved watchdog (mtime + size delta heuristics) and failover to force-sync only on stall.  
   - Add progress logging toggle (PERF_CAPTURE_PROGRESS_DEBUG).
5. Segment-Level RSD & Per-Segment Variance Block  
   - Emit rsd_<segment_label> or a segments_variance array to support targeted optimization decisions.
6. Governance & Badge Integration Enhancements  
   - Auto-refresh governance badge on successful advanced multi-run (multi_source=advanced).  
   - Include auth_shortfall + partial in variance-state JSON.
7. Enhanced Outlier Strategy  
   - Add secondary heuristic: MAD-based factor or top-1 exclusion simulation for decision support.  
   - Emit outlier_excluded_mean when exclusion materially lowers RSD.
8. Caching Refinement  
   - Expand fingerprint to include guidelines checksum & high-sensitivity module mtimes.  
   - Add PERF_CAPTURE_CACHE_VERBOSE for cache decisions audit.
9. Documentation Updates  
   - README badge legend: add explicit row for variance mode (observe/warn/gate) and multi-run source (simple/advanced).  
   - IMPLEMENTATION.md Section 1.3: log first advanced authentic multi-run entry (authentic vs simple).
10. Async Activation Checklist (Prep)  
   - Define readiness gates: stable PROMPT_READY marker, segment coverage ≥ required set, retry loop pass rate > threshold.
11. Partial Aggregate Policy  
   - Decide whether partial_flag=1 aggregates should block gating transitions or only warn (update governance logic accordingly).
12. Performance Optimization Roadmap Linkage  
   - Add mapping: high RSD segments → proposed deferral or lazy loading tasks.
13. Test Additions  
   - Test to assert auth_shortfall=0 when samples==requested & no zero post values.  
   - Schema test for perf-multi-current.json (fail if fields missing or type-mismatched).  
   - Optional: outlier detection deterministic test with synthetic known set.
14. Migration Cleanup  
   - Remove any residual comments referencing synthetic replication or legacy fallback once async path restored.
15. Governance Summary Artifact (Optional)  
   - Generate provisional `governance-advanced.json` summarizing multi_source, auth_shortfall, rsd metrics for early review (not yet badge-bound).
16. Placeholder Test Script Scaffolding (Optional)  
   - Create empty test files matching Advanced Harness Test Checklist to reduce future PR surface (each initially skipping with a TODO marker).
17. Segment Parser Diagnostic Capture (Optional)  
   - Add a debug utility to dump raw `post_plugin_segments` from a single sample to aid parser verification before re-enabling async.

Tracking / Scheduling Recommendation:
- Classify items 1–3 as P0 (stability & authenticity completeness).
- Items 4–7 as P1 (feature parity + analytical depth).
- Items 8–10 as P2 (operational polish & future async enablement).
- Items 11–14 as P3 (policy clarity, test hardening, cleanup).

Exit Criteria for Declaring Advanced Harness “Stable”:
- ≥2 consecutive advanced force-sync (or async) runs with: auth_shortfall=0, partial=0, rsd_post < 0.10, segments array non-empty.
- PROMPT_READY authentic (no approximation) with rsd_prompt ≈ rsd_post (within ±10% relative).
- Outlier detection either not triggered or (if triggered) exclusion delta < threshold (e.g., <15% RSD reduction).

(End Advanced Multi-Run Harness Status)

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
| 2025-09-03 | Stage 2 baseline captured (pre_plugin_total mean=35ms N=5) | Established performance baseline; ready for Stage 3 entry criteria evaluation |
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
| 2025-09-04 | Stage 3 minimal exit (lifecycle trio, monotonic ordering, governance variance baseline) | Achieved non-zero lifecycle trio via single-run fallback + synthetic multi-run replication; monotonic ordering validated; governance badge (observe) generated with explicit variance-state source; logged remediation tasks F48–F50 to replace synthetic path before gating escalation |
| 2025-09-02 | Performance tooling expansion (multi-sample capture, variance & guard tests, budget script) | Added perf-capture-multi, promotion guard multi-sample fields (G5a), variance stability test, structured guard block test, segment budget enforcement (perf-segment-budget) |
| (Future) | Stage 5 compinit success | Mark compinit gate PASS |
| 2025-09-02 | Async Phase A (shadow) activation | Added dispatcher + manifest + shadow task registration, async integrity & shadow mode tests, placeholder sync segment probes, async metrics export & promotion guard async placeholders (no sync deferrals yet) |
| 2025-09-02 | Stage 2 implementation code complete (00–30 modules) | Pre-plugin modules implemented; baseline metrics & tag pending (`preplugin-baseline.json`) |
| 2025-09-02 | Stage 2 enhancements (modules 20 & 25 + preplugin threshold test) | Added deferred macOS defaults hook, lazy_register integration for direnv/gh, and test-preplugin-baseline-threshold.zsh |
| 2025-09-03 | Perf ledger prototype integration (experimental) | Added experimental perf-module-ledger script, CI perf-segments ledger step, nightly perf-ledger workflow (historical snapshots + optional fail-on-over), badge & summary integration (observe mode; soft budgets); added Stage 3 core tests (option snapshot stability, golden option snapshot, core fn namespace, core fn count, integrity scheduler single-registration, sentinels/idempotency design test, perf ledger drift comparison, core functions golden manifest), variance-based auto gating recommender script (`auto-enable-perf-warn-gate.zsh`) integrated into perf workflow (conditional perf-diff fail enablement), perf drift badge generation (JSON+SVG), infra-health badge integration of perf-ledger badge weighting, golden option snapshot & core function manifest baselines, updated gating plan (variance <5% ⇒ enable warn/gate; env toggles: PERF_DIFF_FAIL_ON_REGRESSION / PERF_LEDGER_FAIL_ON_OVER), and SVG rendering for perf-ledger & perf drift badges. |
| 2025-09-04 | Stage 3 core hardening additions (trust anchors + micro benchmark + variance log + drift badge enhancement + caching) | Added trust anchor read helper APIs (zf::trust_anchor_has/get/keys/dump) + unit test; introduced Section 1.3 Variance Stability Log; added micro-benchmark harness (bench-core-functions.zsh) and smoke test; implemented fingerprint caching in perf-capture-multi (skip redundant multi-sample runs); added perf-drift-badge.sh producing enhanced badge message with max positive regression suffix; documented readiness & harness in stage-3-core.md. |
| 2025-09-04 | Stage 3 segment & gating enablement groundwork (markers test, drift badge presence test, exit report scaffold) | Added test-required-stage3-segments.zsh (segment presence + non-zero checks), test-perf-drift-badge-presence.zsh (warn-mode drift badge validation), stage3-exit-report.sh (mini exit report generator), future task backlog section, and planned gating transition steps (observe → warn → gate) appended to Section 1.2. |
| 2025-09-04 | Core micro-benchmark baseline (shim stabilization) | Stabilized bench harness (enumeration + shim fallback, safe error handling), captured initial bench-core-baseline.json (500x2 observe mode), added enumeration_mode + shimmed_count meta, planned true-function enumeration + drift guard tasks. |
| 2025-09-04 | CI drift badge integration & auto bench baseline capture | Integrated perf-drift badge generation (observe) + conditional micro benchmark baseline capture in publish workflow; established automation path for README badge activation; items 1–3 (segment emission prep, drift badge workflow scaffolding, micro bench baseline path) partially completed (awaiting non-zero post/prompt for full closure). |
| 2025-09-04 | Monotonic lifecycle & micro bench regression tests (warn-only) | Added test-perf-monotonic-lifecycle.zsh (ordering pre≤post≤prompt, non-strict by default) and test-bench-core-regression.zsh (warn-only ratio checks; skips when shims present); marked partial fulfillment of F4 (strict enforcement still pending) and introduced new future tasks F23 (strict monotonic gate after stable non-zero metrics) & F24 (integrate micro bench regression summary into governance badge / gating). |
| 2025-09-04 | Governance badge & guard integration (draft) | Added generate-governance-badge.zsh (aggregates drift, ledger, variance, micro bench signals) and integrated monotonic lifecycle ordering + micro bench summary (observational) into promotion-guard.zsh (new exit code 12); future tasks F25 (governance badge CI & extended schema adoption) and F26 (micro bench severity escalation in guard) logged. |
| 2025-09-04 | Governance badge CI integration (extended artifacts & workflow wiring) | Integrated governance badge generation into ci-perf-segments (PR + nightly multi-sample) and ci-perf-ledger-nightly workflows producing extended artifact (docs/redesignv2/artifacts/badges/governance.json) and simple shield (docs/badges/governance.json); README badge legend scaffolded; F25 marked complete; follow-up: infra-health aggregation & variance-state source integration. |
| 2025-09-04 | Variance-state explicit mode artifact (observe baseline) | Added generate-variance-state-badge.zsh producing variance-state.v1 (mode, rsd, streak); integrated steps into perf segments & nightly ledger workflows (pre-governance). Governance badge scheduled to switch from derived variance_mode to explicit source (F40). |


### 1.4 Future / Logged Tasks (Discovered & Deferred)
(These items were identified during implementation of Tasks 1–9; not yet in active 7‑day window. Move into Section 1.2 when promoted.)

Future / Deferred (F):
- F1: Integrate perf-drift-badge.sh into CI workflow (generate docs/redesignv2/artifacts/badges/perf-drift.json each perf run).
- F2: Add max_positive_regression_pct field directly into perf-module-ledger JSON (replace re-parse of perf-diff output).
- F3: Add JSON schema + version tag to perf-drift badge and ledger artifacts (enforce via test).
- F4: Enforce monotonic ordering test: pre_plugin_total <= post_plugin_total <= prompt_ready (strict once markers stable).
- F5: Add trust anchor golden manifest & hash once anchors >2 and hashing phase begins (Stage 5/6).
- F6: Extend micro-benchmark harness JSON test to validate schema bench-core.v1 and per_call_us drift (warn if >100% over baseline).
- F7: Create combined performance governance badge summarizing (variance state + max regression + over_budget_count).
- F8: Automate variance stability log append via workflow step (avoid manual edits).
- F9: Add stage3-exit-report.json machine-readable companion for promotion guard ingestion.
- F10: Add prompt/post-plugin threshold enforcement test (fail if prompt_ready_ms > interim soft target once real values appear).
- F11: Add ledger history diff to stage3-exit-report (if 2+ ledger history snapshots exist).
- F12: Build perf multi-sample cache invalidation test (ensures fingerprint change triggers capture).
- F13: Add optional MAD / median variance computation to perf-capture-multi.zsh (adaptive gating prototype).
- F14: Warn-on-missing drift badge suffix once max_positive_regression_pct embedding lands (test upgrade).
- F15: Add README badges row updates (perf drift, variance decision, micro bench) once artifacts stabilized.
- F16: Replace shim fallback with real Stage 3 function sourcing (ensure all zf:: functions loaded without shims before gating).
- F17: Add guard test that warns/fails if shimmed_count > 0 after Stage 3 (enforces real function benchmarking).
- F18: Automate micro benchmark re-baseline when core function manifest or function body checksums change (skip if no semantic diff).
- F19: Integrate micro benchmark median per-call regression summary into combined governance badge (add micro_regress_max_pct field).
- F20: Add noise filtering to micro benchmark harness (trim/winsorize top 5% outliers; record raw vs adjusted medians).
- F21: Drift badge gating escalation workflow (auto transition observe → warn → fail after variance RSD <5% for 2 consecutive runs & non-zero lifecycle trio).
- F22: Micro benchmark gating phase (warn on median_per_call_us > baseline * 2, fail on > baseline * 3 once shimmed_count == 0 and baseline stabilized).
- F23: Enforce monotonic lifecycle ordering strictly (pre ≤ post ≤ prompt) after two consecutive multi-sample runs with all three non-zero (upgrade test-perf-monotonic-lifecycle.zsh to strict).
- F24: Micro benchmark governance integration (add bench regression summary fields & badge; promote test-bench-core-regression.zsh from warn-only to gated after shimmed_count == 0).
- F25: (COMPLETED 2025-09-04) Governance badge CI integration delivered: generation wired into ci-perf-segments (PR + nightly multi-sample) and ci-perf-ledger-nightly workflows producing extended artifact (docs/redesignv2/artifacts/badges/governance.json) and simple shield (docs/badges/governance.json); README badge row scaffold added.
- F26: Promotion guard micro bench escalation (fail when microbench_worst_ratio >= MICRO_FAIL_FACTOR & shimmed_count == 0; warn when >= MICRO_WARN_FACTOR) once baseline finalized.
- F27: Governance badge infra-health & summary integration (weight governance severity in infra-health badge, include governance.json in badges summary aggregation, add variance-state source once artifact available, document weighting rationale).
- F28: Variance-state artifact & badge generation (produce variance-state.json with mode=observe|warn|gate & integrate as explicit governance source; add generation step to perf segments workflow).
- F29: Shim elimination audit script (enumerate currently shimmed helpers, diff vs manifest, emit actionable list prior to executing F16; add summary to governance extended JSON once shims=0).
- F30: Micro bench threshold codification (centralize BENCH_WARN_FACTOR=2.0 & BENCH_FAIL_FACTOR=3.0; update test-bench-core-regression.zsh + governance badge to consume unified factors).
- F31: README governance publishing cleanup (switch governance badge example to Pages endpoint, add embedding snippet & explanation of extended vs simple JSON).
- F32: Stage 3 exit report enhancement (include governance badge stats snapshot + last N variance log rows + monotonic status).
- F33: PR description template generator script (emit performance + governance summary block for maintainers; integrate optional GitHub Actions step).
- F34: Pages badge integrity manifest (generate badges-integrity.json with sha256 for governance / perf / structure; optional future signing step).
- F35: Micro benchmark drift detection (compare new run vs baseline medians; emit microbench_drift_count & microbench_worst_ratio into governance extended JSON).
- F36: Automated micro gating escalation (script watches for shimmed_count==0 + two stable drift-free runs to auto-suggest enabling micro bench gating env toggles).
- F37: Governance weighting matrix doc (document severity aggregation logic and planned infra-health weighting integration for governance badge).
- F38: (Implemented) post_plugin_total fallback aggregator (sum post_plugin_segments when post_plugin_cost_ms==0 & segments_available=true) to unblock monotonic validation path; verify first synthesized non-zero total before marking monotonic=ok path complete.
- F39: prompt_ready_ms reliability enhancement (inject explicit PROMPT_READY marker in harness after >2 consecutive approximations; add fallback counter + governance surface).
- F40: (COMPLETED 2025-09-04) Governance badge explicit variance-state integration (consumes variance-state.json instead of derived placeholder; removed “derived” label & added stable_run_count passthrough).
- F41: Perf ledger embed max_positive_regression_pct (add field to perf-ledger JSON to eliminate drift badge re-parse inside governance aggregation).
- F48: Remove synthetic multi-sample replication hack from perf-capture-multi (replace cloned sample synthesis with authentic aggregation once loop reliability restored).
- F49: Repair perf-capture-multi loop termination (ensure >1 sample executes fully; add watchdog, retry semantics, robust error propagation).
- F50: Recompute variance-state.json using real multi-sample RSD after F49; update governance badge fields (drop synthetic indicators) and reassess observe → warn transition readiness.

- F51: Add retry_exhausted sample flag surface & governance integration (include flag in perf-multi-current.json sample_flags, propagate summary count + presence into governance extended JSON; WARN annotation when >0 and variance_mode != insufficient_samples).
- F52: Embed lifecycle RSD metrics (rsd_pre, rsd_post, rsd_prompt) in governance extended JSON (stats.*) to accelerate observe→warn variance gating evaluation and document thresholds directly in badge data.
- F53: Generate insufficient_samples badge (docs/redesignv2/artifacts/badges/variance-samples.json) when authenticity shortfall occurs (auth_shortfall>0) and integrate its status into infra-health weighting; add governance note linking authenticity remediation tasks (F49/F48/F50).
- F49b: Governance & variance ingestion bridge (consume perf-multi-simple.json when advanced harness partial; surface rsd_pre/post/prompt + authentic_samples).
- F39a: PROMPT_READY explicit marker (remove prompt=post fallback; lower prompt variance noise).
- F54: Per-run segment outlier detector (flag >2x median contributors; export outlier_segment, outlier_factor).
- F55: Variance-state generator prefers authentic simple source (source=simple vs advanced).
- F56: Advanced harness parity & retirement of simple fallback once stable; remove partial mode.
- F57: Gating readiness doc augmentation (explicit RSD thresholds for pre/post variance).
- F58: Segment-level variance RSD summary (compinit, theme, others) for targeted deferral planning.
Promotion Pre-Requisites (will move to active window when nearing Stage 3 exit):
- PP1: Two consecutive stable multi-sample runs (RSD <5%) with non-zero post_plugin_total and prompt_ready_ms.

### Stage 3 Exit Readiness Checklist

| Check | Status (Target) | Evidence / Source | Notes / Action if Failing |
|-------|-----------------|-------------------|---------------------------|
| PATH append invariant test passing | Required | tests/unit/... path normalization tests | Must be green; investigate helper if failing |
| Security skeleton idempotent | Required | security skeleton test + integrity scheduler log | Duplicate registration or reordered hooks → fix module load |
| Option snapshot stability | Required | option snapshot golden diff test | Re-capture only with intentional change + documented rationale |
| Core function namespace stable | Required | core fn manifest + namespace tests | Regenerate manifest only after reviewed additions/removals |
| Integrity scheduler single registration | Required | integrity scheduler single-registration test | Ensure no duplicate deferred task insertion |
| Lifecycle segments non-zero (pre, post, prompt) | Required | perf-current.json multi-sample run | If post/prompt zero: inspect harness prompt hook emission |
| Monotonic lifecycle = ok (pre ≤ post ≤ prompt) | Required | promotion-guard output monotonic=ok | If warn: trace late segment or prompt timestamp race |
| Variance stability (≥2 low-RSD runs) | Target | Variance Stability Log (RSD <5%) | Needed before enabling warn/fail gating |
| Drift badge present & not fail | Required | docs/badges/perf-drift.json | If missing: ensure perf-diff & drift script step executed |
| Governance badge active (ok or warn only) | Required | docs/badges/governance.json | Fail severity blockers: high regression, over_budget in gate, micro fail |
| Perf ledger snapshots (≥2) with non-zero post | Target | ledger-history directory | Needed for early trend & budget tuning confidence |
| Micro benchmark baseline captured | Required | bench-core-baseline.json | If absent: run bench harness; ensure enumeration_mode != exports_fallback |
| shimmed_count == 0 (or plan F16 scheduled) | Target | bench-core-baseline.json shimmed_count | Blocker for micro gating escalation (F22/F26) |
| Promotion guard all checks pass (exit 0) | Required | CI promotion guard logs | Non-zero codes map to gating docs; resolve before exit |
| TDD gate (G10) pass | Required | enforce-tdd.sh log / guard output | Address failing new/changed test debt before promotion |
| Structure audit green (no violations) | Required | structure-audit.json / badge | Any violation blocks exit; fix ordering / duplicates |
| Path rules badge green | Required | path-rules badge JSON | Violations must be remediated (enforced fail-fast) |
| Infra health badge not red | Required | infra-health.json | Red indicates upstream gating failure or critical signal |
| Governance weighting integration planned (F27) | Informational | Future task list | Not blocking Stage 3 but note schedule |
| Stage 3 exit report generated | Required | stage3-exit-report.sh output | Include governance, variance, monotonic note, ledger snapshot summary |
| Gating readiness decision documented | Required | IMPLEMENTATION.md gating notes | Document enable_warn / enable_fail rationale & streak counts |
| Async shadow mode stable (no premature RUNNING) | Required | async-state.log & guard checks | Fail indicates async mis-sequencing |
| No red badges (perf / structure / governance) | Required | docs/badges/*.json | Red perf requires regression remediation |

Checklist Usage:
1. Run forced multi-sample capture (PERF_CAPTURE_FORCE=1) until lifecycle trio non-zero & monotonic=ok.
2. Update Variance Stability Log and confirm at least two low-RSD entries.
3. Ensure governance badge transitions from missing → ok/warn (not fail).
4. Eliminate (or plan elimination of) shims prior to enabling micro gating tasks (F22/F26).
5. Generate stage3-exit-report.sh and attach to PR marking Stage 3 completion.

Exit Authorization Condition:
All Required items must be satisfied; Target items should be satisfied or explicitly deferred with documented rationale. Promotion should not proceed if any Required line shows failing status without an approved exception note recorded in IMPLEMENTATION.md.

- PP2: Gating toggle commit (PERF_DIFF_FAIL_ON_REGRESSION=1) after PP1.
- PP3: Stage 3 exit mini-report generated & committed (stage3-exit-report.sh output).
- PP4: Optional micro baseline drift smoke (warn-only) enabled.

(End Section 1.4)

---

**Single Source of Truth**: If any other document conflicts with this guide, this file prevails until explicitly versioned.

[Back to Documentation Index](README.md) | [Architecture](ARCHITECTURE.md) | [Reference](REFERENCE.md)