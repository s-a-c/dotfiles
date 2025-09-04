#!/usr/bin/env zsh
# ============================================================================
# preplugin-variance-eval.zsh
#
# Purpose:
#   Evaluate variance across multiple Stage 3 pre-plugin baseline JSON artifacts
#   (produced by stage3-capture-preplugin-baseline.zsh) and recommend a tighter
#   regression guard threshold (+10% → +7% → +5%) when statistical stability
#   justifies it.
#
# Inputs (files):
#   - Stage 3 baseline artifacts (schema: preplugin-baseline.v2) containing:
#       "values_ms": [ ... ], "mean_ms": <float>, "stdev_ms": <float>
#     (Supports fallback legacy key "samples_ms" if encountered.)
#   - Optional Stage 2 original baseline docs/redesignv2/artifacts/metrics/
#       preplugin-baseline.json (mean_ms or mean).
#
# Heuristic Guard Tightening:
#   Let RSD = aggregate_stdev / aggregate_mean.
#     RSD ≤ 0.050 and total_samples ≥ 20  -> recommend +5%
#     else RSD ≤ 0.080 and total_samples ≥ 15 -> recommend +7%
#     else -> retain +10%
#
# Output (default: JSON to stdout):
# {
#   "schema": "preplugin-variance-eval.v1",
#   "analyzed_files": 3,
#   "total_samples": 25,
#   "aggregate_mean_ms": 34.72,
#   "aggregate_stdev_ms": 1.41,
#   "aggregate_rsd": 0.041,
#   "stage2_baseline_mean_ms": 35,
#   "relative_to_stage2_pct": -0.80,
#   "recommended_guard_pct": 5,
#   "recommended_guard_absolute_ms": 36.75,
#   "rsd_band": "stable",
#   "notes": "RSD <=5% with >=20 samples; safe to tighten guard to +5%"
# }
#
# Exit Codes:
#   0  Success
#   1  Argument error
#   2  No matching files
#   3  Parse / computation error
#
# Options:
#   --dir <path>         Directory to scan (default: $ZDOTDIR/docs/redesignv2/artifacts/metrics)
#   --glob <pattern>     Glob for Stage 3 baseline files (default: preplugin-baseline-stage3*.json)
#   --min-files <N>      Require at least N files (default: 1)
#   --min-samples <N>    Require at least N total sample points (default: 5)
#   --text               Human readable summary instead of JSON
#   --json               Force JSON output (default)
#   --fail-on-empty      Exit non-zero (2) if no files (default behavior)
#   --allow-empty        Treat no files as success (outputs empty evaluation)
#   --help               Show usage
#
# Style:
#   4-space indentation; no external heavy deps (jq optional if present but unused).
#
# Notes:
#   - Robust to appended "previous" objects (--append mode) by only reading top-level arrays.
#   - Ignores malformed lines silently unless all parsing fails (then exit 3).
#   - Floating arithmetic via awk.
#
# Future Extensions:
#   - Percentile extraction (p90) once present in baseline schema.
#   - Historical trend persistence (rolling window).
#   - Direct CI badge generation hook.
# ============================================================================

set -euo pipefail

# ----------------------------- Defaults --------------------------------------
DIR_DEFAULT="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}/docs/redesignv2/artifacts/metrics"
SCAN_DIR="$DIR_DEFAULT"
GLOB_PATTERN="preplugin-baseline-stage3*.json"
MIN_FILES=1
MIN_SAMPLES=5
OUTPUT_MODE="json"       # json|text
FAIL_ON_EMPTY=1

STAGE2_FILE="preplugin-baseline.json"

SCRIPT_NAME="${0##*/}"

# ----------------------------- Usage -----------------------------------------
usage() {
    cat <<EOF
$SCRIPT_NAME - Evaluate variance across Stage 3 pre-plugin baseline artifacts

Usage:
  $SCRIPT_NAME [options]

Options:
  --dir <path>        Directory containing baseline artifacts
  --glob <pattern>    Glob for Stage 3 files (default: preplugin-baseline-stage3*.json)
  --min-files <N>     Minimum number of files required (default: 1)
  --min-samples <N>   Minimum aggregate sample count required (default: 5)
  --text              Human readable output
  --json              JSON output (default)
  --fail-on-empty     Exit non-zero if no files (default)
  --allow-empty       Do not error if no files (emit empty result)
  --help              Show this help

Heuristic guard tightening:
  RSD ≤ 5% and samples ≥ 20  => recommend +5%
  else RSD ≤ 8% and samples ≥ 15 => recommend +7%
  else retain +10%

Exit Codes:
  0 success
  1 argument error
  2 no files (unless --allow-empty)
  3 parse / compute error
EOF
}

