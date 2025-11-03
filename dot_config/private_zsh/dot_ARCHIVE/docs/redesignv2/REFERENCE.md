# ZSH Redesign Reference Guide

## Part 08.19.10 — Addendum: JSON Semantics, Single‑Metric Parity, and Badges

This addendum captures the latest stabilizations in the classifier’s JSON contract, parity between single‑ and multi‑metric modes, and the dynamic badge surface published by CI.

### JSON Field Semantics (Phase 6, current)

Applies to `docs/redesignv2/artifacts/metrics/perf-current.json` (multi‑metric) and the single‑metric output when invoked with `--json-out`.

- goal
  - String profile: "streak" | "governance" | "explore" | "ci"
  - Set by `GOAL` (normalized to lowercase) and `apply_goal_profile`
- mode
  - "observe" | "enforce"
  - In observe, exit code is 0 regardless of classification; in enforce, exit code reflects worst classification and/or flags gating
- overall_status (multi‑metric only)
  - "OK" | "WARN" | "FAIL" | "BASELINE_CREATED"
  - Summarizes the worst per‑metric classification across the run
- worst_metric, worst_delta_pct (multi‑metric only)
  - The metric with largest positive delta and its percentage
- thresholds and run context
  - warn_threshold_pct, fail_threshold_pct, runs
  - baseline_dir (multi‑metric) or baseline_file (single‑metric)
  - generated_at ISO‑8601 timestamp
- metric blocks (multi‑metric only)
  - Each `<metric>_ms` object contains: status, delta_pct, mean_ms, median_ms, stddev_ms, rsd_pct, baseline_mean_ms, values
- conditional flags (emitted only when true and allowed by profile flags)
  - partial
    - Emitted as `true` when the PARTIAL latch is set (one or more requested metrics missing) AND the active profile allows JSON emission for partial (`JSON_PARTIAL_OK=1`, e.g., streak/explore). Governance/ci do not emit this top‑level flag.
    - See `_debug.missing_metrics` for the list of missing metric keys (always present in debug when partial is latched).
  - synthetic_used
    - Emitted as `true` at top‑level only when synthetic fallback is detected AND the active profile allows synthetic (`ALLOW_SYNTHETIC_SEGMENTS=1`, e.g., streak/explore).
    - Always mirrored in debug overlay as numeric `_debug.synthetic_used` (0|1) for tooling even when top‑level emission is suppressed.
  - ephemeral
    - Emitted as `true` only in Explore (`EPHEMERAL_FLAG=1`).
- _debug overlay (always present; fields may be zero/empty)
  - `_debug.synthetic_used`: 0|1
  - `_debug.partial`: 0|1 (reflects PARTIAL latch)
  - `_debug.missing_metrics`: array of missing metric names (empty when none)

Notes:
- Governance/CI profiles apply strict gating in enforce mode (e.g., synthetic disallowed, require all metrics). The JSON above is still written before exit (see parity below), so CI always has deterministic artifacts to consume.

### Single‑Metric JSON Parity (always‑before‑exit)

Single‑metric mode now writes JSON before any enforce‑mode exit or gating, matching multi‑metric ordering. Guarantees:
- When there are successful captures, the JSON file is written prior to exiting with WARN/FAIL in enforce mode.
- When there are zero successful captures, a minimal diagnostic JSON object is written:
  - `{"goal": "<profile>","status":"ERROR","error":"no_successful_captures","mode":"<mode>","generated_at":"<ts>"}`

This ensures CI and local tooling can always inspect objective context even on classification failures.

### Badges — goal‑state and summary‑goal

Two dynamic badges are generated and published by CI under `docs/redesignv2/artifacts/badges/`:

- goal‑state.json
  - Compact state map:
    - `governance`: "clean" | "warning" | "failing" (derived from overall_status and absence of partial/synthetic)
    - `ci`: "strict" | "lenient" (goal=ci + mode=enforce → strict)
    - `streak`: "building" | "stable" (building when partial tolerated)
    - `explore`: "sandbox"
  - Source script: `tools/generate-goal-state-badge.zsh` (pure zsh, atomic write)

- summary‑goal.json (Shields endpoint)
  - Aggregates goal‑state and folds in additional project signals:
    - perf‑drift badge (`perf-drift.json`) → suffix `drift:<message>`, influences overall color (warn/fail → yellow/red)
    - structure badge (`structure.json`) → suffix `struct:<message>`, influences overall color
  - Message (example): `gov:clean | ci:strict | streak:building | explore:sandbox | drift:2 warn (+7.1% max) | struct:stable`
  - Color: derived from the worst severity across goal mapping, perf drift, and structure
  - Source script: `tools/generate-summary-goal-badge.zsh` (pure zsh, atomic write)

Shields endpoints (placeholders; CI post‑publish auto‑resolves README links after first gh‑pages publish):
- Goal‑state (flat)
  - `https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<org>/<repo>/gh-pages/badges/goal-state.json`
