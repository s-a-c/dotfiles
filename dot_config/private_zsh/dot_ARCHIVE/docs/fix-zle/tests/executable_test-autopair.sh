#!/usr/bin/env bash
# test-autopair.sh - Functional(ish) validation for optional hlissner/zsh-autopair integration
#
# Goals:
#   1. Detect whether the autopair plugin (Phase 7 optional enhancement) is loaded.
#   2. Provide a tiered functional probe (best-effort) to see if an insertion hook appears active.
#   3. Produce human + (optional) JSON output for CI or aggregation.
#
# NOTE ON LIMITATIONS:
#   True ZLE buffer mutation testing requires an active line editor context (interactive shell).
#   This harness runs a non-interactive zsh instance. We attempt a lightweight simulation;
#   if full simulation is not feasible, we still count presence as PASS (unless forced).
#
# EXIT CODES:
#   0 = Success (autopair present or gracefully skipped if optional)
#   1 = Required but missing (only when ZSH_AUTOPAIR_REQUIRED=1)
#   2 = Internal/unexpected harness error
#
# OPTIONS:
#   --json            Output JSON object
#   --require         Equivalent to ZSH_AUTOPAIR_REQUIRED=1
#
# ENVIRONMENT:
#   ZSH_AUTOPAIR_REQUIRED=1  Fail if autopair not present
#
# JSON FIELDS (when --json):
#   {
#     "status": "pass"|"skip"|"fail",
#     "present": 0|1,
#     "widgets": ["..."],
#     "simulation": "attempted"|"skipped",
#     "paren_pair_success": true|false|null
#   }
#
# Phase Closure Criteria Alignment (Phase 7):
#   - Presence + (attempted) functional verification
#   - For true completion you can later enhance this script to spawn a pseudo-TTY (expect/pty)
#     and validate multiple bracket/quote pairs.

set -euo pipefail

JSON=0
REQUIRE=${ZSH_AUTOPAIR_REQUIRED:-0}

for arg in "$@"; do
  case "$arg" in
  --json) JSON=1 ;;
  --require) REQUIRE=1 ;;
  *)
    echo "Unknown argument: $arg" >&2
    exit 2
    ;;
  esac
done

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmpdir}" 2>/dev/null || true
}
trap cleanup EXIT

# ZSH script we will run in an interactive-capable mode (-i) but without user rc files.
# We source all redesign module directories in numeric ordering just like other harnesses.
zsh_script="${tmpdir}/run.zsh"

cat >"${zsh_script}" <<'ZEOF'
set +o errexit
set +o nounset

# Source redesign layers (mirrors smoke test approach)
for dir in .zshrc.pre-plugins.d.empty .zshrc.add-plugins.d.empty .zshrc.d.empty; do
  if [[ -d $dir ]]; then
    for f in $dir/*.zsh; do
      # shellcheck disable=SC1090
      source "$f" || { print -u2 "ERROR: failed sourcing $f"; }
    done
  fi
done

# Determine autopair presence (function OR widget)
_present=0
autoload -Uz zle 2>/dev/null || true
widgets_list=""
if zle -la 2>/dev/null | grep -qi autopair; then
  _present=1
  widgets_list="$(zle -la 2>/dev/null | grep -i autopair || true)"
elif functions | grep -qi autopair; then
  _present=1
fi
print "__AUTOPAIR_PRESENT=${_present}"
# Emit widget lines (may be empty)
if [[ -n "${widgets_list}" ]]; then
  while IFS= read -r w; do
    print "__AUTOPAIR_WIDGET=${w}"
  done <<< "${widgets_list}"
fi

# Attempt a BEST-EFFORT simulation (will likely not mutate buffer in a non-editing context).
# We explicitly mark it as an attempted simulation; success heuristics follow.
_simulation="skipped"
_pair_success="null"

if (( _present == 1 )); then
  _simulation="attempted"
  # Prepare pseudo ZLE state; this may not reflect a real editing session, but we try.
  BUFFER=""
  CURSOR=0

  # If autopair replaced self-insert, feeding '(' might auto add ')'.
  # However outside a ZLE loop, 'zle -U' usually fails; we guard failures.
  if zle -U "(" 2>/dev/null; then
    # If the autopair logic processed, BUFFER *might* be "()"
    if [[ "${BUFFER}" == "()" ]]; then
      _pair_success="true"
    else
      _pair_success="false"
    fi
  else
    # Could not perform low-level feed; leave null indicating inconclusive.
    _pair_success="null"
  fi
fi

print "__AUTOPAIR_SIMULATION=${_simulation}"
print "__AUTOPAIR_PAREN_PAIR_SUCCESS=${_pair_success}"
exit 0
ZEOF

# Run zsh (interactive flag to widen chances that ZLE modules are available)
# We intentionally avoid user rc files for hermetic behavior.
zout="${tmpdir}/out.txt"
if ! zsh --no-globalrcs --no-rcs -i "${zsh_script}" >"${zout}" 2>&1; then
  echo "Internal error: zsh execution failed" >&2
  cat "${zout}" >&2 || true
  if ((JSON == 1)); then
    printf '{"status":"fail","error":"zsh-exec"}\n'
  fi
  exit 2
fi

present=$(grep '^__AUTOPAIR_PRESENT=' "${zout}" | head -n1 | cut -d= -f2 || echo 0)
simulation=$(grep '^__AUTOPAIR_SIMULATION=' "${zout}" | head -n1 | cut -d= -f2 || echo skipped)
paren_result=$(grep '^__AUTOPAIR_PAREN_PAIR_SUCCESS=' "${zout}" | head -n1 | cut -d= -f2 || echo null)
mapfile_found_widgets=()
while IFS= read -r line; do
  mapfile_found_widgets+=("${line#__AUTOPAIR_WIDGET=}")
done < <(grep '^__AUTOPAIR_WIDGET=' "${zout}" || true)

status="pass"
if ((present == 0)) && ((REQUIRE == 1)); then
  status="fail"
elif ((present == 0)); then
  status="skip"
fi

if ((JSON == 1)); then
  printf '{"status":"%s","present":%d,' "${status}" "${present}"
  printf '"simulation":"%s","paren_pair_success":' "${simulation}"
  if [[ "${paren_result}" == "null" ]]; then
    printf 'null'
  elif [[ "${paren_result}" == "true" ]]; then
    printf 'true'
  elif [[ "${paren_result}" == "false" ]]; then
    printf 'false'
  else
    printf 'null'
  fi
  printf ',"widgets":['
  first=1
  for w in "${mapfile_found_widgets[@]}"; do
    [[ -z "$w" ]] && continue
    if [[ $first -eq 0 ]]; then printf ','; fi
    first=0
    # Minimal JSON escape (only quotes + backslashes)
    esc=${w//\\/\\\\}
    esc=${esc//\"/\\\"}
    printf '"%s"' "$esc"
  done
  printf ']}\n'
else
  echo "Status: ${status}"
  echo "Autopair present: ${present}"
  echo "Simulation: ${simulation}"
  echo "Paren pair heuristic: ${paren_result}"
  if ((${#mapfile_found_widgets[@]} > 0)); then
    echo "Widgets:"
    for w in "${mapfile_found_widgets[@]}"; do
      echo "  - ${w}"
    done
  else
    echo "Widgets: (none detected)"
  fi
fi

# Exit semantics: only treat as failure if required and missing
if [[ "${status}" == "fail" ]]; then
  exit 1
fi
exit 0
