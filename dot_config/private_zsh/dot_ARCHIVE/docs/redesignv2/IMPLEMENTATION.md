# ZSH Configuration Redesign – Implementation Guide

### Part 08.19.10 — Current Implementation Update

- GOAL profiles fully wired via internal flags (streak, governance, explore, ci). Enforce-mode gating is flags-driven; observe mode remains rc=0.
- Single-metric JSON emission now matches multi-metric ordering (always written before any enforce-mode exit).
- Capture-runner stderr noise (“bad math expression”) is suppressed without changing capture logic or metrics.
- Test matrix T-GOAL-01..06 stabilized and passing with gawk available; tests gracefully skip if gawk is missing; JSON parsing regexes hardened.
- Dynamic badges implemented:
  - goal-state badge: docs/redesignv2/artifacts/badges/goal-state.json
  - summary-goal badge (aggregator): docs/redesignv2/artifacts/badges/summary-goal.json (folds in perf drift and structure health)
- CI and publishing:
  - Strict classifier workflow (GOAL=ci enforce) emits docs/redesignv2/artifacts/metrics/perf-current.json and generates goal-state badge; uploads artifacts.
  - Nightly publisher runs the classifier, generates goal-state and summary-goal badges, ensures perf-drift and structure badges, and publishes to gh-pages with an index.
  - Post-publish step auto-replaces README placeholders with correct shields endpoints once badges land on gh-pages.

Badge endpoints (placeholders; auto-resolved in README after first gh-pages publish):
- Goal-state (flat): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/goal-state.json
- Summary-goal (compact): https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/summary-goal.json
Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

### Stage 4 Sprint 2 Status (Part 08.19 Refresh)
- Logging homogeneity complete: legacy underscore wrappers removed; gate test green (no `ZF_LOG_LEGACY_USED`)
- Real segment probes active (anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total` + granular feature/dev-env/history/security/ui segments)
- Deferred dispatcher skeleton operational (one-shot postprompt; telemetry lines: `DEFERRED id=<id> ms=<int> rc=<rc>`)
- Structured telemetry flags available & inert when unset: `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON` (zero-cost disabled path)
- Multi-metric performance classifier in observe mode (Warn 10% / Fail 25% thresholds); enforce activation (S4-33) pending 3× consecutive OK streak
- Dependency export (`zf::deps::export` JSON + DOT) and DOT generator integrated with initial validation tests
- Privacy appendix published & referenced (redaction whitelist stabilized)
- Baseline performance unchanged: 334ms cold start (RSD 1.9%) — no regression after new instrumentation
- **STAGE 4 STATUS (2025-09-14):** INFRASTRUCTURE COMPLETE, SYSTEM NOT READY FOR DAILY USE
  - S4-18 telemetry opt-in plumbing (COMPLETED - infrastructure only)
  - S4-27 idle/background trigger design and implementation (COMPLETED - infrastructure only)  
  - S4-29 homogeneity documentation updates (COMPLETED)
  - S4-30 performance classifier legend (COMPLETED)
  - S4-19 documentation catalog refresh (COMPLETED)
  - S4-33 enforce-mode governance activation (COMPLETED - but for incomplete system)
- **PERFORMANCE REALITY:** 82% improvement only with SKIP_PLUGINS=1 (missing essential features)
- **CRITICAL ISSUE:** Redesigned system fails to load properly, missing plugin ecosystem
- **ACTUAL STATUS:** Legacy system remains only usable configuration
- Logging Homogeneity Policy Summary: Only `zf::log`, `zf::warn`, `zf::err` are approved; legacy underscore wrappers (`_zf_log`, `_zf_warn`, `_zf_err`) are prohibited and now enforced by homogeneity gate; raw `echo`/`print` for runtime logging disallowed except guarded diagnostics: `[[ ${ZSH_DEBUG:-0} == 1 ]] && print -- "[diag] ..."`
- Legacy Wrapper Removal Policy (Completed): Introduced namespaced APIs, instrumented transitional wrappers with sentinel `ZF_LOG_LEGACY_USED`, verified ≥2 consecutive clean runs (no sentinel set), removed wrappers, updated REFERENCE §5.4 & ARCHITECTURE; rollback only via emergency branch + governance PERFORMANCE_LOG row (Type=governance, Scope=logging-homogeneity).
- Developer Checklist (Homogeneity): (1) No underscore wrappers reintroduced, (2) No unguarded diagnostic `echo`, (3) Structured telemetry key additions accompanied by schema + privacy appendix update, (4) ADR required for any new logging helper variant, (5) Run design-only homogeneity test locally before commit.
- Compliance Header Update Note: The checksum in the compliance header must refresh automatically when `/dot-config/ai/guidelines.md` changes; all automation touching this file should validate and rewrite the header if mismatch is detected (policy guard for drift).



**Version:** 3.4  
**Last Updated:** 2025-09-11 (Part 08.19 + GOAL Profiles)  
**Status:** Stage 4 – Sprint 2 (Instrumentation & Telemetry Expansion – classifier in observe mode; enforcement pending 3× OK streak)  
**Critical Update (Part 08.19):**  

### ✅ Telemetry Opt-In Plumbing (S4-18 COMPLETED)

**Status: IMPLEMENTED** - Feature Layer telemetry module with zero-overhead disabled path.

**Implementation:** `feature/40-telemetry.zsh`
- Environment Flag: `ZSH_FEATURE_TELEMETRY=0|off|1|on|debug` (default: 0)
- Data Structures (conditional allocation when enabled):
  - `FL_T0` - Start timestamps (associative array)
  - `FL_DT` - Elapsed times (associative array)
  - `FL_META` - Metadata (version, hostname, shell_pid, session_id)
- API Functions:
  - `fl_telemetry_enabled()` - Zero-overhead boolean check
  - `fl_tstart <key>` - Start timing
  - `fl_tend <key>` - End timing and record delta
  - `fl_twith <key> <cmd>` - Time command execution
  - `fl_telemetry_flush()` - Deferred flush to structured logs
- Timing Support:
  - High-resolution via EPOCHREALTIME (zsh/datetime module)
  - Fallback to date command for compatibility
- Testing: Comprehensive test suite validates disabled/enabled paths and overhead
- Integration: Ready for feature registry wrapping via `fl_wrap_feature_invocation()`

### ✅ Idle Trigger System (S4-27 COMPLETED)

**Status: IMPLEMENTED** - Budget-controlled idle processing with comprehensive queue management.

**Implementation:** `feature/50-idle-trigger.zsh` and `docs/feature-layer/05-idle-triggers.md`
- Scheduler Integration: zsh/sched based timing with precmd hook lifecycle
- Queue Management: Priority-based processing with retry logic and error containment
- Budget Enforcement: ≤3ms per tick with early termination and progress tracking
- Configuration: FL_IDLE_ENABLED, FL_IDLE_PERIOD_SEC, FL_IDLE_MAX_OPS, FL_IDLE_BUDGET_MS
- API Functions:
  - `fl_idle_enqueue <priority> <id> <func> <desc>` - Add work items
  - `fl_idle_status()` - Comprehensive status and statistics
  - `fl_idle_enable/disable()` - Runtime control
  - `fl_idle_flush()` - Immediate processing
  - `fl_idle_reset()` - Clear queue and stats
- Performance Budgets:
  - Startup: <1ms synchronous overhead
  - Runtime: ≤3ms per tick with enforcement
  - Memory: <1KB baseline usage
- Error Handling: Retry logic (max 2 retries), failure statistics, graceful degradation
- Telemetry Integration: Optional timing via `fl_twith` wrapper when available
- Testing: Comprehensive test suite validates queue management, priority processing, and budget compliance

Next Steps:
| ID | Assertion |
|----|-----------|
| T-TEL-01 | Disabled path emits no feature_timing JSON |
| T-TEL-02 | Enabled path records ≥1 known feature timing key |
| T-TEL-03 | Timing values are integers >0 for instrumented features |
| T-TEL-04 | Overhead (disabled) difference vs baseline <0.5ms (5-run avg) |
| T-TEL-05 | Schema validator accepts new `feature_timing` type |
| T-TEL-06 | Privacy appendix lists `feature_timing` fields (name, ms, phase, ts) |

Next Steps:
1. Add flag evaluation + data structure declarations.
2. Instrument registry wrapper (start/stop timestamps).
3. Extend structured telemetry emitter with guarded `feature_timing` block.
4. Add schema + privacy appendix updates.
5. Implement tests T-TEL-01..T-TEL-05.
6. Update PERFORMANCE_LOG if measurable (>1ms) overhead detected (expected: none).

Governance Note: Enforce-mode flip for classifier (S4-33) contingent on telemetry addition showing zero delta to `prompt_ready_ms` in observe mode.

- Real segment probes COMPLETE (phase anchors + granular attribution: pre_plugin_start, pre_plugin_total, post_plugin_total, prompt_ready, deferred_total, plus feature/plugin segments)  
- Deferred dispatcher skeleton ACTIVE (one‑shot postprompt, cumulative `deferred_total` captured)  
- Multi-metric performance classifier integrated (observe mode: OK/WARN/FAIL thresholds 10% / 25%; enforce flip S4-33 pending 3 consecutive OK runs)  
- Governance readiness: PERFORMANCE_LOG governance placeholder + README performance status managed block (pending activation row on enforce flip)  
- Logging namespace migration COMPLETE (underscore wrappers removed; homogeneity gate enforced)  
- Structured telemetry flags AVAILABLE (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) – opt-in, zero overhead when unset; privacy appendix published and referenced  
- Dependency export + DOT generator integrated (`zf::deps::export --dot`) with basic tests green  
- New automation scripts: `tools/update-performance-status.zsh` (streak JSON) & `tools/sync-readme-performance-status.zsh` (managed README block)  
- README segment sync automation operational (`tools/sync-readme-segments.zsh` + CI drift check workflow)  
- Baseline stable: 334ms cold start (RSD 1.9%) – no regression after instrumentation additions  

This document is the authoritative reference for the ZSH configuration redesign implementation, consolidating all progress tracking, execution plans, and promotion readiness criteria.

### 4.x Classifier GOAL Profiles & Execution Semantics

The performance regression classifier now supports adaptive execution via a `GOAL` profile controlling strictness, fallback resilience, baseline handling rules, JSON status augmentation, and exit semantics. Unset `GOAL` defaults to `Streak` for backward compatibility (legacy single-mode behavior maps to today’s Streak).

| Dimension | Streak | Governance | Explore | CI |
|-----------|--------|------------|---------|----|
| Intent | Rapid OK streak build (resilient) | Pre-enforcement strict validation | Developer sandbox (diagnostics) | Deterministic automation gating |
| Strictness | Phased: start `set -uo pipefail`; add `-e` before stats | Full `set -euo pipefail` | `set -uo pipefail` (no `-e`) | Full `set -euo pipefail` |
| Synthetic Fallback | Allowed | Disallowed | Allowed | Disallowed |
| Missing Metrics | Warn + continue (`partial`) | Hard fail | Warn + continue (`partial`) | Hard fail |
| Baseline Creation | Yes (auto if absent) | Yes (only if complete & real) | Yes | Yes |
| Partial Flag (`partial`) | May appear | Must NOT appear | May appear | Must NOT appear |
| Synthetic Flag (`synthetic_used`) | Present if fallback used | Must NOT appear | Present if used | Must NOT appear |
| Ephemeral Flag (`ephemeral`) | No | No | Yes | No |
| Exit on Missing | No | Yes | No (unless catastrophic) | Yes |
| Exit on Synthetic | No | Yes | No | Yes |
| JSON Always | `goal` | `goal` | `goal` | `goal` |

Internal flag mapping (derived after `apply_goal_profile` – documented, not user-facing):

```
streak:     ALLOW_SYNTHETIC_SEGMENTS=1 REQUIRE_ALL_METRICS=0 HARD_STRICT=0 STRICT_PHASED=1 SOFT_MISSING_OK=1 JSON_PARTIAL_OK=1 EPHEMERAL_FLAG=0
governance: ALLOW_SYNTHETIC_SEGMENTS=0 REQUIRE_ALL_METRICS=1 HARD_STRICT=1 STRICT_PHASED=0 SOFT_MISSING_OK=0 JSON_PARTIAL_OK=0 EPHEMERAL_FLAG=0
explore:    ALLOW_SYNTHETIC_SEGMENTS=1 REQUIRE_ALL_METRICS=0 HARD_STRICT=0 STRICT_PHASED=0 SOFT_MISSING_OK=1 JSON_PARTIAL_OK=1 EPHEMERAL_FLAG=1
ci:         ALLOW_SYNTHETIC_SEGMENTS=0 REQUIRE_ALL_METRICS=1 HARD_STRICT=1 STRICT_PHASED=0 SOFT_MISSING_OK=0 JSON_PARTIAL_OK=0 EPHEMERAL_FLAG=0
```

Pseudocode scaffold:

```
apply_goal_profile() {
  local g="${GOAL:-Streak}"
  g="${g:l}"
  ALLOW_SYNTHETIC_SEGMENTS=0 REQUIRE_ALL_METRICS=1 HARD_STRICT=1 STRICT_PHASED=0 \
  SOFT_MISSING_OK=0 JSON_PARTIAL_OK=0 EPHEMERAL_FLAG=0
  case "$g" in
    streak)
      ALLOW_SYNTHETIC_SEGMENTS=1 REQUIRE_ALL_METRICS=0 HARD_STRICT=0 STRICT_PHASED=1 \
      SOFT_MISSING_OK=1 JSON_PARTIAL_OK=1 ;;
    governance) ;;
    explore)
      ALLOW_SYNTHETIC_SEGMENTS=1 REQUIRE_ALL_METRICS=0 HARD_STRICT=0 SOFT_MISSING_OK=1 \
      JSON_PARTIAL_OK=1 EPHEMERAL_FLAG=1 ;;
    ci) ;;
    *) g="streak";;
  esac
  export GOAL="$g" ALLOW_SYNTHETIC_SEGMENTS REQUIRE_ALL_METRICS HARD_STRICT STRICT_PHASED \
         SOFT_MISSING_OK JSON_PARTIAL_OK EPHEMERAL_FLAG
}
```

Missing metric handling (conceptual):

```
if [[ -z "${value:-}" ]]; then
  if (( REQUIRE_ALL_METRICS )); then
    zf::err "Metric '${metric}' missing (GOAL=${GOAL})"; MISSING_CRITICAL=1
  else
    zf::warn "Metric '${metric}' missing (tolerated; GOAL=${GOAL})"; PARTIAL_FLAG=1; continue
  fi
