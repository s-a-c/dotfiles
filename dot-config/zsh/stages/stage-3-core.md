# Stage 3 Core Objectives (Redesign Progression)
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

STATUS: Draft (skeleton – to be iteratively refined before Stage 3 entry)
SCOPE: Post–Stage 2 (pre‑plugin migration + segment instrumentation) → foundational security, interactive performance, completion hardening, and structured lazy/runtime optimization.

---

## 1. Purpose

Stage 3 establishes the “secure & observable core” of the redesigned ZSH environment:
- Formalizes integrity & trust boundaries (startup surface, plugin execution, completion system).
- Elevates performance focus from gross startup time → interactive + segment micro-metrics.
- Introduces robust completion and function namespace hygiene.
- Expands lazy activation patterns beyond Node to additional heavy subsystems (e.g. Python version managers, language servers, legacy wrappers).
- Provides test & policy scaffolding so later stages (Stage 4+: advanced ergonomics and adaptive behaviors) build on a locked, measured baseline.

---

## 2. Thematic Pillars

| Pillar | Objective Summary | Exit Signal |
|--------|-------------------|-------------|
| Security Baseline | Integrity, immutability of critical pre-plugin artifacts; controlled `fpath` & plugin sourcing | All integrity tests green; tamper tests fail safely |
| Interactive Performance | Measure prompt readiness, first-command latency, post-plugin micro-cost | `perf-current.json` includes prompt + “ready” segments |
| Completion Hardening | Single compinit path, collision detection, function namespace audit | Collision inventory stable; no duplicate autoload overrides |
| Lazy Loading Expansion | Extend lazy stubs to ≥2 additional ecosystems (e.g. pyenv, rbenv) | Tests show zero sourcing until first tool invocation |
| Observability & Instrumentation | Unified marker schema + JSON export for segments & prompt timeline | `segments_available=true` + new keys present |
| Policy & CI Enforcement | Stage-specific gate enforcing perf ceilings + security invariants | Promotion guard passes with new Stage 3 checks |
| Recovery & Determinism | Fallback paths for degraded environments (missing dependencies) | Simulated degraded tests PASS (graceful fallback) |

---

## 3. Detailed Objectives & Tasks

### 3.1 Security Baseline
1. Integrity Sentinels
   - Hash & record: key pre-plugin scripts (00-path-safety, 05-fzf-init, 15-node-runtime-env, 40-reserved).
   - Store in `docs/redesignv2/artifacts/metrics/integrity-current.json`.
2. Tamper Detection
   - Test modifies a pre-plugin file mid-run → expect detection + safe abort (non-zero exit).
3. Controlled `fpath` Ordering
   - Test asserts no late injection mutates early canonicalized path ordering post-plugin.
4. Plugin Sourcing Guard
   - Enforce explicit allow-list (deny silent sourcing of arbitrary new plugin dirs).
5. SSH Agent Hardening
   - Confirm reuse + no duplicate spawn under rapid parallel shell initiation (stress test).

### 3.2 Interactive Performance
1. Additional Segment Markers
   - `PROMPT_READY_MS` (time until first PS1 render).
   - `FIRST_CMD_E2E_MS` (optional: first trivial builtin like `:` or `true`).
2. Perf Capture Enhancements
   - Extend `perf-capture.zsh` to emit: `prompt_ready_ms`, `interactive_ready_ms`.
3. Regression Tests
   - Thresholds relative to Stage 2 baseline (configurable env overrides).
4. Variance Tracking
   - 5-run sample; store stdev & relative stdev for prompt readiness.

### 3.3 Completion System Hardening
1. Single Compinit Proof
   - Existing tests extended to assert no hidden re-runs (audit call trace markers).
2. Function Collision Audit
   - Enumerate all autoloadable functions; detect duplicates & shadowing.
   - Export `function-collisions.json`; Stage 3 exit requires controlled (justified) set.
3. Deferred Compdump Optimization (Optional)
   - Evaluate gzip or relocation to cache partition; measure delta impact.

### 3.4 Lazy Loading Expansion
1. Framework Targets
   - Python (pyenv or asdf), Ruby (rbenv), optional: Go toolchain path expansion.
2. Stub Pattern Consistency
   - Shared helper for stub registration + self-replacement logging.
3. Tests
   - Pre-call: stub marker present; Post-call: stub removed; Idempotence stable.
4. Negative / Missing Tool Paths
   - Graceful SKIP tests when binary managers absent (no false FAIL).

