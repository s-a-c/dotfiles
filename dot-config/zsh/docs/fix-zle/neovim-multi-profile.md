# Neovim Multi-Profile Environment (Phase 5 Completion)

This document records the finalized design, edge‑case handling, and validation steps for the Phase 5 Neovim ecosystem module: `340-neovim-environment.zsh`.

## Objectives

- Provide sane editor defaults (`EDITOR`, `VISUAL`, `GIT_EDITOR` → `nvim`).
- Expose profile aliases ONLY when the underlying config directory exists (avoid accidental creation of empty profile trees).
- Offer a generic `nvprofile <Name>` dispatcher without polluting the namespace with speculative aliases.
- Integrate Lazyman + Bob conditionally without imposing a hard dependency.
- Maintain ZLE widget stability (no new widgets; baseline unchanged ≥ 387 / post‑Phase 4 ≥ 400).

## Profile Strategy

Reserved / Recognized profiles (directory names under `$XDG_CONFIG_HOME`):

- `nvim-Lazyman` → alias `lmvim`
- `nvim-Kickstart` → alias `ksnvim`
- `nvim-Lazyvim` → alias `lznvim`
- `nvim-Mini` → alias `minvim`
- `nvim-NvChad` → alias `nvnvim`

Each alias is ONLY defined when its directory exists. This prevents a user from assuming a profile exists and triggering unwanted scaffolding.

## Generic Dispatcher

`nvprofile <Tail> [args...]` → resolves to `NVIM_APPNAME=nvim-<Tail> nvim [args...]` if (and only if) `$XDG_CONFIG_HOME/nvim-<Tail>` exists.

Benefits:

- Low alias surface area.
- Easy exploration: `nvprofile Lazyman :checkhealth`.
- Predictable failure path (exit 1 with diagnostic message) if profile absent.

## Lazyman Integration

If readable:

- `.lazymanrc` is sourced.
- `.nvimsbind` is sourced with a temporary harmless `bind` shim if `bind` is not available (prevents errors in pure zsh context). The shim is always removed afterward—no leakage into user session.

## Bob Integration

If Bob path exists: prepend its directory to `PATH`. No hard dependency—absence is a no‑op.

## Nounset & Safety

- All variable references guarded (`${var:-}`) or locally assigned.
- Functions prefixed with `zf::` except intentional user command `nvprofile`.
- Module ends implicitly with success (no non‑zero stray exit codes introduced).

## Edge Cases & Handling

| Situation | Behavior |
|-----------|----------|
| Profile directory missing | Alias not created; `nvprofile` emits diagnostic & return 1 |
| Lazyman present, missing `.nvimsbind` | Only `.lazymanrc` sourced |
| `.nvimsbind` requires `bind` | Temporary shim ensures safe sourcing then removed |
| Bob installed but config missing | Only PATH updated; config var not set |
| User sets `ZF_DISABLE_NVIM=1` | Entire module short-circuits (no exports/aliases) |

## Validation Steps

1. Source redesign modules in a clean subshell and list targeted aliases:

   ```bash
   for a in lmvim ksnvim lznvim minvim nvnvim; do alias "$a" 2>/dev/null || echo "(missing) $a"; done
   ```

2. Dispatcher check (existing profile): `nvprofile Lazyman -c ':q'` (exit 0 expected).
3. Dispatcher negative check (absent profile): `nvprofile DOES_NOT_EXIST` (exit 1 + message).
4. Ensure environment defaults:

   ```bash
   echo $EDITOR $VISUAL $GIT_EDITOR | tr ' ' '\n' | sort -u  # should output only nvim
   ```

5. Widget stability (should match Phase 4 baseline ≥ 400):

   ```bash
   zle -la | wc -l
   ```

## Observed Results (2025-09-30)

- All existing profile aliases resolved (no unexpected missing ones in test environment).
- `nvprofile` returned success for Lazyman test, failure path for bogus profile worked.
- No persistent `bind` shim after sourcing.
- Widget count unchanged from prior phase (reported 407 in Phase 4 harness → stable).

## Completion Criteria Met

- Editor variables exported.
- Conditional alias creation verified.
- Generic dispatcher functioning with clear diagnostics.
- No ZLE or performance regressions introduced.

Status: Phase 5 requirements satisfied. This document finalizes Phase 5.
