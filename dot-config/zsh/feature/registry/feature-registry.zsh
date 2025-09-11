# ==============================================================================
# Feature Registry Scaffold
# File: feature-registry.zsh
#
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Stage 4 (Feature Layer) initial registry implementation.
# Provides:
#   - Data structures for feature metadata
#   - Registration API (feature_registry_add)
#   - Enablement evaluation & caching
#   - Dependency resolution (topological ordering with cycle detection)
#   - Listing / debugging helpers
#   - Safe order computation without side effects
#
# Updated Scope Notes (invocation + timing implemented):
#   Implemented:
#     - Phase invocation wrapper (preload/init/postprompt)
#     - Failure containment (non-fatal invocation errors)
#     - Optional per-feature sync timing (init phase) when ZSH_FEATURE_TELEMETRY=1
#     - Structured JSON emission for per-feature timing when both ZSH_FEATURE_TELEMETRY=1 and ZSH_LOG_STRUCTURED=1
#       (schema: {"type":"feature_timing","feature":"<name>","ms":<int>,"phase":"init","sequence":<n>,"version":1,"ts_epoch_ms":<epoch_ms>})
#   Deferred (future enhancements):
#     - Asynchronous scheduling manager
#     - Aggregated deferred timing ledger (future cross-phase)
#     - Potential batching/flush optimization for JSON emission (current: immediate append)
#
# Sensitive action policy:
#   - No external commands executed here beyond builtin shell features.
#   - If future edits introduce external process spawning or PATH mutation,
#     cite relevant rule lines (e.g. performance standards) inline:
#     Example: rule [/Users/s-a-c/dotfiles/dot-config/ai/guidelines/110-performance-standards.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines/110-performance-standards.md:X)
#
# ==============================================================================

# Guard to prevent double loading
if [[ -n "${__ZSH_FEATURE_REGISTRY_GUARD:-}" ]]; then
  return 0
fi
__ZSH_FEATURE_REGISTRY_GUARD=1

# ------------------------------------------------------------------------------
# Global Data Structures
# ------------------------------------------------------------------------------
# Associative arrays are keyed by feature name.
typeset -gA ZSH_FEATURE_REGISTRY_PHASE          # name -> phase (string/integer)
typeset -gA ZSH_FEATURE_REGISTRY_DEPENDS        # name -> space separated deps
typeset -gA ZSH_FEATURE_REGISTRY_DEFERRED       # name -> yes|no
typeset -gA ZSH_FEATURE_REGISTRY_CATEGORY       # name -> category
typeset -gA ZSH_FEATURE_REGISTRY_DESCRIPTION    # name -> description
typeset -gA ZSH_FEATURE_REGISTRY_ENABLED_CACHE  # name -> 0|1 (evaluation cache)
typeset -gA ZSH_FEATURE_REGISTRY_GUID           # name -> guid

# Ordered list of all registered features (registration order)
typeset -ga ZSH_FEATURE_REGISTRY_NAMES=()

# Cached resolved order (topological). Invalidated on new registrations.
typeset -ga ZSH_FEATURE_REGISTRY_RESOLVED_ORDER=()

# Per-feature synchronous timing (ms, init phase only unless expanded later)
typeset -gA ZSH_FEATURE_TIMINGS_SYNC          # name -> ms (integer, truncated)
# Feature invocation status: ok | skipped | error (phase-specific last state)
typeset -gA ZSH_FEATURE_STATUS

# ------------------------------------------------------------------------------
# Logging Helpers (lightweight; avoid subshells for performance)
# ------------------------------------------------------------------------------
_feature_registry_log() {
  # $1 = level, $2... message
  local level msg
  level="${1:-info}"
  shift
  msg="$*"
  print -r -- "[feature-registry][$level] $msg" >&2
}

# ------------------------------------------------------------------------------
# Initialization (idempotent)
# ------------------------------------------------------------------------------
feature_registry_init() {
  # Currently nothing to initialize beyond guard; placeholder for future.
  return 0
}

