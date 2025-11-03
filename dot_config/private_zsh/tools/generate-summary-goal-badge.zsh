#!/usr/bin/env zsh
# generate-summary-goal-badge.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   Compact aggregator badge for README: composes multiple goal states into a single
#   shields.io endpoint JSON.
#
#   Input (default):
#     docs/redesignv2/artifacts/badges/goal-state.json
#       {
#         "governance": "clean|warning|failing",
#         "ci":         "strict|lenient",
#         "streak":     "building|stable",
#         "explore":    "sandbox",
#         ...
#       }
#
#   Output (default):
#     docs/redesignv2/artifacts/badges/summary-goal.json
#       {
#         "schemaVersion": 1,
#         "label": "goal",
#         "message": "gov:clean | ci:strict | streak:building | explore:sandbox",
#         "color": "brightgreen",
#         "namedLogo": "zsh",
#         "cacheSeconds": 300
#       }
#
# USAGE:
#   .config/zsh/tools/generate-summary-goal-badge.zsh
#   .config/zsh/tools/generate-summary-goal-badge.zsh \
#     --input docs/redesignv2/artifacts/badges/goal-state.json \
#     --output docs/redesignv2/artifacts/badges/summary-goal.json \
#     --label goal --logo zsh --cache-seconds 300
#
# ENV OVERRIDES:
#   SUMMARY_GOAL_INPUT, SUMMARY_GOAL_OUTPUT, SUMMARY_GOAL_LABEL, SUMMARY_GOAL_LOGO, SUMMARY_GOAL_CACHE_SECONDS
#
# NOTES:
#   - Pure zsh; no jq dependency.
#   - Writes atomically via .tmp then mv.
#   - Idempotent: same inputs → identical JSON.

set -euo pipefail

print_err()  { print -r -- "[summary-goal][err]  $*" >&2; }
print_info() { print -r -- "[summary-goal][info] $*" >&2; }

# Resolve project root from this script dir
script_dir="${0:A:h}"
project_root="${script_dir:A}/.."

# Defaults
in_path="${SUMMARY_GOAL_INPUT:-${project_root}/docs/redesignv2/artifacts/badges/goal-state.json}"
out_path="${SUMMARY_GOAL_OUTPUT:-${project_root}/docs/redesignv2/artifacts/badges/summary-goal.json}"
label="${SUMMARY_GOAL_LABEL:-goal}"
logo="${SUMMARY_GOAL_LOGO:-zsh}"
cache_sec="${SUMMARY_GOAL_CACHE_SECONDS:-300}"

usage() {
  cat <<'EOF'
generate-summary-goal-badge.zsh
  Aggregate goal states into a single shields.io endpoint badge.

Options:
  --input PATH           Input goal-state JSON (default: docs/redesignv2/artifacts/badges/goal-state.json)
  --output PATH          Output badge JSON (default: docs/redesignv2/artifacts/badges/summary-goal.json)
  --label TEXT           Badge label (default: goal)
  --logo NAME            Shields namedLogo (default: zsh)
  --cache-seconds N      Shields cacheSeconds (default: 300)
  -h, --help             Show this help

Environment overrides:
  SUMMARY_GOAL_INPUT, SUMMARY_GOAL_OUTPUT, SUMMARY_GOAL_LABEL, SUMMARY_GOAL_LOGO, SUMMARY_GOAL_CACHE_SECONDS
EOF
}

# Parse args
while (( $# > 0 )); do
  case "${1:-}" in
    --input)          shift; in_path="${1:-${in_path}}";;
    --input=*)        in_path="${1#*=}";;
    --output)         shift; out_path="${1:-${out_path}}";;
    --output=*)       out_path="${1#*=}";;
    --label)          shift; label="${1:-${label}}";;
    --label=*)        label="${1#*=}";;
    --logo)           shift; logo="${1:-${logo}}";;
    --logo=*)         logo="${1#*=}";;
    --cache-seconds)  shift; cache_sec="${1:-${cache_sec}}";;
    --cache-seconds=*) cache_sec="${1#*=}";;
    -h|--help)        usage; exit 0;;
    *) print_err "Unknown argument: ${1:-}"; usage; exit 1;;
  esac
  shift || true
done

# Ensure output directory exists
out_dir="${out_path:h}"
mkdir -p -- "$out_dir"

# Read states from input or use defaults
gov_state="clean"
ci_state="strict"
streak_state="building"
explore_state="sandbox"

if [[ -s "$in_path" ]]; then
  # Best-effort key extraction sans jq
  g="$(sed -nE 's/.*"governance"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$in_path" | head -n1)"
  c="$(sed -nE 's/.*"ci"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$in_path" | head -n1)"
  s="$(sed -nE 's/.*"streak"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$in_path" | head -n1)"
  e="$(sed -nE 's/.*"explore"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$in_path" | head -n1)"
  [[ -n "${g:-}" ]] && gov_state="$g"
  [[ -n "${c:-}" ]] && ci_state="$c"
  [[ -n "${s:-}" ]] && streak_state="$s"
  [[ -n "${e:-}" ]] && explore_state="$e"
