# ZSH Configuration Redesign – Consolidated Refactor Plan
<!-- TOC -->
- [1. Executive Summary](#1-executive-summary)
- [2. New Structure (Target)](#2-new-structure-target)
- [3. Key Design Decisions](#3-key-design-decisions)
- [4. Migration & Rollback Overview](#4-migration--rollback-overview)
- [5. Performance Measurement Strategy](#5-performance-measurement-strategy)
- [6. Security & Integrity Enhancements](#6-security--integrity-enhancements)
- [7. Functionality Preservation Matrix](#7-functionality-preservation-matrix)
- [8. Risk Register & Mitigations](#8-riREDACTED_OPENAI)
- [9. Post-Migration Maintenance](#9-post-migration-maintenance)
- [10. Action Checklist](#10-action-checklist-abbreviated)
- [11. Quick Reference Commands](#11-quick-reference-commands)
- [12. Next Immediate Tasks](#12-next-immediate-tasks)
- [13. Approval Gate](#13-approval-gate)
- [14. Git Workflow & TDD Summary](#14-git-workflow--tdd-summary-new)
- [15. Test Suite Overview](#15-test-suite-overview-new)
- [16. Cross-Document References](#16-cross-document-references-new)
- [17. Next Maintenance Hooks](#17-next-maintenance-hooks-new)
- [18. CI/CD Automation Summary](#18-cicd-automation-summary-phases-10)
- [19. Enhancements Implementation](#19-enhancements-implementation-phase-11)
- [20. Maintenance Automation & Notifications](#20-maintenance-automation--notifications-phase-12)
- [21. Updated Cross-Phase Mapping](#21-updated-cross-phase-mapping)
- [22. Monitoring & Alert Thresholds](#22-monitoring--alert-thresholds)
- [Appendix A: Dry-Run Promotion Checker](#appendix-a-dry-run-promotion-checker)
<!-- /TOC -->
Date: 2025-08-29
Status: Planning Phase Complete (Implementation Pending)

Documents Produced:
- analysis.md – Full current-state inventory & rationale
- diagrams.md – Accessible Mermaid diagrams (relationships, proposed structure, migration flow, sequence, gantt)
- implementation-plan.md – Hierarchical task list with priorities, safety, validation, rollback
- final-report.md – (this file) Consolidated executive summary & guidance

---
## 1. Executive Summary
The existing `.zshrc.d` ecosystem showed fragmentation (5 active + ~40 legacy fragments) leading to redundant logic (PATH/env, plugin integrity splitting, UI/completion mixing) and early heavy operations (hashing, file writes). Proposed redesign creates a lean, deterministic 11‑file structure (`.zshrc.d.REDESIGN`) emphasizing:
- Early lightweight security stubs
- Centralized interactive options & core functions
- Idempotent essential plugin gating
- Clear separation of completions vs prompt/UI
- Deferred/async advanced integrity + performance monitoring
Target outcomes: ≥20% startup latency reduction, simplified maintenance, safer incremental changes, and robust rollback capability.

---
## 2. New Structure (Target)
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
Rationale: Numeric spacing (increments of 5–10) allows future insertion without renumbering; early modules remain lightweight, heavier operations deferred.

---
## 3. Key Design Decisions
| Decision | Reason | Risk Mitigation |
|----------|--------|-----------------|
| Merge legacy function libraries | Reduce I/O & duplication | Guard headers + whence audit |
| Split integrity into early + deferred phases | Balance security presence & startup speed | Background job status variable + user command triggers |
| Single options file (interactive) | Single source of truth | Keep universal options in `.zshenv` only |
| Separate completion from prompt | Isolation of concerns; easier edits | Provide shared theming variables via core functions if needed |
| Conditional essential plugin regeneration | Avoid redundant zgenom rebuilds | Use `zgenom saved` check + timestamp compare |
| Async advanced hashing | Remove CPU spike from critical path | Fallback synchronous if async facilities absent |

---
## 4. Migration & Rollback Overview
High-level migration flow (details in implementation-plan.md):
1. Baseline metrics (cold start timing, functionality snapshot).
2. Backup `.zshrc.d` → `.zshrc.d.backup-<timestamp>` (immutable copy).
3. Create `.zshrc.d.REDESIGN` skeleton.
4. Phase 1 migrate (security/options/functions).
5. Phase 2 migrate (plugins/dev/aliases/completion/prompt).
6. Add deferred performance + integrity modules.
7. A/B benchmark; require ≥20% improvement.
8. Promote redesign → rename directories.
9. Generate diff & finalize docs.
Rollback: Rename backup back to `.zshrc.d` & disable redesign loader flag; all scripts remain intact (see implementation-plan.md §4 & §5).

---
## 5. Performance Measurement Strategy
Metric collection (example commands – adjust if scripts differ):
```
for i in {1..10}; do /usr/bin/time -p zsh -i -c exit 2>> docs/redesign/planning/baseline-times.txt; done
# After redesign
for i in {1..10}; do /usr/bin/time -p zsh -i -c exit 2>> docs/redesign/planning/redesign-times.txt; done
```
Evaluation: compute mean (ignore first warm run if necessary) & standard deviation; improvement target: `(baseline_mean - redesign_mean)/baseline_mean >= 0.20`.

Planned optimization levers if target missed:
- Further defer non-essential exports
- Gate heavy environment detection behind first interactive command
- Optionally compile modules with `zcompile` (only after stable behavior)

---
## 6. Security & Integrity Enhancements
| Layer | Early (00) | Deferred (80) |
|-------|------------|---------------|
| Directory existence | ✅ | – |
| Minimal registry bootstrap | ✅ | – |
| Hash presence check | Stub only (no heavy digest) | Full multi-file + timestamp salted hash |
| Registry maintenance | Basic create | Update, diff, scan commands |
| User commands | `plugin_security_status` | `plugin_scan_now`, `plugin_hash_update`, advanced status |
Heavy operations executed via background job after first prompt (precmd hook). Failures log but do not abort shell. Strict mode optional with `ZSH_REDESIGN_STRICT=1`.

---
## 7. Functionality Preservation Matrix
| Feature | Legacy Source | New Location | Validation Method |
|---------|---------------|--------------|------------------|
| History dedupe/sharing | 00_60-options, .zshrc | 05-interactive-options | `set -o | grep HIST_IGNORE_ALL_DUPS` |
| Core helpers (safe_*, has_command) | Various early files & .zshenv | 10-core-functions | `whence has_command` |
| Essential plugins gating | 20_04-essential | 20-essential-plugins | `zgenom saved` + log check |
| Dev env (SSH, Atuin, VCS) | 10_* modules | 30-development-env | Keys loaded; env vars present |
| Aliases + keybindings | 30_10 / 30_20 + .zshrc | 40-aliases-keybindings | Random alias test + `bindkey` spot check |
| Completion zstyles | .zshrc + scattered | 50-completion-history | `echo $fpath` & sample completion |
| Prompt theming | 30_30-prompt | 60-ui-prompt | Prompt renders starship/p10k fallback |
| Performance monitoring | 00_30-performance-monitoring | 70-performance-monitoring | Log entries appear post prompt |
| Advanced integrity | 00_21-plugin-integrity-advanced | 80-security-validation | Hash scan command output |
| Splash | 99_99-splash | 90-splash | Banner displayed at end |

---
## 8. Risk Register & Mitigations
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| Missed function after merge | Runtime errors | Medium | Automated `whence -w` audit + guard shims |
| Async task race | Partial data or duplicate hashing | Low | Single state var + lockfile pattern (future) |
| Performance gain < target | Redesign adoption delayed | Medium | Secondary defer + optional zcompile pass |
| User custom fragments depending on legacy names | Breakage | Low | Provide alias/shim functions in 10-core-functions temporarily |
| Hash utility absence | Reduced integrity depth | Low | Graceful fallback & log notice |

---
## 9. Post-Migration Maintenance
Cadence:
- Monthly: Re-run quick performance triad (baseline vs current).
- After plugin updates: Run `plugin_scan_now` & update registry hashes intentionally (never automatically write on mismatch in STRICT/WARN).
- Quarterly: Audit file count & ensure no fragmentation creep.
Refinements backlog (deferred): zcompile pass, plugin diff alert tool, JSON schema validation, unified async dispatcher.

---
## 10. Action Checklist (Abbreviated)
| Step | Done? |
|------|-------|
| Baseline metrics captured (Phase 1) | ⬜ |
| Backup created & locked (Phase 2) | ⬜ |
| Redesign skeleton created (Phase 3) | ⬜ |
| Phase 1 migration (security/options/functions) | ⬜ |
| Phase 2 migration (plugins/dev/aliases/completion/prompt) | ⬜ |
| Async modules integrated (Phase 6) | ⬜ |
| Performance benchmark A/B complete (Phase 7) | ⬜ |
| Threshold met (≥20%) | ⬜ |
| Promotion executed (Phase 8) | ⬜ |
| Diff & metrics reports stored (Phase 9) | ⬜ |
| CI/CD workflows operational (Phase 10) | ⬜ |
| Enhancements implemented (Phase 11) | ⬜ |
| Maintenance automation active (Phase 12) | ⬜ |
| Rollback simulation passed | ⬜ |

---
## 11. Quick Reference Commands
| Purpose | Command |
|---------|---------|
| Cold start timing loop | `for i in {1..10}; do /usr/bin/time -p zsh -i -c exit; done` |
| Function audit | `whence -w plugin_security_status` |
| Plugin advanced scan | `plugin_scan_now` (after redesign) |
| Update specific plugin hash | `plugin_hash_update owner/repo` |
| Check completion warnings | `zsh -i -c exit 2>&1 | grep -i insecure` |

---
## 12. Next Immediate Tasks
1. Implement loader flag in `.zshrc` to optionally source `.zshrc.d.REDESIGN`.
2. Create skeleton directory & guarded module headers.
3. Perform baseline performance capture prior to first migration commit.

---
## 13. Approval Gate
Proceed to implementation once stakeholders confirm:
- File set & ordering acceptable
- 20% performance target appropriate
- Async security deferral acceptable from risk perspective

## 14. Git Workflow & TDD Summary (New)
A standardized Git + TDD process underpins all refactor phases to ensure atomic, test-driven, evidence-backed changes.

Key Points:
- Branch-per-phase model (baseline, skeleton, phase1, phase2, async, validation, promotion, docs).
- Commit messages use `type(scope): summary`; scopes align with module domains (security, perf, prompt, completion, integrity, migration).
- Tests are authored first (red) for every structural or behavioral change (see Section 15) before implementation (green) and refactor (clean).
- Each major phase ends with an annotated tag: `refactor-phase<N>` and key artifacts (timing logs, structure audits) are committed append-only.
- Pre-commit hook (optional) enforces: run unit + integration + security tests and quick performance guard (<5% regression allowed transiently).

Phase Git Flow Snapshot:
1. Baseline: capture metrics → commit + tag `refactor-baseline`.
2. Skeleton: add guarded empty modules + design tests → commit.
3. Phase 1: write failing unit/design tests (security/options/functions) → implement → commit.
4. Phase 2: feature + integration tests first (plugins/dev/aliases/completion/prompt) → implement incremental commits.
5. Async: add performance & security async tests → implement deferred logic.
6. Validation: performance threshold test ensures ≥20% improvement.
7. Promotion: directory swap commit + tag `refactor-promotion`.
8. Documentation: finalize reports & metrics; commit with `docs(refactor)`.

Rollback Strategies:
- Full revert: `git revert` promotion commit or reset to baseline tag (preserve backup directory).
- Partial: revert only commits with scope `async` / `integrity` if async logic problematic.

## 15. Test Suite Overview (New)
Test Categories (defined in implementation-plan.md §10):
- Design (Architecture): Ensures file count, naming, guards, unique prefixes.
- Unit: Core helper functions (`has_command`, `safe_*`, plugin registry light logic).
- Feature: User-facing commands (`plugin_scan_now`, integrity status outputs).
- Integration: Loader flag behavior, end-to-end startup path, single `compinit` invocation.
- Performance: Startup mean & stddev, ensuring ≤80% of baseline mean.
- Security: Registry tamper detection, hash mismatch reporting, async integrity non-blocking verification.

Artifacts:
- Metrics JSON & raw timing logs under `docs/redesign/metrics/`.
- Structure audits & security scan logs accompany each phase exit.

TDD Enforcement:
1. Define acceptance criteria per task row (implementation-plan table).
2. Add failing tests (red) – confirm only expected new failures.
3. Minimal implementation (green) – re-run filtered test categories.
4. Refactor (clean) – ensure parity & no performance regression.
5. Commit & tag (when phase boundary).

Performance Testing Modes:
- Quick (dev): 3 runs; warns only.
- Full (CI/validation): 10 runs; failure if threshold unmet.

Security Testing Highlights:
- Tamper test mutates a plugin hash → expect non-zero exit & logged violation.
- Async test ensures first prompt latency unchanged vs baseline (time delta within noise tolerance).

## 16. Cross-Document References (New)
| Topic | Primary Source | Supplemental |
|-------|----------------|-------------|
| Proposed Module Structure | analysis.md §3 | diagrams.md (Structure) |
| Migration Flow | implementation-plan.md §1 | diagrams.md (Migration Flow Gantt) |
| Git & TDD Workflow | implementation-plan.md §§9–14 | This file §§14–15 |
| Performance Metrics | implementation-plan.md §§5,10.2 | final-report.md §5 |
| Security Integrity Phases | analysis.md §8 | diagrams.md (Integrity Phases) |

## 17. Next Maintenance Hooks (New)
Post-promotion additions (optional):
- Pre-push hook to run full performance suite if performance-affecting files changed.
- Nightly cron invoking `tools/perf-capture.zsh` storing rolling 7-day trend.

## 18. CI/CD Automation Summary (Phases 10)
Scope: Enforce continuous quality (tests, performance, security) & provide visibility.
Workflows:
- ci-core.yml: Push/PR trigger; matrix macOS + Ubuntu; runs design, unit, feature, integration, security categories; uploads structure/security artifacts.
- ci-performance.yml: Nightly cron + manual dispatch; 10-run benchmark; compares `perf-current.json` vs `perf-baseline.json`; fails on >5% regression; publishes badge artifact.
- ci-security.yml: Nightly integrity & tamper scan; emits diff report; emails summary on violations.
Local Gate: Pre-commit hook runs quick perf (3 runs), filtered tests (unit+integration+security), rejects >5% regression.
Notifications: All failing nightly jobs email `embrace.s0ul+s-a-c-zsh@gmail.com` (via secret ALERT_EMAIL) with concise markdown summary.
Badges: README to include shields for core CI (tests), performance status, security scan (latest result).

## 19. Enhancements Implementation (Phase 11)
Items formerly deferred are scheduled and test-backed:
- zcompile Pass: Conditional compilation producing `.zwc` only if absent/stale; A/B test ensures no startup regression.
- Async Task Manager: Central queue to serialize background jobs (perf sampling, deep integrity) without overlapping processes.
- Plugin Diff Alerts: Compares registry hash list vs live plugin states; non-zero exit + email on drift.
- JSON Schema Validation: Schema file for trusted plugin registry; jq fallback; CI blocks invalid changes.
- Cross-Platform Timing: Ubuntu runner benchmark appended to metrics for variance tracking.
- Memory Sampling: Record RSS after prompt (macOS & Linux) appended to metrics JSON.
- Structure Drift Guard: Design test ensures file count/prefix invariants & failure on drift.

## 20. Maintenance Automation & Notifications (Phase 12)
Scheduled (local cron / launchd + CI):
- Nightly Performance: `tools/perf-capture.zsh` appends delta → logs/perf; summary emailed if >3% negative drift.
- Weekly Security: `tools/weekly-security-maintenance` runs deep scan; attaches violation report or success digest.
- Monthly Log Rotation: Archive & compress logs >30 days; update index manifest for quick retrieval.
- Health Summary Aggregator: Generates markdown overview (perf trends, security status, structure audit) committed to `docs/redesign/metrics/summary-latest.md` and emailed.
- Regression Sentinel: Script exits non-zero on >10% performance drop immediately halting CI promotion workflows.
Email Handling: Unified notifier script composes unified digest to `embrace.s0ul+s-a-c-zsh@gmail.com` with subject prefix `[zsh-refactor]`.
Retention: Keep 90 days perf & security logs; older compressed into quarterly tarball.

## 21. Updated Cross-Phase Mapping
| Phase | Core Outcome | Automation / Enhancement Output |
|-------|--------------|---------------------------------|
| 10 | CI/CD live | Core, perf, security workflows + badges |
| 11 | Enhancements | zcompile, async manager, diff alerts, schema guard |
| 12 | Maintenance | Cron jobs, summaries, regression sentinel |

## 22. Monitoring & Alert Thresholds
| Metric | Warning | Fail / Abort |
|--------|---------|--------------|
| Startup mean drift vs baseline | >3% slower (email notice) | >5% slower (CI fail) |
| Security integrity mismatches | 1 plugin (yellow email) | >1 or critical plugin (red fail) |
| File structure drift | Added file w/out test | Prefix violation (CI fail) |
| Memory RSS increase | >10% (track) | >20% (investigate task opened) |

---
## Appendix A: Dry-Run Promotion Checker
Script implemented: `tools/dry-run-promotion-check.zsh`
Purpose: Validate readiness before Promotion (Phase 8) without making changes.
Checks:
- Baseline metrics file exists: docs/redesign/metrics/perf-baseline.json
- Current redesign directory present & contains expected guarded module count
- Backup directory `.zshrc.d.backup-*` present & read-only
- Git working tree clean (no unstaged / uncommitted changes)
- Core tests pass (design, integration, security) via test runner
- Performance threshold test (optional: skip with `--no-perf`)
Exit Codes:
- 0 Ready
- 1 Missing prerequisite(s)
- 2 Test failure(s)
- 3 Performance threshold not met
Usage:
```
tools/dry-run-promotion-check.zsh [--no-perf] [--expect-modules 11] [--verbose]
```
Integrate into CI prior to merge of promotion branch.
