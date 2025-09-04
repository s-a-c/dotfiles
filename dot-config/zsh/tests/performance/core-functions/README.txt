# Core Functions Micro-Benchmark Harness (Stage 3 Placeholder)

Status: Draft (Scaffolding Only)
Scope: Benchmarks extremely small `zf::*` helper functions defined in `10-core-functions.zsh` to ensure added logic remains sub‑millisecond and does not accumulate hidden latency across frequent call sites.

This directory exists now so that:
1. A harness script can be added without restructuring tests again.
2. Performance governance (perf ledger, variance gating) can later ingest micro timings for correlation.
3. Documentation & TDD intent are explicit before implementation (avoids “stealth” perf code).

---

## 1. Goals (Immediate Phase)

The initial harness (planned filename: `bench-core-functions.zsh`) will:
- Time a fixed iteration loop (e.g. 5K–50K calls) for each selected `zf::` function.
- Report per-call mean (µs) and aggregate totals.
- Emit a MACHINE + HUMAN section:
  - MACHINE: stable, parseable lines (prefix `BENCH:`) for future JSON conversion.
  - HUMAN: pretty table for local inspection.
- Produce optional Shields-compatible badge JSON (future) once stable thresholds established.

Functions initially in scope:
- `zf::log` (stderr lightweight logging)
- `zf::warn`
- `zf::ensure_cmd` (with both all-present and one-missing cases)
- `zf::require` (success + failure paths)
- `zf::with_timing` (overhead baseline using a no-op command)
- `zf::timed` (wrapper path)
- `zf::list_functions` (enumeration baseline)

(Any newly added Stage 3 `zf::*` helper must be consciously added or explicitly excluded with rationale.)

---

## 2. Non-Goals (Now)

- No statistical dispersion (stdev / percentiles) in first iteration (coarse mean only).
- No automatic gating or CI fail on slow micro results (observe mode only).
- No external dependency (jq, python). Pure zsh + core utilities (awk, date).
- No cross-shell comparison (zsh only).

Enhancements deferred until post Stage 3 hardening.

---

## 3. Accuracy & Methodology

Planned timing source precedence:
1. `EPOCHREALTIME` (native high‑resolution) if available.
2. Fallback: `date +%s%N` (Linux) or `perl` shim / `date +%s` (reduced resolution) on macOS if nanoseconds unavailable.

Each function benchmark:
1. Warm-up phase (e.g. 200 calls discarded).
2. Timed phase (N iterations).
3. Elapsed_ms captured; per-call µs = (elapsed_ms * 1000) / N.

Mitigations for noise:
- Encourage `BENCH_ITER=<N>` override (default ~5000).
- Allow `BENCH_REPEAT=<R>` to repeat timed block and take median (future).
- Runs should occur on otherwise idle system to minimize scheduler artifacts.

---

## 4. Output (Planned Example)

MACHINE (parseable):

```
BENCH name=zf::log iterations=5000 total_ms=22 per_call_us=4.4 rc=0
BENCH name=zf::ensure_cmd(all_present) iterations=5000 total_ms=31 per_call_us=6.2 rc=0
BENCH name=zf::ensure_cmd(one_missing) iterations=5000 total_ms=47 per_call_us=9.4 rc=0
BENCH name=zf::with_timing(noop) iterations=2000 total_ms=19 per_call_us=9.5 rc=0
```

HUMAN (illustrative):

| Function                         | Iter | Total ms | µs/call | Notes                |
|----------------------------------|------|----------|--------:|----------------------|
| zf::log                          | 5K   | 22       |   4.4   | stderr lightweight   |
| zf::warn                         | 5K   | 23       |   4.6   | similar path         |
| zf::ensure_cmd (present)         | 5K   | 31       |   6.2   | loop + command -v    |
| zf::ensure_cmd (1 missing)       | 5K   | 47       |   9.4   | includes warn branch |
| zf::with_timing (noop payload)   | 2K   | 19       |   9.5   | timing wrapper cost  |

