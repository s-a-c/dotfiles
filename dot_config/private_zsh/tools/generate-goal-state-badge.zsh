#!/usr/bin/env zsh
# generate-goal-state-badge.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md vb7f03a299a01b1b6d7c8be5a74646f0b5127cbc5b5d614c8b4c20fc99bc21620
#
# PURPOSE:
#   Tiny badge generator for GOAL state. Emits:
#     docs/redesignv2/artifacts/badges/goal-state.json
#   Defaults (overrideable via flags/env):
#     - governance: clean
#     - ci:         strict
#     - streak:     building
#     - explore:    sandbox
#
# USAGE:
#   .config/zsh/tools/generate-goal-state-badge.zsh
#   .config/zsh/tools/generate-goal-state-badge.zsh \
#     --output /path/to/goal-state.json \
#     --governance clean --ci strict --streak building --explore sandbox
#
# ENV OVERRIDES:
#   GOAL_STATE_GOVERNANCE, GOAL_STATE_CI, GOAL_STATE_STREAK, GOAL_STATE_EXPLORE
#
# NOTES:
#   - Pure zsh, no jq dependency.
#   - Writes atomically via .tmp then mv.
#   - Idempotent: same inputs → identical JSON.

set -euo pipefail

print_err()  { print -r -- "[goal-state-badge][err]  $*" >&2; }
print_info() { print -r -- "[goal-state-badge][info] $*" >&2; }

usage() {
  cat <<'EOF'
generate-goal-state-badge.zsh
  Emit a simple JSON badge representing GOAL modes.

Options:
  --output PATH         Output file path for JSON
  --governance STATE    Governance state (default: clean)
  --ci STATE            CI state (default: strict)
  --streak STATE        Streak state (default: building)
  --explore STATE       Explore state (default: sandbox)
  -h, --help            Show this help

Environment overrides:
  GOAL_STATE_GOVERNANCE, GOAL_STATE_CI, GOAL_STATE_STREAK, GOAL_STATE_EXPLORE
EOF
}

# Resolve project root (zsh-only; 0:A is absolute script path)
script_dir="${0:A:h}"
project_root="${script_dir:A}/.."

# Defaults
out_path="${project_root}/docs/redesignv2/artifacts/badges/goal-state.json"
gov_state="${GOAL_STATE_GOVERNANCE:-clean}"
ci_state="${GOAL_STATE_CI:-strict}"
streak_state="${GOAL_STATE_STREAK:-building}"
explore_state="${GOAL_STATE_EXPLORE:-sandbox}"

# Parse args
while (( $# > 0 )); do
  case "${1:-}" in
    --output)         shift; out_path="${1:-${out_path}}";;
    --output=*)       out_path="${1#*=}";;
    --governance)     shift; gov_state="${1:-${gov_state}}";;
    --governance=*)   gov_state="${1#*=}";;
    --ci)             shift; ci_state="${1:-${ci_state}}";;
    --ci=*)           ci_state="${1#*=}";;
    --streak)         shift; streak_state="${1:-${streak_state}}";;
    --streak=*)       streak_state="${1#*=}";;
    --explore)        shift; explore_state="${1:-${explore_state}}";;
    --explore=*)      explore_state="${1#*=}";;
    -h|--help)        usage; exit 0;;
    *) print_err "Unknown argument: ${1:-}"; usage; exit 1;;
  esac
  shift || true
done

# Dynamic mapping from perf-current.json when present
perf_json="${project_root}/docs/redesignv2/artifacts/metrics/perf-current.json"
if [[ -s "$perf_json" ]]; then
  goal="$(sed -nE 's/.*"goal"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$perf_json" | head -n1)"
  mode="$(sed -nE 's/.*"mode"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$perf_json" | head -n1)"
  overall="$(sed -nE 's/.*"overall_status"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$perf_json" | head -n1)"

  partial_present=0
  grep -q '"partial"[[:space:]]*:[[:space:]]*true' "$perf_json" 2>/dev/null && partial_present=1

  synthetic_present=0
  grep -q '"synthetic_used"[[:space:]]*:[[:space:]]*true' "$perf_json" 2>/dev/null && synthetic_present=1
  if [[ $synthetic_present -eq 0 ]]; then
    dbg_syn="$(sed -nE 's/.*"_debug"[^{]*\{[^}]*"synthetic_used"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p' "$perf_json" | head -n1)"
    [[ "${dbg_syn:-0}" -gt 0 ]] && synthetic_present=1
  fi

  # Governance: clean only when overall OK and no partial or synthetic; otherwise warning/failing
  if [[ "$goal" == "governance" ]]; then
    if [[ "$overall" == "OK" && $partial_present -eq 0 && $synthetic_present -eq 0 ]]; then
      gov_state="clean"
    elif [[ "$overall" == "FAIL" ]]; then
      gov_state="failing"
    elif [[ "$overall" == "WARN" ]]; then
      gov_state="warning"
    fi
  fi

  # CI: strict when GOAL=ci and mode=enforce, else lenient
  if [[ "$goal" == "ci" ]]; then
    if [[ "$mode" == "enforce" ]]; then
      ci_state="strict"
    else
      ci_state="lenient"
    fi
  fi

  # Streak: building when partial tolerated; else stable
  if [[ "$goal" == "streak" ]]; then
    if [[ $partial_present -eq 1 ]]; then
      streak_state="building"
    else
      streak_state="stable"
    fi
  fi

  # Explore remains sandbox
  if [[ "$goal" == "explore" ]]; then
    explore_state="sandbox"
  fi
fi

# Ensure output directory exists
out_dir="${out_path:h}"
mkdir -p -- "$out_dir"

# Compose JSON and write atomically
tmp="${out_path}.tmp"
{
  print '{'
  print "  \"governance\": \"${gov_state}\","
  print "  \"ci\": \"${ci_state}\","
  print "  \"streak\": \"${streak_state}\","
  print "  \"explore\": \"${explore_state}\","
  print "  \"generated_at\": \"$(date -Iseconds 2>/dev/null || date)\","
  print "  \"source\": \"tools/generate-goal-state-badge.zsh\""
  print '}'
} > "$tmp"

mv -f "$tmp" "$out_path"

print_info "Wrote goal-state badge → $out_path"
print_info "governance=${gov_state} ci=${ci_state} streak=${streak_state} explore=${explore_state}"

exit 0
