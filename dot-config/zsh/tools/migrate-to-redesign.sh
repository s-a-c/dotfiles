#!/usr/bin/env zsh
# tools/migrate-to-redesign.sh
#
# Non-destructive migration helper to enable the ZSH redesign locally.
# Default: dry-run (show planned changes).
#
# Capabilities:
#  - --dry-run (default): preview the patch that would be applied.
#  - --apply: perform migration (create backup, inject managed snippet).
#  - --backup: create a timestamped backup of the target file.
#  - --restore: restore the most recent backup created by this tool.
#  - --status: show whether the snippet exists and list recent backups.
#
# Safety:
#  - Always creates backups before modifying files.
#  - Uses conservative, reversible injection (append-only snippet).
#  - Does not delete or rename user files.
#
# Usage:
#   ./tools/migrate-to-redesign.sh --dry-run
#   ./tools/migrate-to-redesign.sh --apply
#   ./tools/migrate-to-redesign.sh --backup
#   ./tools/migrate-to-redesign.sh --restore
#   ./tools/migrate-to-redesign.sh --status
#
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49

set -euo pipefail

# Defaults (can be overridden with flags)
: "${ZSHENV_TARGET:=${ZDOTDIR:-$HOME}/.zshenv}"
: "${BACKUP_DIR:=${HOME}/.local/share/zsh/redesign-migration}"
: "${MIGRATION_LOG:=tools/migration.log}"

# Use the same marker that activate-redesign.sh uses so deactivate helpers can find and remove it
SNIPPET_START="# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>"
SNIPPET_END="# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<"

read -r -d '' REDESIGN_SNIPPET <<'EOF' || true
# >>> REDESIGN-ENV (managed by activate-redesign.sh) >>>
# This block was added by migrate-to-redesign.sh to enable the opt-in redesign.
# It is safe and reversible. To remove this block, run tools/deactivate-redesign.sh --disable
if [[ -f "${PWD}/dot-config/zsh/tools/redesign-env.sh" ]]; then
  source "${PWD}/dot-config/zsh/tools/redesign-env.sh"
fi
# <<< REDESIGN-ENV (managed by activate-redesign.sh) <<<
EOF

DRY_RUN=1
DO_APPLY=0
DO_BACKUP=0
DO_RESTORE=0
DO_STATUS=0
QUIET=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --dry-run          Show planned changes (default).
  --apply            Apply migration: backup and inject snippet.
  --backup           Create a timestamped backup of the target file and exit.
  --restore          Restore the most recent backup created by this tool for the target file.
  --status           Show snippet presence and list backups.
  --zshenv <path>    Target zshenv file to operate on (default: ${ZSHENV_TARGET}).
  --backup-dir <dir> Backup directory (default: ${BACKUP_DIR}).
  --log <file>       Migration log file (default: ${MIGRATION_LOG}).
  --quiet            Suppress informational output.
  --help             Show this help and exit.

Examples:
  $(basename "$0") --dry-run --apply
  $(basename "$0") --backup
  $(basename "$0") --restore
USAGE
}

# ---- arg parsing ----
if (( $# == 0 )); then
  usage
  exit 0
fi

while (( $# )); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --apply) DO_APPLY=1; DRY_RUN=0; shift;;
    --backup) DO_BACKUP=1; shift;;
    --restore) DO_RESTORE=1; shift;;
    --status) DO_STATUS=1; shift;;
    --zshenv) shift; ZSHENV_TARGET="$1"; shift;;
    --backup-dir) shift; BACKUP_DIR="$1"; shift;;
    --log) shift; MIGRATION_LOG="$1"; shift;;
    --quiet) QUIET=1; shift;;
    --help|-h) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

_log() {
  (( QUIET )) || printf '%s\n' "$@"
}
_err() {
  printf 'ERROR: %s\n' "$@" >&2
}

_timestamp() {
  date -u +%Y%m%dT%H%M%SZ 2>/dev/null || date +%s
}

