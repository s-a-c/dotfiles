#!/usr/bin/env zsh
# sync-readme-performance-status.zsh
# Compliant with ${HOME}/dotfiles/dot-config/ai/guidelines.md v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Synchronize the performance classifier status block in docs/redesignv2/README.md
#   between managed markers:
#
#       <!-- BEGIN:PERF_CLASSIFIER_STATUS -->
#       ... (auto generated content) ...
#       <!-- END:PERF_CLASSIFIER_STATUS -->
#
#   The content is derived from a JSON status file produced by
#   tools/update-performance-status.zsh (multi-metric classifier output aggregator).
#
# FEATURES:
#   - Idempotent: only rewrites README if block changes
#   - --check mode for CI gating (non-zero exit if README out of sync)
#   - --diff mode to display unified diff without modifying README
#   - DRY_RUN mode (env) to preview
#   - Graceful placeholder output when status JSON absent (non-failing)
#   - Robust JSON parsing without external dependencies (no jq)
#
# EXIT CODES:
#   0  Success / already in sync
#   1  Usage / argument error
#   2  Status JSON parse failure
#   3  Out of sync (check/diff mode) or diff shown
#   4  Write failure
#
# USAGE:
#   tools/sync-readme-performance-status.zsh
#   DRY_RUN=1 tools/sync-readme-performance-status.zsh
#   tools/sync-readme-performance-status.zsh --check
#   tools/sync-readme-performance-status.zsh --diff
#   tools/sync-readme-performance-status.zsh --json docs/redesignv2/artifacts/metrics/perf_classifier_status.json
#
# ENVIRONMENT:
#   DRY_RUN=1   Do not modify README (preview)
#   VERBOSE=1   Extra diagnostic output
#
# IMPLEMENTATION NOTES:
#   - JSON parsing uses targeted sed/grep since schema is controlled.
#   - Missing JSON is treated as "pending" status; block becomes a placeholder.
#   - A placeholder never triggers failure in --check (treated as synchronized if README already contains matching placeholder).
#
# FUTURE ENHANCEMENTS:
#   - Add optional numeric stale threshold (warn if generated_at older than X hours)
#   - Support alternative rendering (badge summaries)
#

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:A}/.."
REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"

DOC_ROOT="${REPO_ROOT}/docs/redesignv2"
README_FILE="${DOC_ROOT}/README.md"
DEFAULT_STATUS_JSON="${DOC_ROOT}/artifacts/metrics/perf_classifier_status.json"

HEADER_MARK="<!-- BEGIN:PERF_CLASSIFIER_STATUS -->"
FOOTER_MARK="<!-- END:PERF_CLASSIFIER_STATUS -->"

DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"
MODE_CHECK=0
MODE_DIFF=0
STATUS_JSON="$DEFAULT_STATUS_JSON"

print_err() { print -r -- "[perf-sync][ERROR] $*" >&2; }
print_info() { (( VERBOSE )) && print -r -- "[perf-sync][INFO]  $*" >&2 || true; }
print_warn() { print -r -- "[perf-sync][WARN]  $*" >&2; }

usage() {
  cat <<EOF
Usage: ${0:t} [--check] [--diff] [--json <status.json>] [--help]

Synchronize performance classifier status block in README.md.

Options:
  --check            Exit 3 if README is out of sync (no modifications)
  --diff             Show unified diff (implies DRY_RUN; exit 3 if mismatch)
  --json <file>      Path to status JSON (default: $DEFAULT_STATUS_JSON)
  --help             Show this help

Environment:
  DRY_RUN=1          Preview changes (no write)
  VERBOSE=1          Verbose logging

Exit Codes:
  0 success / already in sync / updated
  1 usage error
  2 status JSON parse failure
  3 out of sync (check/diff mode) or diff shown
  4 write failure
EOF
}

# ---------------- Argument Parsing ----------------
while (( $# > 0 )); do
  case "$1" in
    --check) MODE_CHECK=1 ;;
    --diff)  MODE_DIFF=1; DRY_RUN=1 ;;
    --json)
      shift
      STATUS_JSON="${1:-}"
      [[ -n "$STATUS_JSON" ]] || { print_err "--json requires a value"; exit 1; }
      ;;
    --json=*)
      STATUS_JSON="${1#*=}"
      ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      print_err "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

# ---------------- Pre-flight Checks ----------------
[[ -r "$README_FILE" ]] || { print_err "Cannot read README file: $README_FILE"; exit 2; }

# ---------------- JSON Extraction ----------------
# If the status JSON does not exist, we generate a placeholder.
STATUS_CONTENT=""
if [[ -f "$STATUS_JSON" ]]; then
  if [[ ! -r "$STATUS_JSON" ]]; then
    print_err "Status JSON exists but not readable: $STATUS_JSON"
    exit 2
  fi
  STATUS_CONTENT="$(<"$STATUS_JSON")"
