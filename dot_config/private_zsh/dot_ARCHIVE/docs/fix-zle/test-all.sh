#!/usr/bin/env bash
# test-all.sh - Aggregated harness runner for redesign validation
# Runs (if present): test-smoke.sh, test-terminal-integration.sh, test-phase4.sh
# Provides a concise PASS/FAIL summary; exits non-zero if any mandatory test fails.
# Mandatory: smoke; Optional: others (reported but not fatal unless --strict specified).
set -euo pipefail

STRICT=0
JSON=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    --json) JSON=1 ;;
  esac
done

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT_DIR"

PASS=()
FAIL=()
WARN=()

run() {
  local label="$1" path="$2" mandatory="$3"
  if [[ ! -x "$path" ]]; then
    if [[ -f "$path" ]]; then
      chmod +x "$path" || true
    else
      [[ "$mandatory" == 1 ]] && FAIL+=("$label (missing)") || WARN+=("$label missing (optional)")
      return 0
    fi
  fi
  echo "--- RUN $label ($path) ---" >&2
  if output=$("$path" 2>&1); then
    echo "$output" | sed "s/^/[${label}] /"
    PASS+=("$label")
  else
    status=$?
    echo "$output" | sed "s/^/[${label} ERROR] /" >&2
    if [[ "$mandatory" == 1 || $STRICT == 1 ]]; then
      FAIL+=("$label exit $status")
    else
      WARN+=("$label exit $status (non-mandatory)")
    fi
  fi
}

# Mandatory smoke test
run smoke ./test-smoke.sh 1
# Optional tests
run terminal ./test-terminal-integration.sh 0
run phase4 ./test-phase4.sh 0

STATUS=OK
if (( ${#FAIL[@]:-0} > 0 )); then
  STATUS=FAIL
fi

if (( JSON == 1 )); then
  # Emit JSON to stdout only
  printf '{"status":"%s","strict":%s,' "$STATUS" "$([[ $STRICT == 1 ]] && echo true || echo false)"
  printf '"pass":['
  first=1; for x in "${PASS[@]:-}"; do [[ -z "$x" ]] && continue; [[ $first == 0 ]] && printf ','; printf '"%s"' "$x"; first=0; done; printf '],'
  printf '"warn":['
  first=1; for x in "${WARN[@]:-}"; do [[ -z "$x" ]] && continue; [[ $first == 0 ]] && printf ','; printf '"%s"' "$x"; first=0; done; printf '],'
  printf '"fail":['
  first=1; for x in "${FAIL[@]:-}"; do [[ -z "$x" ]] && continue; [[ $first == 0 ]] && printf ','; printf '"%s"' "$x"; first=0; done; printf ']}'
  echo
else
  echo "" >&2
  echo "Summary:" >&2
  printf '  PASS: %s\n' "${PASS[@]:-}" >&2 || true
  printf '  WARN: %s\n' "${WARN[@]:-}" >&2 || true
  printf '  FAIL: %s\n' "${FAIL[@]:-}" >&2 || true
  if [[ $STATUS == FAIL ]]; then
    echo "FAIL: one or more mandatory (or strict) tests failed" >&2
    exit 1
  fi
  echo "ALL_OK" # Stable token for automation
fi

[[ $STATUS == FAIL ]] && exit 1 || exit 0
