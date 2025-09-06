#!/usr/bin/env zsh
# ==============================================================================
# ZSH Configuration: Ongoing Performance Monitoring System
# ==============================================================================
# Purpose: Continuous performance tracking system with automated regression
#          detection, performance metrics collection, trend analysis, and
#          automated alerting for performance degradation with comprehensive
#          monitoring and reporting capabilities.
#
# Author: ZSH Configuration Management System
# Created: 2025-08-22
# Version: 1.0
# Load Order: 6th in 00-core (after async cache, before utilities)
# Dependencies: 01-source-execute-detection.zsh, 00-standard-helpers.zsh
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SOURCE/EXECUTE DETECTION INTEGRATION
# ------------------------------------------------------------------------------

# Guard against multiple sourcing in non-040-testing environments
if [[ -n "${ZSH_PERFORMANCE_MONITORING_LOADED:-}" && -z "${ZSH_MONITORING_TESTING:-}" ]]; then
    return 0
fi

# Load source/execute detection system if not already loaded
if [[ -z "${ZSH_SOURCE_EXECUTE_LOADED:-}" ]]; then
    local detection_script="${ZDOTDIR:-$HOME/.config/zsh}/.zshrc.d/00_01-source-execute-detection.zsh"
    if [[ -f "$detection_script" ]]; then
        source "$detection_script"
    else
        zsh_debug_echo "WARNING: Source/execute detection system not found: $detection_script"
        zsh_debug_echo "Performance monitoring will work but without context-aware features"
    fi
fi

# Use context-aware logging if detection system is available
if declare -f context_zsh_debug_echo >/dev/null 2>&1; then
    # Legacy logging functions are now provided by unified logging system
    # These are kept as compatibility aliases in 00_04-unified-logging.zsh
    # No need to redefine here
    :
else
    # Fallback to unified logging system if context detection not available
    _perf_log() { zsh_log "${2:-INFO}" "performance" "$1"; }
    _perf_error() { zsh_error "performance" "$1" "$2"; }
fi

# 1. Global Configuration and Monitoring Setup
#=============================================================================

[[ "$ZSH_DEBUG" == "1" ]] && {
        zsh_debug_echo "# ++++++ $0 ++++++++++++++++++++++++++++++++++++"
    _perf_log "Loading ongoing performance monitoring system v1.0"
}

# 1.1. Set global performance monitoring version for tracking
export ZSH_PERFORMANCE_MONITORING_VERSION="1.0.0"
export ZSH_PERFORMANCE_MONITORING_LOADED="$(command -v date >/dev/null && date -u '+    %FT%T %Z' || zsh_debug_echo 'loaded')"

# 1.2. Performance monitoring configuration
export ZSH_PERF_MONITOR_DIR="${ZDOTDIR:-$HOME/.config/zsh}/.performance"
export ZSH_PERF_METRICS_FILE="$ZSH_PERF_MONITOR_DIR/metrics.log"
export ZSH_PERF_TRENDS_FILE="$ZSH_PERF_MONITOR_DIR/trends.log"
export ZSH_PERF_ALERTS_FILE="$ZSH_PERF_MONITOR_DIR/alerts.log"

# Create performance monitoring directories
mkdir -p "$ZSH_PERF_MONITOR_DIR" 2>/dev/null || true

# 1.3. Performance monitoring settings
export ZSH_ENABLE_PERF_MONITORING="${ZSH_ENABLE_PERF_MONITORING:-true}"
export ZSH_PERF_SAMPLE_FREQUENCY="${ZSH_PERF_SAMPLE_FREQUENCY:-daily}"  # daily, weekly, startup
export ZSH_PERF_REGRESSION_THRESHOLD="${ZSH_PERF_REGRESSION_THRESHOLD:-20}"  # 20% degradation threshold
export ZSH_PERF_BASELINE_SAMPLES="${ZSH_PERF_BASELINE_SAMPLES:-10}"  # samples for baseline

# 1.4. Performance state tracking
typeset -gA ZSH_PERF_BASELINES
typeset -gA ZSH_PERF_CURRENT_METRICS
typeset -g ZSH_PERF_MONITORING_INITIALIZED="false"

# 2. Performance Metrics Collection
#=============================================================================

