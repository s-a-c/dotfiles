# Dispatch Anomaly Fallback Cleanup Plan
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20

## 1. Purpose
This document defines the structured cleanup of temporary mitigations introduced for the GitHub Actions `workflow_dispatch` anomaly (historic 422: “Workflow does not have 'workflow_dispatch' trigger”) after native behavior recovered (now returning 204). It also records a full resolution narrative and provides a tracking issue template.

## 2. Scope
Artifacts in scope:
- Temporary workflows:
  - `test-minimal-dispatch.yml` (minimal reproduction)
  - `transient-manual-dispatch-validation.yml` (ephemeral confirmation)
- Temporary triggers / inputs / steps:
  - `repository_dispatch` fallback (`badges_v2_run`) in `zsh-badges-and-metrics.yml`
  - Tag push pattern: `zsh-badges-run-*`
  - Chained dispatch input `dispatchBadges` + step in `ci-performance.yml`
- Helper / evidence assets:
  - `dot-config/zsh/tools/dispatch-badges.sh`
  - Evidence capture script modifications: `capture-dispatch-evidence.sh` (now defaulting EXPECT_REPRO_STATUS=204)
  - Diagnostics bundle & README sections referencing persistent 422 state

Out of scope:
- Core performance, badge, or metrics logic (non-fallback functionality)
- Standard CI workflows unrelated to dispatch anomaly

## 3. Current Status (Baseline for Cleanup)
| Item | Status | Next Action |
|------|--------|-------------|
| New manual dispatches | Healthy (204) | Burn‑in watch |
| Minimal repro workflow | Still present | Remove after window |
| Transient validation workflow | Present & functioning | Remove first post-window |
| Fallback triggers (repository_dispatch, tag) | Still active | Prune |
| Chained dispatch input (ci-performance) | Still active | Remove input + step |
| Evidence script expectation | Updated to 204 | Keep override facility |
| Diagnostics README | Updated with resolution note | Add final “Archived” marker on completion |

## 4. Cleanup Strategy Overview
Phased approach to minimize risk:
1. Observation (Burn‑In): Continue to allow normal usage with instrumentation (no changes).
2. Phase A (Low-Risk Pruning): Remove purely additive, unused validation workflow.
3. Phase B (Trigger Consolidation): Remove fallback triggers & chaining input.
4. Phase C (Reproduction Artifact Retirement): Delete minimal repro workflow.
5. Phase D (Documentation & Script Finalization): Archive diagnostics bundle; simplify evidence script usage notes.
6. Close-Out: Open/close tracking issue with checklist; confirm no regressions after 1–2 successful manual dispatches of formerly affected workflows.

## 5. Preconditions & Gating Checks
Before each phase:
- Confirm at least 2+ successful consecutive manual dispatches of the target workflow(s) over ≥48h.
- Confirm no intermittent 422 occurrences in Actions run history or API attempts.
- Ensure no external automation depends on repository_dispatch fallback (search for `badges_v2_run` references).
- Ensure no external docs instruct using tag pattern trigger.

## 6. Detailed Task List (Actionable Items)

### Phase A: Remove Transient Validation Workflow
1. Delete `.github/workflows/transient-manual-dispatch-validation.yml`.
2. Record removal in tracking issue (checkbox).
3. Trigger a manual dispatch of `zsh-badges-and-metrics.yml` to reconfirm 204.

### Phase B: Prune Fallback Mechanisms
1. In `zsh-badges-and-metrics.yml`:
   - Remove `repository_dispatch` stanza.
   - Remove tag trigger pattern `zsh-badges-run-*`.
   - Remove related TODO comments.
2. In `ci-performance.yml`:
   - Remove input `dispatchBadges`.
   - Remove conditional step “Optional Dispatch Badges Workflow”.
   - Remove annotated TODO comment.
3. Optional: Remove `tools/dispatch-badges.sh` if no longer used (archive in history).
4. Update diagnostics README with “Fallbacks removed” note.

### Phase C: Retire Minimal Repro Workflow
1. Delete `.github/workflows/test-minimal-dispatch.yml`.
2. Add a short note to diagnostics README: “Minimal repro workflow removed (date).”
3. Ensure at least one normal manual dispatch still succeeds afterward.

### Phase D: Documentation & Script Consolidation
1. In `.github/dispatch-diagnostics/README.md`:
   - Add “ARCHIVED” banner.
   - Summarize final state (native behavior stable).
2. In `capture-dispatch-evidence.sh`:
   - Keep override envs (`EXPECT_REPRO_STATUS` / `EXPECT_CONTROL_STATUS`).
   - Optionally add a concise header subtitle: “Historical anomaly; defaults assume healthy state.”
3. Add link from CLEANUP_PLAN.md to archived README section.

### Phase E: Tracking Issue Closure
1. Mark all checklist items complete.
2. Add final comment with:
   - Date/time
   - Manual dispatch success evidence (Run IDs)
   - Confirmation no remaining fallback references appear in grep.

## 7. Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Regression after fallback removal | Low | Medium (manual dispatch blocked) | Keep script & revert commits quickly |
| Hidden external automation relying on repository_dispatch | Very Low | Low | Codebase grep & org search before removal |
| Documentation drift (old instructions referencing tag trigger) | Medium | Low | Update README & internal docs simultaneously |
| Missed dependency on chained dispatch input | Low | Low | Search for `dispatchBadges` usage (none expected outside workflow) |

