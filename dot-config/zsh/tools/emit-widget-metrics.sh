#!/usr/bin/env bash
# emit-widget-metrics.sh
#
# Purpose:
#   Emit a single JSON object summarizing ZLE widget counts in two modes:
#     1. Core Harness (clean subshell; no user rc files; manual layer sourcing)
#     2. Full Interactive (normal `zsh -i` startup)
#
#   This allows downstream processes (snapshot appender, CI health, promotion
#   guard) to distinguish between a “core-only” reduced widget set and the
#   enforced interactive baseline without generating false regressions.
#
# Features:
#   - Baseline enforcement flag (interactive baseline ≥ ENFORCED_WIDGET_BASELINE).
#   - Core harness plugin manager presence detection.
#   - Delta calculation (interactive - core).
#   - Tolerant handling if interactive shell fails (sets fields to null).
#   - Emits rationale string when core-only mode lacks plugin manager.
#
# Environment Overrides:
#   ENFORCED_WIDGET_BASELINE   (default: 417)
#   EXPECTED_CORE_WIDGETS      (default: 409) – informational; not enforced
#   ZSH_CORE_HARNESS_DIRS      (override directory list for manual sourcing)
#   EMIT_VERBOSE=1             (adds extra diagnostic fields)
#
# Exit Code:
#   Always 0 (pure metrics emitter; enforcement lives elsewhere).
#
# Example:
#   bash zsh/tools/emit-widget-metrics.sh > artifacts/widget-metrics.json
#
# JSON Schema (stable fields):
#   {
#     "timestamp": "UTC ISO8601",
#     "baseline_enforced": 417,
#     "widgets_core": 409,
#     "widgets_interactive": 417,
#     "widgets_delta": 8,
#     "baseline_met": true,
#     "core_below_baseline": true,
#     "plugin_manager_core": 0,
#     "expected_core_widgets": 409,
#     "core_mode_rationale": "plugin manager absent (core-only harness)",
#     "status": "ok" | "partial" | "error"
#   }
#
# Notes:
#   - If the interactive count is missing, baseline_met becomes false and
#     status becomes "partial" (unless core also failed → "error").
#   - This script is nounset-safe and avoids failing the pipeline.
#
set -euo pipefail

# ---------------- Configuration ----------------
BASELINE="${ENFORCED_WIDGET_BASELINE:-417}"
EXPECTED_CORE="${EXPECTED_CORE_WIDGETS:-409}"
CORE_DIRS_DEFAULT=".zshrc.pre-plugins.d.empty .zshrc.add-plugins.d.empty .zshrc.d.empty"
CORE_DIRS="${ZSH_CORE_HARNESS_DIRS:-$CORE_DIRS_DEFAULT}"

VERBOSE="${EMIT_VERBOSE:-0}"

# ---------------- Helpers ----------------------
is_num() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

json_escape() {
  # Escape backslash and double quotes; leave other characters as-is.
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Portable date (GNU/BSD)
utc_now() {
  if date -u +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  else
    # Fallback (should not happen on typical systems)
    printf '1970-01-01T00:00:00Z'
  fi
}

# Run a core harness subshell:
#   * no global/user rc
#   * manual layer sourcing
core_count="null"
plugin_manager_present=0
core_error=""

{
  core_output="$(
    zsh --no-rcs --no-globalrcs -ic '
      set +e
      for dir in '"$CORE_DIRS"'; do
        [[ -d $dir ]] || continue
        for f in "$dir"/*.zsh; do
          [ -f "$f" ] || continue
          # shellcheck disable=SC1090
          source "$f" || { echo "ERROR_SOURCING=$f"; exit 2; }
        done
      done
      if typeset -f zgenom >/dev/null 2>&1; then
        echo CORE_PLUGIN_MANAGER_PRESENT=1
      else
        echo CORE_PLUGIN_MANAGER_PRESENT=0
      fi
      wc=$(zle -la 2>/dev/null | wc -l | tr -d "[:space:]")
      echo CORE_WIDGET_COUNT=$wc
      exit 0
    ' 2>&1
  )" || true

  # Parse results
  core_count_line=$(printf '%s\n' "$core_output" | grep -E '^CORE_WIDGET_COUNT=' || true)
  pm_line=$(printf '%s\n' "$core_output" | grep -E '^CORE_PLUGIN_MANAGER_PRESENT=' || true)
  if [[ -n "$core_count_line" ]]; then
    core_count="${core_count_line#*=}"
  else
    core_error="missing_core_count"
  fi
  if [[ -n "$pm_line" ]]; then
    plugin_manager_present="${pm_line#*=}"
  fi
} || true

# Interactive shell count
interactive_count="null"
interactive_error=""
{
  # Capture any banner/noise, extract last numeric token (robust against SSH key or MOTD lines)
  interactive_raw="$(
    zsh -i -c 'zle -la 2>/dev/null | wc -l' 2>&1 \
      | grep -Eo '[0-9]+' \
      | tail -1 || true
  )"
  if is_num "$interactive_raw"; then
    interactive_count="$interactive_raw"
  else
    interactive_error="missing_interactive_count"
  fi
} || true

# Compute delta if possible
delta="null"
if is_num "$core_count" && is_num "$interactive_count"; then
  delta=$(( interactive_count - core_count ))
fi

# Determine status & enforcement flags
baseline_met=false
core_below_baseline=false
status="ok"
rationale=""

if is_num "$interactive_count"; then
  if (( interactive_count >= BASELINE )); then
    baseline_met=true
  else
    baseline_met=false
  fi
else
  status="partial"
  rationale+="interactive count unavailable; "
fi

if is_num "$core_count"; then
  if (( core_count < BASELINE )); then
    core_below_baseline=true
  fi
else
  status="error"
  rationale+="core count unavailable; "
fi

if [[ "$plugin_manager_present" -eq 0 ]]; then
  rationale+="plugin manager absent (core-only harness); "
fi

# Trim rationale
if [[ -n "$rationale" ]]; then
  rationale="${rationale%%; }"
fi
[[ -z "$rationale" ]] && rationale=null || rationale="\"$(printf '%s' "$rationale" | json_escape)\""

# Extended diagnostics (optional)
diag=""
if (( VERBOSE )); then
  diag=$(cat <<DIAG
,"diagnostics":{
  "core_subshell_raw":"$(printf '%s' "$core_output" | json_escape)",
  "core_error":"${core_error:-none}",
  "interactive_error":"${interactive_error:-none}"
}
DIAG
)
fi

timestamp="$(utc_now)"

# Emit JSON
# Using a here-doc for readability; ensure proper commas and quoting.
cat <<JSON
{
  "timestamp":"${timestamp}",
  "baseline_enforced":${BASELINE},
  "expected_core_widgets":${EXPECTED_CORE},
  "widgets_core":$(is_num "$core_count" && echo "$core_count" || echo null),
  "widgets_interactive":$(is_num "$interactive_count" && echo "$interactive_count" || echo null),
  "widgets_delta":${delta},
  "plugin_manager_core":${plugin_manager_present},
  "baseline_met":${baseline_met},
  "core_below_baseline":${core_below_baseline},
  "status":"${status}",
  "core_mode_rationale":${rationale}
  ${diag}
}
JSON

# Always exit 0 (metrics-only script)
exit 0
