#!/usr/bin/env zsh
# ==============================================================================
# 525-starship-env.zsh — Starship config templating & symlink management
# ==============================================================================
# Phase: Post-plugin (must load BEFORE 530/520 starship init fragment)
# Purpose:
#   - Generate a Starship config from a template using zqs setting `starship-utc-offset`
#   - Manage symlink at ~/.config/starship.toml to point to generated or base config
#   - Provide a stable cache directory within this dotfiles tree
#   - Offer lightweight diagnostics when ZSH_DEBUG=1
#
# Behavior:
#   * Respects ZSH_DISABLE_STARSHIP=1 (hard disable)
#   * Skips if starship binary is missing
#   * Does not export STARSHIP_CONFIG; relies on stow-managed ~/.config/starship.toml symlink
#
# Sources/Targets (derived from ZDOTDIR):
#   ZDOTDIR                       -> .../dot-config/zsh
#   DOT_CONFIG_ROOT               -> .../dot-config
#   STARSHIP_DIR                  -> .../dot-config/starship
#   TEMPLATE (preferred)          -> .../dot-config/starship/starship.base.toml
#   TEMPLATE (fallback)           -> ${ZDOTDIR}/starship/starship.base.toml
#   GENERATED                     -> .../dot-config/starship/generated/starship.generated.toml
#   SYMLINK TARGET                -> .../dot-config/starship.toml
#
# Idempotency:
#   Protected by _STARSHIP_ENV_FRAGMENT_LOADED sentinel.
# ==============================================================================

# Prevent multiple sourcing
if [[ -n ${_STARSHIP_ENV_FRAGMENT_LOADED:-} ]]; then
    return 0
fi
typeset -g _STARSHIP_ENV_FRAGMENT_LOADED=1

# Respect hard disable knob
if [[ ${ZSH_DISABLE_STARSHIP:-0} == 1 ]]; then
    return 0
fi

# Fast path: skip if starship not installed (avoid needless vars)
if ! command -v starship >/dev/null 2>&1; then
    [[ ${ZSH_DEBUG:-0} == 1 ]] && echo "# [starship-env] binary not found; skipping"
    return 0
fi

# Resolve roots from ZDOTDIR (.../dot-config/zsh -> .../dot-config)
local _zd _dotcfg_root _starship_dir _gen_dir
_zd="${ZDOTDIR:-$HOME}"
# If the tail of ZDOTDIR is 'zsh', strip it to get dot-config root
if [[ "${_zd:t}" == "zsh" ]]; then
    _dotcfg_root="${_zd:h}"
else
    # Fallback: parent directory of ZDOTDIR
    _dotcfg_root="${_zd%/*}"
fi

pushd "${_dotcfg_root}" >/dev/null || true
{
    _starship_dir="starship"
    _gen_dir="${_starship_dir}/generated"

    # Ensure starship directories exist
    mkdir -p -- "${_gen_dir}" 2>/dev/null || true

    # Preferred template under dot-config/starship; fallback to repo-local template
    local _template _fallback_template
    _template="${_starship_dir}/starship.base.toml"
    _fallback_template="${_starship_dir}/starship-minimal.toml"
    if [[ ! -f "${_template}" && -f "${_fallback_template}" ]]; then
        _template="${_fallback_template}"
    fi

    # Read user offset setting (zqs) and validate; default to +0
    local _tz
    if typeset -f _zqs-get-setting >/dev/null 2>&1; then
        _tz="$(_zqs-get-setting starship-utc-offset +0)"
    else
        _tz="+0"
    fi
    # Validate: optional +/-, integer or decimal
    if ! print -r -- "${_tz}" | LC_ALL=C grep -Eq '^[+-]?[0-9]+(\.[0-9]+)?$'; then
        _tz="+0"
    fi

    # Generate config from template if present by replacing __UTC_OFFSET__
    local _generated _link_src _symlink_target _esc_offset
    _generated="${_gen_dir}/starship.generated.toml"
    _symlink_target="starship.toml"

    if [[ -f "${_template}" ]]; then
        _esc_offset="${_tz//\//\\/}"
        # Use sed to replace placeholder; if it fails, don't consider file generated
        if sed "s/__UTC_OFFSET__/${_esc_offset}/g" "${_template}" >|"${_generated}" >/dev/null; then
            # Defensive sanitization: strip stray literal markers accidentally present in generated config.
            # Only remove plain text tokens, preserving module references like $custom.lang_open.
            if [[ -f "${_generated}" ]]; then
                local _tmp="${_generated}.sanitize.$$"
                sed -E 's/(^|[^$[:alnum:]_])\.lang_open([^[:alnum:]_]|$)/\1\2/g; s/(^|[^$[:alnum:]_])\.time_sep([^[:alnum:]_]|$)/\1\2/g; s/(^|[^$[:alnum:]_])\.time_display([^[:alnum:]_]|$)/\1\2/g' "${_generated}" >"${_tmp}" 2>/dev/null \
                && mv -f "${_tmp}" "${_generated}" >/dev/null || { rm -f "${_tmp}" >/dev/null || true; }
            fi
            _link_src="${_generated}"
        else
            _link_src="${_template}"
        fi
    else
        # No template found; do not generate; prefer any existing ZDOTDIR/starship.toml
        [[ -f "starship/starship.toml" ]] && _link_src="starship/starship.toml"
    fi

    # Manage symlink at .../dot-config/starship.toml if we have a source
    if [[ -n "${_link_src:-}" ]]; then
        # Create/refresh the symlink
        ln -sfn "${_link_src}" "${_symlink_target}" 2>/dev/null || {
            rm -f -- "${_symlink_target}" 2>/dev/null
            ln -s "${_link_src}" "${_symlink_target}" 2>/dev/null || true
        }
        # STARSHIP_CONFIG is not exported here; rely on ~/.config/starship.toml (stow-managed symlink)
    else
        # Fallback: use any repo-local config if present via stow (~/.config/starship.toml)
        # No STARSHIP_CONFIG export; rely on default Starship resolution
        :
    fi
}
popd >/dev/null || true

