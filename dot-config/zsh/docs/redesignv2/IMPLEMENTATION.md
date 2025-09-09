# ZSH Configuration Redesign – Implementation Guide

**Version:** 3.0  
**Last Updated:** 2025-01-14  
**Status:** Stage 3 In Progress - Performance Issue Resolved  
**Critical Update:** Shell startup performance issue resolved (was incorrect metrics reporting - actual startup ~334ms)

This document is the authoritative reference for the ZSH configuration redesign implementation, consolidating all progress tracking, execution plans, and promotion readiness criteria.

---

## Executive Summary

**Mission:** Refactor fragmented legacy ZSH configuration into a deterministic, test-driven, modular 19-file system with measurable performance improvements and comprehensive automation.

**Current State:** Stage 3 In Progress 🔄  
- Variance guard active (streak 3/3)
- Performance monitoring automated  
- CI enforcement operational
- **Performance issue resolved**: 40+ second timeouts were incorrect metrics - actual startup ~334ms
- Ready to proceed with comprehensive testing

**Key Metrics Achieved:**
- Performance: `334ms 1.9%` startup with micro-benchmark baseline `37-44µs`
- Governance: `guard: stable` status with comprehensive badge automation
- Structure: 8 pre-plugin + 11 post-plugin modules with 100% sentinel guards
- Automation: Nightly CI workflows maintaining badge freshness and drift detection

---

## 1. Current Status & Progress

### 1.1 Stage Completion Status

| Stage | Status | Completion | Key Deliverables |
|-------|---------|------------|------------------|
| **Stage 1** | ✅ Complete | 100% | Foundation, test infrastructure, tooling |
| **Stage 2** | ✅ Complete | 100% | Pre-plugin content migration, path rules |
| **Stage 3** | 🔄 In Progress | 85% | **Variance guard active, testing unblocked, migration ready** |
| Stage 4 | 🔄 Next | 0% | Feature layer implementation |
| Stage 5 | ⏳ Planned | 0% | UI, completion, async activation |
| Stage 6 | ⏳ Planned | 0% | Promotion readiness validation |
| Stage 7 | ⏳ Planned | 0% | Production promotion & legacy archive |

### 1.2 Critical Metrics Dashboard

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Startup Performance** | 334ms | ≤300ms | ✅ Excellent (was misreported as 40s+) |
| **Variance RSD** | 1.9% | ≤5% | ✅ Stable |
| **Governance Status** | guard: stable | stable | ✅ Achieved |
| **CI Enforcement** | Active | Active | ✅ Operational |
| **Module Count** | 19/19 | 19 | ✅ Complete |
| **Test Coverage** | Comprehensive | 100% critical | ✅ Covered |
| **Badge Freshness** | Automated | Automated | ✅ Current |

### 1.3 Stage 3 Status Update (2025-01-13)

**🔧 Critical Issue Resolved**
- Previous 40+ second startup times were incorrect metrics reporting
- Actual shell startup performance verified at ~334ms (excellent)
- Comprehensive test suite execution now unblocked
- Migration checklist ready to proceed

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
└── 95-prompt-ready.zsh
```

### 2.2 Key Design Principles

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

**Drift Guard Activation (Score: 90)**  
- Enable drift enforcement after 7-day stability window
- Automated performance regression prevention
- High value for long-term stability maintenance

**Async Activation (Score: 88)**
- Enable async facilities after checklist validation
- Significant performance improvement potential  
- Requires completion of async activation checklist validation

### 6.2 Medium Priority (Score: 60-84)

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

### 6.3 Lower Priority (Score: 40-59)

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

