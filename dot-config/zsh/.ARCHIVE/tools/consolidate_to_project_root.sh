#!/bin/zsh
# Consolidate ZSH redesign scripts and tests from repo root to project root, with subdirectory and dry-run support
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

set -e

REPO_ROOT="$HOME/dotfiles"
PROJECT_ROOT="$HOME/dotfiles/dot-config/zsh"

usage() {
  echo "Usage: $0 [--dry-run]"
  echo "  --dry-run   Only show what would be moved/copied, do not perform any changes"
  exit 1
}

DRY_RUN=0
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ -n "$1" ]]; then
  usage
fi

move_dir() {
  local src_dir="$1"
  local dest_dir="$2"
  local label="$3"

  if [ ! -d "$src_dir" ]; then
    echo "$label: Source directory $src_dir does not exist, skipping."
    return
  fi

  mkdir -p "$dest_dir"

  # Find all files and directories recursively
  find "$src_dir" -mindepth 1 | while read src_path; do
    rel_path="${src_path#$src_dir/}"
    dest_path="$dest_dir/$rel_path"

    if [ -d "$src_path" ]; then
      mkdir -p "$dest_path"
      continue
    fi

    if [ ! -e "$dest_path" ]; then
      if [ $DRY_RUN -eq 1 ]; then
        echo "[DRY-RUN] Would move: $src_path -> $dest_path"
      else
        mkdir -p "$(dirname "$dest_path")"
        mv "$src_path" "$dest_path"
        echo "Moved: $src_path -> $dest_path"
      fi
    else
      echo "Skipped (already exists): $dest_path"
    fi
  done
}

echo "Consolidating scripts from $REPO_ROOT/tools to $PROJECT_ROOT/tools ..."
move_dir "$REPO_ROOT/tools" "$PROJECT_ROOT/tools" "Scripts"

echo "Consolidating tests from $REPO_ROOT/tests to $PROJECT_ROOT/tests ..."
move_dir "$REPO_ROOT/tests" "$PROJECT_ROOT/tests" "Tests"

echo "Consolidation complete."
if [ $DRY_RUN -eq 1 ]; then
  echo "No changes were made (dry-run mode)."
else
  echo "Please update documentation and CI workflows to reference $PROJECT_ROOT."
fi
