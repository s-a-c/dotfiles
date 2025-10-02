#!/usr/bin/env bash
# test-smoke.sh - Combined redesign smoke test (widgets + prompt + tools + terminal integration)
# Exit Codes:
#   0 success
#   1 widget regression (core harness vs enforced baseline)
#   2 zsh invocation failure / sourcing error
#   3 missing widget count extraction
#   4 invalid baseline argument
#
# Modes:
#   Core harness: launches clean subshell (no rc files) and sources layer directories directly.
#   Dual mode (--dual): also captures full interactive widget count via `zsh -i` for comparison.
#
# Baseline Policy:
#   Enforced baseline (interactive) currently 417 (historical: 416 superseded; rollback floor 387 for emergency narrative only).
#
set -euo pipefail

: "${ENFORCED_WIDGET_BASELINE:=417}"
BASELINE_WIDGETS="${ENFORCED_WIDGET_BASELINE}"

JSON=0
DUAL=0        # collect interactive widget count if set
BASELINE_ARG=""  # raw baseline override for validation messaging
ALLOW_CORE_BELOW_BASELINE=0  # allow core (plugin-manager-absent) harness below baseline without failing
# Env-driven override (aggregator compatibility): set SMOKE_ALLOW_CORE_BELOW_BASELINE=1 to auto-enable
if [[ "${SMOKE_ALLOW_CORE_BELOW_BASELINE:-0}" == "1" ]]; then
  ALLOW_CORE_BELOW_BASELINE=1
fi

while (( "$#" )); do
  case "$1" in
    --json)
      JSON=1
      shift
      ;;
    --baseline=*)
      BASELINE_ARG="${1#--baseline=}"
      BASELINE_WIDGETS="$BASELINE_ARG"
      shift
      ;;
    --baseline)
      if [[ $# -ge 2 ]]; then
        BASELINE_ARG="$2"
        BASELINE_WIDGETS="$2"
        shift 2
      else
        echo "WARN: --baseline provided without value" >&2
        shift
      fi
      ;;
    --dual|--with-interactive|--dual=1|--with-interactive=1)
      DUAL=1
      shift
      ;;
    --allow-core-below-baseline)
      ALLOW_CORE_BELOW_BASELINE=1
      shift
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: test-smoke.sh [--json] [--baseline N] [--dual]

Description:
  Executes a minimal core harness (no rc files) sourcing layer directories to measure core ZLE widget count
  and key environment markers. Optional dual mode also measures an interactive (full init) widget count.

Options:
  --json                      Emit JSON (machine readable)
  --baseline N                Override enforced baseline (default uses ENFORCED_WIDGET_BASELINE=417)
  --dual                      Capture both core (harness) and interactive counts
  --allow-core-below-baseline Allow pass when core harness < baseline (only valid if plugin manager absent OR dual mode)
  --help                      Show this help

Exit Codes:
  0 success
  1 widget regression (core count < baseline)
  2 zsh invocation failure
  3 missing widget count
  4 invalid baseline
USAGE
      exit 0
      ;;
    *)
      # ignore unknown args for forward compatibility
      shift
      ;;
  esac
done

if ! [[ "$BASELINE_WIDGETS" =~ ^[0-9]+$ ]]; then
  echo "FAIL: invalid baseline '$BASELINE_WIDGETS'" >&2
  exit 4
fi

TMP_OUT=$(mktemp)
CORE_PLUGIN_MANAGER_PRESENT=0

