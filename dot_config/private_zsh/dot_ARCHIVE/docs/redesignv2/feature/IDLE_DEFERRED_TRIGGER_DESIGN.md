# Idle / Background Deferred Trigger Design (S4-27 Draft)

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316  

Status: DRAFT (Part 08.19 – Instrumentation stable; dispatcher skeleton active)  
Owner: S4-27  
Applies To: Stage 4 – Sprint 2 (Instrumentation & Telemetry Expansion)  
Target Outcome: Safe, strictly-governed execution channel for post‑prompt, non‑critical tasks without inflating Time To First Prompt (TTFP) or violating deferral guardrails.  

---

## 1. Purpose

Provide a deterministic, observable mechanism to run low-priority or latency‑tolerant operations *after* the first prompt is available and the user can interact.  
Examples (future candidates):
- Warm caches (e.g. completion cache refresh if stale)
- Background integrity hashing expansions
- Lightweight environment indexing (git status pre‑warming, lazy toolchain probing)
- Housekeeping (log rotation, stale artifact cleanup)

The trigger must:
1. Never block prompt rendering.
2. Provide bounded execution windows.
3. Expose observability hooks (segment / structured telemetry surfaces).
4. Support explicit opt-in gating (telemetry + task enable flags).
5. Fail safely (partial completion must not degrade interactive shell).

---

## 2. Scope

IN-SCOPE:
- Single “idle/deferred” phase orchestration immediately after initial deferred dispatcher batch (current one-shot).
- Simple scheduling queue (ordered FIFO) with optional grouping.
- State machine + instrumentation lines (`DEFERRED_IDLE:*` / structured JSON).
- Time budget & overruns logging.
- Guard & opt-out flags.

OUT-OF-SCOPE (for this sprint):
- Multi-priority scheduler (low / medium / high lanes).
- Parallel task concurrency pool.
- Long-running daemon orchestration.
- Adaptive re-scheduling heuristics (retry with exponential backoff).
- Cross-session persistence of unfinished background job progress.

---

## 3. Terminology

| Term | Definition |
|------|------------|
| Idle Trigger | Mechanism that fires after first prompt + initial deferred batch completion. |
| Background Task | Unit of deferred work registered for the idle trigger. |
| Dispatcher Skeleton | Existing one-shot postprompt executor (current implementation). |
| Idle Window | Time slice during which background tasks may run before yielding again (future extension). |
| Hard Budget | Maximum cumulative ms allowed for the idle batch before logging WARN. |

---

## 4. Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| Non-intrusive | Never delays first prompt | No increase in `prompt_ready_ms` vs control |
| Bounded | Enforce hard execution ceiling | Overrun emits WARN line & structured telemetry |
| Observable | Machine-parseable events | Segment `deferred_total` + new idle markers |
| Deterministic Order | FIFO by registration | Tests assert emission order |
| Safe Failure | A failing task does not abort subsequent tasks | Remaining tasks still execute; error counted |
| Low Overhead Idle Path | Zero cost when no tasks registered | No added ms vs baseline (Δ ≤ 0.5ms) |

---

## 5. Non-Goals

| Non-Goal | Rationale |
|----------|-----------|
| Dynamic priority reshuffling | Complexity not justified initially |
| Multi-shell coordination | Out of scope for local redesign goals |
| Cross-shell task deduplication | Would require IPC / lock strategy |
| Continuous idle monitoring loop | Increases complexity & idle CPU usage |

---

## 6. State Machine (Proposed)

```
IDLE_INIT
  ↓ (trigger after initial deferred dispatcher completes + prompt displayed)
IDLE_READY
  ↓ (tasks registered? yes)
IDLE_RUNNING
  ↙            ↘
IDLE_COMPLETE   IDLE_ERROR (if any task fatal) → IDLE_COMPLETE
```

- `IDLE_ERROR` is a *transient* internal label to increment error counters; external observers only see final COMPLETE summary.
- No re-entry: idle path is single-pass per shell startup (initial MVP).

---

## 7. Event / Trigger Conditions

