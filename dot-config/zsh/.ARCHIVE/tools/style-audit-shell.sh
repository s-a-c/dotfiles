#!/usr/bin/env bash
# ============================================================================
# style-audit-shell.sh
#
# Purpose:
#   Repo‑wide lightweight shell style audit focusing on:
#     * Trailing whitespace
#     * Indentation style (tabs vs spaces)
#     * Indentation width consistency (default 4 spaces)
#     * Mixed indentation (tabs+spaces prefix on same line)
#     * Optional final newline + trailing whitespace auto-fix
#
# Scope:
#   Targets textual source files (default: *.sh, *.zsh, *.bash, shell-related
#   helper scripts, and generic config files) while skipping common third‑party
#   / build artifact directories.
#
# Why:
#   Enforces convergent style early (fast feedback, low noise) instead of
#   deferring to later CI phases; keeps diffs clean and predictable.
#
# Features:
#   - Zero external deps (awk / sed / grep / find / bash only)
#   - Supports JSON summary output
#   - Fast path filtering with include & exclude globs
#   - Optional in-place fixes (trailing spaces + ensure final newline)
#   - Configurable indent expectations & allowed tab files
#
# Style:
#   Indent size: 4
#   Indent style: spaces (except Makefiles or user-specified allowlist)
#
# Exit Codes:
#   0  No violations (or suppressed with --no-fail)
#   1  Violations detected (default)
#   2  Misconfiguration / argument error
#
# ----------------------------------------------------------------------------
# Default Configuration (overridable via flags / env)
# ----------------------------------------------------------------------------
#   SHELL_AUDIT_ROOT          Root to scan (default: git top-level or script dir)
#   SHELL_AUDIT_INCLUDE       Comma list override of inclusion globs
#   SHELL_AUDIT_EXCLUDE       Comma list override of exclusion globs
#   SHELL_AUDIT_INDENT_SIZE   Default indent size (default: 4)
#   SHELL_AUDIT_ALLOW_TABS    Comma list of exact filenames allowed to use tabs
#
# ----------------------------------------------------------------------------
# Examples:
#   ./tools/style-audit-shell.sh
#   ./tools/style-audit-shell.sh --json --output style-audit.json
#   ./tools/style-audit-shell.sh --fix-trailing --fix-final-newline
#   ./tools/style-audit-shell.sh --include '*.sh,*.zsh' --exclude 'vendor/*,dist/*'
#   INDENT_SIZE=2 ./tools/style-audit-shell.sh
#
# JSON Output Example:
# {
#   "schema":"shell-style-audit.v1",
#   "scanned_files":42,
#   "violations_total":7,
#   "trailing_space":3,
#   "tab_indent":2,
#   "mixed_indent":1,
#   "indent_width":1,
#   "fixed_trailing":3,
#   "fixed_final_newline":2,
#   "duration_ms":12
# }
# ============================================================================

set -euo pipefail

SCRIPT_NAME="${0##*/}"

# ---------------------------- Defaults ---------------------------------------
ROOT="${SHELL_AUDIT_ROOT:-}"
INCLUDE_GLOBS_DEFAULT="*.sh,*.zsh,*.bash,*.env,*.ksh,*.mk,*.tmux.conf,*.zprofile,*.zlogin,*.zlogout"
EXCLUDE_GLOBS_DEFAULT=".git/*,node_modules/*,vendor/*,dist/*,build/*,.cache/*,.venv/*,*.min.js,*.min.css"
INCLUDE_GLOBS="${SHELL_AUDIT_INCLUDE:-$INCLUDE_GLOBS_DEFAULT}"
EXCLUDE_GLOBS="${SHELL_AUDIT_EXCLUDE:-$EXCLUDE_GLOBS_DEFAULT}"

INDENT_SIZE="${SHELL_AUDIT_INDENT_SIZE:-${INDENT_SIZE:-4}}"
ALLOW_TABS_CSV="${SHELL_AUDIT_ALLOW_TABS:-Makefile,makefile,Makefile.in}"

OUTPUT_FILE=""
JSON_MODE=0
NO_FAIL=0
SHOW_STATS=1
FIX_TRAILING=0
FIX_FINAL_NEWLINE=0
QUIET=0
COLOR=1

