#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Periodic Review Cycles System
# ==============================================================================
# Purpose: Automated periodic 020-review scheduling system with reminders for
#          system maintenance, performance reviews, security audits, and
#          configuration updates with comprehensive tracking and notification
#          capabilities for long-term system health management.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 7th in 00-core (after performance monitoring, before utilities)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_REVIEW_CYCLES_LOADED:-}" && -z "${ZSH_REVIEW_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zsh_debug_echo "WARNING: Source/execute detection system not found: $detection_script"
        zsh_debug_echo "Review cycles will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zsh_debug_echo >/dev/null 2>&1; then
    _review_log() {
        context_zsh_debug_echo "$1" "${2:-INFO}"
    }
    _review_error() {
        local message="$1"
        local exit_code="${2:-1}"
        if declare -f handle_error >/dev/null 2>&1; then
            handle_error "Review Cycles: $message" "$exit_code" "review"
        else
            zsh_debug_echo "ERROR [review]: $message"
            if declare -f is_being_executed >/dev/null 2>&1 && is_being_executed; then
                exit "$exit_code"
            else
                return "$exit_code"
            fi
        fi
    }
else
    # Fallback logging functions
    _review_log() {
        zsh_debug_echo "# [review] $1"
    }
    _review_error() {
        zsh_debug_echo "ERROR [review]: $1"
        return "${2:-1}"
    }
fi

# 1. Global Configuration and Review Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _review_log "Loading periodic review cycles system v1.0"
}

# 1.1. Set global 020-review cycles version for tracking
export ZSH_REVIEW_CYCLES_VERSION="1.0.0"
export ZSH_REVIEW_CYCLES_LOADED="$(command -v date >/dev/null && date -u '+    %FT%T %Z' || zsh_debug_echo 'loaded')"

# 1.2. Review cycles configuration
export ZSH_REVIEW_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.reviews"
export ZSH_REVIEW_SCHEDULE_FILE="$ZSH_REVIEW_DIR/schedule.conf"
export ZSH_REVIEW_HISTORY_FILE="$ZSH_REVIEW_DIR/history.log"
export ZSH_REVIEW_REMINDERS_FILE="$ZSH_REVIEW_DIR/reminders.log"

# Create 020-review directories
mkdir -p "$ZSH_REVIEW_DIR" 2>/dev/null || true

# 1.3. Review cycle settings
export ZSH_ENABLE_REVIEW_CYCLES="${ZSH_ENABLE_REVIEW_CYCLES:-true}"
export ZSH_REVIEW_REMINDER_DAYS="${ZSH_REVIEW_REMINDER_DAYS:-7}"  # Days before 020-review to remind
export ZSH_REVIEW_QUIET_MODE="${ZSH_REVIEW_QUIET_MODE:-false}"   # Suppress non-critical reminders

# 1.4. Review cycle types and frequencies
typeset -gA ZSH_REVIEW_TYPES
ZSH_REVIEW_TYPES=(
    "performance"    "monthly"     # Performance 020-review every month
    "security"       "quarterly"   # Security 020-review every 3 months
    "configuration"  "quarterly"   # Configuration 020-review every 3 months
    "documentation"  "biannual"    # Documentation 020-review every 6 months
    "system"         "annual"      # Full system 020-review every year
)

# 1.5. Review state tracking
typeset -gA ZSH_REVIEW_LAST_DATES
typeset -gA ZSH_REVIEW_NEXT_DATES
typeset -g ZSH_REVIEW_CYCLES_INITIALIZED="false"

# 2. Review Cycle Management
#=============================================================================

