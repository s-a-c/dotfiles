# Secret History Rewrite Plan

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

Sensitive action: repository history rewrite to purge environment / secret material.

Policy rule citations (security automation, least privilege, incident handling):
- Security standards core principle [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:1)
- Maintainability & clarity for security implementations (lines 3-8) [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:3)
- Security event logging practices (lines 205-212) [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:205)
- Incident response & remediation (lines 233-242) [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/100-security-standards.md:233)

## 1. Objective

Permanently remove sensitive environment files and directories from all reachable git history while preserving unrelated history integrity and enabling collaborators to safely realign with the rewritten main branch.

## 2. In-Scope Secret Material (to DELETE, not redact)

Paths (relative to repo root):
- dot-config/zsh/.env/api-keys.env
- dot-config/zsh/.env/development.env
- dot-config/zsh/.env/   (entire directory; supersedes individual files)

Rationale: Environment configuration and key material do not belong in version control; future presence prevented via updated .gitignore patterns (`.env/`, `**/.env/`).

## 3. Out-of-Scope

- Any already rotated credential values appearing ONLY inside the above paths (removal suffices).
- Build artifacts and logs (already ignored).
- Binary blobs unrelated to secret distribution.

## 4. Strategy Decision

Chosen approach: Surgical path excision (invert-paths) without whole‑repo squash. This keeps meaningful commit history for non-secret changes, minimizing repository churn and rebasing burden.

Alternative (not chosen): Full single-commit squash. Rejected because it destroys granular history helpful for auditing/config evolution.

## 5. Preconditions (MUST complete before rewrite)

1. Credential Rotation: All keys inside the removed files are assumed compromised and rotated (issue tracker entry or internal log referencing timestamp).
2. Merge Freeze: Temporarily block or pause merging to `main` until rewrite + force push complete.
3. Local Clean Workspace: Ensure no uncommitted work. Stash or commit elsewhere.
4. Backup Mirror Clone (defense against mistakes).
5. Communication Plan prepared (template message to collaborators).

### 5.1 Backup Commands

Perform a bare mirror (includes refs, tags, notes):
`git clone --mirror <git_url> repo-mirror.git`

Optional working backup:
`git clone <git_url> repo-backup`

Verify target paths exist historically:
`git log --oneline -- dot-config/zsh/nc/.env/ | head`

## 6. Secret Presence Assessment (Metrics)

Count commits touching sensitive directory:
`git log --oneline -- dot-config/zsh/nc/.env/ | wc -l`

List most recent modifying commits (audit trail):
`git log -n 5 --name-only -- dot-config/zsh/nc/.env/`

(Record counts here after running.)

## 7. Rewrite Execution

Tool: `git filter-repo` (preferred over legacy filter-branch for reliability & speed).
Install (if missing): `pip install git-filter-repo` or `brew install git-filter-repo`.

Core command (path excision):

`git filter-repo --force --invert-paths \`
`  --path dot-config/zsh/.env/api-keys.env \`
`  --path dot-config/zsh/.env/development.env \`
`  --path dot-config/zsh/.env/`

Ordering note: Listing individual files before the directory is harmless; the final directory rule removes remaining content and directory metadata.

Tags: By default filter-repo rewrites tags referencing affected commits. No extra flag required unless selectively preserving specific tags.

## 8. (Optional) Hybrid Redaction Mode

If later you need to retain a file name but blank content historically, instead of removing the directory you would:
1. Restore the directory (revert the inverse removal).
2. Add literal or regex entries to `replacements.txt`.
3. Run `git filter-repo --force --replace-text replacements.txt --path <retained-file>` (exclude `--invert-paths` for kept files).

## 9. Post-Rewrite Validation

Confirm directory gone:
`git log -- dot-config/zsh/nc/.env/ | head -1 || echo "No commits reference directory (expected)."`

Confirm working tree has no tracked .env content:
`git ls-files | grep -E '^dot-config/zsh/nc/.env/' || echo "No tracked .env paths"`

Grep for high-risk markers (add key fragments if known):
`git grep -F 'API_KEY=' || echo 'API_KEY= not present'`

Ensure HEAD build unaffected (if repo has build/test pipelines).

## 10. Local Repo Hygiene (Garbage Collection)

Expire reflogs & prune dangling objects so secrets become unreachable locally:
`git reflog expire --expire=now --all`
`git gc --prune=now --aggressive`

(Note: Remote platforms like GitHub perform their own pruning; leaked blobs may persist in forks & clones.)

## 11. Force Push & Branch Realignment

Push rewritten history (main):
`git push --force-with-lease origin main`

If additional protected branches also contained the directory repeat rewrite on them OR perform the rewrite once on an integration branch and fast-forward others after verification.

### Collaborator Instructions

For contributors with existing local clones:
`git fetch origin`
`git checkout main`
`git reset --hard origin/main`
`git clean -fd`

(If they had local topic branches based on old history they should `git rebase --onto origin/main <old_base_commit> <topic_branch>` or cherry-pick.)

## 12. Downstream & Fork Considerations

- Public forks retain old objects; request fork owners to sync or re-fork.
- If any secrets were *credentials* (not just configs) they are already invalidated (Step 5). Keep rotation evidence (internal ticket ID).

## 13. Monitoring & Logging Alignment

Update security log (referencing security standards logging guidance lines 205‑212) with:
- Timestamp of rewrite
- Responsible engineer
- Checklist results (Sections 5, 9, 11)
- Confirmation of credential rotation

## 14. Incident Response Closure

Reference incident response guidelines (lines 233‑242) to ensure:
- Post-incident review performed
- Root cause categorized (process gap vs. human error vs. tooling)
- Preventive control (secretScan workflow + improved .gitignore) documented

## 15. Integration with Automated Secret Scanning

A `secretScan` GitHub Action now runs on PRs & pushes to catch future secret introductions early. This is complementary (not a substitute) for local pre-commit scanning if you later add it.

Recommended enhancement: Add a local pre-commit hook using `gitleaks protect` or a lightweight custom grep to block secrets before commit.

## 16. Rollback Procedure (Emergency)

If an unforeseen critical corruption is discovered immediately after force push:
1. Disable merges temporarily.
2. Use the mirror clone (`repo-mirror.git`) to restore: `git push --force-with-lease origin <old_sha>:refs/heads/main`
3. Re-evaluate filters, adjust plan, re-run rewrite.

## 17. Timeline Template

| Step | Description | Target Owner | Timestamp |
|------|-------------|--------------|-----------|
| Rotation | Rotate credentials | Security | |
| Backup | Mirror clone created | DevOps | |
| Freeze | Merge freeze initiated | Maintainer | |
| Rewrite | filter-repo executed | Engineer | |
| Validate | Post checks (Section 9) | Engineer | |
| Push | Force push main | Maintainer | |
| Notify | Collaborators instructed | Maintainer | |
| Close | Incident log updated | Security | |

## 18. Approval

List approvers (names / emails) here before executing rewrite.

---

End of plan.