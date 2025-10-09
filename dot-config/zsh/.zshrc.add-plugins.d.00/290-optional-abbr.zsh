#!/usr/bin/env zsh
# 190-optional-abbr.zsh - Optional Abbreviation Expansion (olets/zsh-abbr)
# Phase 7 (Optional Enhancements)
#
# Purpose:
#   Integrate the zsh-abbr plugin (if available) in an idempotent, nounset-safe
#   manner, providing a modern abbreviation system without impacting core shell
#   stability or startup when absent.
#
# Features:
#   - Safe early environment variable exports controlling plugin behavior
#   - Dual load strategy:
#       (a) Preferred: zgenom managed (if function present)
#       (b) Fallback: manual source from discovered plugin path
#   - Marker variables for diagnostics & smoke tests
#   - No-op if explicitly disabled by user (ZF_DISABLE_ABBR=1)
#
# Environment / Toggle Variables:
#   ZF_DISABLE_ABBR=1            -> Skip all abbreviation setup
#   ZF_ABBR_DEBUG=1              -> Force ABBR_DEBUG=1 (verbose plugin logging)
#   ZF_ABBR_NO_DEFAULT_BINDS=1   -> Suppress default key bindings
#
# Marker Variables (exported):
#   _ZF_ABBR_DONE=1              -> This module has been processed
#   _ZF_ABBR=1|0                 -> Abbreviation system loaded (1) or not (0)
#   _ZF_ABBR_MODE=managed|manual -> Load path (if loaded)
#
# Nounset Safety:
#   All variable references guarded with ${var:-}; no unbound parameter errors
#
# Idempotency:
#   Re-sourcing is a no-op (guard sentinel). Uses only additive exports/aliases.
#
# Reference:
#   Legacy configuration details captured from historical plugin integration blocks
#   (see: legacy disabled plugin environment modules).
#
# Validation (Manual):
#   1) Run: `typeset -f abbr >/dev/null && echo OK`
#   2) Create a test abbreviation: `abbr -g hw='echo hello world'`
#      Then type: hw<SPACE> -> should expand.
#
# -----------------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_ABBR_DONE:-} ]] && return 0

# Optional global disable
if [[ "${ZF_DISABLE_ABBR:-0}" == 1 ]]; then
  _ZF_ABBR=0
  _ZF_ABBR_DONE=1
  return 0
fi

# Provide minimal debug helper if not already defined
# zf::debug is now globally available from .zshenv.00

zf::debug "# [abbr] initializing optional abbreviation module"

# Default behavior environment (only set if unset to allow user overrides)
: "${ABBR_AUTOLOAD:=1}"
: "${ABBR_DEFAULT_BINDINGS:=$((${ZF_ABBR_NO_DEFAULT_BINDS:-0} == 1 ? 0 : 1))}"
: "${ABBR_DEBUG:=${ZF_ABBR_DEBUG:-0}}"
: "${ABBR_DRY_RUN:=0}"
: "${ABBR_FORCE:=0}"
: "${ABBR_QUIET:=1}"
: "${ABBR_QUIETER:=1}"
: "${ABBR_TMPDIR:=${XDG_RUNTIME_DIR:-/tmp}/zsh-abbr}"

# Attempt to create ABBR_TMPDIR (non-fatal if fails)
if [[ ! -d "${ABBR_TMPDIR}" ]]; then
  mkdir -p "${ABBR_TMPDIR}" 2>/dev/null || true
fi

# Internal markers (not exported until success)
_ZF_ABBR=0
_ZF_ABBR_MODE=""

# Managed load path (zgenom)
_abbr_try_managed() {
  if typeset -f zgenom >/dev/null 2>&1; then
    if zgenom load olets/zsh-abbr 2>/dev/null; then
      _ZF_ABBR=1
      _ZF_ABBR_MODE="managed"
      zf::debug "# [abbr] loaded via zgenom (managed)"
      return 0
    else
      zf::debug "# [abbr] zgenom load attempt failed (non-fatal)"
    fi
  fi
  return 1
}

# Manual discovery strategy
_abbr_try_manual() {
  # Common potential locations (zgenom cache, sheldon, general clones)
  local cand
  local candidates=(
    "${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr"    # generic (version unspecified)
    "${ZDOTDIR:-$HOME}/.zgenom/olets/zsh-abbr/v6" # versioned
    "${HOME}/.local/share/sheldon/repos/github.com/olets/zsh-abbr"
    "${HOME}/.cache/zsh-abbr" # hypothetical
  )
  for cand in "${candidates[@]}"; do
    if [[ -f "${cand}/zsh-abbr.zsh" ]]; then
      # Add completions path if present
      if [[ -d "${cand}/completions" ]]; then
        fpath=("${cand}/completions" "${fpath[@]}")
      fi
      # shellcheck disable=SC1090
      if source "${cand}/zsh-abbr.zsh" 2>/dev/null; then
        _ZF_ABBR=1
        _ZF_ABBR_MODE="manual"
        zf::debug "# [abbr] manually sourced plugin from: ${cand}"
        return 0
      else
        zf::debug "# [abbr] source failed at candidate: ${cand}"
      fi
    fi
  done
  return 1
}