| Sequence | Condition |
|----------|-----------|
| 1 | Prompt rendered & initial deferred dispatcher finished writing `DEFERRED ...` lines |
| 2 | Dispatcher sets `_IDLE_DEFER_TRIGGER_READY=1` |
| 3 | If `_IDLE_TASK_QUEUE_COUNT > 0` execute FIFO; else emit no-op marker |
| 4 | Emit summary line & structured JSON if telemetry enabled |

Guard:
```
[[ -n ${_IDLE_DEFERRED_DONE:-} ]] && return   # idempotency
```

---

## 8. Registration API (Draft)

```zsh
# Register an idle/background task
# Usage: zf::idle::register <id> <func_name> <description...>
# Contract:
#   - <id>: kebab-case unique key
#   - <func_name>: already defined function (no lazy indirection in MVP)
#   - Description: free text (telemetry note, truncated if >128 chars)
#
# Returns: 0 success, non-zero invalid input or duplicate id
```

Internal Data Structures:
- `_IDLE_TASK_IDS`: ordered array of ids
- `_IDLE_TASK_META[<id>]=<func_name>:<desc>`
- `_IDLE_TASK_RESULTS[<id>]=rc:<ms>` (after execution)

---

## 9. Execution Algorithm (Pseudo)

```
start_time = now()
errors=0
for id in _IDLE_TASK_IDS:
  t0=now()
  call task func
  rc=$?
  dt=elapsed_ms(t0)
  record _IDLE_TASK_RESULTS[id]="rc=${rc}:ms=${dt}"
  if rc!=0; errors+=1
  if (elapsed_ms(start_time) > $IDLE_HARD_BUDGET_MS ); break (log budget_exceeded)
Emit summary line
Set _IDLE_DEFERRED_DONE=1
```

---

## 10. Configuration Flags

| Variable | Default | Purpose |
|----------|---------|---------|
| `ZSH_IDLE_ENABLE` | 1 | Master switch (set 0 to bypass entire idle system) |
| `ZSH_IDLE_HARD_BUDGET_MS` | 75 | Hard ceiling for cumulative idle tasks (WARN when exceeded) |
| `ZSH_IDLE_TASK_TIMEOUT_MS` | 50 | Per-task soft timeout (log only; no kill in MVP) |
| `ZSH_IDLE_LOG_VERBOSE` | 0 | Emit per-task verbose lines |
| `ZSH_FEATURE_TELEMETRY` (future) | 0 | Enables timing arrays export (ties into S4-18) |

---

## 11. Telemetry & Instrumentation

Plaintext Markers (stdout or log):
```
IDLE:START budget=75ms tasks=<N>
IDLE:TASK id=<id> ms=<int> rc=<rc> [timeout=1]?
IDLE:SUMMARY tasks=<N> ok=<N-ok> err=<errors> elapsed=<ms> budget_exceeded=<0|1>
```

Structured JSON (when `ZSH_LOG_STRUCTURED=1`):
```
{"type":"idle_start","ts":<epoch_ms>,"budget_ms":75,"tasks":N}
{"type":"idle_task","id":"<id>","ms":<int>,"rc":0,"timeout":false}
{"type":"idle_summary","tasks":N,"errors":0,"elapsed_ms":42,"budget_exceeded":false}
```

Segment Aggregation:
- Option: add `idle_total` segment (NOT budgeted by classifier initially).
- Decision: Defer classifier inclusion until stability proven (documented in REFERENCE policy §5.3.x when added).

---

## 12. Privacy Considerations

Data fields intentionally minimal:
- No environment values
- No file paths
- Task descriptions truncated
- IDs standardized (kebab-case)
Any extension requires: update REFERENCE §5.3.2 + Privacy Appendix allowlist + schema test.

---

## 13. Failure Modes & Handling

| Scenario | Detection | Action |
|----------|-----------|--------|
| Duplicate Task ID | Registration returns non-zero | Caller decides whether to rename |
| Task Function Missing | `whence -w` check | Registration rejects |
| Task Runtime Exception (non-zero rc) | rc != 0 | Increment error counter; continue |
| Budget Exceeded | elapsed > HARD_BUDGET | Set flag, stop executing further tasks |
| Timeout (soft) | dt > TASK_TIMEOUT_MS | Mark `timeout=1`; continue |
| Telemetry Disabled | Flag off | Emit no JSON (plain markers optional) |

