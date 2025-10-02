# Internal Changelog – Workflow Dispatch Anomaly Resolution
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20

## 1. Summary
Between earlier September 2025 and 2025-09-12 the repository experienced a persistent anomaly where newly added (or recently edited) GitHub Actions workflows containing a valid:
```
on:
  workflow_dispatch: {}
```
trigger returned:
```
HTTP 422
{"message":"Workflow does not have 'workflow_dispatch' trigger", ...}
```
while legacy workflows (unchanged for a longer interval) dispatched successfully (HTTP 204). This indicated a backend indexing / registration issue rather than YAML, permissions, or authentication faults.

Native behavior recovered spontaneously (no repo-side remediation) and by 2025-09-12 manual + API dispatches for new workflows returned HTTP 204.

## 2. Timeline (UTC)
| Date / Time (approx) | Event |
| -------------------- | ----- |
| T0 (early period) | First observation: new workflow returns 422; legacy dispatch OK |
| T0 + Investigations | Repeated curl tests, YAML validation, hex inspection, permissions review |
| Mitigation Phase | Added fallbacks (repository_dispatch, tag trigger, chained dispatch via legacy workflow) |
| Evidence Phase | Added minimal reproduction workflow + capture script (expecting 422) |
| 2025-09-12 | Dispatch for previously failing workflows returns 204 |
| 2025-09-12 | Transient validation workflow added → confirmed secondary API dispatch success |
| 2025-09-12 | Evidence script patched (defaults to EXPECT_REPRO_STATUS=204) |
| 2025-09-12 | Phase A+B cleanup executed: removed transient validation, fallbacks, chaining input/step, archived helper script |
| 2025-09-12 | Phase C completed: minimal reproduction workflow deleted; diagnostics bundle archived |

## 3. Impact
| Area | Impact |
| ---- | ------ |
| Manual dispatch (new workflows) | Blocked (422) during anomaly window |
| Existing workflows | Unaffected |
| Scheduled / push / PR events | Unaffected |
| Release cadence | Minor friction (workarounds available) |
| Security / credentials | No exposure; anomaly unrelated to tokens |

## 4. Mitigations Employed (All Now Retired)
| Mitigation | Purpose | Status |
| ---------- | ------- | ------ |
| `repository_dispatch` (event_type: badges_v2_run) | Alternate manual trigger path | Removed (Phase B) |
| Tag trigger `zsh-badges-run-*` | CLI-based manual activation | Removed (Phase B) |
| Chained dispatch (`dispatchBadges` input in `ci-performance.yml`) | Leverage known-good workflow_dispatch surface | Removed (Phase B) |
| Minimal reproduction workflow `test-minimal-dispatch.yml` | Stable anomaly reproducer | Removed (Phase C) |
| Transient validation workflow | Post-recovery confirmation | Removed (Phase A) |
| Helper script `dispatch-badges.sh` | Simplify repository_dispatch invocation | Archived (moved under `archive/tools/`) |

## 5. Root Cause Assessment
No internal repository issue identified. Root cause highly likely an upstream indexing / propagation defect at GitHub’s Actions backend (event graph registration for new `workflow_dispatch` triggers). Resolution occurred without code or configuration change inside the repository.

## 6. Verification of Recovery
- Direct UI manual dispatch of formerly failing workflow → 204
- REST API dispatch (`POST /actions/workflows/<file>/dispatches`) → 204
- Transient validation workflow’s internal secondary dispatch → 204
- No further 422 responses observed across multiple attempts within the same day
- Post Phase C: Weekly health check workflow added; initial run confirms 204 responses

## 7. Cleanup Phases (Execution Status)
| Phase | Description | Status | Notes |
| ----- | ----------- | ------ | ----- |
| A | Remove transient validation workflow | COMPLETE | Stub left for historical context |
| B | Prune fallbacks & chaining input | COMPLETE | Tags, repository_dispatch, chaining removed |
| C | Remove minimal reproduction workflow | COMPLETE | Deleted 2025-09-12 (Phase C) |
| D | Archive diagnostics bundle | COMPLETE | Archived under `.github/dispatch-diagnostics-archive/2025-09-12/` |
| E | Final docs & issue closure | IN PROGRESS | Monitoring window + issue #15 awaiting closure |

## 8. Rollback Plan (If Regression Occurs)
1. Reintroduce (or restore from history) minimal reproduction workflow (from git history).
2. Run evidence script with:
   ```
   EXPECT_REPRO_STATUS=422 ./dot-config/zsh/tools/capture-dispatch-evidence.sh
   ```
3. (Optional) Reinstate `repository_dispatch` fallback if operational necessity exists.
4. File new “Regression: workflow_dispatch indexing” issue referencing this changelog entry and prior cleanup issue.
5. Provide fresh timestamps + failing run IDs.

All steps are low risk because revert = additive only.

## 9. Commands (Reference)
Check present dispatch-capable workflows:
```
grep -R "workflow_dispatch:" .github/workflows | cut -d: -f1 | sort -u
```
Confirm no fallback remnants:
```
grep -R "badges_v2_run" .github/workflows || echo "OK (no fallback event_type)"
grep -R "dispatchBadges" .github/workflows || echo "OK (no chaining input)"
grep -R "zsh-badges-run-" .github/workflows || echo "OK (no tag trigger)"
```

## 10. Evidence Script (Current Mode)
Default (healthy state):
```
./dot-config/zsh/tools/capture-dispatch-evidence.sh
```
Regression capture:
```
EXPECT_REPRO_STATUS=422 ./dot-config/zsh/tools/capture-dispatch-evidence.sh
```

## 11. Security & Policy Compliance
- No secrets added; only subtractive changes plus archival.
- Redaction in evidence script retains token masking.
- Compliant with guidelines header requirements.

## 12. Pending Actions
| Item | Owner | ETA |
| ---- | ----- | --- |
| Phase E (final monitoring + issue closure) | Maintainer | After 3–7 day monitor |
| Optional removal of transient stub (already deleted) | — | N/A |
| Weekly health check review | Maintainer | Ongoing |

## 13. Final State Criteria (Definition of Done)
All of:
- ≥2 manual dispatch successes post-removal of reproduction workflow (ACHIEVED)
- Diagnostics bundle archived with “ARCHIVED” marker (ACHIEVED)
- Changelog (this file) committed (ACHIEVED)
- Cleanup tracking issue closed with run IDs logged (PENDING)
- No fallback triggers present (ACHIEVED)

## 14. Contacts
| Role | Handle | Notes |
| ---- | ------ | ----- |
| CI / Infra Maintainer | (fill) | Primary |
| Repository Owner | (fill) | Approval |
| Reviewer | (fill) | Optional |

## 15. Appendix – Historical Error Signature
```
HTTP/1.1 422 Unprocessable Entity
{"message":"Workflow does not have 'workflow_dispatch' trigger","documentation_url":"https://docs.github.com/rest/actions/workflows#create-a-workflow-dispatch-event"}
```

## 16. Notes
Retain this changelog entry to preserve institutional knowledge around symptom pattern and remediation approach. Weekly health check workflow provides continuous validation.

## 17. Phase C Completion Note
- Minimal reproduction workflow removed (commit timestamp 2025-09-12T11:42Z).
- All temporary anomaly-specific constructs eliminated.
- Health check workflow introduced to detect any regression early.

---
End of changelog entry.