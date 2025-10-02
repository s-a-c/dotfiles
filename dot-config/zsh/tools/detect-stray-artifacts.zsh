#!/usr/bin/env zsh
# detect-stray-artifacts.zsh
#
# Purpose:
#   Detect unintended numeric (pure-integer) directories or files at the
#   top level of the active ZSH configuration root (default: directory
#   containing this script's parent, typically .../dot-config/zsh).
#
#   Historical issue: stray artifacts "0" (directory) and "2" (file) were
#   created due to variable path substitution / misdirected redirection.
#
# Detection Rules:
#   - Any immediate child whose basename matches ^[0-9]+$ is a violation
#     unless explicitly allowlisted.
#   - Only top-level (maxdepth 1) entries are evaluated.
#
# Features:
#   - JSON output (--json)
#   - Custom scan path (--path)
#   - Allowlist entries (--allow <name>) (repeatable)
#   - Quiet mode (--quiet) suppresses human output (JSON unaffected)
#   - Optional fail-on-empty-scan directory guard
#
# Exit Codes:
#   0 = no violations
#   1 = violations discovered
#   2 = usage error
#
# JSON Schema Example:
# {
#   "status":"violations",
#   "scanned_path":"/abs/path/zsh",
#   "violations":[
#     {"type":"directory","name":"0","reason":"numeric_root_entry"},
#     {"type":"file","name":"2","reason":"numeric_root_entry"}
#   ],
#   "allowlist":["123"],
#   "count":2
# }
#
# Governance:
#   Integrate into CI prior to snapshot / promotion. Any violation requires
#   explicit remediation or documented exception with a governance note.
#
# Implementation Notes:
#   - Pure zsh, no external JSON tooling required.
#   - Namespaced helper functions with zf:: prefix.
#
# -----------------------------------------------------------------------------

set -euo pipefail
setopt extendedglob null_glob

zf::usage() {
  cat <<'EOF'
Usage: detect-stray-artifacts.zsh [options]

Options:
  --json                 Emit JSON summary
  --quiet                Suppress human-readable output (non-zero exit still signals issues)
  --path <dir>           Path to scan (default: parent directory of this script)
  --allow <name>         Allowlist a numeric entry (repeatable)
  --fail-on-missing      Fail (exit 2) if --path does not exist
  --help                 Show this help

Examples:
  detect-stray-artifacts.zsh
  detect-stray-artifacts.zsh --json
  detect-stray-artifacts.zsh --path ./zsh --allow 2024

Exit Codes:
  0 OK (no violations)
  1 Violations detected
  2 Usage / path error
EOF
}

# ---------------------------
# Argument Parsing
# ---------------------------
JSON=0
QUIET=0
FAIL_ON_MISSING=0
SCAN_PATH=""
typeset -a ALLOWLIST
ALLOWLIST=()

# Refactored robust argument parser (added --self-test)
while [[ $# -gt 0 ]]; do
  opt="${1%$'\r'}"
  shift
  case "$opt" in
    --json)
      JSON=1
      ;;
    --quiet)
      QUIET=1
      ;;
    --path)
      [[ $# -gt 0 ]] || { echo "ERROR: --path requires a value" >&2; exit 2; }
      SCAN_PATH="$1"; shift
      ;;
    --allow)
      [[ $# -gt 0 ]] || { echo "ERROR: --allow requires a value" >&2; exit 2; }
      ALLOWLIST+="$1"; shift
      ;;
    --fail-on-missing)
      FAIL_ON_MISSING=1
      ;;
    --self-test)
      ZF_SELF_TEST=1
      ;;
    --help|-h)
      zf::usage; exit 0
      ;;
    *)
      # If an empty (whitespace) arg sneaks in, ignore once; otherwise error
      if [[ -z "${opt//[[:space:]]/}" ]]; then
        continue
      fi
      echo "ERROR: Unknown argument: $opt" >&2
      zf::usage >&2
      exit 2
      ;;
  esac
done

# ---------------------------
# Resolve Scan Directory
# ---------------------------
if [[ -z "$SCAN_PATH" ]]; then
  # Script dir -> parent (expecting .../zsh/tools -> .../zsh)
  SCRIPT_DIR=${0:A:h}
  SCAN_PATH=${SCRIPT_DIR:h}
fi

if [[ ! -d "$SCAN_PATH" ]]; then
  if (( FAIL_ON_MISSING )); then
    if (( JSON )); then
      printf '{"status":"error","error":"scan_path_missing","path":"%s"}\n' "${SCAN_PATH//\"/\\\"}"
    else
      echo "ERROR: Scan path missing: $SCAN_PATH" >&2
    fi
    exit 2
  else
    # Treat as empty (no violations)
    if (( JSON )); then
      printf '{"status":"ok","scanned_path":"%s","violations":[],"allowlist":[],"count":0}\n' "${SCAN_PATH//\"/\\\"}"
    else
      (( QUIET )) || echo "[stray] Scan path not found; treating as OK: $SCAN_PATH"
    fi
    exit 0
  fi
