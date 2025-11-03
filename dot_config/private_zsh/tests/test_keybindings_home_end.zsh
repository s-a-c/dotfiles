#!/usr/bin/env bash
# Compliant with [${HOME}/.config/ai/guidelines.md](${HOME}/.config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Test: Verify Home/End keybindings exist across common sequences in active shell.
set -euo pipefail
cd "$(dirname "$0")/.."
ZDOTDIR="$PWD" export ZDOTDIR
log_file="${TMPDIR:-/tmp}/keybindings-home-end-$$.log"
# Launch interactive shell to dump bindkey
zsh -i -c 'bindkey' >"$log_file" 2>/dev/null || true
failures=()
check_seq() {
  local seq="$1" target="$2"; shift 2 || true
  if ! grep -F "${seq}" "$log_file" | grep -q "${target}"; then
    failures+=("${seq}->${target}")
  fi
}
for s in "^[[H" "^[[1~" "^[OH"; do check_seq "$s" beginning-of-line; done
for s in "^[[F" "^[[4~" "^[OF"; do check_seq "$s" end-of-line; done
if (( ${#failures[@]} )); then
  echo "FAIL: Missing Home/End bindings for: ${failures[*]}" >&2
  exit 1
fi
echo "PASS: Home/End keybindings present for all tested sequences"
