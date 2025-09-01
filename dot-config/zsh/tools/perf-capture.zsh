#!/usr/bin/env zsh
# perf-capture.zsh
# Phase 06 Tool: Capture cold & warm startup metrics (wall-clock ms) and store JSON entries.
# NOTE: Preliminary placeholder; refine after completion 020-consolidation.
set -euo pipefail

zmodload zsh/datetime || true
STAMP=$(date +%Y%m%dT%H%M%S)
OUT_DIR=${ZDOTDIR:-$HOME/.config/zsh}/logs/perf
mkdir -p "$OUT_DIR"

measure_startup() {
  local start=$EPOCHREALTIME
  zsh -ic 'exit' >/dev/null 2>&1 || true
  local end=$EPOCHREALTIME
  # Convert (floating seconds) to ms (integer)
  local delta_sec=$(awk -v s=$start -v e=$end 'BEGIN{printf "%.6f", e-s}')
  awk -v d=$delta_sec 'BEGIN{printf "%d", d*1000}'
}

echo "[perf-capture] cold run..." >&2
COLD_MS=$(measure_startup)
echo "[perf-capture] warm run..." >&2
WARM_MS=$(measure_startup)

cat > "$OUT_DIR/$STAMP.json" <<EOF
{"timestamp":"$STAMP","cold_ms":$COLD_MS,"warm_ms":$WARM_MS}
EOF

echo "[perf-capture] wrote $OUT_DIR/$STAMP.json (cold_ms=$COLD_MS warm_ms=$WARM_MS)"
