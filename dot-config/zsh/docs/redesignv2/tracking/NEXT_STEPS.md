# Next Steps Action Plan - ZSH Redesign (Stage 4 Sprint 2) – Updated (Part 08.19.10)

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

**Generated:** 2025-09-10 (Part 08.19 – instrumentation status refresh: real segment probes complete, multi-metric classifier integrated, streak tracking added)  
**Current Position:** Stage 4 – Sprint 2 (Instrumentation & Telemetry Expansion – classifier in observe mode; governance/enforce pending 3× OK streak)  
**Sprint:** Stage 4 – Sprint 2 (Segment Probes ✅, Logging Homogeneity ✅, Multi‑Metric Classifier (observe), Dependency Export ✅, Privacy Appendix ✅)  
**Performance Baseline:** 334ms cold start, 1.9% variance (RSD)

### Sprint 2 Status Recap (Part 08.19)
- Logging homogeneity complete: legacy underscore wrappers removed; gate test green (no `ZF_LOG_LEGACY_USED`)
- Real segment probes active (anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total` + granular feature/dev-env/history/security/ui segments)
- Deferred dispatcher skeleton operational (one-shot postprompt; stable `DEFERRED id=<id> ms=<int> rc=<rc>` telemetry lines)
- Structured telemetry flags available & inert when unset: `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON` (zero overhead disabled path)
- Multi-metric performance classifier in observe mode (Warn 10% / Fail 25%); enforce flip (S4-33) pending 3× consecutive OK streak
- Dependency export (`zf::deps::export`) JSON + DOT + basic validation tests integrated
- Privacy appendix published & referenced (redaction whitelist stabilized)
- Baseline performance unchanged (334ms cold start, RSD 1.9%) after new instrumentation
- Immediate focus: S4-27 idle/background trigger design, S4-18 telemetry opt-in (`ZSH_FEATURE_TELEMETRY`), S4-29 homogeneity documentation finalization, S4-30 classifier legend + PERFORMANCE_LOG governance template, S4-33 enforce-mode activation procedure

---

## 1. Sprint 2 Objectives

Deliver instrumentation & governance upgrades without degrading baseline:

1. Real segment probes (phase attribution & ms capture)
2. Logging homogeneity gate + removal of underscore wrappers
3. Structured telemetry stubs (JSON sidecar / opt-in flags)
4. Performance regression harness + WARN/FAIL classifier
5. Dependency export command + DOT generator
6. Idle/background deferred trigger design (spec + stubs)
7. Privacy appendix & redaction hook scaffolding
8. Update Performance Log with classifier legend & first deferred row

Exit Criteria (Sprint 2 completes when all true):
- SEGMENT lines reflect real phases (no placeholders remain)
- Homogeneity test green; legacy wrappers removed; `ZF_LOG_LEGACY_USED` absent
- `ZSH_LOG_STRUCTURED=1` produces valid redacted JSON entries (disabled → zero output)
- Perf classifier reports OK (≤10% delta) vs baseline; FAIL path tested (>25% simulated)
- `zf::deps::export --dot` validated by test harness
- Privacy appendix published & referenced in REFERENCE.md

---

## 2. Completed (Sprint 1 So Far)
Note: S4-12 (Invocation wrapper with timing & containment) and S4-13 (Per-feature timing extraction + perf gating test) completed; reflected in task tracker.

| ID | Artifact | Status | Notes |
|----|----------|--------|-------|
| S4-01 | Stage 4 Kickoff Doc | ✅ | Scope & principles anchored |
| S4-02 | Registry Scaffold | ✅ | Cycle detection + ordering |
| S4-03 | Feature Template | ✅ | Full contract + guidance |
| S4-04 | Status Command | ✅ | Table / raw / JSON / summary |
| S4-05 | Noop Feature | ✅ | Init + teardown + self-check |
| S4-06 | Enable/Disable Tests | ✅ | Precedence validated |
| S4-07 | Failure Containment Test | ✅ | Boundary simulation passes |
| S4-08 | Feature Catalog | ✅ | Inventory + phases + dependencies |
| S4-09 | Developer Guide | ✅ | Authoring + lifecycle rules |
| S4-10 | Performance Log Scaffold | ✅ | Baseline + delta schema |
| S4-11 | Implementation Update | ✅ | Feature Layer section inserted |

---

## 3. Sprint 2 Work Items (Progress Updated)

| ID | Task | Goal | Owner | Status |
|----|------|------|-------|--------|
| S4-20 | Real segment probes | Accurate phase attribution + ms | s-a-c | In Progress (core anchors emitted: pre_plugin_start, post_plugin_total, prompt_ready, deferred_total) |
| S4-21 | Logging homogeneity test | Gate before wrapper removal | s-a-c | Done |
| S4-22 | Remove legacy log wrappers | Namespace purity | s-a-c | Done (underscore wrappers removed; ZF_LOG_LEGACY_USED retired) |
| S4-23 | Structured telemetry flag stubs | Inert opt-in (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) | s-a-c | Done (JSON sidecar emitting segments & deferred) |
| S4-24 | Perf regression harness & classifier | Warn >10%, Fail >25% (observe mode init) | s-a-c | In Progress (core prompt_ready metric implemented) |
| S4-25 | Dependency export command | `zf::deps::export` JSON + DOT | s-a-c | Done (tool + basic tests) |
| S4-26 | DOT generator & tests | Stable Graphviz output | s-a-c | Done (integrated in deps-export) |
| S4-27 | Idle/background trigger design | Spec + initial stub (97-idle-trigger.zsh) + design doc | s-a-c | In Progress (draft: feature/IDLE_DEFERRED_TRIGGER_DESIGN.md) |
| S4-28 | Privacy appendix & redaction hooks | Data category whitelist | s-a-c | Done (privacy/PRIVACY_APPENDIX.md published) |
| S4-29 | Homogeneity gate doc updates | Reflect removal & enforcement | s-a-c | Pending |
| S4-30 | Performance Log classifier legend | Document thresholds & statuses | s-a-c | Pending |
| S4-18 | Telemetry opt-in flag stub (`ZSH_FEATURE_TELEMETRY=1`) | Controlled activation switch + timing arrays scaffold | s-a-c | In Progress (scaffold in IMPLEMENTATION.md Telemetry Opt-In section) |
| S4-19 | Catalog status refresh pass | Ensure no drift after wrapper landing | s-a-c | Pending |

---

## 4. Immediate Execution Order (Sprint 2)

1. Complete remaining real segment probes (S4-20) – expand beyond core anchors to feature/module granularity  
2. Finalize perf regression harness multi-segment support (extend beyond prompt_ready) (S4-24)  
3. Add classifier legend + deferred row to Performance Log (S4-30)  
4. Wire dependency export into CI artifact publishing (post-success) (S4-25/26 follow-up)  
5. Idle/background trigger design & stubs (S4-27) – underway (stub + design doc); implement runner integration & tests next  
6. Homogeneity documentation updates (S4-29)  
7. Add telemetry sanitation & schema drift tests (follow-on to privacy appendix)  
8. Final hardening pass (remove deprecated placeholder segment labels)  

---

## 5. Guardrails (Active During Sprint 2)

| Guardrail | Threshold | Action |
|-----------|-----------|--------|
| Aggregate Startup Delta | +10% warn / +25% fail | Classifier WARN / FAIL (observe first) |
| Segment Probe Overhead | <3ms cumulative added | Investigate if exceeded |
| Structured Telemetry Overhead (disabled) | 0ms | Must remain zero when flags off |
| Structured Telemetry Overhead (enabled) | <5ms | Warn if exceeded |
| Per-Phase Attribution Gaps | 0 missing required phases | Test failure |
| Logging Namespace Purity | 0 legacy underscore calls | Test failure |
| Deferred Dispatcher Runs | Exactly 1 | Test asserts single DEFERRED dummy |
| Privacy Data Scope | Only whitelisted fields | Test failure on extraneous keys |

---

## 6. Performance Workflow (During Timing Integration)

```bash
# After adding wrapper & timing
ZDOTDIR=dot-config/zsh zsh -f -c 'source feature/registry/feature-registry.zsh; feature_registry_resolve_order'

# Capture N=5 cold starts (existing harness)
./tools/perf-capture-multi.zsh -n 5 --output tmp/feat-timing.json

# (Planned) Extract per-feature sync timings (future script)
./tools/perf-extract-feature-sync.zsh tmp/feat-timing.json
```

Add row to PERFORMANCE_LOG for any measurable (>1ms) synchronous addition.

---

## 7. Telemetry (Planned Stub Details)

Environment flag: `ZSH_FEATURE_TELEMETRY=1`  
Behavior (future):
- Enables timing collection wrapper (already safe if flag absent)
- Populates `ZSH_FEATURE_TIMINGS_SYNC[name]=<ms>`
- Optional JSON export (Sprint 2)

Default: OFF to avoid skewing baseline until stable.

---

## 8. Deferred Hook Skeleton (Design Snapshot)

Planned function calls (post wrapper landing):
```
feature_registry_invoke_phase preload
feature_registry_invoke_phase init
# prompt rendered ...
feature_registry_invoke_phase postprompt   # asynchronous / deferred
```
Test anchor: ensure first prompt timestamp precedes any postprompt heavy work.

---

## 9. Risk & Mitigation (Sprint 1 Focus)

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Early timing inaccuracies | Misleading perf gating | Validate with manual `time` sampling before enabling |
| Wrapper regressions | Feature init breakage | Start with noop only; expand gradually |
| Unbounded growth in registry complexity | Harder to trace load order | Keep registry pure mapping, move logic to wrapper |
| Telemetry overhead | Polluted baseline | Default OFF; micro-measure overhead before enabling |

---

## 10. Daily Execution Checklist

| Item | Command |
|------|---------|
| Full tests | `./tests/run-all-tests-v2.zsh` |
| Feature tests only | `grep -l 'feature/' tests/feature/**/*.zsh | xargs zsh -f` (improve later) |
| Perf smoke | `./tools/perf-capture-multi.zsh -n 3 --quiet` |
| Feature status | `zsh-features status --table --summary` |
| Catalog drift check | Visually diff Catalog vs registry list |

---

## 11. Sprint 2 (Preview – Not Yet Active)

Planned focus:
- Add first “real” features (prompt-core, safety-boundaries, history-adv)
- Introduce per-feature gating criteria (fail if > budget)
- Implement deferred examples (fzf-integration placeholder)
- Telemetry export + JSON artifact

Not executed until Sprint 1 exit criteria met.

---

## 12. Communication Cadence

| Day | Focus |
|-----|-------|
| Mon | Wrapper status + timing validation |
| Wed | Perf delta review + risk scan |
| Fri | Catalog sync + readiness for Sprint 2 gate |

Weekly summary appended to PERFORMANCE_LOG if any deltas recorded.

---

## 13. Commands Quick Reference

```bash
# Run feature registry contract tests only
grep -l 'feature-registry-contract' tests/feature/registry/*.zsh | xargs -n1 zsh -f

# Force telemetry (future)
ZSH_FEATURE_TELEMETRY=1 ./tools/perf-capture-multi.zsh -n 5

# Show status (after sourcing feature-status.zsh in interactive shell)
zsh-features status --summary --json
```

---

## 14. Immediate Actions (Next Commit Targets)

1. Implement invocation wrapper (S4-12)
2. Add timing accumulation array

### GOAL Rollout Plan (New)

#### Follow-ups (08.19.10)
- Add CI assertion to fail when the summary-goal badge resolves to red (indicates failing governance/drift/structure).
- Add tests validating summary-goal suffix composition (drift:<message>, struct:<message>) and severity blending.
- Extend documentation: badge legend and suffix mapping details (how governance/ci/streak/explore, drift, and structure affect color/message).
- Monitor first gh-pages publish to confirm endpoint availability; ensure README auto-update commit occurred.
- Optional: refine governance state mapping for “BASELINE_CREATED” → informational (distinct from clean).

Phased integration of classifier GOAL profiles (`Streak`, `Governance`, `Explore`, `CI`) to control strictness, synthetic fallback, missing metric policy, baseline creation, and status JSON augmentation.

| Phase | Task ID(s) | Objective | Deliverable | Exit Criteria |
|-------|-----------|-----------|-------------|---------------|
| 1 | S4-34 | Documentation | README / IMPLEMENTATION / REFERENCE / Privacy updated, ADR-0007 accepted | All docs merged; version bumps applied |
| 2 | S4-35 | Scaffold | `apply_goal_profile` + `--goal` parsing (no behavior change) | Classifier prints `goal` field only |
| 3 | S4-36 | JSON augmentation (minimal) | Add `goal` to status JSON | Backward compatibility preserved (other flags absent) |
| 4 | S4-37, S4-38 | Enforcement logic | Synthetic gating + missing metric handling (`partial`) | Governance run fails on synthetic/missing; Streak tolerates |
| 5 | (cont.) | Strictness layering | Phased `-e` (Streak) vs full strict (Governance/CI) | No premature exits in Streak; Governance hard-fails on violations |
| 6 | (cont.) | Flag emission | Conditional fields: `synthetic_used`, `partial`, `ephemeral` | Flags appear only when true; privacy appendix aligned |
| 7 | S4-39 | Test matrix | Implement T-GOAL-01..06 | All tests green locally & CI |
| 8 | S4-40 | CI adoption | Update workflows to set `GOAL=ci` | Stable green runs (≥3 days) |
| 9 | S4-41 | Governance activation (A8) | 3 clean governance runs (`GOAL=Governance`) | Enforce-mode PR readiness (A1–A8 satisfied) |

Test IDs (summary):
- T-GOAL-01: Explore sets `ephemeral=true` & exit 0 with missing metric
- T-GOAL-02: Streak tolerates missing metric (`partial=true`)
- T-GOAL-03: Governance fails on synthetic segment usage
- T-GOAL-04: CI mirrors Governance strictness
- T-GOAL-05: Unset GOAL behaves as Streak
- T-GOAL-06: No extraneous flags when conditions absent

Governance Precondition Update:
- A8 (new): Three consecutive `GOAL=Governance` runs with neither `synthetic_used` nor `partial` present.

Operational Guidance:
- Use `GOAL=Streak` while stabilizing instrumentation or building streak.
- Switch to `GOAL=Governance` only for validation runs intended to count toward A8.
- Use `GOAL=explore` for diagnostic iteration that should not pollute governance evidence (ephemeral marked).
- CI workflows MUST use `GOAL=ci` for deterministic gating.

Risk Mitigations:
- Misuse in CI (Explore/Streak) → add future goal-state badge & workflow assertion.
- Hidden synthetic reliance → governance profile blocks activation (synthetic implies immediate fail).
- Partial metric normalization → explicit `partial` flag prevents silent masking.

Rollback Plan:
- If early strictness causes instability, temporarily revert to Phase 3 (goal field only) while retaining documentation; record rollback rationale in PERFORMANCE_LOG (Type=governance, Scope=goal-profile).
3. Update performance harness to read timing data
4. Add noop timing assertion test (<1ms)
5. Write PERFORMANCE_LOG row template for first timing capture

---

## 15. Maintenance Notes

- Update compliance headers if guidelines checksum changes (current: 3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316)
- Never introduce new feature without Catalog row & tests
- Append (do not edit) historical performance log rows
- Keep NEXT_STEPS tightly scoped to current sprint (avoid backlog noise)

---

**Next Planned Update:** Upon completion of S4-12 through S4-14  
**Sprint 1 Target Completion:** Before enabling additional Phase 1 features  
**Stage 4 Overall Target:** Maintain ≤ +10% aggregate regression while onboarding initial feature set

---

## 16. Performance Classifier Enforce‑Mode Activation Procedure

Purpose: Formalize the governance steps to flip the multi‑metric performance classifier (prompt_ready_ms, pre_plugin_total_ms, post_plugin_total_ms, deferred_total_ms) from observe to enforce mode without risking false positives.

### 16.1 Preconditions (All Required)

| Condition | Description | Verification |
|-----------|-------------|--------------|
| Baselines present | All four baseline JSON files exist in artifacts/metrics | `ENFORCE_BASELINES=1 zsh tests/performance/telemetry/test-classifier-baselines.zsh` |
| Schema stable | Structured telemetry schema test passes (no unknown keys) | `zsh tests/performance/telemetry/test-structured-telemetry-schema.zsh` |
| Consecutive OK streak | 3 consecutive CI runs (ci-performance) overall_status=OK (not WARN/FAIL) | Inspect recent workflow run artifacts (`artifacts/perf-results.json`) |
| No pending segment changes | No unresolved additions/removals to canonical segment table | REFERENCE.md §5.3 + open PR audit |
| Variance stable | RSD ≤5% for prompt_ready_ms across recent runs | Check `perf-results.json` per run |
| Docs synchronized | README segment block matches REFERENCE §5.3 | `tools/sync-readme-segments.zsh --check` exits 0 |

### 16.2 Activation Steps

1. Confirm Preconditions: Run the verification commands locally or inspect CI artifacts.  
2. Manual (Optional) Dry Run: Dispatch `ci-performance` workflow with `mode=observe` and `runs=5` to reconfirm stable OK.  
3. Enforce Flip (Automatic): Merge a change (if needed) that ensures main branch scheduled/dispatch uses `mode=enforce` (current workflow auto-selects enforce on main).  
4. Governance Log Entry: Append PERFORMANCE_LOG row (Type=governance) documenting activation (see template below).  
5. Tracker Update: Mark TASK_TRACKER S4-33 as ✅ Done.  
6. Announce / Document: Add note in NEXT_STEPS (remove this activation block or mark “Activated”) on subsequent update.  
7. Monitoring Window: For first 3 enforce-mode runs, watch for WARN transitions; if a false WARN (environmental), open investigation row before reverting.

### 16.3 PERFORMANCE_LOG Row Template (Do Not Add Until Activation)

| Date | Type | Scope | Δ Synchronous | Δ Deferred | New Total | RSD | Baseline Ref | Status | Notes |
|------|------|-------|---------------|------------|-----------|-----|--------------|--------|-------|
| YYYY-MM-DD | governance | performance-classifier | 0 | — | <mean_ms> | <RSD%> | baseline-stage3-2025-09-10 | pass | Enforce mode activated after 3× OK streak (all metrics ≤10% delta) |

Recording Guidelines:
- Use the mean_ms and RSD from the activation run’s `perf-results.json` prompt_ready metric.
- If any metric is near WARN threshold (>9% delta) delay activation and re-collect baselines.

### 16.4 Rollback Procedure

| Trigger | Action | Follow-up |
|---------|--------|-----------|
| Spurious WARN due to transient host noise | Temporarily re-dispatch workflow with mode=observe (manual input) | Investigate variance (increase runs to N=10) |
| Unexpected FAIL (single metric >25%) but manual retest OK | Revert enforce for 1 cycle (observe) & re-issue run; do NOT delete baselines | Add investigation row to PERFORMANCE_LOG |
| Legitimate regression (confirmed) | Keep enforce; treat FAIL as gating; open regression ticket | Mitigation + new row (regression / mitigation) |

### 16.5 Future Hardening

| Enhancement | Benefit | Status |
|-------------|---------|--------|
| Automatic streak counter badge | Visual confirmation of enforce eligibility | Planned |
| Multi-metric percentile (P95) capture | Tail latency insight | Future |
| Drift trend slope detector | Early anomaly detection | Future |
| Auto README sync check in CI | Prevent stale canonical table | Planned (`--check` integration) |

### 16.6 Command Reference

```bash
# Verify baselines (enforce mode expectation)
ENFORCE_BASELINES=1 zsh tests/performance/telemetry/test-classifier-baselines.zsh

# Verify schema
zsh tests/performance/telemetry/test-structured-telemetry-schema.zsh

# Dry-run classifier (observe mode)
MODE=observe RUNS=5 gh workflow run "CI Performance"

# Force README sync (dry run)
DRY_RUN=1 zsh tools/sync-readme-segments.zsh
```

### 16.7 Activation Checklist (Copy Into PR Description)

- [ ] Baseline integrity test (ENFORCE_BASELINES=1) passed
- [ ] Schema validation test passed
- [ ] 3× consecutive OK streak verified (list dates / run IDs)
- [ ] README sync check passed
- [ ] PERFORMANCE_LOG entry prepared (will append after merge)
- [ ] TASK_TRACKER S4-33 status ready to flip
- [ ] No pending segment definition changes

---

End of document.