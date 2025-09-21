# ZSH Redesign Task Tracker
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316

**Last Updated:** 2025-09-10 (Part 08.19 – Instrumentation Status Refresh)  
**Current Stage:** Stage 4 (Sprint 2 – Instrumentation & Telemetry)  
**Next Milestone:** Segment Probes + Logging Homogeneity (INTEGRATED → shifting focus to governance & opt-in telemetry)

### Sprint 2 Status Snapshot (Part 08.19.10)
- Logging homogeneity COMPLETE (legacy underscore wrappers removed; no `ZF_LOG_LEGACY_USED`; gate test green)
- Real segment probes ACTIVE (anchors: `pre_plugin_start`, `pre_plugin_total`, `post_plugin_total`, `prompt_ready`, `deferred_total` + granular feature/dev-env/history/security/ui attribution)
- Deferred dispatcher skeleton OPERATIONAL (one-shot postprompt; stable `DEFERRED id=<id> ms=<int> rc=<rc>` telemetry)
- Structured telemetry flags AVAILABLE & inert when unset: `ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON` (zero overhead disabled path)
- Multi-metric performance classifier in OBSERVE mode (Warn 10% / Fail 25%); enforce flip (S4-33) pending 3× consecutive OK streak
- Dependency export (`zf::deps::export`) JSON + DOT + basic tests COMPLETE
- Privacy appendix PUBLISHED (redaction whitelist stabilized; referenced across docs)
- Baseline unchanged: 334ms cold start (RSD 1.9%) after new instrumentation
- Immediate focus: 
  * S4-27 idle/background trigger design & stubs (ref: feature/IDLE_DEFERRED_TRIGGER_DESIGN.md)
  * S4-18 telemetry opt-in plumbing (`ZSH_FEATURE_TELEMETRY`) (ref: IMPLEMENTATION.md Telemetry Opt-In Plumbing section)
  * S4-29 homogeneity documentation finalization (namespace rules)
  * S4-30 classifier legend + PERFORMANCE_LOG governance row template integration
  * S4-33 enforce-mode activation procedure (track OK streak & readiness checklist)

## Recently Completed (Part 08.19.10)

### ✅ GOAL & CI — Latest Completions (08.19.10)
- Classifier single-metric JSON ordering moved earlier to ensure “always-before-exit” parity with multi-metric (deterministic artifacts even on enforce failures).
- Capture-runner stderr noise (“bad math expression”) suppressed without altering capture logic or metrics.
- Dynamic badges:
  - goal-state badge emitted at docs/redesignv2/artifacts/badges/goal-state.json
  - summary-goal badge emitted at docs/redesignv2/artifacts/badges/summary-goal.json (folds in perf-drift and structure badges; color reflects worst severity)
- CI wiring:
  - Strict classifier workflow (GOAL=ci enforce) generates perf-current.json and goal-state badge; artifacts uploaded.
  - Nightly publisher runs classifier, generates goal-state + summary-goal badges, ensures perf-drift & structure badges, and publishes to gh-pages with index.
  - Post-publish step auto-replaces README placeholders with repo-specific Shields endpoints once badges land on gh-pages.
- Test suite: remaining T-GOAL-02..06 executed and passing with gawk available; tests gracefully skip if gawk is missing; JSON parsing regexes hardened.

### ✅ Deferred Dispatcher Skeleton
- One-shot post-first prompt execution
- Registration API: `zf::defer::register <id> <func> postprompt <desc>`
- Telemetry line: `DEFERRED id=<id> ms=<int> rc=<rc>`
- Dummy warm job: `dummy-warm` (ensures path exercised)

### ✅ Dependency Cycle Edge-Case Test Suite
- Unknown dependency handling
- Disabled dependency suppression
- Multi-level cycle detection
- Cycle broken by disabled node (isolation)

### ✅ Cycle Detector Enhancements
- Disabled filtering toggle
- Scope limiting via `ZF_CYCLE_SCOPE`
- Include-disabled optional scan flag

### ✅ Logging Namespace Migration (Phase 1)
- Introduced `zf::log`, `zf::warn`, `zf::err`
- Legacy underscore wrappers retained temporarily (compat marker `ZF_LOG_LEGACY_USED`)