fi
```

Status JSON augmentation (new non-sensitive keys):

- `goal` (enum: `streak|governance|explore|ci`)
- `synthetic_used` (present only if synthetic fallback executed)
- `partial` (present only if tolerant profile had missing metrics)
- `ephemeral` (Explore only)

Governance activation precondition update:
- A8: Three consecutive `GOAL=Governance` runs with neither `synthetic_used` nor `partial` present.

Historical note:
Legacy classifier “observe” behavior (tolerant + synthetic) is now explicitly represented by `GOAL=Streak` (resilient) or `GOAL=Explore` (diagnostic), eliminating ambiguous implicit modes.

Rollout phases:
1. Docs (this section)
2. Scaffold parser & `goal` field (no behavior change)
3. Enforce synthetic gating & missing metric policy
4. Strictness layering
5. Emit conditional flags (`synthetic_used`, `partial`, `ephemeral`)
6. Test matrix (T-GOAL-01..06)
7. CI adoption (`GOAL=ci`)
8. Governance activation with A8

## Change Log

| Date       | Version | Change |
|------------|---------|--------|
| 2025-09-11 | 3.4 | Introduced classifier GOAL profiles (Streak/Governance/Explore/CI), added governance precondition A8, privacy appendix v1.1 (goal/partial/synthetic_used/ephemeral), documentation & internal flag mapping | 
| 2025-09-10 | 3.3 | Legacy underscore logging wrappers removed (homogeneity gate enforced); structured telemetry flags (ZSH_LOG_STRUCTURED, ZSH_PERF_JSON) introduced (opt-in, zero overhead by default) |
| 2025-09-10 | 3.2 | Sprint 2 kickoff instrumentation updates (deferred dispatcher, cycle edge-case tests, initial segment probe groundwork) |
| 2025-09-02 | 3.1 | Telemetry & deferred execution section (§2.2) expansion |
| 2025-01-03 | 3.0 | Initial consolidated implementation guide (migration to redesignv2) |

---

## Executive Summary

**Mission:** Refactor fragmented legacy ZSH configuration into a deterministic, test-driven, modular 19-file system with measurable performance improvements and comprehensive automation.

**Current State:**  
- Stage 3 completed (migration + stabilization baseline locked)  
- Stage 4 scaffolding initiated (feature registry, template, status command)  
- Unified test runner (`run-all-tests-v2.zsh`) fully adopted (legacy runner deprecated)  
- Performance baseline established (334ms, 1.9% variance) for delta gating in Stage 4  
- Compliance + policy headers embedded; drift detection active  
- Initial Feature Layer principles ratified (deterministic ordering, failure containment, opt-in/opt-out)  
- Proceeding with registry + contract test onboarding

**Key Metrics Achieved:**
- Performance: `334ms 1.9%` startup with micro-benchmark baseline `37-44µs`
- Governance: `guard: stable` status with comprehensive badge automation
- Structure: 8 pre-plugin + 11 post-plugin modules with 100% sentinel guards
- Automation: Nightly CI workflows maintaining badge freshness and drift detection
- Privacy & Telemetry: Structured telemetry flags opt-in (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`); Privacy Appendix (privacy/PRIVACY_APPENDIX.md) documents minimal schema & governance

