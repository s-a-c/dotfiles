# Stage 3 – Post‑Plugin Core Modules (00 / 05 / 10)
Version: 1.0  
Status: ⏳ Pending (Will flip to 🎯 Ready once Stage 2 is tagged)  
Planned Tag on Completion: `refactor-stage3-core`  
Last Updated: 2025-01-03

> Stage 3 implements the **first functional layer** of the post‑plugin redesign tree:
> - 00-security-integrity.zsh (light security baseline & scheduling hooks)
> - 05-interactive-options.zsh (centralized shell behavior: setopt / unsetopt / zstyles / history policy)
> - 10-core-functions.zsh (user-facing helpers, wrappers, internal utilities)
>
> No heavy performance instrumentation, async scanning, completion, or UI logic should be added here—those are deferred to later stages (50/60/70/80).

---

## 1. Purpose

Provide a **clean, deterministic functional substrate** immediately after plugin manager restoration:
- Centralize fundamental shell behavior (options history behavior) to eliminate scattered mutations later.
- Establish early placeholders for security integrity scheduling (no hashing yet).
- Introduce a curated, documented collection of core functions (safe wrappers) to replace legacy ad‑hoc definitions.

---

## 2. Scope

| Included | Rationale |
|----------|-----------|
| Security integrity baseline stub | Prepares scheduling + log markers for later deep scan (Stage 5/6) |
| Option consolidation (`setopt`, `unsetopt`) | Ensures reproducible environment before features load |
| History & zstyle configuration | Single authoritative location (avoid collisions) |
| Core function library (utility, wrappers, diagnostics) | Replace divergent legacy function scatter |
| Minimal logging (debug gated) | Support troubleshooting during migration |

| Excluded | Defer To | Reason |
|----------|---------|--------|
| Deep hashing / plugin diffs | Stage 5/6 | Maintain fast early phase |
| Completion manipulation | Stage 5 (50) | Avoid early compinit influence |
| Prompt / theme code | Stage 5 (60) | Maintain separation of concerns |
| Performance hooks & timing capture | Stage 5 (70) | Avoid noise in early modules |
| Async execution engine body | Stage 5 (80) | Engine not yet active |
| Cosmetic splash elements | Stage 5 (90) | Final aesthetic layer only |

---

## 3. Entry Criteria (All Must Be ✅ Before Work Starts)

| Criterion | Source | Status (Expected) |
|----------|--------|-------------------|
| Stage 2 tag present | `git tag | grep refactor-stage2-preplugin` | Pending |
| Pre-plugin path logic stabilized | Stage 2 exit checklist | Pending |
| Lazy framework functional (tests PASS) | Stage 2 unit tests | Pending |
| Pre-plugin performance delta recorded | `preplugin-baseline.json` | Pending |
| No unresolved Stage 2 regression issues | Issue tracker / test suite | Pending |

---

## 4. Objectives & Success Metrics

| Objective | Metric / Gate | Target |
|-----------|---------------|--------|
| Secure baseline scheduling | Presence of queue marker (no hash execution) | `SECURITY_ASYNC_QUEUE` logged; no RUNNING |
| Option centralization | All option mutations originate in module 05 | Zero option diffs outside 05 on audit |
| History consolidation | Only module 05 sets history vars | Verified via grep / tests |
| Core functions reliability | Unit coverage for critical helpers | ≥90% of added functions simple path PASS |
| No performance regression | `post_plugin_cost_ms` minimal increase | Δ ≤ +1% vs previous |
| Deterministic load order | structure audit unchanged (19 total) | PASS |
| No compinit interference | `_COMPINIT_DONE` untouched | PASS |

---

## 5. Proposed Module Content Outline

### 5.1 00-security-integrity.zsh
- Sentinel + early scheduling function: `zsh_security_queue_integrity_scan` (NO hash operations yet).
- Record a baseline timestamp/log stub: `SECURITY_ASYNC_QUEUE`.
- Provide lightweight fingerprint placeholder (e.g., plugin dir count) for future diff (commented or stub).
- Export `_ASYNC_PLUGIN_HASH_STATE=IDLE` if unset.

### 5.2 05-interactive-options.zsh
- Grouped `setopt / unsetopt` (e.g., `extendedglob`, `hist_ignore_all_dups`, etc.)
- History parameters (`HISTSIZE`, `SAVEHIST`, `HISTFILE`) if not in `.zshenv` (respect env precedence).
- `zstyle` completion tuning (not calling `compinit`).
- Line editing improvements (e.g., `WORDCHARS`, `REPORTTIME` gating).
- Guard against duplicate re-entry.

### 5.3 10-core-functions.zsh
Suggested categories:
| Category | Examples |
|----------|----------|
| System Introspection | `zsh_show_path_segments`, `zsh_show_module_status` |
| Safety Helpers | `zsh_require_command <cmd>` (fail-fast messaging) |
| Lazy Diagnostics | `zsh_list_lazy_functions` enumerates registry |
| Wrapper Utilities | `mkcd` (mkdir & cd), safe temp directory helper |
| Performance Debug (Conditional) | `zsh_perf_now` wrapper (if `zmodload zsh/datetime`) |
| Security Queue Helper | `plugin_security_status` (stub; real logic Stage 5/6) |

Rules:
- Functions must be idempotent & side-effect minimal.
- Avoid network calls, heavy filesystem ops, or plugin reconfiguration here.

---

## 6. Detailed Task Breakdown

