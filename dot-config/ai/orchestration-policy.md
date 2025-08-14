# Orchestration Policy

Compliant with [.ai/guidelines.md](.ai/guidelines.md) v<computed at runtime by scripts/policy-check.php>

Purpose
- Define orchestration requirements so every AI task loads and enforces project policies from `.ai/guidelines.md` and `.ai/guidelines/`.

Scope
- Applies to all AI-authored changes, CI executions, and local pre-commit validations.

Requirements
1) Policy Context Injection
   - Agents MUST load:
     - `.ai/guidelines.md`
     - All files under `.ai/guidelines/**`
   - Agents MUST compute and expose in their context:
     - guidelinesChecksum (sha256 over ordered concatenation of all guideline sources)
     - lastModified:
       - master: mtime of `.ai/guidelines.md`
       - modules: max mtime across `.ai/guidelines/**`
     - guidelinesPaths: list of included files
   - Agents MUST include these in their logs and confirm loaded versions before performing changes.

2) Policy Acknowledgement
   - AI tasks MUST include an acknowledgement header in the artifacts they author:
     - “Compliant with [.ai/guidelines.md](.ai/guidelines.md) v<checksum>”
   - The checksum MUST match the current composite checksum at authoring time.

3) Sensitive Actions Rule Citation
   - When performing sensitive actions (security-affecting, code execution, external access, CI configuration), agents MUST cite the exact rules used with clickable references:
     - Example: rule [.ai/guidelines/security.md](.ai/guidelines/security.md:42)

4) Drift Detection
   - If guidelines checksum changes since the last recorded run, agents MUST re-acknowledge before proceeding.
   - CI and pre-commit will fail if drift is detected without updated acknowledgement.

5) Enforcement
   - This policy is enforced by:
     - CLI validator: `php scripts/policy-check.php`
     - Pre-commit hook
     - GitHub Actions workflow
   - Violations produce actionable, clickable output and non‑zero exit status.

Notes
- Keep implementation self-contained; no external dependencies.
- All references should be presented as clickable `[file](file:line)` links for developer ergonomics.