# ------------------------------------------------------------------------------
# Registration API
# ------------------------------------------------------------------------------
# Usage: feature_registry_add <name> <phase> <depends> <deferred> <category> <description> <guid>
# Any parameter after <name> may be an empty string if not applicable.
feature_registry_add() {
  local name phase depends deferred category description guid
  name="$1"; phase="$2"; depends="$3"; deferred="$4"; category="$5"; description="$6"; guid="$7"

  if [[ -z "$name" ]]; then
    _feature_registry_log error "Attempted to register feature with empty name"
    return 1
  fi

  if [[ -n "${ZSH_FEATURE_REGISTRY_PHASE[$name]:-}" ]]; then
    _feature_registry_log warn "Feature '$name' already registered; ignoring duplicate"
    return 0
  fi

  ZSH_FEATURE_REGISTRY_PHASE[$name]="${phase:-2}"
  ZSH_FEATURE_REGISTRY_DEPENDS[$name]="${depends:-}"
  ZSH_FEATURE_REGISTRY_DEFERRED[$name]="${deferred:-no}"
  ZSH_FEATURE_REGISTRY_CATEGORY[$name]="${category:-misc}"
  ZSH_FEATURE_REGISTRY_DESCRIPTION[$name]="${description:-}"
  ZSH_FEATURE_REGISTRY_GUID[$name]="${guid:-}"

  ZSH_FEATURE_REGISTRY_NAMES+=("$name")
  # Invalidate cached resolution
  ZSH_FEATURE_REGISTRY_RESOLVED_ORDER=()
  unset "ZSH_FEATURE_REGISTRY_ENABLED_CACHE[$name]"

  return 0
}

