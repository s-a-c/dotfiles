# ZSH Configuration Redesign – Consolidated Refactor Plan
Date: 2025-08-29
Status: Planning Phase Complete (Implementation Pending – All design docs frozen pending baseline capture)

## 1. Executive Summary
The current configuration suffers from fragmentation (5 active + ~40 legacy fragments), early synchronous heavy integrity hashing, mixed concerns (prompt + completion styling), and inconsistent numeric prefixes. The redesign establishes two parallel but distinct modernization tracks:
- Post-Plugin Redesign: 11 deterministic modules (00..90) with strict responsibilities.
- Pre-Plugin Redesign: 8 early-stage preparation modules (00..40 reserved) eliminating redundancy and enabling lazy Node/npm activation.

Primary Goals (Measurable):
| Goal | Baseline Artifact | Target | Measurement Method |
|------|-------------------|--------|--------------------|
| Startup latency (mean) | perf-baseline.json | ≥20% reduction | 10-run mean (minus warm-up) |
| Active post-plugin files | manual count | 11 | structure-audit.json total |
| Pre-plugin fragments | 12 | 8 | preplugin-structure-baseline.json |
| Compinit executions | trace | 1 | compinit-single-run test |
| Deferred hashing | n/a | 0 ms pre-first-prompt | timing + absence in early log |

## 2. Target Structures
### 2.1 Post-Plugin (11 Files)
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
### 2.2 Pre-Plugin (8 Files)
```
.zshrc.pre-plugins.d.redesigned/
  00-path-safety.zsh
  05-fzf-init.zsh
  10-lazy-framework.zsh
  15-node-runtime-env.zsh
  20-macos-defaults-deferred.zsh
  25-lazy-integrations.zsh
  30-ssh-agent.zsh
  40-pre-plugin-reserved.zsh
```

## 3. Key Design Decisions
| Decision | Justification | Mitigation / Safeguard |
|----------|---------------|------------------------|
| Split integrity (00 early / 80 deferred) | Reduce cold start CPU | Async queue + state variable `_ASYNC_PLUGIN_HASH_STATE` |
| Single guarded compinit in 50 | Avoid duplicate initialization, centralized zstyles | `_COMPINIT_DONE` sentinel test enforced |
| Merge dispersed functions → 10 | Reduce file I/O, unify helpers | whence audit + unit tests for exported funcs |
| Separate prompt (60) from completion (50) | Clear responsibility boundaries | Cross-module variable naming conventions (PROMPT_, COMP_) |
| Lazy Node/npm reactivation | Preserve speed while restoring functionality | Stub wrappers + feature flags `ZSH_ENABLE_NVM_PLUGINS`, `ZSH_NODE_LAZY` |
| Performance badge & regression gate | Continuous drift detection | Promotion guard + CI perf job |
| Deterministic numeric prefixes (5/10 step) | Predictable ordering & insertion | Design tests for unique ascending prefixes |

## 4. Pre-Plugin Redesign Details
| Module | Responsibility | Must NOT Do | Performance Budget |
|--------|----------------|-------------|--------------------|
| 00-path-safety | Normalize PATH, handle realpath edge cases | Source plugin/env heavy scripts | 2 ms |
| 05-fzf-init | Export FZF env + key bindings if available | Attempt installs | 4 ms |
| 10-lazy-framework | Define generic lazy loader registration + post-prompt task queue | Source heavy frameworks | 5 ms |
| 15-node-runtime-env | Provide stub nvm(), npm() wrappers; set detection vars | Source nvm.sh immediately | 3 ms |
| 20-macos-defaults-deferred | Schedule mac defaults check asynchronously (macOS only) | Block startup on defaults I/O | 3 ms (scheduling only) |
| 25-lazy-integrations | direnv/git config/copilot wrappers setting single-use hook each | Perform network calls | 5 ms |
| 30-ssh-agent | Launch or bind to existing agent; permission sanity | Start duplicate agent | 8 ms (conditional) |
| 40-pre-plugin-reserved | Guard placeholder | Anything | ~0 ms |

