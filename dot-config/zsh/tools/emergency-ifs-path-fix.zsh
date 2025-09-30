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
        zf::debug "🔧 Fixing corrupted PATH variable..."
    # Replace literal $sep with colons
    PATH="${PATH//\$sep/:}"
    export PATH
        zf::debug "✅ PATH fixed"
else
        zf::debug "✅ PATH appears to be clean"
fi

echo "Current PATH (first 100 chars): ${PATH:0:100}"

# Test basic commands
echo "🧪 Testing basic commands:"
/usr/bin/which date >/dev/null 2>&1 &&     zf::debug "✅ date command found" || zf::debug "❌ date command still missing"
/usr/bin/which sed >/dev/null 2>&1 &&     zf::debug "✅ sed command found" || zf::debug "❌ sed command still missing"
/usr/bin/which awk >/dev/null 2>&1 &&     zf::debug "✅ awk command found" || zf::debug "❌ awk command still missing"

echo "🎉 Emergency fix completed"
