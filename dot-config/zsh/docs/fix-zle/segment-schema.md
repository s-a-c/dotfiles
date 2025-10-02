# Segment Instrumentation Schema Specification
File: segment-schema.md  
Status: Draft (Initial Publication)  
Schema Version Lineage: 1.0.0-segment-draft → 1.0.0 (on acceptance)  

---

## 1. Purpose

This document defines a structured, versioned schema for capturing *startup / initialization segment instrumentation* during the `fix-zle` ZSH redesign phases. It enables:

- Auditable performance snapshots
- Consistent comparison across commits / branches
- Embedding summarized instrumentation in existing CI aggregator output
- Future expansion to fine‑grained “span” or “event” level profiling once Decision D14 (Segment Instrumentation) is formally implemented

The schema balances rigor (stable keys, validation rules) with **extensibility** (open metrics namespace) to avoid premature constraint.

---

## 2. Design Principles

| Principle | Rationale |
|-----------|-----------|
| Deterministic ordering | Enables reproducible checksum signing |
| Minimal mandatory core | Allows incremental adoption; partial instrumentation still valid |
| Namespaced free-form metrics | Encourages domain evolution without schema churn |
| Defensive evolution | Forward compatibility via `schema_version` + extension fields |
| Human-readability first | JSON chosen for ease of inspection and ingestion |

---

## 3. Top-Level Object

```jsonc
{
  "schema_version": "1.0.0",
  "generated_at_utc": "2025-10-01T12:34:56Z",
  "host_context": { ... },
  "capture_parameters": { ... },
  "segments": [ ... ],
  "aggregate": { ... },
  "integrity": { ... },
  "guidance": { ... }
}
```

### 3.1 Required Top-Level Keys

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `schema_version` | string (semver) | ✅ | Semver of this schema (e.g. `1.0.0`). Suffixes like `-segment-draft` allowed pre-stabilization. |
| `generated_at_utc` | string (RFC 3339 UTC) | ✅ | Timestamp of capture. |
| `host_context` | object | ✅ | Host + environment baseline metadata. |
| `capture_parameters` | object | ✅ | Describes instrumentation method + fidelity. |
| `segments` | array<object> | ✅ | Ordered list of captured segments. Must be monotonic by `order`. |
| `aggregate` | object | ✅ | Derived totals / summary metrics. |
| `integrity` | object | ✅ | Optional signing / checksum details (fields may be null/placeholder until implemented). |
| `guidance` | object | ✅ (may be minimal) | Human-facing usage & evolution hints. |

---

## 4. host_context