## 5. Functionality Preservation Matrix
| Feature Set | Legacy Sources | New Module(s) | Validation Strategy |
|-------------|---------------|---------------|--------------------|
| Env & history options | .zshenv + 00_60-options | 05-interactive-options | Sample options subset vs baseline (unit) |
| Core helper functions | functions-core/util/tool splits | 10-core-functions | whence uniqueness + unit tests |
| Essential plugin ensure | 20_04-essential | 20-essential-plugins | Idempotence test (no rebuild if unchanged) |
| Dev tooling (SSH, VCS, Atuin) | 10_10*, 10_60* | 30-development-env + 30-ssh-agent (pre) | SSH env parity + agent not duplicated |
| Aliases & keymaps | 30_10-aliases, 30_20-keybindings | 40-aliases-keybindings | Alias parity diff script |
| Completion + zstyles | .zshrc & completion mgmt fragments | 50-completion-history | Single compinit + zstyle presence |
| Prompt & theming | 30_30-prompt | 60-ui-prompt | Prompt detection test + fallback prompt path |
| Performance capture & hooks | 00_30-performance-monitoring | 70-performance-monitoring | Timing log appears post prompt only |
| Integrity advanced hashing | 00_21-plugin-integrity-advanced | 80-security-validation | Deferred hashing test (timestamp delta) |
| Splash & summary | 99_99-splash | 90-splash | Contains perf delta & async status |
| Node/npm ecosystem | nvm-npm-fix + commented plugins | 15-node-runtime-env + plugin phase 03 | Lazy first-run timing + subsequent speed |

## 6. Performance Measurement Strategy
Formulae:
- mean = Σ run_i / N (N=10 excluding warm-up)
- stddev = sqrt( Σ (run_i - mean)^2 / N )
Acceptance:
```
(improvement_percent) = (baseline_mean - redesign_mean) / baseline_mean * 100 >= 20
regression_guard        = (current_mean - baseline_mean) / baseline_mean * 100 <= 5
```
Artifacts:
| File | Purpose |
|------|---------|
| perf-baseline.json | Frozen baseline mean/stddev + runs |
| perf-current.json | Latest redesign or CI measurement |
| perf-history.log | Rolling appended summary lines (optional) |
| structure-audit.json / md | Module count & ordering proofs |

## 7. Security & Integrity Enhancements
| Phase | Operation | Trigger | Abort Impact |
|-------|-----------|---------|--------------|
| Early (00) | Registry dir ensure, minimal logging, placeholder status function | Sourcing | None (lightweight) |
| Deferred (80) | Plugin hash enumeration, tamper diff, remediation suggestions | Post first prompt (async) OR manual `plugin_scan_now` | No effect on base shell if fails |
| On-demand | `plugin_hash_update <plugin>` updates stored checksum | User invocation | Limited to single plugin |

Commands (planned):
- `plugin_security_status` – returns JSON-ish summary of phases (EARLY_INITIALIZED / HASHING / COMPLETE / FAILED)
- `plugin_scan_now` – forces deferred hashing immediately if not done
- `plugin_hash_update <name>` – recomputes and persists trusted hash after validation

## 8. Rollback & Safety
| Scenario | Action | Time |
|----------|--------|------|
| Perf gain <20% | Restore `.zshrc.d.backup-*` & unset `ZSH_REDESIGN` | ~2m |
| Missing function | Reinstate legacy file from backup, re-run parity diff | ~5m |
| Integrity failure (false positives) | Disable 80 module (flag) → re-run status | ~1m |
| Node wrappers regression | Set `ZSH_ENABLE_NVM_PLUGINS=0` revert to stub mode | ~1m |

Rollback Checklist Script (planned: `tools/dry-run-promotion-check.zsh`) verifies baseline presence, backup immutability, structure integrity, performance threshold prior to promotion commit.

## 9. Implementation Phases (Integrated Pre & Post Plugin)
| Phase | Goal | Key Deliverables | Tests Introduced |
|-------|------|------------------|------------------|
| 1 Baseline | Measure startup & structure | perf-baseline.json | baseline parse test |
| 2 Backup | Immutable snapshot | .zshrc.d.backup-* | backup presence test |
| 3 Pre-Plugin Skeleton | 8 guarded files | .zshrc.pre-plugins.d.redesigned | pre-plugin structure test (allow legacy) |
| 4 Pre-Plugin Migration | Path safety, lazy framework, node stubs, integrations | 00/05/10/15/20/25/30 active content | lazy-node test, no-compinit test |
| 5 Post-Plugin Skeleton | 11 guarded files | .zshrc.d.REDESIGN | structure modules test |
| 6 Phase1 Core (Post) | security/options/functions | 00/05/10 content | unit + design tests |
| 7 Phase2 Features | essential/dev/aliases/completion/prompt | 20/30/40/50/60 content | alias parity, single compinit, prompt test |
| 8 Deferred & Async | perf + advanced integrity | 70/80 modules + async queue | deferred hashing test, no TTFP delta |
| 9 Splash & Summary | finalize UI & status summarization | 90 module | splash content test |
| 10 Validation | Performance threshold | perf-current.json | perf threshold test |
| 11 Promotion | Activate redesign & pre-plugin redesign simultaneously | directory rename/tag | promotion integration test |
| 12 CI/CD | Core / perf / security workflows + badges | workflows & badges json | CI artifact tests |
| 13 Enhancements | zcompile, diff alerts, schema, memory sampling | scripts + tests | enhancement tests |
| 14 Maintenance | Cron, nightly perf + weekly security, drift guard | cron scripts, sentinel | drift guard test |

