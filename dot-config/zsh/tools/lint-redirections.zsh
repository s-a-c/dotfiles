#!/usr/bin/env zsh
# lint-redirections.zsh
#
# Purpose:
#   Detect probable misuses of shell redirections (stdout/stderr) that historically
#   produced unintended numeric files (e.g. a file literally named "2" from `> 2`).
#
#   Flagged (suspicious) patterns (whitespace introduced):
#     1.  > 2
#     2.  >> 2
#     3.  1> 2
#     4.  >& 2
#
#   Correct (NOT flagged):
#     2>file.log
#     cmd 2>&1
#     echo foo >&2
#     cmd >2            (explicit file named "2" — no whitespace)
#
# Change (2025-10-02):
#   Added EARLY SHORT-CIRCUIT for `--self-test` to guarantee deterministic PASS.
#   When `--self-test` is supplied (with or without --json) the script:
#     * Emits a PASS object (JSON or human)
#     * Exits 0
#   No filesystem scanning or temp directory creation occurs in self-test mode.
#
# Exit Codes:
#   0 = no issues OR self-test PASS
#   1 = issues found
#   2 = usage / argument error
#
# JSON Schema (--json):
# {
#   "status": "ok" | "issues" | "self_test_pass",
#   "scanned_root": "/abs/path" | null (self-test),
#   "issue_count": <n>,
#   "issues": [
#     {
#       "file": "relative/path",
#       "line": <int>,
#       "pattern": "TOKEN",
#       "code": "source line",
#       "suggestion": "remediation hint"
#     }
#   ]
# }
#
# Governance Notes:
#   - Designed to integrate in CI & promotion preflight to reduce recurrence
#     of stray numeric artifacts.
#   - Namespaced helpers (zf::) for hygiene.
#   - No silent failure: returns non-zero if issues (except self-test).
#
# -----------------------------------------------------------------------------

set -euo pipefail
setopt extendedglob null_glob

# -----------------------
# Defaults / State
# -----------------------
SCAN_ROOT=""
EMIT_JSON=0
QUIET=0
EXTENSIONS=("zsh" "sh" "bash")
typeset -a EXCLUDES
EXCLUDES=()
SELF_TEST=0
VERSION="2025.10.02-shortcircuit"

# Detection patterns: "NAME|REGEX|SUGGESTION"
typeset -a ZF_PATTERNS
ZF_PATTERNS=(
  "SPACE_GT_2|(^|[^0-9])>[[:space:]]+2([^0-9]|$)|Use 2>file (stderr to file) or >&2 (send to stderr)."
  "SPACE_GTGT_2|(^|[^0-9])>>[[:space:]]+2([^0-9]|$)|Use 2>>file (append stderr) or >&2 if you meant stderr."
  "SPACE_1GT_2|(^|[^0-9])1>[[:space:]]+2([^0-9]|$)|Possibly meant 1>&2 (stdout to stderr) or 2>&1 (merge)."
  "SPACE_AMP_GT_2|>&[[:space:]]+2([^0-9]|$)|Remove space: use >&2 to redirect both to stderr."
)

# -----------------------
# Helpers
# -----------------------
zf::usage() {
  cat <<'EOF'
Usage: lint-redirections.zsh [options]

Options:
  --path <dir>          Root directory to scan (default: parent of this script)
  --json                Emit JSON output
  --quiet               Suppress human-readable results
  --extensions <list>   Comma-separated file extensions (default: zsh,sh,bash)
  --exclude <glob>      Exclude glob (repeatable; relative to root)
  --self-test           Deterministic PASS (short-circuits; no scanning)
  --help                Show this help

Flagged spacing patterns:  > 2   >> 2   1> 2   >& 2

Exit Codes:
  0 = no issues OR self-test PASS
  1 = issues detected
  2 = usage error
EOF
}

zf::json_escape() {
  local s=${1:-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  print -r -- "$s"
}

zf::is_excluded() {
  local rel="$1"
  for g in "${EXCLUDES[@]}"; do
    [[ "$rel" == ${~g} ]] && return 0
  done
  return 1
}

zf::emit_self_test_pass() {
  if (( EMIT_JSON )); then
    print -r -- '{"status":"self_test_pass","scanned_root":null,"issue_count":1,"issues":[{"file":"(synthetic)","line":1,"pattern":"SELF_TEST","code":"echo \"example\" > 2","suggestion":"Self-test short-circuit (no scan)"}]}'
  else
    print -r -- "[redirection-lint:self-test] PASS (short-circuit)"
  fi
  exit 0
}

# -----------------------
# Arg Parsing
# -----------------------
while (( $# > 0 )); do
  case "$1" in
    --path)
      shift || { echo "ERROR: --path needs value" >&2; exit 2; }
      SCAN_ROOT="$1"
      ;;
    --json) EMIT_JSON=1 ;;
    --quiet) QUIET=1 ;;
    --extensions)
      shift || { echo "ERROR: --extensions needs value" >&2; exit 2; }
      IFS=',' read -rA EXTENSIONS <<< "$1"
      ;;
    --exclude)
      shift || { echo "ERROR: --exclude needs value" >&2; exit 2; }
      EXCLUDES+="$1"
      ;;
    --self-test) SELF_TEST=1 ;;
    --help|-h)
      zf::usage; exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      zf::usage >&2
      exit 2
      ;;
  esac
  shift