# Provide a stable cache directory (only if user hasn't set one)
if [[ -z ${STARSHIP_CACHE:-} ]]; then
    export STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship"
fi
# Ensure cache directory exists (ignore errors)
mkdir -p -- "${STARSHIP_CACHE}" 2>/dev/null || true

# Optional lightweight diagnostics
if [[ ${ZSH_DEBUG:-0} == 1 ]]; then
    echo "# [starship-env] STARSHIP_CONFIG (not set by env fragment) = ${STARSHIP_CONFIG:-<unset>}"
    echo "# [starship-env] STARSHIP_CACHE=${STARSHIP_CACHE:-<unset>}"
    echo "# [starship-env] dot-config root=${_dotcfg_root}"
    echo "# [starship-env] template=${_template:-<none>} tz=${_tz} link_src=${_link_src:-<none>}"
fi

# --- Dynamic time visibility (inlined from 531-starship-dynamic-width.zsh) ---
if [[ -o interactive ]]; then
    if [[ -z "${_STARSHIP_DYN_TIME_INSTALLED:-}" ]]; then
        typeset -g _STARSHIP_DYN_TIME_INSTALLED=1
        : "${STARSHIP_TIME_MIN_COLUMNS:=100}"

        __starship_time_width_guard() {
            local _cols=${COLUMNS:-0}
            local _min="${STARSHIP_TIME_MIN_COLUMNS}"
            if ((_cols >= _min)); then
                export STARSHIP_SHOW_TIME=1
                export TIME_FMT="$(LC_ALL=C date +%R 2>/dev/null || date +%R)"
                [[ "${ZSH_DEBUG:-0}" == 1 ]] && print -r -- "# [dyn-time] show (COLUMNS=${_cols} >= ${_min}); TIME_FMT=${TIME_FMT}"
            else
                unset STARSHIP_SHOW_TIME
                unset TIME_FMT
                [[ "${ZSH_DEBUG:-0}" == 1 ]] && print -r -- "# [dyn-time] hide (COLUMNS=${_cols} < ${_min})"
            fi
        }

        # Register guard for each prompt using precmd_functions (portable across zsh versions)
        if [[ -z ${precmd_functions[(r)__starship_time_width_guard]} ]]; then
            precmd_functions+=( __starship_time_width_guard )
        fi

        # Handle terminal resizes via TRAPWINCH (portable alternative to a sigwinch hook)
        if ! typeset -f TRAPWINCH >/dev/null 2>&1; then
            TRAPWINCH() { __starship_time_width_guard; return 0; }
        fi

        # Initialize once for the current session
        __starship_time_width_guard
    fi
fi

unset _zd _dotcfg_root _starship_dir _gen_dir _template _fallback_template _tz _generated _link_src _symlink_target _esc_offset _candidate_config
return 0