### ✅ Telemetry & Deferred Documentation Expansion
- IMPLEMENTATION.md §2.2 enriched (DEFERRED / SEGMENT formats)
- Performance Log scaffold updated (deferred placeholder row)

### ✅ Baseline Performance Revalidated
- 334ms startup, 1.9% variance (no regression after dispatcher integration)

## Recently Completed (Part 08.18)

### ✅ Manifest Test Hardening
- **Issue:** Test failed when run with `zsh -f` (no startup files)
- **Root Causes:**
  1. Core functions not sourced automatically
  2. Associative array syntax incompatible with `::` in keys
  3. Debug function (`zsh_debug_echo`) unavailable in clean shell
- **Fixes Applied:**
  - Added automatic sourcing of `10-core-functions.zsh` module
  - Fixed associative array syntax: `HASH[$key]=value` (no quotes)
  - Replaced debug function with conditional echo statements
  - Updated manifest with missing functions (`zf::exports`, `zf::script_dir`)
- **Verification:** Test passes in both direct execution and CI runner

### ✅ Test Runner Migration
- **Issue:** Legacy runner (`run-all-tests.zsh`) did not enforce isolation and was referenced in CI/docs
- **Fixes Applied:**
  - Migrated all CI workflows and documentation to `run-all-tests-v2.zsh`
  - Deprecated legacy runner and added warning header
  - Updated onboarding and quick start guides
- **Verification:** All CI and documentation now reference new runner; isolation (`zsh -f`) enforced

### ✅ CI Enforcement & Documentation Update
- All progress trackers, onboarding, and reference docs updated
- Manifest test passes in isolation and CI
- Performance: 334ms startup, 1.9% variance

## Active Tasks (In Progress)

### 🚀 Stage 4 Sprint 2 (Instrumentation & Telemetry Expansion)

#### Next Steps to progress & complete Sprint 2 (Part 08.19.10)
- [x] Add CI assertion to fail when summary-goal severity collapses to red in publisher workflow
- [x] Add tiny integration check to ensure summary-goal.json exists whenever goal-state.json exists
- [x] Add minimal test validating summary-goal suffix composition (drift/struct) and keep it resilient
- [x] Document badge legend and README notes for goal-state and summary-goal, including severity mapping and suffix rules
- [ ] Monitor next gh-pages publish to confirm both badges (goal-state.json, summary-goal.json) are present
- [ ] Verify README auto-resolves placeholder endpoints to <org>/<repo> after publish
- [ ] Validate resilience: missing perf-drift.json/structure.json yields no suffix and does not raise severity
- [ ] Confirm dependency coverage: gawk ensured on macOS runner; ubuntu-latest uses GNU awk; tests skip gracefully if absent
- [ ] Decide on optional mapping refinements:
  - Governance: treat BASELINE_CREATED as informational vs. clean
  - Streak: consider nuanced “building” based on number/nature of missing metrics

##### Exit Criteria (Sprint 2)
- First gh-pages publish contains badges/goal-state.json and badges/summary-goal.json
- README endpoints auto-resolved to the real repository
- CI publisher fails runs on red summary-goal severity (guardrail active)
- Summary-goal suffix test passes in CI; logs remain free of “bad math expression” noise
- Resilience confirmed: absence of suffix sources does not inflate severity

