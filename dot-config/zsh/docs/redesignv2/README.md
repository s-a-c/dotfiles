# ZSH Configuration Redesign Documentation

## Part 08.19.10 — Current Status Summary

- GOAL profiles fully wired via flags: streak, governance, explore, ci. Enforce-mode gating is flags-driven; observe mode remains rc=0.
- Single-metric JSON emission now matches multi-metric ordering: JSON is always written before any enforce-mode exit.
- Capture-runner stderr noise (“bad math expression”) suppressed without changing capture logic or metrics.
- Test matrix T-GOAL-01..06 stabilized and passing with gawk available; tests gracefully skip if gawk is missing.
- Dynamic badges implemented:
  - goal-state badge: docs/redesignv2/artifacts/badges/goal-state.json
  - summary-goal badge (aggregator): docs/redesignv2/artifacts/badges/summary-goal.json (folds in perf drift and structure health)
- CI/publishing:
  - Strict classifier workflow (GOAL=ci enforce) emits perf-current.json and goal-state badge.
  - Nightly publisher generates goal-state and summary-goal badges, ensures perf-drift/structure badges, and publishes to gh-pages.
  - Post-publish step auto-replaces README placeholders with the correct endpoints after badges land on gh-pages.

### Badge Endpoints (placeholders resolve after first gh-pages publish)

- Goal-state (flat):
  https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/goal-state.json
- Summary-goal (compact):
  https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/&lt;org&gt;/&lt;repo&gt;/gh-pages/badges/summary-goal.json


## CI wiring (GOAL=ci) – quick snippet

For strict, deterministic gating in CI, set `GOAL=ci` and run the classifier in `--mode enforce`. Example GitHub Actions workflow:

```yaml
name: Perf Classifier CI

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  perf:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      # Optional: install gawk for multi-metric stats (asort)
      - name: Install dependencies
        run: |
          if ! command -v gawk >/dev/null 2>&1; then
            brew update && brew install gawk
          fi

      - name: Run perf classifier (CI strict)
        env:
          GOAL: ci
        run: |
          dotfiles/dot-config/zsh/tools/perf-regression-classifier.zsh \
            --runs 5 \
            --metrics prompt_ready,pre_plugin_total,post_plugin_total,deferred_total \
            --mode enforce \
            --baseline-dir artifacts/metrics \
            --json-out docs/redesignv2/artifacts/metrics/perf-current.json
```

Notes:
- Governance/CI fail in enforce mode when synthetic fallback is used or when required metrics are missing (per Phase 4 gating).
- Multi-metric stats may rely on GNU awk (`gawk`) for `asort`; install it in CI to avoid test skips.

## CI JSON example

When running with `GOAL=ci`, conditional flags like `partial`, `synthetic_used`, and `ephemeral` are not emitted. Example status JSON (structure abbreviated):

```json
{
  "overall_status": "OK",
  "goal": "ci",
  "metrics": {
    "prompt_ready_ms": {
      "status": "OK",
      "delta_pct": 0.00,
      "mean_ms": 334.00,
      "median_ms": 333.00,
      "stddev_ms": 6.30,
      "rsd_pct": 1.89,
      "baseline_mean_ms": 334.00,
      "values": [334]
    }
  },
  "generated_at": "2025-09-11T00:00:00Z",
  "baseline_dir": "artifacts/metrics"
}
```
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