### 3.5 Observability & Instrumentation
1. Unified Marker Spec (Doc)
   - Document: PRE_PLUGIN_COMPLETE, POST_PLUGIN_COMPLETE, PROMPT_READY, INTERACTIVE_READY, PERF_PROMPT:COMPLETE (legacy compatibility).
2. JSON Normalization
   - `perf-current.json` includes: `pre_plugin_cost_ms`, `post_plugin_cost_ms`, `prompt_ready_ms`, `segments_available`.
3. Log Scraper
   - Lightweight tool to reconstruct timeline from raw marker log for debugging (e.g. `tools/perf-timeline.zsh`).
4. Timeline Sanity Test
   - Ensures monotonic increasing ms values; fails on anomalies.

### 3.6 Policy & CI Integration
1. Promotion Guard Stage 3 Module
   - New rule: reject if pre-plugin or prompt segments regress > allowed pct.
2. Drift Detection
   - Composite guidelines checksum reconfirmed & embedded in any Stage 3 authored artifacts.
3. Structured Exit Report
   - Auto-generated `stage-3-exit-report.md` summarizing metrics, deltas, variances, security findings.

### 3.7 Recovery & Determinism
1. Degraded Mode Tests
   - Simulate missing FZF, missing NVM, missing pyenv; environment should still pass core tests.
2. Resilience Assertions
   - Pre-plugin path safety operates even if $HOME unwritable (simulate with tmp overlay).
3. Audit Logging Fallback
   - If `zmodload zsh/datetime` fails, timing gracefully disabled (test verifies no crash).

---

## 4. Metrics & Threshold Proposals (Initial Defaults)

| Metric | Source | Threshold (Fail if) | Rationale |
|--------|--------|---------------------|-----------|
| pre_plugin_cost_ms | perf-current.json | > 175ms absolute OR > +25% baseline | Guard expansion creep |
| post_plugin_cost_ms | perf-current.json | > 250ms | Enforce modularization |
| prompt_ready_ms | perf-current.json | > 400ms warm | User perceived readiness |
| regression_pre_pct | Derived | > configured tolerance | Tunable via env |
| function_collisions | collision audit | Any unapproved increase | Namespace hygiene |

(Thresholds to be tuned after empirical capture; early generous bounds intentionally conservative.)

---

## 5. Test Plan Mapping

| Test Category | New / Extended Tests |
|---------------|----------------------|
| performance | `test-preplugin-segment-threshold.zsh` (already added), `test-prompt-ready-threshold.zsh` (new) |
| security | `test-preplugin-integrity-hash.zsh`, `test-plugin-source-allowlist.zsh`, tamper simulation |
| integration | Lazy loaders for pyenv/rbenv/asdf (`test-lazy-<tool>-activation.zsh`) |
| design | Marker schema validation (`test-marker-timeline-consistency.zsh`) |
| resilience | Degraded environment simulations (`test-degraded-missing-fzf.zsh`, etc.) |

---

## 6. Exit Criteria (Stage 3 “Green” Requirements)

All MUST be true:
- C1: All Stage 2 tests remain passing (no regressions).
- C2: New Stage 3 test suite passes (no FAIL, only allowed SKIP for absent optional ecosystems).
- C3: `perf-current.json` includes non-zero pre_plugin_cost_ms and prompt_ready_ms.
- C4: post_plugin_cost_ms captured (even if low) – not null.
- C5: Integrity baseline file created & tamper tests detect modification.
- C6: Function collision audit stable vs recorded snapshot (`function-collisions.json`).
- C7: Lazy loader expansion ≥ 2 additional ecosystems with passing invariants.
- C8: No unreviewed increase in allowed PATH or fpath entries post-plugin (diff test).
- C9: Stage 3 exit report generated & references correct guidelines checksum.
- C10: Promotion guard module (Stage 3) enforces thresholds in CI.

---

### 6.1 Readiness Checklist & Micro-Benchmark Note

A living Stage 3 readiness checklist is derived directly from Section 6 exit criteria:
- Use Section 6 as the authoritative checklist (C1–C10).
- When implementing supporting artifacts, reference them explicitly in commit messages (e.g., "stage3: C3 prompt_ready_ms capture").

Micro-Benchmark Harness (Informational – Stage 3 Adjacent):
- Placeholder directory added: tests/performance/core-functions/
- README defines forthcoming script: bench-core-functions.zsh (observe mode).
- Intent: measure per-call µs for zf::* helpers (log/warn/ensure_cmd/require/list_functions/with_timing).
- Not a gate in Stage 3; first baseline capture will be stored after harness lands, then considered for warn-only drift reporting in later stages.

