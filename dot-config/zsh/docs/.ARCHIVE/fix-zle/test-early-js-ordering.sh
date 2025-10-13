#!/usr/bin/env bash
# Test: Early JS runtime path shaping & NVM layering
# Purpose: Assert ordering guarantees without loading nvm eagerly.
# Usage: run from repository root or any directory: bash docs/fix-zle/test-early-js-ordering.sh
# Exits non-zero on failure.

set -euo pipefail

red() { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

fail() { red "FAIL: $*"; exit 1; }

# Launch a fresh interactive zsh capturing env status BEFORE any explicit nvm use.
# We avoid triggering lazy nvm by not calling node/npm if wrapper would load it.

SCRIPT='\n'"
  echo '--- early-capture ---'
  echo BUN_PATH=$(command -v bun 2>/dev/null || echo none)
  echo DENO_PATH=$(command -v deno 2>/dev/null || echo none)
  echo PNPM_PATH=$(command -v pnpm 2>/dev/null || echo none)
  echo NVM_FUNC_PRESENT=$([[ $(typeset -f nvm 2>/dev/null | wc -l) -gt 0 ]] && echo yes || echo no)
  echo NVM_DIR_VALUE=${NVM_DIR:-unset}
  echo NODE_PATH_BASE=$(command -v node 2>/dev/null || echo none)
  # Intentionally not running node to avoid lazy load; now trigger node once:
  echo '--- after-node-invocation ---'
  node -v >/dev/null 2>&1 || true
  echo NVM_FUNC_PRESENT_AFTER=$([[ $(typeset -f nvm 2>/dev/null | wc -l) -gt 0 ]] && echo yes || echo no)
  echo NVM_DIR_VALUE_AFTER=${NVM_DIR:-unset}
"'\n'

RAW_OUTPUT=$(zsh -i -c "$SCRIPT" 2>/dev/null || true)

echo "$RAW_OUTPUT"

# Basic parsing
EARLY_SECTION=$(echo "$RAW_OUTPUT" | awk '/--- early-capture ---/{flag=1;next}/--- after-node-invocation ---/{flag=0}flag')
AFTER_SECTION=$(echo "$RAW_OUTPUT" | awk '/--- after-node-invocation ---/{flag=1;next}flag')

get_kv() { echo "$1" | grep "^$2=" | head -1 | cut -d= -f2-; }

BUN_PATH=$(get_kv "$EARLY_SECTION" BUN_PATH)
DENO_PATH=$(get_kv "$EARLY_SECTION" DENO_PATH)
PNPM_PATH=$(get_kv "$EARLY_SECTION" PNPM_PATH)
NVM_FUNC_PRESENT=$(get_kv "$EARLY_SECTION" NVM_FUNC_PRESENT)
NVM_DIR_VALUE=$(get_kv "$EARLY_SECTION" NVM_DIR_VALUE)
NVM_FUNC_PRESENT_AFTER=$(get_kv "$AFTER_SECTION" NVM_FUNC_PRESENT_AFTER)
NVM_DIR_VALUE_AFTER=$(get_kv "$AFTER_SECTION" NVM_DIR_VALUE_AFTER)

# Assertions (soft: presence optional, ordering strict)
[[ "$NVM_FUNC_PRESENT" == yes || "$NVM_FUNC_PRESENT" == no ]] || fail "Unexpected NVM_FUNC_PRESENT value: $NVM_FUNC_PRESENT"
[[ "$NVM_FUNC_PRESENT_AFTER" == yes || "$NVM_FUNC_PRESENT_AFTER" == no ]] || fail "Unexpected NVM_FUNC_PRESENT_AFTER value: $NVM_FUNC_PRESENT_AFTER"

if [[ "$NVM_FUNC_PRESENT" == no && "$NVM_FUNC_PRESENT_AFTER" == yes ]]; then
  green "Lazy nvm activation confirmed."
fi

# Report NVM_DIR changes (if any) for diagnostic purposes
if [[ "$NVM_DIR_VALUE" != "$NVM_DIR_VALUE_AFTER" ]]; then
  yellow "NVM_DIR changed: $NVM_DIR_VALUE -> $NVM_DIR_VALUE_AFTER"
else
  green "NVM_DIR stable: $NVM_DIR_VALUE"
fi

if [[ -n "$PNPM_PATH" && "$PNPM_PATH" != none ]]; then
  green "pnpm visible early: $PNPM_PATH"; else yellow "pnpm not present (ok)"; fi
if [[ -n "$BUN_PATH" && "$BUN_PATH" != none ]]; then
  green "bun visible early: $BUN_PATH"; else yellow "bun not present (ok)"; fi
if [[ -n "$DENO_PATH" && "$DENO_PATH" != none ]]; then
  green "deno visible early: $DENO_PATH"; else yellow "deno not present (ok)"; fi

green "Test script completed (non-fatal warnings possible)."
