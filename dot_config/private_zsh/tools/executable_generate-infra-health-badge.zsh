#!/usr/bin/env zsh
# generate-infra-health-badge.zsh
#
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# Sensitive action rationale (badge synthesizes multiple enforcement signals):
# - Aggregates security / quality / structure guardrails into a single status surface
# - Non-invasive (read-only) but may be used downstream for gating; keep logic transparent
#
# Purpose:
#   Synthesize individual badge JSON files (perf, structure, hooks) into a single
#   infrastructure health badge (infra-health.json) with:
#     - Consolidated color (worst-case + weighted average fallback)
#     - Summary message
#     - Explicit component breakdown retained in docs/badges/summary.json (already generated elsewhere)
#
# Inputs (badge sources - optional, missing files lower confidence):
#   docs/badges/perf.json
#   docs/badges/perf-ledger.json   # performance ledger (budgets / over-budget status)
#   docs/badges/structure.json
#   docs/badges/hooks.json
#   docs/badges/security.json   # (future) produced by security workflow (e.g., secret scan / vuln scan status)
#
# Output:
#   docs/badges/infra-health.json (Shields-compatible JSON)
#
# Color aggregation strategy:
#   1. Immediate RED if any component is red OR hooks = enforced-fail / fail-missing.
#   2. Otherwise score colors:
#        brightgreen=5, green=4, yellow=3, orange=2, lightgrey=1, (red=0)
#      Compute average over present components.
#   3. Map average:
#        >=4.5 -> brightgreen
#        >=4.0 -> green
#        >=3.0 -> yellow
#        >=2.0 -> orange
#        else   -> red
#   4. If a single component drags average down (e.g., one orange among two greens),
#      average-based color stands; message keeps granular detail.
#
# Exit codes:
#   0 success
#   1 failed to write output or invalid arguments
#   2 (optional) --fail-on-red triggered and aggregate color red
#
# Usage:
#   tools/generate-infra-health-badge.zsh
#   tools/generate-infra-health-badge.zsh --output docs/badges/infra-health.json
#   tools/generate-infra-health-badge.zsh --fail-on-red
#
# Dependencies:
#   - jq (optional, graceful fallback to sed/grep)
#
# Notes:
#   - Message truncated to ~80 chars to keep badge compact.
#   - Designed to run after individual badges are generated.
#
# Future enhancements:
#   - Add SARIF / security badge integration
#   - Add drift / promotion phase context
#   - Emit machine-readable severity classification field

set -euo pipefail

OUT="docs/badges/infra-health.json"
FAIL_ON_RED=0
VERBOSE=0

print_err(){ print -u2 "[infra-health] $*"; }
vlog(){ [[ "$VERBOSE" == "1" ]] && print_err "$*"; }

show_help() {
  cat <<EOF
generate-infra-health-badge.zsh

Synthesize perf / structure / hooks / security badges into a single infra-health badge.

OPTIONS:
  --output <path>     Output JSON file (default: $OUT)
  --fail-on-red       Exit with code 2 if aggregate color is red
  -v, --verbose       Verbose logging
  -h, --help          This help

Color aggregation:
  Immediate red on any component red or hooks enforced-fail/fail-missing.
  Else weighted average of component colors:
    brightgreen=5 green=4 yellow=3 orange=2 lightgrey=1 red=0
  Average thresholds:
    >=4.5 brightgreen
    >=4.0 green
    >=3.0 yellow
    >=2.0 orange
    else  red
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT="$2"; shift 2 ;;
    --fail-on-red) FAIL_ON_RED=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) print_err "Unknown argument: $1"; show_help; exit 1 ;;
  esac
done

badge_dir="${OUT:h}"
mkdir -p "$badge_dir" || { print_err "Failed to create output directory: $badge_dir"; exit 1; }

# ---- Helpers -----------------------------------------------------------------

_has_jq=0
command -v jq >/dev/null 2>&1 && _has_jq=1

extract_color_msg() {
  # Args: file key
  local file="$1" key="$2"
  local color="" msg=""
  [[ -f "$file" ]] || { vlog "Missing $file"; print "$key::"; return 0; }
  if (( _has_jq )); then
    msg=$(jq -r '.message // empty' "$file" 2>/dev/null || true)
    color=$(jq -r '.color // empty' "$file" 2>/dev/null || true)
  else
    local line; line=$(<"$file")
    msg=$(print -- "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
    color=$(print -- "$line" | sed -n 's/.*"color":"\([^"]*\)".*/\1/p')
  fi
  print "${key}:${color}:${msg}"
}

score_color() {
  case "$1" in
    brightgreen) print 5 ;;
    green)       print 4 ;;
    yellow)      print 3 ;;
    orange)      print 2 ;;
    lightgrey)   print 1 ;;
    red)         print 0 ;;
    *)           print 1 ;; # unknown -> light penalty
  esac
}

# ---- Collect component badges ------------------------------------------------