| Task | Description | Status | Notes |
|------|-------------|--------|-------|
| S4-20 | Real segment probes (replace placeholders) | ✅ Done | All planned granular probes added: safety/aliases, navigation/cd, ui/prompt-setup, security/validation plus existing anchors (pre_plugin_start, pre_plugin_total, post_plugin_total, prompt_ready, deferred_total) |
| S4-21 | Logging homogeneity test | ✅ Done | Strict absence gate enforced (no underscore wrappers) |
| S4-22 | Remove legacy underscore log wrappers | ✅ Done | Wrappers removed; homogeneity test green; ZF_LOG_LEGACY_USED retired |
| S4-23 | Structured telemetry flag stubs (`ZSH_LOG_STRUCTURED`, `ZSH_PERF_JSON`) | ✅ Done | Flags integrated; segment & deferred JSON sidecar emitting when enabled |
| S4-24 | Performance regression harness + classifier | ✅ Done | Multi-metric CI integrated (ci-performance.yml); baseline presence & telemetry schema validation tests added (`tests/performance/telemetry/test-classifier-baselines.zsh`, `tests/performance/telemetry/test-structured-telemetry-schema.zsh`), schema validator tool added (`tools/test-structured-telemetry-schema.zsh`); pending enforce-mode flip after 3 consecutive OK runs (to be logged in PERFORMANCE_LOG) |
| S4-25 | Dependency export command (`zf::deps::export`) | ✅ Done | JSON + DOT export tool landed (modules + features) |
| S4-26 | DOT generator tool & test | ✅ Done | Integrated in export tool; basic structural test coverage via structured telemetry suite |
| S4-27 | Idle/background trigger design | ⏳ Pending | Design doc + stub (no heavy jobs) |
| S4-28 | Privacy appendix & redaction hooks | ✅ Done | Appendix published (privacy/PRIVACY_APPENDIX.md); field whitelist + governance documented |
| S4-29 | Homogeneity gate documentation update | ✅ Done | REFERENCE & IMPLEMENTATION updated with final namespace rules |
| S4-30 | Performance Log classifier legend | ✅ Done | Added thresholds & aggregation logic to PERFORMANCE_LOG.md |
| S4-31 | CI workflow upgrade (multi-metric integration) | ✅ Done | Consolidated legacy perf job; classifier now authoritative (observe → enforce gating) |
| S4-18 | Telemetry opt-in flag stub (`ZSH_FEATURE_TELEMETRY=1`) | ✅ Done | Controlled activation switch integrated in redesigned config tree |
| S4-19 | Catalog status refresh pass | ✅ Done | Documentation updated with completed S4-18, S4-27, S4-29, S4-30 |
| S4-32 | README segment sync script (`tools/sync-readme-segments.zsh`) | ✅ Done | Automates mirroring of REFERENCE §5.3 into README (managed markers) |
| S4-33 | Classifier enforce-mode activation (3× OK streak) | ⏳ Pending | Await 3 consecutive OK performance classifier runs; then add PERFORMANCE_LOG governance row & mark enforce mode active |

Sprint 2 Exit Criteria (includes Privacy Appendix publication & reference):
- Accurate SEGMENT lines (no placeholders)
- Homogeneity test passes; wrappers removed; no `ZF_LOG_LEGACY_USED`
- Structured telemetry stubs gated & zero overhead when off
- Regression harness operational; baseline within ≤10% delta
- Dependency export (JSON + DOT) validated by test
- Privacy appendix published (privacy/PRIVACY_APPENDIX.md) & referenced in REFERENCE.md / IMPLEMENTATION.md
- Privacy appendix published & referenced

### 🚀 Stage 4 Sprint 1 (Feature Layer Scaffolding) (Archived)

