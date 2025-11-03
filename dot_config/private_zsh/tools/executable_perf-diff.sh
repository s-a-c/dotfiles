#!/usr/bin/env bash
# perf-diff.sh
# Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Compare performance segment timings between a baseline and a current capture and
#   highlight potential regressions. Designed for use in promotion / gating workflows
#   after zsh startup instrumentation emits unified SEGMENT lines or JSON metrics.
#
# SUPPORTED INPUT FORMATS:
#   1) Plain text lines produced by instrumentation (preferred):
#        SEGMENT name=<label> ms=<duration_ms> phase=<phase> sample=<sample>
#      (Order irrelevant; duplicates aggregated by mean.)
#
#   2) perf JSON (perf-current.json style) when --extract-json flag (or auto-detected)
#      containing "post_plugin_segments": [ { "label": "...", "mean_ms": N }, ... ]
#      Parsing performed with jq if available; simple sed/awk fallback otherwise.
#
# OUTPUT:
#   Text report (always) plus optional machine-readable JSON summary (--json) with a stable schema:
#     {
#       "baseline": "<path>",
#       "current": "<path>",
#       "threshold_abs_ms": <int>,
#       "threshold_pct": <int>,
#       "new_allow_ms": <int>,
#       "counts": {
#         "regressions": <int>,
#         "new": <int>,
#         "removed": <int>,
#         "improvements": <int>,
#         "unchanged": <int>
#       },
#       "details": {
#         "regressions": ["label:base:current:delta:pct", ...],
#         "new": ["label:current_ms", ...],
#         "removed": ["label:base_ms", ...],
#         "improvements": ["label:base:current:delta:pct", ...],
#         "unchanged": ["label:base:current:delta:pct", ...]
#       }
#     }
#   This JSON output is intended for promotion guard / gating integration (e.g. G5a observe mode,
#   future budget correlation) and is kept backward‑stable; new fields may be added but existing
#   keys will not be renamed without a schema version bump.
#   When both text and JSON are requested, text precedes JSON on stdout.
#
# EXIT CODES:
#   0  No severe regressions (or none detected) OR warn-only mode.
#   2  Regressions detected AND fail mode active (--fail or PERF_DIFF_FAIL_ON_REGRESSION=1).
#   3  Usage / input errors.
#
# REGRESSION RULE (default):
#   A segment is flagged if BOTH:
#     absolute delta (curr - base) >= --threshold-abs (default 75 ms)
#     AND percentage delta >= --threshold-pct (default 25 %)
#
# NEW SEGMENTS:
#   If a segment appears only in current and its ms >= --new-allow (default 150 ms),
#   it is flagged as "NEW".
#
# REMOVED SEGMENTS:
#   Reported (info) unless --hide-removed specified.
#
# OPTIONS:
#   --baseline <file>        Baseline segment file (required unless PERF_DIFF_BASELINE set)
#   --current <file>         Current segment file (required unless PERF_DIFF_CURRENT set)
#   --threshold-abs <ms>     Absolute ms delta threshold (default 75)
#   --threshold-pct <pct>    Percentage delta threshold (default 25)
#   --new-allow <ms>         Allow new segments below this ms (default 150)
#   --segments-filter <regex> Only consider segments whose label matches regex
#   --json                   Emit JSON summary (in addition to text) (stable schema for guard integration)
#   --fail                   Exit non-zero (2) if any regression flagged
#   --warn-only              Force exit 0 even with regressions (overrides --fail)
#   --hide-removed           Do not list removed segments
#   --extract-json           Force JSON extraction mode (input files are perf-current.json)
#   --help                   Show usage
#
# ENV OVERRIDES:
#   PERF_DIFF_BASELINE, PERF_DIFF_CURRENT
#   PERF_DIFF_FAIL_ON_REGRESSION=1 (implicit --fail)
#
# SECURITY / POLICY:
#   - Read-only analysis, no file mutation.
#   - No network access.
#   - Works without jq (reduced JSON parsing fidelity).
#
# EXAMPLES:
#   ./perf-diff.sh --baseline metrics/perf-baseline-segments.txt --current metrics/perf-current-segments.txt
#   ./perf-diff.sh --baseline base.txt --current curr.txt --fail --threshold-abs 50 --threshold-pct 15
#
set -euo pipefail

