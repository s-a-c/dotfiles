#!/usr/bin/env zsh
# report-layer-health.zsh
# Phase 7 (Optional Enhancements) – Layer Health & Integrity Report
#
# Purpose:
#   Produce a concise, machine + human readable snapshot of the active (or
#   specified) layer set state: widget counts, key feature markers, segment
#   capture status, abbreviation packs, PNPM flags, styling, autopair,
#   and (optionally) segment validation results.
#
# Features:
#   * Safe (nounset-aware) execution (set -euo pipefail)
#   * Optional JSON output (compact or pretty)
#   * Optional widget baseline enforcement
#   * Optional segment file validation (leverages existing validator)
#   * Zero modification of local user config (reads only)
#   * Single-pass zsh probe for markers to avoid repeated shell startup
#
# Usage:
#   report-layer-health.zsh
#   report-layer-health.zsh --json --pretty
#   report-layer-health.zsh --baseline-widgets 417 --fail-on-regression
#   report-layer-health.zsh --segments-file ~/.cache/zsh/segments/live-segments.ndjson --validate-segments
#
# Exit Codes:
#   0 success (and health OK unless --fail-on-regression triggered a fail)
#   1 health / baseline / validation failure (when gating flags used)
#   2 usage error or missing dependency (validator requested but absent)
#   3 internal unexpected error
#
# JSON Schema (top-level keys):
# {
#   "timestamp": "...UTC...",
#   "layer": "00",
#   "symlink_targets": {
#      ".zshrc.d": ".zshrc.d.00",
#      ".zshrc.pre-plugins.d": ".zshrc.pre-plugins.d.00",
#      ".zshrc.add-plugins.d": ".zshrc.add-plugins.d.00"
#   },
#   "widgets": 417,
#   "baseline": 417,
#   "widget_pass": true,
#   "markers": {
#      "_ZF_CARAPACE_STYLES": 1,
#      "_ZF_SEGMENT_CAPTURE": 0,
#      "_ZF_ABBR": 1,
#      "_ZF_ABBR_PACK_CORE": 1,
#      "_ZF_ABBR_BREW": 1,
#      "_ZF_ABBR_BREW_COUNT": 12,
#      "_ZF_PNPM": 1,
#      "_ZF_PNPM_FLAGS": 1,
#      "_ZF_STARSHIP_INIT_MS": "7.12",
#      "_ZF_SEGMENT_CAPTURE_FILE": "/path/...",
#      "_ZF_LAYER_SET": "00"
#   },
#   "autopair": {
#      "present": true,
#      "widgets": ["autopair-insert", "..."]
#   },
#   "segments": {
#      "file": "/path/segments/live-segments.ndjson",
#      "exists": true,
#      "validated": true,
#      "validator_available": true
#   },
#   "fail_reasons": []
# }
#
# Policy Alignment:
#   * No silent stderr suppression (except narrow non-critical probes)
#   * Nounset-safe expansions
#   * Minimal diff surface (self-contained tool)
#
# Limitations:
#   * Does not transform or canonicalize segment logs (use segment-canonicalize.sh separately).
#   * If validator is not executable and validation was requested, exits non-zero.
#
# -----------------------------------------------------------------------------

set -euo pipefail

# ---------------------------
# Defaults / Option Parsing
# ---------------------------
JSON=0
PRETTY=0
BASELINE=""
FAIL_ON_REGRESSION=0
SEG_FILE=""
VALIDATE_SEGMENTS=0
STRICT_SEGMENTS=0
# (moved baseline_json computation until after argument parsing to ensure final BASELINE value)

usage() {
  sed -n '1,/^# -----------------------------------------------------------------------------/p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --json                  Emit JSON instead of human summary
  --pretty                Pretty-print JSON (if --json)
  --baseline-widgets <N>  Specify expected minimum widget baseline
  --fail-on-regression    Return exit 1 if widgets < baseline
  --segments-file <path>  Provide a segment (NDJSON/JSON) file path for metadata
  --validate-segments     Run validator (fail if invalid)
  --strict-segments       Use validator --strict (implies --validate-segments)
  --help                  Show this help

Examples:
  report-layer-health.zsh --json --pretty --baseline-widgets 417 --fail-on-regression
  report-layer-health.zsh --segments-file ~/.cache/zsh/segments/live-segments.ndjson --validate-segments

EOF
}

