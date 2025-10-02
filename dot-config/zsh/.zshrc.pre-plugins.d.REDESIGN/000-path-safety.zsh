#!/usr/bin/env zsh
# 000-PATH-SAFETY.ZSH (canonical after consolidation)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
# Full content migrated from legacy 00-path-safety.zsh (now stubbed).

if [[ -n "${_PATH_SAFETY_LOADED:-}" ]]; then
    return 0
fi
export _PATH_SAFETY_LOADED=1

if [[ -z "${_CORE_INFRASTRUCTURE_REDESIGN:-}" ]] && [[ -f "${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.d.REDESIGN/00-core-infrastructure.zsh"
fi
zf::debug "[PATH-SAFETY][000] Loading PATH safety system"

if [[ ${#PATH} -gt 5000 ]]; then
    zf::debug "[PATH-SAFETY][000] Large PATH detected (${#PATH}), repairing"
    local -a emergency_path
    IFS=':' read -rA emergency_path <<< "$PATH"
    typeset -U emergency_path
    PATH="${(j.:.)emergency_path}"
fi

if [[ -n "${ZQS_BASELINE_PATH_SNAPSHOT:-}" ]]; then
    local -a essential_paths=(
        "/opt/homebrew/bin" "/opt/homebrew/sbin" "/usr/local/bin" "/usr/local/sbin" "/usr/bin" "/bin" "/usr/sbin" "/sbin"
    )
    local -a current_path
    IFS=':' read -rA current_path <<< "$PATH"
    local essential_dir
    for essential_dir in "${essential_paths[@]}"; do
        if [[ -n $essential_dir && -d $essential_dir && ${current_path[(Ie)$essential_dir]} -eq 0 ]]; then
            path+=("$essential_dir")
        fi
    done
else
    PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
    [[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
    [[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
fi

if command -v brew >/dev/null 2>&1; then
    local BREW_PREFIX
    BREW_PREFIX=$(brew --prefix 2>/dev/null)
    if [[ -n $BREW_PREFIX ]]; then
        [[ -d ${BREW_PREFIX}/sbin && :$PATH: != *:${BREW_PREFIX}/sbin:* ]] && PATH="${BREW_PREFIX}/sbin:$PATH"
        [[ -d ${BREW_PREFIX}/bin && :$PATH: != *:${BREW_PREFIX}/bin:* ]] && PATH="${BREW_PREFIX}/bin:$PATH"
    fi
fi

if command -v fzf >/dev/null 2>&1; then export FZF_COMMAND="$(command -v fzf)"; fi
if command -v bat >/dev/null 2>&1; then export BAT_COMMAND="$(command -v bat)"; fi
if command -v eza >/dev/null 2>&1; then export EZA_COMMAND="$(command -v eza)"; fi

safe_command() { zf::path_safe_command "$@" 2>/dev/null || command "$@"; }
safe_date() { zf::safe_date "$@" 2>/dev/null || command date "$@"; }
safe_mkdir() { zf::safe_mkdir "$@" 2>/dev/null || command mkdir "$@"; }
safe_dirname() { zf::safe_dirname "$@" 2>/dev/null || command dirname "$@"; }
safe_basename() { zf::safe_basename "$@" 2>/dev/null || command basename "$@"; }
safe_readlink() { zf::safe_readlink "$@" 2>/dev/null || command readlink "$@"; }

local -a path_components valid_path_components unique_path_components
IFS=':' read -rA path_components <<< "$PATH"
local dir removed_count=0
for dir in "${path_components[@]}"; do
  if [[ -n $dir ]]; then
    valid_path_components+=("$dir")
  else
    ((removed_count++))
  fi
done
if (( removed_count > 0 )); then
  PATH="${(j.:.)valid_path_components}"
fi
IFS=':' read -rA unique_path_components <<< "$PATH"
typeset -U unique_path_components
PATH="${(j.:.)unique_path_components}"
path=("${unique_path_components[@]}")
rehash

: ${RPS1:=""} : ${RPS2:=""} : ${RPS3:=""} : ${RPS4:=""} : ${RPS5:=""}
: ${RPROMPT:=""} : ${PROMPT:=""}
: ${PS1:="%m%# "} : ${PS2:="> "} : ${PS3:="?# "} : ${PS4:="+%N:%i> "}

can_haz() { zf::ensure_cmd "$@" 2>/dev/null || command -v "$1" >/dev/null 2>&1; }
export PATH_SAFETY_REDESIGN_VERSION="2.2.0"
export PATH_SAFETY_REDESIGN_LOADED_AT="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
zf::debug "[PATH-SAFETY][000] Ready (${#path[@]} entries)"

return 0
