<<<<<<< HEAD
#!/usr/bin/env zsh
=======
#!/opt/homebrew/bin/zsh
>>>>>>> origin/develop
# ==============================================================================
# ZSH Configuration: Completion Optimization Verification
# ==============================================================================
# Purpose: Verify that the centralized .zcompdump optimization system is
#          working correctly and measure performance 030-improvements
# ==============================================================================

echo "========================================================"
echo "ZSH Completion Optimization Verification"
echo "========================================================"
echo "Timestamp: $(date)"
echo ""

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
EXPECTED_COMPDUMP="$ZDOTDIR/.completions/zcompdump"

# Test 1: Check if centralized completion directory exists
echo "=== Test 1: Centralized Completion Directory ==="
if [[ -d "$ZDOTDIR/.completions" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Centralized completion directory exists: $ZDOTDIR/.completions"
else
    zf::debug "❌ Centralized completion directory missing: $ZDOTDIR/.completions"
    zf::debug "Creating directory..."
    mkdir -p "$ZDOTDIR/.completions" 2>/dev/null
    if [[ -d "$ZDOTDIR/.completions" ]]; then
        zf::debug "✅ Created centralized completion directory"
    else
        zf::debug "❌ Failed to create centralized completion directory"
=======
        zsh_debug_echo "✅ Centralized completion directory exists: $ZDOTDIR/.completions"
else
        zsh_debug_echo "❌ Centralized completion directory missing: $ZDOTDIR/.completions"
        zsh_debug_echo "Creating directory..."
    mkdir -p "$ZDOTDIR/.completions" 2>/dev/null
    if [[ -d "$ZDOTDIR/.completions" ]]; then
            zsh_debug_echo "✅ Created centralized completion directory"
    else
            zsh_debug_echo "❌ Failed to create centralized completion directory"
>>>>>>> origin/develop
    fi
fi

# Test 2: Check environment variables
echo ""
echo "=== Test 2: Environment Variables ==="
echo "Expected centralized location: $EXPECTED_COMPDUMP"

# Test if we can source the completion management system
if [[ -f "$ZDOTDIR/.zshrc.d/00_03-completion-management.zsh" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Completion management system file exists"
=======
        zsh_debug_echo "✅ Completion management system file exists"
>>>>>>> origin/develop

    # Try to extract key variables from the file
    local comp_dir=$(grep "ZSH_COMPLETION_DIR=" "$ZDOTDIR/.zshrc.d/00_03-completion-management.zsh" | head -1 | cut -d'"' -f2)
    local comp_file=$(grep "ZSH_COMPDUMP_FILE=" "$ZDOTDIR/.zshrc.d/00_03-completion-management.zsh" | head -1 | cut -d'"' -f2)

    if [[ -n "$comp_dir" ]]; then
<<<<<<< HEAD
        zf::debug "✅ Completion directory configured: $comp_dir"
    fi
    if [[ -n "$comp_file" ]]; then
        zf::debug "✅ Completion dump file configured: $comp_file"
    fi
else
    zf::debug "❌ Completion management system file not found"
=======
            zsh_debug_echo "✅ Completion directory configured: $comp_dir"
    fi
    if [[ -n "$comp_file" ]]; then
            zsh_debug_echo "✅ Completion dump file configured: $comp_file"
    fi
else
        zsh_debug_echo "❌ Completion management system file not found"
>>>>>>> origin/develop
fi

# Test 3: Check for old scattered .zcompdump files
echo ""
echo "=== Test 3: Old .zcompdump Files Check ==="
echo "Checking common locations for old .zcompdump files..."

local old_files_found=0
local check_locations=(
    "$HOME/.zcompdump"
    "$HOME/.zcompdump-*"
    "$ZDOTDIR/.zcompdump"
    "$ZDOTDIR/.zcompdump-*"
)

for pattern in "${check_locations[@]}"; do
    if ls $pattern 2>/dev/null | head -3; then
<<<<<<< HEAD
        zf::debug "⚠️  Found old files matching: $pattern"
=======
            zsh_debug_echo "⚠️  Found old files matching: $pattern"
>>>>>>> origin/develop
        old_files_found=$((old_files_found + 1))
    fi
done

if [[ $old_files_found -eq 0 ]]; then
<<<<<<< HEAD
    zf::debug "✅ No old .zcompdump files found in common locations"
else
    zf::debug "⚠️  Found $old_files_found old .zcompdump file patterns"
    zf::debug "💡 These can be cleaned up with the cleanup command"
=======
        zsh_debug_echo "✅ No old .zcompdump files found in common locations"
else
        zsh_debug_echo "⚠️  Found $old_files_found old .zcompdump file patterns"
        zsh_debug_echo "💡 These can be cleaned up with the cleanup command"
>>>>>>> origin/develop
fi

# Test 4: Check current ZSH session completion setup
echo ""
echo "=== Test 4: Current Session Completion Setup ==="

# Check if compinit is loaded
if declare -f compinit >/dev/null 2>&1; then
<<<<<<< HEAD
    zf::debug "✅ compinit function is available"
else
    zf::debug "⚠️  compinit function not loaded"
=======
        zsh_debug_echo "✅ compinit function is available"
else
        zsh_debug_echo "⚠️  compinit function not loaded"
>>>>>>> origin/develop
fi

# Check completion cache settings
local cache_path=$(zstyle -L ':completion:*' cache-path 2>/dev/null | cut -d"'" -f4)
if [[ -n "$cache_path" ]]; then
<<<<<<< HEAD
    zf::debug "✅ Completion cache configured: $cache_path"
    if [[ -d "$cache_path" ]]; then
        local cache_files=$(find "$cache_path" -type f 2>/dev/null | wc -l)
        zf::debug "   Cache directory exists with $cache_files files"
    else
        zf::debug "   ⚠️  Cache directory doesn't exist yet"
    fi
else
    zf::debug "⚠️  No completion cache path configured"
=======
        zsh_debug_echo "✅ Completion cache configured: $cache_path"
    if [[ -d "$cache_path" ]]; then
        local cache_files=$(find "$cache_path" -type f 2>/dev/null | wc -l)
            zsh_debug_echo "   Cache directory exists with $cache_files files"
    else
            zsh_debug_echo "   ⚠️  Cache directory doesn't exist yet"
    fi
else
        zsh_debug_echo "⚠️  No completion cache path configured"
>>>>>>> origin/develop
fi

# Test 5: Performance estimation
echo ""
echo "=== Test 5: Performance Estimation ==="

# Check if centralized file exists and get its size/age
if [[ -f "$EXPECTED_COMPDUMP" ]]; then
<<<<<<< HEAD
    local file_size=$(wc -c <"$EXPECTED_COMPDUMP" 2>/dev/null || zf::debug "unknown")
    local file_age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$EXPECTED_COMPDUMP" 2>/dev/null || zf::debug "unknown")
    zf::debug "✅ Centralized .zcompdump exists:"
    zf::debug "   File: $EXPECTED_COMPDUMP"
    zf::debug "   Size: $file_size bytes"
    zf::debug "   Modified: $file_age"

    # Check if compiled version exists
    if [[ -f "${EXPECTED_COMPDUMP}.zwc" ]]; then
        zf::debug "✅ Compiled version exists (faster loading)"
    else
        zf::debug "⚠️  No compiled version (can be created for faster loading)"
    fi
else
    zf::debug "⚠️  Centralized .zcompdump not found"
    zf::debug "   This will be created on next shell startup"
=======
    local file_size=$(wc -c < "$EXPECTED_COMPDUMP" 2>/dev/null || zsh_debug_echo "unknown")
    local file_age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$EXPECTED_COMPDUMP" 2>/dev/null || zsh_debug_echo "unknown")
        zsh_debug_echo "✅ Centralized .zcompdump exists:"
        zsh_debug_echo "   File: $EXPECTED_COMPDUMP"
        zsh_debug_echo "   Size: $file_size bytes"
        zsh_debug_echo "   Modified: $file_age"

    # Check if compiled version exists
    if [[ -f "${EXPECTED_COMPDUMP}.zwc" ]]; then
            zsh_debug_echo "✅ Compiled version exists (faster loading)"
    else
            zsh_debug_echo "⚠️  No compiled version (can be created for faster loading)"
    fi
else
        zsh_debug_echo "⚠️  Centralized .zcompdump not found"
        zsh_debug_echo "   This will be created on next shell startup"
>>>>>>> origin/develop
fi

# Test 6: Integration verification
echo ""
echo "=== Test 6: Integration Verification ==="

# Check if the completion management system would be loaded
local core_files=(
    "$ZDOTDIR/.zshrc.d/00_01-source-execute-detection.zsh"
    "$ZDOTDIR/.zshrc.d/00_03-completion-management.zsh"
)

local integration_ok=true
for file in "${core_files[@]}"; do
    if [[ -f "$file" ]]; then
<<<<<<< HEAD
        zf::debug "✅ Core file exists: $(basename "$file")"
    else
        zf::debug "❌ Core file missing: $(basename "$file")"
=======
            zsh_debug_echo "✅ Core file exists: $(basename "$file")"
    else
            zsh_debug_echo "❌ Core file missing: $(basename "$file")"
>>>>>>> origin/develop
        integration_ok=false
    fi
done

if $integration_ok; then
<<<<<<< HEAD
    zf::debug "✅ Integration files are in place"
else
    zf::debug "❌ Integration has missing components"
=======
        zsh_debug_echo "✅ Integration files are in place"
else
        zsh_debug_echo "❌ Integration has missing components"
>>>>>>> origin/develop
fi

# Summary
echo ""
echo "========================================================"
echo "Verification Summary"
echo "========================================================"

local issues=0
if [[ ! -d "$ZDOTDIR/.completions" ]]; then issues=$((issues + 1)); fi
if [[ $old_files_found -gt 0 ]]; then issues=$((issues + 1)); fi
if [[ ! -f "$EXPECTED_COMPDUMP" ]]; then issues=$((issues + 1)); fi
if ! $integration_ok; then issues=$((issues + 1)); fi

if [[ $issues -eq 0 ]]; then
<<<<<<< HEAD
    zf::debug "🎉 Completion optimization system is properly configured!"
    zf::debug "✅ All components are in place"
    zf::debug "✅ Ready for centralized .zcompdump management"
elif [[ $issues -le 2 ]]; then
    zf::debug "⚠️  Completion optimization system is mostly configured ($issues minor issues)"
    zf::debug "💡 System will work but may need minor adjustments"
else
    zf::debug "❌ Completion optimization system needs attention ($issues issues found)"
    zf::debug "🔧 Manual configuration may be required"
=======
        zsh_debug_echo "🎉 Completion optimization system is properly configured!"
        zsh_debug_echo "✅ All components are in place"
        zsh_debug_echo "✅ Ready for centralized .zcompdump management"
elif [[ $issues -le 2 ]]; then
        zsh_debug_echo "⚠️  Completion optimization system is mostly configured ($issues minor issues)"
        zsh_debug_echo "💡 System will work but may need minor adjustments"
else
        zsh_debug_echo "❌ Completion optimization system needs attention ($issues issues found)"
        zsh_debug_echo "🔧 Manual configuration may be required"
>>>>>>> origin/develop
fi

echo ""
echo "Next Steps:"
echo "1. Start a new ZSH session to activate centralized completion management"
echo "2. Run 'completion-status' to see detailed status"
echo "3. Run 'cleanup-old-completions' to remove scattered files"
echo "4. Monitor startup time improvements"

exit $issues
