#!/usr/bin/env zsh
# test-structured-telemetry-schema.zsh
# Compliant with ${HOME}/.config/ai/guidelines.md v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Validate structured telemetry JSONL emitted by the ZSH redesign (SEGMENT / future DEFERRED lines)
#   against an allowlisted schema (privacy & stability contract).
#
# SCOPE:
#   - CURRENTLY validates only `type=segment` objects.
#   - Can be extended for `type=deferred` / future telemetry types.
#
# VALIDATION MODES:
#   Default: Non‑strict – unknown keys warn (exit 0) unless --strict passed (then exit >0).
#   Strict: Any unexpected key OR missing required key OR invalid value domain => failure.
#
# REQUIREMENTS:
#   - Does NOT require jq (uses lightweight parsing); will prefer jq if present for stricter JSON parsing.
#   - Works with POSIX-safe subset of zsh features (no external heavy deps).
#
# EXIT CODES:
#   0  success (or only warnings in non-strict mode)
#   1  usage / argument error
#   2  IO error (missing/unreadable file)
#   3  schema violation (strict mode) / critical validation failure
#   4  internal parser error
#
# USAGE:
#   test-structured-telemetry-schema.zsh --file perf-segments.jsonl
#   test-structured-telemetry-schema.zsh -f artifacts/perf-current.jsonl --strict
#   test-structured-telemetry-schema.zsh --stdin   (read from STDIN)
#   test-structured-telemetry-schema.zsh --self-test
#
# ALLOWLIST (segment objects):
#   Required keys: type, name, ms, phase, sample, ts
#   Allowed values:
#     type  == "segment"
#     name  matches ^[a-z0-9._:/+-]+$  (conservative to avoid PII/path leakage)
#     ms    integer >= 0 and < 600000 (cap 10 minutes for sanity)
#     phase in {pre_plugin,post_plugin,prompt,postprompt,core}
#     sample arbitrary token (<=32 chars recommended)  (cold|warm|inline|unknown etc)
#     ts    epoch milliseconds (13 digits) (we do len + numeric check)
#
#   Any additional key => warning (non-strict) or error (strict).
#
# PRIVACY / DRIFT GUARANTEE:
#   This script enforces that no unexpected telemetry fields are silently added.
#   To expand schema:
#     1. Add key to ALLOWLIST_KEYS / REQUIRED_KEYS as appropriate.
#     2. Document in REFERENCE.md §5.3 (Structured Telemetry Keys).
#     3. Update privacy appendix if category changes.
#
# MAINTENANCE NOTES:
#   - Keep logic deterministic & side-effect free.
#   - Avoid external processes in tight loops; rely on pure zsh features where possible.
#
# AUTHOR: AI Orchestration – Structured Telemetry Governance
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_NAME=${0:t}

print_err() { print -r -- "[schema][ERROR] $*" >&2; }
print_warn() { print -r -- "[schema][WARN]  $*" >&2; }
print_info() { print -r -- "[schema][INFO]  $*" >&2; }

usage() {
  cat <<EOF
$SCRIPT_NAME - Structured Telemetry Schema Validator

Usage:
  $SCRIPT_NAME --file <jsonl_file>
  $SCRIPT_NAME --stdin
  $SCRIPT_NAME [--strict] [--allow-extra] [--max-lines N] [--quiet]
  $SCRIPT_NAME --self-test

Options:
  -f, --file <path>     JSON lines file containing structured telemetry (one object per line)
      --stdin           Read JSON lines from STDIN instead of a file
  -s, --strict          Fail (exit 3) on ANY schema deviation (unknown key, missing key, bad value)
      --allow-extra     Treat unknown keys as allowed (overrides --strict unknown-key errors)
  -m, --max-lines <N>   Stop after validating N lines (performance / sampling)
  -q, --quiet           Suppress per-line OK messages
      --self-test       Run internal validator self-tests
  -h, --help            Show this help

Exit Codes:
  0 success
  1 usage error
  2 file IO error
  3 schema violation (strict) or critical parse failure
  4 internal parser error

Environment Overrides:
  SCHEMA_SEGMENT_REQUIRED (space-separated keys)
  SCHEMA_SEGMENT_ALLOWED  (space-separated keys including required)
EOF
}

# Defaults
STRICT=0
ALLOW_EXTRA=0
QUIET=0
MAX_LINES=0
INPUT_FILE=""
USE_STDIN=0

# Parse args
while (( $# > 0 )); do
  case "$1" in
    -f|--file) shift || { usage >&2; exit 1; }; INPUT_FILE=$1;;
    --stdin) USE_STDIN=1;;
    -s|--strict) STRICT=1;;
    --allow-extra) ALLOW_EXTRA=1;;
    -m|--max-lines) shift || { usage >&2; exit 1; }; MAX_LINES=$1;;
    -q|--quiet) QUIET=1;;
    --self-test) SELF_TEST=1;;
    -h|--help) usage; exit 0;;
    *) print_err "Unknown argument: $1"; usage >&2; exit 1;;
  esac
  shift
