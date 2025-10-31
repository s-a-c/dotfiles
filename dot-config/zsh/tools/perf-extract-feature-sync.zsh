#!/usr/bin/env zsh
# ==============================================================================
# File: tools/perf-extract-feature-sync.zsh
#
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v3fb33a85972b794c3c0b2f992b1e5a7c19cfbd2ccb3bb519f8865ad8fdfc0316
#
# Purpose:
#   Extract per-feature synchronous init timing and invocation status produced
#   by the Stage 4 feature invocation wrapper. This script launches a clean
#   (-f) Zsh session, loads all feature modules (excluding template), invokes
#   registry phases (preload, init, optionally postprompt), and captures:
#     - ZSH_FEATURE_TIMINGS_SYNC[name]=<ms>
#     - ZSH_FEATURE_STATUS[name]=(ok|error)
#
# Output Modes:
#   --json       Emit JSON document (default if stdout is not a TTY)
#   --raw        Emit plain key=value lines (timings first, then status)
#   --table      Emit human-readable table (default if stdout is a TTY)
#   --all        Emit table + JSON (table to stderr, JSON to stdout)
#
# Exit Codes:
#   0 success
#   1 usage error
#   2 collection failure (no timings captured)
#
# Notes:
#   - Requires the invocation wrapper (feature_registry_invoke_phase) with
#     telemetry support already loaded in registry.
#   - Telemetry is activated via ZSH_FEATURE_TELEMETRY=1 inside the child shell.
#   - Timing currently covers only init phase (by design).
#
# Sensitive Actions:
#   - None. No external network or PATH mutation beyond sourcing local features.
#
# Example:
#   tools/perf-extract-feature-sync.zsh --json > feature-timings.json
#   tools/perf-extract-feature-sync.zsh --table
#
# JSON Schema (informal):
# {
#   "schema": "feature-sync-timings.v1",
#   "timestamp": "2025-09-10T12:34:56Z",
#   "shell": "/bin/zsh",
#   "phases_invoked": ["preload","init"],
#   "features": [
#     {"name":"noop","timing_ms":2,"status":"ok","phase":"init"}
#   ],
#   "summary": {"count":1,"errors":0}
# }
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# Defaults / Options
# ------------------------------------------------------------------------------
MODE=""
INVOKE_POSTPROMPT=0
FEATURE_GLOB="feature/*.zsh"
ZSH_BIN="${ZSH_BIN:-${SHELL:-/bin/zsh}}"
INVOKE_PHASES=(preload init)
OUTPUT_FILE=""
QUIET=0