ensure_backup_dir() {
  if [[ ! -d "$BACKUP_DIR" ]]; then
    if (( DRY_RUN )); then
      _log "[dry-run] mkdir -p $BACKUP_DIR"
    else
      mkdir -p "$BACKUP_DIR"
    fi
  fi
}

create_backup() {
  ensure_backup_dir
  local ts backupfile
  ts="$(_timestamp)"
  backupfile="${BACKUP_DIR}/$(basename "$ZSHENV_TARGET").${ts}.bak"
  if (( DRY_RUN )); then
    _log "[dry-run] cp '$ZSHENV_TARGET' '$backupfile'"
  else
    if [[ -f "$ZSHENV_TARGET" ]]; then
      cp -p "$ZSHENV_TARGET" "$backupfile"
      _log "Backup created: $backupfile"
    else
      # create placeholder backup to allow restore
      printf '%s\n' "# placeholder backup created by migrate-to-redesign at $ts" > "$backupfile"
      _log "Placeholder backup created (target missing): $backupfile"
    fi
  fi
  printf '%s' "$backupfile"
}

latest_backup() {
  if [[ -d "$BACKUP_DIR" ]]; then
    ls -1t "${BACKUP_DIR}/$(basename "$ZSHENV_TARGET")."* 2>/dev/null | head -n1 || true
  fi
}