done

if [[ -n "${SELF_TEST:-}" ]]; then
  run_self_test() {
    # Minimal embedded self-test without jq dependency.
    local tmp ok=0
    tmp="$(mktemp -t schema-test.XXXXXX)"

    cat > "$tmp" <<'JSON'
{"type":"segment","name":"pre_plugin_start","ms":0,"phase":"pre_plugin","sample":"cold","ts":1690000000000}
{"type":"segment","name":"dev-env/rust","ms":12,"phase":"post_plugin","sample":"warm","ts":1690000001234}
{"type":"segment","name":"prompt_ready","ms":345,"phase":"prompt","sample":"cold","ts":1690000002345}
JSON

    if "$0" --file "$tmp" --strict >/dev/null 2>&1; then
      print_info "Self-test (valid lines) PASS"
    else
      print_err "Self-test (valid lines) FAIL"
      ok=1
    fi

    # Add an invalid key
    echo '{"type":"segment","name":"bad","ms":1,"phase":"post_plugin","sample":"x","ts":1690000009999,"secret":"oops"}' >> "$tmp"
    if "$0" --file "$tmp" --strict >/dev/null 2>&1; then
      print_err "Self-test (unknown key detection) FAIL"
      ok=1
    else
      print_info "Self-test (unknown key detection) PASS"
    fi

    rm -f "$tmp"
    exit $ok
  }
  run_self_test
fi

if (( USE_STDIN )); then
  if [[ -n "$INPUT_FILE" ]]; then
    print_err "--stdin and --file are mutually exclusive"
    exit 1
  fi
else
  if [[ -z "$INPUT_FILE" ]]; then
    print_err "Missing --file or --stdin"
    usage >&2
    exit 1
  fi
fi

# Allow environment override for evolution
: ${SCHEMA_SEGMENT_REQUIRED:="type name ms phase sample ts"}
: ${SCHEMA_SEGMENT_ALLOWED:="${SCHEMA_SEGMENT_REQUIRED}"}

typeset -a REQ_KEYS ALLOWED_KEYS
REQ_KEYS=(${=SCHEMA_SEGMENT_REQUIRED})
ALLOWED_KEYS=(${=SCHEMA_SEGMENT_ALLOWED})

# Add dynamic allowlist (future extensibility)
# Example: export SCHEMA_SEGMENT_ALLOWED="$SCHEMA_SEGMENT_ALLOWED extra_key"

