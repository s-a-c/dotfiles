#!/usr/bin/env zsh
# 170-LAZY-INTEGRATIONS.ZSH (inlined from legacy 55-lazy-integrations.zsh)
# Compliant with [/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md](/Users/s-a-c/dotfiles/dot-config/ai/guidelines.md) v${GUIDELINES_CHECKSUM:-pending}
[[ -n "${_LOADED_25_LAZY_INTEGRATIONS:-}" ]] && return 0
[[ -n ${_LOADED_PRE_LAZY_INTEGRATIONS:-} ]] && return 0
_LOADED_PRE_LAZY_INTEGRATIONS=1
: ${ZSH_LAZY_INTEGRATIONS_DIRENV:=1}
: ${ZSH_LAZY_INTEGRATIONS_GH:=1}
__lazy_loader_direnv_integration() { if ! command -v direnv >/dev/null 2>&1; then direnv(){ echo "# [lazy-direnv] direnv not installed" >&2; return 127; }; return 0; fi; direnv(){ command direnv "$@"; }; zf::debug "# [lazy-integrations] direnv loader installed"; }
((ZSH_LAZY_INTEGRATIONS_DIRENV)) && lazy_register --force direnv __lazy_loader_direnv_integration >/dev/null 2>&1 || true
__lazy_loader_gh_integration() { if ! command -v gh >/dev/null 2>&1; then gh(){ echo "# [lazy-gh] gh not installed" >&2; return 127; }; return 0; fi; gh(){ command gh "$@"; }; zf::debug "# [lazy-integrations] gh loader installed"; }
((ZSH_LAZY_INTEGRATIONS_GH)) && lazy_register --force gh __lazy_loader_gh_integration >/dev/null 2>&1 || true
safe_git config --global user.name >/dev/null 2>&1 || true
zf::prepare_zle_environment() { [[ -o interactive ]] || return 0; autoload -Uz zle; bindkey -e; [[ -z "${widgets[self-insert]:-}" ]] && { zle -N _zle_init_test; zle -D _zle_init_test 2>/dev/null || true; unfunction _zle_init_test 2>/dev/null || true; }; setopt ZLE 2>/dev/null || true; [[ -n "${widgets+x}" && ${#widgets[@]} -gt 0 ]] && zf::debug "# [pre-plugin] ZLE initialized (${#widgets[@]} widgets)" || zf::debug "# [pre-plugin] ZLE fallback"; }
zf::prepare_autopair_environment() { if [[ -z "${AUTOPAIR_PAIRS+x}" ]]; then typeset -gA AUTOPAIR_PAIRS; AUTOPAIR_PAIRS=('`' '`' "'" "'" '"' '"' '{' '}' '[' ']' '(' ')' ' ' ' '); fi; if [[ -z "${AUTOPAIR_LBOUNDS+x}" ]]; then typeset -gA AUTOPAIR_LBOUNDS; AUTOPAIR_LBOUNDS=(all '[.:/\\!]' quotes '[]})a-zA-Z0-9]' spaces '[^{([]' braces '' '`' '`' '"' '"' "'" "'"); fi; if [[ -z "${AUTOPAIR_RBOUNDS+x}" ]]; then typeset -gA AUTOPAIR_RBOUNDS; AUTOPAIR_RBOUNDS=(all '[[{(<,.:?/%$!a-zA-Z0-9]' quotes '[a-zA-Z0-9]' spaces '[^]})]' braces ''); fi; : ${AUTOPAIR_INHIBIT_INIT:=""}; : ${AUTOPAIR_BETWEEN_WHITESPACE:=""}; export AUTOPAIR_INHIBIT_INIT AUTOPAIR_BETWEEN_WHITESPACE; zf::debug "# [pre-plugin] autopair env prepared"; }
zf::prepare_zle_environment
zf::prepare_autopair_environment
if [[ "$TERM_PROGRAM" == WarpTerminal ]]; then unalias k 2>/dev/null || true; zf::debug "# [pre-plugin] cleared k alias for Warp"; fi
zf::debug "# [pre-plugin] lazy-integrations enhanced"
readonly _LOADED_25_LAZY_INTEGRATIONS=1
return 0
