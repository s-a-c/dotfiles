# 05-fzf-init.zsh (Pre-Plugin Redesign Skeleton)
[[ -n ${_LOADED_PRE_FZF_INIT:-} ]] && return
_LOADED_PRE_FZF_INIT=1

# PURPOSE: Lightweight FZF environment + key bindings (no installs)
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    # Basic key-binding registration (defer heavy extras until post-plugin if needed)
    if [[ -f "${HOME}/.fzf/shell/key-bindings.zsh" ]]; then
        source "${HOME}/.fzf/shell/key-bindings.zsh"
    fi
fi

zsh_debug_echo "# [pre-plugin] 05-fzf-init skeleton loaded"
