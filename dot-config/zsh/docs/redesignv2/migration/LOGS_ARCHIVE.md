dot-config/zsh/docs/redesignv2/migration/LOGS_ARCHIVE.md

Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

Purpose
-------
Document the plan to remove heavy historical logs from the repository, archive them as workflow artifacts (or an external object store), and keep the repo small and reviewable. This file explains the archive location options, the exact removal steps to perform locally (and in CI), verification steps, rollback plan, and the recommended commit and workflow templates.

Scope
-----
- Files under: `dot-config/zsh/logs/**` and other large historical test/perf artifacts accidentally committed.
- Preserve: a small, curated set of recent logs / summary artifacts required for migration documentation (explicitly enumerated).
- Archive target: GitHub Actions artifacts for immediate access + (recommended) long-term storage in an object store (S3/GCS/Artifactory) if retention beyond actions retention is required.

Policy citations
----------------
- This plan follows repository guidelines and security practices. See: rule [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:1)
- Policy acknowledgement (must be present in AI-authored artifacts and commit messages):
  Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

High-level approach
-------------------
1. Create Archives (one-time): produce time-stamped compressed tar archives (gz) of the heavy `logs/` tree and any other large artifacts.
2. Upload Archives as CI artifacts and copy to long-term storage (optional).
3. Remove large files from the Git history branch snapshot (soft removal in current branch): `git rm` the files, commit a small "prune logs" commit, and push.
4. Update `.gitignore` to prevent future accidental commits.
5. Add a short `LOGS_ARCHIVE.md` (this file) to document where archives live and how to restore if needed.
6. Optionally, perform a history rewrite if you must remove the blobs from earlier commits (NOT recommended without explicit coordination and review).

Why this pattern
----------------
- Keeps the migration branch small and fast to fetch/review.
- Preserves artifacts as accessible workflow artifacts for reviewers.
- Avoids destructive history rewrite by default; we only remove logs in head commits and keep an archival trace.
- Provides auditability: archives are time-stamped and stored outside the main tree.

Archive naming and retention
----------------------------
- Archive filename pattern: `zsh-logs-<branch>-YYYYMMDDTHHMMSSZ.tar.gz`
  - Example: `zsh-logs-feature-zsh-refactor-configuration-20250908T215221Z.tar.gz`
- GitHub Actions upload: artifacts retained for N days (set per-workflow; default 7–90).
- Recommended retention:
  - CI upload: 30 days (quick access for reviewers).
  - Long-term: copy to S3/GCS with lifecycle policy (retain 365 days, archive to Glacier or Nearline after 90 days).
- Include a small `MANIFEST.md` inside each archive describing contents + generation commit SHA.

Local steps — produce archive (example)
---------------------------------------
1. From repo root:
   - Create a temporary archive workspace:
     - `mkdir -p /tmp/zsh-logs-archive && cd /tmp/zsh-logs-archive`
   - Create a tarball of the logs you want to archive:
     - `tar -czf ~/zsh-logs-$(git rev-parse --abbrev-ref HEAD)-$(date -u +"%Y%m%dT%H%M%SZ").tar.gz -C /path/to/repo dot-config/zsh/logs`
       - Replace `/path/to/repo` with the working repo path (e.g., `~/dotfiles`).
   - Generate a MANIFEST:
     - `cat > MANIFEST.md <<EOF
       branch: $(git rev-parse --abbrev-ref HEAD)
       commit: $(git rev-parse --short HEAD)
       generated_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
       files: $(tar -tzf ~/zsh-logs-*.tar.gz | wc -l)
       EOF`
   - Verify the archive:
     - `tar -tzf ~/zsh-logs-*.tar.gz | head -n 20` (inspect sample entries)
     - `sha256sum ~/zsh-logs-*.tar.gz` (record checksum in MANIFEST.md)

Local steps — remove heavy logs from branch (example)
----------------------------------------------------
1. Ensure you are on the correct branch:
   - `git checkout feature/zsh-refactor-configuration`
2. Commit the archive artifact lines (optional):
   - If you wish to include a pointer file: `echo "archived: zsh-logs-<...>.tar.gz" > dot-config/zsh/docs/redesignv2/migration/ARCHIVE_POINTER.md`
   - `git add dot-config/zsh/docs/redesignv2/migration/ARCHIVE_POINTER.md && git commit -m "docs: add archive pointer for heavy logs (see LOGS_ARCHIVE.md)" && git push`
3. Remove logs from working tree (do not rewrite history here):
   - `git rm -r --cached dot-config/zsh/logs || true`   # remove from index while keeping local files
   - `git commit -m "chore: remove heavy historical logs from repo; archive created\n\nCompliant with /Users/s-a-c/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49"`
   - `git push origin feature/zsh-refactor-configuration`
4. Add `dot-config/zsh/logs/` to `.gitignore` (if not already present) and commit:
   - Add safe allowlist for small curated logs you want retained (e.g., `docs/redesignv2/artifacts/metrics/shim-audit.json`) by explicitly tracking them.
   - Example `.gitignore` addition:
     ```
     # ignore ZSH logs (archived separately)
     dot-config/zsh/logs/*
     !dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json
     !dot-config/zsh/docs/redesignv2/artifacts/*.json
     ```
   - Commit: `git add .gitignore && git commit -m "chore: ignore heavy zsh logs; keep curated metrics files" && git push`

CI workflow to upload archives and remove logs automatically (example)
---------------------------------------------------------------------
- Add a small workflow `.github/workflows/archive-logs.yml` that:
  - Runs on push to the branch or manually.
  - Creates a tar.gz of `dot-config/zsh/logs`.
  - Uploads it as an artifact.
  - Optionally copies the tarball to S3/GCS using secrets (preferred for long-term storage).

