#!/usr/bin/env zsh
# test-preplugin-integrity-hash.zsh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Security test validating integrity hashing manifest for pre‑plugin files.
#   Ensures integrity-current.json exists, is well-formed, lists all targeted
#   pre-plugin files with 64-hex SHA256 hashes, and that the aggregate hash
#   reported matches a recomputation of the ordered "<path>\t<sha256>" list.
#
# SCOPE:
#   - Read-only verification. Does NOT mutate baseline or current manifests.
#   - Baseline divergence is PERMISSIVE (does not fail) per Stage 3 permissive policy.
#
# EXIT CODES:
#   0 PASS
#   1 FAIL
#   2 SKIP (artifact or tooling not yet available)
#
# DEPENDENCIES:
#   - shasum -a 256 OR openssl dgst -sha256
#   - integrity-current.json produced by tools/integrity-hash-preplugin.zsh
#
# DESIGN:
#   - Pure zsh + POSIX tools (no jq).
#   - Minimal parsing using grep/sed/awk; tolerant of ordering.
#
# FUTURE (Optional Extensions):
#   - Enforce baseline stability once Stage 3 hardening finalized.
#   - Detect missing / unexpected files vs baseline (whitelist diff).
#
set -euo pipefail

# Quiet debug helper
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }

# Determine ZDOTDIR / repo root (assumes test resides under .../dot-config/zsh/tests/security/)
# Use absolute paths and avoid fragile parameter expansion fallbacks
if [[ -n "${ZSH_VERSION:-}" ]]; then
    TEST_FILE="${(%):-%N}"
    TEST_DIR="${TEST_FILE:A:h}"
elif typeset -f zf::script_dir >/dev/null 2>&1; then
    TEST_DIR="$(zf::script_dir "$0")"
else
    # Fallback for non-zsh shells
    TEST_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
fi
# Two directories up from tests/security -> zsh root
ZSH_ROOT="${TEST_DIR:h:h}"

# Metrics directory resolution (prefer redesignv2)
if [[ -d "${ZSH_ROOT}/docs/redesignv2/artifacts/metrics" ]]; then
  METRICS_DIR="${ZSH_ROOT}/docs/redesignv2/artifacts/metrics"
elif [[ -d "${ZSH_ROOT}/docs/redesign/metrics" ]]; then
  METRICS_DIR="${ZSH_ROOT}/docs/redesign/metrics"
else
  echo "SKIP: metrics directory not found (run integrity-hash-preplugin.zsh)"
  exit 2
fi

CURR="${METRICS_DIR}/integrity-current.json"
BASE="${METRICS_DIR}/integrity-baseline.json"

if [[ ! -f "$CURR" ]]; then
  echo "SKIP: integrity-current.json missing (run integrity-hash-preplugin.zsh first)"
  exit 2
fi

# Hash utility detection
hash_cmd=""
if command -v shasum >/dev/null 2>&1; then
  hash_cmd="shasum -a 256"
elif command -v gshasum >/dev/null 2>&1; then
  hash_cmd="gshasum -a 256"
elif command -v openssl >/dev/null 2>&1; then
  hash_cmd="openssl dgst -sha256"
else
  echo "SKIP: no sha256 hashing tool (shasum/openssl) available"
  exit 2
fi

failures=()

# Basic file non-empty
if [[ ! -s "$CURR" ]]; then
  failures+=("integrity-current.json is empty")
fi

# Extract schema
schema=$(grep -E '"schema"' "$CURR" 2>/dev/null | head -1 | sed 's/.*"schema"[[:space:]]*:[[:space:]]*"//; s/".*//')
if [[ "$schema" != "preplugin-integrity.v1" ]]; then
  failures+=("Unexpected schema ('$schema') expected 'preplugin-integrity.v1'")
fi

# Extract aggregate reported
reported_aggregate=$(grep -E '"aggregate_sha256"' "$CURR" 2>/dev/null | head -1 | sed 's/.*"aggregate_sha256"[[:space:]]*:[[:space:]]*"//; s/".*//')
if [[ -z "$reported_aggregate" ]]; then
  failures+=("aggregate_sha256 field missing")
elif ! [[ "$reported_aggregate" =~ ^[0-9a-f]{64}$ ]]; then
  failures+=("aggregate_sha256 not 64 hex (${reported_aggregate})")
fi

# Parse file objects (paths & hashes) preserving order
# Strategy: extract with grep -o across full file (handles minified JSON)
paths=()
hashes=()
while IFS= read -r p; do
  [[ -n "$p" ]] && paths+=("$p")
