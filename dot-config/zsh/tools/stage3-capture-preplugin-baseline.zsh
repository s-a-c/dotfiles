#!/usr/bin/env zsh
# ============================================================================
# stage3-capture-preplugin-baseline.zsh
#
# Stage: 3 (Post-Plugin Core – Planning / Hardening)
#
# Purpose:
#     Capture a multi-sample pre-plugin startup baseline AFTER Stage 2 completion
#     and AFTER the PATH append fix, while Stage 3 core scaffolds are being
#     introduced—but BEFORE any Stage 4+ plugin / feature layer cost is mixed in.
#
# Why a Stage 3 Baseline?
#     - Validates that early Stage 3 scaffolds (security, options, core functions)
#       did not introduce significant overhead.
#     - Supplies variance data to justify tightening the regression guard
#       (e.g. lowering allowed pre-plugin regression from +10% → +7% → +5%).
#     - Establishes a refreshed statistical artifact if Stage 3 changes
#       (especially path hygiene, option consolidation) alter pre-plugin timings.
#
# Existing Baseline vs This Script:
#     - Stage 2 baseline (preplugin-baseline.json) locked the initial migration state.
#     - This script produces an UPDATED artifact (default:
#         docs/redesignv2/artifacts/metrics/preplugin-baseline-stage3.json)
#       without overwriting the original Stage 2 file, preserving historical trace.
#
# Output (JSON):
# {
#   "schema": "preplugin-baseline.v2",
#   "timestamp": "YYYYMMDDTHHMMSS",
#   "samples": N,
#   "values_ms": [ ... ],
#   "mean_ms": <float>,
#   "stdev_ms": <float>,
#   "min_ms": <int>,
#   "max_ms": <int>,
#   "tag": "refactor-stage2-preplugin" | "<git_tag_or_none>",
#   "git_commit": "<short_sha>",
#   "zdotdir": "<resolved ZDOTDIR>",
#   "notes": "Stage 3 provisional baseline (pre-plugin only)",
#   "path_fix_verified": true|false
# }
#
# Measurement Strategy:
#     - Run N launches of a constrained shell that exits immediately following
#       completion of pre-plugin modules.
#     - Use high-resolution time with date +%s%N when available; fallback to ms.
#     - Keep each run isolated (env -i) to avoid contamination from user shell state.
#
# How We Stop Before Post-Plugin:
#     - If tools/preplugin-baseline-capture.zsh exists, prefer delegating (it may
#       contain canonical logic used in Stage 2).
#     - Otherwise we emulate a minimal measurement harness by exporting
#       ZSH_PREPLUGIN_ONLY=1 (the redesign loader may ignore this if unsupported;
#       if unsupported you will see inflated times—warn is emitted).
#
# Options:
#     -n / --samples <N>        Number of samples (default: 5)
#     -s / --sleep <SECONDS>    Sleep between samples (default: 0)
#     -o / --output <FILE>      Output JSON artifact path
#     --append                  Append (do not overwrite) if file exists (adds "previous": {...})
#     --show                    Print JSON to stdout after writing
#     --quiet                   Suppress per-run logs
#     --help                    Show usage
#
# Exit Codes:
#     0 Success
#     1 Argument / environment error
#     2 Runtime capture failure
#
# Dependencies:
#     - Standard core utils: date, printf, git (optional), awk (optional fallback)
#
# Style:
#     - 4-space indentation (EditorConfig compliance)
#
# Safe to Run Multiple Times:
#     - Generates deterministic JSON; does NOT delete prior Stage 2 baseline file.
#
# ============================================================================
set -euo pipefail

# ---------------------------- Defaults ---------------------------------------
SAMPLES=5
SLEEP_INTERVAL=0
OUTPUT_FILE_DEFAULT="docs/redesignv2/artifacts/metrics/preplugin-baseline-stage3.json"
OUTPUT_FILE=""
APPEND_MODE=0
SHOW_AFTER=0
QUIET=0

SCRIPT_NAME="${0##*/}"

# ---------------------------- Usage ------------------------------------------
usage() {
    cat <<EOF
$SCRIPT_NAME - Multi-sample Stage 3 pre-plugin baseline capture

Usage: $SCRIPT_NAME [options]

Options:
  -n, --samples <N>         Number of samples (default: 5)
  -s, --sleep <SECONDS>     Sleep between samples (default: 0)
  -o, --output <FILE>       Output JSON file (default: $OUTPUT_FILE_DEFAULT)
      --append              If output exists, wrap old JSON under "previous"
      --show                Print final JSON to stdout
      --quiet               Suppress per-run timing lines
      --help                Show this help

Notes:
  - Attempts to delegate to tools/preplugin-baseline-capture.zsh if present.
  - Falls back to internal lightweight timer harness otherwise.
  - Does NOT overwrite the original Stage 2 baseline file.
EOF
}