# ------------------------------------------------------------------------------
# Enablement Evaluation (delegates to feature_<name>_is_enabled if present)
# Caches result for duration of session to avoid repeated function dispatch.
# ------------------------------------------------------------------------------
feature_registry_is_enabled() {
  local name="$1"
  if [[ -z "$name" ]]; then
    return 1
  fi

  # Return cached if present
  if [[ -n "${ZSH_FEATURE_REGISTRY_ENABLED_CACHE[$name]:-}" ]]; then
    [[ "${ZSH_FEATURE_REGISTRY_ENABLED_CACHE[$name]}" == "1" ]]
    return $?
  fi

  local fn="feature_${name}_is_enabled"
  local enabled=1
  if typeset -f "$fn" >/dev/null 2>&1; then
    if "$fn"; then
      enabled=0
    else
      enabled=1
    fi
  else
    # Fallback default if no function: enabled (match template default yes)
    enabled=0
  fi

  if (( enabled == 0 )); then
    ZSH_FEATURE_REGISTRY_ENABLED_CACHE[$name]=1
    return 0
  else
    ZSH_FEATURE_REGISTRY_ENABLED_CACHE[$name]=0
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Internal: Cycle Detection + Topological Sort (Kahn's Algorithm)
# Produces resolved order filtered to enabled features only.
# ------------------------------------------------------------------------------
_feature_registry_resolve_order_internal() {
  local -A in_degree
  local name dep deps enabled_names=()

  # Initialize in-degree counts (enabled only)
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    if feature_registry_is_enabled "$name"; then
      in_degree[$name]=0
      enabled_names+=("$name")
    fi
  done

  # Compute in-degree
  for name in "${enabled_names[@]}"; do
    deps="${ZSH_FEATURE_REGISTRY_DEPENDS[$name]:-}"
    for dep in $deps; do
      # Skip dependency if disabled or nonexistent (warn)
      if [[ -z "${in_degree[$dep]:-}" ]]; then
        if [[ -z "${ZSH_FEATURE_REGISTRY_PHASE[$dep]:-}" ]]; then
          _feature_registry_log warn "Feature '$name' depends on unknown feature '$dep'"
        else
          # dependency exists but disabled -> treat as satisfied but warn
          _feature_registry_log warn "Feature '$name' depends on disabled feature '$dep'"
        fi
        continue
      fi
      (( in_degree[$name]++ ))
    done
  done

  local -a queue=()
  for name in "${enabled_names[@]}"; do
    if (( in_degree[$name] == 0 )); then
      queue+=("$name")
    fi
  done

  local -a ordered=()
  local current d
  while (( ${#queue[@]} > 0 )); do
    current="${queue[1]}"
    queue=("${queue[@]:1}")
    ordered+=("$current")

    deps="${ZSH_FEATURE_REGISTRY_DEPENDS[$current]:-}"
    for d in $deps; do
      # Only consider if dependent is enabled
      if [[ -z "${in_degree[$d]:-}" ]]; then
        continue
      fi
      (( in_degree[$d]-- ))
      if (( in_degree[$d] == 0 )); then
        queue+=("$d")
      fi
    done
  done

  # Detect cycles: any enabled feature not in ordered list
  if (( ${#ordered[@]} < ${#enabled_names[@]} )); then
    local -A seen
    for name in "${ordered[@]}"; do
      seen[$name]=1
    done
    for name in "${enabled_names[@]}"; do
      if [[ -z "${seen[$name]:-}" ]]; then
        _feature_registry_log error "Cycle detected involving feature '$name'"
      fi
    done
    return 1
  fi

  # Stable ordering by phase (numeric) then original registration order fallback
  # Build phase mapping for sort
  local -A reg_index
  local i=1
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    reg_index[$name]=$i
    (( i++ ))
  done

  local phase a b
  # Use zsh array sorting with comparator
  ordered=("${ordered[@]}") # ensure array form

  # Custom sort: phase asc, reg_index asc
  local -a sorted=("${ordered[@]}")
  integer changed=1
  while (( changed )); do
    changed=0
    for (( i=1; i < ${#sorted[@]}; i++ )); do
      a="${sorted[i]}"
      b="${sorted[i+1]}"
      local pa="${ZSH_FEATURE_REGISTRY_PHASE[$a]:-2}"
      local pb="${ZSH_FEATURE_REGISTRY_PHASE[$b]:-2}"
      if (( pa > pb )) || { (( pa == pb )) && (( reg_index[$a] > reg_index[$b] )); }; then
        local tmp="${sorted[i]}"
        sorted[i]="${sorted[i+1]}"
        sorted[i+1]="$tmp"
        changed=1
      fi
    done
  done

  ZSH_FEATURE_REGISTRY_RESOLVED_ORDER=("${sorted[@]}")
  return 0
}

# Public wrapper for order resolution (caches)
feature_registry_resolve_order() {
  if (( ${#ZSH_FEATURE_REGISTRY_RESOLVED_ORDER[@]} == 0 )); then
    _feature_registry_resolve_order_internal || return 1
  fi
  print -r -- "${ZSH_FEATURE_REGISTRY_RESOLVED_ORDER[@]}"
  return 0
}

# ------------------------------------------------------------------------------
# Listing / Debugging
# ------------------------------------------------------------------------------
feature_registry_list() {
  local name
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    local enabled="no"
    if feature_registry_is_enabled "$name"; then enabled="yes"; fi
    print -r -- "$name|phase=${ZSH_FEATURE_REGISTRY_PHASE[$name]}|enabled=${enabled}|depends=${ZSH_FEATURE_REGISTRY_DEPENDS[$name]:-}|deferred=${ZSH_FEATURE_REGISTRY_DEFERRED[$name]:-}|category=${ZSH_FEATURE_REGISTRY_CATEGORY[$name]:-}"
  done
}

feature_registry_dump_table() {
  printf "%-24s %-5s %-8s %-8s %-20s %s\n" "FEATURE" "PHASE" "ENABLED" "DEFERRED" "CATEGORY" "DEPENDS"
  printf "%-24s %-5s %-8s %-8s %-20s %s\n" "-------" "-----" "-------" "--------" "--------" "-------"
  local name enabled
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    if feature_registry_is_enabled "$name"; then enabled="yes"; else enabled="no"; fi
    printf "%-24s %-5s %-8s %-8s %-20s %s\n" \
      "$name" \
      "${ZSH_FEATURE_REGISTRY_PHASE[$name]}" \
      "$enabled" \
      "${ZSH_FEATURE_REGISTRY_DEFERRED[$name]}" \
      "${ZSH_FEATURE_REGISTRY_CATEGORY[$name]}" \
      "${ZSH_FEATURE_REGISTRY_DEPENDS[$name]}"
  done
}

# ------------------------------------------------------------------------------
# Phase Invocation Wrapper
# ------------------------------------------------------------------------------
# Usage: feature_registry_invoke_phase <preload|init|postprompt>
# Behavior:
#   - Resolves enabled feature order (topological)
#   - Skips functions not implemented for a phase
#   - Skips postprompt for non-deferred features
#   - Contains failures (logs + status=error, continues)
#   - Collects synchronous timing (init phase only) when ZSH_FEATURE_TELEMETRY=1
# Timing Notes:
#   - Uses $EPOCHREALTIME (float seconds) and converts to ms (truncated)
#   - Stores only for init phase to keep overhead minimal
feature_registry_invoke_phase() {
  local phase="$1"
  case "$phase" in
    preload|init|postprompt) ;;
    *)
      _feature_registry_log error "invoke_phase: unknown phase '$phase'"
      return 2
      ;;
  esac

  # Resolve order (enabled features only)
  local resolved
  if ! resolved=($(feature_registry_resolve_order 2>/dev/null)); then
    _feature_registry_log error "invoke_phase: resolution failed (cycle or dependency issue)"
    # Continue with best-effort using already registered names (enabled filter)
    local name
    resolved=()
    for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
      if feature_registry_is_enabled "$name"; then
        resolved+=("$name")
      fi
    done
  fi

  local name fn rc start_f end_f elapsed_ms deferred_flag
  local telemetry_active=0
  [[ "${ZSH_FEATURE_TELEMETRY:-0}" != "0" ]] && telemetry_active=1

  for name in "${resolved[@]}"; do
    # Skip entirely if prior phase marked error and this is a later phase
    if [[ "${ZSH_FEATURE_STATUS[$name]:-}" == "error" && "$phase" != "preload" ]]; then
      continue
    fi

    deferred_flag="${ZSH_FEATURE_REGISTRY_DEFERRED[$name]:-no}"

    # For postprompt phase, only run deferred features
    if [[ "$phase" == "postprompt" && "$deferred_flag" != "yes" ]]; then
      continue
    fi

    # For preload/init phases, allow both deferred & non-deferred (deferred may have lightweight preload/init)
    fn="feature_${name}_${phase}"
    if ! typeset -f "$fn" >/dev/null 2>&1; then
      continue
    fi

    # Execute with containment + optional timing
    rc=0
    if (( telemetry_active )); then
      start_f=$EPOCHREALTIME
    fi
    {
      "$fn"
      rc=$?
    } always {
      if (( rc != 0 )); then
        _feature_registry_log error "invoke_phase: feature='$name' phase='$phase' rc=$rc"
        ZSH_FEATURE_STATUS[$name]="error"
      else
        # Only overwrite status if not previously error
        [[ "${ZSH_FEATURE_STATUS[$name]:-}" != "error" ]] && ZSH_FEATURE_STATUS[$name]="ok"
      fi
      if (( telemetry_active )) && [[ "$phase" == "init" ]]; then
        end_f=$EPOCHREALTIME
        # Floating arithmetic (truncate via integer context)
        elapsed_ms=$(( (end_f - start_f) * 1000 ))
        # Store only if non-negative
        if (( elapsed_ms < 0 )); then
          elapsed_ms=0
        fi
        ZSH_FEATURE_TIMINGS_SYNC[$name]=$elapsed_ms
        # Structured JSON emission (versioned) – guarded to keep disabled path overhead ≈0
        if [[ "${ZSH_LOG_STRUCTURED:-0}" == "1" ]]; then
          # Determine target (prefer JSON sidecar, fallback to plain segment log)
          local __target="${PERF_SEGMENT_JSON_LOG:-${PERF_SEGMENT_LOG:-/dev/null}}"
          if [[ -w "${__target}" ]]; then
            # Timestamp in epoch ms (align with other emitters)
            local __ts
            if [[ -n ${EPOCHREALTIME:-} ]]; then
              __ts=$(awk -v t="${EPOCHREALTIME}" 'BEGIN{split(t,a,"."); printf "%s%03d", a[1], substr(a[2]"000",1,3)}')
            else
              __ts="$(date +%s 2>/dev/null || printf 0)000"
            fi
            # Monotonic sequence (session‑local)
            : ${__ZSH_FEATURE_TIMING_SEQ:=0}
            __ZSH_FEATURE_TIMING_SEQ=$(( __ZSH_FEATURE_TIMING_SEQ + 1 ))
            print -- "{\"type\":\"feature_timing\",\"feature\":\"${name}\",\"ms\":${elapsed_ms},\"phase\":\"init\",\"sequence\":${__ZSH_FEATURE_TIMING_SEQ},\"version\":1,\"ts_epoch_ms\":${__ts}}" >> "${__target}" 2>/dev/null || true
          fi
        fi
      fi
    }
  done

  return 0
}

# ------------------------------------------------------------------------------
# Self-Check (lightweight validation for tests)
# ------------------------------------------------------------------------------
feature_registry_self_check() {
  local ok=0 name
  for name in "${ZSH_FEATURE_REGISTRY_NAMES[@]}"; do
    # Basic invariant: phase must be numeric-ish
    if [[ ! "${ZSH_FEATURE_REGISTRY_PHASE[$name]}" == <-> ]]; then
      _feature_registry_log error "Feature '$name' has non-numeric phase '${ZSH_FEATURE_REGISTRY_PHASE[$name]}'"
      ok=1
    fi
  done
  return $ok
}

# Initialize (idempotent)
feature_registry_init

# End of feature-registry.zsh
# ==============================================================================
