dot-config/zsh/docs/redesignv2/migration/SHIM_AUDIT_GATE.md
Compliant with /Users/s-a-c/.config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

# Shim Audit Gate — README

Purpose
-------
This file explains the shim-audit gate that protects the ZSH redesign migration. It describes:
- what the gate checks,
- where the machine-readable artifact is stored,
- how to interpret the artifact,
- how the gate behaves in CI, and
- recommended remediation and next steps.

Keep this page as the single source of truth for reviewers who need to understand why a build failed due to a shim-audit violation.

What the gate checks
--------------------
The shim audit looks for small "shim" functions (trivial placeholders) in the `zf::` helper namespace. A function is considered a shim if it meets one or more heuristics:
- very short body (<= configured max lines),
- body contains only trivial operations (comments, `return 0`, `true`, `:`),
- explicit shim markers (e.g., `__SHIM__`), or
- function has no meaningful body.

Why this matters
----------------
Shims can conceal important unimplemented behaviour that affects performance, reliability, and instrumentation. The gate ensures we only merge the redesign when critical helpers are implemented or intentionally allowed.

Where the artifact is produced
------------------------------
The audit writes a JSON artifact to the repo-local metrics directory:
- `dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json`

This file is also uploaded as a workflow artifact in CI for reviewers.

How to interpret the JSON
--------------------------
Key fields in the artifact (shim-audit.v1):
- `generated_at` — ISO timestamp of audit.
- `total` — total number of candidate functions inspected.
- `shim_count` — number of functions classified as shims.
- `non_shim_count` — number of functions classified as implemented.
- `shim_max_body_lines` — configured threshold for short-body heuristics.
- `shims` — array of shim records; each record includes:
  - `name` — function name (e.g., `zf::script_dir`)
  - `lines` — measured body line count
  - `reasons` — list of heuristics that triggered classification
  - `hash` — optional hash of the body (helps detect drift)
- `non_shims` — array of non-shim function records (name, lines, hash)

Example: sample JSON summary (human-friendly)
```dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json#L1-120
{
  "generated_at":"2025-09-08T22:04:47Z",
  "total": 12,
  "shim_count": 1,
  "non_shim_count": 11,
  "shims": [
    {"name":"zf::script_dir","lines":1,"reasons":["short_body"],"hash":"sha256:..."}
  ]
}
```

Interpreting results
--------------------
- `shim_count == 0` — Good. No gating issue; CI can pass.
- `shim_count > 0` and `fail_on_shims == true` — Gate fails. CI job will exit non-zero and mark the run failed.
- Review `shims[]` to see function names and reasons. The `hash` helps detect whether a shim changed between runs.

How the CI gate behaves
-----------------------
The repository includes a workflow that runs the audit with strict gating. Example CI step:
```dot-config/zsh/.github/workflows/redesign-shim-audit-gate.yml#L1-120
- name: Run shim audit (fail-on-shims)
  run: |
    export ZDOTDIR="${{ github.workspace }}/dot-config/zsh"
    export SHIM_AUDIT_FAIL_ON_SHIMS=1
    $ZDOTDIR/tools/bench-shim-audit.zsh --output-json "$ZDOTDIR/docs/redesignv2/artifacts/metrics/shim-audit.json" --fail-on-shims
```
When configured as a required check in branch protection, this workflow blocks merges that introduce shims.

How to re-run locally
---------------------
Run the audit locally (from repo root or ensure ZDOTDIR is set):
```dot-config/zsh/tools/bench-shim-audit.zsh#L1-200
SHIM_AUDIT_FAIL_ON_SHIMS=1 ./dot-config/zsh/tools/bench-shim-audit.zsh --output-json dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json --fail-on-shims
```
- Exit codes:
  - `0` — pass (no shims detected or not failing).
  - `2` — audit failed due to shims (when `--fail-on-shims` is used).
- Always inspect the generated JSON to see which functions were flagged.

Remediation guidance
--------------------
For each flagged function in `shims[]`:
1. Determine whether the shim is intentional (temporary placeholder) or a required helper.
2. If it's intentional and acceptable for a short term, add a short explanation in the code or in migration docs and log the exception in the migration ticket.
3. If it should be implemented, replace the shim with a proper implementation in `tools/helpers/` (preferred) or inline in the source before re-running the audit.
4. After implementing, re-run the audit locally and confirm `shim_count` goes to zero.

Recommended best practice
-------------------------
- Prefer placing full implementations under `dot-config/zsh/tools/helpers/` so the audit can treat repository-provided helpers as authoritative.
- Keep helper implementations small, well-tested, and documented.
- Use the audit as a lightweight pre-merge gate rather than the single source of truth for correctness.

Audit drift and tracking
------------------------
- The audit emits hashes for non-shim bodies; use those to detect unexpected changes across runs.
- If a shim is intentionally allowed, document the rationale and a removal target (e.g., "remove-by: 2025-10-01").

Contacts & escalation
---------------------
- Owner for the gate and migration: `s-a-c`
- For urgent unblocking (CI false positives), capture the artifact and open a PR with the fix; attach the shim-audit artifact for reviewers.

Appendix — quick CLI snippets
```dot-config/zsh/tools/bench-shim-audit.zsh#L1-200
# Run audit and write JSON (pass: exit 0; fail-on-shims: exit 2)
SHIM_AUDIT_FAIL_ON_SHIMS=1 ./dot-config/zsh/tools/bench-shim-audit.zsh --output-json dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json --fail-on-shims
# Open the JSON (human readable)
python3 -c "import json,sys; print(json.dumps(json.load(open('dot-config/zsh/docs/redesignv2/artifacts/metrics/shim-audit.json')), indent=2))"
```

Revision history
----------------
- 2025-09-08: Initial README and interpretation guide (policy ack included).

Acknowledgement
---------------
Compliant with /Users/s-a-c/.config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
