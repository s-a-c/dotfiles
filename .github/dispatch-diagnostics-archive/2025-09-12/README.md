# GitHub Actions Workflow Dispatch Anomaly (Diagnostics Bundle)
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v9ab717af287538a58515d2f3369d011f40ef239829ec614afadfc1cc419e5f20
> ARCHIVED (2025-09-12): Native `workflow_dispatch` behavior restored. This diagnostics bundle is retained for historical reference.
> See cleanup plan: [CLEANUP_PLAN.md](CLEANUP_PLAN.md) and the “Resolution Update” section below for post-incident actions.

> Purpose: Provide a precise, support‑ready evidence package for the persistent `422 Unprocessable Entity: Workflow does not have 'workflow_dispatch' trigger` failure affecting newly created or recently modified workflows in this repository while legacy workflows continue to function normally.

---

## 1. Executive Summary
- New (or newly edited) workflows containing a `workflow_dispatch:` trigger are rejected when manually dispatched (UI or REST API) with HTTP 422 stating the workflow lacks that trigger.
- Legacy workflow `ci-performance.yml` (unchanged for a longer interval) dispatches successfully.
- Problem is isolated to event registration / indexing on GitHub’s backend (not YAML syntax, branch, permissions, or required inputs).
- Temporary, additive fallbacks implemented (repository_dispatch, tag trigger, chained dispatch via legacy workflow, helper script).
- This document plus a raw failing curl invocation can be supplied directly to GitHub Support to request internal re-indexing / event graph repair.
- UPDATE 2025-09-12: Manual dispatch has begun returning 204 (success) for newly added workflows. A transient validation workflow (`transient-manual-dispatch-validation.yml`) was introduced to confirm sustained healthy behavior and the evidence capture script was patched to expect 204 for the minimal repro (override via EXPECT_REPRO_STATUS if regression occurs).

### Resolution Update (2025-09-12)
Manual dispatch behavior appears restored. Validation steps:
1. Ran `transient-manual-dispatch-validation` (direct `workflow_dispatch`) → HTTP 204.
2. Secondary API dispatch within that workflow against `test-minimal-dispatch.yml` → HTTP 204.
3. Updated `capture-dispatch-evidence.sh` to default EXPECT_REPRO_STATUS=204 (still configurable to 422 if anomaly recurs).
Planned next actions (post burn-in window):
- Remove transient validation workflow.
- Prune temporary fallback triggers (repository_dispatch, tag pattern, chained dispatch input) after a short stability window (see Cleanup Plan).

---

## 2. Impact Scope
| Aspect | Status |
| ------ | ------ |
| Manual dispatch of new workflows | Broken (422) |
| Scheduled events (`schedule`) | OK |
| Push / PR triggers | OK |
| Existing legacy dispatchable workflows | OK |
| New tag-based or repository_dispatch fallbacks | Working |
| Security / permissions settings | Normal / permissive |
| YAML validation (local / server) | Valid |

No repository secrets or PAT scopes appear implicated.

---

## 3. Affected vs Unaffected Workflows
| Category | Example | Dispatch Result |
| -------- | ------- | --------------- |
| Legacy (unchanged) | `.github/workflows/ci-performance.yml` | 204 (Success) |
| New / recently edited | `.github/workflows/zsh-badges-and-metrics.yml` (after edits) | 422 |
| Minimal reproduction (temp test file) | `test-minimal-dispatch.yml` | 422 |
| Non-dispatch events (push/schedule) | Any | Normal |

---

## 4. Reproduction (Minimal)
### 4.1 Minimal Workflow Content
```
name: Minimal Repro
on:
  workflow_dispatch: {}
jobs:
  noop:
    runs-on: ubuntu-latest
    steps:
      - run: echo hello
```

File placed at: `.github/workflows/test-minimal-dispatch.yml` on default branch (`main`).

### 4.2 REST Invocation (Fails)
```
curl -i -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/<owner>/<repo>/actions/workflows/test-minimal-dispatch.yml/dispatches \
  -d '{"ref":"main"}'
```

Response (abbreviated):
```
HTTP/1.1 422 Unprocessable Entity
{
  "message": "Workflow does not have 'workflow_dispatch' trigger",
  "documentation_url": "https://docs.github.com/rest/actions/workflows#create-a-workflow-dispatch-event"
}
```

