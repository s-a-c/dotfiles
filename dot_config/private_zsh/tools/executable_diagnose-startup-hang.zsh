#!/usr/bin/env zsh
#=============================================================================
# File: diagnose-startup-hang.zsh
# Purpose: Diagnose where shell startup is hanging to fix REDESIGN loading
# Author: ZSH Configuration Redesign Project
# Compliant with .config/ai/guidelines.md v<computed at runtime>
#=============================================================================

# Script configuration
readonly SCRIPT_DIR="${${(%):-%x}:A:h}"
readonly ZSH_CONFIG_DIR="${SCRIPT_DIR:h}"

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

# Create a minimal test zshrc that traces execution
create_trace_zshrc() {
    local trace_file="$ZSH_CONFIG_DIR/.zshrc.trace-test"
    local progress_log="/tmp/zsh-startup-trace.log"

    log_info "Creating traced zshrc: $trace_file"

    cat > "$trace_file" << 'EOF'
#!/usr/bin/env zsh
# Traced ZSH startup for diagnosing hangs
# This file logs progress at each major step

PROGRESS_LOG="/tmp/zsh-startup-trace.log"
echo "=== ZSH STARTUP TRACE $(date) ===" > "$PROGRESS_LOG"

trace_progress() {
    local step="$1"
    echo "[$(date '+%H:%M:%S')] $step" | tee -a "$PROGRESS_LOG"
}

trace_progress "START: Beginning .zshrc execution"

# Set basic environment
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
trace_progress "ENV: ZDOTDIR set to $ZDOTDIR"

# Source .zshenv if not already loaded
if [[ -z "${ZSH_ZSHENV_LOADED:-}" ]]; then
    trace_progress "ZSHENV: Loading .zshenv"
    [[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
    trace_progress "ZSHENV: Completed loading .zshenv"
fi

# Check REDESIGN environment variables
trace_progress "REDESIGN: ZSH_ENABLE_PREPLUGIN_REDESIGN=${ZSH_ENABLE_PREPLUGIN_REDESIGN:-unset}"
trace_progress "REDESIGN: ZSH_ENABLE_POSTPLUGIN_REDESIGN=${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-unset}"

# Define load-shell-fragments if not available
if ! typeset -f load-shell-fragments >/dev/null 2>&1; then
    trace_progress "FUNCTION: Defining load-shell-fragments"
    function load-shell-fragments() {
        local dir="$1"
        trace_progress "LOAD: Starting load-shell-fragments for $dir"
        if [[ -z "$dir" ]]; then
            trace_progress "ERROR: load-shell-fragments called without directory"
            return 1
        fi
        if [[ -d "$dir" ]]; then
            local fragments=("$dir"/*(N))
            if [[ ${#fragments[@]} -gt 0 ]]; then
                local fragment
                for fragment in "${fragments[@]}"; do
                    if [[ -r "$fragment" ]]; then
                        trace_progress "LOAD: Sourcing ${fragment:t}"
                        source "$fragment" || {
                            trace_progress "ERROR: Failed to source ${fragment:t}"
                            return 1
                        }
                    fi
                done
                trace_progress "LOAD: Completed load-shell-fragments for $dir"
            else
                trace_progress "WARN: No fragments found in $dir"
            fi
        else
            trace_progress "ERROR: Directory not found: $dir"
            return 1
        fi
    }
fi

# Test pre-plugin loading
trace_progress "PRE-PLUGIN: Starting pre-plugin section"
if [[ ${ZSH_ENABLE_PREPLUGIN_REDESIGN:-0} == 1 && -d "$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN" ]]; then
    trace_progress "PRE-PLUGIN: Loading REDESIGN pre-plugins"
    load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d.REDESIGN" || {
        trace_progress "ERROR: Failed to load REDESIGN pre-plugins"
    }
else
    trace_progress "PRE-PLUGIN: Loading standard pre-plugins"
    [[ -d "$ZDOTDIR/.zshrc.pre-plugins.d" ]] && load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d"
fi
trace_progress "PRE-PLUGIN: Completed pre-plugin section"

# Test zgenom availability (this is likely where it hangs)
trace_progress "ZGENOM: Testing zgenom availability"
if command -v zgenom >/dev/null 2>&1; then
    trace_progress "ZGENOM: Found zgenom command"

    # Test zgenom saved status with timeout
    trace_progress "ZGENOM: Testing 'zgenom saved' with timeout"
    if timeout 5s zgenom saved >/dev/null 2>&1; then
        trace_progress "ZGENOM: 'zgenom saved' completed successfully"
    else
        trace_progress "ERROR: 'zgenom saved' timed out or failed"
        trace_progress "ZGENOM: This is likely where startup hangs"
    fi
else
    trace_progress "WARN: zgenom command not found"
fi

# Skip actual plugin loading for this test
trace_progress "PLUGINS: Skipping actual plugin loading for diagnosis"

# Test post-plugin loading
trace_progress "POST-PLUGIN: Starting post-plugin section"
if [[ ${ZSH_ENABLE_POSTPLUGIN_REDESIGN:-0} == 1 && -d "$ZDOTDIR/.zshrc.d.REDESIGN" ]]; then
    trace_progress "POST-PLUGIN: Loading REDESIGN post-plugins"
    load-shell-fragments "$ZDOTDIR/.zshrc.d.REDESIGN" || {
        trace_progress "ERROR: Failed to load REDESIGN post-plugins"
    }

    # Test if zf:: functions are available
    if typeset -f zf::log >/dev/null 2>&1; then
        trace_progress "SUCCESS: zf::log function is available"
    else
        trace_progress "ERROR: zf::log function not available after REDESIGN loading"
    fi
else
    trace_progress "POST-PLUGIN: Loading standard post-plugins"
    [[ -d "$ZDOTDIR/.zshrc.d" ]] && load-shell-fragments "$ZDOTDIR/.zshrc.d"
fi
trace_progress "POST-PLUGIN: Completed post-plugin section"

trace_progress "COMPLETE: .zshrc execution completed successfully"
echo "=== TRACE COMPLETE ===" >> "$PROGRESS_LOG"
EOF

    chmod +x "$trace_file"
    echo "$trace_file"
}

# Run traced startup test
run_traced_startup() {
    local trace_file="$1"
    local progress_log="/tmp/zsh-startup-trace.log"
    local timeout_duration="${2:-10}"

    log_info "Running traced startup test (timeout: ${timeout_duration}s)"

    # Clear previous log
    rm -f "$progress_log"

    # Run with timeout
    if timeout "$timeout_duration" zsh -c "source '$trace_file'" 2>&1; then
        log_success "Traced startup completed within timeout"
    else
        log_error "Traced startup timed out or failed"
    fi

    # Show the trace log
    if [[ -f "$progress_log" ]]; then
        echo ""
        log_info "Startup trace log:"
        echo "=================="
        cat "$progress_log"
        echo "=================="
    else
        log_error "No trace log generated"
    fi
}

# Test zgenom specifically
test_zgenom_issues() {
    log_info "Testing zgenom-specific issues"

    echo ""
    log_info "Zgenom command availability:"
    if command -v zgenom >/dev/null 2>&1; then
        log_success "  ✅ zgenom command found: $(which zgenom)"
    else
        log_error "  ❌ zgenom command not found"
        return 1
    fi

    echo ""
    log_info "Zgenom directory structure:"
    local zgen_dir="${ZGEN_DIR:-$ZSH_CONFIG_DIR/.zqs-zgenom}"
    if [[ -d "$zgen_dir" ]]; then
        log_success "  ✅ Zgenom directory exists: $zgen_dir"
        echo "    Contents:"
        ls -la "$zgen_dir" 2>/dev/null | head -10 | sed 's/^/      /'
    else
        log_error "  ❌ Zgenom directory missing: $zgen_dir"
    fi

    echo ""
    log_info "Testing zgenom saved (with timeout):"
    if timeout 3s zgenom saved >/dev/null 2>&1; then
        log_success "  ✅ 'zgenom saved' completed quickly"
    else
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            log_error "  ❌ 'zgenom saved' timed out (this is likely the hang source)"
        else
            log_error "  ❌ 'zgenom saved' failed with exit code $exit_code"
        fi
    fi

    echo ""
    log_info "Zgenom init file status:"
    local init_file="${ZGEN_INIT:-$zgen_dir/init.zsh}"
    if [[ -f "$init_file" ]]; then
        log_success "  ✅ Zgenom init file exists: $init_file"
        local size=$(stat -f%z "$init_file" 2>/dev/null || stat -c%s "$init_file" 2>/dev/null || echo "unknown")
        echo "    Size: $size bytes"
        echo "    Last modified: $(stat -f%Sm "$init_file" 2>/dev/null || stat -c%y "$init_file" 2>/dev/null || echo "unknown")"
    else
        log_error "  ❌ Zgenom init file missing: $init_file"
    fi
}

# Test REDESIGN loading in isolation
test_redesign_isolation() {
    log_info "Testing REDESIGN loading in isolation"

    # Set up environment
    export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
    export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1
    export ZDOTDIR="$ZSH_CONFIG_DIR"

    # Test pre-plugin REDESIGN
    echo ""
    log_info "Pre-plugin REDESIGN directory:"
    local pre_dir="$ZSH_CONFIG_DIR/.zshrc.pre-plugins.d.REDESIGN"
    if [[ -d "$pre_dir" ]]; then
        log_success "  ✅ Directory exists: $pre_dir"
        echo "    Files: $(ls "$pre_dir"/*.zsh 2>/dev/null | wc -l | tr -d ' ')"
    else
        log_error "  ❌ Directory missing: $pre_dir"
    fi

    # Test post-plugin REDESIGN
    echo ""
    log_info "Post-plugin REDESIGN directory:"
    local post_dir="$ZSH_CONFIG_DIR/.zshrc.d.REDESIGN"
    if [[ -d "$post_dir" ]]; then
        log_success "  ✅ Directory exists: $post_dir"
        echo "    Files: $(ls "$post_dir"/*.zsh 2>/dev/null | wc -l | tr -d ' ')"

        # Test core functions loading
        local core_file="$post_dir/10-core-functions.zsh"
        if [[ -f "$core_file" ]]; then
            log_info "    Testing core functions file..."
            if source "$core_file" 2>/dev/null; then
                if typeset -f zf::log >/dev/null 2>&1; then
                    log_success "    ✅ Core functions loaded successfully"
                else
                    log_error "    ❌ Core functions loaded but zf::log not available"
                fi
            else
                log_error "    ❌ Failed to source core functions file"
            fi
        else
            log_error "    ❌ Core functions file missing: $core_file"
        fi
    else
        log_error "  ❌ Directory missing: $post_dir"
    fi
}

# Main function
main() {
    local command="${1:-full}"

    echo "ZSH Startup Hang Diagnosis"
    echo "=========================="
    echo ""

    case "$command" in
        full|trace)
            local trace_file=$(create_trace_zshrc)
            run_traced_startup "$trace_file" 10
            echo ""
            test_zgenom_issues
            echo ""
            test_redesign_isolation
            ;;

        zgenom)
            test_zgenom_issues
            ;;

        redesign)
            test_redesign_isolation
            ;;

        quick)
            local trace_file=$(create_trace_zshrc)
            run_traced_startup "$trace_file" 5
            ;;

        help|--help|-h)
            echo "ZSH Startup Hang Diagnosis Tool"
            echo "==============================="
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  full, trace      Complete diagnosis with traced startup"
            echo "  zgenom          Test zgenom-specific issues only"
            echo "  redesign        Test REDESIGN loading in isolation"
            echo "  quick           Quick traced startup test (5s timeout)"
            echo "  help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 full                     # Complete diagnosis"
            echo "  $0 zgenom                   # Focus on zgenom issues"
            echo "  $0 redesign                 # Test REDESIGN loading"
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
