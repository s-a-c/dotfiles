#!/usr/bin/env zsh
# ZSH Tool Functions: Health Check & Docs Link Lint
# Sourced from .zshrc.d for interactive use

zsh_health_check() {
    local FAILURES=()
    [[ "$ZSH_DEBUG" == "1" ]] && {
      zsh_debug_echo "# ++++++ zsh_health_check ++++++"
      if [[ -f "${ZDOTDIR:-$HOME}/2" ]] || [[ -f "${ZDOTDIR:-$HOME}/3" ]]; then
         zsh_debug_echo "Warning: Numbered files detected - check for redirection typos"
      fi
    }

    zsh_debug_echo "🔍 Zsh Configuration Health Check"
    zsh_debug_echo "================================"

    _check_syntax_errors FAILURES
    _check_exposed_credentials FAILURES
    _check_path_sanity FAILURES
    _check_zgenom_setup FAILURES
    _display_startup_time
    _check_docs_links FAILURES
    _display_health_summary FAILURES

    return $((${#FAILURES[@]} > 0 ? 1 : 0))
}

_check_syntax_errors() {
    local -n failures_ref=$1
    for file in ~/.config/zsh/{.zshenv,.zshrc} ~/.config/zsh/.zshrc.d/*.zsh; do
        if [[ -f "$file" ]]; then
            if zsh -n "$file" 2>/dev/null; then
                zsh_debug_echo "✅ $file - Syntax OK"
            else
                zsh_debug_echo "❌ $file - Syntax Error"
                failures_ref+=("syntax:$file")
            fi
        fi
    done
}

_check_exposed_credentials() {
    local -n failures_ref=$1
    if grep -r "sk-" ~/.config/zsh/ --exclude-dir=.env 2>/dev/null; then
        zsh_debug_echo "⚠️  Possible exposed API keys found!"
        failures_ref+=("secrets")
    else
        zsh_debug_echo "✅ No exposed API keys detected"
    fi
}

_check_path_sanity() {
    local -n failures_ref=$1
    if zsh_debug_echo $PATH | grep -q "/usr/bin"; then
        zsh_debug_echo "✅ System PATH includes /usr/bin"
    else
        zsh_debug_echo "❌ System PATH missing /usr/bin"
        failures_ref+=("path:usrbin")
    fi
}

_check_zgenom_setup() {
    local -n failures_ref=$1
    if [[ -n "$ZGEN_DIR" && -d "$ZGEN_DIR" ]]; then
        zsh_debug_echo "✅ zgenom directory exists: $ZGEN_DIR"
    else
        zsh_debug_echo "⚠️  zgenom directory not found"
        failures_ref+=("zgenom:missing")
    fi
}

_display_startup_time() {
    local startup_time
    startup_time=$( (time zsh -i -c exit) 2>&1 | grep real | awk '{print $2}')
    zsh_debug_echo "⏱️  Startup time: $startup_time"
}

_check_docs_links() {
    local -n failures_ref=$1
    if typeset -f zsh_docs_link_lint >/dev/null 2>&1; then
        if zsh_docs_link_lint; then
            zsh_debug_echo "📚 Docs links: OK"
        else
            zsh_debug_echo "📚 Docs links: FAIL"
            failures_ref+=("docs-links")
        fi
    else
        zsh_debug_echo "📚 Docs links: Skipped (function not available)"
    fi
}

_display_health_summary() {
    local -n failures_ref=$1
    if (( ${#failures_ref[@]} )); then
        zsh_debug_echo "\n❌ Health check failures: ${failures_ref[*]}"
        zsh_debug_echo "Exit code: 1 (failures present)"
    else
        zsh_debug_echo "\n✅ Health check passed (no failures)"
    fi

    zsh_debug_echo "\n💡 Recommendations:\n- Run 'zsh_health_check' monthly\n- Keep startup time under 2 seconds\n- Update plugins quarterly: 'zgenom update'\n- Backup config before major changes\n- Address any Docs link failures promptly"
}

zsh_docs_link_lint() {
    local VERBOSE=0
    [[ ${1:-} == --verbose ]] && VERBOSE=1
    local DOCS_DIR="docs"
    [[ -d $DOCS_DIR ]] || { zsh_debug_echo "[docs-link-lint] ERROR: docs directory not found"; return 2; }

    local md_files missing checked
    md_files=($(command find "$DOCS_DIR" -type f -name '*.md' -print))
    (( ! ${#md_files[@]} )) && { zsh_debug_echo "[docs-link-lint] No markdown files found"; return 0; }

    missing=()
    checked=0

    for f in $md_files; do
        _process_markdown_file "$f" "$DOCS_DIR" "$VERBOSE" missing checked
    done

    _report_link_check_results "$checked" "${#md_files[@]}" missing
}

_process_markdown_file() {
    local file="$1" docs_dir="$2" verbose="$3"
    local -n missing_ref="$4" checked_ref="$5"
    local in_code=0 line

    while IFS= read -r line; do
        if [[ $line == '```'* ]]; then
            in_code=$(( in_code ^ 1 ))
            continue
        fi
        (( in_code )) && continue

        if [[ $line == *"]("* ]]; then
            for link in $(print -r -- "$line" | grep -Eo '\[[^]]+\]\([^()]+\)'); do
                [[ $link == '!'* ]] && continue
                local target=${link#*(}
                target=${target%)}

                if _is_external_or_anchor_link "$target"; then
                    continue
                fi

                if ! _link_target_exists "$target" "$docs_dir"; then
                    missing_ref+=("$file:$target")
                fi

                ((checked_ref++))
                (( verbose )) && zsh_debug_echo "[docs-link-lint] $file => $target"
            done
        fi
    done < "$file"
}

_is_external_or_anchor_link() {
    local target="$1"
    [[ $target == http://* || $target == https://* || $target == mailto:* || $target == \#* ]]
}

_link_target_exists() {
    local target="$1" docs_dir="$2"
    local base_file=${target%%#*}
    [[ -n $base_file ]] && [[ -f $docs_dir/$base_file || -f $base_file ]]
}

_report_link_check_results() {
    local checked="$1" files_count="$2"
    local -n missing_ref="$3"

    if (( ${#missing_ref[@]} )); then
        zsh_debug_echo "[docs-link-lint] Missing link targets (${#missing_ref[@]}):"
        for m in "${missing_ref[@]}"; do
            zsh_debug_echo "  - $m"
        done
        zsh_debug_echo "[docs-link-lint] Checked $checked links"
        return 1
    fi

    zsh_debug_echo "[docs-link-lint] All $checked links OK (files scanned: $files_count)"
    return 0
}
