#!/usr/bin/env zsh
#=============================================================================
# File: fix-sentinel-guards.zsh
# Purpose: Analyze and fix missing sentinel guards in ZSH configuration files
# Author: ZSH Configuration Redesign Project
# Compliant with dotfiles/dot-config/ai/guidelines.md v<computed at runtime>
#=============================================================================

# Script configuration
readonly SCRIPT_DIR="${${(%):-%x}:A:h}"
readonly ZSH_CONFIG_DIR="${SCRIPT_DIR:h}"
readonly PRE_PLUGIN_DIR="$ZSH_CONFIG_DIR/.zshrc.pre-plugins.d"
readonly POST_PLUGIN_DIR="$ZSH_CONFIG_DIR/.zshrc.d"
readonly PRE_PLUGIN_REDESIGN_DIR="$ZSH_CONFIG_DIR/.zshrc.pre-plugins.d.REDESIGN"
readonly POST_PLUGIN_REDESIGN_DIR="$ZSH_CONFIG_DIR/.zshrc.d.REDESIGN"
readonly POSTPLUGIN_SUBDIR="$POST_PLUGIN_REDESIGN_DIR/POSTPLUGIN"

# Color output support
if [[ -t 1 && -n "${TERM:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m' # No Color
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    [[ "${DEBUG:-}" == "1" ]] && echo -e "${CYAN}[DEBUG]${NC} $*" >&2
}

# Generate sentinel variable name from filename
generate_sentinel_name() {
    local filename="$1"
    # Remove path components and .zsh extension
    local basename="${filename:t:r}"
    # Convert to uppercase and replace special chars with underscores
    local sentinel="_LOADED_${basename:u}"
    # Clean up multiple underscores and special characters
    sentinel="${sentinel//[-.]/_}"
    sentinel="${sentinel//__/_}"
    echo "$sentinel"
}

# Check if file has sentinel guard
has_sentinel_guard() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    # Look for common sentinel patterns
    grep -q '\[\[.*-n.*_LOADED_.*\]\].*return.*0' "$file" ||
    grep -q 'if.*\[\[.*-n.*_.*\]\].*then' "$file" ||
    grep -q 'if.*\[\[.*-n.*_.*\]\].*return' "$file" ||
    grep -q '_.*_FIXED.*=.*1' "$file" ||
    grep -q '_.*_LOADED.*=.*1' "$file"
}

# Extract existing sentinel variable name
get_existing_sentinel() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    # Try multiple patterns to find existing sentinel
    local sentinel
    sentinel=$(grep -o '_[A-Z][A-Z_]*_\(LOADED\|FIXED\)' "$file" | head -1)
    if [[ -n "$sentinel" ]]; then
        echo "$sentinel"
        return 0
    fi

    # Try pattern with variable expansion
    sentinel=$(grep -o '\${[A-Z][A-Z_]*:-}' "$file" | sed 's/\${//; s/:-}//' | head -1)
    if [[ -n "$sentinel" ]]; then
        echo "$sentinel"
        return 0
    fi

    return 1
}

# Add sentinel guard to file
add_sentinel_guard() {
    local file="$1"
    local dry_run="${2:-false}"

    [[ -f "$file" ]] || {
        log_error "File not found: $file"
        return 1
    }

    local sentinel
    sentinel="$(generate_sentinel_name "$file")"

    log_debug "Adding sentinel '$sentinel' to $file"

    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would add sentinel '$sentinel' to ${file:t}"
        return 0
    fi

    # Create backup
    local backup_file="${file}.sentinel-backup.$(date +%s)"
    cp "$file" "$backup_file" || {
        log_error "Failed to create backup: $backup_file"
        return 1
    }

    # Create temporary file with sentinel guard
    local temp_file="${file}.tmp.$$"
    {
        # Add sentinel guard after shebang and before any other content
        local in_header=true
        local added_sentinel=false

        while IFS= read -r line || [[ -n "$line" ]]; do
            # Print shebang lines first
            if [[ "$line" =~ '^#!' && "$in_header" == "true" ]]; then
                echo "$line"
                continue
            fi

            # Print initial comments and blank lines
            if [[ "$line" =~ '^#' || "$line" =~ '^[[:space:]]*$' ]] && [[ "$in_header" == "true" ]]; then
                echo "$line"
                continue
            fi

            # First non-comment, non-blank line - add sentinel before it
            if [[ "$in_header" == "true" && "$added_sentinel" == "false" ]]; then
                echo ""
                echo "# Prevent multiple loading"
                echo "[[ -n \"\${${sentinel}:-}\" ]] && return 0"
                echo ""
                added_sentinel=true
                in_header=false
            fi

            echo "$line"
        done < "$file"

        # If we never found a place to add sentinel, add it at the end
        if [[ "$added_sentinel" == "false" ]]; then
            echo ""
            echo "# Prevent multiple loading"
            echo "[[ -n \"\${${sentinel}:-}\" ]] && return 0"
        fi

        # Add the sentinel variable at the end
        echo ""
        echo "# Mark as loaded"
        echo "readonly ${sentinel}=1"

    } > "$temp_file"

    # Verify temp file was created successfully
    if [[ ! -f "$temp_file" || ! -s "$temp_file" ]]; then
        log_error "Failed to create temporary file or file is empty"
        rm -f "$temp_file"
        return 1
    fi

    # Replace original file
    mv "$temp_file" "$file" || {
        log_error "Failed to replace original file"
        rm -f "$temp_file"
        return 1
    }

    log_success "Added sentinel '$sentinel' to ${file:t}"
    log_debug "Backup created: $backup_file"
    return 0
}

