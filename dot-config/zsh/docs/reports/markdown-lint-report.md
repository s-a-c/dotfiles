# Markdown Lint Report — zsh/docs (partial)

## Top


Generated: 2025-10-07T00:00:00Z
Scope: zsh/docs (non-ARCHIVE files)

## Summary

This report aggregates link & anchor issues discovered during the repository-wide link-existence mapping pass (see `link-existence-map.json`). It is a lightweight markdown-lint-like verification focused on:

- Missing internal anchors referenced by `[Top](#top)`
- Absolute filesystem references pointing outside the workspace
- Placeholder/stub pages referenced by indexes
- External links (listed but not HTTP-checked here)


## Findings

### Missing Anchors

The following files reference `[Top](#top)` (or equivalent) but do not contain a matching `#top` heading. Recommendation: either add a top-level anchor heading (e.g., `# Top`) or replace the link with a valid anchor.

- `docs/400-redesign/040-implementation-guide.md` — `[Top](#top)` referenced; missing `#top` heading
- `docs/400-redesign/000-index.md` — `[Top](#top)` referenced; missing `#top` heading
- `docs/400-redesign/010-implementation-plan.md` — `[Top](#top)` referenced; missing `#top` heading
- `docs/400-redesign/020-symlink-architecture.md` — `[Top](#top)` referenced; missing `#top` heading
- `docs/400-redesign/030-versioned-strategy.md` — `[Top](#top)` referenced; missing `#top` heading
- `docs/250-next-steps/010-next-steps-implementation-plan.md` — `[Top](#top)` referenced; missing `#top` heading


### Absolute filesystem references (outside workspace)

These references point at absolute paths that lie outside the workspace; the automated verifier cannot read them. If these must be validated, open the referenced files or include the target folder in the workspace.

- `/Users/s-a-c/dot-config/ai/guidelines.md` referenced from multiple files (400-redesign documents).
  - Files: `docs/400-redesign/*` (multiple files)
  - Status: outside-workspace-unverifiable


### Stubs and placeholder pages

Several index entries link to stub pages (created intentionally to satisfy navigation). They should be expanded later, but are valid targets:

- `docs/100-development-tools.md` — STUB
- `docs/110-productivity-features.md` — STUB
- `docs/120-terminal-integration.md` — STUB
- `docs/130-history-management.md` — STUB
- `docs/140-completion-system.md` — STUB


### External links

External links were detected but not HTTP-checked in this pass. They are reported as "external-not-checked" in `link-existence-map.json`.

Notable external references (examples):

- `https://github.com/unixorn/zsh-quickstart-kit`
- `https://github.com/jandamm/zgenom`
- Many others in nested docs (AI docs and third-party project docs)


## Recommendations (next actions)

1. Fix missing `#top` anchors (trivial): add a `# Top` heading near the top of each document that references `[Top](#top)`, or replace the `Top` link to a valid heading.
2. Decide how to handle absolute repository filesystem references to `ai/guidelines.md`:
   - Option A: include the `ai/` folder in this verification run so those references can be validated.
   - Option B: keep them marked as "outside-workspace" and manually verify by reviewers.
3. Expand STUB pages in priority order (100–140) to provide minimal, helpful content.
4. Optionally perform live HTTP checks against all external links (slower, network required).


## Artifacts

- Primary mapping: `docs/reports/link-existence-map.json`
- This lint report: `docs/reports/markdown-lint-report.md`



---
End of report.
