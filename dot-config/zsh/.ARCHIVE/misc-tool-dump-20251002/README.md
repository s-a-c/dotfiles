# Archived Misc Tool Dump (Forensic Snapshot)
Date Archived: 2025-10-02  
Archive Path: `.ARCHIVE/misc-tool-dump-20251002/0`  
Tracking Tag: `GOV-STRAY-ARTIFACTS-2025-10-02`  

## 1. Summary
This directory contains a large, uncurated collection of executable helper scripts and stray files that were discovered at the root of the active ZSH configuration under a bare numeric directory name: `zsh/0`.  
It was **not** part of the sanctioned layer / module structure (which uses `.zshrc.*.d`, `.zshrc.*.d.<NN>`, or explicitly governed archival sets).  

The directory was relocated intact into this archive for provenance and forensic retention. No scripts here are currently sourced or loaded by the redesign system.

## 2. Reason for Archival
The presence of a bare numeric directory (`0`) violated new governance rules prohibiting:
- Root-level pure-numeric directory names (unless part of a formal layered suffix convention like `.zshrc.d.00`)
- Untracked tool collections without manifest / ownership metadata

Additionally, suspicious filenames inside the directory (`600`, `644`, `700`, `750`, `755`, and a lone `$`) strongly indicated a failed bulk copy or install loop where numeric mode tokens and/or an unexpanded variable were written as filenames.

## 3. Probable Root Causes
| Artifact | Likely Cause | Notes |
|----------|--------------|-------|
| Directory name `0` | Variable interpolation fallback (e.g. `${LAYER_ID:-0}`) in an early prototype or bulk copy script | Layer naming now standardized to two-digit suffixes (`00`, `01`) only in symlinked directories |
| Filenames `600`, `644`, `700`, `750`, `755` | Mode tokens misinterpreted as destination filenames during a loop (`cp` / `install` misuse) | Classic signature of argument ordering or missing `install -m` separation |
| File named `$` | Unquoted empty or literal `$VAR` expansion inserted as a path component | Typically from `cp "$src" "$OUT/$BASENAME$"` or similar |
| Large tool corpus | Blind aggregation of `$HOME/bin`, legacy dotfile exports, or plugin bundle extraction into a temporary staging path | No curation, no manifest, no namespacing alignment |

## 4. Integrity & Modification Policy
This archive is **write-once**.  
Do **not** modify, rename, or delete files within this directory except under an approved cleanup protocol documented in `docs/fix-zle/plan-of-attack.md` with a cross-reference to this tracking tag.

If individual tools are reintroduced:
1. Review for security implications (shell injection, unsafe `rm`, misuse of globbing).
2. Add appropriate namespacing or relocate to a curated `bin/` or `tools/` subdirectory with explicit load semantics.
3. Add them to a manifest or controlled module file with test coverage if they affect interactive shell behavior.

## 5. Governance References
- Stray Artifact Governance Section (Added 2025-10-02) in `docs/fix-zle/plan-of-attack.md`
- Preventative Hardening Measures Table (same document)
- CI Enforcement: `tools/detect-stray-artifacts.zsh` (fails if new root-level numeric entries appear)

## 6. Forensic Recommendations
Suggested optional actions (only if future triage warrants):
- Run static lint (shellcheck) across salvage candidates
- Compute a SHA256 inventory if a fixed manifest of this dump is ever needed
  Example:
    for f in ./*; do [ -f "$f" ] && shasum -a 256 "$f"; done > SHA256SUMS.txt
- Tag any restored script with a provenance header:
  ```
  # Restored from misc-tool-dump-20251002 (original name: <name>)
  # Reviewed: <date> <reviewer>
  ```

## 7. Security Considerations
Because origin is uncertain:
- Treat scripts as untrusted until individually reviewed.
- Do not grant them execute permissions in active PATH without vetting.
- Watch for:
  - Unsanitized command substitutions
  - `eval` usage
  - Blind `rm -rf` patterns
  - Network calls / curl pipes
  - Embedded credentials or tokens

## 8. Disposition Matrix (High-Level)
| Category | Approx Count* | Disposition |
|----------|---------------|------------|
| git helpers | Many | Consider merging into a single curated git-tools module |
| macOS UI / system tweaks | Several | Migrate case-by-case with safety prompts |
| Network / diagnostics | Several | Retain only those not redundant with native tools |
| Random utility (encoding, clipboard, formatting) | Many | Consolidate or discard |
| Permission-mode filenames | 5 | Keep for provenance only (do not re-use) |
| `$` | 1 | Keep as forensic evidence (redirect mishap) |

*Counts not enumerated here to avoid implying active governance of each item.

## 9. Action Log
| Timestamp (UTC) | Action | Actor | Notes |
|-----------------|--------|-------|-------|
| 2025-10-02 | Identified `0` & `2` as stray | redesign audit | Triggered governance addition |
| 2025-10-02 | Moved `0` to archive | automated assist | Directory renamed under archive path |
| 2025-10-02 | Added governance + detector | automated assist | Detector: `tools/detect-stray-artifacts.zsh` |
| 2025-10-02 | Added this README | automated assist | Archive documentation |

## 10. Reintroduction Checklist
Before resurrecting any script here:
- [ ] Justify need (not provided by existing modules)
- [ ] Security review performed
- [ ] Namespaced or relocated properly
- [ ] Added tests (if stateful or complex)
- [ ] Added to an explicit manifest / module load path
- [ ] Documented in `plan-of-attack.md` or appropriate README

## 11. Do Not:
- Use this dump as an ad hoc PATH directory.
- Cherry-pick scripts into active modules without review.
- Delete this archive silently (preserve audit chain).

---

If additional provenance clarity is discovered (commit IDs, original migration script, or ephemeral layer prototype logs), append a short “Addendum” section below without altering existing historical text.

Addendum:
(none yet)

EOF