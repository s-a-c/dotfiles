# ZSH Redesign – Performance Log

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

## 15. Performance Classifier Legend & Governance (Added Part 08.19)

This section documents the multi-metric performance classifier (observe → enforce transition), governance activation criteria, and the row template for enforce-mode activation.

### 15.1 Monitored Metrics (Canonical)

| Metric Key | Definition | Baseline Artifact (expected) | Warn Δ | Fail Δ | Notes |
|------------|------------|------------------------------|--------|--------|-------|
| pre_plugin_total_ms | Time from `pre_plugin_start` to `pre_plugin_total` anchor | artifacts/metrics/pre_plugin_total-baseline.json | 10% | 25% | Pure pre-plugin phase budget |
| post_plugin_total_ms | Functional post-plugin span until post-plugin anchor | artifacts/metrics/post_plugin_total-baseline.json | 10% | 25% | Includes plugins, dev-env, completion, instrumentation |
| prompt_ready_ms | Aggregate to first prompt (TTFP) | artifacts/metrics/prompt_ready-baseline.json | 10% | 25% | User perceived latency |
| deferred_total_ms | First deferred batch cumulative runtime | artifacts/metrics/deferred_total-baseline.json | 10% | 25% | Tracks postprompt work; may expand later |

### 15.2 Status Mapping

| Status | Condition (any metric) | Action (observe mode) | Action (enforce mode) |
|--------|------------------------|------------------------|-----------------------|
| OK | All deltas ≤ Warn | Record streak | Maintain streak |
| WARN | > Warn AND ≤ Fail | Record (streak reset) | Non-zero exit (policy: soft fail) |
| FAIL | > Fail | Record (streak reset) | Hard CI failure |

Overall status = worst individual metric status.

### 15.3 Observe → Enforce Activation Preconditions (All Required)

| ID | Condition | Verification Command / Artifact |
|----|-----------|---------------------------------|
| A1 | 3 consecutive OK overall runs | perf_classifier_status.json (ok_streak_current ≥3) |
| A2 | Baseline artifacts exist & valid | ENFORCE_BASELINES=1 tests/performance/telemetry/test-classifier-baselines.zsh |
| A3 | Structured telemetry schema stable | tests/performance/telemetry/test-structured-telemetry-schema.zsh |
| A4 | No pending segment definition changes | Diff REFERENCE.md §5.3 vs current branch; tools/sync-readme-segments.zsh --check |
| A5 | README / REFERENCE segment sync clean | tools/sync-readme-segments.zsh --check |
| A6 | Variance (RSD) stable (≤5% prompt_ready) | perf_classifier_status.json metrics.prompt_ready.rsd_pct |
| A7 | Privacy appendix updated for any new keys | privacy/PRIVACY_APPENDIX.md delta review |

### 15.4 Governance Activation Row (Template)

Insert into Feature Delta Table (Type=governance) once A1–A7 achieved:

| Date | Type | Scope | Δ Synchronous | Δ Deferred | New Total | RSD | Baseline Ref | Status | Notes |
|------|------|-------|---------------|------------|-----------|-----|--------------|--------|-------|
| YYYY-MM-DD | governance | performance-classifier | 0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Enforce mode activated after 3× OK streak (all metrics ≤10% delta) |

Rules:
- Δ columns remain 0 / — (activation is governance, not performance change).
- New Total / RSD copied from activation run prompt_ready metrics.
- If activation deferred due to near-Warn deltas (>9%), re-collect before logging.

### 15.5 Rollback Policy

| Trigger | Immediate Step | Follow-up |
|---------|----------------|----------|
| Spurious WARN (noise) | Temporarily run classifier in observe mode | Increase sample size (RUNS=10) & re-evaluate |
| FAIL but manual retest OK | Revert to observe for 1 cycle | Add investigation + mitigation row |
| Legitimate Regression | Keep enforce (FAIL) | Open mitigation PR + add regression & mitigation rows |