# -------------------------- Arg Parsing --------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --dir)
            shift || { echo "Missing value after --dir" >&2; exit 1; }
            SCAN_DIR="$1"
            ;;
        --glob)
            shift || { echo "Missing value after --glob" >&2; exit 1; }
            GLOB_PATTERN="$1"
            ;;
        --min-files)
            shift || { echo "Missing value after --min-files" >&2; exit 1; }
            MIN_FILES="$1"
            ;;
        --min-samples)
            shift || { echo "Missing value after --min-samples" >&2; exit 1; }
            MIN_SAMPLES="$1"
            ;;
        --text)
            OUTPUT_MODE="text"
            ;;
        --json)
            OUTPUT_MODE="json"
            ;;
        --fail-on-empty)
            FAIL_ON_EMPTY=1
            ;;
        --allow-empty)
            FAIL_ON_EMPTY=0
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

if (( MIN_FILES < 1 )); then
    echo "Invalid --min-files (must be >=1)" >&2
    exit 1
fi
if (( MIN_SAMPLES < 1 )); then
    echo "Invalid --min-samples (must be >=1)" >&2
    exit 1
fi

if [[ ! -d "$SCAN_DIR" ]]; then
    if (( FAIL_ON_EMPTY )); then
        echo "Directory not found: $SCAN_DIR" >&2
        exit 2
    else
        SCAN_DIR="."
    fi
fi

# ----------------------- File Discovery --------------------------------------
# Use nullglob-like behavior safely
setopt nullglob 2>/dev/null || true
files=("$SCAN_DIR"/$GLOB_PATTERN(N))
unsetopt nullglob 2>/dev/null || true

