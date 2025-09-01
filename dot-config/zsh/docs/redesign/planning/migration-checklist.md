# Migration Execution Checklist
Date: 2025-08-30
Status: Draft (Becomes READ-ONLY after Promotion Tag)

Purpose: A single actionable, linear list to execute the redesign migration safely (pre-plugin + post-plugin) with validation and rollback points.

Legend: (M) Mandatory gate  (I) Informational  (R) Rollback point  (⚠) Abort if fails

## Phase 1 – Baseline & Inventory
1. (M) Capture baseline startup metrics (10 runs, discard warm run) → docs/redesign/metrics/perf-baseline.json
2. (M) Verify stddev <= 12% of mean (else recollect once)
3. (M) Snapshot active post-plugin structure: run tools/generate-structure-audit.zsh → commit structure-audit.json/md
4. (M) Record pre-plugin file inventory → docs/redesign/planning/preplugin-inventory.txt
5. (I) Optional quick perf (3-run) store raw in docs/redesign/metrics/perf-quick-baseline.txt
6. (M) Tag refactor-baseline

## Phase 2 – Backup & Safety
7. (M) Copy .zshrc.d → .zshrc.d.backup-<timestamp>
8. (M) chmod -R a-w .zshrc.d.backup-* (immutable)
9. (M) Confirm diff -rq original vs backup = 0 (⚠ Abort if mismatch)
10. (M) Commit backup & backup SHA256 manifest (optional) → docs/redesign/metrics/backup.SHA256

## Phase 3 – Pre-Plugin Skeleton
11. (M) Create .zshrc.pre-plugins.d.redesigned with guarded empty files (00,05,10,15,20,25,30,40)
12. (M) Add design test (allow legacy + skeleton) – test-preplugins-structure.zsh (RED→GREEN)
13. (M) Commit skeleton (feat(preplugins): skeleton)

## Phase 4 – Pre-Plugin Migration
14. (M) Merge path safety files → 00-path-safety.zsh (idempotent)
15. (M) Move fzf init → 05-fzf-init.zsh (no install logic)
16. (M) Add lazy framework helpers → 10-lazy-framework.zsh
17. (M) Introduce nvm/npm/bun stubs (no sourcing) → 15-node-runtime-env.zsh
18. (M) Consolidate direnv/git/copilot wrappers → 25-lazy-integrations.zsh
19. (M) Merge SSH agent core/security → 30-ssh-agent.zsh (skip if agent active)
20. (M) Add test-preplugins-no-compinit.zsh (ensure zero compinit) (RED→GREEN)
21. (R) Pre-plugin rollback: remove redesigned dir; restore baseline measure (optional)

## Phase 5 – Pre-Plugin Timing Baseline
22. (M) Instrument pre-plugin timing (temp patch or wrapper) → preplugin-baseline.json
23. (M) Commit timing artifact
24. (M) Update perf-baseline with pre_plugin_time_ms (if schema extended)

## Phase 6 – Post-Plugin Skeleton
25. (M) Create .zshrc.d.REDESIGN with empty guarded files (00..90) – 11 modules
26. (M) Add design test test-structure-modules.zsh (RED→GREEN)
27. (M) Commit skeleton

## Phase 7 – Post-Plugin Phase 1 (Core)
28. (M) Implement 00-security-integrity (stub only; no hashing)
29. (M) Implement 05-interactive-options (migrate options) & test sampling
30. (M) Merge functions into 10-core-functions + duplicate symbol audit
31. (M) Unit tests for helper functions pass
32. (R) Rollback: restore old .zshrc.d; unset ZSH_REDESIGN

## Phase 8 – Post-Plugin Phase 2 (Features)
33. (M) Implement 20-essential-plugins (idempotent ensure)
34. (M) Implement 30-development-env (toolchain, SSH NOT duplicated)
35. (M) Implement 40-aliases-keybindings (alias parity diff script PASS)
36. (M) Implement 50-completion-history (guarded compinit)
37. (M) Implement 60-ui-prompt (prompt parity & fallback test)
38. (M) Integration: compinit-single-run test GREEN
39. (R) Rollback: revert commits since phase 7

