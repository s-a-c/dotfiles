#!/usr/bin/env bash
# guidelines-checksum.sh
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v50b6b88e7dea25311b5e28879c90b857ba9f1c4b0bc974a72f6b14bc68d54f49
#
# PURPOSE:
#   Compute the composite guidelines checksum required by orchestration / policy
#   enforcement (see zsh/AGENT.md). The checksum is the SHA‑256 of the ordered
#   concatenation of:
#     1. guidelines.md
#     2. Every regular file under guidelines/** (recursive), path‑sorted (C locale)
#
# OUTPUT (default):
#   Prints the 64‑char hexadecimal checksum to stdout (no trailing text).
#
# OPTIONS:
#   --json              Emit JSON with checksum + metadata.
#   --paths             Print the ordered file list (one per line) to stderr (or
#                       include in JSON when combined with --json).
#   --verify <file>     Scan the target file for a compliance header line of the form:
#                         Compliant with ... guidelines.md) v<checksum>
#                       and compare to current composite checksum. Exit 0 if match,
#                       2 if mismatch, 3 if header missing/malformed.
#   --full              When used with --json include guidelinesPaths array (may be large).
#   --help              Display usage.
#
# EXIT CODES:
#   0 success (or verify match)
#   1 general error (I/O, hashing)
#   2 verify mismatch
#   3 verify header missing / malformed
#
# ENV OVERRIDES:
#   AI_GUIDELINES_ROOT   Root directory containing guidelines.md and guidelines/ (default:
#                        auto-resolved relative to this script: ../../ai)
#
# SECURITY / POLICY ALIGNMENT:
#   - Uses only standard POSIX tooling plus one hashing utility (shasum | sha256sum | openssl).
#   - No network access; read-only.
#   - Stable ordering enforced via LC_ALL=C sort for reproducibility / drift detection.
#
# EXAMPLES:
#   ./guidelines-checksum.sh
#   ./guidelines-checksum.sh --json --full
#   ./guidelines-checksum.sh --paths >/dev/null
#   ./guidelines-checksum.sh --verify dotfiles/dot-config/zsh/.zshrc
#
set -euo pipefail

# ---------- Utility: print usage ----------
usage() {
  sed -n '1,/^set -euo pipefail/d;/^# EXAMPLES:/,/^set -euo pipefail/p' "$0" >/dev/null 2>&1 || true
  cat <<'EOF'
Usage: guidelines-checksum.sh [--json] [--paths] [--full] [--verify <file>]

Compute composite checksum of guidelines policy sources.

Options:
  --json            Emit JSON metadata.
  --paths           List ordered file paths (stderr). With --json and --full they also appear in JSON.
  --full            Include guidelinesPaths array in JSON (suppressed otherwise to keep output small).
  --verify <file>   Check compliance header in <file> matches current checksum.
  --help            Show this help text.

Exit codes:
  0 success / verify OK
  1 error
  2 verify mismatch
  3 verify header missing or malformed
EOF
}

# ---------- Resolve root paths ----------
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-${0}}")" && pwd)"
# tools directory -> zsh -> dot-config -> ai
default_ai_root="$(cd "${script_dir}/../.." && pwd)/ai"
AI_GUIDELINES_ROOT="${AI_GUIDELINES_ROOT:-$default_ai_root}"
master_file="${AI_GUIDELINES_ROOT}/guidelines.md"
modules_dir="${AI_GUIDELINES_ROOT}/guidelines"

if [[ ! -f "$master_file" ]]; then
  echo "ERROR: master guidelines file not found: $master_file" >&2
  exit 1
fi
if [[ ! -d "$modules_dir" ]]; then
  echo "ERROR: guidelines directory not found: $modules_dir" >&2
  exit 1
fi

# ---------- Option parsing ----------
want_json=0
want_paths=0
want_full=0
verify_target=""

while (( $# )); do
  case "$1" in
    --json) want_json=1 ;;
    --paths) want_paths=1 ;;
    --full) want_full=1 ;;
    --verify)
      shift || { echo "ERROR: --verify requires a file path" >&2; exit 1; }
      verify_target="$1"
      ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) echo "ERROR: Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

# ---------- Collect ordered file list ----------
# Enforce deterministic ordering: master file first, then sorted module files
LC_ALL=C
export LC_ALL
mapfile -t module_files < <(find "$modules_dir" -type f -print | sed 's#^\./##' | sort)
ordered_files=("$master_file")
# Append module files
for f in "${module_files[@]}"; do
  ordered_files+=("$f")
