#!/usr/bin/env bash
# normalize-exec-bits.sh
#
# Normalize executable (x) bit for tracked files to match presence of a shebang (#!).
# - If a file starts with "#!" and is not executable, mark it executable (+x).
# - If a file does not start with "#!" but is executable, remove the executable bit (-x).
# Operates only on a scoped set of paths by default: dot-config/zsh, tools, tests.
#
# This script updates both the working tree and the git index to keep them consistent.
#
# Usage:
#   tools/maintenance/normalize-exec-bits.sh [options] [PATH ...]
#
# Options:
#   -n, --dry-run       Show what would change without applying it
#   -q, --quiet         Less output
#   -v, --verbose       More output
#   --no-index          Do not update git index (working tree only)
#   -h, --help          Show help
#
# Examples:
#   # Normalize default scope
#   tools/maintenance/normalize-exec-bits.sh
#
#   # Normalize a specific subtree
#   tools/maintenance/normalize-exec-bits.sh tools/ tests/
#
#   # Preview changes
#   tools/maintenance/normalize-exec-bits.sh --dry-run
#
set -euo pipefail

# --- Defaults -----------------------------------------------------------------
DRY_RUN=0
QUIET=0
VERBOSE=0
UPDATE_INDEX=1

# Default scope paths (override by passing explicit path arguments)
DEFAULT_SCOPE=( "dot-config/zsh" "tools" "tests" )

# --- Helpers ------------------------------------------------------------------
log() { : "${QUIET}"; [ "${QUIET}" -eq 1 ] && return 0; printf '%s\n' "$*"; }
vlog() { : "${VERBOSE}"; [ "${VERBOSE}" -eq 0 ] && return 0; printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
  sed -n '1,60p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

require_git_repo() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    err "This script must be run inside a git repository."
    exit 2
  fi
}

# Return 0 if the file has a shebang at the very beginning, else 1
has_shebang() {
  # Empty or very short files won't have a shebang; read just first 2 bytes
  # Using dd for portability over head -c on some systems
  local f=$1
  # If file is empty, dd will produce nothing; that's fine
  local first2
  first2="$(dd if="$f" bs=1 count=2 2>/dev/null || true)"
  [ "$first2" = "#!" ]
}

# Return 0 if git index marks file as 100755 (executable), else 1
is_exec_in_index() {
  local f=$1
  # format: <mode> <sha> <stage> <path>
  local mode
  mode="$(git ls-files -s -- "$f" | awk '{print $1}' || true)"
  [[ "${mode:-}" =~ ^100755$ ]]
}

# Return 0 if filesystem says file executable, else 1
is_exec_in_fs() {
  local f=$1
  [ -x "$f" ]
}

# Apply chmod +x/-x and keep git index in sync (unless --no-index)
apply_mode() {
  local mode=$1  # +x or -x
  local f=$2

  if [ "${DRY_RUN}" -eq 0 ]; then
    chmod "${mode}" -- "$f" || true
    if [ "${UPDATE_INDEX}" -eq 1 ]; then
      if [ "${mode}" = "+x" ]; then
        git update-index --chmod=+x -- "$f" || true
      else
        git update-index --chmod=-x -- "$f" || true
      fi
    fi
  fi
}

# --- Parse args ----------------------------------------------------------------
SCOPE=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -q|--quiet) QUIET=1 ;;
    -v|--verbose) VERBOSE=$((VERBOSE+1)) ;;
    --no-index) UPDATE_INDEX=0 ;;
    -h|--help) usage 0 ;;
    --) shift; break ;;
    -*)
      err "Unknown option: $1"
      usage 1
      ;;
    *)
      SCOPE+=( "$1" )
      ;;
  esac
  shift
done

# Allow additional positional paths after --
while [ "$#" -gt 0 ]; do
  SCOPE+=( "$1" )
  shift
done

if [ "${#SCOPE[@]}" -eq 0 ]; then
  SCOPE=( "${DEFAULT_SCOPE[@]}" )
fi

require_git_repo

# Build a list of tracked files under scope, null-delimited for safety
# Use git ls-files to respect repository tracking and to avoid traversing submodule internals
vlog "Collecting tracked files in scope: ${SCOPE[*]}"
# shellcheck disable=SC2207
FILES=($(git ls-files -z -- "${SCOPE[@]}" | tr '\0' '\n'))

ADDED=0
REMOVED=0
UNCHANGED=0
SKIPPED=0

for f in "${FILES[@]}"; do
  # Skip if path resolves to non-regular or missing
  if [ ! -e "$f" ]; then
    vlog "skip (missing): $f"
    SKIPPED=$((SKIPPED+1))
    continue
  fi
  # Skip symlinks and directories
  if [ -L "$f" ] || [ -d "$f" ]; then
    vlog "skip (non-regular): $f"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  if has_shebang "$f"; then
    # Should be executable
    if ! is_exec_in_fs "$f" || ! is_exec_in_index "$f"; then
      log "ADD +x: $f"
      apply_mode "+x" "$f"
      ADDED=$((ADDED+1))
    else
      vlog "ok (+x present): $f"
      UNCHANGED=$((UNCHANGED+1))
    fi
  else
    # Should not be executable
    if is_exec_in_fs "$f" || is_exec_in_index "$f"; then
      log "REMOVE -x: $f"
      apply_mode "-x" "$f"
      REMOVED=$((REMOVED+1))
    else
      vlog "ok (-x present): $f"
      UNCHANGED=$((UNCHANGED+1))
    fi
  fi
done

echo
echo "Summary:"
echo "  +x added:     ${ADDED}"
echo "  -x removed:   ${REMOVED}"
echo "  unchanged:    ${UNCHANGED}"
echo "  skipped:      ${SKIPPED}"
echo
if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Dry run: no changes were applied."
fi

# Exit code semantics:
# 0 if everything is fine (even if changes were made).
# Non-zero reserved for script errors only.
exit 0
