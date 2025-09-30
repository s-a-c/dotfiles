#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/.zshrc.d.REDESIGN/70-shim-removal.zsh
#
# Runtime shim removal / runtime guard for the redesign.
#
# Purpose:
#  - Allow opt-in testing of the redesign by preventing legacy shim loading at runtime.
#  - Be non-destructive: do not rename/delete files on disk.
#  - Provide inspection and control helpers:
#      zred::shim::list   - list shim candidates and runtime status
#      zred::shim::disable - disable shim loading in this session (no on-disk change)
#      zred::shim::enable  - revert disable in this session
#      zred::shim::help    - show helper usage
#
# Safety:
#  - No on-disk changes performed.
#  - All behavior is session-local and reversible by `zred::shim::enable`.
#  - The module is a no-op unless `ZSH_USE_REDESIGN=1`.
#
# Note: This module is intentionally conservative. Extend the `_zred_shim_candidates`
# list only after audit and review.

if [[ "${ZSH_USE_REDESIGN:-0}" != "1" ]]; then
  return 0
fi

# Idempotent load sentinel
if [[ -n "${_ZRED_SHIM_REMOVAL_LOADED:-}" ]]; then
  return 0
fi
_ZRED_SHIM_REMOVAL_LOADED=1

# Internal state container
typeset -A _zred_shim_state     # e.g., disabled=0/1
typeset -A _zred_preserved_map  # mapping sanitized -> preserved-function-name
_zred_shim_state[disabled]=0

# Conservative shim candidate list (edit with care)
# Entries may be either function names (loader functions) or file fragments that legacy loaders might source.
_zred_shim_candidates=(
  "load_legacy_shims"               # example: legacy loader function
  ".zshrc.d/shims"                  # example: legacy shim directory
  ".zshrc.d/legacy-shim.zsh"        # example: legacy shim file
)

# Helper: debug emitter (no-op if zf::debug not present)
zred::_maybe_debug() {
  if whence -w zf::debug >/dev/null 2>&1; then
    zf::debug "$@"
  fi
}

# Create a valid sanitized token for a candidate name to use in preserved function identifiers
zred::_sanitize_name() {
  local s="$1"
  # Replace non-alphanum with underscore
  s="${s//[^A-Za-z0-9]/_}"
  # Avoid leading digit for function name, prefix if necessary
  if [[ "$s" =~ ^[0-9] ]]; then
    s="_${s}"
  fi
  printf '%s' "$s"
}

# Compute sentinel variable name for a candidate (used to signal loaders to skip a file)
zred::_sentinel_var_for() {
  local cand="$1"
  local san
  san="$(zred::_sanitize_name "$cand")"
  printf '_ZRED_SKIP_%s' "$san"
}

# List shim candidates and runtime status
zred::shim::list() {
  print "Redesign shim candidates (runtime view):"
  for candidate in "${_zred_shim_candidates[@]}"; do
    local status="missing"
    if [[ -f "${ZDOTDIR}/${candidate}" || -f "${ZDOTDIR}/${candidate}.zsh" ]]; then
      status="file-present"
    elif whence -w "${candidate}" >/dev/null 2>&1; then
      status="loader-function"
    fi
    printf ' - %s (%s)\n' "$candidate" "$status"
  done
}

# Internal: preserve a loader function by creating a copy named _zred_preserved_<san>
# Only preserves within this session (best-effort).
zred::_preserve_function() {
  local fname="$1"
  if ! whence -w "$fname" >/dev/null 2>&1; then
    return 0
  fi

  local san preserved_name body
  san="$(zred::_sanitize_name "$fname")"
  preserved_name="_zred_preserved_${san}"

  # If already preserved, note mapping and return
  if whence -w "$preserved_name" >/dev/null 2>&1; then
    _zred_preserved_map[$san]="$preserved_name"
    return 0
  fi

  # Capture function definition
  if ! body="$(typeset -f "$fname" 2>/dev/null)"; then
    return 0
  fi

  # Replace leading function name with preserved_name (best-effort).
  # typeset -f output typically starts with: fname () { ...
  preserved_body="${body/#$fname/$preserved_name}"

  # Evaluate preserved body to create preserved function
  if [[ -n "$preserved_body" ]]; then
    eval "$preserved_body" 2>/dev/null || true
    if whence -w "$preserved_name" >/dev/null 2>&1; then
      _zred_preserved_map[$san]="$preserved_name"
      zred::_maybe_debug "# [redesign] preserved function '$fname' -> '$preserved_name'"
    fi
  fi
}

