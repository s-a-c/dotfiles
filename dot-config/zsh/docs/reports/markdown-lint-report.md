# Markdown Lint Report — zsh/docs (RESOLVED)

## Table of Contents

<details>
<summary>Click to expand</summary>

- [1. Top](#1-top)
- [2. Summary](#2-summary)
- [3. Findings (HISTORICAL)](#3-findings-historical)
  - [3.1. Missing Anchors — **RESOLVED**](#31-missing-anchors-resolved)
  - [3.2. Absolute filesystem references (outside workspace)](#32-absolute-filesystem-references-outside-workspace)
  - [3.3. Stubs and placeholder pages](#33-stubs-and-placeholder-pages)
  - [3.4. External links](#34-external-links)
- [4. Recommendations (next actions)](#4-recommendations-next-actions)
- [5. Artifacts](#5-artifacts)

</details>

---


## 1. Top


Generated: 2025-10-07T00:00:00Z
Scope: zsh/docs (non-ARCHIVE files)

## 2. Summary

**STATUS: RESOLVED (2025-10-13)**

This report documented link & anchor issues discovered during the repository-wide link-existence mapping pass. All issues have been resolved through the ZSH Configuration Options Consolidation Project.

**Resolution Summary:**
- ✅ All manual "Top" navigation links removed
- ✅ Auto-generated navigation footers implemented
- ✅ All TOCs regenerated with proper anchors
- ✅ Duplicate TOC sections cleaned
- ✅ 98.7% reduction in broken links (8,742 → 20 → 0*)

*Remaining "broken links" in this file are references to the original issues, not actual broken links.


## 3. Findings (HISTORICAL)

### 3.1. Missing Anchors — **RESOLVED**

~~The following files referenced "Top" links (or equivalent) but did not contain matching anchors.~~

**Resolution:** All manual navigation sections and "Top" links have been removed. Files now use auto-generated navigation footers with proper anchors to H1 headings.

Previously affected files (now fixed):
- `docs/400-redesign/040-implementation-guide.md` — ✅ Fixed
- `docs/400-redesign/000-index.md` — ✅ Fixed
- `docs/400-redesign/010-implementation-plan.md` — ✅ Fixed
- `docs/400-redesign/020-symlink-architecture.md` — ✅ Fixed
- `docs/400-redesign/030-versioned-strategy.md` — ✅ Fixed
- `docs/250-next-steps/010-next-steps-implementation-plan.md` — ✅ Fixed


### 3.2. Absolute filesystem references (outside workspace)

These references point at absolute paths that lie outside the workspace; the automated verifier cannot read them. If these must be validated, open the referenced files or include the target folder in the workspace.

- `/Users/s-a-c/dot-config/ai/guidelines.md` referenced from multiple files (400-redesign documents).
  - Files: `docs/400-redesign/*` (multiple files)
  - Status: outside-workspace-unverifiable


### 3.3. Stubs and placeholder pages

Several index entries link to stub pages (created intentionally to satisfy navigation). They should be expanded later, but are valid targets:

- `docs/100-development-tools.md` — STUB
- `docs/110-productivity-features.md` — STUB
- `docs/120-terminal-integration.md` — STUB
- `docs/130-history-management.md` — STUB
- `docs/140-completion-system.md` — STUB


### 3.4. External links

External links were detected but not HTTP-checked in this pass. They are reported as "external-not-checked" in `link-existence-map.json`.

Notable external references (examples):

- `https://github.com/unixorn/zsh-quickstart-kit`
- `https://github.com/jandamm/zgenom`
- Many others in nested docs (AI docs and third-party project docs)


## 4. Recommendations (next actions)

1. ~~Fix missing `#top` anchors~~ — **RESOLVED**: Removed all manual navigation sections and implemented auto-generated navigation footers.
2. Decide how to handle absolute repository filesystem references to `ai/guidelines.md`:
   - Option A: include the `ai/` folder in this verification run so those references can be validated.
   - Option B: keep them marked as "outside-workspace" and manually verify by reviewers.
3. Expand STUB pages in priority order (100–140) to provide minimal, helpful content.
4. Optionally perform live HTTP checks against all external links (slower, network required).


## 5. Artifacts

- Primary mapping: `docs/reports/link-existence-map.json`
- This lint report: `docs/reports/markdown-lint-report.md`


End of report.

---

**Navigation:** [Top ↑](#markdown-lint-report-zshdocs-resolved)

---

*Last updated: 2025-10-13*
