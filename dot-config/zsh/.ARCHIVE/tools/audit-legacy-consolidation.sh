#!/usr/bin/env bash
set -euo pipefail

echo "🔍 COMPREHENSIVE LEGACY CONSOLIDATION AUDIT"
echo "============================================="
echo ""

cd /Users/s-a-c/dotfiles/dot-config/zsh

echo "=== 1. Current State Analysis ==="
echo ""

echo "📁 Active legacy modules (.zshrc.d/):"
ls -1 .zshrc.d/ | sed 's/^/  /'
echo "  Total: $(ls -1 .zshrc.d/ | wc -l | tr -d ' ') modules"
echo ""

echo "📁 Disabled legacy modules (.zshrc.d.disabled/):"
ls -1 .zshrc.d.disabled/ | sed 's/^/  /'
echo "  Total: $(ls -1 .zshrc.d.disabled/ | wc -l | tr -d ' ') modules"
echo ""

echo "📁 Current consolidated modules (.zshrc.d.legacy/consolidated-modules/):"
ls -1 .zshrc.d.legacy/consolidated-modules/ | sed 's/^/  /'
echo "  Total: $(ls -1 .zshrc.d.legacy/consolidated-modules/ | wc -l | tr -d ' ') modules"
echo ""

echo "=== 2. Functionality Mapping Analysis ==="
echo ""

# Create a comprehensive mapping
echo "🔍 Analyzing functionality coverage..."
echo ""

# Function to check if functionality is mentioned in consolidated modules
check_functionality() {
    local search_term="$1"
    local description="$2"
    local found=0
    
    echo -n "  $description: "
    
    if grep -r -i "$search_term" .zshrc.d.legacy/consolidated-modules/ >/dev/null 2>&1; then
        echo "✅ FOUND"
        found=1
    else
        echo "❌ MISSING"
    fi
    
    return $((1-found))
}

echo "📊 Core Functionality Coverage:"
missing_functionality=()

# Core infrastructure checks
check_functionality "debug_log\|error_log\|warn_log" "Logging functions" || missing_functionality+=("logging")
check_functionality "path.*add\|path.*prepend" "Path management" || missing_functionality+=("path-management")
check_functionality "source.*execute.*detection" "Source/execute detection" || missing_functionality+=("source-detection")
check_functionality "unified.*logging" "Unified logging" || missing_functionality+=("unified-logging")
check_functionality "standard.*helpers" "Standard helpers" || missing_functionality+=("standard-helpers")

# Security and integrity checks  
check_functionality "plugin.*integrity" "Plugin integrity" || missing_functionality+=("plugin-integrity")
check_functionality "async.*cache" "Async cache" || missing_functionality+=("async-cache")
check_functionality "security.*validation" "Security validation" || missing_functionality+=("security-validation")

# Environment and options
check_functionality "timeout.*protection" "Timeout protection" || missing_functionality+=("timeout-protection")
check_functionality "options" "ZSH options" || missing_functionality+=("options")

# Completion system
check_functionality "completion.*management" "Completion management" || missing_functionality+=("completion-management")
check_functionality "compinit" "Compinit handling" || missing_functionality+=("compinit")

# Development tools
check_functionality "essential" "Essential tools" || missing_functionality+=("essential-tools")
check_functionality "external.*tools" "External tools" || missing_functionality+=("external-tools")
check_functionality "git.*homebrew" "Git/Homebrew priority" || missing_functionality+=("git-homebrew")

# UI and prompt
check_functionality "prompt" "Prompt configuration" || missing_functionality+=("prompt")

# Legacy compatibility
check_functionality "legacy.*compatibility" "Legacy compatibility" || missing_functionality+=("legacy-compatibility")
check_functionality "shims" "Compatibility shims" || missing_functionality+=("shims")

echo ""
echo "=== 3. Missing Functionality Analysis ==="
echo ""