while (($#)); do
  case "$1" in
    --json) JSON=1 ;;
    --pretty) PRETTY=1 ;;
    --baseline-widgets)
      shift || { echo "ERROR: --baseline-widgets requires a value" >&2; exit 2; }
      BASELINE="$1"
      ;;
    --fail-on-regression) FAIL_ON_REGRESSION=1 ;;
    --segments-file)
      shift || { echo "ERROR: --segments-file requires a path" >&2; exit 2; }
      SEG_FILE="$1"
      ;;
    --validate-segments) VALIDATE_SEGMENTS=1 ;;
    --strict-segments) VALIDATE_SEGMENTS=1; STRICT_SEGMENTS=1 ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

# Compute baseline_json after argument parsing (zsh-safe)
baseline_json="$BASELINE"
if [[ -z "$baseline_json" ]]; then
  baseline_json="null"
fi

# ---------------------------
# Helper Functions
# ---------------------------

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

json_escape() {
  local s=${1:-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

# Derive symlink targets (ignore errors if not symlink)
symlink_target_or_empty() {
  local p=$1
  if [[ -L "$p" ]]; then
    readlink "$p" 2>/dev/null || true
  fi
}

_require_number() {
  local v=$1
  [[ "$v" =~ ^[0-9]+$ ]]
}

# ---------------------------
# Zsh Probe for Markers / Widgets / Autopair
# ---------------------------
# We spawn a single interactive-capable shell to gather:
# - widget count
# - autopair widgets
# - exported markers (select set)
# This avoids multiple startups.

probe_script=$(mktemp)
trap 'rm -f "$probe_script"' EXIT

cat > "$probe_script" <<'ZEOF'
set +o errexit
set +o nounset

# Source active symlinked directories in canonical order
for dir in .zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d; do
  if [[ -d $dir ]]; then
    for f in "$dir"/*.zsh; do
      # shellcheck disable=SC1090
      source "$f" 2>/dev/null || print -u2 "#WARN failed sourcing $f"
    done
  fi
done

autoload -Uz zle 2>/dev/null || true

widgets_total=0
if zle -la >/dev/null 2>&1; then
  widgets_total=$(zle -la | wc -l | tr -d '[:space:]')
fi
print "__WIDGETS_TOTAL=${widgets_total}"

# Collect relevant markers (if set); we explicitly list them to avoid dumping the full env.
for m in _ZF_CARAPACE_STYLES _ZF_SEGMENT_CAPTURE _ZF_SEGMENT_CAPTURE_FILE _ZF_ABBR _ZF_ABBR_PACK_CORE \
          _ZF_ABBR_BREW _ZF_ABBR_BREW_COUNT _ZF_PNPM _ZF_PNPM_FLAGS _ZF_STARSHIP_INIT_MS _ZF_LAYER_SET; do
  eval v=\"\${$m-}\"
  [[ -n "$v" ]] && print "__MARKER_${m}=$v"
done

# Autopair detection
_present=0
autopair_widgets=""
if zle -la 2>/dev/null | grep -qi autopair; then
  _present=1
  autopair_widgets="$(zle -la | grep -i autopair || true)"
fi
print "__AUTOPAIR_PRESENT=${_present}"
if [[ -n "${autopair_widgets}" ]]; then
  while IFS= read -r w; do
    [[ -n "$w" ]] && print "__AUTOPAIR_WIDGET=$w"
  done <<< "${autopair_widgets}"
fi

exit 0
ZEOF

probe_out=$(mktemp)
trap 'rm -f "$probe_out"' EXIT

if ! zsh -i --no-rcs --no-globalrcs "$probe_script" >"$probe_out" 2>/dev/null; then
  echo "ERROR: Failed to execute zsh probe." >&2
  [[ $JSON -eq 1 ]] && echo '{"error":"probe_failed"}'
  exit 3
fi

_zf_layer_widgets=$(grep '^__WIDGETS_TOTAL=' "$probe_out" | head -n1 | cut -d= -f2 || echo 0)
_autopair_present=$(grep '^__AUTOPAIR_PRESENT=' "$probe_out" | head -n1 | cut -d= -f2 || echo 0)
autopair_widgets=()
while IFS= read -r _apw; do
  [[ -n "$_apw" ]] && autopair_widgets+=("$_apw")
done < <(grep '^__AUTOPAIR_WIDGET=' "$probe_out" | sed 's/^__AUTOPAIR_WIDGET=//' || true)

declare -A MARKERS=()
while IFS= read -r line; do
  key=${line#__MARKER_}
  key=${key%%=*}
  val=${line#*=}
  MARKERS["$key"]="$val"
done < <(grep '^__MARKER_' "$probe_out" || true)

layer_from_marker="${MARKERS[_ZF_LAYER_SET]:-}"
# Fallback: parse symlink targets if marker missing
[[ -z "$layer_from_marker" ]] && layer_from_marker=$(basename "$(symlink_target_or_empty .zshrc.d 2>/dev/null || echo "")" | sed -E 's/.*\.([0-9]{2})$/\1/' || true)

# ---------------------------
# Segment File Handling
# ---------------------------
seg_exists=false
seg_valid_json=null
validator_available=false
seg_validation_fail_reason=""
if [[ -n "$SEG_FILE" ]]; then
  if [[ -f "$SEG_FILE" ]]; then
    seg_exists=true
    # Simple structural sniff (not full validation) – check if starts with '{', '[' or JSON-ish lines '{}'
    if head -n1 "$SEG_FILE" | grep -Eq '^[[:space:]]*[\{\[]'; then
      seg_valid_json=true
    else
      # NDJSON heuristic: any line starting with '{'
      if grep -q '^[[:space:]]*{' "$SEG_FILE"; then
        seg_valid_json=true
      else
        seg_valid_json=false
      fi
    fi
    if (( VALIDATE_SEGMENTS == 1 )); then
      validator="docs/fix-zle/tests/validate-segments.sh"
      if [[ -x "$validator" ]]; then
        validator_available=true
        val_args=()
        (( STRICT_SEGMENTS == 1 )) && val_args+=(--strict)
        if "$validator" "${val_args[@]}" --quiet "$SEG_FILE"; then
          seg_valid_json=true
        else
          seg_valid_json=false
          seg_validation_fail_reason="validator_failed"
        fi
      else
        validator_available=false
        seg_validation_fail_reason="validator_missing"
      fi
    fi
  else
    seg_exists=false
    seg_valid_json=false
    seg_validation_fail_reason="not_found"
  fi
fi

# ---------------------------
# Widget Baseline Logic
# ---------------------------
widget_pass=true
fail_reasons=()
if [[ -n "$BASELINE" ]]; then
  if _require_number "$BASELINE"; then
    if ! _require_number "$_zf_layer_widgets"; then
      widget_pass=false
      fail_reasons+=("widget_count_non_numeric")
    else
      if (( _zf_layer_widgets < BASELINE )); then
        widget_pass=false
        fail_reasons+=("widget_regression:${_zf_layer_widgets}<${BASELINE}")
      fi
    fi
  else
    fail_reasons+=("invalid_baseline:${BASELINE}")
  fi
fi

# Segment validation gating failure reason
if (( VALIDATE_SEGMENTS == 1 )); then
  if [[ "$seg_exists" == true && "$seg_valid_json" == false ]]; then
    fail_reasons+=("segment_validation_failed:${seg_validation_fail_reason}")
  elif [[ "$seg_exists" == false ]]; then
    fail_reasons+=("segment_file_missing")
  fi
fi

# Autopair presence note: if desired we could enforce, but currently optional.
# (Could add gating via a future --require-autopair flag.)

# ---------------------------
# Human Output (default)
# ---------------------------
if (( JSON == 0 )); then
  echo "=== Layer Health Report ($(timestamp_utc)) ==="
  echo "Layer Set: ${layer_from_marker:-unknown}"
  echo "Symlink Targets:"
  for p in .zshrc.pre-plugins.d .zshrc.add-plugins.d .zshrc.d; do
    tgt=$(symlink_target_or_empty "$p")
    printf "  %-28s -> %s\n" "$p" "${tgt:-<not-symlink>}"
  done
  echo ""
  echo "Widgets: $_zf_layer_widgets"
  [[ -n "$BASELINE" ]] && echo "Baseline: $BASELINE (pass=$widget_pass)"
  echo ""
  echo "Markers:"
  # zsh associative array key iteration
  for k in "${(@k)MARKERS}"; do
    printf "  %-24s = %s\n" "$k" "${MARKERS[$k]}"
  done | sort
  echo ""
  echo "Autopair:"
  echo "  Present: $_autopair_present"
  if ((${#autopair_widgets[@]} > 0)); then
    echo "  Widgets:"
    for w in "${autopair_widgets[@]}"; do
      echo "    - $w"
    done
  fi
  echo ""
  if [[ -n "$SEG_FILE" ]]; then
    echo "Segments:"
    echo "  File: $SEG_FILE"
    echo "  Exists: $seg_exists"
    echo "  Structural Valid: $seg_valid_json"
    if (( VALIDATE_SEGMENTS == 1 )); then
      echo "  Validator Available: $validator_available"
      echo "  Validation Mode: $([[ $STRICT_SEGMENTS -eq 1 ]] && echo strict || echo standard)"
      [[ -n "$seg_validation_fail_reason" ]] && echo "  Validation Info: $seg_validation_fail_reason"
    fi
    echo ""
  fi
  if ((${#fail_reasons[@]} > 0)); then
    echo "Fail Reasons:"
    for r in "${fail_reasons[@]}"; do
      echo "  - $r"
    done
  else
    echo "Fail Reasons: (none)"
  fi
else
  # ---------------------------
  # JSON Output
  # ---------------------------
  # Build JSON manually (simple / safe escaping for values we control)
  json_autopair_widgets="[]"
  if ((${#autopair_widgets[@]} > 0)); then
    json_autopair_widgets="["
    first=1
    for w in "${autopair_widgets[@]}"; do
      [[ -z "$w" ]] && continue
      esc=$(json_escape "$w")
      if [[ $first -eq 0 ]]; then json_autopair_widgets+=",";
      else first=0; fi
      json_autopair_widgets+="\"$esc\""
    done
    json_autopair_widgets+="]"
  fi

  json_markers="{"
  first=1
  # zsh associative array key iteration
  for k in "${(@k)MARKERS}"; do
    esc_k=$(json_escape "$k")
    esc_v=$(json_escape "${MARKERS[$k]}")
    if [[ $first -eq 0 ]]; then json_markers+=",";
    else first=0; fi
    json_markers+="\"$esc_k\":\"$esc_v\""
  done
  json_markers+="}"

  json_fail_reasons="[]"
  if ((${#fail_reasons[@]} > 0)); then
    json_fail_reasons="["
    first=1
    for r in "${fail_reasons[@]}"; do
      esc=$(json_escape "$r")
      if [[ $first -eq 0 ]]; then json_fail_reasons+=",";
      else first=0; fi
      json_fail_reasons+="\"$esc\""
    done
    json_fail_reasons+="]"
  fi

  json_segments="null"
  if [[ -n "$SEG_FILE" ]]; then
    json_segments="{"
    json_segments+="\"file\":\"$(json_escape "$SEG_FILE")\","
    json_segments+="\"exists\":$([[ "$seg_exists" == true ]] && echo true || echo false),"
    json_segments+="\"validated\":$([[ "$seg_valid_json" == true ]] && echo true || echo false),"
    json_segments+="\"validator_available\":$([[ "$validator_available" == true ]] && echo true || echo false)"
    if [[ -n "$seg_validation_fail_reason" ]]; then
      json_segments+=",\"info\":\"$(json_escape "$seg_validation_fail_reason")\""
    fi
    json_segments+="}"
  fi

  json_obj=$(
    cat <<EOF
{
  "timestamp": "$(timestamp_utc)",
  "layer": "$(json_escape "${layer_from_marker:-}")",
  "symlink_targets": {
    ".zshrc.pre-plugins.d": "$(json_escape "$(symlink_target_or_empty .zshrc.pre-plugins.d || true)")",
    ".zshrc.add-plugins.d": "$(json_escape "$(symlink_target_or_empty .zshrc.add-plugins.d || true)")",
    ".zshrc.d": "$(json_escape "$(symlink_target_or_empty .zshrc.d || true)")"
  },
  "widgets": ${_zf_layer_widgets:-0},
  "baseline": ${baseline_json},
  "widget_pass": $([[ "$widget_pass" == true ]] && echo true || echo false),
  "markers": $json_markers,
  "autopair": {
    "present": $([[ "$_autopair_present" == 1 ]] && echo true || echo false),
    "widgets": $json_autopair_widgets
  },
  "segments": $json_segments,
  "fail_reasons": $json_fail_reasons
}
EOF
  )

  if (( PRETTY == 1 )); then
    if command -v python3 >/dev/null 2>&1; then
      printf '%s' "$json_obj" | python3 - <<'PY' 2>/dev/null || printf '%s' "$json_obj"
import json,sys
try:
    print(json.dumps(json.loads(sys.stdin.read()), indent=2, sort_keys=True))
except Exception:
    sys.stdout.write(sys.stdin.read())
PY
    else
      printf '%s' "$json_obj"
    fi
  else
    printf '%s' "$json_obj"
  fi
fi

# ---------------------------
# Final Exit Logic
# ---------------------------
if (( FAIL_ON_REGRESSION == 1 )); then
  if [[ "$widget_pass" != true ]]; then
    exit 1
  fi
fi

if (( VALIDATE_SEGMENTS == 1 )); then
  if [[ "$seg_exists" == true && "$seg_valid_json" == false ]]; then
    exit 1
  fi
  if [[ "$seg_exists" == false ]]; then
    exit 1
  fi
  if (( STRICT_SEGMENTS == 1 )) && [[ "$seg_valid_json" == false ]]; then
    exit 1
  fi
fi

exit 0