# Try managed, then manual
if ! _abbr_try_managed; then
  _abbr_try_manual || true
fi

# Post-load sanity check: confirm 'abbr' function exists if we claim success
if [[ $_ZF_ABBR -eq 1 ]]; then
  if ! typeset -f abbr >/dev/null 2>&1; then
    zf::debug "# [abbr] function not found after load attempt - marking as not loaded"
    _ZF_ABBR=0
    _ZF_ABBR_MODE=""
  fi
fi

# Curated Core Abbreviation Pack (D16B)
# Enabled by default when abbreviation system is loaded unless user opts out:
#   ZF_DISABLE_ABBR_PACK_CORE=1  -> skip curated core pack
# Markers:
#   _ZF_ABBR_PACK_CORE=1 applied, 0 skipped
#   _ZF_ABBR_PACK="core" when core pack applied (empty otherwise)
#
# Design:
#   - Guarded so it only runs once and only if 'abbr' is available.
#   - Each abbreviation added only if not already defined (avoid user override collision).
#   - Focus: high-signal, low-surprise productivity shorthands.
#
# Nounset safety: all parameter expansions guarded; array defined locally.
if [[ "${ZF_DISABLE_ABBR_PACK_CORE:-0}" != 1 && "${_ZF_ABBR:-0}" == 1 && -n "${_ZF_ABBR_MODE:-}" && "$(
  typeset -f abbr >/dev/null 2>&1
  echo $?
)" -eq 0 ]]; then
  # Helper: define global abbreviation if not already present
  _zf_abbr_core_define() {
    local lhs="$1" rhs="$2"
    [[ -z "${lhs}" || -z "${rhs}" ]] && return 0
    # Check existing abbreviation (quiet)
    if abbr list 2>/dev/null | grep -E "^[[:space:]]*${lhs}[[:space:]]" >/dev/null 2>&1; then
      return 0
    fi
    abbr -g "${lhs}"="${rhs}" 2>/dev/null || true
  }

  # Core curated set (balanced: navigation, git, system, diagnostics)
  _zf_abbr_core_define gs 'git status -sb'
  _zf_abbr_core_define ga 'git add'
  _zf_abbr_core_define gc 'git commit'
  _zf_abbr_core_define gca 'git commit --amend --no-edit'
  _zf_abbr_core_define gco 'git checkout'
  _zf_abbr_core_define gp 'git push'
  _zf_abbr_core_define gpl 'git pull --rebase'
  _zf_abbr_core_define gl 'git log --oneline --decorate --graph -20'
  _zf_abbr_core_define gdf 'git diff'
  _zf_abbr_core_define gdc 'git diff --cached'
  _zf_abbr_core_define gsw 'git switch'
  _zf_abbr_core_define gss 'git stash'
  _zf_abbr_core_define gsp 'git stash pop'
  _zf_abbr_core_define grb 'git rebase -i HEAD~5'
  _zf_abbr_core_define grbc 'git rebase --continue'

  _zf_abbr_core_define .. 'cd ..'
  _zf_abbr_core_define ... 'cd ../..'
  _zf_abbr_core_define .... 'cd ../../..'

  _zf_abbr_core_define vaf 'nvim $(fzf)'
  _zf_abbr_core_define lg 'lazygit'
  _zf_abbr_core_define k 'kubectl'
  _zf_abbr_core_define dcu 'docker compose up'
  _zf_abbr_core_define dcd 'docker compose down'

  _zf_abbr_core_define hst 'history 1 | tail -n 50'
  _zf_abbr_core_define path 'echo $PATH | tr ":" "\\n"'

  _ZF_ABBR_PACK_CORE=1
  unset -f _zf_abbr_core_define
else
  _ZF_ABBR_PACK_CORE=0
fi

# Export final markers
# Derive generic pack marker (D16B acceptance)
if [[ "${_ZF_ABBR_PACK_CORE:-0}" == 1 ]]; then
  _ZF_ABBR_PACK="core"
else
  _ZF_ABBR_PACK=""
fi
export _ZF_ABBR _ZF_ABBR_MODE _ZF_ABBR_PACK_CORE _ZF_ABBR_PACK
_ZF_ABBR_DONE=1

if [[ $_ZF_ABBR -eq 1 ]]; then
  zf::debug "# [abbr] READY (mode=${_ZF_ABBR_MODE})"
else
  zf::debug "# [abbr] unavailable (skipped or not found)"
fi

unset -f _abbr_try_managed _abbr_try_manual

return 0
