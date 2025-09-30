#!/usr/bin/env zsh
# Starship Initialization Wrapper
# Handles ZLE widgets initialization issues gracefully

# Prompt initialization guard
if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]]; then
    return 0
fi

typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }

# Safe Starship initialization function (idempotent)
starship_init_safe() {
    if [[ -n ${__ZF_PROMPT_INIT_DONE:-} ]]; then
        zf::debug "# [prompt] starship init skipped (already done)"
        return 0
    fi
    local _zf_start_time _zf_end_time _zf_elapsed_ms
    _zf_start_time="${EPOCHREALTIME:-}"
    # Ensure we have starship available
    local starship_bin
    starship_bin="$(command -v starship 2>/dev/null || true)"
    [[ -z "$starship_bin" && -x "$HOME/.local/share/cargo/bin/starship" ]] && starship_bin="$HOME/.local/share/cargo/bin/starship"

    if [[ -z "$starship_bin" ]]; then
        echo "# Starship not available" >&2
        return 1
    fi

    # Generate the init script
    local init_script
    init_script="$("$starship_bin" init zsh 2>/dev/null)"

    if [[ -z "$init_script" ]]; then
        echo "# Starship init generation failed" >&2
        return 1
    fi

    # The problematic line is: __starship_preserved_zle_keymap_select=${widgets[zle-keymap-select]#user:}
    # Let's patch it to be safe
    local safe_init_script
    safe_init_script="${init_script//__starship_preserved_zle_keymap_select=\${widgets\[zle-keymap-select\]#user:}/__starship_preserved_zle_keymap_select=\${widgets[zle-keymap-select]#user:}}"

    # Actually, let's use a more robust approach: wrap the problematic access in a safe check
    safe_init_script="${init_script//\${widgets\[zle-keymap-select\]#user:}/\${widgets[zle-keymap-select]:-}}"
    safe_init_script="${safe_init_script//\${widgets\[zle-keymap-select\]:-}#user:/\${widgets[zle-keymap-select]:-}}"

    # Execute the patched script
        eval "$safe_init_script"
        _zf_end_time="${EPOCHREALTIME:-}"
        if [[ -n "$_zf_start_time" && -n "_zf_end_time" ]]; then
            # EPOCHREALTIME format: seconds.microseconds
            local s1=${_zf_start_time%%.*} us1=${_zf_start_time#*.}
            local s2=${_zf_end_time%%.*}   us2=${_zf_end_time#*.}
            # Pad microseconds to 6 digits
            us1="${us1}000000"; us1=${us1:0:6}
            us2="${us2}000000"; us2=${us2:0:6}
            local total_us=$(( (10#$s2*1000000 + 10#$us2) - (10#$s1*1000000 + 10#$us1) ))
            if (( total_us >= 0 )); then
                _zf_elapsed_ms=$(( total_us / 1000 ))
                export _ZF_STARSHIP_INIT_MS=$_zf_elapsed_ms
            fi
        fi
    __ZF_PROMPT_INIT_DONE=1
    export __ZF_PROMPT_INIT_DONE
        if [[ -n ${_ZF_STARSHIP_INIT_MS:-} ]]; then
            zf::debug "# [prompt] starship initialized (${_ZF_STARSHIP_INIT_MS}ms)"
            if [[ -z ${ZF_DISABLE_METRICS:-} ]]; then
                local metrics_dir="${ZDOTDIR:-$HOME}/dot-config/zsh/artifacts/metrics"
                if [[ -d "$metrics_dir" && -w "$metrics_dir" ]]; then
                    {
                        printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "starship_init_ms" "${_ZF_STARSHIP_INIT_MS}" || true
                    } >> "$metrics_dir/starship-init.log" 2>/dev/null || true
                    # Rotate if >64KB (approx) keeping last 500 lines
                    if [[ -f "$metrics_dir/starship-init.log" ]]; then
                        local sz
                        sz=$(wc -c <"$metrics_dir/starship-init.log" 2>/dev/null || echo 0)
                        if [[ -n "$sz" && "$sz" -gt 65536 ]]; then
                            tail -n 500 "$metrics_dir/starship-init.log" > "$metrics_dir/.starship-init.tmp" 2>/dev/null || true
                            mv "$metrics_dir/.starship-init.tmp" "$metrics_dir/starship-init.log" 2>/dev/null || true
                        fi
                    fi
                fi
            fi
        else
            zf::debug "# [prompt] starship initialized"
        fi
}

# Namespaced convenience wrapper (preferred internal entrypoint)
zf::prompt_init() { starship_init_safe "$@"; }

# If this script is being sourced, just define the function
# If it's being executed directly, run the safe initialization
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
    starship_init_safe
fi
