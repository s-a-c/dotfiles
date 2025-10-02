#!/usr/bin/env zsh
# ==============================================================================
# ZSH Legacy Configuration: Performance Monitoring Module
# ==============================================================================
# Purpose: Comprehensive performance monitoring system with automated regression
#          detection, segment timing, startup benchmarking, instrumentation,
#          and system metrics collection with trend analysis
# 
# Consolidated from:
#   - DISABLED-00_30-performance-monitoring.zsh (ongoing performance monitoring)
#   - 70-performance-monitoring.zsh (REDESIGN async metrics export)
#   - 60-p10k-instrument.zsh (REDESIGN P10k theme instrumentation)
#   - 65-vcs-gitstatus-instrument.zsh (REDESIGN VCS/Git status instrumentation)
#   - test-performance.zsh (performance testing utilities)
#
# Dependencies: 01-core-infrastructure.zsh (for logging and basic functions)
# Load Order: Early (20-29 range, after core but before most other modules)
# Author: ZSH Legacy Consolidation System
# Created: 2025-09-15
# Version: 1.0.0
# ==============================================================================

# Prevent multiple loading
if [[ -n "${_PERFORMANCE_MONITORING_LOADED:-}" ]]; then
    return 0
fi

# Disable performance monitoring in Warp terminal to prevent hangs
if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
    return 0
fi

export _PERFORMANCE_MONITORING_LOADED=1

# Debug helper - use core infrastructure if available
_perf_debug() {
    if command -v debug_log >/dev/null 2>&1; then
        debug_log "$1"
    elif [[ -n "${ZSH_DEBUG:-}" ]]; then
        echo "[PERF-DEBUG] $1" >&2
    fi
}

_perf_debug "Loading performance monitoring module..."

# ==============================================================================
# SECTION 1: CONFIGURATION AND GLOBAL SETTINGS
# ==============================================================================
# Purpose: Configure performance monitoring settings and directory structure

_perf_debug "Setting up performance monitoring configuration..."

# 1.1. Version and metadata
export ZSH_PERFORMANCE_MONITORING_VERSION="1.0.0"
export ZSH_PERFORMANCE_MONITORING_LOADED="$(date '+%Y-%m-%d %H:%M:%S')"

# 1.2. Feature toggles and configuration
export ZSH_ENABLE_PERF_MONITORING="${ZSH_ENABLE_PERF_MONITORING:-true}"
export ZSH_PERF_SAMPLE_FREQUENCY="${ZSH_PERF_SAMPLE_FREQUENCY:-daily}"
export ZSH_PERF_REGRESSION_THRESHOLD="${ZSH_PERF_REGRESSION_THRESHOLD:-20}"
export ZSH_PERF_BASELINE_SAMPLES="${ZSH_PERF_BASELINE_SAMPLES:-10}"

# Instrumentation controls
export ZSH_P10K_INSTRUMENT="${ZSH_P10K_INSTRUMENT:-1}"
export ZSH_GITSTATUS_INSTRUMENT="${ZSH_GITSTATUS_INSTRUMENT:-1}"
export ZSH_COMPINIT_INSTRUMENT="${ZSH_COMPINIT_INSTRUMENT:-1}"

# 1.3. Directory and file configuration
export ZSH_PERF_MONITOR_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.performance"
export ZSH_PERF_METRICS_FILE="$ZSH_PERF_MONITOR_DIR/metrics.log"
export ZSH_PERF_TRENDS_FILE="$ZSH_PERF_MONITOR_DIR/trends.log"
export ZSH_PERF_ALERTS_FILE="$ZSH_PERF_MONITOR_DIR/alerts.log"
export ZSH_PERF_BASELINE_FILE="$ZSH_PERF_MONITOR_DIR/baselines.json"

# Create performance monitoring directories
mkdir -p "$ZSH_PERF_MONITOR_DIR" 2>/dev/null || true

# 1.4. Performance state tracking
typeset -gA ZSH_PERF_BASELINES
typeset -gA ZSH_PERF_CURRENT_METRICS
typeset -gA ZSH_PERF_SEGMENT_START

export ZSH_PERF_MONITORING_INITIALIZED="false"

_perf_debug "Performance monitoring directories configured: $ZSH_PERF_MONITOR_DIR"

# ==============================================================================
# SECTION 2: HIGH-PRECISION TIMING UTILITIES
# ==============================================================================
# Purpose: Provide microsecond-level timing for performance measurement

_perf_debug "Setting up high-precision timing utilities..."

# Load datetime module for high-precision timing
zmodload zsh/datetime 2>/dev/null || true

