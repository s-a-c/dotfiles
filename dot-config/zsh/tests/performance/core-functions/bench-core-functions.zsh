#!/usr/bin/env zsh
# NOTE: Pending patch could not be safely applied because I do not have the
# authoritative line numbers/content snapshot required to perform minimal
# replacements. Please provide the current block containing:
#   - The defaults section ending in 'QUIET=0'
#   - The enumeration section starting at 'typeset -a CAND_FUNCS'
# so I can generate an exact, minimal edit that inserts:
#   1. PERF_BENCH_DEBUG default
#   2. Explicit core module sourcing before enumeration
#   3. Debug prints (guard / counts) and improved fallback path.
# bench-core-functions.zsh
# Micro-benchmark harness for Stage 3 core helper functions (zf:: namespace)
# Compliant with [${HOME}/dotfiles/dot-config/ai/guidelines.md](${HOME}/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Provide a lightweight, side‑effect minimal timing harness to measure the
#   approximate per‑call microsecond cost of core helper functions defined in
#   10-core-functions.zsh. Supports machine readable BENCH lines and optional
#   JSON emission for future drift / regression observation (non-gating).
#
# STATUS:
#   Observe mode only. No CI gating. Intended for developer insight & future
#   baseline capture. Safe to skip silently if functions unavailable.
#
# OUTPUT:
#   1) Machine lines (always unless suppressed):
#        BENCH name=<fn> iterations=<N> total_ms=<ms> per_call_us=<µs> rc=<rc> run=<r> repeat=<R>[ extra=...]
#   2) Human table (default; suppress with --machine-only)
#   3) JSON (if --json or --output-json): schema bench-core.v1
#
# EXAMPLES:
#   ./bench-core-functions.zsh
#   ./bench-core-functions.zsh --iterations 10000 --filter log,warn --json
#   BENCH_ITER=2000 BENCH_REPEAT=5 ./bench-core-functions.zsh --machine
#
# EXIT CODES:
#   0 success
#   3 usage error
#   4 failed (threshold exceeded when --fail-on-us specified)
#
# DESIGN NOTES:
#   - Uses EPOCHREALTIME for high-resolution timing when available.
#   - Falls back to date +%s.%N (may reduce precision on macOS).
#   - Median of repeats reported (if --repeat >1) for per_call_us.
#   - Logging helpers optionally redirected to /dev/null to reduce terminal IO
#     interference (toggle with BENCH_CAPTURE_STDERR=1 to include).
#
# ENV / FLAGS (precedence: flag > env > default):
#   --iterations N      / BENCH_ITER           (default 5000)
#   --repeat R          / BENCH_REPEAT         (default 1)
#   --filter list       / BENCH_FILTER         (comma/space separated fn name fragments or exact)
#   --list              (list candidate functions & exit)
#   --json              (emit JSON to stdout after BENCH lines)
#   --output-json FILE  (write JSON to file; if "-" treat as stdout)
#   --machine           (still prints human unless --machine-only)
#   --machine-only      (suppress human summary table)
#   --fail-on-us N      / BENCH_FAIL_ON_US     (fail if any median per_call_us > N)
#   --no-stderr-redir   (do not redirect helper stderr to /dev/null)
#   --quiet             (suppress non-fatal info)
#   --help
#
# FUTURE:
#   - Percentile stats (p50/p90) once repeat>1 usage common.
#   - Integration with perf ledger (aggregate micro_core_helpers_total_ms pseudo segment).
#   - Baseline compare & drift classification (warn / fail tiers).
#
# Relax immediate exit (-e) until after enumeration & shimming stabilization;
# we will selectively re-enable error sensitivity inside critical sections.
set -uo pipefail

# ------------------------- Defaults & Args -------------------------
ITERATIONS="${BENCH_ITER:-5000}"
REPEAT="${BENCH_REPEAT:-1}"
FILTER_RAW="${BENCH_FILTER:-}"
FAIL_ON_US="${BENCH_FAIL_ON_US:-}"
CAPTURE_STDERR="${BENCH_CAPTURE_STDERR:-0}"
MACHINE_ONLY=0
MACHINE_REQUESTED=0
JSON_REQUESTED=0
JSON_OUT_FILE=""
QUIET=0
: ${PERF_BENCH_DEBUG:=0}