---

### 1.2 Recent Achievements (Part 08.19)

- Deferred dispatcher skeleton (postprompt trigger, one-shot, telemetry `DEFERRED id=… ms=… rc=…`)
- Dependency cycle edge-case test suite (unknown deps, disabled suppression, multi-level cycles, cycle broken by disabled node)
- Cycle detector enhancements (scope limiting, disabled filtering toggle)
- Logging namespace migration completed (underscore wrappers removed; homogeneity test enforced)
- Telemetry / deferred execution documentation expansion (§2.2)
- Performance baseline reaffirmed (334ms, 1.9% variance; no regression)
- Telemetry governance tests added (baseline presence: `test-classifier-baselines.zsh`; structured schema validation: `test-structured-telemetry-schema.zsh`) – enforce-mode activation pending 3× consecutive OK classifier runs
- README segment sync automation tool (`tools/sync-readme-segments.zsh`) ensures REFERENCE §5.3 canonical segment table parity in README (drift prevention)

### 1.3 Next Steps (Sprint 2 Focus)
1. Replace placeholder SEGMENT probes with real pre/plugin/post/prompt/deferred attribution
2. Activate structured telemetry stubs (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) with no-op emit paths
3. Introduce structured telemetry stubs (JSON sidecar opt-in flag)
4. Performance regression harness & classifier (warn >10%, fail >25% observe mode)
5. Add Performance Log classifier legend (OK/WARN/FAIL thresholds) & integrate harness output notation
6. Dependency graph export (`zf::deps::export` + DOT renderer)
7. Privacy appendix + redaction hooks before enabling richer structured telemetry
8. Telemetry governance: integrate baseline & schema tests as gated CI step (ENFORCE_BASELINES + schema validation) and prepare enforce-mode flip after 3 consecutive OK runs
9. README canonical segment sync: add CI check (`tools/sync-readme-segments.zsh --check`) to prevent drift between REFERENCE §5.3 and README

---

## 1. Current Status & Progress

### 1.1 Stage Completion Status

| Stage | Status | Completion | Key Deliverables |
|-------|--------|------------|------------------|
| Stage 1 | ✅ Complete | 100% | Foundation, test infrastructure, tooling |
| Stage 2 | ✅ Complete | 100% | Pre-plugin content migration, path rules |
| Stage 3 | ✅ Complete | 100% | Runner migration, manifest test fix, variance guard |
| Stage 4 | 🟡 In Progress (Sprint 2) | ~25% | Feature layer: registry (done), deferred dispatcher skeleton, segment probes (pending), telemetry scaffolding (pending) |
| Stage 5 | ⏳ Pending | 0% | UI & completion enhancements |
| Stage 6 | ⏳ Pending | 0% | Promotion readiness validation |
| Stage 7 | ⏳ Pending | 0% | Production promotion & legacy archive |

### 1.2 Critical Metrics Dashboard

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Startup Performance** | 334ms | ≤300ms | ✅ Excellent (was misreported as 40s+) |
| **Variance RSD** | 1.9% | ≤5% | ✅ Stable |
| **Governance Status** | guard: stable | stable | ✅ Achieved |
| **CI Enforcement** | Active | Active | ✅ Operational |
| **Module Count** | 19/19 | 19 | ✅ Complete |
| **Test Coverage** | Comprehensive | 100% critical | ✅ Enhanced (zsh -f compatible) |
| **Badge Freshness** | Automated | Automated | ✅ Current |

#### Sprint 2 Tracks (Summary)

| Track | Goal | Success Metric |
|-------|------|----------------|
| Real Segment Probes | Replace placeholders with timing & phase fidelity | All core phases logged with non-zero ms (except negligible <1ms flagged) |
| Deferred Triggers Expansion | Prepare idle/background trigger design | Design doc + idle stub function present |
| Logging Homogeneity | Remove legacy underscore wrappers | Homogeneity test passes; `ZF_LOG_LEGACY_USED` absent |
| Perf Regression Harness | Automatic comparison vs baseline | Classifier emits WARN (>10%) / FAIL (>25%) lines |
| Dependency Export | Human + graph tooling | `zf::deps::export --dot` produces stable DOT |
| Structured Telemetry & Privacy | JSON sidecar (opt-in) + redaction | `ZSH_LOG_STRUCTURED=1` yields sanitized JSON lines |

### 1.3 Stage 3 Status Update (2025-01-13)

**🔧 Critical Issue Resolved**
- Previous 40+ second startup times were incorrect metrics reporting
- Actual shell startup performance verified at ~334ms (excellent)
- Comprehensive test suite execution now unblocked
- Migration checklist ready to proceed
- ZSH Testing Standards documented and integrated into AI guidelines
- **NEW:** Core function manifest test fixed for `zsh -f` compatibility (Part 08.18)

### 1.4 Stage 3 Achievements

**✅ Variance Guard & Automation**
- Variance guard active with streak 3/3 maintaining performance stability
- Nightly CI workflow `ci-variance-nightly.yml` runs N=5 captures and updates badges
- `make perf-update` target for local badge refresh and performance monitoring
- Automated badge updates via `tools/update-variance-and-badges.zsh`

**✅ Performance Monitoring**
- Performance badge: `334ms 1.9% • core 37-44µs` with micro-benchmark baseline
- Drift gating thresholds defined (warn >5%, fail >10%) in observe mode
- Historical performance tracking with 7-day stability window monitoring
- Drift guard flip preparation script for future enforcement enablement

**✅ CI Enforcement & Guards**
- Async activation checklist enforcement via `ci-async-guards.yml` workflow
- Single compinit execution validation across startup lifecycle
- No duplicate PROMPT_READY_COMPLETE emission verification
- Monotonic lifecycle constraints (pre ≤ post ≤ prompt, all non-zero) validated
- Configurable enforcement levels: observe/guard/promote

**✅ Documentation & Maintenance**
- Badge refresh instructions in main README with automation details
- Comprehensive progress tracking and future task prioritization
- Drift guard flip readiness assessment tooling
- Structured workflow for continuing Stage 4+ development
- ZSH Testing Standards (ZSH_TESTING_STANDARDS.md) established
- Testing standards integrated into AI guidelines at `dot-config/ai/guidelines/070-testing/090-zsh-testing-standards.md`
- Test Improvement Plan created with 8-week roadmap (testing/TEST_IMPROVEMENT_PLAN.md)
- Mistaken redirection issue resolved (files named `2` cleanup) with prevention measures
- **Manifest test fixed** for `zsh -f` compatibility (associative array syntax, debug function dependencies)
- **Core functions manifest updated** with missing `zf::exports` and `zf::script_dir` functions

---

## 2. Architecture Overview

### 2.1 Module Structure (19-File System)

**Pre-Plugin Phase (8 modules):**
```
.zshrc.pre-plugins.d.REDESIGN/
├── 01-error-handling-framework.zsh
├── 02-module-hardening.zsh  
├── 05-core-functions.zsh
├── 10-lazy-framework.zsh
├── 15-environment-setup.zsh
├── 20-path-management.zsh
├── 25-plugin-preparation.zsh
└── 30-performance-instrumentation.zsh
```