## 10. Testing Overview
(See testing-strategy.md) – all new tests enumerated above integrated gradually; failure gates prevent unsafe promotion.

## 11. Risks & Mitigations (Expanded)
| Risk | Type | Likelihood | Impact | Mitigation |
|------|------|------------|--------|-----------|
| Under-performing redesign (<20%) | Performance | Medium | High | Additional deferrals, measure Node plugin impact separately |
| Hidden duplication after merges | Functional | Low | Medium | whence audit + duplicate symbol test |
| Async race conditions | Reliability | Low | Medium | Single queue/state machine in core-functions |
| Node stub misbehavior | Feature | Medium | Medium | Test first/second invocation timing delta |
| Badge drift due to missing baseline | Process | Low | Medium | Protect baseline file (chmod a-w) |
| Structure creep (new untracked file) | Design | Medium | Low | Structure drift CI test fails |

## 12. Maintenance Cadence
| Interval | Task | Outcome |
|----------|------|---------|
| Nightly | perf capture + summary | perf delta trend |
| Weekly | deep integrity scan + compdump secure refresh | security log |
| Monthly | structure audit, log rotation | updated metrics & archive |
| Quarterly | performance drift review & optional re-baseline | recalibrated baseline (optional) |

## 13. Metrics & Artifacts Directory Map
| Path | Content |
|------|---------|
| docs/redesign/metrics/perf-baseline.json | Frozen baseline |
| docs/redesign/metrics/perf-current.json | Latest measurement |
| docs/redesign/metrics/structure-audit.json | Post-plugin structure audit |
| docs/redesign/metrics/preplugin-structure-baseline.json (future) | Pre-plugin counts baseline |
| docs/redesign/metrics/compinit-history.log (future) | Compinit timing entries |
| docs/redesign/badges/*.json | shields.io endpoints |

## 14. Feature Flags (Planned)
| Flag | Default | Purpose |
|------|---------|---------|
| ZSH_REDESIGN | 0 | Toggle redesigned sourcing branches |
| ZSH_ENABLE_NVM_PLUGINS | 1 | Enable nvm/npm plugin activation phase |
| ZSH_NODE_LAZY | 1 | Force lazy wrappers even if plugins active |
| ZSH_ENABLE_ABBR | 0 | Reintroduce abbr after recursion fix |
| ZSH_REDESIGN_STRICT | 0 | Enforce fail-fast on missing symbols/integrity error |

## 15. Promotion Guard Inputs
Promotion guard verifies:
- structure-audit.json + markdown marker alignment
- perf-current.json vs baseline regression <5%
- badge colors not red (perf/structure)
- redesign file counts (11 post, optionally 8 pre on full promotion)
Additional future extension: verify presence of pre-plugin redesign summary marker.

## 16. Command Quick Reference
| Purpose | Command |
|---------|---------|
| Baseline capture | perf harness loop (see baseline-metrics-plan) |
| Structure audit | tools/generate-structure-audit.zsh |
| Perf badge update | tools/generate-perf-badge.zsh |
| Summary badges | tools/generate-summary-badges.zsh |
| Promotion guard | tools/promotion-guard.zsh <expected> |
| Dry-run promotion | tools/dry-run-promotion-check.zsh (planned) |
| Force integrity scan | plugin_scan_now |
| Update plugin hash | plugin_hash_update <repo> |

## 17. Exit Criteria
Redesign enters implementation when baseline + backup + skeletons + compinit plan + prefix spec + rollback diagram all present and frozen (implementation-entry-criteria.md). Promotion occurs only after performance threshold test green & structure tests stable.

## 18. Appendix – Deferred Enhancements Summary
| Enhancement | Description | Phase |
|-------------|-------------|-------|
| zcompile pass | Compile stable modules; measure delta | 13 |
| Plugin diff alert | Hash diff reporter & email integration | 13 |
| JSON schema validation | Trusted registry schema enforcement | 13 |
| Memory sampling | RSS snapshot after first prompt | 13 |
| Drift guard | Detect unauthorized file additions | 14 |

---
**Navigation:** [← Previous: Diagrams](diagrams.md) | [Next: Implementation Plan →](implementation-plan.md) | [Top](#) | [Back to Index](../README.md)