snippet_present_in_file() {
  local file="$1"
  if [[ -f "$file" ]] && grep -qF "${SNIPPET_START}" "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

preview_patch() {
  # Show unified diff between current target and target+snippet (for dry-run)
  local tmp_before tmp_after
  tmp_before="$(mktemp -t migrate_before.XXXX 2>/dev/null || mktemp)"
  tmp_after="$(mktemp -t migrate_after.XXXX 2>/dev/null || mktemp)"
  if [[ -f "$ZSHENV_TARGET" ]]; then
    cat "$ZSHENV_TARGET" > "$tmp_before"
  else
    printf '%s\n' "# (empty target file)" > "$tmp_before"
  fi

  if snippet_present_in_file "$ZSHENV_TARGET"; then
    cat "$ZSHENV_TARGET" > "$tmp_after"
  else
    cat "$tmp_before" > "$tmp_after"
    printf '\n%s\n' "$REDESIGN_SNIPPET" >> "$tmp_after"
  fi

  if command -v diff >/dev/null 2>&1; then
    _log "---- DRY-RUN: patch preview (unified diff) ----"
    diff -u "$tmp_before" "$tmp_after" || true
  else
    _log "---- DRY-RUN: target file (before) ----"
    cat "$tmp_before"
    _log "---- DRY-RUN: target file (after) ----"
    cat "$tmp_after"
  fi

  rm -f "$tmp_before" "$tmp_after" || true
}

apply_migration() {
  # 1) create backup
  local backupfile
  backupfile="$(create_backup)"
  # 2) inject snippet if not present
  if snippet_present_in_file "$ZSHENV_TARGET"; then
    _log "Snippet already present in $ZSHENV_TARGET; nothing to apply."
  else
    if (( DRY_RUN )); then
      _log "[dry-run] would append redesign snippet to $ZSHENV_TARGET"
      preview_patch
      return 0
    fi
    # Ensure target file exists (create if missing)
    if [[ ! -f "$ZSHENV_TARGET" ]]; then
      # create parent dir if needed
      mkdir -p "$(dirname "$ZSHENV_TARGET")" 2>/dev/null || true
      touch "$ZSHENV_TARGET"
    fi
    # Append snippet
    printf '\n%s\n' "$REDESIGN_SNIPPET" >> "$ZSHENV_TARGET"
    _log "Injected redesign snippet into $ZSHENV_TARGET"
  fi

  # 3) log migration entry (repo-local, best-effort)
  local ts user cwd
  ts="$(_timestamp)"
  user="${USER:-$(whoami 2>/dev/null || echo unknown)}"
  cwd="${PWD:-$(pwd)}"
  if (( DRY_RUN )); then
    _log "[dry-run] would record migration to $MIGRATION_LOG"
  else
    mkdir -p "$(dirname "$MIGRATION_LOG")" 2>/dev/null || true
    printf '%s %s migrate apply target=%s backup=%s cwd=%s\n' "$ts" "$user" "$ZSHENV_TARGET" "$backupfile" "$cwd" >> "$MIGRATION_LOG"
    _log "Recorded migration to $MIGRATION_LOG"
  fi
}

restore_migration() {
  local latest
  latest="$(latest_backup)"
  if [[ -z "$latest" ]]; then
    _err "No backups found in ${BACKUP_DIR} for $(basename "$ZSHENV_TARGET")"
    return 2
  fi
  if (( DRY_RUN )); then
    _log "[dry-run] Would restore backup: $latest -> $ZSHENV_TARGET"
    return 0
  fi
  cp -p "$latest" "$ZSHENV_TARGET"
  _log "Restored $ZSHENV_TARGET from $latest"

  # record restore in migration log
  local ts user cwd
  ts="$(_timestamp)"; user="${USER:-$(whoami 2>/dev/null || echo unknown)}"; cwd="${PWD:-$(pwd)}"
  mkdir -p "$(dirname "$MIGRATION_LOG")" 2>/dev/null || true
  printf '%s %s migrate restore target=%s backup=%s cwd=%s\n' "$ts" "$user" "$ZSHENV_TARGET" "$latest" "$cwd" >> "$MIGRATION_LOG"
}

# ----- Execute requested actions -----
if (( DO_STATUS )); then
  _log "Target: $ZSHENV_TARGET"
  if [[ -f "$ZSHENV_TARGET" ]]; then
    if snippet_present_in_file "$ZSHENV_TARGET"; then
      _log "Status: Redesign snippet PRESENT in $ZSHENV_TARGET"
    else
      _log "Status: Redesign snippet NOT present in $ZSHENV_TARGET"
    fi
  else
    _log "Status: Target file does not exist: $ZSHENV_TARGET"
  fi
  _log "Backups directory: $BACKUP_DIR"
  _log "Recent backups:"
  ls -1t "${BACKUP_DIR}/" 2>/dev/null | grep "$(basename "$ZSHENV_TARGET")" || _log "  (none)"
  exit 0
fi

if (( DO_BACKUP )); then
  create_backup >/dev/null
  exit 0
fi

if (( DO_RESTORE )); then
  restore_migration
  exit $?
fi

# Default action: apply or preview
if (( DO_APPLY )); then
  if (( DRY_RUN )); then
    _log "Performing dry-run of migration (no files will be changed)."
    preview_patch
    _log "Dry-run complete. To perform the migration, re-run with --apply (and without --dry-run)."
    exit 0
  else
    apply_migration
    _log "Migration applied (target: $ZSHENV_TARGET)."
    exit 0
  fi
else
  # No explicit command: show status and preview patch
  _log "No action requested; showing status and a dry-run preview."
  _log "Target: $ZSHENV_TARGET"
  show_status() {
    if [[ -f "$ZSHENV_TARGET" ]]; then
      if snippet_present_in_file "$ZSHENV_TARGET"; then
        _log "Status: Redesign snippet PRESENT in $ZSHENV_TARGET"
      else
        _log "Status: Redesign snippet NOT present in $ZSHENV_TARGET"
      fi
    else
      _log "Status: Target file does not exist: $ZSHENV_TARGET"
    fi
    _log "Backups directory: $BACKUP_DIR"
    _log "Recent backups:"
    ls -1t "${BACKUP_DIR}/" 2>/dev/null | grep "$(basename "$ZSHENV_TARGET")" || _log "  (none)"
  }
  show_status
  preview_patch
  _log "Dry-run preview complete. To apply the migration, re-run with --apply."
  exit 0
fi
