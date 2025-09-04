#!/usr/bin/env zsh
# test-fzf-no-compinit.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Validate that the pre‑plugin FZF initialization module (05-fzf-init.zsh) does NOT
#   execute compinit or produce any compdump artifacts, preserving single compinit
#   responsibility for later Stage 5 (completion subsystem).
#
# INVARIANTS:
#   F1: No ~/.zcompdump* (or $ZDOTDIR/.zcompdump*) file created by sourcing the module alone.
#   F2: Sentinel variable _COMPINIT_DONE is NOT set after sourcing the module.
#   F3: Environment variable FZF_NO_COMPINIT_GUARD is exported (=1) by the module.
#   F4: Debug output includes the marker "05-fzf-init loaded (no-compinit)".
#   F5: No call trace output referencing compinit execution (best-effort grep).
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (if TDD_SKIP_FZF_NO_COMPINIT=1 exported locally – do not commit with skip)
#
# USAGE:
#   Executed via test runner. Can run standalone:
#     ZSH_DEBUG=1 ./tests/unit/tdd/test-fzf-no-compinit.zsh
#
set -euo pipefail

if [[ "${TDD_SKIP_FZF_NO_COMPINIT:-0}" == "1" ]]; then
  echo "SKIP: FZF no-compinit test skipped (TDD_SKIP_FZF_NO_COMPINIT=1)"
  exit 2
fi

# Resolve repo root (assumes file path depth) using resilient helper (avoids brittle ${0:A:h})
if typeset -f zf::script_dir >/dev/null 2>&1; then
  REPO_ROOT="$(cd "$(zf::script_dir "${(%):-%N}")/../../../.." && pwd -P)"
else
  REPO_ROOT="$(cd "${(%):-%N:h}/../../../.." && pwd -P)"
fi

# Use a temporary HOME to isolate any accidental .zcompdump creation in the real home dir
TMP_HOME="$(mktemp -dt fzf_no_compinit_test.XXXXXX)"
trap 'rm -rf "$TMP_HOME"' EXIT

# Prepare clean environment snapshot
mkdir -p "${TMP_HOME}"
# Provide minimal .zshenv override if necessary? We rely on project .zshenv but want logs separate
LOG_CAPTURE="$(mktemp -t fzf_no_compinit_log.XXXXXX)"

# Run subshell to source only .zshenv and the target FZF module
subshell_out="$(
  HOME="${TMP_HOME}" \
  ZDOTDIR="${REPO_ROOT}" \
  ZSH_DEBUG=1 \
  ZSH_DEBUG_LOG="${LOG_CAPTURE}" \
  zsh -c '
    set -euo pipefail
    # Source project .zshenv (defines zsh_debug_echo & base vars)
    [[ -f ./.zshenv ]] && source ./.zshenv
    # Source ONLY the FZF pre-plugin module (not the entire pre-plugin chain)
    target="./.zshrc.pre-plugins.d.REDESIGN/05-fzf-init.zsh"
    if [[ ! -f "$target" ]]; then
      echo "__ERROR:module_missing"
      exit 97
    fi
    source "$target"
    # Print key env / state markers for parent parsing
    echo "__MARK:FZF_NO_COMPINIT_GUARD=${FZF_NO_COMPINIT_GUARD:-<unset>}"
    echo "__MARK:_COMPINIT_DONE=${_COMPINIT_DONE:-<unset>}"
    # List any compdump files under HOME or ZDOTDIR root
    find "${HOME}" -maxdepth 2 -name \".zcompdump*\" -print 2>/dev/null | sed "s|^|__COMPFILE:|"
    find "." -maxdepth 2 -name \".zcompdump*\" -print 2>/dev/null | sed "s|^|__COMPFILE:|"
    # Emit a final marker
    echo "__DONE"
  ' 2>&1
)"

violations=()

if [[ "$subshell_out" == *"__ERROR:module_missing"* ]]; then
  echo "FAIL: FZF module not found"
  exit 1
fi

# Extract markers
fzf_guard=$(echo "$subshell_out" | grep -E "^__MARK:FZF_NO_COMPINIT_GUARD=" | sed 's/^__MARK:FZF_NO_COMPINIT_GUARD=//')
compinit_done=$(echo "$subshell_out" | grep -E "^__MARK:_COMPINIT_DONE=" | sed 's/^__MARK:_COMPINIT_DONE=//')

# Collect compdump files
mapfile -t comp_files < <(echo "$subshell_out" | grep "^__COMPFILE:" | sed 's/^__COMPFILE://')

# Load debug log content
debug_log=""
if [[ -f "$LOG_CAPTURE" ]]; then
  debug_log="$(cat "$LOG_CAPTURE" 2>/dev/null || true)"
fi

# F1: No compdump files produced
if (( ${#comp_files[@]} > 0 )); then
  violations+="+ F1 unexpected compdump artifacts: ${comp_files[*]}"
fi

# F2: _COMPINIT_DONE must not be set
if [[ "$compinit_done" != "<unset>" ]]; then
  violations+="+ F2 _COMPINIT_DONE should be unset (got '$compinit_done')"
fi

# F3: FZF_NO_COMPINIT_GUARD exported & == 1
if [[ "$fzf_guard" != "1" ]]; then
  violations+="+ F3 FZF_NO_COMPINIT_GUARD expected '1' got '$fzf_guard'"
fi

# F4: Debug marker expected in either subshell output or debug log
if ! echo "$subshell_out" "$debug_log" | grep -q "05-fzf-init loaded (no-compinit)"; then
  violations+="+ F4 missing debug marker '05-fzf-init loaded (no-compinit)'"
fi

# F5: No evidence compinit actually ran: look for patterns of compdump lines or 'compinit' executed
if echo "$subshell_out" "$debug_log" | grep -E -q 'compdump|compinit invoked|compinit:'); then
  violations+="+ F5 detected compinit-related output unexpectedly"
fi

# Report
if (( ${#violations[@]} == 0 )); then
  echo "PASS: FZF pre-plugin module did not run compinit (invariants F1–F5 satisfied)"
  exit 0
fi

echo "FAIL: FZF no-compinit invariants violated:"
for v in "${violations[@]}"; do
  echo "  $v"
done

echo ""
echo "---- Diagnostics (first 40 lines of subshell output) ----"
echo "$subshell_out" | head -40 | sed 's/^/  /'
echo "--------------------------------------------------------"

exit 1