| Task | Description | Status | Notes |
|------|-------------|--------|-------|
| S4-01 | Stage 4 Kickoff document (`stage4/STAGE4_KICKOFF.md`) | ✅ Done | Scope, principles, guardrails defined |
| S4-02 | Feature registry scaffold (`feature/registry/feature-registry.zsh`) | ✅ Done | Add/list/resolve with cycle detection |
| S4-03 | Feature module template (`_TEMPLATE_FEATURE_MODULE.zsh`) | ✅ Done | Contract + policy header |
| S4-04 | Self-check / status command (`feature/feature-status.zsh`) | ✅ Done | Table/raw/JSON output, summary + self-check |
| S4-05 | Noop exemplar feature (`feature/noop.zsh`) | ✅ Done | Metadata, enable logic, init/teardown, tests |
| S4-06 | Enable/disable semantics tests (noop) | ✅ Done | Precedence verified (global/all, overrides, lists) |
| S4-07 | Failure containment test (noop) | ✅ Done | Boundary simulation & recovery validated |
| S4-08 | Feature Catalog (`feature/CATALOG.md`) | ✅ Done | Inventory + phases + dependency mapping |
| S4-09 | Developer Guide (`feature/DEVELOPER_GUIDE.md`) | ✅ Done | Authoritative authoring standards |
| S4-10 | Performance Log scaffold (`tracking/PERFORMANCE_LOG.md`) | ✅ Done | Baseline + delta schema |
| S4-11 | Integrate Feature Layer section into IMPLEMENTATION.md | ✅ Done | Architecture anchored |
| S4-12 | Add remaining registry invocation wrapper (timing + containment) | ✅ Done | Invocation wrapper implemented (phase dispatch, containment, init-phase telemetry hook) |
| S4-13 | Per-feature timing integration + perf delta test harness | ✅ Done | Timing extraction tool + gating test added (perf-extract-feature-sync.zsh, test-feature-sync-timings.zsh) |
| S4-14 | Deferred / postprompt hook wiring + test skeleton | ⏳ Pending | After invocation wrapper |
| S4-15 | Add enable/disable + dependency edge-case tests (global suite) | ⏳ Pending | Broader coverage beyond noop |
| S4-16 | Update TASK_TRACKER & NEXT_STEPS with Sprint 2 plan | ⏳ Pending | After S4-12/S4-13 landed |
| S4-17 | Introduce perf gating integration (warn only) | ⏳ Pending | Requires initial timing data |
| S4-18 | Telemetry opt-in flag plumbing (no output by default) | ⏳ Pending | After timing arrays stable |
| S4-19 | Documentation refresh (catalog statuses, guide amendments) | ⏳ Pending | Rolling as tasks complete |

Sprint 1 Exit Criteria:
- Invocation wrapper with timing + error containment implemented (S4-12)
- Per-feature timing captured for noop (baseline <1ms)
- Perf delta harness enforces no regression vs Stage 3 baseline (+15% ceiling)
- Deferred hook framework scaffolded (even if no deferred features yet)
- Catalog & Tracker synchronized; NEXT_STEPS updated

### 🔄 Stage 4 Preparation (0% → 100%)

#### 1. Run Comprehensive Test Suite with New Runner
**Priority:** HIGH  
**Status:** Ready to Execute  
**Dependencies:** Migration and manifest test fixes (✅ complete)  
**Actions:**
- [ ] Run full test suite with redesign enabled (`run-all-tests-v2.zsh`)
- [ ] Document any remaining test failures
- [ ] Create fix tickets for non-critical failures
- [ ] Verify all critical tests pass

#### 2. 7-Day CI Ledger Stability
**Priority:** HIGH  
**Status:** In Progress (Day 3/7)  
**Dependencies:** Nightly CI workflow operational  

### New Tasks (GOAL System Integration)

| ID | Task | Description | Status | Notes |
|----|------|-------------|--------|-------|
| S4-34 | Document GOAL paradigm | Add matrices + privacy + references + ADR | ✅ Done | README, IMPLEMENTATION, REFERENCE, PRIVACY, ADR-0007 |
| S4-35 | Classifier scaffold | Implement `apply_goal_profile` + `--goal` parsing (no behavior change yet) | Pending | Emit `goal` only in status JSON |
| S4-36 | Status JSON goal field | Add `goal` unconditionally to status JSON | Pending | Backward compat: absence ⇒ streak (legacy) |
| S4-37 | Synthetic gating | Enforce per-profile synthetic policy (governance/ci fail) | Pending | Adds `synthetic_used` flag when true |
| S4-38 | Missing metric handling | Implement partial vs hard-fail logic (`partial` flag) | Pending | Governance/ci hard fail; streak/explore tolerate |
| S4-39 | Profile test matrix | Add T-GOAL-01..06 tests | Pending | Explore ephemeral, streak partial, governance synthetic fail |
| S4-40 | CI integration | Update workflows to set `GOAL=ci` | Pending | Deterministic gating; disallow explore in CI |
| S4-41 | Governance precondition A8 | Require 3 clean governance runs (no partial/synthetic) | Pending | Gate enforce-mode activation |
| S4-42 | Goal-state badge (optional) | Generate `goal-state.json` summarizing profile/readiness | Planned | Post initial rollout |
| S4-43 | Explore diagnostic verbosity | Add enhanced diagnostics (only in Explore) | Planned | Guarded behind profile |
| S4-44 | Strictness layering verification | Measure phased vs hard strict overhead (<2ms) | Planned | Add micro timing note |
| S4-45 | Synthetic fallback deprecation plan | Draft removal path once stable | Planned | New ADR if removal approved |

