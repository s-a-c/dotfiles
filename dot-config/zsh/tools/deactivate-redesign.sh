#!/usr/bin/env zsh
# tools/deactivate-redesign.sh
#
# Inverse helper for tools/activate-redesign.sh
#
# Purpose:
#  - Remove the managed redesign injection snippet from the user's zshenv.
#  - Create/restore backups created by the activation/migration helpers.
#  - Provide dry-run preview and status reporting.
#
# Safety:
#  - Non-destructive by default; backups are created before any modification.
#  - Uses markers identical to the activation/migration helpers so removal is reliable.
#  - Does not attempt to modify anything outside the target zshenv unless explicitly told.
#
# Usage (examples):
#  ./tools/deactivate-redesign.sh --status
#  ./tools/deactivate-redesign.sh --dry-run --disable
#  ./tools/deactivate-redesign.sh --backup
#  ./tools/deactivate-redesign.sh --disable --apply
#  ./tools/deactivate-redesign.sh --restore
#
# Defaults:
: "${ZSHENV_PATH:=${ZDOTDIR:-$HOME}/.zshenv}"
: "${BACKUP_DIR:=${HOME}/.local/share/zsh/redesign-migration}"

SNIPPET_START="# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>"
SNIPPET_END="# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<"

set -euo pipefail

DRY_RUN=0
APPLY=0
QUIET=0
CMD=""

print_help() {
  cat <<'EOF'
tools/deactivate-redesign.sh — inverse of activate/migrate helpers

Usage:
  ./tools/deactivate-redesign.sh [--dry-run] <command> [--zshenv <path>] [--backup-dir <dir>] [--quiet]

Commands:
  --disable      Remove the managed redesign snippet from the target zshenv.
                 If --apply is used, perform the change; otherwise show a dry-run preview.
  --backup       Create a timestamped backup of the target zshenv and exit.
  --restore      Restore the most recent backup created by this tool for the target zshenv.
  --status       Report whether the snippet exists and list available backups.
  --help         Show this help.

Flags:
  --dry-run      Print actions without making changes.
  --apply        When used with --disable, actually remove the snippet (default is dry-run).
  --zshenv PATH  Operate on a specific zshenv (default: $ZSHENV_PATH).
  --backup-dir D Use alternate backup directory (default: $BACKUP_DIR).
  --quiet        Suppress informational output.
EOF
}

log() { (( QUIET )) || printf '%s\n' "$@"; }
err() { printf 'ERROR: %s\n' "$@" >&2; }

timestamp() { date -u +%Y%m%dT%H%M%SZ 2>/dev/null || date +%s; }

ensure_backup_dir() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    if (( DRY_RUN )); then
      log "[dry-run] mkdir -p $BACKUP_DIR"
    else
      mkdir -p "$BACKUP_DIR"
    fi
  fi
}

create_backup() {
  ensure_backup_dir
  local ts backupfile target
  ts="$(timestamp)"
  target="$ZSHENV_PATH"
  backupfile="${BACKUP_DIR}/$(basename "$target").${ts}.bak"
  if (( DRY_RUN )); then
    log "[dry-run] cp -p \"$target\" \"$backupfile\""
    printf '%s' "$backupfile"
    return 0
  fi

  if [[ -f "$target" ]]; then
    cp -p "$target" "$backupfile"
    log "Backup created: $backupfile"
  else
    # create a placeholder backup to make restore possible
    printf '%s\n' "# placeholder backup created by deactivate-redesign at $ts" >"$backupfile"
    log "Placeholder backup created (target absent): $backupfile"
  fi
  printf '%s' "$backupfile"
}

list_backups() {
  if [[ -d "$BACKUP_DIR" ]]; then
    ls -1t "${BACKUP_DIR}/$(basename "$ZSHENV_PATH")."* 2>/dev/null || true
  else
    true
  fi
}

latest_backup() {
  if [[ -d "$BACKUP_DIR" ]]; then
    ls -1t "${BACKUP_DIR}/$(basename "$ZSHENV_PATH")."* 2>/dev/null | head -n1 || true
  fi
}

snippet_present() {
  if [[ -f "$ZSHENV_PATH" ]] && grep -qF "$SNIPPET_START" "$ZSHENV_PATH" 2>/dev/null; then
    return 0
  fi
  return 1
}

