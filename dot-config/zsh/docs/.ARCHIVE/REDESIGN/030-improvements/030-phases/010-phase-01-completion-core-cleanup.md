# Phase 01: Completion Core Cleanup (❗ P0 / ▲ P1 Aggregate)

Return: [Index](../../README.md) | Prev: *N/A* | Next: [Phase 02 Styling Extraction](020-phase-02-styling-modularization-extraction.md)

Goal: Eliminate duplicate `compinit` executions, standardize compdump path, remove fallback logic scaffolding for stable single-pass completion initialization.

## 1. Hierarchical Task Breakdown
| Level 1 (Epic) | Level 2 (Task) | Level 3 (Subtasks, ≤3 deep) | Effort | Impact | Status |
|----------------|----------------|-----------------------------|--------|--------|--------|
| Single `compinit` | Remove early init file | Stub `01-completion-init.zsh` → log deprecation → delete in Phase 03 | ⚡ | 🚀 | ⬜ |
|  | Gate tool fallback | Edit `10_17-completion.zsh` remove `compinit`; retain style zstyles only | ⚡ | 🚀 | ⬜ |
|  | Centralize dump path | Align `.zshenv` `ZSH_COMPDUMP` to manager path; export consistent var | ⚡ | 🧹 | ⬜ |
| Rebuild tooling hygiene | Refactor rebuild script | Make `tools/rebuild-completions.zsh` call `rebuild-completions` fn if loaded | ⚡ | 🧹 | ⬜ |
|  | Add idempotency guard | Ensure function detects active centralized manager before run | 🕒 | 🧹 | ⬜ |
| Cleanup old artifacts | Whitelist canonical dump | Add whitelist var; avoid deleting active file | ⚡ | 🔧 | ⬜ |
|  | Surface cleanup report | Add summary of removed files to stderr (debug) | ⚡ | 🧹 | ⬜ |
| Test scaffolding | Write single-compinit test | Fails before changes; passes after removal | ⚡ | 🚀 | ⬜ |
|  | Write compdump age test | Touch aged dump; assert rebuild; fresh skip | 🕒 | 🚀 | ⬜ |
|  | Lock contention test | Parallel spawn 2 shells; ensure one rebuild | ⏳ | 🔧 | ⬜ |

## 2. TDD Plan
| Test File (Planned) | Purpose | Pre-State (Fail) | Post-State (Pass Criteria) |
|---------------------|---------|------------------|---------------------------|
| tests/completion/test-single-compinit.zsh | Exactly one compinit | 2–3 matches | 1 match |
| tests/completion/test-rebuild-heuristics.zsh | Age vs skip logic | Rebuild always | Conditional rebuild |
| tests/completion/test-lock-contention.zsh | Concurrency safety | Possible race / double | Single rebuild; both succeed |

## 3. Implementation Sequence (Micro Commits)
| Seq | Action | Commit Msg (Git / jj) | Notes |
|-----|--------|-----------------------|-------|
| 1 | Create failing tests | `feat(tests): add failing completion single-compinit and rebuild heuristic tests` | Run to confirm red |
| 2 | Stub early file | `refactor(completion): stub early 01-completion-init with deprecation notice` | Keep return early |
| 3 | Remove fallback compinit | `refactor(completion): strip compinit fallback from 17-completion.zsh` | Preserve minimal styles |
| 4 | Align compdump path | `chore(completion): unify ZSH_COMPDUMP path in .zshenv + manager` | No behavior change expected |
| 5 | Update rebuild tool | `refactor(completion): make rebuild-completions tool delegate to function` | Add guard |
| 6 | Whitelist cleanup | `feat(completion): add compdump whitelist + cleanup report` | Debug output gated |
| 7 | Enhance lock logic test | `test(completion): parallel shell lock contention test added` | Concurrency coverage |
| 8 | Remove deprecated early file | `chore(completion): remove deprecated 01-completion-init.zsh` | After green tests |
| 9 | Final snapshot & docs | `docs(completion): update completion-system architecture post cleanup` | Close phase |

### Example jj (colocated) Flow
```bash
# Create branch
jj branch create phase01-completion

# After each micro commit using git
git add .
git commit -m "refactor(completion): stub early 01-completion-init with deprecation notice"
# Import commit into jj (if colocated auto-tracking: jj git import)
jj describe -m "refactor(completion): stub early 01-completion-init with deprecation notice"

# Amend if test fix needed
jj squash -r @ -m "refactor(completion): stub early init (deprecation log)"
```

## 4. Rollback Strategy
| Failure Point | Symptom | Rollback Step |
|---------------|---------|---------------|
| Fallback removal breaks plugin expecting compinit | Missing completion functions | Revert commit 3; add transitional autoload stub |
| Path unify introduces missing dump | No dump file created | Restore previous `ZSH_COMPDUMP` export from reflog |
| Cleanup whitelist misconfigured | Active dump removed | Disable cleanup env flag; restore from backup |

## 5. Metrics to Capture
| Metric | Tool | Baseline | Target |
|--------|------|----------|--------|
| Cold startup ms | `zsh-profile-startup` | Capture pre-phase | -80 to -120 ms |
| Compinit count | Trace grep | 2–3 | 1 |
| Rebuild frequency | Test harness | Always | Conditional |

## 6. Documentation Updates
| Doc | Change |
|-----|--------|
| architecture/completion-system.md | Remove early path references; add unified path note |
| [Improvement Plan](../010-comprehensive-improvement-plan.md) | Mark tasks TASK-CRIT-01,03,05 progress |
| testing/strategy.md | Add new test files and assertions |

## 7. Exit Checklist
- [ ] All new tests GREEN
- [ ] Single compinit verified across 3 consecutive runs
- [ ] Legacy early file removed
- [ ] Docs updated & cross links added
- [ ] Metrics recorded in logs/phase-metrics.log

## 8. Appendix A – Test Skeletons
```bash
# tests/completion/test-single-compinit.zsh (skeleton)
#!/usr/bin/env zsh
set -euo pipefail
<<<<<<< HEAD
TRACE_FILE=${TMPDIR:-/tmp}/compinit-trace.$$
=======
TRACE_FILE=${TMPDIR:-/tmp}/compinit-trace.$$ 
>>>>>>> origin/develop
PS4='+TRACE+ %N:%i ' ZDOTDIR="$HOME/.config/zsh" zsh -xic 'echo READY' &> $TRACE_FILE || true
grep -c 'compinit' $TRACE_FILE | read COUNT
if [[ $COUNT -ne 1 ]]; then
echo "FAIL expected 1 compinit got $COUNT" >&2; exit 1; fi
echo "PASS single compinit"
```

```bash
# tests/completion/test-rebuild-heuristics.zsh (skeleton)
#!/usr/bin/env zsh
set -euo pipefail
DUMP="$HOME/.config/zsh/.completions/zcompdump"
[[ -f $DUMP ]] || {     zsh_debug_echo "No dump found"; exit 1; }
# Force age
perl -e 'utime time-86400*8, time-86400*8, @ARGV' $DUMP
ZDOTDIR="$HOME/.config/zsh" zsh -ic 'echo INIT' >/dev/null 2>&1
# Expect rebuild log marker (implement marker in manager if absent)
```

## 9. Appendix B – Commit Message Template
```text
<type>(completion): <concise imperative summary>

Context:
- Problem:
- Change:
- Impact:

Refs: TASK-CRIT-01
BREAKING: <optional>
```

---
Generated: 2025-08-24
