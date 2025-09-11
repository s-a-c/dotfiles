# Performance Log (Stage 4 Scaffold)
Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

This ledger captures discrete, reproducible performance observations for the ZSH configuration redesign.  
It is intentionally lightweight, append‑only, and human diff friendly.

---

## Conventions

| Column          | Meaning |
|-----------------|---------|
| Date            | YYYY‑MM‑DD (UTC preferred) |
| Feature         | Logical component or probe owner |
| Scenario        | Short descriptor of the measurement context |
| Cold_ms         | Mean cold start (first shell after environment reset) |
| Warm_ms         | Mean warm start (subsequent shells; caches primed) |
| Samples         | `Nc/Wm` → N cold measurements / W warm measurements |
| Variance_pct    | Relative Standard Deviation (%) of the dominant (warm) sample set |
| Notes           | Material qualifiers (method, anomalies, gating decisions) |
| Checksum        | Policy guidelines checksum at measurement time (integrity anchor) |

All times are wall clock milliseconds unless explicitly suffixed.

---

## Methodology (Initial Phase)

1. Cold Run Isolation  
   - New login shell or sandboxed env (PATH + compinit caches cleared if applicable).  
   - Avoid overlapping IO (e.g. Homebrew auto update, Spotlight indexing).

2. Warm Run Series  
   - Same terminal session or repeated subshell spawns (no config edits between runs).  
   - Discard first warm if it exhibits >2× median deviation (cache stabilization).

3. Capture Sources  
   - `PERF_SEGMENT_LOG` lines for structured segment deltas (SEGMENT / DEFERRED / POLICY).  
   - External timing harness (planned) will later cross‑validate.

4. Statistical Treatment (v1)  
   - Mean + RSD (Relative Standard Deviation) for warm.  
   - Flag if RSD >5% (investigate) or >10% (block promotion unless justified).

5. Integrity  
   - Always record the active `GUIDELINES_CHECKSUM`.  
   - If checksum drift occurs between cold and warm series, discard and repeat (environment instability).

---

## Threshold Guidance (Stage 4 – Draft)

| Metric               | Advisory | Soft Alert | Hard Alert |
|----------------------|----------|------------|------------|
| Startup (aggregate)  | ≤340 ms  | >340 ms    | >380 ms    |
| Warm RSD             | ≤5%      | >5%        | >10%       |
| Added Feature Delta* | ≤10 ms   | >10 ms     | >25 ms     |

\* Added Feature Delta = (New post‑plugin total − Baseline post‑plugin total) adjusting for variance envelope.

---

## Change Control

- DO NOT rewrite historical rows (append corrections as a new row with same date + `corr:` in Notes).
- If methodology changes (e.g. switch to trimmed mean), insert a separator header with rationale.
- Any automated tooling that updates this file must:
  1. Recompute current `GUIDELINES_CHECKSUM`
  2. Preserve row ordering (chronological)
  3. Avoid column reflow (fixed header spacing)

---

## Log

| Date       | Feature            | Scenario                         | Cold_ms | Warm_ms | Samples | Variance_pct | Notes                                                                 | Checksum |
|------------|--------------------|----------------------------------|---------|---------|---------|--------------|-----------------------------------------------------------------------|----------|
| 2025-09-10 | deferred-dispatch  | Skeleton (dummy job, no payload) |   TBD    |   TBD    | 3c/10w  |     TBD      | Initial scaffold; verifies zero pre-prompt inflation & one-shot run. | 50b6b88e |
|            |                    |                                  |         |         |         |              |                                                                       |          |

---

### Pending Backfill

The following historical milestones will be backfilled once baselining harness is integrated:

- Stage 3 final stabilization (334 ms / 1.9% RSD reference)
- Pre vs post placeholder segment attribution
- First real prompt-core segmentation (planned)
- Deferred job accumulation once multiple postprompt tasks exist

---

## Future Enhancements (Planned)

- JSON sidecar (`LOG.jsonl`) for machine parsing
- Automated delta classification (regression / noise / improvement)
- Promotion gate hook (fail CI on hard alert classification)
- Optional `git note` embedding for provenance
- Segment budget ledger (per logical label vs committed envelope)

---

## Update Procedure (Manual v1)

1. Export current checksum:
   `echo "$GUIDELINES_CHECKSUM"`
2. Collect cold series (N≥3) after environment cache purge.
3. Collect warm series (W≥10).
4. Compute mean & RSD (awk or lightweight script).
5. Append new row; commit with message:
   `perf: log <feature> <short scenario> (checksum <shortsha>)`
6. If anomalous spike:
   - Re-run series
   - Note reproduction attempt
   - File issue if persistent

---

End of file.