### Stage 4 Sprint 2 Performance & Telemetry Recap (Part 08.19)
- Logging homogeneity complete: legacy underscore wrappers removed; gate test green (no `ZF_LOG_LEGACY_USED`)
- Real segment probes active (anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total` + granular feature/dev-env/history/security/ui attribution)
- Deferred dispatcher skeleton operational (one-shot postprompt; stable `DEFERRED id=<id> ms=<int> rc=<rc>` telemetry)
- Structured telemetry flags available & inert by default: `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON` (zero overhead when unset)
- Multi-metric performance classifier running in observe mode (Warn 10% / Fail 25% thresholds); enforce activation (S4-33) pending 3× consecutive OK streak
- Dependency export (`zf::deps::export`) JSON + DOT implemented with initial tests
- Privacy appendix published & referenced; redaction whitelist stabilized
- Baseline unchanged: 334ms cold start (RSD 1.9%) — no regression after new instrumentation
- Immediate focus: idle/background trigger design (S4-27), telemetry opt-in plumbing (`ZSH_FEATURE_TELEMETRY`, S4-18), classifier legend + governance row (S4-30), enforce-mode activation procedure (S4-33), homogeneity documentation finalization (S4-29)

## New: Module-Fire Selftest & Tracer

Granular segment and native prompt readiness verification are now available as dedicated tools. Use these to confirm that post‑plugin modules emit `POST_PLUGIN_SEGMENT` lines and that native `PROMPT_READY_COMPLETE` markers are present before fallback approximation.

Quick commands:

```bash
# Module-fire selftest (JSON-only, CI-friendly)
env -i ZDOTDIR=$PWD /bin/zsh -f tools/perf-module-fire-selftest.zsh \
  --json --settle-ms 150 --grace-ms 100 \
  > docs/redesignv2/artifacts/metrics/module-fire.json

# Module-fire selftest (human diagnostics to stderr)
ZDOTDIR=$PWD tools/perf-module-fire-selftest.zsh --trace --ci-guidance

# Module tracer (human-readable table)
ZDOTDIR=$PWD tools/perf-module-tracer.zsh --trace --format table

# Module tracer (JSON)
env -i ZDOTDIR=$PWD /bin/zsh -f tools/perf-module-tracer.zsh --format json \
  > docs/redesignv2/artifacts/metrics/module-tracer.json
```

Notes:
- Settle/grace windows help catch late writes:
  - `--settle-ms` defaults to 120ms (post‑exit segment growth).
  - `--grace-ms` defaults to 60ms (await native `PROMPT_READY_COMPLETE` after `POST_PLUGIN_COMPLETE`).
- For clean JSON in CI, prefer a clean shell: `env -i ... /bin/zsh -f`.
- For full classifier test execution, GNU awk (gawk) is required for multi-metric statistics (asort). Without gawk, some tests will be skipped; classifier functionality remains unaffected.

## Notes on perf ledger files
- Daily `perf-ledger-YYYYMMDD.json` files are produced by the nightly CI workflow (`ci-variance-nightly.yml`) and are treated as CI artifacts.
- Do not commit CI-generated daily ledger snapshots to the repo. Keep only small seed/example ledgers for onboarding under `docs/redesignv2/artifacts/metrics/ledger-history/seeded/` and clearly label them as seeds.
- To reproduce a local smoke capture: `./dot-config/zsh/tools/perf-capture-multi.zsh -n 1 --no-segments --quiet` or run the integration checks: `./dot-config/zsh/tests/run-integration-tests.sh`.

## New Badge: modules (module-fire)

A new badge summarizes module emission health:
- File: `docs/redesignv2/artifacts/badges/module-fire.json`
- Shield label: `modules`
- Message values:
  - `ok` → granular segments and native prompt observed
  - `segments_only` → only granular segments observed
  - `prompt_only` → only native prompt observed
  - `missing` → neither observed
- This badge is included in `summary.json` as `modules:<status>`.

Badge Legend Addendum (until the main legend table is revised):
- modules.json | modules | Module emission health | Granular segments + native prompt present | Either missing | Generated via `generate-summary-badges.zsh` from `module-fire.json`

**Version 2.6** – Stage 4 Sprint 2 Instrumentation & Telemetry Expansion  
**Status**: Stage 4 – Sprint 2 In Progress (Real Segment Probes, Structured Telemetry, Perf Classifier, Dependency Export)  
**Last Updated**: 2025-09-10 (Part 08.19)  
**Critical Updates (Sprint 2 so far)**:  
- Deferred dispatcher skeleton (postprompt one‑shot) with cumulative `deferred_total` segment  
- Real segment anchors: `pre_plugin_start`, `post_plugin_total`, `prompt_ready`, `deferred_total`  
- Legacy underscore logging wrappers removed (homogeneity gate enforced)  

<!-- BEGIN:SEGMENTS_SYNC -->
<!-- NOTE: AUTO-GENERATED by tools/sync-readme-segments.zsh. Do NOT edit inside markers. -->
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
<!-- END:SEGMENTS_SYNC -->
<!-- BEGIN:PERF_CLASSIFIER_STATUS -->
<!-- NOTE: AUTO-GENERATED by tools/sync-readme-performance-status.zsh. Do NOT edit inside markers. -->
Status: pending (classifier enforce activation not yet logged; streak < 3)
<!-- END:PERF_CLASSIFIER_STATUS -->
- Structured telemetry flags added (opt‑in, zero overhead when disabled): `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`  
- JSON emission for segments & deferred jobs (sidecar `*.jsonl` when enabled)  
- Performance regression harness & classifier (`tools/perf-regression-classifier.zsh`) – OK/WARN/FAIL thresholds (10% / 25%)  
- Dependency graph export tool (`tools/deps-export.zsh`) supporting JSON + DOT (`zf::deps::export`)  
- Privacy Appendix published: `docs/redesignv2/privacy/PRIVACY_APPENDIX.md` (schema & governance)  
- Baseline reaffirmed: 334ms startup (RSD 1.9%) – no regression after new instrumentation

> NOTE: A “Badge Legend Update Stub” section will be inserted in the Badge Legend area once exact line numbers for that section are provided (required for minimal diff compliance). Please provide the numbered snippet around the existing “## Badge Legend (Expanded – New Pending Rows)” heading so the planned stub (variance-state, multi_source, authenticity fields, perf-multi source note) can be appended precisely.

## Classifier GOAL Profiles (Adaptive Execution Modes)

The performance regression classifier now operates under a unified GOAL paradigm (default: Streak) that controls strictness, resilience, synthetic fallback allowance, baseline creation, JSON status fields, and exit semantics.  
If `GOAL` is unset it is treated as `Streak` (backward compatible with legacy single-mode behavior).

| Profile | Intent | Synthetic Fallback | Missing Metrics | Strictness | Baseline Creation | Possible Extra JSON Flags | Exit on Missing? |
|---------|--------|-------------------|-----------------|-----------|-------------------|---------------------------|------------------|
| Streak | Rapidly build OK streak (resilient) | Allowed | Warn + continue (`partial`) | Phased (`-uo` early; add `-e` before summary) | Yes (auto) | partial, synthetic_used | No |
| Governance | Pre‑enforcement strict validation | Disallowed | Fail (hard) | Full `-euo pipefail` | Yes (only if complete & real) | (none) | Yes |
| Explore | Developer instrumentation sandbox | Allowed | Warn + continue (`partial`) | Soft (`-uo`, no `-e`) | Yes | partial, synthetic_used, ephemeral | No (unless catastrophic) |
| CI | Deterministic automation gating | Disallowed | Fail (hard) | Full `-euo pipefail` | Yes | (none) | Yes |

Key JSON status fields and emission semantics (Phase 6):

- `goal`
  - Always emitted; normalized to lowercase profile name: `streak|governance|explore|ci`.
- `partial`
  - Emitted as `true` only when one or more requested metrics are missing AND the profile allows partial JSON output (`JSON_PARTIAL_OK=1` → Streak, Explore).
  - Not emitted for Governance/CI (those profiles do not tolerate partial JSON).
- `synthetic_used`
  - Emitted as `true` only when synthetic fallback lines were inserted AND the profile allows synthetic segments (`ALLOW_SYNTHETIC_SEGMENTS=1` → Streak, Explore).
  - Not emitted for Governance/CI. In strict profiles, synthetic usage is handled by gating in enforce mode (see below).
- `ephemeral`
  - Emitted as `true` only when the profile is Explore (`EPHEMERAL_FLAG=1`).
  - Not emitted for Streak/Governance/CI.

Gating semantics (Phase 4 — flags from `apply_goal_profile`):

- Flags:
  - `ALLOW_SYNTHETIC_SEGMENTS` — if 0 and synthetic was used, strict profiles fail in enforce mode.
  - `REQUIRE_ALL_METRICS` — if 1 and any metric is missing, strict profiles fail in enforce mode.
  - `HARD_STRICT`, `STRICT_PHASED`, `SOFT_MISSING_OK` — strictness posture (future layering).
  - `JSON_PARTIAL_OK` — whether `partial: true` can be emitted (Streak/Explore).
  - `EPHEMERAL_FLAG` — whether `ephemeral: true` is emitted (Explore).
- Enforce mode:
  - Governance/CI (strict) — `REQUIRE_ALL_METRICS=1` or `ALLOW_SYNTHETIC_SEGMENTS=0` cause non‑zero exit when violated.
  - Streak/Explore (tolerant) — continue classification; exit semantics unchanged by these flags.
- Observe mode:
  - Never changes exit code; flags only influence JSON emission (where applicable).

Governance activation precondition (A8):
- Three consecutive `GOAL=Governance` runs with no `synthetic_used` and no `partial`.

Quick examples:
```
# Default (Streak)
tools/perf-regression-classifier.zsh --runs 5

# Explicit governance validation
GOAL=Governance tools/perf-regression-classifier.zsh --runs 5

# Explore diagnostic mode
tools/perf-regression-classifier.zsh --goal explore --runs 3 --verbose

# CI deterministic run
GOAL=ci tools/perf-regression-classifier.zsh --runs 5
```

JSON examples (Phase 6 semantics):

Streak (missing metric allowed; synthetic allowed):
```
{
  "overall_status": "OK",
  "goal": "streak",
  "partial": true,
  "synthetic_used": true,
  "metrics": { "...": { /* per-metric fields */ } }
}
```

Explore (missing metric allowed; synthetic allowed; ephemeral=true):
```
{
  "overall_status": "OK",
  "goal": "explore",
  "ephemeral": true,
  "partial": true,
  "synthetic_used": true,
  "metrics": { "...": { /* per-metric fields */ } }
}
```

Governance (strict; no partial/synthetic flags emitted; enforce-mode failure if violated):
```
{
  "overall_status": "FAIL",
  "goal": "governance",
  "metrics": { "...": { /* per-metric fields */ } }
}
```

Notes:
- Conditional flags are omitted when conditions aren’t met (e.g., no `partial` if all metrics present; no `synthetic_used` if none used; no `ephemeral` outside Explore).
- A debug-only overlay (`_debug`) may be included during development builds for diagnostics (e.g., `missing_metrics`, raw latches). This overlay is not part of the stable schema.

A future badge (`goal-state.json`) will summarize readiness (e.g. `streak:building`, `governance:clean`, `ci:strict`).

### 🔜 Recommended Next Steps (Updated Summary)

**PERFORMANCE UPDATE (2025-01-13)**: The previously reported 40+ second startup times were due to incorrect metrics reporting. Actual shell startup performance is excellent at ~334ms with variance < 2%. Migration testing can now proceed safely.

**TESTING STANDARDS UPDATE (2025-01-14)**: Comprehensive ZSH testing standards have been established and integrated into AI guidelines at `dot-config/ai/guidelines/070-testing/090-zsh-testing-standards.md`. Test suite enhancements are being tracked for future implementation.

**CLEANUP UPDATE (2025-01-14 - Part 08.16.01)**: Resolved mistaken redirection issue creating files named `2`. Added `.gitignore` entries to prevent recurrence. Documentation at `docs/redesignv2/FIX_MISTAKEN_REDIRECTION.md`.

**MANIFEST TEST FIX (2025-09-10 - Part 08.18)**: Fixed core functions manifest test for `zsh -f` compatibility (pre-Sprint 2 foundation):
- Added automatic sourcing of core functions module when run in isolation
- Fixed associative array syntax for keys containing `::` 
- Replaced `zsh_debug_echo` with conditional echo for clean shell compatibility
- Updated manifest to include `zf::exports` and `zf::script_dir` functions
- Test now passes in both direct execution and CI runner environments

Focused execution priorities and updated checklist reflecting recent local improvements, CI hygiene additions, and test fixes. Statuses have been refreshed to reflect completed test tooling, CI safeguards, documentation work, and manifest test compatibility. Enforcement (fail-on-regression) remains deferred until the 7-day CI ledger stability gate is satisfied.

1. Multi-Sample Segment Refresh & Monotonic Validation ✓ COMPLETE
   - ✓ N=5 captures (fast-harness) integrated with `tools/update-variance-and-badges.zsh`.
   - ✓ `make perf-update` target available to run fast-harness captures and refresh badges locally.
   - ✓ Nightly CI workflow `ci-variance-nightly.yml` performs automated captures and badge refresh.
   - ✓ Lifecycle monotonicity validated (pre ≤ post ≤ prompt) with non-zero trio in current captures.
   - ✓ Performance badge populated with multi-sample baseline data (example: `334ms 1.9% • core 37–44µs`).

2. Governance & Drift Integration ✓ COMPLETE (observe → gate pending 7-day window)
   - ✓ Governance badge and drift detection integrated into nightly pipeline.
   - ✓ Drift thresholds defined (warn >5%, fail >10%); drift badge generated in observe mode.
   - ✓ `tools/prepare-drift-guard-flip.zsh` updated to prefer repo-level metrics path.
   - Note: Enforcement will only be flipped after the 7-day ledger stability gate completes.

3. Micro-Benchmark Baseline & Automation ✓ COMPLETE
   - ✓ Micro-benchmark baseline captured and surfaced in badge automation.
   - ✓ Badge updater consumes microbench results during nightly runs.
   - ✓ Micro-bench data is included in evidence bundles for enforcement decisions.

4. CI Enforcement & Async Activation Guards ✓ COMPLETE (activation gated)
   - ✓ Async activation checklist implemented in CI (single compinit, prompt emission checks, monotonic lifecycle).
   - ✓ Integration tests and perf lifecycle checks added and runnable via local runner.
   - Reminder: Do not enable `PERF_DIFF_FAIL_ON_REGRESSION=1` on `main` until 7-day stability is demonstrated.

5. Badge Refresh & Maintenance ✓ COMPLETE
   - ✓ README instructions added for manual refresh and CI badge automation.
   - ✓ CI uploads nightly badge artifacts and optionally auto-commits badge updates on `main`.
   - ✓ Local smoke actions documented (integration runner, perf-capture dry-run).

6. Tooling & CI Hygiene — NEWLY COMPLETED
   - ✓ Added a focused local integration runner: `dot-config/zsh/tests/run-integration-tests.sh` (compinit, prompt emission, monotonic lifecycle).
   - ✓ Added `--dry-run` support to `perf-capture-multi.zsh` for safe smoke validation.
   - ✓ Added CI workflow to prevent committing `perf-ledger-YYYYMMDD.json` files: `.github/workflows/ci-prevent-ledger-commit.yml`.

7. Test Infrastructure Hardening — NEWLY COMPLETED (Part 08.18)
   - ✓ Fixed manifest test for `zsh -f` compatibility (runs without startup files)
   - ✓ Resolved associative array key handling for function names with `::`
   - ✓ Updated core functions manifest with missing `zf::exports` and `zf::script_dir`
   - ✓ Ensured all core function tests are self-contained and CI-ready
   - ✓ Added `.gitignore` entry to ignore CI-generated ledgers and allow a seeded examples folder.
   - ✓ Created remediation PR template at `.github/PULL_REQUEST_TEMPLATE.md` for fast rollback when enforcement flips.

7. Stage 3 Exit Preparation — IN PROGRESS → READY FOR TESTING
   - Actions completed:
     - Test tooling and smoke-run support added locally.
     - CI safeguard added to prevent accidental ledger commits.
     - ✅ Shell startup performance verified (~334ms, variance < 2%)
     - ✅ Performance metrics corrected and validated
     - ✅ ZSH Testing Standards documented (ZSH_TESTING_STANDARDS.md)
     - ✅ Testing standards integrated into AI guidelines
     - ✅ Mistaken redirection issue resolved (files named `2` cleanup)
   - Ready to proceed:
     - Comprehensive test suite execution (previously blocked)
     - Migration checklist execution (dot-config/zsh/docs/redesignv2/migration/PLAN_AND_CHECKLIST.md)
     - Documentation updated (README/IMPLEMENTATION) to clarify ledger policy and git-flow guidance.
     - Test suite enhancement per new testing standards
   - Remaining gating requirement:
     - Collect 7 consecutive nightly ledger snapshots produced by CI (retain as artifacts for evidence).
     - Ensure `develop` has consistently green integration and nightly runs for the 7-day window.
   - Once 7-day gate satisfied, prepare a promotion PR to `main` that:
     - Enables `PERF_DIFF_FAIL_ON_REGRESSION=1` (or equivalent enforcement),
     - Attaches the evidence bundle (drift badge, stage3-exit-report.json, last 7 ledgers, microbench baseline),
     - Includes a rollback plan and remediation checklist.

8. Future Promotion Hooks (Logged)
   - Continue planned work (shim elimination, micro-gating, ledger embedding).
   - Keep governance badge and ledger policy as primary inputs to the promotion decision.

Pre-PR Checklist (must pass before enabling enforcement on `main`)
- [ ] `dot-config/zsh/tests/run-integration-tests.sh` passes locally and in CI.
- [ ] Nightly CI produced 7 consecutive `perf-ledger-YYYYMMDD.json` artifacts (downloadable from CI).
- [ ] Drift badge shows no fail condition for the window (observe → guard readiness confirmed).
- [ ] Microbench baseline verified and included in evidence bundle.
- [ ] Remediation PR template and rollback plan are reviewed and owners are notified.
- [ ] CI artifact retention configured to preserve ledger artifacts for evidence (>=7 days, recommended 30 days).
- [ ] No CI-generated ledger files are committed to repo (CI prevent-commit workflow passes).

How to reproduce local checks
- Run focused integration tests:
  - `./dot-config/zsh/tests/run-integration-tests.sh --timeout-secs 30 --verbose`
- Perform a perf-capture smoke dry-run:
  - `./dot-config/zsh/tools/perf-capture-multi.zsh --dry-run`
- Run a single-run capture if needed:
  - `./dot-config/zsh/tools/perf-capture-multi.zsh -n 1 --no-segments --quiet`

Notes
- Keep seeded ledger examples under `docs/redesignv2/artifacts/metrics/ledger-history/seeded/` only for onboarding.
- CI is the authoritative source of daily ledgers; prefer artifacts over committing files to the repo.

---

### Stage 3 Exit Criteria Progress (Updated)

| Criterion | Status | Notes |
|-----------|--------|-------|
| PATH append invariant | [x] | Test present & passing |
| Security skeleton idempotent | [x] | Sentinel + deferred integrity scheduler |
| Option snapshot stability | [x] | Golden snapshot path & diff test green |
| Core functions namespace stable | [x] | Manifest & namespace tests green |
| Integrity scheduler single registration | [x] | No duplicate key on re-source |
| Pre-plugin integrity aggregate alignment | [x] | Generator/test use identical bytes; deterministic enumeration and newline; baseline refreshed |
| Perf provisional budget (pre-plugin) | [x] | Pre stable; post/prompt trio non‑zero & monotonic |
| Perf regression gating (observe→gate) | [~] | Variance mode=guard; perf-drift gating remains observe (await drift readiness) |
| Drift badge integration | [~] | Script integrated; CI publication pending; variance/governance badges stable; drift remains observe |
| Module-fire selftest & modules badge | [~] | Tools integrated; CI selftest and “modules” badge wired. Emission stabilization in progress (settle/grace enabled), soft gate active; optional hard gate available |
| Micro benchmark baseline captured | [x] | Baseline captured (metrics/microbench-core.json); summarized in perf badge |
| All new tests green | [~] | Current scope green; new marker/drift tests queued |

Legend: [x]=complete, [~]=in progress/partial, [ ]=not started.

(See IMPLEMENTATION.md §1.2 & §1.3 for canonical rolling plan and variance log.)

---

## 🎯 **Project Overview**

The redesign transforms a fragmented 40+ file setup into a deterministic **8 pre-plugin + 11 post-plugin** modular system aiming for **≥20% startup improvement** alongside maintainability, safety, and auditability.

### **Key Metrics**
| Metric | Baseline | Target | Current Status |
|--------|----------|--------|----------------|
| Startup Time | 4772ms | ≤3817ms (20% improvement) | Optimization phase pending |
| Module Count | 40+ fragments | 19 modules (8+11) | ✅ Structure ready |
| Test Coverage | Limited legacy | 100+ comprehensive tests | ✅ 67+ implemented (growth ongoing) |
| Performance Gates | Observe mode | Automated regression gating | 🔄 Observe (diff + variance) active |
| Path Rules Compliance | (legacy untracked) | 0 violations | ![Path Rules](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/<OWNER>/<REPO>/gh-pages/badges/path-rules.json) |

### Part 08.19 Update (Stage 4 – Deferred Execution & Dependency Hardening)

**Scope Delivered This Part:**
- Added deferred/postprompt dispatcher skeleton (`96-deferred-dispatch.zsh`)
  - One-shot execution after first prompt
  - Registry API: `zf::defer::register <id> <func> postprompt <desc>`
  - Telemetry emission: `DEFERRED id=<id> ms=<int> rc=<rc>` appended to `PERF_SEGMENT_LOG`
  - Dummy validation job (`dummy-warm`) logged to `${ZDOTDIR}/.logs/deferred.log`
- Dependency edge-case test suite (design test) expanding robustness:
  - Unknown dependency detection
  - Disabled dependency suppression (optional warning)
  - Cycle detection (A↔B, partial enable)
  - Multi-level cycle with disabled node (A→B→C→A, C disabled) – isolated checker ensures correctness
- Enhanced module hardening (`02-module-hardening.zsh`):
  - Added cycle detection with optional scoping (`ZF_CYCLE_SCOPE`) & disabled filtering
  - Introduced `ZF_DISABLED_MODULES`, `ZF_DEPENDENCY_WARN_ON_DISABLED`, `ZF_CYCLE_DETECT_INCLUDE_DISABLED`
  - Added debug instrumentation gated by `ZF_DEP_DEBUG`
- Logging namespace migration (in progress):
  - Introduced namespaced logging API (`zf::log`, `zf::warn`, `zf::err`, etc.)
  - Legacy underscore wrappers retained temporarily (compat telemetry via `ZF_LOG_LEGACY_USED`)
- Telemetry & deferred execution documentation appended (IMPLEMENTATION.md §2.2)
- Performance log scaffold created (`docs/performance/LOG.md`) with initial deferred dispatcher placeholder row

**Key Integrity / Performance Invariants Maintained:**
| Invariant | Status | Notes |
|-----------|--------|-------|
| No pre-prompt regression (>5ms delta) | ✅ | Deferred skeleton adds negligible parse cost |
| Single dispatcher run | ✅ | Guard `_ZSH_DEFERRED_DISPATCH_RAN` |
| Dependency cycle false positives (core set) | ⚠ Mitigated | Scoped isolation added; production detector still reports legacy graph if not scoped |
| Logging namespace drift | ⚠ Transitional | Wrappers scheduled for removal in Sprint 2 |
| Telemetry format stability | ✅ | Existing parsers compatible (SEGMENT / POLICY / DEFERRED / ERROR) |

**New Environment / Control Flags:**
| Variable | Purpose | Default |
|----------|---------|---------|
| `ZF_DISABLED_MODULES` | Declare disabled modules (dependency skip) | (empty) |
| `ZF_DEPENDENCY_WARN_ON_DISABLED` | Emit warning for disabled deps | 0 |
| `ZF_CYCLE_DETECT_INCLUDE_DISABLED` | Force inclusion of disabled nodes in cycle scan | 0 |
| `ZF_CYCLE_SCOPE` | Limit cycle analysis to a subset | (unset → full) |
| `ZF_DEP_DEBUG` | Enable verbose dependency/cycle debug lines | (unset) |
| `ZF_LOG_LEGACY_USED` | Marker set when underscore wrappers invoked | (dynamic) |

**Deferred Dispatcher Telemetry Format (Current):**
```
DEFERRED id=<id> ms=<elapsed_ms> rc=<rc>
```
Planned (Sprint 2) JSON sidecar (behind `ZSH_PERF_JSON=1`):
```
{"type":"deferred","id":"cache-warm","ms":12,"ts":1736551005123}
```

**Known Limitations / Backlog (Moved to Sprint 2):**
- Idle & background triggers for deferred jobs (idle debounce, non-blocking spawn)
- Structured logging mode (`ZSH_LOG_STRUCTURED=1`)
- Automated performance regression classifier (observe → gate)
- Dependency graph export tool (DOT + JSON)
- Removal of underscore logging wrappers (post homogeneity test stabilization)

**Sprint 2 Seed (Confirmed Tracks):**
1. Real segment probes (replace placeholders)
2. Deferred trigger expansion (idle/background)
3. Remove legacy logging wrappers + homogeneity test
4. Performance harness + regression classification (observe phase)
5. Dependency export & DOT visualization
6. Telemetry privacy appendix & structured mode draft

**Actionable Next Steps (Immediate Priority):**
| Order | Action | Rationale |
|-------|--------|-----------|
| 1 | Implement real segment attribution (pre/post/prompt) | Replace placeholders; enable gating |
| 2 | Add homogeneity test & begin wrapper deprecation clock | Reduce dual API surface |
| 3 | Introduce perf harness script & classify Added Feature Delta | Quantify guard thresholds |
| 4 | Implement idle deferred trigger prototype | Unlock non-critical warm tasks |
| 5 | Generate dependency graph export (scope support) | Visual audit & documentation |
| 6 | Add telemetry privacy appendix + opt-out stub | Prepare for structured enrichment |

**Migration Advisory:**
If testing dependency cycles in isolation, *always* set `ZF_CYCLE_SCOPE` to the synthetic node set (e.g., `ZF_CYCLE_SCOPE=(A B C)`) or purge baseline module mappings to avoid legacy graph interference.

**Compliance Anchor:**
All newly authored artifacts for Part 08.19 embed the current `GUIDELINES_CHECKSUM` via early pre-plugin export (`02-guidelines-checksum.zsh`) ensuring traceable policy consistency.

---

> Path Rules badge enforces zero direct raw path extraction outside helpers; failure is immediate (CI fail-fast).
> Helper standard: `zf::script_dir` / `resolve_script_dir`.

---

## Badge Legend (Expanded – New Pending Rows)

| Badge (JSON) | Shield Label | Meaning | Green Criteria | Red Criteria | Source Tool / Job |
|--------------|--------------|--------|----------------|--------------|-------------------|
| perf.json | perf | Current startup vs baseline | ≤ regression threshold | > threshold | generate-perf-badge.zsh |
| structure.json | structure | Module structure / drift | Expected counts/order | Missing/unexpected | generate-structure-badge.zsh |
| summary.json | summary | Aggregated status snapshot | No critical failing subsystems | Critical flag failing | generate-badges-summary.zsh |
| infra-health.json | infra health | Infra & maintenance signals | All subsystems healthy | Critical infra flag | generate-infra-health-badge.zsh |
| infra-trend.json | infra trend | Directional infra trend | Stable / improving | Major negative delta | compute-infra-trend.zsh |
| style.json | shell style | Style audit result | 0 violations | ≥1 violation (info now) | style-audit-shell.sh |
| path-rules.json | path rules | Path resolution compliance | 0 violations | ≥1 violation | enforce-path-resolution.zsh |
| preplugin-variance.json | preplugin variance | Baseline variance stability | Low RSD (<5%) | High variance / insufficient samples | generate-preplugin-variance-badge.zsh |
| hooks.json | hooks | Git hook integrity | hooksPath OK + required hooks present | Mismatch/missing | CI hook check |
| perf-ledger.json | perf ledger | Budget adherence (prototype) | overBudgetCount = 0 | Any overBudgetCount (observe now) | perf-module-ledger.zsh |
| perf-drift.json (pending) | perf drift | Regression summary vs baseline | Max regression ≤ threshold; segments present | Regression > gating threshold or missing data | perf-drift-badge.sh |
| bench-core-baseline.json (pending) | micro bench | Core helpers per-call cost | All median per-call ≤ baseline + tolerance | Drift over tolerance | bench-core-functions.zsh |
| variance-state.json (planned) | variance | Enforcement mode state | Reported mode matches conditions | Inconsistent / stale | variance decision step |
| governance.json | governance | Aggregated redesign governance signals (perf drift, perf ledger, variance mode (derived until variance-state.json exists), micro bench baseline) | All source signals present; severity ok or warn only; no FAIL triggers (max regression <10%, over_budget_count=0 OR variance_mode!=gate, no micro fail) | Any fail trigger (max regression ≥10%, over_budget_count>0 in gate mode, microbench fail ratio, or all sources missing) | generate-governance-badge.zsh (ci-perf-segments + nightly ledger) |
| goal-state.json (planned) | goal | Classifier profile & readiness | Profile reported + (if governance) clean (no synthetic/partial) | Inconsistent profile vs run intent OR synthetic/partial present under governance/ci | (future) generate-goal-state-badge.zsh |

Notes:
- Rows labeled (pending) activate after first artifact commit; placeholders here aid discoverability. Governance badge is now active (row no longer marked pending).
- `perf-drift.json` message will embed max positive regression once ledger integration finalizes.
- Micro benchmark badge remains informational until shim elimination (F16/F17) and micro gating thresholds enforced.

---

## 📋 **Current Status Dashboard**

### **Stage Progress**
| Stage | Status | Completion | Next Action |
|-------|--------|------------|-------------|
| 1. Foundation & Testing | ✅ Complete | 100% | Closed |
| 2. Pre-Plugin Migration | ✅ Complete | 100% | Closed |
| 3. Post-Plugin Core | ✅ Complete | 100% | All migration, runner, and CI upgrades finished |
| 4. Features & Environment | 🚧 In Progress | 0% | Feature layer implementation |
| 5. UI & Performance | ⏳ Pending Stage 4 | 0% | Future |
| 6. Validation & Promotion | ⏳ Pending Stage 5 | 0% | Future |
| 7. Cleanup & Finalization | ⏳ Pending Stage 6 | 0% | Future |

### **Key Achievements** ✅
- **Testing Infrastructure**: 67+ tests across 6 categories
- **Manifest Test**: Now passes in isolation (`zsh -f`)
- **CI & Documentation**: All references migrated to `run-all-tests-v2.zsh`
- **Performance**: 334ms startup, 1.9% variance
- **Governance**: Guard stable, badge automation, nightly CI ledger monitoring
- **Core Hardening**: Security skeleton, path invariants, options snapshot, core function namespace
- **Performance Tooling**: Multi-sample capture, variance log, drift badge script, ledger prototype
- **Benchmark Harness**: Micro-benchmark harness stabilized with transparent shim fallback & JSON artifact design
- **Governance**: Trust anchor read APIs & future hashing path documented
- **Segment & Prompt Stability**: Added post-harness settle window and prompt grace; tightened salvage (granular segment sum) and zero-diagnose synthesis to eliminate all‑zero lifecycles
- **Module Emission & Badges**: Introduced module-fire selftest and module tracer; integrated “modules” badge and included it in summary badge aggregation
- **Integrity Manifest**: Generator/test aggregate aligned byte-for-byte; deterministic order + newline handling; baseline refreshed
- **Async Initial-State Test**: Converted last assertion to behavioral-only; PASS on this system

---

## 📚 **Documentation Navigation**

### **🎯 Quick Start Guides**
- **[IMPLEMENTATION.md](IMPLEMENTATION.md)** – Execution & rolling 7‑day plan
- **[ARCHITECTURE.md](ARCHITECTURE.md)** – Design principles & layering
- **[REFERENCE.md](REFERENCE.md)** – Operational commands & troubleshooting
- **[RISK-ASYNC-PLAN.md](RISK-ASYNC-PLAN.md)** – Async enablement & mitigation strategy

### **🧪 Testing Documentation**
- **[ZSH_TESTING_STANDARDS.md](ZSH_TESTING_STANDARDS.md)** – Comprehensive testing standards for ZSH scripts
- **[testing/TEST_IMPROVEMENT_PLAN.md](testing/TEST_IMPROVEMENT_PLAN.md)** – Phased plan to enhance test suite per standards
- **[migration/PLAN_AND_CHECKLIST.md](migration/PLAN_AND_CHECKLIST.md)** – Migration testing checklist and procedures

### **📊 Implementation Tracking**
- Stage documents: `stages/stage-1-foundation.md` (✅), `stage-2-preplugin.md` (✅), `stage-3-core.md` (⏳ live checklist), others pending.

### **📁 Implementation Artifacts**
- `artifacts/inventories/` – Inventories & baselines
- `artifacts/metrics/` – Performance + (pending) micro bench artifacts
- `artifacts/badges/` – Badge JSON endpoints
- `artifacts/checksums/` – Integrity baselines (generator/test aggregate aligned; baseline refreshed)

### **📚 Archive & Historical**
- `archive/planning-complete/` – Completed planning docs
- `archive/deprecated/` – Superseded or retired materials

---

**Migration Note:**  
As of September 2025, the legacy test runner `run-all-tests.zsh` is deprecated.  
Please use `run-all-tests-v2.zsh` for all comprehensive and isolated ZSH configuration testing.  
The new runner enforces standards-compliant isolation (`zsh -f`), explicit dependency declaration, and robust reporting.  
All scripts, CI, and documentation now reference `run-all-tests-v2.zsh`.

---

**Migration Note:**  
As of September 2025, the legacy test runner `run-all-tests.zsh` is deprecated.  
Please use `run-all-tests-v2.zsh` for all comprehensive and isolated ZSH configuration testing.  
The new runner enforces standards-compliant isolation (`zsh -f`), explicit dependency declaration, and robust reporting.  
Update all scripts, CI, and documentation to reference `run-all-tests-v2.zsh` instead of the legacy runner.

## ⚡ **Quick Commands**

### Essential Operations
```bash
# Verify overall implementation status
./verify-implementation.zsh

# Run comprehensive tests (standards-compliant, isolated)
tests/run-all-tests-v2.zsh

# Capture single-run performance segments
tools/perf-capture.zsh

# Multi-sample capture (forces refresh)
PERF_CAPTURE_FORCE=1 tools/perf-capture-multi.zsh

# Capture pre-plugin baseline (multi-sample)
tools/preplugin-baseline-capture.zsh
```

### Benchmark Harness
```bash
# Run core function micro-benchmark baseline (observational)
bench/bench-core-functions.zsh --json --iterations 5000 --repeat 3 \
  > docs/redesignv2/artifacts/metrics/bench-core-baseline.json

# (Future) Drift comparison (schema bench-core.v1)
bench/bench-core-functions.zsh --json --compare docs/redesignv2/artifacts/metrics/bench-core-baseline.json
```

### Performance Drift / Ledger (Observe Mode)
```bash
# Generate drift badge candidate (non-fatal currently)
tools/perf-drift-badge.sh --segments docs/redesignv2/artifacts/metrics/perf-current-segments.txt \
  --output docs/redesignv2/artifacts/badges/perf-drift.json || true

# Experimental ledger (soft budgets)
tools/experimental/perf-module-ledger.zsh \
  --segments docs/redesignv2/artifacts/metrics/perf-current-segments.txt \
  --output docs/redesignv2/artifacts/metrics/perf-ledger.json \
  --budget post_plugin_total:3000,pre_plugin_total:120 \
  --badge docs/redesignv2/artifacts/badges/perf-ledger.json || true
```

---

## 🧭 CI Workflows — Scope and RACI

This section defines clear scope boundaries and RACI for repository-wide (repo-*) and ZSH‑project (zsh-*) workflows to avoid overlap and to simplify ownership and troubleshooting.

### Scope boundaries

- Repository-wide (repo-*)
  - Purpose: Cross-repo governance and nightly badge freshness; consumes artifacts produced by the ZSH project.
  - Assumptions: Runs from repo root; must not assume ZDOTDIR; may publish to gh‑pages; may auto‑commit badges/state on main.
  - Examples:
    - repo-Variance Nightly
    - repo-Perf Ledger Nightly

- ZSH project (zsh-*)
  - Purpose: Generate ZSH artifacts (metrics, badges, structure checks) under docs/redesignv2/artifacts and bridge to legacy paths during migration.
  - Assumptions: Runs with working-directory: dot-config/zsh; sets ZDOTDIR="${{ github.workspace }}/dot-config/zsh"; owns structure and perf generation logic.
  - Examples:
    - zsh-Redesign — nightly perf
    - zsh-Nightly Metrics Refresh
    - zsh-Perf & Structure CI

### RACI matrix (concise)

- repo-Perf Ledger Nightly
  - R: Infra/Perf CI
  - A: Repo Owners
  - C: ZSH Maintainers
  - I: Contributors

- repo-Variance Nightly
  - R: Infra/Perf CI
  - A: Repo Owners
  - C: ZSH Maintainers
  - I: Contributors

- zsh-Redesign — nightly perf
  - R: ZSH Maintainers
  - A: ZSH Lead
  - C: Infra/Perf CI
  - I: Repo Owners

- zsh-Nightly Metrics Refresh
  - R: ZSH Maintainers
  - A: ZSH Lead
  - C: Infra/Perf CI
  - I: Repo Owners

- zsh-Perf & Structure CI
  - R: ZSH Maintainers
  - A: ZSH Lead
  - C: Infra/Perf CI
  - I: Repo Owners

### Operational guardrails

- Working directory
  - zsh-* workflows: defaults.run.working-directory: dot-config/zsh
  - repo-* workflows: run from repo root; pass ZDOTDIR explicitly when calling project tools

- Artifact roots
  - Prefer docs/redesignv2/artifacts/{metrics,badges}; soft-bridge to docs/redesign/* during migration windows

- Naming and triggers
  - Prefixes: repo-* for repository scope, zsh-* for project scope
  - Schedules (UTC):
    - zsh-Nightly Metrics Refresh: 03:15
    - zsh-Redesign — nightly perf: 04:00
    - repo-Variance Nightly: 04:15
    - repo-Perf Ledger Nightly: 05:05

- Drift and gating
  - Default to observe mode; promotion to warn/gate governed by repo variables and stability streaks (see variance/ledger notes)
  - Do not fail fast on missing inputs; produce placeholders to preserve nightly continuity

- PR templates
  - The repo uses a PR template chooser under .github/PULL_REQUEST_TEMPLATE/
  - The ZSH project relies on those templates; the project-local template was removed to reduce confusion

### Extending the workflows

- Repository-wide tasks: create repo-* workflows; operate from repo root; document inputs/outputs and badge publishing behavior
- ZSH project tasks: create zsh-* workflows; operate under dot-config/zsh; ensure all artifacts land in docs/redesignv2/artifacts and bridge to legacy as needed

---

## 🏗️ **Architecture Summary**

### Pre-Plugin Modules (8 files)
```
.zshrc.pre-plugins.d.REDESIGN/
00-path-safety.zsh
05-fzf-init.zsh
10-lazy-framework.zsh
15-node-runtime-env.zsh
20-macos-defaults-deferred.zsh
25-lazy-integrations.zsh
30-ssh-agent.zsh
40-pre-plugin-reserved.zsh
# Early instrumentation helpers (not counted): 01-segment-lib-bootstrap.zsh, 02-guidelines-checksum.zsh
```

### Post-Plugin Modules (11 files)
```
.zshrc.d.REDESIGN/
00-security-integrity.zsh
05-interactive-options.zsh
10-core-functions.zsh
20-essential-plugins.zsh
30-development-env.zsh
40-aliases-keybindings.zsh
50-completion-history.zsh
60-ui-prompt.zsh
70-performance-monitoring.zsh
80-security-validation.zsh
90-splash.zsh
```

---

## 🛡️ **Safety & Quality Assurance**

### Automated Safety Gates
- Structure & sentinel validation
- Performance diff (observe → future warn/gate)
- Path rules enforcement (badge + fail-fast)
- Option snapshot & namespace stability
- Async deferral strategy (shadow now; activation later)
- Checksum freeze (legacy integrity baseline)

### Performance Monitoring
- Lifecycle segments: `pre_plugin_total`, `post_plugin_total`, `prompt_ready`
- Hotspot segments: `compinit`, `p10k_theme`, (conditional) `gitstatus_init`
- Variance & regression: multi-sample JSON + diff tooling
- Micro benchmark harness (core helpers dispatch overhead & helper latency)

---

## 🎯 **Success Criteria (Snapshot)**

| Objective | Current | Target |
|-----------|---------|--------|
| ≥20% startup improvement | Pending optimization | ≤3817ms |
| Module consolidation | 19 modules stable | Maintain 8 + 11 |
| Test coverage growth | 67+ tests | 100+ (Stage 5+) |
| Single compinit | Deferred | Exactly 1 (Stage 5 exit) |
| Async non-blocking | Shadow only | Verified gating (Stage 6) |
| Perf gating | Observe | Gate (variance qualified) |
| Micro benchmark baseline | Harness ready | Baseline committed |

---

Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

### Stage 4 Sprint 2 Status (Part 08.19 Refresh)
- Logging homogeneity complete: legacy underscore wrappers removed; gate test green (no `ZF_LOG_LEGACY_USED`)
- Real segment probes active (all planned granular + phase anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total`)
- Deferred dispatcher skeleton operational (one-shot postprompt, telemetry line: `DEFERRED id=<id> ms=<int> rc=<rc>`)
- Structured telemetry flags available & inert by default: `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`
- Multi-metric performance classifier running in observe mode (Warn 10% / Fail 25%); enforce flip (S4-33) pending 3× consecutive OK streak
- Dependency export (`zf::deps::export` JSON + DOT) & DOT generator integrated with basic tests
- Privacy appendix published & referenced (governance / redaction whitelist)
- Baseline unchanged: 334ms cold start (RSD 1.9%) – no regression after new instrumentation
- Immediate focus: finalize documentation sync (homogeneity rules), idle/background trigger design (S4-27), telemetry opt-in plumbing (S4-18), classifier governance row activation procedure (S4-33)

