#!/usr/bin/env sh
# preplugin-baseline-manual.sh
# Compliant with [/Users/s-a-c/.config/ai/guidelines.md](/Users/s-a-c/.config/ai/guidelines.md) ${GUIDELINES_CHECKSUM:-vUNKNOWN}
#
# PURPOSE:
#   Lightweight, POSIX‑only helper to generate a pre‑plugin phase baseline JSON
#   (preplugin-baseline.json) when the richer Zsh-based capture script is
#   unavailable or failing under constrained environments.
#
# FEATURES:
#   - Uses only POSIX shell + standard coreutils/awk/grep/sed.
#   - Runs N iterative perf captures (invoking perf-capture.zsh if present).
#   - Extracts the SEGMENT line: SEGMENT name=pre_plugin_total ms=<value>
#   - Computes: samples, count, mean, population stdev (integer), min, max.
#   - Emits a minimal JSON artifact suitable for regression guards & tests.
#
# LIMITATIONS:
#   - No percentile / IQR filtering (kept intentionally simple).
#   - Assumes perf-capture.zsh creates/updates perf-current-segments.txt.
#
# USAGE:
#   ./preplugin-baseline-manual.sh [-n runs] [-o output_json] [-s segments_file] [-c perf_capture_script] [-t tag] [-v]
#
# OPTIONS:
#   -n <runs>          Number of samples (default: 5)
#   -o <output_json>   Output file path (default: <ZDOTDIR>/docs/redesignv2/artifacts/metrics/preplugin-baseline.json)
#   -s <segments_file> Override segments file path (auto-detect if omitted)
#   -c <capture_zsh>   Path to perf-capture.zsh (auto-detect if omitted)
#   -t <tag>           Tag string to embed (default: manual-baseline)
#   -v                 Verbose progress
#   -h                 Show help and exit
#
# EXIT CODES:
#   0 Success
#   1 Usage / argument error
#   2 Missing perf-capture tool (if required) or segments file could not be produced
#   3 No valid samples collected
#
# JSON SCHEMA (minimal):
# {
#   "segment": "pre_plugin_total",
#   "samples_ms": [..],
#   "sample_count": N,
#   "mean_ms": M,
#   "stdev_ms": S,
#   "min_ms": m,
#   "max_ms": x,
#   "captured_at": "YYYY-MM-DDTHH:MM:SSZ",
#   "tag": "manual-baseline",
#   "notes": "Manual POSIX capture",
#   "guidelines_checksum": "<sha|unset>"
# }
#
# SAFE PRACTICES:
#   - Writes to a temp file then atomic mv to final output.
#   - Validates integer metrics.
#
# DEPENDENCIES (expected in PATH):
#   awk, grep, sed, date, uname
#
# COPYRIGHT / LICENSE:
#   Internal tooling – keep self‑contained and policy compliant.
#
##############################################################################

set -eu

# -------- Defaults --------
ZDOTDIR_DEFAULT="${ZDOTDIR:-${HOME}/.config/zsh}"
RUNS=5
TAG="manual-baseline"
VERBOSE=0
CAPTURE_SCRIPT=""
SEGMENTS_FILE=""
OUTPUT_JSON=""

# -------- Helpers --------
log() { [ "$VERBOSE" -eq 1 ] && printf '[preplugin-manual] %s\n' "$*" >&2; }
err() { printf '[preplugin-manual][error] %s\n' "$*" >&2; }

show_help() {
  sed -n '1,/^##############################################################################/p' "$0" | sed 's/^# \{0,1\}//'
}

is_int() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

# -------- Arg Parse --------
while [ $# -gt 0 ]; do
  case "$1" in
    -n)
      [ $# -ge 2 ] || { err "Missing value after -n"; exit 1; }
      RUNS="$2"; shift 2
      ;;
    -o)
      [ $# -ge 2 ] || { err "Missing value after -o"; exit 1; }
      OUTPUT_JSON="$2"; shift 2
      ;;
    -s)
      [ $# -ge 2 ] || { err "Missing value after -s"; exit 1; }
      SEGMENTS_FILE="$2"; shift 2
      ;;
    -c)
      [ $# -ge 2 ] || { err "Missing value after -c"; exit 1; }
      CAPTURE_SCRIPT="$2"; shift 2
      ;;
    -t)
      [ $# -ge 2 ] || { err "Missing value after -t"; exit 1; }
      TAG="$2"; shift 2
      ;;
    -v)
      VERBOSE=1; shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate RUNS
is_int "$RUNS" || { err "RUNS must be integer"; exit 1; }
[ "$RUNS" -gt 0 ] || { err "RUNS must be > 0"; exit 1; }

# Detect capture script if not provided
if [ -z "$CAPTURE_SCRIPT" ]; then
  CAND1="${ZDOTDIR_DEFAULT}/tools/perf-capture.zsh"
  [ -x "$CAND1" ] && CAPTURE_SCRIPT="$CAND1"
fi

# Determine output path
if [ -z "$OUTPUT_JSON" ]; then
  OUTPUT_JSON="${ZDOTDIR_DEFAULT}/docs/redesignv2/artifacts/metrics/preplugin-baseline.json"
fi

# Determine segments file if not given (perf tooling standard path)
if [ -z "$SEGMENTS_FILE" ]; then
  SEG_CAND1="${ZDOTDIR_DEFAULT}/docs/redesignv2/artifacts/metrics/perf-current-segments.txt"
  SEG_CAND2="${ZDOTDIR_DEFAULT}/docs/redesign/metrics/perf-current-segments.txt"
  if [ -f "$SEG_CAND1" ]; then
    SEGMENTS_FILE="$SEG_CAND1"
  else
    SEGMENTS_FILE="$SEG_CAND1"  # prefer new path; may be created
  fi
  # fallback existence check only later