**Post-Plugin Phase (11 modules):**
```
.zshrc.d.REDESIGN/
├── 10-security-hardening.zsh
├── 20-essential-options.zsh
├── 30-development-environment.zsh
├── 40-runtime-optimization.zsh
├── 50-completion-history.zsh
├── 60-ui-enhancements.zsh
├── 70-performance-monitoring.zsh
├── 80-async-validation.zsh
├── 85-post-plugin-boundary.zsh
├── 90-cosmetic-finalization.zsh

### 2.2 Telemetry, Timing & Deferred Execution (Stage 4 Enhancements)

This section documents the emerging Stage 4 execution / measurement pipeline: how startup timing, policy checksum emission, and post‑prompt (deferred) tasks interoperate without regressing interactive readiness.

#### Overview

| Component | Purpose | Emission Form | When Recorded | File / Hook |
|-----------|---------|---------------|---------------|-------------|
| GUIDELINES_CHECKSUM | Policy integrity anchor | POLICY checksum=&lt;sha&gt; | Early pre‑plugin | `02-guidelines-checksum.zsh` |
| Segment Timings (placeholders now) | Budget label stabilization | `SEGMENT name=<label> ms=<int> phase=<phase>` | During guarded probes | Various phase stubs |
| Prompt Readiness Marker | Boundary for deferred dispatch eligibility | PROMPT_READY_MS env var | First successful `precmd` | `95-prompt-ready.zsh` |
| Deferred Dispatcher | Executes non-critical jobs post-first prompt | `DEFERRED id=<id> ms=<int> rc=<rc>` | First `precmd` after PROMPT_READY | `96-deferred-dispatch.zsh` |
| Dependency Cycle Scan (optional) | Safety net for module graph | `dependency-cycle:` errors (stderr) | On demand / test scope | `02-module-hardening.zsh` |
| Error / Severity Log | Structured fault surface (namespaced) | `[zf-error] ...` + optional PERF `ERROR level=...` | On each severity event | `01-error-handling-framework.zsh` |

#### Execution Phases (Simplified Timeline)

```
[zsh start]
  -> Pre-plugin modules
       - policy checksum export (POLICY line)
       - (future) early segment markers (pre_plugin_total)
  -> Plugin / post-plugin modules
       - placeholder sync segments
  -> Prompt instrumentation (95-prompt-ready) sets PROMPT_READY_MS
  -> First prompt rendered (interactive control handed to user)
  -> Deferred dispatcher (96-deferred-dispatch) runs queued jobs exactly once
       - Emits DEFERRED timing lines (phase=postprompt logical bucket)
```

#### Deferred Dispatcher (Skeleton – Current Scope)

| Aspect | Current Behavior | Roadmap |
|--------|------------------|---------|
| Registration API | `zf::defer::register <id> <func> postprompt <desc>` | Additional triggers: idle, background-safe, network |
| Launch Condition | First `precmd` after `PROMPT_READY_MS` | Multi-trigger with prioritization |
| Overhead Target | ≤ ~1–2ms definition cost; zero pre-prompt runtime | Fine-grained attribution + budget gating |
| Telemetry | Per-job ms duration → PERF_SEGMENT_LOG (DEFERRED line) | Structured JSON stream |
| Isolation | Silent; logs to `${ZDOTDIR}/.logs/deferred.log` | Failure classification + retry/backoff policies |
| Non-interactive Guard | `$-` contains `i` required | Remote batch fallback queue (later) |

#### Telemetry & Performance Emission Formats (Current + Classifier Integration)

```
POLICY checksum=<sha256>
SEGMENT name=<label> ms=<int> phase=<phase> sample=<mode?>
DEFERRED id=<id> ms=<int> rc=<rc>
ERROR level=<LEVEL> module=<module>
```

The `SEGMENT` line family now underpins the multi-metric performance classifier.  
Structured JSON sidecar records (when `ZSH_LOG_STRUCTURED=1`) mirror each textual SEGMENT with keys:
`{"type":"segment","name":"<label>","ms":<int>,"phase":"<phase>","sample":"<context>","ts":<epoch_ms>}`

##### Canonical Segment Inventory (Sprint 2)

| Segment | Phase | Module | Purpose |
|---------|-------|--------|---------|
| pre_plugin_start | pre_plugin | 00-path-safety (pre) | Anchor (start reference) |
| pre_plugin_total | pre_plugin | 40-pre-plugin-reserved | Aggregate pre-plugin elapsed |
| post_plugin_total | post_plugin | 85-post-plugin-boundary / 90-splash | Aggregate functional post-plugin elapsed |
| prompt_ready | prompt | 95-prompt-ready | Time to first prompt (TTFP) |
| deferred_total | postprompt | 96-deferred-dispatch | Aggregated deferred batch |
| essential/zsh-syntax-highlighting | post_plugin | 20-essential-plugins | Plugin attribution |
| essential/zsh-autosuggestions | post_plugin | 20-essential-plugins | Plugin attribution |
| essential/zsh-completions | post_plugin | 20-essential-plugins | Plugin attribution |
| history/baseline | post_plugin | 50-completion-history | History & policy |
| safety/aliases | post_plugin | 40-aliases-keybindings | Alias setup |
| navigation/cd | post_plugin | 40-aliases-keybindings | Navigation helpers |
| dev-env/nvm | post_plugin | 30-development-env | Toolchain surfacing |
| dev-env/rbenv | post_plugin | 30-development-env | Toolchain surfacing |
| dev-env/pyenv | post_plugin | 30-development-env | Toolchain surfacing |
| dev-env/go | post_plugin | 30-development-env | Toolchain surfacing |
| dev-env/rust | post_plugin | 30-development-env | Toolchain surfacing |
| completion/history-setup | post_plugin | 50-completion-history | History initialization |
| completion/cache-scan | post_plugin | 50-completion-history | Compinit cache inspection |
| compinit | post_plugin | 55-compinit-instrument | Single guarded compinit |
| p10k_theme | post_plugin | 60-p10k-instrument | Prompt theme init |
| gitstatus_init | post_plugin | 65-vcs-gitstatus-instrument | Git status daemon |
| ui/prompt-setup | post_plugin | 60-ui-prompt | Prompt orchestration placeholder |
| security/validation | post_plugin | 80-security-validation | Integrity placeholder |

(Full authoritative table also maintained in REFERENCE §5.3.)

##### Disable Flags (Selective Suppression)

| Flag | Suppresses Segments | Default |
|------|---------------------|---------|
| ZSH_DISABLE_ALIASES_KEYBINDINGS=1 | safety/aliases, navigation/cd | Off |
| ZSH_DISABLE_UI_PROMPT_SEGMENT=1 | ui/prompt-setup | Off |
| ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT=1 | security/validation | Off |

Disabling a segment does NOT disable its module sentinel; tests assert suppression behavior separately.

##### Multi-Metric Classifier Integration

Classifier script: `tools/perf-regression-classifier.zsh`

| Metric Key (JSON) | Derived From | Segment Basis | Typical Baseline | Warn / Fail Thresholds |
|-------------------|--------------|---------------|------------------|------------------------|
| pre_plugin_total_ms | Time between pre-plugin anchors | pre_plugin_total | ~45ms | 10% / 25% |
| post_plugin_total_ms | Functional post-plugin window | post_plugin_total | ~185ms | 10% / 25% |
| prompt_ready_ms | Startup to first prompt | prompt_ready | 334ms | 10% / 25% |
| deferred_total_ms | Deferred dispatcher batch | deferred_total | ~30ms | 10% / 25% (high slack) |

Overall status = worst (FAIL > WARN > OK/Base).  
First run per metric without an existing baseline ⇒ `BASELINE_CREATED` (green).

##### Baseline Integrity (Planned / Implemented)

| Aspect | Mechanism |
|--------|-----------|
| Segment presence & format | `test-granular-segments.zsh` |
| Duplicate prevention | Same test (count == 1) |
| Disable flag suppression | Added section in granular segments test |
| Per-metric baseline existence | Future classifier baseline presence test |
| JSON key whitelist | Planned sanitation test (privacy enforcement) |

##### Policy to Add a New Segment

1. Justify attribution or governance necessity.  
2. Implement single guarded emission (no loops).  
3. Update REFERENCE §5.3 + this section.  
4. Extend granular segment & disable tests.  
5. Run classifier (observe mode) to confirm benign delta.  
6. Append PERFORMANCE_LOG entry if synchronous delta ≥1ms (otherwise note “+0”).  


(All appended to `$PERF_SEGMENT_LOG` when writable.)

#### Adding a New Deferred Job (Example)

```zsh
# Define the job
my__cache_warm_job() {
  # light, silent work here
  command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1 || true
}

