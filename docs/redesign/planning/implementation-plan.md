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

## 1. Task Breakdown & Sequencing

| ID | Task | Description | Priority | Progress | Safety / Preconditions | Validation Step | Rollback Reference |
|----|------|-------------|----------|----------|------------------------|-----------------|--------------------|
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
| Idea | Benefit | Reason Deferred |
|------|--------|------------------|
| zcompile redesigned modules | Faster sourcing | Measure first; may be marginal |
| Central async task manager | Consistent scheduling | Added complexity now |
| Plugin diff alert system | Proactive integrity alerts | Needs stable registry format |
| JSON schema validation for registry | Prevent malformed entries | jq dependency mgmt |

---
Generated as part of redesign planning deliverables.