(End 6.1)

## 7. Risk Register (Condensed)

| Risk | Impact | Mitigation |
|------|--------|------------|
| Over-instrumentation adds latency | Startup regression | Keep instrumentation guarded; measure after enabling |
| Collision audit false positives | Noise / blocked exit | Whitelist canonical overlaps; baseline snapshot diff |
| Lazy stubs masking real errors | Hidden runtime failures | Emit stub->real transition log + test asserts success |
| Hash-based integrity fragile to benign refactors | Frequent baseline churn | Hash stable set only; exclude comments or normalize content |
| Prompt-ready measurement drift (async hooks) | Unreliable metric | Capture marker immediately before first PS1 render path |

---

## 8. Open Questions (To Resolve Early)

1. Should post-plugin timing exclude first on-demand plugin autoload side-effects? (Proposed: yes; measure core load only.)
2. Adopt median vs mean for micro-segment fluctuations? (Proposed: record both; gate on median.)
3. Integrity hashing: single SHA-256 concatenation vs per-file map? (Proposed: per-file map for diff clarity.)

---

## 9. Implementation Order (Suggested)

1. Solidify marker schema + perf capture extensions.
2. Add integrity hashing + tamper test.
3. Implement prompt readiness capture + tests.
4. Expand lazy loading (pyenv/rbenv) + tests.
5. Function collision audit & snapshot.
6. Regression thresholds + promotion guard updates.
7. Degraded environment resilience tests.
8. Stage 3 exit report generator.

---

## 10. Artifact Additions (Planned)

| File | Purpose |
|------|---------|
| tools/perf-timeline.zsh | Reconstruct readable timeline from marker log |
| docs/redesignv2/artifacts/metrics/perf-segment-baseline.json | Baseline segment reference |
| docs/redesignv2/artifacts/metrics/integrity-current.json | Current hash map |
| docs/redesignv2/stage-3-exit-report.md | Auto-generated exit summary |
| tests/performance/test-prompt-ready-threshold.zsh | Prompt readiness guard |
| tests/security/test-preplugin-integrity-hash.zsh | Integrity validation |
| tests/security/test-plugin-source-allowlist.zsh | Enforce controlled sourcing |
| tests/performance/test-prompt-timeline-consistency.zsh | Marker ordering |
| tests/performance/core-functions/README.txt | Micro-benchmark harness scaffold (Stage 3 placeholder; documents upcoming bench-core-functions.zsh) |
| tests/performance/core-functions/bench-core-functions.zsh (planned) | Micro benchmark loop for zf::* helpers (observe mode, non-gating; will emit BENCH lines + optional JSON) |

---

## 11. Environment / Configuration Keys (New)

| Variable | Default | Description |
|----------|---------|-------------|
| ZSH_PERF_PROMPT_MARKERS | 1 | Enable prompt-ready instrumentation |
| PREPLUGIN_MAX_MS | 150 | Absolute upper pre-plugin bound |
| PREPLUGIN_REGRESSION_PCT | 15 | Allowed % over baseline |
| PREPLUGIN_REQUIRE_BASELINE | 0 | Force failure if baseline absent |
| PROMPT_READY_MAX_MS | 400 | Warm prompt upper bound |
| ZSH_LAZY_PYTHON | 1 | Enable pyenv/asdf lazy stub |
| ZSH_LAZY_RUBY | 1 | Enable rbenv/asdf lazy stub |

---

## 12. Documentation Commit Requirements

Each new Stage 3 artifact must:
- Include compliance header (guidelines checksum).
- Reference marker schema section if touching instrumentation.
- If security affecting, cite policy rule with file:line reference (Stage 3 enforcement action).

---

## 13. Post-Stage 3 Preview (Stage 4 Teasers – Not In Scope Yet)

- Dynamic adaptive prompt latency optimizations.
- Async plugin cold compiling abstraction.
- Command usage telemetry (opt-in) → suggestion engine.
- Contextual lazy completions.

---

## 14. Next Actions (To Start Stage 3)

1. Implement segment baseline file writer (optional initialization).
2. Add integrity hashing utility script.
3. Add prompt readiness marker & integrate into perf capture.
4. Create initial Stage 3 test stubs (skipping until utilities land).
5. Run promotion guard dry-run to confirm no false positives.

---

Prepared as a living skeleton; refine thresholds & ordering once first empirical prompt segment metrics are captured under realistic workload.
