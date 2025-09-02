# Async Enablement & Risk Mitigation Plan
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

Status: Stage 2 (pre‑plugin); Performance Phase 0 (Observe)  
Scope: Introduces structured risk register, async subsystem design, rollout phases, manifest governance, testing strategy, and immediate actionable tasks.

---

## 1. Purpose

Establish a controlled, testable path to introduce an asynchronous execution layer that:
1. Reduces synchronous startup (drive `post_plugin_total` toward ≤3000ms interim goal, then ≤500ms final budget).
2. Preserves determinism for performance gating (variance ceiling rel stddev ≤0.15).
3. Avoids regressions (prompt flicker, missing data, race conditions).
4. Integrates with existing Gates (G4 Async, G5/G5a Perf Guard, G6 Budgets, G7 Regression).

---

## 2. High-Level Objectives

| Objective | Success Metric | Phase for Validation |
|-----------|----------------|----------------------|
| Shorten synchronous critical path | Decrease `post_plugin_total` (sync portion) ≥30% vs current mean before deeper optimizations | After Phase C (Active Minimal) |
| Maintain low variance | `post_plugin_total` relative stddev ≤0.15 | Prior to Phase B promotion to C |
| Stable async framework | No `RUNNING` async task before first `prompt_ready` | Every CI run (Gate G4) |
| Deterministic budgeting | Split metrics: `sync_path_total` vs `async_total_accumulated` | Phase D |
| Safety under failure | Timeout + fallback without shell abort | Phases B–E tests |

---

## 3. Consolidated Risk Register

| ID | Risk | Likelihood | Impact | Phase Exposure | Mitigation | Detect Signal |
|----|------|------------|--------|---------------|------------|---------------|
| R1 | Opaque time segments stall optimization | Medium | High | Pre-A | Expand segment probes before deferrals | Missing granular segments >10% total |
| R2 | Variance remains high blocking gating | Medium | Medium | A→B | Multi-sample (N≥5) + outlier trim + median-of-medians | rel stddev >0.15 |
| R3 | Async race causing pre-prompt work | Low | High | B→C | Deferral guard: do not start queue until `prompt_ready` mark scheduled; shadow mode dry-run | Segment for async task start before prompt |
| R4 | Prompt flicker / stale UI data | Medium | Medium | C→D | Shadow + dual compare; atomic application of async results | UI diff test failure |
| R5 | Timeout / hung worker | Medium | Medium | All | Per-task timeout + watchdog heartbeat | Timeout segments or missed heartbeat |
| R6 | Resource saturation (too many tasks) | Low | Medium | D→E | Priority queue + concurrency caps | Large queue backlog metric |
| R7 | Misattribution of costs post-migration | Medium | Medium | All | Task-level segments and manifest diffs | Unclassified residual >10% |
| R8 | Budget enforcement premature (false negatives) | Medium | Medium | C | Keep ENFORCE=0 until sync reductions validated | Budget script warn spam |
| R9 | Drift between manifest & runtime tasks | Medium | Medium | All | Manifest integrity test + checksum | Integrity test fail |
| R10 | Test flakiness due to timing | Medium | Low | All | Threshold buffers + retry semantics for variance tests | Sporadic CI fails with no code changes |
| R11 | zpty incompatibility edge cases | Low | Medium | B | Fallback to background jobs mode | zpty init failure log |
| R12 | Async error swallow (silent failures) | Medium | Medium | C→E | Structured status & error segment emission `_fail` | Missing `_done` + absent `_fail` |

---

## 4. Async Scope & Non-Goals

In Scope:
- Deferral of non-critical plugin initialization, VCS warming, completion cache building, theme extras, security deep scan scheduling.
- Structured metrics + gating integration.

Out of Scope (initial phases):
- Live interactive streaming of partial prompt segments.
- Cross-shell shared async daemon.
- Persistent caching layer (postponed until after stable async adoption).

---

## 5. Segment Expansion Plan (Pre-Async Prerequisite)