is_in_list() {
  local needle=$1; shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

has_jq=0
if command -v jq >/dev/null 2>&1; then
  has_jq=1
fi

validate_segment_object() {
  # Input: raw JSON line (variable)
  local line="$1"
  local violations=()
  local key value

  # Basic quick filter
  [[ "$line" == *'"type":"segment"'* ]] || return 0

  # Use jq if available for robust extraction
  if (( has_jq )); then
    # Ensure parseable
    if ! echo "$line" | jq -e . >/dev/null 2>&1; then
      violations+=("invalid_json")
    else
      # Extract keys via jq
      local keys_raw
      keys_raw=($(echo "$line" | jq -r 'keys[]' 2>/dev/null || echo ""))
      local present=("${keys_raw[@]}")
      # Required keys present?
      for key in "${REQ_KEYS[@]}"; do
        is_in_list "$key" "${present[@]}" || violations+=("missing_required:${key}")
      done
      # Unknown keys?
      for key in "${present[@]}"; do
        if ! is_in_list "$key" "${ALLOWED_KEYS[@]}"; then
          if (( STRICT )) && (( ! ALLOW_EXTRA )); then
            violations+=("unknown_key:${key}")
          else
            print_warn "Unknown key (non-strict accepted): $key"
          fi
        fi
      done

      # Value validations
      local _type=$(echo "$line" | jq -r '.type // empty')
      local _name=$(echo "$line" | jq -r '.name // empty')
      local _ms=$(echo "$line" | jq -r '.ms // empty')
      local _phase=$(echo "$line" | jq -r '.phase // empty')
      local _sample=$(echo "$line" | jq -r '.sample // empty')
      local _ts=$(echo "$line" | jq -r '.ts // empty')

      [[ "$_type" == "segment" ]] || violations+=("bad_type:${_type:-<empty>}")

      [[ "$_name" =~ ^[a-z0-9._:/+-]+$ ]] || violations+=("bad_name:${_name}")
      [[ "$_ms" =~ ^[0-9]+$ ]] || violations+=("bad_ms_format:${_ms}")
      if [[ "$_ms" =~ ^[0-9]+$ ]]; then
        (( _ms >= 0 && _ms < 600000 )) || violations+=("ms_out_of_range:${_ms}")
      fi
      case "$_phase" in
        pre_plugin|post_plugin|prompt|postprompt|core) : ;;
        *) violations+=("bad_phase:${_phase}") ;;
      esac
      [[ "$_ts" =~ ^[0-9]{13}$ ]] || violations+=("bad_ts:${_ts}")

      # sample can be relaxed but enforce length & charset
      [[ "${#_sample}" -le 64 ]] || violations+=("sample_too_long:${#_sample}")
      [[ "$_sample" =~ ^[A-Za-z0-9._-]*$ ]] || violations+=("sample_charset:${_sample}")
    fi
  else
    # Fallback (no jq): approximate validation with pattern slicing
    # Extract key:value pairs with a conservative grep
    local kv keyset=()
    # Remove escaped quotes (simplistic)
    local stripped="${line//\\"/__ESC__}"
    # Iterate keys
    while [[ "$stripped" == *'"'*:* ]]; do
      kv="${stripped#*\"}"
      kv="${kv%%,*}"
      kv="${kv%%\}*}"
      key="${kv%%\"*}"
      keyset+=("$key")
      stripped="${stripped#*,$kv}"
      [[ "$stripped" == "$line" ]] && break
    done

    # Required keys
    for key in "${REQ_KEYS[@]}"; do
      local found=0 k
      for k in "${keyset[@]}"; do
        [[ "$k" == "$key" ]] && found=1
      done
      (( found )) || violations+=("missing_required:${key}")
    done

    # Unknown keys
    for key in "${keyset[@]}"; do
      if ! is_in_list "$key" "${ALLOWED_KEYS[@]}"; then
        if (( STRICT )) && (( ! ALLOW_EXTRA )); then
          violations+=("unknown_key:${key}")
        else
          print_warn "Unknown key (fallback parser, non-strict) key=${key}"
        fi
      fi
    done

    # Minimal value checks (regex approximations)
    [[ "$line" == *'"type":"segment"'* ]] || violations+=("bad_type_or_missing")
    if [[ "$line" =~ \"name\":\"([^\"]+)\" ]]; then
      local _name="${match[1]}"
      [[ "$_name" =~ ^[a-z0-9._:/+-]+$ ]] || violations+=("bad_name:${_name}")
    else
      violations+=("missing_name_value")
    fi
    if [[ "$line" =~ \"ms\":([0-9]+) ]]; then
      local _ms="${match[1]}"
      (( _ms >=0 && _ms < 600000 )) || violations+=("ms_out_of_range:${_ms}")
    else
      violations+=("missing_ms_value")
    fi
    if [[ "$line" =~ \"phase\":\"([^\"]+)\" ]]; then
      local _phase="${match[1]}"
      case "$_phase" in
        pre_plugin|post_plugin|prompt|postprompt|core) : ;;
        *) violations+=("bad_phase:${_phase}") ;;
      esac
    else
      violations+=("missing_phase_value")
    fi
    if [[ "$line" =~ \"ts\":([0-9]{13}) ]]; then
      : # ok
    else
      violations+=("bad_ts")
    fi
  fi

  if (( ${#violations[@]} > 0 )); then
    print_err "Segment schema violations: ${(j:, :)violations}"
    return 3
  else
    (( QUIET )) || print_info "segment OK name=$(echo "$line" | grep -oE '\"name\":\"[^\"]+\"' | head -n1 | cut -d: -f2- | tr -d '\"')"
  fi
  return 0
}

main() {
  local line n=0 rc overall_rc=0
  if (( USE_STDIN )); then
    while IFS= read -r line || [[ -n "$line" ]]; do
      (( MAX_LINES > 0 && n >= MAX_LINES )) && break
      (( n++ ))
      validate_segment_object "$line" || {
        rc=$?
        if (( rc == 3 )); then
          overall_rc=3
          (( STRICT )) || print_warn "Violation in non-strict mode (continuing)"
          (( STRICT )) && break
        elif (( rc > overall_rc )); then
          overall_rc=$rc
        fi
      }
    done
  else
    [[ -r "$INPUT_FILE" ]] || { print_err "File not readable: $INPUT_FILE"; exit 2; }
    while IFS= read -r line || [[ -n "$line" ]]; do
      (( MAX_LINES > 0 && n >= MAX_LINES )) && break
      (( n++ ))
      validate_segment_object "$line" || {
        rc=$?
        if (( rc == 3 )); then
          overall_rc=3
          (( STRICT )) || print_warn "Violation in non-strict mode (continuing)"
          (( STRICT )) && break
        elif (( rc > overall_rc )); then
          overall_rc=$rc
        fi
      }
    done < "$INPUT_FILE"
  fi

  if (( overall_rc == 0 )); then
    print_info "Validation complete: $n line(s) processed – OK"
  elif (( overall_rc == 3 )); then
    print_err "Validation failed (schema violations). Lines processed=$n"
  else
    print_warn "Validation completed with non-fatal issues (rc=$overall_rc). Lines processed=$n"
  fi
  return $overall_rc
}

main "$@"