### 4.3 Control Case (Succeeds)
```
curl -i -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/<owner>/<repo>/actions/workflows/ci-performance.yml/dispatches \
  -d '{"ref":"main","inputs":{"runs":"3"}}'
```
Result: `204 No Content`.

---

## 5. Hex / Encoding Validation
Representative hexdump of a failing workflow (first lines) showed only standard UTF‑8 printable characters; no BOM or stray control bytes.

Command used (example):
```
hexdump -C .github/workflows/test-minimal-dispatch.yml | head -n 20
```
Result: Plain ASCII YAML; nothing anomalous.

---

## 6. Eliminated Causes
| Hypothesis | Action / Evidence | Outcome |
| ---------- | ----------------- | ------- |
| YAML syntax error | Parsed locally (`yamllint`) & accepted (other triggers fire) | Ruled out |
| Missing `workflow_dispatch` key | Verified present, identical structure to working file | Ruled out |
| Required inputs blocking | Tried empty inputs definition & with sample inputs | Ruled out |
| Branch protection / required approvals | No approval banner; dispatch blocked before run | Ruled out |
| Permissions / policies | Actions settings allow all; no org policy banner | Ruled out |
| Encoding / hidden chars | Hex dump clean | Ruled out |
| Caching of deleted / renamed files | New filename not previously used also fails | Ruled out |
| Rate limiting / auth scope | Token succeeds on legacy workflow | Ruled out |
| Repository private vs public behavior | Behavior consistent regardless of privacy | Not causal |

---

## 7. Current Workarounds (Option 3 Implementation)

### 7.1 Repository Dispatch Trigger (Added)
Added to target workflow (example):
```
on:
  repository_dispatch:
    types: [badges_v2_run]
```

Manual invocation:
```
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/<owner>/<repo>/dispatches \
  -d '{"event_type":"badges_v2_run","client_payload":{"ref":"main"}}'
```

### 7.2 Tag-Based Fallback Trigger
Added tag pattern in relevant workflow:
```
on:
  push:
    tags:
      - zsh-badges-run-*
```
Usage:
```
git tag zsh-badges-run-$(date +%s)
git push origin --tags
```
Ensures an API-independent manual path (CLI only).

### 7.3 Chained Dispatch via Legacy Workflow
Extended `ci-performance.yml` with an optional input:
```
workflow_dispatch:
  inputs:
    dispatchBadges:
      description: "repository_dispatch badges_v2_run after run"
      required: false
      default: "false"
```

Conditional step (pseudocode):
```
if: ${{ inputs.dispatchBadges == 'true' }}
run: >
  curl -X POST ... /dispatches -d '{"event_type":"badges_v2_run"}'
```

This leverages a known-good `workflow_dispatch` surface to trigger the failing one indirectly.

### 7.4 Helper Script (`tools/dispatch-badges.sh`)
```
#!/usr/bin/env bash
set -euo pipefail
repo="${1:-s-a-c/dotfiles}"
ref="${2:-main}"
token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
event_type="badges_v2_run"

if [[ -z "${token}" ]]; then
  echo "ERROR: Set GITHUB_TOKEN or GH_TOKEN environment variable." >&2
  exit 1
fi

payload=$(jq -nc --arg et "$event_type" --arg r "$ref" '{event_type:$et, client_payload:{ref:$r}}')
resp=$(mktemp)

code=$(curl -sS -o "$resp" -w '%{http_code}' \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer '"$token"'" \
  -X POST "https://api.github.com/repos/${repo}/dispatches" \
  -d "$payload")

if [[ "$code" != "204" && "$code" != "201" ]]; then
  echo "Dispatch failed (HTTP $code):" >&2
  cat "$resp" >&2
  exit 2
fi
echo "Dispatch accepted (HTTP $code)."
```
Usage:
```
chmod +x tools/dispatch-badges.sh
GITHUB_TOKEN=ghp_xxx ./tools/dispatch-badges.sh s-a-c/dotfiles main
```

---

## 8. Validation of Workarounds
| Path | Mechanism | Result |
| ---- | --------- | ------ |
| repository_dispatch | Direct API event | Success |
| tag push (`zsh-badges-run-*`) | Creates CI run via push | Success |
| chained dispatch (`ci-performance` input) | Indirect dispatch | Success |
| original manual `workflow_dispatch` on new workflow | Fails (422) | Still broken |

---

