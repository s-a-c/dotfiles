# ============================================================================
# Feature Module Template
# File: _TEMPLATE_FEATURE_MODULE.zsh
#
# Replace all <PLACEHOLDER> values before converting this template
# into a concrete feature module. Do NOT commit an unmodified copy
# other than this canonical template.
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Policy Notes:
# - No observable side effects (env, aliases, functions exported to global scope,
#   keybindings, prompt mutations, completion changes) may occur before the
#   feature init function executes.
# - Sensitive actions (PATH mutation, external process spawning, security-impacting
#   sandbox adjustments) MUST cite the exact guideline rule reference with a
#   clickable path + line reference comment at the point of change.
# - All logic MUST be testable under `zsh -f`.
# - Each concrete feature MUST ship with:
#     * Contract tests (metadata + enable/disable semantics)
#     * Failure containment test (forced error path)
#     * (If non-trivial) performance delta test
#
# ============================================================================

# ----------------------------------------------------------------------------
# Guard: Prevent accidental execution if copied verbatim and sourced multiple times.
# ----------------------------------------------------------------------------
if [[ -n "${__ZSH_FEATURE_TEMPLATE_GUARD:-}" ]]; then
  return 0
fi
__ZSH_FEATURE_TEMPLATE_GUARD=1

# ----------------------------------------------------------------------------
# Metadata Section (Static Declarations)
# ----------------------------------------------------------------------------
# All keys MUST remain single-line for simple grep-based extraction.
# FEATURE_NAME: A short machine-safe token (lowercase, dashes or underscores)
# FEATURE_VERSION: Semantic version for migration / upgrade logic
# FEATURE_PHASE: Integer phase (1=early, 2=standard, 3=deferred/async)
# FEATURE_DEPENDS: Space-separated list of other feature names (may be empty)
# FEATURE_DEFAULT_ENABLED: yes|no (baseline default before user overrides)
# FEATURE_DEFERRED: yes|no (if loads after first prompt render)
# FEATURE_DESCRIPTION: Human-readable summary (keep concise)
# FEATURE_CATEGORY: One of: prompt, history, navigation, completion, integration, keybinding, search, safety, telemetry, extensibility, misc
# FEATURE_SINCE_STAGE: Stage number where introduced
# FEATURE_GUID: Unique stable identifier (uuidv4 or deterministic slug)
FEATURE_NAME="<replace-with-feature-name>"
FEATURE_VERSION="0.1.0"
FEATURE_PHASE="2"
FEATURE_DEPENDS=""
FEATURE_DEFAULT_ENABLED="yes"
FEATURE_DEFERRED="no"
FEATURE_DESCRIPTION="<short concise description>"
FEATURE_CATEGORY="misc"
FEATURE_SINCE_STAGE="4"
FEATURE_GUID="<generate-uuid-or-stable-id>"

# Internal state namespace prefix (derive from FEATURE_NAME; keep unique).
# IMPORTANT: Do not export these variables unless intentionally part of the contract.
__feat_ns="__feature_${FEATURE_NAME}"

