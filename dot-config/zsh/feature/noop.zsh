# ==============================================================================
# Noop Feature Module
# File: noop.zsh
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Minimal demonstration feature implementing the Stage 4 feature contract.
#   Provides a stable exemplar for tests (registration, enable/disable semantics,
#   failure injection, self-check) with negligible performance impact.
#
# Policy Notes:
#   - No external processes are spawned.
#   - No PATH or environment mutation outside the feature's namespace.
#   - All side effects are deferred until feature_noop_init executes.
#
# Sensitive Actions: None in this module.
# ==============================================================================

# Guard to prevent multiple sourcing
if [[ -n "${__ZSH_FEATURE_NOOP_GUARD:-}" ]]; then
  return 0
fi
__ZSH_FEATURE_NOOP_GUARD=1

# ------------------------------------------------------------------------------
# Metadata (single-line assignments for grep extraction)
# ------------------------------------------------------------------------------
FEATURE_NAME="noop"
FEATURE_VERSION="0.1.0"
FEATURE_PHASE="1"
FEATURE_DEPENDS=""
FEATURE_DEFAULT_ENABLED="yes"
FEATURE_DEFERRED="no"
FEATURE_DESCRIPTION="Baseline no-op feature (contract exemplar)"
FEATURE_CATEGORY="misc"
FEATURE_SINCE_STAGE="4"
FEATURE_GUID="a4c4d4c0-0fa0-4a9a-9e2a-58d5c9e9b6fd"

# Internal namespace prefix (not exported)
__feature_noop_ns="__feature_${FEATURE_NAME}"

# Internal state flags
typeset -g __feature_noop_registered=0
typeset -g __feature_noop_initialized=0
typeset -g __feature_noop_postprompt_ran=0

# ------------------------------------------------------------------------------
# Helper: truthy evaluation
# ------------------------------------------------------------------------------
_feature_noop_bool() {
  case "${1:-}" in
    1|true|yes|on|enable|enabled) return 0 ;;
    0|false|no|off|disable|disabled|"") return 1 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------------------------
# Required Contract: Metadata
# ------------------------------------------------------------------------------
feature_noop_metadata() {
  cat <<EOF
name=${FEATURE_NAME}
version=${FEATURE_VERSION}
phase=${FEATURE_PHASE}
depends=${FEATURE_DEPENDS}
default_enabled=${FEATURE_DEFAULT_ENABLED}
deferred=${FEATURE_DEFERRED}
description=${FEATURE_DESCRIPTION}
category=${FEATURE_CATEGORY}
since_stage=${FEATURE_SINCE_STAGE}
guid=${FEATURE_GUID}
EOF
}

# ------------------------------------------------------------------------------
# Required Contract: Enablement
# Precedence:
#  1. Global disable sentinel (ZSH_FEATURES_DISABLE contains 'all')
#  2. Per-feature override var: ZSH_FEATURE_NOOP_ENABLED
#  3. ZSH_FEATURES_DISABLE list membership
#  4. ZSH_FEATURES_ENABLE list membership
#  5. FEATURE_DEFAULT_ENABLED
# ------------------------------------------------------------------------------
feature_noop_is_enabled() {
  # Global disable-all sentinel
  if [[ "${ZSH_FEATURES_DISABLE:-}" == *"all"* ]]; then
    return 1
  fi

  # Per-feature explicit override
  if typeset -p ZSH_FEATURE_NOOP_ENABLED >/dev/null 2>&1; then
    if _feature_noop_bool "${ZSH_FEATURE_NOOP_ENABLED}"; then
      return 0
    else
      return 1
    fi
  fi

  # Explicit disable list
  if [[ -n "${ZSH_FEATURES_DISABLE:-}" ]]; then
    if [[ " ${ZSH_FEATURES_DISABLE//,/ } " == *" ${FEATURE_NAME} "* ]]; then
      return 1
    fi
  fi

  # Explicit enable list
  if [[ -n "${ZSH_FEATURES_ENABLE:-}" ]]; then
    if [[ " ${ZSH_FEATURES_ENABLE//,/ } " == *" ${FEATURE_NAME} "* ]]; then
      return 0
    fi
  fi

  # Fallback default
  _feature_noop_bool "${FEATURE_DEFAULT_ENABLED}"
}

# ------------------------------------------------------------------------------
# Required Contract: Registration
# No user-visible side effects here. Only registry bookkeeping.
# ------------------------------------------------------------------------------
feature_noop_register() {
  if (( __feature_noop_registered )); then
    return 0
  fi
  if typeset -f feature_registry_add >/dev/null 2>&1; then
    feature_registry_add \
      "${FEATURE_NAME}" \
      "${FEATURE_PHASE}" \
      "${FEATURE_DEPENDS}" \
      "${FEATURE_DEFERRED}" \
      "${FEATURE_CATEGORY}" \
      "${FEATURE_DESCRIPTION}" \
      "${FEATURE_GUID}"
  fi
  __feature_noop_registered=1
  return 0
}

# ------------------------------------------------------------------------------
# Optional: Preload (kept minimal; no side effects)
# ------------------------------------------------------------------------------
feature_noop_preload() {
  return 0
}

# ------------------------------------------------------------------------------
# Required Contract: Init
# Applies minimal user-visible state: defines a trivial function + flag.
# ------------------------------------------------------------------------------
feature_noop_init() {
  # Guard double init
  if (( __feature_noop_initialized )); then
    return 0
  fi

  # Side effects (lightweight)
  noop::ping() {
    # Simple function used in tests to assert presence & functionality
    return 0
  }

  __feature_noop_initialized=1
  return 0
}

# ------------------------------------------------------------------------------
# Optional: Post-Prompt (noop for this feature)
# ------------------------------------------------------------------------------
feature_noop_postprompt() {
  __feature_noop_postprompt_ran=1
  return 0
}

# ------------------------------------------------------------------------------
# Optional: Teardown
# ------------------------------------------------------------------------------
feature_noop_teardown() {
  unset -f noop::ping 2>/dev/null || true
  __feature_noop_initialized=0
  return 0
}

# ------------------------------------------------------------------------------
# Failure Injection (Testing)
# ------------------------------------------------------------------------------
feature_noop__test_inject_failure() {
  print -u2 "[feature:${FEATURE_NAME}] Injected noop test failure"
  return 42
}

# ------------------------------------------------------------------------------
# Self-Check (lightweight invariants)
# ------------------------------------------------------------------------------
feature_noop_self_check() {
  local missing=0
  for k in FEATURE_NAME FEATURE_VERSION FEATURE_PHASE FEATURE_GUID; do
    if [[ -z "${(P)k}" ]]; then
      print -u2 "[feature:${FEATURE_NAME}] Missing metadata: $k"
      missing=1
    fi
  done

  # If initialized, function should exist
  if (( __feature_noop_initialized )); then
    if ! typeset -f noop::ping >/dev/null 2>&1; then
      print -u2 "[feature:${FEATURE_NAME}] Expected function noop::ping missing after init"
      missing=1
    fi
  fi
  return $missing
}

# ------------------------------------------------------------------------------
# Auto-registration (safe even if registry not yet loaded; later phases can re-call)
# ------------------------------------------------------------------------------
feature_noop_register

# End of noop feature module
# ==============================================================================
