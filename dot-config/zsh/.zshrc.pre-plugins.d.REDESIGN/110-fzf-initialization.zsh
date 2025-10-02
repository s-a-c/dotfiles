#!/usr/bin/env zsh
# 110-FZF-INITIALIZATION.ZSH (inlined from legacy 25-fzf-initialization.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
if [[ -n "${_LOADED_FZF_INIT_REDESIGN:-}" ]]; then return 0; fi
export _LOADED_FZF_INIT_REDESIGN=1
_fzf_debug() { [[ -n "${ZSH_DEBUG:-}" ]] && zf::debug "[FZF-INIT] $1" || true; }
_fzf_debug "Loading FZF integration system (v2.0.0)"
command -v fzf >/dev/null 2>&1 || { _fzf_debug "FZF command not found in PATH - skipping initialization"; return 0; }
local fzf_installation="" search_path loaded_count=0
local -a fzf_search_paths=( "$(command -v fzf 2>/dev/null | xargs dirname | xargs dirname 2>/dev/null)" "/opt/homebrew/opt/fzf" "/usr/local/opt/fzf" "$HOME/.fzf" "/usr/share/fzf" "/opt/fzf" )
for search_path in "${fzf_search_paths[@]}"; do [[ -d "$search_path" ]] && { fzf_installation="$search_path"; _fzf_debug "FZF installation detected: $fzf_installation"; break; }; done
[[ -z $fzf_installation ]] && { _fzf_debug "Warning: FZF binary found but installation directory not detected"; return 0; }
local fzf_bin_dir="${fzf_installation}/bin"; [[ -d "$fzf_bin_dir" && ":$PATH:" != *":$fzf_bin_dir:"* ]] && { export PATH="$PATH:$fzf_bin_dir"; _fzf_debug "Added FZF bin directory to PATH: $fzf_bin_dir"; }
local -a integration_files=("${fzf_installation}/shell/completion.zsh" "${fzf_installation}/shell/key-bindings.zsh") integration_file
for integration_file in "${integration_files[@]}"; do [[ -r "$integration_file" ]] && { source "$integration_file"; ((loaded_count++)); _fzf_debug "Loaded FZF integration: $(basename "$integration_file")"; } || _fzf_debug "Warning: FZF integration file not found: $integration_file"; done
local -a additional_sources=("$HOME/.local/share/fzf/fzf.zsh" "$HOME/.fzf.zsh") additional_source
for additional_source in "${additional_sources[@]}"; do [[ -r "$additional_source" ]] && { source "$additional_source"; _fzf_debug "Loaded additional FZF source: $additional_source"; }; done
export FZF_INSTALL_PATH="$fzf_installation" FZF_PATH="$HOME/.fzf"
[[ -z "${FZF_DEFAULT_OPTS:-}" ]] && { export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"; _fzf_debug "Set default FZF options"; }
if command -v fd >/dev/null 2>&1 && [[ -z "${FZF_DEFAULT_COMMAND:-}" ]]; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  _fzf_debug "Configured FZF to use fd for file discovery"
fi
export FZF_INIT_VERSION="2.0.0" FZF_INIT_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'unknown')"
_fzf_debug "FZF integration completed (${loaded_count} shell integration files loaded)"
unset -f _fzf_debug
return 0
