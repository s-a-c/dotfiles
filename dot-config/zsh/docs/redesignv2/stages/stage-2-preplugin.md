# Stage 2 – Pre‑Plugin Content Migration
Version: 1.0  
Status: 🎯 Ready (Execution Not Yet Begun)  
Planned Tag on Completion: `refactor-stage2-preplugin`  
Last Updated: 2025-01-03

> Stage 2 migrates **legacy early-path & preparation logic** into the redesigned pre‑plugin module set (00–30).  
> No user‑visible behavior (besides performance & cleanliness) should change.  
> Architecture rules & cross‑stage roadmap live in `../IMPLEMENTATION.md` and `../ARCHITECTURE.md`.

---

## 1. Purpose

Transform legacy scattered early initialization (path repair, ad‑hoc environment tweaks, early tool activation) into **four cohesive responsibility layers**:

| Module | Responsibility | High‑Level Outcome |
|--------|----------------|--------------------|
| 00-path-safety.zsh | Deterministic PATH + hygiene | Stable, deduplicated, precedence-safe PATH |
| 05-fzf-init.zsh | Lightweight FZF keymaps only | No heavy binary sourcing before interaction |
| 10-lazy-framework.zsh | Generic lazy dispatcher | Foundation for deferred tool & integration loads |
| 15-node-runtime-env.zsh | Node/npm stub wrappers | Zero nvm/npm cost until first actual use |
| 20-macos-defaults-deferred.zsh | Safe macOS tweaks deferral | No blocking `defaults` calls during cold start |
| 25-lazy-integrations.zsh | direnv/git/copilot lazy shells | On-demand activation; idempotent wrappers |
| 30-ssh-agent.zsh | Single agent mgmt | Prevent duplicate agents & silent socket churn |
| 40-pre-plugin-reserved.zsh | Reserved | Capacity for emergent need without renumbering |

---

## 2. Scope

| Included | Excluded |
|----------|----------|
| Path normalization & dedup logic migration | Any post-plugin configuration (options, aliases, env exports beyond PATH) |
| Lazy loader core implementation | Deep security hashing (Stage 5/6) |
| Node/npm deferral stubs | Real plugin reordering |
| macOS deferred operations scaffold | Prompt/UI changes |
| Consolidated SSH agent function | Completion subsystem changes |
| Integration (direnv/git/copilot) lazy wrappers | Performance badge automation changes |

---

## 3. Entry Criteria (All Must Be ✅)

| Criterion | Evidence | Status |
|-----------|----------|--------|
| Stage 1 tag present | `git tag | grep refactor-stage1-complete` | ✅ |
| Baseline metrics captured | `artifacts/metrics/perf-baseline.json` | ✅ |
| Skeleton modules present (8 pre) | Structure audit (`total=19`) | ✅ |
| Sentinel test passes | `test-redesign-sentinels.zsh` | ✅ |
| Verification script healthy | `./verify-implementation.zsh` PASS | ✅ |
| Async scaffolding intact | Security tests PASS (scaffold) | ✅ |

---

## 4. Objectives & Success Metrics

| Objective | Metric / Gate | Target |
|-----------|---------------|--------|
| Consolidate path logic | Duplicate PATH entries post-load | 0 duplicates |
| Minimize pre-plugin overhead | `pre_plugin_cost_ms` vs baseline | -10% (stretch -15%) |
| Lazy loader correctness | First vs second call delta | First call loads, second is O(1) |
| Node lazy activation | nvm/npm not loaded during startup capture | Confirm absence in perf logs |
| Integration stubs idempotent | Repeated wrapper invocations | No duplicate exports/processes |
| SSH agent protection | Additional agent processes | 0 new if valid socket exists |
| Safety retention | All tests remain green | 100% PASS same categories as Stage 1 |
| No functional drift | Manual smoke commands (core toolchain) | Behavior parity |

---

## 5. Detailed Task Breakdown

