#!/usr/bin/env bash
# append-validation-snapshot.sh
#
# Purpose:
#   Append a standardized validation snapshot line to
#     zsh/docs/fix-zle/plan-of-attack.md
#   capturing current health metrics (widgets baseline, segment validity,
#   autopair PTY status, archive integrity, emergency fallback widget count),
#   and emit a badge JSON summarizing the most recent snapshot.
#
# Baseline Policy:
#   Enforced widget baseline: 417 (historical / superseded: 416; rollback floor: 387).
#   A snapshot SHOULD NOT be recorded if widgets <417 unless --force is used
#   AND a justification is provided (see --reason). This preserves integrity
#   of the documented health ledger.
#
# Additional Governance (2025-10-01):
#   Force snapshots on the primary branch (main / trunk) are blocked unless:
#     * --force is supplied AND
#     * FORCE_REASON contains token [APPROVED]  OR environment variable SNAPSHOT_FORCE_APPROVED=1
#
# Usage:
#   zsh/tools/append-validation-snapshot.sh [options]
#
# Options:
#   --poa <file>          Path to plan-of-attack.md
#   --artifacts <dir>     Directory containing aggregator / health JSON (default: artifacts)
#   --force               Allow append even if widgets < 417
#   --reason <text>       Justification for forced append (required with --force)
#   --dry-run             Compute line; do not append
#   --line-only           Print snapshot line only (no extra output)
#   --help                Show help and exit
#
# Environment Overrides (optional):
#   WIDGETS, SEG_VALID, AUTOPAIR, ARCHIVE_OK, EMERGENCY_WIDGETS
#   (Optional dual metrics overrides)
#   WIDGETS_INTERACTIVE, WIDGETS_CORE
#
# Data Sources (auto-detected, in priority order):
#   1. artifacts/widget-metrics.json (dual widget counts)
#   2. artifacts/smoke.json (dual-capable smoke output)
#   3. artifacts/pre-chsh.json (legacy aggregator)
#   4. artifacts/layer-health.json
#
# Exit Codes:
#   0 success
#   1 generic failure / invalid usage
#   2 policy rejection (widgets below baseline without --force)
#   3 governance rejection (force on protected branch w/out approval)
#
# Logging Conventions:
#   [INFO] normal progress
#   [WARN] recoverable / fallback conditions
#   [ERROR] fatal issues
#
# Safe to re-run; each invocation appends a new immutable line (prefixed - Snapshot entry:)
#
# jq Fast Path:
#   If jq is available, it is used for robust JSON field extraction; otherwise
#   legacy grep/sed fallback logic is used.
#
set -euo pipefail

BASELINE=417
ROLLBACK_FLOOR=387
PROTECTED_BRANCHES_REGEX='^(main|master|trunk)$'

POA_FILE="${POA_FILE:-zsh/docs/fix-zle/plan-of-attack.md}"
ARTIFACTS_DIR="artifacts"
FORCE=0
DRY_RUN=0
LINE_ONLY=0
FORCE_REASON=""

print_help() {
  cat <<EOF
append-validation-snapshot.sh - Append a standardized validation snapshot line.

Baseline enforced: widgets >= ${BASELINE} (rollback floor: ${ROLLBACK_FLOOR})

Usage:
  $0 [options]

Options:
  --poa <file>        Plan-of-attack file (default: ${POA_FILE})
  --artifacts <dir>   Artifacts directory (default: ${ARTIFACTS_DIR})
  --force             Allow append if widgets < ${BASELINE} (requires --reason)
  --reason <text>     Justification for forced append
  --dry-run           Show computed line but do not modify file
  --line-only         Output only the snapshot line (suppresses info logs)
  --help              Show this help

Environment overrides:
  WIDGETS SEG_VALID AUTOPAIR ARCHIVE_OK EMERGENCY_WIDGETS
  WIDGETS_INTERACTIVE WIDGETS_CORE
Approval override (protected branches):
  SNAPSHOT_FORCE_APPROVED=1  or include token [APPROVED] in --reason

Examples:
  $0
  WIDGETS=417 SEG_VALID=true $0 --dry-run
  $0 --force --reason "[APPROVED] Temporary accepted fluctuation after plugin removal"

EOF
}

log() {
  local level="$1"; shift
  if [[ "${LINE_ONLY}" -eq 0 ]]; then
    printf '[%s] %s\n' "${level}" "$*"
  fi
}

