#!/usr/bin/env zsh
# bench-shim-audit.zsh
#
# Schema: shim-audit.v1
#
# PURPOSE:
#   Audit zf:: core helper functions and classify which are "shims" (stub /
#   placeholder / trivial wrappers) vs real implementations. Produces a
#   machine-readable JSON artifact plus a concise summary line to aid
#   gating decisions (e.g., enabling micro benchmark regression checks
#   only after all shims are removed).
#
# SHIM HEURISTICS (any condition ⇒ shim):
#   1. Body line count (excluding declaration + closing brace) <= SHIM_MAX_BODY_LINES (default 3)
#   2. Body composed only of: return 0, true, :, or noop comments
#   3. Contains a sentinel comment like: __SHIM__ or SHIM-PLACEHOLDER
#   4. Empty function (no body lines)
#
# NON-SHIM HASHING:
#   - Non-shim functions are hashed (sha256 of normalized body) so future
#     drift detection can compare structural changes without needing full
#     diff context.
#
# OUTPUT:
#   1. Summary line:
#        SHIM_AUDIT total=<N> shims=<M> non_shims=<K>
#   2. JSON (if requested or via env):
#       {
#         "schema":"shim-audit.v1",
#         "generated_at":"UTC_ISO8601",
#         "repo_root":".../dotfiles",
#         "total":N,
#         "shim_count":M,
#         "non_shim_count":K,
#         "shim_max_body_lines": <int>,
#         "fail_on_shims": true|false,
#         "shims":[
#            {"name":"zf::debug","lines":2,"reasons":["short_body","trivial_ops"],"hash":"sha256:<hash>"},
#            ...
#         ],
#         "non_shims":[
#            {"name":"zf::ensure_cmd","lines":14,"hash":"sha256:<hash>"}
#         ]
#       }
#
# EXIT CODES:
#   0 success
#   1 internal / usage error
#   2 fail-on-shims triggered (when --fail-on-shims or env requests and shim_count > 0)
#
# FLAGS:
#   --output-json <file>   Write JSON (use "-" for stdout)
#   --fail-on-shims        Exit 2 if any shims found
#   --max-lines N          Override SHIM_MAX_BODY_LINES
#   --quiet                Suppress non-error stderr diagnostics
#   --help
#
# ENVIRONMENT OVERRIDES:
#   SHIM_AUDIT_OUTPUT_JSON
#   SHIM_AUDIT_FAIL_ON_SHIMS=1
#   SHIM_MAX_BODY_LINES (default 3)
#
# SECURITY / POLICY:
#   - Read-only introspection of shell functions.
#   - No network access.
#
# DEPENDENCIES:
#   - zsh
#   - awk, sed, grep, date, (sha256sum | shasum -a 256 | openssl dgst -sha256)
#
set -euo pipefail

# ---------------- Configuration & Args ----------------
: "${SHIM_MAX_BODY_LINES:=3}"
OUTPUT_JSON="${SHIM_AUDIT_OUTPUT_JSON:-}"
FAIL_ON_SHIMS="${SHIM_AUDIT_FAIL_ON_SHIMS:-0}"
QUIET=0

print_help() {
  sed -n '1,140p' "$0" | grep -E '^#' | sed 's/^# \{0,1\}//'
  cat <<EOF

Usage:
  $0 [--output-json file|'-'] [--fail-on-shims] [--max-lines N] [--quiet]

Examples:
  $0 --output-json docs/redesignv2/artifacts/metrics/shim-audit.json
  SHIM_AUDIT_FAIL_ON_SHIMS=1 $0 --output-json -

EOF
}

while (( $# )); do
  case "$1" in
    --output-json) shift || { echo "ERROR: missing value after --output-json" >&2; exit 1; }; OUTPUT_JSON="$1";;
    --fail-on-shims) FAIL_ON_SHIMS=1;;
    --max-lines) shift || { echo "ERROR: missing value after --max-lines" >&2; exit 1; }; SHIM_MAX_BODY_LINES="$1";;
    --quiet) QUIET=1;;
    --help|-h) print_help; exit 0;;
    --) shift; break;;
    *) echo "ERROR: unknown argument: $1" >&2; print_help; exit 1;;
  esac
  shift || true
done

if ! [[ "$SHIM_MAX_BODY_LINES" =~ ^[0-9]+$ ]]; then
  echo "ERROR: SHIM_MAX_BODY_LINES must be integer" >&2
  exit 1
fi