print_usage() {
  cat <<'EOF'
perf-extract-feature-sync.zsh - Extract per-feature synchronous init timings

Usage: perf-extract-feature-sync.zsh [options]

Options:
  --json              Emit JSON
  --raw               Emit raw key=value lines
  --table             Emit table
  --all               Emit table (stderr) + JSON (stdout)
  --postprompt        Also invoke postprompt phase (for deferred features)
  --zsh PATH          Use specific zsh binary (default: $SHELL or /bin/zsh)
  --features GLOB     Feature module glob (default: feature/*.zsh)
  --output FILE       Write JSON output to file (implies --json)
  --quiet             Suppress non-error stderr (table suppressed)
  --help              Show help

Environment:
  ZSH_FEATURE_TELEMETRY=1 (forced inside child to collect timings)

Exit Codes:
  0 success
  1 usage error
  2 collection failure (no timings)
EOF
}

# Parse args
while (( $# > 0 )); do
  case "$1" in
    --json) MODE="json";;
    --raw) MODE="raw";;
    --table) MODE="table";;
    --all) MODE="all";;
    --postprompt) INVOKE_POSTPROMPT=1;;
    --zsh) shift; ZSH_BIN="$1";;
    --features) shift; FEATURE_GLOB="$1";;
    --output) shift; OUTPUT_FILE="$1"; MODE="json";;
    --quiet) QUIET=1;;
    --help|-h) print_usage; exit 0;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 1;;
  esac
  shift
done

# Auto mode selection if not specified
if [[ -z "$MODE" ]]; then
  if [[ -t 1 ]]; then
    MODE="table"
  else
    MODE="json"
  fi
fi

if ! command -v "$ZSH_BIN" >/dev/null 2>&1; then
  echo "Error: zsh binary not found: $ZSH_BIN" >&2
  exit 1
fi

if (( INVOKE_POSTPROMPT )); then
  INVOKE_PHASES+=(postprompt)
fi

# ------------------------------------------------------------------------------
# Locate repo root relative to script (assumes standard layout)
# ------------------------------------------------------------------------------
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR%/tools}"
# Basic sanity
if [[ ! -d "${REPO_ROOT}/feature/registry" ]]; then
  echo "Error: Could not locate feature registry directory at: ${REPO_ROOT}/feature/registry" >&2
  exit 1
fi

# ------------------------------------------------------------------------------
# Build child shell script to capture timing & status
# ------------------------------------------------------------------------------
CHILD_SCRIPT=$(
cat <<'EOS'
# Child shell executed with -f (no user config)
setopt NO_prompt_subst
set -u
# Enable telemetry
export ZSH_FEATURE_TELEMETRY=1
# Source registry first
source "feature/registry/feature-registry.zsh"

# Source all feature modules except template safely
for f in feature/*.zsh; do
  case "$f" in
    *"_TEMPLATE_FEATURE_MODULE.zsh") continue;;
  esac
  # shellcheck disable=SC1090
  source "$f"
done

# Invoke phases passed from parent
for ph in __PHASE_LIST__; do
  feature_registry_invoke_phase "$ph" || true
done

print -- "__FEATURE_TIMINGS_START__"
if typeset -p ZSH_FEATURE_TIMINGS_SYNC >/dev/null 2>&1; then
  for k in ${(k)ZSH_FEATURE_TIMINGS_SYNC}; do
    print -- "$k=${ZSH_FEATURE_TIMINGS_SYNC[$k]}"
  done
fi
print -- "__FEATURE_TIMINGS_END__"

print -- "__FEATURE_STATUS_START__"
if typeset -p ZSH_FEATURE_STATUS >/dev/null 2>&1; then
  for k in ${(k)ZSH_FEATURE_STATUS}; do
    print -- "$k=${ZSH_FEATURE_STATUS[$k]}"
  done
fi
print -- "__FEATURE_STATUS_END__"
EOS
)

# Replace phase list placeholder
PHASE_WORDS="${INVOKE_PHASES[*]}"
CHILD_SCRIPT="${CHILD_SCRIPT/__PHASE_LIST__/$PHASE_WORDS}"

# ------------------------------------------------------------------------------
# Execute child shell
# ------------------------------------------------------------------------------
RAW_OUTPUT="$("$ZSH_BIN" -f -c "cd '$REPO_ROOT'; ${CHILD_SCRIPT:q}")" || {
  echo "Error: child shell execution failed" >&2
  exit 2
}

# ------------------------------------------------------------------------------
# Parse output
# ------------------------------------------------------------------------------
typeset -A TIMINGS STATUS
mode=""
while IFS= read -r line; do
  case "$line" in
    __FEATURE_TIMINGS_START__) mode="timings";;
    __FEATURE_TIMINGS_END__) mode="";;
    __FEATURE_STATUS_START__) mode="status";;
    __FEATURE_STATUS_END__) mode="";;
    *)
      if [[ "$mode" == "timings" ]]; then
        if [[ "$line" == *"="* ]]; then
          k="${line%%=*}"
            v="${line#*=}"
          [[ "$v" == <-> ]] || v=0
          TIMINGS["$k"]="$v"
        fi
      elif [[ "$mode" == "status" ]]; then
        if [[ "$line" == *"="* ]]; then
          k="${line%%=*}"
          v="${line#*=}"
          STATUS["$k"]="$v"
        fi
      fi
      ;;
  esac
done <<<"$RAW_OUTPUT"

if (( ${#TIMINGS[@]} == 0 )); then
  echo "Error: No feature timings captured (ensure telemetry + feature registry wrapper are active)" >&2
  exit 2
fi

# ------------------------------------------------------------------------------
# Formatters
# ------------------------------------------------------------------------------
emit_raw() {
  for k in ${(on)${(@k)TIMINGS}}; do
    print -- "timing.$k=${TIMINGS[$k]}"
  done
  for k in ${(on)${(@k)STATUS}}; do
    print -- "status.$k=${STATUS[$k]}"
  done
}

emit_table() {
  printf "%-24s %-8s %-8s\n" "FEATURE" "MS" "STATUS"
  printf "%-24s %-8s %-8s\n" "-------" "----" "------"
  for k in ${(on)${(@k)TIMINGS}}; do
    printf "%-24s %-8s %-8s\n" "$k" "${TIMINGS[$k]}" "${STATUS[$k]:-unknown}"
  done
  # Summary
  local errors=0
  for v in ${(v)STATUS}; do
    [[ "$v" == "error" ]] && (( errors++ ))
  done
  printf "\nSummary: features=%d errors=%d phases=%s\n" "${#TIMINGS[@]}" "$errors" "$PHASE_WORDS"
}

emit_json() {
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print -- "{"
  print -- "  \"schema\": \"feature-sync-timings.v1\","
  print -- "  \"timestamp\": \"${ts}\","
  print -- "  \"shell\": \"${ZSH_BIN}\","
  printf "  \"phases_invoked\": ["
  local i=1
  for ph in "${INVOKE_PHASES[@]}"; do
    printf "\"%s\"%s" "$ph" $(( i == ${#INVOKE_PHASES[@]} ))?"" :","
    (( i++ ))
  done
  print -- "],"
  print -- "  \"features\": ["
  local keys=("${(@k)TIMINGS}")
  keys=("${(on)keys}")
  local idx=1
  for k in "${keys[@]}"; do
    local comma=","
    (( idx == ${#keys[@]} )) && comma=""
    printf '    {"name":"%s","timing_ms":%s,"status":"%s"}%s\n' \
      "$k" "${TIMINGS[$k]}" "${STATUS[$k]:-unknown}" "$comma"
    (( idx++ ))
  done
  # Summary
  local errors=0
  for v in ${(v)STATUS}; do
    [[ "$v" == "error" ]] && (( errors++ ))
  done
  print -- "  ],"
  print -- "  \"summary\": {\"count\": ${#TIMINGS[@]}, \"errors\": $errors}"
  print -- "}"
}

# ------------------------------------------------------------------------------
# Output Dispatch
# ------------------------------------------------------------------------------
case "$MODE" in
  raw)
    emit_raw
    ;;
  table)
    (( QUIET )) || emit_table
    ;;
  json)
    if [[ -n "$OUTPUT_FILE" ]]; then
      emit_json > "$OUTPUT_FILE"
    else
      emit_json
    fi
    ;;
  all)
    (( QUIET )) || emit_table >&2
    emit_json
    ;;
  *)
    echo "Internal error: unknown mode '$MODE'" >&2
    exit 1
    ;;
esac

exit 0
