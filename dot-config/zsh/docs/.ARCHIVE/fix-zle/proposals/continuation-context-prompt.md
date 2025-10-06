# fix-zle Continuation Context Prompt
File: `proposals/continuation-context-prompt.md`
Status: Draft (Generated 2025-10-01)
Audience: Future AI assistant / engineer picking up the redesign thread in a fresh session.

---

## 1. Purpose

Provide a single, self‑contained, high‑fidelity prompt that can be pasted into a new (unrelated) conversation to seamlessly continue the `fix-zle` ZSH redesign initiative without reloading the entire repository history manually. It captures current architecture, phase status, metrics, decision matrix outcomes, instrumentation state, and next actionable tasks.

---

## 2. High-Level State Summary (2025-10-01)

| Aspect | State |
|--------|-------|
| Active Layer Set | `00` (symlinks: `.zshrc.pre-plugins.d -> .zshrc.pre-plugins.d.00`, etc.) |
| Phase Completion | Phases 1–6 COMPLETE; Phase 7 PARTIAL/near-closure |
| Stable Widget Baseline | 417 (historical minimum acceptance ≥387) |
| Styling (Carapace) | KEEP (cold delta ≈ +0.40ms fallback; warm delta ≈ -0.08ms, manual /usr/bin/time delta ≈ -10ms) |
| Segment Capture | Prototype active (module `115-live-segment-capture.zsh`, opt-in) |
| RSS Sampling | Implemented with guard (`ZF_SEGMENT_CAPTURE_DISABLE_RSS=1`) |
| Rotation Strategy | Segment log rotates by size (default 1MB, 3 backups) |
| Autopair | Plugin + PTY harness validated; behavioral tests pass |
| Abbreviations | Core pack ACTIVE (marker `_ZF_ABBR_PACK=core`); Brew pack module present (`195-optional-brew-abbr.zsh`); further curated sets optional |
| Validator | `validate-segments.sh` supports R-001..R-016 (including D14 draft hierarchy/memory) |
| Aggregator | Embeds segments (`--segment-file` + `--embed-segments`), optional `--require-segments-valid` |
| Timing Harness | Supports cold & warm passes, fallback EPOCHREALTIME timing, mode labeling |
| Memory Metrics | Segment events optionally include `rss_start_kb`, `rss_end_kb`, `rss_delta_kb` |
| Integrity & Schema | Schema draft + D14 extension (hierarchy + memory) documented |

---

## 3. Phases Recap

| Phase | Status | Key Artifacts |
|-------|--------|---------------|
| 1 Core & Safety | ✅ | `010-shell-safety-nounset.zsh`, `020-delayed-nounset-activation.zsh` |
| 2 Performance Core | ✅ | Performance modules, async/defer/evalcache |
| 3 Dev Environments | ✅ | Language + toolchain env modules (PHP/Herd, Node+Bun, Rust, Go, GH CLI) |
| 4 Productivity | ✅ | History (Atuin), navigation (eza/zoxide), FZF, Carapace |
| 5 Neovim Ecosystem | ✅ | `340-neovim-environment.zsh`, profile dispatcher |
| 6 Terminal Integration | ✅ | `100-terminal-integration.zsh` + evidence logs |
| 7 Optional Enhancements | 🔄 | Starship instrumentation, autopair PTY tests, styling validation, segment capture prototype, abbreviation packs/RSS toggle pending closure notes |

---

## 4. Key Decision Outcomes (Selected)

| Decision Area | Outcome |
|---------------|---------|
| Carapace Styling | Retained; performance acceptable |
| Segment Capture | Prototype accepted (opt-in) |
| Autopair Validation | Basic + PTY harness (pass) |
| Layer Set Strategy | Single-track versioned directories with symlink flips |
| Namespace | All custom functions `zf::` prefixed |
| Fallback Timing | Always emit synthetic timing if native `time` suppressed (can be disabled later) |
| Memory Metrics | Included as optional prototype (guarded) |
| Segment Hierarchy | Draft spec (D14) with parent/depth fields; not mandatory yet |

---

## 5. Current Instrumentation & Files

| Instrumentation Component | Path / Module | Notes |
|---------------------------|---------------|-------|
| Timing harness | `docs/fix-zle/tests/carapace_timing_harness.sh` | Cold + warm; fallback lines `startup(mode,pass): ... fallback=1` |
| Segment capture | `.zshrc.d.00/115-live-segment-capture.zsh` | NDJSON, rotation, RSS, thresholds |
| Segment schema | `docs/fix-zle/segment-schema.md` | Base + D14 extension (Sec. 26) |
| Validator | `docs/fix-zle/tests/validate-segments.sh` | Rules R-001..R-016 |
| Aggregator | `docs/fix-zle/tests/aggregate-json-tests.sh` | Embeds segments & validator result |
| Autopair harness | `docs/fix-zle/tests/test-autopair-pty.sh` | Behavioral checks |
| Live capture test | `docs/fix-zle/tests/test-live-segment-capture.sh` | NDJSON structural verification |