Test IDs (planned):
- T-GOAL-01: Explore → `ephemeral=true`, exit 0 with missing metric
- T-GOAL-02: Streak → missing tolerated, `partial=true`
- T-GOAL-03: Governance → synthetic usage causes non-zero exit
- T-GOAL-04: CI → mirrors governance strictness
- T-GOAL-05: Unset GOAL ⇒ streak semantics
- T-GOAL-06: Flags absent when conditions not met

Governance Precondition (A8):
- 3 consecutive `GOAL=Governance` runs, no `synthetic_used`, no `partial`.
**Actions:**
- [ ] Monitor CI ledger for 7-day stability window
- [ ] Document any drift or badge issues

#### 3. Documentation & Onboarding Finalization
**Priority:** MEDIUM  
**Status:** In Progress  
**Actions:**
- [ ] Finalize documentation and onboarding guides
- [ ] Ensure compliance headers and orchestration policy references are present

#### 4. Stage 4: Feature Layer Implementation
**Priority:** NEXT  
**Status:** Pending  
**Actions:**
- [ ] Begin feature layer implementation after test suite and CI ledger stability confirmed

- [ ] Monitor daily ledger captures
- [ ] Check for performance regressions
- [ ] Verify badge auto-updates
- [ ] Document any anomalies

#### 3. Test Improvement Plan Week 1-2
**Priority:** MEDIUM  
**Status:** Planning Phase  
**Dependencies:** TEST_IMPROVEMENT_PLAN.md created  
**Actions:**
- [ ] Implement test discovery improvements
- [ ] Add parallel test execution support
- [ ] Create test categorization system
- [ ] Enhance error reporting

## Upcoming Tasks (Next Sprint)

#### Follow-ups (08.19.10)
- Add CI assertion to fail when summary-goal badge resolves to red (indicates failing governance/drift/structure).
- Add tests validating summary-goal suffix composition (drift:<message>, struct:<message>) and severity blending.
- Extend documentation: badge legend + suffix mapping details (how governance/ci/streak/explore, drift, and structure affect color/message).
- Monitor first gh-pages publish to confirm endpoint availability; ensure README auto-update commit occurred.
- Optional: refine governance state mapping for “BASELINE_CREATED” → informational (distinct from clean).

### 🔜 Stage 4: Feature Layer Implementation (0% → 100%)

#### 1. Module Structure Setup
**Estimated:** 2 days  
**Dependencies:** Stage 3 complete  
**Tasks:**
- [ ] Create feature module templates
- [ ] Define feature loading order
- [ ] Implement feature sentinel guards
- [ ] Add feature-specific tests

#### 2. Lazy Loading Framework
**Estimated:** 3 days  
**Dependencies:** Module structure  
**Tasks:**
- [ ] Implement lazy function definitions
- [ ] Create deferred loading triggers
- [ ] Add performance measurements
- [ ] Test memory impact

#### 3. Feature Migration
**Estimated:** 5 days  
**Dependencies:** Lazy loading framework  
**Tasks:**
- [ ] Migrate git features
- [ ] Migrate docker integration
- [ ] Migrate development tools
- [ ] Migrate custom aliases

### 🔜 Stage 5: UI & Completion (0% → 100%)

#### 1. Prompt System Redesign
**Estimated:** 3 days  
**Dependencies:** Stage 4 complete  
**Tasks:**
- [ ] Implement async prompt framework
- [ ] Create prompt segments
- [ ] Add git status integration
- [ ] Test with various terminals

#### 2. Completion System
**Estimated:** 2 days  
**Dependencies:** Prompt system  
**Tasks:**
- [ ] Optimize compinit loading
- [ ] Implement smart caching
- [ ] Add custom completions
- [ ] Test completion performance