Add the following synchronous instrumentation BEFORE deferral to preserve baseline attribution:

| Proposed Segment | Rationale |
|------------------|-----------|
| `syntax_highlight_init` | Identify cost of syntax highlighting plugin(s) |
| `history_backend_init` | Distinguish history configuration overhead |
| `theme_extras_init` | Separate optional prompt embellishments |
| `completion_cache_scan` | Cost of building/populating completion caches |
| `vcs_helpers_init` | Non-gitstatus VCS helper scripts cost |
| `fzf_tools_init` | FZF-related plugin/tool init overhead |
| Future: `async_queue_init` | Mark async dispatcher initialization |
| Future: `async_flush_cycle` | Each collection loop timing |

All new segments:
- Emitted with phase classification (pre_plugin or post_plugin).
- Added to required-or-optional test lists.
- Documented in manifest (Appendix).

---

## 6. Architecture Options Evaluated

| Option | Mechanism | Pros | Cons | Decision |
|--------|-----------|------|------|----------|
| A | Background (&) subshell jobs | Simple; portable | PID tracking + IPC coarse | Fallback |
| B | `zpty` worker pool | Structured IO; bounded concurrency | Slight complexity; edge compatibility | Chosen primary |
| C | Named FIFO / temp files | Inspectable | Higher latency; complexity | Rejected initial |
| D | Event loop (`zle -F`, TRAPs) | Reactive design | Coupled to interactive ZLE state | Deferred |

Primary: Option B with graceful fallback to A if zpty unavailable.

---

## 7. Data Model

Task Registry Fields:
- id
- priority (critical|normal|cosmetic)
- label (segment base name)
- command (function or shell snippet)
- timeout_ms
- retries
- feature_flag (enables phased rollout)
- cache_key (future enhancement)
- max_concurrency_class (optional)

Runtime State Tracked:
- status (pending|running|done|fail|timeout)
- start_ms / end_ms
- pid / worker
- attempts
- last_error (short code/string)

Derived Metrics:
- `async_dispatch_total`
- `async_total_accumulated` (Σ task durations)
- `sync_path_total` (legacy synchronous cost minus now-deferred tasks)

---

## 8. Rollout Phases

| Phase | Mode | Description | Criteria to Advance |
|-------|------|-------------|---------------------|
| A | Shadow | Run async tasks in parallel; keep full synchronous originals | All async segments suffixed `_start/_done`; no change to prompt timing |
| B | Dual/Compare | Skip performing heavy work synchronously; still simulate timing for baseline | Variance stable; tests show no prompt regression |
| C | Active Minimal | Remove sync duplicates for 1–2 low-risk tasks (theme extras, completion cache) | No gating failures; sync_path reduction observed |
| D | Active Extended | Add medium tasks (gitstatus warm, fzf tools) | Stable variance + regression guard green |
| E | Optimization & Tuning | Adaptive concurrency, overhead checks, apply budgets | Overhead ratio <1.2× removed sync cost |
| F (Future) | Adaptive Async Budgets | Per-task budgeting; dynamic throttling | Budget test suite green |

---

## 9. Manifest Governance

Manifest file (e.g. `docs/redesignv2/async/manifest.json` or a `.zsh` associative map) MUST:
- List every async task (one canonical source).
- Include `version` + `checksum` integration with guidelines policy (added to composite checksum).
- Be validated by a test: runtime registered tasks == manifest tasks (set equality).
- Provide stable fields for test harness to introspect.

Manifest Minimal Schema (conceptual):
{
  "version": 1,
  "tasks": [
    {
      "id": "gitstatus_warm",
      "priority": "normal",
      "label": "gitstatus_init_async",
      "timeout_ms": 1200,
      "feature_flag": "ASYNC_TASK_GITSTATUS",
      "retries": 0
    }
  ]
}

Checksum Integration:
- Include manifest in aggregated guidelines checksum to enforce drift re-acknowledgement (G2).

---

## 10. Instrumentation & Segment Naming

