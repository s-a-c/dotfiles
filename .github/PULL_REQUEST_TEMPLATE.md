# Remediation / Rollback PR Template
Use this template exclusively for remediation or rollback Pull Requests when enabling performance enforcement (e.g. `PERF_DIFF_FAIL_ON_REGRESSION=1`) or other gating caused CI failures or regressions.

Note: The repository uses a PR template chooser under `.github/PULL_REQUEST_TEMPLATE/`. For standard changes, select an appropriate template there (e.g., `000-repo-default.md` for repo‑wide changes or `010-zsh-project.md` for ZSH‑specific changes).

---

## Title
Revert: enable perf-diff enforcement / remediation for [ENFORCEMENT_CHANGE_NAME]

---

## Summary
- Purpose: Revert or temporarily disable the enforcement change that caused CI to fail (for example, `PERF_DIFF_FAIL_ON_REGRESSION=1`) so we can triage a performance regression without blocking other work.
- Target branch: `main` (or branch where enforcement was enabled)
- Original enforcement PR: (link to the PR that enabled enforcement)

---

## Why this rollback
- Brief description of the failing symptom (CI job name, failing checks).
- Summary of observed evidence (drift badge state, failing perf-diff JSON, refs to ledger artifacts or run IDs).
- Short justification for rollback (unblock CI, allow fast triage, prevent user-facing regression).

---

## What this PR does
- Reverts the commit(s) that enabled enforcement OR
- Temporarily sets the enforcement environment variable(s) back to a non-fail state. Example:
  - Set `PERF_DIFF_FAIL_ON_REGRESSION=0` in the affected workflow(s), or
  - Revert the line that exported `PERF_DIFF_FAIL_ON_REGRESSION=1` in `.github/workflows/ci-*.yml`.
- Adds short-term observability toggles (optional, recommended for 48–72 hours):
  - Increase `stable_run_count` (e.g., from 3 → 5) to reduce false positives.
  - Enable `VARIANCE_LOG_LEVEL=debug` for a narrow time window.
- Annotates the PR body with links to the failing CI runs, perf-diff JSON, and the ledger snapshots.

---

## Quick rollback steps (for on-call)
1. Merge this remediation PR into `main` to remove enforcement immediately.
2. Re-run the failing CI workflow(s) (manually dispatch) to confirm enforcement is disabled.
3. Collect current diagnostics:
   - CI run logs
   - perf-diff JSON (if generated)
   - Links to last 7 ledger artifacts (or the CI artifact bundle)
4. Start triage using the checklist below. If the regression is confirmed fixable, prepare a fix branch and targeted PR to `develop` (or `main` depending on urgency).

---

## Triage checklist
- [ ] Attach the perf-diff JSON (or link to artifact) that shows the reported regression.
- [ ] Attach or link to the last 7 ledger snapshots used for comparison (CI artifacts preferred).
- [ ] Reproduce the regression locally (run a focused capture):
  - `./dot-config/zsh/tools/perf-capture-multi.zsh -n 3 --no-segments --quiet`
  - Or run N=1 smoke capture and compare using `tools/perf-diff.sh`.
- [ ] Inspect the most recent commits for changes to hotspots (compinit, p10k, plugin loading, zgenom-init).
- [ ] If implicated, create a minimal reproducer branch that isolates the change.
- [ ] If caused by environmental flakiness, consider adjusting `stable_run_count` or adding targeted logging before re-enabling enforcement.
- [ ] Once fixed, re-enable enforcement via a focused PR that includes the evidence bundle described under "Re-enable enforcement" below.

---

## Evidence / Artifacts to attach in this PR
- CI run ID(s) and links showing failures.
- perf-diff JSON produced by the perf diff tooling (if available).
- Last 7 ledger snapshots (or link to a CI artifact bundle containing them).
- stage3-exit-report.json or equivalent readiness report if relevant.
- Microbench baseline JSON (e.g., `docs/redesignv2/artifacts/metrics/perf-multi-simple.json` or bench-core baseline).

---

## Re-enable enforcement (post-triage)
When the root cause is fixed and stability is demonstrated:
1. Create a PR that re-applies the enforcement change (single focused PR).
2. Attach the following evidence:
   - drift badge / perf-diff summary showing no fail-state,
   - `stage3-exit-report.json`,
   - last 7 ledger snapshots demonstrating stability,
   - microbench baseline comparison results.
3. Optionally set a probation period (e.g., require 7 consecutive successful nightly ledgers) before merging.
4. Add a rollback plan in the PR description (link to this remediation PR).

---

## Implementation notes & commands
- To temporarily disable enforcement (example patch snippet for a workflow):
```diff
-      env:
-        PERF_DIFF_FAIL_ON_REGRESSION: '1'
+      env:
+        PERF_DIFF_FAIL_ON_REGRESSION: '0' # temporarily disabled pending triage
```

- To revert the original enabling commit:
```bash
# Example - revert by commit:
git checkout main
git revert <commit-sha-enabling-enforcement> -m 1
git push origin main
```

- To remove CI-committed ledger files from a branch (if accidentally committed):
```bash
git rm --cached docs/redesignv2/artifacts/metrics/ledger-history/perf-ledger-*.json
git commit -m "chore: remove committed CI->generated perf ledger files"
git push origin <branch>
```

---

## Rollout / Communication
- Notify stakeholders and on-call when rollback is merged.
- Post a summary comment in the original enforcement PR linking this remediation PR and the triage notes.
- If the regression impacted external users, coordinate an appropriate release note or rollback notification.

---

## Contacts / Owners
- Enforcement owner: @<team-or-user>
- CI / Infra owner: @<team-or-user>
- Performance owner: @<team-or-user>
- On-call rotation: @<on-call-contact>

---

## Related PRs / Tickets
- Original enforcement PR: [link]
- Incident ticket: [link to issue tracker]
- Follow-up fix PRs: [link(s)]

---

## Final notes
This remediation PR is intended as a temporary unblock to allow investigation and fix without causing churn for other teams. After the underlying issue is resolved, re-apply the enforcement with clear evidence and a controlled re-enable plan.