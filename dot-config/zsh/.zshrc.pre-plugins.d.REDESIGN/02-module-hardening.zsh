# 02-module-hardening.zsh
# P1.1 Core Module Hardening - Module Wrapper and Validation
#
# PURPOSE:
#   Applies robust error handling and validation to existing core modules
#   without modifying their original implementations.

if [[ -n "${_LOADED_02_MODULE_HARDENING:-}" ]]; then
  return 0
fi
_LOADED_02_MODULE_HARDENING=1

# Ensure error handling framework is loaded
if [[ -z "${_LOADED_01_ERROR_HANDLING:-}" ]]; then
  print "[ERROR] Error handling framework not loaded - cannot proceed with module hardening" >&2
  return 1
fi

# ------------------------
# Module Hardening Registry
# ------------------------

declare -A ZF_HARDENED_MODULES
declare -A ZF_MODULE_DEPENDENCIES
declare -A ZF_ORIGINAL_FUNCTIONS
declare -a ZF_CRITICAL_FUNCTIONS

# Define critical functions that must be hardened
ZF_CRITICAL_FUNCTIONS=(
  "zf_log"
  "zf_warn"
  "zf_ensure_cmd"
  "zf_require"
  "zf_with_timing"
)

# Define module dependencies
ZF_MODULE_DEPENDENCIES["10-core-functions"]="00-security-integrity"
ZF_MODULE_DEPENDENCIES["20-essential-plugins"]="10-core-functions 00-security-integrity"
ZF_MODULE_DEPENDENCIES["30-development-env"]="10-core-functions"
ZF_MODULE_DEPENDENCIES["40-aliases-keybindings"]="10-core-functions"
ZF_MODULE_DEPENDENCIES["50-completion-history"]="10-core-functions 20-essential-plugins"

# ------------------------
# Function Hardening System
# ------------------------

