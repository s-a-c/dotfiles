# Improvement Recommendations (v3)

Prioritized recommendations across correctness, resilience, maintainability, performance, and ZSH-native efficiency. Recommendations reference current code and build on `../redesignv2/*` artifacts (e.g., STAGE3 status and testing standards).

## 1) Logical Consistency & Safety

- Harden the loader: `load-shell-fragments` currently sources every readable file in a directory via `ls -A` iteration. This is brittle and risky.
  - Change to a glob-based filter, source only regular `*.zsh` files, numerically sorted, skipping backup/disabled: `for f in $1/*.zsh(N-.L) ; do source $f ; done`
  - Explicitly ignore `*.disabled`, `*.bak`, dotfiles, and non-regular files. Consider a `.disabled.d/` or sibling directory convention for quarantine.
- Settings: `_zqs-get-setting` uses `cat`. Prefer `read -r` or `mapfile` (zmodload zsh/mapfile) to avoid external process and reduce failure modes.
- Update helpers: `_load-lastupdate-from-file` & `_check-for-zsh-quickstart-update` use `expr`/`date`. Prefer arithmetic with `$EPOCHSECONDS` or zsh/time module for portability.
- Ensure fragments are idempotent and side-effect safe; avoid naked calls to `main`-style functions inside fragments.
- Consolidate PATH manipulation: `.zshenv` sets a robust baseline and dedupes early; `.zshrc` again appends/dedupes. Define a single policy and make `.zshrc` additive only where strictly necessary.

## 2) Race Condition Prevention

- zgenom rebuild triggers: ensure `setup-zgen-repos` runs only when inputs change; current timestamp checks are good but avoid directory timestamp reliance on macOS (disabled already).
- Defer heavy plugin init behind explicit gates (e.g., only in interactive shells). Use `$-` to detect interactive sessions and avoid loading expensive pieces in batch shells.
- Ensure completion initialization (`compinit`) is executed once with consistent `$fpath`; do not auto-run when debugging `compinit` issues (`ZGEN_AUTOLOAD_COMPINIT=0` already helps during debug).

## 3) Resilience & Error Handling

- Settings directory bootstrap: if `_ZQS_SETTINGS_DIR` is unwritable or missing, print actionable warnings and continue with defaults.
- SSH agent helpers: guard all external calls with `command -v` checks (already partially implemented); avoid noisy failures.
- iTerm and OS-specific fragments: source only if present; log minimal warnings (currently done) and avoid hard failures.
- Provide a `SAFE_MODE`/`MINIMAL_MODE` env flag to skip optional/expensive fragments during troubleshooting.

## 4) Maintainability & Modularity

- Naming Convention: Adopt `NN_MM-topic.zsh` with concise, unique topic names. Avoid over-segmentation that makes mental model hard; group related responsibilities.
- Documentation in-code: Top-of-file headers summarizing module responsibilities and assumptions; include preconditions (e.g., expects PATH helpers from .zshenv).
- Public vs private: Document public interfaces (helpers, settings functions) and keep private/loader internals unexported.
- Tests: Add minimal shellcheck-style and runtime smoke tests for critical helpers (PATH helpers, settings operations). Use v2's `ZSH_TESTING_STANDARDS.md` as a base.

## 5) Performance

- Replace external processes with built-ins where feasible:
  - `_zqs-get-setting`: use `read -r` instead of `cat`
  - Update math: use arithmetic expansion instead of `expr`
  - `date` usage: prefer `$EPOCHSECONDS` or `strftime` from zmodload zsh/datetime
- Use arrays and `typeset -aU path` consistently instead of string scans when managing PATH (already done at end of `.zshrc`).
- Avoid unnecessary subshells; where subshell isolation is used (e.g., `resolve_script_dir`), keep it minimal.

## 6) ZSH-Native Efficiency

- Glob qualifiers for loader (see 1): `*.zsh(N-.L)` is fast and robust.
- Use `zstat` (from `zmodload zsh/stat`) for file timestamps over external `stat` to remove platform conditionals.
- Prefer `print -r --` over `echo` when printing arbitrary values (avoids escape surprises).
- For settings, consider `zmodload zsh/mapfile` and `zparseopts` to simplify parsing and IO.

## 7) Operational Controls & Observability

- Standardize `ZSH_DEBUG=1` behavior across modules to emit to `$ZSH_DEBUG_LOG`.
- Provide a `zqs doctor` command to validate environment: presence of core tools, PATH sanity, fpath, compdump, settings dir health.
- Add minimal `zqs --version` and `zqs env` for diagnostics.

## 8) Loader Contract (Proposed)

- Pre-plugins: must not assume plugins present; can assume `.zshenv` helpers exist.
- Post-plugins: may assume plugins and zgenom init are loaded; must remain idempotent and fast.
- Fragments must not call `exit` or long-running commands. Any deferred work should be gated by interaction (`$-` contains `i`).

## 9) Safe-by-Default Defaults

- Keep `ZGEN_AUTOLOAD_COMPINIT=0` during active debugging; document how to re-enable for production use once stabilized.
- Optional features default on only when their dependencies are present; otherwise remain silent.

## Quick Wins Checklist

- [ ] Update `load-shell-fragments` to filter by `*.zsh(N-.L)` and skip known-disabled patterns
- [ ] Replace `cat/expr/date` in frequently-run helpers with built-ins
- [ ] Introduce `zqs doctor` (sanity checks) and `SAFE_MODE=1` fast path
- [ ] Normalize PATH policy (source of truth in `.zshenv`; `.zshrc` additive only)
- [ ] Emit consistent debug logs when `ZSH_DEBUG=1`