# Get current time in milliseconds
perf_now_ms() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ms+=substr($2"000",1,3)+0} printf "%d", ms}'
    else
        date +%s 2>/dev/null | awk '{printf "%d",$1*1000}'
    fi
}

# Get current time in nanoseconds (for very precise measurements)
perf_now_ns() {
    if command -v date >/dev/null 2>&1; then
        date +%s%N 2>/dev/null || echo "$(date +%s)000000000"
    else
        echo "$(perf_now_ms)000000"
    fi
}

# Calculate duration between two timestamps
perf_duration() {
    local start="$1"
    local end="${2:-$(perf_now_ms)}"
    local duration=$((end - start))
    (( duration < 0 )) && duration=0
    echo "$duration"
}

_perf_debug "High-precision timing utilities ready"

# ==============================================================================
# SECTION 3: SEGMENT TIMING FRAMEWORK
# ==============================================================================
# Purpose: Segment-based performance measurement for component analysis

_perf_debug "Setting up segment timing framework..."

# Start timing a performance segment
perf_segment_start() {
    local segment_name="$1"
    local phase="${2:-general}"
    
    if [[ -z "$segment_name" ]]; then
        _perf_debug "Error: segment name required for perf_segment_start"
        return 1
    fi
    
    local start_time=$(perf_now_ms)
    ZSH_PERF_SEGMENT_START["${segment_name}_${phase}"]="$start_time"
    
    _perf_debug "Started segment: $segment_name (phase: $phase, start: ${start_time}ms)"
}

# End timing a performance segment
perf_segment_end() {
    local segment_name="$1"
    local phase="${2:-general}"
    
    if [[ -z "$segment_name" ]]; then
        _perf_debug "Error: segment name required for perf_segment_end"
        return 1
    fi
    
    local key="${segment_name}_${phase}"
    local start_time="${ZSH_PERF_SEGMENT_START[$key]:-}"
    
    if [[ -z "$start_time" ]]; then
        _perf_debug "Warning: no start time found for segment $segment_name (phase: $phase)"
        return 1
    fi
    
    local end_time=$(perf_now_ms)
    local duration=$(perf_duration "$start_time" "$end_time")
    
    # Log to performance segment file if available
    if [[ -n "${PERF_SEGMENT_LOG:-}" && -w "${PERF_SEGMENT_LOG}" ]]; then
        local sample="${PERF_SAMPLE_CONTEXT:-unknown}"
        echo "SEGMENT name=$segment_name ms=$duration phase=$phase sample=$sample" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
        echo "POST_PLUGIN_SEGMENT $segment_name $duration" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
    fi
    
    # Record in metrics
    record_performance_metric "${segment_name}_segment" "$duration" "$phase"
    
    # Clean up start time
    unset "ZSH_PERF_SEGMENT_START[$key]"
    
    _perf_debug "Completed segment: $segment_name (phase: $phase, duration: ${duration}ms)"
    echo "$duration"
}

# Time a function or command execution
perf_time_execution() {
    local name="$1"
    shift
    
    perf_segment_start "$name" "execution"
    "$@"
    local result=$?
    perf_segment_end "$name" "execution" >/dev/null
    
    return $result
}

_perf_debug "Segment timing framework ready"

# ==============================================================================
# SECTION 4: STARTUP PERFORMANCE MEASUREMENT
# ==============================================================================
# Purpose: Measure and analyze ZSH startup performance with statistical analysis

_perf_debug "Setting up startup performance measurement..."

# Measure startup performance with multiple iterations
measure_startup_performance() {
    local iterations="${1:-3}"
    local context="${2:-interactive}"
    
    if [[ "$ZSH_ENABLE_PERF_MONITORING" != "true" ]]; then
        _perf_debug "Performance monitoring disabled"
        return 0
    fi

    _perf_debug "Measuring startup performance ($iterations iterations, context: $context)"

    local total_time=0
    local successful_runs=0
    local measurements=()

    for ((i=1; i<=iterations; i++)); do
        local start_time=$(perf_now_ns)

        # Quick shell startup test with timeout
        timeout 10 env ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}" zsh -i -c exit >/dev/null 2>&1

        local end_time=$(perf_now_ns)

        if [[ "$start_time" != "$end_time" ]]; then
            local run_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
            measurements+=("$run_time")
            total_time=$((total_time + run_time))
            successful_runs=$((successful_runs + 1))
            _perf_debug "Startup test $i: ${run_time}ms"
        fi
    done

    if [[ $successful_runs -gt 0 ]]; then
        local avg_time=$((total_time / successful_runs))

        # Calculate standard deviation
        local variance=0
        for time in "${measurements[@]}"; do
            local diff=$((time - avg_time))
            variance=$((variance + diff * diff))
        done
        
        local std_dev=0
        if [[ $successful_runs -gt 1 ]]; then
            if command -v bc >/dev/null 2>&1; then
                std_dev=$(echo "sqrt($variance / ($successful_runs - 1))" | bc -l 2>/dev/null || echo "0")
            else
                std_dev=$(awk "BEGIN {printf \"%d\", sqrt($variance / ($successful_runs - 1))}" 2>/dev/null || echo "0")
            fi
        fi

        # Record metrics
        record_performance_metric "startup_time" "$avg_time" "$context"
        record_performance_metric "startup_std_dev" "$std_dev" "$context"
        record_performance_metric "startup_samples" "$successful_runs" "$context"

        _perf_debug "Startup performance: ${avg_time}ms avg, ${std_dev}ms std_dev ($successful_runs samples)"
        echo "$avg_time"
        return 0
    else
        _perf_debug "Failed to measure startup performance"
        return 1
    fi
}