done < <(grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$CURR" | sed 's/.*"path"[[:space:]]*:[[:space:]]*"//; s/"$//')
while IFS= read -r h; do
  [[ -n "$h" ]] && hashes+=("$h")
done < <(grep -o '"sha256"[[:space:]]*:[[:space:]]*"[^"]*"' "$CURR" | sed 's/.*"sha256"[[:space:]]*:[[:space:]]*"//; s/"$//')

if (( ${#paths[@]} == 0 )); then
  failures+=("No file entries parsed from integrity-current.json")
fi

if (( ${#paths[@]} != ${#hashes[@]} )); then
  failures+=("Path/hash count mismatch (${#paths[@]} paths vs ${#hashes[@]} hashes)")
fi

# Validate each entry
for (( i=1; i<=${#paths[@]}; i++ )); do
  p="${paths[i]}"
  h="${hashes[i]}"
  # Path must exist
  if [[ ! -f "${ZSH_ROOT}/${p}" ]]; then
    failures+=("Listed file missing on disk: ${p}")
  fi
  # Hash format
  if ! [[ "$h" =~ ^[0-9a-f]{64}$ ]]; then
    failures+=("Invalid sha256 for ${p}: ${h}")
  fi
  # Recompute individual hash (optional deep check)
  if [[ -f "${ZSH_ROOT}/${p}" ]]; then
    if [[ $hash_cmd == openssl* ]]; then
      recomputed=$(openssl dgst -sha256 "${ZSH_ROOT}/${p}" 2>/dev/null | awk -F'= ' '{print $2}')
    else
      recomputed=$(shasum -a 256 "${ZSH_ROOT}/${p}" 2>/dev/null | awk '{print $1}')
      [[ -z "$recomputed" ]] && recomputed=$(gshasum -a 256 "${ZSH_ROOT}/${p}" 2>/dev/null | awk '{print $1}')
    fi
    if [[ -n "$recomputed" && "$recomputed" != "$h" ]]; then
      failures+=("Hash mismatch for ${p} (manifest=$h recomputed=$recomputed)")
    fi
  fi
done

# Recompute aggregate hash (ordered)
aggregate_input=""
for (( i=1; i<=${#paths[@]}; i++ )); do
  aggregate_input+="${paths[i]}"$'\t'"${hashes[i]}"$'\n'
done

# Debug: write test aggregate_input bytes if ZSH_DEBUG is set
if [[ -n "${ZSH_DEBUG:-}" ]]; then
  log_dir="${ZSH_LOG_DIR:-${METRICS_DIR}/logs}"
  mkdir -p "$log_dir"
  test_agg_log="${log_dir}/test-preplugin-aggregate-input"
  printf '%s' "$aggregate_input" > "$test_agg_log"
  zsh_debug_echo "# [integrity-test] Wrote aggregate_input (${#aggregate_input} bytes) to $test_agg_log"
fi

# Recompute aggregate hash (ordered) using no trailing newline to match generator
n=${#paths[@]}
recomputed_aggregate=""
if (( n > 0 )); then
  if [[ $hash_cmd == openssl* ]]; then
    recomputed_aggregate=$(printf '%s' "${aggregate_input%$'\n'}" | openssl dgst -sha256 2>/dev/null | awk -F'= ' '{print $2}')
  else
    recomputed_aggregate=$(printf '%s' "${aggregate_input%$'\n'}" | shasum -a 256 2>/dev/null | awk '{print $1}')
    [[ -z "$recomputed_aggregate" ]] && recomputed_aggregate=$(printf '%s' "${aggregate_input%$'\n'}" | gshasum -a 256 2>/dev/null | awk '{print $1}')
  fi
fi

if [[ -z "$recomputed_aggregate" ]]; then
  failures+=("Failed to recompute aggregate hash")
elif [[ "$reported_aggregate" != "$recomputed_aggregate" ]]; then
  failures+=("Aggregate mismatch (reported=$reported_aggregate recomputed=$recomputed_aggregate)")
fi

# (Permissive) Baseline presence check (do not fail if absent / divergent)
if [[ -f "$BASE" ]]; then
  base_agg=$(grep -E '"aggregate_sha256"' "$BASE" 2>/dev/null | head -1 | sed 's/.*"aggregate_sha256"[[:space:]]*:[[:space:]]*"//; s/".*//')
  if [[ -n "$base_agg" && ! "$base_agg" =~ ^[0-9a-f]{64}$ ]]; then
    failures+=("Baseline aggregate hash malformed ($base_agg)")
  fi
  # Divergence is informational only
  if [[ -n "$base_agg" && "$base_agg" != "$reported_aggregate" ]]; then
    zsh_debug_echo "# [integrity-test] Baseline aggregate differs (baseline=$base_agg current=$reported_aggregate) – permissive mode"
  fi
else
  zsh_debug_echo "# [integrity-test] Baseline file absent – permissive mode"
fi

if (( ${#failures[@]} == 0 )); then
  echo "PASS: pre-plugin integrity manifest valid (files=${#paths[@]})"
  exit 0
fi

echo "FAIL: pre-plugin integrity issues:"
for f in "${failures[@]}"; do
  echo "  - $f"
done

# Provide truncated diagnostics head/tail
echo ""
echo "---- integrity-current.json (first 40 lines) ----"
head -40 "$CURR" | sed 's/^/  /'
echo "------------------------------------------------"
exit 1
