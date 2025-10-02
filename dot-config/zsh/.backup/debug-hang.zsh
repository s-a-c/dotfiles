#!/usr/bin/env zsh
# Debug script to identify hang points in ZSH initialization
# Usage: zsh -x debug-hang.zsh

# Enable debug output
set -x

# Set debug environment
export ZSH_DEBUG_MODE=1
export ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Create debug log
DEBUG_LOG="/tmp/zsh-debug-$(date +%Y%m%d-%H%M%S).log"
exec 2>&1 | tee "$DEBUG_LOG"

echo "=== ZSH Debug Hang Detection ==="
echo "ZDOTDIR: $ZDOTDIR"
echo "Log file: $DEBUG_LOG"
echo ""

# Function to trace execution points
trace_point() {
    local point="$1"
    echo "[$(date +%H:%M:%S.%N)] TRACE: $point"
}

# Test 1: Check if .zshrc can be sourced
echo "=== Test 1: Source .zshrc with NO_ZGENOM ==="
trace_point "Starting .zshrc source with NO_ZGENOM=1"
(
    export NO_ZGENOM=1
    export SKIP_PLUGINS=1
    export PERF_CAPTURE_FAST=1
    timeout 5 zsh -c "source $ZDOTDIR/.zshrc; echo 'SUCCESS: .zshrc sourced without plugins'"
)
if [[ $? -eq 124 ]]; then
    echo "FAIL: Timeout sourcing .zshrc even with plugins disabled"
else
    echo "PASS: .zshrc sources without plugins"
fi
echo ""

# Test 2: Check pre-plugin loading
echo "=== Test 2: Test pre-plugin loading only ==="
trace_point "Testing pre-plugin fragments"
(
    export NO_ZGENOM=1
    timeout 5 zsh -c "
        source $ZDOTDIR/.zshrc 2>&1 | head -100
        echo 'Pre-plugin loading complete'
    "
)
if [[ $? -eq 124 ]]; then
    echo "FAIL: Timeout in pre-plugin loading"
else
    echo "PASS: Pre-plugin loading works"
fi
echo ""

# Test 3: Check specific sections
echo "=== Test 3: Load sections incrementally ==="
trace_point "Testing incremental loading"

# Create test script that loads sections one by one
cat > /tmp/test-incremental.zsh << 'EOF'
#!/usr/bin/env zsh
set -x
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

echo "Step 1: Loading .zshenv"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
echo "Step 1: Complete"

echo "Step 2: Setting up functions"
function can_haz() {
    builtin command -v "$1" >/dev/null 2>&1
}
function zqs-debug() {
    [[ -f "$ZDOTDIR/.zqs-debug-mode" ]] && echo "$@"
}
echo "Step 2: Complete"

echo "Step 3: Loading shell fragments function"
function load-shell-fragments() {
    if [[ -d "$1" ]]; then
        local fragments=("$1"/*(N))
        for fragment in "${fragments[@]}"; do
            [[ -r "$fragment" ]] && echo "Loading: $fragment" && source "$fragment"
        done
    fi
}
echo "Step 3: Complete"

echo "Step 4: Loading pre-plugin fragments"
if [[ -d "$ZDOTDIR/.zshrc.pre-plugins.d" ]]; then
    load-shell-fragments "$ZDOTDIR/.zshrc.pre-plugins.d"
fi
echo "Step 4: Complete"

echo "All steps completed successfully"
EOF

chmod +x /tmp/test-incremental.zsh
timeout 10 /tmp/test-incremental.zsh
if [[ $? -eq 124 ]]; then
    echo "FAIL: Timeout in incremental loading"
else
    echo "PASS: Incremental loading works"
fi
echo ""

# Test 4: Check for infinite loops in fragments
echo "=== Test 4: Check for infinite loops in fragments ==="
trace_point "Checking fragment files"

for dir in "$ZDOTDIR/.zshrc.pre-plugins.d" "$ZDOTDIR/.zshrc.d"; do
    if [[ -d "$dir" ]]; then
        echo "Checking directory: $dir"
        for file in "$dir"/*(.N); do
            if [[ -f "$file" ]]; then
                echo -n "  Testing $file ... "
                timeout 2 zsh -c "source '$file' 2>&1 | head -50" > /dev/null 2>&1
                if [[ $? -eq 124 ]]; then
                    echo "TIMEOUT - potential infinite loop!"
                else
                    echo "OK"
                fi
            fi
        done
    fi
done
echo ""

# Test 5: Check zgenom loading
echo "=== Test 5: Test zgenom initialization ==="
trace_point "Testing zgenom"
(
    timeout 10 zsh -c "
        export ZGENOM_SOURCE_FILE=\"$HOME/.zgenom/zgenom.zsh\"
        if [[ -f \"\$ZGENOM_SOURCE_FILE\" ]]; then
            source \"\$ZGENOM_SOURCE_FILE\"
            echo 'zgenom loaded successfully'
        else
            echo 'zgenom not found'
        fi
    "
)
if [[ $? -eq 124 ]]; then
    echo "FAIL: Timeout loading zgenom"
else
    echo "PASS: zgenom loads"
fi
echo ""

# Test 6: Profile with zprof
echo "=== Test 6: Profile with zprof (limited) ==="
trace_point "Running zprof analysis"
(
    timeout 5 zsh -c "
        zmodload zsh/zprof
        export NO_ZGENOM=1
        export SKIP_PLUGINS=1
        source $ZDOTDIR/.zshrc
        zprof | head -20
    "
) 2>/dev/null
echo ""

# Summary
echo "=== Debug Summary ==="
echo "Log saved to: $DEBUG_LOG"
echo ""
echo "Next steps:"
echo "1. Review the log for timeout locations"
echo "2. Check fragment files that timeout"
echo "3. Look for:"
echo "   - Infinite loops (while/for without proper exit)"
echo "   - Blocking reads (read without timeout)"
echo "   - Network operations (git fetch, curl, etc.)"
echo "   - Missing command dependencies causing hangs"
echo ""
echo "To test specific fragment:"
echo "  timeout 2 zsh -c 'source /path/to/fragment.zsh'"
