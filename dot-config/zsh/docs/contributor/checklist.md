# Contributor Checklist (ZSH Redesign)

This checklist is the authoritative quick-reference for contributing to the ZSH redesign. It encodes enforceable rules (guarded by CI) plus best practices that keep the codebase stable, fast, and maintainable.

---

## 1. Path Resolution (MANDATORY)

Rule: Do NOT use the brittle form ${0:A:h} (or ${0:a:h}) directly in any non‑test script.

Why: Plugin managers (e.g. zgenom) may compile or source code in a context where $0 points to a temporary wrapper or compilation stub. This causes incorrect path derivation.

Use instead (preference order):
1. zf::script_dir "${(%):-%N}"  (namespaced helper – preferred once functions loaded)
2. resolve_script_dir "${(%):-%N}" (bootstrap-safe helper)
3. Fallback: ${(%):-%N:h} ONLY in extremely early bootstrap if neither helper is available (document with comment LAST RESORT) – avoid adding new instances unless justified.

Do not re-implement your own path math (e.g. nested dirname calls, manual ${0:h} chains).

Suppression:
Add trailing comment # ALLOW_0_A_H ONLY if the usage cannot be refactored (should be rare; expect PR discussion).

Enforcement:
tools/enforce-path-resolution.zsh runs early in CI (path-enforcement job). Any violation fails the build.
Strict mode: pass --strict to also flag raw ${(%):-%N:h} usage outside helpers (unless the line ends with # ALLOW_STRICT_PATH). Use for progressive tightening or audits.
Helper verification: tools/verify-path-helpers.zsh --assert both --json confirms both helpers resolve consistently (use --allow-mismatch during investigations).
Strict suppression: use # ALLOW_STRICT_PATH only when unavoidable and document rationale in the PR.

---

## 2. Shell Style & Formatting

Audited by: tools/style-audit-shell.sh (produces JSON + badge).

Core rules (enforced / visible in badge):
- Indentation: 4 spaces (no hard tabs in tracked .zsh scripts).
- No trailing whitespace.
- Final newline present.
- Avoid unquoted command substitutions in assignments unless intentional.

Recommended (not yet hard-failed):
- Prefer set -euo pipefail (already standard in tooling scripts).
- Group logical sections with 80–100 char width soft wrap.
- Use lowercase for local temporary variables; ALL_CAPS for exported or environment-sensitive symbols.

Run locally:
dot-config/zsh/tools/style-audit-shell.sh --summary
Add --json --output artifacts/style.json for machine output.

---

## 3. Performance & Variance Expectations

Artifacts & tools:
- Baseline capture: tools/capture-baseline-10run.zsh or stage-specific harness scripts.
- Regression evaluation: tools/perf-regression-check.zsh (configurable tolerance percentage).
- Variance badge: tools/generate-preplugin-variance-badge.zsh (aggregates multiple Stage 3 baselines).
- Perf badge: tools/generate-perf-badge.zsh <tolerance_pct>

Principles:
- Keep added initialization under observed variance noise before declaring stable regressions.
- Tighten gates only after multiple nightly samples converge (variance harness will recommend).
- Avoid adding expensive instrumentation to always-loaded early phases—defer or lazy-load.

---

## 4. Badge Ecosystem

Badges typically live under:
docs/badges/ (general CI)
docs/redesign/metrics/ or docs/redesignv2/artifacts/{badges,metrics}/ (migration layout)

Current key badges:
- structure.json (module / drift status)
- perf.json (current vs baseline performance)
- summary.json (aggregated status)
- infra-health.json (infrastructure signals)
- infra-trend.json (trend severity)
- style.json (shell style audit)
- path-rules.json (path resolution violations count)
- preplugin-variance.json (startup variance quality)

Path Rules Badge specifics:
- Source: tools/enforce-path-resolution.zsh (early CI job before test matrix)
- Green criteria: violations == 0 (badge message: clean)
- Red criteria: violations > 0 (badge message: "<n> viol" and CI fails)
- Scope: Non-test .zsh scripts (tests, docs, .backups excluded unless --include-tests passed)
- Purpose: Ensures all new code uses zf::script_dir / resolve_script_dir helpers and prevents regression to brittle ${0:A:h}

Color semantics (default):
brightgreen = clean/stable
green = fixed (recovered) or acceptable
orange = mismatch / warning
red = regression / fail condition
lightgrey = unavailable / no-data

Do not hard-edit badge JSON manually; always regenerate via proper tool.

---

## 5. Test Categories

Invoke master runner:
tests/run-all-tests.zsh --category=<comma list>

Categories:
- design: Structural guarantees, drift detection, sentinel guards
- style: Lint-like enforcement (path resolution, style sub-harnesses, future plugin path guard test, optional strict helper audits)
- unit: Focused functional logic
- feature: Cross-cut behavior (lazy activation, integrations)
- integration: Larger multi-component flows
- security: Integrity and hashing behavior
- (future) perf: May graduate from tooling scripts when stabilized

Add new tests under the appropriate subdirectory; prefer names test-<topic>.zsh.

---

## 6. Suppression Mechanics

Path resolution:
- Use # ALLOW_0_A_H sparingly; justify in PR description.

Style:
- If a style rule is intentionally violated (rare), add an inline preceding comment explaining rationale (avoid permanent suppressions; prefer adjusting tooling if rule is misaligned).

Performance regression gates:
- Temporary soft pass may be allowed via documented environment variable (if such a mechanism is introduced). At the moment, rely on tolerance args where supported.

---

## 7. Migration Guidelines (Legacy → Redesign)

When refactoring a legacy script:
1. Replace direct ${0:A:h} or ${0:h} usage with helper.
2. Add set -euo pipefail near top if the script exits standalone (skip if pure sourced modular snippet and untested for strict mode).
3. Normalize indentation to 4 spaces.
4. Remove dead or commented-out legacy path math.
5. Localize variables (typeset / local) in functions to avoid namespace leakage.
6. Where a script previously exported ad hoc environment variables, evaluate scoping—prefer function-return or explicit export only where required.
7. Update documentation references or READMEs under docs/redesign if behavior semantics changed.

---

## 8. Quick PR Self-Review Checklist

Before opening / marking Ready:
[ ] No direct ${0:A:h} usage (search or run tool).
[ ] No stray debug echos or set -x left behind.
[ ] Style audit locally shows zero new violations.
[ ] Added / updated tests for new logic paths.
[ ] Badges that should change were regenerated (if relevant).
[ ] Performance impact minimal or justified (mention in PR).
[ ] README / relevant docs updated if user-facing change.
[ ] No silent broad catch blocks masking errors.
[ ] Path helpers used consistently (no hand-written dirname chains).
[ ] Variables intended for user environment export are explicitly exported (not implicitly relied upon).

---

## 9. Local Development Quickstart

From repo root:
1. cd dot-config/zsh
2. Run core design tests: tests/run-all-tests.zsh --category=design
3. Run broad suite: tests/run-all-tests.zsh --category=unit,feature,style
4. Generate structure audit: tools/generate-structure-audit.zsh
5. Path enforcement dry-run: tools/enforce-path-resolution.zsh --json
6. Verify helper presence: tools/verify-path-helpers.zsh --assert both --json

Fast grep for any forbidden pattern:
grep -R '${0:A:h}' . | grep -v tests || true

(Use single quotes around pattern to avoid shell expansion.)

---

## 10. Git Hooks & CI Integrity

CI validates:
- core.hooksPath must point to .githooks
- Presence of key hook scripts (pre-commit etc.)
- Hook status badge generated (hooks.json)

If you add new automation requiring a hook:
1. Place script in .githooks or .githooks/<hook>.d/
2. Keep hooks idempotent (safe to rerun).
3. Avoid long-running synchronous processes—defer with background tasks only if safe.

---

## 11. Script Patterns & Best Practices

Prefer functions over top-level imperative logic (except minimal initialization).
Use explicit return codes; avoid relying solely on set -e for semantic flow control.
Wrap subshell-heavy logic into helper functions to concentrate error handling.
Document non-trivial environment assumptions at the top (e.g., requires jq).

Variable guidelines:
UPPER_SNAKE for exported or cross-script configuration (declared early).
local / typeset for transient function-level state.
Avoid global mutation unless part of an intentional cached state.

---

## 12. Extending Enforcement (Future-Proofing)

Current strict mode coverage: raw ${(%):-%N:h} (flagged unless suppressed with # ALLOW_STRICT_PATH).
Potential additional deny patterns (beyond strict mode):
- Hand-rolled dirname "$(cd "$(dirname "$0")"... ) constructs (partially covered by future plugin guard test)
- Re-implementations duplicating logic of zf::script_dir / resolve_script_dir

If adding enforcement:
1. Extend tools/enforce-path-resolution.zsh with optional --strict-mode or additional pattern branch.
2. Update this checklist & open PR referencing rationale (empirical failure, consistency need, etc.).
3. Add new test under tests/style that asserts deny-list behavior.

---

## 13. Troubleshooting Matrix

Symptom: Path enforcement fails unexpectedly.
Actions:
- Open docs/badges/path-enforce-raw.json for file+line.
- Check for missing helper load point (are you too early in bootstrap?).
- If in a test, confirm test path exclusion logic (maybe you passed --include-tests locally).

Symptom: Performance regression gate fails.
Actions:
- Compare perf-current.json vs perf-baseline.json
- Re-run local baseline capture after verifying environment parity (CPU scaling, no background jobs).

Symptom: Badge not updating.
Actions:
- Confirm tool produced JSON (non-empty).
- Ensure main branch or workflow with contents: write permission if auto-commit expected.
- Check if migration layout (redesignv2) bridging logic applies.

---

## 14. PR Documentation Expectations

When PR introduces:
- New helper: Document invocation + rationale in docs/redesign or appropriate subpage.
- New badge: Add explanation to README badge legend.
- New enforcement rule: Update this checklist and mention migration guidance.

Minimal acceptable PR description structure:
Context (1–2 sentences)
Change Summary (bulleted)
Verification (tests / manual steps)
Risk / Rollback Plan (if applicable)

---

## 15. Security & Integrity

Integrity hash scripts:
- Must use resilient path helpers.
- Should not silently ignore missing files—explicit error to stderr, non-zero exit.

When adding scripts interacting with remote data:
- Avoid curl | sh patterns.
- Validate downloaded content (hash or signature) before sourcing/executing.

---

## 16. Versioning / Incremental Tightening

Tighten gates only after:
- A baseline has stabilized (multiple nightly data points).
- A migration window was announced (add TODO with date if helpful).
- Documentation (this file + README) updated to reflect new expectation.

---

## 17. Minimal Template for New Tool Script

(Write this manually; do NOT copy brittle path expansions.)

Header expectations:
- Purpose
- Usage
- Exit codes
- Path resolution note referencing helpers
- set -euo pipefail

---

## 18. Contributor Workflow (TL;DR)

1. Implement feature / refactor (helpers for paths).
2. Run style, path, and design tests locally.
3. Validate no performance cliff (optional: generate perf badge).
4. Commit with meaningful message (conventional or clear semantic).
5. Open PR; ensure badge diffs make sense (red to green, etc.).
6. Respond to CI signals; fix violations rather than suppress unless exceptional.

---

## Appendix A: Frequently Used Patterns (Inline)

Resilient current script directory:
if typeset -f zf::script_dir >/dev/null 2>&1; then
  DIR="$(zf::script_dir "${(%):-%N}")"
elif typeset -f resolve_script_dir >/dev/null 2>&1; then
  DIR="$(resolve_script_dir "${(%):-%N}")"
else
  DIR="${(%):-%N:h}"
fi

Repo root from tool under dot-config/zsh/tools:
REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/.." && pwd -P)"

---

## Appendix B: When Not To Introduce a Helper

Avoid wrapping trivial one-off path usage (like temporary mktemp output) in a helper just for abstraction. Limit helpers to repeated patterns with semantic meaning (script directory, repo root, cache dirs).

---

## Maintenance Ownership

If this checklist drifts from actual CI behavior:
1. Treat as a bug.
2. Update fastest path (either CI YAML / tool or this doc) then open follow-up issue referencing commit hash that diverged.

---
End of checklist. Keep PRs aligned with this and changes stay smooth, visible, and enforceable.