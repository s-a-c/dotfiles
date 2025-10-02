#!/usr/bin/env zsh
#=============================================================================
# File: test-zf-functions.zsh
# Purpose: Force-load REDESIGN modules and test zf:: function manifest
# Author: ZSH Configuration Redesign Project
# Compliant with dotfiles/dot-config/ai/guidelines.md v<computed at runtime>
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

# Force-load REDESIGN core functions
force_load_redesign_core() {
    local core_file="$ZSH_CONFIG_DIR/.zshrc.d.REDESIGN/10-core-functions.zsh"

    log_info "Force-loading REDESIGN core functions"

    if [[ ! -f "$core_file" ]]; then
        log_error "REDESIGN core functions file not found: $core_file"
        return 1
    fi

    # Clear any existing sentinel to force reload
    unset _LOADED_10_CORE_FUNCTIONS

    # Source the core functions file
    if source "$core_file"; then
        log_success "REDESIGN core functions loaded successfully"
        return 0
    else
        log_error "Failed to load REDESIGN core functions"
        return 1
    fi
}

# Test zf:: function availability
test_zf_functions() {
    log_info "Testing zf:: function availability"

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

# Test zf::list_functions specifically
test_zf_list_functions() {
    log_info "Testing zf::list_functions output"

    if ! typeset -f zf::list_functions >/dev/null 2>&1; then
        log_error "zf::list_functions not available"
        return 1
    fi

    local functions_output
    functions_output=$(zf::list_functions 2>/dev/null)

    if [[ -z "$functions_output" ]]; then
        log_error "zf::list_functions returned no output"
        return 1
    fi

    local function_count
    function_count=$(echo "$functions_output" | wc -l | tr -d ' ')

    log_success "zf::list_functions returned $function_count functions:"
    echo "$functions_output" | sed 's/^/    /'

    return 0
}

# Run the manifest test in the current context
run_manifest_test() {
    log_info "Running manifest test with zf:: functions loaded"

    local manifest_test="$ZSH_CONFIG_DIR/tests/unit/core/test-core-functions-manifest.zsh"

    if [[ ! -f "$manifest_test" ]]; then
        log_error "Manifest test not found: $manifest_test"
        return 1
    fi

    # Set environment to use current context (not spawn new shell)
    export CORE_FN_MANIFEST_WARN_ONLY=0

    log_info "Executing manifest test..."
    echo "========================================"

    # Execute in current context to preserve loaded functions
    if "$manifest_test"; then
        log_success "Manifest test passed!"
        return 0
    else
        log_error "Manifest test failed"
        return 1
    fi
}

# Compare current vs expected functions
compare_functions() {
    log_info "Comparing current vs expected zf:: functions"

    # Expected functions from golden manifest
    local -a expected_functions=(
        "zf::debug"
        "zf::ensure_cmd"
        "zf::list_functions"
        "zf::log"
        "zf::require"
        "zf::timed"
        "zf::warn"
        "zf::with_timing"
    )

    # Get current functions
    local -a current_functions
    if typeset -f zf::list_functions >/dev/null 2>&1; then
        while IFS= read -r func; do
            [[ -n "$func" ]] && current_functions+=("$func")
        done < <(zf::list_functions 2>/dev/null)
    fi

    log_info "Expected functions (${#expected_functions[@]}):"
    printf "  %s\n" "${expected_functions[@]}"

    log_info "Current functions (${#current_functions[@]}):"
    printf "  %s\n" "${current_functions[@]}"

    # Check for differences
    local -a missing=()
    local -a extra=()

    # Find missing functions
    for expected in "${expected_functions[@]}"; do
        local found=0
        for current in "${current_functions[@]}"; do
            if [[ "$expected" == "$current" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            missing+=("$expected")
        fi
    done

    # Find extra functions
    for current in "${current_functions[@]}"; do
        local found=0
        for expected in "${expected_functions[@]}"; do
            if [[ "$current" == "$expected" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            extra+=("$current")
        fi
    done

    # Report differences
    if [[ ${#missing[@]} -eq 0 && ${#extra[@]} -eq 0 ]]; then
        log_success "✅ Functions match exactly!"
        return 0
    else
        if [[ ${#missing[@]} -gt 0 ]]; then
            log_error "❌ Missing functions (${#missing[@]}):"
            printf "    %s\n" "${missing[@]}"
        fi
        if [[ ${#extra[@]} -gt 0 ]]; then
            log_warn "⚠️  Extra functions (${#extra[@]}):"
            printf "    %s\n" "${extra[@]}"
        fi
        return 1
    fi
}

# Main function
main() {
    local command="${1:-test}"

    echo "ZSH zf:: Function Testing Tool"
    echo "=============================="
    echo ""

    case "$command" in
        test|load-and-test)
            # Full test sequence
            force_load_redesign_core || return 1
            echo ""
            test_zf_functions || return 1
            echo ""
            test_zf_list_functions || return 1
            echo ""
            compare_functions || return 1
            ;;

        manifest)
            # Load functions and run manifest test
            force_load_redesign_core || return 1
            echo ""
            test_zf_functions || return 1
            echo ""
            run_manifest_test || return 1
            ;;

        list)
            # Just test zf::list_functions
            force_load_redesign_core || return 1
            echo ""
            test_zf_list_functions || return 1
            ;;

        compare)
            # Load and compare functions
            force_load_redesign_core || return 1
            echo ""
            compare_functions || return 1
            ;;

        help|--help|-h)
            echo "ZSH zf:: Function Testing Tool"
            echo "==============================="
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  test             Load REDESIGN functions and test availability"
            echo "  manifest         Load functions and run manifest test"
            echo "  list             Test zf::list_functions output"
            echo "  compare          Compare current vs expected functions"
            echo "  help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 test                    # Full function test"
            echo "  $0 manifest                # Run manifest validation"
            echo "  $0 list                    # Test function listing"
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
