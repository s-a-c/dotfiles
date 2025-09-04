#!/usr/bin/env zsh
# ============================================================================
# enforce-path-resolution.zsh
#
# Purpose:
#   Enforce the repository rule prohibiting direct usage of the brittle pattern
#       ${0:A:h}  (or lowercase ${0:a:h})
#   in Zsh scripts outside explicitly allowed contexts. This pattern is
#   discouraged because plugin managers (e.g. zgenom) or compilation / caching
#   phases can rewrite $0 and cause incorrect path resolution at runtime.
#
# Allowed / Ignored Contexts (by default):
#   - Test directories (paths containing /tests/) unless --include-tests specified.
#   - Documentation or markdown (docs/, *.md)
#   - Lines explicitly annotated with:  # ALLOW_0_A_H
#
# Preferred Replacement:
#   Use the resilient helpers introduced in .zshenv:
#       zf::script_dir [<path_or_script>]
#       resolve_script_dir [<path_or_script>]
#
# Output Modes:
#   - Human readable (default)
#   - JSON (--json) for CI consumption or badge generation
#
# Exit Codes:
#   0  No violations (or violations found but --fail-on-violation not given)
#   1  Violations found AND --fail-on-violation enabled
#   2  Usage / argument error
#   3  Internal error
#
# JSON Schema Example:
# {
#   "schema": "path-resolution-enforce.v1",
#   "root": "/abs/repo/root",
#   "scanned": 87,
#   "violations": 2,
#   "files": [
#     { "path":"dot-config/zsh/tools/foo.zsh","line":42,"match":"${0:A:h}","excerpt":"SCRIPT_DIR=\"${0:A:h}\"" }
#   ],
#   "recommendation": "Replace ${0:A:h} with zf::script_dir or resolve_script_dir"
# }
#
# Usage:
#   tools/enforce-path-resolution.zsh
#   tools/enforce-path-resolution.zsh --root . --json --fail-on-violation
#   tools/enforce-path-resolution.zsh --pattern '*.zsh,*.plugin.zsh'
#   tools/enforce-path-resolution.zsh --include-tests
#
# Options:
#   --root <dir>              Root directory to scan (defaults to git root or CWD)
#   --pattern <csv>           Comma list of filename globs (default: *.zsh)
#   --exclude-dirs <csv>      Comma list of directory globs to skip (default: .git,node_modules,vendor,dist,build,docs)
#   --include-tests           Include test directories in scan
#   --json                    Emit machine JSON output
#   --fail-on-violation       Exit 1 if violations detected
#   --max-files <N>           Safety cap on files scanned (default: 5000)
#   --quiet                   Suppress per-violation lines in human mode
#   --help | -h               Show help
#
# Environment Overrides:
#   ENFORCE_PATH_RESOLUTION_ROOT
#
# Notes:
#   - Only simple textual detection via grep; false positives are possible but
#     minimized with explicit allow comment marker.
#   - To suppress a legitimate usage (rare), add:  # ALLOW_0_A_H
#     on the same line (prefer refactor over suppressions).
#
# Style: 4-space indentation, POSIX-friendly where easily feasible (Zsh features minimal).
# ============================================================================

set -euo pipefail

SCRIPT_NAME="${0##*/}"

# Defaults
ROOT="${ENFORCE_PATH_RESOLUTION_ROOT:-}"
PATTERNS_CSV="*.zsh"
EXCLUDE_DIRS_CSV=".git,node_modules,vendor,dist,build,docs,.backups"
INCLUDE_TESTS=0
JSON_MODE=0
FAIL_ON=0
STRICT=0
QUIET=0
MAX_FILES=5000