# 2.1. Initialize 020-review cycles system
_init_review_cycles() {
    _review_log "Initializing review cycles system..."

    # Create schedule file if it doesn't exist
    if [[ ! -f "$ZSH_REVIEW_SCHEDULE_FILE" ]]; then
        cat > "$ZSH_REVIEW_SCHEDULE_FILE" << EOF
# ZSH Configuration Review Schedule
# Format: review_type:frequency:last_date:next_date
# Created: $(date -u '+    %FT%T %Z' 2>/dev/null || zsh_debug_echo 'unknown')

# Performance Reviews (Monthly)
performance:monthly::

# Security Reviews (Quarterly)
security:quarterly::

# Configuration Reviews (Quarterly)
configuration:quarterly::

# Documentation Reviews (Biannual)
documentation:biannual::

# System Reviews (Annual)
system:annual::
EOF
        _review_log "Created review schedule file: $ZSH_REVIEW_SCHEDULE_FILE"
    fi

    # Create history file if it doesn't exist
    if [[ ! -f "$ZSH_REVIEW_HISTORY_FILE" ]]; then
        cat > "$ZSH_REVIEW_HISTORY_FILE" << EOF
# ZSH Configuration Review History
# Format: timestamp,review_type,status,notes
# Created: $(date -u '+    %FT%T %Z' 2>/dev/null || zsh_debug_echo 'unknown')
EOF
        _review_log "Created review history file: $ZSH_REVIEW_HISTORY_FILE"
    fi

    # Create reminders file if it doesn't exist
    if [[ ! -f "$ZSH_REVIEW_REMINDERS_FILE" ]]; then
        touch "$ZSH_REVIEW_REMINDERS_FILE"
        _review_log "Created review reminders file: $ZSH_REVIEW_REMINDERS_FILE"
    fi

    # Load existing 020-review schedule
    _load_review_schedule

    ZSH_REVIEW_CYCLES_INITIALIZED="true"
}