fi

# Normalize absolute path
SCAN_PATH=${SCAN_PATH:A}

# ---------------------------
# Helpers
# ---------------------------
zf::in_allowlist() {
  local name=$1
  for a in "${ALLOWLIST[@]}"; do
    [[ "$a" == "$name" ]] && return 0
  done
  return 1
}

zf::json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  print -r -- "$s"
}

# ---------------------------
# Self Test (invoked with --self-test)
# ---------------------------
zf::self_test() {
  local tmp
  tmp="$(mktemp -d)"
  (
    cd "$tmp" || exit 1
    mkdir 00 2>/dev/null || true   # should be flagged (directory "00")
    : > 3                           # should be flagged (file "3")
  )
  SCAN_PATH="$tmp"
  # Continue into normal scan; expect violations >=1
}

if [[ "${ZF_SELF_TEST:-0}" == "1" ]]; then
  zf::self_test
fi

# ---------------------------
# Scan
# ---------------------------
typeset -a VIOLATION_NAMES VIOLATION_TYPES VIOLATION_REASONS
VIOLATION_NAMES=()
VIOLATION_TYPES=()
VIOLATION_REASONS=()

# Only immediate entries
for entry in "$SCAN_PATH"/*(N); do
  base=${entry:t}
  # Match pure number
  if [[ "$base" =~ '^[0-9]+$' ]]; then
    if zf::in_allowlist "$base"; then
      continue
    fi
    if [[ -d "$entry" ]]; then
      VIOLATION_TYPES+="directory"
    else
      VIOLATION_TYPES+="file"
    fi
    VIOLATION_NAMES+="$base"
    VIOLATION_REASONS+="numeric_root_entry"
  fi
done

VIOLATION_COUNT=${#VIOLATION_NAMES[@]}

# ---------------------------
# Reporting (Human)
# ---------------------------
if (( ! JSON )) && (( ! QUIET )); then
  if (( VIOLATION_COUNT == 0 )); then
    echo "[stray] OK – no numeric root artifacts in: $SCAN_PATH"
  else
    echo "[stray] Violations detected ($VIOLATION_COUNT) in: $SCAN_PATH"
    # Arrays in zsh are 1-based; iterate directly without subtracting
    for i in {1..$VIOLATION_COUNT}; do
      printf "  - %s: %s (reason=%s)\n" "${VIOLATION_TYPES[$i]}" "${VIOLATION_NAMES[$i]}" "${VIOLATION_REASONS[$i]}"
    done
  fi
fi

# ---------------------------
# Reporting (JSON)
# ---------------------------
if (( JSON )); then
  result_status="ok"
  if (( VIOLATION_COUNT > 0 )); then
    if [[ "${ZF_SELF_TEST:-0}" == "1" ]]; then
      result_status="self_test_pass"
    else
      result_status="violations"
    fi
  fi
  printf '{'
  printf '"status":"%s",' "$result_status"
  printf '"scanned_path":"%s",' "$(zf::json_escape "$SCAN_PATH")"
  printf '"violations":['
  if (( VIOLATION_COUNT > 0 )); then
    for i in {1..$VIOLATION_COUNT}; do
      [[ $i -gt 1 ]] && printf ','
      printf '{"type":"%s","name":"%s","reason":"%s"}' \
        "$(zf::json_escape "${VIOLATION_TYPES[$i]-}")" \
        "$(zf::json_escape "${VIOLATION_NAMES[$i]-}")" \
        "$(zf::json_escape "${VIOLATION_REASONS[$i]-}")"
    done
  fi
  printf '],'
  printf '"allowlist":['
  if (( ${#ALLOWLIST[@]} )); then
    first=1
    for a in "${ALLOWLIST[@]}"; do
      [[ $first -eq 0 ]] && printf ','
      printf '"%s"' "$(zf::json_escape "$a")"
      first=0
    done
  fi
  printf '],'
  printf '"count":%d' "$VIOLATION_COUNT"
  if [[ "${ZF_SELF_TEST:-0}" == "1" ]]; then
    printf ',"self_test":true,"expected_violations":%s' "$([[ $VIOLATION_COUNT -gt 0 ]] && echo true || echo false)"
  fi
  printf '}\n'
fi

# ---------------------------
# Exit
# ---------------------------
if (( VIOLATION_COUNT > 0 )); then
  # In self-test JSON mode we already encoded pass; treat as success.
  if [[ "${ZF_SELF_TEST:-0}" == "1" && "${JSON}" -eq 1 ]]; then
    exit 0
  fi
  exit 1
fi
# No violations case:
if [[ "${ZF_SELF_TEST:-0}" == "1" && "${JSON}" -eq 1 ]]; then
  # Self-test expected violations; absence indicates failure (single JSON already emitted with count=0)
  exit 1
fi
exit 0
