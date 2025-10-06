#!/usr/bin/env zsh
# 160-NODE-RUNTIME.ZSH (inlined from legacy 50-node-runtime.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n "${_LOADED_NODE_RUNTIME_REDESIGN:-}" ]]; then return 0; fi
export _LOADED_NODE_RUNTIME_REDESIGN=1
_node_debug() { [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[NODE-RUNTIME] $1" || true; }
_node_debug "Loading Node.js runtime environment (v2.0.0)"
export NODE_ENV="${NODE_ENV:-development}" NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}" NVM_LAZY_LOAD="${NVM_LAZY_LOAD:-true}" NVM_COMPLETION="${NVM_COMPLETION:-true}"
export NPM_CONFIG_PROGRESS="${NPM_CONFIG_PROGRESS:-true}" NPM_CONFIG_COLOR="${NPM_CONFIG_COLOR:-always}"
if [[ -d "$HOME/.bun" ]]; then export BUN_INSTALL="$HOME/.bun"; [[ :$PATH: == *":$BUN_INSTALL/bin:"* ]] || export PATH="$BUN_INSTALL/bin:$PATH"; _node_debug "Added Bun to PATH"; fi
_load_nvm() { local cmd="$1"; _node_debug "Loading NVM for command: $cmd"; if [[ -s "$NVM_DIR/nvm.sh" ]]; then source "$NVM_DIR/nvm.sh"; [[ -s "$NVM_DIR/bash_completion" && ${NVM_COMPLETION:-true} == true ]] && source "$NVM_DIR/bash_completion"; return 0; else _node_debug "NVM not found at $NVM_DIR/nvm.sh"; return 1; fi }
if command -v lazy_register >/dev/null 2>&1 && [[ -s "$NVM_DIR/nvm.sh" ]]; then lazy_register nvm _load_nvm; _node_debug "NVM registered for lazy loading"; elif [[ -s "$NVM_DIR/nvm.sh" ]]; then _load_nvm nvm; fi
if command -v nvm >/dev/null 2>&1; then unset NPM_CONFIG_PREFIX 2>/dev/null || true; _node_debug "NPM_CONFIG_PREFIX kept unset"; fi
local -a node_paths=( "$HOME/.local/share/npm/bin" "$HOME/.npm-global/bin" "/usr/local/share/npm/bin" ) p
for p in "${node_paths[@]}"; do [[ -d "$p" && :$PATH: != *":$p:"* ]] && { export PATH="$PATH:$p"; _node_debug "Added Node path: $p"; }; done
export NODE_RUNTIME_VERSION="2.0.0" NODE_RUNTIME_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
_node_debug "Node.js runtime environment ready"
unset -f _node_debug
return 0