(Values are illustrative placeholders, not measured baselines.)

---

## 5. Threshold Philosophy (Future)

We do NOT gate on absolute µs yet. Later phases may introduce soft alerts when:
- Any per-call µs > 50 (arbitrary early heuristic) for lightweight helpers.
- Regression vs previous ledger sample > +100% for same helper.

Mapping to ledger:
- Micro results can be aggregated into an optional `micro_core_helpers_total_ms` pseudo segment for drift watching (not currently produced by `perf-module-ledger.zsh`).

---

## 6. Integration Points

Planned script `bench-core-functions.zsh` will support:
- `--iterations N` / `BENCH_ITER=N`
- `--list` (show target functions)
- `--filter <glob/regex>`
- `--machine` (suppress HUMAN)
- `--fail-on >limit_us` (optional future CI early guard)
- `--json` (future: emit stable JSON schema `bench-core.v1`)

Potential JSON schema outline (future):
```
{
  "schema": "bench-core.v1",
  "generated_at": "2025-09-04T00:00:00Z",
  "iterations_default": 5000,
  "functions": [
    {"name":"zf::log","iterations":5000,"total_ms":22,"per_call_us":4.4},
    ...
  ]
}
```

---

## 7. Test Strategy (Planned)

A lightweight test (`test-core-micro-bench-smoke.zsh`) will:
1. Invoke harness with drastically reduced iterations (e.g. 50).
2. Assert:
   - Expected BENCH lines count ≥ subset of functions.
   - Each per_call_us numeric & non-negative.
   - No BENCH line reports rc != 0.
3. Skip gracefully if harness script absent (early placeholder phase).

Performance regression detection for micro helpers will *not* fail CI until after at least one stable baseline artifact is committed (tracked in `artifacts/metrics/` as `bench-core-baseline.json` or similar).

---

## 8. Risks & Considerations

| Risk | Mitigation |
|------|------------|
| IO noise (stderr logging) inflates numbers | Option to redirect to /dev/null in benchmark path |
| Low iteration counts distort timing | Enforce minimum or warn when N < 500 |
| EPOCHREALTIME unavailable | Fallback path + warn banner |
| Shell GC / allocator jitter | Repeat loop & median (future) |

---

## 9. Roadmap

Phase A (this placeholder)
- Directory + README + consensus on scope.

Phase B
- Implement `bench-core-functions.zsh` (observe mode).
- Add smoke test (non-fatal if missing).

Phase C
- Add JSON emission + baseline capture script.
- Integrate micro baseline diff (warn-only).

Phase D
- Correlate micro drift with perf ledger & surface combined badge.

Phase E (optional)
- Adaptive auto-threshold (median-of-last-N baselines).

---

## 10. Implementation Checklist (To Add Harness)

[ ] Create `bench-core-functions.zsh` with iteration loop & BENCH lines
[ ] Add smoke test (performance category) with reduced iterations
[ ] Commit initial human + machine sample (optional baseline JSON)
[ ] Update IMPLEMENTATION.md Section 1.2 (mark micro-benchmark harness landed)
[ ] Integrate optional invocation into perf workflows (non-blocking step)
[ ] Plan baseline drift logic (warn mode)

---

## 11. Contributing Notes

- Adding a new `zf::` function? Decide if it needs micro-bench coverage.
- Keep harness self-contained (no sourcing of heavy modules).
- Avoid adding external dependencies (jq, perl) solely for the harness.

---

## 12. Exit Criteria for “Harness Ready” (Stage 3 Adjacent)

All must be true:
- Script present + executable.
- Smoke test passes deterministically (≤2s runtime).
- BENCH lines for at least 80% of targeted core helpers.
- Documented mean/µs values recorded at least once (commit message referencing capture).
- No CI gating enabled yet (observe only).

---

Questions / modifications welcome—update this file in the same PR as the harness script to keep intent aligned.

# End of README
