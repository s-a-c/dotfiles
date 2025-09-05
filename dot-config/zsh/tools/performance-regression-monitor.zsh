#!/usr/bin/env zsh
# performance-regression-monitor.zsh
# P1.3 Performance Regression Monitoring System
#
# PURPOSE:
#   Automated performance regression detection and monitoring system.
#   Integrates with variance-state.json and perf-multi-current.json to
#   detect performance degradation and trigger appropriate responses.
#
# FEATURES:
#   - Historical performance trend analysis
#   - Regression detection with configurable thresholds
#   - Integration with variance-state monitoring
#   - Automated alerting and escalation
#   - Performance baseline management
#   - CI/CD integration for performance gates

set -euo pipefail

# ------------------------
# Configuration
# ------------------------

SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd "${0%/*}" && pwd)"
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

# Directories
: ${METRICS_DIR:="$ZDOTDIR/docs/redesignv2/artifacts/metrics"}
: ${PERF_HISTORY_DIR:="$METRICS_DIR/history"}
: ${PERF_ALERTS_DIR:="$METRICS_DIR/alerts"}
: ${PERF_REPORTS_DIR:="$METRICS_DIR/reports"}

# Performance thresholds
: ${PERF_REGRESSION_THRESHOLD:=15}      # 15% regression threshold
: ${PERF_RSD_WARNING_THRESHOLD:=0.08}   # 8% RSD warning
: ${PERF_RSD_CRITICAL_THRESHOLD:=0.15}  # 15% RSD critical
: ${PERF_LOAD_TIME_WARNING:=1500}       # 1.5s warning threshold
: ${PERF_LOAD_TIME_CRITICAL:=3000}      # 3s critical threshold
: ${PERF_HISTORY_RETENTION_DAYS:=30}    # Keep 30 days of history

# Monitoring configuration
: ${PERF_MONITORING_ENABLED:=1}
: ${PERF_BASELINE_AUTO_UPDATE:=1}
: ${PERF_ALERT_ENABLED:=1}
: ${PERF_TREND_ANALYSIS_ENABLED:=1}
: ${PERF_VERBOSE:=0}

# Baseline configuration
: ${PERF_BASELINE_FILE:="$METRICS_DIR/performance-baseline.json"}
: ${PERF_BASELINE_MIN_SAMPLES:=5}
: ${PERF_BASELINE_CONFIDENCE:=0.95}

# ------------------------
# Utility Functions
# ------------------------

# Logging with timestamps
log() {
  local level="$1"; shift
  echo "[$(date -Iseconds)] [$level] [perf-monitor] $*" >&2
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }
debug() { (( PERF_VERBOSE )) && log "DEBUG" "$@"; }

# Ensure directory exists
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || {
      error "Failed to create directory: $dir"
      return 1
    }
    debug "Created directory: $dir"
  fi
}

# Get current timestamp
get_timestamp() {
  date -Iseconds 2>/dev/null || date
}

# Calculate percentage change
percentage_change() {
  local old="$1"
  local new="$2"
  
  if (( $(echo "$old == 0" | bc -l 2>/dev/null || echo 0) )); then
    echo "0"
    return
  fi
  
  echo "scale=2; ($new - $old) / $old * 100" | bc -l 2>/dev/null || awk -v o="$old" -v n="$new" 'BEGIN{printf "%.2f", (n-o)/o*100}'
}

# ------------------------
# Performance Data Collection
# ------------------------