# Register (postprompt trigger)
zf::defer::register "cache-warm" "my__cache_warm_job" "postprompt" "Light cache warm priming"
```

#### Design Invariants

1. No deferred job may emit user-facing output to stdout/stderr (logs only).
2. Dispatcher must not re-run (idempotent; guard `_ZSH_DEFERRED_DISPATCH_RAN`).
3. Pre-prompt critical path must remain < existing variance thresholds (currently ~334ms, 1.9% RSD).
4. Telemetry lines must remain parse-stable (regex compatibility with CI parsers).
5. Policy checksum must precede any deferred reference to ensure integrity context is available downstream.

#### Privacy & Scope

Current telemetry is local-only:
- No network transmission.
- Plaintext append to PERF segment log + optional local deferred log.
- Redaction not presently required; future structured mode will add redaction hooks before enabling richer content.

#### Testing Guidance

| Test Type | Focus | Example Assertion |
|-----------|-------|-------------------|
| Design / Structure | One-shot dispatch | Log contains single DEFERRED id=dummy-warm |
| Performance | No added pre-plugin delta | Compare pre_plugin_total variance before/after |
| Dependency Edge Cases | Disabled / unknown / cycle resilience | Cycle absent when disabled node breaks chain |
| Namespace Homogeneity (logging) | Use of `zf::` API only | Grep ensures no stray `zf_warn` etc (excluding wrapper block) |

#### Future Enhancements (Planned)

- Idle time budgeted queue (increments after user keystrokes settle)
- Adaptive backoff for failed jobs (exponential with cap)
- Structured JSON ledger: `{"type":"deferred","id":"…","ms":12,"ts":...}`
- Optional export command: `zf::telemetry::export --format=jsonl`
- Telemetry gating flag: `ZSH_TELEMETRY_OPTOUT=1` (placeholder design)
- Telemetry JSON key sanitation test (A): whitelist enforcement (planned CI gate) to fail on unexpected structured segment fields
- Per-metric baseline presence test (B): classifier guard to ensure each tracked metric has an up-to-date baseline before enforcing drift
- README cross-link automation (C): script to sync canonical segment & classifier table (REFERENCE §5.3 → README badges/legend)
- Structured telemetry schema validator script (D): `tools/test-structured-telemetry-schema.zsh` – denies unknown keys, emits diff of allowed vs observed

---

└── 95-prompt-ready.zsh
```

### 2.2 Key Design Principles

### 2.3 Feature Layer Architecture (Stage 4 Kickoff)

The Feature Layer introduces an opt-in, modular capability stack above the stabilized core. Its design enforces deterministic loading, failure containment, and measurable performance impact.

Core Components:
1. Feature Registry (`feature/registry/feature-registry.zsh`)
   - Stores metadata: phase, dependencies, category, deferred flag, GUID.
   - Provides add/list/resolve functions with cycle detection (topological sort).
   - Caches enablement decisions (per session) to minimize repeated dispatch cost.

2. Feature Module Contract (see `_TEMPLATE_FEATURE_MODULE.zsh`)
   - Required metadata variables (single-line for grep extraction).
   - Required functions (by naming convention):
     - `feature_<name>_metadata`
     - `feature_<name>_is_enabled`
     - `feature_<name>_register`
     - `feature_<name>_init` (primary activation point)
   - Optional: `preload`, `postprompt`, `teardown`, `self_check`, failure injection helper.

3. Enable / Disable Semantics (precedence order)
   - `ZSH_FEATURES_DISABLE` (supports `all`)
   - `ZSH_FEATURES_ENABLE`
   - Per-feature override: `ZSH_FEATURE_<UPPER_NAME>_ENABLED`
   - Fallback to `FEATURE_DEFAULT_ENABLED`

4. Load Phases (planned)
   - Phase 1: Critical early UX scaffolding (minimal prompt base)
   - Phase 2: Standard interactive features (history, completion augmentation, keybindings)
   - Phase 3: Deferred / async (fzf integrations, telemetry, heavy scans)

5. Performance Guardrails
   - Baseline: 334ms cold start (Stage 3 reference)
   - Hard ceiling (early Stage 4): +15% (< ~384ms) – failing CI (planned enforcement gate)
   - Soft per-feature synchronous budget: 20ms (warn + defer recommendation)
   - Telemetry is opt-in to avoid skewing baseline; timing wrappers to be introduced after stable registry adoption.

6. Failure Containment Strategy
   - Each feature invocation (future implementation) wrapped in:
     - Timing capture (optional)
     - `set -e`–resilient boundary with non-zero exit logged but not fatal
   - A failing feature must not abort shell startup; registry resolution isolates dependency-related fallout.

7. Testing Additions (Stage 4)
   - Registry contract tests (present)
   - Enable/disable semantics tests (planned)
   - Dependency + cycle detection tests (present)
   - Failure containment + injected error path tests (planned)
   - Performance delta tests (planned once invocation wrapper added)
   - Deferred load validation (will follow postprompt hook integration)

8. Observability & Introspection
   - `feature-status.zsh` provides:
     - Table / raw / JSON output
     - Summary counts
     - Lightweight self-check
   - Future: per-feature timing & phase execution ledger (opt-in)

9. Compliance & Policy
   - Each module carries checksum-referenced compliance header.
   - Sensitive operations (PATH mutation, external process spawn) will cite exact guideline file + line references inline when introduced.

10. Planned Next Increments
   - Add invocation wrapper + timing
   - Implement noop demo feature (contract exemplar)
   - Add enable/disable + dependency edge-case test suite
   - Integrate performance delta harness extension
   - Author Feature Catalog + Developer Guide (tracked in Stage 4 kickoff doc)

This section will evolve as invocation and deferred scheduling mechanisms are implemented; all structural changes require synchronized updates to the Feature Catalog and Task Tracker.

1. **Deterministic Loading:** Sequential numbered modules with clear dependencies
2. **Sentinel Guards:** Every module protected against multiple sourcing
3. **Performance First:** Lazy loading, deferred heavy operations, instrumented hotspots
4. **Test-Driven:** Comprehensive test coverage across 6 categories
5. **Automated Governance:** CI-driven badge system with drift detection
6. **Rollback Ready:** Checksum validation and recovery mechanisms

---

## 3. Performance & Monitoring

### 3.1 Current Performance Profile

**Lifecycle Segments (Mean from N=5 samples):**
- `pre_plugin_cost_ms`: 99ms (RSD: 2.1%)
- `post_plugin_total_ms`: 334ms (RSD: 1.9%) 
- `prompt_ready_ms`: 334ms (RSD: 1.9%)

**Micro-Benchmark Baseline:**
- Core functions: 37-44µs per call
- Status: Baseline captured and surfaced in performance badge
- Coverage: All critical helper functions benchmarked

**Hotspot Instrumentation:**
- `compinit`: Completion system initialization
- `p10k_theme`: Theme loading and configuration
- `zgenom-init`: Plugin manager overhead
- Module-specific: Individual post-plugin module timing

### 3.2 Variance Tracking & Gating

**Current Status:** Variance Guard Active ✅
- Mode: `guard` (promoted from observe)  
- Streak: 3/3 consecutive stable batches
- RSD Target: ≤5% for warn transition, ≤25% for gate
- Outlier Policy: Drop samples >2x median

**Drift Detection:** Observe Mode
- Warn Threshold: >5% performance regression
- Fail Threshold: >10% performance regression  
- Status: Monitoring only, enforcement after 7-day stability
- Assessment: `tools/prepare-drift-guard-flip.zsh` for readiness evaluation

**Automation:**
- Nightly captures: `ci-variance-nightly.yml` at 04:15 UTC
- Badge refresh: Automated via `tools/update-variance-and-badges.zsh`
- Local updates: `make perf-update` for manual refresh

---

## 4. Testing & Quality Assurance

### 4.1 Test Categories & Coverage

| Category | Status | Count | Purpose |
|----------|---------|-------|---------|
| **Design** | ✅ Active | ~15 | Structural integrity, sentinel guards |
| **Unit** | ✅ Active | ~25 | Individual function validation |
| **Feature** | ✅ Active | ~20 | End-to-end functionality |
| **Integration** | ✅ Active | ~30 | Cross-module interaction |
| **Security** | ✅ Active | ~10 | Integrity, path validation |
| **Performance** | ✅ Active | ~15 | Startup time, variance, regression |

