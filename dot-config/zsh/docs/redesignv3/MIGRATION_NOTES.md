# Migration Notes (v2 → v3)

This document captures the deltas from redesign v2 and aligns the current implementation with Stage 3 completion requirements. It cites v2 artifacts and organizes next steps for a clean v3 rollout.

## References to v2
- Read: `../redesignv2/README.md`, `ARCHITECTURE.md`, `REFERENCE.md`
- Status: `../redesignv2/STAGE3_STATUS_ASSESSMENT.md`, `tracking/STAGE3_COMPLETION_SUMMARY.md`
- Testing: `../redesignv2/ZSH_TESTING_STANDARDS.md`, `testing/TEST_IMPROVEMENT_PLAN.md`
- Async & risk: `../redesignv2/RISK-ASYNC-PLAN.md`

## Deltas Observed in Code
- `.zshenv` now provides more robust PATH/bootstrap helpers and localizes zgenom to ZDOTDIR when available
- `.zshrc` has ZDOTDIR-aware settings system and loader; still requires hardening of `load-shell-fragments`
- `.zgen-setup` respects `.zshenv`-controlled paths; avoids changing ZGEN_DIR inside `.zgen-setup`
- Pre-/post-plugin directories are clearly organized; POSTPLUGIN includes security/interactive/core functions logical grouping

## Stage 3 Alignment Summary
- Foundation (XDG, ZDOTDIR consistency): Complete; v3 codifies the rules
- Pre-plugin redesign: Present; ensure all pre-plugins assume no plugins
- Core (plugin manager, plugin list, cache rebuild policy): Present; keep rebuild checks deterministic and portable
- Post-plugin consolidation: Present; ensure idempotence and gating for interactive only
- Observability & troubleshooting: Add `SAFE_MODE` fast path and `zqs doctor`

## Migration Recommendations
1) Harden Loader Semantics
   - Implement strict file filtering in loader as outlined in IMPROVEMENTS.md
   - Adopt quarantine directory `.zshrc.d.disabled/` convention (already in use operationally)

2) Replace External Dependencies in Hot Paths
   - `_zqs-get-setting` → use built-ins to remove `cat`
   - Update math in update-check to remove `expr`; prefer arithmetic & `$EPOCHSECONDS`

3) Normalize PATH Policy
   - `.zshenv` is source of truth; `.zshrc` appends only when necessary
   - Deduplicate once at end of `.zshrc` (retained) and avoid more string scans

4) Add Diagnostics & Safe Mode
   - `zqs doctor` reports PATH/fpath/compinit/settings dir health
   - `SAFE_MODE=1` loads minimal modules to quickly isolate issues

5) Testing & Validation
   - Add smoke scripts under `docs/redesignv2/testing/` or new v3 testing dir
   - Validate compinit cache behavior, zgenom init rebuild triggers, and settings operations

## Rollout Plan (Incremental)
- Phase 1: Implement loader filter + setting IO built-ins; add minimal `zqs doctor`
- Phase 2: Normalize PATH; add SAFE_MODE gating in pre-/post-plugins
- Phase 3: Replace external `stat/date/expr` with zsh modules or `$EPOCHSECONDS`; add portable tests
- Phase 4: Documentation updates; declare Stage 3 completion and archive v2 status

