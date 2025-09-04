#!/usr/bin/env bash
# ensure-zgenom-symlink.sh
# Create a compatibility symlink `.zgenom -> zgenom` either in the repo (repo mode)
# or in the runtime/stowed configuration directory (runtime mode).
#
# This script prefers an explicitly provided ZDOTDIR via --zdotdir, then the
# environment variable $ZDOTDIR, and finally falls back to XDG defaults.
#
# Usage:
#   ./ensure-zgenom-symlink.sh                 # runtime mode (default)
#   ./ensure-zgenom-symlink.sh --repo          # create symlink inside the repo
#   ./ensure-zgenom-symlink.sh --target /path  # create symlink at /path/.zgenom -> /path/zgenom
#   ./ensure-zgenom-symlink.sh --zdotdir /my/zdotdir
#   ./ensure-zgenom-symlink.sh --dry-run
#   ./ensure-zgenom-symlink.sh --force
#
# Behavior:
# - If the symlink already exists and points to the expected target: nothing done.
# - If a non-symlink file/directory exists at the link path, script refuses unless --force,
#   in which case the existing path is moved to a timestamped backup and replaced.
# - Dry-run prints actions without performing them.
#
# Exit codes:
#  0 - success (or nothing to do)
#  1 - generic error / invalid args / precondition failure
#  2 - user aborted / nothing done because of missing preconditions (non-fatal)
set -euo pipefail

# Determine repository root (one level up from this script's directory)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"

# Default runtime dir fallback (if no ZDOTDIR provided)
DEFAULT_RUNTIME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

MODE="runtime" # runtime or repo
TARGET_DIR=""
DRY_RUN=0
FORCE=0
OVERRIDE_ZDOTDIR=""

print_usage() {
    cat <<EOF
ensure-zgenom-symlink.sh - create .zgenom -> zgenom compatibility symlink

Usage:
  $(basename "$0") [OPTIONS]

Options:
  --repo               Create symlink inside the repository (REPO_DIR/.zgenom -> REPO_DIR/zgenom)
  --runtime            Create symlink in the runtime/stowed dir (default)
  --target DIR         Create symlink at DIR/.zgenom -> DIR/zgenom
  --zdotdir DIR        Explicit runtime ZDOTDIR to use (preferred over env)
  --force              If something exists at the link location, back it up and replace it
  --dry-run            Print what would be done, do not modify filesystem
  --help               Show this help
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
    --repo)
        MODE="repo"
        shift
        ;;
    --runtime)
        MODE="runtime"
        shift
        ;;
    --target)
        if [[ -z "${2:-}" ]]; then
            echo "Error: --target requires a directory argument" >&2
            exit 1
        fi
        TARGET_DIR="$2"
        shift 2
        ;;
    --zdotdir)
        if [[ -z "${2:-}" ]]; then
            echo "Error: --zdotdir requires a directory argument" >&2
            exit 1
        fi
        OVERRIDE_ZDOTDIR="$2"
        shift 2
        ;;
    --force)
        FORCE=1
        shift
        ;;
    --dry-run)
        DRY_RUN=1
        shift
        ;;
    --help | -h)
        print_usage
        exit 0
        ;;
    *)
        echo "Unknown argument: $1" >&2
        print_usage
        exit 1
        ;;
    esac
done

# Compute base directory
if [[ -n "$TARGET_DIR" ]]; then
    BASE_DIR="$TARGET_DIR"
else
    if [[ "$MODE" == "repo" ]]; then
        BASE_DIR="$REPO_DIR"
    else
        # runtime: prefer override, then env ZDOTDIR, then XDG default
        if [[ -n "${OVERRIDE_ZDOTDIR:-}" ]]; then
            BASE_DIR="$OVERRIDE_ZDOTDIR"
        elif [[ -n "${ZDOTDIR:-}" ]]; then
            BASE_DIR="$ZDOTDIR"
        else
            BASE_DIR="$DEFAULT_RUNTIME_DIR"
        fi
    fi
fi

# Normalize paths
# Avoid failing if BASE_DIR contains tilde by expanding
BASE_DIR="$(cd "$BASE_DIR" >/dev/null 2>&1 && pwd -P || echo "$BASE_DIR")"
LINK_PATH="${BASE_DIR}/.zgenom"
DEST_PATH="${BASE_DIR}/zgenom"

echo "Operation summary:"
echo "  base dir:    $BASE_DIR"
echo "  link path:   $LINK_PATH"
echo "  dest path:   $DEST_PATH"
echo "  dry-run:     $DRY_RUN"
echo "  force:       $FORCE"
echo

# Dry-run helper
if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would ensure base dir exists: $BASE_DIR"
    echo "[dry-run] would create symlink: $LINK_PATH -> $(basename "$DEST_PATH")"
    exit 0
fi

# Ensure base exists (create it if necessary)
if [[ ! -d "$BASE_DIR" ]]; then
    echo "Base directory '$BASE_DIR' does not exist; creating it..."
    mkdir -p "$BASE_DIR"
fi

# Validate destination presence (optional: warn if zgenom missing)
if [[ ! -e "$DEST_PATH" ]]; then
    echo "Warning: destination '$DEST_PATH' does not exist. The symlink will still be created to the expected name 'zgenom'."
fi

# Handle existing link or path at LINK_PATH
if [[ -L "$LINK_PATH" ]]; then
    current_target="$(readlink "$LINK_PATH")"
    if [[ "$current_target" == "zgenom" || "$current_target" == "./zgenom" || "$current_target" == "$DEST_PATH" || "$current_target" == "$(basename "$DEST_PATH")" ]]; then
        echo "Symlink already exists and points to expected target: $current_target"
        exit 0
    else
        if [[ $FORCE -eq 1 ]]; then
            echo "Replacing existing symlink (was pointing to: $current_target)"
            rm -f "$LINK_PATH"
        else
            echo "Existing symlink points to '$current_target'. Use --force to replace." >&2
            exit 1
        fi
    fi
elif [[ -e "$LINK_PATH" ]]; then
    # Exists but is not a symlink
    if [[ $FORCE -eq 1 ]]; then
        timestamp="$(date +%Y%m%d%H%M%S)"
        backup="${LINK_PATH}.bak.${timestamp}"
        echo "Backing up existing path to: $backup"
        mv "$LINK_PATH" "$backup"
    else
        echo "Path exists at '$LINK_PATH' and is not a symlink. Use --force to back it up and replace it." >&2
        exit 1
    fi
fi

# Create symlink as relative link (preferred for repo portability)
pushd "$BASE_DIR" >/dev/null 2>&1 || {
    echo "Failed to cd into $BASE_DIR" >&2
    exit 1
}

# Decide relative link target. Prefer "zgenom" (relative) if that name exists or not.
link_target="zgenom"

# Create the symlink
echo "Creating symlink: $LINK_PATH -> $link_target"
ln -s "$link_target" "$LINK_PATH"

# Verify
if [[ -L "$LINK_PATH" ]]; then
    echo "Done. Symlink created: $LINK_PATH -> $(readlink "$LINK_PATH")"
    popd >/dev/null 2>&1
    exit 0
else
    echo "Failed to create symlink at $LINK_PATH" >&2
    popd >/dev/null 2>&1
    exit 1
fi
