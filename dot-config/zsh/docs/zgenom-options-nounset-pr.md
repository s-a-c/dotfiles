# PR: Make zgenom options.zsh nounset-resilient (setopt -u)

## Summary
This document tracks the upstream PR preparation to harden `zgenom`'s `options.zsh` against `setopt -u` (nounset) without changing behavior in normal environments.

- Repo: https://github.com/jandamm/zgenom
- Local clone used: `$ZDOTDIR/.zqs-zgenom` (fresh clone)
- Target file: `.zqs-zgenom/options.zsh`
- Branch name: `fix/nounset-resilience-options`
- Goal: Avoid all “parameter not set” failures if nounset is accidentally enabled during zgenom save/init.

## Why this change
Several patterns in the original `options.zsh` expand variables that may be unset during early init phases. With `setopt -u` in effect, those expansions cause hard errors:
- Numeric compares on unset variables
- `[[ -z "${VAR}" ]]` checks that expand unset variables
- Use of `${(t)_comps}` to detect `compinit` having run
- Derived defaults that reference possibly-unset parents
- Arrays/scalars accessed before being initialized

## What changed (techniques)
No functional behavior change; only parameter expansion safety.

- Numeric compares use arithmetic defaults:
  - Before: `[[ $ZGENOM_AUTO_ADD_BIN -eq 1 ]]`
  - After:  `(( ${ZGENOM_AUTO_ADD_BIN:-0} == 1 ))`

- Empty/existence checks avoid expanding unset:
  - Before: `[[ -z "${VAR}" ]]`
  - After:  `[[ -z ${VAR-} ]]` or `(( ${+VAR} == 0 ))`

- Compinit detection uses existence test instead of type expansion:
  - Before: `[[ -z "${(t)_comps}" ]]`
  - After:  `(( ${+_comps} == 0 ))`

- Defaults/derived values guarded without expanding parents:
  - Example: `: ${ZGEN_CUSTOM_COMPDUMP:=${ZGEN_DIR}/zcompdump_${ZSH_VERSION}}` (only when `ZGEN_DIR` is set)

- Initialize arrays/scalars with safe idioms:
  - `: ${ARR:=()}`
  - `: ${SCALAR:=default}`

- Preserve quoting semantics where the original used `${(q)...}` when building flags.

## Patch highlights (excerpts)
```zsh
# Numeric compare (nounset-safe)
if (( ${ZGENOM_AUTO_ADD_BIN:-0} == 1 )); then
  export PMSPEC=0fbiPs
else
  export PMSPEC=0fiPs
  ZGENOM_AUTO_ADD_BIN=0
fi

# Guarded defaults without expanding unset parents
[[ -z ${ZPFX-} && -n ${ZGEN_SOURCE-} ]] && export ZPFX="${ZGEN_SOURCE}/polaris"
[[ -z ${ZGENOM_SOURCE_BIN-} && -n ${ZGEN_SOURCE-} ]] && ZGENOM_SOURCE_BIN="${ZGEN_SOURCE}/bin"

# compinit auto-load decision
if (( ${+ZGEN_AUTOLOAD_COMPINIT} == 0 )) && (( ${+_comps} == 0 )); then
  ZGEN_AUTOLOAD_COMPINIT=1
fi

# compdump path guarded
if (( ${+ZGEN_CUSTOM_COMPDUMP} == 0 )) && (( ${+ZGEN_DIR} )); then
  ZGEN_CUSTOM_COMPDUMP="${ZGEN_DIR}/zcompdump_${ZSH_VERSION}"
fi
[[ -n ${ZGEN_CUSTOM_COMPDUMP-} ]] && ZGEN_COMPINIT_DIR_FLAG="-d ${(q)ZGEN_CUSTOM_COMPDUMP}"
ZGEN_COMPINIT_FLAGS="${ZGEN_COMPINIT_DIR_FLAG-} ${ZGEN_COMPINIT_FLAGS-}"

# Arrays/scalars initialized safely
: ${ZGEN_LOADED:=()}
: ${ZGENOM_LOADED:=()}
: ${ZGENOM_PLUGINS:=()}
(( ${+zsh_loaded_plugins} )) || typeset -ga zsh_loaded_plugins
: ${ZGEN_PREZTO_OPTIONS:=()}
: ${ZGEN_PREZTO_LOAD:=()}
: ${ZGEN_COMPLETIONS:=()}
: ${ZGEN_USE_PREZTO:=0}
: ${ZGEN_PREZTO_LOAD_DEFAULT:=1}
: ${ZGEN_OH_MY_ZSH_REPO:=ohmyzsh/ohmyzsh}
[[ ${ZGEN_OH_MY_ZSH_REPO-} != */* ]] && ZGEN_OH_MY_ZSH_REPO="${ZGEN_OH_MY_ZSH_REPO}/oh-my-zsh"
: ${ZGEN_PREZTO_REPO:=sorin-ionescu}
[[ ${ZGEN_PREZTO_REPO-} != */* ]] && ZGEN_PREZTO_REPO="${ZGEN_PREZTO_REPO}/prezto"
```

