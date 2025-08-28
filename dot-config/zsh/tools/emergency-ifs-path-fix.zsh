#!/usr/bin/env zsh
# Emergency IFS and PATH Fix Script
# Restores shell functionality immediately
# Created: 2025-08-26

echo "🚨 Emergency IFS and PATH Fix Script"

# Reset IFS to default value immediately
unset IFS
IFS=$' \t\n'
export IFS

echo "Current IFS after reset: '${IFS}'"

# Fix PATH by replacing $sep with colons if needed
if [[ "$PATH" == *'$sep'* ]]; then
        zsh_debug_echo "🔧 Fixing corrupted PATH variable..."
    # Replace literal $sep with colons
    PATH="${PATH//\$sep/:}"
    export PATH
        zsh_debug_echo "✅ PATH fixed"
else
        zsh_debug_echo "✅ PATH appears to be clean"
fi

echo "Current PATH (first 100 chars): ${PATH:0:100}"

# Test basic commands
echo "🧪 Testing basic commands:"
/usr/bin/which date >/dev/null 2>&1 &&     zsh_debug_echo "✅ date command found" || zsh_debug_echo "❌ date command still missing"
/usr/bin/which sed >/dev/null 2>&1 &&     zsh_debug_echo "✅ sed command found" || zsh_debug_echo "❌ sed command still missing"
/usr/bin/which awk >/dev/null 2>&1 &&     zsh_debug_echo "✅ awk command found" || zsh_debug_echo "❌ awk command still missing"

echo "🎉 Emergency fix completed"