_usage() {
  sed -n '1,160p' "$0" | grep -E '^(# |#!/|#$)' | sed 's/^# \{0,1\}//'
  cat <<EOF

Additional Flags:
  --iterations N
  --repeat R
  --filter f1,f2 (comma or space separated; substring or exact match)
  --list
  --json
  --output-json FILE
  --machine
  --machine-only
  --fail-on-us N    (per-call microseconds threshold)
  --no-stderr-redir (keep stderr; default redirects helper logs)
  --quiet
  --help

Environment overrides:
  BENCH_ITER BENCH_REPEAT BENCH_FILTER BENCH_FAIL_ON_US BENCH_CAPTURE_STDERR

Exit codes:
  0 ok, 3 usage, 4 threshold failure

EOF
}

while (( $# )); do
  case "$1" in
    --iterations) shift; ITERATIONS="${1:-}";;
    --repeat) shift; REPEAT="${1:-}";;
    --filter) shift; FILTER_RAW="${1:-}";;
    --list) LIST_ONLY=1;;
    --json) JSON_REQUESTED=1;;
    --output-json) shift; JSON_OUT_FILE="${1:-}"; JSON_REQUESTED=1;;
    --machine) MACHINE_REQUESTED=1;;
    --machine-only) MACHINE_ONLY=1; MACHINE_REQUESTED=1;;
    --fail-on-us) shift; FAIL_ON_US="${1:-}";;
    --no-stderr-redir) CAPTURE_STDERR=1;;
    --quiet) QUIET=1;;
    --help|-h) _usage; exit 0;;
    --) shift; break;;
    *) echo "ERROR: unknown arg: $1" >&2; _usage; exit 3;;
  esac
  shift || true
done