# Storage
typeset -a PATTERNS
typeset -a EXCLUDES
typeset -a FILES
typeset -a VIOLATION_JSON_CHUNKS
typeset -i SCANNED=0
typeset -i VIOLATIONS=0

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
usage() {
    cat <<EOF
$SCRIPT_NAME - Enforce resilient path resolution (ban raw \${0:A:h})

Usage:
  $SCRIPT_NAME [options]

Options:
  --root <dir>              Root directory to scan (git root fallback)
  --pattern <csv>           Comma-separated file globs (default: *.zsh)
  --exclude-dirs <csv>      Comma-separated directory globs to exclude
                           (default: .git,node_modules,vendor,dist,build,docs,.backups)
  --include-tests           Include test directories (default skips /tests/)
  --json                    Emit JSON summary
  --fail-on-violation       Exit 1 if violations detected
  --strict                  Also flag raw ${(%):-%N:h} usage (strict mode). Suppress with # ALLOW_STRICT_PATH
  --max-files <N>           Limit number of files scanned (default 5000)
  --quiet                   Suppress per-violation human output
  --help | -h               Show help

Allowed Suppression:
  Add trailing comment '# ALLOW_0_A_H' on a line to skip flagging.

Recommendation:
  Replace \${0:A:h} with 'zf::script_dir "\${(%):-%N}"' or 'resolve_script_dir'.

Exit Codes:
  0 success / no (enforced) violations
  1 violations + --fail-on-violation
  2 argument error
  3 internal error
EOF
}

json_escape() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Resolve root
detect_root() {
    if [[ -n "$ROOT" ]]; then
        return 0
    fi
    if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
        ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
    else
        ROOT="$(pwd -P)"
    fi
}

split_csv() {
    local csv="$1"
    local -a out
    IFS=',' read -rA out <<<"$csv"
    print -r -- "${out[@]}"
}

is_excluded_dir() {
    local dir_rel="$1"
    local ex
    for ex in "${EXCLUDES[@]}"; do
        [[ -z "$ex" ]] && continue
        case "$dir_rel" in
            */"$ex"/*|"$ex"/*|*/"$ex"|"$ex") return 0 ;;
        esac
    done
    return 1
}