perf_line=$(extract_color_msg docs/badges/perf.json perf)
perf_ledger_line=$(extract_color_msg docs/badges/perf-ledger.json perf_ledger)
struct_line=$(extract_color_msg docs/badges/structure.json structure)
hooks_line=$(extract_color_msg docs/badges/hooks.json hooks)
security_line=$(extract_color_msg docs/badges/security.json security)

vlog "perf_line=$perf_line"
vlog "perf_ledger_line=$perf_ledger_line"
vlog "structure_line=$struct_line"
vlog "hooks_line=$hooks_line"

components=($perf_line $perf_ledger_line $struct_line $hooks_line $security_line)

present=()
any_red=0
hooks_enforced_fail=0
security_force_red=0  # Severity weighting: security red forces aggregate red

json_entries=()

for entry in "${components[@]}"; do
  key=${entry%%:*}
  rest=${entry#*:}
  color=${rest%%:*}
  msg=${rest#*:*}
  [[ -z "$color$msg" ]] && continue
  present+=("$key")
  [[ "$color" == "red" ]] && any_red=1
  if [[ "$key" == "hooks" && "$msg" == "enforced-fail" ]]; then
    hooks_enforced_fail=1
  fi
  # Severity weighting: security red escalates aggregate immediately
  if [[ "$key" == "security" && "$color" == "red" ]]; then
    security_force_red=1
  fi
  json_entries+=("\"$key\":{\"color\":\"$color\",\"message\":\"${msg//\"/\\\"}\"}")
done

# ---- Aggregate color ---------------------------------------------------------

aggregate_color="lightgrey"
aggregate_message=""
# Severity / precedence order:
# 1. security_force_red (explicit security failure)
# 2. hooks_enforced_fail (hook integrity critical)
# 3. any_red (any other component red)
if (( security_force_red )); then
  aggregate_color="red"
elif (( hooks_enforced_fail )); then
  aggregate_color="red"
elif (( any_red )); then
  aggregate_color="red"
elif (( ${#present[@]} == 0 )); then
  aggregate_color="lightgrey"
else
  # Weighted average
  total_score=0
  n=0
  for entry in "${components[@]}"; do
    key=${entry%%:*}; rest=${entry#*:}; color=${rest%%:*}; msg=${rest#*:*}
    [[ -z "$color$msg" ]] && continue
    s=$(score_color "$color")
    total_score=$(( total_score + s ))
    n=$(( n + 1 ))
  done
  avg=0
  (( n > 0 )) && avg=$(( total_score * 100 / (n) ))  # scale by 100 to keep precision
  # Convert back to float-like threshold logic using integer scaled by 100
  # threshold mapping (scaled):
  # 4.5 -> 450, 4.0 -> 400, 3.0 -> 300, 2.0 -> 200
  if   (( avg >= 450 )); then aggregate_color="brightgreen"
  elif (( avg >= 400 )); then aggregate_color="green"
  elif (( avg >= 300 )); then aggregate_color="yellow"
  elif (( avg >= 200 )); then aggregate_color="orange"
  else aggregate_color="red"
  fi
fi

# Build concise summary message
build_segment() {
  local key="$1" color="$2" msg="$3"
  [[ -z "$color$msg" ]] && return
  print "${key}=${msg}"
}

for entry in "${components[@]}"; do
  key=${entry%%:*}; rest=${entry#*:}; color=${rest%%:*}; msg=${rest#*:*}
  [[ -z "$color$msg" ]] && continue
  segment=$(build_segment "$key" "$color" "$msg")
  if [[ -n "$segment" ]]; then
    if [[ -z "$aggregate_message" ]]; then
      aggregate_message="$segment"
    else
      aggregate_message="$aggregate_message|$segment"
    fi
  fi
done

# Fallback message if empty
[[ -z "$aggregate_message" ]] && aggregate_message="no-components"

# Truncate message for badge readability (approx 80 chars)
if (( ${#aggregate_message} > 80 )); then
  aggregate_message="${aggregate_message[1,77]}..."
fi

# Compose JSON
timestamp=$(date -u +%FT%TZ 2>/dev/null || date)
{
  print -n '{'
  print -n "\"schemaVersion\":1,"
  print -n "\"label\":\"infra\","
  print -n "\"message\":\"${aggregate_message//\"/\\\"}\","
  print -n "\"color\":\"$aggregate_color\","
  print -n "\"generated\":\"$timestamp\","
  # Include embedded components breakdown for transparency
  print -n '"components":{'
  if (( ${#json_entries[@]} > 0 )); then
    print -n "${(j:,:.)json_entries}"
  fi
  print -n '}'
  print '}'
} > "$OUT".tmp || { print_err "Failed writing temp file"; exit 1; }

mv "$OUT".tmp "$OUT" || { print_err "Failed to finalize $OUT"; exit 1; }
print_err "Wrote $OUT (color=$aggregate_color message='$aggregate_message')"

if (( FAIL_ON_RED )) && [[ "$aggregate_color" == "red" ]]; then
  print_err "Aggregate color red and --fail-on-red set; exiting 2"
  exit 2
fi

exit 0