## Discovered Issues & Technical Debt

### 🐛 Known Issues

1. **Design Tests Stage 4 Variables**
   - **Impact:** Low (expected until Stage 4)
   - **Description:** Missing sentinel variables for Stage 4 modules
   - **Resolution:** Will be fixed during Stage 4 implementation

2. **POSTPLUGIN Directory Inconsistency**
   - **Impact:** Medium
   - **Description:** Some tests reference `.zshrc.d.REDESIGN/POSTPLUGIN/` path
   - **Resolution:** Standardize on `.zshrc.d.REDESIGN/` path

3. **Test Runner Output Verbosity**
   - **Impact:** Low
   - **Description:** Direct test runner doesn't show individual test results
   - **Resolution:** Add verbose mode option to runner

### 📝 Technical Debt

1. **Test Pattern Consistency**
   - Standardize `functions[(I)pattern]` vs `functions:#pattern` usage
   - Document zsh pattern matching best practices
   - Update all tests to use consistent patterns

2. **Associative Array Documentation**
   - Document quirks with special characters in keys
   - Create helper functions for safe key handling
   - Add examples to developer guide

3. **CI Workflow Consolidation**
   - Further consolidate badge generation workflows
   - Reduce workflow duplication
   - Optimize CI execution time

## Success Metrics

### Stage 3 Completion Criteria
- [x] Variance guard active (3/3 streak) ✅
- [x] Performance < 350ms startup ✅ (334ms)
- [x] All core tests pass ✅
- [ ] 7-day CI stability window complete (3/7)
- [ ] Migration tools tested end-to-end
- [ ] Documentation fully updated

### Stage 4 Entry Criteria
- [ ] Stage 3 100% complete
- [ ] Performance baseline locked
- [ ] Test infrastructure stable
- [ ] Migration rollback tested
- [ ] Team alignment on feature priorities

## Risk Register

### 🔴 High Risk
- **None currently identified**

### 🟡 Medium Risk
1. **7-Day Stability Window**
   - Risk: CI failures could reset counter
   - Mitigation: Manual override option available
   - Status: Monitoring daily

2. **Migration Tool Compatibility**
   - Risk: Edge cases in user configurations
   - Mitigation: Extensive testing with various setups
   - Status: Test coverage expanding

### 🟢 Low Risk
1. **Test Flakiness**
   - Risk: Intermittent failures in performance tests
   - Mitigation: Increased sample sizes (N=5)
   - Status: Stable with current configuration

## Quick Links

### Documentation
- [Implementation Guide](../IMPLEMENTATION.md)
- [Migration Plan](../migration/PLAN_AND_CHECKLIST.md)
- [Architecture](../ARCHITECTURE.md)
- [Reference](../REFERENCE.md)

### Tools & Scripts
- Manifest Test: `tests/unit/core/test-core-functions-manifest.zsh`
- Migration Tool: `tools/migrate-to-redesign.sh`
- Performance Capture: `tools/perf-capture-multi.zsh`
- Badge Update: `tools/update-variance-and-badges.zsh`

### CI Workflows
- Nightly Variance: `.github/workflows/ci-variance-nightly.yml`
- Async Guards: `.github/workflows/ci-async-guards.yml`
- Badge Generation: `.github/workflows/ci-badge-generation.yml`

## Notes & Observations

### Performance Insights
- Shell startup consistently ~334ms (excellent)
- Variance < 2% indicates stable performance
- Micro-benchmarks show 37-44µs for core operations
- No memory leaks detected in extended sessions

### Test Infrastructure Learnings
- `zsh -f` testing crucial for CI compatibility
- Associative arrays require careful key handling
- Self-contained tests improve maintainability
- Direct test runner significantly faster than full shell

### Migration Readiness
- Tools verified working with `/bin/bash`
- Shim audit shows clean environment
- Rollback procedures tested successfully
- Documentation comprehensive and current

---

**Next Review:** 2025-09-11  
**Sprint Planning:** Every Monday  
**Stage 4 Target:** 2025-10-01