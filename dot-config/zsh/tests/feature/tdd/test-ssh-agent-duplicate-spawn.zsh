#!/usr/bin/env zsh
# test-ssh-agent-duplicate-spawn.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE (ACTIVE GATE):
#   Validate SSH agent consolidation invariants against the enhanced implementation in
#   pre‑plugin module `30-ssh-agent.zsh`. This test now ENFORCES behavior (must PASS).
#
# SCOPE:
#   Exercises spawn, reuse, validation, counter, and idempotency guarantees. Assumes the
#   enhanced module defines ensure_ssh_agent and supporting state variables.
#
# INVARIANTS:
#   SA1 ensure_ssh_agent is idempotent.
#   SA2 Invalid / absent socket -> single spawn; second call does NOT spawn again.
#   SA3 _SSH_AGENT_SPAWN_COUNT == 1 after two invocations (spawn + reuse).
#   SA4 Valid socket reuse emits reuse marker.
#   SA5 Validation sentinel _SSH_AGENT_VALIDATED set.
#   SA6 Debug output includes either '[ssh-agent] spawn' then '[ssh-agent] reuse'.
#
# IMPLEMENTATION HOOKS NEEDED (to make this test pass later):
#   - Introduce function: ensure_ssh_agent (or documented alias) invoked during pre-plugin phase.
#   - Manage environment exports: SSH_AUTH_SOCK, SSH_AGENT_PID.
#   - Maintain: integer _SSH_AGENT_SPAWN_COUNT (export optional).
#   - Optional: sentinel file or variable _SSH_AGENT_VALIDATED=1 after first validation path.
#
# TEST STRATEGY:
#   1. Create a temporary directory to simulate invalid and valid socket scenarios.
#   2. Launch a subshell with a deliberately invalid SSH_AUTH_SOCK pointing to a stale path.
#   3. Source `.zshenv` and the pre-plugin module directory (no other user config).
#   4. Invoke the (future) consolidating function twice (or simulate by sourcing module twice if function absent).
#   5. Capture:
#        - Final environment variables (SSH_AUTH_SOCK, SSH_AGENT_PID)
#        - Any exposed counters (_SSH_AGENT_SPAWN_COUNT)
#        - Debug lines (requires ZSH_DEBUG=1)
#   6. Assert invariants (currently EXPECTED TO FAIL).
#
# FAILURE MODE:
#   Accumulates any invariant violations and exits non‑zero; otherwise emits PASS.
#
# TEMPORARY SKIP (never commit with this set):
#   export TDD_ALLOW_FAIL_SSH_AGENT_DUP=1
#
# EXIT CODES:
#   0 PASS
#   1 FAIL (one or more invariants broken)
#   2 SKIP (developer local skip)
#
set -euo pipefail

if [[ "${TDD_ALLOW_FAIL_SSH_AGENT_DUP:-0}" == 1 ]]; then
    echo "SKIP: SSH agent duplicate spawn feature test (TDD_ALLOW_FAIL_SSH_AGENT_DUP=1)"
    exit 2
fi

if typeset -f zf::script_dir >/dev/null 2>&1; then
REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/../../../../" && pwd -P)"
else
REPO_ROOT="$(cd "${(%):-%N:h}/../../../../" && pwd -P)"
fi

cd "$REPO_ROOT"

# Synthetic invalid socket path
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

INVALID_SOCK="$TEMP_DIR/invalid-agent.sock"

# Build script to run in isolated subshell
subshell_script=$'
set -euo pipefail
export ZSH_DEBUG=1
export SSH_AUTH_SOCK="'$INVALID_SOCK'"
unset SSH_AGENT_PID || true
source ./.zshenv 2>/dev/null || true