# Collect current performance metrics
collect_current_metrics() {
  local output_file="${1:-}"
  
  debug "Collecting current performance metrics"
  
  # Check for required files
  local perf_multi_file="$METRICS_DIR/perf-multi-current.json"
  local variance_state_file="$METRICS_DIR/variance-state.json"
  
  if [[ ! -f "$perf_multi_file" ]]; then
    error "Performance data not found: $perf_multi_file"
    return 1
  fi
  
  # Extract key metrics
  local timestamp cold_mean warm_mean pre_mean post_mean prompt_mean
  local cold_stddev warm_stddev pre_stddev post_stddev prompt_stddev
  local rsd_pre rsd_post rsd_prompt samples authentic_samples
  
  # Parse perf-multi-current.json
  if command -v jq >/dev/null 2>&1; then
    timestamp=$(jq -r '.timestamp // "unknown"' "$perf_multi_file")
    samples=$(jq -r '.samples // 0' "$perf_multi_file")
    authentic_samples=$(jq -r '.authentic_samples // 0' "$perf_multi_file")
    
    cold_mean=$(jq -r '.aggregate.cold_ms.mean // 0' "$perf_multi_file")
    warm_mean=$(jq -r '.aggregate.warm_ms.mean // 0' "$perf_multi_file")
    pre_mean=$(jq -r '.aggregate.pre_plugin_cost_ms.mean // 0' "$perf_multi_file")
    post_mean=$(jq -r '.aggregate.post_plugin_cost_ms.mean // 0' "$perf_multi_file")
    prompt_mean=$(jq -r '.aggregate.prompt_ready_ms.mean // 0' "$perf_multi_file")
    
    cold_stddev=$(jq -r '.aggregate.cold_ms.stddev // 0' "$perf_multi_file")
    warm_stddev=$(jq -r '.aggregate.warm_ms.stddev // 0' "$perf_multi_file")
    pre_stddev=$(jq -r '.aggregate.pre_plugin_cost_ms.stddev // 0' "$perf_multi_file")
    post_stddev=$(jq -r '.aggregate.post_plugin_cost_ms.stddev // 0' "$perf_multi_file")
    prompt_stddev=$(jq -r '.aggregate.prompt_ready_ms.stddev // 0' "$perf_multi_file")
    
    rsd_pre=$(jq -r '.rsd_pre // 0' "$perf_multi_file")
    rsd_post=$(jq -r '.rsd_post // 0' "$perf_multi_file")
    rsd_prompt=$(jq -r '.rsd_prompt // 0' "$perf_multi_file")
  else
    # Fallback parsing without jq
    timestamp=$(grep -o '"timestamp":[[:space:]]*"[^"]*"' "$perf_multi_file" | cut -d'"' -f4)
    samples=$(grep -o '"samples":[[:space:]]*[0-9]*' "$perf_multi_file" | grep -o '[0-9]*$')
    # ... more fallback parsing would go here
    warn "jq not available, using limited parsing"
  fi
  
  # Collect variance state if available
  local variance_status="unknown"
  local max_rsd="0"
  local quality_grade="unknown"
  
  if [[ -f "$variance_state_file" ]] && command -v jq >/dev/null 2>&1; then
    variance_status=$(jq -r '.rsd_metrics.status // "unknown"' "$variance_state_file")
    max_rsd=$(jq -r '.rsd_metrics.current_max_rsd // 0' "$variance_state_file")
    quality_grade=$(jq -r '.variance_assessment.consistency_grade // "unknown"' "$variance_state_file")
  fi
  
  # Create metrics object
  local metrics_data
  metrics_data=$(
cat <<EOF
{
  "collection_timestamp": "$(get_timestamp)",
  "source_timestamp": "$timestamp",
  "samples": $samples,
  "authentic_samples": $authentic_samples,
  "metrics": {
    "cold_ms": {
      "mean": $cold_mean,
      "stddev": $cold_stddev
    },
    "warm_ms": {
      "mean": $warm_mean,
      "stddev": $warm_stddev
    },
    "pre_plugin_cost_ms": {
      "mean": $pre_mean,
      "stddev": $pre_stddev
    },
    "post_plugin_cost_ms": {
      "mean": $post_mean,
      "stddev": $post_stddev
    },
    "prompt_ready_ms": {
      "mean": $prompt_mean,
      "stddev": $prompt_stddev
    }
  },
  "rsd": {
    "pre_plugin_cost_ms": $rsd_pre,
    "post_plugin_cost_ms": $rsd_post,
    "prompt_ready_ms": $rsd_prompt,
    "max_rsd": $max_rsd
  },
  "variance_state": {
    "status": "$variance_status",
    "consistency_grade": "$quality_grade"
  }
}
EOF
)
  
  if [[ -n "$output_file" ]]; then
    echo "$metrics_data" >"$output_file"
    debug "Metrics written to: $output_file"
  else
    echo "$metrics_data"
  fi
  
  return 0
}

