# Segment Instrumentation Proposal (Deferred Activation)

Compliant with `AGENT.md` orchestration policy. This document specifies a future, opt‑in performance instrumentation framework for the ZSH redesign. No active code changes are implied until explicitly approved.

## 1. Purpose & Non-Goals
**Purpose**: Define a structured, low-overhead, reversible plan to (re)introduce timing instrumentation across startup and plugin phases for observability, regression detection, and performance budgeting.

**Non-Goals (Current Phase)**:
- No automatic wrapping of plugin loads
- No JSON emission in baseline shells
- No CI gating on micro-segments yet
- No mandatory user overhead or added latency

## 2. Current State Snapshot

| Component | Status | Notes |
|-----------|--------|-------|
| `tools/segment-lib.zsh` | Present | Passive unless `PERF_SEGMENT_LOG` set |
| `030-segment-management.zsh` | Minimal shim + breadcrumb | Fallback only, no expansion |
| Synthetic markers script (`tools/helpers/perf-minimal-markers.zsh`) | Available | Not wired into normal flow |
| Promotion guard (`tools/promotion-guard.zsh`) | Expects aggregate metrics optionally | Micro segment gating deferred |
| Docs | Lacking dedicated taxonomy file | This proposal fills gap |

## 3. Activation Model: `ZF_PERF_MODE`
Introduce single environment mode flag evaluated early (Phase 2):

| Mode | Description | Emission | Overhead Target |
|------|-------------|----------|-----------------|
| `off` (default) | No instrumentation beyond user overrides | None (unless user sets `PERF_SEGMENT_LOG`) | ~0 ms |
| `light` | Aggregate "tripod" markers only | `pre_plugin_total`, `post_plugin_total`, `prompt_ready` | <3 ms |
| `full` | Aggregate + per-module + probes (compinit, prompt theme, productivity tools) | All labeled segments | <10 ms (cold) |

Decision precedence:

1. If user exports `ZF_PERF_MODE` explicitly, honor it.
2. If `CI=1` and `ZSH_PERF_TRACK=1` and no mode set → default to `light`.
3. If a perf harness variable (e.g. `PERF_SAMPLE_CONTEXT`) present → escalate to `full` unless overridden.

## 4. Label Taxonomy (Reserved)
Namespace hierarchy to avoid collisions and clarify grouping:

| Prefix | Example | Scope |
|--------|---------|-------|
| `plugin/` | `plugin/fzf` | Individual plugin/module load wrapper |
| `env/` | `env/node` | Environment setup cost (toolchain path exports etc.) |
| `prod/` | `prod/atuin` | Productivity/UI adjuncts |
| `neovim/` | `neovim/lazyman` | Editor ecosystem integration |
| `term/` | `term/warp` | Terminal-specific feature setups |
| `ux/` | `ux/starship` | Prompt / user experience enhancements |
| `core/` | `core/compinit` | Core initialization hotspots (compinit, theme bootstrap) |
| `defer/` | `defer/history-sync` | Deferred post-prompt tasks |

Rules:

- Lowercase, dash or underscore only
- No spaces; auto-normalization preserves dashes
- Avoid reusing labels across namespaces

## 5. Emission Contracts
SEGMENT line schema (unchanged):
```text
SEGMENT name=<label> ms=<duration_ms> phase=<phase> sample=<context>
```
Where `phase ∈ {pre_plugin, add_plugin, post_plugin, prompt, other, postprompt}`.

Backward compatibility: legacy `POST_PLUGIN_SEGMENT` still emitted automatically for `post_plugin` segments by `segment-lib` when enabled.

## 6. Future Tooling Artifacts
Planned (NOT yet added):

### 6.1 `tools/segments-to-json.zsh`
Transforms raw `PERF_SEGMENT_LOG` into `artifacts/metrics/perf-segments.json`.

Functional contract:

- Input: path from `$PERF_SEGMENT_LOG`
- Output JSON keys:
  - `segments_available: true`
  - `summary`: aggregate means for tripod (if present)
  - `segments`: array of objects `{ name, phase, ms }` (per run or last run)
  - Optional stability stats (mean, stdev per label) when multiple logs provided via `--multi <glob>`
- Exit 0 even if no segments (emits `segments_available: false`)
- Nounset-safe; avoids external deps except `awk` + optional `jq` fallback logic.

### 6.2 Wrapper Helper (Deferred)
`zf::with_segment <phase> <label> -- <command ...>`

- No-op when `ZF_PERF_MODE=off`
- Expands to start/end calls otherwise
- Guarantee: never throws, preserves `$?` of wrapped command

