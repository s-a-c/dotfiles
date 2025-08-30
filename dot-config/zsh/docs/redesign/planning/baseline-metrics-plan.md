# Baseline Metrics Capture Plan
Date: 2025-08-30
Status: Planning (Pre-Execution)

## 1. Purpose
Establish statistically defensible baseline performance & structural metrics BEFORE any migration/renames for both pre-plugin and post-plugin redesign phases. Time To First Prompt (TTFP) improvements will be inferred from overall startup mean reductions.

## 2. Metrics Set
| Metric | Description | Artifact | Threshold / Target Use |
|--------|-------------|----------|------------------------|
| startup_mean_ms | Mean of interactive startup (cold-ish) | perf-baseline.json | Redesign must achieve ≥20% reduction |
| startup_stddev_ms | Variability indicator | perf-baseline.json | If >12% of mean → recollect |
| pre_plugin_time_ms | Time to complete pre-plugin phase only | preplugin-baseline.json | Inform consolidation benefit |
| module_count_active | Count of active post-plugin modules | structure-audit.json | Expect reduction to 11 (target) after redesign |
| preplugin_file_count | Count pre-plugin fragments | preplugin-structure-baseline.json | Reduction 12 → 8 |
| compinit_invocations | Should be 0 baseline (guard not yet added) | baseline-compinit.log | Ensure no hidden early compinit |
| memory_rss_kb | RSS after first prompt (optional) | perf-baseline.json (future) | Track drift only |

## 3. Run Protocol
1. Close all noisy background tasks if possible.
2. Clear OS file cache (optional; macOS limited) – rely on multiple runs instead.
3. Warm-up run (discard first measurement).
4. Collect 11 runs, discard run #1, use remaining 10 for mean/stddev.
5. If stddev > 12% of mean → repeat set once; choose lower-variance set.

## 4. Command Set
```bash
# Full interactive timing set
for i in {1..11}; do /usr/bin/time -p zsh -i -c exit 2>> docs/redesign/planning/startup-times-raw.txt; done

# Extract real seconds -> ms JSON
awk '/^real/ {print $2}' docs/redesign/planning/startup-times-raw.txt | \
  awk 'NR>1 {sum+=$1; a[NR]=$1} END{n=NR-1; for(i=2;i<=NR;i++){vals=vals (vals?",":"") int(a[i]*1000)}; mean=sum/n*1000; \
       # stddev
       for(i=2;i<=NR;i++){d=(a[i]*1000-mean); ss+=d*d} sd=sqrt(ss/n); \
       printf "{\n  \"timestamp\": \"%s\",\n  \"runs\": [%s],\n  \"mean_ms\": %d,\n  \"stddev_ms\": %d\n}\n", strftime("%Y-%m-%dT%H:%M:%S%z"), vals, mean, sd; }' > docs/redesign/metrics/perf-baseline.json

# Capture pre-plugin phase (instrument .zshrc temporarily or use wrapper script) – documented, not yet implemented.
```

## 5. Pre-Plugin Timing (Planned Instrumentation)
Temporary patch (not committed) in `.zshrc` to export timestamps:
```zsh
_ZSH_START_EPOCH=${EPOCHREALTIME}
# after pre-plugin loader finishes
_ZSH_PREPLUGIN_DONE=${EPOCHREALTIME}
print -r -- "PREPLUGIN_MS=$(( (${_ZSH_PREPLUGIN_DONE%.*}.${_ZSH_PREPLUGIN_DONE#*.} - ${_ZSH_START_EPOCH%.*}.${_ZSH_START_EPOCH#*.}) * 1000 ))" >> docs/redesign/planning/preplugin-times.txt
```
Convert aggregated lines to JSON `preplugin-baseline.json` similarly.

## 6. Structural Baseline
Run existing structure audit tool (post-plugin) and planned pre-plugin variant (future extension) to record counts without enforcing new naming yet.

## 7. Validation Criteria
| Check | Pass Condition |
|-------|----------------|
| Baseline JSON present | `perf-baseline.json` exists & has ≥10 runs |
| Stddev bound | `stddev_ms <= mean_ms * 0.12` |
| Pre-plugin count recorded | preplugin file count logged |
| Compinit baseline | Zero occurrences of `compinit` in pre-plugin trace |

## 8. Freezing Baseline
Baseline is FROZEN once: `perf-baseline.json` committed, implementation-entry-criteria checklist marks capture complete, and a tag `refactor-baseline` is created.

## 9. Risks
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Environmental variance | Skews mean | Extra runs & variance check |
| Accidental redesign code applied before capture | Invalid baseline | Perform capture on dedicated baseline branch before any skeleton merges |

## 10. Next Steps
- Implement minimal pre-plugin timestamp instrumentation wrapper (planning only – not yet committed).
- Execute capture procedure & commit artifacts.

---
**Navigation:** [← Previous: Plugin Loading Optimization](plugin-loading-optimization.md) | [Next: Compinit Audit Plan →](compinit-audit-plan.md) | [Top](#) | [Back to Index](../README.md)
