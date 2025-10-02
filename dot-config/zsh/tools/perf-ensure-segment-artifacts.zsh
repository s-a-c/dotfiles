#!/usr/bin/env zsh
# perf-ensure-segment-artifacts.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Guarantee that the core performance capture artifacts used by tests and gating:
#     - perf-current.json
#     - perf-current-segments.txt
#   exist and are sufficiently fresh, regenerating them (once) via tools/perf-capture.zsh
#   only when necessary (missing, stale, or forced).
#
# WHY:
#   - Avoid duplicating "did you run perf-capture first?" logic inside every
#     performance test script.
#   - Provide consistent, low-noise CI logs and deterministic regeneration.
#
# BEHAVIOR:
#   1. Locate metrics directory (prefer redesignv2 path, fallback to legacy redesign).
#   2. Check age of artifacts; if either missing OR older than PERF_ENSURE_MAX_AGE_SEC,
#      or if PERF_ENSURE_FORCE=1, run perf-capture.zsh once.
#   3. Exit non-zero with clear diagnostic if regeneration fails or artifacts still absent.
#
# EXIT CODES:
#   0  Success (artifacts present & fresh after optional regeneration)
#   1  Metrics directory or capture tool missing
#   2  perf-capture run failed
#   3  Artifacts still missing after attempted regeneration
#   4  Invalid PERF_ENSURE_MAX_AGE_SEC value
#
# ENVIRONMENT / CONFIG:
#   PERF_ENSURE_MAX_AGE_SEC   Maximum acceptable age in seconds (default 600 / 10m)
#   PERF_ENSURE_VERBOSE=1     Emit additional logging
#   PERF_ENSURE_FORCE=1       Force unconditional regeneration
#   PERF_CAPTURE_BIN          Override path to perf-capture.zsh (default: $ZDOTDIR/tools/perf-capture.zsh)
#   ZDOTDIR                   Root zsh config directory (auto-detected if unset)
#
# CLI OPTIONS:
#   --help / -h               Show usage and exit
#
# EXAMPLES:
#   zsh tools/perf-ensure-segment-artifacts.zsh
#   PERF_ENSURE_VERBOSE=1 zsh tools/perf-ensure-segment-artifacts.zsh
#   PERF_ENSURE_FORCE=1 zsh tools/perf-ensure-segment-artifacts.zsh
#
# SAFETY:
#   - Writes only inside repo metrics/log directories.
#   - Silently skips if capture already fresh (fast path).
#
# FUTURE:
#   - Add checksum comparison caching.
#   - Support JSON schema validation before declaring success.
#
# ------------------------------------------------------------------------------

set -euo pipefail

# -------------- Usage --------------
usage() {
  cat <<'EOF'
perf-ensure-segment-artifacts.zsh
Ensure perf-current.json and perf-current-segments.txt exist and are fresh.

Environment:
  PERF_ENSURE_MAX_AGE_SEC   Max acceptable age in seconds (default 600)
  PERF_ENSURE_VERBOSE=1     Enable verbose logs
  PERF_ENSURE_FORCE=1       Force regeneration regardless of freshness
  PERF_CAPTURE_BIN          Override perf-capture.zsh path
  ZDOTDIR                   Override zsh config root

Exit Codes:
  0 success
  1 metrics directory or capture tool missing
  2 capture tool execution failed
  3 artifacts still missing after regeneration
  4 invalid configuration value

EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

# -------------- Configuration --------------
: ${PERF_ENSURE_MAX_AGE_SEC:=600}
: ${PERF_ENSURE_VERBOSE:=0}
: ${PERF_ENSURE_FORCE:=0}

if ! [[ $PERF_ENSURE_MAX_AGE_SEC =~ ^[0-9]+$ ]]; then
  echo "[perf-ensure] ERROR: PERF_ENSURE_MAX_AGE_SEC must be a non-negative integer (got: $PERF_ENSURE_MAX_AGE_SEC)" >&2
  exit 4
fi

ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

if [[ -d "$ZDOTDIR/docs/redesignv2/artifacts/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesignv2/artifacts/metrics"
elif [[ -d "$ZDOTDIR/docs/redesign/metrics" ]]; then
  METRICS_DIR="$ZDOTDIR/docs/redesign/metrics"
else
  echo "[perf-ensure] ERROR: metrics directory not found under $ZDOTDIR/docs" >&2
  exit 1
fi

PERF_CAPTURE_BIN="${PERF_CAPTURE_BIN:-$ZDOTDIR/tools/perf-capture.zsh}"
CUR_JSON="$METRICS_DIR/perf-current.json"
CUR_SEGMENTS="$METRICS_DIR/perf-current-segments.txt"

log() { [[ $PERF_ENSURE_VERBOSE == 1 ]] && echo "[perf-ensure] $*"; }

# -------------- Helpers --------------
file_age() {
  # Print age in seconds or large number if stat unavailable
  local f="$1"
  [[ -f $f ]] || { echo 999999999; return 0; }
  local mtime
  # macOS / BSD stat first, then GNU
  mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
  local now
  now=$(date +%s)
  echo $(( now - mtime ))
}

needs_regeneration=0

assess_file() {
  local f="$1" label="$2"
  if [[ ! -f "$f" ]]; then
    log "$label missing"
    needs_regeneration=1
    return
  fi
  local age
  age=$(file_age "$f")
  if (( age > PERF_ENSURE_MAX_AGE_SEC )); then
    log "$label stale (age=${age}s > ${PERF_ENSURE_MAX_AGE_SEC}s)"
    needs_regeneration=1
  else
    log "$label fresh (age=${age}s)"
  fi
}

# -------------- Assessment --------------
if (( PERF_ENSURE_FORCE == 1 )); then
  log "Force regeneration requested (PERF_ENSURE_FORCE=1)"
  needs_regeneration=1
else
  assess_file "$CUR_JSON" "perf-current.json"
  assess_file "$CUR_SEGMENTS" "perf-current-segments.txt"
fi

# -------------- Regeneration (if needed) --------------
if (( needs_regeneration == 1 )); then
  if [[ ! -f "$PERF_CAPTURE_BIN" ]]; then
    echo "[perf-ensure] ERROR: perf-capture tool not found at $PERF_CAPTURE_BIN" >&2
    exit 1
  fi
  log "Running perf-capture: $PERF_CAPTURE_BIN"
  # Use subshell to isolate any options changes
  if ! zsh "$PERF_CAPTURE_BIN" >/dev/null 2>&1; then
    echo "[perf-ensure] ERROR: perf-capture execution failed" >&2
    exit 2
  fi
else
  log "No regeneration required"
fi

# -------------- Post-Check --------------
missing=0
[[ -f "$CUR_JSON" ]] || { echo "[perf-ensure] ERROR: perf-current.json missing after ensure pass" >&2; missing=1; }
[[ -f "$CUR_SEGMENTS" ]] || { echo "[perf-ensure] ERROR: perf-current-segments.txt missing after ensure pass" >&2; missing=1; }

if (( missing == 1 )); then
  exit 3
fi

log "Artifacts ready (json=$(file_age "$CUR_JSON")s old, segments=$(file_age "$CUR_SEGMENTS")s old)"

# -------------- Summary (concise) --------------
if [[ $PERF_ENSURE_VERBOSE == 1 ]]; then
  echo "[perf-ensure] OK: perf-current.json & perf-current-segments.txt present (max_age=${PERF_ENSURE_MAX_AGE_SEC}s)"
fi

exit 0
