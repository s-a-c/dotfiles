#!/usr/bin/env bash
# perf-drift-badge.sh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Generate a Shields‑compatible JSON badge summarizing current performance
#   drift (regressions) extracted from a perf diff JSON artifact (produced by
#   perf-diff.sh --json) or, in a fallback mode, by parsing raw regression
#   lines. Enhances drift badge with maximum positive regression percent
#   suffix: e.g. "2 warn (+7.1% max)".
#
# FEATURES:
#   * Reads structured JSON emitted by perf-diff.sh (preferred).
#   * Computes:
#       - regression_count
#       - max_positive_pct   (largest % regression among flagged segments)
#       - severity class (none|warn|fail) using configurable thresholds.
#   * Outputs Shields JSON: {"label":"perf drift","message":"<status>","color":"<color>"}.
#   * Message patterns:
#       - No regressions:    "0"
#       - Warn only:         "<count> warn (+X.Y% max)"
#       - Fail present:      "<count> fail (+X.Y% max)"
#       - Mixed (if future): "<count> regress (+X.Y% max)"
#   * Threshold defaults align with redesign plan:
#       WARN >5%, FAIL >10%.
#
# INPUT MODES:
#   1) --diff-json <file> (or PERF_DRIFT_DIFF_JSON env)
#         JSON schema from perf-diff.sh (stable fields):
#           counts.regressions (int)
#           details.regressions[] "label:base:current:delta:pct"
#   2) (fallback) --regression-lines <file>
#         A plaintext file where each line contains the token 'regression'
#         OR colon-delimited entries label:base:current:delta:pct (mimicking
#         perf-diff details) – used if JSON not provided.
#
# EXIT CODES:
#   0 success (badge JSON emitted)
#   1 usage / input error
#   2 parsing error (malformed JSON or lines)
#
# ENVIRONMENT VARIABLES (override flags):
#   PERF_DRIFT_DIFF_JSON            Path to perf diff JSON
#   PERF_DRIFT_REGRESSION_LINES     Path to raw regression lines (fallback)
#   PERF_DRIFT_WARN_PCT             Warn threshold percent (default 5)
#   PERF_DRIFT_FAIL_PCT             Fail threshold percent (default 10)
#   PERF_DRIFT_LABEL                Badge label (default "perf drift")
#   PERF_DRIFT_PRECISION            Decimal places for max pct (default 1)
#   PERF_DRIFT_COLOR_NONE           Color when no regressions (default "green")
#   PERF_DRIFT_COLOR_WARN           Color when warn only (default "yellow")
#   PERF_DRIFT_COLOR_FAIL           Color when fail (default "red")
#   PERF_DRIFT_COLOR_PARSE_ERROR    Color when parsing failed (default "lightgrey")
#
# SECURITY:
#   - Read‑only; does not modify inputs.
#   - No network access.
#
# FUTURE ENHANCEMENTS (documented hook):
#   - Accept direct perf-ledger historical diff JSON (planned).
#   - Emit extended JSON schema (badge + raw stats) for composite infra-health badge.
#   - Integrate dual widget metrics context:
#       * Read optional artifacts/widget-metrics.json
#       * If present, augment badge (or extended mode) with interactive/core widget delta
#       * Provide perf drift correlation token (e.g. wΔ=<delta>) for composite infra badge
#
# USAGE EXAMPLES:
#   ./perf-drift-badge.sh --diff-json docs/redesignv2/artifacts/metrics/perf-diff.json
#   PERF_DRIFT_DIFF_JSON=perf-diff.json ./perf-drift-badge.sh
#   ./perf-drift-badge.sh --regression-lines tmp/regress.txt
#
set -euo pipefail

# ---------------- Defaults ----------------
WARN_PCT="${PERF_DRIFT_WARN_PCT:-5}"
FAIL_PCT="${PERF_DRIFT_FAIL_PCT:-10}"
LABEL="${PERF_DRIFT_LABEL:-perf drift}"
PRECISION="${PERF_DRIFT_PRECISION:-1}"