if [[ ${#missing_functionality[@]} -gt 0 ]]; then
    echo "⚠️  Missing functionality detected:"
    for func in "${missing_functionality[@]}"; do
        echo "  ❌ $func"
    done
    echo ""
    echo "🔍 Detailed analysis of missing components:"
    echo ""
    
    # Analyze each missing component
    for func in "${missing_functionality[@]}"; do
        case "$func" in
            "logging"|"unified-logging"|"standard-helpers")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d.disabled/ | grep -i "log\|helper" | sed 's/^/    /'
                ;;
            "source-detection")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d.disabled/ | grep -i "source\|execute\|detection" | sed 's/^/    /'
                ;;
            "plugin-integrity")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d/ | grep -i "plugin\|integrity" | sed 's/^/    /'
                ;;
            "timeout-protection")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d/ | grep -i "timeout\|protection" | sed 's/^/    /'
                ;;
            "async-cache")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d.disabled/ | grep -i "async\|cache" | sed 's/^/    /'
                ;;
            "completion-management")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d.disabled/ | grep -i "completion" | sed 's/^/    /'
                ;;
            "git-homebrew")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d.disabled/ | grep -i "git\|homebrew" | sed 's/^/    /'
                ;;
            "external-tools"|"essential-tools")
                echo "📋 $func:"
                echo "  Source modules:"
                ls -1 .zshrc.d/ | grep -i "essential\|external\|tools" | sed 's/^/    /'
                ;;
        esac
        echo ""
    done
else
    echo "✅ All major functionality appears to be consolidated!"
fi

echo "=== 4. Recommended Consolidation Structure ==="
echo ""
echo "Based on analysis, here's the recommended 9-module structure:"
echo ""
echo "01-core-infrastructure.zsh     - ✅ EXISTS"
echo "02-performance-monitoring.zsh  - ✅ EXISTS"  
echo "03-security-integrity.zsh      - ✅ EXISTS (currently 02-security-integrity.zsh)"
echo "04-environment-options.zsh     - ✅ EXISTS (currently 05-environment-options.zsh)"
echo "05-completion-system.zsh       - ✅ EXISTS (currently 06-completion-system.zsh)"
echo "06-user-interface.zsh          - ✅ EXISTS (currently 07-user-interface.zsh)"
echo "07-development-tools.zsh       - ✅ EXISTS (currently 08-development-tools.zsh)"
echo "08-legacy-compatibility.zsh    - ✅ EXISTS (currently 09-legacy-compatibility.zsh)"
echo "09-external-integrations.zsh   - ❓ NEEDS CREATION/VERIFICATION"
echo ""

echo "=== 5. Action Items ==="
echo ""

if [[ ${#missing_functionality[@]} -gt 0 ]]; then
    echo "🚨 CRITICAL: Missing functionality must be consolidated"
    echo ""
    echo "Required actions:"
    echo "1. Review each missing component listed above"
    echo "2. Consolidate missing functionality into appropriate modules"
    echo "3. Consider creating 09-external-integrations.zsh for external tools"
    echo "4. Renumber modules to follow 01-09 sequence"
    echo "5. Re-test all consolidated modules"
else
    echo "✅ Consolidation appears complete!"
    echo ""
    echo "Recommended actions:"
    echo "1. Renumber modules to follow 01-09 sequence"
    echo "2. Create comprehensive test suite"
    echo "3. Validate all functionality works as expected"
fi

echo ""
echo "=== 6. Module Content Preview ==="
echo ""

for module in .zshrc.d.legacy/consolidated-modules/*.zsh; do
    if [[ -f "$module" ]]; then
        echo "📄 $(basename "$module"):"
        echo "  Size: $(wc -l < "$module") lines"
        echo "  Functions exported: $(grep -c "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(" "$module" 2>/dev/null || echo "0")"
        echo "  Last modified: $(stat -f "%Sm" "$module" 2>/dev/null || echo "unknown")"
        echo ""
    fi
done

echo "🏁 Audit complete!"