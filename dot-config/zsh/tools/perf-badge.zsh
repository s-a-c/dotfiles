#!/usr/bin/env zsh
# perf-badge.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Thin ZSH-friendly wrapper around perf-variance-badge.sh to simplify invocation
#   inside ZDOTDIR workflows (adds automatic metrics directory detection, argument
#   flags, and fallback shell selection). Outputs either Shields JSON or plain text
#   summarizing relative standard deviation (RSD = stddev/mean) for a selected
#   aggregate metric in perf-multi-current.json.
#
# USAGE:
#   zsh tools/perf-badge.zsh                 # default (metric=post_plugin_cost_ms, format=shields)
#   zsh tools/perf-badge.zsh -m pre_plugin_cost_ms
#   zsh tools/perf-badge.zsh -m prompt_ready_ms -f text
#   zsh tools/perf-badge.zsh --metric cold_ms --format text --label cold_var
#
# OPTIONS:
#   -m, --metric <name>     Aggregate metric key (default: post_plugin_cost_ms)
#   -f, --format <fmt>      shields|text (default: shields)
#   -l, --label <label>     Override badge label (default: <metric>_var)
#   -p, --precision <n>     Decimal places for rsd (default: 2)
#       --green <flt>       Green threshold max (inclusive, default 0.10)
#       --yellow <flt>      Yellow threshold max (inclusive, default 0.20)
#       --file <path>       Explicit perf-multi-current.json path
#       --metrics-dir <d>   Directory containing perf-multi-current.json
#   -h, --help              Show help
#
# ENVIRONMENT (mirrors perf-variance-badge.sh):
#   METRIC FORMAT LABEL PRECISION GREEN_MAX YELLOW_MAX RED_MAX FAIL_ON_MISSING MULTI_FILE METRICS_DIR
#
# EXIT CODES:
#   0 success
#   1 underlying script or file error (propagated)
#
# NOTES:
#   - This wrapper does NOT parse perf-multi-current.json itself; it defers to
#     perf-variance-badge.sh (bash). Wrapper exists to keep ZSH tasks ergonomic.
#   - If perf-variance-badge.sh not found or executable, a concise error is emitted.
#
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

badge_script="${SCRIPT_DIR}/perf-variance-badge.sh"
if [[ ! -r "$badge_script" ]]; then
  print -u2 "[perf-badge] ERROR: perf-variance-badge.sh not found at $badge_script"
  exit 1
fi

have_bash=0
if command -v bash >/dev/null 2>&1; then
  have_bash=1
else
  # Attempt /usr/bin/env bash fallback check
  if [[ -x /usr/bin/bash || -x /bin/bash ]]; then
    have_bash=1
  fi
fi

if (( have_bash == 0 )); then
  print -u2 "[perf-badge] ERROR: bash not available; cannot execute perf-variance-badge.sh"
  exit 1
fi

metric="post_plugin_cost_ms"
format="shields"
label=""
precision="2"
green_max=""
yellow_max=""
metrics_dir=""
multi_file=""

usage() {
  sed -n '1,/^# -----------------------------------------------------------------------------/p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

# --------------- Argument Parsing ---------------
while (( $# > 0 )); do
  case "$1" in
    -m|--metric) shift || { print -u2 "Missing value after --metric"; exit 1; }; metric="$1" ;;
    -f|--format) shift || { print -u2 "Missing value after --format"; exit 1; }; format="$1" ;;
    -l|--label) shift || { print -u2 "Missing value after --label"; exit 1; }; label="$1" ;;
    -p|--precision) shift || { print -u2 "Missing value after --precision"; exit 1; }; precision="$1" ;;
    --green) shift || { print -u2 "Missing value after --green"; exit 1; }; green_max="$1" ;;
    --yellow) shift || { print -u2 "Missing value after --yellow"; exit 1; }; yellow_max="$1" ;;
    --metrics-dir) shift || { print -u2 "Missing value after --metrics-dir"; exit 1; }; metrics_dir="$1" ;;
    --file|--multi-file) shift || { print -u2 "Missing value after --file"; exit 1; }; multi_file="$1" ;;
    -h|--help) usage ;;
    *) print -u2 "[perf-badge] Unknown argument: $1"; usage ;;
  esac
  shift
done

# --------------- Resolve Metrics Dir ---------------
if [[ -z "$metrics_dir" && -z "$multi_file" ]]; then
  if [[ -f "${ZDOTDIR}/docs/redesignv2/artifacts/metrics/perf-multi-current.json" ]]; then
    metrics_dir="${ZDOTDIR}/docs/redesignv2/artifacts/metrics"
  elif [[ -f "${ZDOTDIR}/docs/redesign/metrics/perf-multi-current.json" ]]; then
    metrics_dir="${ZDOTDIR}/docs/redesign/metrics"
  else
    metrics_dir="."
  fi
fi

if [[ -z "$multi_file" ]]; then
  multi_file="${metrics_dir%/}/perf-multi-current.json"
fi

if [[ ! -f "$multi_file" ]]; then
  print -u2 "[perf-badge] WARNING: multi-sample file not found: $multi_file"
fi

# --------------- Export Overrides for Script ---------------
export METRIC="$metric"
export FORMAT="$format"
[[ -n "$label" ]] && export LABEL="$label"
export PRECISION="$precision"
[[ -n "$green_max" ]] && export GREEN_MAX="$green_max"
[[ -n "$yellow_max" ]] && export YELLOW_MAX="$yellow_max"
[[ -n "$metrics_dir" ]] && export METRICS_DIR="$metrics_dir"
export MULTI_FILE="$multi_file"

# --------------- Execute ---------------
exec bash "$badge_script"
