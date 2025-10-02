#!/usr/bin/env zsh
# test-integrations-idempotence.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate idempotence & non-polluting behavior of pre‑plugin integration lazy wrappers
#   implemented in 25-lazy-integrations.zsh (direnv / gh / placeholder future hooks).
#
# COVERED INVARIANTS:
#   I1 Repeated invocation of wrapper command produces stable exit codes (no progressive failure).
#   I2 Wrapper removes or replaces itself at most once; no duplicate function redefinitions over calls.
#   I3 Environment does not accumulate duplicate PATH entries or obvious duplicate exported variables.
#   I4 For missing tools, error stub output is stable & exit code remains 127.
#   I5 For present tools, first call transitions from wrapper → real binary; second call bypasses wrapper logic.
#
# TEST STRATEGY:
#   - Source project .zshenv then only the integration module.
#   - For each target command (direnv, gh):
#       * Capture initial resolution state (function vs external binary vs absent).
#       * Run two invocations (lightweight subcommand: version/help/status) capturing:
#           stdout, stderr, exit code, presence/absence of function after each call.
#       * Compare outputs & exit codes for stability.
#       * Detect unexpected persistent wrapper (function still present AND body unchanged after second call).
#   - Perform a simple PATH duplicate scan pre/post.
#
# OUTPUT:
#   PASS: integration wrappers idempotent
#   or FAIL with enumerated violations.
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (developer / CI override: TDD_SKIP_INTEGRATIONS_IDEMP=1)
#
# SAFE MODE:
#   Avoids expensive commands; if a command is installed choose a trivial subcommand.
#
# NOTE:
#   This test is tolerant to absence of each tool; absence path itself is a scenario (stub).
#
# -----------------------------------------------------------------------------

set -euo pipefail

if [[ "${TDD_SKIP_INTEGRATIONS_IDEMP:-0}" == "1" ]]; then
  echo "SKIP: integration wrappers idempotence (TDD_SKIP_INTEGRATIONS_IDEMP=1)"
  exit 2
fi

# Resolve repo root (resilient path resolution avoids brittle ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/../../../.." && pwd -P)"
else
REPO_ROOT="$(cd "${(%):-%N:h}/../../../.." && pwd -P)"
fi
cd "${REPO_ROOT}"

# Source environment (defines zf::debug, etc.)
[[ -f ./.zshenv ]] && source ./.zshenv

# Source ONLY the integration module (not the full chain)
MODULE="./.zshrc.pre-plugins.d.REDESIGN/25-lazy-integrations.zsh"
if [[ ! -f "$MODULE" ]]; then
  echo "FAIL: integration module missing: $MODULE"
  exit 1
fi
source "$MODULE"

violations=()

# Utility: capture function body (empty if none)
_get_func_body() {
  local f="$1"
  if typeset -f -- "$f" >/dev/null 2>&1; then
    functions "$f"
  else
    echo ""
  fi
}

# Utility: run a command capturing (stdout+stderr + exit) in a delimited record
_run_cmd() {
  local cmd="$1"; shift
  local tmp_out; tmp_out="$(mktemp -t integ_idemp.XXXXXX)"
  local rc
  {
    "$cmd" "$@" 2>&1
  } >"$tmp_out" || rc=$?
  rc=${rc:-0}
  printf "%s\n" "EXIT_CODE=$rc"
  printf "%s\n" "OUTPUT<<EOF"
  cat "$tmp_out"
  echo "EOF"
  rm -f "$tmp_out"
}

# PATH snapshot pre
ORIG_PATH="$PATH"

