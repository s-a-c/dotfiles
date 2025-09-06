Compliant with [/Users/s-a-c/dot-config/ai/guidelines.md](/Users/s-a-c/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

<!--
  PR title guidance: Use one of `feat/`, `fix/`, `docs/`, `chore/` followed by a short summary.
  Replace the acknowledgement header above with the exact checksum when available.
-->

# Pull Request

## Purpose
Briefly describe why this change is needed and what problem it solves.

## Summary of changes
- List the main changes in short bullets (files and behavior).
  - Added `path/to/new_file` to handle ...
  - Updated `path/to/modified_file` to validate ...
  - Removed deprecated usage of `some_old_code`

## Background / Context
Connect this change to higher-level goals or linked issue(s).
- Closes: #<issue-number> (if applicable)
- Relevant discussion or design docs: link to docs or issues

## Implementation notes
- Key design decisions and trade-offs.
- Notable third-party libraries or versions used (and why).
- Any database schema/config changes required.

## Testing
- Unit tests: list added/updated tests and their paths.
- Integration/manual tests: steps you ran to verify behavior locally.
  1. Step one
  2. Step two
- CI: expected checks (e.g., `lint`, `unit`, `integration`)

## Rollout / Deployment plan
- Feature flags, migrations, and scheduling notes.
- Expected downtime (if any) and mitigation steps.
- Steps to verify a successful rollout.

## Backward compatibility & Migration
- Call out breaking changes explicitly.
- Provide migration steps or scripts (if applicable).

## Risks & Mitigations
- Main risks and how to mitigate them (revert steps, toggles, monitoring).

## Notes for reviewers
- Suggested starting point(s) in the diff (key files).
- Key focus areas: security, performance, UX, accessibility, etc.
- Any follow-ups planned in subsequent PRs.

---

### Checklist
- [ ] PR title follows repo convention
- [ ] I have linked related issue(s): Closes #<issue-number>
- [ ] I have added/updated unit tests and they cover the relevant behavior
- [ ] All tests pass locally and in CI (`lint`, `unit`, `integration`)
- [ ] I have manually tested the main flows and documented steps in `Testing`
- [ ] I have updated documentation where applicable (`README.md`, `docs/`, `CHANGELOG.md`)
- [ ] I have added migration scripts and documented migration steps (if needed)
- [ ] I have added a rollback plan in the PR description
- [ ] I have requested the appropriate reviewers and owners
- [ ] I have run security and dependency scans and addressed warnings
- [ ] Acknowledgement header included: “Compliant with [/Users/s-a-c/dot-config/ai/guidelines.md](/Users/s-a-c/dot-config/ai/guidelines.md) v<checksum>” (replace <checksum> with the computed value)

### Recommended reviewers
- Code owners: `@owner1`, `@owner2`
- Domain experts: `@frontend`, `@backend`
- QA: `@qa-person`

<!--
  How to compute and insert the required guidelines checksum (manual steps):

  1. Gather these sources in this exact order:
     - `/Users/s-a-c/dot-config/ai/guidelines.md`
     - All files under `/Users/s-a-c/dot-config/ai/guidelines/**` sorted by path
  2. Concatenate their raw contents in that order (no separators).
  3. Compute the SHA256 hexdigest of the concatenated bytes.
  4. Replace the placeholder `v<UNCOMPUTED — replace with computed checksum>` above with `v<sha256-hexdigest>`.

  Notes:
  - The project policy requires this acknowledgement header in AI-authored artifacts.
  - If you want me to insert the computed checksum, provide the computed SHA256 value or grant access to the guideline files and I will update the header.
-->
