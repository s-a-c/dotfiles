# Privacy Appendix – ZSH Configuration Redesign Telemetry
Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v<current-guidelines-checksum>

Version: 1.1  
Status: Authoritative privacy reference for Stage 4+ telemetry  
Last Updated: 2025-09-11 (Part 08.19 – Sprint 2, GOAL status metadata)  

---

## 1. Purpose

Define the data classification, collection boundaries, redaction model, governance rules, and change control process for all telemetry emitted by the redesigned ZSH configuration. This appendix guarantees that instrumentation remains minimal, predictable, reversible, and privacy‑preserving.

---

## 2. Scope

IN SCOPE:
- Local-only performance & lifecycle telemetry (plain text SEGMENT lines).
- Optional structured JSON telemetry (opt‑in flags).
- Deferred dispatcher job timing lines.
- Dependency graph exports (structure, not content of external systems).

OUT OF SCOPE (MUST NOT BE ADDED WITHOUT FORMAL ADR + PRIVACY REVIEW):
- User command history
- Environment variable contents (except explicit whitelisted static flags)
- File / directory listings from user projects
- Network destinations / hostnames
- Toolchain / version provenance beyond coarse module names

---

## 3. Data Collection Principles

| Principle | Description | Enforcement |
|----------|-------------|------------|
| Minimality | Collect only timing & categorical phase data indispensable for performance governance | Schema allowlist + tests |
| Locality | All telemetry written only to local filesystem (no network) | No network calls in emitters |
| Determinism | Same startup path → same field set & ordering semantics | Snapshot tests + homogeneity checks |
| Opt-In Expansion | Structured (JSON) mode disabled by default | Flags default 0 |
| Explicit Versioning | Format changes require version bump & changelog entry | CI diff guard |
| Reversible | Deleting log files fully removes collected data | No external replication |
| Redactable-by-Design | No personal or sensitive content generated → precludes per-field dynamic redaction | Explicit “No PII” contract |

---

## 4. Telemetry Channels Overview

| Channel | Format | Default State | Content Class | Location (default) |
|---------|--------|---------------|---------------|--------------------|
| PERF Segment Log | Plain text lines | Enabled (if PERF_SEGMENT_LOG set by harness) | Phase timings & markers | `logs/perf-current.log` (example; harness-controlled) |
| Deferred Job Log | Plain text (job details) | Enabled (interactive shells) | Deferred job durations | `${ZDOTDIR}/.logs/deferred.log` |
| Structured JSON Sidecar | JSON Lines (one object / line) | Disabled (`ZSH_LOG_STRUCTURED=0`) | Timings (same as plain) | `<segment-log-base>.jsonl` |
| Dependency Export | JSON / DOT (on demand) | On demand only | Static dependency graph | User-specified path |
| Baseline Performance JSON | JSON | Created on first classifier run | Aggregated stats only | `artifacts/metrics/perf-baseline.json` |
| Classifier Summary | Single line + optional JSON | On demand | Regression classification | Stdout / user path |

No network transmission is performed by any channel.

---

## 5. Plain Text Line Schemas (Allowlist)

1. Segment Timing  
   `SEGMENT name=<label> ms=<int> phase=<phase> sample=<context?>`  
   - `name`: enumerated stable identifier (e.g. `pre_plugin_start`, `post_plugin_total`, `prompt_ready`, `deferred_total`, feature or integration probe).  
   - `ms`: non-negative integer (milliseconds).  
   - `phase`: one of `pre_plugin`, `post_plugin`, `prompt`, `postprompt`, `core` (transition label; may shrink).  
   - `sample`: optional classification (e.g. `inline`, `unknown`, harness tag).

2. Deferred Job  
   `DEFERRED id=<id> ms=<int> rc=<int>`  
   - `id`: registration id (no dynamic user content).  
   - `ms`: job elapsed ms.  
   - `rc`: exit status (0 success, non-zero failure).

3. Error Bridge (performance surface only)  
   `ERROR level=<LEVEL> module=<module>`  
   - `LEVEL`: one of `WARN|ERROR|CRITICAL|FATAL`.  
   - `module`: static module tag (no dynamic user content).

4. Legacy Markers (will remain until retirement is approved)  
   - `POST_PLUGIN_COMPLETE <ms>`  
   - `PROMPT_READY_COMPLETE <ms>`

If a line does not match one of these patterns it is considered out-of-contract; tests should fail.

---

## 6. Structured JSON Telemetry (Opt-In)

Enabled by: `ZSH_LOG_STRUCTURED=1`  
Optional perf snapshot: `ZSH_PERF_JSON=1` (sidecar path derivation)

### 6.1 JSON Object Types

| type | When Emitted | Required Fields |
|------|--------------|-----------------|
| segment | Every allowed SEGMENT timing | `type,name,ms,phase,sample?,ts` |
| deferred | Each deferred job completion | `type,id,ms,rc,phase="postprompt",ts` |