# Quick startup time test
quick_startup_test() {
    local iterations="${1:-1}"
    echo "🧪 Quick Startup Performance Test"
    echo "Running $iterations startup test$([ $iterations -gt 1 ] && echo 's')..."
    
    local result
    result=$(measure_startup_performance "$iterations" "quick_test")
    
    if [[ -n "$result" ]]; then
        echo "Startup time: ${result}ms"
        
        # Performance rating
        if [[ $result -lt 1000 ]]; then
            echo "Performance: 🚀 Excellent"
        elif [[ $result -lt 2000 ]]; then
            echo "Performance: ✅ Good"
        elif [[ $result -lt 3000 ]]; then
            echo "Performance: ⚠️ Fair"
        else
            echo "Performance: 🐌 Needs Improvement"
        fi
    else
        echo "❌ Failed to measure startup performance"
        return 1
    fi
}

_perf_debug "Startup performance measurement ready"

# ==============================================================================
# SECTION 5: METRICS COLLECTION AND STORAGE
# ==============================================================================
# Purpose: Record, store, and manage performance metrics with persistence

_perf_debug "Setting up metrics collection and storage..."

# Initialize performance monitoring system
init_performance_monitoring() {
    if [[ "$ZSH_PERF_MONITORING_INITIALIZED" == "true" ]]; then
        return 0
    fi

    _perf_debug "Initializing performance monitoring system..."

    # Create metrics file if it doesn't exist
    if [[ ! -f "$ZSH_PERF_METRICS_FILE" ]]; then
        cat > "$ZSH_PERF_METRICS_FILE" << EOF
# ZSH Performance Metrics Log
# Format: timestamp,metric_type,value,context
# Created: $(date -u '+%Y-%m-%dT%H:%M:%S %Z' 2>/dev/null || echo 'unknown')
EOF
        _perf_debug "Created performance metrics file: $ZSH_PERF_METRICS_FILE"
    fi

    # Create other log files
    [[ ! -f "$ZSH_PERF_ALERTS_FILE" ]] && touch "$ZSH_PERF_ALERTS_FILE"
    [[ ! -f "$ZSH_PERF_TRENDS_FILE" ]] && touch "$ZSH_PERF_TRENDS_FILE"

    # Load existing baselines
    load_performance_baselines

    ZSH_PERF_MONITORING_INITIALIZED="true"
    export ZSH_PERF_MONITORING_INITIALIZED

    _perf_debug "Performance monitoring system initialized"
}

# Record a performance metric
record_performance_metric() {
    local metric_type="$1"
    local value="$2"
    local context="${3:-general}"

    if [[ "$ZSH_PERF_MONITORING_INITIALIZED" != "true" ]]; then
        init_performance_monitoring
    fi

    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S %Z')
    else
        timestamp="unknown"
    fi

    # Record to metrics file
    echo "$timestamp,$metric_type,$value,$context" >> "$ZSH_PERF_METRICS_FILE"

    # Update current metrics
    ZSH_PERF_CURRENT_METRICS["${metric_type}_${context}"]="$value:$timestamp"

    # Check for regression
    check_performance_regression "$metric_type" "$value" "$context"

    _perf_debug "Recorded metric: $metric_type=$value (context: $context)"
}

