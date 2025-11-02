#!/usr/bin/env zsh
# TEST_CLASS: integration
# TEST_MODE: zsh-f-required
# Integration test for cross-platform compatibility (Darwin vs Linux)

set -eo pipefail

# Minimal environment
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

typeset -i PASS_COUNT=0
typeset -i FAIL_COUNT=0

assert_passes() {
    ((PASS_COUNT++))
    echo "✓ PASS: $1"
}

assert_fails() {
    ((FAIL_COUNT++))
    echo "✗ FAIL: $1"
}

echo "========================================="
echo "Cross-Platform Compatibility Tests"
echo "Platform: $(uname -s) $(uname -m)"
echo "========================================="
echo ""

# Test: Core environment loads on current platform
test_core_env_loads() {
    echo "Running: test_core_env_loads"
    
    if source "$REPO_ROOT/.zshenv.01" 2>&1; then
        assert_passes "Core environment (.zshenv.01) loads on $(uname -s)"
    else
        assert_fails "Core environment should load on all platforms"
    fi
}

# Test: Essential variables set on all platforms
test_essential_vars_cross_platform() {
    echo "Running: test_essential_vars_cross_platform"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # These should be set on ALL platforms
    local essential_vars=("HOME" "ZDOTDIR" "ZSH_CACHE_DIR" "PATH")
    
    for var in "${essential_vars[@]}"; do
        if [[ -n "${(P)var:-}" ]]; then
            assert_passes "$var is set on $(uname -s)"
        else
            assert_fails "$var should be set on all platforms"
        fi
    done
}

# Test: Platform-specific directories handled correctly
test_platform_specific_dirs() {
    echo "Running: test_platform_specific_dirs"
    
    local os_type="$(uname -s)"
    
    case "$os_type" in
        Darwin)
            # macOS-specific checks
            if [[ -d "$REPO_ROOT/.zshrc.Darwin.d" ]]; then
                assert_passes "Darwin: .zshrc.Darwin.d exists for macOS"
            else
                echo "  INFO: .zshrc.Darwin.d not found"
            fi
            ;;
        Linux)
            # Linux could have .zshrc.Linux.d (if implemented)
            if [[ -d "$REPO_ROOT/.zshrc.Linux.d" ]]; then
                assert_passes "Linux: .zshrc.Linux.d exists"
            else
                echo "  INFO: .zshrc.Linux.d not implemented (using defaults)"
            fi
            ;;
        *)
            echo "  INFO: Platform $os_type - using default configuration"
            ;;
    esac
}

# Test: Package manager detection works cross-platform
test_package_manager_detection() {
    echo "Running: test_package_manager_detection"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Check if zf::detect_pkg_manager exists
    if typeset -f zf::detect_pkg_manager >/dev/null 2>&1; then
        assert_passes "Package manager detection function exists"
        
        # Try to detect package manager
        local pm="$(zf::detect_pkg_manager 2>/dev/null || echo "none")"
        echo "  INFO: Detected package manager: $pm"
        
        # Verify detection makes sense for platform
        local os_type="$(uname -s)"
        case "$os_type" in
            Darwin)
                if [[ "$pm" == "brew" || "$pm" == "port" || "$pm" == "none" ]]; then
                    assert_passes "Darwin: Package manager detection appropriate ($pm)"
                else
                    echo "  INFO: Unexpected package manager on Darwin: $pm"
                fi
                ;;
            Linux)
                if [[ "$pm" == "apt" || "$pm" == "yum" || "$pm" == "dnf" || "$pm" == "pacman" || "$pm" == "none" ]]; then
                    assert_passes "Linux: Package manager detection appropriate ($pm)"
                else
                    echo "  INFO: Unexpected package manager on Linux: $pm"
                fi
                ;;
        esac
    else
        echo "  INFO: zf::detect_pkg_manager not defined"
    fi
}

# Test: Path manipulation functions work cross-platform
test_path_functions_cross_platform() {
    echo "Running: test_path_functions_cross_platform"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Check if path manipulation functions exist
    local path_funcs=("zf::path_prepend" "zf::path_append" "zf::path_remove")
    
    for func in "${path_funcs[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            assert_passes "$func exists on $(uname -s)"
        else
            assert_fails "$func should exist on all platforms"
        fi
    done
}

# Run tests
test_core_env_loads
test_essential_vars_cross_platform
test_platform_specific_dirs
test_package_manager_detection
test_path_functions_cross_platform

# Summary
echo ""
echo "========================================="
echo "Cross-Platform Integration Test Results"
echo "========================================="
echo "Platform: $(uname -s) $(uname -m)"
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

