# tools/deactivate-redesign.sh

Compliant with [.config/ai/guidelines.md](file:.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

## Draft: tools/deactivate-redesign.sh
# Purpose
# -------
# Inverse helper for `tools/activate-redesign.sh`.
# Provides safe, reversible operations to disable the redesign environment injection
# and restore user zshenv/zshrc state created by the activation helper.
#
# This is a draft for review. It is intentionally conservative and non-destructive:
# - `--dry-run` shows actions without making changes.
# - `--disable` removes the injected snippet added by the activation helper (if present).
# - `--backup` creates a timestamped backup of targeted config files.
# - `--restore` restores the most recent backup created by this tool.
# - `--status` reports the presence of the redesign snippet and any backups found.
#
# Usage (draft)
# --------------
#  ./deactivate-redesign.sh --status
#  ./deactivate-redesign.sh --dry-run --disable
#  ./deactivate-redesign.sh --backup
#  ./deactivate-redesign.sh --disable --apply
#  ./deactivate-redesign.sh --restore
#
# Safety notes
# ------------
# - No files are deleted; backups are created before any modification.
# - The script only manipulates the user's zsh environment files that were
#   targeted by `activate-redesign.sh` (e.g., ~/.zshenv). It will not alter
#   other dotfiles unless explicitly instructed.
# - This draft intentionally mirrors the activation helper's injection markers so
#   it can reliably locate and remove the managed block.
#
# Implementation (draft script)
# -----------------------------
```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Configurable (matches activate-redesign.sh defaults)
ZSHENV_PATH_DEFAULT="${ZDOTDIR:-$HOME}/.zshenv"
BACKUP_DIR_DEFAULT="${HOME}/.local/share/zsh/redesign-migration"
SNIPPET_MARKER_START="# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>"
SNIPPET_MARKER_END="# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<"

# CLI flags
DRY_RUN=0
APPLY=0
CMD=""
VERBOSE=1
TARGET_ZSHENV="${ZSHENV_PATH_DEFAULT}"
BACKUP_DIR="${BACKUP_DIR_DEFAULT}"

log() {
  [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$@"
}

err() {
  printf 'ERROR: %s\n' "$@" >&2
}

print_help() {
  cat <<'EOF'
tools/deactivate-redesign.sh — Draft

Usage:
  ./deactivate-redesign.sh [--dry-run] <command> [--zshenv <path>] [--backup-dir <dir>] [--quiet]

Commands:
  --disable      Remove the managed redesign snippet from the target zshenv.
                 If --apply is set (or omitted when interactive), write changes.
  --backup       Create a timestamped backup of the target zshenv file.
  --restore      Restore the most recent backup created by this tool.
  --status       Print status: whether the snippet exists and list backups.
  --help         Show this help.

Flags:
  --dry-run      Print actions without modifying files.
  --apply        When paired with --disable, actually perform the removal.
  --zshenv PATH  Specify alternate zshenv file (defaults to $ZSHENV_PATH_DEFAULT).
  --backup-dir D Specify where backups are stored (defaults to $BACKUP_DIR_DEFAULT).
  --quiet        Suppress non-error messages.
EOF
}

# Minimal argument parsing (robustness left for final script)
if (( $# == 0 )); then
  print_help
  exit 0
fi

while (( $# )); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --apply) APPLY=1; shift;;
    --disable|--backup|--restore|--status) CMD="$1"; shift;;
    --zshenv) shift; TARGET_ZSHENV="$1"; shift;;
    --backup-dir) shift; BACKUP_DIR="$1"; shift;;
    --quiet) VERBOSE=0; shift;;
    --help|-h) print_help; exit 0;;
    *) err "Unknown argument: $1"; print_help; exit 1;;
  esac
done

# Helpers
timestamp() {
  date -u +%Y%m%dT%H%M%SZ 2>/dev/null || date +%s
}

ensure_backup_dir() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    if (( DRY_RUN )); then
      log "[dry-run] mkdir -p $BACKUP_DIR"
    else
      mkdir -p "$BACKUP_DIR"
    fi
  fi
}

list_backups() {
  if [[ -d "$BACKUP_DIR" ]]; then
    ls -1t "${BACKUP_DIR}" 2>/dev/null || true
  fi
}

latest_backup_for() {
  # returns the latest backup file path for the target zshenv (if any)
  local base
  base="$(basename "$TARGET_ZSHENV")"
  if [[ -d "$BACKUP_DIR" ]]; then
    # look for files starting with basename plus .bak or with timestamp
    local latest
    latest=$(ls -1t "${BACKUP_DIR}/${base}"* 2>/dev/null | head -n1 || true)
    printf '%s' "${latest:-}"
  fi
}

create_backup() {
  ensure_backup_dir
  local ts backupfile
  ts="$(timestamp)"
  backupfile="${BACKUP_DIR}/$(basename "$TARGET_ZSHENV").${ts}.bak"
  if (( DRY_RUN )); then
    log "[dry-run] cp ${TARGET_ZSHENV} ${backupfile}"
  else
    if [[ -f "$TARGET_ZSHENV" ]]; then
      cp -p "$TARGET_ZSHENV" "$backupfile"
      log "Backup created: $backupfile"
    else
      log "No target zshenv file found at ${TARGET_ZSHENV} — creating empty backup placeholder"
      printf '%s\n' "# placeholder backup (no original file present)" > "$backupfile"
      log "Placeholder backup created: $backupfile"
    fi
  fi
  printf '%s' "$backupfile"
}

remove_snippet_from_file() {
  local file="$1"
  local start="$SNIPPET_MARKER_START"
  local end="$SNIPPET_MARKER_END"

  if ! grep -qF "$start" "$file" 2>/dev/null; then
    log "No redesign injection marker found in ${file}"
    return 0
  fi

  if (( DRY_RUN )); then
    log "[dry-run] Would remove redesign snippet block from ${file} (markers: start=${start} end=${end})"
    return 0
  fi

  # Create a safe temporary file and rewrite without the snippet block.
  local tmp="${file}.tmp.deactivate.$$"
  awk -v s="$start" -v e="$end" '
    BEGIN{inblock=0}
    $0==s{inblock=1; next}
    inblock && $0==e{inblock=0; next}
    !inblock{print $0}
  ' "$file" > "$tmp"
  # Ensure write succeeded before overwriting
  if [[ -s "$tmp" ]]; then
    mv "$tmp" "$file"
    log "Removed redesign snippet from ${file}"
  else
    rm -f "$tmp"
    err "Failed to safely rewrite ${file}; aborting"
    return 1
  fi
}

restore_backup() {
  local backupfile="$1"
  if [[ -z "$backupfile" || ! -f "$backupfile" ]]; then
    err "No valid backup file specified: ${backupfile}"
    return 1
  fi
  if (( DRY_RUN )); then
    log "[dry-run] cp ${backupfile} ${TARGET_ZSHENV}"
  else
    cp -p "$backupfile" "$TARGET_ZSHENV"
    log "Restored ${TARGET_ZSHENV} from ${backupfile}"
  fi
}

# Execute the requested command
case "$CMD" in
  --status)
    log "Target zshenv: $TARGET_ZSHENV"
    if [[ -f "$TARGET_ZSHENV" ]]; then
      if grep -qF "$SNIPPET_MARKER_START" "$TARGET_ZSHENV" 2>/dev/null; then
        log "Status: redesign snippet PRESENT in $TARGET_ZSHENV"
      else
        log "Status: redesign snippet NOT found in $TARGET_ZSHENV"
      fi
    else
      log "Status: target zshenv file does not exist: $TARGET_ZSHENV"
    fi
    log "Backups directory: $BACKUP_DIR"
    log "Recent backups:"
    list_backups || true
    ;;
  --backup)
    create_backup >/dev/null || true
    ;;
  --disable)
    # create a backup before making changes
    local latest_backup
    latest_backup="$(create_backup)"
    if (( APPLY == 0 )); then
      log "--disable was requested without --apply: performing dry preview only"
      log "Backup created (preview): ${latest_backup}"
      if (( DRY_RUN == 0 )); then
        log "To actually remove the snippet, rerun with --apply"
      fi
      exit 0
    fi
    if [[ ! -f "$TARGET_ZSHENV" ]]; then
      log "Target zshenv not found at ${TARGET_ZSHENV}; nothing to remove, backup created at ${latest_backup}"
      exit 0
    fi
    remove_snippet_from_file "$TARGET_ZSHENV"
    ;;
  --restore)
    local latest
    latest="$(latest_backup_for)"
    if [[ -z "$latest" ]]; then
      err "No backups found in ${BACKUP_DIR} for ${TARGET_ZSHENV}"
      exit 1
    fi
    restore_backup "$latest"
    ;;
  *)
    err "Unknown or missing command. See --help"
    exit 1
    ;;
esac

exit 0

```

# End of draft deactivate-redesign.sh
# ---------------------------------------------------------------------------
# Developer notes / review items:
# - The precise snippet markers used here must match activate-redesign.sh exactly.
# - For the final implementation we should:
#   * Add stronger argument validation and unit tests for the file rewrite logic.
#   * Preserve file permissions/ownership when restoring backups.
#   * Optionally support a `--target FILE` flag to operate on zshrc/zprofile in addition to zshenv.
#   * Consider a safe confirmation prompt when not running in --dry-run mode (or provide --yes).
#
# - This draft intentionally avoids making destructive calls; the real script will be
#   implemented only after you approve the draft and the exact marker strings are
#   validated against the activation script.
