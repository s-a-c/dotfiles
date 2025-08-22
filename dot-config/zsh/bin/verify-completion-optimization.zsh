#!/opt/homebrew/bin/zsh
# ==============================================================================
# ZSH Configuration: Completion Optimization Verification
# ==============================================================================
# Purpose: Verify that the centralized .zcompdump optimization system is
#          working correctly and measure performance improvements
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
    echo "✅ Centralized completion directory exists: $ZDOTDIR/.completions"
else
    echo "❌ Centralized completion directory missing: $ZDOTDIR/.completions"
    echo "Creating directory..."
    mkdir -p "$ZDOTDIR/.completions" 2>/dev/null
    if [[ -d "$ZDOTDIR/.completions" ]]; then
        echo "✅ Created centralized completion directory"
    else
        echo "❌ Failed to create centralized completion directory"
    fi
fi

# Test 2: Check environment variables
echo ""
echo "=== Test 2: Environment Variables ==="
echo "Expected centralized location: $EXPECTED_COMPDUMP"

# Test if we can source the completion management system
if [[ -f "$ZDOTDIR/.zshrc.d/00-core/03-completion-management.zsh" ]]; then
    echo "✅ Completion management system file exists"
    
    # Try to extract key variables from the file
    local comp_dir=$(grep "ZSH_COMPLETION_DIR=" "$ZDOTDIR/.zshrc.d/00-core/03-completion-management.zsh" | head -1 | cut -d'"' -f2)
    local comp_file=$(grep "ZSH_COMPDUMP_FILE=" "$ZDOTDIR/.zshrc.d/00-core/03-completion-management.zsh" | head -1 | cut -d'"' -f2)
    
    if [[ -n "$comp_dir" ]]; then
        echo "✅ Completion directory configured: $comp_dir"
    fi
    if [[ -n "$comp_file" ]]; then
        echo "✅ Completion dump file configured: $comp_file"
    fi
else
    echo "❌ Completion management system file not found"
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
        echo "⚠️  Found old files matching: $pattern"
        old_files_found=$((old_files_found + 1))
    fi
done

if [[ $old_files_found -eq 0 ]]; then
    echo "✅ No old .zcompdump files found in common locations"
else
    echo "⚠️  Found $old_files_found old .zcompdump file patterns"
    echo "💡 These can be cleaned up with the cleanup command"
fi

# Test 4: Check current ZSH session completion setup
echo ""
echo "=== Test 4: Current Session Completion Setup ==="

# Check if compinit is loaded
if declare -f compinit >/dev/null 2>&1; then
    echo "✅ compinit function is available"
else
    echo "⚠️  compinit function not loaded"
fi

# Check completion cache settings
local cache_path=$(zstyle -L ':completion:*' cache-path 2>/dev/null | cut -d"'" -f4)
if [[ -n "$cache_path" ]]; then
    echo "✅ Completion cache configured: $cache_path"
    if [[ -d "$cache_path" ]]; then
        local cache_files=$(find "$cache_path" -type f 2>/dev/null | wc -l)
        echo "   Cache directory exists with $cache_files files"
    else
        echo "   ⚠️  Cache directory doesn't exist yet"
    fi
else
    echo "⚠️  No completion cache path configured"
fi

# Test 5: Performance estimation
echo ""
echo "=== Test 5: Performance Estimation ==="

# Check if centralized file exists and get its size/age
if [[ -f "$EXPECTED_COMPDUMP" ]]; then
    local file_size=$(wc -c < "$EXPECTED_COMPDUMP" 2>/dev/null || echo "unknown")
    local file_age=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$EXPECTED_COMPDUMP" 2>/dev/null || echo "unknown")
    echo "✅ Centralized .zcompdump exists:"
    echo "   File: $EXPECTED_COMPDUMP"
    echo "   Size: $file_size bytes"
    echo "   Modified: $file_age"
    
    # Check if compiled version exists
    if [[ -f "${EXPECTED_COMPDUMP}.zwc" ]]; then
        echo "✅ Compiled version exists (faster loading)"
    else
        echo "⚠️  No compiled version (can be created for faster loading)"
    fi
else
    echo "⚠️  Centralized .zcompdump not found"
    echo "   This will be created on next shell startup"
fi

# Test 6: Integration verification
echo ""
echo "=== Test 6: Integration Verification ==="

# Check if the completion management system would be loaded
local core_files=(
    "$ZDOTDIR/.zshrc.d/00-core/01-source-execute-detection.zsh"
    "$ZDOTDIR/.zshrc.d/00-core/03-completion-management.zsh"
)

local integration_ok=true
for file in "${core_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ Core file exists: $(basename "$file")"
    else
        echo "❌ Core file missing: $(basename "$file")"
        integration_ok=false
    fi
done

if $integration_ok; then
    echo "✅ Integration files are in place"
else
    echo "❌ Integration has missing components"
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
    echo "🎉 Completion optimization system is properly configured!"
    echo "✅ All components are in place"
    echo "✅ Ready for centralized .zcompdump management"
elif [[ $issues -le 2 ]]; then
    echo "⚠️  Completion optimization system is mostly configured ($issues minor issues)"
    echo "💡 System will work but may need minor adjustments"
else
    echo "❌ Completion optimization system needs attention ($issues issues found)"
    echo "🔧 Manual configuration may be required"
fi

echo ""
echo "Next Steps:"
echo "1. Start a new ZSH session to activate centralized completion management"
echo "2. Run 'completion-status' to see detailed status"
echo "3. Run 'cleanup-old-completions' to remove scattered files"
echo "4. Monitor startup time improvements"

exit $issues
