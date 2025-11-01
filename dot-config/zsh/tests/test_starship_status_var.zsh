#!/usr/bin/env bash
# Test: STARSHIP_CMD_STATUS resilience & fallback activation
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Purpose: Ensure no 'parameter not set' errors for STARSHIP_CMD_STATUS across multiple prompt cycles.

# If executed with an interpreter other than bash (e.g. user runs `zsh tests/...`),
# seamlessly re-exec under bash so bashisms & -o pipefail semantics are preserved.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

# Portable timeout utility detection (GNU timeout or gtimeout on macOS); fallback to manual watchdog
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN=gtimeout
fi

_run_with_timeout() {
  local seconds="$1"; shift
  if [[ -n "$TIMEOUT_BIN" ]]; then
    "$TIMEOUT_BIN" "${seconds}s" "$@"
    return $?
  fi
  # Preferred manual fallback: perl alarm (does not background interactive job)
  if command -v perl >/dev/null 2>&1; then
    perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
    return $?
  fi
  # Last resort: background watchdog (may interfere with interactive -i shells)
  echo "[watchdog-warning] Using background watchdog fallback; interactive behavior may hang" >&2
  "$@" &
  local cmd_pid=$!
  (
    sleep "$seconds"
    if kill -0 $cmd_pid 2>/dev/null; then
      echo "[watchdog] Command exceeded ${seconds}s; killing pid=$cmd_pid" >&2
      kill $cmd_pid 2>/dev/null || true
      sleep 1
      kill -9 $cmd_pid 2>/dev/null || true
    fi
  ) &
  local watchdog=$!
  wait $cmd_pid || true
  local rc=$?
  kill $watchdog 2>/dev/null || true
  return $rc
}
cd "$(dirname "$0")/.."
ZDOTDIR="$PWD" export ZDOTDIR

# We run an interactive zsh with controlled commands.
log_file="${TMPDIR:-/tmp}/starship-status-test-$$.log"
trap 'rm -f "$log_file"' EXIT
echo "[starship-status-test] log=$log_file" >&2

# The here-doc drives several command cycles; we also force an unset mid-run
# to verify guards reseed without errors.

_run_with_timeout 25 zsh -i <<'EOF' >"$log_file" 2>&1
# Defensive: ensure shell will honor EOF & not require multiple ^D presses.
unsetopt ignoreeof 2>/dev/null || true
setopt prompt_subst 2>/dev/null || true
print '--- BEGIN STARSHIP STATUS TEST ---'
print "ZDOTDIR=$ZDOTDIR"
print "has_starship=$(command -v starship >/dev/null && echo 1 || echo 0)"
for i in 1 2 3 4 5; do
  echo "cycle=$i pre status=${STARSHIP_CMD_STATUS:-unset} defined=$(( ${+STARSHIP_CMD_STATUS} ))"
  true
  false || true
  echo "cycle=$i mid status=${STARSHIP_CMD_STATUS:-unset} defined=$(( ${+STARSHIP_CMD_STATUS} ))"
  # On cycle 3 deliberately unset to test reseed
  if [[ $i -eq 3 ]]; then
    unset STARSHIP_CMD_STATUS 2>/dev/null || true
    echo "cycle=$i forced_unset"
  fi
  echo "cycle=$i post status=${STARSHIP_CMD_STATUS:-unset} defined=$(( ${+STARSHIP_CMD_STATUS} ))"
  # Trigger precmd by printing a newline/prompt boundary; no-op command already does
done
# Report health
which starship_health_report >/dev/null 2>&1 && starship_health_report || echo 'health_report_function_missing=1'
print '--- END STARSHIP STATUS TEST ---'
print 'STARSHIP_STATUS_TEST_SENTINEL=1'
exit
EOF

# Assertions
if grep -q "parameter not set: STARSHIP_CMD_STATUS" "$log_file"; then
  echo "FAIL: Detected 'parameter not set: STARSHIP_CMD_STATUS' in output" >&2
  sed -n '1,120p' "$log_file" >&2
  exit 1
fi
if ! grep -q "cycle=5 post status" "$log_file"; then
  echo "FAIL: Missing cycle output (interactive loop may have aborted)" >&2
  sed -n '1,160p' "$log_file" >&2
  exit 1
fi

# Ensure sentinel present (confirms heredoc fully processed & exit executed)
if ! grep -q 'STARSHIP_STATUS_TEST_SENTINEL=1' "$log_file"; then
  echo "FAIL: Missing sentinel (interactive zsh may not have exited cleanly)" >&2
  sed -n '1,200p' "$log_file" >&2
  exit 1
fi

# If fallback triggered unexpectedly on zero failures, treat as soft warning
if grep -q "\[STARSHIP-FALLBACK]" "$log_file"; then
  echo "NOTE: Fallback activated; check STARSHIP_WRAP_FAILS threshold" >&2
fi

echo "PASS: STARSHIP_CMD_STATUS remained safe across cycles"

# Provide a short tail for convenience in CI or local runs
echo "--- tail (last 40 lines) ---"
tail -n 40 "$log_file" || true
