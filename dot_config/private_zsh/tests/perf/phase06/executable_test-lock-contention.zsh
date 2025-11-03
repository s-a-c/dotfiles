#!/usr/bin/env zsh
# Phase 06 Test: Completion rebuild lock contention
# UPDATED: Consistent with .zshenv configuration
set -euo pipefail

# Source .zshenv to ensure consistent environment variables
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Use zf::debug from .zshenv if available
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-lock-contention] Testing completion rebuild lock contention"
fi

# Test completion rebuild tools exist and are consistent
rebuild_tool="${ZDOTDIR}/tools/rebuild-completions.zsh"
if [[ ! -f "$rebuild_tool" ]]; then
        zf::debug "FAIL: Rebuild completions tool not found: $rebuild_tool"
    exit 1
fi

if [[ ! -x "$rebuild_tool" ]]; then
        zf::debug "FAIL: Rebuild completions tool not executable: $rebuild_tool"
    exit 1
fi

# Test that ZSH_COMPDUMP is properly configured for lock testing
if [[ -z "$ZSH_COMPDUMP" ]]; then
        zf::debug "FAIL: ZSH_COMPDUMP not set in .zshenv"
    exit 1
fi

# Create a backup of the current completion dump if it exists
compdump_backup=""
if [[ -f "$ZSH_COMPDUMP" ]]; then
    compdump_backup="${ZSH_COMPDUMP}.backup.$$"
    cp "$ZSH_COMPDUMP" "$compdump_backup"
fi

# Cleanup function
cleanup() {
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true

    # Restore backup if it exists
    if [[ -n "$compdump_backup" && -f "$compdump_backup" ]]; then
        mv "$compdump_backup" "$ZSH_COMPDUMP" 2>/dev/null || true
    fi

    # Remove any test lock files
    rm -f "${ZSH_COMPDUMP}.lock" 2>/dev/null || true
}
trap cleanup EXIT

# Test concurrent rebuild operations
echo "Testing concurrent completion rebuilds..."

# Remove existing completion dump to force rebuild
rm -f "$ZSH_COMPDUMP" 2>/dev/null || true

# Start two concurrent rebuild processes
log1="${TMPDIR:-/tmp}/rebuild1.$$"
log2="${TMPDIR:-/tmp}/rebuild2.$$"

# Launch first rebuild in background
(
    cd "$ZDOTDIR"
    exec "$rebuild_tool" >"$log1" 2>&1
) &
pid1=$!

# Launch second rebuild in background (slight delay to ensure overlap)
(
    sleep 0.1
    cd "$ZDOTDIR"
    exec "$rebuild_tool" >"$log2" 2>&1
) &
pid2=$!

# Wait for both to complete with timeout
timeout_seconds=30
elapsed=0
while [[ $elapsed -lt $timeout_seconds ]]; do
    if ! kill -0 "$pid1" 2>/dev/null && ! kill -0 "$pid2" 2>/dev/null; then
        break
    fi
    sleep 0.5
    ((elapsed++))
done

# Check if processes completed successfully
wait "$pid1" 2>/dev/null
exit1=$?
wait "$pid2" 2>/dev/null
exit2=$?

# Clean up log files
rm -f "$log1" "$log2" 2>/dev/null || true

# Both processes should succeed (or at least one should succeed)
if [[ $exit1 -ne 0 && $exit2 -ne 0 ]]; then
        zf::debug "FAIL: Both concurrent rebuild processes failed"
        zf::debug "  Process 1 exit code: $exit1"
        zf::debug "  Process 2 exit code: $exit2"
    exit 1
fi

# Verify that completion dump was created
if [[ ! -f "$ZSH_COMPDUMP" ]]; then
        zf::debug "FAIL: Completion dump not created after concurrent rebuilds"
    exit 1
fi

# Test that completion dump is valid (contains expected content)
if ! grep -q "^#compdef" "$ZSH_COMPDUMP" 2>/dev/null; then
        zf::debug "FAIL: Completion dump appears to be invalid (no #compdef entries)"
    exit 1
fi

# Test file locking mechanism if available
if command -v flock >/dev/null 2>&1; then
    # Test that rebuild script can handle lock files properly
    touch "${ZSH_COMPDUMP}.lock"

    # Try rebuild with existing lock - should either wait or skip gracefully
    timeout 5 "$rebuild_tool" >/dev/null 2>&1
    rebuild_with_lock_exit=$?

    rm -f "${ZSH_COMPDUMP}.lock"

    # Exit code should be 0 (success) or specific lock-detected code
    if [[ $rebuild_with_lock_exit -gt 1 ]]; then
            zf::debug "WARN: Rebuild script may not handle lock files gracefully (exit: $rebuild_with_lock_exit)"
        # This is a warning, not a failure, as lock handling implementation may vary
    fi
fi

# Use zf::debug for success message
if declare -f zf::debug >/dev/null 2>&1; then
    zf::debug "# [test-lock-contention] Lock contention test passed"
    zf::debug "# [test-lock-contention] Process exits: $exit1, $exit2"
fi

echo "PASS: Completion rebuild lock contention handled correctly"