# ---------------------------- Utilities --------------------------------------
usage() {
    cat <<EOF
$SCRIPT_NAME - Shell style audit (indent, trailing spaces, tabs)

Usage:
  $SCRIPT_NAME [options]

Options:
  --root <dir>              Root directory to scan (auto-detect via git if omitted)
  --include <csv>           Comma list of inclusion globs (default: $INCLUDE_GLOBS_DEFAULT)
  --exclude <csv>           Comma list of exclusion globs (default: $EXCLUDE_GLOBS_DEFAULT)
  --indent-size <N>         Expected indentation multiple (default: $INDENT_SIZE)
  --allow-tabs <csv>        Filenames allowed to use tab indentation (default: $ALLOW_TABS_CSV)
  --json                    Emit JSON summary
  --output <file>           Write JSON / text summary to file
  --no-fail                 Always exit 0 (informational mode)
  --quiet                   Suppress per-violation lines (summary only)
  --no-color                Disable ANSI colors
  --fix-trailing            Remove trailing whitespace in-place
  --fix-final-newline       Ensure file ends with exactly one newline
  --no-stats                Suppress summary block (with text mode)
  --help                    Show help

Environment Overrides:
  SHELL_AUDIT_ROOT, SHELL_AUDIT_INCLUDE, SHELL_AUDIT_EXCLUDE,
  SHELL_AUDIT_INDENT_SIZE, SHELL_AUDIT_ALLOW_TABS

Exit Codes:
  0 success / no violations (or --no-fail)
  1 violations detected
  2 argument or configuration error

Examples:
  $SCRIPT_NAME --json --output audit.json
  $SCRIPT_NAME --fix-trailing --fix-final-newline
EOF
}

err() { printf '%s\n' "[ERROR] $*" >&2; }
warn() { printf '%s\n' "[WARN]  $*" >&2; }
info() { (( QUIET )) || printf '%s\n' "[INFO]  $*"; }

is_number() { [[ "$1" =~ ^[0-9]+$ ]]; }
trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

color_wrap() {
    local code="$1"; shift
    if (( COLOR )); then
        printf "\033[%sm%s\033[0m" "$code" "$*"
    else
        printf "%s" "$*"
    fi
}

red() { color_wrap "31" "$*"; }
yellow() { color_wrap "33" "$*"; }
green() { color_wrap "32" "$*"; }

# ---------------------- Argument Parsing -------------------------------------
while (( $# > 0 )); do
    case "$1" in
        --root)
            shift || { err "Missing value after --root"; exit 2; }
            ROOT="$1"
            ;;
        --include)
            shift || { err "Missing value after --include"; exit 2; }
            INCLUDE_GLOBS="$1"
            ;;
        --exclude)
            shift || { err "Missing value after --exclude"; exit 2; }
            EXCLUDE_GLOBS="$1"
            ;;
        --indent-size)
            shift || { err "Missing value after --indent-size"; exit 2; }
            INDENT_SIZE="$1"
            ;;
        --allow-tabs)
            shift || { err "Missing value after --allow-tabs"; exit 2; }
            ALLOW_TABS_CSV="$1"
            ;;
        --json) JSON_MODE=1 ;;
        --output)
            shift || { err "Missing value after --output"; exit 2; }
            OUTPUT_FILE="$1"
            ;;
        --no-fail) NO_FAIL=1 ;;
        --fix-trailing) FIX_TRAILING=1 ;;
        --fix-final-newline) FIX_FINAL_NEWLINE=1 ;;
        --quiet) QUIET=1 ;;
        --no-stats) SHOW_STATS=0 ;;
        --no-color) COLOR=0 ;;
        --help|-h) usage; exit 0 ;;
        *)
            err "Unknown argument: $1"
            usage
            exit 2
            ;;
    esac
    shift
done

if ! is_number "$INDENT_SIZE" || (( INDENT_SIZE < 1 || INDENT_SIZE > 16 )); then
    err "Invalid --indent-size (must be 1-16): $INDENT_SIZE"
    exit 2
fi

# ---------------------- Root Resolution --------------------------------------
if [[ -z "$ROOT" ]]; then
    if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
        ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    fi
fi
if [[ -z "$ROOT" ]]; then
    ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
fi
if [[ ! -d "$ROOT" ]]; then
    err "Resolved root is not a directory: $ROOT"
    exit 2
fi

# Normalize root path
ROOT="$(cd "$ROOT" && pwd -P)"

# ---------------------- Build Find Command -----------------------------------
IFS=',' read -r -a include_arr <<<"$INCLUDE_GLOBS"
IFS=',' read -r -a exclude_arr <<<"$EXCLUDE_GLOBS"
IFS=',' read -r -a allow_tabs_arr <<<"$ALLOW_TABS_CSV"

declare -A allow_tabs_map
for f in "${allow_tabs_arr[@]}"; do
    f="$(echo "$f" | trim)"
    [[ -n "$f" ]] && allow_tabs_map["$f"]=1
done