# ---------------- Repo Root Detection ----------------
script_dir="${0:A:h}"
# Try git root first
if git -C "$script_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)"
else
  # Walk upward until we see dot-config/zsh or .git
  _probe="$script_dir"
  REPO_ROOT=""
  while [[ -n "$_probe" && "$_probe" != "/" ]]; do
    if [[ -d "$_probe/dot-config/zsh" ]]; then
      REPO_ROOT="$_probe"; break
    fi
    if [[ -d "$_probe/.git" && -z "$REPO_ROOT" ]]; then
      REPO_ROOT="$_probe"
    fi
    next="${_probe%/*}"
    [[ "$next" == "$_probe" ]] && break
    _probe="$next"
  done
  [[ -z "$REPO_ROOT" ]] && REPO_ROOT="$script_dir"
fi

# ---------------- Helpers ----------------
_hash() {
  local data
  data="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$data" | sha256sum | awk '{print "sha256:"$1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$data" | shasum -a 256 | awk '{print "sha256:"$1}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$data" | openssl dgst -sha256 2>/dev/null | sed 's/^.* //; s/^/sha256:/'
  else
    # Fallback naive hash
    printf '%s' "$data" | awk '{h=0; for(i=1;i<=length($0);i++){ h = (h*131 + ord(substr($0,i,1))) % 4294967291 } } END{printf "hash32:%u\n", h}'
  fi
}

