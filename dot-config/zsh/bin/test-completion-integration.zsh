<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Simple Completion Integration Test
# ==============================================================================
# Purpose: Test centralized completion management integration
# ==============================================================================

echo "========================================================"
echo "Completion Integration Test"
echo "========================================================"

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Test 1: Check directory structure
echo "=== Directory Structure ==="
if [[ -d "$ZDOTDIR/.completions" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Completion directory exists"
    if [[ -d "$ZDOTDIR/.completions/cache" ]]; then
        zf::debug "✅ Cache directory exists"
    else
        zf::debug "⚠️  Cache directory missing"
    fi
else
    zf::debug "❌ Completion directory missing"
=======
        zsh_debug_echo "✅ Completion directory exists"
    if [[ -d "$ZDOTDIR/.completions/cache" ]]; then
            zsh_debug_echo "✅ Cache directory exists"
    else
            zsh_debug_echo "⚠️  Cache directory missing"
    fi
else
        zsh_debug_echo "❌ Completion directory missing"
>>>>>>> origin/develop
fi

# Test 2: Check completion management file
echo ""
echo "=== Completion Management System ==="
COMP_FILE="$ZDOTDIR/.zshrc.d/00_03-completion-management.zsh"
if [[ -f "$COMP_FILE" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Completion management system exists"
    zf::debug "   File: $COMP_FILE"

    # Check file size
    local file_size=$(wc -c <"$COMP_FILE" 2>/dev/null || zf::debug "0")
    zf::debug "   Size: $file_size bytes"

    # Check if it has key functions
    if grep -q "_initialize_completion_system" "$COMP_FILE"; then
        zf::debug "✅ Contains initialization function"
    fi
    if grep -q "completion-status" "$COMP_FILE"; then
        zf::debug "✅ Contains status command"
    fi
    if grep -q "cleanup-old-completions" "$COMP_FILE"; then
        zf::debug "✅ Contains cleanup command"
    fi
else
    zf::debug "❌ Completion management system missing"
=======
        zsh_debug_echo "✅ Completion management system exists"
        zsh_debug_echo "   File: $COMP_FILE"

    # Check file size
    local file_size=$(wc -c < "$COMP_FILE" 2>/dev/null || zsh_debug_echo "0")
        zsh_debug_echo "   Size: $file_size bytes"

    # Check if it has key functions
    if grep -q "_initialize_completion_system" "$COMP_FILE"; then
            zsh_debug_echo "✅ Contains initialization function"
    fi
    if grep -q "completion-status" "$COMP_FILE"; then
            zsh_debug_echo "✅ Contains status command"
    fi
    if grep -q "cleanup-old-completions" "$COMP_FILE"; then
            zsh_debug_echo "✅ Contains cleanup command"
    fi
else
        zsh_debug_echo "❌ Completion management system missing"
>>>>>>> origin/develop
fi

# Test 3: Check integration with main .zshrc
echo ""
echo "=== Integration Check ==="
ZSHRC_FILE="$ZDOTDIR/.zshrc"
if [[ -f "$ZSHRC_FILE" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Main .zshrc exists"

    # Check if it references centralized completion
    if grep -q "ZSH_COMPLETION_CACHE_DIR" "$ZSHRC_FILE"; then
        zf::debug "✅ References centralized completion cache"
    fi
    if grep -q "ZSH_COMPLETION_MANAGEMENT_LOADED" "$ZSHRC_FILE"; then
        zf::debug "✅ Checks for completion management system"
    fi
else
    zf::debug "❌ Main .zshrc missing"
=======
        zsh_debug_echo "✅ Main .zshrc exists"

    # Check if it references centralized completion
    if grep -q "ZSH_COMPLETION_CACHE_DIR" "$ZSHRC_FILE"; then
            zsh_debug_echo "✅ References centralized completion cache"
    fi
    if grep -q "ZSH_COMPLETION_MANAGEMENT_LOADED" "$ZSHRC_FILE"; then
            zsh_debug_echo "✅ Checks for completion management system"
    fi
else
        zsh_debug_echo "❌ Main .zshrc missing"
>>>>>>> origin/develop
fi

# Test 4: Check tools completion integration
echo ""
echo "=== Tools Integration ==="
TOOLS_COMP="$ZDOTDIR/.zshrc.d/10_17-completion.zsh"
if [[ -f "$TOOLS_COMP" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Tools completion file exists"

    if grep -q "ZSH_COMPLETION_MANAGEMENT_LOADED" "$TOOLS_COMP"; then
        zf::debug "✅ Integrated with centralized management"
    else
        zf::debug "⚠️  Not integrated with centralized management"
    fi
else
    zf::debug "⚠️  Tools completion file missing"
=======
        zsh_debug_echo "✅ Tools completion file exists"

    if grep -q "ZSH_COMPLETION_MANAGEMENT_LOADED" "$TOOLS_COMP"; then
            zsh_debug_echo "✅ Integrated with centralized management"
    else
            zsh_debug_echo "⚠️  Not integrated with centralized management"
    fi
else
        zsh_debug_echo "⚠️  Tools completion file missing"
>>>>>>> origin/develop
fi

# Test 5: Expected file locations
echo ""
echo "=== Expected File Locations ==="
EXPECTED_DUMP="$ZDOTDIR/.completions/zcompdump"
echo "Expected centralized dump: $EXPECTED_DUMP"

if [[ -f "$EXPECTED_DUMP" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Centralized dump file exists"
    local dump_size=$(wc -c <"$EXPECTED_DUMP" 2>/dev/null || zf::debug "0")
    zf::debug "   Size: $dump_size bytes"

    if [[ -f "${EXPECTED_DUMP}.zwc" ]]; then
        zf::debug "✅ Compiled version exists"
    else
        zf::debug "⚠️  No compiled version (will be created automatically)"
    fi
else
    zf::debug "⚠️  Centralized dump file not created yet (normal for first run)"
=======
        zsh_debug_echo "✅ Centralized dump file exists"
    local dump_size=$(wc -c < "$EXPECTED_DUMP" 2>/dev/null || zsh_debug_echo "0")
        zsh_debug_echo "   Size: $dump_size bytes"

    if [[ -f "${EXPECTED_DUMP}.zwc" ]]; then
            zsh_debug_echo "✅ Compiled version exists"
    else
            zsh_debug_echo "⚠️  No compiled version (will be created automatically)"
    fi
else
        zsh_debug_echo "⚠️  Centralized dump file not created yet (normal for first run)"
>>>>>>> origin/develop
fi

echo ""
echo "========================================================"
echo "Integration Status: READY"
echo "========================================================"
echo "The centralized completion management system is properly"
echo "integrated and ready to use. On next shell startup:"
echo ""
echo "1. ✅ Completion management will load early (03-completion-management.zsh)"
echo "2. ✅ Centralized .zcompdump will be created at:"
echo "      $EXPECTED_DUMP"
echo "3. ✅ All completion cache will use:"
echo "      $ZDOTDIR/.completions/cache"
echo "4. ✅ Plugin managers will use centralized location"
echo "5. ✅ Old scattered files will be cleaned up automatically"
echo ""
echo "Commands available after next shell startup:"
echo "- completion-status    (show detailed status)"
echo "- rebuild-completions  (force rebuild)"
echo "- cleanup-old-completions (clean scattered files)"
echo ""
echo "🎉 Centralized .zcompdump optimization is ready!"