# Construct find predicates
find_cmd=(find "$ROOT" -type f)
# Exclusions
for ex in "${exclude_arr[@]}"; do
    ex="$(echo "$ex" | trim)"
    [[ -z "$ex" ]] && continue
    # Convert simple glob to -path match
    find_cmd+=(-not -path "$ROOT/$ex")
done

# We'll first collect all candidate files, then filter by include globs manually
mapfile -t all_files < <("${find_cmd[@]}" 2>/dev/null || true)

# ---------------------- File Filtering ---------------------------------------
should_include() {
    local path="$1" b rel
    b="$(basename "$path")"
    rel="${path#$ROOT/}"
    for g in "${include_arr[@]}"; do
        g="$(echo "$g" | trim)"
        [[ -z "$g" ]] && continue
        case "$b" in
            "$g") return 0 ;;
        esac
        case "$rel" in
            "$g") return 0 ;;
        esac
    done
    return 1
}

# Filter text-like quickly (skip binaries)
is_text_file() {
    local f="$1"
    # Heuristic: if file contains a NUL byte, treat as binary
    if LC_ALL=C grep -Il . "$f" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

declare -a target_files
for f in "${all_files[@]}"; do
    [[ -f "$f" ]] || continue
    should_include "$f" || continue
    is_text_file "$f" || continue
    target_files+=("$f")
done

# ---------------------- Audit Pass -------------------------------------------
viol_trailing=0
viol_tab_indent=0
viol_mixed_indent=0
viol_indent_width=0
files_scanned=0

fixed_trailing=0
fixed_final_newline=0

declare -a report_lines

audit_file() {
    local file="$1"
    (( files_scanned++ ))
    local bn="${file##*/}"
    local allow_tabs=0
    [[ -n "${allow_tabs_map[$bn]:-}" ]] && allow_tabs=1

    local line_no=0
    # shellcheck disable=SC2034  # had_final_newline reserved for potential newline enforcement logic
    local had_final_newline=1
    local last_char
    # shellcheck disable=SC2034  # trailing_fixed removed (no longer used)
    local tmp_fixed

    # shellcheck disable=SC2002
    while IFS= read -r line || [[ -n "$line" ]]; do
        (( line_no++ ))
        # Detect if last read lacked newline (Bash read without -r sets last line)
        last_char=${line: -1}
        if [[ "$last_char" != $'\n' ]]; then
            had_final_newline=0
        fi

        # Raw line for length check (use printf to preserve trailing spaces)
        local raw="$line"

        # Trailing spaces (space or tab at EOL)
        if [[ "$raw" =~ [[:space:]]+$ ]]; then
            (( viol_trailing++ ))
            (( QUIET )) || report_lines+=("TRAILING_SPACE ${file}:${line_no} :: $(printf '%s' "$raw" | sed -E 's/[[:space:]]+$//')")
        fi

        # Leading indentation analysis
        if [[ "$raw" =~ ^([[:space:]]+) ]]; then
            local prefix="${BASH_REMATCH[1]}"

            # Mixed indent prefix (tabs + spaces interleaved or both kinds)
            if [[ "$prefix" == *$'\t'* && "$prefix" == *' '* ]]; then
                (( viol_mixed_indent++ ))
                (( QUIET )) || report_lines+=("MIXED_INDENT ${file}:${line_no} :: mixed tabs+spaces")
            else
                # Pure tab indent
                if [[ "$prefix" == *$'\t'* ]]; then
                    if (( ! allow_tabs )); then
                        (( viol_tab_indent++ ))
                        (( QUIET )) || report_lines+=("TAB_INDENT ${file}:${line_no} :: tabs not allowed")
                    fi
                else
                    # Pure spaces: enforce width multiple
                    local count=${#prefix}
                    local rem=$(( count % INDENT_SIZE ))
                    if (( rem != 0 )); then
                        (( viol_indent_width++ ))
                        (( QUIET )) || report_lines+=("INDENT_WIDTH ${file}:${line_no} :: length=${count} not multiple of ${INDENT_SIZE}")
                    fi
                fi
            fi
        fi
    done <"$file"

    # Auto-fixes
    if (( FIX_TRAILING )) || (( FIX_FINAL_NEWLINE )); then
        tmp_fixed="${file}.style_audit_tmp.$$"
        local modified=0
        local changed_trailing=0

        awk -v fix_trailing="$FIX_TRAILING" '
            {
                line=$0
                if (fix_trailing == 1) {
                    sub(/[ \t]+$/, "", line)
                }
                print line
            }
            END {
                # awk automatically preserves final newline; we track removal separately outside
            }
        ' "$file" >"$tmp_fixed"

        if (( FIX_TRAILING )); then
            # Count diff for trailing spaces removed (approx: diff lines)
            # Quick heuristic: re-scan both for trailing spaces
            local before after
            before=$(grep -cE '[[:space:]]+$' "$file" || true)
            after=$(grep -cE '[[:space:]]+$' "$tmp_fixed" || true)
            if (( before > after )); then
                changed_trailing=$(( before - after ))
                (( fixed_trailing += changed_trailing ))
                modified=1
            fi
        fi

        if (( FIX_FINAL_NEWLINE )); then
            if [[ -s "$file" ]]; then
                if [[ $(tail -c1 "$file" 2>/dev/null || echo "") != $'\n' ]]; then
                    echo "" >>"$tmp_fixed"
                    (( fixed_final_newline++ ))
                    modified=1
                fi
            fi
        fi

        if (( modified )); then
            mv "$tmp_fixed" "$file"
        else
            rm -f "$tmp_fixed"
        fi
    fi
}

start_ns=$(date +%s%N 2>/dev/null || echo 0)

for f in "${target_files[@]}"; do
    audit_file "$f"
done

end_ns=$(date +%s%N 2>/dev/null || echo 0)
delta_ms=0
if [[ "$start_ns" != "0" && "$end_ns" != "0" ]]; then
    delta_ms=$(( (end_ns - start_ns) / 1000000 ))
fi

viol_total=$(( viol_trailing + viol_tab_indent + viol_mixed_indent + viol_indent_width ))

# ---------------------- Output Rendering -------------------------------------
emit_text() {
    if (( QUIET == 0 )); then
        for line in "${report_lines[@]}"; do
            case "$line" in
                TRAILING_SPACE*) printf "%s\n" "$(red "$line")" ;;
                TAB_INDENT*) printf "%s\n" "$(yellow "$line")" ;;
                MIXED_INDENT*) printf "%s\n" "$(red "$line")" ;;
                INDENT_WIDTH*) printf "%s\n" "$(yellow "$line")" ;;
                *) printf "%s\n" "$line" ;;
            esac
        done
    fi

    if (( SHOW_STATS )); then
        printf "\n"
        printf "%s\n" "==== Style Audit Summary ===="
        printf "Root:               %s\n" "$ROOT"
        printf "Files scanned:      %d\n" "$files_scanned"
        printf "Violations total:   %d\n" "$viol_total"
        printf "  Trailing spaces : %d\n" "$viol_trailing"
        printf "  Tab indent      : %d\n" "$viol_tab_indent"
        printf "  Mixed indent    : %d\n" "$viol_mixed_indent"
        printf "  Indent width    : %d\n" "$viol_indent_width"
        if (( FIX_TRAILING || FIX_FINAL_NEWLINE )); then
            printf "Fixes applied:\n"
            (( FIX_TRAILING )) && printf "  Trailing trimmed : %d lines\n" "$fixed_trailing"
            (( FIX_FINAL_NEWLINE )) && printf "  Final newlines   : %d files\n" "$fixed_final_newline"
        fi
        printf "Duration:           %d ms\n" "$delta_ms"
        if (( viol_total == 0 )); then
            printf "%s\n" "$(green "STATUS: CLEAN")"
        else
            printf "%s\n" "$(red "STATUS: VIOLATIONS")"
        fi
    fi
}