# -------- Usage --------
usage() {
  sed -n '1,120p' "$0" | grep -E '^(# |#$|#!/)' | sed 's/^# \{0,1\}//'
}

# -------- Defaults --------
BASELINE_FILE="${PERF_DIFF_BASELINE:-}"
CURRENT_FILE="${PERF_DIFF_CURRENT:-}"
THRESHOLD_ABS=75
THRESHOLD_PCT=25
NEW_ALLOW=150
SEGMENTS_FILTER=""
FAIL_MODE=0
WARN_ONLY=0
HIDE_REMOVED=0
FORCE_JSON_EXTRACT=0
WANT_JSON=0

# -------- Parse Args --------
while (( $# )); do
  case "$1" in
    --baseline) shift; BASELINE_FILE="${1-}";;
    --current) shift; CURRENT_FILE="${1-}";;
    --threshold-abs) shift; THRESHOLD_ABS="${1-}";;
    --threshold-pct) shift; THRESHOLD_PCT="${1-}";;
    --new-allow) shift; NEW_ALLOW="${1-}";;
    --segments-filter) shift; SEGMENTS_FILTER="${1-}";;
    --fail) FAIL_MODE=1;;
    --warn-only) WARN_ONLY=1;;
    --hide-removed) HIDE_REMOVED=1;;
    --json) WANT_JSON=1;;
    --extract-json) FORCE_JSON_EXTRACT=1;;
    --help|-h) usage; exit 0;;
    --) shift; break;;
    *) echo "ERROR: Unknown option: $1" >&2; usage; exit 3;;
  esac
  shift || true
done

# ENV fail override
if [[ "${PERF_DIFF_FAIL_ON_REGRESSION:-0}" == "1" ]]; then
  FAIL_MODE=1
fi

# warn-only supersedes fail
if (( WARN_ONLY )); then
  FAIL_MODE=0
fi

# Validate required
if [[ -z $BASELINE_FILE || -z $CURRENT_FILE ]]; then
  echo "ERROR: --baseline and --current required (or PERF_DIFF_BASELINE / PERF_DIFF_CURRENT env)" >&2
  exit 3
fi
if [[ ! -f $BASELINE_FILE ]]; then
  echo "ERROR: baseline file not found: $BASELINE_FILE" >&2
  exit 3
fi
if [[ ! -f $CURRENT_FILE ]]; then
  echo "ERROR: current file not found: $CURRENT_FILE" >&2
  exit 3
fi

# -------- Helpers --------
has_jq=0
command -v jq >/dev/null 2>&1 && has_jq=1

declare -A base_ms
declare -A curr_ms
declare -A base_samples
declare -A curr_samples

