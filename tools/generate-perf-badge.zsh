#!/usr/bin/env zsh
# generate-perf-badge.zsh
# Creates/updates docs/badges/perf.json (shields.io compatible) using baseline & current metrics.
# Strategy:
# 1. Prefer explicit current metrics file arg, else docs/redesign/metrics/perf-current.json
# 2. If missing, optionally run quick harness (3 runs) if bin/test-performance.zsh exists.
# 3. Compare mean vs baseline (docs/redesign/metrics/perf-baseline.json) produce delta & color.
# 4. Output Shield JSON: {schemaVersion, label, message, color}
# Exit 0 even on partial failure (so docs generation doesn’t break pipelines) unless --strict.

set -euo pipefail
QUIET=0
STRICT=0
CUR_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet) QUIET=1 ; shift ;;
        --strict) STRICT=1 ; shift ;;
        --current) CUR_FILE=$2 ; shift 2 ;;
        *) echo "[perf-badge] Unknown arg: $1" >&2 ; shift ;;
    esac
done

ROOT_DIR=${0:A:h:h}
BADGE_DIR=$ROOT_DIR/docs/badges
METRICS_DIR=$ROOT_DIR/docs/redesign/metrics
mkdir -p "$BADGE_DIR" "$METRICS_DIR"
BASELINE=$METRICS_DIR/perf-baseline.json
CURRENT=${CUR_FILE:-$METRICS_DIR/perf-current.json}
BADGE=$BADGE_DIR/perf.json

log() { [[ $QUIET -eq 1 ]] || echo "$*" >&2; }
warn() { echo "[perf-badge] WARN: $*" >&2; }
fail() { echo "[perf-badge] ERROR: $*" >&2; [[ $STRICT -eq 1 ]] && exit 1; }

extract_mean() {
    local file=$1
    if command -v jq >/dev/null 2>&1; then
        jq -r '.startup_mean_ms // empty' "$file" 2>/dev/null || true
    else
        # naive grep fallback
        grep -E 'startup_mean_ms' "$file" 2>/dev/null | tr -dc '0-9.'
    fi
}

# Generate current if missing and harness available
if [[ ! -f $CURRENT && -x $ROOT_DIR/bin/test-performance.zsh ]]; then
    log "No current metrics file; running quick harness (3 runs)"
    if ! $ROOT_DIR/bin/test-performance.zsh --runs 3 --json-out "$CURRENT"; then
        warn "Quick harness failed; cannot produce current metrics"
    fi
fi

base_mean=""; cur_mean=""
[[ -f $BASELINE ]] && base_mean=$(extract_mean "$BASELINE") || warn "Baseline file missing"
[[ -f $CURRENT ]] && cur_mean=$(extract_mean "$CURRENT") || warn "Current metrics file missing"

color="lightgrey"
message="n/a"
if [[ -n $cur_mean ]]; then
    if [[ -n $base_mean ]]; then
        delta=$(awk -v b="$base_mean" -v c="$cur_mean" 'BEGIN{ if (b==0){print 0}else{printf "%.2f", (c-b)/b*100}}')
        # Determine color thresholds
        # Improvement (negative delta): brightgreen if <= -20%, green <= -10%, yellow <= 0, orange <= +5, red > +5
        perc_label="${delta}%"
        if awk -v d="$delta" 'BEGIN{exit (d<=-20?0:1)}'; then color="brightgreen"; fi
        if awk -v d="$delta" 'BEGIN{exit (d>-20 && d<=-10?0:1)}'; then color="green"; fi
        if awk -v d="$delta" 'BEGIN{exit (d>-10 && d<=0?0:1)}'; then color="yellow"; fi
        if awk -v d="$delta" 'BEGIN{exit (d>0 && d<=5?0:1)}'; then color="orange"; fi
        if awk -v d="$delta" 'BEGIN{exit (d>5?0:1)}'; then color="red"; fi
        message="${cur_mean}ms (${perc_label})"
    else
        message="${cur_mean}ms"
        color="blue"
    fi
fi

cat > "$BADGE" <<EOF
{"schemaVersion":1,"label":"startup","message":"$message","color":"$color"}
EOF
log "Wrote badge: $BADGE"
exit 0