emit_json() {
    cat <<JSON
{
  "schema": "shell-style-audit.v1",
  "root": "$(printf '%s' "$ROOT" | sed 's/"/\\"/g')",
  "scanned_files": $files_scanned,
  "violations_total": $viol_total,
  "trailing_space": $viol_trailing,
  "tab_indent": $viol_tab_indent,
  "mixed_indent": $viol_mixed_indent,
  "indent_width": $viol_indent_width,
  "fixed_trailing": $fixed_trailing,
  "fixed_final_newline": $fixed_final_newline,
  "indent_size": $INDENT_SIZE,
  "duration_ms": $delta_ms,
  "allow_tabs_files": [$(printf '%s\n' "${!allow_tabs_map[@]}" | awk 'NR>1{printf ","} {printf "\"%s\"",$0}')],
  "status": "$( (( viol_total == 0 )) && echo clean || echo violations )"
}
JSON
}

if (( JSON_MODE )); then
    out="$(emit_json)"
else
    out="$(emit_text 2>&1)"
fi

if [[ -n "$OUTPUT_FILE" ]]; then
    printf '%s\n' "$out" >"$OUTPUT_FILE"
else
    printf '%s\n' "$out"
fi

if (( NO_FAIL )); then
    exit 0
fi

if (( viol_total > 0 )); then
    exit 1
fi
exit 0