else
  print_warn "Status JSON not found: $STATUS_JSON (using placeholder pending block)"
fi

# Parsing helpers (only if we have content)
overall_status=""
ok_streak_current=""
ok_streak_max=""
enforce_active=""
generated_at=""
declare -A metric_status metric_mean metric_base metric_delta metric_rsd

parse_json_field() {
  # Simple pattern extract: field appears as "name": value or "name": "value"
  local name="$1" raw
  raw="$(grep -E "\"$name\"" <<<"$STATUS_CONTENT" | head -n1 | sed -E 's/.*"'$name'":[[:space:]]*//' )" || return 1
  # Strip trailing commas
  raw="${raw%%,*}"
  raw="${raw%% }"
  raw="${raw%%	}"
  # Remove surrounding quotes
  raw="${raw%\"}"
  raw="${raw#\"}"
  print -r -- "$raw"
}

extract_metrics() {
  # Extract between "metrics": { ... }
  local block
  block="$(awk '/"metrics"[[:space:]]*:/,/^[[:space:]]*}/' <<<"$STATUS_CONTENT")" || return 0
  # Each metric line looks like: "prompt_ready":{...}
  # We'll break into lines with metric keys
  grep -E '^[[:space:]]*"' <<<"$block" | while IFS= read -r line; do
    # metric key
    local key
    key="$(sed -n 's/^[[:space:]]*"\([^"]\+\)".*/\1/p' <<<"$line")" || true
    [[ -z "$key" ]] && continue
    # For each field inside this metric object, we extract from following lines until '},'
    # Simpler: capture sub-object inline using sed
    local obj
    obj="$(echo "$block" | sed -n "/\"$key\"[[:space:]]*:/,/},/p")"
    metric_status[$key]="$(grep -E '"status"' <<<"$obj" | head -n1 | sed -E 's/.*"status":[[:space:]]*"([^"]+)".*/\1/' )"
    metric_mean[$key]="$(grep -E '"mean_ms"' <<<"$obj" | head -n1 | sed -E 's/.*"mean_ms":[[:space:]]*([0-9]+).*/\1/' )"
    metric_base[$key]="$(grep -E '"baseline_mean_ms"' <<<"$obj" | head -n1 | sed -E 's/.*"baseline_mean_ms":[[:space:]]*([0-9]+).*/\1/' )"
    metric_delta[$key]="$(grep -E '"delta_pct"' <<<"$obj" | head -n1 | sed -E 's/.*"delta_pct":[[:space:]]*([0-9.]+).*/\1/' )"
    metric_rsd[$key]="$(grep -E '"rsd_pct"' <<<"$obj" | head -n1 | sed -E 's/.*"rsd_pct":[[:space:]]*([0-9.]+).*/\1/' )"
  done
}

if [[ -n "$STATUS_CONTENT" ]]; then
  overall_status="$(parse_json_field "overall_status" || true)"
  ok_streak_current="$(parse_json_field "ok_streak_current" || true)"
  ok_streak_max="$(parse_json_field "ok_streak_max" || true)"
  enforce_active="$(parse_json_field "enforce_active" || true)"
  generated_at="$(parse_json_field "generated_at" || true)"
  extract_metrics
  # Basic validation: overall_status present implies valid parse
  if [[ -z "$overall_status" ]]; then
    print_warn "Could not parse overall_status; will fall back to placeholder."
    STATUS_CONTENT=""
  fi
fi

# ---------------- Build Managed Block ----------------
build_placeholder_block() {
  cat <<'EOF'
<!-- BEGIN:PERF_CLASSIFIER_STATUS -->
<!-- NOTE: AUTO-GENERATED by tools/sync-readme-performance-status.zsh. Do NOT edit inside markers. -->
Status: pending (classifier enforce activation not yet logged; streak < 3 or status JSON unavailable)
<!-- END:PERF_CLASSIFIER_STATUS -->
EOF
}

build_full_block() {
  local status_line table_lines updated_ts
  local enforce_val streak_line
  enforce_val="${enforce_active:-false}"
  local s_current="${ok_streak_current:-0}"
  local s_max="${ok_streak_max:-0}"
  updated_ts="${generated_at:-unknown}"
  status_line="Status: ${overall_status} (streak ${s_current}/${s_max}; enforce: ${enforce_val})"

  # Build metrics table
  local keys key
  keys=(${(ok)metric_status})
  if (( ${#keys[@]} == 0 )); then
    table_lines="(No metrics parsed)"
  else
    # Sort keys for deterministic output
    keys=(${(on)keys})
    table_lines="| Metric | Mean | Baseline | Δ% | RSD | Status |\n|--------|------|----------|----|-----|--------|"
    for key in "${keys[@]}"; do
      local mean="${metric_mean[$key]:-0}"
      local base="${metric_base[$key]:-0}"
      local delta="${metric_delta[$key]:-0}"
      local rsd="${metric_rsd[$key]:-0}"
      local st="${metric_status[$key]:-UNKNOWN}"
      # Normalize delta formatting
      [[ "$delta" != "0" && "$delta" != "0.0" ]] && delta="+${delta}"
      table_lines+="\n| ${key} | ${mean} | ${base} | ${delta}% | ${rsd}% | ${st} |"
    done
  fi

  cat <<EOF
$HEADER_MARK
<!-- NOTE: AUTO-GENERATED by tools/sync-readme-performance-status.zsh. Do NOT edit inside markers. -->
${status_line}
${table_lines}
Updated: ${updated_ts} UTC
$FOOTER_MARK
EOF
}

MANAGED_BLOCK=""
if [[ -z "$STATUS_CONTENT" ]]; then
  MANAGED_BLOCK="$(build_placeholder_block)"
else
  MANAGED_BLOCK="$(build_full_block)"
fi

# Ensure trailing newline
[[ "${MANAGED_BLOCK[-1]}" == $'\n' ]] || MANAGED_BLOCK+=$'\n'

# ---------------- Generate Updated README Content ----------------
README_ORIG_CONTENT="$(<"$README_FILE")"

if ! grep -q "$HEADER_MARK" "$README_FILE"; then
  print_info "Managed performance status markers not found; appending block near segments block."
  # Attempt to place block after existing PERF_CLASSIFIER_STATUS placeholder if absent we append near end.
  NEW_README_CONTENT="${README_ORIG_CONTENT}"$'\n'"${MANAGED_BLOCK}"
else
  # Replace existing block using awk approach similar to segment sync script.
  block_file="$(mktemp -t perf-status-block.XXXXXX)"
  printf "%s" "$MANAGED_BLOCK" > "$block_file"
  trap 'rm -f "$block_file"' EXIT INT TERM
  NEW_README_CONTENT=$(
    awk -v hdr="$HEADER_MARK" -v ftr="$FOOTER_MARK" -v bf="$block_file" '
      function emit_block() {
        while ( (getline line < bf) > 0 ) { print line }
        close(bf)
      }
      {
        if ($0 == hdr) {
          emit_block()
          skip=1
          next
        }
        if ($0 == ftr && skip) {
          # Footer already emitted as part of managed block
          skip=0
          next
        }
        if (!skip) print
      }
    ' "$README_FILE"
  )
fi

# ---------------- Compare & Actions ----------------
if [[ "$NEW_README_CONTENT" == "$README_ORIG_CONTENT" ]]; then
  print_info "README performance status block already in sync; no changes."
  if (( MODE_CHECK || MODE_DIFF )); then
    exit 0
  fi
  exit 0
fi

# Show diff if requested
if (( MODE_DIFF )); then
  if command -v diff >/dev/null 2>&1; then
    tmp_orig="$(mktemp -t perf-status-orig.XXXXXX)"
    tmp_new="$(mktemp -t perf-status-new.XXXXXX)"
    printf "%s" "$README_ORIG_CONTENT" > "$tmp_orig"
    printf "%s" "$NEW_README_CONTENT" > "$tmp_new"
    print_warn "README performance status block out of sync. Showing diff:"
    diff -u "$tmp_orig" "$tmp_new" || true
    rm -f "$tmp_orig" "$tmp_new"
  else
    print_warn "diff utility not found; cannot show unified diff."
  fi
  exit 3
fi

# Check mode (no write)
if (( MODE_CHECK )); then
  print_warn "README performance status block is out of sync (run sync script to update)."
  exit 3
fi

# DRY RUN preview
if (( DRY_RUN )); then
  print_warn "DRY_RUN=1 → README would be updated. Preview of managed block:"
  print -r -- "----- BEGIN PERF CLASSIFIER BLOCK -----"
  print -r -- "${MANAGED_BLOCK}"
  print -r -- "----- END PERF CLASSIFIER BLOCK -----"
  exit 0
fi

# Write updated README
tmp_write="$(mktemp -t perf-status-write.XXXXXX)" || { print_err "Could not create temp file"; exit 4; }
printf "%s" "$NEW_README_CONTENT" > "$tmp_write" || { print_err "Failed writing temp file"; rm -f "$tmp_write"; exit 4; }
mv "$tmp_write" "$README_FILE" || { print_err "Failed to replace README (mv failed)"; rm -f "$tmp_write"; exit 4; }

print_info "README performance status block updated."
print -r -- "[perf-sync] SUCCESS: README performance status synchronized."
exit 0