# Store metrics in history
store_metrics_history() {
  ensure_dir "$PERF_HISTORY_DIR"
  
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local history_file="$PERF_HISTORY_DIR/perf-metrics-$timestamp.json"
  
  if collect_current_metrics "$history_file"; then
    info "Stored performance metrics: $history_file"
    
    # Clean up old history files
    cleanup_old_history
    
    return 0
  else
    error "Failed to collect and store performance metrics"
    return 1
  fi
}

# Clean up old history files
cleanup_old_history() {
  local cutoff_date
  cutoff_date=$(date -d "$PERF_HISTORY_RETENTION_DAYS days ago" +%Y%m%d 2>/dev/null || date -v-"${PERF_HISTORY_RETENTION_DAYS}d" +%Y%m%d 2>/dev/null)
  
  if [[ -z "$cutoff_date" ]]; then
    warn "Unable to calculate cutoff date for history cleanup"
    return 1
  fi
  
  local removed_count=0
  local file
  
  for file in "$PERF_HISTORY_DIR"/perf-metrics-*.json; do
    if [[ ! -f "$file" ]]; then
      continue
    fi
    
    local file_date
    file_date=$(basename "$file" | grep -o '[0-9]\{8\}')
    
    if [[ -n "$file_date" ]] && [[ "$file_date" -lt "$cutoff_date" ]]; then
      rm -f "$file" && (( removed_count++ ))
    fi
  done
  
  if (( removed_count > 0 )); then
    debug "Cleaned up $removed_count old history files"
  fi
}

# ------------------------
# Baseline Management
# ------------------------

# Load performance baseline
load_baseline() {
  if [[ ! -f "$PERF_BASELINE_FILE" ]]; then
    debug "No performance baseline found: $PERF_BASELINE_FILE"
    return 1
  fi
  
  debug "Loading performance baseline from: $PERF_BASELINE_FILE"
  cat "$PERF_BASELINE_FILE"
}

