# Documentation (Superseded Layout)

The authoritative redesign documentation has been consolidated under `docs/redesign/`.

Key Index: redesign/README.md
Contributor Checklist: contributor/checklist.md

All legacy or prior scattered planning/analysis docs are superseded by their consolidated counterparts in `docs/redesign`.

---
Superseded Notice: This stub exists to redirect tooling or readers to the new structure. Do not add new planning content here.

## Immutability & Manifest Tooling (Adder Appendix)

Although this README is a superseded routing stub, the following operational notes are appended here for quick discoverability of the new immutability governance utilities introduced during the fix‑zle initiative.

### 1. Empty Layer Immutability Checker

Script: `zsh/tools/check-empty-layer-immutability.zsh`  
Purpose: Validates that the three redesign “empty” layer skeleton directories match the committed manifest (`layers/immutable/manifest.json`) and enforces drift policy.

Core exit codes (normal mode):
- 0: OK (no drift)
- 1: Drift detected (missing/extra/mismatch/aggregate/hash policy failures)
- 2: Usage error (bad flags)
- 3: Manifest missing (unless `--allow-missing-manifest`)
- 4: Parse/runtime/hash tool failure
- Self-test mode: 0 = pass, 1 = fail

Key flags:
- `--json`                       Emit JSON (machine readable)
- `--quiet`                      Suppress human report
- `--allow-missing-manifest`     Non-fatal if manifest absent (status=manifest_missing)
- `--recompute-dir-hash`         Include computed `aggregate_sha256` per directory
- `--strict`                     Enforce schema + non‑zero expected counts + unlisted FS dir detection
- `--allow-empty-ok`             Relax strict zero expected count failure
- `--list-changes`               Only show drift directories in human output
- `--self-test`                  Run synthetic OK + drift scenario (ignores provided manifest)
- `--skip-aggregate-validate`    Do not validate manifest `dir_hash` fields if present
- `--manifest <path>`            Override manifest file path

JSON additions:
- Each directory: `missing_files`, `extra_files`, `hash_mismatches`, optional `aggregate_sha256`, optional `dir_hash_manifest`, `aggregate_hash_mismatch`
- Top-level `metrics`: elapsed_ms, directories_total, directories_drift, files_expected, files_checked, files_missing, files_extra, hash_mismatches, aggregate_hash_mismatches

Example (human + JSON):
```
zsh/tools/check-empty-layer-immutability.zsh --json --recompute-dir-hash
```

Self-test sanity:
```
zsh/tools/check-empty-layer-immutability.zsh --self-test --json --quiet
```

### 2. Manifest Regeneration Utility

Script: `zsh/tools/regenerate-empty-layer-manifest.zsh`  
Purpose: Produce a new immutable manifest snapshot of `.zshrc.*.d.empty` directories with per‑file sha256 (and optional directory aggregate / canonical hash).

Flags:
- `--output <path>`            Write to custom (recommended timestamped) file
- `--in-place`                 Overwrite canonical (`layers/immutable/manifest.json`) (governance exception)
- `--force-overwrite`          Required to replace existing output
- `--aggregate`                Add `aggregate_sha256` (directory aggregate digest)
- `--embed-dir-hash`           Add canonical `dir_hash` (enables validation path in checker)
- `--pretty`                   Indented JSON
- `--schema-version <v>`       Override schema version
- `--help`                     Usage

Safe snapshot example:
```
zsh/tools/regenerate-empty-layer-manifest.zsh \
  --output layers/immutable/manifest-$(date -u +%Y%m%dT%H%M%SZ).json --aggregate --embed-dir-hash --pretty
```

Update canonical (discouraged; requires justification):
```
zsh/tools/regenerate-empty-layer-manifest.zsh --in-place --force-overwrite --aggregate --embed-dir-hash --pretty
```

### 3. Aggregate Hash Semantics

When `--aggregate` (and/or `--embed-dir-hash`) is used:
- Directory aggregate = sha256 of sorted lines: `<sha256> <filename>`
- Stored as `aggregate_sha256` (snapshot evidence) and/or `dir_hash` (governance target)
- Checker:
  - Recomputes `aggregate_sha256` with `--recompute-dir-hash`
  - Validates `dir_hash` automatically unless `--skip-aggregate-validate` supplied
  - Marks drift on mismatch (`aggregate_hash_mismatches` metric increments)

### 4. CI Integration Pattern

Typical workflow steps (already present in `immutability-check.yml`):
1. Checkout repository
2. Run stray artifact + redirection lint
3. Run immutability checker:
   ```
   zsh/tools/check-empty-layer-immutability.zsh --json --recompute-dir-hash > immutability.json
   ```
4. Parse JSON and fail build if:
   - `status` not in { ok, manifest_missing (allowed) }
   - `drift` top-level flag = 1
5. (Optional) Run with `--strict --list-changes` for concise failure output
6. Upload artifacts (`immutability.json`, health reports) for audit

### 5. Governance Recommendations

- Use timestamped manifest snapshots plus a maintained symlink `manifest.json` pointing to the latest approved snapshot.
- PRs that regenerate manifests should:
  - Include diff of new snapshot
  - Provide reason (added/removed files, normative reordering, refactor)
  - Show checker output (pre/post) in PR body
- Enable `--embed-dir-hash` once stable to lock aggregate digests for faster drift triage.

### 6. Quick Command Reference

| Action                                   | Command |
|------------------------------------------|---------|
| Validate (human + JSON)                  | `zsh/tools/check-empty-layer-immutability.zsh --json` |
| Strict validation (changes only)         | `zsh/tools/check-empty-layer-immutability.zsh --strict --list-changes` |
| Include aggregate hash output            | `zsh/tools/check-empty-layer-immutability.zsh --json --recompute-dir-hash` |
| Self-test health                         | `zsh/tools/check-empty-layer-immutability.zsh --self-test --json` |
| Regenerate snapshot (timestamped)        | `zsh/tools/regenerate-empty-layer-manifest.zsh --aggregate --embed-dir-hash --pretty --output layers/immutable/manifest-$(date -u +%Y%m%dT%H%M%SZ).json` |
| Overwrite canonical (exception)          | `zsh/tools/regenerate-empty-layer-manifest.zsh --in-place --force-overwrite --aggregate --embed-dir-hash` |

### 7. Drift Response Playbook (Abbreviated)

| Drift Type          | Likely Cause                     | Resolution Path |
|---------------------|----------------------------------|-----------------|
| Missing file        | Accidental deletion              | Restore from history / regenerate manifest if intentional |
| Extra file          | Unapproved addition / stray test | Remove or regenerate manifest with justification |
| Hash mismatch       | File modified without manifest   | Revert change or regenerate snapshot with rationale |
| dir_hash mismatch   | Aggregate sequencing / tamper    | Recalculate, confirm authenticity, update manifest if valid |
| Unknown directory   | New layer skeleton introduced    | Add to manifest (append-only snapshot) |

---

Refer to `docs/redesign/` for broader architectural context; this appendix is operational only.