# Internal: create a stub for a loader function that logs prevention and returns
zred::_override_with_stub() {
  local fname="$1"
  # Define a lightweight stub that logs debug and returns success
  eval "function ${fname}() { zred::_maybe_debug \"# [redesign] prevented legacy loader: ${fname}\"; return 0; }"
}

# Public: disable legacy shim loading in this session (non-destructive)
zred::shim::disable() {
  if (( _zred_shim_state[disabled] == 1 )); then
    print "zred::shim::disable: already disabled in this session"
    return 0
  fi

  for candidate in "${_zred_shim_candidates[@]}"; do
    # If candidate is a function loader, preserve & stub it
    if whence -w "$candidate" >/dev/null 2>&1; then
      # Preserve original if not preserved already
      zred::_preserve_function "$candidate"
      # Override original with stub
      zred::_override_with_stub "$candidate"
    fi

    # If the candidate corresponds to a file a loader might source, export a sentinel var
    if [[ -f "${ZDOTDIR}/${candidate}" || -f "${ZDOTDIR}/${candidate}.zsh" ]]; then
      local sname
      sname="$(zred::_sentinel_var_for "$candidate")"
      # Export sentinel so guarded loaders can detect and skip the file
      export "${sname}"=1 2>/dev/null || true
      zred::_maybe_debug "# [redesign] exported sentinel ${sname}=1 for candidate ${candidate}"
    fi
  done

  # Best-effort: remove known shim hook references from precmd_functions
  if (( ${#precmd_functions[@]} )); then
    local -a filtered
    for f in "${precmd_functions[@]}"; do
      local is_shim=0
      for candidate in "${_zred_shim_candidates[@]}"; do
        if [[ "$f" == "$candidate" ]]; then
          is_shim=1
          break
        fi
      done
      if (( is_shim )); then
        zred::_maybe_debug "# [redesign] removing shim precmd function: ${f}"
        continue
      fi
      filtered+=("$f")
    done
    precmd_functions=("${filtered[@]}")
  fi

  _zred_shim_state[disabled]=1
  print "zred::shim::disable: runtime shim disabling applied (no on-disk changes)"
}

# Public: enable (revert) runtime shim disabling in this session
zred::shim::enable() {
  if (( _zred_shim_state[disabled] == 0 )); then
    print "zred::shim::enable: not disabled in this session"
    return 0
  fi

  # Remove stub overrides and attempt to restore preserved functions
  for candidate in "${_zred_shim_candidates[@]}"; do
    # If we overrode a function, unset it so original preserved one can be restored
    if whence -w "$candidate" >/dev/null 2>&1; then
      unset -f "$candidate" 2>/dev/null || true
    fi

    # If preserved mapping exists, re-evaluate preserved function as original
    local san preserved_name preserved_body
    san="$(zred::_sanitize_name "$candidate")"
    preserved_name="${_zred_preserved_map[$san]:-}"
    if [[ -n "$preserved_name" ]] && whence -w "$preserved_name" >/dev/null 2>&1; then
      # Capture preserved body and recreate original name from it (best-effort)
      if preserved_body="$(typeset -f "$preserved_name" 2>/dev/null)"; then
        # Replace preserved name with original candidate name at start
        original_body="${preserved_body/#$preserved_name/$candidate}"
        eval "$original_body" 2>/dev/null || true
        # Optionally unset preserved function
        unset -f "$preserved_name" 2>/dev/null || true
      fi
      unset "_zred_preserved_map[$san]" 2>/dev/null || true
    fi

    # Unset any sentinel variables that were exported
    local sname
    sname="$(zred::_sentinel_var_for "$candidate")"
    unset "${sname}" 2>/dev/null || true
  done

  # Note: we do not attempt to reconstruct original precmd_functions order perfectly,
  # because that can be complex and fragile; we keep best-effort behavior.
  _zred_shim_state[disabled]=0
  print "zred::shim::enable: runtime shim disabling reverted in this session"
}

# Public: brief usage help
zred::shim::help() {
  cat <<'EOF'
zred::shim::list      — list shim candidates and runtime status
zred::shim::disable   — disable shim loading at runtime (non-destructive)
zred::shim::enable    — re-enable shim loading in current session
zred::shim::help      — this help text
EOF
}

# Auto-apply runtime shim disable if the explicit opt-in runtime flag is set.
# This keeps behavior opt-in: set ZSH_REDESIGN_DISABLE_SHIMS_AT_RUNTIME=1 to auto-disable.
if [[ "${ZSH_REDESIGN_DISABLE_SHIMS_AT_RUNTIME:-0}" == "1" ]]; then
  zred::shim::disable || true
fi

# End of shim-removal module