COLOR_NONE="${PERF_DRIFT_COLOR_NONE:-green}"
COLOR_WARN="${PERF_DRIFT_COLOR_WARN:-yellow}"
COLOR_FAIL="${PERF_DRIFT_COLOR_FAIL:-red}"
COLOR_PARSE_ERR="${PERF_DRIFT_COLOR_PARSE_ERROR:-lightgrey}"

DIFF_JSON="${PERF_DRIFT_DIFF_JSON:-}"
REG_LINES="${PERF_DRIFT_REGRESSION_LINES:-}"

# ---------------- Help ----------------
usage () {
  sed -n '1,140p' "$0" | grep -E '^(# |#)$' | sed 's/^# \{0,1\}//'
  cat <<EOF

Flags:
  --diff-json <file>          Path to perf-diff.sh JSON output
  --regression-lines <file>   Fallback plain lines (label:base:current:delta:pct)
  --warn-pct <int>            Warn threshold percent (default $WARN_PCT)
  --fail-pct <int>            Fail threshold percent (default $FAIL_PCT)
  --label <text>              Badge label (default "$LABEL")
  --precision <int>           Decimal places for max pct (default $PRECISION)
  --help                      Show help

Priority: diff-json > regression-lines. If both omitted, env vars consulted; else error.
EOF
}

# ---------------- Arg Parse ----------------
while (( $# )); do
  case "$1" in
    --diff-json) shift; DIFF_JSON="${1-}";;
    --regression-lines) shift; REG_LINES="${1-}";;
    --warn-pct) shift; WARN_PCT="${1-}";;
    --fail-pct) shift; FAIL_PCT="${1-}";;
    --label) shift; LABEL="${1-}";;
    --precision) shift; PRECISION="${1-}";;
    --help|-h) usage; exit 0;;
    --) shift; break;;
    *) echo "[perf-drift-badge] ERROR: unknown argument: $1" >&2; usage; exit 1;;
  esac
  shift || true
done

# Validate thresholds numeric
num_re='^[0-9]+([.][0-9]+)?$'
if ! [[ "$WARN_PCT" =~ $num_re && "$FAIL_PCT" =~ $num_re ]]; then
  echo "[perf-drift-badge] ERROR: thresholds must be numeric" >&2
  exit 1
fi

# ---------------- Data Extraction ----------------
regression_count=0
max_positive_pct=0
parse_mode=""
have_jq=0

command -v jq >/dev/null 2>&1 && have_jq=1

if [[ -n "$DIFF_JSON" ]]; then
  if [[ ! -f "$DIFF_JSON" ]]; then
    echo "[perf-drift-badge] ERROR: diff JSON not found: $DIFF_JSON" >&2
    exit 1
  fi
  parse_mode="json"
elif [[ -n "$REG_LINES" ]]; then
  if [[ ! -f "$REG_LINES" ]]; then
    echo "[perf-drift-badge] ERROR: regression lines file not found: $REG_LINES" >&2
    exit 1
  fi
  parse_mode="lines"
else
  echo "[perf-drift-badge] ERROR: no input provided (use --diff-json or --regression-lines)" >&2
  exit 1
fi

parse_json() {
  local file="$1"
  # counts.regressions mandatory; details.regressions array optional (older versions could differ)
  if (( have_jq )); then
    regression_count=$(jq -r '.counts.regressions // 0' "$file" 2>/dev/null || echo 0)
    # Extract pct field (fifth colon segment) from details.regressions
    if (( regression_count > 0 )); then
      mapfile -t pct_list < <(jq -r '.details.regressions[]? // empty' "$file" 2>/dev/null | awk -F: '{if (NF>=5){print $5}}')
      for p in "${pct_list[@]}"; do
        [[ "$p" =~ ^-?[0-9]+$ ]] || continue
        # Only consider positive regressions
        if (( p > max_positive_pct )); then
          max_positive_pct=$p
        fi
      done
    fi
  else
    # Lightweight fallback: grep out "regressions" structure
    # Count lines containing '"regressions": ['
    regression_count=$(grep -E '"regressions"' "$file" 2>/dev/null | head -1 | sed -n 's/.*"regressions":[[:space:]]*\([0-9]\+\).*/\1/p')
    [[ -z "$regression_count" ]] && regression_count=0
    # Extract lines with pattern label:base:current:delta:pct inside quotes
    while IFS= read -r line; do
      pct=$(echo "$line" | sed -n 's/.*:[0-9]\+:[0-9]\+:[-0-9]\+:\([0-9]\+\)".*/\1/p')
      [[ -z "$pct" ]] && continue
      if [[ "$pct" =~ ^[0-9]+$ ]] && (( pct > max_positive_pct )); then
        max_positive_pct=$pct
      fi
    done < <(grep -E '"[A-Za-z0-9_.-]+:[0-9]+:[0-9]+:-?[0-9]+:-?[0-9]+"' "$file" 2>/dev/null || true)
  fi
}