# 2.1. Initialize performance monitoring
_init_performance_monitoring() {
    _perf_log "Initializing performance monitoring system..."

    # Create metrics file if it doesn't exist
    if [[ ! -f "$ZSH_PERF_METRICS_FILE" ]]; then
        cat > "$ZSH_PERF_METRICS_FILE" << EOF
# ZSH Performance Metrics Log
# Format: timestamp,metric_type,value,context
# Created: $(date -u '+    %FT%T %Z' 2>/dev/null || zsh_debug_echo 'unknown')
EOF
        _perf_log "Created performance metrics file: $ZSH_PERF_METRICS_FILE"
    fi

    # Create alerts file if it doesn't exist
    if [[ ! -f "$ZSH_PERF_ALERTS_FILE" ]]; then
        touch "$ZSH_PERF_ALERTS_FILE"
        _perf_log "Created performance alerts file: $ZSH_PERF_ALERTS_FILE"
    fi

    # Create trends file if it doesn't exist
    if [[ ! -f "$ZSH_PERF_TRENDS_FILE" ]]; then
        touch "$ZSH_PERF_TRENDS_FILE"
        _perf_log "Created performance trends file: $ZSH_PERF_TRENDS_FILE"
    fi

    # Load existing baselines
    _load_performance_baselines

    ZSH_PERF_MONITORING_INITIALIZED="true"
}

# 2.2. Measure startup performance
_measure_startup_performance() {
    local iterations="${1:-3}"
    local context="${2:-interactive}"

    if [[ "$ZSH_ENABLE_PERF_MONITORING" != "true" ]]; then
        return 0
    fi

    _perf_log "Measuring startup performance ($iterations iterations, context: $context)" "DEBUG"

    local total_time=0
    local successful_runs=0
    local measurements=()

    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        # Quick shell startup test with timeout
        timeout 10 env ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}" /usr/bin/env zsh -i -c exit >/dev/null 2>&1

        local end_time=$(date +%s%N 2>/dev/null || zsh_debug_echo "$(date +%s)000000000")

        if [[ "$start_time" != "$end_time" ]]; then
            local run_time=$(( (end_time - start_time) / 1000000 ))
            measurements+=("$run_time")
            total_time=$((total_time + run_time))
            successful_runs=$((successful_runs + 1))
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
            std_dev=$(( $(zsh_debug_echo "sqrt($variance / ($successful_runs - 1))" | bc -l 2>/dev/null || zsh_debug_echo "0") ))
        fi

        # Record metrics
        _record_performance_metric "startup_time" "$avg_time" "$context"
        _record_performance_metric "startup_std_dev" "$std_dev" "$context"

        zsh_debug_echo "$avg_time"
        return 0
    else
        _perf_error "Failed to measure startup performance"
        return 1
    fi
}

# 2.3. Record performance metric
_record_performance_metric() {
    local metric_type="$1"
    local value="$2"
    local context="${3:-general}"

    if [[ "$ZSH_PERF_MONITORING_INITIALIZED" != "true" ]]; then
        return 0
    fi

    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    # Record to metrics file
    zsh_debug_echo "$timestamp,$metric_type,$value,$context" >> "$ZSH_PERF_METRICS_FILE"

    # Update current metrics
    ZSH_PERF_CURRENT_METRICS["${metric_type}_${context}"]="$value:$timestamp"

    # Check for regression
    _check_performance_regression "$metric_type" "$value" "$context"

    _perf_log "Recorded metric: $metric_type=$value (context: $context)" "DEBUG"
}

# 2.4. Load performance baselines
_load_performance_baselines() {
    if [[ ! -f "$ZSH_PERF_METRICS_FILE" ]]; then
        return 0
    fi

    # Calculate baselines from recent metrics
    local metric_types=("startup_time" "startup_std_dev")

    for metric_type in "${metric_types[@]}"; do
        # Get last N samples for baseline (including any metric_type)
        local samples=$(grep ",$metric_type," "$ZSH_PERF_METRICS_FILE" 2>/dev/null | tail -n "$ZSH_PERF_BASELINE_SAMPLES" | cut -d',' -f3)

        if [[ -n "$samples" ]]; then
            local total=0
            local count=0

            while IFS= read -r sample; do
                if [[ "$sample" =~ ^[0-9]+$ ]]; then
                    total=$((total + sample))
                    count=$((count + 1))
                fi
            done <<< "$samples"

            if [[ $count -gt 0 ]]; then
                local baseline=$((total / count))
                ZSH_PERF_BASELINES["$metric_type"]="$baseline"
                _perf_log "Loaded baseline for $metric_type: ${baseline}ms" "DEBUG"
            fi
        fi
    done
}

