# ZSH Configuration Redesign – Implementation Plan
Date: 2025-08-29

Priority Legend (colorblind-accessible):
- ⬛ Critical
- 🔶 High
- 🔵 Medium
- ⚪ Low

Progress Legend (single green usage; no red icon used):
- ⬜ Not Started
- 🔄 In Progress
- ⚠ Blocked / Needs Attention
- ✅ Complete (only green symbol)
- ⏸ Deferred / On Hold

<<<<<<< HEAD
<!-- TOC -->
- [1. Task Breakdown & Sequencing](#1-taREDACTED_OPENAI)
- [1A. TDD & Git Activities Matrix](#1a-tdd--git-activities-matrix-per-main-task)
  - [Anchors (Matrix Task Detail)](#anchors-matrix-task-detail)
- [1B. Condensed CLI Cheat Sheet](#1b-condensed-cli-cheat-sheet)
- [2. Detailed Safety Procedures](#2-detailed-safety-procedures)
- [3. Validation Steps Checklist](#3-validation-steps-checklist)
- [4. Rollback Procedures](#4-rollback-procedures)
- [5. Metrics Collection Commands](#5-metrics-collection-commands-suggested)
- [6. Acceptance Criteria Mapping](#6-acceptance-criteria-mapping)
- [7. Post-Migration Maintenance Recommendations](#7-post-migration-maintenance-recommendations)
- [8. Optional Future Enhancements](#8-optional-future-enhancements-deferred)
- [9. Git Workflow & TDD Integration](#9-new-git-workflow--tdd-integration)
- [10. TDD Test Taxonomy & Strategy](#10-new-tdd-test-taxonomy--strategy)
- [11. Metrics & Evidence Artifacts](#11-new-metrics--evidence-artifacts)
- [12. Phase Exit Criteria](#12-new-phase-exit-criteria-augmented)
- [13. Rollback Git Strategy](#13-new-rollback-git-strategy)
- [14. Open Test Gaps](#14-new-open-test-gaps--future-additions)
- [15. CI/CD Implementation Notes](#15-new-cicd-implementation-notes)
- [16. Maintenance Automation Details](#16-new-maintenance-automation-details)
- [Appendix A: Commit Skeleton Usage](#appendix-a-commit-skeleton-usage)
- [Appendix B: Dry-Run Promotion Checker](#appendix-b-dry-run-promotion-checker)
<!-- /TOC -->

=======
>>>>>>> origin/develop
## 1. Task Breakdown & Sequencing

| ID | Task | Description | Priority | Progress | Safety / Preconditions | Validation Step | Rollback Reference |
|----|------|-------------|----------|----------|------------------------|-----------------|--------------------|
<<<<<<< HEAD
| [1](#matrix-1) | Baseline Capture | Establish performance & functional baselines before changes | ⬛ | ⬜ | Shell stable; no pending edits | 10 cold launches timed; record mean/stddev | 7.1 |
| [1.1](#matrix-1) | Perf Metrics Script Run | Execute existing performance harness (e.g. `bin/test-performance.zsh`) n=5–10 | 🔶 | ⬜ | Ensure no background heavy tasks | Store results in `docs/redesign/planning/baseline-perf.txt` | 7.1 |
| [1.2](#matrix-1) | Functional Snapshot | List current active modules & key env vars | 🔵 | ⬜ | After baseline perf | `env | grep -E 'ZSH|ZGEN|HIST'` capture | 7.1 |
| [2](#matrix-2) | Backup & Archival | Create restorable snapshots | ⬛ | ⬜ | Adequate disk space | Verify directories copied & checksums | 7.2 |
| [2.1](#matrix-2) | Backup Active Dir | Copy `.zshrc.d` → `.zshrc.d.backup-<ts>` | ⬛ | ⬜ | None | `diff -rq` should show zero differences | 7.2 |
| [2.2](#matrix-2) | Freeze Disabled Dir | Set read-only perms on `.zshrc.d.disabled` | 🔵 | ⬜ | Not currently modified | Attempt write (should fail) | 7.2 |
| [3](#matrix-3) | Create Redesign Skeleton | Add `.zshrc.d.REDESIGN` with empty module placeholders | ⬛ | ⬜ | Backup complete | Directory exists with planned file names | 7.3 |
| [3.1](#matrix-3) | Module Templates | Create 00..90 files with header blocks & guard patterns | 🔶 | ⬜ | 3 complete | `wc -l` minimal counts; no syntax errors (`zsh -n`) | 7.3 |
| [3.2](#matrix-3) | Loader Flag | Introduce `ZSH_REDESIGN=1` conditional loader in `.zshrc` | 🔶 | ⬜ | Shell restart upcoming | Start new shell logs show redesign path | 7.3 |
| [4](#matrix-4) | Content Migration (Phase 1) | Move lightweight logic (security stubs, options, functions) | ⬛ | ⬜ | Skeleton in place | No errors on `zsh -n` & features accessible | 7.3 |
| [4.1](#matrix-4) | Security Core | Merge minimal integrity init into `00-security-integrity.zsh` | 🔶 | ⬜ | Hash routines deferred | Function `plugin_security_status` loads | 7.3 |
| [4.2](#matrix-4) | Options Consolidation | Move interactive options from `00_60-options.zsh` | 🔵 | ⬜ | None | Random option sampling via `set -o` | 7.3 |
| [4.3](#matrix-4) | Core Functions Merge | Consolidate helpers from legacy function files | 🔶 | ⬜ | Duplicates flagged | `whence function_name` resolves uniquely | 7.3 |
| [5](#matrix-5) | Content Migration (Phase 2) | Move remaining logic (plugins, dev env, aliases, completion) | ⬛ | ⬜ | Phase 1 validated | Equivalent behavior vs baseline | 7.3 |
| [5.1](#matrix-5) | Essential Plugins | Refactor `20_04-essential` → idempotent loader | 🔶 | ⬜ | zgenom available | `zgenom saved` unaffected | 7.3 |
| [5.2](#matrix-5) | Dev Environment | Merge toolchain & SSH logic (10_x group) | 🔵 | ⬜ | No duplicates | SSH agent status unchanged | 7.3 |
| [5.3](#matrix-5) | Aliases/Keys | Integrate alias/keybinding modules | 🔵 | ⬜ | None | Random alias expansion test | 7.3 |
| [5.4](#matrix-5) | Completion+History | Consolidate scattered zstyles + history tweaks | 🔵 | ⬜ | COMPINIT guard maintained | `echo $fpath` stable; comp works | 7.3 |
| [5.5](#matrix-5) | UI & Prompt | Isolate prompt (Starship / P10k / fallback) | 🔶 | ⬜ | Instant prompt intact | Prompt renders; no flicker regression | 7.3 |
| [6](#matrix-6) | Deferred & Async Features | Implement background tasks & advanced security | 🔶 | ⬜ | Core stable; performance measured | Async tasks not blocking TTFP | 7.4 |
| [7](#matrix-7) | Validation & Benchmarks | A/B compare redesigned vs baseline | ⬛ | ⬜ | Redesign fully migrated | 20% improvement threshold | 7.5 |
| [8](#matrix-8) | Promotion | Replace old directory with redesign | ⬛ | ⬜ | Threshold met | `.zshrc.d` now new layout | 7.6 |
| [9](#matrix-9) | Documentation Finalization | Compile final report & diff | 🔶 | ⬜ | Promotion complete | `final-report.md` updated | 7.7 |
| [10](#matrix-10) | CI/CD Automation | Establish automated quality gates & notifications | ⬛ | 🔄 | Phases 1–9 stable | All workflows green in default branch | 12.1 |
| [11](#matrix-11) | Enhancements Implementation | Realize previously deferred improvements | 🔶 | ⬜ | Core stable & monitored | All enhancement tests green | 12.2 |
| [12](#matrix-12) | Maintenance Automation | Continuous upkeep tasks | 🔶 | ⬜ | CI/CD operational | Cron scripts present & logged | 12.3 |

## 1A. TDD & Git Activities Matrix (Per Main Task)

| Main Task ID | Scope Summary | TDD Activities (Before -> During -> After) | Git Activities & Commands |
|--------------|---------------|---------------------------------------------|---------------------------|
| 1 Baseline Capture | Metrics & env snapshot | Write failing perf baseline parse test (design/unit); run to confirm RED; generate baseline metrics; update test expectations; rerun GREEN | git checkout -b feat/baseline-capture; git add docs/redesign/metrics/perf-baseline.json docs/redesign/planning/baseline-perf.txt; git commit -m "chore(perf): add baseline performance + env snapshot"; git push -u origin feat/baseline-capture |
| 2 Backup & Archival | Immutable snapshot | Add design test asserting backup dir presence hash file; run RED (dir missing) then create & rerun GREEN | git add .zshrc.d.backup-* docs/redesign/metrics/backup.SHA256; git commit -m "chore(backup): add immutable config snapshot"; git push |
| 3 Skeleton | Guarded empty modules | Add structure test expecting 11 filenames (RED); create empty guarded files (GREEN); add guard unit check | git checkout -b feat/skeleton; git add .zshrc.d.REDESIGN; git commit -m "feat(structure): add redesign skeleton with guards"; git push -u origin feat/skeleton |
| 4 Phase 1 Migration | Security stub, options, functions | Write failing unit tests for migrated helpers + security stub presence (RED); migrate minimal code until pass (GREEN); refactor duplicates | git checkout -b refactor/phase1-core; git add .zshrc.d.REDESIGN/00-security-integrity.zsh .zshrc.d.REDESIGN/05-interactive-options.zsh .zshrc.d.REDESIGN/10-core-functions.zsh tests/unit; git commit -m "refactor(core): migrate security stub options and core functions"; git push -u origin refactor/phase1-core |
| 5 Phase 2 Migration | Plugins, dev env, aliases, completion, prompt | Add failing feature/integration tests: alias parity, completion single-run, prompt render (RED); migrate each module sequentially validating tests (GREEN) | git checkout -b refactor/phase2-features; git add .zshrc.d.REDESIGN/{20-essential-plugins.zsh,30-development-env.zsh,40-aliases-keybindings.zsh,50-completion-history.zsh,60-ui-prompt.zsh}; git commit -m "refactor(features): migrate plugins dev env aliases completion prompt"; git push -u origin refactor/phase2-features |
| 6 Deferred & Async | Perf monitor + advanced integrity | Add failing async non-blocking + deferred integrity tests (RED); implement 70/80 modules & background trigger (GREEN) | git checkout -b feat/async-integrity-perf; git add .zshrc.d.REDESIGN/{70-performance-monitoring.zsh,80-security-validation.zsh} tests/performance tests/security; git commit -m "feat(async): add performance monitoring & deferred integrity"; git push -u origin feat/async-integrity-perf |
| 7 Validation & Benchmarks | A/B compare & thresholds | Add failing performance threshold test requiring <=80% baseline (RED if not met); tune until GREEN; record redesign metrics | git add docs/redesign/metrics/perf-current.json tests/performance; git commit -m "test(perf): record redesign metrics & enforce threshold"; git push |
| 8 Promotion | Activate redesign | Add integration test expecting redesign path sourced (RED pre-swap); perform swap (GREEN) | git checkout -b chore/promotion; git add .zshrc .zshrc.d .zshrc.d.legacy-final; git commit -m "chore(promotion): activate redesign layout"; git push -u origin chore/promotion |
| 9 Documentation Finalization | Reports & guides | Add failing doc presence test (structure) for final-report & maintenance guide (RED); write docs (GREEN) | git add docs/redesign/planning/final-report.md docs/README.md; git commit -m "docs(refactor): finalize reports and maintenance guide"; git push |
| 10 CI/CD Automation | Workflows, hooks, badges | Add failing CI config lint test or placeholder badge existence (RED); add workflows & badge gen scripts (GREEN) | git checkout -b ci/automation; git add .github/workflows docs/badges tools/*.zsh .githooks/pre-commit; git commit -m "ci: add core/perf/security workflows, hooks, badges"; git push -u origin ci/automation |
| 11 Enhancements Implementation | zcompile, diff alerts, schema, memory | Add failing tests for diff alert, schema validation, memory sampling (RED); implement features (GREEN) | git checkout -b feat/enhancements; git add tools/* zsh compiled artifacts tests/*; git commit -m "feat(enhancements): add zcompile diff alerts schema validation memory sampling"; git push -u origin feat/enhancements |
| 12 Maintenance Automation | Cron, summaries, sentinel | Add failing tests for drift guard & regression sentinel (RED); implement cron scripts & sentinel (GREEN) | git checkout -b chore/maintenance-automation; git add tools/run-nightly-maintenance.zsh tools/notify-email.zsh docs/redesign/metrics/summary-* tests/style; git commit -m "chore(maintenance): add nightly/weekly jobs and regression sentinel"; git push -u origin chore/maintenance-automation |

### Anchors (Matrix Task Detail)
#### <a id="matrix-1"></a>Matrix Task 1 – Baseline Capture ([back to table](#1-taREDACTED_OPENAI))
#### <a id="matrix-2"></a>Matrix Task 2 – Backup & Archival ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-3"></a>Matrix Task 3 – Skeleton ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-4"></a>Matrix Task 4 – Phase 1 Core Migration ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-5"></a>Matrix Task 5 – Phase 2 Feature Migration ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-6"></a>Matrix Task 6 – Deferred & Async ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-7"></a>Matrix Task 7 – Validation & Benchmarks ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-8"></a>Matrix Task 8 – Promotion ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-9"></a>Matrix Task 9 – Documentation Finalization ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-10"></a>Matrix Task 10 – CI/CD Automation ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-11"></a>Matrix Task 11 – Enhancements Implementation ([back](#1-taREDACTED_OPENAI))
#### <a id="matrix-12"></a>Matrix Task 12 – Maintenance Automation ([back](#1-taREDACTED_OPENAI))

## 1B. Condensed CLI Cheat Sheet
| Phase | Quick Commands (Sequence) |
|-------|---------------------------|
| 1 Baseline | `git checkout -b feat/baseline-capture` → run perf harness → `git add docs/redesign/metrics/perf-baseline.json` → `git commit -m "chore(perf): add baseline performance"` → `git push` |
| 2 Backup | `cp -R .zshrc.d .zshrc.d.backup-$(date +%Y%m%d%H%M%S)` → `shasum -a 256 -r .zshrc.d.backup-* > docs/redesign/metrics/backup.SHA256` → `git add .zshrc.d.backup-* docs/redesign/metrics/backup.SHA256` → `git commit -m "chore(backup): snapshot"` → `git push` |
| 3 Skeleton | `git checkout -b feat/skeleton` → create `.zshrc.d.REDESIGN/{00,05,...,90}*` → add guards → `git add .zshrc.d.REDESIGN` → `git commit -m "feat(structure): skeleton"` → `git push` |
| 4 Phase1 | add failing tests → implement core modules → `git add` core files tests → `git commit -m "refactor(core): migrate security/options/functions"` |
| 5 Phase2 | add parity tests → migrate 20–60 modules → commit `refactor(features)` |
| 6 Async | add async tests → implement 70/80 → commit `feat(async)` |
| 7 Validate | run perf (10 runs) → update `perf-current.json` → commit `test(perf)` |
| 8 Promotion | backup tag → swap dirs → commit `chore(promotion)` → tag `refactor-promotion` |
| 9 Docs | update reports → commit `docs(refactor)` |
| 10 CI/CD | add workflows & hook → commit `ci: add core/perf/security workflows` |
| 11 Enhancements | implement zcompile/diff/schema/memory → commit `feat(enhancements)` |
| 12 Maintenance | add cron + sentinel scripts → commit `chore(maintenance)` |

| Utility | Command |
|---------|---------|
| Quick perf (3 runs) | `bin/test-performance.zsh --runs 3 --json-out perf-quick.json` |
| Full perf (10 runs) | `bin/test-performance.zsh --runs 10 --json-out docs/redesign/metrics/perf-current.json` |
| Structure test | `tests/run-all-tests.zsh --category=design` |
| Security test | `tests/run-all-tests.zsh --category=security` |
| Integration subset | `tests/run-all-tests.zsh --category=integration` |
| Generate badge | `tools/generate-perf-badge.zsh --strict` |
| Commit skeleton (helper) | `tools/commit-skeleton.zsh <task>` |
=======
| 1 | Baseline Capture | Establish performance & functional baselines before changes | ⬛ | ⬜ | Shell stable; no pending edits | 10 cold launches timed; record mean/stddev | 7.1 |
| 1.1 | Perf Metrics Script Run | Execute existing performance harness (e.g. `bin/test-performance.zsh`) n=5–10 | 🔶 | ⬜ | Ensure no background heavy tasks | Store results in `docs/redesign/planning/baseline-perf.txt` | 7.1 |
| 1.2 | Functional Snapshot | List current active modules & key env vars | 🔵 | ⬜ | After baseline perf | `env | grep -E 'ZSH|ZGEN|HIST'` capture | 7.1 |
| 2 | Backup & Archival | Create restorable snapshots | ⬛ | ⬜ | Adequate disk space | Verify directories copied & checksums | 7.2 |
| 2.1 | Backup Active Dir | Copy `.zshrc.d` → `.zshrc.d.backup-<ts>` | ⬛ | ⬜ | None | `diff -rq` should show zero differences | 7.2 |
| 2.2 | Freeze Disabled Dir | Set read-only perms on `.zshrc.d.disabled` | 🔵 | ⬜ | Not currently modified | Attempt write (should fail) | 7.2 |
| 3 | Create Redesign Skeleton | Add `.zshrc.d.REDESIGN` with empty module placeholders | ⬛ | ⬜ | Backup complete | Directory exists with planned file names | 7.3 |
| 3.1 | Module Templates | Create 00..90 files with header blocks & guard patterns | 🔶 | ⬜ | 3 complete | `wc -l` minimal counts; no syntax errors (`zsh -n`) | 7.3 |
| 3.2 | Loader Flag | Introduce `ZSH_REDESIGN=1` conditional loader in `.zshrc` | 🔶 | ⬜ | Shell restart upcoming | Start new shell logs show redesign path | 7.3 |
| 4 | Content Migration (Phase 1) | Move lightweight logic (security stubs, options, functions) | ⬛ | ⬜ | Skeleton in place | No errors on `zsh -n` & features accessible | 7.3 |
| 4.1 | Security Core | Merge minimal integrity init into `00-security-integrity.zsh` | 🔶 | ⬜ | Hash routines deferred | Function `plugin_security_status` loads | 7.3 |
| 4.2 | Options Consolidation | Move interactive options from `00_60-options.zsh` | 🔵 | ⬜ | None | Random option sampling via `set -o` | 7.3 |
| 4.3 | Core Functions Merge | Consolidate helpers from legacy function files | 🔶 | ⬜ | Duplicates flagged | `whence function_name` resolves uniquely | 7.3 |
| 5 | Content Migration (Phase 2) | Move remaining logic (plugins, dev env, aliases, completion) | ⬛ | ⬜ | Phase 1 validated | Equivalent behavior vs baseline | 7.3 |
| 5.1 | Essential Plugins | Refactor `20_04-essential` → idempotent loader | 🔶 | ⬜ | zgenom available | `zgenom saved` unaffected | 7.3 |
| 5.2 | Dev Environment | Merge toolchain & SSH logic (10_x group) | 🔵 | ⬜ | No duplicates | SSH agent status unchanged | 7.3 |
| 5.3 | Aliases/Keys | Integrate alias/keybinding modules | 🔵 | ⬜ | None | Random alias expansion test | 7.3 |
| 5.4 | Completion+History | Consolidate scattered zstyles + history tweaks | 🔵 | ⬜ | COMPINIT guard maintained | `echo $fpath` stable; comp works | 7.3 |
| 5.5 | UI & Prompt | Isolate prompt (Starship / P10k / fallback) | 🔶 | ⬜ | Instant prompt intact | Prompt renders; no flicker regression | 7.3 |
| 6 | Deferred & Async Features | Implement background tasks & advanced security | 🔶 | ⬜ | Core stable; performance measured | Async tasks not blocking TTFP | 7.4 |
| 6.1 | Performance Monitoring | Add timing capture precmd hook | 🔵 | ⬜ | 10-core-functions loaded | Log file shows timing entries | 7.4 |
| 6.2 | Advanced Integrity | Move heavy hashing to 80 file with async trigger | 🔶 | ⬜ | Hash utilities present | First prompt unaffected; manual trigger works | 7.4 |
| 6.3 | User Commands | Expose `plugin_scan_now`, `plugin_hash_update` | 🔵 | ⬜ | Adv integrity present | Commands return expected status codes | 7.4 |
| 7 | Validation & Benchmarks | A/B compare redesigned vs baseline | ⬛ | ⬜ | Redesign fully migrated | 20% improvement threshold | 7.5 |
| 7.1 | Rollback Test | Simulate rollback using backup | 🔶 | ⬜ | Backup exists | Shell identical to baseline metrics | 7.2 |
| 7.2 | Error Injection Test | Temporarily break one module to confirm guard | ⚪ | ⬜ | Safe environment | Startup continues with log warning | 7.5 |
| 7.3 | Timing Sample | 10-run average redesigned startup time | ⬛ | ⬜ | Perf harness accurate | Mean time recorded | 7.5 |
| 7.4 | Functionality Parity Checklist | Compare aliases, history, prompt, completions | ⬛ | ⬜ | All modules loaded | Checklist file signed off | 7.5 |
| 7.5 | Security Status Review | Run `plugin_security_status_advanced` | 🔵 | ⬜ | Adv integrity done | Report shows no violations | 7.5 |
| 8 | Promotion | Replace old directory with redesign | ⬛ | ⬜ | Threshold met | `.zshrc.d` now new layout | 7.6 |
| 8.1 | Archive Old | Rename previous active to `.zshrc.d.legacy-final` | 🔵 | ⬜ | Promotion complete | Directory present & untouched | 7.6 |
| 8.2 | Clean Flags | Remove `ZSH_REDESIGN` conditional or set default | 🔵 | ⬜ | Promotion verified | `.zshrc` diff minimal | 7.6 |
| 9 | Documentation Finalization | Compile final report & diff | 🔶 | ⬜ | Promotion complete | `final-report.md` updated | 7.7 |
| 9.1 | Diff Report | Generate `diff -ruN` vs backup | 🔵 | ⬜ | Tools available | Stored in docs path | 7.7 |
| 9.2 | Metrics Report | Summarize before/after measurements | 🔵 | ⬜ | Benches done | Metrics table present | 7.7 |
| 9.3 | Maintenance Guide | Add future extension guidelines | ⚪ | ⬜ | Final design stable | Document exists | 7.7 |
>>>>>>> origin/develop

## 2. Detailed Safety Procedures
1. Immutable Backup: After Task 2.1 set filesystem permissions (e.g., chmod -R a-w) on backup copy to prevent accidental edits.
2. Guard Headers: Each redesign file begins with `[[ -n "${_LOADED_<NAME>:-}" ]] && return` style guard to avoid double sourcing.
3. Conditional Writes: Any file generation (emergency safe mode) checks existence + checksum before writing.
4. Async Isolation: Background hashing exports status variable `_ASYNC_PLUGIN_HASH_STATE` and never terminates the shell on failure (logs & sets failure code only).
5. Strict Mode (Optional): Provide environment flag `ZSH_REDESIGN_STRICT=1` to abort on missing critical functions during trial.

## 3. Validation Steps Checklist
| Category | Checks |
|----------|--------|
| Performance | Mean startup time reduction >= 20%; stddev not inflated (>2x baseline) |
| Security | Basic registry created; advanced hash deferred; manual scan works |
| Prompt | Starship path (if installed) or P10k fallback correct; no duplicate prompt lines |
| Completions | `compinit` runs once; no insecure directory warnings; sample completion test (e.g., `git ch<Tab>`) |
| History | Immediate append (`INC_APPEND_HISTORY`), sharing across sessions, dedupe active |
| Aliases | Critical aliases (ls variants) functional; no alias recursion or override loss |
| Functions | `whence` for migrated helpers returns single path |
| SSH Agent | Existing behavior unchanged (key list present if previously loaded) |
| Rollback | Move directories back & confirm parity measurements |

## 4. Rollback Procedures
| Scenario | Action | Time Cost |
|----------|--------|-----------|
| Performance regression (<20% gain) | Remove new `.zshrc.d`, restore backup, set `ZSH_REDESIGN=0` | ~1–2 min |
| Functional breakage (missing critical function) | Re-enable legacy directory, isolate failing redesign file for patch | ~5 min |
| Security regression (hash failures) | Re-enable original integrity modules from backup; disable advanced async temporarily | ~3–5 min |
| Prompt failure | Temporarily symlink old `30_30-prompt.zsh` into redesign dir for continuity | ~2 min |

## 5. Metrics Collection Commands (Suggested)
```
# Cold startup timing (example loop)
for i in {1..10}; do /usr/bin/time -p zsh -i -c exit 2>> docs/redesign/planning/startup-times.txt; done

# Extract real times
grep ^real docs/redesign/planning/startup-times.txt | awk '{sum+=$2; c++} END{print "mean="sum/c, "runs="c}'

# Function presence audit
whence -w plugin_security_status > docs/redesign/planning/check-functions.txt

# Completion security warning check
zsh -i -c 'exit' 2>&1 | grep -i insecure > docs/redesign/planning/comp-warnings.txt || true
```

## 6. Acceptance Criteria Mapping
| Success Criterion | Plan Step(s) | Measurement |
|-------------------|-------------|-------------|
| 20% Startup Reduction | 1,7 | Mean real time comparison |
| Functionality Preserved | 7.4 | Checklist sign-off |
| Maintainability Improved | 3–6,9 | File count & documentation clarity |
| Documentation Adequate | 9.x | Presence & completeness review |
| Safe Migration & Rollback | 2,7.1 | Successful simulation |

## 7. Post-Migration Maintenance Recommendations
- Quarterly: Re-run performance harness; adjust lazy-loading boundaries if drift >10%.
- Security: Refresh trusted plugin registry hashes after controlled plugin updates only.
- Additions: New logical category? Prefer enhancing existing file vs creating new one unless separation reduces cognitive load or startup latency.
- Observability: Keep performance monitoring lightweight; archive old perf logs monthly.

## 8. Optional Future Enhancements (Deferred)
<<<<<<< HEAD
(Integrated into Phases 11 & 12 — no longer deferred.)

## 9. (NEW) Git Workflow & TDD Integration
This project adopts a strict Test-Driven Development (TDD) and incremental Git hygiene workflow. Every substantive configuration change follows: Red failing test -> Minimal implementation -> Green tests -> Refactor -> Commit.

### 9.1 Git Conventions
- Commit style: `type(scope): summary` where type in {feat, refactor, perf, fix, chore, docs, test, ci}
- Scope examples: `security`, `perf`, `prompt`, `completion`, `integrity`, `migration`
- Each phase (Tasks 1–9) ends with a signed, annotated tag: `refactor-phase<N>`
- Baseline & benchmark artifacts committed (raw timing logs) – never rewritten (append-only)
- Use one commit per logical task (table row). If a task mixes code + docs + tests, tests first commit may be allowed followed by implementation commit.

### 9.2 Required Git Steps Per Major Task
| Task Block | Before Starting | During | After Completion |
|-----------|-----------------|--------|------------------|
| Baseline (1.x) | `git checkout -b feat/zsh-refactor-baseline` | Capture metrics & env snapshots | Commit: `chore(perf): add baseline metrics & env snapshot` Tag: `refactor-baseline` |
| Backup (2.x) | Ensure clean index | N/A | `git add .zshrc.d.backup-*` -> Commit: `chore(backup): add immutable config snapshot` |
| Skeleton (3.x) | Branch `feat/zsh-refactor-skeleton` | Add empty guarded files + loader flag tests | Commit: `feat(structure): introduce redesign skeleton & loader flag` |
| Phase 1 (4.x) | Write failing tests for security/options/functions | Implement minimal logic to pass | Commit: `refactor(core): migrate security/options/functions (phase1)` |
| Phase 2 (5.x) | Add failing tests (aliases, completion, prompt) | Incremental commits per 5.1–5.5 | Commit: `refactor(features): migrate plugins dev aliases completion prompt` |
| Deferred/Async (6.x) | Add tests for async status & timing invariants | Implement async & ensure pass | Commit: `feat(async): add perf monitor & deferred integrity` |
| Validation (7.x) | Write performance expectation test (threshold) | Run; if fail adjust deferrals | Commit: `test(perf): record redesign metrics & parity checklist` |
| Promotion (8.x) | Tag previous HEAD | Rename dirs & finalize flags | Commit: `chore(promotion): activate redesign layout` Tag: `refactor-promotion` |
| Documentation (9.x) | Ensure all code tests green | Update docs & guidance | Commit: `docs(refactor): finalize reports & maintenance guide` |

### 9.3 Pre-Commit Quality Gate (Hook Recommendation)
Add (optional) `.git/hooks/pre-commit` executing:
1. `bin/test-performance.zsh --quick` (skips if only docs changed)
2. `tests/run-all-tests.zsh --category=unit,integration,security`
3. Abort if performance regression >5% vs latest `metrics-current.json`

### 9.4 Refactor Safety Commits
When splitting large legacy files: commit intermediate neutral state BEFORE deletion of old module; then commit removal with message `refactor(cleanup): remove superseded legacy modules` referencing previous commit hash.

## 10. (NEW) TDD Test Taxonomy & Strategy
Tests are authored BEFORE implementing or migrating logic.

| Category | Purpose | Location Pattern | Naming | Trigger Method |
|----------|---------|------------------|--------|----------------|
| Design (Architecture) | Enforce structure (file count, naming, guards) | `tests/style/phase*/` | `test_structure_*.zsh` | CI + pre-commit |
| Unit | Validate individual helper functions (e.g., `has_command`, `safe_*`) | `tests/miscellany/` or `tests/unit/` (create) | `test_unit_<fn>.zsh` | `run-all-tests.zsh --category=unit` |
| Feature | User-facing commands (`plugin_scan_now`) | `tests/security/` / `tests/performance/` | `test_feat_<name>.zsh` | Category=feature |
| Integration | Full startup path, loader flag logic | `tests/performance/` or `tests/validation/` | `test_integration_startup.zsh` | Category=integration |
| Performance | Assert startup budget & regression guard | `tests/performance/` | `test_perf_startup_threshold.zsh` | Category=performance |
| Security | Registry tamper detection, hash mismatch handling | `tests/security/` | `test_sec_registry_integrity.zsh` | Category=security |

### 10.1 TDD Cycle (Per Change)
1. Identify requirement (e.g., consolidate options).
2. Write failing unit/design tests (structure & behavior).
3. Run test suite: verify new failures only relate to targeted change.
4. Implement minimal code to satisfy tests.
5. Re-run full relevant categories.
6. Refactor (no new features) — ensure tests still green.
7. Commit change referencing task ID.
8. Update metrics or docs if performance/security related.

### 10.2 Performance Test Design
- Baseline JSON file `docs/redesign/planning/perf-baseline.json` with keys: `startup_mean_ms`, `startup_stddev_ms`, `date`.
- After redesign tests produce `perf-current.json`; performance test compares: require `startup_mean_ms <= baseline_mean * 0.8`.
- Quick mode test: 3 runs (development); Full mode: 10 runs (CI).

### 10.3 Security Test Design
- Tamper test: Modify hash of one plugin in temp copy of registry; run `plugin_security_status` expecting non-zero exit & violation log line.
- Async completion test: Ensure first prompt time unchanged (measure wall time) when enabling advanced validation.

### 10.4 Design (Architecture) Test Assertions
- Exactly 11 redesign files present when promotion complete.
- All redesign files have numeric prefix pattern `^[0-9]{2}` and kebab descriptive suffix.
- Guards: each file contains `_LOADED_` sentinel to prevent double load.

### 10.5 Naming & File Conventions Tests
- No duplicate numeric prefixes pre-promotion (except intentional reserved gaps).
- Post-promotion: prefixes unique and ascending.

### 10.6 Test Runner Enhancements (Planned)
Add flags to `tests/run-all-tests.zsh`:
- `--category=<list>` filter categories
- `--fail-fast` short-circuits on first failure
- `--json-report` emits machine-readable summary stored under `docs/redesign/reports/latest-test.json`

## 11. (NEW) Metrics & Evidence Artifacts
Artifacts stored under `docs/redesign/metrics/`:
- `baseline-times.txt`, `redesign-times.txt`
- `perf-baseline.json`, `perf-current.json`
- `structure-audit.json` (design test output)
- `security-scan-initial.log`, `security-scan-post-redesign.log`

## 12. (NEW) Phase Exit Criteria (Augmented)
| Phase | Existing Criteria | Added TDD/Git Criteria | New Automation Criteria |
|-------|-------------------|------------------------|-------------------------|
| Baseline (1) | Metrics captured | Tests for baseline parsing committed | – |
| Backup (2) | Backup present | Hash of backup recorded (`shasum -a 256 > backup.SHA256`) | – |
| Skeleton (3) | Files created | Design tests enforce skeleton & pass | – |
| Phase 1 (4) | Core migrated | All unit tests for core green | – |
| Phase 2 (5) | Feature parity | Feature + integration tests green | – |
| Deferred (6) | Async added | Security + async timing tests green | – |
| Validation (7) | 20% gain | Performance threshold test green | – |
| Promotion (8) | Directory swap | Tag + structure tests re-run green | – |
| Docs (9) | Reports updated | Test report artifacts committed | – |
| CI/CD (10) | Workflows created | All new tests referenced in CI | Perf & security jobs scheduled; notifications configured |
| Enhancements (11) | Features implemented | New tests for each enhancement | Cross-platform & zcompile A/B reports stored |
| Maintenance (12) | Cron scripts present | Tests cover drift guards | Scheduled jobs produce artifacts & emails |

## 13. (NEW) Rollback Git Strategy
- Hard rollback: `git revert <promotion-commit>` (keeps history) OR `git reset --hard <baseline-tag>` if discarding redesign.
- Partial rollback (async only): revert commits with scope `async` or `integrity` while keeping structural changes.
- Always retain tags; create `rollback-<date>` annotated tag documenting reason.

## 14. (NEW) Open Test Gaps / Future Additions
(Previously identified gaps scheduled under Phases 11–12; monitor for newly emerging gaps only.)

## 15. (NEW) CI/CD Implementation Notes
- GitHub Actions Workflows:
  - `ci-core.yml`: triggers on push/PR; matrix: {os: [macos-latest, ubuntu-latest]} runs categories: design, unit, feature, integration, security.
  - `ci-performance.yml`: nightly (cron) + manual dispatch; runs performance harness (10 runs) compares against `perf-baseline.json`; uploads `perf-current.json` & delta badge artifact.
  - `ci-security.yml`: nightly integrity diff; sends email on violations.
- Secrets & Config: Use repository secret `ALERT_EMAIL` for notification address; action step pipes summary to mailer (e.g., `actions-sendmail`).
- Artifacts: Store `structure-audit.json`, `perf-current.json`, `security-scan-*.log` per run.

## 16. (NEW) Maintenance Automation Details
- Cron Examples (macOS launchd or crontab):
  - Nightly perf: `0 2 * * * zsh $ZDOTDIR/tools/perf-capture.zsh >> $ZDOTDIR/logs/perf-cron.log 2>&1`
  - Weekly security: `0 3 * * 1 zsh $ZDOTDIR/tools/weekly-security-maintenance >> $ZDOTDIR/logs/security-weekly.log 2>&1`
  - Monthly rotate: `0 4 1 * * zsh $ZDOTDIR/tools/archive-logs.zsh >> $ZDOTDIR/logs/log-archive.log 2>&1`
- Email Dispatch: Aggregator script composes markdown → plain text; sends via `mail` or API wrapper if available.

## Appendix A: Commit Skeleton Usage
Use `tools/commit-skeleton.zsh <task>` to print suggested branch / add / commit commands derived from the matrix. Example:
```
$ tools/commit-skeleton.zsh 5 --dry
# Commit Skeleton for Task 5
# (output ...)
```
Pipe to a file or copy/paste. Add `--type refactor` to override inferred commit type.

## Appendix B: Dry-Run Promotion Checker
Script: `tools/dry-run-promotion-check.zsh` validates prerequisites before executing Promotion (Task 8):
- Baseline metrics JSON exists
- Backup directory present & immutable
- Redesign skeleton file count & guard headers
- Tests pass (structure, compinit, perf threshold optional)
- No uncommitted changes (clean index)
Exit codes:
- 0 = Ready for promotion
- 1 = Missing prerequisites (details printed)
- 2 = Tests failing
Integrate into CI or run manually prior to branch merge.

---
(End of augmented implementation plan including CI/CD, enhancement, and maintenance phases.)
=======
| Idea | Benefit | Reason Deferred |
|------|--------|------------------|
| zcompile redesigned modules | Faster sourcing | Measure first; may be marginal |
| Central async task manager | Consistent scheduling | Added complexity now |
| Plugin diff alert system | Proactive integrity alerts | Needs stable registry format |
| JSON schema validation for registry | Prevent malformed entries | jq dependency mgmt |

---
Generated as part of redesign planning deliverables.
>>>>>>> origin/develop