read_segment_lines() {
  # $1 file  $2 mode base|curr
  local file="$1" mode="$2" line name ms
  while IFS= read -r line || [[ -n $line ]]; do
    # Plain SEGMENT lines
    if [[ $line == SEGMENT* ]]; then
      name=$(sed -E 's/.* name=([^ ]+).*/\1/' <<<"$line")
      ms=$(sed -E 's/.* ms=([0-9]+).*/\1/' <<<"$line")
      [[ -z $name || -z $ms ]] && continue
    # Legacy POST_PLUGIN_SEGMENT label ms
    elif [[ $line == POST_PLUGIN_SEGMENT* ]]; then
      # Format: POST_PLUGIN_SEGMENT <label> <ms>
      name=$(awk '{print $2}' <<<"$line")
      ms=$(awk '{print $3}' <<<"$line")
      [[ $name =~ ^[0-9A-Za-z._-]+$ ]] || continue
    else
      continue
    fi
    [[ -n $SEGMENTS_FILTER ]] && ! [[ $name =~ $SEGMENTS_FILTER ]] && continue
    if [[ $mode == base ]]; then
      # Average duplicates
      if [[ -n ${base_ms[$name]:-} ]]; then
        base_ms[$name]=$(( (base_ms[$name] + ms) / 2 ))
        base_samples[$name]=$(( base_samples[$name] + 1 ))
      else
        base_ms[$name]=$ms
        base_samples[$name]=1
      fi
    else
      if [[ -n ${curr_ms[$name]:-} ]]; then
        curr_ms[$name]=$(( (curr_ms[$name] + ms) / 2 ))
        curr_samples[$name]=$(( curr_samples[$name] + 1 ))
      else
        curr_ms[$name]=$ms
        curr_samples[$name]=1
      fi
    fi
  done <"$file"
}

extract_json_segments() {
  local file="$1" mode="$2" raw label mean
  if (( has_jq )); then
    # shellcheck disable=SC2016
    while IFS=$'\t' read -r label mean; do
      [[ -z $label || -z $mean ]] && continue
      [[ -n $SEGMENTS_FILTER ]] && ! [[ $label =~ $SEGMENTS_FILTER ]] && continue
      if [[ $mode == base ]]; then
        base_ms[$label]=$mean
        base_samples[$label]=1
      else
        curr_ms[$label]=$mean
        curr_samples[$label]=1
      fi
    done < <(jq -r '.post_plugin_segments[]? | "\(.label)\t\(.mean_ms)"' "$file" 2>/dev/null || true)
  else
    # Naive fallback: grep/sed each {"label":"X","mean_ms":N}
    while IFS= read -r raw; do
      label=$(sed -n 's/.*"label"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' <<<"$raw")
      mean=$(sed -n 's/.*"mean_ms"[[:space:]]*:[[:space:]]*\([0-9]\+\).*/\1/p' <<<"$raw")
      [[ -z $label || -z $mean ]] && continue
      [[ -n $SEGMENTS_FILTER ]] && ! [[ $label =~ $SEGMENTS_FILTER ]] && continue
      if [[ $mode == base ]]; then
        base_ms[$label]=$mean
        base_samples[$label]=1
      else
        curr_ms[$label]=$mean
        curr_samples[$label]=1
      fi
    done < <(grep -o '{"label":[^}]*}' "$file" 2>/dev/null || true)
  fi
}

detect_json_file() {
  local file="$1"
  grep -q '"post_plugin_segments"' "$file" 2>/dev/null
}

# Decide parsing mode per file
parse_file() {
  local file="$1" mode="$2"
  if (( FORCE_JSON_EXTRACT )) || detect_json_file "$file"; then
    extract_json_segments "$file" "$mode"
  else
    read_segment_lines "$file" "$mode"
  fi
}

parse_file "$BASELINE_FILE" base
parse_file "$CURRENT_FILE" curr

# -------- Analysis --------
regressions=()
new_segments=()
removed_segments=()
improvements=()
unchanged=()

# Build set of all labels
declare -A all_labels
for k in "${!base_ms[@]}"; do all_labels["$k"]=1; done
for k in "${!curr_ms[@]}"; do all_labels["$k"]=1; done

for label in "${!all_labels[@]}"; do
  b=${base_ms[$label]:-}
  c=${curr_ms[$label]:-}
  if [[ -z $b && -n $c ]]; then
    if (( c >= NEW_ALLOW )); then
      new_segments+=("$label:$c")
    else
      improvements+=("$label:+new+$c")
    fi
  elif [[ -n $b && -z $c ]]; then
    removed_segments+=("$label:$b")
  else
    # Both present
    delta=$(( c - b ))
    if (( b == 0 )); then
      pct=999
    else
      pct=$(( (delta * 100) / b ))
    fi
    if (( delta >= THRESHOLD_ABS && pct >= THRESHOLD_PCT )); then
      regressions+=("$label:$b:$c:$delta:$pct")
    elif (( delta < 0 )); then
      improvements+=("$label:$b:$c:$delta:$pct")
    else
      unchanged+=("$label:$b:$c:$delta:$pct")
    fi
  fi
