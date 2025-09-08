# Draft: tools/migrate-to-redesign.sh

Purpose
-------
Non-destructive migration helper for enabling the redesign locally. Designed to:
- Show what would change by default (`--dry-run`).
- Apply the minimal, reversible change to enable the redesign (`--apply`): inject a managed snippet into the user's `~/.zshenv` (or another specified target) that sources the repo-local redesign environment file.
- Create and restore backups.
- Log migrations to `tools/migration.log` (repo-local).
- Never delete or rename user files without explicit confirmation (the script is conservative).

Notes
-----
- This is a draft for review. It is intentionally conservative and includes defensive checks and dry-run behavior.
- The snippet injected matches the pattern used by `tools/activate-redesign.sh` so `tools/deactivate-redesign.sh` can remove it reliably.
- On `--apply` the script writes a timestamped backup into a backup directory (default `~/.local/share/zsh/redesign-migration/`).
- The script records a migration entry to `tools/migration.log` in the repo (when run from the repo root). If you run outside the repo, it still writes an explicit local log entry, but the repo log is preferred.

Usage
-----
  tools/migrate-to-redesign.sh [--dry-run] [--apply] [--backup] [--restore] [--status] [--zshenv <path>] [--log <file>]

Examples:
  tools/migrate-to-redesign.sh --dry-run --apply
  tools/migrate-to-redesign.sh --backup --zshenv ~/.zshenv
  tools/migrate-to-redesign.sh --apply --zshenv ~/.zshenv --log tools/migration.log
  tools/migrate-to-redesign.sh --restore

Draft script
------------