---

## 6. Active Environment Variables (Guards & Toggles)

| Variable | Purpose |
|----------|---------|
| `_ZF_LAYER_SET` | Active version marker (e.g. 00) |
| `ZF_DISABLE_CARAPACE_STYLES=1` | Disable styling layer |
| `ZF_SEGMENT_CAPTURE=1` | Enable live segment capture |
| `ZF_SEGMENT_CAPTURE_MIN_MS` | Minimum elapsed threshold (ms) |
| `ZF_SEGMENT_CAPTURE_DISABLE_RSS=1` | Skip RSS collection |
| `ZF_SEGMENT_CAPTURE_ROTATE_MAX_BYTES` | Rotation threshold (default 1MB) |
| `ZF_SEGMENT_CAPTURE_ROTATE_BACKUPS` | Rotation depth (default 3) |
| `ZF_SEGMENT_CAPTURE_DISABLE_TIME_FALLBACK=1` | Skip internal fallback timing attempt |
| `RUN_AUTOPAIR_PTY=1` | Enable PTY autopair test inside aggregator/smoke |
| `AGG_EMBED_SEGMENTS=1` | Embed segments in aggregator output |
| `AGG_REQUIRE_SEGMENTS=1` | Fail aggregator if segment validation fails |
| `ZF_HISTORY_ATUIN_DISABLE_KEYBINDS=1` | Opt out of Atuin keybindings |
| `ZF_SEGMENT_CAPTURE_HOOKS=1` | Enable (experimental) prompt preexec hooks |
| `ZF_DISABLE_ABBR=1` | Disable abbreviation system entirely |
| `ZF_DISABLE_ABBR_PACK_CORE=1` | Skip core abbreviation pack injection |
| `ZF_DISABLE_ABBR_BREW=1` | Skip brew abbreviation pack |

---

## 7. Recent Harness Results (Evidence Snapshot)

Cold (fallback timing):
- no-style cold: 0.010828s
- with-style cold: 0.011227s
- delta (with - no): +0.000399s (~+0.40ms)

Warm (fallback timing):
- no-style warm: 0.010359s
- with-style warm: 0.010278s
- delta (with - no): -0.000081s (~ -0.08ms)

Widgets: 417 total (user-defined 39) stable across all passes.

Interpretation: Styling overhead statistically negligible; Keep decision stands.

---

## 8. Segment Capture Prototype (Operational Details)

NDJSON Fields (current prototype):
```
{
  "type": "segment",
  "version": 1,
  "segment": "<name>",
  "elapsed_ms": <float>,
  "ts": "RFC3339",
  "pid": <int>,
  "shell": "zsh",
  "layer_set": "00",
  "rss_start_kb": <int?>,
  "rss_end_kb": <int?>,
  "rss_delta_kb": <int?>,
  "rc": "0|N",
  "... user extra key/value pairs ..."
}
```
Rotation occurs pre-append if file exceeds threshold.

---

## 9. Validation Rules Coverage

Implemented (validator):
- R-001..R-010 (base schema)
- R-011: parent_id ordering
- R-012: depth constraints
- R-013: rss delta consistency
- R-014: rss_delta_kb requires start & end
- R-015: mem_class enumeration
- R-016: advisory depth derivation (fail only in strict mode)

---

## 10. Outstanding / Near-Term Actions

| Priority | Task | Description | Proposed Success Signal |
|----------|------|-------------|--------------------------|
| High | Phase 7 closure | Mark Phase 7 COMPLETE after documenting final styling + warm timing metrics | plan-of-attack updated & baseline snapshot |
| High | README badges (optional) | Add CI status & widget baseline badge | README updated |
| High | Segment validator integration in CI | Run aggregator with live segment file + `--embed-segments --require-segments-valid` | CI artifact shows `"segments_valid":true` |
| Medium | Integrity checksum script | Add tool to canonicalize + sha256 instrumentation file | Script outputs checksum & sets tamper flag |
| Medium | Widget baseline guard | Enforce fail if widgets <417 in CI | CI step fails on regression |
| Low | Optional RSS sampling docs | Document resource overhead & disable guidance | README / schema note added |
| Low | Fallback timing disable toggle docs | Add explicit mention in harness header | Harness header updated |

