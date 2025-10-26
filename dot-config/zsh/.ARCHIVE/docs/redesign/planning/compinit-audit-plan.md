# Compinit Single-Run Verification Plan
Date: 2025-08-30
Status: Planning (Pre-Implementation)

## 1. Goal
Guarantee exactly one guarded `compinit` execution per interactive startup across BOTH pre-plugin and post-plugin redesign phases, with stable compdump path reuse and no security warnings.

## 2. Scope
- Applies to future `50-completion-history.zsh` (post-plugin) and any helper pre-plugin scaffolding (none planned—compinit deferred until post-plugin).
- Verifies environment variables: `ZGEN_AUTOLOAD_COMPINIT=0`, optional `ZSH_REDESIGN=1` flag once redesign active.

## 3. Guard Pattern
```zsh
if [[ -z ${_COMPINIT_DONE:-} ]]; then
  autoload -U compinit
  compinit -C -d "${ZGEN_CUSTOM_COMPDUMP}" 2>&1 | grep -vi 'insecure' || true
  _COMPINIT_DONE=1
fi
```
- `-C` skips security rehash (weekly full run planned separately).
- Weekly secure refresh (Phase 12): run `compinit -D` or full `compinit` in isolated subshell to rebuild compdump.

## 4. Evidence Collection
| Evidence | Method | Artifact |
|----------|--------|----------|
| Single invocation | Instrument wrapper increments counter | tests/integration/test-compinit-single-run.zsh |
| Compdump existence | `[[ -f $ZGEN_CUSTOM_COMPDUMP ]]` | Integration test output |
| No prompt latency impact | Measure delta w/ & w/o completion file (3-run mean) | perf comparison log |
| No insecure warnings | Capture stderr of guarded compinit call | `compinit-warnings.log` |

## 5. Test Design
### 5.1 Integration Test Pseudocode
```zsh
#!/usr/bin/env zsh
set -euo pipefail
# Source redesign flag (future)
ZSH_REDESIGN=1
# Simulate sourcing sequence (simplified)
source .zshenv
# (Pretend plugin layer complete, then) source completion module twice
source .zshrc.d.REDESIGN/50-completion-history.zsh 2>/dev/null || true
source .zshrc.d.REDESIGN/50-completion-history.zsh 2>/dev/null || true
[[ ${_COMPINIT_DONE:-0} -eq 1 ]] || { echo 'FAIL: guard not set'; exit 1; }
# Ensure not re-run
[[ $(grep -c '^_COMPINIT_DONE=1$' <(typeset -pm _COMPINIT_DONE)) -eq 1 ]] || echo 'WARN: unexpected guard duplication'
[[ -f ${ZGEN_CUSTOM_COMPDUMP} ]] || { echo 'FAIL: compdump missing'; exit 1; }
```

### 5.2 Performance Sanity Check
Quick timing harness (3 runs) before & after enabling completion module; assert delta < 3% (noise threshold). Failing delta implies heavy logic was added incorrectly.

## 6. Failure Modes & Responses
| Failure | Likely Cause | Mitigation |
|---------|--------------|-----------|
| Multiple compinit runs | Missing guard or plugin triggers earlier | Strengthen guard; scan for `compinit` tokens in pre-plugin modules |
| Missing compdump | Wrong path / permission issue | Validate `ZSH_CACHE_DIR` existence early in `.zshenv` |
| Insecure directory warnings | Permissions on fpath entries | Weekly full security run + path hardening script |
| >3% latency increase | Heavy zstyle logic or extra I/O | Defer complex zstyles until after first prompt or lazy-load subset |

## 7. Weekly Secure Refresh Procedure (Optional)
1. Subshell: `(autoload -U compinit; compinit; exit)` capturing any warnings.
2. If warnings appear → log & email alert (Phase 12 maintenance).
3. Replace existing compdump atomically: `mv newdump olddump` only if successful.

## 8. Metrics & Logging
- Add line to performance logs: `COMPINIT: <ms>` (elapsed time measurement in completion module for instrumentation window).
- Collect into `docs/redesign/metrics/compinit-history.log` (append-only).

## 9. Entry Criteria Dependency
Implementation of this plan is a prerequisite for Promotion Phase sign-off; design test must exist even if redesign modules not yet populated.

## 10. Approval
Frozen when: integration test merged + design test referencing guard variable present.

---
**Navigation:** [← Previous: Baseline Metrics Plan](baseline-metrics-plan.md) | [Next: Implementation Entry Criteria →](implementation-entry-criteria.md) | [Top](#) | [Back to Index](../README.md)

---
(End compinit audit plan)