### 4.2 CI Enforcement

**Active Workflows:**
- `ci-async-guards.yml`: Async activation checklist validation
- `ci-variance-nightly.yml`: Performance monitoring and badge refresh
- `ci-perf-segments.yml`: Comprehensive multi-sample analysis
- `ci-perf-ledger-nightly.yml`: Historical performance tracking

**Enforcement Levels:**
- **Observe:** Run checks, warn on violations (current for drift)
- **Guard:** Fail on violations (current for async checklist)  
- **Promote:** Full enforcement with no exceptions (planned)

---

## 5. Badge System & Governance

### 5.1 Current Badge Status

**Core Badges:**
- **Performance:** `334ms 1.9% • core 37-44µs` (Green)
- **Governance:** `guard: stable` (Green)  
- **Variance:** `guard` mode with streak 3/3 (Green)
- **Drift:** `observe` mode, no current regressions (Grey)
- **Structure:** All modules with sentinel guards (Green)

**Badge Refresh:**
- **Automated:** Nightly via CI workflows
- **Manual:** `make perf-update` or direct script execution
- **Monitoring:** Drift detection with configurable thresholds

### 5.2 Governance Integration

**Variance State Tracking:**
- File: `docs/redesignv2/artifacts/metrics/variance-gating-state.json`
- Current: `{"mode":"guard","stable_run_count":3}`
- Integration: Feeds governance badge and drift detection

**Performance Tracking:**
- Samples: `docs/redesignv2/artifacts/metrics/perf-multi-simple.json`
- History: `docs/redesignv2/artifacts/metrics/ledger-history/`
- Analysis: Automated trend analysis and regression detection

---

## 6. Future Tasks (Prioritized by Cost-Benefit)

### 6.1 High Priority (Score: 85-100)

**Stage 4 Core Implementation (Score: 95)**
- Implement remaining feature layer modules (40-70 series)
- Critical for advancing to Stage 5 and async activation
- High impact on overall project completion

**Test Suite Enhancement per ZSH Testing Standards (Score: 92)**
- Implement comprehensive test coverage per ZSH_TESTING_STANDARDS.md
- Add unit tests for individual functions with mocking support
- Enhance integration tests with proper isolation and cleanup
- Implement performance regression tests with statistical validation
- Add security validation tests for permission and sanitization checks
- Follow 8-week implementation plan in testing/TEST_IMPROVEMENT_PLAN.md
- Critical for Stage 3 exit and production readiness

**Drift Guard Activation (Score: 90)**  
- Enable drift enforcement after 7-day stability window
- Automated performance regression prevention
- High value for long-term stability maintenance

**Async Activation (Score: 88)**
- Enable async facilities after checklist validation
- Significant performance improvement potential  
- Requires completion of async activation checklist validation

### 6.2 Medium Priority (Score: 60-84)

**Test Framework Improvements (Score: 78)**
- Implement proper test isolation with setup/teardown hooks
- Add parallel test execution support for faster CI runs
- Create test fixture management system for consistent test data
- Enhance test reporter with structured output and failure details
- Aligns with ZSH Testing Standards documentation

**Micro-Benchmark Gating (Score: 75)**
- Enable performance regression detection at function level
- Warn >2x baseline, fail >3x baseline
- Requires shim elimination (current shimmed_count >0)

**Advanced Multi-Run Harness (Score: 72)**
- Replace simple harness with full advanced harness
- Better variance detection and outlier handling
- Foundation for more sophisticated performance analysis

**Shim Elimination (Score: 70)**
- Replace all shimmed functions with real implementations
- Required for micro-benchmark gating activation
- Enables more precise performance measurement

**Historical Drift Analysis (Score: 68)**
- Implement trend analysis over extended periods
- Early warning system for gradual performance degradation
- Supports proactive optimization decisions

**Test Coverage Metrics (Score: 65)**
- Implement code coverage tracking for ZSH scripts
- Set minimum coverage thresholds (80% target)
- Generate coverage reports for CI and local development
- Track coverage trends over time

### 6.3 Lower Priority (Score: 40-59)

**Test Documentation Generation (Score: 58)**
- Auto-generate test documentation from test descriptions
- Create test matrix showing coverage across different scenarios
- Generate test execution reports with trends
- Supports testing standards compliance tracking

**Schema Versioning (Score: 55)**
- Add JSON schema validation to performance artifacts
- Better artifact integrity and compatibility
- Supports future tooling evolution

**Performance Percentiles (Score: 52)**
- Add P50/P90/P95 percentile tracking to variance analysis
- More sophisticated statistical analysis
- Better outlier detection and handling

**Badge SVG Generation (Score: 50)**
- Generate static SVG badges for offline documentation
- Improved documentation presentation
- Lower priority given Pages integration works well

**Multi-Source Governance (Score: 48)**
- Integrate additional data sources into governance badge
- More comprehensive health assessment
- Complex implementation with moderate benefit

### 6.4 Optional/Experimental (Score: 20-39)

**Noise Filtering Enhancement (Score: 35)**
- Advanced outlier detection with multiple algorithms
- Experimental statistical methods
- Uncertain benefit vs implementation complexity

**Distributed Performance Testing (Score: 30)**
- Multi-environment performance validation
- Complex setup with limited immediate value
- Better suited for later optimization phases

**Advanced Visualization (Score: 25)**
- Performance trend graphs and dashboards  
- Nice-to-have but not essential for core functionality
- High implementation cost for moderate benefit

**External Integration Hooks (Score: 22)**
- Slack/email notifications for performance events
- Convenient but not critical for core workflow
- Lower priority given existing CI notification systems

---

## 7. Stage 4+ Roadmap

### 7.1 Stage 4: Feature Layer (Next Phase)

**Objectives:**
- Complete remaining post-plugin modules (40-80 series)
- Implement full feature set in redesigned architecture
- Maintain performance targets throughout implementation

**Key Deliverables:**
- Development environment configuration (30-dev-env.zsh)
- Runtime optimization (40-runtime-optimization.zsh) 
- UI enhancements (60-ui-enhancements.zsh)
- Performance monitoring integration (70-performance-monitoring.zsh)

**Success Criteria:**
- All feature modules implemented and tested
- Performance regression <5% from current baseline
- All badges remain green throughout implementation
- Comprehensive test coverage maintained

### 7.2 Stage 5: UI & Async Activation

**Objectives:**
- Activate async facilities after checklist validation
- Complete UI and completion system integration
- Enable full asynchronous background operations

**Prerequisites:**
- Stage 4 completion with stable performance
- 7-day drift detection stability window
- All async activation checklist items verified
- Variance guard maintained throughout transition

### 7.3 Stage 6: Promotion Readiness

**Objectives:**
- Final validation and promotion preparation
- Legacy system retirement planning  
- Production deployment readiness

**Key Activities:**
- Comprehensive system validation
- Performance optimization final tuning
- Documentation completion and review
- Migration strategy finalization

---

## 8. Maintenance & Operations

### 8.1 Regular Monitoring

**Daily (Automated):**
- Nightly CI workflows for badge refresh
- Performance variance tracking and outlier detection  
- Drift analysis with threshold monitoring
- Governance status assessment

**Weekly (Manual Review):**
- Performance trend analysis via `make perf-update`
- Badge status review for any degradations
- CI workflow health check and optimization
- Documentation updates as needed

**Monthly (Strategic Review):**
- Stage progression planning and prioritization
- Future task cost-benefit reassessment
- Performance target adjustment based on data
- Rollback procedure validation and updates

### 8.2 Badge Refresh Procedures

**Automated Refresh:**
- Nightly: `ci-variance-nightly.yml` at 04:15 UTC
- Triggered: On main branch performance-related commits
- Emergency: Manual workflow dispatch available

**Manual Refresh:**
- Local: `make perf-update` (N=5 capture + badge update)
- Direct: `ZDOTDIR=dot-config/zsh zsh tools/update-variance-and-badges.zsh`
- Emergency: Individual badge script execution as needed

**Troubleshooting:**
- Stale badges: Use manual refresh procedures above
- Failed CI: Check workflow logs and re-run if transient
- Performance alerts: Investigate via drift analysis tools

---

## 9. Risk Management & Rollback

### 9.1 Current Risk Posture: Controlled ✅

**Active Mitigations:**
- Rollback mechanisms tested and documented
- Checksum validation for integrity verification
- Automated performance regression detection
- Comprehensive test coverage preventing regressions

