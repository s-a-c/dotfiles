# ADR-0007: Classifier GOAL Profiles (Streak, Governance, Explore, CI)

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

Status: Accepted  
Date: 2025-09-11  
Supersedes: (none)  
Superseded By: (n/a)  
Related: IMPLEMENTATION.md §4.x “Classifier Goal Profiles & Execution Semantics”; PERFORMANCE_LOG.md §15 (A8); PRIVACY_APPENDIX.md v1.1; README “Classifier GOAL Profiles” section  

---

## 1. Context

The performance regression classifier originally operated in a single “observe” mode:
- Tolerated missing segment metrics silently (or with weak warnings).
- Allowed synthetic fallback segments (fabricated placeholder timings) to preserve pipeline continuity while instrumentation stabilized.
- Employed uniform strict shell options (`set -euo pipefail`) intermittently, causing brittle failures when instrumentation was incomplete.

As instrumentation matured (multi-metric baselines, telemetry schema tests, governance activation streak), competing needs emerged:

| Need | Description |
|------|-------------|
| Fast Confidence Building | Accumulate consecutive OK runs despite transient missing metrics (streak bootstrap). |
| Strict Governance Validation | Guarantee *real* (non-synthetic, complete) data before enforce-mode activation. |
| Exploratory / Diagnostic Iteration | Let developers experiment with new segment capture logic without resetting the streak or producing false governance failures. |
| Deterministic CI Gating | Provide reproducible, strictly-enforced outcomes for automation (no accidental tolerance drift). |

Ad‑hoc conditionals became hard to reason about and risked conflating governance readiness with experimentation noise.

---

## 2. Decision

Introduce a single environment / CLI variable `GOAL` (enum: `Streak`, `Governance`, `Explore`, `CI`) controlling:
1. **Strictness Strategy** (phased vs hard `set -euo pipefail`).
2. **Synthetic Fallback Permission** (allow / deny).
3. **Missing Metric Policy** (tolerated, flagged partial, or hard fail).
4. **Baseline Creation Conditions** (whether missing metrics block new baselines).
5. **Classifier Status JSON Augmentation**:
   - `goal` (always)
   - `synthetic_used` (present only if synthetic fallback invoked)
   - `partial` (present only if metrics missing under a tolerant profile)
   - `ephemeral` (only for `Explore`)
6. **Exit Semantics** (non-zero vs always-zero in exploratory mode).
7. **Governance Precondition A8**: Three consecutive `GOAL=Governance` runs with no `synthetic_used` and no `partial` before enforce-mode activation.

Default (unset) behavior = `Streak` to maintain backward compatibility and avoid breaking existing CI or local workflows prior to migration.

---

## 3. Options Considered

| Option | Summary | Rejected Because |
|--------|---------|------------------|
| Single Strict Mode + Flags | One profile; multiple booleans toggled ad-hoc | Hard to audit; combinatorial complexity; implicit, error-prone layering. |
| Early Permanent Strictness | Enforce all invariants immediately | Slows stabilization; increases false failures during instrumentation churn. |
| Soft Mode Only | Keep tolerant observe mode, rely on manual checks | Insufficient governance assurance; risk of synthetic data masking regressions. |
| Per-Flag CLI Explosion | Fine-grained switches (`--allow-synthetic`, `--strict-metrics`, etc.) | Increases cognitive load; lacks opinionated lifecycle structure. |
| Profile Abstraction (Chosen) | Encapsulate coherent behavior bundles | Clear mental model; easier documentation, testing, and governance gating. |

---

## 4. Consequences

### Positive
- Clear separation between resilience (Streak), strict trust validation (Governance), exploratory freedom (Explore), and deterministic automation (CI).
- Simplifies governance documentation (one new precondition A8 vs diffuse implicit assumptions).
- Encourages early experimentation without penalizing stability streak.
- Status JSON becomes self-describing for audits (no guesswork about mode).
- Facilitates targeted test matrix (T-GOAL-01..06) rather than broad combinatorial flag coverage.

### Negative / Trade-Offs
- Slight additional runtime overhead (profile dispatch + conditional logic) — target <2ms total.
- Requires updating tests and tooling to interpret new JSON fields.
- Risk of misuse (e.g., using `Explore` in CI) — mitigated through documentation and CI workflow convention (`GOAL=ci`).

### Neutral / Deferred
- Potential future collapse of `Streak` and `Explore` if instrumentation stabilizes (would require superseding ADR).
- Synthetic fallback removal pathway documented but not executed yet (observability during transition still valuable).

---

## 5. Security & Privacy Impact

- No new sensitive categories introduced; only enumerated values and booleans.
- Privacy Appendix updated (v1.1) to add: `goal`, `synthetic_used`, `partial`, `ephemeral`.
- No retention or transmission changes.
- Synthetic detection metadata *reduces* risk of hidden masking by making fallback explicit.

