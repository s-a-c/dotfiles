#!/usr/bin/env zsh
# 195-optional-brew-abbr.zsh - Optional Homebrew Abbreviation Module (Decision D5A)
# Phase: 7 (Optional Enhancements)
#
# Purpose:
#   Provide a curated, low-noise set of Homebrew-related abbreviations to accelerate
#   routine package management workflows. Integrates with the existing abbreviation
#   system (olets/zsh-abbr) if available; otherwise offers a lightweight alias fallback.
#
# Design Constraints (Policy Alignment):
#   - Nounset-safe: all parameter expansions guarded with ${var:-}
#   - Idempotent: multiple sourcing has no cumulative side effects
#   - Guarded: user can disable globally or request minimal set
#   - No silent failure: emits debug markers (via zf::debug stub if absent)
#   - Marker variables exported for smoke/CI detection
#
# Environment Toggles:
#   ZF_DISABLE_BREW_ABBR=1       -> Skip module entirely
#   ZF_BREW_ABBR_MINIMAL=1       -> Load minimal core set only
#   ZF_BREW_ABBR_DRY_RUN=1       -> Show what would be added (no mutation)
#
# Markers (exported):
#   _ZF_BREW_ABBR=1|0            -> Module processed & active (1) or skipped/disabled (0)
#   _ZF_BREW_ABBR_COUNT=<n>      -> Number of abbreviations (or aliases fallback) actually added
#   _ZF_BREW_ABBR_MODE=abbr|alias|none  -> Mechanism used
#   _ZF_BREW_ABBR_MINIMAL=1|0    -> Whether minimal mode was active
#
# Dependencies:
#   - Homebrew presence (`brew` in PATH)
#   - Optional: zsh-abbr plugin (function `abbr`) provided by 190-optional-abbr.zsh
#
# Fallback Behavior:
#   If `abbr` not available, attempts alias definitions (best-effort; no dynamic expansion).
#
# Abbreviation Philosophy:
#   - Predictable prefixes: b<verb/descriptor>
#   - Avoid collision with common generic short commands
#   - Focus on frequently used read/update/inspect operations
#
# Example Usage (after load):
#   Type: bupd<SPACE>  -> expands to 'brew update' (abbr mode)
#   Type: bls<SPACE>   -> expands to 'brew list'
#
# Test Snippet (manual):
#   echo "$_ZF_BREW_ABBR / $_ZF_BREW_ABBR_MODE / $_ZF_BREW_ABBR_COUNT"
#
# ------------------------------------------------------------------------------

# Idempotency guard
[[ -n ${_ZF_BREW_ABBR_DONE:-} ]] && return 0

# Provide minimal debug helper if not already defined
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Early global disable
if [[ "${ZF_DISABLE_BREW_ABBR:-0}" == 1 ]]; then
  _ZF_BREW_ABBR=0
  _ZF_BREW_ABBR_MODE="none"
  _ZF_BREW_ABBR_COUNT=0
  _ZF_BREW_ABBR_MINIMAL=0
  export _ZF_BREW_ABBR _ZF_BREW_ABBR_MODE _ZF_BREW_ABBR_COUNT _ZF_BREW_ABBR_MINIMAL
  _ZF_BREW_ABBR_DONE=1
  zf::debug "# [brew-abbr] disabled via ZF_DISABLE_BREW_ABBR=1"
  return 0
fi

# Require brew
if ! command -v brew >/dev/null 2>&1; then
  _ZF_BREW_ABBR=0
  _ZF_BREW_ABBR_MODE="none"
  _ZF_BREW_ABBR_COUNT=0
  _ZF_BREW_ABBR_MINIMAL=0
  export _ZF_BREW_ABBR _ZF_BREW_ABBR_MODE _ZF_BREW_ABBR_COUNT _ZF_BREW_ABBR_MINIMAL
  _ZF_BREW_ABBR_DONE=1
  zf::debug "# [brew-abbr] brew not found; skipping"
  return 0
fi

# Minimal mode?
_ZF_BREW_ABBR_MINIMAL=$((${ZF_BREW_ABBR_MINIMAL:-0} == 1 ? 1 : 0))

# Curated abbreviation sets (lhs=rhs). Ordered by expected frequency.
# Minimal Core Set (safe + high value):
typeset -a _brew_abbr_minimal
_brew_abbr_minimal=(
  bupd 'brew update'
  bout 'brew outdated'
  bupg 'brew upgrade'
  bls 'brew list'
  bins 'brew install'
  brem 'brew remove'
  bcln 'brew cleanup'
)

# Extended Set (loaded only when not minimal)
typeset -a _brew_abbr_extended
_brew_abbr_extended=(
  binfo 'brew info'
  bdeps 'brew deps --tree'
  bsearch 'brew search'
  bleaf 'brew leaves'
  bdoc 'brew doctor'
  bpin 'brew pin'
  bwin 'brew --prefix'
  bcfg 'brew config'
  bcask 'brew install --cask'
  bcs 'brew list --cask'
  brlog 'brew update-reset'
)

# Assemble final flat array
typeset -a _brew_abbr_pairs
_brew_abbr_pairs=()
_brew_abbr_pairs+=("${_brew_abbr_minimal[@]}")
if [[ $_ZF_BREW_ABBR_MINIMAL -eq 0 ]]; then
  _brew_abbr_pairs+=("${_brew_abbr_extended[@]}")