Example job snippet (copy into a workflow file as appropriate):
```yaml
name: Archive heavy logs
on:
  workflow_dispatch:
  push:
    branches:
      - feature/zsh-refactor-configuration

jobs:
  archive-logs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create archive
        run: |
          ARCHIVE_NAME="zsh-logs-${{ github.ref_name }}-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
          tar -czf "$ARCHIVE_NAME" dot-config/zsh/logs || true
          echo "$ARCHIVE_NAME" > archive-name.txt
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: zsh-logs-${{ github.ref_name }}
          path: ${{ env.WORKSPACE }}/$ARCHIVE_NAME
          retention-days: 30
      - name: Optional: Copy to S3 (if required)
        if: env.S3_BUCKET != ''
        env:
          AWS_S3_BUCKET: ${{ secrets.ARCHIVE_S3_BUCKET }}
        run: |
          # Example: aws s3 cp "$ARCHIVE_NAME" s3://$AWS_S3_BUCKET/archives/
          echo "Copy to S3 would run here using configured secrets"
```

Notes about handling large historical files already committed
-----------------------------------------------------------
- We did a non-destructive removal above (we removed files from index and added them to `.gitignore`). This leaves the historical blobs in the repository history but keeps the branch head small.
- If you MUST remove the binary blobs from the repository history (to reduce clone size), that is a sensitive operation and requires:
  - Team coordination (it rewrites history).
  - Using `git filter-repo` or BFG to remove blobs, then force-pushing to all affected branches.
  - Updating any CI/deployment systems that use old SHAs.
  - This action is sensitive and must cite policy rules (see policy citation above) — do not perform without explicit approvals.
- Recommended safer flow: do not rewrite history unless the repo size is blocking.

Verification
------------
After the removal commit:
- `git ls-files | grep dot-config/zsh/logs || true` — should not list log files (except any allowlisted curated artifacts).
- CI workflow run should show `archive-logs` artifact available in the Actions UI (verify artifact name and checksum).
- Inspect the uploaded artifact (download from Actions) and validate:
  - `tar -tzf <artifact> | head -n 20`
  - `sha256sum <artifact>` matches the checked SHA.

Rollback
--------
- If you removed log files from the index and want them back:
  - If you kept local copies: `git checkout -- dot-config/zsh/logs` restores from working tree state.
  - If you committed removal and pushed, but want to restore the files in head:
    - Restore from the archive: download artifact or archive from long-term store, extract into `dot-config/zsh/logs/`, then `git add` and commit a restoration commit describing why.
- If you require full historical restoration, use `git reflog` and `git checkout <old-commit>` to recover prior state (requires care).

Commit message guidance
-----------------------
- Use a short subject + longer body, include the policy acknowledgement header exactly:
  ```
  chore: remove heavy historical logs from repo; archive created

  - Created archive: zsh-logs-<branch>-<timestamp>.tar.gz uploaded as Actions artifact
  - Removed `dot-config/zsh/logs/*` from index and added to .gitignore
  - Kept curated artifacts: dot-config/zsh/docs/redesignv2/artifacts/metrics/*
  - To restore: download artifact from Actions or S3 and re-add to working tree

  Compliant with /Users/s-a-c/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
  ```

Security considerations
-----------------------
- Ensure that archived logs do not contain secrets before uploading to any external store. Scan archives for keywords (`password`, `secret`, `token`, `key`) prior to upload.
- If logs contain sensitive information, redact or redact-by-filter before archiving and storing externally. See rule [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:1).
- Limit access to archived storage with IAM policies and short-lived credentials.

Follow-up: shim audit gating (how to re-run)
---------------------------------------------
To demonstrate CI gating behavior, re-run the shim audit with "fail on shims" enabled:
- Locally:
  - `SHIM_AUDIT_FAIL_ON_SHIMS=1 ./tools/bench-shim-audit.zsh --output-json dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json --fail-on-shims`
  - Expected: exit code 2 if any shims are present; the JSON will still be produced.
- In CI:
  - Add a job step in `redesign-flagged.yml` or a separate gating workflow:
    ```yaml
    - name: Run shim audit and fail on shims
      run: |
        SHIM_AUDIT_FAIL_ON_SHIMS=1 $ZDOTDIR/tools/bench-shim-audit.zsh --output-json $ZDOTDIR/docs/redesignv2/artifacts/metrics/shim-audit.json --fail-on-shims
    ```
  - Configure the job to prevent merges when the job fails.

Recommended next actions (pick one)
----------------------------------
- I can prepare a small commit that:
  - Creates `dot-config/zsh/docs/redesignv2/migration/ARCHIVE_POINTER.md` referencing the artifact name and checksum.
  - Removes `dot-config/zsh/logs/*` from the index (`git rm --cached`) and adds `.gitignore` entries.
  - Leaves curated metrics (e.g., `shim-audit.json`) tracked.
- I can add the `archive-logs.yml` GitHub Actions workflow to the repository and open a PR.
- I can run `bench-shim-audit.zsh` locally with `SHIM_AUDIT_FAIL_ON_SHIMS=1` and paste the output in a follow-up message (I will not modify the repo in that step).

Notes about this change
-----------------------
- This is a non-destructive, conservative approach: it avoids history rewrites, keeps artifacts available to reviewers, and reduces the chance of accidental future commits of heavy logs.
- If you require aggressive repo shrink (removing blobs from history), notify the team and coordinate a maintenance window — I will draft an exact policy-reviewed plan for rewrite and force-push.

End of document