done

# Summary counts
count_reg=${#regressions[@]}
count_new=${#new_segments[@]}
count_removed=${#removed_segments[@]}
count_imp=${#improvements[@]}
count_unch=${#unchanged[@]}

# -------- Output (text) --------
print_section() {
  local title="$1"; shift
  local -n arr_ref=$1
  (( ${#arr_ref[@]} == 0 )) && return 0
  echo ""
  echo "== $title =="
  local item
  for item in "${arr_ref[@]}"; do
    echo "  $item"
  done
}

echo "perf-diff: baseline=$BASELINE_FILE current=$CURRENT_FILE"
echo " thresholds: abs>=$THRESHOLD_ABS ms & pct>=$THRESHOLD_PCT% | new_allow < $NEW_ALLOW ms allowed"
[[ -n $SEGMENTS_FILTER ]] && echo " filter: $SEGMENTS_FILTER"
echo " segments: baseline=${#base_ms[@]} current=${#curr_ms[@]}"
echo " results: regressions=$count_reg new=$count_new removed=$count_removed improvements=$count_imp unchanged=$count_unch"

print_section "REGRESSIONS (label:base:current:delta:pct)" regressions
print_section "NEW (label:current_ms)" new_segments
if (( ! HIDE_REMOVED )); then
  print_section "REMOVED (label:base_ms)" removed_segments
fi
print_section "IMPROVEMENTS (label:base:current:delta:pct)" improvements

# -------- JSON Summary (optional) --------
if (( WANT_JSON )); then
  json_escape() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
  {
    echo "{"
    echo "  \"baseline\":\"$(printf '%s' "$BASELINE_FILE" | json_escape)\","
    echo "  \"current\":\"$(printf '%s' "$CURRENT_FILE" | json_escape)\","
    echo "  \"threshold_abs_ms\":$THRESHOLD_ABS,"
    echo "  \"threshold_pct\":$THRESHOLD_PCT,"
    echo "  \"new_allow_ms\":$NEW_ALLOW,"
    echo "  \"counts\":{"
    echo "    \"regressions\":$count_reg,"
    echo "    \"new\":$count_new,"
    echo "    \"removed\":$count_removed,"
    echo "    \"improvements\":$count_imp,"
    echo "    \"unchanged\":$count_unch"
    echo "  },"
    # Arrays
    emit_array() {
      local name="$1"; shift
      local -n arr=$1
      echo "  \"$name\":["
      local first=1 it
      for it in "${arr[@]}"; do
        if (( first )); then first=0; else echo ","; fi
        printf '    "%s"' "$(printf '%s' "$it" | json_escape)"
      done
      echo
      echo "  ]"
    }
    # Build arrays (regressions etc.)
    # We'll output under "details"
    echo "  \"details\":{"
    emit_array "regressions" regressions
    echo ","
    emit_array "new" new_segments
    if (( ! HIDE_REMOVED )); then
      echo ","
      emit_array "removed" removed_segments
    fi
    echo ","
    emit_array "improvements" improvements
    echo ","
    emit_array "unchanged" unchanged
    echo "  }"
    echo "}"
  } | sed '/^$/d'
fi

# -------- Exit Code Logic --------
if (( count_reg > 0 )) && (( FAIL_MODE )); then
  echo ""
  echo "perf-diff: FAIL (regressions detected and fail mode active)"
  exit 2
fi

echo ""
if (( count_reg > 0 )); then
  echo "perf-diff: WARN (regressions detected; exit 0 due to warn-only mode/setting)"
else
  echo "perf-diff: OK (no regressions beyond thresholds)"
fi
exit 0