done

# ---------- Hash implementation selection ----------
hash_cmd=""
if command -v shasum >/dev/null 2>&1; then
  hash_cmd="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  hash_cmd="sha256sum"
elif command -v openssl >/dev/null 2>&1; then
  hash_cmd="openssl dgst -sha256"
else
  echo "ERROR: Could not find shasum, sha256sum, or openssl for hashing" >&2
  exit 1
fi

# ---------- Compute checksum ----------
# Concatenate in-memory to avoid race; preserve file order strictly
checksum_tmp=""
# shellcheck disable=SC2068
if [[ "$hash_cmd" == "openssl dgst -sha256" ]]; then
  # openssl prints: (stdin)= <hash>
  checksum_tmp=$(cat "${ordered_files[@]}" | openssl dgst -sha256 | awk '{print $2}')
else
  checksum_tmp=$(cat "${ordered_files[@]}" | $hash_cmd | awk '{print $1}')
fi

if [[ ${#checksum_tmp} -ne 64 ]]; then
  echo "ERROR: Unexpected checksum length (${#checksum_tmp}), want 64" >&2
  exit 1
fi
composite_checksum="$checksum_tmp"

# ---------- Metadata: modification times ----------
# Portable stat wrapper
stat_mtime() {
  local path="$1"
  if command -v stat >/dev/null 2>&1; then
    if stat -f '%m' "$path" >/dev/null 2>&1; then
      stat -f '%m' "$path"
    else
      stat -c '%Y' "$path"
    fi
  else
    # Fallback: use perl if available
    perl -e 'print((stat($ARGV[0]))[9])' "$path" 2>/dev/null || echo 0
  fi
}

master_mtime=$(stat_mtime "$master_file")
modules_max_mtime=0
for f in "${module_files[@]}"; do
  mt=$(stat_mtime "$f")
  (( mt > modules_max_mtime )) && modules_max_mtime=$mt
done

# ---------- Verification mode ----------
if [[ -n "$verify_target" ]]; then
  if [[ ! -f "$verify_target" ]]; then
    echo "ERROR: verify target not found: $verify_target" >&2
    exit 1
  fi
  # Extract first matching compliance line
  header_line=$(grep -E 'Compliant with .+guidelines\.md.* v[0-9a-f]{64}' "$verify_target" | head -1 || true)
  if [[ -z "$header_line" ]]; then
    echo "VERIFY: MISSING compliance header in $verify_target" >&2
    exit 3
  fi
  found_checksum=$(echo "$header_line" | sed -n 's/.* v\([0-9a-f]\{64\}\).*/\1/p')
  if [[ -z "$found_checksum" ]]; then
    echo "VERIFY: MALFORMED header (no checksum) in $verify_target" >&2
    exit 3
  fi
  if [[ "$found_checksum" == "$composite_checksum" ]]; then
    echo "VERIFY: OK $verify_target (checksum $composite_checksum)"
    exit 0
  else
    echo "VERIFY: MISMATCH $verify_target"
    echo "  expected: $composite_checksum"
    echo "  found:    $found_checksum"
    exit 2
  fi
fi

# ---------- Optional path listing ----------
if (( want_paths )); then
  {
    echo "# Ordered guideline source files:"
    for f in "${ordered_files[@]}"; do
      printf '%s\n' "$f"
    done
  } >&2
fi

# ---------- JSON output ----------
if (( want_json )); then
  # ISO8601 timestamp
  iso_ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
  file_count=${#ordered_files[@]}

  # Build JSON (minimal escaping: file paths assumed safe)
  printf '{'
  printf '"checksum":"%s",' "$composite_checksum"
  printf '"fileCount":%s,' "$file_count"
  printf '"masterFile":"%s",' "$master_file"
  printf '"modulesDir":"%s",' "$modules_dir"
  printf '"masterMTime":%s,' "$master_mtime"
  printf '"modulesMaxMTime":%s,' "$modules_max_mtime"
  printf '"generatedAt":"%s",' "$iso_ts"
  printf '"toolVersion":1'
  if (( want_full )); then
    printf ',"guidelinesPaths":['
    first=1
    for f in "${ordered_files[@]}"; do
      if (( first )); then first=0; else printf ','; fi
      printf '"%s"' "$f"
    done
    printf ']'
  fi
  printf '}\n'
else
  # Plain checksum
  printf '%s\n' "$composite_checksum"
fi

exit 0