### 6.2 Field Definitions

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| type | string | `segment` or `deferred` | Allowlist |
| name | string | Segment label allowlist (see §5) | segment only |
| id | string | Deferred job id (registration) | deferred only |
| ms | integer | ≥0 | Milliseconds elapsed |
| rc | integer | ≥0 | Return code (deferred only) |
| phase | string | `pre_plugin|post_plugin|prompt|postprompt|core` | Must reflect actual phase classification |
| sample | string | Optional; controlled enumeration (`inline`, harness tag) | No user raw data |
| ts | integer | Epoch ms (UTC) | Derived from `EPOCHREALTIME` |

No additional keys permitted without schema bump & changelog entry.

### 6.3 Classifier Status Metadata (GOAL Profiles)

The performance classifier emits a *separate* status JSON artifact (governance evidence; distinct from structured segment / deferred telemetry).  
New enumerated / boolean fields (Version 1.1) are strictly non-sensitive and provide execution context:

| Field | Type | Emitted When | Sensitivity | Purpose |
|-------|------|--------------|-------------|---------|
| goal | enum(`streak`,`governance`,`explore`,`ci`) | Always | Non-sensitive | Identifies execution profile semantics |
| synthetic_used | boolean | Synthetic fallback segment(s) injected | Non-sensitive | Signals resilience path; prevents masked governance readiness |
| partial | boolean | Missing metric tolerated under Streak/Explore | Non-sensitive | Declares incomplete metric set (governance gating) |
| ephemeral | boolean | GOAL=Explore | Non-sensitive | Marks non-governance, diagnostic output |

Characteristics:
- Fields are *not* added to structured per-line telemetry; they appear only in the classifier status JSON object.
- Omitted entirely when false/not applicable (no `false` literal clutter).
- Backward compatibility: absence of `goal` in older artifacts should be interpreted as historical “streak-like” behavior.

Governance Precondition (A8):
- Three consecutive governance runs (`goal=governance`) with neither `synthetic_used` nor `partial` present are required before enforce-mode activation.

Privacy Justification:
- All additions are bounded enumerations or booleans (no free-form text, no user identifiers).
- They reduce risk of hidden synthetic masking by making fallback explicit.

Allowlist Update:
- Add `goal` enumeration values (`streak`,`governance`,`explore`,`ci`) to the classifier status artifact allowlist (separate from segment `phase`).


---

## 7. Allowlist / Denylist Summary

| Dimension | Allowed | Denied |
|-----------|---------|--------|
| Timing | ms integer durations | Raw microsecond traces, call stacks |
| Identity | Static module/feature ids | User paths, hostnames, user names |
| Status Codes | rc (numeric) | Shell output / command stderr text |
| Context | Enumerated phase/sample | Arbitrary free-form strings |
| Graph | Module & feature identifiers | File content snapshots, environment dumps |

---

## 8. Redaction Model

Because no personal / sensitive data is collected, runtime redaction is *not required*. Instead we enforce an *input allowlist* strategy:

1. Only enumerated fields are emitted (schema-based emission functions).
2. Adding a field requires:
   - Code change
   - Test update to assert new field presence
   - Documentation (this appendix + change log)
   - Privacy review (lightweight ADR note referencing this appendix)

If a regression introduces a disallowed token (e.g., path containing `/Users/`), a grep-based “telemetry sanitation” test (to be added in later sprint) should fail.

---

## 9. Configuration Flags & Privacy Effects

| Flag | Default | Effect |
|------|---------|--------|
| `ZSH_LOG_STRUCTURED` | 0 | Enables JSON line emission (segments & deferred) |
| `ZSH_PERF_JSON` | 0 | Derives JSON sidecar path for performance snapshots |
| `PERF_SEGMENT_LOG` | (unset) | If unset, no plain segment lines are written |
| `ZSH_FEATURE_TELEMETRY` | 0 | Enables per-feature init timing capture (ZSH_FEATURE_TIMINGS_SYNC + feature_timing JSON lines when ZSH_LOG_STRUCTURED=1) |
| `DEPS_EXPORT_DEBUG` | (unset) | Debug logging for dependency exporter (stderr only) |

All defaults are *OFF* for enriched data paths; baseline plain timing requires explicit harness setup.

---

## 10. Data Flow (Structured Mode)

1. Module / dispatcher captures timing → memory.
2. Emission layer constructs key/value map (restricted set).
3. Validation (presence + type) inline; non-conforming values dropped (future enhancement).
4. Line serialized → append-only file (no rotation logic in core).
5. External tooling (classifier, graph exporter) reads read-only.

No background upload, no asynchronous network jobs.

---

## 11. Retention & Deletion

