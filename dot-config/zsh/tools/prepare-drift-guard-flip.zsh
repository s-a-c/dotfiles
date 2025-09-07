#!/usr/bin/env zsh
# prepare-drift-guard-flip.zsh
# Prepare drift guard flip after 7-day stability window
#
# Purpose:
#   Evaluates readiness for enabling drift gating enforcement based on:
#   1. Variance guard stability (current mode and streak)
#   2. Historical performance stability over 7-day window
#   3. Async activation checklist compliance
#   4. CI enforcement readiness
#
# This script assesses but does not automatically enable drift gating.
# It provides recommendations and generates a readiness report.
#
# Usage:
#   tools/prepare-drift-guard-flip.zsh [--check-only] [--days N]
#
# Options:
#   --check-only    Only assess readiness, don't prepare configs
#   --days N        Stability window in days (default: 7)
#   --help          Show this help
#
# Exit codes:
#   0 - Ready for drift guard flip
#   1 - Not ready (missing preconditions)
#   2 - Usage error
#   3 - Missing dependencies or files

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ZDOTDIR="${ZDOTDIR:-${SCRIPT_DIR}/..}"

# Configuration
STABILITY_DAYS_DEFAULT=7
# Prefer repository-level docs path for metrics; fall back to dot-config path when missing
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." 2>/dev/null && pwd -P || true)"
REPO_DOCS_METRICS="${REPO_ROOT}/docs/redesignv2/artifacts/metrics"

VARIANCE_STATE_FILE="${REPO_DOCS_METRICS}/variance-gating-state.json"
if [[ ! -f "$VARIANCE_STATE_FILE" ]]; then
  VARIANCE_STATE_FILE="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/variance-gating-state.json"
fi

GOVERNANCE_BADGE="${ZDOTDIR}/docs/redesignv2/artifacts/badges/governance.json"

HISTORY_DIR="${REPO_DOCS_METRICS}/ledger-history"
if [[ ! -d "$HISTORY_DIR" ]]; then
  HISTORY_DIR="${ZDOTDIR}/docs/redesignv2/artifacts/metrics/ledger-history"
fi
DRIFT_CONFIG_FILE="${ZDOTDIR}/tools/config/drift-gating-config.json"

# Parse arguments
CHECK_ONLY=0
STABILITY_DAYS="$STABILITY_DAYS_DEFAULT"