## 8. Rollback Plan
If a 422 regression appears at any cleanup phase:
1. Immediately reintroduce minimal reproduction workflow (copy from git history).
2. Set `EXPECT_REPRO_STATUS=422` when running evidence script to capture fresh bundle.
3. (Optional) Reinstate repository_dispatch fallback only if operational need emerges before resolution.
4. Open a new “Regression: workflow_dispatch indexing” issue referencing original anomaly timeline.

Rollback complexity: Very low — all removals are subtractive and recoverable via git revert or cherry-pick.

## 9. Burn-In & Timeline
| Window | Duration | Objective |
|--------|----------|-----------|
| Observation | 2–3 days | Confirm consistent 204 status |
| Phases A–B | 1 day | Remove validation workflow and fallbacks |
| Phase C | +1 day (post A–B) | Remove minimal repro file |
| Phase D | Same day as C | Archive docs & finalize scripts |
| Monitoring | 3–7 days | Watch for regressions post-cleanup |
| Close-Out | After monitoring | Finalize tracking issue |

Total estimated effort: Low (< 2 engineer-hours distributed).

## 10. Full Resolution Narrative (Post-Incident)
The repository experienced a persistent anomaly where newly created or recently modified workflows containing a valid `workflow_dispatch` trigger returned HTTP 422 stating the trigger was absent. Legacy workflows dispatched successfully, proving authentication, branch targeting, and token scopes were correct. To maintain operability, additive fallback paths (repository_dispatch, tag-based triggers, chained dispatch via a legacy workflow) were introduced along with a minimal reproduction file and an evidence capture script.

On 2025-09-12 UTC, manual dispatches of previously affected workflows began returning HTTP 204 without any intermediate remediation changes in the repository, indicating a backend indexing or caching issue at GitHub resolved externally. A transient validation workflow confirmed sustained healthy behavior via a secondary internal dispatch API call. The evidence script was updated to expect 204 by default while preserving the ability to revert expectation to 422 for potential future regressions.

The cleanup plan now safely removes temporary artifacts to reduce surface area and complexity while retaining the historical record in version control. Because all mitigations were additive and isolated, removal poses negligible operational risk.

## 11. Tracking Issue Template
Copy/paste to open an issue titled: “Cleanup: Dispatch Anomaly Fallback Removal”

```
## Checklist
- [ ] Burn-in window complete (>= 2 days, multiple 204 dispatch successes)
- [ ] Delete transient validation workflow
- [ ] Remove repository_dispatch fallback in badges workflow
- [ ] Remove tag trigger pattern (zsh-badges-run-*)
- [ ] Remove chained dispatch input + step (ci-performance)
- [ ] Remove minimal reproduction workflow
- [ ] Archive diagnostics README (ARCHIVED banner)
- [ ] Confirm no refs to badges_v2_run remain (grep)
- [ ] Confirm no refs to dispatchBadges remain (grep)
- [ ] Run manual dispatch (post-cleanup) → 204
- [ ] Log final successful run IDs
- [ ] Close issue

## Evidence
- Manual dispatch Run IDs (pre-cleanup): …
- Manual dispatch Run IDs (post-cleanup): …
- grep badges_v2_run output: (attach)
- grep dispatchBadges output: (attach)

## Notes
Include any anomalies or transient failures observed during cleanup.
```

## 12. Commands & Grep Aids
Search for fallback references:
```
grep -R "badges_v2_run" .github/workflows
grep -R "dispatchBadges" .github/workflows
grep -R "zsh-badges-run-" .github/workflows
```
List manual-dispatch capable workflows post-cleanup:
```
grep -R "workflow_dispatch:" .github/workflows | cut -d: -f1 | sort -u
```

## 13. Evidence Script Usage (Healthy vs Regression)
Healthy state (default expectations already 204):
```
./dot-config/zsh/tools/capture-dispatch-evidence.sh
```
Regression capture (force anomaly expectation):
```
EXPECT_REPRO_STATUS=422 ./dot-config/zsh/tools/capture-dispatch-evidence.sh
```

## 14. Policy & Security Notes
- Artifact removal is subtractive; no new secrets or elevated permissions introduced.
- Reference security rule: [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) (secret handling section).
- Ensure no bearer tokens appear in committed evidence bundles (script redaction logic retained).

## 15. Acceptance Criteria (Definition of Done)
All of the following must be true:
1. No fallback-only triggers or chained dispatch inputs remain in workflows.
2. Normal manual dispatches succeed (≥2 consecutive 204 responses).
3. Diagnostics README clearly marked archived with resolution summary.
4. Minimal repro & transient validation workflows removed.
5. Tracking issue closed with evidence recorded.
6. Evidence script still functional (optionally tested with control dispatch).

## 16. Future Monitoring (Optional)
Add lightweight periodic check (weekly) via a matrix job that:
- Uses GitHub API to enumerate workflows containing `workflow_dispatch`.
- Randomly dispatches one newly added workflow (or a designated test) and logs status.
(Only if organizational risk tolerance justifies continued automated surveillance.)

## 17. Glossary
| Term | Definition |
|------|------------|
| Fallback | Temporary alternative trigger path enabling intended job execution |
| Chained Dispatch | Indirect triggering of a blocked workflow via a working one |
| Burn-In | Observation interval verifying stability before subtractive changes |

## 18. Sign-Off
| Role | Name / Handle | Date |
|------|---------------|------|
| Maintainer | (fill) | (fill) |
| Reviewer | (fill) | (fill) |

---

End of Cleanup Plan.