| Artifact | Rotation Strategy (Current) | Deletion |
|----------|-----------------------------|----------|
| Segment Log | Harness recreates per run | Delete file |
| JSON Sidecar | Per run (derived) | Delete file |
| Baseline JSON | Persist until manually regenerated | Delete file (recreated on next classifier run) |
| Deferred Log | Append; no rotation yet (low volume) | Delete file |

Future enhancement: size-based rotation (configurable threshold) – requires appendix update.

---

## 12. Dependency Export Privacy

Exported graph includes only:
- Node ids (modules / features)
- Enabled boolean (true/false/unknown)
- Declared edges

No file paths, no execution timings (unless explicitly added with ADR). Graph is safe to publish.

---

## 13. Threat & Risk Assessment (Current Stage)

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Accidental inclusion of PII via new field | Low | Medium | Schema allowlist + test guard |
| Overgrowth of log size | Medium (long sessions) | Low | Planned rotation policy (future) |
| Misinterpretation of anonymized metrics | Medium | Low | Clear documentation & units (ms) |
| Timing correlation to sensitive workflow | Low | Low | Aggregate only; no command context |

No elevated risks require anonymization at this stage.

---

## 14. Testing & Enforcement

Planned / Active Tests:
| Test | Purpose | Status |
|------|---------|--------|
| segment-attribution test | Ensures required segments present | Active |
| structured-telemetry test | Ensures JSON lines appear only when enabled | Active |
| logging homogeneity test | Prevents legacy wrapper regression | Active |
| (Planned) telemetry sanitation test | Grep for forbidden tokens (`/Users/`, etc.) | Pending |
| (Planned) schema drift test | Fail if JSON keys outside allowlist | Pending |
| dependency export tests | Validate DOT/JSON structural minimality | Active (basic) |

---

## 15. Change Control Procedure

1. Proposal (PR) adds new field / channel.
2. Update:
   - This appendix (increment version)
   - REFERENCE.md (Environment Flag or Logging section)
   - IMPLEMENTATION.md (Change Log)
3. Add/Update tests:
   - Schema allowlist adaptation
   - Negative test ensuring no leakage
4. Obtain approval referencing Orchestration Policy (link with file + line citations).
5. Merge; baseline re-captured if performance impact >1ms aggregate.

---

## 16. Developer Checklist (Adding Telemetry)

Before merging:
- [ ] Field justified (what decision does it enable?)
- [ ] Field not derivable from existing data
- [ ] Added to structured schema table
- [ ] Tests updated (presence + absence when flag off)
- [ ] No dynamic user paths or arbitrary strings
- [ ] Performance overhead measured (<1ms added path or justified)
- [ ] Changelog entries written (all docs)

---

## 17. Future Enhancements (Require Appendix Update)

| Candidate | Rationale | Privacy Consideration |
|-----------|-----------|-----------------------|
| Per-feature sync budget timings | Fine-grained regression isolation | Ensure feature ids remain non-sensitive |
| Memory/RSS sampling | Detect memory regressions | Numeric only – no process cmdline |
| Invocation error taxonomy | Faster triage | Avoid embedding raw stderr |

---

## 18. Field Allowlist (Canonical Enumerations)

| Category | Values (Current) |
|----------|------------------|
| Phase | `pre_plugin`, `post_plugin`, `prompt`, `postprompt`, `core` |
| Segment Names (base) | `pre_plugin_start`, `post_plugin_total`, `prompt_ready`, `deferred_total`, plus future per-feature labels |
| Deferred Type | `deferred` |
| Segment Type | `segment` |
| Levels (error bridge) | `WARN`, `ERROR`, `CRITICAL`, `FATAL` |

All additions must extend this list and update tests.

---

## 19. Incident Response (Telemetry Misclassification)

1. Disable structured telemetry: set `ZSH_LOG_STRUCTURED=0` globally (or remove enabling logic).
2. Purge local logs: remove `perf-*.log`, sidecar JSON, deferred log.
3. Patch: remove offending emission code.
4. Add regression test asserting absence of the leaked pattern.
5. Document in project CHANGELOG (not just appendix).

---

## 20. FAQ (Focused)

| Question | Answer |
|----------|--------|
| Does enabling structured telemetry change performance? | Negligible (<1ms target); classifier monitors aggregate delta. |
| Does any telemetry leave my machine? | No – no network emission implemented. |
| Can I safely publish the dependency DOT graph? | Yes; it contains only module & feature ids. |
| How do I disable all telemetry? | Do not set `PERF_SEGMENT_LOG` and keep `ZSH_LOG_STRUCTURED=0`; nothing emits. |

---

## 21. Revision History (Appendix Only)

| Date | Version | Change |
|------|---------|--------|
| 2025-09-10 | 1.0 | Initial appendix: schemas, structured telemetry flags & governance |

---

*End of Privacy Appendix*
