#!/usr/bin/env zsh
#=============================================================================
# File: test-redesign-loading.zsh
# Purpose: Test REDESIGN module loading without full shell startup
# Author: ZSH Configuration Redesign Project
# Compliant with .config/ai/guidelines.md v<computed at runtime>
#=============================================================================

# Script configuration
readonly SCRIPT_DIR="${${(%):-%x}:A:h}"
readonly ZSH_CONFIG_DIR="${SCRIPT_DIR:h}"
readonly PRE_PLUGIN_REDESIGN_DIR="$ZSH_CONFIG_DIR/.zshrc.pre-plugins.d.REDESIGN"
readonly POST_PLUGIN_REDESIGN_DIR="$ZSH_CONFIG_DIR/.zshrc.d.REDESIGN"

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

# Simulate the load-shell-fragments function
load_shell_fragments() {
    local dir="$1"
    local label="${2:-$(basename "$dir")}"

    [[ -d "$dir" ]] || {
        log_error "Directory not found: $dir"
        return 1
    }

    log_info "Loading fragments from $label ($dir)"

    local fragments=("$dir"/*(N))
    if [[ ${#fragments[@]} -gt 0 ]]; then
        local fragment
        for fragment in "${fragments[@]}"; do
            if [[ -r "$fragment" && "$fragment" == *.zsh ]]; then
                log_debug "  Loading: ${fragment:t}"
                if source "$fragment"; then
                    log_debug "    ✅ Success: ${fragment:t}"
                else
                    log_error "    ❌ Failed: ${fragment:t}"
                    return 1
                fi
            fi
        done
    else
        log_warn "No fragments found in $dir"
        return 1
    fi

    return 0
}

# Test function availability
test_function_availability() {
    local -a zf_functions=(
        "zf::log"
        "zf::warn"
        "zf::debug"
        "zf::ensure_cmd"
        "zf::require"
        "zf::with_timing"
        "zf::timed"
        "zf::list_functions"
        "zf::script_dir"
    )

    log_info "Testing zf:: function availability"

    local available=0
    local total=${#zf_functions[@]}

    for func in "${zf_functions[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            log_success "  ✅ $func"
            ((available++))
        else
            log_error "  ❌ $func (not defined)"
        fi
    done

    echo ""
    log_info "Function availability: $available/$total"

    if [[ $available -eq $total ]]; then
        log_success "All zf:: functions are available!"
        return 0
    else
        log_error "Missing $((total - available)) zf:: functions"
        return 1
    fi
}

# Test sentinel guards
test_sentinel_guards() {
    local -a expected_sentinels=(
        "_LOADED_10_CORE_FUNCTIONS"
        "ZF_TRUST_ANCHORS_INITIALIZED"
        "ZF_FORCE_INTERACTIVE_OPTIONS"
    )

    log_info "Testing sentinel guard status"

    for sentinel in "${expected_sentinels[@]}"; do
        local value="${(P)sentinel}"
        if [[ -n "$value" ]]; then
            log_success "  ✅ $sentinel=$value"
        else
            log_warn "  ⚠️  $sentinel (unset)"
        fi
    done
    echo ""
}

# Main test function
main() {
    local command="${1:-test}"

    echo "REDESIGN Loading Test"
    echo "===================="
    echo ""

    # Set up environment
    export ZSH_ENABLE_PREPLUGIN_REDESIGN=1
    export ZSH_ENABLE_POSTPLUGIN_REDESIGN=1
    export ZDOTDIR="$ZSH_CONFIG_DIR"

    log_info "Environment setup:"
    echo "  ZSH_ENABLE_PREPLUGIN_REDESIGN=$ZSH_ENABLE_PREPLUGIN_REDESIGN"
    echo "  ZSH_ENABLE_POSTPLUGIN_REDESIGN=$ZSH_ENABLE_POSTPLUGIN_REDESIGN"
    echo "  ZDOTDIR=$ZDOTDIR"
    echo ""

    case "$command" in
        test|load)
            # Test current state first
            log_info "=== BEFORE LOADING ==="
            test_function_availability
            test_sentinel_guards

            # Load pre-plugin REDESIGN modules
            if [[ -d "$PRE_PLUGIN_REDESIGN_DIR" ]]; then
                echo ""
                log_info "=== LOADING PRE-PLUGIN REDESIGN ==="
                if load_shell_fragments "$PRE_PLUGIN_REDESIGN_DIR" "Pre-plugin REDESIGN"; then
                    log_success "Pre-plugin REDESIGN loaded successfully"
                else
                    log_error "Failed to load pre-plugin REDESIGN"
                fi
            else
                log_warn "Pre-plugin REDESIGN directory not found: $PRE_PLUGIN_REDESIGN_DIR"
            fi

            # Load post-plugin REDESIGN modules
            if [[ -d "$POST_PLUGIN_REDESIGN_DIR" ]]; then
                echo ""
                log_info "=== LOADING POST-PLUGIN REDESIGN ==="
                if load_shell_fragments "$POST_PLUGIN_REDESIGN_DIR" "Post-plugin REDESIGN"; then
                    log_success "Post-plugin REDESIGN loaded successfully"
                else
                    log_error "Failed to load post-plugin REDESIGN"
                fi
            else
                log_warn "Post-plugin REDESIGN directory not found: $POST_PLUGIN_REDESIGN_DIR"
            fi

            # Test final state
            echo ""
            log_info "=== AFTER LOADING ==="
            test_function_availability
            test_sentinel_guards
            ;;

        core-only)
            # Load only the core functions file
            log_info "=== LOADING CORE FUNCTIONS ONLY ==="
            local core_file="$POST_PLUGIN_REDESIGN_DIR/10-core-functions.zsh"
            if [[ -f "$core_file" ]]; then
                log_info "Loading: $core_file"
                if source "$core_file"; then
                    log_success "Core functions loaded successfully"
                    echo ""
                    test_function_availability
                    test_sentinel_guards
                else
                    log_error "Failed to load core functions"
                    return 1
                fi
            else
                log_error "Core functions file not found: $core_file"
                return 1
            fi
            ;;

        manifest-test)
            # Load core functions and run manifest test
            log_info "=== MANIFEST TEST ==="
            local core_file="$POST_PLUGIN_REDESIGN_DIR/10-core-functions.zsh"
            if [[ -f "$core_file" ]]; then
                source "$core_file" || {
                    log_error "Failed to load core functions"
                    return 1
                }

                # Run manifest test
                local manifest_test="$ZSH_CONFIG_DIR/tests/unit/core/test-core-functions-manifest.zsh"
                if [[ -f "$manifest_test" ]]; then
                    log_info "Running manifest test..."
                    "$manifest_test"
                else
                    log_error "Manifest test not found: $manifest_test"
                    return 1
                fi
            else
                log_error "Core functions file not found: $core_file"
                return 1
            fi
            ;;

        help|--help|-h)
            echo "REDESIGN Loading Test Tool"
            echo "=========================="
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  test, load       Load all REDESIGN modules and test"
            echo "  core-only        Load only core functions module"
            echo "  manifest-test    Load core functions and run manifest test"
            echo "  help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 test                  # Full REDESIGN loading test"
            echo "  $0 core-only             # Test core functions only"
            echo "  $0 manifest-test         # Test with manifest validation"
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
