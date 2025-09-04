# 15-node-runtime-env.zsh (Pre-Plugin Redesign Skeleton)
[[ -n ${_LOADED_PRE_NODE_RUNTIME_ENV:-} ]] && return
_LOADED_PRE_NODE_RUNTIME_ENV=1

# PURPOSE: Provide lazy Node.js (nvm / npm) environment wrappers without sourcing heavy scripts.
# Full nvm & npm plugin activation occurs later (gated) in add-plugins phase if enabled.

# Feature flags (honor existing exports if set in .zshenv)
: ${ZSH_ENABLE_NVM_PLUGINS:=1}
: ${ZSH_NODE_LAZY:=1}

# Configure NVM_DIR detection chain (Herd -> Homebrew -> ~/.nvm)
if [[ -z ${NVM_DIR:-} ]]; then
    if [[ -d "${HOME}/Library/Application Support/Herd/config/nvm" ]]; then
        NVM_DIR="${HOME}/Library/Application Support/Herd/config/nvm"
    elif [[ -n ${HOMEBREW_PREFIX:-} && -d "${HOMEBREW_PREFIX}/opt/nvm" ]]; then
        NVM_DIR="${HOMEBREW_PREFIX}/opt/nvm"
    elif [[ -d "${HOME}/.nvm" ]]; then
        NVM_DIR="${HOME}/.nvm"
    fi
    export NVM_DIR
fi

export NVM_AUTO_USE=true
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true

# zstyle hints (if OMZ nvm plugin later loaded)
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
zstyle ':omz:plugins:nvm' autoload yes

# Lazy nvm() stub (only if directory exists and nvm.sh present later)
if [[ ${ZSH_NODE_LAZY} == 1 && -d ${NVM_DIR:-/nonexistent} ]]; then
    nvm() {
        # Replace stub with real nvm
        unfunction nvm 2>/dev/null || true
        if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
            builtin source "${NVM_DIR}/nvm.sh"
        fi
        if [[ -s "${NVM_DIR}/bash_completion" ]]; then
            builtin source "${NVM_DIR}/bash_completion"
        fi
        # Optional first-use init hook
        if typeset -f node_first_use_init >/dev/null 2>&1; then
            node_first_use_init || true
        fi
        nvm "$@"
    }
fi

# Optional placeholder for first-use initialization
node_first_use_init() { :; }

zsh_debug_echo "# [pre-plugin] 15-node-runtime-env skeleton loaded (lazy=${ZSH_NODE_LAZY})"