fi

log "Runs=$RUNS"
log "Output=$OUTPUT_JSON"
log "Segments file target=$SEGMENTS_FILE"
log "Capture script=${CAPTURE_SCRIPT:-<none>} (invoked each run if present)"

TMPDIR="${TMPDIR:-/tmp}"
SAMPLES_TMP="$(mktemp "${TMPDIR%/}/preplugin_samples.XXXXXX")"

cleanup() {
  rm -f "$SAMPLES_TMP" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

i=1
while [ "$i" -le "$RUNS" ]; do
  log "Run $i/$RUNS"
  if [ -n "$CAPTURE_SCRIPT" ] && [ -x "$CAPTURE_SCRIPT" ]; then
    # Invoke capture through zsh to ensure proper environment; ignore user rc confusions.
    # Avoid -l/-o expansions; minimal interactive to trigger segments.
    ZSH_ENABLE_PREPLUGIN_REDESIGN=1 zsh -f "$CAPTURE_SCRIPT" --segments >/dev/null 2>&1 || true
  else
    if [ ! -f "$SEGMENTS_FILE" ]; then
      err "segments file not present and no capture script available"
      exit 2
    fi
  fi

  # Ensure segments file now exists
  if [ ! -f "$SEGMENTS_FILE" ]; then
    err "segments file still missing after run $i: $SEGMENTS_FILE"
    exit 2
  fi

  LINE="$(grep '^SEGMENT name=pre_plugin_total ' "$SEGMENTS_FILE" 2>/dev/null | head -n 1 || true)"
  if [ -z "$LINE" ]; then
    log "Segment not found run $i (skipping)"
  else
    # extract ms=
    VAL="$(printf '%s\n' "$LINE" | sed -E 's/.* ms=([0-9]+).*/\1/')"
    if is_int "$VAL"; then
      printf '%s\n' "$VAL" >> "$SAMPLES_TMP"
      log "Captured pre_plugin_total=${VAL}ms"
    else
      log "Non-integer ms parse run $i (ignored)"
    fi
  fi

  i=$(( i + 1 ))
done

if [ ! -s "$SAMPLES_TMP" ]; then
  err "No valid samples collected"
  exit 3
fi

# Aggregate
COUNT=0
SUM=0
MIN=""
MAX=""
VALUES=""
while IFS= read -r v; do
  is_int "$v" || continue
  VALUES="${VALUES}${v} "
  SUM=$(( SUM + v ))
  COUNT=$(( COUNT + 1 ))
  if [ -z "$MIN" ] || [ "$v" -lt "$MIN" ]; then MIN="$v"; fi
  if [ -z "$MAX" ] || [ "$v" -gt "$MAX" ]; then MAX="$v"; fi
done < "$SAMPLES_TMP"

if [ "$COUNT" -eq 0 ]; then
  err "No numeric samples gathered"
  exit 3
fi

MEAN=$(( SUM / COUNT ))

# Compute population stdev (integer) using awk for precision
STDEV="$(awk -v vals="$VALUES" -v mean="$MEAN" '
  BEGIN {
    n=0; split(vals,a," ");
    for(i in a){
      if(a[i] ~ /^[0-9]+$/){
        n++; d=a[i]-mean; ss+=d*d;
      }
    }
    if(n>0){ st=sqrt(ss/n); } else { st=0; }
    printf("%d", st);
  }
  function sqrt(x){return x^0.5}
')"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GUIDE="${GUIDELINES_CHECKSUM:-unset}"

# Build JSON safely via printf
TMP_JSON="$(mktemp "${TMPDIR%/}/preplugin_baseline_json.XXXXXX")"
{
  printf '{\n'
  printf '  "segment": "pre_plugin_total",\n'
  printf '  "samples_ms": ['
  FIRST=1
  while IFS= read -r v; do
    is_int "$v" || continue
    if [ $FIRST -eq 1 ]; then
      printf '%s' "$v"
      FIRST=0
    else
      printf ', %s' "$v"
    fi
  done < "$SAMPLES_TMP"
  printf '],\n'
  printf '  "sample_count": %d,\n' "$COUNT"
  printf '  "mean_ms": %d,\n' "$MEAN"
  printf '  "stdev_ms": %s,\n' "$STDEV"
  printf '  "min_ms": %d,\n' "$MIN"
  printf '  "max_ms": %d,\n' "$MAX"
  printf '  "captured_at": "%s",\n' "$TS"
  printf '  "tag": "%s",\n' "$TAG"
  printf '  "notes": "Manual POSIX capture (N=%d)",\n' "$COUNT"
  printf '  "guidelines_checksum": "%s"\n' "$GUIDE"
  printf '}\n'
} > "$TMP_JSON"

# Ensure directory for output
OUT_DIR="${OUTPUT_JSON%/*}"
if [ ! -d "$OUT_DIR" ]; then
  if command -v mkdir >/dev/null 2>&1; then
    command mkdir -p "$OUT_DIR" 2>/dev/null || true
  fi
fi

mv "$TMP_JSON" "$OUTPUT_JSON"

log "Baseline JSON written to: $OUTPUT_JSON"
log "Mean=${MEAN}ms Stdev=${STDEV}ms Count=${COUNT} Min=${MIN} Max=${MAX}"

printf '%s\n' "$OUTPUT_JSON"
exit 0