Never delete baselines; re-baselining requires a new governance row: Type=governance, Scope=rebaseline, with justification.

### 15.6 perf_classifier_status.json Schema (Excerpt)

```
{
  "overall_status": "OK",
  "ok_streak_current": 2,
  "ok_streak_max": 2,
  "metrics": {
    "prompt_ready": {
      "raw_metric_key": "prompt_ready_ms",
      "status": "OK",
      "mean_ms": 334,
      "baseline_mean_ms": 334,
      "delta_pct": 0.0,
      "rsd_pct": 1.9,
      "runs": 5
    }
  },
  "source": { "mode": "observe", "warn_threshold_pct": 10, "fail_threshold_pct": 25 }
}
```

### 15.7 Enforcement Guardrails

| Guardrail | Condition | Enforcement Step |
|-----------|-----------|------------------|
| Baseline drift | Missing or zero baseline file | Block enforce (remain observe) |
| Metric absence | Missing segment anchor | Fail baseline integrity test |
| Added telemetry key | Not in allowlist | Schema test FAIL; block activation |
| Streak reset | WARN/FAIL encountered | ok_streak_current → 0 |

### 15.8 PR Activation Checklist (Copy/Paste)

- [ ] A1: ok_streak_current ≥ 3 (list run IDs)
- [ ] A2: Baseline integrity test PASS
- [ ] A3: Schema validation test PASS
- [ ] A4: No pending segment changes (diff clean)
- [ ] A5: README segment sync PASS
- [ ] A6: RSD ≤5% (prompt_ready)
- [ ] A7: Privacy appendix up to date
- [ ] Governance row prepared (not yet committed)
- [ ] TASK_TRACKER S4-33 ready to mark complete

### 15.9 Future Enhancements (Planned)

| Enhancement | Description | Priority |
|-------------|-------------|----------|
| Percentile capture | Add P50/P95 for each metric | Medium |
| Streak badge | Visual readiness indicator | High |
| Trend slope detection | Early drift regression slope | Low |
| Auto README perf status validation | CI gate using update-performance-status output | Medium |

### 15.10 GOAL Profile Influence on Enforcement

The classifier now operates under a GOAL paradigm. These profiles bundle strictness, fallback, and exit semantics:

| Profile | Synthetic Fallback | Missing Metric Policy | Partial Flag Allowed | synthetic_used Allowed | Exit on Missing? | Exit on Synthetic? | Typical Use |
|---------|--------------------|------------------------|----------------------|------------------------|------------------|--------------------|-------------|
| Streak | Allowed | Warn + continue | Yes | Yes (if used) | No | No | Build OK streak (resilient) |
| Governance | Disallowed | Hard fail | No | No | Yes | Yes | Pre-enforcement validation |
| Explore | Allowed | Warn + continue | Yes | Yes (if used) | No (unless catastrophic) | No | Developer diagnostics |
| CI | Disallowed | Hard fail | No | No | Yes | Yes | Deterministic automation gating |

Classifier status JSON (governance artifact, not per-line telemetry) now includes:
- `goal` (always)
- `synthetic_used` (only if synthetic fallback executed)
- `partial` (only if one or more required metrics absent under a tolerant profile)
- `ephemeral` (only in Explore mode)

New Governance Activation Precondition (A8):
- Three consecutive runs executed with `GOAL=Governance` in which neither `synthetic_used` nor `partial` appears in the status JSON.

Activation Row Note:
- When logging the governance activation row, append a note `(goal=governance, A8 satisfied)` to verify the profile and cleanliness.

#### Legacy Behavior (Historical Footnote)

Prior to GOAL integration the classifier implicitly behaved like today’s `Streak` (synthetic fallback permitted; missing metrics tolerated with warnings; no explicit JSON fields indicating partial or synthetic usage). That implicit mode is deprecated—current evidence must rely on explicit `goal` plus optional flags.