**Monitoring:**
- Real-time CI feedback on all changes
- Performance variance tracking with alerting
- Badge system provides immediate visual feedback
- Historical tracking enables trend analysis

### 9.2 Rollback Procedures

**Performance Degradation:**
1. Identify regression source via drift analysis
2. Revert specific commit or disable problematic module
3. Verify performance recovery via `make perf-update`
4. Update documentation and lessons learned

**Structural Issues:**
1. Use promotion guard for immediate validation
2. Leverage test suite for regression identification
3. Apply sentinel guard rollback if module issues
4. Restore from last known good configuration

**Emergency Procedures:**
- Legacy fallback available via environment toggle
- Individual module disable capability maintained
- Comprehensive logging for post-incident analysis
- Automated recovery procedures where feasible

---

## 10. Conclusion & Next Steps

### 10.1 Current Achievement Summary

The ZSH configuration redesign has successfully completed Stage 3 with:

- **Variance guard active** (streak 3/3) providing stable performance monitoring
- **Comprehensive automation** via CI workflows maintaining badge freshness
- **Performance optimization** achieving 334ms startup with micro-benchmark baseline
- **Quality assurance** through extensive test coverage and CI enforcement
- **Future-ready architecture** positioned for async activation and feature completion

### 10.2 Immediate Next Actions

1. **Begin Stage 4 Implementation:** Start feature layer module development
2. **Monitor Drift Detection:** Prepare for guard flip after 7-day stability window  
3. **Maintain Automation:** Ensure nightly workflows continue badge refresh
4. **Plan Async Activation:** Prepare for async facility enablement
5. **Document Progress:** Keep implementation tracking current and accurate

### 10.2.1 Git-flow guidance and recommended branch workflow

To remain consistent with the project's use of Git Flow, follow this lightweight, explicit workflow for feature development, CI validation, and promotion to main production enforcement:

1. Work on a feature branch (naming convention: `feature/<short-desc>` or `hotfix/<short-desc>` for urgent fixes).
   - Example: `feature/zsh-refactor-configuration`
   - Keep commits focused and testable; run the integration runner and perf smoke locally before pushing.

2. Push the completed feature branch to the remote and open a Pull Request targeting `develop`.
   - PR base: `develop`
   - PR head: `feature/<name>`
   - Mark as Draft while still iterating; convert to Ready for review when stable.

3. Let CI validate the feature branch and `develop`:
   - Ensure the integration tests pass (compinit single-run, prompt single emission, monotonic lifecycle).
   - Confirm nightly ledger capture runs and that `develop` accumulates ledger snapshots (CI will create the real `perf-ledger-YYYYMMDD.json` files).
   - Use PR feedback loops to iterate until CI is consistently green.

4. Merge feature -> develop when:
   - Integration tests pass locally and in CI.
   - The feature's behavior is validated (no regressions, no structural breakage).
   - Any documentation changes (README / IMPLEMENTATION) are included.

5. Validate stability on `develop` for the 7-day gate:
   - Let CI produce daily ledger snapshots for seven consecutive nights in `docs/redesignv2/artifacts/metrics/ledger-history/` (or store them as retained CI artifacts).
   - Ensure integration tests remain green across pushes to `develop`.
   - Collect and attach evidence (drift badge, `stage3-exit-report.json`, the last 7 ledger snapshots, microbench baseline) when preparing to flip enforcement.

6. Promote to main (separate PR):
   - Once the 7-day stability gate and CI validation are satisfied on `develop`, open a targeted PR to `main` that *enables* enforcement flags such as `PERF_DIFF_FAIL_ON_REGRESSION=1`.
   - This PR should include the evidence bundle and a clear rollback plan.

7. Rollback & remediation:
   - If a regression appears after enabling enforcement, open a remediation PR to revert the enforcement change and include instructions to temporarily set `PERF_DIFF_FAIL_ON_REGRESSION=0` (or revert the main PR).
   - Add temporary observability toggles (increase `stable_run_count`, set `VARIANCE_LOG_LEVEL=debug`) while investigating.

Rationale and benefits
- Keeps feature development isolated and reviewable.
- Ensures `develop` is the CI-validated staging area where the 7-day ledger history accumulates.
- Keeps the `main` branch reserved for production enforcement changes that should only be made after provable stability.
- Enables a clear, auditable roll-forward / roll-back plan for enforcement toggles.

Notes on seeded ledger snapshots and CI-generated artifacts
- Seeded snapshots in `docs/redesignv2/artifacts/metrics/ledger-history/` are acceptable for local testing and documentation, but CI should be the source of truth for the 7-day stability gate.
- Recommendation:
  - Keep only explicit, small "seed" snapshots committed (clearly labeled as seeds) for developer onboarding and quick validation.
  - Do NOT commit CI-generated daily ledgers produced by the nightly job; instead:
    - Either retain them as CI artifacts that can be downloaded for evidence, or
    - Provide an automated process (script in CI) that, upon stable collection of 7 days, bundles evidence into a release branch or an artifacts location for PR attachment.
- Update README and IMPLEMENTATION to clarify that:
  - Seeds are for local validation only and are not the canonical ledger history.
  - CI is responsible for writing the authoritative ledger snapshots used for the 7-day gate and enforcement decision.

How this affects documentation
- `dot-config/zsh/docs/redesignv2/IMPLEMENTATION.md`
  - Add and maintain the Git-flow guidance and the ledger snapshot policy (this section).
  - Clarify the roles of `develop` (staging/validation) vs `main` (production enforcement) in the promotion process.

- `dot-config/zsh/docs/redesignv2/README.md`
  - Add a short note explaining the ledger snapshot policy:
    - Seed snapshots are included for examples/testing.
    - The CI nightly job produces authoritative daily ledgers and should be used when preparing enforcement PRs.
  - Point to the Git-flow guidance maintained in `IMPLEMENTATION.md` for the branch/PR process.

Adopting this Git-flow guidance will keep promotion decisions auditable and minimize surprise enforcement flips on `main`. Follow the checklist above before enabling strict enforcement on `main`.

---

## Fast-track: In-branch activation & full redesign task list

Goal: implement and activate the complete redesign in this feature branch (opt-in via feature flag), then iterate QA and testing until ready to merge to `develop`. Activation default: feature-flag protected (`ZSH_USE_REDESIGN=1`) and fail‑soft behavior for regressions.

Activation summary
- Activation mode: opt-in via environment variable `ZSH_USE_REDESIGN=1` (default off).
- Target: run redesign locally (interactive) and in dedicated CI job(s) in this branch only.
- Rollback: fail-soft by default; emergency toggle `ZSH_USE_REDESIGN=0` or CI env `PERF_DIFF_FAIL_ON_REGRESSION=0` for rapid disable.

Fast-track task table (P0 = highest priority)