preview_removal_patch() {
  # Show unified diff between current file and the file after snippet removal
  local tmp_before tmp_after
  tmp_before="$(mktemp -t deactivate_before.XXXX 2>/dev/null || mktemp)"
  tmp_after="$(mktemp -t deactivate_after.XXXX 2>/dev/null || mktemp)"
  if [[ -f "$ZSHENV_PATH" ]]; then
    cat "$ZSHENV_PATH" >"$tmp_before"
  else
    printf '%s\n' "# (empty target)" >"$tmp_before"
  fi

  # Remove block between markers and produce tmp_after
  awk -v start="$SNIPPET_START" -v end="$SNIPPET_END" '
    BEGIN { inblock = 0 }
    $0 == start { inblock = 1; next }
    inblock && $0 == end { inblock = 0; next }
    !inblock { print $0 }
  ' "$tmp_before" >"$tmp_after"

  if command -v diff >/dev/null 2>&1; then
    printf '---- DRY-RUN: unified diff (before -> after) ----\n'
    diff -u "$tmp_before" "$tmp_after" || true
  else
    printf '---- DRY-RUN: before ----\n'; cat "$tmp_before"
    printf '---- DRY-RUN: after ----\n'; cat "$tmp_after"
  fi

  rm -f "$tmp_before" "$tmp_after" || true
}

remove_snippet() {
  # Safely remove the snippet block from the target file using awk to avoid sed pitfalls.
  if ! [[ -f "$ZSHENV_PATH" ]]; then
    log "Target file not found: $ZSHENV_PATH (nothing to remove)"
    return 0
  fi

  if ! snippet_present; then
    log "No redesign snippet found in $ZSHENV_PATH"
    return 0
  fi

  if (( DRY_RUN )); then
    log "[dry-run] would remove redesign snippet from $ZSHENV_PATH"
    preview_removal_patch
    return 0
  fi

  local tmp
  tmp="${ZSHENV_PATH}.tmp.deactivate.$$"
  awk -v start="$SNIPPET_START" -v end="$SNIPPET_END" '
    BEGIN { inblock = 0 }
    $0 == start { inblock = 1; next }
    inblock && $0 == end { inblock = 0; next }
    !inblock { print $0 }
  ' "$ZSHENV_PATH" >"$tmp"

  # Verify the tmp file was created and is not empty (at least safe)
  if [[ -s "$tmp" ]]; then
    mv "$tmp" "$ZSHENV_PATH"
    log "Removed redesign snippet from $ZSHENV_PATH"
    return 0
  else
    rm -f "$tmp" 2>/dev/null || true
    err "Failed to safely rewrite $ZSHENV_PATH; aborting"
    return 1
  fi
}

restore_backup() {
  local backup
  backup="$(latest_backup)"
  if [[ -z "$backup" ]]; then
    err "No backups found in $BACKUP_DIR for $(basename "$ZSHENV_PATH")"
    return 2
  fi

  if (( DRY_RUN )); then
    log "[dry-run] would restore $backup -> $ZSHENV_PATH"
    return 0
  fi

  cp -p "$backup" "$ZSHENV_PATH"
  log "Restored $ZSHENV_PATH from $backup"
}

# -- parse args
if (( $# == 0 )); then
  print_help
  exit 0
fi

while (( $# )); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --apply) APPLY=1; shift;;
    --disable|--backup|--restore|--status) CMD="$1"; shift;;
    --zshenv) shift; ZSHENV_PATH="$1"; shift;;
    --backup-dir) shift; BACKUP_DIR="$1"; shift;;
    --quiet) QUIET=1; shift;;
    --help|-h) print_help; exit 0;;
    *) err "Unknown argument: $1"; print_help; exit 2;;
  esac
done

case "$CMD" in
  --status)
    log "Target zshenv: $ZSHENV_PATH"
    if [[ -f "$ZSHENV_PATH" ]]; then
      if snippet_present; then
        log "Status: redesign snippet PRESENT in $ZSHENV_PATH"
      else
        log "Status: redesign snippet NOT present in $ZSHENV_PATH"
      fi
    else
      log "Status: target zshenv does not exist: $ZSHENV_PATH"
    fi
    log "Backups directory: $BACKUP_DIR"
    log "Recent backups for this target (newest first):"
    list_backups || true
    exit 0
    ;;
  --backup)
    create_backup >/dev/null
    exit 0
    ;;
  --disable)
    # create backup first
    create_backup >/dev/null
    if (( APPLY == 0 && DRY_RUN == 0 )); then
      # If neither apply nor dry-run explicitly requested, default to dry-run behavior
      DRY_RUN=1
    fi

    if (( APPLY == 0 )); then
      # Dry-run preview
      preview_removal_patch
      log "Dry-run complete. To actually remove the snippet, re-run with --disable --apply"
      exit 0
    fi

    # Actual removal
    if (( DRY_RUN )); then
      log "[dry-run] backup created; would remove snippet"
      preview_removal_patch
      exit 0
    fi

    remove_snippet
    exit $?
    ;;
  --restore)
    if (( DRY_RUN )); then
      log "[dry-run] would restore latest backup (no changes)"
      latest_backup || true
      exit 0
    fi
    restore_backup
    exit $?
    ;;
  *)
    err "No valid command specified."
    print_help
    exit 2
    ;;
esac
