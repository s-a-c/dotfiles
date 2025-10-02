#!/usr/bin/env bash
# test-terminal-integration.sh - Validate terminal environment flag exports from 100-terminal-integration.zsh
# Simulates different TERM_PROGRAM / TERM values in isolated zsh invocations.
# Exit codes: 0 success, non-zero indicates first failure.
set -euo pipefail

MODULE=".zshrc.d.empty/100-terminal-integration.zsh"
if [[ ! -f $MODULE ]]; then
  echo "ERROR: module $MODULE not found" >&2
  exit 2
fi

run_case() {
  local name="$1" term_program="$2" term_val="$3" expect_flags="$4"
  local out
  out=$(TERM_PROGRAM="$term_program" TERM="$term_val" zsh --no-rcs --no-globalrcs -ic "source $MODULE; env | grep -E '^(WARP_IS_LOCAL_SHELL_SESSION|WEZTERM_SHELL_INTEGRATION|GHOSTTY_SHELL_INTEGRATION|KITTY_SHELL_INTEGRATION)=' || true" )
  printf "CASE %-10s -> %s\n" "$name" "$out"
  # Verify each expected flag appears
  local flag
  for flag in $expect_flags; do
    if ! grep -q "^${flag}=" <<<"$out"; then
      echo "FAIL: $name missing $flag" >&2
      return 1
    fi
  done
}

# Cases: name TERM_PROGRAM TERM expected-flags
run_case warp   WarpTerminal xterm-256color WARP_IS_LOCAL_SHELL_SESSION || exit 1
run_case wez    WezTerm      xterm-256color WEZTERM_SHELL_INTEGRATION || exit 1
run_case ghost  ghostty      xterm-256color GHOSTTY_SHELL_INTEGRATION || exit 1
run_case kitty  unknown      xterm-kitty    KITTY_SHELL_INTEGRATION || exit 1
run_case iterm  iTerm.app    xterm-256color # minimal; no required flags (integration script optional)

echo "PASS: terminal integration flags behave as expected"
exit 0