| ID | Title | Description | Files to add / modify | Local test command(s) | CI step(s) | Tests | Acceptance criteria | Dependencies | Owner | ETA |
|-----|-------|-------------|------------------------|-----------------------|------------|-------|---------------------|--------------|-------|-----|
| FT-01 | Enable feature-flag gating | Add global opt-in flag and early switchpoints | `dot-config/zsh/.zshenv`, `dot-config/zsh/init.zsh` (feature toggle read) | `env ZSH_USE_REDESIGN=1 zsh -i -c 'echo $ZSH_USE_REDESIGN'` | Add `ZSH_USE_REDESIGN` option to CI job env | none | Redesign code paths conditional on `ZSH_USE_REDESIGN` – default unchanged | None | s-a-c | 1h |
| FT-02 | Implement module 40 runtime optimization | Implement runtime optimizations and sentinel guards | `dot-config/zsh/.zshrc.d.REDESIGN/40-runtime-optimization.zsh` (+ test) | `./dot-config/zsh/tests/unit/test-40-runtime.zsh` | run unit tests in CI job | unit + integration | Module loads with sentinel; no errors; behavior behind flag | FT-01 | s-a-c | 4h |
| FT-03 | Implement module 50 completion/history | Port completion/history logic from legacy design | `.../50-completion-history.zsh` (+ integration test) | `./dot-config/zsh/tests/integration/test-compinit-single-run.zsh` | CI integration job (flag=1) | integration | Single compinit runs; compdump stable | FT-01 | s-a-c | 6h |
| FT-04 | Implement module 60 UI & prompt | Port prompt/UI features (p10k wiring) | `.../60-ui-enhancements.zsh` (+ prompt test) | `./dot-config/zsh/tests/integration/test-prompt-ready-single-emission.zsh` | CI runs prompt test (flag=1) | integration | Prompt emits expected single emission; no duplicate markers | FT-01, FT-03 | s-a-c | 6h |
| FT-05 | Ensure sentinel guards & idempotency | Audit all modules, add sentinel guards | Modules dir files | run `run-all-tests` unit/integration | Run unit/integration in CI job | unit + integration | No module re-source or duplicate side-effects | FT-01 | s-a-c | 3h |
| FT-06 | Remove/replace shims (microbench) | Replace shimbed helpers used by bench with real impls | `dot-config/zsh/bench/*` and module implementations | Run bench baseline (`bench-core-functions.zsh`) | Run bench job in CI branch job | bench | `shimmed_count == 0` and stable medians | FT-02, FT-04 | s-a-c | 1-2 days |
| FT-07 | Micro-bench baseline commit | Capture bench baseline with no shims | `docs/.../bench-core-baseline.json` | Run bench harness locally | CI bench job stores baseline | bench | Baseline JSON committed as seed and verified locally | FT-06 | s-a-c | 2-4h |
| FT-08 | Async: shadow-mode validation | Run async behavior in shadow mode and compare deltas | Add tests under `tests/performance/test-async-shadow-mode.zsh` | `ASYNc_MODE=shadow ./run-integration-tests...` | CI nightly shadow capture job (flag=1) | performance | Shadow delta <= threshold; no functional regressions | FT-02, FT-03, FT-04 | s-a-c | 1 day |
| FT-09 | Async: controlled activation steps | Add CI switch and staged activation plan (canary) | CI workflow updates: `.github/workflows/*` | Trigger CI with `ZSH_USE_REDESIGN=1` for branch | Add optional job(s) that run redesign paths | integration + perf | Canary runs succeed; no critical regressions | FT-08 | s-a-c | 4-8h |
| FT-10 | Migration helper script | Add convenience script to toggle redesign locally and back up existing config | `tools/migrate-to-redesign.sh` + README snippet | `tools/migrate-to-redesign.sh --enable` | optional run in CI (manual) | none | Script creates backup, sets ZDOTDIR override for local shell | FT-01 | s-a-c | 2h |
| FT-11 | Artifact bundler for 7-day evidence | Workflow to bundle last 7 ledger artifacts for PR attachment | `.github/workflows/bundle-ledgers.yml` | N/A locally | `workflow_dispatch` & scheduled bundling | none | Creates zip with 7 ledgers for PR | CI artifact retention | s-a-c | 4h |
| FT-12 | QA harness & extended tests | Add longer QA suite to run monotonic lifecycle and historical stability tests | `dot-config/zsh/tests/performance/*` | run `./dot-config/zsh/tests/run-all-tests.zsh --perf-only` | CI nightly job for branch-level QA | perf + integration | All QA tests pass; no monotonic violations | FT-06, FT-08 | s-a-c | 1-2 days |
| FT-13 | Documentation & activation guide | Update IMPLEMENTATION.md + README with Activation & Rollback steps | `docs/redesignv2/*` (this file) + README | N/A | N/A | docs review | Clear activation & rollback steps present | FT-01 | s-a-c | 2h |
| FT-14 | Performance regression guard flip plan | Prepare enforcement PR checklist and remediation PR template | `.github/PULL_REQUEST_TEMPLATE.md` | N/A | N/A | docs | PR checklist ready and template present | FT-11, FT-12 | s-a-c | 2h |

Notes:
- All tasks are owned by `s-a-c` by default (you can assign others later).
- ETA times are conservative estimates; parallelization will reduce calendar time.
- Priority labeling: all above are P0 for the fast-track (must complete before enabling redesign broadly).

Activation checklist (quick)
1. Enable redesign locally:
   - Backup current config: `tools/migrate-to-redesign.sh --backup`
   - Enable redesign: `export ZSH_USE_REDESIGN=1`
   - Start a clean shell: `env -i ZDOTDIR=$PWD /bin/zsh -i -f`
2. Run local smoke tests:
   - `./dot-config/zsh/tests/run-integration-tests.sh --timeout-secs 30 --verbose`
   - `./dot-config/zsh/tools/perf-capture-multi.zsh -n 1 --no-segments --quiet`
3. If issues arise, disable: `export ZSH_USE_REDESIGN=0` and `tools/migrate-to-redesign.sh --restore`
4. For CI, run the branch-only redesign job with `ZSH_USE_REDESIGN=1` and observe artifacts and logs.

Emergency rollback commands
- Disable redesign in your session: `export ZSH_USE_REDESIGN=0`
- Restore previous dotfiles snapshot (created by migration script):
  - `tools/migrate-to-redesign.sh --restore`
- If enforcement flips accidentally in CI, create remediation PR using `.github/PULL_REQUEST_TEMPLATE.md` and set `PERF_DIFF_FAIL_ON_REGRESSION=0` until triage completes.

QA plan in-branch (summary)
- Use opt-in flag to exercise redesign locally and in branch CI.
- Keep all enforcement disabled (fail-soft): `PERF_DIFF_FAIL_ON_REGRESSION` remains `0` in branch CI.
- Run nightly branch CI that uploads ledger artifacts (retention >= 7 days) and use `bundle-ledgers.yml` to create an evidence zip.
- Iterate on modules and tests until all QA and perf tests are green in branch CI for an observation window (recommended: 7 days).
- After signoff, prepare the develop-targeted PR that migrates the code from being branch-only to the mainline (per Git-flow).

Security & safety notes
- The redesign will be behind `ZSH_USE_REDESIGN` by default. Only enable for your local shells or in branch CI runs for testing.
- Keep `.gitignore` entries and commit-check workflows to avoid accidentally committing CI-generated ledger files.
- Keep remediation PR template and owners informed for fast rollback.

---

If you want me to proceed now, I will:
- Implement the feature-flag scaffolding (`FT-01`), migration helper (`FT-10`), and skeleton module files for 40/50/60 (`FT-02`, `FT-03`, `FT-04`) in this branch and push them.
- After that I will run local integration & perf smoke checks and report results. (You asked for sprint/today timing; I will start immediately if you confirm.)


### 10.3 Long-term Vision

The redesigned ZSH configuration will deliver:
- **Predictable Performance:** Sub-300ms startup with <5% variance
- **Comprehensive Monitoring:** Real-time performance and health tracking
- **Automated Quality:** CI-driven testing and validation at every change
- **Future Flexibility:** Modular architecture supporting ongoing evolution
- **Operational Excellence:** Complete tooling for maintenance and troubleshooting

This implementation represents a foundation for long-term ZSH configuration excellence, balancing performance, maintainability, and feature richness in a sustainable, automated framework.

---

*This document is maintained as the authoritative implementation reference. All changes require review and approval to maintain consistency with the overall redesign strategy.*
## Stage 3 Exit: Implementation Updates

Summary of actions completed for Stage 3 exit:
- Added robust per-sample watchdog and retry logic to `tools/perf-capture-multi.zsh` (F49). This ensures authentic multi-sample captures and rejects synthetic cloning of results.
- Automated badge refresh: `tools/update-variance-and-badges.zsh` now consumes `perf-multi-simple.json` and updates `variance-gating-state.json`, governance badge, and perf badge.
- Drift readiness helper `tools/prepare-drift-guard-flip.zsh` updated to prefer the repo-level metrics path and fallback to the dot-config path; corrected repo-root resolution.
- Seeded `docs/redesignv2/artifacts/metrics/ledger-history/` for readiness verification (CI should populate this directory nightly for real historical evaluation).
- Added a robust local test framework at `dot-config/zsh/tests/lib/test-framework.zsh` to let integration tests run in minimal CI and dev environments; integration tests were run locally and the prompt single emission test now passes.

Implications for Stage 4:
- The monitoring, gating, and enforcement infrastructure is in place. After a successful 7-day CI-driven stability window and passing async activation checklist in CI, the team may flip the drift guard to enforcement (fail on >10% regressions).

Operational notes:
- Default enforcement remains disabled; do not enable `PERF_DIFF_FAIL_ON_REGRESSION=1` until a 7-day stable ledger history exists and CI tests pass consistently.
- The `perf-capture-multi.zsh` default retry and watchdog parameters can be tuned for CI latency.
