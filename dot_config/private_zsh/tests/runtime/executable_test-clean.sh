#!/usr/bin/env bash
# Simple test for tools/clean-zsh-refactor.sh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT_DIR/tools/clean-zsh-refactor.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/logs" "$TMP/artifacts/metrics" "$TMP/.zsh-evalcache"
# Create baseline files with different mtimes
for i in 1 2 3 4 5; do
  f="$TMP/logs/baseline_$i.txt"
  echo "$i" > "$f"
  # Stagger mtime
  sleep 0.1
  touch "$f"
done
# artifacts
printf '{}' > "$TMP/artifacts/a.json"
printf '{}' > "$TMP/artifacts/metrics/m.json"

# Dry run retain 2 should plan deletions of 3 baseline files
out_dry=$(WORK_ROOT_OVERRIDE="$TMP" bash "$SCRIPT" --scope logs --retain 2)
printf '%s\n' "$out_dry" | grep -q 'baseline_1' || { echo "[FAIL] expected baseline_1 in dry-run output"; exit 1; }

# Apply retain 4 (delete oldest 1)
WORK_ROOT_OVERRIDE="$TMP" bash "$SCRIPT" --scope logs --retain 4 --apply >/dev/null
remaining=$(ls -1 "$TMP/logs"/baseline_* | wc -l | tr -d ' ')
[[ "$remaining" -eq 4 ]] || { echo "[FAIL] expected 4 baseline files remain, got $remaining"; exit 1; }

echo "[OK] test-clean passed"