# 3. Performance Regression Detection
#=============================================================================

# 3.1. Check for performance regression
_check_performance_regression() {
    local metric_type="$1"
    local current_value="$2"
    local context="${3:-general}"

    local baseline="${ZSH_PERF_BASELINES[$metric_type]:-}"

    if [[ -z "$baseline" || ! "$baseline" =~ ^[0-9]+$ || ! "$current_value" =~ ^[0-9]+$ ]]; then
        return 0
    fi

    # Calculate percentage change
    local percentage_change
    if command -v bc >/dev/null 2>&1; then
        percentage_change=$(zsh_debug_echo "scale=2; (($current_value - $baseline) * 100) / $baseline" | bc 2>/dev/null || zsh_debug_echo "0")
    else
        percentage_change=$(( ((current_value - baseline) * 100) / baseline ))
    fi

    # Check if regression exceeds threshold
    if [[ $(zsh_debug_echo "$percentage_change > $ZSH_PERF_REGRESSION_THRESHOLD" | bc -l 2>/dev/null || zsh_debug_echo "0") == "1" ]]; then
        _trigger_performance_alert "$metric_type" "$baseline" "$current_value" "$percentage_change" "$context"
    fi
}

# 3.2. Trigger performance alert
_trigger_performance_alert() {
    local metric_type="$1"
    local baseline="$2"
    local current_value="$3"
    local percentage_change="$4"
    local context="${5:-general}"

    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    local alert_message="PERFORMANCE REGRESSION DETECTED: $metric_type increased by ${percentage_change}% (baseline: ${baseline}ms, current: ${current_value}ms, context: $context)"

    # Log alert
    zsh_debug_echo "$timestamp,REGRESSION,$metric_type,$baseline,$current_value,$percentage_change,$context" >> "$ZSH_PERF_ALERTS_FILE"

    # Display alert (if interactive)
    if [[ -t 1 ]]; then
        zsh_debug_echo "⚠️  $alert_message"
    fi

    _perf_log "$alert_message" "WARN"
}

# 4. Performance Trend Analysis
#=============================================================================