## How to test locally (zsh startup)
Use both a forced zgenom regeneration and a normal startup. Look for any “parameter not set” or aborts.

1) Force a fresh zgenom cache and start interactive shell:
```sh
ZDOTDIR="$HOME/dotfiles/dot-config/zsh" ZSH_FORCE_ZGEN_RESET=1 zsh -i
```

2) Normal startup (cached):
```sh
ZDOTDIR="$HOME/dotfiles/dot-config/zsh" zsh -i
```

3) Quick sanity checks during startup:
- No `parameter not set` messages from `options.zsh`
- Prompt appears as normal; plugins load; completions work

4) Optional: grep logs or console output for errors:
```sh
# If you log startup, check for errors
grep -i "parameter not set\|nounset" "$HOME/dotfiles/dot-config/zsh/logs"/* 2>/dev/null || true
```

Note: We do not purposely force `set -u` globally during init; the goal is resilience if a user enables it in their environment.

## Upstream PR steps
Using GitHub CLI (newer versions don’t have `--yes` for `gh repo fork`):

```sh
cd "$HOME/dotfiles/dot-config/zsh/.zqs-zgenom"
# Create branch and commit (if not yet committed)
git checkout -b fix/nounset-resilience-options
git add options.zsh
git commit -m "options.zsh: make nounset-resilient (setopt -u)

- Use arithmetic defaults for numeric tests
- Avoid expanding unset vars: \${var-} and \${+var}
- Replace \${(t)_comps} with existence check on _comps
- Guard derived defaults and flags; keep quoting where needed
- Initialize arrays/scalars via : \${var:=...}

No behavior change under normal conditions; improves robustness when set -u is in effect."

# Fork and add remote
gh repo fork --remote --remote-name fork
# If the fork already exists, add it manually:
# git remote add fork git@github.com:<your-user>/zgenom.git

# Push branch to your fork
git push -u fork fix/nounset-resilience-options

# Create PR against upstream
gh pr create --repo jandamm/zgenom --base main --head <your-user>:fix/nounset-resilience-options \
  --title "Make options.zsh nounset-resilient (setopt -u)" \
  --body "Harden options.zsh against setopt -u without changing behavior. Avoid expanding unset vars, use arithmetic defaults, guard compinit detection, and initialize arrays/scalars safely."
```

If not using `gh`, open the compare URL in a browser:
```
https://github.com/jandamm/zgenom/compare/main...<your-user>:fix/nounset-resilience-options?expand=1
```

## Compatibility and risk
- Behavior unchanged when variables are set as usual
- Purely defensive parameter/array initialization
- Preserves original quoting and semantics
- Low risk; improves robustness for stricter user environments

## Status
- Local patch staged in `.zqs-zgenom/options.zsh`
- Ready to push a branch and open the upstream PR