[[ -z "$ITERATIONS" || ! "$ITERATIONS" =~ ^[0-9]+$ || "$ITERATIONS" -lt 1 ]] && { echo "ERROR: invalid --iterations" >&2; exit 3; }
[[ -z "$REPEAT" || ! "$REPEAT" =~ ^[0-9]+$ || "$REPEAT" -lt 1 ]] && { echo "ERROR: invalid --repeat" >&2; exit 3; }
if [[ -n "$FAIL_ON_US" && ! "$FAIL_ON_US" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --fail-on-us must be integer microseconds" >&2
  exit 3
fi

# ------------------------- Repo / Module Load -------------------------
_script_dir() {
  local src="${(%):-%N}"
  print -r -- "${src:h}"
}
SCRIPT_DIR="$(_script_dir)"
[[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: script_dir=$SCRIPT_DIR"
# Derive repository root (expected parent containing dot-config). Original logic
# climbed 4 levels which resolved to .../dot-config; we need the parent of that.
# Primary attempt: climb 5 levels from tests/performance/core-functions/.
# Repository root detection (robust):
# 1. Prefer git rev-parse (fast & accurate).
# 2. Otherwise walk upward until dot-config/zsh or .git found.
# 3. Fallback to historical fixed-depth climb.

if git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"
else
  REPO_ROOT=""
  _probe="$SCRIPT_DIR"
  while [[ -n "$_probe" && "$_probe" != "/" ]]; do
    if [[ -d "$_probe/dot-config/zsh" ]]; then
      REPO_ROOT="$_probe"
      break
    fi
    if [[ -d "$_probe/.git" && -z "$REPO_ROOT" ]]; then
      REPO_ROOT="$_probe"
      # continue searching upward in case a higher parent has dot-config/zsh
    fi
    _next="${_probe%/*}"
    [[ "$_next" == "$_probe" ]] && break
    _probe="$_next"
  done
  if [[ -z "${REPO_ROOT:-}" ]]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../" 2>/dev/null && pwd -P || true)"
  fi
fi

if [[ ! -d "${REPO_ROOT}/dot-config/zsh" ]]; then
  print -u2 "WARN: bench-core-functions: could not confidently locate repo root (REPO_ROOT='${REPO_ROOT}')"
fi

CORE_MODULE="${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/10-core-functions.zsh"
# Unconditional explicit sourcing of core modules (pre + post) before enumeration
for __bench_core_try in \
  "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/10-core-functions.zsh" \
  "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/POSTPLUGIN/10-core-functions.zsh"
do
  if [[ -f "$__bench_core_try" ]]; then
    . "$__bench_core_try" 2>/dev/null || true
    [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: sourced $__bench_core_try (guards: ZSH_CORE_FUNCTIONS_GUARD=${ZSH_CORE_FUNCTIONS_GUARD:-unset} _LOADED_10_CORE_FUNCTIONS=${_LOADED_10_CORE_FUNCTIONS:-unset})"
  else
    [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: missing $__bench_core_try"
  fi
done
# Fallback: if pre-plugin core module missing, try post-plugin scaffold version
if [[ ! -f "$CORE_MODULE" ]]; then
  CORE_MODULE_POST="${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/POSTPLUGIN/10-core-functions.zsh"
  if [[ -f "$CORE_MODULE_POST" ]]; then
    CORE_MODULE="$CORE_MODULE_POST"
    (( QUIET )) || echo "INFO: bench-core-functions: using POSTPLUGIN core functions module fallback" >&2
  fi
fi
# Load if not already provided by either sentinel (_LOADED_10_CORE_FUNCTIONS or ZSH_CORE_FUNCTIONS_GUARD)
if [[ -f "$CORE_MODULE" && -z "${ZSH_CORE_FUNCTIONS_GUARD:-${_LOADED_10_CORE_FUNCTIONS:-}}" ]]; then
  # shellcheck disable=SC1090
  . "$CORE_MODULE" 2>/dev/null || true
elif [[ ! -f "$CORE_MODULE" ]]; then
  (( QUIET )) || echo "WARN: bench-core-functions: core functions module not found (looked for pre & post-plugin variants)" >&2
fi

# If still not loaded, attempt a basic dynamic load by searching for zf:: functions.
typeset -a CAND_FUNCS
CAND_FUNCS=($(typeset -f | awk '/^zf::[a-zA-Z0-9_]+\s*\(\)/{sub(/\(\)/,"",$1);print $1}' | sort))
[[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: initial enumeration count=${#CAND_FUNCS[@]}"

# Function: attempt forced sourcing of core modules if enumeration empty
__bench_force_core_load() {
  local candidates=(
    "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/10-core-functions.zsh"
    "${REPO_ROOT}/dot-config/zsh/.zshrc.d.REDESIGN/POSTPLUGIN/10-core-functions.zsh"
  )
  local f
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] || continue
    # If sentinel already set, no need to source again
    if [[ -z "${ZSH_CORE_FUNCTIONS_GUARD:-${_LOADED_10_CORE_FUNCTIONS:-}}" ]]; then
      . "$f" 2>/dev/null || true
    fi
  done
}

# If initial parse empty, try explicit exports & forced load
if (( ${#CAND_FUNCS[@]} == 0 )); then
  __bench_force_core_load
  # Re-enumerate after potential load
  CAND_FUNCS=($(typeset -f | awk '/^zf::[a-zA-Z0-9_]+\s*\(\)/{sub(/\(\)/,"",$1);print $1}' | sort))
  [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: post-force enumeration count=${#CAND_FUNCS[@]}"
fi

# Fallback enumeration via explicit export helper / variable
if (( ${#CAND_FUNCS[@]} == 0 )); then
  if typeset -f zf::exports >/dev/null 2>&1; then
    CAND_FUNCS=($(zf::exports | tr ' ' '\n' | grep '^zf::' | sort -u))
    [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: used zf::exports fallback count=${#CAND_FUNCS[@]}"
  elif [[ -n "${ZF_CORE_EXPORTS:-}" ]]; then
    CAND_FUNCS=($(print -r -- "$ZF_CORE_EXPORTS" | tr ' ' '\n' | grep '^zf::' | sort -u))
    [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && print -u2 -- "DEBUG[bench]: used ZF_CORE_EXPORTS fallback count=${#CAND_FUNCS[@]}"
  fi
fi

# Accept enumeration if we now have functions (set force-continue flag)
if (( ${#CAND_FUNCS[@]} > 0 )); then
  BENCH_FORCE_CONTINUE=1
fi

# Emit initialization marker (post-enumeration) for diagnostics
print -- "BENCH_INIT enumeration_count=${#CAND_FUNCS[@]} mode=${BENCH_ENUM_MODE:-pre} shimmed_count=${BENCH_SHIMMED_COUNT:-0}"

# Still nothing? Abort quietly (observe mode)
if (( ${#CAND_FUNCS[@]} == 0 )); then
  (( QUIET )) || echo "WARN: no zf:: core functions detected (nothing to benchmark)" >&2
  [[ "${PERF_BENCH_DEBUG:-0}" == "1" ]] && {
    print -u2 -- "DEBUG[bench]: guards ZSH_CORE_FUNCTIONS_GUARD=${ZSH_CORE_FUNCTIONS_GUARD:-unset} _LOADED_10_CORE_FUNCTIONS=${_LOADED_10_CORE_FUNCTIONS:-unset}"
    print -u2 -- "DEBUG[bench]: REPO_ROOT=${REPO_ROOT}"
  }
  exit 0
fi

# ------------------------- Shim Fallback (if definitions missing) -------------------------
# Build list of missing function definitions (not present in typeset -f after all sourcing).
typeset -a _bench_missing _bench_defined
for _bf in "${CAND_FUNCS[@]}"; do
  if typeset -f -- "$_bf" >/dev/null 2>&1; then
    _bench_defined+=("$_bf")
  else
    _bench_missing+=("$_bf")
  fi
done

BENCH_ENUM_MODE="dynamic"
if (( ${#_bench_missing[@]} > 0 )); then
  # If majority missing, enable shim mode.
  if (( ${#_bench_defined[@]} == 0 || ${#_bench_missing[@]} * 2 >= ${#CAND_FUNCS[@]} )); then
    BENCH_ENUM_MODE="shim_fallback"
    (( QUIET )) || echo "INFO: bench-core-functions: activating shim fallback (${#_bench_missing[@]} missing / ${#CAND_FUNCS[@]} total)" >&2
    for _sf in "${_bench_missing[@]}"; do
      # Provide a no-op shim (return 0) so dispatch overhead is measurable.
      eval "${_sf}(){ :; }"
    done
  else
    BENCH_ENUM_MODE="partial_shim"
    (( QUIET )) || echo "INFO: bench-core-functions: partially shimmed (${#_bench_missing[@]} missing)" >&2
    for _sf in "${_bench_missing[@]}"; do
      eval "${_sf}(){ :; }"
    done
  fi
fi
BENCH_SHIMMED_COUNT=${#_bench_missing[@]}

# ------------------------- Filter Application -------------------------
_apply_filter() {
  local raw="$1"
  [[ -z "$raw" ]] && return 0
  local -a wanted out
  # Normalize delimiters
  raw="${raw//,/ }"
  for w in $raw; do
    wanted+=("$w")
  done
  local fn match
  for fn in "${CAND_FUNCS[@]}"; do
    match=0
    for pat in "${wanted[@]}"; do
      # substring or exact
      if [[ "$fn" == "$pat" || "$fn" == *"$pat"* ]]; then
        match=1; break
      fi
    done
    (( match )) && out+=("$fn")
  done
  CAND_FUNCS=("${out[@]}")
}

_apply_filter "$FILTER_RAW"

if [[ -n "${LIST_ONLY:-}" ]]; then
  printf '%s\n' "${CAND_FUNCS[@]}"
  exit 0
fi

if (( ${#CAND_FUNCS[@]} == 0 )); then
  echo "WARN: filter removed all candidate functions" >&2
  exit 0
fi

# ------------------------- Timing Helpers -------------------------
_now_epoch_ms() {
  # Millisecond resolution, high precision path
  if [[ -n ${EPOCHREALTIME:-} ]]; then
    # EPOCHREALTIME: seconds.microseconds
    # Convert to milliseconds accurately via awk
    awk -v t="$EPOCHREALTIME" 'BEGIN{split(t,a,"."); ms = (a[1]*1000) + (a[2]/1000); printf "%.3f", ms}'
  else
    # Fallback (may lose precision)
    local t
    t=$(date +%s.%N 2>/dev/null || date +%s 2>/dev/null)
    awk -v t="$t" 'BEGIN{split(t,a,"."); ms=(a[1]*1000); if(a[2]!=""){ ms += (a[2]/1000000) } printf "%.3f", ms}'
  fi
}

_elapsed_us() {
  # Args: start_ms end_ms
  # Return microseconds (integer)
  awk -v s="$1" -v e="$2" 'BEGIN{
    d = e - s;
    if (d < 0) d = 0;
    printf "%d", (d * 1000.0)
  }'
}

_fmt_float() {
  local val="$1" prec="${2:-1}"
  awk -v v="$val" -v p="$prec" 'BEGIN{fmt="%."p"f"; printf fmt,v}'
}

# ------------------------- Benchmark Core -------------------------
# Decide iteration strategy per function (some may get auto-scaling later; uniform for now)
ITER_LOOP="$ITERATIONS"

# Optional stderr redirection (reduce noise)
_redir_stderr() {
  if (( CAPTURE_STDERR )); then
    "$@"
  else
    "$@" 2>/dev/null
  fi
}

# Execute one timing run for a function name
# Outputs: total_ms per_call_us rc
_bench_once() {
  local fn="$1" iter="$2"
  local start_ms end_ms us rc i shimmed=0
  # Shim detection: rely on original missing list membership instead of body pattern
  if [[ " ${_bench_missing[*]:-} " == *" $fn "* ]]; then
    shimmed=1
  fi
  start_ms="$(_now_epoch_ms)"
  set +e
  case "$fn" in
    zf::ensure_cmd)
      for (( i=1; i<=iter; i++ )); do _redir_stderr "$fn" true false >/dev/null || true; done
      ;;
    zf::require)
      for (( i=1; i<=iter; i++ )); do _redir_stderr "$fn" echo >/dev/null || true; done
      ;;
    zf::with_timing)
      for (( i=1; i<=iter; i++ )); do _redir_stderr "$fn" noop true >/dev/null || true; done
      ;;
    zf::timed)
      for (( i=1; i<=iter; i++ )); do _redir_stderr "$fn" anon ':' >/dev/null || true; done
      ;;
    zf::log|zf::warn|zf::debug)
      for (( i=1; i<=iter; i++ )); do _redir_stderr "$fn" "x" >/dev/null || true; done
      ;;
    zf::list_functions)
      for (( i=1; i<=iter; i++ )); do "$fn" >/dev/null 2>&1 || true; done
      ;;
    *)
      for (( i=1; i<=iter; i++ )); do "$fn" >/dev/null 2>&1 || true; done
      ;;
  esac
  rc=$?
  set -e
  end_ms="$(_now_epoch_ms)"
  us="$(_elapsed_us "$start_ms" "$end_ms")"
  local total_ms per_call_us
  total_ms=$(_fmt_float "$(awk -v u="$us" 'BEGIN{printf "%.3f", u/1000.0}')" 3)
  if (( iter > 0 )); then
    per_call_us=$(awk -v u="$us" -v it="$iter" 'BEGIN{printf "%.2f", (u/it)}')
  else
    per_call_us="0.00"
  fi
  # Append shim flag as third field extension (preserve original output contract for existing parsing)
  print -- "$total_ms $per_call_us $rc $shimmed"
}

_median() {
  # Read numbers (one per line) from stdin; output median (float as-is)
  awk '
    NF {
      a[NR]=$1
    }
    END {
      if (NR==0){print 0; exit}
      n=NR
      # sort
      for(i=1;i<=n;i++){
        for(j=i+1;j<=n;j++){
          if(a[j]<a[i]){tmp=a[i];a[i]=a[j];a[j]=tmp}
        }
      }
      if (n%2==1) {
        print a[(n+1)/2]
      } else {
        print (a[n/2] + a[n/2 + 1]) / 2.0
      }
    }'
}

# ------------------------- Run Benchmarks -------------------------
typeset -a BENCH_JSON_ENTRIES
typeset -a HUMAN_ROWS
HUMAN_ROWS+=("Function|Iter|Repeat|Median µs/call|Total ms (median run)|RC(median)")
FAIL_REASON=""

run_id=0
for fn in "${CAND_FUNCS[@]}"; do
  (( run_id++ ))
  # Skip internal functions or those not fitting expected pattern
  if [[ "$fn" != zf::* ]]; then
    (( QUIET )) || echo "INFO: skipping non-namespaced function $fn" >&2
    continue
  fi
  # Progress marker (machine parsable)
  print -- "BENCH_START name=${fn} iterations=${ITER_LOOP} repeat=${REPEAT}"

  typeset -a per_call_samples total_ms_samples rc_samples
  local r
  for (( r=1; r<=REPEAT; r++ )); do
    read -r total_ms per_call_us rc shimmed_flag <<< "$(_bench_once "$fn" "$ITER_LOOP")"
    per_call_samples+=("$per_call_us")
    total_ms_samples+=("$total_ms")
    rc_samples+=("$rc")
    print -- "BENCH name=${fn} iterations=${ITER_LOOP} total_ms=${total_ms} per_call_us=${per_call_us} rc=${rc} shimmed=${shimmed_flag} run=${r} repeat=${REPEAT}"  # machine line
  done

  # Compute medians
  local median_us median_total_ms median_rc
  median_us="$(printf '%s\n' "${per_call_samples[@]}" | _median)"
  median_total_ms="$(printf '%s\n' "${total_ms_samples[@]}" | _median)"
  # Choose rc from median position (or 0 if all zero)
  median_rc="0"
  # If any rc != 0 preserve as indicative; else 0
  for rcval in "${rc_samples[@]}"; do
    if [[ "$rcval" != "0" ]]; then median_rc="$rcval"; break; fi
  done

  # Store JSON entry
  # Determine if shimmed (any sample flagged shimmed=1 implies shimmed)
  shimmed_sample=0
  if print -r -- "${rc_samples[@]}" >/dev/null 2>&1; then :; fi
  if [[ " ${_bench_missing[*]:-} " == *" $fn "* ]]; then
    shimmed_sample=1
  fi
  BENCH_JSON_ENTRIES+=("{\"name\":\"${fn}\",\"iterations\":${ITER_LOOP},\"repeat\":${REPEAT},\"median_per_call_us\":${median_us},\"median_total_ms\":${median_total_ms},\"rc\":${median_rc},\"shimmed\":${shimmed_sample}}")

  HUMAN_ROWS+=("${fn}|${ITER_LOOP}|${REPEAT}|${median_us}|${median_total_ms}|${median_rc}")

  if [[ -n "$FAIL_ON_US" ]]; then
    # Compare numeric (float safe) using awk
    awk -v a="$median_us" -v b="$FAIL_ON_US" 'BEGIN{exit !(a>b)}'
    if (( $? == 0 )); then
      FAIL_REASON="per_call_us(${fn})=${median_us} > ${FAIL_ON_US}"
    fi
  fi
done

# ------------------------- Human Output -------------------------
if (( MACHINE_ONLY == 0 )); then
  # Simple table rendering
  print ""
  print "Core Function Micro Benchmarks"
  print "Iterations=${ITER_LOOP} Repeat=${REPEAT} Timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  print ""
  # Header
  local row
  for row in "${HUMAN_ROWS[@]}"; do
    IFS='|' read -r c1 c2 c3 c4 c5 c6 <<<"$row"
    printf '%-30s %8s %8s %15s %16s %8s\n' "$c1" "$c2" "$c3" "$c4" "$c5" "$c6"
  done
fi

# ------------------------- JSON Output -------------------------
_emit_json() {
  local ts iter rep
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
  printf '{\n'
  printf '  "schema": "bench-core.v1",\n'
  printf '  "generated_at": "%s",\n' "$ts"
  printf '  "iterations": %s,\n' "$ITER_LOOP"
  printf '  "repeat": %s,\n' "$REPEAT"
  # Recompute shimmed_count dynamically from BENCH_JSON_ENTRIES to ensure accuracy
  local dyn_shimmed=0
  for e in "${BENCH_JSON_ENTRIES[@]}"; do
    [[ "$e" == *'"shimmed":1'* ]] && (( dyn_shimmed++ ))
  done
  printf '  "shimmed_count": %s,\n' "$dyn_shimmed"
  printf '  "enumeration_mode": "%s",\n' "$BENCH_ENUM_MODE"
  printf '  "functions": [\n'
  local i=0
  local total=${#BENCH_JSON_ENTRIES[@]}
  for e in "${BENCH_JSON_ENTRIES[@]}"; do
    (( i++ ))
    if (( i < total )); then
      printf '    %s,\n' "$e"
    else
      printf '    %s\n' "$e"
    fi
  done
  printf '  ]\n'
  printf '}\n'
}

if (( JSON_REQUESTED )); then
  if [[ -n "$JSON_OUT_FILE" && "$JSON_OUT_FILE" != "-" ]]; then
    _emit_json >| "$JSON_OUT_FILE" 2>/dev/null || {
      echo "ERROR: failed to write JSON to $JSON_OUT_FILE" >&2
      exit 3
    }
    (( QUIET )) || echo "Wrote JSON: $JSON_OUT_FILE" >&2
  else
    _emit_json
  fi
fi

# ------------------------- Threshold Evaluation -------------------------
if [[ -n "$FAIL_REASON" ]]; then
  echo "FAIL: $FAIL_REASON" >&2
  exit 4
fi

exit 0
