# ZSH Configuration Redesign Documentation
**Version 2.4** – Core Hardening, Perf/Bench & Governance Badge Integration Updates  
**Status**: Stage 2 Complete (baseline & tag created) – Stage 3 (Core Modules) In Progress  
**Last Updated**: 2025-09-04

## 🔜 Recommended Next Steps (Updated Summary)

Focused execution priorities for the remainder of Stage 3 (after recent additions: trust anchor read APIs, micro-benchmark harness with shim fallback, variance stability log, perf drift badge script, multi-sample fingerprint caching):

1. Multi-Sample Segment Refresh & Monotonic Validation  
   - Force a fresh multi-sample run: `PERF_CAPTURE_FORCE=1 tools/perf-capture-multi.zsh` to obtain non‑zero `post_plugin_total` & `prompt_ready_ms`.  
   - Confirm monotonic lifecycle (`pre ≤ post ≤ prompt`) shows `monotonic=ok` (promotion-guard note).  
   - Append new Variance Stability Log row (IMPLEMENTATION.md §1.3) with refreshed metrics.

2. Governance & Drift Integration (Governance badge now active)  
   - Governance badge generation integrated in perf + nightly workflows (extended artifact + simple shield). Monitor first artifact; once stable, reference it via Pages endpoint.  
   - Continue stabilizing perf drift badge; after two consecutive low-RSD (<5%) runs with non‑zero trio, prepare enabling `PERF_DIFF_FAIL_ON_REGRESSION=1` (warn→gate).

3. Micro-Benchmark Baseline & Shim Removal Plan  
   - If not yet committed: `bench-core-functions.zsh --json --iterations 5000 --repeat 3 > docs/redesignv2/artifacts/metrics/bench-core-baseline.json`.  
   - Draft F16 shim removal plan (enumerate currently shimmed helpers) to unlock micro bench gating path (F22/F26).  
   - Track `shimmed_count` reduction in future governance badge stats.

4. Test / Enforcement Enhancements  
   - Promote monotonic lifecycle test to strict after two passes with non‑zero trio + monotonic=ok.  
   - Define micro bench thresholds (warn ≥2x, fail ≥3x median) aligned with governance script factors.  
   - Elevate drift badge presence test from warn to enforce after first stable governance cycle.

5. Documentation & Badges  
   - Governance badge row scaffold present; remove "(pending)" tag once first published artifact verified.  
   - Update Stage 3 readiness checklist when governance badge appears green (no FAIL conditions).  
   - Add variance decision badge once variance-state artifact implemented.

6. Stage 3 Exit Preparation  
   - Collect evidence set: PATH invariant, security skeleton idempotency, option snapshot, core namespace stability, single scheduler registration, provisional perf budget adherence, micro baseline + governance badge green.  
   - Run `stage3-exit-report.sh` after governance + drift + non‑zero segment validation.

7. Future Promotion Hooks (Logged)  
   - Execute F16 (remove shims) → enables F17 (shim guard) & micro gating (F22/F26).  
   - Integrate ledger max regression embedding (F2) & future variance-state source into governance badge.  
   - Prepare combined infra-health weighting once governance badge stable across ≥3 nightly runs.

---

### Stage 3 Exit Criteria Progress (Updated)

| Criterion | Status | Notes |
|-----------|--------|-------|
| PATH append invariant | [x] | Test present & passing |
| Security skeleton idempotent | [x] | Sentinel + deferred integrity scheduler |
| Option snapshot stability | [x] | Golden snapshot path & diff test green |
| Core functions namespace stable | [x] | Manifest & namespace tests green |
| Integrity scheduler single registration | [x] | No duplicate key on re-source |
| Perf provisional budget (pre-plugin) | [~] | Pre stable; post/prompt metrics pending non-zero |
| Perf regression gating (observe→gate) | [ ] | Await stable multi-sample + drift readiness |
| Drift badge integration | [~] | Script ready; CI publication pending (governance badge generation now wired into perf & nightly workflows; waiting on stable non-zero post/prompt segments for full activation) |
| Micro benchmark baseline captured | [ ] | Harness stabilized; baseline not yet committed |
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
- `artifacts/checksums/` – Integrity baselines

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