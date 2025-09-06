#!/usr/bin/env zsh
# ============================================================================
# Mermaid Diagram Validation & Rendering Utility
# ----------------------------------------------------------------------------
# Scans markdown files for ```mermaid fenced code blocks, extracts them, and
# attempts to render each via Mermaid CLI (mmdc). Produces a summary report
# with pass/fail status. Designed for CI or local pre-commit validation.
# ----------------------------------------------------------------------------
# Features:
#    - Auto-discovers markdown files (default: docs/ **/*.md)
#    - Supports explicit file/dir arguments
#    - Output directory configurable (default: docs/diagrams/rendered)
#    - Fail-fast option
#    - Optional auto-install of mmdc when AUTO_INSTALL_MERMAID=1 and npm present
#    - Colored terse or verbose logging
#    - Ensures consistent single compinit call not required (standalone script)
# ----------------------------------------------------------------------------
# Usage:
#     bin/validate-mermaid-diagrams.zsh [options] [paths...]
# Options:
#     --out DIR                 Output directory for rendered artifacts
#     --fail-fast             Stop on first failure
#     --list-only             Parse & list diagrams without rendering
#     --quiet                     Suppress non-error output
#     --verbose                 Verbose logging
#     --no-color                Disable ANSI colors
#     --help                        Show help
# Env Vars:
#     AUTO_INSTALL_MERMAID=1    Attempt npm global install if mmdc missing
#     MERMAID_CLI=mmdc                 Override mermaid CLI executable
# Exit Codes:
#     0 success, 1 failures found, 2 internal error, 3 dependency missing
# ============================================================================

set -u
SCRIPT_NAME=${0:t}

# ----------------------------- Color Handling --------------------------------
if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
    RED=$'%F{160}'; GREEN=$'%F{76}'; YELLOW=$'%F{178}'; BLUE=$'%F{33}'; CYAN=$'%F{45}'; DIM=$'%F{244}'; BOLD=$'%B'; RESET=$'%f%b'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; DIM=""; BOLD=""; RESET=""
fi

# ----------------------------- Defaults --------------------------------------
OUTPUT_DIR="docs/diagrams/rendered"
FAIL_FAST=0
LIST_ONLY=0
QUIET=0
VERBOSE=0
MERMAID_CLI=${MERMAID_CLI:-mmdc}
TMP_ROOT="${TMPDIR:-/tmp}/${SCRIPT_NAME}-$$"
mkdir -p "$TMP_ROOT" 2>/dev/null || true

print_help() {
    cat <<'EOF'
Mermaid Diagram Validation & Rendering
Scans markdown for mermaid code fences and renders them via mmdc.

Usage:
    validate-mermaid-diagrams.zsh [options] [paths...]

Options:
    --out DIR                 Output directory for rendered files (default: docs/diagrams/rendered)
    --fail-fast             Abort on first failure
    --list-only             Only list discovered diagrams (no rendering)
    --quiet                     Minimal output (errors only)
    --verbose                 Extra diagnostic output
    --no-color                Disable colored output (or set NO_COLOR=1)
    --help                        This help message

Environment:
    AUTO_INSTALL_MERMAID=1    Attempt npm -g install of @mermaid-js/mermaid-cli if missing
    MERMAID_CLI=mmdc                Override the Mermaid CLI executable name/path

Exit Codes:
    0 success; 1 validation/render errors; 2 internal error; 3 dependency missing
EOF
}

log() { (( QUIET )) && return 0; print -r -- "$@"; }
vecho() { (( VERBOSE )) && log "$@"; }
warn() { print -r -- "${YELLOW}[WARN]${RESET} $@" >&2; }
err() { print -r -- "${RED}[ERROR]${RESET} $@" >&2; }
ok() { (( QUIET )) || print -r -- "${GREEN}[OK]${RESET} $@"; }

# ----------------------------- Arg Parsing -----------------------------------
ARGS=()
while (( $# > 0 )); do
    case "$1" in
        --out) OUTPUT_DIR="$2"; shift 2;;
        --fail-fast) FAIL_FAST=1; shift;;
        --list-only) LIST_ONLY=1; shift;;
        --quiet) QUIET=1; shift;;
        --verbose) VERBOSE=1; shift;;
        --no-color) NO_COLOR=1; shift;;
        --help) print_help; exit 0;;
        --) shift; break;;
        -*) err "Unknown option: $1"; print_help; exit 2;;
        *) ARGS+="$1"; shift;;
    esac
done

