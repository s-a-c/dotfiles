#!/usr/bin/env zsh
# Phase 05 Test: PATH Lock Enforcement
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

<<<<<<< HEAD
# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-path-lock] Testing PATH deduplication function consistency"
=======
# Use zsh_debug_echo from .zshenv if available
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-path-lock] Testing PATH deduplication function consistency"
>>>>>>> origin/develop
fi

# Test that path_dedupe function exists and works correctly
if ! declare -f path_dedupe >/dev/null 2>&1; then
<<<<<<< HEAD
        zf::debug "FAIL: path_dedupe function not available from .zshenv"
=======
        zsh_debug_echo "FAIL: path_dedupe function not available from .zshenv"
>>>>>>> origin/develop
    exit 1
fi

# Test path_dedupe functionality with a controlled PATH
original_path="$PATH"
test_path="/usr/bin:/bin:/usr/bin:/usr/local/bin:/bin:/usr/sbin"

# Set test PATH with known duplicates
PATH="$test_path"

# Run path_dedupe
path_dedupe

# Check that duplicates were removed
if [[ "$PATH" == *"/usr/bin:/bin:/usr/bin"* ]] || [[ "$PATH" == *"/bin:/usr/local/bin:/bin"* ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: path_dedupe did not remove duplicates"
        zf::debug "  Test PATH: $test_path"
        zf::debug "  Result PATH: $PATH"
=======
        zsh_debug_echo "FAIL: path_dedupe did not remove duplicates"
        zsh_debug_echo "  Test PATH: $test_path"
        zsh_debug_echo "  Result PATH: $PATH"
>>>>>>> origin/develop
    PATH="$original_path"  # Restore original PATH
    exit 1
fi

# Verify essential paths are still present
essential_paths=("/usr/bin" "/bin" "/usr/local/bin" "/usr/sbin")
for essential_path in "${essential_paths[@]}"; do
    if [[ ":$PATH:" != *":$essential_path:"* ]]; then
<<<<<<< HEAD
            zf::debug "FAIL: Essential path removed by path_dedupe: $essential_path"
=======
            zsh_debug_echo "FAIL: Essential path removed by path_dedupe: $essential_path"
>>>>>>> origin/develop
        PATH="$original_path"  # Restore original PATH
        exit 1
    fi
done

# Test that PATH_DEDUP_DONE flag is set
if [[ -z "$PATH_DEDUP_DONE" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: PATH_DEDUP_DONE flag not set by path_dedupe"
=======
        zsh_debug_echo "FAIL: PATH_DEDUP_DONE flag not set by path_dedupe"
>>>>>>> origin/develop
    PATH="$original_path"  # Restore original PATH
    exit 1
fi

# Test path_dedupe idempotency (running twice should not change PATH)
deduped_path="$PATH"
path_dedupe
if [[ "$PATH" != "$deduped_path" ]]; then
<<<<<<< HEAD
        zf::debug "FAIL: path_dedupe is not idempotent"
        zf::debug "  First run: $deduped_path"
        zf::debug "  Second run: $PATH"
=======
        zsh_debug_echo "FAIL: path_dedupe is not idempotent"
        zsh_debug_echo "  First run: $deduped_path"
        zsh_debug_echo "  Second run: $PATH"
>>>>>>> origin/develop
    PATH="$original_path"  # Restore original PATH
    exit 1
fi

# Restore original PATH
PATH="$original_path"

# Test that XDG_BIN_HOME is properly handled if it exists
if [[ -d "$XDG_BIN_HOME" ]]; then
    if [[ ":$PATH:" != *":$XDG_BIN_HOME:"* ]]; then
<<<<<<< HEAD
            zf::debug "FAIL: XDG_BIN_HOME not found in PATH despite directory existing"
            zf::debug "  XDG_BIN_HOME: $XDG_BIN_HOME"
            zf::debug "  PATH: $PATH"
=======
            zsh_debug_echo "FAIL: XDG_BIN_HOME not found in PATH despite directory existing"
            zsh_debug_echo "  XDG_BIN_HOME: $XDG_BIN_HOME"
            zsh_debug_echo "  PATH: $PATH"
>>>>>>> origin/develop
        exit 1
    fi
fi

<<<<<<< HEAD
# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-path-lock] PATH deduplication function test passed"
    zf::debug "# [test-path-lock] PATH_DEDUP_DONE=$PATH_DEDUP_DONE"
=======
# Use zsh_debug_echo for success message
if declare -f zsh_debug_echo >/dev/null 2>&1; then
    zsh_debug_echo "# [test-path-lock] PATH deduplication function test passed"
    zsh_debug_echo "# [test-path-lock] PATH_DEDUP_DONE=$PATH_DEDUP_DONE"
>>>>>>> origin/develop
fi

echo "PASS: PATH deduplication function working correctly"
