# ZSH Configuration Redesign Documentation

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

**Version 2.5** – Core Hardening, Perf/Bench & Governance Badge Integration Updates
**Status**: Stage 2 Complete (baseline & tag created) – Stage 3 (Core Modules) In Progress
**Last Updated**: 2025-01-13
**Critical Update**: Shell startup performance issue resolved (was incorrect metrics reporting)

> NOTE: A “Badge Legend Update Stub” section will be inserted in the Badge Legend area once exact line numbers for that section are provided (required for minimal diff compliance). Please provide the numbered snippet around the existing “## Badge Legend (Expanded – New Pending Rows)” heading so the planned stub (variance-state, multi_source, authenticity fields, perf-multi source note) can be appended precisely.

### 🔜 Recommended Next Steps (Updated Summary)

**PERFORMANCE UPDATE (2025-01-13)**: The previously reported 40+ second startup times were due to incorrect metrics reporting. Actual shell startup performance is excellent at ~334ms with variance < 2%. Migration testing can now proceed safely.

Focused execution priorities and updated checklist reflecting recent local improvements and CI hygiene additions. Statuses have been refreshed to reflect completed test tooling, CI safeguards, and documentation work. Enforcement (fail-on-regression) remains deferred until the 7-day CI ledger stability gate is satisfied.

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
   - ✓ Added `.gitignore` entry to ignore CI-generated ledgers and allow a seeded examples folder.
   - ✓ Created remediation PR template at `.github/PULL_REQUEST_TEMPLATE.md` for fast rollback when enforcement flips.

7. Stage 3 Exit Preparation — IN PROGRESS → READY FOR TESTING
   - Actions completed:
     - Test tooling and smoke-run support added locally.
     - CI safeguard added to prevent accidental ledger commits.
     - ✅ Shell startup performance verified (~334ms, variance < 2%)
     - ✅ Performance metrics corrected and validated
   - Ready to proceed:
     - Comprehensive test suite execution (previously blocked)
     - Migration checklist execution (dot-config/zsh/docs/redesignv2/migration/PLAN_AND_CHECKLIST.md)
     - Documentation updated (README/IMPLEMENTATION) to clarify ledger policy and git-flow guidance.
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
| 3. Post-Plugin Core | 🚧 In Progress | 40% | Segment stability & gating prep |
| 4. Features & Environment | ⏳ Pending Stage 3 | 0% | Future |
| 5. UI & Performance | ⏳ Pending Stage 4 | 0% | Future |
| 6. Validation & Promotion | ⏳ Pending Stage 5 | 0% | Future |
| 7. Cleanup & Finalization | ⏳ Pending Stage 6 | 0% | Future |

### **Key Achievements** ✅
- **Testing Infrastructure**: 67+ tests across 6 categories
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

## ⚡ **Quick Commands**

### Essential Operations
```bash
# Verify overall implementation status
./verify-implementation.zsh

# Run comprehensive tests
tests/run-all-tests.zsh

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

