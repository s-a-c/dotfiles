# Draft: dotfiles/dot-config/zsh/.zshrc.d.REDESIGN/70-shim-removal.zsh
#
# Purpose
# =======
# Runtime shim disable guard (F-A5) — draft for review.
#
# This file is a safe, non-destructive runtime shim controller intended to:
# - Allow opt-in testing of the redesign by preventing legacy shim loading at runtime.
# - Provide inspection helpers to list shim candidates and their statuses.
# - Be idempotent and guarded by the `ZSH_USE_REDESIGN` feature flag.
# - Avoid any on-disk modifications. Actual file renames/deletions require
#   explicit, separate approval and must be performed only by `tools/migrate-to-redesign.sh --apply`.
#
# Usage Notes (draft)
# -------------------
# - The module is a no-op unless `ZSH_USE_REDESIGN=1` in the environment.
# - To list shim candidates in the current session:
#     zred::shim::list
# - To apply runtime-only shim disabling:
#     zred::shim::disable
# - To revert runtime-only shim disabling (current shell only):
#     zred::shim::enable
# - For help:
#     zred::shim::help
#
# Safety
# ------
# - The draft intentionally avoids touching any files on disk.
# - It uses defensive guards and snapshots existing hook state to restore later.
# - It should be added to `.zshrc.d.REDESIGN` and only executed when the redesign flag is active.
#
# Draft Implementation (script)
# -----------------------------
#!/usr/bin/env zsh
# .zshrc.d.REDESIGN/70-shim-removal.zsh — runtime shim guard (draft)
#
# Guard: only active when ZSH_USE_REDESIGN=1
if [[ "${ZSH_USE_REDESIGN:-0}" != "1" ]]; then
  return 0
fi

# Idempotent sentinel
if [[ -n "${_ZRED_SHIM_REMOVAL_LOADED:-}" ]]; then
  return 0
fi
_ZRED_SHIM_REMOVAL_LOADED=1

# Internal state
typeset -A _zred_shim_state
_zred_shim_state[disabled]=0

# Conservative list of known shim loader names or shim file fragments.
# This list is intentionally small; extend via documented PRs after review.
_zred_shim_candidates=(
  "load_legacy_shims"               # legacy loader function name (example)
  ".zshrc.d/shims"                  # legacy shim directory (example)
  ".zshrc.d/legacy-shim.zsh"        # legacy shim file (example)
)

# Save snapshot of relevant hook/state to support best-effort restore
_zred_shim_original_precmd="${(j: :)precmd_functions:-}"
_zred_shim_original_prompt="${PROMPT:-}"

# Helper: print a compact debug message if zsh_debug_echo exists, otherwise noop
zred::_maybe_debug() {
  if whence -w zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "$@"
  fi
}

# Public: list shim candidates and their current runtime status
zred::shim::list() {
  print -- "Redesign shim candidates (runtime view):"
  for candidate in "${_zred_shim_candidates[@]}"; do
    local status="missing"
    if [[ -f "${ZDOTDIR}/${candidate}" || -f "${ZDOTDIR}/${candidate}.zsh" ]]; then
      status="file-present"
    elif whence -w "${candidate}" >/dev/null 2>&1; then
      status="loader-function"
    fi
    printf ' - %s (%s)\n' "${candidate}" "${status}"
  done
}

# Internal: compute a sentinel variable name for a candidate
zred::_sentinel_var_for() {
  local cand="$1"
  # Replace non-alphanumeric with underscores
  printf '_ZRED_SKIP_%s' "${cand//[^A-Za-z0-9]/_}"
}

