#!/opt/homebrew/bin/zsh
# 02-module-hardening.zsh
# P1.1 Core Module Hardening - Module Wrapper and Validation
# Compliant with /Users/s-a-c/dotfiles/dot-config/ai/guidelines.md v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Applies robust error handling and validation to existing core modules
#   without modifying their original implementations.
#
# COMPATIBILITY: zsh 5.9+ (/opt/homebrew/bin/zsh)

if [[ -n "${_LOADED_02_MODULE_HARDENING:-}" ]]; then
  return 0
fi
_LOADED_02_MODULE_HARDENING=1

# Ensure error handling framework is loaded
# Accept either legacy sentinel (_LOADED_01_ERROR_HANDLING) or the framework sentinel (_LOADED_01_ERROR_HANDLING_FRAMEWORK)
if [[ -z "${_LOADED_01_ERROR_HANDLING:-${_LOADED_01_ERROR_HANDLING_FRAMEWORK:-}}" ]]; then
  print "[ERROR] Error handling framework not loaded - cannot proceed with module hardening" >&2
  return 1
fi

# ------------------------
# Module Hardening Registry
# ------------------------

typeset -gA ZF_HARDENED_MODULES
typeset -gA ZF_MODULE_DEPENDENCIES
typeset -gA ZF_ORIGINAL_FUNCTIONS
typeset -ga ZF_CRITICAL_FUNCTIONS