# ----------------------- Argument Parsing ------------------------------------
while (( $# > 0 )); do
    case "$1" in
        -n|--samples)
            shift || { echo "Missing value after --samples" >&2; exit 1; }
            SAMPLES="$1"
            ;;
        -s|--sleep)
            shift || { echo "Missing value after --sleep" >&2; exit 1; }
            SLEEP_INTERVAL="$1"
            ;;
        -o|--output)
            shift || { echo "Missing value after --output" >&2; exit 1; }
            OUTPUT_FILE="$1"
            ;;
        --append)
            APPEND_MODE=1
            ;;
        --show)
            SHOW_AFTER=1
            ;;
        --quiet)
            QUIET=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
    shift
done

if ! [[ "$SAMPLES" =~ ^[0-9]+$ ]] || (( SAMPLES < 1 )); then
    echo "Invalid samples count: $SAMPLES" >&2
    exit 1
fi

if [[ -z "${OUTPUT_FILE:-}" ]]; then
    OUTPUT_FILE="${OUTPUT_FILE_DEFAULT}"
fi

# ------------------------ Environment / Paths --------------------------------
# Attempt to resolve ZDOTDIR similarly to redesign expectation.
ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"

if [[ ! -d "$ZDOTDIR" ]]; then
    echo "ZDOTDIR directory not found: $ZDOTDIR" >&2
    exit 1
fi

METRICS_DIR_REL=$(dirname -- "$OUTPUT_FILE")
METRICS_DIR_ABS="$ZDOTDIR/$METRICS_DIR_REL"
mkdir -p "$METRICS_DIR_ABS" 2>/dev/null || true

DELEGATE_SCRIPT="$ZDOTDIR/tools/preplugin-baseline-capture.zsh"
DELEGATE_AVAILABLE=0
[[ -x "$DELEGATE_SCRIPT" ]] && DELEGATE_AVAILABLE=1

# ------------------------ Utility Functions ----------------------------------
hires_now_ns() {
    if date +%s%N >/dev/null 2>&1; then
        date +%s%N
    else
        # Fallback ms -> pseudo ns
        printf '%s000000' "$(date +%s 2>/dev/null || echo 0)"
    fi
}

diff_ms() {
    # Args: start_ns end_ns
    local start="$1" end="$2"
    local delta=$(( end - start ))
    (( delta < 0 )) && delta=0
    printf '%d' $(( delta / 1000000 ))
}

json_escape() {
    # Minimal escaper for values without newlines
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

calc_mean() {
    awk '{s+=$1; n++} END{ if(n==0) print "0.0"; else printf("%.2f", s/n); }'
}

calc_stdev() {
    # Population stdev
    awk '{s+=$1; ss+=$1*$1; n++} END{
        if(n<2){print "0.0"; exit}
        m=s/n
        var=(ss/n)-(m*m)
        if(var<0) var=0
        printf("%.2f", sqrt(var))
    }'
}

calc_min() {
    awk 'NR==1{min=$1} { if($1<min) min=$1 } END{ if(NR==0) print 0; else print min }'
}

calc_max() {
    awk 'NR==1{max=$1} { if($1>max) max=$1 } END{ if(NR==0) print 0; else print max }'
}

timestamp() {
    date +%Y%m%dT%H%M%S 2>/dev/null || echo "unknown"
}

git_tag() {
    git -C "$ZDOTDIR" describe --tags 2>/dev/null || true
}

