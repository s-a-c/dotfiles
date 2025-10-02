#!/opt/homebrew/bin/bash
# trace-zsh-startup.bash - Comprehensive ZSH startup tracing

set -x  # Enable bash tracing too

echo "=== COMPREHENSIVE ZSH STARTUP TRACE ==="
echo "Timestamp: $(date)"
echo "Current shell: $0"
echo "Bash PID: $$"
echo "ZDOTDIR: /Users/s-a-c/dotfiles/dot-config/zsh"
echo

# Prepare trace file
TRACE_FILE="/tmp/zsh-startup-trace-$(date +%s).log"
echo "Trace output will be saved to: $TRACE_FILE"

# Launch ZSH with maximum tracing and timeout
echo "Launching ZSH with comprehensive tracing..."
echo "=============================================="

timeout 30 env \
    ZDOTDIR="/Users/s-a-c/dotfiles/dot-config/zsh" \
    ZSH_DEBUG=1 \
    PS4='+[%D{%H:%M:%S}] %N:%i> ' \
    zsh -x -i -c 'echo "===ZSH STARTUP COMPLETED===" && sleep 2 && echo "===EXITING ZSH===" && exit 0' \
    > "$TRACE_FILE" 2>&1 &

ZSH_PID=$!
echo "ZSH launched with PID: $ZSH_PID"
echo "Monitoring startup progress..."

# Monitor the process every second
for i in {1..30}; do
    if kill -0 "$ZSH_PID" 2>/dev/null; then
        echo "[$i/30s] ZSH process $ZSH_PID still running..."
        
        # Show last few lines of trace every 5 seconds
        if (( i % 5 == 0 )); then
            echo "  Last 3 lines from trace:"
            tail -3 "$TRACE_FILE" 2>/dev/null | sed 's/^/    /'
        fi
        
        sleep 1
    else
        echo "[$i/30s] ZSH process exited"
        break
    fi
done

# Wait for process to finish
wait "$ZSH_PID" 2>/dev/null
ZSH_EXIT_CODE=$?

echo
echo "=== TRACE ANALYSIS ==="
echo "ZSH exit code: $ZSH_EXIT_CODE"
echo "Trace file: $TRACE_FILE"

if [[ -f "$TRACE_FILE" ]]; then
    TRACE_SIZE=$(wc -l < "$TRACE_FILE")
    echo "Trace file size: $TRACE_SIZE lines"
    
    echo
    echo "=== FIRST 20 LINES OF TRACE ==="
    head -20 "$TRACE_FILE"
    
    echo
    echo "=== LAST 20 LINES OF TRACE ==="
    tail -20 "$TRACE_FILE"
    
    echo
    echo "=== LOOKING FOR KEY EVENTS ==="
    echo "Lines containing 'error', 'failed', 'exit':"
    grep -i -n "error\|failed\|exit" "$TRACE_FILE" | head -10 || echo "No error/exit patterns found"
    
    echo
    echo "Lines containing startup completion markers:"
    grep -n "ZSH STARTUP COMPLETED\|baseline=\|SUCCESS" "$TRACE_FILE" || echo "No completion markers found"
    
    echo
    echo "Lines containing module loading:"
    grep -n "pre-plugin\|post-plugin\|zgenom\|plugin" "$TRACE_FILE" | tail -10 || echo "No plugin loading found"
    
else
    echo "ERROR: Trace file was not created!"
fi

echo
echo "=== SUMMARY ==="
echo "To analyze the full trace manually, run:"
echo "  less $TRACE_FILE"
echo "  grep -n 'pattern' $TRACE_FILE"

set +x  # Disable bash tracing