## 9. What To Request From GitHub Support
1. Confirm internal registration state for newly added workflow files in this repository (compare with legacy `ci-performance.yml`).
2. Re-index or refresh workflow event bindings for the repository (suspected stale event map for `workflow_dispatch`).
3. Check for backend flags or partial ingestion errors after prior file renames or rapid commits.
4. Determine if recent feature rollout / caching layer is impacting recognition of new `workflow_dispatch` events.
5. Provide any correlation / ingestion logs referencing the failing workflow filenames during commit SHAs: (supply commit SHAs & timestamps when opening ticket).

Suggested wording:
> “New workflows containing a `workflow_dispatch` trigger return 422 (‘does not have workflow_dispatch trigger’) while existing legacy workflows dispatch fine. YAML validated, no org or repo restrictions. Please re-index workflow definitions or identify ingestion anomaly.”

---

## 10. Rollback / Cleanup Plan (Post-Fix)
When native manual dispatch resumes functioning for newly created workflows:
1. Remove `repository_dispatch` stanza (unless useful for automation).
2. Remove tag pattern trigger if not desired long-term.
3. Remove `dispatchBadges` input and related step from `ci-performance.yml`.
4. Delete helper script `tools/dispatch-badges.sh` if redundant.
5. Remove this diagnostics directory (optional) after Support ticket closure.
6. Audit for stale tags `zsh-badges-run-*` and delete remotely if cluttered.

Rollback is strictly subtractive; no badge generation logic depends on the added triggers.

---

## 11. Open Questions
| Question | Rationale |
| -------- | --------- |
| Is there a soft limit or throttling on registering new dispatchable workflows within a short time window? | Multiple new files added in rapid succession. |
| Are there known propagation delays > several minutes? | Failures persisted beyond normal cache TTL expectations. |
| Could a previously failing ingestion (transient error) leave a negative cache entry? | Would explain persistent 422 on stable YAML. |
| Any repository-level flag toggled internally (e.g., Actions migration state)? | Might affect only new entries. |

---

## 12. Proposed Internal Debug Hooks (If Needed)
- Internal log correlation: filter by repository ID and action `"workflow_dispatch"` for the failing workflow path at push time.
- Compare stored event descriptor JSON for `ci-performance.yml` vs a failing workflow (should both list `workflow_dispatch`).
- Force a manual reparse of `.github/workflows/*.yml`.

---

## 13. Integrity & Policy Notes
- No secrets, tokens, or credentials are embedded in this document.
- Sample commands use placeholder `<owner>/<repo>`; user substitutes locally.
- Sensitive action compliance: referencing security rule (guidelines security section) rule [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md:17) (line reference approximate; content mandates no secret leakage).

---

## 14. Quick Usage Cheat Sheet
| Goal | Command |
| ---- | ------- |
| Dispatch via repository_dispatch | `tools/dispatch-badges.sh` (script) |
| Dispatch via tag | `git tag zsh-badges-run-$(date +%s) && git push origin --tags` |
| Chained (legacy) | UI: run `CI Performance` with `dispatchBadges=true` |
| Direct manual (currently broken) | Attempt in UI (expect 422) |

---

## 15. FAQ
**Q:** Could required inputs omission cause 422?  
**A:** No. 422 specifically states trigger absence, not invalid payload; minimal file still fails.

**Q:** Could branch mismatch cause this?  
**A:** The ref exists and succeeds for legacy workflow; same ref used.

**Q:** Can we ignore and rely on fallbacks?  
**A:** Yes short-term, but native manual dispatch is ergonomically superior and less error‑prone.

---

## 16. Next Action Summary
| Priority | Action |
| -------- | ------ |
| High | Open Support ticket with this README + failing curl response body |
| Medium | Track Support case ID in issue tracker |
| Medium | Continue using fallback triggers for manual needs |
| Low | After resolution, prune temporary triggers |

---

## 17. Appendices

### A. Example Failing Response Body
```
{"message":"Workflow does not have 'workflow_dispatch' trigger","documentation_url":"https://docs.github.com/rest/actions/workflows#create-a-workflow-dispatch-event"}
```

### B. Example Successful Dispatch (Legacy)
HTTP 204 No Content (empty body).

### C. Suggested Ticket Attachments
- This README.
- `curl -v` transcript (redact token).
- Commit SHAs for (a) creation of failing workflow, (b) last successful legacy dispatch.

---

## 18. Contact / Ownership
Maintainer: (fill in GitHub username)  
All changes additive; safe to merge anytime.

---

End of diagnostics bundle.