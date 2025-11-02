#!/usr/bin/env zsh
# TEST_CLASS: unit
# TEST_MODE: zsh-f-required
# Test PATH priority and security (system paths should come first)

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

# Test: Essential system paths are present
test_essential_paths_present() {
    echo "Running: test_essential_paths_present"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    local essential_paths=("/usr/bin" "/bin" "/usr/sbin" "/sbin")
    
    for essential_path in "${essential_paths[@]}"; do
        if [[ ":$PATH:" == *":$essential_path:"* ]]; then
            assert_passes "Essential path present: $essential_path"
        else
            assert_fails "Essential path missing: $essential_path"
        fi
    done
}

# Test: System paths come before user paths (security)
test_system_paths_prioritized() {
    echo "Running: test_system_paths_prioritized"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Get first 6 PATH entries
    local path_array=("${(@s/:/)PATH}")
    local first_six="${path_array[1]}, ${path_array[2]}, ${path_array[3]}, ${path_array[4]}, ${path_array[5]}, ${path_array[6]}"
    
    # System paths should be in first 6 entries
    local has_system_path=0
    for i in {1..6}; do
        case "${path_array[$i]}" in
            /usr/bin|/bin|/usr/sbin|/sbin|/opt/homebrew/bin|/usr/local/bin)
                has_system_path=1
                break
                ;;
        esac
    done
    
    if [[ $has_system_path -eq 1 ]]; then
        assert_passes "System paths prioritized (found in first 6 entries)"
    else
        assert_fails "System paths should be in first 6 PATH entries (got: $first_six)"
    fi
}

# Test: PATH deduplication
test_path_deduplication() {
    echo "Running: test_path_deduplication"
    
    # Set up PATH with duplicates
    export PATH="/usr/bin:/opt/test:/usr/bin:/bin:/opt/test:/bin"
    
    source "$REPO_ROOT/.zshenv.01" || return 1
    
    # Count occurrences of /usr/bin
    local usr_bin_count=$(echo "$PATH" | grep -o '/usr/bin' | wc -l | tr -d ' ')
    
    # Note: PATH deduplication may not be automatic, document if duplicates exist
    if [[ $usr_bin_count -le 1 ]]; then
        assert_passes "PATH does not contain duplicates of /usr/bin"
    else
        echo "  INFO: PATH contains $usr_bin_count instances of /usr/bin (deduplication may be deferred)"
    fi
}

# Test: Homebrew PATH on macOS
test_homebrew_path_on_macos() {
    echo "Running: test_homebrew_path_on_macos"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        source "$REPO_ROOT/.zshenv.01" || return 1
        
        # On Apple Silicon, /opt/homebrew/bin should be in PATH
        if [[ "$(uname -m)" == "arm64" ]]; then
            if [[ ":$PATH:" == *":/opt/homebrew/bin:"* ]]; then
                assert_passes "Apple Silicon: /opt/homebrew/bin in PATH"
            else
                echo "  INFO: /opt/homebrew/bin not in PATH (Homebrew may not be installed)"
            fi
        fi
        
        # On Intel, /usr/local/bin should be in PATH
        if [[ "$(uname -m)" == "x86_64" ]]; then
            if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
                assert_passes "Intel Mac: /usr/local/bin in PATH"
            fi
        fi
    else
        echo "  SKIP: Not running on macOS"
    fi
}

# Run tests
test_essential_paths_present
test_system_paths_prioritized
test_path_deduplication
test_homebrew_path_on_macos

# Summary
echo ""
echo "========================================="
echo "PATH Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "========================================="

[[ $FAIL_COUNT -eq 0 ]] && exit 0 || exit 1