# Create or update performance baseline
update_baseline() {
  local force="${1:-false}"
  
  info "Updating performance baseline (force: $force)"
  
  # Check if we have enough historical data
  local history_count
  history_count=$(find "$PERF_HISTORY_DIR" -name "perf-metrics-*.json" 2>/dev/null | wc -l)
  
  if (( history_count < PERF_BASELINE_MIN_SAMPLES )) && [[ "$force" != "true" ]]; then
    warn "Insufficient historical data for baseline ($history_count < $PERF_BASELINE_MIN_SAMPLES samples)"
    return 1
  fi
  
  # Calculate baseline from recent stable measurements
  local -A metric_sums metric_counts
  local file
  
  # Process recent history files
  for file in "$PERF_HISTORY_DIR"/perf-metrics-*.json; do
    if [[ ! -f "$file" ]]; then
      continue
    fi
    
    if command -v jq >/dev/null 2>&1; then
      # Extract metrics and add to running totals
      local cold_mean warm_mean pre_mean post_mean prompt_mean
      
      cold_mean=$(jq -r '.metrics.cold_ms.mean // 0' "$file")
      warm_mean=$(jq -r '.metrics.warm_ms.mean // 0' "$file")
      pre_mean=$(jq -r '.metrics.pre_plugin_cost_ms.mean // 0' "$file")
      post_mean=$(jq -r '.metrics.post_plugin_cost_ms.mean // 0' "$file")
      prompt_mean=$(jq -r '.metrics.prompt_ready_ms.mean // 0' "$file")
      
      # Skip invalid measurements
      if (( $(echo "$post_mean <= 0" | bc -l 2>/dev/null || echo 0) )); then
        continue
      fi
      
      # Add to running totals
      metric_sums[cold_ms]=$(echo "${metric_sums[cold_ms]:-0} + $cold_mean" | bc -l)
      metric_sums[warm_ms]=$(echo "${metric_sums[warm_ms]:-0} + $warm_mean" | bc -l)
      metric_sums[pre_plugin_cost_ms]=$(echo "${metric_sums[pre_plugin_cost_ms]:-0} + $pre_mean" | bc -l)
      metric_sums[post_plugin_cost_ms]=$(echo "${metric_sums[post_plugin_cost_ms]:-0} + $post_mean" | bc -l)
      metric_sums[prompt_ready_ms]=$(echo "${metric_sums[prompt_ready_ms]:-0} + $prompt_mean" | bc -l)
      
      (( metric_counts[valid]++ ))
    fi
  done
  
  local valid_count=${metric_counts[valid]:-0}
  if (( valid_count == 0 )); then
    error "No valid measurements found for baseline calculation"
    return 1
  fi
  
  # Calculate baseline averages
  local baseline_cold baseline_warm baseline_pre baseline_post baseline_prompt
  
  baseline_cold=$(echo "scale=2; ${metric_sums[cold_ms]} / $valid_count" | bc -l)
  baseline_warm=$(echo "scale=2; ${metric_sums[warm_ms]} / $valid_count" | bc -l)
  baseline_pre=$(echo "scale=2; ${metric_sums[pre_plugin_cost_ms]} / $valid_count" | bc -l)
  baseline_post=$(echo "scale=2; ${metric_sums[post_plugin_cost_ms]} / $valid_count" | bc -l)
  baseline_prompt=$(echo "scale=2; ${metric_sums[prompt_ready_ms]} / $valid_count" | bc -l)
  
  # Create baseline file
  cat >"$PERF_BASELINE_FILE" <<EOF
{
  "schema": "performance-baseline.v1",
  "created": "$(get_timestamp)",
  "samples_used": $valid_count,
  "confidence_level": $PERF_BASELINE_CONFIDENCE,
  "baseline_metrics": {
    "cold_ms": $baseline_cold,
    "warm_ms": $baseline_warm,
    "pre_plugin_cost_ms": $baseline_pre,
    "post_plugin_cost_ms": $baseline_post,
    "prompt_ready_ms": $baseline_prompt
  },
  "thresholds": {
    "regression_threshold_percent": $PERF_REGRESSION_THRESHOLD,
    "rsd_warning_threshold": $PERF_RSD_WARNING_THRESHOLD,
    "rsd_critical_threshold": $PERF_RSD_CRITICAL_THRESHOLD,
    "load_time_warning_ms": $PERF_LOAD_TIME_WARNING,
    "load_time_critical_ms": $PERF_LOAD_TIME_CRITICAL
  }
}
EOF
  
  info "Performance baseline updated with $valid_count samples"
  debug "Baseline metrics: cold=${baseline_cold}ms warm=${baseline_warm}ms pre=${baseline_pre}ms post=${baseline_post}ms prompt=${baseline_prompt}ms"
  
  return 0
}

# ------------------------
# Regression Detection
# ------------------------