abort() {
  log "ERROR" "$*"
  exit 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --poa)
        POA_FILE="$2"; shift 2;;
      --artifacts)
        ARTIFACTS_DIR="$2"; shift 2;;
      --force)
        FORCE=1; shift;;
      --reason)
        FORCE_REASON="$2"; shift 2;;
      --dry-run)
        DRY_RUN=1; shift;;
      --line-only)
        LINE_ONLY=1; shift;;
      --help|-h)
        print_help; exit 0;;
      --)
        shift; break;;
      *)
        abort "Unknown argument: $1 (use --help)"
        ;;
    esac
  done
}

have_jq() { command -v jq >/dev/null 2>&1; }

# Attempt to extract a JSON numeric field (fallback mode).
extract_json_number_fallback() {
  local field="$1" file="$2"
  [[ -f "$file" ]] || return 1
  grep -m1 "\"${field}\":" "$file" 2>/dev/null | sed -E "s/.*\"${field}\": *([0-9]+).*/\\1/" || true
}

# Attempt to detect a boolean true for a given field (fallback mode).
extract_json_true_flag_fallback() {
  local field="$1" file="$2"
  [[ -f "$file" ]] || return 1
  if grep -q "\"${field}\": *true" "$file" 2>/dev/null; then
    echo true
  else
    echo false
  fi
}

