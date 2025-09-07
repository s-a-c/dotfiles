#!/usr/bin/env zsh
# dotfiles/dot-config/zsh/tests/unit/test-40-runtime.zsh
# Minimal unit test for 40-runtime module (runtime optimizations)
# Verifies:
#  - module loads when feature flag enabled
#  - public function `zred::runtime::optimize` exists and is callable
#  - optimize() is idempotent and sets a visible status variable
set -euo pipefail

# Prefer repo-local ZDOTDIR when running from repository root in CI/local dev
ZDOTDIR="${ZDOTDIR:-${PWD}/dot-config/zsh}"
[[ -f "${ZDOTDIR}/.zshenv" ]] && source "${ZDOTDIR}/.zshenv"

# Ensure we exercise redesign paths
export ZSH_USE_REDESIGN=1

# Source the module directly (module is idempotent/safe)
MODULE="${ZDOTDIR}/.zshrc.d.REDESIGN/40-runtime-optimization.zsh"
if [[ ! -f "${MODULE}" ]]; then
  echo "FAIL: runtime module not found at ${MODULE}" >&2
  exit 1
fi
# Source in a subshell-like isolated manner to avoid polluting test harness,
# but we want definitions available in this shell so source normally.
source "${MODULE}"

# Basic assertions
# 1) Sentinel loaded
if [[ -z "${_ZRED_40_LOADED:-}" ]]; then
  echo "FAIL: sentinel _ZRED_40_LOADED not set after sourcing module" >&2
  exit 1
fi

# 2) Function exists
if ! typeset -f zred::runtime::optimize >/dev/null 2>&1; then
  echo "FAIL: function zred::runtime::optimize not found" >&2
  exit 1
fi

# 3) Initial status (may be 0 if not auto-applied); run optimize and verify applied
zred::runtime::optimize

# The module exports a status variable ZRED_RUNTIME_OPTIMIZED when applied
if [[ "${ZRED_RUNTIME_OPTIMIZED:-0}" != "1" && "${_ZRED_40_APPLIED:-0}" != "1" ]]; then
  echo "FAIL: optimize did not mark as applied (ZRED_RUNTIME_OPTIMIZED or _ZRED_40_APPLIED)" >&2
  exit 1
fi

# 4) Idempotency: calling optimize again should not error and status remains applied
zred::runtime::optimize >/dev/null 2>&1 || {
  echo "FAIL: second call to zred::runtime::optimize failed" >&2
  exit 1
}

if [[ "${ZRED_RUNTIME_OPTIMIZED:-0}" != "1" && "${_ZRED_40_APPLIED:-0}" != "1" ]]; then
  echo "FAIL: optimize lost applied status after second call" >&2
  exit 1
fi

# All checks passed
echo "PASS: 40-runtime module basic unit checks (sentinel, function, apply, idempotency)"
exit 0