# 2.2. Load 020-review schedule from file
_load_review_schedule() {
    if [[ ! -f "$ZSH_REVIEW_SCHEDULE_FILE" ]]; then
        return 0
    fi

    while IFS=':' read -r review_type frequency last_date next_date; do
        # Skip comments and empty lines
        if [[ "$review_type" =~ ^#.*$ || -z "$review_type" ]]; then
            continue
        fi

        ZSH_REVIEW_LAST_DATES["$review_type"]="$last_date"
        ZSH_REVIEW_NEXT_DATES["$review_type"]="$next_date"

        _review_log "Loaded review schedule: $review_type ($frequency)" "DEBUG"
    done < "$ZSH_REVIEW_SCHEDULE_FILE"
}

# 2.3. Calculate next 020-review date
_calculate_next_review_date() {
    local review_type="$1"
    local frequency="${ZSH_REVIEW_TYPES[$review_type]:-monthly}"
    local last_date="$2"

    if [[ -z "$last_date" ]]; then
        # If no last date, set next 020-review to today
        if command -v date >/dev/null 2>&1; then
            zsh_debug_echo "$(date '+%Y-%m-%d')"
        else
            zsh_debug_echo "2025-08-22"
        fi
        return 0
    fi

    # Calculate next date based on frequency
    local next_date=""
    if command -v date >/dev/null 2>&1; then
        case "$frequency" in
            "weekly")
                next_date=$(date -d "$last_date + 1 week" '+%Y-%m-%d' 2>/dev/null || date -v+1w -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
            "monthly")
                next_date=$(date -d "$last_date + 1 month" '+%Y-%m-%d' 2>/dev/null || date -v+1m -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
            "quarterly")
                next_date=$(date -d "$last_date + 3 months" '+%Y-%m-%d' 2>/dev/null || date -v+3m -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
            "biannual")
                next_date=$(date -d "$last_date + 6 months" '+%Y-%m-%d' 2>/dev/null || date -v+6m -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
            "annual")
                next_date=$(date -d "$last_date + 1 year" '+%Y-%m-%d' 2>/dev/null || date -v+1y -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
            *)
                next_date=$(date -d "$last_date + 1 month" '+%Y-%m-%d' 2>/dev/null || date -v+1m -j -f "%Y-%m-%d" "$last_date" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$last_date")
                ;;
        esac
    else
        # Fallback: just return the last date
        next_date="$last_date"
    fi

    zsh_debug_echo "$next_date"
}

# 2.4. Update 020-review schedule
_update_review_schedule() {
    local review_type="$1"
    local completion_date="${2:-$(date '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo '2025-08-22')}"

    # Calculate next 020-review date
    local next_date=$(_calculate_next_review_date "$review_type" "$completion_date")

    # Update in-memory tracking
    ZSH_REVIEW_LAST_DATES["$review_type"]="$completion_date"
    ZSH_REVIEW_NEXT_DATES["$review_type"]="$next_date"

    # Update schedule file
    if [[ -f "$ZSH_REVIEW_SCHEDULE_FILE" ]]; then
        local temp_file=$(mktemp)
        local frequency="${ZSH_REVIEW_TYPES[$review_type]:-monthly}"

        # Read existing file and update the specific 020-review type
        while IFS=':' read -r type freq last next; do
            if [[ "$type" == "$review_type" ]]; then
                zsh_debug_echo "$review_type:$frequency:$completion_date:$next_date" >> "$temp_file"
            elif [[ ! "$type" =~ ^#.*$ && -n "$type" ]]; then
                zsh_debug_echo "$type:$freq:$last:$next" >> "$temp_file"
            else
                zsh_debug_echo "$type:$freq:$last:$next" >> "$temp_file"
            fi
        done < "$ZSH_REVIEW_SCHEDULE_FILE"

        # Replace original file
        mv "$temp_file" "$ZSH_REVIEW_SCHEDULE_FILE"
    else
        _review_error "Schedule file not found: $ZSH_REVIEW_SCHEDULE_FILE"
    fi

    _review_log "Updated review schedule: $review_type completed on $completion_date, next due $next_date"
}

# 3. Review Reminder System
#=============================================================================

# 3.1. Check for due reviews
_check_due_reviews() {
    if [[ "$ZSH_ENABLE_REVIEW_CYCLES" != "true" ]]; then
        return 0
    fi

    local today
    if command -v date >/dev/null 2>&1; then
        today=$(date '+%Y-%m-%d')
    else
        today="2025-08-22"
    fi

    local due_reviews=()
    local upcoming_reviews=()

    # Check each 020-review type
    for review_type in "${(@k)ZSH_REVIEW_TYPES}"; do
        local next_date="${ZSH_REVIEW_NEXT_DATES[$review_type]:-}"

        if [[ -n "$next_date" ]]; then
            # Compare dates (simple string comparison works for YYYY-MM-DD format)
            if [[ "$today" > "$next_date" || "$today" == "$next_date" ]]; then
                due_reviews+=("$review_type")
            elif [[ -n "$ZSH_REVIEW_REMINDER_DAYS" ]]; then
                # Check if 020-review is coming up within reminder period
                if command -v date >/dev/null 2>&1; then
                    local reminder_days="${ZSH_REVIEW_REMINDER_DAYS:-7}"
                    local reminder_date=$(date -d "$next_date - $reminder_days days" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$next_date")
                    if [[ "$today" > "$reminder_date" || "$today" == "$reminder_date" ]] && [[ "$today" < "$next_date" ]]; then
                        upcoming_reviews+=("$review_type")
                    fi
                fi
            fi
        fi
    done

    # Display due reviews
    if [[ ${#due_reviews[@]} -gt 0 ]]; then
        zsh_debug_echo "📅 Reviews Due:"
        for review in "${due_reviews[@]}"; do
            local review_due_date="${ZSH_REVIEW_NEXT_DATES[$review]}"
            zsh_debug_echo "  • $review review (due: $review_due_date)"
        done
        zsh_debug_echo "  Run 'review-status' for details or 'review-complete <type>' when done"
        zsh_debug_echo ""
    fi

    # Display upcoming reviews (if not in quiet mode)
    if [[ ${#upcoming_reviews[@]} -gt 0 && "$ZSH_REVIEW_QUIET_MODE" != "true" ]]; then
        zsh_debug_echo "📋 Upcoming Reviews:"
        for review in "${upcoming_reviews[@]}"; do
            local review_upcoming_date="${ZSH_REVIEW_NEXT_DATES[$review]}"
            zsh_debug_echo "  • $review review (due: $review_upcoming_date)"
        done
        zsh_debug_echo ""
    fi
}

# 3.2. Log 020-review reminder
_log_review_reminder() {
    local review_type="$1"
    local reminder_type="${2:-due}"  # due, upcoming, completed

    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    zsh_debug_echo "$timestamp,$review_type,$reminder_type" >> "$ZSH_REVIEW_REMINDERS_FILE"
}

# 4. Review Management Commands
#=============================================================================

# 4.1. Review status command
review-status() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Review Cycles Status"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_REVIEW_CYCLES_VERSION"
    zsh_debug_echo "Review Cycles Enabled: $ZSH_ENABLE_REVIEW_CYCLES"
    zsh_debug_echo "Reminder Days: $ZSH_REVIEW_REMINDER_DAYS"
    zsh_debug_echo "Quiet Mode: $ZSH_REVIEW_QUIET_MODE"
    zsh_debug_echo ""

    local today
    if command -v date >/dev/null 2>&1; then
        today=$(date '+%Y-%m-%d')
    else
        today="2025-08-22"
    fi

    zsh_debug_echo "Current Date: $today"
    zsh_debug_echo ""

    zsh_debug_echo "Review Schedule:"
    printf "%-15s %-12s %-12s %-12s %s\n" "Type" "Frequency" "Last" "Next" "Status"
    printf "%-15s %-12s %-12s %-12s %s\n" "----" "---------" "----" "----" "------"

    for review_type in "${(@k)ZSH_REVIEW_TYPES}"; do
        local frequency="${ZSH_REVIEW_TYPES[$review_type]}"
        local last_date="${ZSH_REVIEW_LAST_DATES[$review_type]:-never}"
        local next_date="${ZSH_REVIEW_NEXT_DATES[$review_type]:-pending}"

        local status="scheduled"
        if [[ "$next_date" != "pending" ]]; then
            if [[ "$today" > "$next_date" || "$today" == "$next_date" ]]; then
                status="DUE"
            elif command -v date >/dev/null 2>&1; then
                local reminder_days="${ZSH_REVIEW_REMINDER_DAYS:-7}"
                local reminder_date=$(date -d "$next_date - $reminder_days days" '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "$next_date")
                if [[ "$today" > "$reminder_date" || "$today" == "$reminder_date" ]]; then
                    status="upcoming"
                fi
            fi
        fi

        printf "%-15s %-12s %-12s %-12s %s\n" "$review_type" "$frequency" "$last_date" "$next_date" "$status"
    done

    zsh_debug_echo ""
    zsh_debug_echo "Recent Review History:"
    if [[ -f "$ZSH_REVIEW_HISTORY_FILE" ]]; then
        tail -n 5 "$ZSH_REVIEW_HISTORY_FILE" | while IFS=',' read -r timestamp review_type status notes; do
            if [[ ! "$timestamp" =~ ^#.*$ && -n "$timestamp" ]]; then
                zsh_debug_echo "  $timestamp: $review_type ($status) - $notes"
            fi
        done
    else
        zsh_debug_echo "  No review history available"
    fi
}

# 4.2. Complete 020-review command
review-complete() {
    local review_type="$1"
    local notes="${2:-Review completed}"

    if [[ -z "$review_type" ]]; then
        zsh_debug_echo "Usage: review-complete <type> [notes]"
        zsh_debug_echo "Available types: ${(@k)ZSH_REVIEW_TYPES}"
        return 1
    fi

    if [[ -z "${ZSH_REVIEW_TYPES[$review_type]}" ]]; then
        zsh_debug_echo "Unknown review type: $review_type"
        zsh_debug_echo "Available types: ${(@k)ZSH_REVIEW_TYPES}"
        return 1
    fi

    local completion_date
    if command -v date >/dev/null 2>&1; then
        completion_date=$(date '+%Y-%m-%d')
    else
        completion_date="2025-08-22"
    fi

    # Update schedule
    _update_review_schedule "$review_type" "$completion_date"

    # Log completion
    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    zsh_debug_echo "$timestamp,$review_type,completed,$notes" >> "$ZSH_REVIEW_HISTORY_FILE"
    _log_review_reminder "$review_type" "completed"

    zsh_debug_echo "✅ $review_type review marked as completed on $completion_date"
    zsh_debug_echo "📅 Next $review_type review due: ${ZSH_REVIEW_NEXT_DATES[$review_type]}"
}

# 4.3. Schedule 020-review command
review-schedule() {
    local review_type="$1"
    local date="$2"

    if [[ -z "$review_type" || -z "$date" ]]; then
        zsh_debug_echo "Usage: review-schedule <type> <YYYY-MM-DD>"
        zsh_debug_echo "Available types: ${(@k)ZSH_REVIEW_TYPES}"
        return 1
    fi

    if [[ -z "${ZSH_REVIEW_TYPES[$review_type]}" ]]; then
        zsh_debug_echo "Unknown review type: $review_type"
        zsh_debug_echo "Available types: ${(@k)ZSH_REVIEW_TYPES}"
        return 1
    fi

    # Validate date format
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        zsh_debug_echo "Invalid date format. Use YYYY-MM-DD"
        return 1
    fi

    # Update next date
    ZSH_REVIEW_NEXT_DATES["$review_type"]="$date"

    # Update schedule file
    local temp_file=$(mktemp)
    local frequency="${ZSH_REVIEW_TYPES[$review_type]}"
    local last_date="${ZSH_REVIEW_LAST_DATES[$review_type]:-}"

    while IFS=':' read -r type freq last next; do
        if [[ "$type" == "$review_type" ]]; then
            zsh_debug_echo "$review_type:$frequency:$last_date:$date" >> "$temp_file"
        elif [[ ! "$type" =~ ^#.*$ && -n "$type" ]]; then
            zsh_debug_echo "$type:$freq:$last:$next" >> "$temp_file"
        else
            zsh_debug_echo "$type:$freq:$last:$next" >> "$temp_file"
        fi
    done < "$ZSH_REVIEW_SCHEDULE_FILE"

    mv "$temp_file" "$ZSH_REVIEW_SCHEDULE_FILE"

    zsh_debug_echo "📅 $review_type review scheduled for $date"
}

# 5. Initialization and Startup Check
#=============================================================================

# 5.1. Initialize 020-review cycles system
_init_review_cycles

# 5.2. Check for due reviews on startup (if enabled and interactive)
if [[ "$ZSH_ENABLE_REVIEW_CYCLES" == "true" && -t 1 ]]; then
    _check_due_reviews
fi

[[ "$ZSH_DEBUG" == "1" ]] && _review_log "✅ Review cycles system loaded successfully"

# ------------------------------------------------------------------------------
# 6. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
review_cycles_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Review Cycles System"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_REVIEW_CYCLES_VERSION"
    zsh_debug_echo "Loaded: $ZSH_REVIEW_CYCLES_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    review-status

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        review_cycles_main "$@"
    fi
elif [[ "${(%):-%N}" == "$0" ]] || [[ "${(%):-%N}" == *"review-cycles"* ]]; then
    # Fallback detection for direct execution
    review_cycles_main "$@"
fi

# ==============================================================================
# END: Periodic Review Cycles System
# ==============================================================================