# Create hardened wrapper for a function
zf_harden_function() {
  local func_name="$1"
  local module="${2:-unknown}"
  local timeout="${3:-5}"
  
  # Skip if already hardened
  if [[ -n "${ZF_ORIGINAL_FUNCTIONS[$func_name]:-}" ]]; then
    zf_debug "module-hardening" "function '$func_name' already hardened"
    return 0
  fi
  
  # Validate function exists
  if ! typeset -f "$func_name" >/dev/null 2>&1; then
    zf_warn "module-hardening" "cannot harden non-existent function: $func_name"
    return 1
  fi
  
  # Store original function
  local original_def
  original_def=$(typeset -f "$func_name")
  ZF_ORIGINAL_FUNCTIONS[$func_name]="$original_def"
  
  # Create hardened wrapper
  eval "
${func_name}_original() {
  ${original_def#*\{}
}

$func_name() {
  zf_execute_hardened '$func_name' '$module' $timeout \"\$@\"
}
"
  
  zf_info "module-hardening" "hardened function: $func_name"
  return 0
}

# Execute function with hardening
zf_execute_hardened() {
  local func_name="$1"
  local module="$2"
  local timeout="$3"
  shift 3
  
  # Execute with error handling
  local start_time result rc
  if [[ -n "${EPOCHREALTIME:-}" ]]; then
    start_time="$EPOCHREALTIME"
  else
    start_time="$(date +%s.%N 2>/dev/null || date +%s)"
  fi
  
  # Execute the function
  result=$("${func_name}_original" "$@" 2>&1)
  rc=$?
  
  local end_time elapsed_ms
  if [[ -n "${EPOCHREALTIME:-}" ]]; then
    end_time="$EPOCHREALTIME"
  else
    end_time="$(date +%s.%N 2>/dev/null || date +%s)"
  fi
  elapsed_ms=$(awk -v s="$start_time" -v e="$end_time" 'BEGIN{printf "%.0f", (e-s)*1000}')
  
  # Handle results
  if (( rc != 0 )); then
    zf_err "$module" "function '$func_name' failed" "exit_code=$rc elapsed=${elapsed_ms}ms"
    # Try fallback if available
    if typeset -f "${func_name}_fallback" >/dev/null 2>&1; then
      zf_info "$module" "attempting fallback for function: $func_name"
      "${func_name}_fallback" "$@"
      return $?
    fi
  elif (( elapsed_ms > 100 )); then
    zf_warn "$module" "function '$func_name' slow execution" "elapsed=${elapsed_ms}ms"
  fi
  
  # Output result if successful
  if (( rc == 0 )) && [[ -n "$result" ]]; then
    print -r -- "$result"
  fi
  
  return $rc
}

# ------------------------
# Module Dependency Validation
# ------------------------

# Validate module dependencies
zf_validate_module_dependencies() {
  local module="$1"
  local deps="${ZF_MODULE_DEPENDENCIES[$module]:-}"
  
  if [[ -z "$deps" ]]; then
    zf_debug "module-hardening" "no dependencies defined for module: $module"
    return 0
  fi
  
  local dep missing_deps=()
  for dep in ${=deps}; do
    local sentinel_var="_LOADED_${dep//-/_}"
    sentinel_var="${sentinel_var:u}"  # uppercase
    
    if [[ -z "${(P)sentinel_var:-}" ]]; then
      missing_deps+=("$dep")
    fi
  done
  
  if (( ${#missing_deps[@]} > 0 )); then
    zf_err "module-hardening" "missing dependencies for module '$module': ${missing_deps[*]}"
    return 1
  fi
  
  zf_debug "module-hardening" "all dependencies satisfied for module: $module"
  return 0
}

# ------------------------
# Module Monitoring System
# ------------------------

# Monitor module performance and health
zf_monitor_module() {
  local module="$1"
  local operation="${2:-load}"
  
  # Record monitoring data
  local timestamp=$(date +%s)
  local health_key="${module}_${operation}_${timestamp}"
  
  # Collect metrics
  local error_count="${ZF_MODULE_ERROR_COUNT[$module]:-0}"
  local load_time="${ZF_MODULE_LOAD_TIME[$module]:-unknown}"
  local health_status="${ZF_MODULE_HEALTH[$module]:-unknown}"
  
  # Export to performance monitoring if enabled
  if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
    print "MODULE_MONITOR module=$module operation=$operation errors=$error_count load_time=$load_time status=$health_status" >> "$PERF_SEGMENT_LOG" 2>/dev/null || true
  fi
  
  zf_debug "module-hardening" "monitored module '$module': errors=$error_count load_time=$load_time status=$health_status"
  return 0
}

# ------------------------
# Fallback Function Registry
# ------------------------

# Register fallback functions for critical operations
zf_register_fallbacks() {
  # Fallback for zf_log
  zf_log_fallback() {
    print "[zf-fallback] $*" >&2
  }
  
  # Fallback for zf_warn
  zf_warn_fallback() {
    print "[zf-warn-fallback] $*" >&2
  }
  
  # Fallback for zf_ensure_cmd
  zf_ensure_cmd_fallback() {
    local missing=0 c
    for c in "$@"; do
      command -v -- "$c" >/dev/null 2>&1 || missing=1
    done
    return $missing
  }
  
  # Fallback for zf_require
  zf_require_fallback() {
    local c="$1"
    command -v -- "$c" >/dev/null 2>&1
  }
  
  # Fallback for zf_with_timing
  zf_with_timing_fallback() {
    local seg="$1"; shift
    # Just execute without timing
    "$@"
  }
  
  zf_info "module-hardening" "fallback functions registered"
}

# ------------------------
# Automatic Hardening System
# ------------------------

# Apply hardening to critical functions
zf_apply_hardening() {
  local module="${1:-auto}"
  
  zf_info "module-hardening" "applying hardening (module: $module)"
  
  # Register fallbacks first
  zf_register_fallbacks
  
  # Harden critical functions
  local func
  for func in "${ZF_CRITICAL_FUNCTIONS[@]}"; do
    if typeset -f "$func" >/dev/null 2>&1; then
      zf_harden_function "$func" "$module" 5
    else
      zf_warn "module-hardening" "critical function not found: $func"
    fi
  done
  
  zf_info "module-hardening" "hardening applied to ${#ZF_CRITICAL_FUNCTIONS[@]} functions"
  return 0
}

# Remove hardening (for testing or emergency)
zf_remove_hardening() {
  local func
  for func in ${(k)ZF_ORIGINAL_FUNCTIONS}; do
    if [[ -n "${ZF_ORIGINAL_FUNCTIONS[$func]:-}" ]]; then
      eval "${ZF_ORIGINAL_FUNCTIONS[$func]}"
      unset "ZF_ORIGINAL_FUNCTIONS[$func]"
      zf_debug "module-hardening" "restored original function: $func"
    fi
  done
  
  zf_info "module-hardening" "hardening removed from ${#ZF_ORIGINAL_FUNCTIONS[@]} functions"
  ZF_ORIGINAL_FUNCTIONS=()
}

# ------------------------
# Health Check Integration
# ------------------------

# Check hardening system health
zf_hardening_health_check() {
  local issues=0
  
  # Check critical functions are available
  local func
  for func in "${ZF_CRITICAL_FUNCTIONS[@]}"; do
    if ! typeset -f "$func" >/dev/null 2>&1; then
      zf_err "hardening-health" "critical function missing: $func"
      (( issues++ ))
    fi
  done
  
  # Check fallbacks are available
  for func in "${ZF_CRITICAL_FUNCTIONS[@]}"; do
    if ! typeset -f "${func}_fallback" >/dev/null 2>&1; then
      zf_warn "hardening-health" "fallback function missing: ${func}_fallback"
      (( issues++ ))
    fi
  done
  
  # Check hardened functions
  local hardened_count=0
  for func in ${(k)ZF_ORIGINAL_FUNCTIONS}; do
    if typeset -f "${func}_original" >/dev/null 2>&1; then
      (( hardened_count++ ))
    else
      zf_err "hardening-health" "hardened function missing original: ${func}_original"
      (( issues++ ))
    fi
  done
  
  if (( issues == 0 )); then
    zf_info "hardening-health" "hardening system healthy (${hardened_count} functions hardened)"
    return 0
  else
    zf_err "hardening-health" "hardening system has $issues issues"
    return 1
  fi
}

# ------------------------
# Integration Points
# ------------------------

# Hook for module loading
zf_pre_module_load_hook() {
  local module="$1"
  zf_validate_module_dependencies "$module"
  zf_module_load_start "$module"
}

# Hook for module loaded
zf_post_module_load_hook() {
  local module="$1"
  local status="${2:-success}"
  zf_module_load_complete "$module" "$status"
  zf_monitor_module "$module" "load"
}

# Initialize module hardening
zf_info "module-hardening" "module hardening system initialized"
