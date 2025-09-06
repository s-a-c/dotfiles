# ZSH Redesign Reference Guide
Version: 2.0
Status: Living Operational Reference (authoritative for day‑to‑day use)
Last Updated: 2025-01-03

This document is the quick‑use companion to:
- IMPLEMENTATION.md – Stage plan, execution gates, promotion criteria
- ARCHITECTURE.md – Design principles, layering model, deferred execution strategy

If a conflict exists:
1. Architecture intent → ARCHITECTURE.md
2. Execution status & gates → IMPLEMENTATION.md
3. Operational detail & usage → THIS FILE

---

## 1. Quick Command Cheat Sheet

### 1.1 Validation & Health
| Purpose | Command |
|---------|---------|
| Full test suite | `tests/run-all-tests.zsh` |
| Design / structure only | `tests/run-all-tests.zsh --design-only` |
| Performance only | `tests/run-all-tests.zsh --performance-only` |
| Security / async only | `tests/run-all-tests.zsh --security-only` |
| Unit tests only | `tests/run-all-tests.zsh --unit-only` |
| Implementation snapshot | `./verify-implementation.zsh` |
| Promotion readiness gate | `tools/promotion-guard.zsh` |
| Perf capture (2 runs + segments) | `tools/perf-capture.zsh` |
| Legacy checksum verification | `tools/verify-legacy-checksums.zsh` |

### 1.2 Development Cycle (Per Stage)
```bash
# Branch & implement
git checkout -b stage-2-preplugin
# Edit modules...
tests/run-all-tests.zsh --design-only
tests/run-all-tests.zsh --unit-only

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
tests/run-all-tests.zsh --security-only

# Manually inspect logs
grep ASYNC_STATE logs/async-state.log
grep PERF_PROMPT logs/perf-current.log
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
2. If regression: run `tests/run-all-tests.zsh --performance-only`.
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

---

## 15. Navigation
[Implementation](IMPLEMENTATION.md) | [Architecture](ARCHITECTURE.md) | [Stages](stages/) | [Artifacts](artifacts/)

*End of Reference Guide*
