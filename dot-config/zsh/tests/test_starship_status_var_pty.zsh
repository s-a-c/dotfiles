#!/usr/bin/env zsh
# PTY Test: STARSHIP_CMD_STATUS resilience via zpty command loop
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
# Purpose: Validate STARSHIP_CMD_STATUS stays defined across multiple precmd/preexec cycles
#          when driven through a pseudo-terminal (zpty) rather than a here-doc interactive shell.

set -euo pipefail

# Ensure zpty is available
if ! zmodload zsh/zpty 2>/dev/null; then
  echo "SKIP: zsh/zpty not available in this build" >&2
  exit 0
fi

ZDOTDIR=${ZDOTDIR:-$(cd "$(dirname "$0")/.." && pwd)}
export ZDOTDIR

log_file="${TMPDIR:-/tmp}/starship-status-pty-$$.log"
trap 'rm -f "$log_file"' EXIT

echo "[starship-status-pty] log=$log_file" >&2

# Launch interactive shell in PTY
zpty -b starstatus "zsh -i"

_pty_send() { printf '%s\n' "$1" | zpty -w starstatus; }

# Prime: minimal commands to ensure prompt init executed
_pty_send 'echo PTY_TEST_START'
sleep 0.2

cycles=5
for i in $(seq 1 $cycles); do
  _pty_send "echo cycle=$i pre status=\${STARSHIP_CMD_STATUS:-unset} defined=$(( \${+STARSHIP_CMD_STATUS} ))"
  _pty_send 'true'
  _pty_send 'false || true'
  _pty_send "echo cycle=$i mid status=\${STARSHIP_CMD_STATUS:-unset} defined=$(( \${+STARSHIP_CMD_STATUS} ))"
  if [[ $i -eq 3 ]]; then
    _pty_send 'unset STARSHIP_CMD_STATUS 2>/dev/null || true'
    _pty_send 'echo cycle=3 forced_unset'
  fi
  _pty_send "echo cycle=$i post status=\${STARSHIP_CMD_STATUS:-unset} defined=$(( \${+STARSHIP_CMD_STATUS} ))"
done

# Emit a sentinel & health report if available
_pty_send 'which starship_health_report >/dev/null 2>&1 && starship_health_report || echo health_report_missing=1'
_pty_send 'echo STARSHIP_STATUS_TEST_PTY_SENTINEL=1'
_pty_send 'exit'

# Read until sentinel or timeout
end_ts=$((SECONDS + 20))
found=0
{
  while (( SECONDS < end_ts )); do
    if zpty -r starstatus line 2>/dev/null; then
      print -- "$line" >>"$log_file"
      if [[ $line == *STARSHIP_STATUS_TEST_PTY_SENTINEL=1* ]]; then
        found=1
        break
      fi
    else
      sleep 0.05
    fi
  done
} || true

zpty -d starstatus 2>/dev/null || true

if [[ $found -ne 1 ]]; then
  echo "FAIL: Sentinel not observed in PTY log (possible premature termination)" >&2
  sed -n '1,160p' "$log_file" >&2 || true
  exit 1
fi

if grep -q 'parameter not set: STARSHIP_CMD_STATUS' "$log_file"; then
  echo "FAIL: Found 'parameter not set' error in PTY run" >&2
  sed -n '1,160p' "$log_file" >&2 || true
  exit 1
fi

if ! grep -q 'cycle=5 post status' "$log_file"; then
  echo "FAIL: Missing cycle 5 post status line in PTY run" >&2
  sed -n '1,160p' "$log_file" >&2 || true
  exit 1
fi

echo "PASS: STARSHIP_CMD_STATUS stable across PTY cycles" >&2
tail -n 40 "$log_file" 2>/dev/null || true
exit 0
