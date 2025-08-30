# Testing Strategy
Date: 2025-08-30
Status: Initial Strategy Established

## 1. Goals
- Prevent regressions in performance, structure, security, and functionality during redesign.
- Enforce single-run patterns (compinit, async integrity) and structural invariants (file count, naming scheme).
- Provide measurable evidence for ≥20% startup performance improvement.

## 2. Test Categories
| Category | Focus | Example Tests | Trigger |
|----------|-------|--------------|---------|
| Design | Structure, naming, guards | test-structure-modules.zsh | CI Core / pre-commit |
| Unit | Core helper functions | test-unit-has_command.zsh | CI Core |
| Feature | User-facing commands | test-feat-plugin_scan_now.zsh | CI Core |
| Integration | Startup path, loader flag, compinit single-run | test-compinit-single-run.zsh | CI Core |
| Performance | Startup time thresholds, regression drift | test-perf-startup-threshold.zsh | CI Perf / pre-commit quick |
| Security | Registry integrity, tamper detection, deferred hashing | test-sec-registry-tamper.zsh | CI Security |
| Maintenance (future) | Drift (file count/prefix), memory sampling | test-structure-drift.zsh | Nightly / Enhancements |

## 3. Naming & Layout Conventions
- Pattern: `test-<category>-<slug>.zsh`
- Executable bit set; tests are self-contained (explicitly source required helpers).
- Output: PASS/FAIL or SKIP (uppercase tokens). Non-zero exit code indicates failure.

## 4. Environment Assumptions
- `.zshenv` is source-safe and idempotent.
- `ZDOTDIR` resolved before tests run (runner ensures this).
- `ZGEN_AUTOLOAD_COMPINIT=0` (explicit compinit is guarded in redesigned completion module / tool script).

## 5. Guard / Sentinel Variables
| Variable | Purpose | Test Enforcement |
|----------|---------|------------------|
| `_COMPINIT_DONE` | Prevent multiple compinit runs | integration test sources init twice |
| `_ASYNC_PLUGIN_HASH_STATE` | Tracks async integrity scan state | security async test (planned) |
| `ZSH_REDESIGN` | Feature flag for redesign sourcing | integration test toggles (future) |

## 6. Performance Testing Approach
| Mode | Runs | Use | Threshold |
|------|------|-----|-----------|
| Quick | 3 | Pre-commit heuristic | Warn >5% delta (block commit) |
| Full | 10 | CI nightly / validation phase | Fail >5% regression; require -20% improvement redesign |

Metrics stored in `docs/redesign/metrics/` (`perf-baseline.json`, `perf-current.json`, optional historical snapshots).

## 7. Security Testing Focus
- Registry tamper: modify a plugin hash; expect non-zero exit + log entry.
- Deferred hashing: confirm advanced hash not executed before first prompt (timestamp comparison in log vs session start).
- Hash utility absence: simulate missing `shasum`; expect graceful WARN, not FAIL.

## 8. Structure Tests (Design)
Assertions:
- Exactly 11 redesign files after promotion (names/prefix pattern `^(00|05|10|20|30|40|50|60|70|80|90)-.*\.zsh$`).
- Guard line present in each file (`_LOADED_`).
- No duplicate numeric prefixes.

## 9. Integration Tests
| Test | Validates |
|------|-----------|
| compinit-single-run | Single guarded compinit execution + stable compdump path |
| startup-integration (planned) | Ordered sourcing & absence of early heavy hashing |

## 10. Exit Criteria Mapping
| Criterion | Test(s) |
|-----------|---------|
| 20% performance improvement | perf-startup-threshold + baseline comparison |
| Single compinit | compinit-single-run |
| Deferred integrity | security async timing test |
| Structural consistency | structure modules & drift guard |

## 11. Failure Diagnosis Guidelines
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Compinit test FAIL (duplicate) | Guard missing or second init script | Add `_COMPINIT_DONE` guard earlier |
| Perf regression | New synchronous logic added early | Move to deferred module / async hook |
| Security tamper test passes unexpectedly | Test not mutating correct file | Verify mutation path & plugin registry location |

## 12. Future Enhancements
- JSON summary export for CI dashboards (`--json-report` flag extension).
- Memory footprint sampling baseline & regression detection.
- Flamegraph generation optional target (off by default).

## 13. Cross-References
| Topic | File |
|-------|------|
| Architecture | ../architecture/overview.md |
| Issues Review | ../review/issues.md |
| Completion Audit | ../review/completion-audit.md |
| Consolidation Plan | ../consolidation/plan.md |
| Master Improvement Plan | ../improvements/master-plan.md |

---
(End testing strategy)
