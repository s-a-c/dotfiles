#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test platform detection (Darwin/Linux/BSD)

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

# Test: Platform detection via uname
test_uname_detection() {
    echo "Running: test_uname_detection"
    
    local os_type="$(uname -s)"
    
    if [[ -n "$os_type" ]]; then
        assert_passes "uname -s returns platform type: $os_type"
    else
        assert_fails "uname -s should return platform type"
    fi
    
    # Verify it's one of the expected platforms
    case "$os_type" in
        Darwin|Linux|FreeBSD|OpenBSD|NetBSD)
            assert_passes "Platform type is recognized: $os_type"
            ;;
        *)
            echo "  INFO: Unusual platform detected: $os_type"
            ;;
    esac
}

# Test: Darwin-specific directory detection
test_darwin_specific_dirs() {
    echo "Running: test_darwin_specific_dirs"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        # Check for common macOS-specific directories
        if [[ -d "/Applications" ]]; then
            assert_passes "macOS /Applications directory exists"
        fi
        
        if [[ -d "/Library" ]]; then
            assert_passes "macOS /Library directory exists"
        fi
        
        if [[ -d "/System/Library" ]]; then
            assert_passes "macOS /System/Library directory exists"
        fi
        
        # Check for Homebrew (common on macOS)
        if [[ -d "/opt/homebrew" ]] || [[ -d "/usr/local/Homebrew" ]]; then
            assert_passes "Homebrew directory detected on macOS"
        fi
    else
        echo "  SKIP: Not running on macOS"
    fi
}

# Test: Platform-conditional code loading
test_platform_conditional_loading() {
    echo "Running: test_platform_conditional_loading"
    
    local os_type="$(uname -s)"
    local darwin_dir="$REPO_ROOT/.zshrc.Darwin.d"
    
    if [[ "$os_type" == "Darwin" ]]; then
        # Darwin-specific directory should exist
        if [[ -d "$darwin_dir" ]]; then
            assert_passes "Darwin-specific directory exists: .zshrc.Darwin.d"
            
            # Check if it contains files
            if ls "$darwin_dir"/*.zsh >/dev/null 2>&1; then
                assert_passes "Darwin-specific directory contains .zsh files"
            else
                echo "  INFO: Darwin directory exists but contains no .zsh files"
            fi
        else
            echo "  INFO: .zshrc.Darwin.d not found (may be intentional)"
        fi
    else
        echo "  INFO: Platform is $os_type (Darwin-specific tests skipped)"
    fi
}

# Test: Arch-specific PATH elements
test_arch_specific_paths() {
    echo "Running: test_arch_specific_paths"
    
    local arch="$(uname -m)"
    
    if [[ -n "$arch" ]]; then
        assert_passes "Architecture detected: $arch"
        
        # On Apple Silicon, /opt/homebrew should be in PATH
        if [[ "$arch" == "arm64" && "$(uname -s)" == "Darwin" ]]; then
            if [[ ":$PATH:" == *":/opt/homebrew/bin:"* ]]; then
                assert_passes "Apple Silicon: /opt/homebrew/bin in PATH"
            else
                echo "  INFO: /opt/homebrew/bin not in PATH (may not be installed)"
            fi
        fi
        
        # On Intel Mac, /usr/local should be in PATH
        if [[ "$arch" == "x86_64" && "$(uname -s)" == "Darwin" ]]; then
            if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
                assert_passes "Intel Mac: /usr/local/bin in PATH"
            fi
        fi
    else
        assert_fails "Architecture detection failed"
    fi
}

# Run tests
test_uname_detection
test_darwin_specific_dirs
test_platform_conditional_loading
test_arch_specific_paths

# Summary
echo ""
echo "========================================="
echo "Platform Detection Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

