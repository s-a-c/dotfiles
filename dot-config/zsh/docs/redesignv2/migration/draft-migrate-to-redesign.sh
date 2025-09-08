#!/bin/zsh
# migrate-to-redesign.sh - User config migration tool for ZSH redesign
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v<checksum>

set -e

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
BACKUP_DIR="$ZDOTDIR/backups/redesign"
MIGRATION_LOG="$ZDOTDIR/tools/migration.log"

usage() {
    echo "Usage: $0 [--dry-run | --apply] [--verbose]"
    echo "Migrates user configuration to enable ZSH redesign"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be changed without making any modifications"
    echo "  --apply      Apply the migration (modifies user configuration)"
    echo "  --verbose    Show detailed output during migration"
    echo ""
    echo "Migration actions:"
    echo "  - Backs up original ~/.zshenv"
    echo "  - Injects managed snippet into ~/.zshenv to enable redesign"
    echo "  - Creates redesign environment file"
    echo "  - Writes migration log for tracking"
    exit 1
}

log_action() {
    local action_type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "[$timestamp] [DRY-RUN] $action_type: $message" | tee -a "$MIGRATION_LOG"
    else
        echo "[$timestamp] $action_type: $message" | tee -a "$MIGRATION_LOG"
    fi

    [[ "$VERBOSE" == "1" ]] && echo "$message"
}

backup_zshenv() {
    local zshenv_file="$HOME/.zshenv"
    local backup_file="$BACKUP_DIR/zshenv.backup"
    local timestamp_backup="$BACKUP_DIR/zshenv.backup.$(date +%Y%m%d_%H%M%S)"

    if [[ -f "$zshenv_file" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            log_action "BACKUP" "Would backup $zshenv_file to $backup_file"
            log_action "BACKUP" "Would create timestamped backup at $timestamp_backup"
        else
            mkdir -p "$BACKUP_DIR"
            cp "$zshenv_file" "$backup_file"
            cp "$zshenv_file" "$timestamp_backup"
            log_action "BACKUP" "Created backup of .zshenv at $backup_file"
            log_action "BACKUP" "Created timestamped backup at $timestamp_backup"
        fi
    else
        log_action "INFO" ".zshenv does not exist, will be created"
    fi
}

inject_redesign_snippet() {
    local zshenv_file="$HOME/.zshenv"

    # Check if redesign snippet already exists
    if [[ -f "$zshenv_file" ]] && grep -q "ZSH_USE_REDESIGN" "$zshenv_file"; then
        log_action "INFO" "Redesign snippet already exists in .zshenv"
        return 0
    fi

    local redesign_snippet='
# ZSH Redesign activation
export ZSH_USE_REDESIGN=1
export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1
# End ZSH Redesign activation'

    if [[ "$DRY_RUN" == "1" ]]; then
        log_action "INJECT" "Would inject redesign snippet into $zshenv_file"
        echo "Snippet content:"
        echo "$redesign_snippet"
    else
        if [[ -f "$zshenv_file" ]]; then
            echo "$redesign_snippet" >> "$zshenv_file"
        else
            echo "$redesign_snippet" > "$zshenv_file"
        fi
        log_action "INJECT" "Injected redesign snippet into $zshenv_file"
    fi
}

create_environment_file() {
    local env_file="$ZDOTDIR/.redesign-env"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local env_content="# ZSH Redesign Environment Configuration
# Generated on: $timestamp
# Migration tool: migrate-to-redesign.sh

# Core redesign settings
ZSH_USE_REDESIGN=1
ZSH_ENABLE_PREPLUGIN_REDESIGN=1
ZSH_ENABLE_POSTPLUGIN_REDESIGN=1

# Migration metadata
ZSH_REDESIGN_MIGRATION_DATE=\"$timestamp\"
ZSH_REDESIGN_MIGRATION_TOOL=\"migrate-to-redesign.sh\"
ZSH_REDESIGN_MIGRATION_VERSION=\"v1.0\""

    if [[ "$DRY_RUN" == "1" ]]; then
        log_action "CREATE" "Would create environment file at $env_file"
        echo "Environment file content:"
        echo "$env_content"
    else
        mkdir -p "$(dirname "$env_file")"
        echo "$env_content" > "$env_file"
        log_action "CREATE" "Created redesign environment file at $env_file"
    fi
}

verify_migration() {
    local issues=0
    local zshenv_file="$HOME/.zshenv"

    if [[ "$DRY_RUN" == "1" ]]; then
        log_action "VERIFY" "Would verify migration results"
        return 0
    fi

    # Check if redesign variables are in .zshenv
    if ! grep -q "ZSH_USE_REDESIGN=1" "$zshenv_file" 2>/dev/null; then
        log_action "ERROR" "ZSH_USE_REDESIGN not found in .zshenv"
        ((issues++))
    fi

    # Check if environment file was created
    if [[ ! -f "$ZDOTDIR/.redesign-env" ]]; then
        log_action "ERROR" "Redesign environment file not created"
        ((issues++))
    fi

    if [[ $issues -eq 0 ]]; then
        log_action "VERIFY" "Migration verification passed"
        return 0
    else
        log_action "ERROR" "Migration verification found $issues issues"
        return 1
    fi
}

# Parse arguments
DRY_RUN=0
APPLY=0
VERBOSE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --apply)
            APPLY=1
            shift
            ;;
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

# Validate arguments
if [[ $DRY_RUN -eq 1 && $APPLY -eq 1 ]]; then
    echo "Error: Cannot use both --dry-run and --apply"
    usage
fi

if [[ $DRY_RUN -eq 0 && $APPLY -eq 0 ]]; then
    echo "Error: Must specify either --dry-run or --apply"
    usage
fi

# Ensure required directories exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$MIGRATION_LOG")"

# Main migration sequence
if [[ "$DRY_RUN" == "1" ]]; then
    log_action "START" "Starting ZSH redesign migration (DRY RUN)"
else
    log_action "START" "Starting ZSH redesign migration (APPLY MODE)"
fi

# Step 1: Backup current .zshenv
backup_zshenv

# Step 2: Inject redesign snippet
inject_redesign_snippet

# Step 3: Create environment file
create_environment_file

# Step 4: Verify migration (if applying)
if verify_migration; then
    if [[ "$DRY_RUN" == "1" ]]; then
        log_action "COMPLETE" "Dry run completed - no changes made"
        echo ""
        echo "🔍 Migration dry run completed successfully"
        echo ""
        echo "To apply these changes, run:"
        echo "$0 --apply"
    else
        log_action "COMPLETE" "ZSH redesign migration completed successfully"
        echo ""
        echo "✅ ZSH Redesign migration completed successfully"
        echo ""
        echo "Next steps:"
        echo "1. Restart your shell or run: exec zsh"
        echo "2. Verify redesign is enabled: echo \$ZSH_USE_REDESIGN (should be '1')"
        echo "3. Check migration log: $MIGRATION_LOG"
    fi
else
    if [[ "$APPLY" == "1" ]]; then
        log_action "ERROR" "Migration completed with errors"
        echo ""
        echo "❌ ZSH Redesign migration completed with errors"
        echo ""
        echo "Please check the migration log for details: $MIGRATION_LOG"
        exit 1
    fi
fi
