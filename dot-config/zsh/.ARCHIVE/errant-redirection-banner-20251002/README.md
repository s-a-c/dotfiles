# Archived Errant Redirection Banner (Forensic Artifact)

Date Archived: 2025-10-02  
Archive Path: `.ARCHIVE/errant-redirection-banner-20251002/2`  
Tracking Tag: `GOV-STRAY-ARTIFACTS-2025-10-02`  

---

## 1. Summary

This archive contains a single file originally found at the root of the ZSH configuration repository named literally: `2`

File contents (verbatim):

```
# ++++++++++++++++++++++++++++++++++++++++++++++
```

The file has no executable context, shebang, trailing commentary, or functional logic. It is a classic banner / separator line fragment. Its existence at repository root indicates a redirection misuse rather than an intentional tracked asset.

---

## 2. Root Cause (Most Probable)

One of the following shell patterns likely produced this file:

| Pattern | Intended Meaning | Actual Result |
|---------|------------------|---------------|
| `echo "# +++++" > 2` | (Mistaken attempt to write to file descriptor 2 / stderr) | Creates a regular file named `2` |
| `some_command > 2` | (Mistaken attempt to redirect stderr: should be `2>`) | Redirects stdout into a file named `2` |
| `printf "...banner..." > $FD` with `FD=2` (unquoted logic bug) | Write to FD 2 | Writes to a file if variable expansion occurred in an unsafe context |
| Partially copied heredoc or banner template | Provide visual log segmentation | Truncated placeholder persisted as a standalone file |

Key distinction:
- To address stderr explicitly, the correct idioms are:
  - `echo "message" >&2`
  - `command 2>error.log`
  - `command >out.log 2>&1`

Any whitespace or omission (e.g. `> 2`) is parsed as "redirect stdout into a regular file named 2".

---

## 3. Why Preserve It?

Governance requires forensic retention of unexpected artifacts until:
1. They are documented with origin hypothesis and mitigation.
2. Prevention controls are in place (now covered by the stray artifact detector and governance rules).
3. Their removal or purge can be justified without obscuring historical state.

This README fulfills (1); the newly instituted detector and policy fulfill (2).

---

## 4. Governance & Policy References

- "Stray Artifact Governance" section in `docs/fix-zle/plan-of-attack.md` (added 2025-10-02).
- Preventative Hardening Measures table (same document).
- Detector Script: `tools/detect-stray-artifacts.zsh` (CI will fail on reintroduction of root-level numeric files).

Policy: Root-level pure-numeric filenames are disallowed unless:
- They belong to a sanctioned manifest format
- They accompany a formal documentation entry (not applicable here for active usage)

---

## 5. Forensic Handling Rules

| Action | Allowed? | Notes |
|--------|----------|-------|
| Modify contents | No | Immutable archive principle |
| Delete file | Not without governance PR | Must update plan-of-attack with removal rationale |
| Reintroduce a similar root file | Disallowed | Detector enforces |
| Use as template | Not recommended | Recreate banners explicitly in source files |

---

## 6. Prevention Mechanisms Now Active

1. Stray Artifact Detector  
   - Scans for root-level names matching `^[0-9]+$`.
   - Exits non-zero in CI if violations found.

2. Redirection Lint (Planned)  
   - Pattern search for `> 2([^0-9]|$)` to catch misuse.

3. Engineering Guidelines  
   - Always use `>&2` for stderr writes.
   - For split streams: `command >out.log 2>err.log` or `command >out.log 2>&1`.

4. Code Review Checklist Addendum  
   - "No accidental numeric root files" item appended (pending if not yet integrated).

---

## 7. Recovery / Triage Procedure (If Similar File Reappears)

1. Run detector:  
   `zsh/tools/detect-stray-artifacts.zsh --json`
2. Inspect recent commit diffs for shell script modifications with redirections.
3. Grep candidate patterns:  
   `grep -R --line-number -E '> 2($|[^0-9])' zsh/tools`
4. If a script attempted fancy formatting on stderr, patch to:
   `printf '%s\n' '--- banner ---' >&2`

---

## 8. Optional Next Steps (If Further Auditing Required)

| Step | Purpose | Effort |
|------|---------|--------|
| Introduce shellcheck rule gating redirection misuse | Automated catch | Medium |
| Add pre-commit hook for numeric root detection | Early dev feedback | Low |
| Collect frequency metric of stderr banners (for formatting standardization) | Consistency | Low |
| Add style guide section for logging / banners | Developer clarity | Low |

---

## 9. Disposition

STATUS: Archived (Write-Once)  
No functional dependency. Safe to retain indefinitely or prune later with explicit governance removal record.

---

## 10. Addendum (Future Notes)

(None yet)

If origin is conclusively traced (e.g., to a specific commit or script), append:
- Commit hash
- Script name
- Correction commit link

---

Maintainer Acknowledgement:
This artifact requires no further action unless new numeric files appear or a policy change mandates cleaning historical archives.