# Detect performance regressions
detect_regressions() {
  local current_metrics_file="${1:-}"
  
  info "Detecting performance regressions"
  
  # Load baseline
  local baseline_data
  if ! baseline_data=$(load_baseline); then
    warn "No baseline available for regression detection"
    return 1
  fi
  
  # Get current metrics
  local current_data
  if [[ -n "$current_metrics_file" && -f "$current_metrics_file" ]]; then
    current_data=$(<"$current_metrics_file")
  else
    if ! current_data=$(collect_current_metrics); then
      error "Failed to collect current metrics"
      return 1
    fi
  fi
  
  # Parse baseline and current data
  if ! command -v jq >/dev/null 2>&1; then
    error "jq required for regression detection"
    return 1
  fi
  
  local -A baseline_metrics current_metrics regressions
  local metric_names=("cold_ms" "warm_ms" "pre_plugin_cost_ms" "post_plugin_cost_ms" "prompt_ready_ms")
  
  # Extract baseline metrics
  for metric in "${metric_names[@]}"; do
    baseline_metrics[$metric]=$(echo "$baseline_data" | jq -r ".baseline_metrics.$metric // 0")
  done
  
  # Extract current metrics
  for metric in "${metric_names[@]}"; do
    current_metrics[$metric]=$(echo "$current_data" | jq -r ".metrics.$metric.mean // 0")
  done
  
  # Calculate regressions
  local regression_detected=false
  local total_regressions=0
  
  for metric in "${metric_names[@]}"; do
    local baseline_val="${baseline_metrics[$metric]}"
    local current_val="${current_metrics[$metric]}"
    
    # Skip if baseline or current value is zero/invalid
    if (( $(echo "$baseline_val <= 0 || $current_val <= 0" | bc -l) )); then
      debug "Skipping $metric: invalid baseline ($baseline_val) or current ($current_val) value"
      continue
    fi
    
    local change_percent
    change_percent=$(percentage_change "$baseline_val" "$current_val")
    
    # Check for regression (performance degradation)
    if (( $(echo "$change_percent > $PERF_REGRESSION_THRESHOLD" | bc -l) )); then
      regressions[$metric]="$change_percent"
      regression_detected=true
      (( total_regressions++ ))
      
      warn "Performance regression detected: $metric ($change_percent% increase from baseline)"
      warn "  Baseline: ${baseline_val}ms, Current: ${current_val}ms"
    else
      debug "$metric within threshold: $change_percent% change (threshold: $PERF_REGRESSION_THRESHOLD%)"
    fi
  done
  
  # Check RSD regressions
  local current_max_rsd
  current_max_rsd=$(echo "$current_data" | jq -r '.rsd.max_rsd // 0')
  
  local rsd_status="OK"
  if (( $(echo "$current_max_rsd > $PERF_RSD_CRITICAL_THRESHOLD" | bc -l) )); then
    rsd_status="CRITICAL"
    regression_detected=true
    warn "RSD regression detected: $current_max_rsd (critical threshold: $PERF_RSD_CRITICAL_THRESHOLD)"
  elif (( $(echo "$current_max_rsd > $PERF_RSD_WARNING_THRESHOLD" | bc -l) )); then
    rsd_status="WARNING"
    warn "RSD warning: $current_max_rsd (warning threshold: $PERF_RSD_WARNING_THRESHOLD)"
  fi
  
  # Create regression report
  if [[ "$regression_detected" == "true" ]]; then
    create_regression_alert "$baseline_data" "$current_data" regressions
    info "Performance regression detected: $total_regressions metric(s), RSD status: $rsd_status"
    return 1
  else
    info "No performance regressions detected"
    return 0
  fi
}