fi

# Dedup helper (in case of accidental overlap)
typeset -A _brew_abbr_seen
typeset -a _brew_abbr_final
_brew_abbr_final=()
local i lhs rhs
for ((i = 1; i <= ${#_brew_abbr_pairs[@]}; i += 2)); do
  lhs="${_brew_abbr_pairs[i]}"
  rhs="${_brew_abbr_pairs[i + 1]}"
  [[ -z "${lhs:-}" || -z "${rhs:-}" ]] && continue
  if [[ -z ${_brew_abbr_seen[$lhs]:-} ]]; then
    _brew_abbr_seen[$lhs]=1
    _brew_abbr_final+=("$lhs" "$rhs")
  fi
done

# Detect abbr availability
_have_abbr=0
typeset -f abbr >/dev/null 2>&1 && _have_abbr=1

# Dry run mode
_dry_run=$((${ZF_BREW_ABBR_DRY_RUN:-0} == 1 ? 1 : 0))

_added=0
_failed=0

# Define utility to check existing abbreviation or alias
_zf_brew_abbr_exists() {
  local key="$1"
  # If abbr present, inspect abbr list
  if ((_have_abbr == 1)); then
    if abbr list 2>/dev/null | grep -E "^[[:space:]]*${key}[[:space:]]" >/dev/null 2>&1; then
      return 0
    fi
  fi
  # Alias fallback
  if alias "$key" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Apply abbreviations
if ((_have_abbr == 1)); then
  _ZF_BREW_ABBR_MODE="abbr"
  for ((i = 1; i <= ${#_brew_abbr_final[@]}; i += 2)); do
    lhs="${_brew_abbr_final[i]}"
    rhs="${_brew_abbr_final[i + 1]}"
    _zf_brew_abbr_exists "$lhs" && continue
    if ((_dry_run == 1)); then
      printf "%s -> %s (DRY RUN)\n" "$lhs" "$rhs"
      continue
    fi
    if abbr -g "${lhs}"="${rhs}" 2>/dev/null; then
      _added=$((_added + 1))
    else
      _failed=$((_failed + 1))
    fi
  done
else
  # Alias fallback
  _ZF_BREW_ABBR_MODE="alias"
  for ((i = 1; i <= ${#_brew_abbr_final[@]}; i += 2)); do
    lhs="${_brew_abbr_final[i]}"
    rhs="${_brew_abbr_final[i + 1]}"
    _zf_brew_abbr_exists "$lhs" && continue
    if ((_dry_run == 1)); then
      printf "%s -> %s (DRY RUN - alias fallback)\n" "$lhs" "$rhs"
      continue
    fi
    alias "${lhs}=${rhs}" 2>/dev/null || _failed=$((_failed + 1))
    _added=$((_added + 1))
  done
fi

# Markers
if ((_dry_run == 1)); then
  _ZF_BREW_ABBR=0
  _ZF_BREW_ABBR_COUNT=0
  zf::debug "# [brew-abbr] dry run listing emitted (no changes applied)"
else
  _ZF_BREW_ABBR=1
  _ZF_BREW_ABBR_COUNT=${_added}
fi

export _ZF_BREW_ABBR _ZF_BREW_ABBR_COUNT _ZF_BREW_ABBR_MODE _ZF_BREW_ABBR_MINIMAL

# Public helper to list active brew abbreviations (works in both modes)
zf::brew_abbr_list() {
  if ((_dry_run == 1)); then
    echo "Dry run mode – no active brew abbreviations."
    return 0
  fi
  echo "Brew abbreviations (mode=${_ZF_BREW_ABBR_MODE}, count=${_ZF_BREW_ABBR_COUNT}, minimal=${_ZF_BREW_ABBR_MINIMAL})"
  if [[ "${_ZF_BREW_ABBR_MODE}" == "abbr" ]]; then
    # Filter only those we introduced (heuristic: keys in our final list)
    local key
    for ((i = 1; i <= ${#_brew_abbr_final[@]}; i += 2)); do
      key="${_brew_abbr_final[i]}"
      if abbr list 2>/dev/null | grep -E "^[[:space:]]*${key}[[:space:]]" >/dev/null 2>&1; then
        echo "  $key"
      fi
    done
  elif [[ "${_ZF_BREW_ABBR_MODE}" == "alias" ]]; then
    alias | grep -E "^(bupd|bupg|bins|brem|bcln|bls|bout|binfo|bdeps|bsearch|bleaf|bdoc|bpin|bwin|bcfg|bcask|bcs|brlog)=" 2>/dev/null || true
  else
    echo "  (none)"
  fi
}

# Debug summary
zf::debug "# [brew-abbr] mode=${_ZF_BREW_ABBR_MODE} added=${_ZF_BREW_ABBR_COUNT} failed=${_failed} minimal=${_ZF_BREW_ABBR_MINIMAL} dry_run=${_dry_run}"

_unset_list=(
  _brew_abbr_minimal _brew_abbr_extended _brew_abbr_pairs _brew_abbr_seen
  _brew_abbr_final _brew_abbr_done lhs rhs i _have_abbr _added _failed
  _dry_run
)
unset "${_unset_list[@]}" 2>/dev/null || true
unset _unset_list

_ZF_BREW_ABBR_DONE=1
return 0