## 📞 **Support & Troubleshooting**

- **Performance anomalies**: Re-run multi-sample capture; inspect `perf-multi-current.json` and drift badge output.
- **Benchmark oddities**: Check `shimmed_count` in micro bench JSON; if >0, enumeration fallback occurred (replace shims before enforcing drift).
- **Namespace drift**: Run function manifest test (see IMPLEMENTATION.md for invocation details).

---

## 📊 **Project Statistics**

- **Total Modules**: 19 (8 + 11)
- **Tests**: 67+ (design / unit / feature / integration / security / performance)
- **Perf Tooling**: Segment capture, diff, ledger prototype, drift badge script
- **Benchmarking**: Core function harness (shim-aware, JSON artifact)
- **Governance**: Variance log, trust anchor APIs, path rules badge, helper verifier

---

## ✅ Stage 3 Readiness Checklist (Live Mirror)

### Current Status (2025-09-10)
- All migration, runner, and CI upgrades complete
- Manifest test passes in isolation
- All documentation and onboarding updated
- Nightly CI ledger monitoring in progress
- Ready for Stage 4 feature layer implementation

### Next Steps
- Run comprehensive test suite with new runner
- Document and fix any remaining test failures
- Monitor CI ledger for stability
- Begin Stage 4 feature layer implementation
| Check | Status |
|-------|--------|
| PATH append invariant test passes | ✅ |
| Security skeleton idempotent | ✅ |
| Option snapshot stable | ✅ |
| Core function namespace stable | ✅ |
| Integrity scheduler registered exactly once | ✅ |
| Pre-plugin integrity aggregate aligned (generator=test; baseline refreshed) | ✅ |
| Async initial-state test: behavioral-only assertion (no warning-text dependency) | ✅ |
| Lifecycle segments non-zero (post/prompt) | ⏳ Pending instrumentation confirmation |
| Micro benchmark baseline committed | ⏳ Pending |
| Drift badge integrated in CI | ⏳ Pending |
| Perf diff warn/gate toggle decision | ⏳ Waiting variance streak |
| Re-source idempotency (00/05/10) | ✅ |
| Monotonic timing test (pre ≤ post ≤ prompt) | ⏳ Pending non-zero segments |