# Create regression alert
create_regression_alert() {
  local baseline_data="$1"
  local current_data="$2"
  local -n regression_map=$3
  
  ensure_dir "$PERF_ALERTS_DIR"
  
  local alert_timestamp=$(date +%Y%m%d-%H%M%S)
  local alert_file="$PERF_ALERTS_DIR/regression-alert-$alert_timestamp.json"
  
  info "Creating regression alert: $alert_file"
  
  cat >"$alert_file" <<EOF
{
  "alert_type": "performance_regression",
  "severity": "high",
  "timestamp": "$(get_timestamp)",
  "summary": {
    "total_regressions": ${#regression_map[@]},
    "regression_threshold_percent": $PERF_REGRESSION_THRESHOLD
  },
  "regressions": {
EOF
  
  # Add regression details
  local first=true
  local metric
  for metric in "${(@k)regression_map}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo "," >>"$alert_file"
    fi
    echo "    \"$metric\": \"${regression_map[$metric]}%\"" >>"$alert_file"
  done
  
  cat >>"$alert_file" <<EOF
  },
  "baseline_data": $baseline_data,
  "current_data": $current_data,
  "recommended_actions": [
    "Review recent changes that may impact performance",
    "Run additional performance tests to confirm regression",
    "Consider rolling back recent changes if regression is severe",
    "Update performance baseline if regression is acceptable"
  ]
}
EOF
  
  # Send alert notification
  send_regression_notification "$alert_file"
}

# Send regression notification
send_regression_notification() {
  local alert_file="$1"
  
  if [[ "${PERF_ALERT_ENABLED:-1}" != "1" ]]; then
    debug "Performance alerts disabled"
    return 0
  fi
  
  # This would integrate with external notification systems
  # For now, just log and create a visible alert file
  
  local summary_file="$PERF_ALERTS_DIR/PERFORMANCE_REGRESSION_ALERT"
  
  {
    echo "PERFORMANCE REGRESSION DETECTED"
    echo "================================"
    echo "Alert File: $alert_file"
    echo "Timestamp: $(get_timestamp)"
    echo ""
    echo "A performance regression has been detected."
    echo "Please review the detailed alert file for more information."
    echo ""
    echo "Immediate Actions:"
    echo "1. Review recent changes"
    echo "2. Run performance analysis"
    echo "3. Consider rollback if necessary"
  } >"$summary_file"
  
  error "PERFORMANCE REGRESSION ALERT CREATED: $summary_file"
}

# ------------------------
# Trend Analysis
# ------------------------

# Analyze performance trends
analyze_trends() {
  local days_back="${1:-7}"
  
  if [[ "${PERF_TREND_ANALYSIS_ENABLED:-1}" != "1" ]]; then
    debug "Trend analysis disabled"
    return 0
  fi
  
  info "Analyzing performance trends (last $days_back days)"
  
  # Find history files within the time window
  local cutoff_date
  cutoff_date=$(date -d "$days_back days ago" +%Y%m%d 2>/dev/null || date -v-"${days_back}d" +%Y%m%d 2>/dev/null)
  
  local -a history_files
  local file
  
  for file in "$PERF_HISTORY_DIR"/perf-metrics-*.json; do
    if [[ ! -f "$file" ]]; then
      continue
    fi
    
    local file_date
    file_date=$(basename "$file" | grep -o '[0-9]\{8\}')
    
    if [[ -n "$file_date" ]] && [[ "$file_date" -ge "$cutoff_date" ]]; then
      history_files+=("$file")
    fi
  done
  
  if (( ${#history_files[@]} < 2 )); then
    warn "Insufficient data for trend analysis (${#history_files[@]} files found)"
    return 1
  fi
  
  # Sort files chronologically
  IFS=$'\n' history_files=($(printf '%s\n' "${history_files[@]}" | sort))
  
  # Calculate trends for key metrics
  ensure_dir "$PERF_REPORTS_DIR"
  local trend_report="$PERF_REPORTS_DIR/trend-analysis-$(date +%Y%m%d-%H%M%S).json"
  
  generate_trend_report "${history_files[@]}" >"$trend_report"
  
  info "Trend analysis completed: $trend_report"
}

# Generate trend report
generate_trend_report() {
  local -a files=("$@")
  
  if ! command -v jq >/dev/null 2>&1; then
    error "jq required for trend analysis"
    return 1
  fi
  
  # Initialize trend data structure
  cat <<EOF
{
  "report_type": "performance_trend_analysis",
  "generated": "$(get_timestamp)",
  "period_days": 7,
  "samples_analyzed": ${#files[@]},
  "trends": {
EOF
  
  local metric_names=("cold_ms" "warm_ms" "pre_plugin_cost_ms" "post_plugin_cost_ms" "prompt_ready_ms")
  local metric first_metric=true
  
  for metric in "${metric_names[@]}"; do
    if [[ "$first_metric" != "true" ]]; then
      echo ","
    fi
    first_metric=false
    
    # Collect data points for this metric
    local -a values timestamps
    local file
    
    for file in "${files[@]}"; do
      local value timestamp
      value=$(jq -r ".metrics.$metric.mean // 0" "$file")
      timestamp=$(jq -r '.collection_timestamp // ""' "$file")
      
      if (( $(echo "$value > 0" | bc -l) )); then
        values+=("$value")
        timestamps+=("$timestamp")
      fi
    done
    
    # Calculate trend statistics
    if (( ${#values[@]} >= 2 )); then
      local first_val last_val trend_percent
      first_val="${values[1]}"
      last_val="${values[-1]}"
      
      trend_percent=$(percentage_change "$first_val" "$last_val")
      
      # Calculate average and std deviation
      local sum=0 count=${#values[@]}
      local val
      
      for val in "${values[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
      done
      
      local avg
      avg=$(echo "scale=2; $sum / $count" | bc -l)
      
      echo -n "    \"$metric\": {"
      echo -n "\"trend_percent\": $trend_percent, "
      echo -n "\"average\": $avg, "
      echo -n "\"samples\": $count, "
      echo -n "\"first_value\": $first_val, "
      echo -n "\"last_value\": $last_val"
      echo -n "}"
    else
      echo -n "    \"$metric\": {\"error\": \"insufficient_data\"}"
    fi
  done
  
  echo ""
  echo "  }"
  echo "}"
}

# ------------------------
# CLI Interface
# ------------------------

usage() {
  cat <<EOF
$SCRIPT_NAME - Performance Regression Monitoring System

Usage: $SCRIPT_NAME [command] [options]

Commands:
  monitor                  Collect current metrics and store in history
  detect                   Detect performance regressions
  baseline [update]        Show or update performance baseline
  trends [days]            Analyze performance trends (default: 7 days)
  report                   Generate comprehensive performance report
  cleanup                  Clean up old history files
  health                   Check system health

Options:
  --verbose                Enable verbose output
  --force                  Force operations (e.g., baseline update)
  --no-alerts              Disable alert notifications
  --help                   Show this help

Examples:
  $SCRIPT_NAME monitor
  $SCRIPT_NAME detect --verbose
  $SCRIPT_NAME baseline update --force
  $SCRIPT_NAME trends 14
EOF
}

# Main function
main() {
  local command="${1:-monitor}"
  shift 2>/dev/null || true
  
  # Parse options
  local force=false
  
  while (( $# > 0 )); do
    case "$1" in
      --verbose)
        PERF_VERBOSE=1
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      --no-alerts)
        PERF_ALERT_ENABLED=0
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done
  
  # Ensure directories exist
  ensure_dir "$METRICS_DIR"
  ensure_dir "$PERF_HISTORY_DIR"
  ensure_dir "$PERF_ALERTS_DIR"
  ensure_dir "$PERF_REPORTS_DIR"
  
  # Execute command
  case "$command" in
    monitor)
      store_metrics_history
      ;;
    detect)
      detect_regressions
      ;;
    baseline)
      local sub_cmd="${1:-show}"
      case "$sub_cmd" in
        show)
          if load_baseline; then
            exit 0
          else
            error "No baseline available"
            exit 1
          fi
          ;;
        update)
          update_baseline "$force"
          ;;
        *)
          error "Unknown baseline command: $sub_cmd"
          exit 1
          ;;
      esac
      ;;
    trends)
      local days="${1:-7}"
      analyze_trends "$days"
      ;;
    report)
      info "Generating comprehensive performance report"
      store_metrics_history
      detect_regressions
      analyze_trends
      ;;
    cleanup)
      cleanup_old_history
      ;;
    health)
      check_system_health
      ;;
    *)
      error "Unknown command: $command"
      usage
      exit 1
      ;;
  esac
}

# Check system health
check_system_health() {
  info "Checking performance monitoring system health"
  
  local issues=0
  
  # Check directories
  for dir in "$METRICS_DIR" "$PERF_HISTORY_DIR" "$PERF_ALERTS_DIR" "$PERF_REPORTS_DIR"; do
    if [[ ! -d "$dir" ]]; then
      error "Directory missing: $dir"
      (( issues++ ))
    fi
  done
  
  # Check required commands
  for cmd in jq bc date; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      error "Required command missing: $cmd"
      (( issues++ ))
    fi
  done
  
  # Check data files
  if [[ ! -f "$METRICS_DIR/perf-multi-current.json" ]]; then
    warn "Current performance data not found"
    (( issues++ ))
  fi
  
  # Check history
  local history_count
  history_count=$(find "$PERF_HISTORY_DIR" -name "perf-metrics-*.json" 2>/dev/null | wc -l)
  info "Historical data: $history_count files"
  
  if (( issues == 0 )); then
    info "System health: OK"
    return 0
  else
    error "System health: $issues issue(s) found"
    return 1
  fi
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
  main "$@"
fi