| ID | Task | Output | Validation |
|----|------|--------|-----------|
| S3.1 | Create 00 module stub content | 00-security-integrity.zsh populated | Sentinel test PASS |
| S3.2 | Implement queue scheduling stub | Logging line + exported state | Async initial test still PASS |
| S3.3 | Add integrity stub comments | Future integration notes | Code review |
| S3.4 | Implement options consolidation | setopt/unsetopt block | Grep reveals no duplicates elsewhere |
| S3.5 | Centralize history/zstyle settings | Inline documented section | Full tests PASS |
| S3.6 | Create function namespace plan | Comment header map | Review |
| S3.7 | Implement core functions batch 1 | Basic helpers + tests | Unit tests PASS |
| S3.8 | Add diagnostics / lazy registry viewer | Introspection helper | Manual invocation OK |
| S3.9 | Add stub `plugin_security_status` | Placeholder returns explanatory message | CLI call returns 0 |
| S3.10 | Performance sanity capture | perf-current.json update | Segment regression test PASS |
| S3.11 | Update IMPLEMENTATION.md | Stage 3 progress markers | Git diff |
| S3.12 | Tag & document completion | `refactor-stage3-core` | Tag exists |

---

## 7. Performance Plan

| Step | Action | Expectation |
|------|--------|-------------|
| 1 | Capture perf before Stage 3 | Baseline post Stage 2 |
| 2 | Implement 00 + 05 only | Negligible delta (<0.5%) |
| 3 | Add 10-core-functions | Slight overhead; still ≤1% |
| 4 | Run segment regression test | PASS (≤5% global gate, ≤1% expected) |
| 5 | Commit metrics delta note | Document actual impact |

---

## 8. Risk Matrix (Stage 3 Specific)

| Risk | Likelihood | Impact | Mitigation | Early Signal |
|------|------------|--------|------------|--------------|
| Options conflict with legacy un-migrated modules | Medium | Medium | Audit grep for duplicate setopt lines | Option test failure |
| Security stub accidentally triggers hashing early | Low | High | Keep only scheduling + markers (no hash functions) | RUNNING state before prompt |
| Function name collisions | Medium | Medium | Prefix internal helpers or audit `function-collisions.json` | Structure audit violation or collision JSON |
| Added latency from verbose logging | Low | Low | Gate debug output on `ZSH_DEBUG` | Perf delta >1% |
| Overreach in history config (user overrides) | Medium | Low | Respect existing exported env values | User config diff complaint |

---

## 9. Validation & Exit Gates

| Gate | Tool / Evidence | PASS Condition |
|------|-----------------|----------------|
| G3A Structure unchanged | Structure audit | Total=19, no violations |
| G3B No early async execution | Async tests | No RUNNING pre-prompt |
| G3C Option centralization | Grep audit | Only 05 sets core options |
| G3D Core functions callable | Manual & unit tests | No errors invoking helpers |
| G3E Perf delta acceptable | Segment regression test | Δ ≤1% (soft), ≤5% (hard) |
| G3F Documentation sync | IMPLEMENTATION.md | Stage 3 updated |
| G3G Tag created | Git | `refactor-stage3-core` exists |

---

## 10. Exit Checklist

| Item | Status |
|------|--------|
| 00 module stub + scheduling present | ⬜ |
| 05 options & history centralized | ⬜ |
| 10 core functions (initial set) | ⬜ |
| Stub `plugin_security_status` implemented | ⬜ |
| All tests PASS (no new failures) | ⬜ |
| Performance delta documented | ⬜ |
| IMPLEMENTATION.md updated (Stage 3 complete) | ⬜ |
| Tag pushed & verified | ⬜ |

---

## 11. Rollback Strategy (Stage 3 → Stage 2)

| Scenario | Action | Follow-Up |
|----------|--------|-----------|
| Option regression | Revert 05 changes selectively | Add incremental setopt commits |
| Unexpected perf spike | Temporarily remove new functions block | Binary search function groups |
| Async logging issue | Strip 00 scheduling lines | Reintroduce with smaller scope |
| Collision or name break | Rename conflicting function with `_zsh_` prefix | Update reference doc |

---

## 12. Deferred / Non-Blocking Items

| Item | Reason for Deferral |
|------|---------------------|
| Function help autogeneration | Nice-to-have; not critical path |
| Extended history analytics | Belongs to performance/telemetry phases |
| Early color/theme adjustments | UI isolation principle |
| Deep security scan bootstrap | Only after core stability proven |

---

## 13. ADR Linkage

| ADR | Influence |
|-----|-----------|
| ADR-001 | Numeric ordering – ensures early core boundary stays lean |
| ADR-002 | Single compinit unaffected by Stage 3 |
| ADR-003 | Deferral principle enforced in 00 stub |
| ADR-004 | Lazy loader introspection supported by 10 |
| ADR-005 | Separation of artifacts (no embedded metrics) |
| ADR-006 | Baseline integrity preserved (no legacy edits) |

---

## 14. Change Log (This Document)

| Date | Version | Change |
|------|---------|--------|
| 2025-01-03 | 1.0 | Initial Stage 3 skeleton plan (pre-execution) |

---

**Status:** Pending Stage 2 completion.  
Prepare branch: `git checkout -b stage-3-core`.

[Back to Overview](../README.md) | [Implementation Guide](../IMPLEMENTATION.md) | [Stage 2](stage-2-preplugin.md) | Stage 4 (will follow)  
