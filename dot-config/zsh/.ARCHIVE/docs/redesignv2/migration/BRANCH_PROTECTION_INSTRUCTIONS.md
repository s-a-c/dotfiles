Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

# Branch protection instructions — require shim-audit gate

Purpose
- Make the shim-audit CI job mandatory for merges on the redesign branch so the repository "migrates with the branch".
- Enforce that any pull request touching the ZSH configuration is validated by the shim-audit gate which produces a machine-readable `shim-audit.json` artifact and fails the check if shims are present.

Who should apply these instructions
- A repository administrator with permission to change branch protection rules in the GitHub repository.

Assumptions
- The repository contains the shim-audit workflow: `dot-config/zsh/.github/workflows/redesign-shim-audit-gate.yml` (job `shim-audit`).
- The workflow is configured to run on pushes and PRs (or at least on the branch you will protect).
- CI run names and job names are visible under the repository Actions UI after at least one run.

High-level recommendation
1. Protect the branch `feature/zsh-refactor-configuration` (or whichever branch you use for the rollout) by requiring the shim-audit job to pass.
2. Keep the check strict (require the branch to be up-to-date with the base branch before merging) so the gate is evaluated against the latest base.
3. Document the requirement in `PLAN_AND_CHECKLIST.md` and notify the team so they know the gate will block merges until shim_count == 0.

UI step-by-step (GitHub web)
1. Go to the repository on GitHub, open `Settings` → `Branches`.
2. Under "Branch protection rules" click `Add rule`.
3. In "Branch name pattern" enter:
   - `feature/zsh-refactor-configuration`
   - (If you want this for multiple branches, create additional rules or use a pattern like `feature/zsh-refactor-*`.)
4. Select the protections you want. Minimum recommended options:
   - Check `Require a pull request before merging`.
   - Check `Require status checks to pass before merging`.
     - Click `Select required checks` (or the entry area) and choose the shim-audit status check. The check typically shows as:
       - `Redesign Shim Audit Gate / shim-audit`
       - or `redesign-shim-audit-gate / shim-audit`
     - If you don't see the check name listed, run the workflow once on the branch so the check run is registered, then return and select it.
   - (Optional but recommended) Check `Require branches to be up to date before merging` — enforces a fresh evaluation against the base branch.
   - (Optional) `Require approvals` if your team wants code review in addition to CI gating.
   - Choose `Include administrators` if you want the rule to apply to admins as well.
5. Click `Create` (or `Save changes`) to apply the rule.

CLI / API examples (for repo admins)
- Quick check: run the shim-audit workflow once on the branch so a check run appears in Actions. This makes the check selectable in branch protection.
- gh CLI (example pattern; replace OWNER/REPO/BRANCH and the contexts array as appropriate):
  ```
  gh api \
    -X PUT /repos/OWNER/REPO/branches/feature/zsh-refactor-configuration/protection \
    -F required_status_checks='{"strict":true,"contexts":["Redesign Shim Audit Gate / shim-audit"]}' \
    -F enforce_admins=true
  ```
  - Note: the `contexts` string must match the check name reported by GitHub exactly (you may need to run Actions once and inspect the check name).
- REST API: Use the Branch Protection API and include `required_status_checks` with `strict: true` and `contexts: [ <exact-check-name> ]`.

What exact status check name should you require?
- The exact name displayed by GitHub appears from the workflow run and is usually structured as:
  - `<Workflow name> / <job name>` e.g. `Redesign Shim Audit Gate / shim-audit`
- If your organization is configured to surface only workflow-level checks, you may see `redesign-shim-audit-gate` or similar. Use the name as shown in the Checks section of a PR or in an Actions run.

Verifying the protection
1. Open the branch protection rule you created and confirm the shim-audit check is listed under required status checks.
2. Create a test PR on the protected branch (or push a commit) and verify:
   - The shim-audit job runs (visible in Actions).
   - If `shim_count > 0` the job fails and the PR shows a failing required check preventing merge.
   - If `shim_count == 0` the job passes and the PR can be merged (assuming other required checks pass).

Rollback / emergency bypass
- Only repo admins can temporarily relax branch protection. If you need to merge an urgent fix:
  1. An admin can uncheck the required status check (or set `Include administrators` off), merge the PR, then re-enable the rule.
  2. Recommended safer alternative: create a short-lived branch/PR that does not touch the ZSH config, or fix the shim issue in a follow-up PR and merge when the gate passes.
- Record any bypass in your team change log with justification and timestamp.

Operational notes and best practices
- Keep the shim-audit workflow's run frequency and artifact retention reasonable (e.g., 30 days) to reduce storage cost.
- Make sure the shim-audit workflow uploads the machine-readable artifact at:
  - `dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json`
  - This allows reviewers to download and inspect details when a check fails.
- Ensure the shim-audit workflow runs on:
  - `push` to the branch (so the check is available for the protection rule), and
  - `pull_request` targeting `develop`/`main` so PRs also get validated.
- Communicate to contributors: add a short note in the PR template (e.g. `.github/PULL_REQUEST_TEMPLATE/010-zsh-project.md`) reminding them that the `shim-audit` check is required and how to run the migration locally (`tools/migrate-to-redesign.sh --dry-run`).

Relevant guideline references
- Policy acknowledgement (required header): see `dot-config/ai/guidelines.md` (acknowledgement rules).
- Workflow & CI guidance: see `dot-config/ai/guidelines/050-workflow-guidelines.md`.
- Security considerations for CI gating and artifacts: see `dot-config/ai/guidelines/100-security-standards.md`.

If you want, I will:
- Draft an admin-friendly checklist you can paste into the repo's operations docs that includes the exact `contexts` string to use (I can generate it after a shim-audit run if you want the precise check name).
- Draft the short PR-template note reminding contributors about the shim-audit gate.