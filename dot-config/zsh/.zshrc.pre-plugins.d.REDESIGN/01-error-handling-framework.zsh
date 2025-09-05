#!/opt/homebrew/bin/zsh
# 01-error-handling-framework.zsh
# P1.1 Core Module Hardening - Error Handling Framework
#
# PURPOSE:
#   Provides robust error handling, validation, and fault tolerance
#   for all core zsh modules. Optimized for zsh 5.9+.
#
# COMPATIBILITY: zsh 5.9+ (/opt/homebrew/bin/zsh)

if [[ -n "${_LOADED_01_ERROR_HANDLING:-}" ]]; then
  return 0
fi
_LOADED_01_ERROR_HANDLING=1

# ------------------------
# Error Handling Framework
# ------------------------

# Error tracking
ZF_ERROR_LOG_MAX=100
ZF_MIN_LOG_LEVEL=${ZF_MIN_LOG_LEVEL:-2}  # WARN and above
ZF_PERF_MONITOR_ERRORS=${ZF_PERF_MONITOR_ERRORS:-1}
ZF_ERROR_RECOVERY_ENABLED=${ZF_ERROR_RECOVERY_ENABLED:-1}

# Initialize arrays using zsh 5.9+ syntax
typeset -ga ZF_ERROR_LOG
ZF_ERROR_LOG=()

# ------------------------
# Core Error Functions
# ------------------------

# Get error level numeric value
get_error_level() {
  case "$1" in
    "DEBUG") echo 0 ;;
    "INFO") echo 1 ;;
    "WARN") echo 2 ;;
    "ERROR") echo 3 ;;
    "CRITICAL") echo 4 ;;
    "FATAL") echo 5 ;;
    *) echo 3 ;;  # Default to ERROR
  esac
}