| Event | Segment Pattern |
|-------|-----------------|
| Task start | `async_task_<id>_start` |
| Task success | `async_task_<id>_done` |
| Task failure | `async_task_<id>_fail` |
| Dispatcher init | `async_queue_init` |
| Flush loop | `async_flush_cycle` |
| Shadow aggregate | `async_shadow_total` (optional) |

All segments use existing `SEGMENT name=<...> ms=<delta> phase=post_plugin sample=<mode>` format.

---

## 11. Timeouts, Retries & Safety

Defaults:
- timeout_ms default: 1500 (configurable per task).
- retries: 0 (increase selectively for transient tasks).

On timeout:
1. Emit `_fail` with `reason=timeout`.
2. Mark task status `timeout`.
3. (Optional future) queue fallback minimal sync variant at next prompt.

Watchdog:
- Periodic flush loop (e.g., every 150ms for limited cycles) tracking last progress timestamp.
- On stall > configured threshold (e.g., 3× longest task timeout), record diagnostic and disable async next run (persist sentinel file).

Failure Transparency:
- Tests assert that each started task ends in `done|fail|timeout` (no silent drop).
- Promotion guard may parse counts.

---

## 12. Testing Strategy

| Test Name (Proposed) | Purpose | Phase Introduced |
|----------------------|---------|------------------|
| `test-async-manifest-integrity.zsh` | Manifest == runtime registered tasks | A |
| `test-async-shadow-mode.zsh` | No prompt_ready inflation; required sync segments unchanged | A |
| `test-async-timeouts.zsh` | Force timeout via env & detect `_fail` emission | B |
| `test-async-race-prompt-ready.zsh` | Assert zero async start before prompt_ready | B |
| `test-async-variance-impact.zsh` | Variance not degraded > threshold | B |
| `test-async-budget-partition.zsh` | Ensure budgets consider only sync in sync_path_total | C |
| `test-async-error-propagation.zsh` | Fail path surfaces correct `_fail` segment & status | C |
| `test-async-overhead-ratio.zsh` | Validate Async Overhead ratio < limit | D |
| `test-async-watchdog.zsh` | Simulated stall triggers watchdog disable | E |

Test Controls (ENV Vars):
- `ASYNC_MODE=off|shadow|on`
- `ASYNC_TEST_FAKE_LATENCY_MS=<int>`
- `ASYNC_FORCE_TIMEOUT=<task_id>`
- `ASYNC_MAX_CONCURRENCY=<n>`
- `ASYNC_DEBUG_VERBOSE=1`

---

## 13. Performance Metrics Integration

New Derived:
- `SYNC_REDUCTION_PCT = 100 * (baseline_sync - current_sync)/baseline_sync`
- `ASYNC_OVERHEAD = Σ async task durations - (sync removed)`
Warning Thresholds (initial):
- Overhead > 1.2 × removed sync cost → WARN (not fail until tuning).
Budget Strategy Evolution:
1. Maintain legacy aggregate budgets (Phase 0–2 observe/warn).
2. Introduce `sync_path_total` interim budget after initial async reduction.
3. Add per-task budgets once distributions known (Phase E).

---

## 14. Implementation Artifacts (Planned Deliverables)

| Artifact | Description |
|----------|-------------|
| Dispatcher skeleton (`async-dispatcher.zsh`) | Core register/launch/collect functions |
| Task registration file (`async-tasks.zsh`) | Declarative register calls (mirrors manifest) |
| Manifest (`manifest.json`) | Authoritative task list + metadata |
| Shadow mode tests | Baseline invariants preserving sync path |
| Timeout & race tests | Reliability and gating support |
| Watchdog module | Detect & mitigate stalls |
| Overhead metrics integration | Extend promotion guard perf block |
| Budget partition logic | Distinguish sync vs async budgets |
| JSON aggregator | Exports sync/async breakdown for CI artifact |

---

## 15. Immediate Next Action Checklist (Actionable)