# ----------------------------------------------------------------------------
# User Configuration Override Conventions
# ----------------------------------------------------------------------------
# Users may control enablement via (precedence: highest first):
#  1. ZSH_FEATURES_DISABLE (space or comma separated, supports 'all')
#  2. ZSH_FEATURES_ENABLE  (explicit inclusion even if default off)
#  3. FEATURE_DEFAULT_ENABLED fallback
#
# Optional per-feature override variable pattern (if needed):
#   ZSH_FEATURE_<UPPER_FEATURE_NAME>_ENABLED=(yes|no)
#
# Do not implement overrides inside the template body; actual features may
# extend this pattern as needed.
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Helper: Boolean utility (local to module)
# ----------------------------------------------------------------------------
_feature_template_bool() {
  # Normalize truthy / falsy into 0(success=true)/1(false)
  # Usage: if _feature_template_bool "$var"; then ...
  case "${1:-}" in
    1|true|yes|on|enable|enabled) return 0 ;;
    0|false|no|off|disable|disabled|"" ) return 1 ;;
    *) return 1 ;;
  esac
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_metadata
# MUST return key=value lines (no spaces around '=')
# This is consumed by the registry / self-check command.
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_metadata() {
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

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_is_enabled
# Evaluate effective enablement (no side effects).
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_is_enabled() {
  # Honor global disable-all sentinel
  if [[ "${ZSH_FEATURES_DISABLE:-}" == *"all"* ]]; then
    return 1
  fi

  local upper
  upper="${FEATURE_NAME:u}"   # zsh uppercase transformation

  # Per-feature explicit override variable (optional pattern)
  local override_var="ZSH_FEATURE_${upper}_ENABLED"
  if typeset -p "${override_var}" >/dev/null 2>&1; then
    local val; eval "val=\${${override_var}}"
    if _feature_template_bool "${val}"; then return 0; else return 1; fi
  fi

  # Explicit disable list wins over enable list
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

  # Fall back to default
  _feature_template_bool "${FEATURE_DEFAULT_ENABLED}"
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_register
# Performs registration side effects ONLY (e.g., adds itself to a global
# associative array managed by the registry). Must not mutate user-visible
# shell state (aliases, prompt, bindings, PATH).
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_register() {
  # Example (placeholder) — actual registry function 'feature_registry_add'
  # will be implemented separately in registry scaffold.
  # if typeset -f feature_registry_add >/dev/null 2>&1; then
  #   feature_registry_add "${FEATURE_NAME}" "${FEATURE_PHASE}" "${FEATURE_DEPENDS}" "${FEATURE_DEFERRED}" "${FEATURE_CATEGORY}"
  # fi
  return 0
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_preload (Optional)
# Runs before main init (Phase pre-init). No visible side effects allowed
# unless absolutely necessary (and documented).
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_preload() {
  return 0
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_init
# Primary activation hook. All user-visible changes (functions, keymaps,
# prompt segments, env exports) must occur here or later. Wrap mutating
# logic in error boundaries if failure-safe behavior desired.
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_init() {
  # Example guarded section skeleton:
  {
    # Perform main initialization steps.
    # 1. Define functions
    # 2. Register prompt segments
    # 3. Set environment variables
    :
  } always {
    # Optional cleanup or state flag
    :
  }
  return 0
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_postprompt (Optional)
# Executed after first prompt render (for deferred / async setups).
# Should not block user interaction.
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_postprompt() {
  return 0
}

# ----------------------------------------------------------------------------
# Contract Function: feature_<name>_teardown (Optional)
# Reverse user-visible effects if feature is dynamically disabled or during
# controlled teardown (test harness, shell exit debug).
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_teardown() {
  # Undo prompt injections, keybindings, exports, etc.
  return 0
}

# ----------------------------------------------------------------------------
# Failure Injection Helper (Testing Only)
# Provide a standardized way for tests to simulate failure.
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>__test_inject_failure() {
  print -u2 "[feature:${FEATURE_NAME}] Injected test failure"
  return 42
}

# ----------------------------------------------------------------------------
# Self-Check Hook (Optional)
# Returns 0 if internal invariants hold, non-zero otherwise.
# Tests may call this to validate expected internal state.
# ----------------------------------------------------------------------------
feature_<replace-with-feature-name>_self_check() {
  # Example invariant: required metadata fields non-empty
  local missing=0
  for k in FEATURE_NAME FEATURE_VERSION FEATURE_PHASE FEATURE_CATEGORY FEATURE_GUID; do
    if [[ -z "${(P)k}" ]]; then
      print -u2 "[feature:${FEATURE_NAME}] Missing required metadata: $k"
      missing=1
    fi
  done
  return $missing
}

# ----------------------------------------------------------------------------
# Template Guidance (Remove Section in Concrete Module)
# ----------------------------------------------------------------------------
# 1. Copy this file to: feature/<feature-name>.zsh
# 2. Replace all <replace-with-feature-name> tokens (lowercase) consistently.
# 3. Fill metadata variables (do NOT leave placeholders).
# 4. Add tests:
#    - tests/feature/<feature-name>/test-contract.zsh
#    - tests/feature/<feature-name>/test-enable-disable.zsh
#    - tests/feature/<feature-name>/test-failure-containment.zsh
#    - (If needed) tests/perf/<feature-name>-delta.zsh
# 5. Update catalog + tracker with Planned -> In Progress.
# 6. Cite guideline rule lines for any sensitive operations added later.
#
# End of template.
# ============================================================================