---

## 11. Proposed Next Implementation Steps (Actionable Script)

1. Finalize Phase 7:
   - Update `plan-of-attack.md` Phase 7 block to COMPLETE.
   - Insert final timing table (manual + harness cold/warm).
   - Record abbreviation + brew pack status (already active).
2. Integrity checksum tool:
   - Add `tools/segment-canonicalize.sh` (canonical JSON + sha256 manifest).
   - Include usage snippet in README instrumentation section.
3. CI:
   - Extend workflow to:
     * Export `ZF_SEGMENT_CAPTURE=1` for a run.
     * Pass `--segment-file … --embed-segments --require-segments-valid`.
     * Add widget ≥417 guard.
4. Documentation:
   - Add “Performance & Instrumentation” section (segment capture, validator, checksum usage).
   - Add toggle table enumerating guards & defaults.
5. Optional refinement (post-closure):
   - Consider compression toggle & retention notes; mark future D14 expansion path.

---

## 12. Constraints & Guardrails

- Do NOT merge changes that reduce widgets below 416 without documentation and acceptance rationale (historical min acceptance still 387, but 416 is current stability).
- Avoid introducing global `set +u` expansions; maintain nounset strategy.
- No silent error suppression—log via debug or warnings channel.
- Each new module must be idempotent and namespaced.

---

## 13. Quick Diagnostic Commands

Widget + markers:
```
zsh -ic 'echo WIDGETS=$(zle -la | wc -l); echo LAYER=$_ZF_LAYER_SET; echo SEG_CAPTURE=$_ZF_SEGMENT_CAPTURE; echo CARA_STYLE=$_ZF_CARAPACE_STYLES'
```

Segment validator (strict):
```
bash docs/fix-zle/tests/validate-segments.sh --strict path/to/segments.json
```

Harness (warm included):
```
bash docs/fix-zle/tests/carapace_timing_harness.sh RUN_WARM=1
```

Aggregator with segments:
```
bash docs/fix-zle/tests/aggregate-json-tests.sh \
  --segment-file ~/.cache/zsh/segments/live-segments.ndjson \
  --embed-segments --require-segments-valid --pretty
```

---

## 14. Minimal Warm Start Prompt (TL;DR Variant)

If space limited, use:

```
Continue fix-zle Phase 7 finalization.
Active layer: 00, widgets=417 stable.
Carapace styling kept (cold delta +0.40ms fallback; warm delta -0.08ms).
Segment capture prototype (RSS + rotation) active (opt-in via ZF_SEGMENT_CAPTURE=1).
Validator enforces R-001..R-016.
Need: Phase 7 closure doc update, abbreviation core pack, segment integrity checksum script, CI segment validation gating.
Proceed with those tasks respecting existing namespace & nounset patterns.
```

---

## 15. Rollback Strategy (If Instability Detected)

1. Disable new feature via env guard (e.g., `ZF_SEGMENT_CAPTURE=0`).
2. Re-run smoke + timing harness; confirm widgets revert to 417.
3. If failure persists, flip layer symlinks back to prior numbered set (when available).
4. Capture diff of instrumentation log pre/post rollback for audit.

---

## 16. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Excessive segment log growth | Rotation already in place; consider compression later |
| Widget regression from new modules | Always measure (`zle -la | wc -l`) in harness post-change |
| False-negative timing due to fallback only | Optionally add native timing debug capture once root cause identified |
| RSS sampling overhead in constrained CI | Guard variable + skip when `ps` absent |

---

## 17. Acceptance Criteria for Declaring Phase 7 COMPLETE

- plan-of-attack updated with warm & cold timing evidence.
- Abbreviation pack decision documented (implemented or explicitly deferred).
- Segment validator integrated into CI aggregator run (segments_valid=true).
- Segment capture prototype documented (README instrumentation section).
- Integrity checksum workflow design drafted or initial script committed (even if manual invocation).

---

## 18. Continuation Instructions (What To Ask From Assistant)

When starting a fresh session, prompt:

```
Load fix-zle context. Confirm Phase 7 outstanding tasks (abbr pack, integrity checksum, CI segment validation). If not complete, implement them sequentially with minimal diffs, validate widget baseline (≥417), then update plan-of-attack and README instrumentation section.
```

---

## 19. Do Not Forget

- Keep diffs minimal and modular.
- Document every performance-impacting addition (even micro) in code comments.
- Preserve test harness reliability—avoid embedding assumptions about terminal environment beyond existing markers.

---

## 20. End

This document can be copied verbatim as a seed prompt for the next assistant or engineer.