# Analyze directory for sentinel guard status
analyze_directory() {
    local dir="$1"
    local label="$2"
    local include_subdirs="${3:-false}"

    [[ -d "$dir" ]] || {
        log_warn "Directory not found: $dir"
        return 1
    }

    log_info "Analyzing $label directory: $dir"
    echo ""

    local total_files=0
    local files_with_sentinels=0
    local files_without_sentinels=0
    local -a missing_sentinel_files

    # Process files in main directory
    for file in "$dir"/*.zsh(N); do
        [[ -f "$file" ]] || continue
        ((total_files++))

        local filename="${file:t}"
        local has_guard=""
        local sentinel=""

        if has_sentinel_guard "$file"; then
            ((files_with_sentinels++))
            sentinel="$(get_existing_sentinel "$file")"
            has_guard="✅"
        else
            ((files_without_sentinels++))
            missing_sentinel_files+=("$file")
            has_guard="❌"
        fi

        printf "  %s %-45s %s\n" "$has_guard" "$filename" "${sentinel:-(none)}"
    done

    # Process subdirectories if requested
    if [[ "$include_subdirs" == "true" ]]; then
        for subdir in "$dir"/*(N/); do
            [[ -d "$subdir" ]] || continue
            local subdir_name="${subdir:t}"
            echo ""
            log_info "  Analyzing subdirectory: $subdir_name"

            for file in "$subdir"/*.zsh(N); do
                [[ -f "$file" ]] || continue
                ((total_files++))

                local filename="${subdir_name}/${file:t}"
                local has_guard=""
                local sentinel=""

                if has_sentinel_guard "$file"; then
                    ((files_with_sentinels++))
                    sentinel="$(get_existing_sentinel "$file")"
                    has_guard="✅"
                else
                    ((files_without_sentinels++))
                    missing_sentinel_files+=("$file")
                    has_guard="❌"
                fi

                printf "    %s %-43s %s\n" "$has_guard" "$filename" "${sentinel:-(none)}"
            done
        done
    fi

    echo ""
    log_info "$label Summary:"
    echo "  Total files: $total_files"
    echo "  With sentinels: $files_with_sentinels"
    echo "  Missing sentinels: $files_without_sentinels"

    if [[ ${#missing_sentinel_files[@]} -gt 0 ]]; then
        echo ""
        log_warn "Files missing sentinel guards in $label:"
        for file in "${missing_sentinel_files[@]}"; do
            local rel_path="${file#$dir/}"
            echo "  - $rel_path"
        done
    fi

    echo ""
    return $files_without_sentinels
}

# Fix all missing sentinel guards in directory
fix_directory() {
    local dir="$1"
    local label="$2"
    local dry_run="${3:-false}"
    local include_subdirs="${4:-false}"

    [[ -d "$dir" ]] || {
        log_warn "Directory not found: $dir"
        return 1
    }

    log_info "Fixing sentinel guards in $label directory..."

    local fixed_count=0
    local error_count=0

    # Process files in main directory
    for file in "$dir"/*.zsh(N); do
        [[ -f "$file" ]] || continue

        if ! has_sentinel_guard "$file"; then
            if add_sentinel_guard "$file" "$dry_run"; then
                ((fixed_count++))
            else
                ((error_count++))
            fi
        fi
    done

    # Process subdirectories if requested
    if [[ "$include_subdirs" == "true" ]]; then
        for subdir in "$dir"/*(N/); do
            [[ -d "$subdir" ]] || continue
            local subdir_name="${subdir:t}"
            log_debug "Processing subdirectory: $subdir_name"

            for file in "$subdir"/*.zsh(N); do
                [[ -f "$file" ]] || continue

                if ! has_sentinel_guard "$file"; then
                    if add_sentinel_guard "$file" "$dry_run"; then
                        ((fixed_count++))
                    else
                        ((error_count++))
                    fi
                fi
            done
        done
    fi

    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would fix $fixed_count files in $label"
    else
        log_success "Fixed $fixed_count files in $label"
    fi

    if [[ $error_count -gt 0 ]]; then
        log_error "Failed to fix $error_count files in $label"
        return 1
    fi

    return 0
}

# Main function
main() {
    local command="${1:-analyze}"
    local dry_run="false"

    case "$command" in
        analyze|check)
            echo "Sentinel Guard Analysis Report"
            echo "=============================="
            echo ""

            local pre_missing=0
            local post_missing=0

            analyze_directory "$PRE_PLUGIN_DIR" "Pre-plugin"
            pre_missing=$?

            analyze_directory "$POST_PLUGIN_DIR" "Post-plugin"
            post_missing=$?

            local redesign_pre_missing=0
            local redesign_post_missing=0

            if [[ -d "$PRE_PLUGIN_REDESIGN_DIR" ]]; then
                analyze_directory "$PRE_PLUGIN_REDESIGN_DIR" "Pre-plugin REDESIGN"
                redesign_pre_missing=$?
            fi

            if [[ -d "$POST_PLUGIN_REDESIGN_DIR" ]]; then
                analyze_directory "$POST_PLUGIN_REDESIGN_DIR" "Post-plugin REDESIGN" true
                redesign_post_missing=$?
            fi

            local total_missing=$((pre_missing + post_missing + redesign_pre_missing + redesign_post_missing))

            echo "Overall Summary:"
            echo "==============="
            echo "Total files missing sentinel guards: $total_missing"
            echo "  - Pre-plugin (current): $pre_missing"
            echo "  - Post-plugin (current): $post_missing"
            echo "  - Pre-plugin REDESIGN: $redesign_pre_missing"
            echo "  - Post-plugin REDESIGN: $redesign_post_missing"
            echo ""

            if [[ $total_missing -gt 0 ]]; then
                log_warn "Run 'fix-sentinel-guards.zsh fix' to add missing sentinel guards"
                log_warn "Run 'fix-sentinel-guards.zsh fix --dry-run' to preview changes"
                return 1
            else
                log_success "All files have proper sentinel guards!"
                return 0
            fi
            ;;

        fix)
            if [[ "$2" == "--dry-run" ]]; then
                dry_run="true"
                log_info "DRY RUN MODE - No files will be modified"
                echo ""
            fi

            echo "Fixing Sentinel Guards"
            echo "======================"
            echo ""

            fix_directory "$PRE_PLUGIN_DIR" "Pre-plugin" "$dry_run"
            fix_directory "$POST_PLUGIN_DIR" "Post-plugin" "$dry_run"

            if [[ -d "$PRE_PLUGIN_REDESIGN_DIR" ]]; then
                fix_directory "$PRE_PLUGIN_REDESIGN_DIR" "Pre-plugin REDESIGN" "$dry_run"
            fi

            if [[ -d "$POST_PLUGIN_REDESIGN_DIR" ]]; then
                fix_directory "$POST_PLUGIN_REDESIGN_DIR" "Post-plugin REDESIGN" "$dry_run" true
            fi

            echo ""
            if [[ "$dry_run" == "true" ]]; then
                log_info "DRY RUN completed. Run without --dry-run to apply changes."
            else
                log_success "Sentinel guard fixes completed!"
                log_info "Backups created with .sentinel-backup.* extension"
                log_info "Run 'fix-sentinel-guards.zsh analyze' to verify fixes"
            fi
            ;;

        test)
            # Test specific file
            local test_file="$2"
            if [[ -z "$test_file" ]]; then
                log_error "Usage: $0 test <file>"
                return 1
            fi

            if [[ ! -f "$test_file" ]]; then
                log_error "File not found: $test_file"
                return 1
            fi

            echo "Testing sentinel guard for: ${test_file:t}"
            echo ""

            if has_sentinel_guard "$test_file"; then
                local sentinel="$(get_existing_sentinel "$test_file")"
                log_success "File has sentinel guard: $sentinel"
            else
                log_warn "File missing sentinel guard"
                local suggested="$(generate_sentinel_name "$test_file")"
                echo "Suggested sentinel name: $suggested"
            fi
            ;;

        help|--help|-h)
            echo "ZSH Configuration Sentinel Guard Fixer"
            echo "======================================"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  analyze, check    Analyze sentinel guard status"
            echo "  fix              Add missing sentinel guards"
            echo "  fix --dry-run    Preview changes without modifying files"
            echo "  test <file>      Test specific file for sentinel guard"
            echo "  help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 analyze                    # Check current status"
            echo "  $0 fix --dry-run             # Preview changes"
            echo "  $0 fix                       # Apply fixes"
            echo "  $0 test file.zsh             # Test specific file"
            echo ""
            ;;

        *)
            log_error "Unknown command: $command"
            echo "Run '$0 help' for usage information"
            return 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