should_scan_file() {
    local rel="$1" base="${1##*/}" pat
    # Exclude directories patterns first
    is_excluded_dir "$rel" && return 1

    # Exclude tests unless included
    if (( INCLUDE_TESTS == 0 )); then
        case "$rel" in
            *"/tests/"*|*"/tests_"*|*/tests/*) return 1 ;;
        esac
    fi

    # Match patterns
    for pat in "${PATTERNS[@]}"; do
        case "$base" in
            $pat) return 0 ;;
        esac
    done
    return 1
}

scan_files() {
    local f rel
    for f in "${FILES[@]}"; do
        rel="${f#$ROOT/}"
        should_scan_file "$rel" || continue
        (( SCANNED++ ))
        # Safety cap
        if (( SCANNED > MAX_FILES )); then
            print -u2 "[enforce-path-resolution] Reached max file cap (${MAX_FILES}), stopping early."
            break
        fi
        scan_single_file "$f" "$rel"
    done
}

scan_single_file() {
    local abs="$1" rel="$2"
    local line_no=0
    local line
    # Grep first to skip reading when no match candidate
    if ! grep -q '\${0:[Aa]:h}' "$abs" 2>/dev/null; then
        return 0
    fi
    while IFS= read -r line; do
        (( line_no++ )) || true
        # Ignore comment-only lines (after trimming leading whitespace)
        if [[ "${line#"${line%%[![:space:]]*}"}" == \#* ]]; then
            continue
        fi
        # Fast filter
        case "$line" in
            *'${0:A:h}'*|*'${0:a:h}'*)
                # Allow suppression
                if [[ "$line" == *"ALLOW_0_A_H"* ]]; then
                    continue
                fi
                (( VIOLATIONS++ ))
                if (( JSON_MODE )); then
                    local match excerpt
                    if [[ "$line" == *'${0:A:h}'* ]]; then
                        match='${0:A:h}'
                    else
                        match='${0:a:h}'
                    fi
                    excerpt="$(printf '%s' "$line" | head -c 200 | json_escape)"
                    VIOLATION_JSON_CHUNKS+=("{\"path\":\"$(printf '%s' "$rel" | json_escape)\",\"line\":$line_no,\"match\":\"$(printf '%s' "$match" | json_escape)\",\"excerpt\":\"$excerpt\"}")
                else
                    if (( QUIET == 0 )); then
                        printf '[VIOLATION] %s:%d -> %s\n' "$rel" "$line_no" "$line"
                    fi
                fi
                ;;
        esac
        # Strict mode: flag raw ${(%):-%N:h} usages (except when suppressed)
        if (( STRICT == 1 )); then
            if [[ "$line" == *'${(%):-%N:h}'* ]] && [[ "$line" != *'ALLOW_STRICT_PATH'* ]]; then
                (( VIOLATIONS++ ))
                if (( JSON_MODE )); then
                    local excerpt
                    excerpt="$(printf '%s' "$line" | head -c 200 | json_escape)"
                    VIOLATION_JSON_CHUNKS+=("{\"path\":\"$(printf '%s' "$rel" | json_escape)\",\"line\":$line_no,\"match\":\"\${(%):-%N:h}\",\"excerpt\":\"$excerpt\"}")
                else
                    if (( QUIET == 0 )); then
                        printf '[VIOLATION][STRICT] %s:%d -> %s\n' "$rel" "$line_no" "$line"
                    fi
                fi
            fi
        fi
    done < "$abs"
}

emit_json() {
    local rec_json
    local files_json="[]"
    if (( ${#VIOLATION_JSON_CHUNKS[@]} > 0 )); then
        files_json="[$(printf '%s\n' "${VIOLATION_JSON_CHUNKS[@]}" | paste -sd',' -)]"
    fi
    rec_json="Replace \${0:A:h} with zf::script_dir or resolve_script_dir"
    printf '{\n'
    printf '  "schema": "path-resolution-enforce.v1",\n'
    printf '  "root": "%s",\n' "$(printf '%s' "$ROOT" | json_escape)"
    printf '  "scanned": %d,\n' "$SCANNED"
    printf '  "violations": %d,\n' "$VIOLATIONS"
    printf '  "files": %s,\n' "$files_json"
    printf '  "recommendation": "%s"\n' "$(printf '%s' "$rec_json" | json_escape)"
    printf '}\n'
}

emit_human_summary() {
    printf '\nPath Resolution Enforcement Summary\n'
    printf '  Root:        %s\n' "$ROOT"
    printf '  Scanned:     %d files\n' "$SCANNED"
    printf '  Violations:  %d\n' "$VIOLATIONS"
    if (( VIOLATIONS > 0 )); then
        printf '  Recommendation: Replace ${0:A:h} with zf::script_dir or resolve_script_dir\n'
    else
        printf '  Status:      CLEAN\n'
    fi
}

# -----------------------------------------------------------------------------
# Argument Parsing
# -----------------------------------------------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --root) shift || { usage >&2; exit 2; }; ROOT="$1" ;;
        --pattern) shift || { usage >&2; exit 2; }; PATTERNS_CSV="$1" ;;
        --exclude-dirs) shift || { usage >&2; exit 2; }; EXCLUDE_DIRS_CSV="$1" ;;
        --include-tests) INCLUDE_TESTS=1 ;;
        --json) JSON_MODE=1 ;;
        --fail-on-violation) FAIL_ON=1 ;;
        --max-files) shift || { usage >&2; exit 2; }; MAX_FILES="${1:-5000}" ;;
        --quiet) QUIET=1 ;;
        --help|-h) usage; exit 0 ;;
        *)
            printf '[enforce-path-resolution] Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

detect_root

# Normalize & build pattern arrays
PATTERNS=("${(@f)$(split_csv "$PATTERNS_CSV")}")
EXCLUDES=("${(@f)$(split_csv "$EXCLUDE_DIRS_CSV")}")

# Gather candidate files (zsh globbing safer & faster)
# Use **/* patterns then filter by PATTERNS later
setopt extended_glob null_glob 2>/dev/null || true
FILES=("$ROOT"/**/*(.N))
unsetopt null_glob 2>/dev/null || true

# -----------------------------------------------------------------------------
# Execution
# -----------------------------------------------------------------------------
scan_files || { printf '[enforce-path-resolution] Internal scanning error\n' >&2; exit 3; }

if (( JSON_MODE )); then
    emit_json
else
    emit_human_summary
fi

# -----------------------------------------------------------------------------
# Exit handling
# -----------------------------------------------------------------------------
if (( VIOLATIONS > 0 && FAIL_ON == 1 )); then
    exit 1
fi
exit 0