---

## 🚀 Active Task Focus (Condensed)
| ID | Focus | Mode |
|----|-------|------|
| T1 | Non-zero post/prompt segments capture | Blocking |
| T2 | Authentic variance stabilization (N=5); remove synthetic replication (F49→F48) | Blocking |
| T3 | Recompute variance-state and update governance badge (F50) | Active |
| T4 | Commit micro-benchmark baseline and surface in docs/badges | Active |
| T5 | Prepare async activation checklist (single compinit precondition) | Active |
| T2 | Drift badge CI integration | Blocking |
| T3 | Micro bench baseline commit | Blocking |
| T4 | Marker presence & monotonic tests | Near-term |
| T5 | Gating enablement (perf diff) decision | Conditional |
| F16 | Replace shim fallback (enumeration) | Future |
| F17 | Shim guard test (shimmed_count > 0 fail) | Future |
| F2 | Embed max regression in ledger JSON | Future |
| F7 | Combined governance badge | Future |

Full future backlog & variance log: IMPLEMENTATION.md §1.3 & §1.4.

---

## ℹ️ Micro-Benchmark Harness Notes

- JSON meta fields include:
  - `enumeration_mode`: `dynamic` | `exports_fallback`
  - `shimmed_count`: Number of functions replaced with no-op shims (dispatch overhead only)
  - `version`: `bench-core.v1`