compute_archive_ok() {
  local tools_dir=".ARCHIVE/tools"
  local manifest=".ARCHIVE/manifest.json"
  if [[ ! -d "$tools_dir" || ! -f "$manifest" ]]; then
    log "WARN" "Archive components missing; treating archive_ok=1 (not gating)."
    echo 1
    return
  fi
  local fs_count man_count
  fs_count=$(find "$tools_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  man_count=$(grep -c '"original_path"' "$manifest" 2>/dev/null || echo 0)
  if [[ "$fs_count" == "$man_count" ]]; then
    echo 1
  else
    log "WARN" "Archive mismatch fs=${fs_count} manifest=${man_count}"
    echo 0
  fi
}

derive_emergency_widgets() {
  zsh -ic 'source .zshrc.emergency 2>/dev/null; zle -la | wc -l' 2>/dev/null | tr -d ' ' || echo "NA"
}

current_branch() {
  # Try env (CI) first, then git
  if [[ -n "${GITHUB_REF:-}" ]]; then
    basename "${GITHUB_REF}"
  else
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
  fi
}

main() {
  parse_args "$@"

  if [[ "$FORCE" -eq 1 && -z "$FORCE_REASON" ]]; then
    abort "--force requires --reason <text>"
  fi

  : "${WIDGETS:=}"
  : "${SEG_VALID:=}"
  : "${AUTOPAIR:=}"
  : "${ARCHIVE_OK:=}"
  : "${EMERGENCY_WIDGETS:=}"
  : "${WIDGETS_INTERACTIVE:=}"
  : "${WIDGETS_CORE:=}"

  local metrics_json="${ARTIFACTS_DIR}/widget-metrics.json"
  local smoke_json="${ARTIFACTS_DIR}/smoke.json"
  local aggregator="${ARTIFACTS_DIR}/pre-chsh.json"
  local layer_health="${ARTIFACTS_DIR}/layer-health.json"

  if have_jq; then
    # jq fast path (prefer explicit dual metrics sources)
    if [[ -f "$metrics_json" ]]; then
      [[ -z "$WIDGETS_INTERACTIVE" ]] && WIDGETS_INTERACTIVE=$(jq -r '(.widgets_interactive // empty)' "$metrics_json" 2>/dev/null || echo "")
      [[ -z "$WIDGETS_CORE" ]] && WIDGETS_CORE=$(jq -r '(.widgets_core // empty)' "$metrics_json" 2>/dev/null || echo "")
      if [[ -z "$WIDGETS" && -n "$WIDGETS_INTERACTIVE" ]]; then
        WIDGETS="$WIDGETS_INTERACTIVE"
      fi
    fi
    if [[ -f "$smoke_json" ]]; then
      # Use smoke JSON only if metrics not already populated
      [[ -z "$WIDGETS_INTERACTIVE" ]] && WIDGETS_INTERACTIVE=$(jq -r '(.widgets_interactive // empty)' "$smoke_json" 2>/dev/null || echo "")
      [[ -z "$WIDGETS_CORE" ]] && WIDGETS_CORE=$(jq -r '(.widgets_core // empty)' "$smoke_json" 2>/dev/null || echo "")
      if [[ -z "$WIDGETS" && -n "$WIDGETS_INTERACTIVE" ]]; then
        WIDGETS="$WIDGETS_INTERACTIVE"
      fi
      # Legacy single field fallback (core)
      if [[ -z "$WIDGETS" ]]; then
        alt=$(jq -r '(.widgets // empty)' "$smoke_json" 2>/dev/null || echo "")
        [[ -n "$alt" ]] && WIDGETS="$alt"
      fi
    fi
    # Legacy sources last
    if [[ -z "$WIDGETS" ]]; then
      if [[ -f "$aggregator" ]]; then
        WIDGETS=$(jq -r '(.widget_count // .widgets // empty)' "$aggregator" 2>/dev/null || echo "")
      fi
      if [[ -z "$WIDGETS" && -f "$layer_health" ]]; then
        WIDGETS=$(jq -r '(.widgets // empty)' "$layer_health" 2>/dev/null || echo "")
      fi
    fi
    if [[ -z "$SEG_VALID" ]]; then
      if [[ -f "$aggregator" ]]; then
        SEG_VALID=$(jq -r '(.segments_valid // .validated // empty)' "$aggregator" 2>/dev/null || echo "")
      fi
      if [[ -z "$SEG_VALID" && -f "$smoke_json" ]]; then
        SEG_VALID=$(jq -r '(.segments_valid // .validated // empty)' "$smoke_json" 2>/dev/null || echo "")
      fi
      if [[ -z "$SEG_VALID" && -f "$layer_health" ]]; then
        SEG_VALID=$(jq -r '(.validated // .segments_valid // empty)' "$layer_health" 2>/dev/null || echo "")
      fi
    fi
    if [[ -z "$AUTOPAIR" ]]; then
      if [[ -f "$smoke_json" ]]; then
        AUTOPAIR=$(jq -r '(.autopair // .autopair_pty_passed // empty)' "$smoke_json" 2>/dev/null || echo "")
      elif [[ -f "$aggregator" ]]; then
        AUTOPAIR=$(jq -r '(.autopair_pty_passed // empty)' "$aggregator" 2>/dev/null || echo "")
      fi
    fi
  else
    # Fallback (grep/sed) - legacy only; dual metrics not parsed without jq
    if [[ -z "$WIDGETS" ]]; then
      WIDGETS=$(extract_json_number_fallback "widget_count" "$aggregator")
      [[ -z "$WIDGETS" ]] && WIDGETS=$(extract_json_number_fallback "widgets" "$layer_health")
      [[ -z "$WIDGETS" ]] && WIDGETS=$(extract_json_number_fallback "widgets" "$smoke_json")
    fi
    if [[ -z "$SEG_VALID" ]]; then
      SEG_VALID=$(extract_json_true_flag_fallback "segments_valid" "$aggregator" || echo false)
      if [[ "$SEG_VALID" == "false" ]]; then
        local v
        v=$(extract_json_true_flag_fallback "validated" "$layer_health" || echo false)
        [[ "$v" == "true" ]] && SEG_VALID=true
      fi
    fi
    if [[ -z "$AUTOPAIR" ]]; then
      AUTOPAIR=$(extract_json_true_flag_fallback "autopair_pty_passed" "$aggregator" || echo false)
      [[ "$AUTOPAIR" == "false" ]] && AUTOPAIR=$(extract_json_true_flag_fallback "autopair" "$smoke_json" || echo false)
    fi
  fi

  [[ -z "$ARCHIVE_OK" ]] && ARCHIVE_OK=$(compute_archive_ok)
  [[ -z "$EMERGENCY_WIDGETS" ]] && EMERGENCY_WIDGETS=$(derive_emergency_widgets)

  : "${WIDGETS:=NA}"
  : "${SEG_VALID:=unknown}"
  : "${AUTOPAIR:=unknown}"
  : "${EMERGENCY_WIDGETS:=NA}"

  # Normalize booleans
  [[ "$SEG_VALID" != "true" ]] && [[ "$SEG_VALID" != "false" ]] && SEG_VALID="unknown"
  [[ "$AUTOPAIR" != "true" ]] && [[ "$AUTOPAIR" != "false" ]] && AUTOPAIR="unknown"

  # Compute delta if dual metrics present
  WIDGETS_DELTA="NA"
  if [[ "$WIDGETS_INTERACTIVE" =~ ^[0-9]+$ && "$WIDGETS_CORE" =~ ^[0-9]+$ ]]; then
    WIDGETS_DELTA=$(( WIDGETS_INTERACTIVE - WIDGETS_CORE ))
  fi

  # Governance guard: block force on protected branch unless approved
  local branch
  branch=$(current_branch)
  if (( FORCE == 1 )) && [[ "$branch" =~ $PROTECTED_BRANCHES_REGEX ]]; then
    if [[ "${SNAPSHOT_FORCE_APPROVED:-0}" != "1" && "${FORCE_REASON}" != *"[APPROVED]"* ]]; then
      log "ERROR" "Force snapshot blocked on protected branch '${branch}' without approval token."
      exit 3
    else
      log "INFO" "Force snapshot on protected branch '${branch}' approved (token/env present)."
    fi
  fi

  if [[ "$WIDGETS" =~ ^[0-9]+$ ]]; then
    if (( WIDGETS < BASELINE )); then
      if (( FORCE == 0 )); then
        log "ERROR" "Widgets=${WIDGETS} below baseline ${BASELINE}; use --force with --reason to record."
        exit 2
      else
        log "WARN" "Recording snapshot below baseline (${WIDGETS} < ${BASELINE}) with justification: ${FORCE_REASON}"
      fi
    fi
  else
    log "WARN" "Widgets value non-numeric (${WIDGETS}); cannot enforce baseline check."
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%MZ)

  local line="${timestamp} widgets=${WIDGETS} segments_valid=${SEG_VALID} autopair_pty_passed=${AUTOPAIR} archive_ok=${ARCHIVE_OK} emergency_widgets=${EMERGENCY_WIDGETS}"
  if [[ -n "$WIDGETS_INTERACTIVE" || -n "$WIDGETS_CORE" ]]; then
    line="${line} widgets_interactive=${WIDGETS_INTERACTIVE:-NA} widgets_core=${WIDGETS_CORE:-NA} widgets_delta=${WIDGETS_DELTA}"
  fi
  if (( FORCE == 1 )); then
    line="${line} force_reason=\"${FORCE_REASON//\"/\\\"}\""
  fi

  if (( DRY_RUN == 1 )); then
    if (( LINE_ONLY == 1 )); then
      echo "${line}"
    else
      log "INFO" "DRY-RUN Snapshot line (not appended):"
      echo "${line}"
    fi
    exit 0
  fi

  if [[ ! -f "$POA_FILE" ]]; then
    # Fallback resolution:
    # 1. If caller passed relative path without leading zsh/, try stripping that prefix expectation.
    # 2. Try alternate relative location: docs/fix-zle/plan-of-attack.md (when running from within zsh/).
    if [[ -f "docs/fix-zle/plan-of-attack.md" ]]; then
      POA_FILE="docs/fix-zle/plan-of-attack.md"
      log "INFO" "Resolved POA_FILE fallback: ${POA_FILE}"
    elif [[ -f "../docs/fix-zle/plan-of-attack.md" ]]; then
      POA_FILE="../docs/fix-zle/plan-of-attack.md"
      log "INFO" "Resolved POA_FILE parent fallback: ${POA_FILE}"
    else
      abort "Plan-of-attack file not found (tried ${POA_FILE}, docs/fix-zle/plan-of-attack.md, ../docs/fix-zle/plan-of-attack.md)"
    fi
  fi

  if grep -n 'Snapshot template:' "$POA_FILE" >/dev/null 2>&1; then
    {
      echo "- Snapshot entry: \`${line}\`"
    } >> "$POA_FILE"
    log "INFO" "Appended snapshot after template marker."
  else
    {
      echo
      echo "### Appended Validation Snapshot"
      echo "- Snapshot entry: \`${line}\`"
    } >> "$POA_FILE"
    log "INFO" "Appended snapshot at file end (template marker not found)."
  fi

  # Badge JSON/SVG emission (enriched with dual metrics + optional perf drift integration)
  local badge_dir="docs/redesignv2/artifacts/badges"
  mkdir -p "${badge_dir}"

  # Determine base color
  local color="brightgreen"
  [[ "$WIDGETS" =~ ^[0-9]+$ ]] || color="lightgrey"
  if [[ "$SEG_VALID" != "true" && "$SEG_VALID" != "unknown" ]]; then color="yellow"; fi
  if [[ "$AUTOPAIR" != "true" && "$AUTOPAIR" != "unknown" ]]; then color="yellow"; fi
  if [[ "$WIDGETS" =~ ^[0-9]+$ && "$WIDGETS" -lt $BASELINE ]]; then color="red"; fi

  # Compose primary message
  local msg=""
  if [[ "$WIDGETS_INTERACTIVE" =~ ^[0-9]+$ && "$WIDGETS_CORE" =~ ^[0-9]+$ ]]; then
    msg="${WIDGETS_INTERACTIVE}w(core:${WIDGETS_CORE},Δ:${WIDGETS_DELTA})|seg:${SEG_VALID}|ap:${AUTOPAIR}"
  else
    msg="${WIDGETS}w|seg:${SEG_VALID}|ap:${AUTOPAIR}"
  fi

  # Optional perf drift badge merge (if produced by perf-drift-badge.sh)
  # When PERF_DRIFT_BADGE_JSON is present, append short perf token: perf:<message>
  local perf_badge_json="${PERF_DRIFT_BADGE_JSON:-${badge_dir}/perf-drift.json}"
  local perf_token=""
  if [[ -f "$perf_badge_json" ]]; then
    if command -v jq >/dev/null 2>&1; then
      perf_token=$(jq -r '.message // empty' "$perf_badge_json" 2>/dev/null || echo "")
    else
      perf_token=$(grep -m1 '"message"' "$perf_badge_json" 2>/dev/null | sed -E 's/.*"message":"([^"]+)".*/\1/')
    fi
    if [[ -n "$perf_token" ]]; then
      msg="${msg}|perf:${perf_token}"
    fi
  fi

  # Emit Shields JSON
  printf '%s\n' "{\"schemaVersion\":1,\"label\":\"snapshot\",\"message\":\"${msg}\",\"color\":\"${color}\"}" > "${badge_dir}/last-snapshot.json"

  # Generate minimal SVG (Shields-like static rendering)
  # Simple width heuristic: 7px per char + padding
  local label="snapshot"
  local full="${label}:${msg}"
  local chars=${#full}
  local width=$(( chars * 7 + 20 ))
  local label_width=$(( ${#label} * 7 + 16 ))
  local font_family="DejaVu Sans,Verdana,Geneva,sans-serif"
  cat > "${badge_dir}/last-snapshot.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="20" role="img" aria-label="${label}: ${msg}">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <rect rx="3" width="${width}" height="20" fill="#555"/>
  <rect rx="3" x="${label_width}" width="$(( width - label_width ))" height="20" fill="#${color}"/>
  <rect rx="3" width="${width}" height="20" fill="url(#s)"/>
  <g fill="#fff" text-anchor="middle" font-family="${font_family}" font-size="11">
    <text x="$(( label_width / 2 ))" y="14">${label}</text>
    <text x="$(( label_width + (width - label_width)/2 ))" y="14">${msg}</text>
  </g>
</svg>
SVG

  # Promotion hook integration:
  # If PROMOTION_HOOK_FILE is set, append a concise machine-parsable line (& optionally perf token).
  if [[ -n "${PROMOTION_HOOK_FILE:-}" ]]; then
    {
      echo "snapshot widgets=${WIDGETS} widgets_interactive=${WIDGETS_INTERACTIVE:-NA} widgets_core=${WIDGETS_CORE:-NA} delta=${WIDGETS_DELTA:-NA} seg=${SEG_VALID} autopair=${AUTOPAIR} perf='${perf_token}' color=${color}"
    } >> "${PROMOTION_HOOK_FILE}"
  fi

  # Optional summary line for Makefile / local target (if SNAPSHOT_SUMMARY=1)
  if [[ "${SNAPSHOT_SUMMARY:-0}" == "1" ]]; then
    echo "[SUMMARY] ${msg} (color=${color})"
  fi

  if (( LINE_ONLY == 1 )); then
    echo "${line}"
  else
    log "INFO" "Snapshot recorded:"
    echo "${line}"
    log "INFO" "Badge JSON written: ${badge_dir}/last-snapshot.json"
    log "INFO" "Badge SVG written:  ${badge_dir}/last-snapshot.svg"
    [[ -n "${perf_token}" ]] && log "INFO" "Perf drift merged: ${perf_token}"
    [[ -n "${PROMOTION_HOOK_FILE:-}" ]] && log "INFO" "Promotion hook appended: ${PROMOTION_HOOK_FILE}"
  fi

  if (( LINE_ONLY == 1 )); then
    echo "${line}"
  else
    log "INFO" "Snapshot recorded:"
    echo "${line}"
    log "INFO" "Badge JSON written: ${badge_dir}/last-snapshot.json"
  fi
}

main "$@"
