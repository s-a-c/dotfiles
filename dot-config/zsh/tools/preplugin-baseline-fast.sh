#!/usr/bin/env sh
# preplugin-baseline-fast.sh
# Compliant with internal AI guidelines checksum: ${GUIDELINES_CHECKSUM:-UNSET}
#
# PURPOSE:
#   Fast, POSIX-only capture of the pre-plugin phase baseline (SEGMENT name=pre_plugin_total)
#   without invoking the heavier perf-capture harness (avoids nested shells & potential hangs).
#
# FEATURES:
#   - Runs N lightweight interactive zsh startups.
#   - Forces PERF_SEGMENT_LOG so the redesigned pre-plugin end marker emits the SEGMENT line.
#   - Collects ms values, computes mean, stdev (population), min, max.
#   - Emits JSON artifact suitable for regression tests & gating.
#
# OUTPUT (JSON):
# {
#   "segment": "pre_plugin_total",
#   "samples_ms": [..],
#   "sample_count": N,
#   "mean_ms": <int>,
#   "stdev_ms": <int>,
#   "min_ms": <int>,
#   "max_ms": <int>,
#   "captured_at": "YYYY-MM-DDTHH:MM:SSZ",
#   "tag": "<TAG>",
#   "notes": "Fast manual baseline (N=<N>)",
#   "guidelines_checksum": "<sha256|unset>"
# }
#
# OPTIONS / ENV:
#   RUNS=<int>              Number of samples (default 5)
#   OUT=<path>              Output JSON (default: $ZDOTDIR/docs/redesignv2/artifacts/metrics/preplugin-baseline.json)
#   TAG=<string>            Tag label (default fast-manual)
#   VERBOSE=1               Enable progress logging
#   ZDOTDIR=<path>          Root redesign directory (auto-detect if unset)
#
# EXIT CODES:
#   0 success
#   1 usage / env error
#   2 no samples or segment missing
#
# DEPENDENCIES: zsh, awk, grep, sed, date, (optional) mkdir
#
# SAFETY:
#   - Writes to a temp file then mv to final location.
#   - Does not modify user state or configs.
#
# NOTE:
#   If results look suspiciously large or zero, ensure that:
#     - Redesigned pre-plugin modules are active (ZSH_ENABLE_PREPLUGIN_REDESIGN=1)
#     - 40-pre-plugin-reserved emits SEGMENT lines (PERF_SEGMENT_LOG set)
#     - No blocking plugin manager logic is triggered prematurely
#
set -eu

########################################
# Configuration
########################################
: "${ZDOTDIR:=${ZDOTDIR:-${HOME}/.config/zsh}}"
RUNS="${RUNS:-5}"
OUT="${OUT:-$ZDOTDIR/docs/redesignv2/artifacts/metrics/preplugin-baseline.json}"
TAG="${TAG:-fast-manual}"
VERBOSE="${VERBOSE:-1}"
TMPDIR="${TMPDIR:-/tmp}"

log() { [ "$VERBOSE" = "1" ] && printf '[preplugin-fast] %s\n' "$*" >&2; }
err() { printf '[preplugin-fast][error] %s\n' "$*" >&2; }

case "$RUNS" in ''|*[!0-9]*|0) err "RUNS must be positive integer"; exit 1;; esac

OUTDIR="${OUT%/*}"
if command -v mkdir >/dev/null 2>&1; then
  command mkdir -p "$OUTDIR" 2>/dev/null || true
fi

SAMPLES_FILE="$(mktemp "${TMPDIR%/}/preplugin_fast_samples.XXXXXX")"
trap 'rm -f "$SAMPLES_FILE"' EXIT INT TERM