- Baseline is observational until all shims eliminated.
- Drift logic (planned): warn if median per-call exceeds baseline median * 2 (temporary heuristic) until stricter statistical threshold introduced.

---

**Next Action Reminder**: Capture multi-sample after ensuring lifecycle trio instrumentation → integrate drift badge → record variance log entry → commit micro bench baseline → prepare Stage 3 exit report.

---

*Authoritative reference: For any discrepancy, see `IMPLEMENTATION.md` (single source of execution truth).*

---

## Stage 3 Exit — Summary & Status

Status: ready to proceed to Stage 4 (feature development) — with operational caveats.

Evidence:
- Variance guard: mode="guard", stable_run_count=3 (see docs/redesignv2/artifacts/metrics/variance-gating-state.json).
- Recent authenticated multi-sample capture: `dot-config/zsh/docs/redesignv2/artifacts/metrics/perf-multi-simple.json` (N=5, post mean ≈ 334ms, RSD ≈ 1.9%).
- Governance badge updated: `dot-config/zsh/docs/redesignv2/artifacts/badges/governance.json` (message: "guard: stable").
- Microbench baseline present: `dot-config/zsh/docs/redesignv2/artifacts/metrics/microbench-core.json`.

Caveats before enabling hard drift enforcement (FAIL on regression):
- The drift-enforcement flip (observe → enforce/fail) must wait until a 7-day CI-driven stability window is observed in the _ledger-history_. We seeded ledger-history for local readiness checks; CI must populate `docs/redesignv2/artifacts/metrics/ledger-history/` nightly for a full evaluation.
- Confirm CI workflows exist and are configured: `.github/workflows/ci-variance-nightly.yml` and `.github/workflows/ci-async-guards.yml`.
- Verify async activation checklist in CI: ensure `tests/integration/*` execute successfully in CI environment (we added a robust local test framework shim to run the prompt single-emission check).

Recommended immediate actions (short):
- Let CI run nightly for 7 days to accumulate genuine ledger-history snapshots.
- After 7-day stability without regressions, enable `PERF_DIFF_FAIL_ON_REGRESSION=1` on main and monitor for 48 hours.

For details and machine-readable report, see `dot-config/zsh/docs/redesignv2/artifacts/metrics/stage3-exit-report.json`.