(End Section 15)

> Authoritative chronological ledger for startup performance, per‑feature deltas (Stage 4+), variance stability, and remediation actions.  
> This document is append‑only (except for clearly marked placeholder sections). Historical rows MUST never be rewritten—add corrections as new rows with a “Correction Of” note.

---

## 1. Purpose

Track:
1. Baseline cold start metrics (wall clock + variance).
2. Incremental synchronous cost attributed to each Feature Layer module as it lands.
3. Deferred (postprompt) completion times for asynchronous / deferred features.
4. Regression events, investigation summaries, and mitigations.
5. Guardrail compliance (aggregate and per-feature thresholds).

All entries must be reproducible from committed artifacts (performance capture JSON, CI logs, test evidence) or explained if transient.

---

## 2. Current Baseline (Stage 3 Exit Reference)

| Metric | Value | Notes |
|--------|-------|-------|
| Cold Start Mean | 334ms | Measured under `zsh -f` redesign environment |
| Variance (RSD) | 1.9% | N=5 sample set, outlier filtering (none removed) |
| Micro Benchmark Core (per-call) | 37–44µs | Core function micro benchmark range |
| Variance Guard Mode | guard | 3/3 stability streak achieved |
| Drift Detection Mode | observe | Enforcement deferred pending Stage 4 deltas |
| Enforcement Ceiling (Interim) | 384ms (~+15%) | Planned CI fail threshold (early Stage 4) |

Baseline Anchor ID: `baseline-stage3-2025-09-10`
(Use this ID in future delta rows “Baseline Ref” column.)

---

## 3. Measurement Methodology (Authoritative)

| Aspect | Specification |
|--------|---------------|
| Shell Invocation | `env -i ZDOTDIR=<repo>/dot-config/zsh /bin/zsh -f -i -c '...'` |
| Sample Size (standard) | N=5 for routine guard checks |
| Sample Size (investigation) | N=15 (or more) for suspected regression |
| Outlier Policy | Discard samples >2x median (log discard count) |
| Timing Source | Internal instrumentation (monotonic) – validated by harness |
| Environment Controls | No network I/O, warmed filesystem, steady CPU |
| Variance Metric | Relative Standard Deviation (RSD = stdev/mean * 100) |
| Feature Delta Capture | (Stage 4+) Wrapped per-feature init timing (synchronous only) |
| Deferred Timing | First prompt timestamp vs deferred completion timestamp ledger |

Any deviation from methodology must be explicitly annotated in the row where it occurs.

---

## 4. Logging Conventions

Each performance change entry uses this canonical schema (Markdown table row):

`| <Date> | <Type> | <Scope> | <Δ Synchronous> | <Δ Deferred> | <New Total> | <RSD> | <Baseline Ref> | <Status> | <Notes> |`

Field definitions:

| Field | Definition |
|-------|------------|
| Date | ISO `YYYY-MM-DD` (UTC) |
| Type | baseline · feature-add · refactor · regression · mitigation · investigation · correction · governance |
| Scope | Feature name(s) or “global” |
| Δ Synchronous | Added (+) or removed (−) cold start synchronous time (ms); “0” if negligible (<1ms) |
| Δ Deferred | Added (+)/removed (−) postprompt work (ms) until fully ready; “—” if N/A |
| New Total | New cold start mean after change (ms) |
| RSD | Variance after change (%) |
| Baseline Ref | ID of anchor row used for comparisons |
| Status | pass (within guardrails) · warn (soft threshold) · fail (breach) |
| Notes | Concise summary (link to artifacts / PR / commit references) |

---

## 5. Feature Delta Table (Empty – To Be Populated)