- Summary‑goal (compact)
  - `https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<org>/<repo>/gh-pages/badges/summary-goal.json`

## Classifier Goal Quick Reference

The performance regression classifier now supports adaptive execution profiles via the `GOAL` variable (environment or `--goal` CLI).  
If `GOAL` is unset it defaults to `streak` (backward compatibility with legacy single observe mode).

| Profile | Intent | Synthetic Fallback | Missing Metrics | Strictness Model | Baseline Creation | Extra JSON Flags (conditional) | Exit on Missing? | Exit on Synthetic? |
|---------|--------|-------------------|-----------------|------------------|-------------------|--------------------------------|------------------|--------------------|
| streak | Rapid OK streak building (resilient) | Allowed | Warn + continue (`partial`) | Phased: start `-uo`, add `-e` before summary | Yes (auto) | `partial`, `synthetic_used` | No | No |
| governance | Pre‑enforcement strict validation | Disallowed | Hard fail | Full `-euo pipefail` | Yes (only if complete & real) | (none) | Yes | Yes |
| explore | Developer / diagnostic sandbox | Allowed | Warn + continue (`partial`) | Soft: `-uo` only (no `-e`) | Yes | `partial`, `synthetic_used`, `ephemeral` | No (unless catastrophic) | No |
| ci | Deterministic CI gating | Disallowed | Hard fail | Full `-euo pipefail` | Yes | (none) | Yes | Yes |

### Classifier JSON Schema (Phase 6)

The classifier emits a status JSON artifact (distinct from per-segment telemetry). Keys and emission rules:

- goal
  - Always emitted; normalized to lowercase profile name: streak|governance|explore|ci.
- partial
  - Emitted as true only when one or more requested metrics are missing AND the profile allows partial JSON (JSON_PARTIAL_OK=1 → Streak, Explore).
  - Not emitted for Governance/CI (strict profiles do not tolerate partial JSON).
- synthetic_used
  - Emitted as true only when synthetic fallback lines were inserted AND the profile allows synthetic segments (ALLOW_SYNTHETIC_SEGMENTS=1 → Streak, Explore).
  - Not emitted for Governance/CI (strict profiles gate on synthetic use in enforce mode instead of emitting this flag).
- ephemeral
  - Emitted as true only for Explore (EPHEMERAL_FLAG=1).
  - Not emitted for Streak/Governance/CI.

Profile emission matrix (true when emitted; otherwise omitted):
- Streak: partial (when missing), synthetic_used (when used), no ephemeral
- Governance: none of the above (partial/synthetic_used/ephemeral)
- Explore: partial (when missing), synthetic_used (when used), ephemeral
- CI: none of the above (partial/synthetic_used/ephemeral)

Enforce-mode gating (flags from apply_goal_profile):
- Governance/CI:
  - Missing metrics → classification-fatal in enforce mode (REQUIRE_ALL_METRICS=1).
  - Synthetic fallback → classification-fatal in enforce mode (ALLOW_SYNTHETIC_SEGMENTS=0).
- Streak/Explore:
  - Tolerant: exit semantics unchanged by partial/synthetic; JSON flags may be emitted per rules above.

Examples:
```
# Default (streak)
tools/perf-regression-classifier.zsh --runs 5

# Governance validation run
GOAL=Governance tools/perf-regression-classifier.zsh --runs 5

# Explore diagnostic mode
tools/perf-regression-classifier.zsh --goal explore --runs 3 --verbose

# CI deterministic gating
GOAL=ci tools/perf-regression-classifier.zsh --runs 5
```

Governance activation precondition (A8):
- Three consecutive `GOAL=Governance` runs with neither `synthetic_used` nor `partial` present.

Unset / unknown values:
- Any unrecognized value is treated as `streak`.

Refer to IMPLEMENTATION.md §4.x and ADR-0007 for full rationale & internal flag mapping.
Version: 2.2
Status: Living Operational Reference (authoritative for day‑to‑day use)
Last Updated: 2025-09-10 (Part 08.19 – Sprint 2 Instrumentation Status Refresh)

This document is the quick‑use companion to:
- IMPLEMENTATION.md – Stage plan, execution gates, promotion criteria
- ARCHITECTURE.md – Design principles, layering model, deferred execution strategy

If a conflict exists:
1. Architecture intent → ARCHITECTURE.md
2. Execution status & gates → IMPLEMENTATION.md
3. Operational detail & usage → THIS FILE

Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