---

## 14. Guardrails

| Guardrail | Enforcement |
|-----------|-------------|
| Zero overhead if disabled & no tasks | Early return before any date/time calls |
| Deterministic ordering | Single append-only array, no sorting |
| Idempotent run | `_IDLE_DEFERRED_DONE` sentinel |
| No prompt regression | Classifier + per-run diff ensures unchanged prompt_ready_ms |
| Bounded cost | HARD_BUDGET with early break |
| Observability | Mandatory SUMMARY line |

---

## 15. Test Plan (Initial Scaffold)

| Test ID | Focus | Strategy | Status |
|---------|-------|----------|--------|
| T-IDLE-01 | Registration success | Register N tasks; assert ordered array | Pending |
| T-IDLE-02 | Duplicate detection | Register same id twice; expect non-zero | Pending |
| T-IDLE-03 | Execution order | Inject tasks capturing ordinal | Pending |
| T-IDLE-04 | Error isolation | One task returns 1; others still run | Pending |
| T-IDLE-05 | Budget enforcement | Set low budget; ensure early stop | Pending |
| T-IDLE-06 | Timeout marker | Artificial sleep > timeout threshold | Pending |
| T-IDLE-07 | Idempotent sentinel | Invoke trigger twice; second emits nothing | Pending |
| T-IDLE-08 | Telemetry JSON (opt-in) | Enable flags; parse JSON lines schema | Pending |
| T-IDLE-09 | Disabled pathway overhead | Benchmark diff vs baseline (<0.5ms) | Pending |
| T-IDLE-10 | Summary accuracy | Cross-check counts vs tasks executed | Pending |

Test Harness Notes:
- Use `zmodload zsh/datetime` for precise monotonic timing.
- Simulate tasks with controlled `sleep 0.01` to test ordering & timeout logic.

---

## 16. Implementation Outline (Phased)

| Phase | Deliverable |
|-------|-------------|
| P1 | Core data structures + `zf::idle::register` |
| P2 | Trigger integration after existing deferred dispatcher |
| P3 | Execution loop + plaintext markers |
| P4 | Budget + timeout logic |
| P5 | Structured telemetry emission |
| P6 | Test suite (unit + integration) |
| P7 | Documentation (REFERENCE + IMPLEMENTATION updates) |
| P8 | Optional: add `idle_total` segment (deferred) |

---

## 17. API Surface (MVP)

```zsh
zf::idle::register <id> <func> <description...>   # returns 0/1
zf::idle::run_if_ready                            # internal (invoked once)
```

Future (Not MVP):
```zsh
zf::idle::stats        # prints summary (debug)
zf::idle::list         # lists registered tasks
```

---

## 18. Open Questions

| # | Question | Proposed Disposition |
|---|----------|----------------------|
| 1 | Include idle_total in classifier early? | Defer until variance impact measured |
| 2 | Per-task concurrency (background & join)? | Not in MVP; adds complexity |
| 3 | Persist failure counts to artifacts? | Possibly via structured telemetry summary only |
| 4 | Soft vs hard kill of long tasks? | MVP logs only; revisit if abuse observed |

---

## 19. Rollout Plan

1. Land registration + trigger (no tasks) – prove zero overhead path.
2. Add synthetic test task set (internal) for performance soak.
3. Integrate first real low-risk task (e.g. cache directory scan).
4. Monitor classifier (ensure no prompt_ready variance shift).
5. Add structured telemetry gating path.
6. Document REFERENCE additions (policy for adding idle tasks).
7. Re-evaluate adding `idle_total` segment after 3 stable runs.

---

## 20. Change Log

| Date | Version | Change |
|------|---------|--------|
| 2025-09-10 | 0.1 | Initial skeleton design (draft) |

---

## 21. Next Steps (Actionable)

- Implement P1/P2 code (data structures + trigger call site).
- Add unit tests for registration & ordering.
- Integrate budget enforcement logic.
- Extend PERFORMANCE_LOG with governance note once first real task added.

---

*End of Document (S4-27 Draft)*