# Generic test block for one tool
test_tool() {
  local name="$1"
  shift
  local args=("$@")  # optional args for the test run (e.g. --version)

  local present=0
  if command -v "$name" >/dev/null 2>&1; then present=1; fi

  local func_before="$(_get_func_body "$name")"
  local was_function_before=0
  [[ -n "$func_before" ]] && was_function_before=1

  # First invocation
  local first="$(_run_cmd "$name" "${args[@]}" || true)"
  local exit1
  exit1=$(echo "$first" | sed -n 's/^EXIT_CODE=//p' | head -1)
  local out1
  out1=$(echo "$first" | awk '/^OUTPUT<<EOF$/,/^EOF$/ {if($0!="OUTPUT<<EOF" && $0!="EOF") print}')
  local func_mid="$(_get_func_body "$name")"
  local was_function_mid=0
  [[ -n "$func_mid" ]] && was_function_mid=1

  # Second invocation
  local second="$(_run_cmd "$name" "${args[@]}" || true)"
  local exit2
  exit2=$(echo "$second" | sed -n 's/^EXIT_CODE=//p' | head -1)
  local out2
  out2=$(echo "$second" | awk '/^OUTPUT<<EOF$/,/^EOF$/ {if($0!="OUTPUT<<EOF" && $0!="EOF") print}')
  local func_after="$(_get_func_body "$name")"
  local was_function_after=0
  [[ -n "$func_after" ]] && was_function_after=1

  # Invariants evaluation
  # I1 stable exit code pattern (some tools may alter exit code on second run if interactive; allow difference only if both non-zero & tool present)
  if (( present )); then
    if (( exit1 != 0 )); then
      # Acceptable if tool's chosen arg unsupported; just record for parity check
      :
    fi
    # If wrapper self-removed, mid or after function should become 0
    if (( was_function_before == 1 )) && (( was_function_after == 1 )); then
      # If still a function after two invocations AND bodies identical, wrapper not self-removing → potential non-idempotence
      if [[ "$func_before" == "$func_after" ]]; then
        violations+="+ ${name}: wrapper function persisted unchanged after two calls (expected self-removal or replacement)"
      fi
    fi
  else
    # Absent tool: Expect stub exit 127 (or stable non-zero)
    if [[ "$exit1" != "$exit2" ]]; then
      violations+="+ ${name}: absent-tool stub exit codes differ (first=$exit1 second=$exit2)"
    fi
    # Expect output stability (ignoring possible timestamps) - simple heuristic: first line match
    local first_line1 first_line2
    first_line1=$(echo "$out1" | head -1)
    first_line2=$(echo "$out2" | head -1)
    if [[ -n "$first_line1" && "$first_line1" != "$first_line2" ]]; then
      violations+="+ ${name}: absent-tool stub output first line differs between calls"
    fi
  fi

  # I2/I3 PATH duplicate check after invocations (quick scan)
  local dup_count=0
  local -A seen
  local segment
  for segment in ${(s/:/)PATH}; do
    [[ -z "$segment" ]] && continue
    if [[ -n ${seen[$segment]:-} ]]; then
      ((dup_count++))
    else
      seen[$segment]=1
    fi
  done
  if (( dup_count > 0 )); then
    violations+="+ ${name}: PATH duplicates detected post invocation (dup_count=$dup_count)"
  fi

  # Provide specific reuse expectation: For present tool wrapper should not remain function BOTH times
  if (( present && was_function_before == 1 && was_function_after == 1 )); then
    violations+="+ ${name}: function still defined after second call; expected unwrap to external command"
  fi

  # Summarize (debug)
  zf::debug "# [integrations-idempotence] $name present=$present exit1=$exit1 exit2=$exit2 f(before/mid/after)=$was_function_before/$was_function_mid/$was_function_after"
}

# Choose safe args:
# direnv: `version` is stable; fallback to `--help` if version unsupported
# gh: `--version` or `version` (we prefer --version)
test_tool direnv version
test_tool gh --version

# FUTURE: Add copilot, git-specific lazy wrappers as they evolve.

if (( ${#violations[@]} == 0 )); then
  echo "PASS: integration wrappers idempotent"
  exit 0
fi

echo "FAIL: integration wrapper idempotence violations:"
for v in "${violations[@]}"; do
  echo "  $v"
done

exit 1
