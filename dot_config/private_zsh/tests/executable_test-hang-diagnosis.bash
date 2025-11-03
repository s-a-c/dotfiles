#!/usr/bin/env bash
set -euo pipefail

echo "=== HANG DIAGNOSIS TEST ==="
echo "Testing ZSH startup to identify hanging point..."
echo ""

# Test 1: Basic shell startup with timeout and progress tracking
echo "🧪 Test 1: Shell startup with progress tracking"
timeout 15s bash -c '
    export ZDOTDIR="'$PWD'"
    export ZSH_DEBUG=1
    export DEBUG_ZSH_REDESIGN=1
    
    echo "Starting ZSH with debug enabled..."
    zsh -i -c "
        echo \"=== ZSH STARTUP PROGRESS ==="
        echo \"Interactive shell started successfully\"
        echo \"ZLE_VERSION: \${ZLE_VERSION:-not_set}\"
        echo \"STARSHIP_SHELL: \${STARSHIP_SHELL:-not_set}\"
        echo \"Current time: \$(date)\"
        echo \"Shell PID: \$\$\"
        echo \"SUCCESS: Shell startup completed\"
        exit
    " 2>&1 | while IFS= read -r line; do
        echo "[$(date +%T)] $line"
    done
' 2>&1 || echo "❌ Shell startup timed out or failed"

echo ""

# Test 2: Test without starship initialization
echo "🧪 Test 2: Shell startup without Starship"
timeout 10s bash -c '
    export ZDOTDIR="'$PWD'"
    export STARSHIP_DISABLE=1
    export ZSH_DISABLE_STARSHIP=1
    
    echo "Starting ZSH without Starship..."
    zsh -i -c "
        echo \"SUCCESS: Shell startup without Starship completed\"
        exit
    "
' 2>&1 || echo "❌ Shell startup without Starship timed out"

echo ""

# Test 3: Test with minimal modules (disable most features)
echo "🧪 Test 3: Minimal shell startup"
timeout 10s bash -c '
    export ZDOTDIR="'$PWD'"
    export ZSH_DISABLE_SPLASH=1
    export ZSH_MINIMAL=1
    export STARSHIP_DISABLE=1
    export ZSH_DISABLE_STARSHIP=1
    export ZSH_ENABLE_ABBR=0
    export ZSH_ENABLE_NVM_PLUGINS=0
    
    echo "Starting ZSH with minimal configuration..."
    zsh -i -c "
        echo \"SUCCESS: Minimal shell startup completed\"
        exit
    "
' 2>&1 || echo "❌ Minimal shell startup timed out"

echo ""

# Test 4: Check for background processes
echo "🧪 Test 4: Background process check"
timeout 5s bash -c '
    export ZDOTDIR="'$PWD'"
    
    echo "Checking for background processes during startup..."
    zsh -c "
        echo \"Background jobs at startup: \$(jobs | wc -l)\"
        ps aux | grep -E \"(zsh|starship)\" | grep -v grep || echo \"No zsh/starship processes\"
        exit
    "
' 2>&1 || echo "Background process check timed out"

echo ""

# Test 5: Check for infinite loops in modules
echo "🧪 Test 5: Module-by-module loading test"
echo "Testing individual pre-plugin modules..."

for module in .zshrc.pre-plugins.d/*.zsh; do
    if [[ -f "$module" ]]; then
        module_name=$(basename "$module")
        echo -n "Testing $module_name... "
        
        timeout 3s bash -c '
            export ZDOTDIR="'$PWD'"
            echo "Loading single module: '$module'"
            zsh -c "
                source \"'$module'\" 2>/dev/null
                echo \"Module loaded successfully\"
                exit
            "
        ' >/dev/null 2>&1 && echo "✅ OK" || echo "❌ FAILED/TIMEOUT"
    fi
done

echo ""
echo "=== HANG DIAGNOSIS COMPLETE ==="
echo ""
echo "Interpretation:"
echo "- If Test 1 times out: General startup hang"
echo "- If Test 2 succeeds but Test 1 fails: Starship-related hang"
echo "- If Test 3 succeeds: Feature-specific hang" 
echo "- If Module tests fail: Specific module causing hang"
echo ""
echo "Next steps based on results above:"
echo "1. If Starship-related: Check Starship initialization"
echo "2. If feature-specific: Disable problematic features"
echo "3. If module-specific: Fix or disable problematic module"