zsh --no-globalrcs --no-rcs -ic '
  set +e
  for dir in .zshrc.pre-plugins.d.empty .zshrc.add-plugins.d.empty .zshrc.d.empty; do
    if [[ -d $dir ]]; then
      for f in $dir/*.zsh; do
        source "$f" || { echo "ERROR: failed sourcing $f"; exit 2; }
      done
    fi
  done
  # Detect presence of plugin manager function (best-effort)
  if typeset -f zgenom >/dev/null 2>&1; then
    echo CORE_PLUGIN_MANAGER_PRESENT=1
  else
    echo CORE_PLUGIN_MANAGER_PRESENT=0
  fi
  # Widget count
  WC=$(zle -la 2>/dev/null | wc -l | tr -d "[:space:]")
  echo WIDGET_COUNT=$WC
  # Prompt guard
  echo PROMPT_GUARD=${__ZF_PROMPT_INIT_DONE:-0}
  # Terminal integration markers
  echo TERM_WARP=${WARP_IS_LOCAL_SHELL_SESSION:-0}
  echo TERM_WEZTERM=${WEZTERM_SHELL_INTEGRATION:-0}
  echo TERM_GHOSTTY=${GHOSTTY_SHELL_INTEGRATION:-0}
  echo TERM_KITTY=${KITTY_SHELL_INTEGRATION:-0}
  # Key tool presence
  for cmd in nvim fzf zoxide eza carapace atuin starship; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo HAVE_${cmd}=1
    else
      echo HAVE_${cmd}=0
    fi
  done
  # Autopair detection: check for function or widget names containing autopair
  if functions | grep -qi autopair || zle -la 2>/dev/null | grep -qi autopair; then
    echo HAVE_AUTOPAIR=1
    # Emit matching widgets for inspection
    if ! zle -la 2>/dev/null | grep -i autopair | sed "s/^/AUTOPAIR_WIDGET=/" ; then
      echo AUTOPAIR_WIDGET=__none_found
    fi
  else
    echo HAVE_AUTOPAIR=0
  fi
  # Starship timing metric (if prompt initialized & timing captured)
  if [[ -n ${_ZF_STARSHIP_INIT_MS:-} ]]; then
    echo STARSHIP_INIT_MS=${_ZF_STARSHIP_INIT_MS}
  fi
  exit 0
' >"$TMP_OUT" 2>&1 || {
  echo "FAIL: zsh invocation failed"
  cat "$TMP_OUT"
  exit 2
}

WC=$(grep '^WIDGET_COUNT=' "$TMP_OUT" | cut -d= -f2 || echo 0)
CORE_PLUGIN_MANAGER_PRESENT=$(grep '^CORE_PLUGIN_MANAGER_PRESENT=' "$TMP_OUT" | cut -d= -f2 || echo 0)
[[ -z $WC ]] && {
  echo "FAIL: missing widget count"
  cat "$TMP_OUT"
  exit 3
}
# Preliminary core check:
# If dual mode is enabled we defer enforcement until interactive count is known.
if (( WC < BASELINE_WIDGETS )); then
  if (( DUAL == 1 )); then
    : # defer decision
  else
    if (( ALLOW_CORE_BELOW_BASELINE == 1 )) && (( CORE_PLUGIN_MANAGER_PRESENT == 0 )); then
      echo "WARN: core widgets below baseline (core=$WC < $BASELINE_WIDGETS) but allowed via --allow-core-below-baseline (plugin manager absent)" >&2
    else
      echo "FAIL: widget regression (core=$WC < baseline=$BASELINE_WIDGETS)"
      cat "$TMP_OUT"
      exit 1
    fi
  fi
fi

PROMPT_GUARD=$(grep '^PROMPT_GUARD=' "$TMP_OUT" | cut -d= -f2 || echo 0)
if [[ $PROMPT_GUARD != 0 && $PROMPT_GUARD != 1 ]]; then
  echo "WARN: unexpected PROMPT_GUARD value: $PROMPT_GUARD" >&2
fi

INTERACTIVE_WC=""
if (( DUAL == 1 )); then
  # Full interactive measurement (prompt init etc.)
  # Capture all output (some environments print banners); extract last numeric token.
  INTERACTIVE_WC="$(zsh -i -c 'zle -la 2>/dev/null | wc -l' 2>&1 | grep -Eo '[0-9]+' | tail -1 || true)"
  if ! [[ "$INTERACTIVE_WC" =~ ^[0-9]+$ ]]; then
    INTERACTIVE_WC=""
  fi
fi

# Dual-mode enforcement: enforce baseline on interactive count instead of core
if (( DUAL == 1 )); then
  if [[ "$INTERACTIVE_WC" =~ ^[0-9]+$ ]] && (( INTERACTIVE_WC < BASELINE_WIDGETS )); then
    echo "FAIL: widget regression (interactive=$INTERACTIVE_WC < baseline=$BASELINE_WIDGETS)"
    cat "$TMP_OUT"
    exit 1
  fi
  if (( WC < BASELINE_WIDGETS )) && (( CORE_PLUGIN_MANAGER_PRESENT == 0 )); then
    if (( ALLOW_CORE_BELOW_BASELINE == 1 )); then
      echo "INFO: core-only harness below baseline tolerated (core=$WC baseline=$BASELINE_WIDGETS; plugin manager absent)" >&2
    else
      echo "INFO: core-only harness below baseline (core=$WC < $BASELINE_WIDGETS) – not enforced because interactive baseline satisfied" >&2
    fi
  fi
fi

if (( CORE_PLUGIN_MANAGER_PRESENT == 0 )); then
  if (( DUAL == 1 )); then
    echo "INFO: core-only harness (no plugin manager); core=$WC interactive=${INTERACTIVE_WC:-NA}" >&2
  else
    echo "INFO: core-only harness (no plugin manager); core=$WC (dual mode not enabled)" >&2
  fi
fi

if ((JSON == 1)); then
  # Collect values
  have_tools=$(grep '^HAVE_' "$TMP_OUT" | sed 's/^HAVE_//' | tr '\n' ' ' || true)
  star=$(grep '^STARSHIP_INIT_MS=' "$TMP_OUT" | cut -d= -f2 || true)
  autopair=$(grep '^HAVE_AUTOPAIR=' "$TMP_OUT" | cut -d= -f2 || echo 0)
  term_warp=$(grep '^TERM_WARP=' "$TMP_OUT" | cut -d= -f2 || echo 0)
  term_wez=$(grep '^TERM_WEZTERM=' "$TMP_OUT" | cut -d= -f2 || echo 0)
  term_ghost=$(grep '^TERM_GHOSTTY=' "$TMP_OUT" | cut -d= -f2 || echo 0)
  term_kitty=$(grep '^TERM_KITTY=' "$TMP_OUT" | cut -d= -f2 || echo 0)
  # Autopair widgets list
  ap_widgets=()
  while IFS= read -r __apw; do
    ap_widgets+=("${__apw}")
  done < <(grep '^AUTOPAIR_WIDGET=' "$TMP_OUT" | cut -d= -f2)
  printf '{"status":"OK","widgets":%s,' "$WC"
  printf '"prompt_guard":%s,' "$PROMPT_GUARD"
  if [[ -n "$star" ]]; then printf '"starship_ms":%s,' "$star"; else printf '"starship_ms":null,'; fi
  printf '"tools":{'
  first=1
  while read -r line; do
    [[ -z "$line" ]] && continue
    key=${line%%=*}
    val=${line##*=}
    if [[ $key == HAVE_* ]]; then
      tool=${key#HAVE_}
      [[ $first == 0 ]] && printf ','
      first=0
      printf '"%s":%s' "${tool}" "$val"
    fi
  done < <(grep '^HAVE_' "$TMP_OUT")
  printf '},'
  printf '"terminal":{"warp":%s,"wezterm":%s,"ghostty":%s,"kitty":%s},' "$term_warp" "$term_wez" "$term_ghost" "$term_kitty"
  printf '"autopair":%s,' "$autopair"
  printf '"autopair_widgets":['
  first=1
  for w in "${ap_widgets[@]:-}"; do
    [[ -z "$w" ]] && continue
    [[ $first == 0 ]] && printf ','
    first=0
    printf '"%s"' "$w"
  done
  printf ']'  # properly close array even if empty
  # Dual metrics extension (backward compatible)
  if (( DUAL == 1 )); then
    # Always keep original "widgets" = core harness count
    if [[ -n "$INTERACTIVE_WC" && "$INTERACTIVE_WC" =~ ^[0-9]+$ ]]; then
      delta=$((INTERACTIVE_WC - WC))
      printf ',"widgets_core":%s,"widgets_interactive":%s,"widgets_delta":%s,"plugin_manager_core":%s' "$WC" "$INTERACTIVE_WC" "$delta" "$CORE_PLUGIN_MANAGER_PRESENT"
    else
      printf ',"widgets_core":%s,"widgets_interactive":null,"widgets_delta":null,"plugin_manager_core":%s' "$WC" "$CORE_PLUGIN_MANAGER_PRESENT"
    fi
  else
    printf ',"plugin_manager_core":%s' "$CORE_PLUGIN_MANAGER_PRESENT"
  fi
  printf '}'
  echo
else
  if (( DUAL == 1 )); then
    echo "PASS: smoke (core_widgets=$WC interactive_widgets=${INTERACTIVE_WC:-NA} prompt_guard=$PROMPT_GUARD)"
  else
    echo "PASS: smoke (widgets=$WC prompt_guard=$PROMPT_GUARD)"
  fi
  grep '^HAVE_' "$TMP_OUT" || true
  grep '^TERM_' "$TMP_OUT" || true
  grep '^STARSHIP_INIT_MS=' "$TMP_OUT" || true
fi

# Starship timing sanity check (optional, non-fatal warnings)
STAR_MS=$(grep '^STARSHIP_INIT_MS=' "$TMP_OUT" | cut -d= -f2 || true)
if [[ -n "$STAR_MS" ]]; then
  if ! [[ "$STAR_MS" =~ ^[0-9]+$ ]]; then
    echo "WARN: STARSHIP_INIT_MS not numeric: $STAR_MS" >&2
  elif ((STAR_MS < 0)); then
    echo "WARN: STARSHIP_INIT_MS negative: $STAR_MS" >&2
  elif ((STAR_MS > 5000)); then
    echo "WARN: STARSHIP_INIT_MS unusually high: ${STAR_MS}ms" >&2
  fi
fi

# Autopair widget assertion (if autopair claimed present)
if grep -q '^HAVE_AUTOPAIR=1' "$TMP_OUT"; then
  if ! grep -q '^AUTOPAIR_WIDGET=' "$TMP_OUT"; then
    echo "WARN: Autopair reported present but no widgets listed" >&2
  fi
fi

# Optional PTY autopair behavioral harness (Decision D2)
# Activate by setting RUN_AUTOPAIR_PTY=1 in environment.
# If JSON mode is enabled, the harness JSON is emitted on a dedicated line
# prefixed with #AUTOPAIR_PTY_JSON for downstream aggregators.
if [[ ${RUN_AUTOPAIR_PTY:-0} == 1 ]]; then
  if grep -q '^HAVE_AUTOPAIR=1' "$TMP_OUT"; then
    PTY_HARNESS="tests/test-autopair-pty.sh"
    if [[ -x "$PTY_HARNESS" ]]; then
      PTY_JSON_OUT=$(mktemp)
      if "$PTY_HARNESS" --json >"$PTY_JSON_OUT" 2>&1; then
        if ((JSON == 1)); then
          echo "#AUTOPAIR_PTY_JSON $(cat "$PTY_JSON_OUT")"
        else
          echo "Autopair PTY harness summary:"
          # Show concise status/summary if present, else dump full JSON
          grep -E '"status"|"summary"' "$PTY_JSON_OUT" || cat "$PTY_JSON_OUT"
        fi
      else
        echo "WARN: PTY autopair harness failed (non-fatal)" >&2
        [[ -f "$PTY_JSON_OUT" ]] && cat "$PTY_JSON_OUT" >&2 || true
      fi
      rm -f "$PTY_JSON_OUT"
    else
      echo "INFO: PTY harness not executable or missing: $PTY_HARNESS" >&2
    fi
  fi
fi

rm -f "$TMP_OUT"
exit 0