parse_lines() {
  local file="$1"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Accept either colon schema label:base:current:delta:pct or lines containing 'regression'
    if [[ "$line" == *":"*":"*":"*":"* ]]; then
      # Split to get pct (5th field)
      IFS=':' read -r _l _b _c _d _p <<<"$line"
      if [[ "${_p:-}" =~ ^-?[0-9]+$ ]]; then
        local pct="${_p#-}"  # we measure magnitude for positive direction
        if (( _p > 0 && _p > max_positive_pct )); then
          max_positive_pct=$_p
        fi
        (( regression_count++ ))
      fi
    elif grep -qi 'regression' <<<"$line"; then
      # Can't parse % reliably without schema, treat as generic +1 regression (no pct)
      (( regression_count++ ))
    fi
  done < "$file"
}

case "$parse_mode" in
  json)  parse_json "$DIFF_JSON" ;;
  lines) parse_lines "$REG_LINES" ;;
  *) echo "[perf-drift-badge] ERROR: internal mode switch failed" >&2; exit 2 ;;
esac

# ---------------- Severity & Badge Message ----------------
severity="none"
color="$COLOR_NONE"

# Determine severity using max_positive_pct
float_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }
float_gt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }

# Convert to float-safe for comparisons
warn_thr="$WARN_PCT"
fail_thr="$FAIL_PCT"

if (( regression_count == 0 )); then
  severity="none"
  color="$COLOR_NONE"
else
  # If any regression; use max_positive_pct to decide
  if float_ge "$max_positive_pct" "$fail_thr"; then
    severity="fail"
    color="$COLOR_FAIL"
  elif float_ge "$max_positive_pct" "$warn_thr"; then
    severity="warn"
    color="$COLOR_WARN"
  else
    # Regressions below warn threshold count as 'none' semantically, but we still display number
    severity="none"
    color="$COLOR_NONE"
  fi
fi

format_pct() {
  local v="$1" p="$PRECISION"
  if [[ "$v" =~ ^[0-9]+$ && "$p" =~ ^[0-9]+$ ]]; then
    # Format integer to chosen precision (.0 etc.)
    awk -v x="$v" -v prec="$p" 'BEGIN{fmt="%."prec"f"; printf(fmt,x+0.0)}'
  else
    echo "$v"
  fi
}

badge_message=""
case "$severity" in
  none)
    if (( regression_count == 0 )); then
      badge_message="0"
    else
      # regressions present but below warn threshold
      if (( regression_count == 1 )); then
        badge_message="1 (<$(format_pct "$WARN_PCT")%)"
      else
        badge_message="${regression_count} (<$(format_pct "$WARN_PCT")%)"
      fi
    fi
    ;;
  warn)
    pct_fmt="$(format_pct "$max_positive_pct")"
    badge_message="${regression_count} warn (+${pct_fmt}% max)"
    ;;
  fail)
    pct_fmt="$(format_pct "$max_positive_pct")"
    badge_message="${regression_count} fail (+${pct_fmt}% max)"
    ;;
  *)
    badge_message="parse error"
    color="$COLOR_PARSE_ERR"
    ;;
esac

# ---------------- Emit Badge (Shields JSON) ----------------
json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '{"label":"%s","message":"%s","color":"%s"}\n' \
  "$(printf '%s' "$LABEL" | json_escape)" \
  "$(printf '%s' "$badge_message" | json_escape)" \
  "$(printf '%s' "$color" | json_escape)"

exit 0