Sprint 2 Focus (Active):
- Real segment probes COMPLETE (all planned granular + phase anchors emitted)
- Deferred dispatcher skeleton ACTIVE (one-shot postprompt; cumulative `deferred_total` segment captured)
- Dependency cycle edge-case tests PASS (unknown / disabled suppression / multi-level / broken cycle scenarios covered)
- Logging namespace migration COMPLETE (underscore wrappers removed; homogeneity gate enforced; documentation fully updated)
- Structured telemetry flags AVAILABLE (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) – opt-in, zero overhead when unset
- Multi-metric performance classifier in OBSERVE mode (OK/WARN/FAIL thresholds: 10% / 25%); enforce-mode flip pending 3× consecutive OK streak (S4-33)
- Governance: PERFORMANCE_LOG governance row (Type=governance) & enforce activation queued post-streak; README perf status block placeholder present
- Baseline stable: 334ms cold start (RSD 1.9%) – no regression after new instrumentation

## 1. Quick Command Cheat Sheet

### 1.1 Validation & Health
| Purpose | Command |
|---------|---------|
| Full test suite | `tests/run-all-tests-v2.zsh` |
| Design / structure only | `tests/run-all-tests-v2.zsh --design-only` |
| Performance only | `tests/run-all-tests-v2.zsh --performance-only` |
| Security / async only | `tests/run-all-tests-v2.zsh --security-only` |
| Unit tests only | `tests/run-all-tests-v2.zsh --unit-only` |
| Manifest test (direct) | `zsh -f tests/unit/core/test-core-functions-manifest.zsh` |
| Manifest test (with debug) | `CORE_FN_MANIFEST_DEBUG=1 zsh -f tests/unit/core/test-core-functions-manifest.zsh` |
| Implementation snapshot | `./verify-implementation.zsh` |
| Promotion readiness gate | `tools/promotion-guard.zsh` |
| Perf capture (2 runs + segments) | `tools/perf-capture.zsh` |
|| Legacy checksum verification | `tools/verify-legacy-checksums.zsh` |
|| **Testing Harness** | See [WARP.md §7.1.1](../../WARP.md#711-mandatory-harness-standard-bash-harness-for-zsh-templatebash) |
|| Bash harness self-test | `bash tools/selftest-harness.bash` |
|| Harness compliance check | `bash tools/enforce-harness-usage.bash` |
|| Direct harness test suite | `bash .bash-harness-for-zsh-template.bash` |

### 1.2 Development Cycle (Per Stage)
```bash
# Branch & implement
git checkout -b stage-2-preplugin
# Edit modules...
tests/run-all-tests-v2.zsh --design-only
tests/run-all-tests-v2.zsh --unit-only
```
**Current Status:**  
- Stage 3 is 92% complete.  
- All migration, CI, and runner upgrades are done.  
- The new `run-all-tests-v2.zsh` is enforced everywhere.  
- Manifest test now passes in isolation (`zsh -f`).  
- Performance: 334ms startup, 1.9% variance.

**Next Steps:**  
- Run comprehensive test suite with new runner  
- Document and fix any remaining test failures  
- Monitor CI ledger for stability  
- Proceed to Stage 4: Feature layer implementation  

# Measure performance effect
tools/perf-capture.zsh

# Validate readiness
./verify-implementation.zsh
tools/promotion-guard.zsh

# Commit & tag
git add .
git commit -m "feat(pre-plugin): implement lazy framework dispatcher"
git tag -a refactor-stage2-preplugin -m "Stage 2 complete"
```

### 1.3 Performance Analysis Workflow
```bash
# Capture current metrics
tools/perf-capture.zsh

# Inspect JSON
jq . docs/redesignv2/artifacts/metrics/perf-current.json

# Compare with baseline
diff <(jq '.mean_ms,.post_plugin_cost_ms' docs/redesignv2/artifacts/metrics/perf-baseline.json) \
     <(jq '.mean_ms,.post_plugin_cost_ms' docs/redesignv2/artifacts/metrics/perf-current.json)
```

### 1.4 Security / Async Verification
```bash
# Run async-specific tests
tests/run-all-tests-v2.zsh --security-only

# Manually inspect logs
grep ASYNC_STATE logs/async-state.log
grep PERF_PROMPT logs/perf-current.log
```

### 1.5 Core Functions Testing (zsh -f compatibility)
```bash
# Test manifest directly with clean shell
zsh -f tests/unit/core/test-core-functions-manifest.zsh

# Debug manifest test issues
CORE_FN_MANIFEST_DEBUG=1 zsh -f tests/unit/core/test-core-functions-manifest.zsh

# List current core functions
source dot-config/zsh/.zshrc.d.REDESIGN/10-core-functions.zsh
zf::list_functions

# Update manifest after function changes
zf::list_functions > /tmp/current-functions.txt
# Then manually update: docs/redesignv2/artifacts/golden/core-functions-manifest-stage3.txt
```

---

## 2. Directory & Artifact Map

```
docs/redesignv2/
  README.md                 # Overview & navigation
  IMPLEMENTATION.md         # Consolidated execution plan (source of truth)
  ARCHITECTURE.md           # Design principles & rationale
  REFERENCE.md              # THIS FILE (ops, cheats, glossary)
  stages/                   # Stage-focused detail (per-stage guides)
  artifacts/
    inventories/            # preplugin|postplugin inventories (txt/tsv/json)
    metrics/                # perf-current.json, perf-baseline.json, structure-audit*
    badges/                 # JSON endpoints consumed by Shields
    checksums/              # legacy-checksums.sha256 & future snapshots
  archive/                  # Frozen planning & deprecated documents
```

### 2.1 Key Metrics Files
| File | Description |
|------|-------------|
| perf-baseline.json | Initial 10-run or filtered baseline (frozen) |
| perf-current.json | Latest capture (includes segment fields) |
| structure-audit.json | Count/order/violations summary |
| function-collisions.json | Potential namespace overlaps |
| perf-regression-*.json | Rolling regression sample sets |

### 2.2 Inventories – When To Update
| File | Rule |
|------|------|
| preplugin-inventory.txt | NEVER mutate until promotion / archive |
| postplugin-inventory.txt | Same as above – replace only after official promotion |
| disabled inventories | Provide drift snapshot of disabled modules |

---

## 3. Environment & Feature Flags

| Variable | Accepted Values | Default (Pre-Promo) | Purpose |
|----------|-----------------|---------------------|---------|
| ZSH_ENABLE_PREPLUGIN_REDESIGN | 0|1 | 0 (toggle) | Activate redesigned pre-plugin tree |
| ZSH_ENABLE_POSTPLUGIN_REDESIGN | 0|1 | 0 (toggle) | Activate redesigned post-plugin tree |
| ZSH_NODE_LAZY | 0|1 | 1 | Keep lazy Node stubs active |
| ZSH_ENABLE_NVM_PLUGINS | 0|1 | 1 | Opt-in nvm/npm plugin activation |
| ZSH_ENABLE_ABBR | 0|1 | 0 | Optional abbreviation plugin |
| ZSH_DISABLE_SPLASH (planned) | 0|1 | 0 | Turn off splash module |
| ZSH_DEBUG | 0|1 | 0 | Emit debug echo traces (if implemented) |
| ZSH_LOG_STRUCTURED | 0|1 | 0 | Enable structured (JSON line) telemetry emission (opt-in only; off = no JSON output) |
| ZSH_PERF_JSON | 0|1 | 0 | Write perf-current.json (structured timing snapshot) when enabled |

### 3.1 Async (Phase A Shadow) Environment Variables

| Variable | Accepted Values | Default (Phase A) | Purpose |
|----------|-----------------|-------------------|---------|
| ASYNC_MODE | off \| shadow \| on | off | Select async dispatcher operating mode (shadow = run async tasks without removing sync path) |
| ASYNC_TASKS_AUTORUN | 0 \| 1 | 0 | Auto-bootstrap async tasks registration on sourcing `async-tasks.zsh` |
| ASYNC_TEST_FAKE_LATENCY_MS | integer (ms) | unset | Inject artificial latency into each async task (testing / variance probing) |
| ASYNC_FORCE_TIMEOUT | <task_id> | unset | Force named task to simulate a timeout path (testing) |
| ASYNC_MAX_CONCURRENCY | integer | 4 (planned) | Upper bound on simultaneous async tasks (effective in active phases) |
| ASYNC_DEBUG_VERBOSE | 0 \| 1 | 0 | Enable verbose dispatcher/task debug logging |
| ASYNC_METRICS_FILE | filesystem path | unset | Override target file for exported async metrics (`async-metrics-export.zsh`) |
| ZSH_LOG_STRUCTURED | 0 \| 1 | 0 | (Structural duplicate listed above; included here for quick async/telemetry reference) |
| ZSH_PERF_JSON | 0 \| 1 | 0 | (Structural duplicate listed above; async tools may read to decide JSON perf snapshot emission) |
| ASYNC_SHADOW_PROMPT_DELTA_MAX | integer (ms) | 50 | Threshold used by shadow mode test for allowable prompt_ready delta |
| ASYNC_TASK_<NAME> | 0 \| 1 | 1 (per enabled task) | Per-task feature flags (e.g. `ASYNC_TASK_THEME_EXTRAS=0` disables that task) |

**Guideline**: Avoid enabling post-plugin redesign without pre-plugin redesign unless diagnosing partial staging.

---

## 4. Sentinel Naming & Guards

### 4.1 Pattern
```
_LOADED_<UPPERCASE_FILE_NAME_WITH_DASHES_AS_UNDERSCORES>=1
```
Examples:
```
.zshrc.d.REDESIGN/50-completion-history.zsh -> _LOADED_50_COMPLETION_HISTORY
.zshrc.pre-plugins.d.REDESIGN/10-lazy-framework.zsh -> _LOADED_10_LAZY_FRAMEWORK
```

### 4.2 Guard Idiom
```zsh
[[ -n ${_LOADED_50_COMPLETION_HISTORY:-} ]] && return
_LOADED_50_COMPLETION_HISTORY=1
```

Failing to include the guard:
- Causes sentinel test failure
- Risks duplicate side effects (compinit, PATH mutations)

---

## 5. Logging & Instrumentation

| Log / Artifact | Location | Producer | Purpose |
|----------------|----------|----------|---------|
| async-state.log | logs/ | Async module (70/80 interplay) | State machine timeline |
| perf-current.log | logs/ | perf-capture/perf hooks | Raw timing events |
| perf-*.json | artifacts/metrics | perf-capture.zsh | Historical snapshots |
| structure-audit.json | artifacts/metrics | generate-structure-audit.zsh | Order & duplication enforcement |

### 5.1 Expected Async Log Markers
```
ASYNC_STATE:IDLE <epoch_float>
SECURITY_ASYNC_QUEUE <epoch_float>
PERF_PROMPT:COMPLETE <epoch_float>   # (perf log, cross-correlation)
ASYNC_STATE:RUNNING <epoch_float>
ASYNC_STATE:SCANNING <epoch_float>
ASYNC_STATE:COMPLETE <epoch_float>
```
If `ASYNC_STATE:RUNNING` appears **before** `PERF_PROMPT:COMPLETE` → violation.

### 5.2 Performance Segment Fields (perf-current.json)
| Field | Meaning |
|-------|---------|
| mean_ms | Aggregated (simple) average of warm+cool captures |
| cold_ms / warm_ms | Raw run durations |
| cold_pre_plugin_ms | Pre-plugin portion (cold run) |
| warm_pre_plugin_ms | Pre-plugin portion (warm run) |
| cold_post_plugin_ms | Post-plugin portion (cold run) |
| warm_post_plugin_ms | Post-plugin portion (warm run) |
| pre_plugin_cost_ms / post_plugin_cost_ms | Averaged segment costs |
| segments_available | Boolean – instrumentation presence |

**Interpretation**:
- `post_plugin_cost_ms > 500` → investigate modules 20–70 for bloat
- Spikes in pre-plugin cost → inspect lazy framework & path operations

### 5.3 Canonical Performance Segments & Disable Flags

Authoritative list of segment names emitted by the redesign (Sprint 2).  
Names are stable contracts: tests and the multi-metric classifier depend on them.

| Segment Name | Phase | Origin Module (Ordinal) | Purpose / Scope | Disable Flag (if any) |
|--------------|-------|--------------------------|-----------------|-----------------------|
| `pre_plugin_start` | pre_plugin | 00-path-safety (pre) | Anchor (epoch ms=0 reference) | (none) |
| `pre_plugin_total` | pre_plugin | 40-pre-plugin-reserved (pre end) | Total pre-plugin elapsed | (none) |
| `post_plugin_total` | post_plugin | 85-post-plugin-boundary / 90-splash | Total post-plugin (functional) time | (none) |
| `prompt_ready` | prompt | 95-prompt-ready | Time to first prompt (TTFP) | (none) |
| `deferred_total` | postprompt | 96-deferred-dispatch | Aggregated deferred jobs runtime (first pass) | (none) |
| `essential/zsh-syntax-highlighting` | post_plugin | 20-essential-plugins | Plugin load attribution | (none) |
| `essential/zsh-autosuggestions` | post_plugin | 20-essential-plugins | Plugin load attribution | (none) |
| `essential/zsh-completions` | post_plugin | 20-essential-plugins | Plugin load attribution | (none) |
| `history/baseline` | post_plugin | 50-completion-history | History + policy init | (none) |
| `safety/aliases` | post_plugin | 40-aliases-keybindings | Alias setup timing | `ZSH_DISABLE_ALIASES_KEYBINDINGS=1` (suppresses) |
| `navigation/cd` | post_plugin | 40-aliases-keybindings | Lightweight navigation helpers | `ZSH_DISABLE_ALIASES_KEYBINDINGS=1` (suppresses) |
| `dev-env/nvm` | post_plugin | 30-development-env | Dev env path / stub timing | (none) |
| `dev-env/rbenv` | post_plugin | 30-development-env | Dev env path / stub timing | (none) |
| `dev-env/pyenv` | post_plugin | 30-development-env | Dev env path / stub timing | (none) |
| `dev-env/go` | post_plugin | 30-development-env | Go toolchain surfacing | (none) |
| `dev-env/rust` | post_plugin | 30-development-env | Rust toolchain surfacing | (none) |
| `completion/history-setup` | post_plugin | 50-completion-history | History file + var setup | (none) |
| `completion/cache-scan` | post_plugin | 50-completion-history | Compinit cache inspection | (none) |
| `compinit` | post_plugin | 55-compinit-instrument | Single guarded compinit invocation | (none) |
| `p10k_theme` | post_plugin | 60-p10k-instrument | Prompt theme init (optional) | (none) |
| `gitstatus_init` | post_plugin | 65-vcs-gitstatus-instrument | Git status daemon init | (none) |
| `ui/prompt-setup` | post_plugin | 60-ui-prompt | Future prompt orchestration placeholder | `ZSH_DISABLE_UI_PROMPT_SEGMENT=1` |
| `security/validation` | post_plugin | 80-security-validation | Security validation placeholder | `ZSH_DISABLE_SECURITY_VALIDATION_SEGMENT=1` |

Disable flags suppress only the specific segment(s) indicated; they do not disable the module sentinel or other unrelated segments.

#### 5.3.1 Classifier Metric Mapping

| Classifier Metric Key | Aggregates | Notes |
|-----------------------|------------|-------|
| `pre_plugin_total_ms` | All pre-plugin work (start → pre-plugin end) | Derived from anchors (`pre_plugin_start`, `pre_plugin_total`) |
| `post_plugin_total_ms` | Functional post-plugin modules (00–80 until post_plugin_total emitted) | Includes plugin + dev-env + completion + instrumentation |
| `prompt_ready_ms` | `pre_plugin_total_ms + post_plugin_total_ms (+ prompt delta)` | Time until first prompt rendered |
| `deferred_total_ms` | Deferred dispatcher batch (postprompt) | May grow as real deferred jobs added |

#### 5.3.2 Structured Telemetry Keys (JSON Sidecar)

When `ZSH_LOG_STRUCTURED=1`:
```
{"type":"segment","name":"<segment>","ms":<int>,"phase":"<phase>","sample":"<cold|warm|unknown>","ts":<epoch_ms>}
```
Privacy Appendix governs allowed keys; additions require documentation + tests.

#### 5.3.3 Baseline Integrity Tests (Current)

| Integrity Aspect | Current Test / Status | Action if Failing |
|------------------|-----------------------|-------------------|
| Segment presence (core + granular) | `tests/performance/segments/test-granular-segments.zsh` | Investigate instrumentation regression |
| Disable flags suppress emission | `tests/performance/segments/test-granular-segments.zsh` (disable‑flag block) | Fix guard or flag logic |
| No duplicate emission | `tests/performance/segments/test-granular-segments.zsh` duplicate check | Ensure idempotent emission guard |
| Classifier per-metric baselines exist | `tests/performance/telemetry/test-classifier-baselines.zsh` | Recreate baselines (observe) or restore missing metric emission |
| JSON schema (allowed keys only) | `tests/performance/telemetry/test-structured-telemetry-schema.zsh` | Add key to allowlist + privacy docs OR remove unauthorized field |
| README sync parity (segments) | `tools/sync-readme-segments.zsh` (manual / future CI) | Re-run sync tool; resolve diffs |

#### 5.3.4 Adding a New Segment (Policy)

1. Justify need (feature-specific attribution or governance hook).
2. Implement guarded emission (single write).
3. Add to this table + PERFORMANCE_LOG if it affects budgets.
4. Extend tests:
   - Presence
   - Duplicate prevention
   - Disable flag (if applicable)
5. Run classifier in observe mode to confirm benign delta.
6. Run `tools/sync-readme-segments.zsh` to propagate canonical table into README.
7. Submit PR referencing this policy and updated REFERENCE section.

---

---

### 5.4 Logging Namespace Homogeneity Policy

This policy governs permissible logging call sites and enforces namespace purity after the Stage 4 Sprint 2 migration removed legacy underscore wrappers.

| Aspect | Rule | Enforcement |
|--------|------|-------------|
| Approved public APIs | `zf::log`, `zf::warn`, `zf::err` | Homogeneity test (CI) |
| Disallowed (removed) | `_zf_log`, `_zf_warn`, `_zf_err`, any future underscore-prefixed aliases | Grep + fail gate |
| Raw `echo` / `print` for runtime logging | Prohibited (except: controlled early bootstrap debug guarded by `[[ ${ZSH_DEBUG:-0} == 1 ]]`) | Style / grep test |
| Structured telemetry emission | Must go through existing segment / structured JSON emitters (not ad‑hoc) | Telemetry schema test |
| New logging helper introduction | Requires ADR + update to ARCHITECTURE.md + REFERENCE §5.4 + Implementation Guide | PR review + policy mention |
| External plugin logs | Out of scope (not normalized) | N/A |
| Privacy / PII | No secrets, tokens, usernames, host paths beyond minimal file basenames | Privacy appendix + schema test |
| Performance overhead | Single call ≤0.05ms; bursts aggregated or deferred | Future micro-bench (planned) |

#### 5.4.1 Removal / Migration Policy

1. Introduce new namespaced functions (`zf::log|warn|err`).
2. Add transitional wrappers incrementing a sentinel (`ZF_LOG_LEGACY_USED`) for detection.
3. Update all internal call sites to namespaced versions.
4. Remove legacy wrappers once CI homogeneity test shows zero legacy usage for ≥2 consecutive runs.
5. Delete sentinel & update REFERENCE (this section) and IMPLEMENTATION change log.

#### 5.4.2 Test Enforcement

Homogeneity test (design/performance suite) performs:
- Pattern scan: `grep -R "_zf_\\(log\\|warn\\|err\\)"` over redesign trees.
- Fails on any match (excluding test fixture allowlist).
- Optionally warns (not fails) on direct `echo` / `print` lines containing `[LOG]` style tokens outside approved helpers.

#### 5.4.3 Adding a New Logging Variant (Rare)

Must satisfy:
- Clear functional gap (e.g. throttled, rate‑limited variant).
- ADR entry with performance rationale & fallback semantics.
- Privacy review (no new sensitive fields).
- Structured telemetry alignment if exporting JSON.

#### 5.4.4 Quick Checklist (Pre-Commit)

- [ ] No underscore logging wrappers introduced.
- [ ] No direct user‑facing `echo` replacements for existing APIs.
- [ ] No secret or path leakage (absolute paths trimmed or redacted).
- [ ] Structured telemetry keys unchanged OR schema + privacy docs updated.
- [ ] Homogeneity test passes locally (`--design-only` or dedicated target).

#### 5.4.5 Exception Handling

Emergency diagnostic insertion (temporary raw echo):
- Must be guarded: `[[ ${ZSH_DEBUG:-0} == 1 ]] && print -- "[diag] ..."`
- Must be removed or converted before merge to main.
- Any permanent exception requires governance PERFORMANCE_LOG row citing impact.

#### 5.4.6 Rationale

Namespace purity:
- Simplifies grep-based audits.
- Prevents drift / shadowing from legacy helpers.
- Enables consistent formatting & future structured JSON mirroring.

Violation Impact: Merge blocked; no override without governance notice.

---

## 6. Troubleshooting

### 6.1 Symptom → Diagnostic Matrix
| Symptom | Quick Check | Likely Cause | Resolution |
|---------|-------------|--------------|-----------|
| Slow startup (> target) | `jq '.mean_ms' perf-current.json` | New module overhead | Run perf regression test; bisect enabling modules |
| prompt appears late | Compare prompt timestamp vs RUNNING state | Async running too early | Fix deferral logic (ensure queue before prompt) |
| Multiple compdump timestamps | `test-postplugin-compinit-single-run.zsh` | Compinit not guarded | Add `_COMPINIT_DONE` guard or remove duplicate call |
| PATH duplicates reappear | Grep `echo $PATH` vs inventory | Missing dedup logic in 00-path-safety | Re-run consolidation; add filter |
| Lazy function never loads | `typeset -f func` after call | Mis-registered loader or guard interference | Verify `lazy_register` signature & loader body |
| SSH agent duplicates | `pgrep ssh-agent | wc -l` | Missing socket reuse logic | Improve 30-ssh-agent checks (test file existence, permissions) |
| Async never completes | Tail async-state.log | State stuck at QUEUED | Scheduler not invoked post prompt; hook missing |
| Performance badge red | Inspect perf.json | Regression > gate | Optimize slow module; recapture metrics |

### 6.2 Deep-Dive Steps (Performance)
1. Capture fresh metrics: `tools/perf-capture.zsh`.
2. If regression: run `tests/run-all-tests-v2.zsh --performance-only`.
3. Disable redesign toggles individually to isolate (pre vs post).
4. Temporarily comment suspected module; re-run capture.
5. Use `zmodload zsh/datetime` and manual time logging inside module for micro-costs.

### 6.3 Lazy Loader Debugging
```zsh
# Show registered lazy functions
typeset -p _LAZY_REGISTRY 2>/dev/null

# Trace a function
set -x
my_lazy_function arg1
set +x
```

### 6.4 Async State Forensics
```bash
grep ASYNC_STATE logs/async-state.log
awk '/ASYNC_STATE/ {print $1,$2,$3}' logs/async-state.log
```
Check monotonicity:
```bash
awk '/ASYNC_STATE/ {print $2}' logs/async-state.log | sort -n | diff - <(awk '/ASYNC_STATE/ {print $2}' logs/async-state.log)
# Empty diff = monotonic
```

---

## 7. Performance Optimization Playbook

| Scenario | Action |
|----------|--------|
| Pre-plugin too heavy | Inline micro path operations, push side-effects post-plugin |
| Node stub slow on first use | Ensure loader only sources nvm once; cache resolved Node version |
| Completion slow | Confirm single compinit; reduce large completion functions before load |
| Prompt delay | Ensure p10k theme not sourcing large external processes; defer optional segments |
| Async contention | Lower concurrency or break large hash batch into slices |

---

## 8. Commit & Tag Conventions

| Action | Format |
|--------|--------|
| Feature module addition | `feat(<area>): <short description>` |
| Performance improvement | `perf(<area>): <delta rationale>` |
| Test addition | `test(<category>): <scope>` |
| Architectural refactor | `refactor(<area>): <scope>` |
| Documentation | `docs(<section>): <update summary>` |
| Stage completion | `feat: Stage N complete - <summary>` |
| Promotion | `feat: promotion enable redesigned config` |

Tag patterns:
- `refactor-stage<N>-<label>`
- `refactor-promotion-complete`
- `rollback-YYYYMMDD`

---

## 9. API / Function Contracts (Current & Planned)

| Contract | Status | Description |
|----------|--------|-------------|
| `lazy_register <name> <loader>` | Active | Registers a stub replaced at first invocation |
| `plugin_security_status` | Planned | Summarize async scan results & integrity |
| `plugin_scan_now` | Planned | Immediately trigger deferred scan cycle |
| `_COMPINIT_DONE` | Active | Sentinel to prevent duplicate compinit |
| `_ASYNC_PLUGIN_HASH_STATE` | Scaffold | Exposes current async machine state |

Return Code Expectations:
| Function | Success | Failure |
|----------|---------|---------|
| lazy loader | 0 | Non-zero if real function missing |
| plugin_security_status | 0 (healthy or degraded reported) | >0 for fatal state (planned) |

---

## 10. Glossary (Operational Subset)

| Term | Meaning |
|------|--------|
| Pre-plugin | Earliest phase modules controlling baseline environment |
| Post-plugin | Modules loaded after plugin manager restore |
| Segment Timing | Partitioned measurement of startup phases |
| Sentinel | Variable marking module as loaded once |
| Deferred Hashing | Integrity scanning after first prompt to avoid blocking |
| Promotion | The act of making redesigned trees default & regenerating checksum baseline |
| Structure Audit | Automated enumeration of module set, order, and duplicates |
| TTFP | Time To First Prompt |

(Full conceptual glossary: ARCHITECTURE.md)

---

## 11. FAQ (Targeted)

**Q: Why not auto-run deep security scan immediately?**
A: It would inflate TTFP. Architectural principle mandates deferral of non-essential CPU & IO.

**Q: Why numeric prefixes instead of dependency detection?**
A: Determinism & auditability > implicit ordering logic.

**Q: Can I add a 35‑something module?**
A: Only if justified; update structure audit expectations & keep total file count static unless ADR filed.

**Q: How do I test only redesigned pre-plugin path?**
```bash
ZSH_ENABLE_PREPLUGIN_REDESIGN=1 ZSH_ENABLE_POSTPLUGIN_REDESIGN=0 zsh -ic exit
```

**Q: Why one compinit?**
A: Re-running compinit wastes time & can corrupt completion state caching.

**Q: How do I revert safely mid-stage?**
A: `git reset --hard refactor-stage$(N-1)-*` then re-apply granular patches.

---

## 12. Escalation Guide

| Situation | Escalate To | Provide |
|-----------|-------------|---------|
| Async race / pre-prompt RUNNING | Security maintainer | async-state.log, perf-current.log |
| Repeated perf regression | Performance maintainer | perf-current.json deltas, module diff |
| Structural drift violation | Config owner | structure-audit.json + inventories |
| Hash mismatch (checksum fail) | Integrity lead | Modified file list, git diff summary |

---

## 13. Maintenance Checklist (Periodic)

| Cadence | Task |
|---------|------|
| Weekly | Re-run perf capture & compare stddev |
| Bi-weekly | Inspect async-state.log size & rotation |
| Monthly | Validate structure audit with manual spot check |
| Pre-promotion | Full promotion-guard run + manual doc sync |
| Post-promotion | Archive legacy trees, regenerate checksums |

---

## 14. Change Log (This Reference)

| Date | Version | Change |
|------|---------|--------|
| 2025-01-03 | 2.0 | Initial consolidated reference (migration to redesignv2) |
| 2025-09-02 | 2.0 | Added async environment variable reference (Phase A shadow) |
| 2025-09-10 | 2.2 | Segment probes finalized; dispatcher skeleton active; dependency cycle edge-case tests passing; logging namespace migration + homogeneity gate enforced; structured telemetry flags (ZSH_LOG_STRUCTURED, ZSH_PERF_JSON) stabilized; privacy appendix published; performance classifier in observe mode (awaiting 3× OK streak) |

---

## 15. Navigation
[Implementation](IMPLEMENTATION.md) | [Architecture](ARCHITECTURE.md) | [Stages](stages/) | [Artifacts](artifacts/) | [Privacy](privacy/PRIVACY_APPENDIX.md)

*End of Reference Guide*