file_count=${#files[@]}

if (( file_count == 0 )); then
    if (( FAIL_ON_EMPTY )); then
        (( OUTPUT_MODE == "json" )) && printf '{ "schema":"preplugin-variance-eval.v1","analyzed_files":0,"total_samples":0,"notes":"no matching files" }\n'
        (( OUTPUT_MODE == "text" )) && echo "[variance-eval] No matching files (pattern=$GLOB_PATTERN dir=$SCAN_DIR)"
        exit 2
    else
        (( OUTPUT_MODE == "json" )) && printf '{ "schema":"preplugin-variance-eval.v1","analyzed_files":0,"total_samples":0,"notes":"empty (allowed)" }\n'
        (( OUTPUT_MODE == "text" )) && echo "[variance-eval] Empty set allowed"
        exit 0
    fi
fi

if (( file_count < MIN_FILES )); then
    echo "Found $file_count file(s) < required minimum $MIN_FILES" >&2
    exit 2
fi

# ----------------------- Parsing Utilities -----------------------------------
json_escape() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Extract numbers from a JSON array line like:  "values_ms": [12, 34, 5],
extract_array_numbers() {
    # stdin: line containing array
    sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' | sed -E 's/[^0-9]//g' | awk 'NF && $0 ~ /^[0-9]+$/ {print}'
}

collect_values() {
    local f="$1"
    # Strategy:
    #   - Find "values_ms": [...] first
    #   - Fallback to "samples_ms": [...]
    local line values
    line="$(grep -E '"values_ms"[[:space:]]*:' "$f" 2>/dev/null | head -1 || true)"
    if [[ -z "$line" ]]; then
        line="$(grep -E '"samples_ms"[[:space:]]*:' "$f" 2>/dev/null | head -1 || true)"
    fi
    if [[ -z "$line" ]]; then
        return 1
    fi
    extract_array_numbers <<<"$line"
}

# ----------------------- Aggregate Collection --------------------------------
typeset -a ALL_VALUES
missing_any=0

for f in "${files[@]}"; do
    if ! vals=$(collect_values "$f"); then
        missing_any=1
        continue
    fi
    while IFS= read -r v; do
        [[ -z "$v" ]] && continue
        ALL_VALUES+=("$v")
    done <<<"$vals"
done

total_samples=${#ALL_VALUES[@]}
if (( total_samples < MIN_SAMPLES )); then
    echo "Aggregate samples $total_samples < required minimum $MIN_SAMPLES" >&2
    exit 2
fi

# ----------------------- Statistics (awk) ------------------------------------
# Provide numbers line by line to awk
mean=""
stdev=""

if (( total_samples > 0 )); then
    stats=$(printf '%s\n' "${ALL_VALUES[@]}" | awk '
        { s+=$1; ss+=$1*$1; n++ }
        END {
            if (n==0) { print "0 0"; exit }
            m = s / n
            var = (ss / n) - (m * m)
            if (var < 0) var = 0
            sd = sqrt(var)
            printf "%.6f %.6f\n", m, sd
        }')
    mean=${stats%% *}
    stdev=${stats##* }
else
    mean="0"
    stdev="0"
fi

# Relative standard deviation
rsd="0"
if awk -v m="$mean" 'BEGIN{exit !(m>0)}'; then
    rsd=$(awk -v sd="$stdev" -v m="$mean" 'BEGIN{printf "%.6f", sd/m}')
fi

# ----------------------- RSD Band & Guard Recommendation ---------------------
rsd_band="noisy"
guard_pct=10
notes=""

if awk -v r="$rsd" 'BEGIN{exit !(r <= 0.05)}'; then
    if (( total_samples >= 20 )); then
        guard_pct=5
        rsd_band="stable"
        notes="RSD <=5% with >=20 samples; safe to tighten guard to +5%"
    else
        guard_pct=7
        rsd_band="moderate"
        notes="RSD <=5% but insufficient samples for +5% (promote at >=20); recommend provisional +7%"
    fi
elif awk -v r="$rsd" 'BEGIN{exit !(r <= 0.08)}'; then
    if (( total_samples >= 15 )); then
        guard_pct=7
        rsd_band="moderate"
        notes="RSD <=8% with >=15 samples; tighten guard to +7%"
    else
        guard_pct=10
        rsd_band="moderate"
        notes="RSD <=8% but insufficient samples for +7%; retain +10% until >=15 samples"
    fi
else
    guard_pct=10
    rsd_band="noisy"
    notes="Variance above 8%; retain +10% guard (collect more samples / investigate noise)"
fi

# ----------------------- Stage 2 Baseline Comparison -------------------------
stage2_mean=""
stage2_path="$SCAN_DIR/$STAGE2_FILE"
rel_pct=""
guard_abs=""

if [[ -f "$stage2_path" ]]; then
    # Accept either "mean_ms": or legacy "mean": (integer)
    stage2_line=$(grep -E '"mean_ms"[[:space:]]*:' "$stage2_path" 2>/dev/null | head -1 || true)
    if [[ -z "$stage2_line" ]]; then
        stage2_line=$(grep -E '"mean"[[:space:]]*:' "$stage2_path" 2>/dev/null | head -1 || true)
    fi
    if [[ -n "$stage2_line" ]]; then
        stage2_mean=$(printf '%s' "$stage2_line" | sed -E 's/.*:[[:space:]]*([0-9]+).*/\1/' | sed 's/[^0-9]//g')
    fi
    if [[ -n "$stage2_mean" && "$stage2_mean" =~ ^[0-9]+$ && "$mean" != "0" ]]; then
        rel_pct=$(awk -v cur="$mean" -v base="$stage2_mean" 'BEGIN{ if (base>0){ printf "%.2f", ((cur-base)/base)*100 } else {print ""} }')
        guard_abs=$(awk -v base="$stage2_mean" -v g="$guard_pct" 'BEGIN{ printf "%.2f", base*(1+g/100.0) }')
    fi
fi

[[ -z "$stage2_mean" ]] && stage2_mean="null"
[[ -z "$rel_pct" ]] && rel_pct="null"
[[ -z "$guard_abs" ]] && guard_abs="null"

# ----------------------- Output ----------------------------------------------
if [[ "$OUTPUT_MODE" == "json" ]]; then
    printf '{\n'
    printf '  "schema": "preplugin-variance-eval.v1",\n'
    printf '  "analyzed_files": %d,\n' "$file_count"
    printf '  "total_samples": %d,\n' "$total_samples"
    printf '  "aggregate_mean_ms": %.2f,\n' "$mean"
    printf '  "aggregate_stdev_ms": %.2f,\n' "$stdev"
    printf '  "aggregate_rsd": %.4f,\n' "$rsd"
    if [[ "$stage2_mean" == "null" ]]; then
        printf '  "stage2_baseline_mean_ms": null,\n'
    else
        printf '  "stage2_baseline_mean_ms": %s,\n' "$stage2_mean"
    fi
    if [[ "$rel_pct" == "null" ]]; then
        printf '  "relative_to_stage2_pct": null,\n'
    else
        printf '  "relative_to_stage2_pct": %s,\n' "$rel_pct"
    fi
    printf '  "recommended_guard_pct": %d,\n' "$guard_pct"
    if [[ "$guard_abs" == "null" ]]; then
        printf '  "recommended_guard_absolute_ms": null,\n'
    else
        printf '  "recommended_guard_absolute_ms": %s,\n' "$guard_abs"
    fi
    printf '  "rsd_band": "%s",\n' "$rsd_band"
    printf '  "notes": "%s"\n' "$(printf '%s' "$notes" | json_escape)"
    printf '}\n'
else
    echo "[variance-eval] files=$file_count samples=$total_samples mean=${mean}ms stdev=${stdev}ms rsd=$rsd band=$rsd_band"
    [[ "$stage2_mean" != "null" ]] && echo "[variance-eval] stage2_mean_ms=$stage2_mean rel_pct=$rel_pct%%"
    echo "[variance-eval] recommend guard +${guard_pct}%% (absolute threshold=${guard_abs}ms)"
    echo "[variance-eval] notes: $notes"
fi

exit 0