---

## 6. Rollout Plan (Phases)

| Phase | Action | Success Metric |
|-------|--------|----------------|
| 1 | Documentation (this ADR + README + Implementation + Privacy) | All docs reference GOAL |
| 2 | Scaffold parsing (`--goal` + env) | Classifier prints `goal` only, no behavior change |
| 3 | Emit `goal` in status JSON | Backward compatibility preserved |
| 4 | Enforce synthetic & missing metric gating | Governance run fails on synthetic or missing |
| 5 | Strictness layering (phased vs hard) | Streak still resilient; Governance fail-fast |
| 6 | Emit optional flags (`partial`, `synthetic_used`, `ephemeral`) | Flags present only when true |
| 7 | Test matrix T-GOAL-01..06 | All green locally + CI |
| 8 | CI workflow adoption (`GOAL=ci`) | CI runs deterministic outcomes |
| 9 | Governance streak enforcement (A8) | 3 governance runs clean → enforce PR ready |

---

## 7. Reconsideration Triggers

Trigger a new ADR (supersession) if:
- Synthetic fallback is permanently eliminated.
- Metrics set expands (e.g., percentile / feature-level gating) requiring new profile semantics.
- Governance introduces multi-dimensional (latency + variance + privacy) simultaneous gating.
- CI requires divergence from Governance semantics (currently identical except naming).

---

## 8. Detailed Semantics (Snapshot)

| Dimension | Streak | Governance | Explore | CI |
|-----------|--------|------------|---------|----|
| Strictness | Phased: `-uo` early; add `-e` before summarizing | Full `-euo pipefail` | `-uo` only; internal error ledger | Full `-euo pipefail` |
| Synthetic Fallback | Allowed | Disallowed | Allowed | Disallowed |
| Missing Metrics | Warn; continue; mark partial | Hard fail | Warn; continue; mark partial | Hard fail |
| Baseline Creation | Allowed (auto) | Only when complete & real | Allowed | Allowed |
| Extra JSON Flags | partial, synthetic_used | (none) | partial, synthetic_used, ephemeral | (none) |
| Exit on Missing | No | Yes | No | Yes |
| Exit on Synthetic | No | Yes | No | Yes |
| Default Mode (unset) | This profile | N/A | N/A | N/A |

---

## 9. Migration & Backward Compatibility

- Legacy behavior (pre-ADR) effectively mapped to `Streak`.
- No existing scripts relying on synthetic fallback need to change; they inherit `Streak` semantics unless they explicitly adopt stricter profiles.
- Tooling reading old status JSON (without `goal`) remains valid; new consumers should treat absence of `goal` as `streak` during transient transition window.

---

## 10. Testing Strategy (Planned IDs)

| ID | Assertion |
|----|-----------|
| T-GOAL-01 | GOAL=Explore → exit 0 on missing metric + `ephemeral=true` |
| T-GOAL-02 | GOAL=Streak → missing metric tolerated + `partial=true` |
| T-GOAL-03 | GOAL=Governance → synthetic fallback causes non-zero exit |
| T-GOAL-04 | GOAL=CI → identical gating to Governance (strict fail) |
| T-GOAL-05 | Unset GOAL behaves exactly like Streak |
| T-GOAL-06 | Absent flags (`synthetic_used`, `partial`, `ephemeral`) when conditions not met |

---

## 11. Operational Guidance

| Scenario | Recommended GOAL |
|----------|------------------|
| Local baseline refresh | `Streak` |
| Pre-enforce validation PR | `Governance` |
| Investigating incomplete segments | `Explore` |
| CI main branch gating | `ci` |
| Governance activation streak counting | `Streak` until final 3 runs, then `Governance` |

---

## 12. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| CI misconfigured to use `Explore` | Explicit workflow step documentation + badge audit |
| Synthetic fallback unintentionally relied upon long-term | Governance profile + A8 precondition forbids enforce activation until removed |
| Partial flag misinterpreted as failure | Documentation clarifies tolerance in Streak/Explore; only Governance/CI treat as fatal |
| Overhead creep | Instrument profile dispatch timing; maintain <2ms budget |

---

## 13. References

- PERFORMANCE_LOG.md §15 (GOAL influence and A8)
- PRIVACY_APPENDIX.md v1.1 (status JSON fields)
- IMPLEMENTATION.md §4.x (full matrix & internal flags)
- README “Classifier GOAL Profiles” (quick usage)
- Task Tracker entries S4-34..S4-41

---

## 14. Decision Owner

ZSH Redesign Maintainer (Stage 4 Sprint 2)  

---

## 15. Change Log (ADR Internal)

| Date | Change |
|------|--------|
| 2025-09-11 | Initial acceptance |

---

*End of ADR-0007*