| ID | Task | Description | Outputs | Validation |
|----|------|-------------|---------|-----------|
| S2.1.1 | Analyze legacy path scripts | Inventory logic from `00_00`, `00_01`, `00_05` | Notes & diff plan | Internal review |
| S2.1.2 | Implement path normalization | Build unified dedup + ordering function | 00-path-safety.zsh (content) | Path test snippet |
| S2.1.3 | Edge case coverage | Handle trailing slashes, nonexistent paths | Additional guards | Manual + echo checks |
| S2.1.4 | Micro timing | Instrument internal timing optional | Inline comment metrics | `<5ms` inspection |
| S2.1.5 | Add path invariants test (future) | (Optional) future test harness stub | Test TODO marker | Deferred (not blocking) |
| S2.2.1 | Identify essential FZF binds | Minimal keymap subset only | List in comments | No subprocess spawn |
| S2.2.2 | Write lightweight FZF init | 05-fzf-init.zsh (no compinit) | File content | `grep` absence of heavy ops |
| S2.3.1 | Design lazy dispatcher API | Decide function naming & storage associative arrays | Spec header block | Unit test alignment |
| S2.3.2 | Implement registry & dispatcher | `_LAZY_REGISTRY`, `_LAZY_LOADED` maps | 10-lazy-framework.zsh | `test-lazy-framework.zsh` PASS |
| S2.3.3 | Loader error handling | Non-zero exit + message on failure | Code paths | Unit tests negative branch |
| S2.3.4 | Document extension contract | Inline doc comment | README snippet (optional) | Code comment presence |
| S2.4.1 | Create nvm stub wrapper | `node`, `npm`, `npx` redirect to lazy loader | 15-node-runtime-env.zsh | First-call timing test |
| S2.4.2 | Implement singular nvm bootstrap | Ensure only ONE actual nvm load | Guard variable | Multi-call test |
| S2.4.3 | Edge: missing nvm install | Graceful error / help suggestion | Conditional check | Manual test |
| S2.5.1 | Direnv wrapper | Load only if command exists & RC file present | `direnv` stub | Repeated invocation |
| S2.5.2 | Git integration wrapper | Defer git-specific env adjustments | Stub function | Git commands unaffected |
| S2.5.3 | Copilot wrapper stub | Placeholder for future lazy use | Non-blocking no-op | Structure test |
| S2.5.4 | Consolidate into 25 file | Group wrappers logically | 25-lazy-integrations.zsh | Sentinel + grep |
| S2.5.5 | Idempotence audit | Re-invoke wrappers and diff env | Manual check script (optional) | No duplication |
| S2.6.1 | Merge SSH agent logic | Consolidate spawn detection into single function | 30-ssh-agent.zsh | Feature test PASS |
| S2.6.2 | Add socket validity heuristics | Test file, perm bits | Code path | Manual simulation |
| S2.6.3 | Avoid duplicate spawns | Detect running agent PID mismatch | Early exit message | Feature test re-run |
| S2.6.4 | Logging (light) | Optional debug echo if ZSH_DEBUG | Conditional branch | Visual check |
| S2.7.1 | Pre-plugin perf sampling | Run `perf-capture.zsh` repeatedly | preplugin-baseline.json | Data plausibility |
| S2.7.2 | Record delta vs baseline | Compute `%` improvement | Inline note + metrics commit | Derived metric |
| S2.7.3 | Update perf badge inputs | (Optional) preplugin badge JSON | Badge refresh (future CI) | Visible |
| S2.8.1 | Run full suite | All categories green | Test log artifact | PASS statuses |
| S2.8.2 | Update IMPLEMENTATION statuses | Reflect Stage 2 completion | Document diff | Commit content |
| S2.9.1 | Commit & tag | Clean working tree & tag | Git tag | `git show` |
| S2.9.2 | Document handoff | Create stage-3-core skeleton doc | stage-3-core.md | File exists |

---

## 6. Performance Validation Plan

| Step | Action | Threshold |
|------|--------|-----------|
| 1 | Capture N=5 cold/warm pairs | — |
| 2 | Extract `pre_plugin_cost_ms` | Must exist (segments_available true) |
| 3 | Compare vs legacy measured pre-plugin (estimated) | ≥10% reduction target |
| 4 | Confirm `post_plugin_cost_ms` unchanged | Variation <5% (noise only) |
| 5 | Ensure no unplanned PATH expansion count | PATH element count stable ±1 |

---

## 7. Risk Matrix (Stage 2 Specific)