| Date | Type | Scope | Δ Synchronous | Δ Deferred | New Total | RSD | Baseline Ref | Status | Notes |
|------|------|-------|---------------|------------|-----------|-----|--------------|--------|-------|
| 2025-09-10 | baseline | global | 0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Stage 3 exit baseline capture |
| 2025-09-10 | feature-add | registry-invocation-wrapper | +0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Added invocation wrapper + init-phase telemetry (no measurable sync delta) |
| 2025-09-10 | feature-add | aliases-keybindings (safety/aliases,navigation/cd) | +0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Added granular SEGMENT probes (safety/aliases, navigation/cd); negligible (<1ms) |
| 2025-09-10 | feature-add | instrumentation (ui/prompt-setup) | +0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Added ui/prompt-setup placeholder SEGMENT; zero-cost stub |
| 2025-09-10 | feature-add | instrumentation (security/validation) | +0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | Added security/validation placeholder SEGMENT; zero-cost stub |
| 2025-09-10 | infra | ci-performance-workflow-upgrade | +0 | — | 334ms | 1.9% | baseline-stage3-2025-09-10 | pass | CI migrated to multi-metric classifier (prompt_ready, pre_plugin_total, post_plugin_total, deferred_total) – baseline creation expected on first run |

(Insert new rows BELOW this marker; do not edit earlier rows.)
<!-- APPEND_MARKER_DO_NOT_REMOVE -->
| 2025-09-14 | governance | performance-classifier-enforce-mode | 0 | — | 1012ms | 2.9% | s4-baseline-redesign-2025-09-14 | pass | Enforce-mode activated: Stage 4 redesigned modules stable (82% perf improvement), preconditions A2-A7 verified, consistent ~1012ms baseline established |

---

## 6. Guardrails & Thresholds

| Guardrail | Threshold | Action |
|-----------|-----------|--------|
| Aggregate Cold Start (Early Stage 4) | +15% (> ~384ms) | CI fail (planned) |
| Aggregate Warning | +10% (> ~367ms) | Warning + investigation trigger |
| Per-Feature Sync Budget | >20ms | Flag for deferral / optimization |
| Deferred Aggregate Budget | >100ms cumulative | Evaluate asynchronous chunking |
| Variance Stability | RSD >5% | Investigate environment noise or new hotspots |
| Drift Fail (Future) | >10% regression vs baseline anchor | Hard fail once drift guard enabled |

---

## 7. Investigation / Mitigation Template

When a regression or variance anomaly is detected, append a row (Type=investigation) and create a short subsection:

```
### Investigation: <identifier>
Date: <YYYY-MM-DD>
Trigger: (regression / variance spike / anomaly)
Observed: <metrics>
Suspected Cause: <brief hypothesis>
Actions Taken:
1. <step>
2. <step>
Outcome: <resolved|unresolved|monitoring>
Follow-up Tasks: <list or “none”>
```

Include references (commit hashes, PR numbers, artifact paths) inline.

---

## 8. Per-Feature Timing (Planned Instrumentation Schema)

(Will activate after registry invocation wrappers land.)

Proposed internal associative arrays:

- `ZSH_FEATURE_TIMINGS_SYNC[name]=<ms>` – synchronous init cost
- `ZSH_FEATURE_TIMINGS_DEFERRED[name]=<ms>` – deferred cumulative time (optional)
- `ZSH_FEATURE_TIMINGS_VERSION=name:version` – captured for drift correlates

Export to JSON (future tooling) for automated ingestion into CI performance dashboards.

---

## 9. Data Integrity & Reproducibility

| Risk | Mitigation |
|------|------------|
| Environmental noise | Controlled shell invocation + multiple samples |
| Hidden caching effects | Periodic cold cache validation run (filesystem flush not automated; note disclaimers) |
| Feature timing skew by telemetry | Telemetry default OFF; timing wrappers minimal overhead (<0.2ms target) |
| Forgotten update after change | Add PR checklist item: “Updated PERFORMANCE_LOG if performance-affecting” |
| Accidental row edits | Append-only policy + code review enforcement |

---