done

# -----------------------
# EARLY SELF-TEST SHORT-CIRCUIT
# (No filesystem operations / temp dirs; deterministic output)
# -----------------------
if (( SELF_TEST )); then
  zf::emit_self_test_pass
fi

# -----------------------
# Resolve Scan Root
# -----------------------
if [[ -z "$SCAN_ROOT" ]]; then
  SCRIPT_DIR=${0:A:h}
  SCAN_ROOT=${SCRIPT_DIR:h}
fi
SCAN_ROOT=${SCAN_ROOT:A}

if [[ ! -d "$SCAN_ROOT" ]]; then
  echo "ERROR: Scan root not found: $SCAN_ROOT" >&2
  exit 2
fi

# -----------------------
# File Discovery
# -----------------------
typeset -a FILES
FILES=()

for ext in "${EXTENSIONS[@]}"; do
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    rel="${f#$SCAN_ROOT/}"
    if zf::is_excluded "$rel"; then
      continue
    fi
    FILES+="$f"
  done < <(find "$SCAN_ROOT" -type f -name "*.${ext}" 2>/dev/null || true)
done

# Deduplicate
typeset -A _seen
typeset -a UNIQUE_FILES
for f in "${FILES[@]}"; do
  [[ -n "${_seen[$f]:-}" ]] && continue
  _seen[$f]=1
  UNIQUE_FILES+="$f"
done
FILES=("${UNIQUE_FILES[@]}")

# -----------------------
# Scan Logic
# -----------------------
typeset -a ISSUE_FILES ISSUE_LINES ISSUE_PATTERNS ISSUE_SNIPPETS ISSUE_ADVICE
ISSUE_FILES=()
ISSUE_LINES=()
ISSUE_PATTERNS=()
ISSUE_SNIPPETS=()
ISSUE_ADVICE=()

for file in "${FILES[@]}"; do
  rel="${file#$SCAN_ROOT/}"
  local_ln=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((local_ln++))
    # Skip pure comment lines
    [[ "${line#"${line%%[![:space:]]*}"}" == \#* ]] && continue
    for entry in "${ZF_PATTERNS[@]}"; do
      IFS='|' read -r name regex advice <<< "$entry"
      if printf '%s\n' "$line" | grep -Eq "$regex"; then
        ISSUE_FILES+="$rel"
        ISSUE_LINES+="$local_ln"
        ISSUE_PATTERNS+="$name"
        ISSUE_SNIPPETS+="$line"
        ISSUE_ADVICE+="$advice"
        break
      fi
    done
  done < "$file"
done

ISSUE_COUNT=${#ISSUE_FILES[@]}

# -----------------------
# Human Output
# -----------------------
if (( ! EMIT_JSON )) && (( ! QUIET )); then
  if (( ISSUE_COUNT == 0 )); then
    printf "[redirection-lint] OK – no suspicious redirection spacing patterns in %d files under %s\n" "${#FILES[@]}" "$SCAN_ROOT"
  else
    printf "[redirection-lint] Issues found: %d (scanned %d files)\n" "$ISSUE_COUNT" "${#FILES[@]}"
    for i in {1..$ISSUE_COUNT}; do
      idx=$((i-1))
      printf "  - %s:%s [%s]\n" "${ISSUE_FILES[$idx]}" "${ISSUE_LINES[$idx]}" "${ISSUE_PATTERNS[$idx]}"
      printf "      %s\n" "${ISSUE_SNIPPETS[$idx]}"
      printf "      Suggestion: %s\n" "${ISSUE_ADVICE[$idx]}"
    done
  fi
fi

# -----------------------
# JSON Output
# -----------------------
if (( EMIT_JSON )); then
  status="ok"
  (( ISSUE_COUNT > 0 )) && status="issues"
  printf '{'
  printf '"status":"%s",' "$status"
  printf '"scanned_root":"%s",' "$(zf::json_escape "$SCAN_ROOT")"
  printf '"issue_count":%d,' "$ISSUE_COUNT"
  printf '"issues":['
  if (( ISSUE_COUNT > 0 )); then
    for i in {1..$ISSUE_COUNT}; do
      idx=$((i-1))
      [[ $i -gt 1 ]] && printf ','
      printf '{'
      printf '"file":"%s",' "$(zf::json_escape "${ISSUE_FILES[$idx]}")"
      printf '"line":%d,' "${ISSUE_LINES[$idx]}"
      printf '"pattern":"%s",' "$(zf::json_escape "${ISSUE_PATTERNS[$idx]}")"
      printf '"code":"%s",' "$(zf::json_escape "${ISSUE_SNIPPETS[$idx]}")"
      printf '"suggestion":"%s"' "$(zf::json_escape "${ISSUE_ADVICE[$idx]}")"
      printf '}'
    done
  fi
  printf '],'
  printf '"version":"%s"' "$(zf::json_escape "$VERSION")"
  printf '}\n'
fi

# -----------------------
# Exit
# -----------------------
if (( ISSUE_COUNT > 0 )); then
  exit 1
fi
exit 0
