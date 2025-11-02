#!/usr/bin/env zsh
# test-logging-homogeneity.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Assert that all legacy underscore logging wrapper identifiers
#   (zf_warn, zf_err, zf_log, zf_info, zf_debug, zf_error, zf_crit, zf_fatal)
#   are completely absent from the active redesigned trees now that the
#   compatibility layer has been removed (Sprint 2).
#
# SCOPE:
#   Fails on ANY occurrence inside pre‑plugin or post‑plugin redesign module
#   directories. Tests, backups, and archived snapshots are ignored.
#
# MODES:
#   - Strict (default): Any occurrence => FAIL (exit != 0)
#   - Warn-only: Set LOG_HOMOGENEITY_STRICT=0 to downgrade to WARN (diagnostics)
#
# WHAT IS FLAGGED:
#   - Any legacy wrapper token in:
#       .zshrc.pre-plugins.d.REDESIGN/*.zsh
#       .zshrc.d.REDESIGN/*.zsh
#     (Exclusions: tests/, backups/, .ARCHIVE/)
#
# OUTPUT:
#   PASS on zero occurrences; otherwise enumerates each offending file:line and FAIL/WARN.
#
# NOTE:
#   Prior allowance for a compatibility file has been retired; presence of that
#   file or wrappers is a regression.
#
# ------------------------------------------------------------------------------
set -euo pipefail

strict="${LOG_HOMOGENEITY_STRICT:-1}"

fail() { print -r -- "FAIL: $*" >&2; exit 1; }
warn() { print -r -- "WARN: $*" >&2; }
note() { print -r -- "INFO: $*" >&2; }
pass() { print -r -- "PASS: $*"; }

# Repo root heuristic: assume test is invoked from repo root OR tests runner sets PWD.
REPO_ROOT="${PWD}"
# Normalize to repository root if executed from inside tests directory
if [[ ! -d "${REPO_ROOT}/dot-config/zsh" && -d "${PWD}/../../dot-config/zsh" ]]; then
  REPO_ROOT="$(cd "${PWD}/../.." && pwd)"
fi

ZSH_ROOT="${REPO_ROOT}/dot-config/zsh"
[[ -d "${ZSH_ROOT}" ]] || fail "Could not locate dot-config/zsh root at ${ZSH_ROOT}"

# (Compatibility layer removed; no file expected. If still present, treat as violation via scan.)

# Legacy wrapper identifiers (must be absent)
legacy_wrappers=(zf_warn zf_err zf_log zf_info zf_debug zf_error zf_crit zf_fatal)

# Build a combined ERE pattern
pat="\\b($(printf '%s|' "${legacy_wrappers[@]}" | sed 's/|$//'))\\b"

violations=()

# Collect candidate module files (exclude tests, backups, archives)
# Pre-plugin and post-plugin redesign trees
module_globs=(
  ".zshrc.pre-plugins.d.REDESIGN/*.zsh"
  ".zshrc.d.REDESIGN/*.zsh"
)

for g in "${module_globs[@]}"; do
  for f in "${ZSH_ROOT}/${g}"; do
    [[ -f "$f" ]] || continue
    rel="${f#${ZSH_ROOT}/}"

    # No compatibility file allowance anymore; any match anywhere (non-excluded) is a violation.

    # Skip any backups / archive artifacts defensively
    case "$rel" in
      backups/*|.ARCHIVE/*) continue ;;
    esac

    # Grep for any legacy wrapper usage
  if zf::safe_grep -E -n "$pat" "$f" >/dev/null 2>&1; then
      # Extract lines for context
      while IFS= read -r line; do
        violations+=("${rel}:${line}")
  done < <(zf::safe_grep -E -n "$pat" "$f" || true)
    fi
  done
done

# Legacy definitions must be entirely absent now; if any token appears we already flag it above.

# ZF_LOG_LEGACY_USED variable should no longer be set anywhere (indirectly enforced by wrapper absence).

if (( ${#violations[@]} > 0 )); then
  print -r -- "---- Legacy Logging Wrapper Violations ----" >&2
  for v in "${violations[@]}"; do
    print -r -- "$v" >&2
  done
  if [[ "$strict" == "1" ]]; then
    fail "Found ${#violations[@]} legacy logging wrapper occurrences outside compatibility layer"
  else
    warn "Found ${#violations[@]} legacy logging wrapper occurrences outside compatibility layer (warn-only mode)"
  fi
else
  pass "No legacy underscore logging wrappers detected outside compatibility layer"
fi

# Future strictness: verify wrappers removed entirely when migration complete
# (placeholder for upgrade path)
exit 0