| # | Action | Output / Success |
|---|--------|------------------|
| 1 | Add missing synchronous segment probes (Section 5) | SEGMENT lines appear in capture; updated tests |
| 2 | Create async manifest (empty or minimal) | File + checksum update; integrity test passes |
| 3 | Implement dispatcher skeleton (shadow only) | `ASYNC_MODE=shadow` test green |
| 4 | Register 1–2 low-risk tasks (theme extras, completion cache) | Tasks listed; no sync change |
| 5 | Add tests: manifest integrity + shadow invariants | CI green |
| 6 | Run multi-sample capture & confirm variance stable | Relative stddev logged ≤ prior baseline |
| 7 | Plan & document candidate sync deferrals (list in manifest) | Added to manifest comments |
| 8 | Prepare overhead calculation hooks (not enforced) | Additional fields in perf guard block |
| 9 | Document environment variables (Section 12) | README snippet or reference update |
| 10 | Pre-Phase B go/no-go review | Sign-off note in docs |

---

## 16. Environment Variable Reference (Initial)

| Variable | Effect | Default |
|----------|--------|---------|
| `ASYNC_MODE` | off|shadow|on mode selection | off |
| `ASYNC_MAX_CONCURRENCY` | Upper bound worker concurrency | 4 (planned) |
| `ASYNC_TEST_FAKE_LATENCY_MS` | Inject artificial delay in each task | unset |
| `ASYNC_FORCE_TIMEOUT` | Task id to force into timeout path | unset |
| `ASYNC_DEBUG_VERBOSE` | Emit debug logs to stderr/log file | 0 |
| `ASYNC_DISABLE_WATCHDOG` | Skip watchdog for debugging | 0 |

---

## 17. Fallback Strategy

If async introduces instability:
1. Set `ASYNC_MODE=off` (fail-safe).
2. Keep instrumentation—no loss of historical comparability.
3. Investigate logs: look for missing `_done` or early `_start`.
4. Re-enable phased tasks one by one (binary search approach).

Rollback Tagging:
- Create tag `async-shadow-only-<date>` after Phase A success.
- Allow rapid revert to shadow snapshot if Phase C regression arises.

---

## 18. Future Enhancements (Optional / Later)

| Enhancement | Benefit |
|-------------|---------|
| Adaptive scheduling (duration-weighted priority) | Reduced tail latency for short tasks |
| Persistent cache warm pre-heating | Lower subsequent shell startup cost |
| Task result memoization across sessions | Avoid repeated expensive computations |
| Dynamic budget recalibration (rolling baseline) | Reduces manual threshold maintenance |
| Schema-locked perf-diff + async correlation | Precise root cause isolation in regressions |

---

## 19. Compliance & Governance Hooks

- Manifest included in policy checksum to trigger re-ack (G2).
- Each new async task addition requires:
  1. Manifest update.
  2. Integrity test delta.
  3. Segment coverage confirmation.
  4. Documentation snippet update (this file or manifest commentary).

- Promotion guard extended to:
  - Parse presence of `async_queue_init`.
  - Report counts: tasks_started / tasks_done / tasks_fail / tasks_timeout.
  - Fail (later phase) if any started tasks lack terminal status at capture end.

---

## 20. Example Minimal Dispatcher (Conceptual Pseudocode)

(Real implementation belongs in `tools/` or redesign module; kept brief for clarity.)

FUNCTIONS (outline):
- `async_register_task <id> <priority> <timeout_ms> <label> <command>`
- `async_launch_pool` (Phase A: spawn & mark start segments)
- `async_collect` (poll statuses, emit `_done` or `_fail`)
- `async_flush_loop_once` (one pass; repeat or schedule)
- `async_finalize` (emit aggregate metrics)

Constraints:
- Phase A intentionally simplistic (one subshell per task) to derisk complexity before introducing pooling or zpty multiplexing.

---

## 21. Manifest Authoring Guidelines