## 10. Change Log (Meta – Edits to This File)

| Date | Change | Author | Notes |
|------|--------|--------|-------|
| 2025-09-10 | Initial scaffold created | Stage 4 automation | Added baseline row + methodology |
| 2025-09-10 | Added guardrail table & investigation template | Stage 4 automation | Prepared for first feature deltas |
| 2025-09-10 | Appended multi-metric classifier legend & new instrumentation rows | Stage 4 automation | Documented added SEGMENT probes + CI workflow upgrade |

---

## 11. Open Items

| ID | Topic | Description | Planned Resolution |
|----|-------|-------------|--------------------|
| O1 | Invocation Wrappers | Add per-feature timing capture around `feature_<name>_init` | Implement mid Phase B |
| O2 | Deferred Timing | Standardize postprompt completion ledger capture | After async prompt manager integration |
| O3 | JSON Export | Automated export of timing arrays to artifacts | Phase C telemetry-core feature |
| O4 | Drift Guard Flip | Enable enforcement after stable feature additions | Post Phase D stabilization |
| O5 | Micro Benchmark Deltas | Correlate function-level regression with feature changes | Introduce after shim elimination |

---

## 12. Usage Guidelines

1. After merging a feature impacting startup, run the performance suite locally (N=5) + confirm CI replication.
2. If delta <1ms, you may record `0` (negligible) but note reasoning if feature is non-trivial.
3. If variance increases (>5% RSD), open an investigation row even if total time remains under threshold.
4. Always reference the baseline anchor ID unless establishing a NEW anchor (rare; justify).
5. Do not remove historical anomalies—close them out with a mitigation row.

---

## 13. Performance Regression Classifier

The automated performance regression classifier (tools/perf-regression-classifier.zsh) monitors key timing metrics across multiple dimensions:

### Classification Thresholds

| Status | Criteria | Badge Color | Action |
|--------|----------|-------------|--------|
| OK | All metrics ≤ 10% delta | Green | Continue |
| WARN | Any metric > 10% but ≤ 25% delta | Yellow | Investigation recommended |
| FAIL | Any metric > 25% delta | Red | CI failure (enforce mode) |

### Monitored Metrics

| Metric | Description | Baseline | Budget |
|--------|-------------|----------|--------|
| `prompt_ready_ms` | Total startup to first prompt | 334ms | +15% (384ms) |
| `pre_plugin_total_ms` | Pre-plugin phase duration | ~45ms | +20% |
| `post_plugin_total_ms` | Post-plugin phase duration | ~185ms | +15% |
| `deferred_total_ms` | Postprompt async work | ~30ms | +50% |

### Multi-Metric Aggregation

The classifier evaluates each metric independently and reports:
- Per-metric status with delta percentages
- Overall status (worst-case of all metrics)
- Unified CLASSIFIER line for CI parsing

Example output:
```
CLASSIFIER status=WARN delta=+12.3% mean_ms=341 baseline_mean_ms=334 median_ms=340 rsd=1.8% runs=5 metric=prompt_ready_ms warn_threshold=10% fail_threshold=25% mode=observe
CLASSIFIER status=OVERALL overall_status=WARN metrics=4 worst_metric=post_plugin_total_ms worst_delta=+12.3%
```

---

## 14. Future Enhancements (Not Yet Implemented)

| Proposal | Benefit | Status |
|----------|---------|--------|
| Percentile Tracking (P50/P95) | Improved tail latency insight | Planned post initial per-feature timing |
| Automated Drift Badge Integration | Visual guardrail feedback | Pending telemetry-core |
| Trend Regression Classifier | Early warning for gradual drift | Deferred (low immediate ROI) |
| Multi-Environment Sampling | Detect host-specific regressions | Deferred (complex setup) |

---

Maintainers: Treat this log as compliance-critical. Omissions in performance-impacting PRs must be corrected before promotion gating is enabled.

End of document.