else
  print_info "Input not found; using default states (gov=${gov_state}, ci=${ci_state}, streak=${streak_state}, explore=${explore_state})"
fi

# Determine severity → color mapping
# severity: 0=ok, 1=info, 2=warn, 3=fail
sev=0
# governance
case "${gov_state:l}" in
  failing) (( sev = sev < 3 ? 3 : sev ));;
  warning) (( sev = sev < 2 ? 2 : sev ));;
  clean)   :;;
  *)       (( sev = sev < 1 ? 1 : sev ));;
esac
# ci
case "${ci_state:l}" in
  strict)  :;;
  lenient) (( sev = sev < 1 ? 1 : sev ));;
  *)       (( sev = sev < 1 ? 1 : sev ));;
esac
# streak
case "${streak_state:l}" in
  stable)  :;;
  building) (( sev = sev < 1 ? 1 : sev ));;
  *)       (( sev = sev < 1 ? 1 : sev ));;
esac
# explore
case "${explore_state:l}" in
  sandbox) :;;
  *)       (( sev = sev < 1 ? 1 : sev ));;
esac

# Incorporate perf drift and (optional) structure badge severities/suffix
# Paths prefer redesignv2
perf_drift_badge="${project_root}/docs/redesignv2/artifacts/badges/perf-drift.json"
struct_badge="${project_root}/docs/redesignv2/artifacts/badges/structure.json"

perf_sev=0   # 0 none, 1 info, 2 warn, 3 fail
perf_msg=""
if [[ -s "$perf_drift_badge" ]]; then
  # Extract message and/or color
  perf_msg="$(sed -nE 's/.*"message"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$perf_drift_badge" | head -n1)"
  perf_color="$(sed -nE 's/.*"color"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$perf_drift_badge" | head -n1)"
  # Determine severity: fail > warn > any non-zero regressions (below warn) > none
  if [[ "$perf_msg" == *" fail "* || "$perf_msg" == fail* || "$perf_color" == "red" ]]; then
    perf_sev=3
  elif [[ "$perf_msg" == *" warn "* || "$perf_msg" == warn* || "$perf_color" == "yellow" ]]; then
    perf_sev=2
  elif [[ "$perf_msg" != "0" && -n "$perf_msg" ]]; then
    perf_sev=1
  fi
fi

struct_sev=0
struct_msg=""
if [[ -s "$struct_badge" ]]; then
  struct_msg="$(sed -nE 's/.*"message"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$struct_badge" | head -n1)"
  struct_color="$(sed -nE 's/.*"color"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$struct_badge" | head -n1)"
  case "${struct_color:l}" in
    red) struct_sev=3 ;;
    yellow) struct_sev=2 ;;
    green) struct_sev=0 ;;
    *) struct_sev=1 ;;  # unknown → info
  esac
fi

# Fold severities into overall
(( sev = (sev > perf_sev ? sev : perf_sev) ))
(( sev = (sev > struct_sev ? sev : struct_sev) ))

# Map overall severity to color
color="brightgreen"
if   (( sev >= 3 )); then color="red"
elif (( sev == 2 )); then color="yellow"
elif (( sev == 1 )); then color="blue"
fi
is_error="false"
(( sev >= 3 )) && is_error="true"

# Compose suffixes (compact) – only include when present
suffix_parts=()
[[ -n "$perf_msg" ]] && suffix_parts+=("drift:${perf_msg}")
[[ -n "$struct_msg" ]] && suffix_parts+=("struct:${struct_msg}")
suffix=""
if (( ${#suffix_parts[@]} > 0 )); then
  suffix=" | ${(j: | :)suffix_parts}"
fi

# Compose message (keep compact for shields)
message="gov:${gov_state} | ci:${ci_state} | streak:${streak_state} | explore:${explore_state}${suffix}"

# Sanitize label/logo to basic ASCII (best-effort)
label="${label//\"/}"
logo="${logo//\"/}"

# Write shields endpoint JSON atomically
tmp="${out_path}.tmp"
{
  print '{'
  print '  "schemaVersion": 1,'
  print "  \"label\": \"${label}\","
  print "  \"message\": \"${message}\","
  print "  \"color\": \"${color}\","
  print "  \"namedLogo\": \"${logo}\","
  print "  \"cacheSeconds\": ${cache_sec},"
  print "  \"isError\": ${is_error},"
  print "  \"_source\": \"tools/generate-summary-goal-badge.zsh\""
  print '}'
} > "$tmp"

mv -f "$tmp" "$out_path"
print_info "Wrote summary goal badge → $out_path"
print_info "label='${label}' color='${color}' message='${message}'"

exit 0
