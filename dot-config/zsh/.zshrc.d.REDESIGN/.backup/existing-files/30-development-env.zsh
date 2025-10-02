#!/usr/bin/env zsh
# 30-development-env.zsh
: ${_LOADED_30_DEVELOPMENT_ENV:=1}
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v900f08def0e6f7959ffd283aebb73b625b3473f5e49c57e861c6461b50a62ef2
#
# PURPOSE:
#   Timing instrumentation for development environment initialization phase.
#   Emits a granular post-plugin segment marker so we can attribute cost
#   separate from other post-plugin modules.
#
# MARKER:
#   POST_PLUGIN_SEGMENT 30-dev-env <delta_ms>
#
# NOTES:
#   - Designed to be lightweight & idempotent.
#   - Insert real dev environment setup logic between START/END placeholders.
#   - Only emits when PERF_SEGMENT_LOG is set (perf-capture context).
#
zmodload zsh/datetime 2>/dev/null || true
typeset -f zf::debug >/dev/null 2>&1 || zf::debug() { :; }
if [[ -n ${PERF_SEGMENT_LOG:-} && -z ${POST_SEG_30_DEV_ENV_START_MS:-} ]]; then
    POST_SEG_30_DEV_ENV_START_MS=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
    export POST_SEG_30_DEV_ENV_START_MS
fi
# === Development environment setup START ===

# Helper for granular timing
_zf_dev_now_ms() {
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=($1*1000); if(NF>1){ ms+=substr($2 "000",1,3)+0 } printf "%d", ms}'
        return 0
    fi
    date +%s 2>/dev/null | awk '{printf "%d",$1*1000}'
}

# Segment helper with fallback
_zf_dev_segment() {
    local name="$1" action="$2"
    if typeset -f _zsh_perf_segment_${action} >/dev/null 2>&1; then
        _zsh_perf_segment_${action} "dev-env/${name}" post_plugin
    else
        # Fallback timing
        if [[ "$action" == "start" ]]; then
            _ZF_DEV_SEG_START[$name]=$(_zf_dev_now_ms)
        elif [[ "$action" == "end" && -n ${_ZF_DEV_SEG_START[$name]:-} ]]; then
            local end_ms=$(_zf_dev_now_ms)
            local delta=$((end_ms - _ZF_DEV_SEG_START[$name]))
            ((delta < 0)) && delta=0
            if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
                print "SEGMENT name=dev-env/${name} ms=${delta} phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
            fi
        fi
    fi
}

typeset -gA _ZF_DEV_SEG_START

# Herd Integration (PHP + Node.js management) - PRIORITY OVER NVM
_zf_dev_segment "herd" "start"
if [[ -d "$HOME/Library/Application Support/Herd" ]]; then
    zf::debug "# [dev-env] Herd detected - setting up PHP and Node.js environment"

    # Herd environment variables
    export HERD_APP="/Applications/Herd.app"
    export HERD_TOOLS_HOME="$HOME/Library/Application Support/Herd"
    export HERD_TOOLS_BIN="$HERD_TOOLS_HOME/bin"
    export HERD_TOOLS_CONFIG="$HERD_TOOLS_HOME/config"

    # PHP version-specific configurations
    export HERD_PHP_82_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/82/"
    export HERD_PHP_83_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/83/"
    export HERD_PHP_84_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/84/"
    export HERD_PHP_85_INI_SCAN_DIR="$HERD_TOOLS_CONFIG/php/85/"

    # Add Herd paths (highest priority)
    export PATH="$HERD_TOOLS_BIN:$HERD_TOOLS_HOME:$PATH"

    # Add Herd resources if available
    [[ -d "$HERD_APP/Contents/Resources" ]] &&
        export PATH="$HERD_APP/Contents/Resources:$PATH"

    # Herd includes its own Node.js management - check if NVM should be Herd's
    [[ -d "$HERD_TOOLS_CONFIG/nvm" ]] && {
        export NVM_DIR="$HERD_TOOLS_CONFIG/nvm"
        zf::debug "# [dev-env] Using Herd's NVM: $NVM_DIR"
    }

    zf::debug "# [dev-env] Herd environment configured (supersedes standard PHP/Node setup)"
else
    zf::debug "# [dev-env] Herd not found - will use standard Node.js/PHP setup"
fi
_zf_dev_segment "herd" "end"

# NVM (Node Version Manager) with Lazy Loading - AFTER Herd check
_zf_dev_segment "nvm" "start"

# Custom NVM directory detection
# Fallback: If no NVM_DIR was set by Herd, try to find standard NVM locations
zf::debug "# [dev-env] No NVM_DIR found, searching for standard NVM installations"
[[ -d "${BREW_PREFIX}/opt/nvm" ]] &&
    export NVM_DIR="${NVM_DIR:-${BREW_PREFIX}/opt/nvm}"
[[ -d "${XDG_CONFIG_HOME:-${HOME}/.config}/nvm" ]] &&
    export NVM_DIR="${NVM_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/nvm}"
[[ -d "${HOME}/.nvm" ]] &&
    export NVM_DIR="${NVIM_DIR:-${HOME}/.nvm}"

# NVM Lazy Loading Setup (works for ALL NVM versions - standard or Herd)
zf::debug "# [dev-env] Setting up NVM lazy loading for: $NVM_DIR"

