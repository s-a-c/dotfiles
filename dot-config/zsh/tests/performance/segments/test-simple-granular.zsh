#!/usr/bin/env zsh
# test-simple-granular.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Simple test to verify granular segments are being emitted correctly
#   from the updated modules.

set -euo pipefail

# Test setup
TMP_LOG="$(mktemp)"
export PERF_SEGMENT_LOG="$TMP_LOG"

# Define minimal required functions
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Source just the 20-essential-plugins module
print "Testing 20-essential-plugins.zsh..."
unset _LOADED_20_ESSENTIAL_PLUGINS 2>/dev/null || true
source ".zshrc.d.REDESIGN/20-essential-plugins.zsh"

# Check what was logged
print "\nSegments logged:"
grep "^SEGMENT" "$TMP_LOG" || print "(none)"

print "\nExpected segments:"
print "  - essential/zsh-syntax-highlighting"
print "  - essential/zsh-autosuggestions"
print "  - essential/zsh-completions"

print "\nChecking for expected segments..."
failed=0
for seg in "essential/zsh-syntax-highlighting" "essential/zsh-autosuggestions" "essential/zsh-completions"; do
    if grep -q "^SEGMENT name=${seg} " "$TMP_LOG"; then
        print "  ✓ Found: $seg"
    else
        print "  ✗ Missing: $seg"
        failed=1
    fi
done

# Cleanup
rm -f "$TMP_LOG"

if (( failed )); then
    print "\nFAIL: Some segments were missing"
    exit 1
else
    print "\nPASS: All segments found"
    exit 0
fi