# Source pre-plugin modules explicitly (mimic loader ordering)
for f in ./.zshrc.pre-plugins.d.REDESIGN/*.zsh; do
  source "$f"
done

# Preferred consolidating function name (future). If absent, we fallback to sourcing ssh-agent module twice.
agent_fn=""
for candidate in ensure_ssh_agent start_ssh_agent init_ssh_agent manage_ssh_agent; do
  if typeset -f "$candidate" >/dev/null 2>&1; then
    agent_fn="$candidate"
    break
  fi
done

if [[ -n "$agent_fn" ]]; then
  "$agent_fn" >/dev/null 2>&1 || true
  "$agent_fn" >/dev/null 2>&1 || true
else
  # Re-source the module to simulate re-entry idempotency expectation
  src="./.zshrc.pre-plugins.d.REDESIGN/30-ssh-agent.zsh"
  [[ -f "$src" ]] && source "$src"
  [[ -f "$src" ]] && source "$src"
fi

# Dump environment / markers
echo "__ENV_SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-}"
echo "__ENV_SSH_AGENT_PID=${SSH_AGENT_PID:-}"
echo "__ENV_SPAWN_COUNT=${_SSH_AGENT_SPAWN_COUNT:-<unset>}"
echo "__ENV_VALIDATED=${_SSH_AGENT_VALIDATED:-<unset>}"

# Grep any debug output we can capture by replaying module once more under debug
' # end subshell script variable

# Execute subshell and capture output (stderr merged for debug lines)
OUTPUT="$(bash -c "$subshell_script" 2>&1 || true)"

# Collect violations
violations=()

extract() {
    echo "$OUTPUT" | grep -E "^$1=" | head -1 | sed "s/^$1=//"
}

sock=$(extract "__ENV_SSH_AUTH_SOCK")
pidv=$(extract "__ENV_SSH_AGENT_PID")
spawn_count=$(extract "__ENV_SPAWN_COUNT")
validated=$(extract "__ENV_VALIDATED")

# V1: Spawn count variable should exist and be >=1 and equal to 1 after two invocations (NOT IMPLEMENTED YET)
if [[ "$spawn_count" == "<unset>" ]]; then
    violations+="+ V1 spawn counter _SSH_AGENT_SPAWN_COUNT missing"
else
    if ! [[ "$spawn_count" == "1" ]]; then
        violations+="+ V1 expected _SSH_AGENT_SPAWN_COUNT=1 got '$spawn_count'"
    fi
fi

# V2: After first call with invalid socket, SSH_AUTH_SOCK should point to a (future) created socket path (file exists & is a socket)
if [[ -n "$sock" && -S "$sock" ]]; then
    : # pass
else
    violations+="+ V2 expected a valid socket path (got '$sock')"
fi

# V3: SSH_AGENT_PID should be exported and correspond to a live process (portable check)
if [[ -n "$pidv" && "$pidv" != "<unset>" && "$pidv" =~ '^[0-9]+$' ]]; then
    if ps -p "$pidv" >/dev/null 2>&1; then
        : # pass
    else
        violations+="+ V3 ssh-agent process not found via ps (pid=$pidv)"
    fi
else
    violations+="+ V3 expected numeric SSH_AGENT_PID (got '$pidv')"
fi

# V4: Validation sentinel should be set after first successful path
if [[ "$validated" == "<unset>" ]]; then
    violations+="+ V4 expected _SSH_AGENT_VALIDATED sentinel"
fi

# V5: Debug output should include both spawn (first) and reuse (second) markers
if ! echo "$OUTPUT" | grep -qi "[ssh-agent].*spawn"; then
    violations+="+ V5 missing spawn marker"
fi
if ! echo "$OUTPUT" | grep -qi "[ssh-agent].*reuse"; then
    violations+="+ V5 missing reuse marker"
fi

# Summarize
if ((${#violations[@]} == 0)); then
    echo "PASS: SSH agent consolidation invariants satisfied"
    exit 0
fi

echo "FAIL: SSH agent consolidation invariant violations:"
for v in "${violations[@]}"; do
    echo "  $v"
done

echo ""
echo "---- Diagnostic Output (first 60 lines) ----"
echo "$OUTPUT" | head -60 | sed 's/^/  /'
echo "-------------------------------------------"

exit 1