## Phase 9 – Deferred & Async
40. (M) Implement 70-performance-monitoring (precmd hook, no blocking)
41. (M) Implement 80-security-validation (queued hash scan, state var)
42. (M) Add deferred hashing test – ensures no deep hash pre first prompt
43. (M) Add async non-blocking test – time delta within noise threshold
44. (R) Rollback: remove 70/80 modules, keep earlier phases

## Phase 10 – Splash & Summary
45. (M) Implement 90-splash (perf delta + integrity status when available)
46. (I) Cosmetic review (colors/emojis minimal overhead)

## Phase 11 – Validation & Benchmark
47. (M) Run 10-run redesign benchmark → perf-current.json
48. (M) Compute improvement: (baseline_mean - redesign_mean)/baseline_mean ≥ 0.20 (⚠ Abort if < 0.20)
49. (M) Ensure regression vs baseline <5% for any subsequent commit; perf threshold test updated
50. (M) Update badges (perf, summary) – green/yellow only (⚠ Red abort)

## Phase 12 – Promotion
51. (M) Dry run tools/dry-run-promotion-check.zsh (expect OK)
52. (M) Rename existing .zshrc.d → .zshrc.d.legacy-final
53. (M) Move .zshrc.d.REDESIGN → .zshrc.d
54. (M) Set ZSH_REDESIGN=0 (or remove conditional) in .zshrc
55. (M) Commit & tag refactor-promotion
56. (R) Full rollback: rename legacy-final back; reset tag if required

## Phase 13 – Documentation Finalization
57. (M) Update final-report.md with actual improvement numbers
58. (M) Update README indices & maintenance guidance
59. (M) Commit diff report (legacy vs redesign) diff-report-<timestamp>.txt

## Phase 14 – CI/CD & Enhancements
60. (M) Ensure ci-core, ci-performance, ci-security workflows green
61. (M) Add structure drift test (fail new untracked modules)
62. (I) Introduce zcompile pass (A/B test – optional)
63. (I) Add plugin diff alert & schema validation

## Phase 15 – Maintenance Enablement
64. (M) Configure nightly perf capture (cron / GH workflow)
65. (M) Configure weekly security scan + compdump refresh
66. (I) Add monthly log rotation and summary aggregator

## Phase 16 – Freeze & Archive
67. (M) Mark planning docs READ-ONLY (update status) & add freeze commit `docs(plan): freeze redesign`
68. (M) Record final metrics snapshot → metrics/final-metrics-<date>.json
69. (I) Optionally delete superseded legacy directory after 2 stable weeks

## Quick Rollback Reference
| Rollback Point | Command Summary |
|----------------|-----------------|
| Pre-Plugin Only | rm -rf .zshrc.pre-plugins.d.redesigned; restore baseline branch |
| Post Phase 1 | git revert / reset to tag refactor-baseline; restore backup dir |
| After Async | Remove 70/80; toggle STRICT flags off |
| After Promotion | Restore .zshrc.d.legacy-final; unset loader flag; git reset --hard refactor-baseline |

## Verification Matrix Snapshot
| Gate | Artifact | Test Name | Status (fill) |
|------|----------|-----------|---------------|
| Baseline Perf | perf-baseline.json | test-perf-baseline-parse |  |
| Pre-Plugin No Compinit | trace log | test-preplugins-no-compinit |  |
| Structure Skeleton | structure-audit.json | test-structure-modules |  |
| Single Compinit | compdump + guard | test-compinit-single-run |  |
| Deferred Hashing | timing log | test-integrity-deferred |  |
| Perf Threshold | perf-current.json | test-perf-threshold |  |

---
**Navigation:** [← Previous: Master Plan](master-plan.md) | [Next: Prefix Reorg Spec →](prefix-reorg-spec.md) | [Top](#) | [Back to Index](../README.md)

---
(End migration execution checklist)