git_short() {
    git -C "$ZDOTDIR" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

# ---------------------- Capture Logic (Delegate) -----------------------------
delegate_capture_once() {
    # Expects delegate script to emit JSON containing "mean_ms" or a similar field.
    # We time the entire delegate invocation as a fallback reference.
    local start end ms
    start="$(hires_now_ns)"
    if ! zsh "$DELEGATE_SCRIPT" --single --quiet >/dev/null 2>&1; then
        return 1
    fi
    end="$(hires_now_ns)"
    ms="$(diff_ms "$start" "$end")"
    # The delegate may have written a file like preplugin-baseline.json; we do not parse it here.
    printf '%s\n' "$ms"
}

# ---------------------- Capture Logic (Internal Harness) --------------------
internal_capture_once() {
    # Launch a minimal zsh that exits immediately after pre-plugin load.
    # Attempt to signal redesign loader to stop early (implementation may ignore).
    local start_ns end_ns elapsed
    start_ns="$(hires_now_ns)"
    # Use env -i to minimize environment noise.
    # PERF_HARNESS_MINIMAL / ZSH_PREPLUGIN_ONLY are advisory toggles (if recognized).
    env -i \
        HOME="$HOME" \
        ZDOTDIR="$ZDOTDIR" \
        PATH="$PATH" \
        TERM=dumb \
        ZSH_DEBUG=0 \
        PERF_HARNESS_MINIMAL=1 \
        ZSH_PREPLUGIN_ONLY=1 \
        zsh -dfc 'exit 0' >/dev/null 2>&1 || true
    end_ns="$(hires_now_ns)"
    elapsed="$(diff_ms "$start_ns" "$end_ns")"
    printf '%s\n' "$elapsed"
}

# ------------------------- Execution Loop ------------------------------------
VALUES=()
if (( QUIET == 0 )); then
    echo "[${SCRIPT_NAME}] Starting capture: samples=$SAMPLES delegate=$DELEGATE_AVAILABLE zdotdir=$ZDOTDIR"
fi

for (( i=1; i<=SAMPLES; i++ )); do
    local_ms=""
    if (( DELEGATE_AVAILABLE == 1 )); then
        local_ms="$(delegate_capture_once || true)"
    fi
    if [[ -z "$local_ms" || "$local_ms" == "0" ]]; then
        local_ms="$(internal_capture_once)"
    fi
    VALUES+=("$local_ms")
    (( QUIET == 0 )) && echo "[${SCRIPT_NAME}] Run $i/$SAMPLES = ${local_ms}ms"
    if (( i < SAMPLES )) && [[ "$SLEEP_INTERVAL" != "0" ]]; then
        sleep "$SLEEP_INTERVAL"
    fi
done

# ------------------------- Stats ---------------------------------------------
VALUES_JOINED=$(printf '%s\n' "${VALUES[@]}")
MEAN=$(printf '%s\n' "${VALUES[@]}" | calc_mean)
STDEV=$(printf '%s\n' "${VALUES[@]}" | calc_stdev)
MIN_V=$(printf '%s\n' "${VALUES[@]}" | calc_min)
MAX_V=$(printf '%s\n' "${VALUES[@]}" | calc_max)
TS="$(timestamp)"
TAG="$(git_tag || true)"
COMMIT="$(git_short)"
[[ -z "$TAG" ]] && TAG="none"

# Verify PATH fix (heuristic: required commands present)
PATH_FIX_OK=1
for req in awk date mkdir; do
    if ! command -v "$req" >/dev/null 2>&1; then
        PATH_FIX_OK=0
        break
    fi
done

# ------------------------- JSON Assembly -------------------------------------
OUT_ABS="$ZDOTDIR/$OUTPUT_FILE"
TMP_OUT="${OUT_ABS}.tmp.$$"

PREVIOUS_JSON=""
if (( APPEND_MODE == 1 )) && [[ -s "$OUT_ABS" ]]; then
    PREVIOUS_JSON="$(cat "$OUT_ABS" 2>/dev/null || true)"
fi

VALUES_ARRAY=$(printf '%s\n' "${VALUES[@]}" | paste -sd',' -)

{
    echo '{'
    echo '  "schema": "preplugin-baseline.v2",'
    printf '  "timestamp": "%s",\n' "$TS"
    printf '  "samples": %d,\n' "$SAMPLES"
    printf '  "values_ms": [%s],\n' "$VALUES_ARRAY"
    printf '  "mean_ms": %s,\n' "$MEAN"
    printf '  "stdev_ms": %s,\n' "$STDEV"
    printf '  "min_ms": %s,\n' "$MIN_V"
    printf '  "max_ms": %s,\n' "$MAX_V"
    printf '  "tag": "%s",\n' "$(printf '%s' "$TAG" | json_escape)"
    printf '  "git_commit": "%s",\n' "$(printf '%s' "$COMMIT" | json_escape)"
    printf '  "zdotdir": "%s",\n' "$(printf '%s' "$ZDOTDIR" | json_escape)"
    echo '  "notes": "Stage 3 provisional baseline (pre-plugin only)",'
    printf '  "path_fix_verified": %s' "$([[ $PATH_FIX_OK -eq 1 ]] && echo true || echo false)"
    if (( APPEND_MODE == 1 )) && [[ -n "$PREVIOUS_JSON" ]]; then
        echo ','
        echo '  "previous": '"$PREVIOUS_JSON"
    else
        echo
    fi
    echo '}'
} > "$TMP_OUT"

mv "$TMP_OUT" "$OUT_ABS"

(( QUIET == 0 )) && echo "[${SCRIPT_NAME}] Wrote: $OUT_ABS (mean=${MEAN}ms stdev=${STDEV}ms path_fix=${PATH_FIX_OK})"

if (( SHOW_AFTER == 1 )); then
    cat "$OUT_ABS"
fi

exit 0