########################################
# Capture Loop
########################################
i=1
while [ "$i" -le "$RUNS" ]; do
  log "Run $i/$RUNS"
  SEGLOG="$(mktemp "${TMPDIR%/}/preplugin_seg.XXXXXX")"
  # Force redesigned pre-plugin mode & segment logging.
  PERF_SEGMENT_LOG="$SEGLOG" \
    ZSH_ENABLE_PREPLUGIN_REDESIGN=1 \
    ZSH_DEBUG=0 \
    zsh -ic 'exit' >/dev/null 2>&1 || true

  LINE="$(grep '^SEGMENT name=pre_plugin_total ' "$SEGLOG" 2>/dev/null | head -n1 || true)"
  rm -f "$SEGLOG"
  if [ -z "$LINE" ]; then
    log "WARNING: segment missing this run (skipping)"
  else
    MS="$(printf '%s' "$LINE" | sed -E 's/.* ms=([0-9]+).*/\1/')"
    case "$MS" in
      ''|*[!0-9]*) log "Non-integer ms parse (ignored)";;
      *) printf '%s\n' "$MS" >> "$SAMPLES_FILE"; log "Captured ${MS}ms";;
    esac
  fi
  i=$(( i + 1 ))
done

[ -s "$SAMPLES_FILE" ] || { err "No samples captured"; exit 2; }

########################################
# Aggregate Stats
########################################
COUNT=0
SUM=0
MIN=
MAX=
VALS=""
while IFS= read -r v; do
  case "$v" in ''|*[!0-9]* ) continue ;; esac
  VALS="$VALS $v"
  SUM=$(( SUM + v ))
  COUNT=$(( COUNT + 1 ))
  [ -z "${MIN:-}" ] || [ "$v" -lt "$MIN" ] && MIN="$v"
  [ -z "${MAX:-}" ] || [ "$v" -gt "$MAX" ] && MAX="$v"
done < "$SAMPLES_FILE"

[ "$COUNT" -gt 0 ] || { err "No numeric samples processed"; exit 2; }

MEAN=$(( SUM / COUNT ))

# Population stdev (integer) via awk
STDEV="$(awk -v vals="$VALS" -v mean="$MEAN" '
  BEGIN {
    n=0; split(vals,a," ");
    for(i in a){ if(a[i]~/^[0-9]+$/){ d=a[i]-mean; ss+=d*d; n++; } }
    if(n>0){
      val=sqrt(ss/n);              # use built-in sqrt; avoid redefining
      printf("%d", val);
    } else {
      print 0;
    }
  }
')"

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
GUIDE="${GUIDELINES_CHECKSUM:-unset}"

########################################
# Emit JSON
########################################
TMPJSON="$(mktemp "${TMPDIR%/}/preplugin_fast_json.XXXXXX")"

{
  printf '{\n'
  printf '  "segment": "pre_plugin_total",\n'
  printf '  "samples_ms": ['
  FIRST=1
  while IFS= read -r v; do
    case "$v" in ''|*[!0-9]* ) continue ;; esac
    if [ $FIRST -eq 1 ]; then
      FIRST=0; printf '%s' "$v"
    else
      printf ', %s' "$v"
    fi
  done < "$SAMPLES_FILE"
  printf '],\n'
  printf '  "sample_count": %d,\n' "$COUNT"
  printf '  "mean_ms": %d,\n' "$MEAN"
  printf '  "stdev_ms": %s,\n' "$STDEV"
  printf '  "min_ms": %d,\n' "$MIN"
  printf '  "max_ms": %d,\n' "$MAX"
  printf '  "captured_at": "%s",\n' "$TS"
  printf '  "tag": "%s",\n' "$TAG"
  printf '  "notes": "Fast manual baseline (N=%d)",\n' "$COUNT"
  printf '  "guidelines_checksum": "%s"\n' "$GUIDE"
  printf '}\n'
} > "$TMPJSON"

mv "$TMPJSON" "$OUT"

log "Baseline written: $OUT (mean=${MEAN}ms stdev=${STDEV}ms count=${COUNT})"
printf '%s\n' "$OUT"

# Suggested follow-up (not executed):
#   jq '.mean_ms,.stdev_ms' "$OUT"
#   git add "$OUT" && git commit -m "perf(stage2): add pre-plugin baseline" && git tag -a refactor-stage2-preplugin -m "Stage 2: baseline"
#
exit 0