# 4.1. Analyze performance trends
_analyze_performance_trends() {
    local metric_type="${1:-startup_time}"
    local days="${2:-30}"

    if [[ ! -f "$ZSH_PERF_METRICS_FILE" ]]; then
        zsh_debug_echo "No performance metrics available"
        return 1
    fi

    _perf_log "Analyzing performance trends for $metric_type over $days days"

    # Get recent metrics
    local cutoff_date
    if command -v date >/dev/null 2>&1; then
        cutoff_date=$(date -u -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || date -u -v-${days}d '+%Y-%m-%d' 2>/dev/null || zsh_debug_echo "1970-01-01")
    else
        cutoff_date="1970-01-01"
    fi

    local recent_metrics=$(awk -F',' -v cutoff="$cutoff_date" -v metric="$metric_type" '
        $1 >= cutoff && $2 == metric { print $1 "," $3 }
    ' "$ZSH_PERF_METRICS_FILE" | sort)

    if [[ -z "$recent_metrics" ]]; then
        zsh_debug_echo "No recent metrics found for $metric_type"
        return 1
    fi

    # Calculate trend statistics
    local values=($(zsh_debug_echo "$recent_metrics" | cut -d',' -f2))
    local count=${#values[@]}

    if [[ $count -lt 2 ]]; then
        zsh_debug_echo "Insufficient data for trend analysis"
        return 1
    fi

    # Calculate basic statistics
    local total=0
    local min=${values[1]}
    local max=${values[1]}

    for value in "${values[@]}"; do
        total=$((total + value))
        if [[ $value -lt $min ]]; then min=$value; fi
        if [[ $value -gt $max ]]; then max=$value; fi
    done

    local average=$((total / count))

    # Record trend analysis
    local timestamp
    if command -v date >/dev/null 2>&1; then
        timestamp=$(date -u '+    %FT%T %Z')
    else
        timestamp="unknown"
    fi

    zsh_debug_echo "$timestamp,TREND_ANALYSIS,$metric_type,$count,$average,$min,$max" >> "$ZSH_PERF_TRENDS_FILE"

    # Display results
    zsh_debug_echo "Performance Trend Analysis: $metric_type"
    zsh_debug_echo "  Period: Last $days days"
    zsh_debug_echo "  Samples: $count"
    zsh_debug_echo "  Average: ${average}ms"
    zsh_debug_echo "  Range: ${min}ms - ${max}ms"
    zsh_debug_echo "  Variation: $((max - min))ms"
}

# 5. Monitoring Commands and Utilities
#=============================================================================

# 5.1. Performance monitoring status
perf-status() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Performance Monitoring System Status"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_PERFORMANCE_MONITORING_VERSION"
    zsh_debug_echo "Monitoring Enabled: $ZSH_ENABLE_PERF_MONITORING"
    zsh_debug_echo "Sample Frequency: $ZSH_PERF_SAMPLE_FREQUENCY"
    zsh_debug_echo "Regression Threshold: ${ZSH_PERF_REGRESSION_THRESHOLD}%"
    zsh_debug_echo ""

    zsh_debug_echo "Monitoring Directories:"
    zsh_debug_echo "  Monitor Dir: $ZSH_PERF_MONITOR_DIR"
    zsh_debug_echo "  Metrics File: $ZSH_PERF_METRICS_FILE"
    zsh_debug_echo "  Trends File: $ZSH_PERF_TRENDS_FILE"
    zsh_debug_echo "  Alerts File: $ZSH_PERF_ALERTS_FILE"
    zsh_debug_echo ""

    zsh_debug_echo "Current Baselines:"
    for metric in "${(@k)ZSH_PERF_BASELINES}"; do
        zsh_debug_echo "  $metric: ${ZSH_PERF_BASELINES[$metric]}ms"
    done

    zsh_debug_echo ""
    zsh_debug_echo "Recent Metrics:"
    if [[ -f "$ZSH_PERF_METRICS_FILE" ]]; then
        local recent_count=$(tail -n 10 "$ZSH_PERF_METRICS_FILE" | wc -l)
        zsh_debug_echo "  Recent samples: $recent_count"
        zsh_debug_echo "  Latest entries:"
        tail -n 5 "$ZSH_PERF_METRICS_FILE" | while IFS=',' read -r timestamp metric_type value context; do
            zsh_debug_echo "    $timestamp: $metric_type=${value}ms ($context)"
        done
    else
        zsh_debug_echo "  No metrics file found"
    fi

    zsh_debug_echo ""
    zsh_debug_echo "Recent Alerts:"
    if [[ -f "$ZSH_PERF_ALERTS_FILE" ]]; then
        local alert_count=$(wc -l < "$ZSH_PERF_ALERTS_FILE" 2>/dev/null || zsh_debug_echo "0")
        zsh_debug_echo "  Total alerts: $alert_count"
        if [[ $alert_count -gt 0 ]]; then
            zsh_debug_echo "  Recent alerts:"
            tail -n 3 "$ZSH_PERF_ALERTS_FILE" | while IFS=',' read -r timestamp type metric baseline current change context; do
                zsh_debug_echo "    $timestamp: $metric regression ${change}% (${baseline}ms → ${current}ms)"
            done
        fi
    else
        zsh_debug_echo "  No alerts file found"
    fi
}

# 5.2. Manual performance measurement
perf-measure() {
    local iterations="${1:-5}"
    zsh_debug_echo "Measuring current startup performance ($iterations iterations)..."

    local startup_time=$(_measure_startup_performance "$iterations" "manual")

    if [[ -n "$startup_time" ]]; then
        zsh_debug_echo "Current startup time: ${startup_time}ms"

        # Compare to baseline
        local baseline="${ZSH_PERF_BASELINES[startup_time]:-}"
        if [[ -n "$baseline" ]]; then
            local diff=$((startup_time - baseline))
            local percentage
            if command -v bc >/dev/null 2>&1; then
                percentage=$(zsh_debug_echo "scale=1; ($diff * 100) / $baseline" | bc 2>/dev/null || zsh_debug_echo "0")
            else
                percentage=$(( (diff * 100) / baseline ))
            fi

            if [[ $diff -gt 0 ]]; then
                zsh_debug_echo "Performance: ${percentage}% slower than baseline (${baseline}ms)"
            else
                zsh_debug_echo "Performance: ${percentage#-}% faster than baseline (${baseline}ms)"
            fi
        fi
    else
        zsh_debug_echo "Failed to measure performance"
        return 1
    fi
}

# 5.3. Performance trend analysis command
perf-trends() {
    local metric="${1:-startup_time}"
    local days="${2:-30}"

    _analyze_performance_trends "$metric" "$days"
}

# 5.4. Reset performance baselines
perf-reset-baselines() {
    zsh_debug_echo "Resetting performance baselines..."

    # Clear current baselines
    unset ZSH_PERF_BASELINES
    typeset -gA ZSH_PERF_BASELINES

    # Reload from recent metrics
    _load_performance_baselines

    zsh_debug_echo "Baselines reset and reloaded from recent metrics"
    perf-status
}

# 6. Automatic Performance Sampling
#=============================================================================

# 6.1. Automatic startup performance sampling
_auto_sample_performance() {
    if [[ "$ZSH_ENABLE_PERF_MONITORING" != "true" ]]; then
        return 0
    fi

    # Sample based on frequency setting
    local should_sample=false

    case "$ZSH_PERF_SAMPLE_FREQUENCY" in
        "startup")
            should_sample=true
            ;;
        "daily")
            # Sample once per day
            local today
            if command -v date >/dev/null 2>&1; then
                today=$(date '+%Y-%m-%d')
                local last_sample_date=$(grep "startup_time" "$ZSH_PERF_METRICS_FILE" 2>/dev/null | tail -1 | cut -d',' -f1 | cut -d' ' -f1)
                if [[ "$today" != "$last_sample_date" ]]; then
                    should_sample=true
                fi
            fi
            ;;
        "weekly")
            # Sample once per week
            local this_week
            if command -v date >/dev/null 2>&1; then
                this_week=$(date '+%Y-W%U')
                local last_sample_week=$(grep "startup_time" "$ZSH_PERF_METRICS_FILE" 2>/dev/null | tail -1 | cut -d',' -f1)
                if command -v date >/dev/null 2>&1; then
                    last_sample_week=$(date -d "$last_sample_week" '+%Y-W%U' 2>/dev/null || zsh_debug_echo "")
                fi
                if [[ "$this_week" != "$last_sample_week" ]]; then
                    should_sample=true
                fi
            fi
            ;;
    esac

    if $should_sample; then
        # Sample in background to avoid blocking startup
        (
            sleep 2  # Wait for shell to fully initialize
            _measure_startup_performance 3 "auto" >/dev/null 2>&1
        ) &
    fi
}