Rules:
1. Stable ordering (alphabetical by `id`) to avoid checksum churn.
2. Comment lines allowed (if `.zsh` form) but excluded from checksum via pre-processing OR retained consistently.
3. Each task must have one-line rationale comment.

Quality Checks:
- No duplicate `id`.
- `timeout_ms` ≤ global hard cap (e.g., 5000).
- `priority` value enumerated in allowed set.

---

## 22. Metrics & Reporting Additions (Perf Guard)

Add JSON (or key=value lines) in PERF_GUARD block:
- `async_tasks_total=<n>`
- `async_tasks_done=<n>`
- `async_tasks_fail=<n>`
- `async_tasks_timeout=<n>`
- `async_overhead_ms=<ms>`
- `sync_path_total_ms=<ms>`
- `sync_reduction_pct=<pct>`

Observe Mode: purely informational.  
Warn Mode: highlight large overhead ratio.  
Gate Mode: enforce overhead ratio and missing terminal states.

---

## 23. Acceptance Criteria for Phase Transitions

| Transition | Criteria |
|------------|----------|
| A → B | Shadow tasks stable (≥3 CI runs), variance unchanged, no early starts |
| B → C | Selected tasks show measurable sync_path reduction, no regressions in required segments |
| C → D | >20% sync reduction from original baseline OR clear incremental path documented |
| D → E | Overhead ratio ≤1.2, all tasks have per-task durations captured |
| E → Budgets | Interim sync budget (≤ target) met across 3 consecutive runs |

---

## 24. Open Questions (To Resolve Before Phase C)

| Question | Resolution Path |
|----------|-----------------|
| zpty support detection robust? | Add capability probe test; fallback gracefully |
| Minimum safe concurrency? | Empirically measure with 1–4; choose stable default |
| Are any tasks IO bound & benefit from concurrency cap exceptions? | Log task durations & classify |
| Need per-task retry? | Only if transient network (currently none) |

---

## 25. Execution Roadmap (Timeline Sketch)

| Week | Focus | Milestone |
|------|-------|-----------|
| W1 | Segment expansion + shadow infra | Phase A complete |
| W2 | Dual compare & variance stabilization | Phase B sign-off |
| W3 | Minimal active tasks + first sync reduction | Phase C |
| W4 | Extended tasks + overhead metrics | Phase D |
| W5 | Optimization & tuning + watchdog | Phase E |
| W6 | Introduce sync budget & prepare gating | Budget pre-enforcement |

(Timeline flexible; progression gated by variance + stability not calendar.)

---

## 26. How to Contribute (Async Changes)

1. Add/modify task in manifest (alphabetical).
2. Update dispatcher registration.
3. Add/extend test if new behavior introduced.
4. Run full performance + async test subset.
5. Include perf comparison snippet in PR description.
6. Reference this file’s section if altering policy (update risk section if needed).

---

## 27. Reference Glossary (Async Specific)

| Term | Definition |
|------|------------|
| Shadow Mode | Async executes in background but results ignored; sync baseline preserved |
| Dual / Compare | Sync heavy work skipped; async results collected but validated vs simulated baseline |
| Overhead | Sum async task durations vs the synchronous cost removed |
| Watchdog | Safety thread/process verifying progress of async lifecycle |
| Manifest | Declarative authoritative list of all async tasks and metadata |
| Sync Path Total | Residual synchronous initialization cost after deferrals |
| Segment | Timing emission line used for attribution & gating |

---

## 28. Change Log (This File)

| Date | Change | Notes |
|------|--------|-------|
| 2025-09-02 | Initial creation (risk + async plan) | Derived from implementation guide Section 14/15 expansion |

---

## 29. Summary

This plan operationalizes async introduction with measurable guardrails:
- Clear phases
- Manifest governance
- Comprehensive risk coverage
- Deterministic testing & variance controls
- Integration with existing performance tooling and gates

Next actionable step: Execute Checklist Item #1 (segment probes) and bootstrap shadow dispatcher + manifest.

---

End of document.