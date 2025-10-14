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
<<<<<<< HEAD
        zf::debug "🔧 Fixing corrupted PATH variable..."
    # Replace literal $sep with colons
    PATH="${PATH//\$sep/:}"
    export PATH
        zf::debug "✅ PATH fixed"
else
        zf::debug "✅ PATH appears to be clean"
=======
        zsh_debug_echo "🔧 Fixing corrupted PATH variable..."
    # Replace literal $sep with colons
    PATH="${PATH//\$sep/:}"
    export PATH
        zsh_debug_echo "✅ PATH fixed"
else
        zsh_debug_echo "✅ PATH appears to be clean"
>>>>>>> origin/develop
fi

echo "Current PATH (first 100 chars): ${PATH:0:100}"

# Test basic commands
echo "🧪 Testing basic commands:"
<<<<<<< HEAD
/usr/bin/which date >/dev/null 2>&1 &&     zf::debug "✅ date command found" || zf::debug "❌ date command still missing"
/usr/bin/which sed >/dev/null 2>&1 &&     zf::debug "✅ sed command found" || zf::debug "❌ sed command still missing"
/usr/bin/which awk >/dev/null 2>&1 &&     zf::debug "✅ awk command found" || zf::debug "❌ awk command still missing"
=======
/usr/bin/which date >/dev/null 2>&1 &&     zsh_debug_echo "✅ date command found" || zsh_debug_echo "❌ date command still missing"
/usr/bin/which sed >/dev/null 2>&1 &&     zsh_debug_echo "✅ sed command found" || zsh_debug_echo "❌ sed command still missing"
/usr/bin/which awk >/dev/null 2>&1 &&     zsh_debug_echo "✅ awk command found" || zsh_debug_echo "❌ awk command still missing"
>>>>>>> origin/develop

echo "🎉 Emergency fix completed"