```jsonc
"host_context": {
  "os": "macOS",
  "zsh_version": "5.9",
  "git_head": "abc1234deadbeef",
  "baseline_widget_count": 416,
  "shell_start_epoch_ms": 1696152345123,
  "hardware": {
    "arch": "arm64",
    "logical_cores": 10
  },
  "_note": "Optional keys begin with underscore."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `os` | string | ✅ | Platform family. |
| `zsh_version` | string | ✅ | Full version (e.g. `5.9`). |
| `git_head` | string | ✅ | Commit SHA (short or full). |
| `baseline_widget_count` | integer | ✅ | Widget count at capture start (pre-instrumentation mutations). |
| `shell_start_epoch_ms` | integer | ⛔ (optional) | Millisecond epoch at shell entry; enables relative mapping. |
| `hardware.arch` | string | ⛔ | `arm64`, `x86_64`, etc. |
| `hardware.logical_cores` | integer | ⛔ | Snapshot at capture time. |
| `_note` | string | ⛔ | Free narrative. All “underscore” keys are non-normative. |

---

## 5. capture_parameters

```jsonc
"capture_parameters": {
  "method": "manual_instrumentation_stub",
  "precision_class": "coarse",
  "time_source": "date +%s%3N",
  "environment": {
    "TERM": "xterm-256color",
    "COLORTERM": "truecolor"
  },
  "flags": {
    "deferred_loading": true,
    "evalcache_active": true,
    "zsh_defer_active": true
  }
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `method` | string | ✅ | E.g. `manual_instrumentation_stub`, `auto_probe_v1` |
| `precision_class` | enum | ✅ | One of: `coarse` (≥10ms granularity), `fine` (<5ms), `trace` (sub-ms / event). |
| `time_source` | string | ✅ | Command or mechanism (documentation aid). |
| `environment` | object<string,string> | ⛔ | Selected env vars captured (whitelist). |
| `flags` | object<string,bool|number|string> | ⛔ | Instrumentation-relevant toggles (deferred, caching, etc.). |

---

## 6. segments Array

Each entry captures one logically atomic *phase or sub-phase*.

### 6.1 Segment Object Structure

```jsonc
{
  "id": "seg-040-productivity-layer",
  "name": "Productivity Layer",
  "phase": "phase4",
  "order": 40,
  "status": "ok",
  "start_ms": 275,
  "end_ms": 420,
  "duration_ms": 145,
  "metrics": {
    "fzf_integrations": 3,
    "navigation_tools": 3,
    "abbr_packs": 2
  },
  "notes": "Atuin, fzf, zoxide, eza, abbreviations.",
  "warnings": [],
  "errors": []
}
```

### 6.2 Field Definitions

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `id` | string | ✅ | Pattern: `seg-<3-digit>-<kebab-slug>` (e.g. `seg-010-env-bootstrap`). |
| `name` | string | ✅ | Human-readable. |
| `phase` | string | ✅ | One of `phase1`..`phase7` or future `phaseX`. |
| `order` | integer | ✅ | Monotonic ascending (no duplicates). |
| `status` | enum | ✅ | `ok` | `partial` | `fail` | `skipped` |
| `start_ms` | integer | ✅ | Relative to earliest segment start (0 base recommended). |
| `end_ms` | integer | ✅ | Must satisfy `end_ms >= start_ms`. |
| `duration_ms` | integer | ✅ | Must equal `end_ms - start_ms`. |
| `metrics` | object | ✅ (may be empty `{}`) | Free-form flat key/value set (no nested objects except by later extension). |
| `notes` | string | ⛔ | Short description. |
| `warnings` | array<string> | ⛔ | Non-fatal anomalies. |
| `errors` | array<object> | ⛔ | Fatal/inhibiting errors (required if `status=fail`). |

#### Error Object (if present)

```jsonc
{
  "code": "E_PLUGIN_TIMEOUT",
  "message": "Deferred plugin load exceeded threshold",
  "detail": {
    "threshold_ms": 200,
    "observed_ms": 350
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | ✅ | Stable symbolic identifier. |
| `message` | string | ✅ | Human-friendly explanation. |
| `detail` | object | ⛔ | Arbitrary structured metadata. |

### 6.3 Status Semantics

| Status | Meaning | Aggregation Impact |
|--------|---------|-------------------|
| `ok` | Segment executed successfully | Counts toward `ok_segments` |
| `partial` | Segment incomplete / degraded but not fatal | Counts toward `partial_segments` |
| `fail` | Segment failure; may undermine overall integrity | Counts toward `failed_segments` |
| `skipped` | Explicitly bypassed (conditional exclusion) | Does not increment ok/partial/fail; trackable via metrics |

---

## 7. aggregate Object

```jsonc
"aggregate": {
  "total_duration_ms": 760,
  "segment_count": 7,
  "ok_segments": 6,
  "partial_segments": 1,
  "failed_segments": 0,
  "earliest_start_ms": 0,
  "latest_end_ms": 760,
  "widget_baseline": 416,
  "widget_delta": 0,
  "_interpretation": "All mandatory phases complete; optional enhancements partial."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `total_duration_ms` | integer | ✅ | MUST equal `latest_end_ms - earliest_start_ms`. |
| `segment_count` | integer | ✅ | MUST equal length of `segments` array. |
| `ok_segments` | integer | ✅ | Derived count where `status=ok`. |
| `partial_segments` | integer | ✅ | Derived count where `status=partial`. |
| `failed_segments` | integer | ✅ | Derived count where `status=fail`. |
| `earliest_start_ms` | integer | ✅ | Minimum of all `start_ms`. |
| `latest_end_ms` | integer | ✅ | Maximum of all `end_ms`. |
| `widget_baseline` | integer | ✅ | Initial widget count. |
| `widget_delta` | integer/null | ⛔ | Post-run minus baseline (null if not computed). |
| `_interpretation` | string | ⛔ | Narrative summary. |

---

## 8. integrity Object

```jsonc
"integrity": {
  "capture_method": "prototype",
  "checksum": "sha256:NOT_COMPUTED",
  "tamper_evident": false,
  "canonicalization_version": 1,
  "_note": "Checksum to be sha256 over canonical JSON (UTF‑8, sorted keys)."
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `capture_method` | string | ✅ | Method name or version (`prototype`, `instrumentor_v2`). |
| `checksum` | string | ✅ | Format: `<algo>:<hex>` (e.g. `sha256:deadbeef...`). Placeholder allowed until implemented. |
| `tamper_evident` | boolean | ✅ | True only if checksum computed post-canonicalization. |
| `canonicalization_version` | integer | ✅ | Version controlling ordering + whitespace elimination rules. |
| `_note` | string | ⛔ | Free-form explanation. |

Canonicalization (v1 proposal):
1. Recursively sort object keys lexicographically.
2. Ensure arrays remain in declared order (do not sort).
3. Encode as UTF‑8, no trailing spaces, no indentation.
4. Compute SHA-256 over the exact byte stream.

---

## 9. guidance Object

```jsonc
"guidance": {
  "_usage": "Pass file via --segment-file to aggregator to embed.",
  "_next_steps": [
    "Replace estimated timings with measured ones.",
    "Add fine precision once instrumentation hooks land."
  ],
  "_cautions": [
    "Draft timings are not performance baselines.",
    "Do not compare different precision classes directly."
  ]
}
```

All keys here are advisory. Keys beginning with `_` are **non-normative**.

---

## 10. Validation Rules (Normative)

| Rule ID | Description | Enforcement |
|---------|-------------|------------|
| R-001 | `schema_version` must parse as semver; prerelease tags allowed. | Required |
| R-002 | Segment `order` strictly increases (no equality). | Required |
| R-003 | `duration_ms == end_ms - start_ms` for every segment. | Required |
| R-004 | `aggregate.segment_count == len(segments)` | Required |
| R-005 | Counts (ok/partial/failed) match statuses in `segments`. | Required |
| R-006 | If a segment has `status=fail` then `errors.length >= 1`. | Required |
| R-007 | `aggregate.total_duration_ms == aggregate.latest_end_ms - aggregate.earliest_start_ms` | Required |
| R-008 | If `checksum` starts with `sha256:` then hex digest must be 64 chars. | Recommended |
| R-009 | `widget_delta` (if integer) equals (post - baseline) measured externally. | Informational |
| R-010 | Segment `id` matches regex: `^seg-[0-9]{3}-[a-z0-9-]+$` | Required |

---

## 11. Reserved / Extension Fields

| Location | Prefix | Purpose |
|----------|--------|---------|
| Any object | `_` | Non-normative, safe to ignore |
| `segment.metrics` | `exp_` | Experimental metric (subject to removal) |
| Future `segments[*]` | `spans` | (Planned) Nested fine-grain span array |
| Top-level | `events` | (Planned) Cross-segment asynchronous events collection |

---

## 12. Example: Minimal Valid Document

```json
{
  "schema_version": "1.0.0",
  "generated_at_utc": "2025-10-01T12:00:00Z",
  "host_context": {
    "os": "macOS",
    "zsh_version": "5.9",
    "git_head": "abcdef1",
    "baseline_widget_count": 416
  },
  "capture_parameters": {
    "method": "manual_instrumentation_stub",
    "precision_class": "coarse",
    "time_source": "date +%s%3N"
  },
  "segments": [],
  "aggregate": {
    "total_duration_ms": 0,
    "segment_count": 0,
    "ok_segments": 0,
    "partial_segments": 0,
    "failed_segments": 0,
    "earliest_start_ms": 0,
    "latest_end_ms": 0,
    "widget_baseline": 416,
    "widget_delta": null
  },
  "integrity": {
    "capture_method": "prototype",
    "checksum": "sha256:NOT_COMPUTED",
    "tamper_evident": false,
    "canonicalization_version": 1
  },
  "guidance": {
    "_usage": "Empty instrumentation placeholder."
  }
}
```

---

## 13. Example: Expanded (Reflecting Current Sample)

(See `zsh/.performance/segments.sample.json` — remains authoritative for exemplar multi-segment structure.)

---

## 14. Aggregator Embedding

The CI aggregator embeds parsed segment instrumentation under:

```
summary.instrumentation.segments  ← full JSON document
summary.widget_delta              ← delta from aggregator canonical source
```

Implementation note: for performance,
- The entire instrumentation JSON is inserted as-is (no mutation).
- Consumers should treat absence of `instrumentation` as “not collected”.

---

## 15. Versioning & Evolution

| Change Type | Semver Impact |
|-------------|---------------|
| Add optional field | PATCH |
| Add required field (with default inference) | MINOR |
| Remove / rename required field | MAJOR |
| Tighten validation (narrow enum) | MAJOR |
| Add new enum value (backward-compatible) | MINOR |

Draft suffix (e.g. `1.0.0-segment-draft`) removed when stability proven across ≥3 consecutive CI runs without structural change.

---

## 16. Migration Guidance

| From | To | Action |
|------|----|--------|
| draft → 1.0.0 | Remove `-segment-draft`, recompute checksum |
| 1.0.x → 1.1.0 | Add new `spans` array (optional) |
| 1.x.y → 2.0.0 | Breaking restructure (e.g. nested metrics) |

---

## 17. Tooling Recommendations

- **Linting**: Implement a lightweight validator (Bash + jq optional) enforcing Rules R-001..R-010.
- **Hashing**: Canonicalization library or deterministic Python script recommended prior to `checksum` seal.
- **Diffing**: Encourage normalized key ordering to yield stable diffs.

---

## 18. Open Questions (For D14 Finalization)

| Topic | Consideration |
|-------|---------------|
| Real-time streaming | Do we need incremental emission before full shell readiness? |
| Span hierarchy | Represent sub-segment operations vs. flatten with derived fine metrics? |
| Multi-shell aggregation | Single file per shell vs. consolidated multi-session artifact? |
| Privacy filters | Redaction strategy for environment variables (PATH subsets, user names). |

---

## 19. Future Extensions (Non-Normative)

1. **Spans**:  
   ```jsonc
   "spans": [
     { "name": "load:zgenom", "start_ms": 15, "end_ms": 42, "status": "ok" }
   ]
   ```
2. **Events**: asynchronous markers (e.g., deferred plugin post-init).
3. **Resource Metrics**: memory snapshots (RSS deltas), file descriptor usage.
4. **Degradation Tags**: indicate jitter when fine precision clock unstable.

---

## 20. Compliance Checklist (Producer)

- [ ] `schema_version` stable & semver valid  
- [ ] All required top-level keys present  
- [ ] Segments sorted by `order` ascending  
- [ ] Durations internally consistent (`duration_ms == end_ms - start_ms`)  
- [ ] Aggregate counts match segment statuses  
- [ ] Checksum either placeholder OR valid hash string  
- [ ] Widget baseline matches pre-harness smoke output  
- [ ] Widget delta computed (or null) after post-smoke validation  

---

## 21. Compliance Checklist (Consumer)

- [ ] Validate semver & timestamp format  
- [ ] Accept unknown keys gracefully (forward compatible)  
- [ ] Reject documents where mandatory rules violated (R-001..R-007)  
- [ ] Log (do not fail) on checksum placeholder during draft phase  

---

## 22. Rationale Highlights

| Decision | Justification |
|----------|---------------|
| Flat metrics map | Avoid premature schema rigidity; domain evolves quickly. |
| Separate aggregate block | Lowers downstream parsing complexity; precomputed counts. |
| Optional `widget_delta` | Not all runs perform post-validation; preserves cheap mode. |
| `status` granularity | Distinguishes partial degradation from full failure. |
| Integrity block early | Encourages eventual adoption of tamper detection without blocking initial use. |

---

## 23. Change Log (Schema Spec)

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0-segment-draft | 2025-10-01 | Initial draft authored |
| 1.0.0 | (TBD) | Draft promoted (no structural changes) |

---

## 24. Acceptance Criteria (Stabilization)

To promote from draft to `1.0.0`:
1. At least 3 CI captures with non-empty segments validated.
2. Zero violations of Rules R-001..R-007.
3. Aggregator successfully embeds and exports instrumentation in JSON artifact bundle.
4. No required field additions pending for near-term D14 instrumentation execution phase.

---

## 25. Summary

This specification seeds a pragmatic, extensible foundation for startup segment instrumentation aligned with Decision D14. It is intentionally permissive where innovation is active (metrics, future spans) while strict where auditability matters (ordering, duration consistency, status semantics).

> Once D14 implementation matures, update this document and bump `schema_version` per Section 15.

---
## 26. D14 Extension Draft: Parent Hierarchy, Nesting Depth & Memory Deltas

Status: Draft (not yet part of stable `schema_version` – becomes normative upon D14 acceptance)

### 26.1 Added Optional Segment Fields

| Field | Type | When Present | Description |
|-------|------|--------------|-------------|
| `parent_id` | string | Child segment | Must reference an existing segment `id` (appearing earlier in the array). Enables hierarchical grouping without requiring nested arrays. |
| `depth` | integer ≥0 | Any segment with hierarchy | Root segments implicitly `depth=0`; if omitted and no `parent_id` ⇒ assume 0. If `parent_id` is provided and `depth` omitted ⇒ consumer MAY derive `depth = parent.depth + 1`. |
| `rss_start_kb` | integer | Memory tracking enabled | Resident set size (kB) sampled at segment start. |
| `rss_end_kb` | integer | Memory tracking enabled | Resident set size (kB) sampled at segment end. |
| `rss_delta_kb` | integer | Memory tracking enabled | SHOULD equal `rss_end_kb - rss_start_kb`. If absent while start/end present, consumer MAY compute. |
| `mem_class` | enum | Optional classification | One of: `neutral`, `cache_growth`, `expected_increase`, `leak_suspect`. (Advisory; non-fatal hints.) |

All are OPTIONAL and MUST NOT invalidate a document if absent.

### 26.2 Hierarchy Semantics

- A segment with `parent_id` is considered a logical child; ordering rule (R-002) implicitly guarantees the parent appears first.
- `depth` consistency (if provided) allows fast consumer validation; discrepancies SHOULD be logged but not necessarily reject (unless strict mode).
- Hierarchy is *non-exclusive*: children occupy the same global ordered namespace (`segments` not nested) simplifying diff operations.

### 26.3 Memory Sampling Guidance

Memory (RSS) sampling is coarse and intended for directional insight:
- Capture mechanism SHOULD be documented in `capture_parameters.time_source` or a new `capture_parameters.memory_source` field when promoted.
- Producers SHOULD avoid high-frequency micro-spans purely for memory deltas to prevent measurement distortion.
- Negative `rss_delta_kb` (legitimate reclamation) is allowed.

### 26.4 New Validation Rules (Draft)

| Rule ID | Description | Enforcement (Draft) |
|---------|-------------|---------------------|
| R-011 | If `parent_id` present it MUST match an earlier segment `id`. | Required |
| R-012 | If `depth` present and `parent_id` absent then `depth` MUST be 0. | Required |
| R-013 | If both `rss_start_kb` & `rss_end_kb` present, and `rss_delta_kb` present, then `rss_delta_kb == rss_end_kb - rss_start_kb`. | Required |
| R-014 | If only one of (`rss_start_kb`, `rss_end_kb`) present, `rss_delta_kb` MUST NOT be present. | Required |
| R-015 | `mem_class` (if present) MUST be one of the enumerated values. | Required |
| R-016 | Depth monotonicity: if `parent_id` resolves to depth `d`, child depth (explicit or inferred) MUST equal `d+1`. | Recommended (can warn) |

### 26.5 Aggregation Impact

`aggregate` MAY be extended (future minor version) with:
```jsonc
"aggregate": {
  "...": "...",
  "max_depth": 2,
  "memory": {
    "rss_total_delta_kb": 512,
    "rss_peak_kb": 185000
  }
}
```
Draft consumers MUST ignore unknown keys safely.

### 26.6 Canonicalization & Integrity

Canonical sort still applies; newly introduced optional keys integrate into object key ordering lexicographically. No change to canonicalization algorithm behavior (Section 8).

### 26.7 Forward Evolution Path

| Stage | Action |
|-------|--------|
| Draft (current) | Optional fields emitted opportunistically; validation tolerant. |
| Promotion | After ≥3 consecutive validated CI runs capturing at least one hierarchy & memory example, mark stable. |
| Stabilize | Increment MINOR version (e.g. `1.1.0`); add `memory_source` inside `capture_parameters`. |
| Extension | Potential addition of per-segment `spans` referencing same hierarchical model (children remain flat). |

### 26.8 Example Segment (Draft Fields)

```json
{
  "id": "seg-045-fzf-bindings",
  "name": "FZF Keybindings",
  "phase": "phase4",
  "order": 45,
  "status": "ok",
  "start_ms": 390,
  "end_ms": 410,
  "duration_ms": 20,
  "parent_id": "seg-040-productivity-layer",
  "depth": 1,
  "rss_start_kb": 182400,
  "rss_end_kb": 182460,
  "rss_delta_kb": 60,
  "mem_class": "expected_increase",
  "metrics": {
    "bindings_installed": 12
  }
}
```

### 26.9 Consumer Handling Recommendations

1. Treat absence of draft fields as a LEGACY (flat) view.
2. When visualizing, group children under parents using `parent_id`, ordering preserved.
3. If conflicting `rss_delta_kb`, prefer recomputed value and flag integrity warning.
4. Ignore unknown `mem_class` values (future expansion) but surface them in introspection tooling.

### 26.10 Migration Notes

- No existing required field semantics change.
- Producers adding hierarchy/memory MUST still satisfy original Rules R-001..R-010.
- Upon stabilization, Rules R-011..R-016 MAY become strictly enforced (except R-016 which can remain advisory).

> Draft status: Do not base hard performance budgets solely on memory deltas until stabilized; measurements are coarse and environment-dependent.

(Section 26 concludes Draft D14 extension specification.)

> Once D14 implementation matures, update this document and bump `schema_version` per Section 15.

---
End of specification.