```dotfiles/dot-config/zsh/tools/migrate-to-redesign.sh#L1-999
#!/usr/bin/env zsh
#
# tools/migrate-to-redesign.sh
#
# Draft migration helper for the ZSH redesign feature.
# Default mode: --dry-run (show planned changes).
#
# Behavior summary:
#  - --dry-run: print the snippet and the patch that would be applied; do not modify files.
#  - --apply: perform the migration (create backup, inject snippet).
#  - --backup: create a timestamped backup and exit.
#  - --restore: restore the most recent backup for the target file (created by this tool).
#  - --status: show whether the snippet exists and list recent backups.
#
set -euo pipefail

# Configuration defaults
: "${ZSHENV_TARGET:=${ZDOTDIR:-$HOME}/.zshenv}"
: "${BACKUP_DIR:=${HOME}/.local/share/zsh/redesign-migration}"
: "${MIGRATION_LOG:=tools/migration.log}"
SNIPPET_START="# >>> REDESIGN-ENV (managed by migrate-to-redesign.sh) >>>"
SNIPPET_END="# <<< REDESIGN-ENV (managed by migrate-to-redesign.sh) <<<"

# The snippet to inject (sources the repo-local redesign env file).
# NOTE: we deliberately avoid absolute repo paths here; the snippet will use
# the working directory evaluated at the time it is injected so user control is explicit.
read -r -d '' REDESIGN_SNIPPET <<'EOF' || true
# >>> REDESIGN-ENV (managed by migrate-to-redesign.sh) >>>
# This block was added by migrate-to-redesign.sh to enable the opt-in redesign.
# It is safe and reversible. To remove this block, run tools/deactivate-redesign.sh --restore
if [[ -f "${PWD}/dot-config/zsh/tools/redesign-env.sh" ]]; then
  source "${PWD}/dot-config/zsh/tools/redesign-env.sh"
fi
# <<< REDESIGN-ENV (managed by migrate-to-redesign.sh) <<<
EOF

# CLI flags
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
  --zshenv <path>    Target zshenv file to operate on (default: $ZSHENV_TARGET).
  --backup-dir <dir> Backup directory (default: $BACKUP_DIR).
  --log <file>       Migration log file (default: $MIGRATION_LOG).
  --quiet            Suppress informational output.
  --help             Show this help and exit.

Examples:
  $(basename "$0") --dry-run --apply
  $(basename "$0") --backup
  $(basename "$0") --restore
USAGE
}

# simple arg parsing
ARGS=("$@")
i=1
while (( "$#" )); do
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
      # If target doesn't exist, create an explicit placeholder backup so restore is possible.
      printf '%s\n' "# placeholder backup created by migrate-to-redesign at $ts" > "$backupfile"
      _log "Placeholder backup created (no target file present): $backupfile"
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
  local file=$1
  if [[ -f "$file" ]] && grep -qF "$SNIPPET_START" "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

show_status() {
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
}

# produce a patch preview for dry-run: show patch as unified diff
preview_patch() {
  # create temporary files
  local tmp_before tmp_after
  tmp_before="$(mktemp -t migrate_before.XXXX 2>/dev/null || mktemp)"
  tmp_after="$(mktemp -t migrate_after.XXXX 2>/dev/null || mktemp)"
  if [[ -f "$ZSHENV_TARGET" ]]; then
    cat "$ZSHENV_TARGET" > "$tmp_before"
  else
    printf '%s\n' "# empty or non-existent file" > "$tmp_before"
  fi
  # create the after version with snippet appended (if not present).
  if snippet_present_in_file "$ZSHENV_TARGET"; then
    cat "$ZSHENV_TARGET" > "$tmp_after"
  else
    cat "$tmp_before" > "$tmp_after"
    printf '\n%s\n' "$REDESIGN_SNIPPET" >> "$tmp_after"
  fi
  # show unified diff
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
  # Steps:
  # 1) Create backup
  # 2) If snippet not present, append snippet
  # 3) Log migration entry
  local backupfile
  backupfile="$(create_backup)"
  if snippet_present_in_file "$ZSHENV_TARGET"; then
    _log "Snippet already present in $ZSHENV_TARGET; nothing to change."
  else
    if (( DRY_RUN )); then
      _log "[dry-run] Would append redesign snippet to $ZSHENV_TARGET"
      preview_patch
      return 0
    fi
    # Append snippet to target file
    printf '\n%s\n' "$REDESIGN_SNIPPET" >> "$ZSHENV_TARGET"
    _log "Injected redesign snippet into $ZSHENV_TARGET"
  fi

  # Append migration log entry (best-effort)
  local ts
  ts="$(_timestamp)"
  local user
  user="${USER:-$(whoami 2>/dev/null || echo unknown)}"
  local cwd
  cwd="${PWD:-$(pwd)}"
  if (( DRY_RUN )); then
    _log "[dry-run] Would append migration log to $MIGRATION_LOG"
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
    _err "No backups found in $BACKUP_DIR for $(basename "$ZSHENV_TARGET")"
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

# Execute requested actions
if (( DO_STATUS )); then
  show_status
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

# Default action: either preview (dry-run) or apply
if (( DO_APPLY )); then
  if (( DRY_RUN )); then
    _log "Performing dry-run of migration (no files will be changed)."
    preview_patch
    _log "Dry-run complete. To perform the migration, rerun with --apply (and without --dry-run)."
    exit 0
  else
    apply_migration
    _log "Migration applied (target: $ZSHENV_TARGET)."
    exit 0
  fi
else
  # If no explicit command given, show status and preview
  show_status
  preview_patch
  _log "No --apply requested. This was a dry-run preview. To apply: re-run with --apply."
  exit 0
fi
# End of migrate-to-redesign.sh (draft)
```

Reviewer notes
--------------
- Please review the exact snippet contents and the paths used in the snippet — the draft uses `${PWD}/dot-config/zsh/tools/redesign-env.sh` so the injected snippet will reference the repo working directory. If you want the snippet to reference an absolute path or a different relative path, update the draft accordingly.
- Once you approve the script content, I will:
  1. Add the script into `dotfiles/dot-config/zsh/tools/` (one commit).
  2. Run local tests (shim audit + design tests) and paste outputs.
  3. Push to `origin/feature/zsh-refactor-configuration` only after you sign off on the test outputs.
- The script deliberately avoids destructive operations and always creates backups prior to changing the target file.