| Risk | Likelihood | Impact | Mitigation | Early Indicator |
|------|------------|--------|------------|-----------------|
| PATH misordering breaks tools | Medium | High | Side-by-side echo diff before commit | Missing command in session |
| Lazy loader recursion | Low | Medium | Self-replacement before invocation | Stack growth / repeated stderr |
| Node stub loads too early | Medium | Medium | Assert absence in perf logs | `nvm` strings in startup log |
| SSH agent duplicate spawn | Low | Medium | Feature test repeated invocation | Two ssh-agent PIDs |
| Added startup regression | Medium | High | Segment regression test failing | `post_plugin_cost_ms` spike |

---

## 8. Validation Matrix (Exit Gates)

| Gate | Evidence Tool | PASS Condition |
|------|---------------|----------------|
| G2A Pre-plugin structural integrity | Sentinel + structure tests | No violations |
| G2B Lazy loader functionality | Unit tests | All PASS |
| G2C Node deferral | Perf capture log | No nvm call pre-first prompt |
| G2D SSH agent correctness | Feature test | Duplicate spawn test PASS |
| G2E Performance delta | perf-current vs baseline | ≥10% pre-plugin improvement (document actual) |
| G2F No regression elsewhere | Full test suite | 0 FAIL |
| G2G Tag immutability | Git tag | `refactor-stage2-preplugin` created |

---

## 9. Exit Checklist (All Must Be ✅ to Tag)

| Item | Status |
|------|--------|
| 00–30 modules populated (clean, guarded) | ⬜ |
| Lazy dispatcher & tests PASS | ⬜ |
| Node stubs functional (single load) | ⬜ |
| Integrations wrappers idempotent | ⬜ |
| SSH agent logic idempotent | ⬜ |
| Performance sample recorded | ⬜ |
| IMPLEMENTATION.md updated (Stage 2 complete) | ⬜ |
| Stage 3 doc stub created | ⬜ |
| Tag & commit pushed | ⬜ |

---

## 10. Deferred / Nice-To-Have (Not Blocking)

| Item | Rationale |
|------|-----------|
| Automated PATH integrity test script | Could add deterministic check later |
| Pre-plugin specific perf badge | Optional visualization |
| Env diff snapshot before/after migration | Audit artifact (historical) |
| Memory footprint sampling | Lower priority vs CPU/time metrics |

---

## 11. Rollback Procedure (Stage 2 → Stage 1)

| Scenario | Command | Follow-Up |
|----------|---------|-----------|
| Functional break discovered | `git reset --hard refactor-stage1-complete` | Re-apply commits one-by-one |
| Performance regression > threshold | Same as above | Binary search sub-module changes |
| SSH agent instability | Temporarily stub 30-ssh-agent contents | Open issue; re-implement |
| Lazy loader failure | Replace 10-lazy-framework with NOOP shim | Reproduce failing invocation |

---

## 12. Handoff to Stage 3 (Preparation)

Upon successful tagging:
1. Create `stage-3-core.md` with skeleton for modules 00/05/10 post-plugin.
2. Update IMPLEMENTATION.md Stage 3 status → 🎯 Ready.
3. Announce internal availability for security baseline stub & options migration.

---

## 13. Logging & Instrumentation Additions (Stage 2)

| Addition | Location | Purpose |
|----------|----------|---------|
| Lazy load counters (optional) | 10-lazy-framework.zsh | Future perf tuning |
| SSH agent debug echo (conditional) | 30-ssh-agent.zsh | Troubleshooting |
| Path normalization trace (DEBUG gated) | 00-path-safety.zsh | Validation / support |

---

## 14. ADR References (Reinforced)

| ADR | Relevance in Stage 2 |
|-----|----------------------|
| ADR-001 | Numeric layering influences module commit order |
| ADR-004 | Lazy dispatcher implemented here |
| ADR-005 | Artifacts kept separate (no metrics in code tree) |
| ADR-006 | Baseline immutability preserved during migration |

---

## 15. Change Log (This Document)

| Date | Version | Change |
|------|---------|--------|
| 2025-01-03 | 1.0 | Initial Stage 2 execution plan (pre-migration) |

---

**Status:** Stage 2 awaiting execution start.  
Proceed with caution: migrate iteratively (one file per commit where feasible) to preserve bisectability.

[Back to Overview](../README.md) | [Implementation Guide](../IMPLEMENTATION.md) | [Stage 1 (Complete)](stage-1-foundation.md)

---
*End Stage 2 Plan*