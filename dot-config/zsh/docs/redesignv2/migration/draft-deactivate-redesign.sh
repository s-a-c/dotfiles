#!/bin/zsh
# deactivate-redesign.sh - Exact inverse operations of activate-redesign.sh
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

set -e

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
BACKUP_DIR="$ZDOTDIR/backups/redesign"
MIGRATION_LOG="$ZDOTDIR/tools/migration.log"

usage() {
    echo "Usage: $0 [--verbose]"
    echo "Deactivates ZSH redesign by restoring original configurations"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed output during deactivation"
    echo ""
    echo "This script performs the exact inverse of activate-redesign.sh:"
    echo "  - Removes redesign environment variables from ~/.zshenv"
    echo "  - Restores original .zshenv from backup"
    echo "  - Removes redesign activation snippet"
    echo "  - Updates migration log"
    exit 1
}

log_action() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] DEACTIVATE: $1" | tee -a "$MIGRATION_LOG"
    [[ "$VERBOSE" == "1" ]] && echo "$1"
}

restore_zshenv() {
    local zshenv_file="$HOME/.zshenv"
    local backup_file="$BACKUP_DIR/zshenv.backup"

    if [[ -f "$backup_file" ]]; then
        log_action "Restoring original .zshenv from backup"
        cp "$backup_file" "$zshenv_file"
        log_action "Original .zshenv restored successfully"
    else
        log_action "WARNING: No .zshenv backup found, removing redesign snippet manually"

        if [[ -f "$zshenv_file" ]]; then
            # Remove redesign-specific lines
            sed -i.deactivate-backup '/# ZSH Redesign activation/,/# End ZSH Redesign activation/d' "$zshenv_file"
            sed -i.deactivate-backup '/export ZSH_USE_REDESIGN=/d' "$zshenv_file"
            sed -i.deactivate-backup '/export ZSH_ENABLE_PREPLUGIN_REDESIGN=/d' "$zshenv_file"
            sed -i.deactivate-backup '/export ZSH_ENABLE_POSTPLUGIN_REDESIGN=/d' "$zshenv_file"
            log_action "Removed redesign snippet from .zshenv"
        fi
    fi
}

remove_environment_file() {
    local env_file="$ZDOTDIR/.redesign-env"

    if [[ -f "$env_file" ]]; then
        rm "$env_file"
        log_action "Removed redesign environment file: $env_file"
    fi
}

update_migration_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] DEACTIVATE: ZSH Redesign deactivated successfully" >> "$MIGRATION_LOG"
    echo "[$timestamp] DEACTIVATE: All redesign configurations removed" >> "$MIGRATION_LOG"
    echo "[$timestamp] DEACTIVATE: Shell restart required to take effect" >> "$MIGRATION_LOG"
}

verify_deactivation() {
    local issues=0

    # Check if redesign variables are still in .zshenv
    if grep -q "ZSH_USE_REDESIGN" "$HOME/.zshenv" 2>/dev/null; then
        log_action "WARNING: ZSH_USE_REDESIGN still found in .zshenv"
        ((issues++))
    fi

    # Check if environment file was removed
    if [[ -f "$ZDOTDIR/.redesign-env" ]]; then
        log_action "WARNING: Redesign environment file still exists"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        log_action "Deactivation verification passed"
        return 0
    else
        log_action "Deactivation verification found $issues issues"
        return 1
    fi
}

# Parse arguments
VERBOSE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=1
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Main deactivation sequence
log_action "Starting ZSH redesign deactivation"

# Step 1: Restore original .zshenv
restore_zshenv

# Step 2: Remove environment file
remove_environment_file

# Step 3: Update migration log
update_migration_log

# Step 4: Verify deactivation
if verify_deactivation; then
    log_action "ZSH redesign deactivated successfully"
    echo ""
    echo "✅ ZSH Redesign has been deactivated"
    echo ""
    echo "Next steps:"
    echo "1. Restart your shell or run: exec zsh"
    echo "2. Verify redesign is disabled: echo \$ZSH_USE_REDESIGN (should be empty)"
    echo "3. Check migration log: $MIGRATION_LOG"
else
    log_action "Deactivation completed with warnings - manual cleanup may be required"
    echo ""
    echo "⚠️  ZSH Redesign deactivation completed with warnings"
    echo ""
    echo "Please check the migration log for details: $MIGRATION_LOG"
    exit 1
fi