usage() {
  echo "Usage: ${0:t} [OPTIONS]"
  echo ""
  echo "Prepare drift guard flip after stability window"
  echo ""
  echo "Options:"
  echo "  --check-only    Only assess readiness, don't prepare configs"
  echo "  --days N        Stability window in days (default: 7)"
  echo "  --help          Show this help"
  echo ""
  echo "Exit codes:"
  echo "  0 - Ready for drift guard flip"
  echo "  1 - Not ready (missing preconditions)"
  echo "  2 - Usage error"
  echo "  3 - Missing dependencies or files"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only)
      CHECK_ONLY=1
      shift
      ;;
    --days)
      shift
      if [[ $# -eq 0 ]] || [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --days requires a positive integer" >&2
        exit 2
      fi
      STABILITY_DAYS="$1"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Utilities
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }
log_check() { echo "[CHECK] $*"; }

# Check prerequisites
check_dependencies() {
  local missing=0

  if [[ ! -f "$VARIANCE_STATE_FILE" ]]; then
    log_error "Variance state file not found: $VARIANCE_STATE_FILE"
    missing=1
  fi

  if [[ ! -d "$HISTORY_DIR" ]]; then
    log_error "Performance history directory not found: $HISTORY_DIR"
    missing=1
  fi

  return $missing
}

# Get current variance state
get_variance_state() {
  if [[ ! -f "$VARIANCE_STATE_FILE" ]]; then
    echo "unknown"
    return 1
  fi

  if (( have_jq )); then
    jq -r '.mode // "unknown"' "$VARIANCE_STATE_FILE" 2>/dev/null || echo "unknown"
  else
    grep -o '"mode":"[^"]*"' "$VARIANCE_STATE_FILE" | cut -d'"' -f4 || echo "unknown"
  fi
}

get_variance_streak() {
  if [[ ! -f "$VARIANCE_STATE_FILE" ]]; then
    echo "0"
    return 1
  fi

  if (( have_jq )); then
    jq -r '.stable_run_count // 0' "$VARIANCE_STATE_FILE" 2>/dev/null || echo "0"
  else
    grep -o '"stable_run_count":[0-9]*' "$VARIANCE_STATE_FILE" | cut -d':' -f2 || echo "0"
  fi
}

# Check stability window
check_stability_window() {
  local days="$1"
  local cutoff_date

  # Calculate cutoff date (days ago)
  cutoff_date=$(date -v-${days}d +%Y%m%d 2>/dev/null || date -d "-${days} days" +%Y%m%d)

  log_check "Checking ${days}-day stability window (since $cutoff_date)"

  if [[ ! -d "$HISTORY_DIR" ]]; then
    log_error "No performance history available"
    return 1
  fi

  # Count files within stability window
  local recent_files=()
  for file in "$HISTORY_DIR"/perf-ledger-*.json; do
    if [[ -f "$file" ]]; then
      local date_str
      date_str=$(basename "$file" | sed -n 's/perf-ledger-\([0-9]\{8\}\)\.json/\1/p')
      if [[ -n "$date_str" && "$date_str" -ge "$cutoff_date" ]]; then
        recent_files+=("$file")
      fi
    fi
  done

  if [[ ${#recent_files[@]} -lt 3 ]]; then
    log_warn "Insufficient recent performance data: ${#recent_files[@]} files (need ≥3)"
    return 1
  fi

  log_info "Found ${#recent_files[@]} performance samples in ${days}-day window ✓"

  # Check for any performance regressions in recent files
  local regression_count=0
  for file in "${recent_files[@]}"; do
    if (( have_jq )); then
      local over_budget
      over_budget=$(jq -r '.overall.overBudgetCount // 0' "$file" 2>/dev/null)
      if [[ "$over_budget" -gt 0 ]]; then
        ((regression_count++))
        log_warn "Performance regression detected in $(basename "$file"): $over_budget segments over budget"
      fi
    fi
  done

  if [[ $regression_count -gt 1 ]]; then
    log_warn "Multiple performance regressions detected in stability window: $regression_count files"
    return 1
  fi

  log_info "Performance stability confirmed over ${days}-day window ✓"
  return 0
}

# Check async activation readiness
check_async_readiness() {
  log_check "Checking async activation checklist compliance"

  local tests_dir="${ZDOTDIR}/tests/integration"
  local ready=1

  # Check for required test files
  if [[ ! -x "$tests_dir/test-postplugin-compinit-single-run.zsh" ]]; then
    log_warn "Missing compinit single-run test"
    ready=0
  fi

  if [[ ! -x "$tests_dir/test-prompt-ready-single-emission.zsh" ]]; then
    log_warn "Missing PROMPT_READY single-emission test"
    ready=0
  fi

  if [[ $ready -eq 1 ]]; then
    log_info "Async activation tests available ✓"
  fi

  return $ready
}

# Check CI workflow readiness
check_ci_readiness() {
  log_check "Checking CI workflow configuration"

  local workflows_dir="${ZDOTDIR}/../../.github/workflows"
  local ready=1

  if [[ ! -f "$workflows_dir/ci-variance-nightly.yml" ]]; then
    log_warn "Missing nightly variance workflow"
    ready=0
  fi

  if [[ ! -f "$workflows_dir/ci-async-guards.yml" ]]; then
    log_warn "Missing async guards workflow"
    ready=0
  fi

  if [[ $ready -eq 1 ]]; then
    log_info "CI workflows configured ✓"
  fi

  return $ready
}

# Generate drift gating configuration
generate_drift_config() {
  log_info "Generating drift gating configuration..."

  mkdir -p "$(dirname "$DRIFT_CONFIG_FILE")"

  cat > "$DRIFT_CONFIG_FILE" <<EOF
{
  "schema": "drift-gating-config.v1",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "enabled": false,
  "thresholds": {
    "warn_pct": 5,
    "fail_pct": 10,
    "comment": "warn >5%, fail >10% as per Stage 3 specification"
  },
  "enforcement": {
    "observe_mode": true,
    "guard_flip_date": null,
    "stability_window_days": ${STABILITY_DAYS},
    "comment": "Set observe_mode=false and guard_flip_date when ready to enforce"
  },
  "prerequisites": {
    "variance_guard_active": true,
    "variance_streak_min": 3,
    "stability_window_satisfied": true,
    "async_checklist_complete": true,
    "ci_workflows_ready": true
  },
  "monitoring": {
    "nightly_variance_workflow": "ci-variance-nightly.yml",
    "async_guards_workflow": "ci-async-guards.yml",
    "drift_badge_artifact": "docs/redesignv2/artifacts/badges/perf-drift.json"
  }
}
EOF

  log_info "Configuration written to: $DRIFT_CONFIG_FILE"
}

# Main assessment
main() {
  log_info "=== Drift Guard Flip Readiness Assessment ==="
  log_info "Stability window: ${STABILITY_DAYS} days"
  log_info "Check only mode: $CHECK_ONLY"

  # Check dependencies
  if ! check_dependencies; then
    log_error "Missing required files or directories"
    exit 3
  fi

  # Check variance guard status
  local variance_mode variance_streak
  variance_mode=$(get_variance_state)
  variance_streak=$(get_variance_streak)

  log_check "Current variance state: mode=$variance_mode, streak=$variance_streak/3"

  local ready=1
  local checks_passed=0
  local total_checks=5

  # Assessment checks
  if [[ "$variance_mode" == "guard" && "$variance_streak" -ge 3 ]]; then
    log_info "✓ Variance guard active and stable"
    ((checks_passed++))
  else
    log_warn "✗ Variance guard not ready (mode=$variance_mode, streak=$variance_streak/3)"
    ready=0
  fi

  if check_stability_window "$STABILITY_DAYS"; then
    log_info "✓ Performance stability window satisfied"
    ((checks_passed++))
  else
    log_warn "✗ Performance stability window not satisfied"
    ready=0
  fi

  if check_async_readiness; then
    log_info "✓ Async activation checklist ready"
    ((checks_passed++))
  else
    log_warn "✗ Async activation checklist incomplete"
    ready=0
  fi

  if check_ci_readiness; then
    log_info "✓ CI workflows configured"
    ((checks_passed++))
  else
    log_warn "✗ CI workflows not ready"
    ready=0
  fi

  # Check current governance status
  if [[ -f "$GOVERNANCE_BADGE" ]]; then
    if (( have_jq )); then
      local gov_message
      gov_message=$(jq -r '.badge.message // "unknown"' "$GOVERNANCE_BADGE" 2>/dev/null)
      if [[ "$gov_message" == "guard: stable" ]]; then
        log_info "✓ Governance badge shows stable guard status"
        ((checks_passed++))
      else
        log_warn "✗ Governance badge not stable: $gov_message"
        ready=0
      fi
    else
      log_warn "✗ Cannot verify governance badge (jq unavailable)"
      ready=0
    fi
  else
    log_warn "✗ Governance badge not found"
    ready=0
  fi

  # Summary
  log_info ""
  log_info "=== Assessment Summary ==="
  log_info "Checks passed: $checks_passed/$total_checks"

  if [[ $ready -eq 1 ]]; then
    log_info "🎉 READY: All preconditions satisfied for drift guard flip"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review CI workflow configurations"
    log_info "2. Prepare drift gating enforcement"
    log_info "3. Monitor for additional 24-48 hours"
    log_info "4. Enable drift enforcement with observe_mode=false"

    if [[ $CHECK_ONLY -eq 0 ]]; then
      generate_drift_config
    fi

    exit 0
  else
    log_warn "❌ NOT READY: Missing preconditions for drift guard flip"
    log_info ""
    log_info "Required actions:"
    [[ "$variance_mode" != "guard" ]] && log_info "- Achieve variance guard mode with 3/3 streak"
    log_info "- Ensure ${STABILITY_DAYS}-day performance stability"
    log_info "- Complete async activation checklist"
    log_info "- Configure required CI workflows"
    log_info ""
    log_info "Re-run this script after addressing the issues above."

    exit 1
  fi
}

# Run main function
main "$@"