_trim() {
  sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

_json_escape() {
  # Escape JSON special chars
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

_is_trivial_line() {
  local l="$1"
  [[ -z "$l" ]] && return 0
  case "$l" in
    return\ 0|return\ 1|:|true|false) return 0 ;;
  esac
  # pure comment?
  if [[ "$l" =~ ^# ]]; then
    return 0
  fi
  # assignment only (lightweight)? treat as trivial if extremely short
  if [[ "$l" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
    local len=${#l}
    (( len < 20 )) && return 0
  fi
  return 1
}

_detect_shim() {
  local body="$1"
  local reasons=()
  # Split lines
  local IFS=$'\n'
  local -a lines=(${(f)body})
  # Strip first/last lines if they contain function declaration or lone brace
  # Already we only pass body region (see extraction logic).
  local effective=()
  for l in "${lines[@]}"; do
    [[ -z "$l" ]] && continue
    [[ "$l" == "{" ]] && continue
    [[ "$l" == "}" ]] && continue
    effective+=("$l")
  done
  local count=${#effective[@]}
  if (( count == 0 )); then
    reasons+=("empty")
  fi
  if (( count > 0 && count <= SHIM_MAX_BODY_LINES )); then
    reasons+=("short_body")
  fi
  local trivial_all=1
  for l in "${effective[@]}"; do
    local stripped="${l%%#*}"
    stripped=$(_trim <<<"$stripped")
    if ! _is_trivial_line "$stripped"; then
      trivial_all=0
      break
    fi
  done
  (( trivial_all )) && reasons+=("trivial_ops")
  if grep -qiE '__SHIM__|SHIM-PLACEHOLDER|PLACEHOLDER' <<<"$body"; then
    reasons+=("marker")
  fi
  if (( ${#reasons[@]} > 0 )); then
    printf '%s\n' "${reasons[*]}"
    return 0
  fi
  return 1
}

_extract_function_body() {
  # Uses 'functions -t' style output fallback: typeset -f name
  local name=$1
  # 'functions' in zsh prints body; 'typeset -f' also works
  local raw
  if ! raw=$(typeset -f "$name" 2>/dev/null); then
    return 1
  fi
  # Remove the first line (declaration) and final line if only '}'.
  # Keep interior for hashing / analysis.
  local IFS=$'\n'
  local -a lines=(${(f)raw})
  (( ${#lines[@]} == 0 )) && return 1
  # Drop declaration line
  lines=("${lines[@]:1}")
  # Trim trailing blank lines
  while (( ${#lines[@]} > 0 )) && [[ "${lines[-1]}" == "" ]]; do
    unset "lines[-1]"
  done
  # Drop ending '}' if present
  if (( ${#lines[@]} > 0 )) && [[ "${lines[-1]}" == "}" ]]; then
    unset "lines[-1]"
  fi
  printf '%s\n' "${lines[*]}"
}

_now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date
}

# ---------------- Enumeration ----------------
autoload -Uz +X zmodload || true

# List candidate zf:: functions
local -a candidates
candidates=(${(ok)functions})
candidates=(${candidates[@]:#*_})          # drop internal maybe
candidates=(${candidates[@]:#prompt_*})    # ignore prompt wrappers
candidates=(${candidates[@]:#zf::%})       # pattern mismatch guard (will re-add)
# Rebuild with only zf::
candidates=(${(M)candidates:#zf::*})

local total=${#candidates[@]}
local shim_count=0
local non_shim_count=0

local -a shims_json non_json
local -A seen

for fname in "${candidates[@]}"; do
  [[ -n "${seen[$fname]:-}" ]] && continue
  seen[$fname]=1
  body=$(_extract_function_body "$fname" || true)
  if [[ -z "${body// /}" ]]; then
    reasons=$(_detect_shim "$body" || true)
    shim_count=$((shim_count+1))
    shims_json+=("$fname|0|${reasons:-empty}")
    continue
  fi
  # Normalize body for hashing: strip leading/trailing whitespace on each line
  norm=$(printf '%s\n' "$body" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' )
  reasons=$(_detect_shim "$norm" || true)
  if [[ -n "$reasons" ]]; then
    # classify as shim
    line_ct=$(printf '%s\n' "$norm" | grep -cv '^[[:space:]]*$' || true)
    shim_count=$((shim_count+1))
    shims_json+=("$fname|${line_ct}|${reasons}")
  else
    line_ct=$(printf '%s\n' "$norm" | grep -cv '^[[:space:]]*$' || true)
    h=$(_hash "$norm")
    non_shim_count=$((non_shim_count+1))
    non_json+=("$fname|${line_ct}|$h")
  fi
done

# ---------------- Emit Summary ----------------
(( QUIET == 0 )) && echo "SHIM_AUDIT total=${total} shims=${shim_count} non_shims=${non_shim_count}"

# ---------------- JSON Output (if requested) ----------------
emit_json() {
  local out="$1"
  local iso=$(_now_iso)
  {
    echo '{'
    echo '  "schema":"shim-audit.v1",'
    echo '  "generated_at":"'"$iso"'",'
    echo '  "repo_root":"'"$(printf '%s' "$REPO_ROOT" | _json_escape)"'",'
    echo '  "total":'$total','
    echo '  "shim_count":'$shim_count','
    echo '  "non_shim_count":'$non_shim_count','
    echo '  "shim_max_body_lines":'$SHIM_MAX_BODY_LINES','
    echo '  "fail_on_shims":'$( [[ "$FAIL_ON_SHIMS" == "1" ]] && echo true || echo false )','
    echo '  "shims":['
    local first=1
    for rec in "${shims_json[@]}"; do
      name=${rec%%|*}; rest=${rec#*|}
      lines=${rest%%|*}; reasons=${rest#*|}
      IFS=' ' read -rA reason_arr <<<"$reasons"
      (( first )) || echo ','
      first=0
      printf '    {"name":"%s","lines":%s,"reasons":[' "$(printf '%s' "$name" | _json_escape)" "$lines"
      local rfirst=1
      for r in "${reason_arr[@]}"; do
        [[ -z "$r" ]] && continue
        (( rfirst )) || printf ','
        rfirst=0
        printf '"%s"' "$(printf '%s' "$r" | _json_escape)"
      done
      # Optionally hash even for shims (helps detect accidental changes)
      hash_body=""
      hash_body=$(_hash "$body" 2>/dev/null || echo "")
      printf '],"hash":"%s"}' "$(printf '%s' "$hash_body" | _json_escape)"
    done
    echo
    echo '  ],'
    echo '  "non_shims":['
    first=1
    for rec in "${non_json[@]}"; do
      name=${rec%%|*}; rest=${rec#*|}
      lines=${rest%%|*}; hash=${rest#*|}
      (( first )) || echo ','
      first=0
      printf '    {"name":"%s","lines":%s,"hash":"%s"}' \
        "$(printf '%s' "$name" | _json_escape)" \
        "$lines" \
        "$(printf '%s' "$hash" | _json_escape)"
    done
    echo
    echo '  ]'
    echo '}'
  } | {
    if [[ "$out" == "-" ]]; then
      cat
    else
      mkdir -p "$(dirname "$out")" 2>/dev/null || true
      cat >"$out"
    fi
  }
}

if [[ -n "$OUTPUT_JSON" ]]; then
  emit_json "$OUTPUT_JSON"
fi

# ---------------- Fail on Shims (optional) ----------------
if (( shim_count > 0 )) && [[ "$FAIL_ON_SHIMS" == "1" ]]; then
  (( QUIET == 0 )) && echo "FAIL: shim(s) present and --fail-on-shims enabled" >&2
  exit 2
fi

exit 0