(( ${#ARGS} == 0 )) && ARGS=( docs )

# Re-init colors if --no-color passed after earlier setup
if [[ "${NO_COLOR:-0}" == "1" ]]; then
    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; DIM=""; BOLD=""; RESET=""
fi

# ----------------------------- Dependency Check ------------------------------
has_command() { command -v "$1" >/dev/null 2>&1; }

ensure_mermaid_cli() {
    if has_command "$MERMAID_CLI"; then
        vecho "Found Mermaid CLI: $MERMAID_CLI"
        return 0
    fi
    if [[ "${AUTO_INSTALL_MERMAID:-0}" == "1" ]] && has_command npm; then
        warn "Mermaid CLI not found; attempting global install (@mermaid-js/mermaid-cli)"
        if npm install -g @mermaid-js/mermaid-cli >/dev/null 2>&1; then
            if has_command mmdc; then
                MERMAID_CLI=mmdc
                ok "Installed Mermaid CLI"
                return 0
            fi
        fi
        err "Automatic install failed. Install manually: npm install -g @mermaid-js/mermaid-cli"
        return 3
    else
        err "Mermaid CLI not found: $MERMAID_CLI. Install: npm install -g @mermaid-js/mermaid-cli"
        return 3
    fi
}

if (( ! LIST_ONLY )); then
    ensure_mermaid_cli || exit 3
fi

mkdir -p "$OUTPUT_DIR" 2>/dev/null || { err "Cannot create output dir: $OUTPUT_DIR"; exit 2; }

# ----------------------------- File Collection -------------------------------
collect_files() {
    local target files=()
    for target in "$@"; do
        if [[ -d "$target" ]]; then
            # Use globbing for speed; include only .md, .markdown
            files+=( ${(f)"$(print -l "$target"/**/*.md(N) "$target"/**/*.markdown(N))"} )
        elif [[ -f "$target" ]]; then
            files+=( "$target" )
        else
            warn "Skipping non-existent path: $target"
        fi
    done
    # Deduplicate
    typeset -U files
    print -r -- "$files[@]"
}

TARGET_FILES=( $(collect_files "$ARGS[@]") )
(( ${#TARGET_FILES} == 0 )) && { warn "No target markdown files found."; exit 0; }

# ----------------------------- Extraction & Render ---------------------------
integer total_blocks=0 total_files=0 failures=0 rendered=0

render_block() {
    local src_file="$1" block_index="$2" block_file="$3" out_format="$4"
    local base_name out_base out_file rc
    base_name="${src_file:t:r}" # strip extension
    out_base="${base_name}-diagram-${block_index}"
    case "$out_format" in
        png|svg|pdf) out_file="$OUTPUT_DIR/${out_base}.$out_format" ;;
        *) out_file="$OUTPUT_DIR/${out_base}.png" ;;
    esac
    if (( LIST_ONLY )); then
        log "FOUND: $src_file (block #$block_index) -> $out_file"
        return 0
    fi
    "$MERMAID_CLI" -i "$block_file" -o "$out_file" >/dev/null 2>&1
    rc=$?
    if (( rc == 0 )); then
        (( rendered++ ))
        vecho "Rendered: $out_file"
        return 0
    else
        (( failures++ ))
        err "Render failed (exit $rc) $src_file block #$block_index -> $out_file"
        if (( FAIL_FAST )); then
            log "Fail-fast enabled; aborting."
            exit 1
        fi
    fi
}

process_file() {
    local file="$1" line in_block=0 buf="" block_index=0 syntax_line format="png"
    (( total_files++ ))
    vecho "Scanning $file"
    while IFS= read -r line || [[ -n "$line" ]]; do
        if (( ! in_block )) && [[ "$line" == '```mermaid'* ]]; then
            in_block=1
            buf=""
            block_index=$(( block_index + 1 ))
            syntax_line="$line"
            # Optional output format hint: ```mermaid:svg
            if [[ "$syntax_line" == "\`\`\`mermaid:"* ]]; then
                format="${syntax_line##\`\`\`mermaid:}"
                format="${format%% *}" # strip trailing tokens
            else
                format="png"
            fi
            continue
        fi
        if (( in_block )) && [[ "$line" == '```' ]]; then
            # finalize block
            local tmp_file="$TMP_ROOT/block-${file:t}-${block_index}.mmd"
            print -r -- "$buf" > "$tmp_file"
            (( total_blocks++ ))
            render_block "$file" "$block_index" "$tmp_file" "$format"
            in_block=0
            buf=""
            continue
        fi
        if (( in_block )); then
            buf+="$line\n"
        fi
    done < "$file"
}

for f in "$@"; do
    process_file "$f"
done

# ----------------------------- Summary ---------------------------------------
if (( LIST_ONLY )); then
    log "Listed $total_blocks mermaid blocks across $total_files files"
    exit 0
fi

if (( failures > 0 )); then
    err "Completed with $failures failed render(s); $rendered succeeded; total blocks: $total_blocks"
    exit 1
else
    ok "All $total_blocks mermaid blocks rendered successfully across $total_files files (outputs in $OUTPUT_DIR)"
    exit 0
fi