# Define critical functions that must be hardened
ZF_CRITICAL_FUNCTIONS=(
  "zf::log"
  "zf::warn"
  "zf::ensure_cmd"
  "zf::require"
  "zf::with_timing"
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
    zf::debug "module-hardening" "function '$func_name' already hardened"
    return 0
  fi

  # Validate function exists
  if ! typeset -f "$func_name" >/dev/null 2>&1; then
    zf::warn "module-hardening" "cannot harden non-existent function: $func_name"
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

  zf::info "module-hardening" "hardened function: $func_name"
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
    zf::err "$module" "function '$func_name' failed" "exit_code=$rc elapsed=${elapsed_ms}ms"
    # Try fallback if available
    if typeset -f "${func_name}_fallback" >/dev/null 2>&1; then
      zf::info "$module" "attempting fallback for function: $func_name"
      "${func_name}_fallback" "$@"
      return $?
    fi
  elif (( elapsed_ms > 100 )); then
    zf::warn "$module" "function '$func_name' slow execution" "elapsed=${elapsed_ms}ms"
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

  # Debug: raw deps string
  if [[ -n "${ZF_DEP_DEBUG:-}" ]]; then
    print "[dep-debug] module=${module} deps_raw='${deps}'" >&2
  fi

  if [[ -z "$deps" ]]; then
    zf::debug "module-hardening" "no dependencies defined for module: $module"
    return 0
  fi

  # Disabled module list (tests may pre-populate); define if absent
  typeset -ga ZF_DISABLED_MODULES
  : ${ZF_DEPENDENCY_WARN_ON_DISABLED:=0}

  local dep
  local -a missing_deps disabled_deps
  missing_deps=()
  disabled_deps=()

  for dep in ${=deps}; do
    # If explicitly disabled, treat as skipped (optionally warn) and continue
    if (( ${ZF_DISABLED_MODULES[(Ie)$dep]} )); then
      disabled_deps+=("$dep")
      if [[ "${ZF_DEPENDENCY_WARN_ON_DISABLED}" == "1" ]]; then
        zf::warn "module-hardening" "dependency '$dep' disabled (module='$module')"
      else
        zf::debug "module-hardening" "dependency '$dep' disabled (suppressed warning)"
      fi
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[dep-debug] dep=${dep} reason=disabled" >&2
      continue
    fi

    local sentinel_var="_LOADED_${dep//-/_}"
    # Normalize to uppercase (portable uppercase expansion for current zsh)
    sentinel_var="${(U)sentinel_var}"  # uppercase

    # Use existence test via typeset -p (indirection flags may be limited in some environments)
    if ! typeset -p "${sentinel_var}" >/dev/null 2>&1; then
      missing_deps+=("$dep")
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[dep-debug] dep=${dep} sentinel=${sentinel_var} status=MISSING" >&2
    else
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[dep-debug] dep=${dep} sentinel=${sentinel_var} status=present" >&2
    fi
  done

  [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[dep-debug] module=${module} missing_deps=(${missing_deps[*]:-}) disabled=(${disabled_deps[*]:-})" >&2

  if (( ${#missing_deps[@]} > 0 )); then
    zf::err "module-hardening" "missing dependencies for module '$module': ${missing_deps[*]}"
    return 1
  fi

  zf::debug "module-hardening" "all dependencies satisfied for module: $module (disabled=${disabled_deps[*]:-none})"
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

  zf::debug "module-hardening" "monitored module '$module': errors=$error_count load_time=$load_time status=$health_status"
  return 0
}

# ------------------------
# Fallback Function Registry
# ------------------------

# Register fallback functions for critical operations
zf_register_fallbacks() {
  # Fallbacks for namespaced critical functions (underscore wrappers removed)
  # zf::log
  zf::log_fallback() {
    print "[zf-fallback] $*" >&2
  }

  # zf::warn
  zf::warn_fallback() {
    print "[zf-warn-fallback] $*" >&2
  }

  # zf::ensure_cmd
  zf::ensure_cmd_fallback() {
    local missing=0 c
    for c in "$@"; do
      command -v -- "$c" >/dev/null 2>&1 || missing=1
    done
    return $missing
  }

  # zf::require
  zf::require_fallback() {
    local c="$1"
    command -v -- "$c" >/dev/null 2>&1
  }

  # zf::with_timing (no timing when falling back)
  zf::with_timing_fallback() {
    local seg="$1"; shift
    "$@"
  }

  zf::info "module-hardening" "fallback functions registered"
}

# ------------------------
# Automatic Hardening System
# ------------------------

# Apply hardening to critical functions
zf_apply_hardening() {
  local module="${1:-auto}"

  zf::info "module-hardening" "applying hardening (module: $module)"

  # Register fallbacks first
  zf_register_fallbacks

  # Harden critical functions
  local func
  for func in "${ZF_CRITICAL_FUNCTIONS[@]}"; do
    if typeset -f "$func" >/dev/null 2>&1; then
      zf_harden_function "$func" "$module" 5
    else
      zf::warn "module-hardening" "critical function not found: $func"
    fi
  done

  zf::info "module-hardening" "hardening applied to ${#ZF_CRITICAL_FUNCTIONS[@]} functions"
  return 0
}

# Remove hardening (for testing or emergency)
zf_remove_hardening() {
  local func
  for func in ${(k)ZF_ORIGINAL_FUNCTIONS}; do
    if [[ -n "${ZF_ORIGINAL_FUNCTIONS[$func]:-}" ]]; then
      eval "${ZF_ORIGINAL_FUNCTIONS[$func]}"
      unset "ZF_ORIGINAL_FUNCTIONS[$func]"
      zf::debug "module-hardening" "restored original function: $func"
    fi
  done

  zf::info "module-hardening" "hardening removed from ${#ZF_ORIGINAL_FUNCTIONS[@]} functions"
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
      zf::err "hardening-health" "critical function missing: $func"
      (( issues++ ))
    fi
  done

  # Check fallbacks are available
  for func in "${ZF_CRITICAL_FUNCTIONS[@]}"; do
    if ! typeset -f "${func}_fallback" >/dev/null 2>&1; then
      zf::warn "hardening-health" "fallback function missing: ${func}_fallback"
      (( issues++ ))
    fi
  done

  # Check hardened functions
  local hardened_count=0
  for func in ${(k)ZF_ORIGINAL_FUNCTIONS}; do
    if typeset -f "${func}_original" >/dev/null 2>&1; then
      (( hardened_count++ ))
    else
      zf::err "hardening-health" "hardened function missing original: ${func}_original"
      (( issues++ ))
    fi
  done

  if (( issues == 0 )); then
    zf::info "hardening-health" "hardening system healthy (${hardened_count} functions hardened)"
    return 0
  else
    zf::err "hardening-health" "hardening system has $issues issues"
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
zf::info "module-hardening" "module hardening system initialized"

# -----------------------------------------------------------------------------
# Dependency Cycle Detection (Stage 4 addition)
# -----------------------------------------------------------------------------
# Detect cycles in ZF_MODULE_DEPENDENCIES (excluding disabled modules unless
# ZF_CYCLE_DETECT_INCLUDE_DISABLED=1). Intended for test harness invocation.
#
# Returns:
#   0 - no cycles
#   1 - one or more cycles detected
#
# Emits:
#   zf::err lines: "dependency-cycle: A->B->C->A"
#
zf_detect_module_dependency_cycles() {
  # Helper inserted (was previously missing when early references occurred)
  __cycle_is_disabled() {
    local m="$1"
    (( ${ZF_DISABLED_MODULES[(Ie)$m]} )) && return 0
    return 1
  }
  # Preserve externally provided ZF_DISABLED_MODULES (only define if unset)
  if ! typeset -p ZF_DISABLED_MODULES >/dev/null 2>&1; then
    typeset -ga ZF_DISABLED_MODULES
  fi
  : ${ZF_CYCLE_DETECT_INCLUDE_DISABLED:=0}

  local -A _color        # node => white|gray|black (unset means white)
  local -A _parent       # node => parent
  local -a _cycles       # collected cycle strings

  # Build node universe: keys plus referenced deps
  local k v token
  local -A _universe

  # Optional scope limiting: if ZF_CYCLE_SCOPE (array) is defined & non-empty,
  # only modules present in that scope are considered for cycle analysis.
  # This enables tests to isolate synthetic graphs without interference
  # from baseline dependency declarations.
  if [[ -n "${ZF_CYCLE_SCOPE+x}" && ${#ZF_CYCLE_SCOPE[@]} -gt 0 ]]; then
    : ${ZF_DEP_DEBUG:=}  # ensure var defined for conditional prints
  fi

  # Build universe excluding disabled nodes unless explicitly included
  for k in ${(k)ZF_MODULE_DEPENDENCIES}; do
    if [[ -n "${ZF_CYCLE_SCOPE+x}" && ${#ZF_CYCLE_SCOPE[@]} -gt 0 ]]; then
      if ! (( ${ZF_CYCLE_SCOPE[(Ie)$k]} )); then
        [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_root_out_of_scope k=$k" >&2
        continue
      fi
    fi
    if __cycle_is_disabled "$k" && [[ "${ZF_CYCLE_DETECT_INCLUDE_DISABLED}" != "1" ]]; then
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_root_disabled k=$k" >&2
      continue
    fi
    _universe[$k]=1
    for token in ${=ZF_MODULE_DEPENDENCIES[$k]}; do
      if [[ -n "${ZF_CYCLE_SCOPE+x}" && ${#ZF_CYCLE_SCOPE[@]} -gt 0 ]]; then
        if ! (( ${ZF_CYCLE_SCOPE[(Ie)$token]} )); then
          [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_dep_out_of_scope parent=$k dep=$token" >&2
          continue
        fi
      fi
      if __cycle_is_disabled "$token" && [[ "${ZF_CYCLE_DETECT_INCLUDE_DISABLED}" != "1" ]]; then
        [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_dep_disabled parent=$k dep=$token" >&2
        continue
      fi
      _universe[$token]=1
    done
  done
  [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] universe=(${(k)_universe}) disabled=(${ZF_DISABLED_MODULES[*]:-}) include_disabled=${ZF_CYCLE_DETECT_INCLUDE_DISABLED}" >&2

  # If universe empty, nothing to do
  (( ${#_universe[@]} == 0 )) && return 0

  # Helper: check disabled
  __cycle_is_disabled() {
    local m="$1"
    (( ${ZF_DISABLED_MODULES[(Ie)$m]} )) || return 1
    return 0
  }

  local dfs
  dfs() {
    local node="$1"
    _color[$node]="gray"

    local dep
    for dep in ${=ZF_MODULE_DEPENDENCIES[$node]:-}; do
      # Skip disabled unless include flag set
      if __cycle_is_disabled "$dep" && [[ "${ZF_CYCLE_DETECT_INCLUDE_DISABLED}" != "1" ]]; then
        [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_edge node=$node dep=$dep (disabled)" >&2
        continue
      fi
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] edge node=$node dep=$dep color_dep=${_color[$dep]:-white}" >&2

      # Skip if dep disabled and not included
      if [[ -z ${_color[$dep]:-} ]]; then
        _parent[$dep]="$node"
        dfs "$dep"
      elif [[ ${_color[$dep]} == "gray" ]]; then
        # Cycle found – reconstruct path dep -> node -> ... -> dep
        local path=("$dep")
        local cur="$node"
        while [[ "$cur" != "$dep" && -n "$cur" ]]; do
          path+=("$cur")
          cur="${_parent[$cur]:-}"
        done
        path+=("$dep")
        # Reverse order to display cycle starting at first occurrence
        local -a rev
        local i
        for (( i=${#path[@]}-1; i>=0; i-- )); do
          rev+=("${path[$i]}")
        done
        [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] cycle_detected path=${rev[*]}" >&2
        _cycles+=("${(j:->:)rev}")
      fi
    done

    _color[$node]="black"
  }

  # Traverse
  for k in ${(k)_universe}; do
    # Skip disabled roots (unless include)
    if __cycle_is_disabled "$k" && [[ "${ZF_CYCLE_DETECT_INCLUDE_DISABLED}" != "1" ]]; then
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] skip_traverse_root k=$k (disabled)" >&2
      continue
    fi
    if [[ -z ${_color[$k]:-} ]]; then
      [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] traverse_root k=$k" >&2
      dfs "$k"
    fi
  done

  if (( ${#_cycles[@]} > 0 )); then
    local c
    for c in "${_cycles[@]}"; do
      zf::err "module-hardening" "dependency-cycle: $c"
    done
    return 1
  fi

  [[ -n "${ZF_DEP_DEBUG:-}" ]] && print "[cycle-debug] no_cycles modules=${#_universe[@]} color_count=${#_color[@]}" >&2
  zf::debug "module-hardening" "dependency-cycle-scan clean (modules=${#_universe[@]})"
  return 0
}

# Optional automatic cycle scan on load (disabled by default)
if [[ "${ZF_CHECK_CYCLES_ON_LOAD:-0}" == "1" ]]; then
  zf_detect_module_dependency_cycles || true
fi
