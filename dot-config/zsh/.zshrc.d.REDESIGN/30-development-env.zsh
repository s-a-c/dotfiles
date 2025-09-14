#!/opt/homebrew/bin/zsh
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
typeset -f zsh_debug_echo >/dev/null 2>&1 || zsh_debug_echo() { :; }
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
            local delta=$(( end_ms - _ZF_DEV_SEG_START[$name] ))
            (( delta < 0 )) && delta=0
            if [[ -n "${PERF_SEGMENT_LOG:-}" ]]; then
                print "SEGMENT name=dev-env/${name} ms=${delta} phase=post_plugin sample=${PERF_SAMPLE_CONTEXT:-unknown}" >> "${PERF_SEGMENT_LOG}" 2>/dev/null || true
            fi
        fi
    fi
}

typeset -gA _ZF_DEV_SEG_START

# NVM (Node Version Manager)
_zf_dev_segment "nvm" "start"
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # Defer full nvm init (expensive) - just set up path
    if [[ -d "$NVM_DIR/versions/node" ]]; then
        # Find default or latest node
        local node_dir="$(ls -1d "$NVM_DIR"/versions/node/v* 2>/dev/null | tail -1)"
        [[ -d "$node_dir/bin" ]] && export PATH="$node_dir/bin:$PATH"
    fi
fi
_zf_dev_segment "nvm" "end"

# Rbenv (Ruby)
_zf_dev_segment "rbenv" "start"
if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - --no-rehash zsh 2>/dev/null || rbenv init - zsh 2>/dev/null)" 2>/dev/null || true
elif [[ -d "$HOME/.rbenv/bin" ]]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
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
if command -v gpg >/dev/null 2>&1; then
    # Set GPG_TTY for proper terminal interaction
    export GPG_TTY=$(tty)
    
    # Start gpg-agent if not running
    if ! pgrep -x "gpg-agent" > /dev/null; then
        gpg-connect-agent /bye >/dev/null 2>&1 || true
    fi
fi
_zf_dev_segment "gpg" "end"

# === Development environment setup END ===
if [[ -n ${PERF_SEGMENT_LOG:-} && -n ${POST_SEG_30_DEV_ENV_START_MS:-} && -z ${POST_SEG_30_DEV_ENV_MS:-} ]]; then
  local __post_seg_30_end_ms __post_seg_30_delta
  __post_seg_30_end_ms=$(printf '%s' "$EPOCHREALTIME" | awk -F. '{ms=$1*1000;if(NF>1){ms+=substr($2"000",1,3)+0}printf "%d",ms}')
  if [[ -n $__post_seg_30_end_ms ]]; then
    (( __post_seg_30_delta = __post_seg_30_end_ms - POST_SEG_30_DEV_ENV_START_MS ))
    POST_SEG_30_DEV_ENV_MS=$__post_seg_30_delta
    export POST_SEG_30_DEV_ENV_MS
    if [[ $__post_seg_30_delta -ge 0 ]]; then
      print "POST_PLUGIN_SEGMENT 30-dev-env $__post_seg_30_delta" >>"${PERF_SEGMENT_LOG}" 2>/dev/null || true
    fi
    zsh_debug_echo "# [post-plugin][perf] segment=30-dev-env delta=${POST_SEG_30_DEV_ENV_MS}ms"
  fi
fi
