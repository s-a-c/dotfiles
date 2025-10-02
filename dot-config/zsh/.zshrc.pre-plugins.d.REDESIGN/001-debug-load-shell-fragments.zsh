#!/usr/bin/env zsh
# Debug hook for load-shell-fragments function
# This will override the vendored function to add ZLE debugging

# Only enable debugging when requested
[[ "${DEBUG_LOAD_FRAGMENTS:-0}" == "1" ]] || return 0

echo "[DEBUG] Installing load-shell-fragments debug hook..."

# Test ZLE status
_debug_test_zle() {
    local context="$1"
    local test_func="_zle_debug_test_$$"
    
    # Create test function
    eval "${test_func}() { echo 'test'; }"
    
    # Try to register as ZLE widget
    if zle -N "$test_func" 2>/dev/null; then
        zle -D "$test_func" 2>/dev/null || true
        unfunction "$test_func" 2>/dev/null || true
        echo "    ✅ ZLE: OK ($context)"
        return 0
    else
        unfunction "$test_func" 2>/dev/null || true
        echo "    ❌ ZLE: BROKEN ($context)"
        return 1
    fi
}

# Override the load-shell-fragments function
load-shell-fragments() {
    local fragment_dir="$1"
    
    echo ""
    echo "📂 [DEBUG] Loading fragments from: $fragment_dir"
    
    # Test ZLE before loading
    _debug_test_zle "before $fragment_dir"
    
    # Check if directory exists
    if [[ ! -d "$fragment_dir" ]]; then
        echo "    ⚠️  Directory not found: $fragment_dir"
        return 0
    fi
    
    # Process files in the directory
    local file
    for file in "$fragment_dir"/*.{sh,zsh}(N); do
        [[ -f "$file" ]] || continue
        
        local filename=$(basename "$file")
        echo "    📄 Loading: $filename"
        
        # Source the file
        if source "$file"; then
            echo "        ✅ Sourced successfully"
        else
            local rc=$?
            echo "        ⚠️  Source failed (exit code: $rc)"
        fi
        
        # Test ZLE after each file
        if ! _debug_test_zle "after $filename"; then
            echo ""
            echo "🚨 CULPRIT FOUND!"
            echo "================="
            echo "File: $file"
            echo "This file broke ZLE!"
            echo ""
            echo "First 10 lines of the problematic file:"
            head -10 "$file" | sed 's/^/    /'
            echo ""
            return 1
        fi
    done
    
    echo "    ✅ All files in $fragment_dir loaded successfully"
    _debug_test_zle "after all files in $fragment_dir"
}

echo "[DEBUG] load-shell-fragments debug hook installed"
echo "[DEBUG] ZLE debugging will be active for all fragment loading"