# Log error with severity level
zf_error() {
  local level="${1:-ERROR}"
  local module="${2:-unknown}"
  local message="$3"
  local context="${4:-}"
  
  # Get numeric level
  local level_num
  level_num=$(get_error_level "$level")
  
  # Check if we should log this level
  if (( level_num < ZF_MIN_LOG_LEVEL )); then
    return 0
  fi
  
  # Create log entry
  local timestamp
  timestamp=$(date -Iseconds 2>/dev/null || date)
  local entry="$timestamp [$level] [$module] $message"
  [[ -n "$context" ]] && entry="$entry (context: $context)"
  
  # Add to log buffer
  ZF_ERROR_LOG+=("$entry")
  
  # Rotate log if too large
  if (( ${#ZF_ERROR_LOG[@]} > ZF_ERROR_LOG_MAX )); then
    local half=$((ZF_ERROR_LOG_MAX/2))
    ZF_ERROR_LOG=("${ZF_ERROR_LOG[@]: -$half}")
  fi
  
  # Output to stderr if appropriate
  if (( level_num >= 2 )); then  # WARN and above
    print "[zf-error] $entry" >&2
  fi
  
  # Performance monitoring integration
  if [[ "$ZF_PERF_MONITOR_ERRORS" == "1" && -n "${PERF_SEGMENT_LOG:-}" ]]; then
    print "ERROR level=$level module=$module" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
  fi
  
  # Trigger recovery if critical
  if [[ "$level" == "CRITICAL" || "$level" == "FATAL" ]]; then
    zf_trigger_recovery "$module" "$level" "$message"
  fi
  
  return $((level_num >= 3 ? 1 : 0))
}

# Convenience functions for different severity levels
zf_debug() { zf_error "DEBUG" "$1" "$2" "$3"; }
zf_info()  { zf_error "INFO" "$1" "$2" "$3"; }
zf_warn()  { zf_error "WARN" "$1" "$2" "$3"; }
zf_err()   { zf_error "ERROR" "$1" "$2" "$3"; }
zf_crit()  { zf_error "CRITICAL" "$1" "$2" "$3"; }
zf_fatal() { zf_error "FATAL" "$1" "$2" "$3"; }

# ------------------------
# Module Health Tracking
# ------------------------

# Simple module health tracking using files
get_module_health_file() {
  local module="$1"
  echo "/tmp/zf_module_${module}_health"
}

# Register module load start
zf_module_load_start() {
  local module="$1"
  [[ -z "$module" ]] && return 1
  
  local health_file
  health_file=$(get_module_health_file "$module")
  
  local start_time
  if [[ -n "${EPOCHREALTIME:-}" ]]; then
    start_time="$EPOCHREALTIME"
  else
    start_time="$(date +%s.%N 2>/dev/null || date +%s)"
  fi
  
  echo "status=loading start_time=$start_time" > "$health_file"
  return 0
}

# Register module load completion
zf_module_load_complete() {
  local module="$1"
  local load_status="${2:-success}"
  [[ -z "$module" ]] && return 1
  
  local health_file
  health_file=$(get_module_health_file "$module")
  
  local end_time
  if [[ -n "${EPOCHREALTIME:-}" ]]; then
    end_time="$EPOCHREALTIME"
  else
    end_time="$(date +%s.%N 2>/dev/null || date +%s)"
  fi
  
  # Read start time if available
  local start_time="$end_time"
  if [[ -f "$health_file" ]]; then
    start_time=$(grep '^start_time=' "$health_file" | cut -d= -f2)
  fi
  
  local load_time_ms
  load_time_ms=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN{printf "%.0f", (e-s)*1000}' 2>/dev/null || echo "0")
  
  echo "status=$load_status load_time_ms=$load_time_ms end_time=$end_time" > "$health_file"
  
  # Log if slow or failed
  if (( load_time_ms > 100 )); then
    zf_warn "$module" "slow load time: ${load_time_ms}ms"
  fi
  
  if [[ "$load_status" != "success" ]]; then
    zf_err "$module" "load failed with status: $load_status"
  fi
  
  return 0
}

# Get module health status
zf_module_health() {
  local module="$1"
  [[ -z "$module" ]] && return 1
  
  local health_file
  health_file=$(get_module_health_file "$module")
  
  if [[ -f "$health_file" ]]; then
    local module_status load_time
    module_status=$(grep '^status=' "$health_file" | cut -d= -f2)
    load_time=$(grep '^load_time_ms=' "$health_file" | cut -d= -f2)
    print "module=$module health=${module_status:-unknown} load_time=${load_time:-unknown}ms"
  else
    print "module=$module health=unknown load_time=unknown"
  fi
  
  return 0
}

# ------------------------
# Validation Framework
# ------------------------

# Validate function exists and is callable
zf_validate_function() {
  local func="$1"
  local module="${2:-validation}"
  
  if ! typeset -f "$func" >/dev/null 2>&1; then
    zf_err "$module" "required function '$func' not found"
    return 1
  fi
  
  return 0
}

# Validate command is available
zf_validate_command() {
  local cmd="$1"
  local module="${2:-validation}"
  local required="${3:-true}"
  
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$required" == "true" ]]; then
      zf_err "$module" "required command '$cmd' not found"
      return 1
    else
      zf_warn "$module" "optional command '$cmd' not found"
      return 2
    fi
  fi
  
  return 0
}

# Validate environment variable is set
zf_validate_env() {
  local var="$1"
  local module="${2:-validation}"
  local required="${3:-true}"
  
  if [[ -z "${(P)var:-}" ]]; then
    if [[ "$required" == "true" ]]; then
      zf_err "$module" "required environment variable '$var' not set"
      return 1
    else
      zf_warn "$module" "optional environment variable '$var' not set"
      return 2
    fi
  fi
  
  return 0
}

# Validate directory exists and is accessible
zf_validate_directory() {
  local dir="$1"
  local module="${2:-validation}"
  local create="${3:-false}"
  
  if [[ ! -d "$dir" ]]; then
    if [[ "$create" == "true" ]]; then
      if ! mkdir -p "$dir" 2>/dev/null; then
        zf_err "$module" "failed to create directory '$dir'"
        return 1
      fi
      zf_info "$module" "created directory '$dir'"
    else
      zf_err "$module" "required directory '$dir' not found"
      return 1
    fi
  fi
  
  if [[ ! -r "$dir" ]]; then
    zf_err "$module" "directory '$dir' not readable"
    return 1
  fi
  
  return 0
}

# ------------------------
# Recovery Mechanisms
# ------------------------

# Trigger automated recovery
zf_trigger_recovery() {
  local module="$1"
  local severity="$2"
  local message="$3"
  
  if [[ "$ZF_ERROR_RECOVERY_ENABLED" != "1" ]]; then
    return 0
  fi
  
  zf_info "recovery" "triggering recovery for module '$module' (severity: $severity)"
  
  # Generic recovery: mark module as degraded or failed
  local health_file
  health_file=$(get_module_health_file "$module")
  
  if [[ "$severity" == "FATAL" ]]; then
    echo "status=failed recovery_time=$(date +%s)" >> "$health_file"
  else
    echo "status=degraded recovery_time=$(date +%s)" >> "$health_file"
  fi
  
  zf_warn "recovery" "recovery applied to module '$module' (marked as degraded/failed)"
  return 0
}

# ------------------------
# Health Check System
# ------------------------

# Comprehensive health check
zf_health_check() {
  local module="${1:-all}"
  local verbose="${2:-false}"
  
  if [[ "$module" != "all" ]]; then
    # Single module check
    zf_module_health "$module"
    return 0
  fi
  
  # Check all modules with health files
  local total_modules=0
  local healthy_modules=0
  local issues=0
  
  # Use nullglob to handle case where no files match
  setopt local_options nullglob
  local health_files=(/tmp/zf_module_*_health)
  
  if (( ${#health_files[@]} == 0 )); then
    if [[ "$verbose" == "true" ]]; then
      print "[Health Check] No modules currently tracked"
    fi
    return 0
  fi
  
  for health_file in "${health_files[@]}"; do
    if [[ -f "$health_file" ]]; then
      (( total_modules++ ))
      
      local module_name
      module_name=$(basename "$health_file" | sed 's/zf_module_//;s/_health//')
      
      if [[ "$verbose" == "true" ]]; then
        zf_module_health "$module_name"
      fi
      
      local module_status
      module_status=$(grep '^status=' "$health_file" | tail -1 | cut -d= -f2)
      
      case "$module_status" in
        "success"|"recovered") (( healthy_modules++ )) ;;
        *) (( issues++ )) ;;
      esac
    fi
  done
  
  if [[ "$verbose" == "true" ]]; then
    print "\n[Health Summary] Total: $total_modules | Healthy: $healthy_modules | Issues: $issues"
  fi
  
  # Return status based on health
  if (( issues > 0 )); then
    return 1  # Some issues found
  else
    return 0  # All healthy or no modules tracked
  fi
}

# Test module registration for demonstration
zf_test_module_registration() {
  echo "Registering test module for demonstration..."
  zf_module_load_start "test-module"
  # Simulate some work
  sleep 0.1
  zf_module_load_complete "test-module" "success"
  echo "Test module registered successfully"
}

# Initialize error handling framework
zf_module_load_start "error-framework"
zf_info "error-framework" "error handling framework initialized"
zf_module_load_complete "error-framework" "success"
