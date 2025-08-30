# Dotfiles Documentation Index
Date: 2025-08-30
Status: Living Reference (Redesign In Progress)

## 1. Navigation
| Section | Purpose | Key Files |
|---------|---------|-----------|
| Redesign Planning | Original analysis, diagrams, plan & final report | redesign/planning/analysis.md, diagrams.md, implementation-plan.md, final-report.md |
| Architecture | Baseline & target structural overview | architecture/overview.md |
| Review | Issues list & completion system audit | review/issues.md, review/completion-audit.md |
| Consolidation | Detailed source → target module migration steps | consolidation/plan.md |
| Improvements | Master phased improvement roadmap | improvements/master-plan.md |
| Testing | Strategy, categories, guard variables | testing/strategy.md |
| Optional Next Steps | CI/CD & automation scaffolds | redesign/planning/optional-next-steps.md |

## 2. Quick Links
- Performance Metrics: `docs/redesign/metrics/`
- Badges (generated): `docs/badges/perf.json`
- Security Registry: `security/plugin-registry/`

## 3. Core Goals (Snapshot)
- ≥20% interactive startup time reduction vs baseline
- Single guarded `compinit` invocation
- Consolidated 11-module redesign structure (00..90 sequence)
- Deferred heavy integrity scanning & performance monitoring post first prompt
- Automated CI: core tests, performance regression, security scan

## 4. Current Status Summary
| Area | Status | Notes |
|------|--------|-------|
| Analysis & Diagrams | Complete | Stored under redesign/planning |
| Implementation Plan | Complete | Phase tasks 1–12 defined |
| CI/CD Workflows | Added (core, perf, security) | Email notification setup pending SMTP secrets |
| Pre-Commit Hook | Added | Enforces perf +/- tests |
| Notifier & Maintenance Scripts | Added | `tools/notify-email.zsh`, `tools/run-nightly-maintenance.zsh` |
| Completion Guard | Implemented | `_COMPINIT_DONE` guard in minimal-completion-init.zsh |
| Git Wrapper Safety | Implemented | `_lazy_gitwrapper` delegates to safe_git |

## 5. Key Guard Variables
| Variable | Purpose |
|----------|---------|
| `_COMPINIT_DONE` | Ensures single compinit execution |
| `_ASYNC_PLUGIN_HASH_STATE` | Tracks asynchronous integrity scan (future) |
| `ZSH_REDESIGN` | Conditional loader flag for redesign directory (future) |

## 6. How to Contribute Changes
1. Create branch per phase or logical task.
2. Write failing test first (design/unit/integration/security/perf).
3. Implement minimal code until test passes.
4. Run pre-commit (auto invoked) – ensure no >5% perf regression.
5. Commit using `type(scope): summary` format; tag at phase boundaries.

## 7. Running Tests
```bash
# All tests
ZSH_DEBUG=1 tests/run-all-tests.zsh

# Performance only
tests/run-all-tests.zsh --perf-only

# Path/env tests only
tests/run-all-tests.zsh --path-only
```

## 8. Performance Badge Generation
Generated nightly by `ci-performance.yml` and locally via:
```bash
tools/generate-perf-badge.zsh --strict
```
Result: `docs/badges/perf.json` (shields.io compatible).

## 9. Upcoming Enhancements
- zcompile pass (conditional) – Phase 11
- Plugin diff alert system – Phase 11
- JSON registry schema validation – Phase 11
- Memory sampling harness – Phase 11/12
- Structure drift guard test – Phase 11

## 10. Support & Escalation
Email notifications configured to: `embrace.s0ul+s-a-c-zsh@gmail.com` (ALERT_EMAIL secret).

## 11. Badges & Status
Local JSON badge outputs (consumed by CI or external tooling):
| Badge | Path | Meaning | Notes |
|-------|------|---------|-------|
| Performance | docs/badges/perf.json | Startup mean + delta vs baseline | Generated nightly / on-demand |
| Structure | docs/badges/structure.json | Module count / expected and drift status | Strict on main branch |
| Summary | docs/badges/summary.json | Aggregated snapshot of all badge messages | Combines perf + structure |

Example shield via shields.io endpoint (requires hosting JSON over HTTPS, e.g., GitHub Pages or raw gist):
```
https://img.shields.io/endpoint?url=<RAW_URL_TO>/docs/badges/perf.json
https://img.shields.io/endpoint?url=<RAW_URL_TO>/docs/badges/structure.json
```

To preview locally:
```bash
cat docs/badges/perf.json | jq .
cat docs/badges/structure.json | jq .
cat docs/badges/summary.json | jq .
```

Promotion Guard Criteria (enforced in CI main branch):
- Structure badge must not be red.
- (Optional future) Performance badge regression >5% blocked.

---
(End documentation index)