# Public: apply runtime-only shim disabling (non-destructive)
zred::shim::disable() {
  if (( _zred_shim_state[disabled] == 1 )); then
    print -- "zred::shim::disable: already disabled in this session"
    return 0
  fi

  # Shadow known loader functions with lightweight no-op proxies
  for candidate in "${_zred_shim_candidates[@]}"; do
    if whence -w "${candidate}" >/dev/null 2>&1; then
      # Preserve original if possible by copying to a uniquely named function.
      # Avoid overwriting if already preserved.
      if ! whence -w "_zred_preserved_${candidate}" >/dev/null 2>&1; then
        if whence -w "${candidate}" >/dev/null 2>&1; then
          eval "typeset -f ${candidate} >/dev/null 2>&1 && autoload -Uz -X || true"
          # Attempt to move original to preserved name (best-effort)
          eval "if whence -w ${candidate} >/dev/null 2>&1; then eval \"$(whence -v ${candidate} 2>/dev/null | sed \"s/^/ /\")\"; fi" 2>/dev/null || true
        fi
      fi
      # Override with a harmless stub that logs a debug message
      eval "function ${candidate}() { zred::_maybe_debug \"# [redesign] prevented legacy loader: ${candidate}\"; return 0; }"
    fi

    # If a candidate corresponds to a file that may be sourced by a loader,
    # export a sentinel variable so guarded loaders can detect and skip it.
    local sname
    sname="$(zred::_sentinel_var_for "${candidate}")"
    export "${sname}"=1 2>/dev/null || true
  done

  # Best-effort: remove known shim hook references from precmd_functions
  if (( ${#precmd_functions[@]} )); then
    local -a filtered
    for f in "${precmd_functions[@]}"; do
      local is_shim=0
      for candidate in "${_zred_shim_candidates[@]}"; do
        if [[ "${f}" == "${candidate}" ]]; then
          is_shim=1; break
        fi
      done
      if (( is_shim )); then
        zred::_maybe_debug "# [redesign] removing shim precmd function: ${f}"
        continue
      fi
      filtered+=("${f}")
    done
    precmd_functions=("${filtered[@]}")
  fi

  _zred_shim_state[disabled]=1
  print -- "zred::shim::disable: runtime shim disabling applied (no on-disk changes)"
}

# Public: revert runtime-only shim disabling in the current shell session
zred::shim::enable() {
  if (( _zred_shim_state[disabled] == 0 )); then
    print -- "zred::shim::enable: not disabled in this session"
    return 0
  fi

  # Attempt to unset any stubbed functions we created
  for candidate in "${_zred_shim_candidates[@]}"; do
    # Remove override function if present
    if whence -w "${candidate}" >/dev/null 2>&1; then
      unset -f "${candidate}" 2>/dev/null || true
    fi
    # Unset sentinel variable
    local sname
    sname="$(zred::_sentinel_var_for "${candidate}")"
    unset "${sname}" 2>/dev/null || true
  done

  # Restore precmd_functions snapshot (best-effort)
  if [[ -n "${_zred_shim_original_precmd:-}" ]]; then
    precmd_functions=("${(@s: :)_zred_shim_original_precmd}")
  fi

  _zred_shim_state[disabled]=0
  print -- "zred::shim::enable: runtime shim disabling reverted in this session"
}

# Public: help text
zred::shim::help() {
  cat <<'EOF'
zred::shim::list      — list shim candidates and runtime status
zred::shim::disable   — disable shim loading at runtime (non-destructive)
zred::shim::enable    — re-enable shim loading in current session
EOF
}

# Optional: auto-apply runtime shim disable if an explicit runtime opt-in is set.
# This keeps behavior opt-in: set ZSH_REDESIGN_DISABLE_SHIMS_AT_RUNTIME=1 to auto-disable.
if [[ "${ZSH_REDESIGN_DISABLE_SHIMS_AT_RUNTIME:-0}" == "1" ]]; then
  zred::shim::disable || true
fi

# End of draft shim-removal module
# Notes for reviewers:
# - The function-preservation logic above is intentionally conservative and best-effort:
#   it's safer to shadow loader functions than to try to reconstruct and restore them
#   perfectly. If preservation of original behavior is required, we should implement
#   an explicit save/restore mechanism that copies function bodies to preserved names.
# - Before merging runtime shim disabling into any shared branch, ensure unit/integration
#   tests cover typical legacy loader behavior and that sentinel variables are respected
#   by guarded loaders. The `tools/bench-shim-audit.zsh` helper can be used to enumerate
#   shim candidates and guide further remediation.