# Always set up lazy loading if we have an NVM_DIR (from Herd or standard locations)
if [[ -n "$NVM_DIR" && -d "$NVM_DIR" ]]; then
    zf::debug "# [dev-env] Found standard NVM at: $NVM_DIR"

    # NVM environment setup
    export NVM_AUTO_USE=true
    export NVM_LAZY_LOAD=true
    export NVM_COMPLETION=true

    # CRITICAL: Unset NPM_CONFIG_PREFIX for NVM compatibility
    unset NPM_CONFIG_PREFIX

    # Lazy load nvm function for faster startup (works for ALL NVM types)
    # Use explicit typeset to ensure proper function scoping
    typeset -f nvm >/dev/null 2>&1 && unfunction nvm 2>/dev/null
    nvm() {
        # Remove the lazy loader function
        unfunction nvm 2>/dev/null
        unset NPM_CONFIG_PREFIX

        # Source NVM scripts
        [[ -s "$NVM_DIR/nvm.sh" ]] && builtin source "$NVM_DIR/nvm.sh"
        [[ -s "$NVM_DIR/bash_completion" ]] && builtin source "$NVM_DIR/bash_completion"

        # Call nvm with original arguments
        nvm "$@"
    }

    # Explicitly export the function
    typeset -f nvm >/dev/null 2>&1 && zf::debug "# [dev-env] NVM function properly defined"

    zf::debug "# [dev-env] NVM lazy loader configured for: $NVM_DIR"

    # Set up minimal path for immediate node access (if default exists)
    [[ -d "$NVM_DIR/versions/node" ]] && {
        local node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | tail -1)"
        [[ -d "$node_dir/bin" ]] && export PATH="$node_dir/bin:$PATH"
        zf::debug "# [dev-env] Added immediate Node.js access: $node_dir/bin"
    }
else
    zf::debug "# [dev-env] NVM not found in any standard locations"
fi
_zf_dev_segment "nvm" "end"

# pnpm Integration
_zf_dev_segment "pnpm" "start"
if command -v pnpm >/dev/null 2>&1; then
    # pnpm PATH configuration
    export PNPM_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/pnpm"
    export PATH="$PNPM_HOME:$PATH"

    # pnpm environment optimization
    export NPM_CONFIG_PROGRESS=false
    export NPM_CONFIG_AUDIT=false
    export NPM_CONFIG_FUND=false

    zf::debug "# [dev-env] pnpm configured with PNPM_HOME=$PNPM_HOME"
else
    zf::debug "# [dev-env] pnpm not found"
fi
_zf_dev_segment "pnpm" "end"

# Rbenv (Ruby)
_zf_dev_segment "rbenv" "start"
[[ -d "$HOME/.rbenv/bin" ]] && export PATH="$HOME/.rbenv/bin:$PATH"

if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - --no-rehash zsh 2>/dev/null || rbenv init - zsh 2>/dev/null)" 2>/dev/null || true
fi
_zf_dev_segment "rbenv" "end"

# Pyenv (Python)
_zf_dev_segment "pyenv" "start"
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    eval "$(pyenv init - --no-rehash 2>/dev/null || pyenv init -)" 2>/dev/null || true
elif [[ -d "$HOME/.pyenv/bin" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - --no-rehash 2>/dev/null || pyenv init -)" 2>/dev/null || true
fi
_zf_dev_segment "pyenv" "end"

# Go
_zf_dev_segment "go" "start"
if [[ -d "/usr/local/go/bin" ]]; then
    export PATH="/usr/local/go/bin:$PATH"
fi
if [[ -d "$HOME/go/bin" ]]; then
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$GOPATH/bin:$PATH"
fi
_zf_dev_segment "go" "end"

# Rust/Cargo
_zf_dev_segment "rust" "start"
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env" 2>/dev/null || true
elif [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
_zf_dev_segment "rust" "end"

# GPG Configuration
_zf_dev_segment "gpg" "start"
# Guard GPG agent initialization from Warp to avoid interactive prompts
if [[ $TERM_PROGRAM != "WarpTerminal" ]] && command -v gpg >/dev/null 2>&1; then
    # Set GPG_TTY for proper terminal interaction
    export GPG_TTY=$(tty)

    # Start gpg-agent if not running
    if ! pgrep -x "gpg-agent" >/dev/null; then
        gpg-connect-agent /bye >/dev/null 2>&1 || true
    fi
fi
_zf_dev_segment "gpg" "end"

# === Development environment setup END ===
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_SEG_30_DEV_ENV_START_MS:-} && -z ${POST_SEG_30_DEV_ENV_MS:-} ]]; then
    local __post_seg_30_end_ms __post_seg_30_delta
    __post_seg_30_end_ms=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
    if [[ -n $__post_seg_30_end_ms ]]; then
        ((__post_seg_30_delta = __post_seg_30_end_ms - POST_SEG_30_DEV_ENV_START_MS))
        POST_SEG_30_DEV_ENV_MS=$__post_seg_30_delta
        export POST_SEG_30_DEV_ENV_MS
        if [[ $__post_seg_30_delta -ge 0 ]]; then
            print "POST_PLUGIN_SEGMENT 30-dev-env $__post_seg_30_delta" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
        fi
        zf::debug "# [post-plugin][perf] segment=30-dev-env delta=${POST_SEG_30_DEV_ENV_MS}ms"
    fi
fi
