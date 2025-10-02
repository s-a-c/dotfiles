# GitHub Actions Workflow Dispatch Diagnostics (Stub)
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20

This directory has been archived. The full historical diagnostics bundle, cleanup plan, and resolution narrative for the former `workflow_dispatch` 422 anomaly have been moved to:

- `.github/dispatch-diagnostics-archive/2025-09-12/`

## Quick Links
| Artifact | Location |
| -------- | -------- |
| Archived Diagnostics README | `.github/dispatch-diagnostics-archive/2025-09-12/README.md` |
| Cleanup Plan | `.github/dispatch-diagnostics-archive/2025-09-12/CLEANUP_PLAN.md` |
| Internal Changelog | `CHANGELOG-DISPATCH-ANOMALY.md` |
| Cleanup Tracking Issue | #15 (Cleanup: Dispatch Anomaly Fallback Removal) |

## Status
- Anomaly resolved: native `workflow_dispatch` for new workflows returns HTTP 204.
- Temporary fallbacks (repository_dispatch, tag triggers, chained dispatch) removed (Phases A & B complete).
- Minimal reproduction workflow staged for deletion (Phase C) and retained only as a stub for short burn‑in confirmation.
- This stub remains solely to guide developers to archival material.

## If Regression Occurs
1. Recreate minimal reproduction workflow from git history.
2. Run evidence script with:
   ```
   EXPECT_REPRO_STATUS=422 ./dot-config/zsh/tools/capture-dispatch-evidence.sh
   ```
3. Open a new regression issue referencing the archived bundle and issue #15.

## Rationale for Archiving
Keeping historical artifacts separate:
- Reduces repository surface noise in active CI areas.
- Preserves institutional knowledge (root cause characterization, mitigation playbook).
- Simplifies future incident response (clear, immutable snapshot).

End of stub.