# Load performance baselines from historical data
load_performance_baselines() {
    if [[ ! -f "$ZSH_PERF_METRICS_FILE" ]]; then
        return 0
    fi

    _perf_debug "Loading performance baselines..."

    # Calculate baselines from recent metrics
    local metric_types=("startup_time" "startup_std_dev" "compinit_segment" "p10k_theme_segment")

    for metric_type in "${metric_types[@]}"; do
        # Get last N samples for baseline
        local samples=$(grep ",$metric_type," "$ZSH_PERF_METRICS_FILE" 2>/dev/null | tail -n "$ZSH_PERF_BASELINE_SAMPLES" | cut -d',' -f3)

        if [[ -n "$samples" ]]; then
            local total=0
            local count=0

            while IFS= read -r sample; do
                if [[ "$sample" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    if command -v bc >/dev/null 2>&1; then
                        total=$(echo "$total + $sample" | bc 2>/dev/null || echo "$total")
                    else
                        total=$((total + ${sample%.*}))  # Truncate decimal for integer math
                    fi
                    count=$((count + 1))
                fi
            done <<< "$samples"

            if [[ $count -gt 0 ]]; then
                local baseline
                if command -v bc >/dev/null 2>&1; then
                    baseline=$(echo "scale=2; $total / $count" | bc 2>/dev/null || echo "$total")
                else
                    baseline=$((total / count))
                fi
                ZSH_PERF_BASELINES["$metric_type"]="$baseline"
                _perf_debug "Loaded baseline for $metric_type: ${baseline}ms"
            fi
        fi
    done
}

# Save baselines to JSON file
save_performance_baselines() {
    local json_content="{\n"
    local first=true
    
    for metric_type in "${(@k)ZSH_PERF_BASELINES}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json_content+=",\n"
        fi
        json_content+="  \"$metric_type\": ${ZSH_PERF_BASELINES[$metric_type]}"
    done
    
    json_content+="\n}"
    echo -e "$json_content" > "$ZSH_PERF_BASELINE_FILE"
    _perf_debug "Saved performance baselines to $ZSH_PERF_BASELINE_FILE"
}

_perf_debug "Metrics collection and storage ready"

# ==============================================================================
# SECTION 6: REGRESSION DETECTION AND ALERTING
# ==============================================================================
# Purpose: Detect performance regressions and trigger alerts

_perf_debug "Setting up regression detection and alerting..."

# Check for performance regression
check_performance_regression() {
    local metric_type="$1"
    local current_value="$2"
    local context="${3:-general}"

    local baseline="${ZSH_PERF_BASELINES[$metric_type]:-}"

    if [[ -z "$baseline" ]]; then
        return 0
    fi

    # Ensure both values are numeric
    if ! [[ "$baseline" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$current_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    fi

    # Calculate percentage change
    local percentage_change
    if command -v bc >/dev/null 2>&1; then
        percentage_change=$(echo "scale=2; (($current_value - $baseline) * 100) / $baseline" | bc 2>/dev/null || echo "0")
    else
        # Integer math approximation
        percentage_change=$(( ((${current_value%.*} - ${baseline%.*}) * 100) / ${baseline%.*} ))
    fi

    # Check if regression exceeds threshold
    local exceeds_threshold=false
    if command -v bc >/dev/null 2>&1; then
        if [[ $(echo "$percentage_change > $ZSH_PERF_REGRESSION_THRESHOLD" | bc -l 2>/dev/null || echo "0") == "1" ]]; then
            exceeds_threshold=true
        fi
    else
        if [[ ${percentage_change%.*} -gt $ZSH_PERF_REGRESSION_THRESHOLD ]]; then
            exceeds_threshold=true
        fi
    fi

    if [[ "$exceeds_threshold" == "true" ]]; then
        trigger_performance_alert "$metric_type" "$baseline" "$current_value" "$percentage_change" "$context"
    fi
}

# Trigger performance alert
trigger_performance_alert() {
    local metric_type="$1"
    local baseline="$2"
    local current_value="$3"
    local percentage_change="$4"
    local context="${5:-general}"

    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S %Z')
    else
        timestamp="unknown"
    fi

    local alert_message="PERFORMANCE REGRESSION DETECTED: $metric_type increased by ${percentage_change}% (baseline: ${baseline}ms, current: ${current_value}ms, context: $context)"

    # Log alert
    echo "$timestamp,REGRESSION,$metric_type,$baseline,$current_value,$percentage_change,$context" >> "$ZSH_PERF_ALERTS_FILE"

    # Display alert (if interactive)
    if [[ -t 1 ]]; then
        echo "⚠️  $alert_message"
    fi

    _perf_debug "$alert_message"
}

_perf_debug "Regression detection and alerting ready"

# ==============================================================================
# SECTION 7: INSTRUMENTATION FRAMEWORK
# ==============================================================================
# Purpose: Instrument specific components like themes, completion, VCS

_perf_debug "Setting up instrumentation framework..."

# P10k Theme Instrumentation
instrument_p10k_theme() {
    if [[ "${ZSH_P10K_INSTRUMENT:-1}" == "0" ]]; then
        _perf_debug "P10k instrumentation disabled"
        return 0
    fi
    
    # Resolve P10k configuration file
    local p10k_file
    if [[ -n "${ZSH_P10K_FILE:-}" ]]; then
        p10k_file="$ZSH_P10K_FILE"
    elif [[ -r "${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh" ]]; then
        p10k_file="${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh"
    elif [[ -r "$HOME/.p10k.zsh" ]]; then
        p10k_file="$HOME/.p10k.zsh"
    fi
    
    if [[ -z "$p10k_file" || ! -r "$p10k_file" ]]; then
        _perf_debug "P10k theme file not found"
        return 0
    fi
    
    if [[ -n "${_P10K_THEME_LOADED:-}" ]]; then
        _perf_debug "P10k theme already loaded"
        return 0
    fi
    
    _perf_debug "Instrumenting P10k theme: $p10k_file"
    
    perf_segment_start "p10k_theme" "post_plugin"
    source "$p10k_file" 2>/dev/null || _perf_debug "Error sourcing P10k theme"
    perf_segment_end "p10k_theme" "post_plugin" >/dev/null
    
    export _P10K_THEME_LOADED=1
    _perf_debug "P10k theme instrumentation completed"
}

# VCS/Git Status Instrumentation
instrument_gitstatus() {
    if [[ "${ZSH_GITSTATUS_INSTRUMENT:-1}" == "0" ]]; then
        _perf_debug "Gitstatus instrumentation disabled"
        return 0
    fi
    
    if [[ -n "${_GITSTATUS_INIT_DONE:-}" || -n "${GITSTATUS_DAEMON_PID:-}" ]]; then
        _perf_debug "Gitstatus already initialized"
        return 0
    fi
    
    # Find gitstatus plugin
    local gitstatus_candidates=(
        "${ZDOTDIR:-$HOME/.config/zsh}/.zsh/gitstatus/gitstatus.plugin.zsh"
        "${ZDOTDIR:-$HOME/.config/zsh}/.zsh/plugins/gitstatus/gitstatus.plugin.zsh"
        "${ZDOTDIR:-$HOME/.config/zsh}/plugins/gitstatus/gitstatus.plugin.zsh"
        "${HOME}/.cache/gitstatus/gitstatus.plugin.zsh"
        "${HOME}/.oh-my-zsh/custom/plugins/gitstatus/gitstatus.plugin.zsh"
    )
    
    local gitstatus_plugin=""
    for candidate in "${gitstatus_candidates[@]}"; do
        if [[ -r "$candidate" ]]; then
            gitstatus_plugin="$candidate"
            break
        fi
    done
    
    if [[ -z "$gitstatus_plugin" ]]; then
        _perf_debug "Gitstatus plugin not found"
        return 0
    fi
    
    _perf_debug "Instrumenting gitstatus: $gitstatus_plugin"
    
    perf_segment_start "gitstatus_init" "post_plugin"
    source "$gitstatus_plugin" 2>/dev/null || _perf_debug "Error sourcing gitstatus plugin"
    
    # Optional readiness wait
    local wait_ms="${ZSH_GITSTATUS_WAIT_MS:-120}"
    if [[ "$wait_ms" =~ ^[0-9]+$ ]] && (( wait_ms > 0 )); then
        local poll_count=0
        local max_polls=$((wait_ms / 10))
        
        while (( poll_count < max_polls )); do
            if [[ -n "${GITSTATUS_DAEMON_PID:-}" ]] || typeset -f gitstatus_prompt >/dev/null 2>&1; then
                break
            fi
            sleep 0.01
            ((poll_count++))
        done
        
        _perf_debug "Gitstatus readiness wait: $poll_count/$max_polls polls"
    fi
    
    perf_segment_end "gitstatus_init" "post_plugin" >/dev/null
    
    export _GITSTATUS_INIT_DONE=1
    _perf_debug "Gitstatus instrumentation completed"
}

# Async metrics export
export_async_metrics() {
    if [[ -n "${ASYNC_METRICS_EXPORTED_70:-}" ]]; then
        return 0
    fi
    
    export ASYNC_METRICS_EXPORTED_70=1
    
    # Try to load async metrics export tool
    local async_tools=(
        "${ZDOTDIR:-$HOME/.config/zsh}/tools/async-metrics-export.zsh"
        "${ZDOTDIR:-$HOME/.config/zsh}/../tools/async-metrics-export.zsh"
    )
    
    for tool in "${async_tools[@]}"; do
        if [[ -r "$tool" ]]; then
            source "$tool" 2>/dev/null || true
            _perf_debug "Async metrics export loaded: $tool"
            break
        fi
    done
}

_perf_debug "Instrumentation framework ready"

# ==============================================================================
# SECTION 8: SYSTEM MONITORING UTILITIES
# ==============================================================================
# Purpose: Monitor system resources and environment health

_perf_debug "Setting up system monitoring utilities..."

# Get system memory usage
get_memory_usage() {
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ppid,pmem,rss,comm -p $$ 2>/dev/null | tail -1
    else
        echo "Memory monitoring not available"
    fi
}

# Get CPU usage
get_cpu_usage() {
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,ppid,pcpu,time,comm -p $$ 2>/dev/null | tail -1
    else
        echo "CPU monitoring not available"
    fi
}

# System health check
system_health_check() {
    echo "🔍 System Health Check"
    echo "======================"
    
    # Memory usage
    echo "Memory Usage:"
    get_memory_usage | awk '{print "  RSS: " $4 " KB, %MEM: " $3 "%"}'
    
    # CPU usage
    echo "CPU Usage:"
    get_cpu_usage | awk '{print "  %CPU: " $3 "%, TIME: " $4}'
    
    # Load average (if available)
    if command -v uptime >/dev/null 2>&1; then
        echo "Load Average:"
        uptime | sed 's/.*load average: /  /'
    fi
    
    # Disk usage for ZSH directories
    echo "Disk Usage:"
    if command -v du >/dev/null 2>&1; then
        local zsh_size=$(du -sh "${ZDOTDIR:-$HOME/.config/zsh}" 2>/dev/null | awk '{print $1}')
        echo "  ZSH Config: $zsh_size"
        
        local perf_size=$(du -sh "$ZSH_PERF_MONITOR_DIR" 2>/dev/null | awk '{print $1}')
        echo "  Performance Data: $perf_size"
    fi
    
    # PATH integrity
    local path_entries=$(echo "$PATH" | tr ':' '\n' | wc -l)
    local unique_entries=$(echo "$PATH" | tr ':' '\n' | sort -u | wc -l)
    echo "PATH Integrity:"
    echo "  Entries: $path_entries total, $unique_entries unique"
    
    if [[ $path_entries -eq $unique_entries ]]; then
        echo "  Status: ✅ No duplicates"
    else
        local duplicates=$((path_entries - unique_entries))
        echo "  Status: ⚠️ $duplicates duplicate(s)"
    fi
}

_perf_debug "System monitoring utilities ready"

# ==============================================================================
# SECTION 9: PERFORMANCE MANAGEMENT COMMANDS
# ==============================================================================
# Purpose: Provide user commands for performance monitoring and analysis

_perf_debug "Setting up performance management commands..."

# Performance status command
perf-status() {
    echo "========================================================"
    echo "Performance Monitoring System Status"
    echo "========================================================"
    echo "Version: $ZSH_PERFORMANCE_MONITORING_VERSION"
    echo "Monitoring Enabled: $ZSH_ENABLE_PERF_MONITORING"
    echo "Sample Frequency: $ZSH_PERF_SAMPLE_FREQUENCY"
    echo "Regression Threshold: ${ZSH_PERF_REGRESSION_THRESHOLD}%"
    echo ""

    echo "Monitoring Files:"
    echo "  Monitor Dir: $ZSH_PERF_MONITOR_DIR"
    echo "  Metrics File: $ZSH_PERF_METRICS_FILE"
    echo "  Trends File: $ZSH_PERF_TRENDS_FILE"
    echo "  Alerts File: $ZSH_PERF_ALERTS_FILE"
    echo ""

    echo "Current Baselines:"
    if [[ ${#ZSH_PERF_BASELINES[@]} -gt 0 ]]; then
        for metric in "${(@k)ZSH_PERF_BASELINES}"; do
            echo "  $metric: ${ZSH_PERF_BASELINES[$metric]}ms"
        done
    else
        echo "  No baselines loaded"
    fi

    echo ""
    echo "Recent Metrics:"
    if [[ -f "$ZSH_PERF_METRICS_FILE" ]]; then
        local recent_count=$(tail -n 10 "$ZSH_PERF_METRICS_FILE" | wc -l)
        echo "  Recent samples: $recent_count"
        if [[ $recent_count -gt 0 ]]; then
            echo "  Latest entries:"
            tail -n 5 "$ZSH_PERF_METRICS_FILE" | while IFS=',' read -r timestamp metric_type value context; do
                echo "    $timestamp: $metric_type=${value}ms ($context)"
            done
        fi
    else
        echo "  No metrics file found"
    fi

    echo ""
    echo "Recent Alerts:"
    if [[ -f "$ZSH_PERF_ALERTS_FILE" ]]; then
        local alert_count=$(wc -l < "$ZSH_PERF_ALERTS_FILE" 2>/dev/null || echo "0")
        echo "  Total alerts: $alert_count"
        if [[ $alert_count -gt 0 ]]; then
            echo "  Recent alerts:"
            tail -n 3 "$ZSH_PERF_ALERTS_FILE" | while IFS=',' read -r timestamp type metric baseline current change context; do
                echo "    $timestamp: $metric regression ${change}% (${baseline}ms → ${current}ms)"
            done
        fi
    else
        echo "  No alerts file found"
    fi
}

# Manual performance measurement
perf-measure() {
    local iterations="${1:-5}"
    echo "Measuring current startup performance ($iterations iterations)..."

    local startup_time
    startup_time=$(measure_startup_performance "$iterations" "manual")

    if [[ -n "$startup_time" ]]; then
        echo "Current startup time: ${startup_time}ms"

        # Compare to baseline
        local baseline="${ZSH_PERF_BASELINES[startup_time]:-}"
        if [[ -n "$baseline" ]]; then
            local diff
            local percentage
            
            if command -v bc >/dev/null 2>&1; then
                diff=$(echo "$startup_time - $baseline" | bc 2>/dev/null || echo "0")
                percentage=$(echo "scale=1; ($diff * 100) / $baseline" | bc 2>/dev/null || echo "0")
            else
                diff=$((${startup_time%.*} - ${baseline%.*}))
                percentage=$(( (diff * 100) / ${baseline%.*} ))
            fi

            if [[ ${diff%.*} -gt 0 ]]; then
                echo "Performance: ${percentage}% slower than baseline (${baseline}ms)"
            else
                echo "Performance: ${percentage#-}% faster than baseline (${baseline}ms)"
            fi
        fi
    else
        echo "Failed to measure performance"
        return 1
    fi
}

# Reset performance baselines
perf-reset-baselines() {
    echo "Resetting performance baselines..."

    # Clear current baselines
    unset ZSH_PERF_BASELINES
    typeset -gA ZSH_PERF_BASELINES

    # Reload from recent metrics
    load_performance_baselines
    save_performance_baselines

    echo "Baselines reset and reloaded from recent metrics"
    perf-status
}

# Performance test suite
perf-test-suite() {
    echo "🧪 ZSH Performance Test Suite"
    echo "============================="
    echo

    # Test 1: Startup Time
    echo "📊 Testing startup time..."
    quick_startup_test 3
    echo

    # Test 2: System Health
    system_health_check
    echo

    # Test 3: Function availability
    echo "🔍 Testing performance functions..."
    local func_tests=("perf_now_ms" "perf_segment_start" "measure_startup_performance")
    local func_passed=0
    
    for func in "${func_tests[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            echo "  ✅ $func available"
            ((func_passed++))
        else
            echo "  ❌ $func missing"
        fi
    done
    
    echo "  Functions: $func_passed/${#func_tests[@]} available"
    echo

    # Test 4: Instrumentation status
    echo "🔧 Testing instrumentation status..."
    echo "  P10k Instrument: ${ZSH_P10K_INSTRUMENT:-0}"
    echo "  Gitstatus Instrument: ${ZSH_GITSTATUS_INSTRUMENT:-0}"
    echo "  Monitoring Enabled: $ZSH_ENABLE_PERF_MONITORING"
    echo

    echo "✅ Performance test suite completed!"
}

_perf_debug "Performance management commands ready"

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

_perf_debug "Initializing performance monitoring module..."

# Initialize the monitoring system
init_performance_monitoring

# Set up automatic sampling based on frequency
if [[ "$ZSH_ENABLE_PERF_MONITORING" == "true" ]]; then
    # Background performance sampling
    case "$ZSH_PERF_SAMPLE_FREQUENCY" in
        "startup")
            # Sample on every startup (background to avoid blocking)
            (
                sleep 2
                measure_startup_performance 1 "auto" >/dev/null 2>&1
            ) &
            ;;
        "daily")
            # Check if we need to sample today
            local today
            if command -v date >/dev/null 2>&1; then
                today=$(date '+%Y-%m-%d')
                local last_sample_date
                if [[ -f "$ZSH_PERF_METRICS_FILE" ]]; then
                    last_sample_date=$(grep "startup_time" "$ZSH_PERF_METRICS_FILE" 2>/dev/null | tail -1 | cut -d',' -f1 | cut -d'T' -f1)
                fi
                if [[ "$today" != "$last_sample_date" ]]; then
                    (
                        sleep 3
                        measure_startup_performance 2 "daily" >/dev/null 2>&1
                    ) &
                fi
            fi
            ;;
    esac
fi

# Export async metrics (best effort)
export_async_metrics

# Set module metadata
local active_instruments=0
[[ "${ZSH_P10K_INSTRUMENT:-1}" == "1" ]] && ((active_instruments++))
[[ "${ZSH_GITSTATUS_INSTRUMENT:-1}" == "1" ]] && ((active_instruments++))
[[ "${ZSH_COMPINIT_INSTRUMENT:-1}" == "1" ]] && ((active_instruments++))

export PERFORMANCE_ACTIVE_INSTRUMENTS=$active_instruments
export PERFORMANCE_BASELINES_COUNT=${#ZSH_PERF_BASELINES[@]}

_perf_debug "Performance monitoring module ready ($active_instruments instruments, ${#ZSH_PERF_BASELINES[@]} baselines)"

# ==============================================================================
# MODULE SELF-TEST
# ==============================================================================

test_performance_monitoring() {
    local tests_passed=0
    local tests_total=12
    
    # Test 1: Module metadata
    if [[ -n "$ZSH_PERFORMANCE_MONITORING_VERSION" ]]; then
        ((tests_passed++))
        echo "✅ Module metadata available"
    else
        echo "❌ Module metadata missing"
    fi
    
    # Test 2: Directory creation
    if [[ -d "$ZSH_PERF_MONITOR_DIR" ]]; then
        ((tests_passed++))
        echo "✅ Performance directories created"
    else
        echo "❌ Performance directories missing"
    fi
    
    # Test 3: Timing functions
    if command -v perf_now_ms >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Timing functions available"
    else
        echo "❌ Timing functions missing"
    fi
    
    # Test 4: Segment timing
    if command -v perf_segment_start >/dev/null 2>&1 && command -v perf_segment_end >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Segment timing functions available"
    else
        echo "❌ Segment timing functions missing"
    fi
    
    # Test 5: Startup measurement
    if command -v measure_startup_performance >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Startup measurement available"
    else
        echo "❌ Startup measurement missing"
    fi
    
    # Test 6: Metrics recording
    if command -v record_performance_metric >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Metrics recording available"
    else
        echo "❌ Metrics recording missing"
    fi
    
    # Test 7: Management commands
    if command -v perf-status >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Management commands available"
    else
        echo "❌ Management commands missing"
    fi
    
    # Test 8: System monitoring
    if command -v system_health_check >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ System monitoring available"
    else
        echo "❌ System monitoring missing"
    fi
    
    # Test 9: Instrumentation functions
    if command -v instrument_p10k_theme >/dev/null 2>&1; then
        ((tests_passed++))
        echo "✅ Instrumentation functions available"
    else
        echo "❌ Instrumentation functions missing"
    fi
    
    # Test 10: Metrics file created
    if [[ -f "$ZSH_PERF_METRICS_FILE" ]]; then
        ((tests_passed++))
        echo "✅ Metrics file created"
    else
        echo "❌ Metrics file missing"
    fi
    
    # Test 11: Initialization status
    if [[ "$ZSH_PERF_MONITORING_INITIALIZED" == "true" ]]; then
        ((tests_passed++))
        echo "✅ System initialized"
    else
        echo "❌ System not initialized"
    fi
    
    # Test 12: High-precision timing test
    local start_time=$(perf_now_ms)
    sleep 0.01  # 10ms sleep
    local end_time=$(perf_now_ms)
    local duration=$((end_time - start_time))
    
    if [[ $duration -gt 5 && $duration -lt 50 ]]; then  # Should be around 10ms, allowing variance
        ((tests_passed++))
        echo "✅ High-precision timing working (${duration}ms)"
    else
        echo "❌ High-precision timing issues (${duration}ms)"
    fi
    
    echo ""
    echo "Performance Monitoring Self-Test: $tests_passed/$tests_total tests passed"
    echo "📁 Monitor directory: $ZSH_PERF_MONITOR_DIR"
    echo "🔧 Active instruments: $PERFORMANCE_ACTIVE_INSTRUMENTS"
    echo "📊 Baseline metrics: $PERFORMANCE_BASELINES_COUNT"
    echo "🗂️  Module version: $ZSH_PERFORMANCE_MONITORING_VERSION"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        return 0
    else
        return 1
    fi
}

# ==============================================================================
# END OF PERFORMANCE MONITORING MODULE
# ==============================================================================