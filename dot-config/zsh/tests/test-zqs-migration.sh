#!/usr/bin/env bash
# test-zqs-migration.sh - Test harness for ZQS migration extension files

set -euo pipefail

echo "=== ZQS Migration Extension Files Test ==="
echo "Testing extension files before switching to symlinked ZQS .zshrc..."
echo ""

# Test 1: Pre-plugin extensions
echo "Test 1: Pre-plugin extensions"
test_pre_plugin_extensions() {
    echo "Testing pre-plugin extension files..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -c '
        # Simulate pre-plugin loading
        if [[ -d "$ZDOTDIR/.zshrc.pre-plugins.d" ]]; then
            for file in "$ZDOTDIR/.zshrc.pre-plugins.d"/*.zsh; do
                if [[ -r "$file" ]]; then
                    echo "Loading: $(basename $file)"
                    source "$file"
                fi
            done
        fi
        echo "PRE_PLUGIN_EXTENSIONS_LOADED"
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "PRE_PLUGIN_EXTENSIONS_LOADED"; then
        echo "✅ Pre-plugin extensions loaded successfully"
        echo "   Files loaded:"
        echo "$test_output" | grep "Loading:" | sed 's/^/     /'
        return 0
    else
        echo "❌ Pre-plugin extensions failed to load"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 2: Post-plugin extensions  
echo ""
echo "Test 2: Post-plugin extensions"
test_post_plugin_extensions() {
    echo "Testing post-plugin extension files..."
    
    local test_output
    test_output=$(ZDOTDIR="$PWD" timeout 10s zsh -c '
        # Simulate post-plugin loading
        if [[ -d "$ZDOTDIR/.zshrc.d" ]]; then
            for file in "$ZDOTDIR/.zshrc.d"/*.zsh; do
                if [[ -r "$file" ]]; then
                    echo "Loading: $(basename $file)"
                    source "$file"
                fi
            done
        fi
        echo "POST_PLUGIN_EXTENSIONS_LOADED"
        
        # Test emergency fix variables
        echo "ZSH_AUTOSUGGEST_DISABLE: $ZSH_AUTOSUGGEST_DISABLE"
        echo "GITSTATUS_DISABLE: $GITSTATUS_DISABLE"
        
        # Test function existence
        if declare -f _zsh_autosuggest_bind_widget >/dev/null; then
            echo "✅ Emergency no-op functions exist"
        fi
        
        exit
    ' 2>&1)
    
    if echo "$test_output" | grep -q "POST_PLUGIN_EXTENSIONS_LOADED"; then
        echo "✅ Post-plugin extensions loaded successfully"
        echo "   Emergency fix active:"
        echo "$test_output" | grep -E "(ZSH_AUTOSUGGEST_DISABLE|GITSTATUS_DISABLE|Emergency no-op)" | sed 's/^/     /'
        return 0
    else
        echo "❌ Post-plugin extensions failed to load"
        echo "Output: $test_output"
        return 1
    fi
}

# Test 3: ZQS .zshrc compatibility check
echo ""
echo "Test 3: ZQS .zshrc compatibility"
test_zqs_compatibility() {
    echo "Testing ZQS .zshrc accessibility..."
    
    if [[ -f "zsh-quickstart-kit/zsh/.zshrc" ]]; then
        echo "✅ ZQS .zshrc found at: zsh-quickstart-kit/zsh/.zshrc"
        
        # Check if it's readable
        if [[ -r "zsh-quickstart-kit/zsh/.zshrc" ]]; then
            echo "✅ ZQS .zshrc is readable"
            local line_count=$(wc -l < "zsh-quickstart-kit/zsh/.zshrc")
            echo "   Lines: $line_count"
            return 0
        else
            echo "❌ ZQS .zshrc exists but is not readable"
            return 1
        fi
    else
        echo "❌ ZQS .zshrc not found"
        echo "   Expected at: zsh-quickstart-kit/zsh/.zshrc"
        return 1
    fi
}

# Test 4: Extension file permissions and syntax
echo ""
echo "Test 4: Extension file validation"
test_extension_files() {
    echo "Validating extension files..."
    
    local failed=0
    
    for ext_dir in ".zshrc.pre-plugins.d" ".zshrc.d"; do
        if [[ -d "$ext_dir" ]]; then
            echo "Checking $ext_dir/:"
            for file in "$ext_dir"/*.zsh; do
                if [[ -f "$file" ]]; then
                    echo -n "  $(basename $file): "
                    
                    # Check permissions
                    if [[ ! -r "$file" ]]; then
                        echo "❌ not readable"
                        failed=1
                        continue
                    fi
                    
                    # Check syntax
                    if zsh -n "$file" 2>/dev/null; then
                        echo "✅ syntax valid"
                    else
                        echo "❌ syntax error"
                        failed=1
                    fi
                fi
            done
        else
            echo "⚠️  Directory $ext_dir not found"
        fi
    done
    
    return $failed
}

# Test 5: Current configuration backup
echo ""  
echo "Test 5: Configuration backup"
test_backup_status() {
    echo "Checking configuration backup..."
    
    if [[ -f ".zshrc.CUSTOM.backup" ]]; then
        echo "✅ Current .zshrc backed up as .zshrc.CUSTOM.backup"
        local backup_size=$(wc -l < ".zshrc.CUSTOM.backup")
        echo "   Backup size: $backup_size lines"
        return 0
    else
        echo "❌ No backup found - this is required before migration"
        echo "   Run: cp .zshrc .zshrc.CUSTOM.backup"
        return 1
    fi
}

# Run all tests
echo "Running test suite..."
echo "===================================="

failed_tests=0

test_backup_status || ((failed_tests++))
echo ""
test_extension_files || ((failed_tests++)) 
echo ""
test_pre_plugin_extensions || ((failed_tests++))
echo ""
test_post_plugin_extensions || ((failed_tests++))
echo ""
test_zqs_compatibility || ((failed_tests++))

echo ""
echo "=== Test Summary ==="
if [[ $failed_tests -eq 0 ]]; then
    echo "✅ All tests passed! Ready for Phase 2 (symlink switch)"
    echo ""
    echo "Next steps:"
    echo "1. Switch to ZQS symlink: mv .zshrc .zshrc.current && ln -sf zsh-quickstart-kit/zsh/.zshrc .zshrc"
    echo "2. Test the new configuration: ZDOTDIR=$PWD zsh -i"
    echo "3. Verify ZQS auto-update works"
else
    echo "❌ $failed_tests test(s) failed"
    echo "   Fix issues before proceeding to Phase 2"
fi