### 6.3 Mode Bootstrap
Snippet (future injection early Phase 2):

```zsh
: ${ZF_PERF_MODE:=off}
if [[ -z ${ZF_PERF_MODE_SET_EXPLICIT:-} ]]; then
  if [[ ${CI:-0} == 1 && ${ZSH_PERF_TRACK:-0} == 1 ]]; then
    ZF_PERF_MODE=light
  fi
  if [[ -n ${PERF_SAMPLE_CONTEXT:-} && $ZF_PERF_MODE == off ]]; then
    ZF_PERF_MODE=full
  fi
fi
export ZF_PERF_MODE
```

## 7. Light Mode Specification
Implementation steps when activated:

1. Record `pre_plugin_total` just before first plugin load.
2. Record `post_plugin_total` after last plugin load (includes plugin manager overhead).
3. Record `prompt_ready` just before the first interactive prompt render.
4. Write tripod lines to `PERF_SEGMENT_LOG` (auto-set if not provided):
   - Path: `${ZSH_LOG_DIR}/perf-segments-${ZSH_SESSION_ID}.log`
5. Create minimal JSON via `segments-to-json.zsh` if in CI.

## 8. Full Mode Specification
Adds to Light mode:

- Wrap each plugin load (labels: `plugin/<id>`)
- Core probes: `core/compinit`, `core/p10k_theme` (only if themes used)
- Environment groups (optional gating): `env/node`, `env/go`, etc.
- Productivity: `prod/fzf`, `prod/atuin`, `prod/zoxide`, `prod/carapace`
- UX: `ux/starship`, `ux/autopair`
- Terminal: `term/warp`, `term/wezterm`, etc.
- Deferred tasks: measure `defer/<task>` at first completion boundary.

## 9. Overhead Budget & Guardrails

| Layer | Target Added Cost (cold) |
|-------|--------------------------|
| Light | ≤ 3 ms |
| Full (baseline typical config) | ≤ 10 ms |

Guard strategies:

- Avoid external processes beyond `awk` (EPOCHREALTIME path)
- Batch I/O writes (append only; no per-line sync flush forced)
- Use associative arrays for O(1) segment lookup

## 10. Failure & Safety Semantics

| Condition | Behavior |
|-----------|----------|
| Missing `segment-lib` | Fallback no-op or basic timing if currently present (unchanged) |
| Log unwritable | Suppress emission silently (debug trace if `ZF_DEBUG=1`) |
| Duplicate start | Ignored; first start timestamp preserved |
| End without start | Ignored |
| Negative delta | Clamped to 0 |

## 11. CI / Automation Future Path
Phased adoption:

1. (Optional) Collect sample logs on perf branches (`perf/*`).
2. Enable `light` mode in CI for baseline creation.
3. Introduce variance checks (stdev <= threshold) for tripod metrics.
4. Optionally gate PRs on ≥X% regression for tripod.
5. Later: narrow gating on hot labels only (e.g. `plugin/fzf`, `core/compinit`).

## 12. Rollback Strategy
Single-step disable:

- Export `ZF_PERF_MODE=off` (or unset) before shell start.
- Remove or comment out mode bootstrap block.
- CI jobs referencing segment JSON skip gracefully (script emits `segments_available:false`).

## 13. Open Questions (Document Before Implementation)

| Topic | Notes |
|-------|-------|
| Nested segments | Not currently supported; depth >1 ignored to simplify overhead |
| JSON aggregation window | Default to last run; multi-run aggregation behind `--multi` flag |
| Warm vs cold discrimination | Based on `PERF_SAMPLE_CONTEXT`; need harness to set reliably |
| Threshold source of truth | Possibly `tools/perf-thresholds.json` later |

## 14. Minimal Acceptance Criteria for Enabling Light Mode

- Breadcrumb remains intact.
- Mode variable bootstrap added.
- Tripod metrics appear in log and JSON.
- Promotion guard optionally extended to warn (not fail) if missing tripod when `ZF_PERF_MODE=light`.

## 15. Implementation Checklist (Future PR Template)

- [ ] Add mode bootstrap (no functional change when off)
- [ ] Add `zf::with_segment` helper (guarded by mode)
- [ ] Implement tripod emission flow
- [ ] Add `tools/segments-to-json.zsh`
- [ ] Write docs update (`copilot-instructions.md` progress section)
- [ ] Optional CI job to archive segment logs
- [ ] Provide rollback note in PR body

## 16. Explicit Deferral Marker
Until a PR references this file and marks sections 15 items completed, **no additional segment instrumentation should be introduced**.

---
Prepared as a forward-looking specification. No runtime behavior altered by this document alone.