# 7. Initialization
#=============================================================================

# 7.1. Initialize performance monitoring system
_init_performance_monitoring

# 7.2. Set up automatic sampling (if enabled)
if [[ "$ZSH_ENABLE_PERF_MONITORING" == "true" ]]; then
    _auto_sample_performance
fi

[[ "$ZSH_DEBUG" == "1" ]] && _perf_log "✅ Performance monitoring system loaded successfully"

# ------------------------------------------------------------------------------
# 8. CONTEXT-AWARE EXECUTION
# ------------------------------------------------------------------------------

# Main function for when script is executed directly
performance_monitoring_main() {
    zsh_debug_echo "========================================================"
    zsh_debug_echo "ZSH Performance Monitoring System"
    zsh_debug_echo "========================================================"
    zsh_debug_echo "Version: $ZSH_PERFORMANCE_MONITORING_VERSION"
    zsh_debug_echo "Loaded: $ZSH_PERFORMANCE_MONITORING_LOADED"
    zsh_debug_echo ""

    if declare -f get_execution_context >/dev/null 2>&1; then
        zsh_debug_echo "Execution Context: $(get_execution_context)"
        zsh_debug_echo ""
    fi

    perf-status

    if declare -f safe_exit >/dev/null 2>&1; then
        safe_exit 0
    else
        exit 0
    fi
}

# Use context-aware execution if detection system is available
if declare -f is_being_executed >/dev/null 2>&1; then
    if is_being_executed; then
        performance_monitoring_main "$@"
    fi
elif [[ "${(%):-%N}" == "${0}" ]] || [[ "${(%):-%N}" == *"performance-monitoring"* ]]; then
    # Fallback detection for direct execution
    performance_monitoring_main "$@"
fi

# ==============================================================================
# END: Ongoing Performance Monitoring System
# ==============================================================================
