#!/usr/bin/env zsh
# Filename: 300-brew-abbr.zsh
# Purpose:  Decision: D5A (Implement brew abbreviation module) Provide a small, high-signal set of Homebrew-related abbreviations leveraging the zsh-abbr plugin (if loaded) to accelerate common maintenance, install, and diagnostic workflows without polluting the namespace or overriding user preferences. Load & Behavior Rules: - Only activates if: * Abbreviation system loaded (_ZF_ABBR == 1) AND * 'abbr' function exists AND * 'brew' is on PATH - Skippable via toggle: export ZF_DISABLE_ABBR_BREW=1 - Idempotent: guarded by sentinel _ZF_ABBR_BREW_DONE - Does NOT overwrite existing abbreviations (pre-existing user definitions win)
# Phase:    Plugin activation (.zshrc.add-plugins.d/)
# Toggles:  export ZF_DISABLE_ABBR_BREW=1

# ------------------------------------------------------------------------------

# Idempotency sentinel
[[ -n ${_ZF_ABBR_BREW_DONE:-} ]] && return 0
_ZF_ABBR_BREW_DONE=1

# zf::debug is now globally available from .zshenv.00

# Default outcome (assume skip)
_ZF_ABBR_BREW=0
_ZF_ABBR_BREW_COUNT=0

# Early opt-out
if [[ "${ZF_DISABLE_ABBR_BREW:-0}" == 1 ]]; then
  zf::debug "# [brew-abbr] disabled via ZF_DISABLE_ABBR_BREW"
  export _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT
  return 0
fi

# Preconditions: abbreviation system + brew + abbr function
if [[ "${_ZF_ABBR:-0}" != 1 ]]; then
  zf::debug "# [brew-abbr] base abbreviation system not active (_ZF_ABBR=${_ZF_ABBR:-unset})"
  export _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT
  return 0
fi
if ! command -v brew >/dev/null 2>&1; then
  zf::debug "# [brew-abbr] brew not found on PATH"
  export _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT
  return 0
fi
if ! typeset -f abbr >/dev/null 2>&1; then
  zf::debug "# [brew-abbr] 'abbr' function unavailable despite _ZF_ABBR=1"
  export _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT
  return 0
fi

zf::debug "# [brew-abbr] applying curated brew abbreviation set"

# Helper: define abbreviation only if not already declared
_zf_brew_abbr_define() {
  local lhs="$1" rhs="$2"
  [[ -z "$lhs" || -z "$rhs" ]] && return 0
  # Detect existing abbreviation (quiet)
  if abbr list 2>/dev/null | grep -E "^[[:space:]]*${lhs}[[:space:]]" >/dev/null 2>&1; then
    return 0
  fi
  if abbr -g "${lhs}"="${rhs}" 2>/dev/null; then
    ((_ZF_ABBR_BREW_COUNT++))
  fi
}

# Core maintenance / update cycle
_zf_brew_abbr_define bup 'brew update'
_zf_brew_abbr_define bupg 'brew upgrade'
_zf_brew_abbr_define bupga 'brew upgrade --greedy'
_zf_brew_abbr_define bupd 'brew update && brew outdated'
_zf_brew_abbr_define bo 'brew outdated'
_zf_brew_abbr_define bcl 'brew cleanup'
_zf_brew_abbr_define bcln 'brew cleanup --prune=all --dry-run'
_zf_brew_abbr_define bdr 'brew doctor'

# Install / info / search
_zf_brew_abbr_define bi 'brew install'
_zf_brew_abbr_define binf 'brew info'
_zf_brew_abbr_define bse 'brew search'
_zf_brew_abbr_define brm 'brew uninstall'
_zf_brew_abbr_define ble 'brew leaves'

# Cask operations (guard simple subset)
_zf_brew_abbr_define bci 'brew install --cask'
_zf_brew_abbr_define bcu 'brew upgrade --cask'

# Link management
_zf_brew_abbr_define bln 'brew link'
_zf_brew_abbr_define bunl 'brew unlink'

# Mark success if at least one added
if ((_ZF_ABBR_BREW_COUNT > 0)); then
  _ZF_ABBR_BREW=1
fi

# Cleanup helper
unset -f _zf_brew_abbr_define

# Export markers
export _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT

zf::debug "# [brew-abbr] complete (applied=${_ZF_ABBR_BREW} count=${_ZF_ABBR_BREW_COUNT})"

return 0
